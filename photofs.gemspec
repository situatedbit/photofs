# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'photofs/version'

Gem::Specification.new do |s|
  s.name          = "photofs"
  s.version       = PhotoFS::VERSION
  s.authors       = ["Matt Schaefer"]
  s.email         = ["matt@situatedbit.com"]

  s.summary       = %q{Core library for PhotoFS, a photo workflow system.}
  s.homepage      = "https://github.com/situatedbit/photofs"
  s.license       = "GPL3"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if s.respond_to?(:metadata)
    s.metadata['allowed_push_host'] = "https://situatedbit.com"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  s.files         = Dir.glob("{db,lib}/**/*") + %w(LICENSE README.md)
  s.executables   = []
  s.require_paths = ["lib"]

  s.add_development_dependency "bundler", "~> 1.12"
  s.add_development_dependency "rake", "~> 12.1"
end
