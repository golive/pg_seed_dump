# frozen_string_literal: true
require_relative "base"

module PgSeedDump
  module TableDump
    class Seed < Base
      def add_records_to_process(ids)
        return if (Set.new(ids) - processed_ids).empty?

        raise "Seed table cannot receive new records to process"
      end

      def add_seed_records_to_process(ids)
        if processed_ids.any?
          raise "Table seed records cannot be added if there are already processed ids"
        end

        pending_to_process_ids.merge(ids)
      end
    end
  end
end