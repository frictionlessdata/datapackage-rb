module DataPackage
  DEFAULTS = {
    resource: {
      profile: 'data-resource',
      tabular_profile: 'tabular-data-resource',
      encoding: 'utf-8',
    },
    package: {
      profile: 'data-package',
    },
    schema: {
      format: 'default',
      type: 'string',
      missing_values: [''],
    },
    dialect: {
      delimiter: ',',
      doubleQuote: true,
      lineTerminator: '\r\n',
      quoteChar: '"',
      escapeChar: '\\',
      skipInitialSpace: true,
      header: true,
      caseSensitiveHeader: false,
    },
  }.freeze
end
