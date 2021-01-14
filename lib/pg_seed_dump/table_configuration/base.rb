# frozen_string_literal: true
require_relative "foreign_key"
require_relative "column_transform"

module PgSeedDump
  module TableConfiguration
    class Base
      attr_reader :table_name, :foreign_keys, :transforms, :sequence_name

      def initialize(configuration, table_name, _options = {})
        unless ::ActiveRecord::Base.connection.table_exists?(table_name)
          raise Configuration::TableNotExistsError,
                "Table #{table_name} doesn't exist"
        end
        @configuration = configuration
        @table_name = table_name.to_sym
        @foreign_keys = Set.new
        @transforms = []
        primary_key, sequence = ActiveRecord::Base.connection.pk_and_sequence_for(table_name)
        @primary_key = primary_key&.to_sym || :id
        @sequence_name = sequence&.identifier
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

      def primary_key(column_name = nil)
        @primary_key = column_name.to_sym if column_name
        @primary_key
      end

      def foreign_key(id_column, to_table, type_column: nil, type_value: nil, reverse_processing: true)
        ForeignKey.new(table_name, id_column, to_table, type_column: type_column,
                       type_value: type_value, reverse_processing: reverse_processing).tap do |foreign_key|
          @foreign_keys << foreign_key
        end
      end

      def polymorphic_foreign_key(id_column, type_column, table_types_map, reverse_processing: true)
        if table_types_map.empty?
          raise StandardError, "Add at least one table to type map in #{table_name}.#{id_column}"
        end
        table_types_map.map do |to_table, value|
          foreign_key(id_column, to_table, type_column: type_column,
                      type_value: value, reverse_processing: reverse_processing)
        end
      end

      def transform(attribute, &block)
        @transforms << ColumnTransform.new(attribute, block)
      end
    end
  end
end
