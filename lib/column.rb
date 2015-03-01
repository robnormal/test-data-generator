require 'forwardable'

require_relative 'data_generators'
require_relative 'table'
require_relative 'dependency'

module TestDataGenerator
  class Column
    include Generator
    extend Forwardable

    attr_reader :name, :data

    def_delegators(:@generator, :generate, :dependencies, :needs)

    # [name] name of this column
    # [generator] Generator used by this Column
    def initialize(name, generator)
      @generator = generator
      @name = name.to_sym
      reset!
    end

    def reset!
      @data = []
    end

    def generate(db = nil)
      datum = @generator.generate(db)
      @data << datum
      datum
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

