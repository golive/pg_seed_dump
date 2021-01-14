# frozen_string_literal: true
require_relative "base"

module PgSeedDump
  module TableDump
    class Seed < Base
      def add_records_to_process(ids)
        return super(ids) if table_configuration.can_grow?
        return 0 if (Set.new(ids) - processed_ids).empty?

        raise StandardError,
              "Seed table #{table_configuration.table_name} cannot receive new records for processing"
      end

      def add_seed_records_to_process(ids)
        if processed_ids.any?
          raise StandardError,
                "Table seed records cannot be added if there are already processed ids"
        end

        pending_to_process_ids.merge(ids)
      end
    end
  end
end