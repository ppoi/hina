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
      logging.debug(params)
      keyword = params[:keyword]
      archived = params[:archived] == 'true'
      sort_key = params[:sort]
      sort_dir = params[:sort_dir]

      options = {:excludes=>[:posts], :sort=>[['_id', :desc]]}
      options[:sort][0][0] = sort_key unless sort_key.nil? or sort_key.empty?
      options[:sort][0][1] = sort_dir.to_sym unless sort_dir.nil? or sort_dir.empty?
      threadlist = Hina::Models::Thread.select(options) do |record|
        keyword_cond = ((record.title =~ keyword) | (record.posts.contents =~ keyword)) unless keyword.nil? or keyword.empty?
        archived_cond = (record.archived == false) unless archived
        if keyword_cond.nil? and archived_cond.nil?
          record
        elsif keyword_cond.nil?
          archived_cond
        elsif archived_cond.nil?
          keyword_cond
        else
          archived_cond  & keyword_cond
        end
      end
      json :total=>Hina::Models::Thread.table.size, :count=>threadlist.size, :threadlist=>threadlist
    end

    get '/thread/:thread_id' do
      thread_id = params[:thread_id]
      standalone = params[:standalone] == 'true'
      thread = Hina::Models::Thread[thread_id, :excludes=>[:posts]]
      if thread.nil?
        404
      end
      if thread.archived or standalone
        thread.sync
      else
        latest = get_thread(thread.source_url, thread.lastpost_date)
        if not latest.nil? and (thread.archived != latest.archived or thread.post_count != latest.post_count)
          logging.debug("Update!")
          added_post_count = latest.post_count - thread.post_count
          if added_post_count > 0
            logging.debug("Add #{added_post_count} posts to #{thread.key}") if logging.debug?
            latest.posts[thread.post_count, added_post_count].each do |post|
              logging.debug("add #{post.key}")
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

