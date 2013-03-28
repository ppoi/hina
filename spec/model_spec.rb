require 'spec_helper'

module ModelSpec
  class Helpers
    include Hina::ThreadHelper
  end
end

def save_thread(thread)
  thread.posts.each {|post| post.save}
  thread.save
end

describe 'Hina::Models' do

  describe 'Base' do
    it 'extends Subclass' do
      Hina::Models::Thread.table_name.should eq :Thread
      Hina::Models::Post.table_name.should eq :Post
    end
  end

  describe 'Thread/Post' do
    let :helpers do
      ModelSpec::Helpers.new
    end

    it 'can save(create) & load' do
      Groonga[:Thread].has_key?('vip4ssnip1355062957').should be_false

      dat = File.open("#{APP_ROOT}/spec/dat/1355062957.dat", "r") do |file|
        file.set_encoding(Encoding::SJIS, Encoding::UTF_8, :invalid=>:replace)
        file.read
      end
      thread = helpers.parse_dat('vip4ssnip1355062957', dat)
      thread.posts.each {|post| post.save}
      thread.save

      Groonga[:Thread].has_key?('vip4ssnip1355062957').should be_true
      reloaded = Hina::Models::Thread['vip4ssnip1355062957']
      reloaded.should_not be thread
      reloaded.key.should eq thread.key
      reloaded.title.should eq thread.title
      reloaded.created_date.strftime('%Y/%m/%d %H:%M:%S.%-2L').should eq thread.created_date.strftime('%Y/%m/%d %H:%M:%S.%-2L')
      reloaded.lastpost_date.strftime('%Y/%m/%d %H:%M:%S.%-2L').should eq thread.lastpost_date.strftime('%Y/%m/%d %H:%M:%S.%-2L')
      reloaded.posts.should have(1000).items
      for i in 0..999
        reloaded.posts[i].key.should eq thread.posts[i].key
        reloaded.posts[i].author.should eq thread.posts[i].author
        reloaded.posts[i].author_hash.should eq thread.posts[i].author_hash
        reloaded.posts[i].post_date.strftime('%Y/%m/%d %H:%M:%S.%-2L').should eq thread.posts[i].post_date.strftime('%Y/%m/%d %H:%M:%S.%-2L')
        reloaded.posts[i].contents.should eq thread.posts[i].contents
      end
    end

    it 'can search' do
      thread1 = Hina::Models::Thread.new('thread1', :title=>'スレッド1')
      thread1.add_post :author=>'P', :post_date=>Time.local(2013,3,25,01,39,39,39000), :contents=>'初音ミク'
      thread1.add_post :author=>'P', :post_date=>Time.local(2013,3,25,02,39,39,39000), :contents=>'鏡音リン'
      save_thread thread1

      thread2 = Hina::Models::Thread.new('thread2', :title=>'スレッド2')
      thread2.add_post :author=>'P', :post_date=>Time.local(2013,3,25,03,39,39,39000), :contents=>'鏡音レン'
      thread2.add_post :author=>'P', :post_date=>Time.local(2013,3,25,04,39,39,39000), :contents=>'巡音ルカ'
      save_thread thread2

      thread3 = Hina::Models::Thread.new('thread3', :title=>'スレッド3')
      thread3.add_post :author=>'P', :post_date=>Time.local(2013,3,25,05,39,39,39000), :contents=>'KAITO'
      thread3.add_post :author=>'P', :post_date=>Time.local(2013,3,25,06,39,39,39000), :contents=>'MEIKO'
      save_thread thread3

      thread4 = Hina::Models::Thread.new('thread4', :title=>'スレッド4')
      thread4.add_post :author=>'P', :post_date=>Time.local(2013,3,25,01,39,39,39000), :contents=>'初音ミク'
      thread4.add_post :author=>'P', :post_date=>Time.local(2013,3,25,02,39,39,39000), :contents=>'鏡音リン'
      thread4.add_post :author=>'P', :post_date=>Time.local(2013,3,25,03,39,39,39000), :contents=>'鏡音レン'
      thread4.add_post :author=>'P', :post_date=>Time.local(2013,3,25,02,39,39,39000), :contents=>'巡音ルカ'
      save_thread thread4


      result = Hina::Models::Thread.select do |record|
        record.posts.contents =~ '鏡音'
      end
      result.should have(3).items
      result.each do |record|
        p record
      end
    end
  end
end
