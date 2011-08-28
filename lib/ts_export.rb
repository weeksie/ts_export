# -*- encoding: utf-8 -*-
require 'mysql2'
require 'json'

module TsExport
  class Base
    
    # refactor and abstract this later.
    def initialize
      @mysql = Mysql2::Client.new :host => 'localhost', :username => 'root', :database => 'twelvestone_legacy'
      @json  = { }
      @user_slug_map = { }
      @conv_slug_map = { }
      @user_map = {
        :twelvestone_id => "userid", 
        :name           => "username", 
        :email          => "email",
        :title          => "usertitle",
        :created_at     => "joindate",
        :post_count     => "posts",
        :birthday       => "birthday"
      }
      @forum_map = {
        :twelvestone_id     => "forumid",
        :name               => "title",
        :description        => "description",
        :post_count         => "replycount",
        :conversation_count => "threadcount",
        :last_post_id       => "lastpost"
      }
      @conversation_map = {
        :twelvestone_id     => "threadid",
        :forum_id           => "forumid",
        :title              => "title",
        :post_count         => "replycount",
        :view_count         => "views",
        :open               => "open",
        :sticky             => "sticky",
        :created_at         => "dateline",
        :last_posted_in     => "lastpost"
      }
      @post_map = {
        :twelvestone_id  => "postid",
        :conversation_id => "threadid",
        :author_id       => "userid",
        :text            => "pagetext",
        :created_at      => "dateline",
        :edited_at       => "editdate"
      }
    end
    
    def to_file(base, *collections)
      collections = %w[ users forums conversations posts ] if collections.empty?
      collections.each do |collection|
        self.send collection.to_sym, "#{base}/#{collection}.json"
      end
    end
    
    def to_mongo(base, db)
      Dir["#{base}/*.json"].each do |collection|
        collection = File.basename collection
        collection.gsub! /\.json/, ''
        `mongoimport --db #{db} --collection #{collection} --file #{base}/#{collection}.json --type json`
      end
    end
    
    def pms
    end
    
    def forums(out=nil)
      @json[:forums] ||= query(@forum_map, "forum", out) do |row|
        row[:slug] = parameterize row[:name]
        row
      end
    end

    def users(out=nil)
      @json[:users] ||= query @user_map, "user", out do |row|
        row[:created_at] = utc row[:created_at]
        set_slug row, :name, @user_slug_map
        row
      end
    end
    
    def posts(out=nil)
      @json[:posts] ||= query @post_map, "post", out do |row|
        row[:body].strip!        
        row[:created_at] = utc row[:created_at]
        row[:edited_at]  = utc row[:edited_at] unless row[:edited_at].nil? || row[:edited_at] == 0
        row
      end
    end
    
    def conversations(out=nil)
      @json[:conversations] ||= query @conversation_map, "thread", out do |row|
        row[:open]           = row[:open] == 1
        row[:sticky]         = row[:sticky] == 1
        row[:post_count]     = row[:post_count].to_i
        row[:view_count]     = row[:view_count].to_i
        row[:created_at]     = utc row[:created_at]
        row[:last_posted_in] = utc row[:last_posted_in]
        set_slug row, :title, @conv_slug_map
        row
      end
    end
    
    def to_json(*options)
      @json.to_json
    end
    
    protected
    
    def utc(str)
      Time.at(str.to_i).utc
    end
    
    def transform(map, row)
      Hash[*map.collect { |k,v| [ k, row[v] ] }.flatten]
    end

    def query(map, table, out=nil)
      cols = map.values.collect { |k| k.to_s }.join(",")
      result = @mysql.query "SELECT #{cols} FROM #{table};", :cache_rows => false
      if out
        File.open(out, "w") do |f|
          result.each do |row|
            f.syswrite(yield(transform(map, row)).to_json + "\n")
          end
          f.flush
        end
      else
        data   = []
        result.each do |row|
          data << yield(transform(map, row))
        end
        data
      end
    end
    
    def set_slug(row, attr, map)
      row[:slug] = parameterize row[attr]
      if map[row[:slug]]
        map[row[:slug]] += 1
        row[:slug] = row[:slug] + "-#{map[row[:slug]]}"
      else
        map[row[:slug]] = 0
      end
    end
    
    # From ActiveSupport::Inflector
    def parameterize(string, sep = '-')
      parameterized_string = string.dup
      # Turn unwanted chars into the separator
      parameterized_string.gsub!(/[^a-z0-9\-_]+/i, sep)
      unless sep.nil? || sep.empty?
        re_sep = Regexp.escape(sep)
        # No more than one of the separator in a row.
        parameterized_string.gsub!(/#{re_sep}{2,}/, sep)
        # Remove leading/trailing separator.
        parameterized_string.gsub!(/^#{re_sep}|#{re_sep}$/, '')
      end
      parameterized_string.downcase
    end    
    
  end
end

