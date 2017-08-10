module DataPackage
  class Exception < ::Exception; end
  class RegistryException < Exception; end
  class ResourceException < Exception; end
  class ProfileException < Exception; end
  class PackageException < Exception; end
  class ValidationError < Exception; end
end
