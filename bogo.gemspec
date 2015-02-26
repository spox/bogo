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
  s.add_runtime_dependency 'hashie'
  s.add_runtime_dependency 'multi_json'
  s.add_development_dependency 'pry'
  s.add_development_dependency 'minitest'
  s.files = Dir['lib/**/*'] + %w(bogo.gemspec README.md CHANGELOG.md CONTRIBUTING.md LICENSE)
end
