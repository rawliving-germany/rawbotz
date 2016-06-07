# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rawbotz/version'

Gem::Specification.new do |spec|
  spec.name          = "rawbotz"
  spec.version       = Rawbotz::VERSION
  spec.authors       = ["Felix Wolfsteller"]
  spec.email         = ["felix.wolfsteller@gmail.com"]

  spec.summary       = %q{web-interface and other tools to manage a magento shop}
  spec.description   = %q{provides a (sinatra) web interface to order from another shop, view stock history ...}
  spec.homepage      = %q{https://rawliving-germany.github.io/rawbotz/}
  spec.licenses      = ['AGPLv3+']

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "sinatra", '~> 1.4'
  spec.add_dependency 'pony', '~> 1.11'
  spec.add_dependency 'haml', '~> 4.0'
  spec.add_dependency "rawgento_models", '~> 0.2.2'
  spec.add_dependency "rawgento_db", "~> 0.1.1"
  spec.add_dependency "magento_remote"
  spec.add_dependency "terminal-table", '~> 1.5'

  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest"
end
