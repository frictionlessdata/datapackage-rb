[![Build Status](http://img.shields.io/travis/theodi/datapackage.rb.svg?style=flat-square)](https://travis-ci.org/theodi/datapackage.rb)
[![Dependency Status](http://img.shields.io/gemnasium/theodi/datapackage.rb.svg?style=flat-square)](https://gemnasium.com/theodi/datapackage.rb)
[![Coverage Status](http://img.shields.io/coveralls/theodi/datapackage.rb.svg?style=flat-square)](https://coveralls.io/r/theodi/datapackage.rb)
[![Code Climate](http://img.shields.io/codeclimate/github/theodi/datapackage.rb.svg?style=flat-square)](https://codeclimate.com/github/theodi/datapackage.rb)
[![Gem Version](http://img.shields.io/gem/v/datapackage.svg?style=flat-square)](https://rubygems.org/gems/datapackage)
[![License](http://img.shields.io/:license-mit-blue.svg?style=flat-square)](http://theodi.mit-license.org)

# DataPackage.rb

A ruby library for working with [Data Packages](http://dataprotocols.org/data-packages/).

The library is intending to support:

* Parsing and using data package metadata and data
* Validating data packages to ensure they conform with the Data Package specification

## Installation

Add the gem into your Gemfile:

```
gem 'datapackage.rb'
```

Or:

```
gem install datapackage
```

## Reading a Data Package

Require the gem, if you need to:

```ruby
require 'datapackage.rb'
```

Parsing a Data Package from a remote location:

```ruby
package = DataPackage::Package.new( "http://example.org/datasets/a" )
```

This assumes that `http://example.org/datasets/a/datapackage.json` exists, or specifically load a JSON file:

```ruby
package = DataPackage::Package.new( "http://example.org/datasets/a/datapackage.json" )
```

Similarly you can load a package from a local JSON file, or specify a directory:

```ruby
package = DataPackage::Package.new( "/my/data/package" )
package = DataPackage::Package.new( "/my/data/package/datapackage.json" )
```

There are a set of helper methods for accessing data from the package, e.g:

```ruby
package = DataPackage::Package.new( "/my/data/package" )
package.name
package.title
package.description
package.homepage
package.license
```

## Creating a Data Package

```ruby
package = DataPackage::Package.new

package.name = 'my_sleep_duration'
package.resources =  [
  {'name': 'data'}
]

resource = package.resources[0]
resource.descriptor['data'] = [
  7, 8, 5, 6, 9, 7, 8
]

File.open('datapackage.json', 'w') do |f|
  f.write(package.to_json)
end

# {"name": "my_sleep_duration", "resources": [{"name": "data", "data": [7, 8, 5, 6, 9, 7, 8]}]}
```

## Using a different schema

By default, the gem uses the standard [Data Package Schema](http://specs.frictionlessdata.io/data-packages/), but alternative schemas are available.

### Schemas in the local cache

The gem comes with schemas for the standard Data Package Schema, as well as the [Tabular Data Package Schema](http://specs.frictionlessdata.io/tabular-data-package/), and the [Fiscal Data Package Schema](http://fiscal.dataprotocols.org/spec/). These can be referred to via an identifier, expressed as a symbol.

```ruby
package = DataPackage::Package.new(nil, :tabular) # Or :fiscal
```

### Schemas from elsewhere

If you have a schema stored in an alternative registry, you can pass a `registry_url` option to the initializer.

```ruby
package = DataPackage::Package.new(nil, :identifier, {registry_url: 'http://example.org/my-registry.csv'} )
```

## Developer notes

These notes are intended to help people that want to contribute to this package itself. If you just want to use it, you can safely ignore them.

### Updating the local schemas cache

We cache the schemas from https://github.com/dataprotocols/schemas using git-subtree. To update it, use:

```
  git subtree pull --prefix datapackage/schemas https://github.com/dataprotocols/schemas.git master --squash
```
