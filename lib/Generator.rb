require 'forgery'
require_relative 'util.rb'

module TestDataGenerator
  class Generator
    include Enumerable

    # Iterates over all generated data
    def each
      loop do
        yield generate_one
      end
    end

    def handles_unique?
      false
    end

    protected

    # Every subclass must define this
    def generate_one
      raise NotImplementedError, "Define #{self.class}::generate_one()"
    end
  end

  # Generates data using the forgery library
  class ForgeryGenerator < Generator
    def initialize(forger, method_name, args = [])
      @forgery        = Forgery(forger.to_sym)
      @forgery_method = method_name.to_sym
      @forgery_args   = args
    end

    protected
    @forgery
    @forgery_method
    @forgery_args

    def generate_one
      @forgery.send(@forgery_method, *@forgery_args)
    end
  end

  # creates lorem ipsum verbiage
  class WordGenerator < ForgeryGenerator
    # [count] number of words per phrase; can be Integer, Array, or Range.
    #         If Array or Range, number of words is randomly selected for each phrase
    def initialize(count)
      super(:lorem_ipsum, :words)
      @count = count
    end

    protected

    def generate_one
      @forgery.send(@forgery_method, num_words, random: true)
    end

    private

    @count

    def num_words
      if @count.is_a? Integer
        @count
      else
        rand_in(@count)
      end
    end
  end

  # random strings
  class StringGenerator < Generator
    ALL_CHARS  = ('!'..'z').to_a
    WORD_CHARS = ('0'..'9').to_a + ('A'..'Z').to_a + ('a'..'z').to_a << '_'

    # [chars] Set of characters from which to form String
    # [length] If present, all Strings will be this long
    # [max_length] If present, all Strings will be at most this long
    # [min_length] All strings are at least this long
    # Either length or max_length must be set
    def initialize(chars: WORD_CHARS, length: nil, min_length: 1, max_length: nil)
      @chars = chars

      if length.is_a? Range
        min_length = length.min
        max_length = length.max
        length = nil
      end

      if length
        @length = length
      elsif max_length
        @min_length = min_length
        @max_length = max_length
      else
        raise(ArgumentError, "#{self.class} requires :length or :max_length option")
      end
    end

    protected

    def generate_one
      length = @length || rand_between(@min_length, @max_length)

      (length.times.collect { rand_in @chars }).join
    end

    @min_length
    @max_length
    @length # exact length for all values
    @chars # set of characters to choose from
  end

  class NumberGenerator < Generator
    # [max] maximum value
    # [min] minimum value
    # [greater_than] name of Column; must generate value > column's current() value
    def initialize(max: nil, min: 0, greater_than: nil)
      if max
        @max = max
      else
        raise(ArgumentError, "#{self.class} requires :max option")
      end

      if greater_than
        table, column = *greater_than
        @greater_than = { table: table, column: column }
      else
        @min = min
      end
    end

    protected

    def generate_one
      if @greater_than
        current = Table.current(@greater_than[:table], @greater_than[:column]) || 0

        # enforce min requirement, if present
        if @min && @min > current
          min = @min
        else
          min = current
        end

      else
        min = @min
      end

      rand_between(min, @max)
    end

    @greater_than
    @min
    @max
  end

  class UrlGenerator < Generator
    def initialize(options = nil)
      @forgery = Forgery(:internet)
    end

    protected

    def generate_one
      domain = @forgery.send :domain_name
      'http://' + domain
    end
  end

  class DateTimeGenerator < NumberGenerator
    def initialize(options = {})
      options[:max] ||= Time.now().to_i

      super(options)
    end
  end

  # Decorator class - returns unique values from base Generator
  class UniqueGenerator < Generator
    # [gen] base Generator
    # [max] maximum number of unique values available
    def initialize(gen, max: nil)
      @generator = gen
      @max = max
      @count = 0
      @data_tracker = {}
    end

    protected

    def generate_one
      if @max && @count >= @max
        raise(IndexError, "No more unique data; all #{@max} unique values have been used")
      else
        begin
          value = @generator.first
        end while @data_tracker[value]

        @data_tracker[value] = true
        @count += 1
        value
      end
    end

    private
    @generator
    @defer
    @data_tracker
    @max
    @count
  end

  # Decorator class - returns base Generator values mixed with NULLs
  class NullGenerator < Generator
    # [gen] base Generator
    # [null] probability of producing a null value
    def initialize(gen, null)
      @generator = gen
      @null = null
    end

    protected

    def generate_one
      if rand < @null
        nil
      else
        @generator.first
      end
    end

    private
    @generator
    @data_tracker
  end

  # for values selected from a set
  # including any column that "belongs_to" another column
  class EnumGenerator < Generator
    def handles_unique?
      true
    end

    def initialize(set, unique: false)
      @set = set.to_a
      @unique = unique
    end

    protected

    def generate_one
      if @unique
        # intialize @data, if not initialized
        if !@data
          @data = @set.uniq.shuffle
        end

        if @data.empty?
          raise(IndexError, "No more unique data")
        end

        @data.shift
      else
        @set.sample
      end
    end

    private
    @set
    @data
  end

  # selects values from a column in a table
  class BelongsToGenerator < EnumGenerator
    attr_reader :table, :column

    def initialize(table, column, options = {})
      @table = table.to_sym
      @column = column.to_sym
      @unique = options[:unique]
    end

    protected

    # wait until we need data before asking Table to generate it
    def generate_one
      unless @set
        @set = Table.all(@table, @column)
      end

      super
    end
  end
end

