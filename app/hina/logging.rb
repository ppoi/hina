require 'logger'
require 'singleton'

module Hina

  class Logging
    include Singleton

    def initialize

      case Config[:stream]
        when :stdout then logdev = STDOUT
        else logdev = STDOUT
      end

      case Config[:log_level]
        when :debug then log_level = ::Logger::DEBUG
        when :info  then log_level = ::Logger::INFO
        when :warn  then log_level = ::Logger::WARN
        when :error then log_level = ::Logger::ERROR
        when :fatal then log_level = ::Logger::FATAL
        else log_level = Logger::INFO
      end

      @logger = Logger.new(logdev)
      @logger.level = log_level
    end

    def debug(msg)
      @logger.debug(msg)
    end

    def info(msg)
      @logger.info(msg)
    end

    def warn(msg)
      @logger.info(msg)
    end

    def error(msg)
      @logger.error(msg)
    end

    def fatal(msg)
      @logger.fatal(msg)
    end

    Config = {
      log_level: :warn,
      stream: :stdout
    }

  end

end

module Kernel
  def logs
    return Hina::Logging.instance
  end
end

