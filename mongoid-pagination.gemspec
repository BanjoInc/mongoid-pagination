# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "mongoid/pagination/version"

Gem::Specification.new do |s|
  s.name        = "banjo-mongoid-pagination"
  s.version     = Mongoid::Pagination::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Alex Sharp", "KW Justin Leung"]
  s.email       = ["ajsharp@gmail.com", "justin@teambanjo.com"]
  s.homepage    = "https://github.com/BanjoInc/mongoid-pagination"
  s.summary     = %q{A simple pagination module for Mongoid}
  s.description = %q{A simple pagination module for Mongoid}

  s.rubyforge_project = s.name

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency 'mongoid'
end
