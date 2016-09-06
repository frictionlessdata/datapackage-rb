module DataPackage
  class RegistryError < StandardError; end

  class SchemaException < Exception
    attr_reader :status
    
    def initialize status
      @status = status
    end
  end
end
