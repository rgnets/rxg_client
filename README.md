# rxg_client
A simple CRUDE (Create, Read, Update, Delete, Execute) client to interface with the RXG's API

## Install

```
gem install rxg_client
```

## Requirements

* Ruby 2.0.0 or higher
* HTTParty
* multi_xml

## Examples

```ruby
require 'rxg_client'
options = { 
    default_timeout: 8, 
    raise_exceptions: true,
    verify_ssl: false
}

client = RxgClient.new("hostname.domain.com", "api_key", options)



# create a record
client.create(:wan_targets, {name: "my wan target", targets: "50.50.50.50"})
=> {:id=>14, :name=>"my wan target", :targets=>"50.50.50.50", :note=>nil, :created_at=>"2017-05-17T17:22:43.500-04:00", :updated_at=>"2017-05-17T17:22:43.500-04:00", :created_by=>"api", :updated_by=>"api", :scratch=>nil} 

# show a record
client.show(:wan_targets, 14)
=> {:id=>14, :name=>"my wan target", :targets=>"50.50.50.50", :note=>nil, :created_at=>"2017-05-17T17:22:43.500-04:00", :updated_at=>"2017-05-17T17:22:43.500-04:00", :created_by=>"api", :updated_by=>"api", :scratch=>nil} 


# update a record
client.update(:wan_targets, 14, {targets: "60.60.60.60"})
=> {:id=>14, :name=>"my wan target", :targets=>"60.60.60.60", :note=>nil, :created_at=>"2017-05-17T17:22:43.500-04:00", :updated_at=>"2017-05-17T17:23:37.989-04:00", :created_by=>"api", :updated_by=>"api", :scratch=>nil} 

# list a table
client.list(:wan_targets)
=> [ {:id=>14, :name=>"my wan target", :targets=>"60.60.60.60", :note=>nil, :created_at=>"2017-05-17T17:22:43.500-04:00", :updated_at=>"2017-05-17T17:23:37.989-04:00", :created_by=>"api", :updated_by=>"api", :scratch=>nil} ]

# destroy a record
client.destroy(:wan_targets, 14)
=> {success: true}
# list a table

client.list(:wan_targets)
=> [  ]
```

