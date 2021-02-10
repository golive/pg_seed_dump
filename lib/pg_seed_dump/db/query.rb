# frozen_string_literal: true
require "pg_seed_dump/support/measure"
require "pg_seed_dump/db"

module PgSeedDump
  module DB
    class Query
      def initialize(query, decoder: nil)
        @query = query.strip
        @decoder = decoder || PG::TextDecoder::CopyRow.new
      end

      def rows
        Enumerator.new do |yielder|
          DB.raw_connection.copy_data "COPY (#{@query}) TO STDOUT", @decoder do
            while row = DB.raw_connection.get_copy_data
              yielder << row
            end
          end
        end
      end

      def self.exec(query)
        DB.raw_connection.exec(query)
      end
    end
  end
end
