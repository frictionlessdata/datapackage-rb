module DataPackage
  class Resource < Hash

    def initialize(resource, base_path = '')
      self.merge! resource
    end

    def self.load(resource, base_path = '', opts = {})
      if local?(resource, opts) && file_exists?(resource, base_path)
        if resource['data']
          InlineResource.new(resource)
        else
          LocalResource.new(resource, base_path)
        end
      else
        RemoteResource.new(resource, base_path)
      end
    end

    def self.local?(resource, opts)
      return opts[:local] if opts[:local]
      return resource['path'] != nil || resource['data'] != nil
    end

    def self.file_exists?(resource, base_path)
      if resource['path']
        path = resource['path']
        path = File.join(base_path, path) if base_path != ''
        File.exists?(path)
      else
        true
      end
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
