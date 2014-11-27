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

      @storage = TestDataGenerator.from_config(@config)
    end

    it 'returns ColumnwiseStorage' do
      expect(@storage).to be_a(ColumnwiseStorage)
    end

    it 'produces data for tables whose names are the keys in the config' do
      @storage.generate!
      data = @storage.offload_all!

      expect(data[:authors]).to be_a(Array)
      expect(data[:books]).to be_a(Array)
    end
  end
end
