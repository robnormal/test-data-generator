require_relative "util"
require_relative 'weighted_picker'

module TestDataGenerator
  class Database
    # @param [Database]
    def initialize(tables_limits = {})
      @tables = {}
      @limits = {}
      add_tables! tables_limits
    end

    def table_names
      @tables.keys
    end

    def retrieve(table, column)
      @tables[table].retrieve(column)
    end

    def current(table, column)
      retrieve(table, column).last
    end

    def retrieve_by_id(column_id)
      retrieve(column_id.table, column_id.column)
    end

    def column_names(table)
      @tables[table].columns
    end

    def height(table)
      @tables[table].height
    end

    def add_table!(table, limit)
      add_table_raw!(table, limit)
      update_table_data!
    end

    def generate!
      pick_table.fmap do |table|
        generate_row! table
      end
    end

    def generate_all!
      until generate!.nothing?; end
    end

    def reset!
      @tables.each do |name, table|
        table.reset!
      end
    end

    # yield successive rows to block, and delete the row
    def each_row(table, &blk)
      @tables[table].each(&blk)
    end

    def dump
      fmap(@tables) do |t|
        rows = []

        each_row(t.name) do |row|
          rows << row
        end

        rows
      end
    end

    def fulfill_need!(source_id, num, target)
      require_space(source_id.table, num, target)
      @tables[source_id.table].fulfill_need!(source_id.column, num, self)
    end


    private


    def add_tables!(tables_limits)
      tables_limits.each do |table, limit|
        add_table_raw!(table, limit)
      end
      update_table_data!
    end

    def space_left(table)
      (@limits[table] || 0) - height(table)
    end

    def dependency_graph
      if @dep_graph.nil?
        @dep_graph = DirectedGraph.new(
          list_bind(@tables) { |_, t| t.dependencies_as_edges }
        )
      end

      @dep_graph
    end

    def check_dependencies
      if dependency_graph.has_cycles?
        raise(ArgumentError, 'tables have circular dependencies')
      end
    end

    def add_table_raw!(table, limit)
      @tables[table.name] = table
      @limits[table.name] = limit
    end

    def update_table_data!
      check_dependencies
      create_thresholds!
      reset!
    end

    def require_space(source, num, target)
      if space_left(source) < num
        raise(RuntimeError, "Unable to fulfill requirements for " +
          "#{target} due to dependency on #{table}")
      end
    end

    def create_thresholds!
      @table_picker =
        if @limits.empty?
          Maybe.nothing
        else
          Maybe.just(WeigtedPicker.new @limits)
        end
    end

    def generate_row!(table)
      @tables[table].generate!(self)
      check_space!(table);
    end

    def check_space!(table)
      if space_left(table) <= 0
        @limits.delete table
        create_thresholds!
      end
    end

    # pick table at random (weighted odds)
    def pick_table
      @table_picker.fmap(&:pick)
    end

  end
end
