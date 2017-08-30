# datapackage-rb

[![Travis](https://travis-ci.org/frictionlessdata/datapackage-rb.svg?branch=master)](https://travis-ci.org/frictionlessdata/datapackage-rb)
[![Coveralls](http://img.shields.io/coveralls/frictionlessdata/datapackage-rb.svg?branch=master)](https://coveralls.io/r/frictionlessdata/datapackage-rb?branch=master)
[![Gem Version](http://img.shields.io/gem/v/datapackage.svg)](https://rubygems.org/gems/datapackage)
[![SemVer](https://img.shields.io/badge/versions-SemVer-brightgreen.svg)](http://semver.org/)
[![Gitter](https://img.shields.io/gitter/room/frictionlessdata/chat.svg)](https://gitter.im/frictionlessdata/chat)

A ruby library for working with [Data Packages](https://specs.frictionlessdata.io/data-package/).

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

Parsing a data package descriptor from a remote location:

```ruby
package = DataPackage::Package.new( "http://example.org/datasets/a/datapackage.json" )
```

This assumes that `http://example.org/datasets/a/datapackage.json` exists.
Similarly you can load a package descriptor from a local JSON file.

```ruby
package = DataPackage::Package.new( "/my/data/package/datapackage.json" )
```

The data package descriptor
i.e. `datapackage.json` file, is expected to be at the _root_ directory
of the data package and the `path` attribute of the package's `resources` will be resolved
relative to it.

You can also load a data package descriptor directly from a Hash:

```ruby
 descriptor = {
  'resources'=> [
    {
      'name'=> 'example',
      'profile'=> 'tabular-data-resource',
      'data'=> [
        ['height', 'age', 'name'],
        ['180', '18', 'Tony'],
        ['192', '32', 'Jacob'],
      ],
      'schema'=>  {
        'fields'=> [
          {'name'=> 'height', 'type'=> 'integer'},
          {'name'=> 'age', 'type'=> 'integer'},
          {'name'=> 'name', 'type'=> 'string'},
        ],
      }
    }
  ]
}

package = DataPackage::Package.new(descriptor)
```

There are a set of helper methods for accessing data from the package, e.g:

```ruby
package.name
package.title
package.description
package.homepage
package.license
```

## Reading Data Resources

A data package must contain an array of [Data Resources](https://specs.frictionlessdata.io/data-resource).
You can access the resources in your Data Package either by their name or by their index in the `resources` array:

```ruby
first_resource = package.resources[0]
first_resource = package.get_resource('example')

# Get info about the data source of this resource
first_resource.inline?
first_resource.local?
first_resource.remote?
first_resource.multipart?
first_resource.tabular?
first_resource.source
```

You can then read the source depending on its type. For example if resource is local and not multipart it could by open as a file: `File.open(resource.source)`.

If a resource complies with the [Tabular Data Resource spec](https://specs.frictionlessdata.io/tabular-data-resource/) or uses the
`tabular-data-resource` [profile](#profiles) you can read resource rows:

```ruby
resoure = package.resources[0]
resource.tabular?
resource.headers
resource.schema

# Read the the whole rows at once
data = resource.read
data = resource.read(keyed: true)

# Or iterate through it
data = resource.iter {|row| print row}
```

See [TableSchema](https://github.com/frictionlessdata/tableschema-rb) documentation for other things you can do with tabular resource.

## Creating a Data Package

```ruby
package = DataPackage::Package.new

# Add package properties
package.name = 'my_sleep_duration'

# Add a resource
package.add_resource(
  {
    'name'=> 'sleep_durations_this_week',
    'data'=> [7, 8, 5, 6, 9, 7, 8],
  }
)
```

If the resource is valid it will be added to the `resources` array of the Data Package;
if it's invalid it will not be added and you should try creating and [validating](#validating-a-resource) your resource to see why it fails.

```ruby
# Update a resource
my_resource = package.get_resource('sleep_durations_this_week')
my_resource['schema'] = {
  'fields'=> [
    {'name'=> 'number_hours', 'type'=> 'integer'},
  ]
}

# Save the Data Package descriptor to the target file
package.save('datapackage.json')

# Remove a resource
package.remove_resource('sleep_durations_this_week')
```

## Profiles

Data Package and Data Resource descriptors can be validated against  [JSON schemas](https://tools.ietf.org/html/draft-zyp-json-schema-04) that we call `profiles`.

By default, this gem uses the standard [Data Package profile](http://specs.frictionlessdata.io/schemas/data-package.json) and [Data Resource profile](http://specs.frictionlessdata.io/schemas/data-resource.json) but alternative profiles are available for both.

According to the [specs](https://specs.frictionlessdata.io/profiles/) the value of
the `profile` property can be either a URL or an indentifier from [the registry](https://specs.frictionlessdata.io/schemas/registry.json).

### Profiles in the local cache

The profiles from the registry come bundled with the gem. You can reference them in your Data Package descriptor by their identifier in [the registry](https://specs.frictionlessdata.io/schemas/registry.json):

- `data-package` the default profile for a [Data Package](https://specs.frictionlessdata.io/data-package/)
- `data-resource` the default profile for a [Data Resource](https://specs.frictionlessdata.io/data-resource)
- `tabular-data-package` for a [Tabular Data Package](http://specs.frictionlessdata.io/tabular-data-package/)
- `tabular-data-resource` for a [Tabular Data Resource](https://specs.frictionlessdata.io/tabular-data-resource/)
- `fiscal-data-package` for a [Fiscal Data Package](http://fiscal.dataprotocols.org/spec/)

```ruby
{
  "profile": "tabular-data-package"
}
```

### Profiles from elsewhere

If you have a custom profile schema you can reference it by its URL:

```ruby
{
  "profile": "https://specs.frictionlessdata.io/schemas/tabular-data-package.json"
}
```

## Validation

Data Resources and Data Packages are validated against their profiles to ensure they respect the expected structure.

### Validating a Resource

```ruby
descriptor = {
  'name'=> 'incorrect name',
  'path'=> 'https://cdn.rawgit.com/frictionlessdata/datapackage-rb/master/spec/fixtures/test-pkg/test.csv',
}
resource = DataPackage::Resource.new(descriptor, base_path='')

# Returns true if resource is valid, false otherwise
resource.valid?

# Returns true or raises DataPackage::ValidationError
resource.validate

# Iterate through validation errors
resource.iter_errors{ |err| p err}
```

### Validating a Package

The same methods used to check the validity of a Resource - `valid?`, `validate` and `iter_errors`- are also available for a Package.
The difference is that after a Package descriptor is validated against its `profile`, each of its `resources` are also validated against their `profile`.

In order for a Package to be valid all its Resources have to be valid.

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
