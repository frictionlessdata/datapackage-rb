This directory contains some JSON Schema documents for validating:

* `datapackage-schema.json` -- [datapackage.json](http://dataprotocols.org/data-packages/) package files
* `jsontable-schema.json` -- [JSON Table Schemas](http://dataprotocols.org/json-table-schema/) objects
* `csvddf-dialect-schema.json` -- [CSV Dialect Description Format](http://dataprotocols.org/csv-dialect/) dialect objects

The JSON Table Schemas and CSV Dialect Description Format both define JSON object structures that can appear in `datapackage.json` files (via the `schema` and `dialect` keywords). In the main `datapackage-schema.json` object, these keywords are only validated as simple objects. 

In the application the subsidiary schemas are automatically applied to relevant keys. This could be improved by using JSON Schema cross-referencing.

Other potential improvements include:

* Add `data` keyword validation to `datapackage-schema.json`
* Add `format` keywords for validating email addresses and date/date-times
* Or, add `pattern` for validating dates
* Improve regexs used in various places


