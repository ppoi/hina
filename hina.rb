APP_ENVIRONMENT = (ENV['RACK_ENV'] || 'development').to_sym unless defined?(APP_ENVIRONMENT)
APP_ROOT = File.expand_path('..', __FILE__)

require 'rubygems'
require 'bundler/setup'
Bundler.require(:default, APP_ENVIRONMENT)

require 'net/http'

Groonga::Database.open "#{APP_ROOT}/db/hina.db"

module Hina

  module Models
    class Thread

      class << self
        @@table = Groonga[:Thread]

        def get(id, include_posts=true)
          record = @@table[id]
          if record.nil?
            return nil
          else
            thread = Thread.new(id, :title=>record['title'])
            if include_posts
              record[:posts].each do |post|
                thread.add_post Post[post.key]
              end
            else
              thread.created_date = record[:created_date]
              thread.lastpost_date = record[:lastpost_date]
            end
            return thread
          end
        end

        def [](id)
          return self.get(id, true)
        end
      end

      def initialize(id, title:nil, posts:[])
        @id = id
        @title = title
        @posts = posts
        if posts.size > 0
          @created_date = posts[0].post_date
          @lastpost_date = posts[-1].post_date
        end
      end

      def add_post(post)
        post.thread_id = @id
        post.post_number = @posts.size
        @created_date = post.post_date if @posts.empty?
        @lastpost_date = post.post_date
        @posts << post
      end

      attr_accessor :id, :title, :created_date, :lastpost_date
      attr_reader :posts
    end

    class Post

      class << self
        @@table = Groonga[:Post]

        def [](record_key)
          record = @@table[record_key]
          if record.nil?
            return nil
          else
            return Post.new :author=>record[:author], :author_hash=>record[:author_hash], :mail=>record['mail'],
                :post_date=>record[:post_date], :contents=>record[:contents]
          end
        end
      end

      def initialize(thread_id:nil, post_number:nil, visible:false,
          author:nil, author_hash:nil, mail:nil, post_date:nil, contents:nil)
        @author = author
        @author_hash = author_hash
        @mail = mail
        @post_date = post_date
        @contents = contents
        @visible = visible
      end
      attr_accessor :thread_id, :post_number, :visible, :author, :author_hash, :mail, :post_date, :contents
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
        post = Models::Post.new(author:fragments[0], mail:fragments[1], contents:fragments[3])
        if %r!(\d+)/(\d+)/(\d+)\(.+\)\s+(\d+):(\d+):(\d+)\.(\d+)\s+ID:(\S+)! === fragments[2]
          post.post_date = Time.local($1, $2, $3, $4, $5, $6, "#{$7}0000")
          post.author_hash = $8
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

