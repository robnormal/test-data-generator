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
        @db.offload_all!
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
      data = db.offload_all!

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

      srand(1112) # set comes out wrong

      db = TestDataGenerator.from_config(config)
      db.generate_all!
      data = db.offload_all!

      user_ids = Set.new(data[:users].map { |user| user[:id] })
      book_user_ids = Set.new(data[:books].map { |book| book[:user_id] })

      expect(book_user_ids).to eq(user_ids)
    end
  end
end
