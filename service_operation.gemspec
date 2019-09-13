require './lib/service_operation/version'

Gem::Specification.new do |s|
  s.name        = 'service_operation'
  s.version     = ServiceOperation::VERSION

  s.summary     = 'Service Operations based on Interactor, Interactor Contracts, and ValueSemantics'
  s.homepage    = 'https://github.com/babelian/service_operation'
  s.authors     = ['Zach Powell']
  s.email       = 'zach@babelian.net'
  s.license     = 'MIT'
  s.required_ruby_version = '>= 2.5.3'

  s.files = Dir.glob('{lib}/**/*')
  s.require_paths = %w[lib]

  s.add_development_dependency 'pry-byebug', '~> 3.7.0'
  s.add_development_dependency 'rspec', '3.7.0'
  s.add_development_dependency 'simplecov', '~> 0.17.0'
end
