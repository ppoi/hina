require 'net/http'
require 'hina/models'

module Hina

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
        unless q.has_key?('bbs') and q.has_key?('dat')
          raise URI::InvalidURIError
        end
        @board_name = q['bbs']
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

  module Helpers

    module BBSHelper
      def get_dat(url, modified_since=nil)
        if url.is_a? String
          url = URI.parse url
        end
        req = Net::HTTP::Get.new(url.path)
        req['If-Modified-Since'] = modified_since.httpdate unless modified_since.nil?
        http = Net::HTTP.new(url.host, url.port)
        #http.set_debug_output(STDOUT)
        res = http.start do |http|
          http.request(req)
        end
        logging.debug "request to <#{url}>, return #{res.code}"
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
          fragments = line.split /\s*<>\s*/, 5
          raise Hina::InvalidDatFormatError.new "#{fragments.to_s}/#{thread.posts.size}" if fragments.size < 4
  
          thread = Hina::Models::Thread.new(thread_id, title:fragments[-1].strip!) if thread.nil?
          post = { author:fragments[0].gsub(%r@</b>\s*(◆.*)<b>@, '\1'), mail:fragments[1], contents:fragments[3] }
          if %r!(\d+)/(\d+)/(\d+)\(.+\)\s+(\d+):(\d+):(\d+)\.(\d+)\s+ID:(\S+)! === fragments[2]
            post[:post_date] = Time.local($1, $2, $3, $4, $5, $6, "#{$7}0000")
            post[:author_hash] = $8
          elsif thread.posts.size >= 1000
            break
          elsif fragments[2] == '移転'
            post[:author_hash] = '移転'
          else
            raise Hina::InvalidDatFormatError.new "#{fragments.to_s}/#{thread.posts.size}"
          end
          thread.add_post post
        end
        return thread
      end
  
      def get_thread(source_url, modified_since=nil)
        dat_url = Hina::DatURL.new source_url
        thread_id = "#{dat_url.board_name}:#{dat_url.thread_id}"
        dat = nil
        begin
          dat = get_dat(dat_url, modified_since)
        rescue Net::HTTPExceptions=>e
          dat = get_dat(dat_url.archived!)
        end
  
        unless dat.nil?
          logging.debug "Found: #{dat_url}"
          thread = parse_dat(thread_id, dat)
          thread.archived = dat_url.archived?
          thread.source_url = dat_url.thread_url.to_s
          thread
        else
          logging.debug 'Not Modified' 
          nil
        end
      end
    end

  end
end
