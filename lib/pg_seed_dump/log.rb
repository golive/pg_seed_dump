require "logger"

module PgSeedDump
  module Log
    module_function

    def warn(value, &block)
      logger&.warn(value, &block)
    end

    def info(value, &block)
      logger&.info(value, &block)
    end

    def debug(value, &block)
      logger&.debug(value, &block)
    end

    def error(value, &block)
      logger&.error(value, &block)
    end

    def setup(file_path, debug: false)
      @logger = ::Logger.new(file_path).tap do |logger|
        logger.level = debug ? ::Logger::DEBUG : ::Logger::INFO
        logger.formatter = proc do |severity, datetime, progname, msg|
          progname = "[#{progname}] " if progname
          output = "[#{datetime}] #{severity.rjust(5)}: #{progname}#{msg}\n"
          puts output unless severity == 'DEBUG' && debug == 'file'
          output
        end
      end
    end

    def logger
      @logger
    end
  end
end