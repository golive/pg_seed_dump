# frozen_string_literal: true
require "pg_seed_dump/table_to_sql_copy"

module PgSeedDump
  module TableDump
    class Base
      attr_reader :table_configuration

      def initialize(table_configuration, table_dumps)
        @table_configuration = table_configuration
        @processed_ids = Set.new
        @pending_to_process_ids = Set.new
        @table_copy = TableToSqlCopy.new(table_configuration, table_dumps)
      end

      def add_records_to_process(ids)
        previous_size = @pending_to_process_ids.size
        @pending_to_process_ids.merge(Set.new(ids) - @processed_ids)

        @pending_to_process_ids.size - previous_size
      end

      def pending_to_process_records?
        @pending_to_process_ids.any?
      end

      def dump_pending_records
        return unless pending_to_process_records?

        ids_to_be_processed = @pending_to_process_ids.dup
        @table_copy.process_records(ids_to_be_processed)
        @table_copy.process_associated_records(ids_to_be_processed)
        ids_to_be_processed.each { |id| record_processed(id) }
      end

      def dump_processed_to_file(file)
        @table_copy.write_copy_to_file(file)
      end

      def num_records_processed
        @table_copy.num_records_processed
      end

      private

      def record_processed(id)
        @pending_to_process_ids.delete(id)
        @processed_ids.add(id)
      end
    end
  end
end
