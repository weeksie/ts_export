# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "ts_export/version"

Gem::Specification.new do |s|
  s.name        = "ts_export"
  s.version     = TsExport::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Scotty Weeks"]
  s.email       = ["scott.weeks@gmail.com"]
  s.homepage    = ""
  s.summary     = %q{Export vbulletin and put it in a format that can be imported into 12s}
  s.description = %q{Export vbulletin and put it in a format that can be imported into 12s}

  s.rubyforge_project = "ts_export"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  
  s.add_dependency "mysql"
  s.add_dependency "json"
end
