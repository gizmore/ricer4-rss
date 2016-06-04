module Ricer4::Plugins::Rss
  class Feed < ActiveRecord::Base
    
    require 'rss'
    require 'open-uri'

    include Ricer4::Include::Readable
    include Ricer4::Include::UsesInternet

    TITLE_LEN ||= 96
    DESCR_LEN ||= 255
    
    abbonementable_by([Ricer4::User, Ricer4::Channel])

    belongs_to :user, :class_name => 'Ricer4::User'
    
    validates :name, named_id: true
    validates :url,  uri: { ping:false, exists:false, shemes:[:http, :https] }

    def self.visible(user); self.enabled; end
    def self.enabled; where('feeds.deleted_at IS NULL'); end
    def self.deleted; where('feeds.deleted_at IS NOT NULL'); end
    
    arm_install do |m|
      m.create_table table_name do |t|
        t.integer   :user_id,     :null => true
        t.string    :name,        :null => false, :unique => true, :charset => :ascii, :collate => :ascii_bin
        t.string    :url,         :null => false, :unique => true
        t.string    :title,       :null => true,  :length => TITLE_LEN
        t.string    :description, :null => true,  :length => DESCR_LEN
        t.integer   :updates,     :null => false, :default => 0,   :unsigned => true
        t.datetime  :checked_at,  :null => true,  :default => nil
        t.datetime  :deleted_at,  :null => true,  :default => nil
        t.timestamps :null => false
      end
      m.add_index table_name, :name,  :name => :feeds_name_index
    end

    arm_install('Ricer4::User' => 1) do |m|
      m.add_foreign_key table_name, :ricer_users, :column => :user_id, :name => :feed_users_f_key, :on_delete => :nullify
    end
    
    search_syntax do
      search_by :text do |scope, phrases|
        columns = [:url, :name, :title, :description]
        scope.where_like(columns => phrases)
      end
    end
      
    def self.by_id(id)
      where(:id => id).first
    end
    def self.by_url(url)
      where(:url => url).first
    end
    def self.by_name(name)
      where(:name => name).first
    end
    def self.by_arg(arg)
      by_id(arg) || by_name(arg)
    end

    def display_show_item(number)
      I18n.t('ricer4.plugins.rss.show_item', id:self.id, name:self.name, title:self.title, description:self.description);
    end

    def display_list_item(number)
      I18n.t('ricer4.plugins.rss.list_item', id:self.id, name:self.name)
    end

    def request_feed(&block)
      get_request(url) do |response|
        if response.nil? 
          raise Ricer4::HTTPException(response)
        elsif response.code != "200"
          raise Ricer4::HTTPException(response)
        else
          yield(RSS::Parser.parse(response.body))
        end
      end
    end

    def working?
      request_feed do |feed|
        self.title = feed_title(feed)
        self.description = feed_descr(feed)
        self.checked_at = feed_date(feed)
        return (self.title != nil) && (self.checked_at != nil)
      end
    end
    
    def check_feed
      request_feed do |feed|
        collect = feed.items.select { |item| item_date(item) > self.checked_at }
        feed_has_news(feed, collect) unless collect.empty?
      end
    end
    
    def feed_title_text(feed)
      return feed.channel.title if feed.respond_to?(:channel)
      return feed.title if feed.title
      nil
    end

    def feed_title(feed)
      text = feed_title_text(feed)
      return no_html(text.to_s, TITLE_LEN) if text
    end
    
    def feed_descr_text(feed)
      return feed.channel.description if feed.respond_to?(:channel) && feed.channel.description
      return feed.subtitle if feed.subtitle
    end
    
    def feed_descr(feed)
      text = feed_descr_text(feed)
      no_html(text.to_s, DESCR_LEN) if text
    end
    
    def item_date(item)
      if item.respond_to?(:updated)
        DateTime.parse(no_html(item.updated.to_s))
      else
        item.pubDate
      end
    end
    
    def feed_date(feed)
      if feed.respond_to?(:channel)
        c = feed.channel
        return c.pubDate if c.pubDate
        return c.lastBuildDate if c.lastBuildDate
      else
        return feed.pubDate if feed.respond_to?(:pubDate)
      end
      if (feed.items && feed.items.length)
        return feed.items[-1].pubDate if feed.items[-1].respond_to?(:pubDate)
      end
      return no_html(feed.updated.to_s) if feed.updated
      nil
    end
    
    def feed_has_news(feed, items)
      announce_news(items)
      self.title = feed_title(feed)
      self.description = feed_descr(feed)
      self.checked_at = item_date(items[-1])
      self.updates = self.updates + items.length
      self.save!
    end
    
    def announce_news(items)
      items.reverse!
      abbonements.each do |abbonement|
        if abbonement.target.online
          abbonement.target.localize!
          items.each do |item|
            abbonement.target.send_privmsg(feedmessage(item))
          end
        end
      end
    end
    
    def feedmessage(item)
      link = item.link == nil ? item.description : item.link
      I18n.t('ricer4.plugins.rss.msg_got_news', name:name, title:item.title, link:link)
    end
    
  end
end
