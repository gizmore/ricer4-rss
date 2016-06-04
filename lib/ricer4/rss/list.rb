module Ricer4::Plugins::Rss
  class List < Ricer4::Plugin
    
    is_list_trigger :feeds, :for => Ricer4::Plugins::Rss::Feed

  end
end
