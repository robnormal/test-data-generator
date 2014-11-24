module TestDataGenerator
  module Generator
    # @return One generated value
    def generate; raise NotImplementedError end

    # @return [Array<Object>]
    def iterate(n)
      (1..n).collect { generate }
    end

    # @return [Array<ColumnId>]
    def dependencies
      []
    end

    # How much data do other columns need to generate before
    # we can generate one more datum?
    # Default implementation assumes we only need one row per
    # dependency
    #
    # @param Database
    #   Database containing data for depended-on columns
    # @return [Array<Array(ColumnId, Integer)>]
    def needs(database)
      needed = []
      dependencies.each { |d|
        if database.data_for(d).empty?
          needed << [d, 1]
        end
      }

      needed
    end

    def to_unique
      UniqueGenerator.new self
    end
  end
end

