require_relative "util"
require_relative 'weighted_picker'

module TestDataGenerator
  class ColumnwiseStorage
    # @param [Database]
    def initialize(db, table_limits)
      @db = db
      @limits = table_limits
      @categories = table_limits.keys

      create_thresholds
      reset!
    end

    def retrieve(cat, subcat)
      check_category cat

      @data[cat][subcat] || []
    end

    def retrieve_by_id(column_id)
      retrieve(column_id.table, column_id.column)
    end

    def generate!
      # pick table at random (weighted odds), and return what it generates
      @table_picker.fmap(&:pick).fmap do |table|
        generate_for! table
      end
    end

    def generate_all!
      until generate!.nothing?; end
    end

    def reset!
      @data = {}
      @categories.each do |cat|
        @data[cat] = {}
      end
    end

    # yield successive rows to block, and delete the row
    def offload!(category)
      check_category category

      columns = @data[category].values
      len = columns.first ? columns.first.length : 0 # height of data

      len.times do
        yield columns.map(&:shift)
      end
    end

    def offload_all!
      output = {}
      fmap_with_keys(@data) { |cat, column|
        to_enum(:offload!, cat).to_a
      }
    end

    def height(category)
      check_category category

      @data[category].empty? ? 0 : @data[category].first[1].length
    end


    private


    def check_category(cat)
      if @data[cat].nil?
        raise(ArgumentError, "No such table: #{cat}")
      end
    end

    def generate_for!(table)
      check_category table
      fulfill_needs! table

      @db.generate_for(table).each do |col, data|
        @data[table][col] ||= []
        @data[table][col] << data
      end

      if space_left(table) <= 0
        @limits.delete table
        create_thresholds
      end
    end

    def fulfill_needs!(table)
      @db.needs_for(table, self).each do |source_id, num|
        # If row cannot be created, needs are unfulfillable, so bail
        if space_left(table) < num
          raise(RuntimeError, "Unable to fulfill requirements for " +
            "#{table} due to dependency on #{source_id.table}")
        end

        num.times do
          generate_for!(source_id.table)
        end
      end
    end

    def space_left(table)
      @limits[table] - height(table)
    end

    def create_thresholds
      @table_picker =
        if @limits.empty?
          Maybe.nothing
        else
          Maybe.just(WeigtedPicker.new @limits)
        end
    end
  end
end
