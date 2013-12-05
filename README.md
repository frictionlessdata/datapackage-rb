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

Or:

	sudo gem install datapackage

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

### Validating a Package

Quickly checking the validity of a package can be achieve as follows:

    package.valid?
    
To expose more detail on errors and warnings:

    messages = package.validate() # or package.validate(:datapackage)

This returns an object with two keys: `:errors` and `:warnings`. These are arrays of messages.

Warnings might include notes on missing metadata elements (e.g. package `licenses`) which are not required by the DataPackage specification 
but which SHOULD be included.

It is possible to treat all warnings as errors by performing strict validation:

    package.valid?(true)

Warnings are currently generated for:

* Missing `README.md` files from packages
* Missing `licenses` key from `datapackage.json`
* Missing `datapackage_version` key from `datapackage.json`

### Selecting a Validation Profile

The library contains two validation classes, one for the core Data Package specification and the other for the Simple Data Format 
rules. By default the library uses the more liberal Data Package rules.

The required profile can be specified in one of two ways. Either as a parameter to the validation methods:

    package.valid?(:datapackage)
    package.valid?(:simpledataformat)
    package.validate(:datapackage)
    package.validate(:simpledataformat)

Or, by using a `DataPackage::Validation` class:

    validator = DataPackage::SimpleDataFormatValidator.new
    validator.valid?( package )
    validator.validate( package )

### Approach to Validation

The library will support validating packages against the general rules specified in the 
[DataPackage specification](http://dataprotocols.org/data-packages/) as well as the stricter requirements given in the 
[Simple Data Format specification](http://dataprotocols.org/simple-data-format/) (SDF). 
 
SDF is essentially a profile of DataPackage which includes some additional restrictions on 
how data should be published and described. For example all data is to be published as CSV files.

The validation in the library is divided into two parts:

* Metadata validation -- checking that the structure of the `datapackage.json` file is correcgt
* Integrity checking -- checking that the overall package and data files appear to be in order

#### Metadata Validation

The basic structure of `datapackage.json` files are validated using [JSON Schema](http://json-schema.org/). This provides a simple 
declarative way to describe the expected structure of the package metadata. 

The schema files can be found in the `etc` directory of the project and could be used in other applications. The schema files can 
be customised to support local validation checks (see below).

#### Integrity Checking

While the metadata for a package might be correct, there are other ways in which the package could be invalid. For example, 
data files might be missing or incorrectly described.

The metadata validation is therefore supplemented with some custom code that performs some other checks:

* (Both profiles) All resources described in the package must be accessible, e.g. the local file exists or a URL responds successfully to a `HEAD`
* (`:simpledataformat`) All resources must be CSV files
* (`:simpledataformat`) All resources must have a valid JSON Table Schema
* (`:simpledataformat`) CSV `dialect` descriptions must be valid
* (`:simpledataformat`) All fields declared in the schema must be present in the CSV file
* (`:simpledataformat`) All fields present in the CSV file must be present in the schema

### Customising the Validation Code

The library provides several extension points for customising the way that packages are validated.

#### Supplying Custom JSON Schemas

Custom JSON schemas can be provided to allow validation to be tweaked for local conventions. An options hash can be 
provided to the constructor of a `DataPackage::Validator` object, this can be used to map schema names to custom 
schemas.

(Any options passed to the constructor of a `DataPackage::Package` object will also be passed to its validator)
  
For example to create a new validation profile called `my-validation-rules` and then apply it:

    opts = {
        :schema => {
            :my-validation-rules => "/path/to/json/schema.json"
        }
    }
    package = DataPackage::Package.new( url )
    package.valid?(:my-validation-rules)

This will cause the code to create a custom `DataPackage::Validator` instance that will apply the supplied schema. This class 
does not provide any integrity checks.

To mix a custom schema with the existing integrity checking, you must manually create a `Validator` instance. E.g:

    opts = {
        :schema => {
            :my-validation-rules => "/path/to/json/schema.json"
        }
    }
    validator = DataPackage::SimpleDataFormatValidator(:my-validation-rules, opts)
    validator.valid?( package )

Custom schemas must be valid JSON files that conforms to the JSON Schema v4 specification. The absolute path to the schema file must be 
provided.

Validation is performed using the [json-schema](https://github.com/hoxworth/json-schema) gem which has some documented restrictions.
     
The built-in schema files can also be overridden in this way, e.g. by specifying an alternate location for the `:datapackage` schema.

#### Custom Integrity Checking

Integrity checking can be customized by creating new sub-classes of `DataPackage::Validator` or one of the existing sub-classes. 

The following methods can be implemented:

* `validate_metadata(package, messages)` -- perform additional metadata checking after JSON schema is provided.
* `validate_resource(package, resource, messages)` -- called for each resource in the package
