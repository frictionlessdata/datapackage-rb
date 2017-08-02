# DataPackage.rb

[![Travis](https://travis-ci.org/frictionlessdata/datapackage-rb.svg?branch=master)](https://travis-ci.org/frictionlessdata/datapackage-rb)
[![Coveralls](http://img.shields.io/coveralls/frictionlessdata/datapackage-rb.svg?branch=master)](https://coveralls.io/r/frictionlessdata/datapackage-rb?branch=master)
[![Gem Version](http://img.shields.io/gem/v/datapackage.svg)](https://rubygems.org/gems/datapackage)
[![SemVer](https://img.shields.io/badge/versions-SemVer-brightgreen.svg)](http://semver.org/)
[![Gitter](https://img.shields.io/gitter/room/frictionlessdata/chat.svg)](https://gitter.im/frictionlessdata/chat)

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
require 'datapackage'
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

## Reading a Data Package and its resources

```ruby
require 'datapackage'

dp = DataPackage::Package.new('http://data.okfn.org/data/core/gdp/datapackage.json')

data = CSV.parse(dp.resources[0].data, headers: true)
brazil_gdp = data.select { |r| r["Country Code"] == "BRA" }.
                  map { |row| { year: Integer(row["Year"]), value: Float(row['Value']) } }

max_gdp = brazil_gdp.max_by { |r| r[:value] }
min_gdp = brazil_gdp.min_by { |r| r[:value] }

percentual_increase = (max_gdp[:value] / min_gdp[:value]).round(2)
max_gdp_val = max_gdp[:value].to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse

msg =  "The highest Brazilian GDP occured in #{max_gdp[:year]}, when it peaked at US$ " +
"#{max_gdp_val}. This was #{percentual_increase}% more than its minumum GDP " +
"in #{min_gdp[:year]}"

print msg

# The highest Brazilian GDP occured in 2011, when it peaked at US$ 2,615,189,973,181. This was 172.44% more than its minimum GDP in 1960.
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

## Validating a Data Package

Data Package descriptors can be validated against a [JSON schema](https://tools.ietf.org/html/draft-zyp-json-schema-04) that we call `profile`.

By default, the gem uses the standard [Data Package profile](http://specs.frictionlessdata.io/schemas/data-package.json), but alternative profiles are available.

```ruby
package = DataPackage::Package.new('http://data.okfn.org/data/core/gdp/datapackage.json')

package.valid?
#=> true
package.errors
#=> [] # An array of errors
```

## Using a different profile

According to the [specs](https://specs.frictionlessdata.io/profiles/) the value of
the `profile` property can be either a URL or an indentifier from [the registry](https://specs.frictionlessdata.io/schemas/registry.json).

### Profiles in the local cache

The profiles from the registry come bundled with the gem. You can reference them in your DataPackage descriptor by their identifier in [the registry](https://specs.frictionlessdata.io/schemas/registry.json):

    - `tabular-data-package` for a [Tabular Data Package](http://specs.frictionlessdata.io/tabular-data-package/)
    - `fiscal-data-package` for a [Fiscal Data Package](http://fiscal.dataprotocols.org/spec/)

```ruby
{
  "profile": "tabular-data-package" #or "fiscal-data-package"
}
```

### Profiles from elsewhere

If you have a custom profile schema you can reference it by its URL

```ruby
{
  "profile": "https://specs.frictionlessdata.io/schemas/tabular-data-package.json"
}
```

## Developer notes

These notes are intended to help people that want to contribute to this package itself. If you just want to use it, you can safely ignore them.

After checking out the repo, run `bundle` to install dependencies. Then, run `rake spec` to run the tests.

To install this gem onto your local machine, run `bundle exec rake install`.
To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`,
which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

### Updating the local schemas cache

We cache the local schemas from https://specs.frictionlessdata.io/schemas/registry.json.
The local schemas should be kept up to date with the remote ones using:

```
rake update_profiles
```
