module DataPackage
  class Resource < Hash
    include DataPackage::Helpers

    attr_reader :name, :profile, :source, :source_type, :valid, :errors

    def initialize(resource, base_path = '')
      resource = dereference_descriptor(resource, base_path: base_path,
        reference_fields: ['schema', 'dialect'])
      self.merge! resource
      @profile = DataPackage::Profile.new(self.fetch('profile', 'data-resource'))
      @name = self['name']
      get_source!(base_path)
    end

    def table
      @table ||= TableSchema::Table.new(self.source, self['schema']) if tabular?
    end

    def tabular?
      tabular_profile = 'tabular-data-resource'
      return true if @profile.name == tabular_profile
      return true if DataPackage::Profile.new(tabular_profile).valid?(self)
      false
    end

    alias :tabular :tabular?

    def valid?
      validate
      @valid
    end

    def validate
      @errors = @profile.validate(self)
      @valid = @profile.valid?(self)
    end

    private

    def get_source!(base_path)
      if self.fetch('data', nil)
        @source = self['data']
        @source_type = 'inline'
      elsif self.fetch('path', nil)
        unless is_safe_path?(self['path'])
          raise ResourceException.new "Path `#{self['path']}` is not safe"
        end
        @source = join_paths(base_path, self['path'])
        @source_type = is_fully_qualified_url?(@source) ? 'remote' : 'local'
      else
        raise ResourceException.new 'A resource descriptor must have a `path` or `data` property.'
      end
    end

  end
end
