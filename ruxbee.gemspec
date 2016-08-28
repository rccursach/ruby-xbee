# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ruxbee/version'

Gem::Specification.new do |spec|
  spec.name          = "ruxbee"
  spec.version       = Ruxbee::VERSION
  spec.authors       = ['Ricardo Carrasco-Cursach', 'Landon Cox', 'Mike Ashmore', 'Sten Feldman']
  spec.email         = ["rccursach@gmail.com"]
  spec.licenses      = ['AGPL']

  spec.summary       = "Ruby Gem for XBee forked from ruby-xbee"
  spec.description   = "A lighter XBee S1 and S2 library for ruby"
  spec.homepage      = "http://www.github.com/rccursach/ruxbee"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "https://rubygems.org'"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "serialport", ">= 1.3.1"
  spec.add_development_dependency "bundler", "~> 1.12"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
