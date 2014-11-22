require "rspec"
require_relative "../lib/Column.rb"
require 'set'

module TestDataGenerator
  describe Column do
    table = Table.new('dummy', 10)
    num = Column.new(table, 'age', NumberGenerator.new(min: 18, max: 100))

    it 'has symbol attribute "name"' do
      expect(num.name).to eq(:age)
    end

    it 'has Table attribute "table"' do
      expect(num.table).to eq(table)
    end

    describe 'generate_one' do
      it 'uses given generator to produce one datum' do
        expect(num.generate_one).to be_between(18, 100)
      end
    end

    describe 'current' do
      it 'returns the most recently produced datum' do
        last = num.generate_one
        expect(num.current).to eq(last)
      end
    end

    context 'from_spec' do
      describe 'when name is String' do
        it 'converts to Symbol' do
          col = Column.from_spec(table, 'alpha', :bool)
          expect(col.name).to eq(:alpha)
        end
      end

      describe 'when name is "id"' do
        it 'produces a unique primary key' do
          col = Column.from_spec(table, :id)
          # TODO: test this a better way, without knowing stuff you shouldn't
          expect(col.instance_variable_get '@generator').to be_a(UniqueGenerator)
        end
      end

      describe 'when name is "*_at"' do
        it 'produces a timestamp column' do
          col = Column.from_spec(table, :created_at)
          # TODO: test this a better way, without knowing stuff you shouldn't
          expect(col.instance_variable_get '@generator').to be_a(DateTimeGenerator)
        end
      end

      describe 'when type is :forgery' do
        it 'uses third argument Array as args to Forgery' do
          col = Column.from_spec(table, :surname, :forgery, [:name, :last_name])
          expect(col.generate_one).to be_a(String)
        end
      end

      describe 'when type is :belongs_to' do
        it 'creates ForeignColumn with BelongsToGenerator pointing to given column' do
          target = Table.new('target', 10, [:id])
          source = Table.new('source', 10)

          col = Column.from_spec(source, :foreign, :belongs_to, [:target, :id])
          source.add col

          id = col.generate_one
          ids = target.to_a.map(&:first)
          expect(ids).to include(id)
        end
      end

      describe 'when "unique" option is true' do
        it 'produces a UniqueGenerator' do
          col = Column.from_spec(table, :surname, :number, [min: 1, max: 10], unique: true)

          nums = (1..10).map { col.generate_one }
          expect(nums).to contain_exactly(*(1..10))
        end
      end

      describe 'when "null" option is true' do
        it 'produces a NullGenerator' do
          col = Column.from_spec(table, :surname, :number, [max: 8], null: 0.5)

          has_nil = false
          has_nonnil = false
          count = 0
          until (has_nil && has_nonnil) || count > 100000
            if col.generate_one.nil?
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

  describe ForeignColumn do
    it 'selects random entries from another column' do
      table1 = Table.new('main', 5, [[:id]])
      table2 = Table.new('other', 5)

      belongs = BelongsToGenerator.new(:main, :id)
      foreign = ForeignColumn.new(table2, :main_id, belongs)
      table2.add foreign

      set1 = Set.new(table1.to_a.map { |x| x.first })
      set2 = Set.new(table2.to_a.map { |x| x.first })

      expect(set2.subset?(set1)).to be true
    end

    it 'respects uniqueness' do
      table1 = Table.new('main', 10, [[:id]])
      table2 = Table.new('other', 10)

      belongs = BelongsToGenerator.new(:main, :id, unique: true)
      foreign = ForeignColumn.new(table2, :main_id, belongs)
      table2.add foreign

      a = table1.to_a.map { |x| x.first}
      b = table2.to_a.map { |x| x.first}
      set1 = Set.new(a)
      set2 = Set.new(b)

      # Only need to check that set1 is contained in set2
      # By previous test, we know set2 is contained in set1
      expect(set1.subset?(set2)).to be true
    end
  end
end

