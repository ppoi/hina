require 'spec_helper'
require 'hina/models'
require 'hina/helpers'

module ModelSpec
  class Helpers
    include Hina::Helpers::BBSHelper
  end
end

def save_thread(thread)
  thread.posts.each {|post| post.save}
  thread.save
end

describe 'Hina::Models' do

  describe 'Base' do
    it 'extends Subclass' do
      
    end
  end

  describe 'Thread/Post' do
    let :helpers do
      ModelSpec::Helpers.new
    end

    it 'can save(create) & load' do
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

    it 'can save(update) & load' do
      thread = Hina::Models::Thread.new('thread1', :title=>'スレッド1')
      thread.add_post :author=>'「」', :post_date=>Time.local(2013,3,25,01,39,39,390000), :contents=>'レス1'
      thread.save

      thread = Hina::Models::Thread['thread1']
      thread.should_not be_nil

      thread.add_post :author=>'「」', :post_date=>Time.local(2013,3,25,02,39,39,390000), :contents=>'レス2'
      thread.save

      reload = Hina::Models::Thread['thread1']
      reload.should_not be_nil
      reload.post_count.should eq 2
      reload.posts.should have(2).items
      reload.lastpost_date.to_json.should eq '"2013/03/25 02:39:39.39"'
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
      result[0].key.should eq 'thread1'
      result[0].posts.should_not be_nil
      result[0].posts.should have(2).items
      result[0].posts[0].key.should eq 'thread1:1'
      result[0].posts[1].key.should eq 'thread1:2'
      result[1].key.should eq 'thread2'
      result[1].posts.should_not be_nil
      result[1].posts.should have(2).items
      result[1].posts[0].key.should eq 'thread2:1'
      result[1].posts[1].key.should eq 'thread2:2'
      result[2].key.should eq 'thread4'
      result[2].posts.should_not be_nil
      result[2].posts.should have(4).items
      result[2].posts[0].key.should eq 'thread4:1'
      result[2].posts[1].key.should eq 'thread4:2'
      result[2].posts[2].key.should eq 'thread4:3'
      result[2].posts[3].key.should eq 'thread4:4'

      result = Hina::Models::Thread.select(:excludes=>[:posts]) do |record|
        record.posts.contents =~ '初音ミク'
      end
      result.should have(2).items
      result[0].key.should eq 'thread1'
      result[0].posts.should be_nil
      result[1].key.should eq 'thread4'
      result[1].posts.should be_nil

      result = Hina::Models::Thread.select
      result.should have(4).items
    end


    it 'can sort' do
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


      result = Hina::Models::Thread.select(:sort=>[['created_date',:asc],['title',:desc]])
      result.should have(4).items
      result[0].key.should eq 'thread4'
      result[1].key.should eq 'thread1'
      result[2].key.should eq 'thread2'
      result[3].key.should eq 'thread3'
    end

    it 'can limit' do
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


      result = Hina::Models::Thread.select(:offset=>1, :limit=>2)
      result.should have(2).items
      result[0].key.should eq 'thread2'
      result[1].key.should eq 'thread3'

      result = Hina::Models::Thread.select(:limit=>2)
      result.should have(2).items
      result[0].key.should eq 'thread1'
      result[1].key.should eq 'thread2'

      result = Hina::Models::Thread.select(:offset=>1)
      result.should have(3).items
      result[0].key.should eq 'thread2'
      result[1].key.should eq 'thread3'
      result[2].key.should eq 'thread4'

      result = Hina::Models::Thread.select(:sort=>[['created_date',:asc],['title',:desc]], :offset=>1, :limit=>2)
      result.should have(2).items
      result[0].key.should eq 'thread1'
      result[1].key.should eq 'thread2'
    end
  end
end
