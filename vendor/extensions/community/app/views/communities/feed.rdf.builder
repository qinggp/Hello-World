xml.instruct!

mars_rdf_feed_layout(xml,
                     :title => @xml_title,
                     :link => @xml_link,
                     :description => @xml_title,
                     :resources => @threads.map{|t| t.polymorphic_url_on_community(self) }
                     ) do |xml|
  @threads.each do |t|
    xml.item("rdf:about" => t.polymorphic_url_on_community(self)) do
      xml.title(h(t.title))
      xml.link(t.polymorphic_url_on_community(self))
      xml.tag!("dc:subject", t.community.name)
      xml.tag!("dc:date", t.send(@time).iso8601)
      xml.tag!("dc:creator", t.author.name)
      xml.description(normalize_text_for_feed(strip_tags(t.content)))
      xml.tag!("content:encoded"){|d| d.cdata!(t.content)}
    end
  end
end
