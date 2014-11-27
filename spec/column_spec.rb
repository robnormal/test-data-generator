require "rspec"
require_relative "../lib/column"
require_relative "shared"
require 'set'

module TestDataGenerator
  describe Column do
    table = Table.new('dummy')
    num = Column.new('age', NumberGenerator.new(min: 18, max: 100))

    it 'has symbol attribute "name"' do
      expect(num.name).to eq(:age)
    end

    describe 'generate' do
      it 'uses given generator to produce one datum' do
        expect(num.generate).to be_between(18, 100)
      end
    end

    context 'from_spec' do
      describe 'when name is String' do
        it 'converts to Symbol' do
          col = Column.from_spec('alpha', :bool)
          expect(col.name).to eq(:alpha)
        end
      end

      describe 'when name is "id"' do
        it 'produces a unique primary key' do
          col = Column.from_spec(:id)
          # TODO: test this a better way, without knowing stuff you shouldn't
          expect(col.instance_variable_get '@generator').to be_a(UniqueGenerator)
        end
      end

      describe 'when name is "*_at"' do
        it 'produces a timestamp column' do
          col = Column.from_spec(:created_at)
          # TODO: test this a better way, without knowing stuff you shouldn't
          expect(col.instance_variable_get '@generator').to be_a(DateTimeGenerator)
        end
      end

      describe 'when type is :forgery' do
        it 'uses third argument Array as args to Forgery' do
          col = Column.from_spec(:surname, :forgery, [:name, :last_name])
          expect(col.generate).to be_a(String)
        end
      end

      describe 'when type is :belongs_to' do
        include TestFixtures

        it 'uses third argument Array as args to Forgery' do
          setup_belongs([8])
          col = Column.from_spec(:user_id, :belongs_to, [:users, :id], db: @db)
          expect(col.generate).to eq(8)
        end
      end

      describe 'when "unique" option is true' do
        it 'produces a UniqueGenerator' do
          col = Column.from_spec(:surname, :number, [min: 1, max: 10], unique: true)

          nums = (1..10).map { col.generate }
          expect(nums).to contain_exactly(*(1..10))
        end
      end

      describe 'when "null" option is true' do
        it 'produces a NullGenerator' do
          col = Column.from_spec(:surname, :number, [max: 8], null: 0.5)

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

end

