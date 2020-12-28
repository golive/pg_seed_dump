# frozen_string_literal: true
require_relative 'base'

module PgSeedDump
  module TableConfiguration
    class Full < Base
      def full?
        true
      end
    end
  end
end
