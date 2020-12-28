# frozen_string_literal: true

module PgSeedDump
  module DB
    class Query
      COL_SEP = "\t"

      def initialize(query)
        @query = query
        @decoder = PG::TextDecoder::String.new
      end

      # def each_row2
      #   connection = ActiveRecord::Base.connection.raw_connection
      #   connection.send_query(@query)
      #   connection.set_single_row_mode
      #   results = connection.get_result
      #   @columns ||= Columns.new(results.fields)
      #   results.stream_each_row do |row|
      #     yield row, @columns
      #   end
      #   connection.get_result # to finish the query
      # end

      def rows
        connection = ActiveRecord::Base.connection.raw_connection
        Enumerator.new do |yielder|
          connection.copy_data "COPY (#{@query}) TO STDOUT", @decoder do
            while row = connection.get_copy_data
              yielder << row.strip.split(COL_SEP)
            end
          end
        end
      end
    end
  end
end
