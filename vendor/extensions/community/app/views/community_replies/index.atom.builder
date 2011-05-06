xml.instruct!
xml.feed(:language => "ja-JP", 'xmlns' => 'http://www.w3.org/2005/Atom', 'xmlns:mars' => request.protocol + request.host_with_port) do |feed|
  feed.id "tag:#{request.host},2009:community-replies-#{current_user.id}"
  feed.title @feed_title
  feed.updated Time.now.xmlschema

  feed.link(:rel => "user_timeline", :href => url_for(:only_path => false, :host => request.host, :format => "atom", :action => :index, :port => request.port))

  with_options(:only_path => false, :host => request.host, :port => request.port, :format => "atom",
               :action => :index, :count => @count, :community_id => params[:community_id],
               :topic_id => params[:topic_id]) do |url_opt|

    feed.link(:rel => "first", :href => url_opt.url_for(:page => 1))

    if @comments.previous_page
      feed.link(:rel => "previous", :href => url_opt.url_for(:page => @comments.previous_page))
    end

    feed.link(:rel => "self", :href => url_opt.url_for(:page => @page))

    if @comments.next_page
      feed.link(:rel => "next", :href => url_opt.url_for(:page => @comments.next_page))
    end

    feed.link(:rel => "last", :href => url_opt.url_for(:page => @comments.total_pages))
  end

  @comments.each do |comment|
    feed.entry do |entry|
      render :partial => "entry_subelements", :locals => {:comment => comment, :entry => entry}
    end
  end
end
