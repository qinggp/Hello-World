Community.blueprint do
  name { "コミュニティ名" }
  comment { "説明文" }
  participation_and_visibility { Community::APPROVALS_AND_VISIBILITIES[:public] }
  community_category CommunityCategory.parent_id_not_null.first
  topic_createable_admin_only { false }
  event_createable_admin_only { false }
  participation_notice { true }
end

CommunityMembership.blueprint do
end

PendingCommunityUser.blueprint do
  user
  community
end

CommunityEvent.blueprint do
  title { "イベント名" }
  content { "説明文" }
  community
  author
  event_date { Date.civil(2009, 4, 10)}
  event_date_note { "開催日補足" }
  place { "開催場所" }
  latitude { 11.111111 }
  longitude { 111.111111 }
  zoom { 9 }
  public { true }
end

CommunityTopic.blueprint do
  title { "トピック名" }
  content { "説明文" }
  community
  author
end

CommunityMarker.blueprint do
  title { "イベント名" }
  content { "説明文" }
  community
  author
  latitude { 11.111111 }
  longitude { 111.111111 }
  zoom { 9 }
  map_category
end

CommunityMapCategory.blueprint do
  community
  name { "マップカテゴリ" }
  author
end


CommunityReply.blueprint do
  title { "返信名" }
  content { "本文"}
  community
  author
end

CommunityCategory.blueprint do
  name { "カテゴリ名"}
  parent_id { "親カテゴリID"}
end

CommunityReplyAttachment.blueprint do
  reply
end

CommunityThreadAttachment.blueprint do
  thread
end

CommunityGroup.blueprint do
  user
  name { "グループ名" }
end

CommunityGroupMembership.blueprint do
end

CommunityInnerLinkage.blueprint do
  owner
  inner_link
end

CommunityOuterLinkage.blueprint do
  owner
end
