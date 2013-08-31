require 'rubygems' 
require 'bundler/setup'
require 'tweetstream'
require 'yaml'
require 'redis'

require './frequent_items'

# TODO: Make it configurable
$redis = Redis.new(:host => 'localhost', :port => 6379)

tweet_config = YAML.load_file("twitter.yml")

TweetStream.configure do |config|
  config.consumer_key       = tweet_config[:consumer_key]
  config.consumer_secret    = tweet_config[:consumer_secret]
  config.oauth_token        = tweet_config[:oauth_token]
  config.oauth_token_secret = tweet_config[:oauth_token_secret]
  config.auth_method        = :oauth
end

daemon = TweetStream::Daemon.new('tweetstream', :log_output => true)
daemon.track(['nasa']) do |status, client|
#TweetStream::Client.new.sample do |status|
  begin
    five_items = FrequentItems.new 5, '5_items'
    ten_items = FrequentItems.new 10, '10_items'
    twenty_items = FrequentItems.new 20, '20_items'
    fifty_items = FrequentItems.new 50, '50_items'

    puts "Receiving tweet: #{status.text} - by @#{status.user.screen_name}"

    if status.lang == 'en'
      hashtags = (status.hashtags.map{|h| h.text.downcase} - ['nasa'])
      if hashtags.length > 0
        hashtags.each{|h| five_items.add(h); ten_items.add(h); twenty_items.add(h);}

        File.open("5_items.csv", 'a+'){|f| f.puts(five_items.get_scores().join(',')) }
        File.open("10_items.csv", 'a+'){|f| f.puts(ten_items.get_scores().join(',')) }
        File.open("20_items.csv", 'a+'){|f| f.puts(twenty_items.get_scores().join(',')) }
        File.open("50_items.csv", 'a+'){|f| f.puts(fifty_items.get_scores().join(',')) }
      end
    end
    
  rescue Exception => e
    p "####################"
    p " - Exception - "
    p "e: #{e}"
    p "e: #{e.backtrace.join("\n")}"
  end
end
daemon.on_reconnect do |timeout, retries|
  p "####################"
  p " - Reconnecting - "
  p "timeout: #{timeout}"
  p "retries: #{retires}"
end
daemon.on_error do |message|
  p "####################"
  p " - Error - "
  p "message: #{message}"
end