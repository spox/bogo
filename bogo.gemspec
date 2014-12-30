$LOAD_PATH.unshift File.expand_path(File.dirname(__FILE__)) + '/lib/'
require 'bogo/version'
Gem::Specification.new do |s|
  s.name = 'bogo'
  s.version = Bogo::VERSION.version
  s.summary = 'Helper libraries'
  s.author = 'Chris Roberts'
  s.email = 'code@chrisroberts.org'
  s.homepage = 'https://github.com/spox/bogo'
  s.description = 'Helper libraries'
  s.require_path = 'lib'
  s.license = 'Apache 2.0'
  s.add_dependency 'hashie'
  s.add_dependency 'multi_json'
  s.files = Dir['lib/**/*'] + %w(bogo.gemspec README.md CHANGELOG.md CONTRIBUTING.md LICENSE)
end
