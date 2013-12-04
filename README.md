# DataPackage.rb

A ruby library for working with [Data Packages](http://dataprotocols.org/data-packages/).

[![Build Status](http://jenkins.theodi.org/job/datapackage.rb-master/badge/icon)](http://jenkins.theodi.org/job/datapackage.rb-master/)
[![Code Climate](https://codeclimate.com/github/theodi/datapackage.rb.png)](https://codeclimate.com/github/theodi/datapackage.rb)
[![Dependency Status](https://gemnasium.com/theodi/datapackage.rb.png)](https://gemnasium.com/theodi/datapackage.rb)

The library is intending to support:

* Parsing and using data package metadata and data
* Validating data packages to ensure they conform with the Data Package specification

## Installation

Add the gem into your Gemfile:

        gem 'datapackage.rb', :git => "git://github.com/theodi/datapackage.rb.git"

Note: gem release to come

## Basic Usage

Require the gem, if you need to:

    require 'datapackage.rb'

Parsing a datapackage from a remote location:

    package = DataPackage::Package.new( "http://example.org/datasets/a" )
    
This assumes that `http://example.org/datasets/a/datapackage.json` exists, or specifically load a JSON file:

    package = DataPackage::Package.new( "http://example.org/datasets/a/datapackage.json" )
    
Similarly you can load a package from a local JSON file, or specify a directory:

    package = DataPackage::Package.new( "/my/data/package" )
    package = DataPackage::Package.new( "/my/data/package/datapackage.json" )
    
There are a set of helper methods for accessing data from the package, e.g:

    package = DataPackage::Package.new( "/my/data/package" )
    package.name
    package.title
    package.licenses
    package.resources
    
These currently just return the raw JSON structure, but this might change in future.

## Package Validation

The library supports validating packages. It can be used to validate both the metadata for the package (`datapackage.json`) 
and the integrity of the package itself, e.g. whether the data files exist.

### Approach to Validation

The library will support validating packages against the general rules specified in the 
[DataPackage specification](http://dataprotocols.org/data-packages/) as well as the stricter requirements given in the 
[Simple Data Format specification](http://dataprotocols.org/simple-data-format/) (SDF). 

SDF is essentially a profile of 
DataPackage which includes some additional restrictions on how data should be published and described.

The validation is divided into two parts

* The basic structure of the `datapackage.json` file is validated using [JSON Schema](http://json-schema.org/). This provides 
some basic checks for required fields, expected values for patterns, etc. These schema files can be found in the `etc` directory 
and could be used in other applications.
* Some additional integrity checks are carried out to ensure that, e.g. all referenced files actually exist and conform to their 
documented schema(s)

### Validating a Package

The following will give a boolean response as to whether a package is valid:

    package.valid?
    
A specific profile can be specified:

    package.valid?(:datapackage) #or package.valid?(:simpledataformat)

### Validation Details
    
Validation results are divided into errors and warnings. It is an error if a package references a resource that 
doesn't exist. Both the `path` and `url` properties of the resource will be checked. For remote resources a `HEAD` 
request will be carried out.

Warnings are currently generated for:

* Missing `README.md` files from packages
* Missing `licenses` key from `datapackage.json`
* Missing `datapackage_version` key from `datapackage.json`

Strict mode can be enabled which will then treat all warnings as errors:

    package.valid(:datapackage, true)         

To expose more detail on errors and warnings:

    messages = package.validate() # or package.validate(:datapackage)

This returns an object with two keys: `:errors` and `:warnings`. These are arrays of messages.

TODO: improve structure of messages

### Custom Validation Schemas

Custom JSON schemas can be provided to allow validation to be tweaked for local conventions. An options hash can be 
provided to the constructor of a `DataPackage::Package` object, this can be used to map validation profiles to custom 
schemas.

For example to create a new validation profile called `my-validation-rules` and then apply it:

    opts = {
        :schema => {
            :my-validation-rules => "/path/to/json/schema.json"
        }
    }
    package = DataPackage::Package.new( url )
    package.valid?(:my-validation-rules)

The provided schema should be a valid JSON file that conforms to the JSON Schema v4 specification. Validation is performed using the [json-schema](https://github.com/hoxworth/json-schema) gem 
which has some documented restrictions.
     
The built-in schema files can also be overridden in this way, e.g. by specifying an alternate location for the `:datapackage` schema.

Currently there is no way to override the integrity checks, to check for missing resources.
