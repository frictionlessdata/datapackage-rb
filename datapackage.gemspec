lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'datapackage/version'

Gem::Specification.new do |s|
  s.name                  = 'datapackage'
  s.version               = DataPackage::VERSION
  s.authors               = ['Leigh Dodds', 'pezholio', 'pikesley']
  s.email                 = ['ops@theodi.org']
  s.homepage              = 'http://github.com/theodi/datapackage.rb'
  s.summary               = 'Library for working with data packages'
  s.files                 = Dir['{bin,lib'] + ['LICENSE.md', 'README.md']
  s.executables           << 'datapackage'
  s.executables           << 'console'
  s.license               = 'MIT'
  s.required_ruby_version = '>= 2.0'

  s.add_dependency 'json-schema'
  s.add_dependency 'colorize'
  s.add_dependency 'rubyzip'
  s.add_dependency 'ruby_dig'
  s.add_dependency 'tableschema'

  s.add_development_dependency 'bundler', '~> 1.3'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'fakeweb', '~> 1.3'
  s.add_development_dependency 'coveralls'
  s.add_development_dependency 'pry'
end
