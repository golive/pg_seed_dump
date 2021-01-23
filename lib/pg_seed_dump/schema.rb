# frozen_string_literal: true
require "pg_seed_dump/table_configuration/seed"
require "pg_seed_dump/table_configuration/full"
require "pg_seed_dump/table_configuration/partial"

module PgSeedDump
  class Schema
    attr_reader :seed_table_configurations,
                :full_table_configurations,
                :partial_table_configurations

    TableNotExistsError      = Class.new(StandardError)
    ColumnNotExistsError     = Class.new(StandardError)
    TableAlreadyDefinedError = Class.new(StandardError)

    def initialize
      @table_configurations_map = {}
      @seed_table_configurations = []
      @full_table_configurations = []
      @partial_table_configurations = []
    end

    def seed(table_name, options = {}, &block)
      setup_configuration(TableConfiguration::Seed, table_name: table_name, options: options, &block).tap do |config|
        @seed_table_configurations << config
      end
    end

    def full(table_name, &block)
      setup_configuration(TableConfiguration::Full, table_name: table_name, &block).tap do |config|
        @full_table_configurations << config
      end
    end

    def partial(table_name, &block)
      setup_configuration(TableConfiguration::Partial, table_name: table_name, &block).tap do |config|
        @partial_table_configurations << config
      end
    end

    def table_configurations
      @table_configurations_map.values
    end

    def configured_tables
      @table_configurations_map.keys
    end

    def configuration_for_table(table_name)
      @table_configurations_map.fetch(table_name.to_sym)
    end

    def associated_to_table(table_name, &block)
      table_name = table_name.to_sym
      @table_configurations_map.each_value do |table_configuration|
        foreign_keys = table_configuration.foreign_keys.select do |foreign_key|
          foreign_key.to_table == table_name && foreign_key.pull
        end
        block.call(table_configuration, foreign_keys) if foreign_keys.any?
      end
    end

    private

    def prevent_same_table_configuration(table_name)
      return unless @table_configurations_map.key?(table_name)

      raise TableAlreadyDefinedError, "Table #{table_name} has been already defined"
    end

    def setup_configuration(table_configuration_class, table_name:, options: {})
      table_name = table_name.to_sym
      prevent_same_table_configuration(table_name)

      table_configuration_class.new(self, table_name, options).tap do |table_configuration|
        @table_configurations_map[table_name] = table_configuration
        yield(table_configuration) if block_given?
      end
    end
  end
end
