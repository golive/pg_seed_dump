# frozen_string_literal: true
require "pg_seed_dump/db/schema"

module PgSeedDump
  module TableConfiguration
    class Base
      attr_reader :table_name, :foreign_keys, :primary_key, :transforms, :sequence_name

      def initialize(schema, table_name)
        unless DB::Schema.table_exists?(table_name)
          raise Schema::TableNotExistsError,
                "Table #{table_name} doesn't exist"
        end
        @schema = schema
        @table_name = table_name.to_sym
        @foreign_keys = Set.new
        @transforms = []
        primary_key = DB::Schema.primary_key_for(table_name)
        @primary_key = (primary_key || :id).to_sym
        @sequence_name = DB::Schema.sequence_for(table_name)
      end

      def full?
        false
      end

      def partial?
        false
      end

      def seed?
        false
      end

      def empty?
        false
      end

      def associated_tables(&block)
        @schema.associated_to_table(table_name, &block)
      end

      def primary_key=(column_name)
        @primary_key = column_name.to_sym
      end

      def add_foreign_key(foreign_key)
        @foreign_keys << foreign_key
      end

      def add_transform(transform)
        @transforms << transform
      end
    end
  end
end
