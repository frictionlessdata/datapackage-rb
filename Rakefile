$:.unshift File.join( File.dirname(__FILE__), "lib")

require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "open-uri"
require "json"

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

task :update_profiles do

  DEFAULT_REGISTRY_URL = 'https://specs.frictionlessdata.io/schemas/registry.json'
  DEFAULT_REGISTRY_PATH =  File.join(File.expand_path(File.dirname(__FILE__)), 'lib', 'profiles', 'registry.json')

  cache_folder = Pathname.new(DEFAULT_REGISTRY_PATH).split[0]
  remote_registry = open(DEFAULT_REGISTRY_URL).read
  remote_resources = JSON.parse(remote_registry, symbolize_names: true)

  File.open(DEFAULT_REGISTRY_PATH, 'w') do |local_registry|
    local_registry << remote_registry
  end
  remote_resources.each do |resource_meta|
    file_name = Pathname.new(resource_meta[:schema]).split[1]
    local_file_path = cache_folder.join(file_name)
    open(resource_meta[:schema]) do |remote_resource|
      File.open(local_file_path, 'w') do |local_resource|
        local_resource << remote_resource.read
      end
    end
  end

end
