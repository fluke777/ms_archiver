# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "archiver/version"

Gem::Specification.new do |s|
  s.name        = "archiver"
  s.version     = Archiver::VERSION
  s.authors     = ["tereza.cihelkova@gooddata.com"]
  s.email       = ["tereza.cihelkova@gooddata.com"]
  s.homepage    = ""
  s.summary     = %q{Gem for archiving to S3}
  s.description = %q{Gem for archiving to S3}

  s.rubyforge_project = "archiver"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  # s.add_development_dependency "rspec"
  # s.add_runtime_dependency "rest-client"
  s.add_dependency('pry')
  s.add_dependency('rubyzip')
  s.add_dependency('aws-s3')
  s.add_dependency('openpgp')
  s.add_dependency('inifile')
end
