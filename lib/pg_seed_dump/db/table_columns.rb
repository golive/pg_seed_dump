# frozen_string_literal: true

module PgSeedDump
  module DB
    class TableColumns
      attr_reader :table_name, :columns

      def initialize(table_name)
        @table_name = table_name
        @columns = ActiveRecord::Base.connection.columns(table_name).map { |c| c.name.to_sym }
        @column_positions = @columns.each_with_object({}).with_index do |(column, h), i|
          h[column] = i
        end
      end

      def value_at(row, column_name)
        row[index(column_name)]
      end

      def set_value(row, column_name, value)
        row[index(column_name)] = value
      end

      def to_s
        @columns.map { |column| %("#{column}") }.join(", ")
      end

      private

      def index(column_name)
        @column_positions.fetch(column_name.to_sym)
      end
    end
  end
end
