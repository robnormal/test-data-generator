require 'forgery'
require(File.dirname(__FILE__) + '/Generator.rb')
require(File.dirname(__FILE__) + '/Table.rb')

module TestDataGenerator
  def zipall as
    if as.size > 0
      as.first.zip(as[1..-1])
    else
      []
    end
  end

  class Column
    attr_reader :name, :last, :table

    def initialize table, name, generator, options = nil
      @table   = table
      @name    = name
      @options = options
      @values_produced = 0

      if generator.is_a? Generator
        @generator = generator
      else
        raise ArgumentError, "Argument 3 for Column.new must be a Generator"
      end
    end

    def generate_one
      if being_selected_from?
        @last = @data[@values_produced]
      else
        @last = @generator.take(1).first
      end

      @values_produced += 1
      @last
    end

    def current
      generate_one until @values_produced == @table.rows_produced
      @last
    end

    def all
      if being_selected_from?
        @data
      else
        raise "Column::all() called on uncached column #{@table.name}.#{@name}"
      end
    end

    private
    @table
    @name
    @values_produced
    @generator
    @options
    @last

    @being_selected_from
    @data

    def generate_all
      count = @table.num_rows
      data = @generator.take count
      data
    end

    def being_selected_from?
      # only run on first call
      if @being_selected_from == nil
        @being_selected_from = @table.need_all? self

        if @being_selected_from
          @data = generate_all
          @data.freeze
          @values_produced = 0
        end
      end

      @being_selected_from
    end

  end
end

a = TestDataGenerator::Table.new 'authors', 30
a.add 'id',         :id
a.add 'first_name', :forgery, [:name, :first_name]
a.add 'last_name',  :forgery, [:name, :last_name]
a.add 'email',      :forgery, [:email, :address], :unique => true
a.add 'created_at', :datetime
a.add 'updated_at', :datetime, :greater_than => [:authors, :created_at]

b = TestDataGenerator::Table.new 'books', 30
b.add 'id',        :id
b.add 'author_id', :belongs_to, [:authors, :id]
b.add 'title',     :words, 2..4
b.add 'isbn',      :string, :length => 20

c = TestDataGenerator::Table.new 'phone_numbers', 30
c.add 'author_id', :belongs_to, [:authors, :id], :unique => true
c.add 'number', :string, :length => 10, :chars => ('0'..'9')

[a,b,c].each { |t| t.each_row { |row| p row } }

