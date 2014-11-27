require "rspec"
require_relative "../lib/columnwise_storage"
require_relative "../lib/dependency"

module TestDataGenerator
  describe ColumnwiseStorage do
    before :example do
      @data_store = ColumnwiseStorage.new([:a, :b])
    end

    describe :append_row! do
      context 'adds a row to the given category, and then' do
        describe :retrieve do
          it 'returns all the values at the two coordinates given' do
            @data_store.append_row!(:b, { x: 8, y: 5 })
            expect(@data_store.retrieve(:b, :x)).to eq([8])
            expect(@data_store.retrieve(:b, :wrong)).to eq([])
          end

          it 'raises an ArgumentError if the category does not exist' do
            expect {
              @data_store.retrieve(:wrong, :x)
            }.to raise_error(ArgumentError)
          end
        end
      end
    end

    describe :retrieve_by_id do
      it 'retrieves data by ColumnId' do
        @data_store.append_row!(:b, { x: 8, y: 5 })
        id = ColumnId.new(:b, :x)

        expect(@data_store.retrieve_by_id(id)).to eq([8])
      end
    end

    describe :reset! do
      it 'deletes existing data' do
        @data_store.append_row!(:a, { dog: 'Rex', cat: 'Spot' })
        @data_store.append_row!(:b, { x: 9, y: 12 })
        @data_store.reset!

        expect(@data_store.retrieve(:a, :dog)).to eq([])
      end
    end

    describe :offload! do
      it 'yields data from category as rows, in order appended, then deletes that data' do
        @data_store.append_row!(:a, { dog: 'Rex', cat: 'Spot' })
        @data_store.append_row!(:a, { dog: 'Dog', cat: 'Merlin' })

        count = 0
        @data_store.offload!(:a) do |row|
          if count == 0
            expect(row).to eq(['Rex', 'Spot'])
          elsif count == 1
            expect(row).to eq(['Dog', 'Merlin'])
          end

          count += 1
        end

        expect(count).to be 2
        expect(@data_store.retrieve(:a, :dog)).to eq([])
      end
    end

    describe :offload_all! do
      it 'yields all rows from all categories, in a Hash' do
        @data_store.append_row!(:a, { dog: 'Rex', cat: 'Spot' })
        @data_store.append_row!(:a, { dog: 'Dog', cat: 'Merlin' })
        @data_store.append_row!(:b, { x: 2, y: 0 })

        data = @data_store.offload_all!

        expect(data[:a].length).to be 2
        expect(data[:a][1]).to eq(['Dog', 'Merlin'])
        expect(data[:b].length).to be 1
        expect(data[:b][0]).to eq([2, 0])
      end
    end

  end
end

