# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ubiquity/lts2/version'

Gem::Specification.new do |spec|
  spec.name          = 'ubiquity-lts2'
  spec.version       = Ubiquity::LTS2::VERSION
  spec.authors       = ['John Whitson']
  spec.email         = ['john.whitson@gmail.com']
  spec.summary       = %q{A library and utilities to interact with the EVault Long-Term Storage Service (LTS2).}
  spec.description   = %q{}
  spec.homepage      = 'http://github.com/XPlatform-Consulting/ubiquity-lts2'

  spec.required_ruby_version     = '>= 1.8.7'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})

  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.7'
  spec.add_development_dependency 'rake', '~> 10.0'

  spec.add_runtime_dependency 'fog', '~> 1.20'
end
