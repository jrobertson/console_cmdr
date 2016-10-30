Gem::Specification.new do |s|
  s.name = 'console_cmdr'
  s.version = '0.1.0'
  s.summary = 'A customisable command-line shell which uses the cmdr gem.'
  s.authors = ['James Robertson']
  s.files = Dir['lib/console_cmdr.rb']
  s.add_runtime_dependency('cmdr', '~> 0.4', '>=0.4.0')  
  s.signing_key = '../privatekeys/console_cmdr.pem'
  s.cert_chain  = ['gem-public_cert.pem']
  s.license = 'MIT'
  s.email = 'james@r0bertson.co.uk'
  s.homepage = 'https://github.com/jrobertson/console_cmdr'
end
