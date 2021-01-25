# frozen_string_literal: true
require_relative "base"

module PgSeedDump
  module TableConfiguration
    module Dsl
      class Seed < Base
        def seed_query
          @table_configuration.seed_query = yield
        end

        def foreign_key(id_column, to_table, type_column: nil, type_value: nil, pull: false)
          raise(StandardError, "Cannot define pull foreign keys for seed tables") if pull

          super(id_column, to_table, type_column: type_column, type_value: type_value, pull: false)
        end
      end
    end
  end
end
