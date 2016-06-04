module Ricer4::Plugins::Rss
  class Rss < Ricer4::Plugin
    
    trigger_is 'feed'

    has_subcommands
    
    has_usage
    def execute
      rply(:msg_stats,
        total_feeds: Feed.count,
        user_abbos: Feed.abbonements_for(Ricer4::User).count,
        channel_abbos: Feed.abbonements_for(Ricer4::Channel).count,
      )
    end

  end
end
