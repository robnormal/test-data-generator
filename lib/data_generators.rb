require 'forgery'
require_relative 'util.rb'
require_relative 'generator.rb'

module TestDataGenerator
  # Generates data using the forgery library
  class ForgeryGenerator
    include Generator

    def initialize(forger, method, args = [])
      @forger        = Forgery(forger.to_sym)
      @forger_method = method.to_sym
      @forger_args   = args
    end

    def generate
      @forger.send(@forger_method, *@forger_args)
    end

    protected
    @forger
    @forger_method
    @forger_args
  end


  # creates lorem ipsum verbiage
  class WordGenerator < ForgeryGenerator
    # @param count [Fixnum] number of words per phrase; can be Integer, Array, or Range.
    #   If Array or Range, number of words is randomly selected for each phrase
    def initialize(count)
      super(:lorem_ipsum, :words)
      @count = count
    end

    def generate
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
  class StringGenerator
    include Generator

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

    def generate
      length = @length || rand_between(@min_length, @max_length)

      (length.times.collect { rand_in @chars }).join
    end

    private
    @min_length
    @max_length
    @length # exact length for all values
    @chars # set of characters to choose from
  end

  class NumberGenerator
    include Generator

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

    def generate
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

    private
    @greater_than
    @min
    @max
  end

  class UrlGenerator
    include Generator

    def initialize(options = nil)
      @forgery = Forgery(:internet)
    end

    def generate
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
  class UniqueGenerator
    include Generator

    # [gen] base Generator
    # [max] maximum number of unique values available
    def initialize(gen, max: nil)
      @generator = gen
      @max = max
      @count = 0
      @data_tracker = {}
    end

    def generate
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
  class NullGenerator
    include Generator

    # [gen] base Generator
    # [null] probability of producing a null value
    def initialize(gen, null)
      @generator = gen
      @null = null
    end

    def generate
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
  class EnumGenerator
    include Generator

    def to_unique
      EnumGenerator.new(@set, unique: true)
    end

    def initialize(set, unique: false)
      @set = set.to_a
      @unique = unique
    end

    def generate
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
  class BelongsToGenerator
    include Generator

    # @param col_accum [Accumulator] Accumulator for Column this generator points to
    def initialize(column_accum)
      @col_accum = column_accum
    end

    def generate
      @col_accum.sample
    end
  end
end

