# Ruby♥︎Db
This is an object relational mapping written in Ruby that has some of the fine aspects of Rails' ActiveRecord.

It could be used in tandem with a Rails-like framework to act as the back-end for a web application.  Or just for your own amusement.

## How to use Ruby♥︎Db
Naturally, one needs Ruby to run the project.  [Here](https://www.ruby-lang.org/en/) is a good place to start for instructions on putting ruby on your machine and general Ruby information.

If you already have the deep, deep Ruby knowledge, you can try out Ruby♥︎Db in a REPL like irb or [pry](http://pryrepl.org/).  Simply download the repository and go to town:

    $ bundle install
    $ pry
    > load 'demo.db'

The demo has `Cat`, `Human`, and `House` classes, all inheriting from `HeartObject`.

## HeartObject
This is the core of the system.  `HeartObject` has available the following methods:

- Class methods
  - `::all`
  - `::find(id)`

- Instance methods
  - `#attributes`
  - `#save` which accesses `#insert` or `#update` depending on whether the record is already in the database.

## Searchable
This module extends `HeartObject` with the `::where` class method, which takes a hash with the form `{attribute_name: attribute_value}`.

## Associatable
This module adds associations:
- `#belongs_to`
- `#has_many`
- `#has_one_through`
allowing one to call, say `random_human.cats` and receive an array of all of the cats belonging to `random_human`.

## Future additions
In the spirit of making this thing more interesting, I would like to add:
- [ ] `::first` and `::last`
- [ ] Lazy, stackable `#where` so that it doesn't query the database until necessary (lazy is a _good_ thing in this case).
- [ ] `includes` for prefetching associated data to reduce db queries.
- [ ] `has_many :through` associations.
- [ ] data validations.
