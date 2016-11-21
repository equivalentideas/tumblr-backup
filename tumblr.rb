require 'dotenv'
require 'tumblr_client'
require 'json'
require 'pry'

Dotenv.load

Tumblr.configure do |config|
  config.consumer_key = ENV['CONSUMER_KEY']
  config.consumer_secret = ENV['CONSUMER_SECRET']
  config.oauth_token = ENV['OAUTH_TOKEN']
  config.oauth_token_secret = ENV['OAUTH_TOKEN_SECRET']
end

# the hash to be saved into JSON file
@postsHash = {}

# offset count for pagination
@posts_offset = 0

def request_posts (offset)
  client = Tumblr::Client.new
  client.posts('oliverbone.com', :offset => offset)
end

# initial request
@posts_whole = request_posts(@posts_offset)

# save total post count
@total_posts_count = @posts_whole['total_posts']

# track progress
@saved_posts_count = 0

# set posts to process
@posts = @posts_whole['posts']

def process_posts (posts)
  posts.each do |post|
    timestamp = post['timestamp']
    caption = post['caption']
    post_type = post['type']
    photos_array = []

    if post_type == 'photo'
      post['photos'].each do |photo, index|
        photos_array.push(photo['original_size'])
      end
    end

    @postsHash[post['id']] = {
      'timestamp': timestamp,
      'type': post_type,
      'caption': caption,
      'photos': photos_array
    }
    @saved_posts_count += 1
    puts @saved_posts_count

    if @saved_posts_count == @posts_offset + 20
      @posts_offset += 20
      request_next_page(@posts_offset)
    elsif @saved_posts_count == @total_posts_count
      posts_to_json(@postsHash)
      puts 'Done!'
      return
    end
  end

end

def request_next_page (offset)
  @next_page = request_posts(offset)
  process_posts(@next_page['posts'])
end

def posts_to_json (hash)
  File.open('data/posts.json', 'w') do |f|
    f.write(JSON.pretty_generate(hash))
  end
end

# Let's begin!
process_posts(@posts)
