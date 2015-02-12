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

    def generate(_ = nil)
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

    def generate(_ = nil)
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

    def generate(_ = nil)
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

      if greater_than
        @greater_than = greater_than
        @greater_than_id = ColumnId.new(*greater_than)
      end
    end

    def dependencies
      @greater_than ? [@greater_than_id] : []
    end

    def generate(col_data = nil)
      if @greater_than
        current = (col_data[@greater_than] || []).last || 0

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

    def generate(_ = nil)
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

    def generate(input = nil)
      rand < @null ? nil : @generator.generate(input)
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

    def generate(_ = nil)
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

    def empty?
      @unused.empty?
    end

    def reset!
      @unused = @data.shuffle
    end

    protected

    def next_value(_ = nil)
      @unused.pop
    end
  end


  # selects values from a column in a table
  class BelongsToGenerator
    include Generator

    # @param db [Database]
    # @param column_id [ColumnId]
    def initialize(column_id)
      @column = column_id
      @column_a = @column.to_a
    end

    # @param [Hash{ Array(String,String) => Array]
    #   data for columns depended on
    def generate(column_data)
      if column_data[@column_a].nil?
        raise(ArgumentError, "Missing required data for column: #{@column}")
      end

      column_data[@column_a].sample
    end

    def dependencies
      [@column]
    end

    def to_unique
      UniqueBelongsToGenerator.new(@column)
    end
  end

  class UniqueBelongsToGenerator < BelongsToGenerator
    include UniqueGenerator

    def initialize(column_id)
      super
      reset!
    end

    # must update @unused before checking for empty
    def generate(data)
      update_unused(data)
      super @unused
    end

    def empty?
      @unused.empty?
    end

    def reset!
      @grabbed = 0
      @unused = []
    end

    def to_unique
      self
    end

    def needs(db)
      if @unused.empty?
        count = [1 + @grabbed - db.retrieve_by_id(@column).length, 0].max

        if count > 0
          [[@column, count]]
        else
          []
        end
      else
        []
      end
    end

    protected
    def next_value(_ = nil)
      @unused.delete_at rand(@unused.length)
    end

    private
    def update_unused(column_data)
      data = column_data[@column_a]

      @unused += data.drop @grabbed
      @grabbed = data.length
    end
  end
end

