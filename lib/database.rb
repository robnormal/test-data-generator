require_relative 'Table'
require_relative 'weighted_picker'
require_relative 'directed_graph'
require_relative 'util'

module TestDataGenerator
  class Database
    attr_reader :name, :data

    # @param name [String]
    # @param table_limits [Hash{Table => Integer}]
    #   Tables with the total number of entries to be generated for them
    def initialize(name, table_limits)
      @name = name
      @tables = {}
      @limits = {}
      @data = {}

      table_limits.each do |table, limit|
        @tables[table.name] = table
        @limits[table.name] = limit
        @data[table.name] = []
      end

      if dependency_graph.has_cycles?
        raise(ArgumentError, 'tables have circular dependencies')
      end

      create_thresholds
    end

    def generate!
      # pick table at random (weighted odds), and return what it generates
      @table_picker.fmap(&:pick).fmap do |table|
        fulfill_needs table
        row table
      end
    end

    def generate_all!
      until generate!.nothing?; end
    end

    def data_for(column_id)
      @data[column_id.table] && @data[column_id.table][column_id.column_id]
    end


    private

    def dependency_graph
      if @dep_graph.nil?
        @dep_graph = DirectedGraph.new(
          @tables.map { |k, table| table.dependencies_as_edges }.flatten
        )
      end

      @dep_graph
    end

    def row(table)
      store_rows(table, @tables[table].generate)
    end

    def store_rows(table, rows)
      @data[table] += rows
      still_has_space table
    end

    def fulfill_needs(table)
      t = @tables[table]

      t.needs(@data).each do |source, num|
        # If row cannot be created, needs are unfulfillable, so bail
        if space_left(table) < num
          raise(RuntimeError, "Unable to fulfill requirements for " +
            "#{source.name} due to dependency from #{table}")
        end

        store_rows(table, t.iterate(num))
      end
    end

    def space_left(table)
      @limits[table] - @data[table].length
    end

    def create_thresholds
      if @limits.empty?
        @table_picker = Maybe.nothing
      else
        @table_picker = Maybe.just WeigtedPicker.new(@limits)
      end
    end

    # stop generating rows if table is full
    def still_has_space(table)
      if @data[table].length >= @limits[table]
        @limits.delete table
        create_thresholds

        false
      else
        true
      end
    end

  end
end

