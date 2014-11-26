require_relative 'Table'
require_relative 'weighted_picker'
require_relative 'directed_graph'
require_relative 'util'

module TestDataGenerator
  # represents an entire database worth of data
  # acts as a Mediator between different Tables and Columns
  class Database
    attr_reader :name, :data

    # @param name [String]
    # @param table_limits [Hash{Table => Integer}]
    #   Tables with the total number of entries to be generated for them
    def initialize(name, table_limits)
      @name = name
      @tables = {}
      @limits = {}

      table_limits.each do |table, limit|
        @tables[table.name] = table
        @limits[table.name] = limit
      end

      reset!

      # allows dependent Columns to query the data they need
      # without allowing them access to the full Database
      @column_data = ColumnData.new @data

      if dependency_graph.has_cycles?
        raise(ArgumentError, 'tables have circular dependencies')
      end

      create_thresholds
    end

    def generate!
      # pick table at random (weighted odds), and return what it generates
      @table_picker.fmap(&:pick).fmap do |table|
        fulfill_needs table

        @tables[table].generate.each do |column, value|
          @data[table][column] << value
        end

        if space_left(table) <= 0
          @limits.delete table
          create_thresholds
        end
      end
    end

    def generate_all!
      until generate!.nothing?; end
    end

    def reset!
      @data = {}

      @tables.each do |t_name, table|
        @data[t_name] = {}
        table.column_names.each do |c_name|
          @data[t_name][c_name] = []
        end
      end
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

    def fulfill_needs(table)
      t = @tables[table]

      t.needs(@column_data).each do |source, num|
        # If row cannot be created, needs are unfulfillable, so bail
        if space_left(table) < num
          raise(RuntimeError, "Unable to fulfill requirements for " +
            "#{source.name} due to dependency from #{table}")
        end

        num.times do
          @tables[source].generate
        end
      end
    end

    def space_left(table)
      @limits[table] - row_count(table)
    end

    def create_thresholds
      @table_picker =
        if @limits.empty?
          Maybe.nothing
        else
          Maybe.just(WeigtedPicker.new @limits)
        end
    end

    def row_count(table)
      @data[table].first[1].length || 0
    end
  end
end

