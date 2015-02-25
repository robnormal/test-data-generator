require "rspec"
require "set"
require_relative "../test-data-generator"

module TestDataGenerator
  describe :from_config do
    before :example do
      @config = {
        authors: [3, [
          [:name, :string, [:max_length => 20]]
        ]],
        books: [5, [
          [:title, :words, [2..4]]
        ]]
      }

      @db = TestDataGenerator.from_config(@config)

      @get_data = -> do
        @db.generate_all!
        @db.dump
      end
    end

    it 'returns Database' do
      expect(@db).to be_a(Database)
    end

    it 'produces data for tables whose names are the keys in the config' do
      data = @get_data.call

      expect(data[:authors]).to be_a(Array)
      expect(data[:books]).to be_a(Array)
    end

    it 'produces number of rows for each table as given in the config' do
      data = @get_data.call

      expect(data[:authors].length).to eq(3)
      expect(data[:books].length).to eq(5)
    end

    it 'creates a row as Hash{ columnname => datum }' do
      data = @get_data.call

      expect(data[:authors].first).to be_a(Hash)
      expect(data[:authors].first[:name]).to be_a(String)
    end

    it 'creates belongs_to columns' do
      config = {
        users: [3, [
          [:id]
        ]],
        books: [5, [
          [:user_id, :belongs_to, [:users, :id]]
        ]]
      }

      db = TestDataGenerator.from_config(config)
      db.generate_all!
      data = db.dump

      user_ids = Set.new(data[:users].map { |user| user[:id] })
      book_user_ids = Set.new(data[:books].map { |book| book[:user_id] })

      expect(book_user_ids).to be_subset(user_ids)
    end

    it 'accepts a "unique" option for belongs_to columns' do
      config = {
        users: [3, [
          [:id],
          [:name, :string, [:max_length => 20]]
        ]],
        books: [3, [
          [:user_id, :belongs_to, [:users, :id], :unique => true]
        ]]
      }

      db = TestDataGenerator.from_config(config)
      expect { db.generate_all! }.not_to raise_error
      data = db.dump

      user_ids = Set.new(data[:users].map { |user| user[:id] })
      book_user_ids = Set.new(data[:books].map { |book| book[:user_id] })

      expect(book_user_ids).to eq(user_ids)
    end

    it 'creates greater_than columns, greater than concurrent value in another column' do
      config = {
        times: [10, [
          [:created_at, :datetime],
          [:updated_at, :datetime, [:greater_than => [:times, :created_at]]]
        ]]
      }

      db = TestDataGenerator.from_config(config)
      expect { db.generate_all! }.not_to raise_error
      data = db.dump

      data[:times].each do |row|
        expect(row[:updated_at]).to be > row[:created_at]
      end
    end
  end

  context :make_column do
    describe 'when name is String' do
      it 'converts to Symbol' do
        col = ConfigProcess.make_column('alpha', :bool)
        expect(col.name).to eq(:alpha)
      end
    end

    describe 'when name is "id"' do
      it 'produces a unique primary key' do
        col = ConfigProcess.make_column(:id)
        # TODO: test this a better way, without knowing stuff you shouldn't
        expect(col.instance_variable_get '@generator').to be_a(UniqueGenerator)
      end
    end

    describe 'when name is "*_at"' do
      it 'produces a timestamp column' do
        col = ConfigProcess.make_column(:created_at)
        # TODO: test this a better way, without knowing stuff you shouldn't
        expect(col.instance_variable_get '@generator').to be_a(DateTimeGenerator)
      end
    end

    describe 'when type is :forgery' do
      it 'uses third argument Array as args to Forgery' do
        col = ConfigProcess.make_column(:surname, :forgery, [:name, :last_name])
        expect(col.generate).to be_a(String)
      end
    end

    describe 'when type is :belongs_to' do
      include TestFixtures

      it 'uses third argument Array as args to Forgery' do
        setup_belongs([8])
        col = ConfigProcess.make_column(:user_id, :belongs_to, [:users, :id], db: @db)
        expect(col.generate({ [:users, :id] => [8] })).to eq(8)
      end
    end

    describe 'when "unique" option is true' do
      it 'produces a UniqueGenerator' do
        col = ConfigProcess.make_column(:surname, :number, [min: 1, max: 10], unique: true)

        nums = (1..10).map { col.generate }
        expect(nums).to contain_exactly(*(1..10))
      end
    end

    describe 'when "null" option is true' do
      it 'produces a NullGenerator' do
        col = ConfigProcess.make_column(:surname, :number, [max: 8], null: 0.5)

        has_nil = false
        has_nonnil = false
        count = 0
        until (has_nil && has_nonnil) || count > 100000
          if col.generate.nil?
            has_nil = true
          else
            has_nonnil = true
          end
        end

        expect(has_nil).to be true
        expect(has_nonnil).to be true
      end
    end
  end
end
