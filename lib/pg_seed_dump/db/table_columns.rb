# frozen_string_literal: true
require "pg_seed_dump/db/query"
require "pg_seed_dump/db/schema"

module PgSeedDump
  module DB
    class TableColumns
      attr_reader :table_name, :columns

      def initialize(table_name)
        @table_name = table_name
        @columns = DB::Schema.columns(table_name).map { |c| c.name.to_sym }
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
        @copy_decoder ||= PG::TextDecoder::CopyRow.new(
          type_map: DB::Schema.column_type_map(PG::BasicTypeMapForResults, column_oids)
        )
      end

      def copy_encoder
        @copy_encoder ||= PG::TextEncoder::CopyRow.new(
          type_map: DB::Schema.column_type_map(PG::BasicTypeMapBasedOnResult, column_oids)
        )
      end

      private

      def index(column_name)
        @column_positions.fetch(column_name.to_sym)
      end

      def column_oids
        @column_oids ||= DB::Query.exec("SELECT #{self} FROM #{@table_name} LIMIT 0")
      end
    end
  end
end
