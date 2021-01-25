# frozen_string_literal: true
require "pg_seed_dump/support/measure"

module PgSeedDump
  module DB
    class Query
      def initialize(query, decoder: nil)
        @query = query.strip
        @decoder = decoder || PG::TextDecoder::CopyRow.new
      end

      def rows
      connection = ActiveRecord::Base.connection.raw_connection
        Enumerator.new do |yielder|
          connection.copy_data "COPY (#{@query}) TO STDOUT", @decoder do
            while row = connection.get_copy_data
              yielder << row
            end
          end
        end
      end
    end
  end
end
