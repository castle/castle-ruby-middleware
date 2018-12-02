# coding: utf-8
# frozen_string_literal: true

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'castle/middleware/version'

Gem::Specification.new do |spec|
  spec.name          = 'castle-middleware'
  spec.version       = Castle::Middleware::VERSION
  spec.authors       = ['Johan Brissmyr']
  spec.email         = ['brissmyr@gmail.com']

  spec.summary       = 'Write a short summary, because Rubygems requires one.'
  spec.description   = 'Write a longer description or delete this line.'
  spec.homepage      = 'https://castle.io'
  spec.license       = 'MIT'

  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(spec)/}) }
  end
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.2.0'
  spec.add_dependency 'castle-rb', '< 4.0'
end
