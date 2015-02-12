# Intro

Creating a test database is a tedious task - you must not only produce
varied data, but you must also ensure that the data meets the constraints
of your database. TestDataGenerator was created to solve this problem.

TestDataGenerator is written in Ruby, and uses the 
[forgery](https://github.com/sevenwire/forgery) gem for some of
the data generation.

# Usage

```ruby
db = TestDataGenerator::from_config({
  authors: [3, [
    [:id],
    [:first_name, :forgery, [:name, :first_name]],
    [:last_name,  :forgery, [:name, :last_name]],
    [:email,      :forgery, [:email, :address], :unique => true],
    [:created_at],
    [:updated_at, :datetime, [:greater_than => [:authors, :created_at]]]
  ]],

  books: [3, [
    [:id],
    [:author_id, :belongs_to, [:authors, :id]],
    [:title,     :words,      [2..4]],
    [:isbn,      :string,     [:length => 20]]
  ]],

  phone_numbers: [3, [
    [:author_id, :belongs_to, [:authors, :id], :unique => true],
    [:number,    :string,     [:length => 10, :chars => ('0'..'9')]]
  ]]
})

db.generate_all!

data = db.offload_all!
```

