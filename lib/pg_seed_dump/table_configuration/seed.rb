# frozen_string_literal: true
require_relative 'base'

module PgSeedDump
  module TableConfiguration
    class Seed < Base
      def initialize(configuration, table_name, options = {})
        super
        @can_grow = options.fetch(:can_grow) { false }
      end

      def can_grow?
        @can_grow
      end

      def seed?
        true
      end

      def seed_query
        @seed_query = yield if block_given?
        @seed_query
      end

      def foreign_key(id_column, to_table, type_column: nil, type_value: nil)
        super(id_column, to_table, type_column: type_column, type_value: type_value, reverse_processing: false)
      end
    end
  end
end
