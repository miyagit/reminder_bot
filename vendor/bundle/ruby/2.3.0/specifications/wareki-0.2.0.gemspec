# -*- encoding: utf-8 -*-
# stub: wareki 0.2.0 ruby lib

Gem::Specification.new do |s|
  s.name = "wareki"
  s.version = "0.2.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Tatsuki Sugiura"]
  s.date = "2017-07-25"
  s.description = "Pure ruby library of Wareki (Japanese calendar date) that supports string parsing, formatting, and bi-directional convertion with standard Date class."
  s.email = ["sugi@nemui.org"]
  s.homepage = "https://github.com/sugi/wareki"
  s.licenses = ["BSD"]
  s.required_ruby_version = Gem::Requirement.new(">= 2.0.0")
  s.rubygems_version = "2.5.1"
  s.summary = "Pure ruby library of Wareki (Japanese calendar date)"

  s.installed_by_version = "2.5.1" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<bundler>, ["~> 1.9"])
      s.add_development_dependency(%q<rake>, ["~> 10.0"])
      s.add_development_dependency(%q<rspec>, [">= 0"])
    else
      s.add_dependency(%q<bundler>, ["~> 1.9"])
      s.add_dependency(%q<rake>, ["~> 10.0"])
      s.add_dependency(%q<rspec>, [">= 0"])
    end
  else
    s.add_dependency(%q<bundler>, ["~> 1.9"])
    s.add_dependency(%q<rake>, ["~> 10.0"])
    s.add_dependency(%q<rspec>, [">= 0"])
  end
end
