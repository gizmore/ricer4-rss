module Ricer4::Plugins::Rss
  class Add < Ricer4::Plugin
    
    trigger_is "feed.add"
    
    permission_is :operator
    
    has_usage  '<name> <url>', function: :execute
    def execute(name, url)
      
      return rply :err_dup_name if Feed.by_name(name)
      if feed = Feed.by_url(url)
        return rply :err_dup_url, name: feed.name
      end
      
      feed = Feed.new({name:name, url:url, user:user})
      
      return rply :err_test unless feed.working?
      
      feed.save!
      
      # Auto Abbo for issuer
      feed.abbonement!(channel == nil ? user : channel)
      
      rply :msg_added, id:feed.id, name:name, title:feed.title, description:feed.description
    end
    
  end
end
