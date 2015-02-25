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

    def dependency_edges(my_table)
      my_id = ColumnId.new(my_table, name)

      dependencies.map { |col_id|
        GraphEdge.new(my_id, col_id)
      }
    end
  end
end

