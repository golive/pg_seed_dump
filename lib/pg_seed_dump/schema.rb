# frozen_string_literal: true
require "pg_seed_dump/table_configuration/seed"
require "pg_seed_dump/table_configuration/full"
require "pg_seed_dump/table_configuration/partial"

module PgSeedDump
  class Schema
    attr_accessor :dump_all_db_objects
    attr_reader :seed_table_configurations,
                :full_table_configurations,
                :partial_table_configurations

    TableNotExistsError = Class.new(StandardError)
    ColumnNotExistsError = Class.new(StandardError)
    TableAlreadyDefinedError = Class.new(StandardError)

    def initialize
      @dump_all_db_objects = false
      @table_configurations_map = {}
      @seed_table_configurations = []
      @full_table_configurations = []
      @partial_table_configurations = []
    end

    %i[seed full partial].each do |type|
      define_method "add_#{type}_configuration" do |table_configuration|
        table_name = table_configuration.table_name
        prevent_same_table_configuration(table_name)

        @table_configurations_map[table_name] = table_configuration
        send("#{type}_table_configurations") << table_configuration
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
  end
end
