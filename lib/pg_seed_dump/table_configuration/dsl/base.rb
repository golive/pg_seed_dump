# frozen_string_literal: true
require_relative "../column_transform"
require_relative "../foreign_key"

module PgSeedDump
  module TableConfiguration
    module Dsl
      class Base
        def initialize(table_configuration)
          @table_configuration = table_configuration
        end

        def primary_key(column_name)
          @table_configuration.primary_key = column_name
        end

        def foreign_key(to_table, id_column, type_column: nil, type_value: nil, pull: true)
          foreign_key = ForeignKey.new(
            @table_configuration.table_name, id_column, to_table,
            type_column: type_column, type_value: type_value, pull: pull
          )
          @table_configuration.add_foreign_key(foreign_key)
        end

        def polymorphic_foreign_key(id_column, type_column)
          called = false
          probe = -> { called = true }
          dsl = PolymorphicForeignKeyDsl.new(self, id_column, type_column, probe)
          yield(dsl) if block_given?

          unless called
            raise(StandardError, "Add at least one foreign key in polymorphic #{id_column}.#{type_column}")
          end
        end

        def transform(attribute, &block)
          transform = ColumnTransform.new(attribute, block)
          @table_configuration.add_transform(transform)
        end

        class PolymorphicForeignKeyDsl < Struct.new(:dsl, :id_column, :type_column, :probe)
          def foreign_key(to_table, type:, pull: true)
            probe.call
            dsl.foreign_key(to_table, id_column, type_column: type_column, type_value: type, pull: pull)
          end
        end
        private_constant :PolymorphicForeignKeyDsl
      end
    end
  end
end
