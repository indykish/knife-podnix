# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "chef/podnix/version"

Gem::Specification.new do |s|
  s.name        = "knife-podnix"
  s.version     = Chef::Podnix::VERSION
  s.authors     = ["Kishorekumar Neelamegam, Thomas Alrin"]
  s.email       = ["nkishore@megam.co.in","alrin@megam.co.in"]
  s.homepage    = "http://github.com/indykish/knife-podnix"
  s.license = "Apache V2"
  s.extra_rdoc_files = ["README.md", "LICENSE" ]
  s.summary     = %q{Knife Client for Podnix cloud}
  s.description = %q{Knife Client for Podnix cloud. If you wish to use Chef with Podnix an awesome cloud}
  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  s.add_runtime_dependency 'podnix'
  s.add_runtime_dependency 'highline'
  s.add_runtime_dependency 'yajl-ruby'
  s.add_runtime_dependency 'chef'
  s.add_development_dependency 'minitest'
  s.add_development_dependency 'rake'
end
