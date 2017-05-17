Gem::Specification.new do |s|
  s.name        = 'rxg_client'
  s.version     = '0.0.1'
  s.date        = '2017-05-17'
  s.summary     = "RXG API Client"
  s.description = "A simple CRUDE (Create, Read, Update, Delete, Execute) client to interface with the RXG's API"
  s.authors     = ["Lannar Dean"]
  s.email       = 'ldd@rgnets.com'
  s.files       = ["lib/rxg_client.rb"]
  s.add_dependency 'httparty', '>= 0.10.0'
  s.homepage    =
    'https://github.com/moracca/rxg_client'
  s.license       = 'MIT'
end