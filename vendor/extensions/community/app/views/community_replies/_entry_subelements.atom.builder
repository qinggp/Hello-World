with_options(:ony_path => false, :host => request.host, :format => "atom", :port => request.port) do |url_opt|
  entry.link(:rel => "profile_image", :type => "image/gif",
             :href => "http://#{request.host_with_port}" +
                      theme_image_path(face_photo_path(comment.author.face_photo,
                                                       :image_type => :thumb)))

  entry.link(:rel => "community_timeline",
             :href => url_opt.url_for(:action => :index,
                                      :community_id => comment.object_type == "Topic" ? comment.community_id : comment.thread.community_id))

  entry.link(:rel => "topic_timeline",
             :href => url_opt.url_for(:action => :index,
                                      :topic_id => comment.object_type == "Topic" ? comment.id : comment.thread_id))

  entry.link(:rel => "reply_to_topic",
             :href => url_opt.url_for(:action => :create,
                                      :topic_id => comment.object_type == "Topic" ? comment.id : comment.thread_id))

  entry.id(comment.id)
  if comment.object_type == "Topic"
    entry.link(:rel => "reply_to_comment",
               :href => url_opt.url_for(:action => :create,
                                        :topic_id => comment.id))
  else
    entry.link(:rel => "reply_to_comment",
               :href => url_opt.url_for(:action => :create,
                                        :parent_id => comment.id))
  end
end

entry.title comment.title
entry.author do
  entry.name comment.author.name
end
entry.tag!("mars:community", comment.object_type == "Topic" ? comment.community.name : comment.thread.community.name)
entry.tag!("mars:topic", comment.object_type == "Topic" ? comment.title : comment.thread.title)
entry.content(comment.content, :type => "text")
entry.updated(comment.created_at.xmlschema)
