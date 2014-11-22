require_relative('lib/Table.rb')
require_relative('lib/Column.rb')

a = TestDataGenerator::Table.new 'authors', 3, [
  [:id],
  [:first_name, :forgery, [:name, :first_name]],
  [:last_name,  :forgery, [:name, :last_name]],
  [:email,      :forgery, [:email, :address], :unique => true],
  [:created_at],
  [:updated_at, :datetime, [:greater_than => [:authors, :created_at]]]
]

b = TestDataGenerator::Table.new 'books', 3, [
  [:id],
  [:author_id, :belongs_to, [:authors, :id]],
  [:title,     :words,      [2..4]],
  [:isbn,      :string,     [:length => 20]]
]

c = TestDataGenerator::Table.new 'phone_numbers', 3, [
  [:author_id, :belongs_to, [:authors, :id], :unique => true],
  [:number,    :string,     [:length => 10, :chars => ('0'..'9')]]
]

[a,b,c].each { |t| t.each { |row| p row } }

