# frozen_string_literal: true
require_relative "base"

module PgSeedDump
  module TableDump
    class Full < Base
      def initialize(*)
        super
        @full_mode = false
        @fully_dumped = false
      end

      def add_records_to_process(ids)
        return 0 if @full_mode
        super
      end

      def pending_to_process_records?
        !@fully_dumped && (super || @full_mode)
      end

      def dump_pending_records
        ids_to_be_processed = @pending_to_process_ids.dup
        if @full_mode && !@fully_dumped
          @table_copy.process_all_records
          @fully_dumped = true
        end
        return unless ids_to_be_processed.any?

        @table_copy.process_associated_records(ids_to_be_processed)
        ids_to_be_processed.each { |id| record_processed(id) }
      end

      def enable_full_mode
        @full_mode = true
      end
    end
  end
end
