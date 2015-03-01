require 'forwardable'

require_relative 'data_generators'
require_relative 'table'
require_relative 'dependency'

module TestDataGenerator
  class Column
    include Generator
    extend Forwardable

    attr_reader :name, :data

    def_delegators(:@generator, :dependencies, :needs)

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

    def generate!(db = nil)
      datum = @generator.generate(db)
      @data << datum
      datum
    end
  end
end

