module DataPackage
  class Resource < Hash

    def initialize(resource, base_path = '')
      self.merge! resource
    end

    def self.load(resource, base_path = '')
      # This returns if there are no alternative ways to access the data OR there
      # is a base_path which is a URL
      if is_url?(resource, base_path)
        RemoteResource.new(resource, base_path)
      else
        # If there's a data attribute, we definitely want an inline resource
        if resource['data']
          InlineResource.new(resource)
        else
          # If the file exists - we want a local resource
          if file_exists?(resource, base_path)
            LocalResource.new(resource, base_path)
          # If it doesn't exist and there's a URL to grab the data from, we want
          # a remote resource
          elsif resource['url']
            RemoteResource.new(resource, base_path)
          end
        end
      end
    end

    def self.file_exists?(resource, base_path)
      path = resource['path']
      path = File.join(base_path, path) if base_path != ''
      File.exists?(path)
    end

    def self.is_url?(resource, base_path)
      return true if resource['url'] != nil && resource['path'] == nil && resource['data'] == nil
      return true if base_path.start_with?('http')
    end

  end

  class LocalResource < Resource

    def initialize(resource, base_path = '')
      @base_path = base_path
      @path = resource['path']
      super
    end

    def data
      @path = File.join(@base_path, @path) if @base_path != ''
      open(@path).read
    end

  end

  class InlineResource < Resource
    def data
      self['data']
    end
  end

  class RemoteResource < Resource

    def initialize(resource, base_url = '')
      @base_url = base_url
      @url = resource['url']
      @path = resource['path']
      super
    end

    def data
      url = @url ? @url : URI.join(@base_url, @path)
      open(url).read
    end

  end
end
