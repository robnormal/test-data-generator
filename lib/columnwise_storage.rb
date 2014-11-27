require_relative "util"

module TestDataGenerator
  class ColumnwiseStorage
    # @param [Hash{ Object => Hash{ Object => Array } }]
    def initialize(categories)
      @categories = categories
      reset!
    end

    def retrieve(cat, subcat)
      check_category(cat)

      @data[cat][subcat] || []
    end

    def append_row!(category, row)
      check_category(category)

      row.each do |cat2, data|
        @data[category][cat2] ||= []
        @data[category][cat2] << data
      end
    end

    def reset!
      @data = {}
      @categories.each do |cat|
        @data[cat] = {}
      end
    end

    # yield successive rows to block, and delete the row
    def offload!(category)
      check_category(category)

      columns = @data[category].values
      len = columns.first.length # height of data

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
      @data[category].first[1].length
    end

    private

    def check_category(cat)
      if @data[cat].nil?
        raise(ArgumentError, "No such category: #{cat}")
      end
    end
  end
end

