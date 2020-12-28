# frozen_string_literal: true
require_relative 'foreign_key'

module PgSeedDump
  module TableConfiguration
    class Base
      attr_reader :table_name, :foreign_keys, :primary_key, :sequence_name, :process_associated

      def initialize(configuration, table_name, process_associated: true)
        unless ::ActiveRecord::Base.connection.table_exists?(table_name)
          raise Configuration::TableNotExistsError,
                "Table #{table_name} doesn't exist"
        end
        @configuration = configuration
        @table_name = table_name.to_sym
        @foreign_keys = Set.new
        primary_key, sequence = ActiveRecord::Base.connection.pk_and_sequence_for(table_name)
        @primary_key = primary_key&.to_sym
        @sequence_name = sequence&.identifier
        @process_associated = process_associated
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

      def associated_tables(&block)
        @configuration.associated_to_table(table_name, &block)
      end

      def foreign_key(id_column, to_table, type_column = nil, type_value = nil)
        ForeignKey.new(table_name, id_column, to_table, type_column, type_value).tap do |foreign_key|
          @foreign_keys << foreign_key
        end
      end

      def polymorphic_foreign_key(id_column, type_column, table_types_map)
        if table_types_map.empty?
          raise "Add at least one table to type map in #{table_name}.#{id_column}"
        end
        table_types_map.map do |to_table, value|
          foreign_key(id_column, to_table, type_column, value)
        end
      end

      def transform(attribute, &block)
        # pending
      end
    end
  end
end
