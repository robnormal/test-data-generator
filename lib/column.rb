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
    def self.from_spec(name, type_sym = nil, args = [], options = {})
      name = name.to_sym
      type = spec_type(type_sym, name)
      generator = spec_generator(type, args)

      if type == :id
        # id should be unique integer
        options[:unique] = true
      end

      generator = use_spec_options(generator, options)

      Column.new(name.to_sym, generator)
    end

    def self.spec_type(type, name)
      # name-based type magic
      case name
      when :id
        :id
      when /_at$/
        :datetime
      else
        type
      end
    end

    def self.spec_generator(type, args)
      case type
      when :string
        StringGenerator.new(*args)
      when :number
        NumberGenerator.new(*args)
      when :datetime
        DateTimeGenerator.new(*args)
      when :forgery
        ForgeryGenerator.new(*args)
      when :words
        WordGenerator.new(*args)
      when :url
        UrlGenerator.new(*args)
      when :enum
        EnumGenerator.new(*args)
      when :bool, :boolean
        NumberGenerator.new(min: 0, max: 1)
      when :belongs_to
        BelongsToGenerator.new(ColumnId.new(*args))
      when :id
        NumberGenerator.new(min: 1, max: 2147483647)
      else
        raise ArgumentError, "Unknown generator type: #{type}"
      end
    end


    def self.use_spec_options(generator, opts)
      if opts[:unique]
        generator = generator.to_unique
      end

      # null must come after unique, since NULL is not a "unique" value
      if opts[:null]
        generator = NullGenerator.new(generator, opts[:null])
      end

      generator
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

