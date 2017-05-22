class RxgClient
  require 'delegate'
  require 'httparty'

  include HTTParty

  attr_accessor :api_key, :hostname, :request_format, :raise_exceptions

  def request_format= (requested_format)
    raise HTTParty::UnsupportedFormat unless [ :json, :xml ].include?(requested_format.to_sym)
    @request_format = requested_format
  end

  def initialize(hostname, api_key, request_format: :json, default_timeout: 5, raise_exceptions: false, verify_ssl: false)

    self.api_key = api_key
    
    self.request_format = request_format.to_sym
    self.class.format self.request_format

    self.hostname = hostname
    self.class.base_uri "https://#{self.hostname}/admin/scaffolds"
    
    self.class.default_timeout default_timeout

    self.raise_exceptions = raise_exceptions

    self.class.default_options.update(verify: verify_ssl)
  end

  def auth
    {api_key: self.api_key}
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
    response = self.class.post("/#{table}/create/index.#{self.request_format}", { body: {record: new_record}.merge(self.auth) })
    response.success? ? self.parse(response.body) : raise(response.message)
  end
  
  # list all records from the given table
  def list(table)
    response = self.class.get("/#{table}/index.#{self.request_format}", {body: self.auth})
    response.success? ? self.parse(response.body) : raise(response.message)
  end

  # return the record from the given table having the given id
  def show(table, id)
    response = self.class.get("/#{table}/show/#{id}.#{self.request_format}", {body: self.auth})
    response.success? ? self.parse(response.body) : raise(response.message)
  end

  # update a record from the given table, having the given id, with the updated attributes provided in updated_record_hash
  def update(table, id, updated_record_hash)
    response = self.class.post("/#{table}/update/#{id}.#{self.request_format}", {body: {record: updated_record_hash}.merge(self.auth)})
    response.success? ? self.parse(response.body) : raise(response.message)
  end

  # destroy a record from the given table having the given id
  def destroy(table, id)
    response = self.class.post("/#{table}/destroy/#{id}.#{self.request_format}", {body: self.auth})
    response.success? ? self.parse(response.body) : raise(response.message)
  end

  # executes an arbitrary method on given scaffold
  # The "request" hash parameters:
  #   record_name - The "name" attribute of the desired record, if any. Not required if calling a class method or if record_id is present.
  #   record_id - The id of the desired record, if any. Not required if calling a class method or if record_name is present.
  #   method_name - The name of the desired class or instance method to be run against the model.
  #   method_args - A serialized Array or Hash of the argument(s) expected by the method.
  # example method call:
  #   node.execute("shared_credential_groups", {record_id: 7, method_name: "make_login_session", method_args:["192.168.20.111", "00:00:00:00:00:05", "test", 1]})
  #
  # reference the rXg's API documentation to determine available methods and required arguments
  def execute(table, request)
    response = self.class.post("/#{table}/execute.#{self.request_format}", {query: self.auth, body: {request: request}})
    response.success? ? self.parse(response.body) : raise(response.message)
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
  rescue_from StandardError, :create, :list, :show, :update, :destroy, :execute do |exception, instance|
    puts exception.message

    raise exception if instance.raise_exceptions
  end

  
end