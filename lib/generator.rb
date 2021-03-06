module TestDataGenerator
  module Generator
    # @return One generated value
    def generate(input = {}); raise NotImplementedError end

    # @return [Array<Object>]
    def iterate(n, input = {})
      (1..n).collect { generate(input) }
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
    def needs(db)
      needed = []
      dependencies.each { |d|
        if db.retrieve_by_id(d).empty?
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

    def generate(input = {})
      if empty?; runout end

      next_value(input)
    end

    protected
    def next_value(input); raise NotImplementedError end
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

    def empty?
      !@max.nothing? && @max.from_just <= @used.length
    end

    def reset!
      @used = {}
    end

    protected

    def next_value(input)
      begin
        value = @generator.generate(input)
      end while @used[value]

      @used[value] = true
      value
    end
  end

end

