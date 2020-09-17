class RxgClient
  require 'httparty'

  include HTTParty

  attr_accessor :api_key, :hostname, :base_uri, :fleet, :request_format,
    :raise_exceptions, :verify_ssl, :auth_method, :default_timeout, :debug_output

  def request_format= (requested_format)
    raise HTTParty::UnsupportedFormat unless [ :json, :xml ].include?(requested_format.to_sym)
    @request_format = requested_format
  end

  # The following options can be configured when initializing the client:
  #  - default_timeout: the amount of time in seconds to wait for a response.
  #      default is 5
  #  - raise_exceptions: true or false.
  #      default is true
  #  - verify_ssl: true or false.
  #      default is true
  #      If using an IP, must be false.
  #  - fleet: pass true if authentication should use the 'fleetkey' header
  #      instead of apikey.
  #      default is false
  #  - auth_method: must be one of: :headers, :query
  #      default is :headers
  #      If fleet is true, headers will always be used
  #  - debug: pass a logger or $stdout to have debug_output logged, or nil to disable.
  #      default is nil
  #  - base_uri: provide an alternative base_uri, either a full URL or just the
  #      path to append to the hostname.
  #      default uses the admin/scaffolds context to access the traditional API
  def initialize(hostname, api_key, request_format: :json, default_timeout: 5,
    raise_exceptions: false, verify_ssl: false, fleet: false, debug_output: nil,
    base_uri: 'admin/scaffolds', auth_method: :headers)

    self.api_key = api_key

    self.hostname = hostname

    self.set_base_uri(base_uri)

    self.fleet = fleet

    self.default_timeout = default_timeout

    self.raise_exceptions = raise_exceptions

    self.verify_ssl = verify_ssl

    self.debug_output = debug_output

    self.request_format = request_format.to_sym

    self.auth_method = auth_method

  end


  # change the active base_uri
  def set_base_uri(base_uri)
    if base_uri =~ /^https?:\/\//
      self.base_uri = base_uri
    else
      self.base_uri = "https://#{self.hostname}/#{base_uri.delete_prefix('/')}"
    end
  end

  # temporarily change the base_uri for the duration of the provided block, then
  # change it back to its previous value
  def with_base_uri(new_base_uri, &blk)
    if block_given?
      begin
        old_uri = self.base_uri

        set_base_uri(new_base_uri)

        blk.call
      ensure
        set_base_uri(old_uri)
      end
    end
  end



  def default_header
    @headers ||= begin
      h = { 'Accept' => "application/#{self.request_format}" }
      if self.fleet
        h['fleetkey'] = self.api_key
      elsif self.auth_method == :headers # compatible with rXg version 11.442 or later
        h['apikey'] = self.api_key
      end
      h
    end
  end

  def default_query
    case self.auth_method
    when :query
      { api_key: self.api_key }
    when :headers
      { }
    end
  end

  %i(post get put patch delete).each do |http_method|
    define_method(http_method) do |action, **args|
      action = "/#{action.to_s.delete_prefix('/')}"
      default_args = {
        :headers      => self.default_header.merge(args.delete(:headers) || {}),
        :query        => self.default_query.merge(args.delete(:query) || {}).presence,
        :base_uri     => self.base_uri,
        :timeout      => self.default_timeout,
        :format       => self.request_format,
        :debug_output => self.debug_output
      }
      response = self.class.send(http_method, action, **default_args.merge(args))
      response.success? ? self.parse(response.body) : raise(response.message)
    end
  end


  def parse(body)
    return {success: true} if body == ""
    begin
      case self.request_format
      when :json
        result = JSON.parse(body)
      when :xml
        result = Hash.from_xml(body)
      else
        raise "Request format should be one of: :json, :xml"
      end

      if result.is_a?(Array)
        result = result.map do |hash|
          # symbolize keys
          hash.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
        end
      elsif result.is_a?(Hash)
        # symbolize keys
        result = result.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
      end

    rescue JSON::ParserError => e
      return body
    end

  end

  # create a record in the given table with the attributes provided in new_record
  def create(table, new_record)
    self.post("/#{table}/create", body: {record: new_record})
  end

  # list all records from the given table
  def list(table)
    self.get("/#{table}")
  end

  def search(table, search_params)
    self.post("/#{table}/index", body: search_params)
  end

  # return the record from the given table having the given id
  def show(table, id)
    self.get("/#{table}/show/#{id}")
  end

  # update a record from the given table, having the given id, with the updated attributes provided in updated_record_hash
  def update(table, id, updated_record_hash)
    self.post("/#{table}/update/#{id}", body: {record: updated_record_hash})
  end

  # destroy a record from the given table having the given id
  def destroy(table, id)
    self.post("/#{table}/destroy/#{id}")
  end

  def execute(table, request)
    # executes an arbitrary method on given scaffold
    # The "request" hash parameters:
    #   record_name - The "name" attribute of the desired record, if any. Not required if calling a class method or if record_id is present.
    #   record_id - The id of the desired record, if any. Not required if calling a class method or if record_name is present.
    #   method_name - The name of the desired class or instance method to be run against the model.
    #   method_args - A serialized Array or Hash of the argument(s) expected by the method.
    # example method call:
    #   node.execute("shared_credential_groups", {record_id: 7, method_name: "make_login_session", method_args:["192.168.20.111", "00:00:00:00:00:05", "test", 1]})
    self.post("/#{table}/execute", body: {request: request})
  end

  private

  # define a unified exception handler for some methods
  def self.rescue_from exception, *meths, &handler
    meths.each do |meth|
      # store the previous implementation
      old = instance_method(meth)
      # wrap it
      define_method(meth) do |*args|
        begin
          old.bind(self).call(*args)
        rescue exception => e
          handler.call(e, self)
        end
      end
    end
  end

  # The listed methods will be rescued from all StandardError exceptions, and the code within
  # the block will be executed.
  rescue_from StandardError, :create, :list, :show, :update, :destroy, :execute, :search do |exception, instance|
    puts exception.message

    raise exception if instance.raise_exceptions
  end

end