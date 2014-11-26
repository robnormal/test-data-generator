require "rspec"
require_relative "../lib/column_data"
require_relative "../lib/dependency"

module TestDataGenerator
  describe ColumnData do
    context 'initialize accepts Hash{Table => Column => data}, then' do
      before :example do
        @cd = ColumnData.new({ tbl: { a: [1,2,3], b: [:x, :y] } })
        @column_b = ColumnId.new(:tbl, :b)
      end

      describe :data_for do
        it 'returns data for a column' do
          expect(@cd.data_for(@column_b)).to contain_exactly(:x, :y)
        end

        it 'raises an ArgumentError, if no such column is found' do
          expect { @cd.data_for(ColumnId.new(:j, :k)) }
            .to raise_error(ArgumentError)
        end
      end
    end
  end
end


