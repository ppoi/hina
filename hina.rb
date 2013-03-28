APP_ENVIRONMENT = (ENV['RACK_ENV'] || 'development').to_sym unless defined?(APP_ENVIRONMENT)
APP_ROOT = File.expand_path('..', __FILE__)

require 'rubygems'
require 'bundler/setup'
Bundler.require(:default, APP_ENVIRONMENT)

require 'net/http'

Groonga::Database.open "#{APP_ROOT}/db/hina.db"

module Hina

  module Models
    class Base
      class << self
        @@entity_map = {}

        def inherited(subclass)
          table_name = subclass.name.split('::')[-1].to_sym
          table = Groonga[table_name]
          columns = table.columns
          attributes = []
          columns.each do |column|
            next if column.index?
            column_name = column.local_name.to_sym
            attributes << column_name
            define_method column_name do
              @values[column_name]
            end
            define_method "#{column_name}=" do |value|
              @modified_attributes << column_name unless @modified_attributes.nil? or @modified_attributes.include? column_name
              @values[column_name] = value
            end
          end
          subclass.class_variable_set(:@@table_name, table_name)
          subclass.class_variable_set(:@@table, table)
          subclass.class_variable_set(:@@attributes, attributes)
          @@entity_map[table_name] = subclass
        end

        def table_name
          class_variable_get(:@@table_name)
        end

        def attributes
          class_variable_get(:@@attributes)
        end

        def table
          class_variable_get(:@@table)
        end

        def [](key)
          record = Groonga[table_name][key]
          new record unless record.nil?
        end

        def select(&block)
          table = Groonga[table_name]
          query_result = table.select(&block)
          result_list = []
          query_result.each do |record|
            result_list << new(record)
          end
          result_list
        end
      end

      def initialize(*args)
        if args.first.is_a? Groonga::Record
          record = args.first
          @key = record._key
          @values = {}
          self.class.attributes.each do |attr|
            value = record[attr]
            column = self.class.table.column(attr)
            if column.reference?
              entity_class = @@entity_map[column.range.name.to_sym]
              if column.vector?
                value = value.map {|subrecord| entity_class.new(subrecord) }
              else
                value = entity_class.new(value)
              end
            end
            @values[attr] = value
          end
          @stored = true
          @modified_attribtues = []
        else
          @key = args.first
          @values = args[1]
          @storead = false
        end
      end

      def key
        @key
      end

      def save
        @stored ? update : create
      end

      def create
        values = {}
        @values.each do |key, value|
          next if value.nil?
          column = self.class.table.column key
          if column.reference?
            if column.vector?
              value = value.map {|item| item.key}
            else
              value = value.key
            end
          end
          values[key] = value
        end
        self.class.table.add @key, values
        @stored = true
      end

      def update
        unless @modified_attributes.nil? or @modified_attributes.empty?
          record = self.class.table[@key]
          @modified_attributes.each do |attr|
            value = @values[attr]
            column = self.class.table.column attr
            if not value.nil? and column.reference?
              if column.vector?
                value = value.map {|item| item.key }
              else
                value = value.key
              end
            end
            record[attr] = value
          end
        end
      end

      def delete
        Groonga[table_name].delete(key)
      end
    end

    class Thread < Base

      def add_post(post={})
        posts = self.posts || []
        if post.is_a? Hash
          post = Post.new "#{key}:#{posts.size + 1}", post
        end
        self.created_date = post.post_date if created_date.nil?
        self.lastpost_date = post.post_date
        self.posts = (posts << post)
        self.post_count = posts.size
      end
    end

    class Post < Base
    end
  end

  module ThreadHelper

    class InvalidDatFormatError < Exception
    end

    def request(source_url)
      url = get_dat_url source_url
      request = Net::HTTP::Get.new(url.path)
      response = Net::HTTP.start url.host, url.port do |http|
        http.request(request)
      end
      return response.body
    end

    def parse_dat(thread_id, dat)
      thread = nil
      dat.each_line do |line|
        fragments = line.split /\s*<>\s*/
        raise InvalidDatFormatError.new "#{fragments.to_s}/#{thread.posts.size}" if fragments.size < 4

        thread = Models::Thread.new(thread_id, title:fragments[-1].strip!) if thread.nil?
        post = { author:fragments[0], mail:fragments[1], contents:fragments[3] }
        if %r!(\d+)/(\d+)/(\d+)\(.+\)\s+(\d+):(\d+):(\d+)\.(\d+)\s+ID:(\S+)! === fragments[2]
          post[:post_date] = Time.local($1, $2, $3, $4, $5, $6, "#{$7}0000")
          post[:author_hash] = $8
        elsif thread.posts.size >= 1000
          break
        else
          raise InvalidDatFormatError.new fragments.to_s
        end
        thread.add_post post
      end
      return thread
    end

    def get_dat_url(source_url, archived=false)
      if not source_url.is_a? URI::Generic
        source_url = URI.parse source_url.to_s
      end

      path = source_url.path.split '/'
      if path.size < 2
        raise URI::InvalidURIError
      end
      board_name = path[-2]
      thread_id = path[-1]
      if archived
        source_url.merge "/#{board_name}/kako/#{thread_id[0,4]}/#{thread_id[0,5]}/#{thread_id}.dat"
      else
        source_url.merge "/#{board_name}/dat/#{thread_id}.dat"
      end
    end

  end

  class Application < Sinatra::Base

    helpers do
      include ThreadHelper
    end

    get '/thread' do
    end

    get '/thread/:thread_id' do
    end

    put '/thread' do
    end

    post '/thread/:thread_id' do
    end

    get '/tag' do
    end

    get '/tag/:tag_name' do
    end

    put '/tag' do
    end

    post '/tag/:tag_name' do
    end

    delete '/tag/:tag_name' do
    end

  end
end

