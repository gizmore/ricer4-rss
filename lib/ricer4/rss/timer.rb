module Ricer4::Plugins::Rss
  class Timer < Ricer4::Plugin
    
    def plugin_init
      arm_subscribe("ricer/ready") do
        service_threaded do
          loop do
            check_feeds
            sleep(60)
          end
        end
      end
    end

    def check_feeds
      Feed.all.enabled.each do |feed|
        begin
          feed.check_feed
        rescue => e
          send_exception(e)
        ensure 
          sleep(5)
        end
      end
    end
    
  end
end
