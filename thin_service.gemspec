# -*- encoding: utf-8 -*-
require File.expand_path('../lib/thin_service/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Garth Smedley"]
  gem.email         = ["gsmedley@kanayo.com"]
  gem.description   = %q{Runs Thin as a Windows Service - based on mongrel_service}
  gem.summary       = %q{Windows service exe launches thin_service and keeps it launched.}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "thin_service"
  gem.require_paths = ["lib"]
  gem.version       = ThinService::VERSION
   
  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'rspec'

end
