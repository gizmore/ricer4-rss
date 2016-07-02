require 'spec_helper'

describe Ricer4::Plugins::Rss do
  
  # LOAD
  bot = Ricer4::Bot.new("ricer4.spec.conf.yml")
  bot.db_connect
  ActiveRecord::Magic::Update.install
  ActiveRecord::Magic::Update.run
  bot.load_plugins
  ActiveRecord::Magic::Update.run
  
  FEEDS = Ricer4::Plugins::Rss::Feed

  it("can reinstall and flush") do
    ActiveRecord::Base.connection.execute("TRUNCATE TABLE #{FEEDS.table_name}")
  end

  it("can abbonement feeds") do
    expect(bot.exec_line_for("Rss/Add", "WC https://www.wechall.net/news/feed")).to start_with("msg_added:")
  end
  
  it("can utilize abbo and unabbo") do
    expect(bot.exec_line_for("Rss/Unabbo", "WC")).to start_with("msg_unabbonemented:")
    expect(bot.exec_line_for("Rss/Abbo", "WC")).to start_with("msg_abbonemented:")
    expect(bot.exec_line_for("Rss/List", "WC")).to start_with("msg_list_item_page:")
  end
  
end
