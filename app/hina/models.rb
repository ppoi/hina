require 'hina/groonga'

module Hina
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
end

