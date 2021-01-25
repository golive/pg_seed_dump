# frozen_string_literal: true

module PgSeedDump
  module DB
    class TableColumns
      attr_reader :table_name, :columns

      def initialize(table_name)
        @table_name = table_name
        @columns = connection.columns(table_name).map { |c| c.name.to_sym }
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

      def copy_decoder
        @decoder ||= PG::TextDecoder::CopyRow.new(type_map: type_map(PG::BasicTypeMapForResults))
      end

      def copy_encoder
        @encoder ||= PG::TextEncoder::CopyRow.new(type_map: type_map(PG::BasicTypeMapBasedOnResult))
      end

      private

      def index(column_name)
        @column_positions.fetch(column_name.to_sym)
      end

      def connection
        ActiveRecord::Base.connection
      end

      def raw_connection
        connection.raw_connection
      end

      def column_oids
        @column_oids ||= raw_connection.exec("SELECT #{self} FROM #{@table_name} LIMIT 0")
      end

      def type_map(mapper_class)
        mapper_class.new(raw_connection).build_column_map(column_oids)
      end
    end
  end
end
