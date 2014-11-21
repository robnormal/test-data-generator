require 'forgery'
require(File.dirname(__FILE__) + '/Generator.rb')
require(File.dirname(__FILE__) + '/Column.rb')

module TestDataGenerator
  class Table
    include Enumerable

    attr_reader :name, :rows_produced, :num_rows

    def initialize(name, num_rows, col_config = {})
      @name          = name.to_sym
      @num_rows      = num_rows
      @rows_produced = 0
      @columns       = {}
      @data          = {}

      # register this table with the class
      @@tables[@name] = self

      col_config.each do |cfg|
        col_name = cfg.shift
        type     = cfg.shift
        args     = cfg

        add(col_name, type, *args)
      end
    end

    def add(column_name, type, *args)
      # name-based type magic
      case column_name
      when :id
        type = :id
      when /_at$/
        type = :datetime
      end

      case type
      when :string
        generator = StringGenerator.new(*args)
      when :datetime
        generator = DateTimeGenerator.new(*args)
      when :forgery
        generator = ForgeryGenerator.new(*args)
      when :words
        generator = WordGenerator.new(*args)
      when :url
        generator = UrlGenerator.new(*args)
      when :bool, :boolean
        generator = NumberGenerator.new(min: 0, max: 1)
      when :enum
        generator = EnumGenerator.new(enum_options args.last)
      when :id
        # id should be unique integer
        args << :unique
        generator = NumberGenerator.new(min: 1, max: 2147483647)
      when :belongs_to
        table   = args[0][0].to_sym
        column  = args[0][1].to_sym
        options = enum_options args[1]

        @@need_all << [table, column]

        generator = BelongsToGenerator.new(table, column, options)
      else
        raise ArgumentError, "Unknown generator type: #{type}"
      end

      if args.include?(:unique) and !generator.handles_unique?
        generator = UniqueGenerator.new(generator)
      end

      # null must come after unique, since NULL is not a "unique" value
      if args.include?(:null)
        generator = NullGenerator.new(generator)
      end

      optional_args = if args.last.is_a?(Hash) then args.last else {} end

      @columns[column_name.to_sym] = Column.new(
        self, column_name.to_sym, generator, optional_args
      )
    end

    def column(column_name)
      @columns[column_name]
    end

    def current(column_name)
      @columns[column_name].current
    end

    def all(column_name)
      @columns[column_name].all
    end

    def self.current(table_name, column_name)
      @@tables[table_name].current column_name
    end

    def self.all(table_name, column_name)
      @@tables[table_name].all column_name
    end

    def self.table(table_name)
      @@tables[table_name]
    end

    def need_all?(column)
      @@need_all.include? [@name, column.name]
    end

    def add_value(column_name, value)
      @data[column_name] ||= []
      @data[column_name] << value
    end

    def each
      @num_rows.times { yield row }
    end

    def row
      @rows_produced += 1
      @columns.values.map &:current
    end

    private
    @@tables = {}
    @@need_all = []

    @columns
    @num_rows
    @rows_produced
    @data

    def enum_options(options)
      options ||= {}

      if options[:unique]
        options[:max] = @num_rows
      end

      options
    end
  end
end

