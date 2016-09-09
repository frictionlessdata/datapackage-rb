module DataPackage
  class Resource < Hash

    def initialize(resource, base_path = '')
      self.merge! resource
    end

    def self.load(resource, base_path = '', opts = {})
      if local?(resource, opts)
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

  end

  class LocalResource < Resource
  end

  class InlineResource < Resource
  end

  class RemoteResource < Resource
  end
end
