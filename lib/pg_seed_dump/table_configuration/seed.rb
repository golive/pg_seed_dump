# frozen_string_literal: true
require_relative 'base'

module PgSeedDump
  module TableConfiguration
    class Seed < Base
      attr_accessor :seed_query
      attr_writer :can_grow

      def can_grow?
        @can_grow
      end

      def seed?
        true
      end
    end
  end
end
