require 'forwardable'

require_relative 'data_generators'
require_relative 'table'
require_relative 'dependency'

module TestDataGenerator
  class Column
    include Generator
    extend Forwardable

    attr_reader :name

    def_delegators(:@generator, :generate, :dependencies, :needs)

    # [name] name of this column
    # [generator] Generator used by this Column
    def initialize(name, generator)
      @generator = generator
      @name = name.to_sym
    end

    # [table] Table this Column will belong to
    # [name] name to give to the Column
    # [type] Symbol designating Column type
    # [args] Additional arguments, depending on type
    def self.from_spec(name, type = nil, args = [], options = {})
      # unfortunately, passing explicit nil will override defaults, so...
      args ||= []
      options ||= {}

      name = name.to_sym

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
      when :enum
        generator = EnumGenerator.new(*args)
      when :bool, :boolean
        generator = NumberGenerator.new(min: 0, max: 1)
      when :belongs_to
        generator = BelongsToGenerator.new(options[:db], ColumnId.new(*args))
      when :id
        # id should be unique integer
        options[:unique] = true
        generator = NumberGenerator.new(min: 1, max: 2147483647)
      else
        raise ArgumentError, "Unknown generator type: #{type}"
      end

      if options[:unique]
        generator = generator.to_unique
      end

      # null must come after unique, since NULL is not a "unique" value
      if options[:null]
        generator = NullGenerator.new(generator, options[:null])
      end

      Column.new(name.to_sym, generator)
    end
  end

  # Database object will turn this into
  class DependentColumnStub
    attr_reader :name, :dependencies

    def initialize(name, generator_type, column_names, generator_options = {})
      @name = name
      @gen = generator_type
      @dependencies = column_names
      @gen_options = generator_options
    end

    # @param accumulator [Accumulator] Accumulates column(s) this column depends on
    def resolve(tables)
      Column.new(@name, @type.new(accumulator, options))
    end
  end
end

