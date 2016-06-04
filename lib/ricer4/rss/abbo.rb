module Ricer4::Plugins::Rss
  class Abbo < Ricer4::Plugin
    
    is_add_abbo_trigger :for => Ricer4::Plugins::Rss::Feed
    
    def abbo_search(relation, term)
      return Ricer4::Plugins::Rss::Feed.where(:id => term) ||
      Ricer4::Plugins::Rss::Feed.by_name(term)
    end

  end
end
