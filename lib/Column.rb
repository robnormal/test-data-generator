require 'forgery'
require(File.dirname(__FILE__) + '/Generator.rb')
require(File.dirname(__FILE__) + '/Table.rb')

module TestDataGenerator
  class Column
    attr_reader :name, :table

    def initialize(table, name, generator, options = {})
      if generator.is_a? Generator
        if options[:null]
          @generator = NullGenerator.new generator
        else
          @generator = generator
        end
      else
        raise ArgumentError, "Argument 3 for Column.new must be a Generator"
      end

      @table   = table
      @name    = name.to_sym
      @options = options
      @values_produced = 0
    end

    def generate_one
      if being_selected_from?
        @last = @data[@values_produced]
      else
        @last = @generator.first
      end

      @values_produced += 1
      @last
    end

    def current
      generate_one until @values_produced >= @table.rows_produced

      if being_selected_from?
        @data[@table.rows_produced - 1]
      else
        @last
      end
    end

    def all
      if being_selected_from?
        @data
      else
        raise "Column::all() called on uncached column #{@table.name}.#{@name}"
      end
    end

    def self.from_spec(table, name, type, *args)
      # name-based type magic
      case name
      when :id
        type = :id
      when /_at$/
        type = :datetime
      end

      case type
      when :string
        generator = StringGenerator.new(*args)
      when :number
        generator = NumberGenerator.new(*args)
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
        generator = EnumGenerator.new(enum_options(table.num_rows, args.last))
      when :id
        # id should be unique integer
        args << :unique
        generator = NumberGenerator.new(min: 1, max: 2147483647)
      when :belongs_to
        foreign_table  = args[0][0].to_sym
        foreign_column = args[0][1].to_sym
        options        = enum_options(table.num_rows, args[1])

        generator = BelongsToGenerator.new(
          foreign_table, foreign_column, options
        )
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

      if type == :belongs_to
        ForeignColumn.new(table, name.to_sym, generator, optional_args)
      else
        Column.new(table, name.to_sym, generator, optional_args)
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

    def self.enum_options(num_rows, options)
      options ||= {}

      if options[:unique]
        options[:max] = num_rows
      end

      options
    end
  end

  class ForeignColumn < Column
    attr_reader :foreign_table, :foreign_column

    def initialize(table, name, generator, options = {})
      super
      @foreign_table = generator.table
      @foreign_column = generator.column
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

