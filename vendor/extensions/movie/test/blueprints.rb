MoviePreference.blueprint do
  default_visibility { MoviePreference::VISIBILITIES[:friend_only] }
end

Movie.blueprint do
  user { User.make }
  title { "太郎の動画" }
  body { "太郎の動画" }
  visibility { MoviePreference::VISIBILITIES[:publiced] }
  convert_status { Movie::CONVERT_STATUSES[:done] }
end
