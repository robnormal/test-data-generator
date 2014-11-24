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
    # @param count [Integer] number of words per phrase; can be Integer, Array, or Range.
    #   If Array or Range, number of words is randomly selected for each phrase
    def initialize(count)
      super(:lorem_ipsum, :words)
      @count = count
    end

    def generate
      @forger.send(@forger_method, num_words, random: true)
    end

    private

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
        @min_length = length.min
        @max_length = length.max
      elsif length
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
  end

  class NumberGenerator
    include Generator

    # [max] maximum value
    # [min] minimum value
    # [greater_than] Column data in Database object
    def initialize(max: nil, min: 0, greater_than: nil)
      if max.nil?
        raise(ArgumentError, "#{self.class} requires :max option")
      end

      @max = max
      @min = min
      @greater_than = greater_than
    end

    def generate
      if @greater_than
        current = @greater_than.last

        # enforce min requirement, if present
        min = if @min && @min > current then @min else current end
      else
        min = @min
      end

      rand_between(min, @max)
    end
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
      if rand < @null then nil else @generator.generate end
    end
  end

  # for values selected from a set
  class EnumGenerator
    include Generator

    def to_unique
      UniqueEnumGenerator.new(@set)
    end

    def initialize(set)
      @set = set.to_a
    end

    def generate
      @set.sample
    end
  end

  # Decorator class - generates caches all possible values, then
  #   "generating" them in a random order
  class UniqueEnumGenerator < EnumGenerator
    include UniqueGenerator

    # [gen] base Generator
    # [max] maximum number of unique values available
    def initialize(data)
      @data = data.to_a.uniq
      reset!
    end

    def generate
      if @unused.empty?; runout end

      @unused.pop
    end

    def reset!
      @unused = @data.shuffle
    end
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

  class UniqueBelongsToGenerator
    include Generator

    # @param
    def initialize(db, col_id, data_store)
      @db = db
      @column = col_id
      @data_store = data_store
      update_unused
    end

    def generate
      @unused.sample
    end

    private
    def update_unused
      @unused += db.data_for(@column).drop(@unused.length)
    end
  end
end

