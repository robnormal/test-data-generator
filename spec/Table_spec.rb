require "rspec"
require_relative "../lib/Table.rb"

def col_stub
  col = double('Column',
    name: :stub,
    dependencies: [TestDataGenerator::ColumnId.new(:table1, :column1)]
  )
end

module TestDataGenerator
  describe Table do
    before :example do
      @dummy = Table.new('dummy')
      @age = Column.new('age', NumberGenerator.new(min: 18, max: 100))
    end

    it 'has symbol attribute "name"' do
      expect(@dummy.name).to eq(:dummy)
    end

    context 'add! adds a column, and' do
      describe :column do
        it 'retrieves one by name' do
          @dummy.add! @age
          expect(@dummy.column(:age)).to eq(@age)
        end
      end
    end

    describe :add_from_spec do
      it 'adds a column via Column.from_spec()' do
        @dummy.add_from_spec!(:tries, :number, [max: 10])
        expect(@dummy.column(:tries).generate).to be_between(0, 10)
      end
    end

    describe :column_names do
      it 'returns the names of the columns' do
        @dummy.add! @age
        @dummy.add_from_spec!(:tries, :number, [max: 10])
        expect(@dummy.column_names).to eq([:age, :tries])
      end
    end

    def test_row(row)
      expect(row.length).to eq(2)

      age = row[:age]
      tries = row[:tries]
      expect(age).to be_between(18, 100)
      expect(tries).to be_between(0, 10)
    end

    describe 'generate' do
      it 'generates a full row' do
        @dummy.add! @age
        @dummy.add_from_spec!(:tries, :number, [max: 10])
        10.times do
          test_row @dummy.generate
        end
      end
    end

    describe :initialize do
      it 'accepts an array of column specs as the third argument' do
        users = Table.new 'users', [
          [:id],
          [:name, :forgery, [:name, :first_name]],
          [:title, :words, [2..4]],
          [:created_at]
        ]

        row = users.generate

        expect(row[:id]).to be_a(Fixnum)
        expect(row[:name]).to be_a(String)
        expect(row[:title]).to be_a(String)
        expect(row[:created_at]).to be_a(Fixnum)
      end
    end

    describe
  end

  describe :dependencies_as_edges do
    it 'returns all column dependencies, in the form [column_depending, column_source]' do
      tbl = Table.new 'test'
      tbl.add! col_stub

      expect(tbl.dependencies_as_edges[0].from).to eq(ColumnId.new(:test, :stub))
      expect(tbl.dependencies_as_edges[0].to).to eq(ColumnId.new(:table1, :column1))
    end
  end
end


