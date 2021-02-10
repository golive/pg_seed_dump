# frozen_string_literal: true
require "pg_seed_dump/db"

module PgSeedDump
  module DB
    module Schema
      def self.column_type_map(mapper_class, column_oids)
        mapper_class.new(DB.raw_connection).build_column_map(column_oids)
      end

      def self.columns(table_name)
        DB.connection.columns(table_name)
      end

      def self.tables
        DB.connection.tables
      end

      def self.table_exists?(table_name)
        DB.connection.table_exists?(table_name)
      end

      def self.column_exists?(table_name, column_name)
        DB.connection.column_exists?(table_name, column_name)
      end

      def self.foreign_keys_for(table_name)
        DB.connection.foreign_keys(table_name)
      end

      def self.primary_key_for(table_name)
        DB.connection.pk_and_sequence_for(table_name)&.first
      end

      def self.sequence_for(table_name)
        [*DB.connection.pk_and_sequence_for(table_name)].last&.identifier
      end
    end
  end
end
