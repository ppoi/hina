require File.expand_path('../app/boot', __FILE__)
require 'hina/models'
require 'hina/helpers'

module Hina

  class Application < Sinatra::Base
    helpers Sinatra::JSON, Hina::Helpers::BBSHelper

    configure do
      set :json_encoder, :to_json
    end


    get '/thread' do
      threadlist = Hina::Models::Thread.select(:model_excludes=>[:posts])
      json :count=>threadlist.size, :threadlist=>threadlist
    end

    get '/thread/:thread_id' do
      thread_id = params[:thread_id]
      thread = Hina::Models::Thread[thread_id, :model_excludes=>[:posts]]
      if thread.nil?
        404
      end
      if thread.archived
        thread.sync
      else
        latest = get_thread(thread.source_url, thread.lastpost_date)
        if not latest.nil? and (thread.archived != latest.archived or thread.post_count != latest.post_count)
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

