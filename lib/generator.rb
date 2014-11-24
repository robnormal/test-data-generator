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

    # Defaults to UniqueByUsed strategy
    # @param options [Hash] Options for uniqueness strategy
    def to_unique(options = {})
      UniqueByUsedGenerator.new self
    end
  end

  # marker for generators guarenteed to return unique values
  module UniqueGenerator
    include Generator

    # whether we have any data left
    def empty?; raise NotImplementedError end

    # "forget" data that has been produced so far
    def reset!; raise NotImplementedError end

    # raise error - can't fulfill data request
    def runout
      raise(RuntimeError, 'no more unique values')
    end
  end

  # Decorator class - generates values until it gets to one it
  #   hasn't generated before
  class UniqueByUsedGenerator
    include UniqueGenerator

    # [gen] base Generator
    # [max] maximum number of unique values available
    def initialize(gen, max = nil)
      @generator = gen
      @used = {}
      @max = Maybe.maybe max
      reset!
    end

    def generate
      if @available.check { |x| x <= 0 }; runout end

      begin
        value = @generator.generate
      end while @used[value]

      @used[value] = true
      @available = @available.fmap { |x| x - 1 }
      value
    end

    def empty?
    end

    def reset!
      @available = @max
    end
  end

end

