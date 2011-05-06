mars_atom_feed_layout(xml,
                      :title => @xml_title,
                      :subtitle => @xml_title,
                      :root_url => @xml_link) do |feed|
  @blog_entries.each do |b|
    feed.entry(b, :id => blog_entry_url(b), :updated => b.created_at, :published => b.created_at) do |entry|
      entry.title h(b.title)
      entry.author do
        entry.name b.user.name
      end
      entry.category(:term => b.blog_category.name,
                     :label => b.blog_category.name,
                     :schema => index_for_user_user_blog_entries_url(:user_id => b.user_id, :blog_category_id => b.blog_category_id),
                     "xml:lang" => "ja")
      entry.summary(normalize_text_for_feed(display_blog_entry_body(b, :display_type => :raw)),
                    :type => "text", "xml:lang" => "ja")
      entry.content(:type => "xhtml", "xml:lang" => "ja") do |xhtml|
        xhtml << normalize_text_for_feed(display_blog_entry_body(b, :display_type => :raw))
      end
    end
  end
end
