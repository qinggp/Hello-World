Track.blueprint do
  user
  visitor
  page_type { 1 }
end

Track.blueprint(:blog) do
  user
  visitor
  page_type { 2 }
end

Track.blueprint(:community) do
  user
  visitor
  page_type { 3 }
end

TrackPreference.blueprint do
  preference
  notification_track_count { 1 }
end
