require "rspec"
require_relative "../test-data-generator"

module TestDataGenerator
  class SimpleGenerator
    include Generator
    def initialize(references)
      @refs = references
    end

    def generate(_ = nil)
      @refs[:counter] += 1
      @refs[:data][@refs[:counter]]
    end
  end

  class DBStub
    def initialize(data)
      @data = data
    end

    def retrieve_by_id(_)
      @data
    end
  end

  module TestFixtures
    def setup_belongs(data)
      @refs = {}
      reset_belongs_gen data

      @id = Column.new(:id, SimpleGenerator.new(@refs))

      @users = Table.new(:users)
      @users.add! @id
      @db = Database.new({ @users => 10 })

      @foreign = ColumnId.new(:users, :id)
      @foreign_a = @foreign.to_a
      @belongs = BelongsToGenerator.new(@foreign)
      @unique = UniqueBelongsToGenerator.new(@foreign)

      set_belongs_data(data)
    end

    def reset_belongs_gen(data)
      @refs[:data] = data
      @refs[:counter] = -1
    end

    def set_belongs_data(data)
      @db.reset!
      reset_belongs_gen(data)
      data.length.times { @db.generate! }
    end

    def setup_greater_than(data)
      @refs = {}
      reset_belongs_gen data

      @num1 = Column.new(:num1, SimpleGenerator.new(@refs))

      @numbers = Table.new(:numbers)
      @numbers.add! @num1
      @db = Database.new({ @numbers => 10 })
      @db.add_table!(@numbers, 3)
    end
  end
end

