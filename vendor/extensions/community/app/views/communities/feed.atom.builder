mars_atom_feed_layout(xml,
                      :title => @xml_title,
                      :subtitle => @xml_title,
                      :root_url => @xml_link) do |feed|
  @threads.each do |t|
    feed.entry(t,
               :url => t.polymorphic_url_on_community(self),
               :id => t.polymorphic_url_on_community(self),
               :updated => t.send(@time),
               :published => t.send(@time)
               ) do |thread|
      thread.title h(t.title)
      thread.author do
        thread.name t.author.name
      end
      thread.category(:term => t.community.name,
                     :label => t.community.name,
                     :schema => community_url(t.community),
                     "xml:lang" => "ja")
      thread.summary(normalize_text_for_feed(t.content),
                    :type => "text", "xml:lang" => "ja")
      thread.content(:type => "xhtml", "xml:lang" => "ja") do |xhtml|
        xhtml << normalize_text_for_feed(t.content)
      end
    end
  end
end
