APP_ENVIRONMENT = (ENV['RACK_ENV'] || 'development').to_sym unless defined?(APP_ENVIRONMENT)
APP_ROOT = File.expand_path('..', __FILE__)

require 'rubygems'
require 'bundler/setup'
Bundler.require(:default, APP_ENVIRONMENT)

require 'json'
require 'net/http'

Groonga::Database.open "#{APP_ROOT}/db/hina.db"

class Time

  def to_json(*a)
    "\"#{strftime('%Y/%m/%d %H:%M:%S.%-2L')}\""
  end

end

module Hina

  class Model

    module ModelExtensionMethods

      def entity_map
        @@entity_map ||= {}
      end

      def inherited(subclass)
        super
        table_name = subclass.name.split('::')[-1].to_sym
        table = Groonga[table_name]
        subclass.setup_model(table)
        entity_map[table_name] = subclass
      end

      protected
      def setup_model(table)
        @table = table
        @attributes = table.columns.map do |column|
          attr_name = column.local_name.to_sym
          define_attribute(attr_name)
          attr_name
        end
        extend ClassMethods
        include InstanceMethods
      end

      def define_attribute(name)
        define_method name do
          @values[name]
        end
        define_method "#{name}=" do |value|
          @modified_attributes << name unless @modified_attributes.nil? or @modified_attributes.include? name
          @values[name] = value
        end
      end
    end

    module ClassMethods
      attr_reader :table, :attributes

      def [](key, options={})
        record = table[key]
        record.nil? ? nil : new(record, options)
      end

      def select(options={}, &block)
        groonga_options = options.reject {|k,v| k.to_s.start_with?('model_')}
        table.select(groonga_options, &block).map do |record|
          new(record, options)
        end
      end
    end

    module InstanceMethods
      attr_reader :key

      def initialize(*args)
        if args.first.is_a? Groonga::Record
          sync(*args)
        else
          @key = args.first
          @values = args[1]
          @storead = false
        end
      end

      def sync(record=nil, options={})
        if @stored and record.nil?
          record = self.class.table[key]
        end
        unless record.nil?
          @key = record._key
          @values = {}
          target_attributes = options[:model_includes] || self.class.attributes
          target_attributes -= options[:model_excludes] if options.has_key?(:model_excludes)
          target_attributes.each do |attr|
            column = self.class.table.column(attr)
            next if column.index?
            value = record[attr]
            if column.reference?
              entity_class = self.class.entity_map[column.range.name.to_sym]
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
        end
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
          record = self.class.table[key]
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
        self.class.delete(key)
      end

      def to_json(*a)
        values = @values.dup
        values[:key] = key
        values.to_json
      end
    end

    extend ModelExtensionMethods
  end

  module Models
    class Thread < Hina::Model

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

    class Post < Hina::Model
    end
  end

  module ThreadHelper

    class DatURL < URI::HTTP
      def initialize(thread_url, archived=false)
        if not thread_url.is_a? URI::Generic
          thread_url = URI.parse thread_url.to_s
        end

        if thread_url.query.nil?
          paths = thread_url.path.split '/'
          if paths.size < 2
            raise URI::InvalidURIError
          end
          @board_name = paths[-2]
          @thread_id = paths[-1]
          @thread_url = thread_url
        else
          q = Hash[URI.decode_www_form(thread_url.query)]
          unless q.has_key?('board') and q.has_key?('dat')
            raise URI::InvalidURIError
          end
          @board_name = q['board']
          @thread_id = q['dat']
          @thread_url = thread_url.merge("/test/read.cgi/#{@board_name}/#{@thread_id}/")
        end

        @archived = archived
        path = archived ? "/#{board_name}/kako/#{thread_id[0,4]}/#{thread_id[0,5]}/#{thread_id}.dat"
                        : "/#{board_name}/dat/#{thread_id}.dat"
        super thread_url.scheme, thread_url.userinfo, thread_url.host, thread_url.port, nil, path, nil, nil, nil, false
      end

      def archived!
        unless archived?
          self.path = "/#{board_name}/kako/#{thread_id[0,4]}/#{thread_id[0,5]}/#{thread_id}.dat"
          @archived = true
        end
        self
      end

      def archived?
        @archived
      end

      attr_accessor :thread_id, :board_name, :thread_url
    end

    class InvalidDatFormatError < Exception
    end

    def get_dat(url, modified_since=nil)
      if url.is_a? String
        url = URI.parse url
      end
      p modified_since
      req = Net::HTTP::Get.new(url.path)
      req['If-Modified-Since'] = modified_since.httpdate unless modified_since.nil?
      p req['If-Modified-Since']
      http = Net::HTTP.new(url.host, url.port)
      #http.set_debug_output(STDOUT)
      res = http.start do |http|
        http.request(req)
      end
      if res.is_a? Net::HTTPOK
        res.body.encode(Encoding::UTF_8, Encoding::Windows_31J, :invalid=>:replace, :undef=>:replace)
      elsif res.is_a? Net::HTTPFound
        get_dat(res['Location'])
      elsif res.is_a? Net::HTTPNotModified
        nil
      else
        res.value
      end
    end

    def parse_dat(thread_id, dat)
      thread = nil
      dat.each_line do |line|
        fragments = line.split /\s*<>\s*/
        raise InvalidDatFormatError.new "#{fragments.to_s}/#{thread.posts.size}" if fragments.size < 4

        thread = Models::Thread.new(thread_id, title:fragments[-1].strip!) if thread.nil?
        post = { author:fragments[0].gsub(%r@</b>\s*(◆.*)<b>@, '\1'), mail:fragments[1], contents:fragments[3] }
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

    def get_thread(source_url, modified_since=nil)
      dat_url = ThreadHelper::DatURL.new source_url
      thread_id = "#{dat_url.board_name}:#{dat_url.thread_id}"
      dat = nil
      begin
        p "#{dat_url} #{modified_since}"
        dat = get_dat(dat_url, modified_since)
      rescue Net::HTTPExceptions=>e
        p "NotFound!: #{e}"
        dat = get_dat(dat_url.archived!)
      end

      unless dat.nil?
        p "Found: #{dat_url}"
        thread = parse_dat(thread_id, dat)
        thread.archived = dat_url.archived?
        thread.source_url = dat_url.thread_url.to_s
        thread
      else
        p 'Not Modified' 
        nil
      end
    end
  end

  class Application < Sinatra::Base

    helpers Sinatra::JSON, ThreadHelper

    configure do
      set :json_encoder, :to_json
    end


    get '/thread' do
      threadlist = Models::Thread.select(:model_excludes=>[:posts])
      json :count=>threadlist.size, :threadlist=>threadlist
    end

    get '/thread/:thread_id' do
      thread_id = params[:thread_id]
      thread = Models::Thread[thread_id, :model_excludes=>[:posts]]
      if thread.nil?
        404
      end
      if thread.archived
        thread.sync
      else
        latest = get_thread(thread.source_url, thread.lastpost_date)
        if not latest.nil? and thread.archived != latest.archived and thread.post_count != latest.post_count
          added_post_count = latest.post_count - thread.post_count
          if added_post_count > 0
            latest.posts[thread.post_count, added_post_count].each do |post|
              post.save
            end
            thread.lastpost_date = latest.lastpost_date
            thread.post_count = latest.post_count
            thread.posts = latest.posts
          end
          thread.archived = latest.archived unless thread.archived == latest.archived
          thread.save
        else
          thread.sync
        end
      end
      json thread
    end

    put '/thread' do
      thread = get_thread(params[:source_url])
      thread.posts.each do |post|
        post.save
      end
      thread.save
      json :key=>thread.key, :title=>thread.title, :post_count=>thread.post_count
    end

  end
end

