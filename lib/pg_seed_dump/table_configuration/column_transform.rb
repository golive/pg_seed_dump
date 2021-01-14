module PgSeedDump
  module TableConfiguration
    class ColumnTransform
      attr_reader :column_name

      def initialize(column_name, block)
        @column_name = column_name.to_sym
        @block = block
      end

      def call(*args)
        @block.call(*args)
      end

      def column_names
        [column_name, *@block.parameters.map(&:last)[1..-1]]
      end
    end
  end
end