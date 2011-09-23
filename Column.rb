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

=begin
require "yaml"
config = YAML::load_file(File.dirname(__FILE__) + '/config.yml')
tables = config.map do |table, info|
  t = TestDataGenerator::Table.new table, info['rows']

  info['columns'].each do |c, col_def|
    case c
    when 'id'
      t.add c, :id
    when 'created_at'
      t.add c, :datetime
    when 'updated_at'
      if info['columns']['created_at']
        t.add c, :datetime, :greater_than => [t.to_sym, :created_at]
      else
        t.add c, :datetime
      end
    else
      unless col_def
        raise "No config info for #{t}.#{c}"
      end

      # if just a scalar, assume it is the column type
      if col_def.is_a? String
        t.add c, col_def.to_sym
      else
        unique       = col_def.delete 'unique'
        greater_than = col_def.delete 'greater_than'

        # only one entry can be left, or else the file is invalid
        if col_def.size == 1
          type, args = col_def.first
          args ||= []

          if args.is_a? Array
            t.add c, type.to_sym, *args
          else
            t.add c, type.to_sym, args
          end
        else
          raise "Unknown column info: " + col_def.keys.to_s
        end
      end
    end
  end

  t
end
=end

a = TestDataGenerator::Table.new 'authors', 3, [
  [:id],
  [:first_name, :forgery, [:name, :first_name]],
  [:last_name,  :forgery, [:name, :last_name]],
  [:email,      :forgery, [:email, :address], :unique => true],
  [:created_at],
  [:updated_at, :datetime, :greater_than => [:authors, :created_at]]
]

b = TestDataGenerator::Table.new 'books', 3, [
  [:id],
  [:author_id, :belongs_to, [:authors, :id]],
  [:title,     :words, 2..4],
  [:isbn,      :string, :length => 20]
]

c = TestDataGenerator::Table.new 'phone_numbers', 3, [
  [:author_id, :belongs_to, [:authors, :id], :unique => true],
  [:number,     :string, :length => 10, :chars => ('0'..'9')]
]

[a,b,c].each { |t| t.each_row { |row| p row } }

