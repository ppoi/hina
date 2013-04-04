require 'spec_helper'

class HelperSpec
  class Helpers
    include Hina::ThreadHelper
  end
end

describe 'ThreadHelper' do

  let :helpers do
    HelperSpec::Helpers.new
  end

  describe 'DatURL' do
    it 'create from source url' do
      source = 'http://ex14.vip2ch.com/test/read.cgi/news4ssnip/1364129784/'
      url = Hina::ThreadHelper::DatURL.new(source)
      url.to_s.should eq 'http://ex14.vip2ch.com/news4ssnip/dat/1364129784.dat'
      url.thread_id.should eq '1364129784'
      url.board_name.should eq 'news4ssnip'
      url.thread_url.to_s.should.should eq source
    end

    it 'create archived url from source' do
      source = 'http://ex14.vip2ch.com/test/read.cgi/news4ssnip/1364129784/'
      url = Hina::ThreadHelper::DatURL.new(source, true)
      url.to_s.should eq 'http://ex14.vip2ch.com/news4ssnip/kako/1364/13641/1364129784.dat'
      url.thread_id.should eq '1364129784'
      url.board_name.should eq 'news4ssnip'
      url.thread_url.to_s.should.should eq source
    end

    it 'create from mobile url' do
      source = 'http://ex14.vip2ch.com/i/response.html?bbs=news4ssnip&dat=1364129784'
      url = Hina::ThreadHelper::DatURL.new(source)
      url.to_s.should eq 'http://ex14.vip2ch.com/news4ssnip/dat/1364129784.dat'
      url.thread_id.should eq '1364129784'
      url.board_name.should eq 'news4ssnip'
      url.thread_url.to_s.should.should eq 'http://ex14.vip2ch.com/test/read.cgi/news4ssnip/1364129784/'
    end

    it 'change to archived url' do
      source = 'http://ex14.vip2ch.com/test/read.cgi/news4ssnip/1364129784/'
      url = Hina::ThreadHelper::DatURL.new(source)
      url.archived!.to_s.should eq 'http://ex14.vip2ch.com/news4ssnip/kako/1364/13641/1364129784.dat'
    end
  end

  describe 'module methods' do
    it 'parse dat' do
      dat = File.open("#{APP_ROOT}/spec/dat/1355062957.dat", "r") do |file|
        file.set_encoding(Encoding::SJIS, Encoding::UTF_8, :invalid=>:replace)
        file.read
      end
      thread = helpers.parse_dat('vip4ssnip1355062957', dat)
      thread.title.should eq "【咲SS】　京太郎「鹿児島で巫女さん！」　初美「13スレ目、幸せでした……」【安価】"
      thread.posts[0].author.should eq '◆tIyvKbQmDwyE'
      thread.posts[0].post_date.strftime('%Y/%m/%d %H:%M:%S.%-2L').should eq "2012/12/09 23:22:38.13"
      thread.posts.should have(1000).items
    end

    it 'get dat', :if=>false do
      url = helpers.get_dat_url('http://ex14.vip2ch.com/test/read.cgi/news4ssnip/1362052790/')
      dat = helpers.get_dat(url, Time.now)
      p dat
      p helpers.parse_dat('news4ssnip1362052790', dat) unless dat.nil?
    end
  end
end
