# frozen_string_literal: true
require_relative "base"

module PgSeedDump
  module TableDump
    class Full < Base
      attr_writer :run_full_dump

      def initialize(*)
        super
        @run_full_dump = false
      end

      def pending_to_process_records?
        super || run_full_dump
      end

      def dump_pending_records
        ids_to_be_processed = pending_to_process_ids.dup
        if run_full_dump
          table_copy.process_all_records
          self.run_full_dump = false
        end
        return unless ids_to_be_processed.any?

        if table_configuration.process_associated
          table_copy.process_associated_records(ids_to_be_processed)
        end
        ids_to_be_processed.each { |id| record_processed(id) }
      end

      private

      attr_reader :run_full_dump
    end
  end
end