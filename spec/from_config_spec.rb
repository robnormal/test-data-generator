require "rspec"
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
  end
end
