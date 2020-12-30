# frozen_string_literal: true
require "pg_seed_dump/support/measure"

module PgSeedDump
  module DB
    class Query
      COL_SEP = "\t"

      def initialize(query)
        @query = query.strip
        @decoder = PG::TextDecoder::String.new
      end

      def rows
        connection = ActiveRecord::Base.connection.raw_connection
        Enumerator.new do |yielder|
          measure = Support::Measure.start
          connection.copy_data "COPY (#{@query}) TO STDOUT", @decoder do
            while row = connection.get_copy_data
              yielder << row.strip.split(COL_SEP)
            end
          end
          Log.debug("[#{measure.elapsed}] query\n#{@query.gsub(/^/, "\t")}")
        end
      end
    end
  end
end
