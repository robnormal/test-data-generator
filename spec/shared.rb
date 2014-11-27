require "rspec"
require_relative "../test-data-generator"

module TestDataGenerator
  module TestFixtures
    def setup_belongs(data)
      @refs = {}
      reset_belongs_gen data

      @id = Column.new(:id, SimpleGenerator.new(@refs))

      @users = Table.new(:users)
      @users.add! @id
      @db = Database.new({ @users => 10 })

      @foreign = ColumnId.new(:users, :id)
      @belongs = BelongsToGenerator.new(@db, @foreign)
      @unique = UniqueBelongsToGenerator.new(@db, @foreign)

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
  end
end

