BlogEntry.blueprint do
  user { User.make }
  blog_category { BlogCategory.make }
  title { "タイトル" }
  body { "本文" }
  body_format { "" }
  visibility { BlogPreference::VISIBILITIES[:publiced] }
  comment_restraint { BlogPreference::VISIBILITIES[:publiced] }
  access_count { 0 }
end

BlogComment.blueprint do
  user { User.make }
  blog_entry
  body { "本文" }
  anonymous { false }
end

BlogComment.blueprint(:anonymous) do
  blog_entry
  user_name { Faker::Name.name }
  email
  body { "本文" }
  anonymous { true }
end

BlogCategory.blueprint do
  user { User.make }
  name { "カテゴリ名" }
end

BlogAttachment.blueprint do
  image { ActionController::TestUploadedFile.new(RAILS_ROOT + "/test/fixtures/files/test.png", "image/png") }
  position { 1 }
end

BlogPreference.blueprint do
  title { "太郎のブログ" }
  visibility { BlogPreference::VISIBILITIES[:publiced] }
  basic_color { BlogPreference::BASIC_COLORS[:green] }
  email_post_visibility { BlogPreference::VISIBILITIES[:publiced] }
  comment_notice_acceptable { false }
end
