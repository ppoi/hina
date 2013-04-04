APP_ENVIRONMENT = (ENV['RACK_ENV'] || 'development').to_sym unless defined?(APP_ENVIRONMENT)
APP_ROOT = File.expand_path('../..', __FILE__)

$:.unshift "#{APP_ROOT}/app".untaint

require 'rubygems'
require 'bundler/setup'
Bundler.require(:default, APP_ENVIRONMENT)

Groonga::Database.open "#{APP_ROOT}/db/hina.db"

