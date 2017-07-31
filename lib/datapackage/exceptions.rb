module DataPackage
  class Exception < ::Exception; end
  class RegistryError < Exception; end
  class ResourceError < Exception; end

  class SchemaException < Exception
    attr_reader :status, :message

    def initialize status
      @status = status
      @message = status
    end
  end
end
