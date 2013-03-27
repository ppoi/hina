require 'spec_helper'

class TestApp
  include Hina::ThreadHelper
end

describe 'ThreadHelper' do

  let :helpers do
    TestApp.new
  end

  it 'get dat url from source url' do
    url =  helpers.get_dat_url 'http://ex14.vip2ch.com/test/read.cgi/news4ssnip/1362581171/'
    url.to_s.should eq 'http://ex14.vip2ch.com/news4ssnip/dat/1362581171.dat'
  end

  it 'get archived dat url from source url' do
    url = helpers.get_dat_url 'http://ex14.vip2ch.com/test/read.cgi/news4ssnip/1358161445/', :archived=>true
    url.to_s.should eq 'http://ex14.vip2ch.com/news4ssnip/kako/1358/13581/1358161445.dat'
  end

  it 'parse dat' do
    dat = File.open("#{APP_ROOT}/spec/dat/1355062957.dat", "r") do |file|
      file.set_encoding(Encoding::SJIS, Encoding::UTF_8, :invalid=>:replace)
      file.read
    end
    thread = helpers.parse_dat('vip4ssnip1355062957', dat)
    thread.title.should eq "【咲SS】　京太郎「鹿児島で巫女さん！」　初美「13スレ目、幸せでした……」【安価】"
    thread.posts[0].post_date.strftime('%Y/%m/%d %H:%M:%S.%-2L').should eq "2012/12/09 23:22:38.13"
    thread.posts.should have(1000).items
  end
end
