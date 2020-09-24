Gem::Specification.new do |s|
  s.name                  = 'rxg_client'
  s.version               = '1.1.2'
  s.date                  = '2020-09-23'
  s.summary               = "RXG API Client"
  s.description           = "A simple CRUDE (Create, Read, Update, Delete, Execute) client to interface with the rXg's API"
  s.authors               = ["Lannar Dean"]
  s.email                 = 'ldd@rgnets.com'
  s.files                 = ["lib/rxg_client.rb"]
  s.required_ruby_version = '>= 2.0'
  s.homepage              =
    'https://github.com/rgnets/rxg_client'
  s.license               = 'MIT'

  s.add_dependency 'httparty', '>= 0.10.0'
end