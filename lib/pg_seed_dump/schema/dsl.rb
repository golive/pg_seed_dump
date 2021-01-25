# frozen_string_literal: true
require "pg_seed_dump/table_configuration/seed"
require "pg_seed_dump/table_configuration/full"
require "pg_seed_dump/table_configuration/partial"
require "pg_seed_dump/table_configuration/dsl/seed"
require "pg_seed_dump/table_configuration/dsl/full"
require "pg_seed_dump/table_configuration/dsl/partial"

module PgSeedDump
  class Schema
    class Dsl
      def initialize(schema)
        @schema = schema
      end

      def dump_all_db_objects!
        @schema.dump_all_db_objects = true
      end

      def seed(table_name, options = {}, &block)
        options.transform_keys!(&:to_sym)
        setup_configuration("seed", table_name, &block).tap do |table_configuration|
          table_configuration.can_grow = options.fetch(:can_grow, false)
        end
      end

      def full(table_name, &block)
        setup_configuration("full", table_name, &block)
      end

      def partial(table_name, &block)
        setup_configuration("partial", table_name, &block)
      end

      private

      def setup_configuration(type, table_name)
        class_name = type.capitalize
        TableConfiguration.const_get(class_name).new(@schema, table_name).tap do |table_configuration|
          @schema.public_send("add_#{type}_configuration", table_configuration)
          dsl = TableConfiguration::Dsl.const_get(class_name).new(table_configuration)
          yield(dsl) if block_given?
        end
      end
    end
  end
end
