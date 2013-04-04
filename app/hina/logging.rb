require 'logger'
require 'singleton'

module Hina

  class Logging
    include Singleton

    def initialize

      logdev = case Config[:stream]
        when :stdout then STDOUT
        when :to_file then
          log_file = Config.has_key?(:log_file) ? Config[:log_file] : "#{APP_ROOT}/logs/hina.#{APP_ENVIRONMENT}.log"
          file = open(log_file, 'a')
          file.sync = true
          file
        else STDOUT
      end

      log_level = case Config[:log_level]
        when :debug then ::Logger::DEBUG
        when :info  then ::Logger::INFO
        when :warn  then ::Logger::WARN
        when :error then ::Logger::ERROR
        when :fatal then ::Logger::FATAL
        else ::Logger::INFO
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

    def level
      @logger.level
    end

    def debug?
      @logger.level >= ::Logger::DEBUG
    end

    def info?
      @logger.level >= ::Logger::INFO
    end

    def warn?
      @logger.level >= ::Logger::WARN
    end

    def error?
      @logger.level >= ::Logger::ERROR
    end

    def fatal?
      @logger.level >= ::Logger::FATAL
    end

    Config = {
      log_level: :warn,
      stream: :stdout
    }

  end

end

module Kernel
  def logging
    return Hina::Logging.instance
  end
end

