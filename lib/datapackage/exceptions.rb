module DataPackage
  class RegistryError < StandardError; end

  class SchemaException < Exception
    attr_reader :status, :message

    def initialize status
      @status = status
      @message = status
    end
  end

  class ReferenceException < Exception; end
end
