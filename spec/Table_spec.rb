require "rspec"
require_relative "../lib/Table.rb"

module TestDataGenerator
  describe Table do
    dummy = Table.new('dummy', 10)

    it 'has symbol attribute "name"' do
      expect(dummy.name).to eq(:dummy)
    end

    it 'has int attribute "num_rows"' do
      expect(dummy.num_rows).to eq(10)
    end

    it 'has int attribute "rows_produced"' do
      expect(dummy.rows_produced).to eq(0)
    end
  end
end


