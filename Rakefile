APP_ROOT = File.dirname(__FILE__) unless defined? APP_ROOT

task :environment do
  APP_ENVIRONMENT = (ENV['RACK_ENV'] || 'development').to_sym unless defined?(APP_ENVIRONMENT)
  require 'rubygems'
  require 'bundler/setup'
  Bundler.require(:default, APP_ENVIRONMENT)
end

namespace :grn do
  dbpath = "#{APP_ROOT}/db/hina.db"

  namespace :db do
    task :create => :environment do
      dbdir = File.dirname(dbpath)
      Dir.mkdir dbdir unless Dir.exists? dbdir    
      Groonga::Context.default_options = {encoding: :utf8}
      Groonga::Database.create :path=>dbpath
    end
  end

  namespace :schema do
    task :create => :environment do
      Groonga::Database.open(dbpath)
      Groonga::Schema.define do |schema|
        schema.create_table :Tag, :type=>:hash, :key_type=>'short_text'

        schema.create_table :Post, :type=>:hash, :key_type=>'short_text' do |table|
          table.short_text :author
          table.short_text :author_hash
          table.short_text :mail
          table.time :post_date
          table.text :contents
        end

        schema.create_table :Thread, :type=>:hash, :key_type=>'short_text' do |table|
          table.text :title
          table.time :created_date
          table.time :lastpost_date
          table.int16 :post_count
          table.short_text :note
          table.short_text :source_url
          table.time :last_checked
          table.boolean :archived
          table.reference :posts, :Post, :type=>:vector
          table.reference :tags, :Tag, :type=>:vector
        end

        schema.change_table :Tag do |table|
          table.index 'Thread.tags'
        end
        schema.change_table 'Post' do |table|
          table.index 'Thread.posts'
        end
        schema.create_table :Lexicon, 
            :type=>:patricia_trie, :default_tokenizer=>'TokenBigramSplitSymbolAlphaDigit' do |table|
          table.index 'Thread.title'
          table.index 'Post.contents'
          table.index 'Tag._key'
        end
      end
    end
  end
end

