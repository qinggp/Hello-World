xml.instruct!

mars_rdf_feed_layout(xml,
                     :title => @xml_title,
                     :link => @xml_link,
                     :description => @xml_title,
                     :resources => @blog_entries.map{|b| blog_entry_url(b) }
                     ) do |xml|
  @blog_entries.each do |b|
    xml.item("rdf:about" => blog_entry_url(b)) do
      xml.title h(b.title)
      xml.link blog_entry_url(b)
      xml.tag!("dc:subject", b.blog_category.name)
      xml.tag!("dc:date", b.created_at.iso8601)
      xml.tag!("dc:creator", b.user.name)
      xml.description(normalize_text_for_feed(strip_tags(display_blog_entry_body(b, :display_type => :raw))))
      xml.tag!("content:encoded"){|d| d.cdata!(normalize_text_for_feed(display_blog_entry_body(b, :display_type => :raw)))}
    end
  end
end
