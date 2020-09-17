# rxg_client
A simple CRUDE (Create, Read, Update, Delete, Execute) client to interface with the rXg's API

## Install

install the gem directly:
```
gem install rxg_client
```
or include in your gemfile:
```
gem 'rxg_client'
```

## Requirements

* Ruby 2.0.0 or higher
* HTTParty
* multi_xml

## Examples

```ruby
require 'rxg_client'

# In addition to the required host and api_key arguments, the following options
# can be configured when initializing the client:
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

client = RxgClient.new("hostname.domain.com", "api_key",
    default_timeout: 8,
    raise_exceptions: true,
    verify_ssl: true)



# create a record
client.create(:wan_targets, {name: "my wan target", targets: "50.50.50.50"})
=> {id: 14, name: "my wan target", targets: "50.50.50.50", note: nil, created_at: "2017-05-17T17:22:43.500-04:00", updated_at: "2017-05-17T17:22:43.500-04:00", created_by: "api", updated_by: "api", scratch: nil} 

# show a record
client.show(:wan_targets, 14)
=> {id: 14, name: "my wan target", targets: "50.50.50.50", note: nil, created_at: "2017-05-17T17:22:43.500-04:00", updated_at: "2017-05-17T17:22:43.500-04:00", created_by: "api", updated_by: "api", scratch: nil} 


# update a record
client.update(:wan_targets, 14, {targets: "60.60.60.60"})
=> {id: 14, name: "my wan target", targets: "60.60.60.60", note: nil, created_at: "2017-05-17T17:22:43.500-04:00", updated_at: "2017-05-17T17:23:37.989-04:00", created_by: "api", updated_by: "api", scratch: nil} 

# list a table
client.list(:wan_targets)
=> [ {id: 14, name: "my wan target", targets: "60.60.60.60", note: nil, created_at: "2017-05-17T17:22:43.500-04:00", updated_at: "2017-05-17T17:23:37.989-04:00", created_by: "api", updated_by: "api", scratch: nil} ]

# search a table for a record matching the provided hash of attributes
client.search(:accounts, { last_name: 'Smith' })
=> [ {id: 10, login: 'asmith', first_name: 'Alex', last_name: 'Smith', email: 'asmith@school.edu', [...]} ]

# destroy a record
client.destroy(:wan_targets, 14)
=> {success: true}


## EXECUTE
# The “request” hash parameters
# record_name - The “name” attribute of the desired record, if any. 
#       -Not required if calling a class method or if record_id is present.
#
# record_id - The id of the desired record, if any. 
#       -Not required if calling a class method or if record_name is present.
#
# method_name - The name of the desired class or instance method to be run against the model.
#
# method_args - A serialized Array or Hash of the argument(s) expected by the method.

# execute an arbitrary class method, such as 
# Uplink.last
client.execute(:uplinks, {method_name: 'last'})
=> {id: 1, interface_id: 1, vlan_id: nil, ppp_id: nil, name: "Uplink", 
=> dhcp: true, gateway_ip: nil, priority: 9, download_bw: 65, 
=> download_bw_unit: "Mbps", upload_bw: 65, upload_bw_unit: "Mbps", 
=> online: true, weight: 1}

# CustomEmailfind(20).send_including_admins(email, replacement_objs = [ ])
client.execute(:custom_emails, {record_id: 20, method_name: 'send_including_admins', method_args: 'admin@mydomain.com'})
=> "null" 
# email is sent in background.  

# execute an arbitrary instance method, such as
# Account.find(1).quota
client.execute(:accounts, {record_id: 1, method_name: 'quota'})
=> "\"1000 MB / 1000 MB\""

```

