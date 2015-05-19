# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-
# stub: rally-wsapi 0.5.0 ruby lib

Gem::Specification.new do |s|
  s.name = "rally-wsapi"
  s.version = "0.5.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Antti Pitk\u{e4}nen", "Oskari Virtanen"]
  s.date = "2015-05-19"
  s.description = "Simple client for Rally WSAPI"
  s.email = "antti@flowdock.com"
  s.extra_rdoc_files = [
    "LICENSE",
    "README.md"
  ]
  s.files = [
    "Gemfile",
    "Gemfile.lock",
    "LICENSE",
    "README.md",
    "Rakefile",
    "VERSION",
    "lib/rally-wsapi.rb",
    "lib/wsapi/mapper.rb",
    "lib/wsapi/models/object.rb",
    "lib/wsapi/models/project.rb",
    "lib/wsapi/models/subscription.rb",
    "lib/wsapi/models/user.rb",
    "lib/wsapi/session.rb"
  ]
  s.homepage = "http://github.com/flowdock/rally-wsapi"
  s.licenses = ["MIT"]
  s.rubygems_version = "2.4.5"
  s.summary = "Simple client for Rally WSAPI"

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<rake>, [">= 0"])
      s.add_runtime_dependency(%q<multi_json>, [">= 0"])
      s.add_runtime_dependency(%q<faraday>, [">= 0"])
      s.add_runtime_dependency(%q<faraday_middleware>, [">= 0"])
      s.add_runtime_dependency(%q<excon>, [">= 0"])
    else
      s.add_dependency(%q<rake>, [">= 0"])
      s.add_dependency(%q<multi_json>, [">= 0"])
      s.add_dependency(%q<faraday>, [">= 0"])
      s.add_dependency(%q<faraday_middleware>, [">= 0"])
      s.add_dependency(%q<excon>, [">= 0"])
    end
  else
    s.add_dependency(%q<rake>, [">= 0"])
    s.add_dependency(%q<multi_json>, [">= 0"])
    s.add_dependency(%q<faraday>, [">= 0"])
    s.add_dependency(%q<faraday_middleware>, [">= 0"])
    s.add_dependency(%q<excon>, [">= 0"])
  end
end

