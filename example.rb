require_relative 'test-data-generator'

a = TestDataGenerator::from_config({
  authors: [5, [
    [:id],
    [:first_name, :forgery, [:name, :first_name]],
    [:last_name,  :forgery, [:name, :last_name]],
    [:email,      :forgery, [:email, :address], :unique => true],
    [:created_at],
    [:updated_at, :datetime, [:greater_than => [:authors, :created_at]]]
  ]],

  books: [10, [
    [:id],
    [:author_id, :belongs_to, [:authors, :id]],
    [:title,     :words,      [2..4]],
    [:isbn,      :string,     [:length => 20]]
  ]],

  phone_numbers: [4, [
    [:author_id, :belongs_to, [:authors, :id], :unique => true],
    [:number,    :string,     [:length => 10, :chars => ('0'..'9')]]
  ]]
})

a.generate_all!
a.table_names.each do |table|
  cols = a.column_names(table)

  puts table
  puts cols.join("\t")

  a.each_row(table) do |row|
    cols.each do |col|
      print(row[col].to_s + "\t")
    end
    puts
  end

  puts
end

