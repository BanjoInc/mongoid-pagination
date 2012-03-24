## What

Adds pagination scopes to your mongoid models.

## Usage

```ruby
class Person
  include Mongoid::Document
  include Mongoid::Pagination

  default_page_size 20
end

Person.paginate(:page => 2, :limit => 25) # limit and page
Person.paginate(:offset => 20, :limit => 25) # limit and offset
Person.per_page(25) # just does a limit
```
