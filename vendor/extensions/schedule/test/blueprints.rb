Schedule.blueprint do
  title { "タイトル "}
  detail { "詳細" }
  public { true }
  author
end

Schedule.blueprint(:valid) do
  title { "タイトル "}
  detail { "詳細" }
  public { true }
  due_date { "2009/10/10" }
  start_time { Time.local(2009, 10, 10, 1, 1) }
  end_time { Time.local(2009, 10, 10, 23, 58) }
end

Schedule.blueprint(:invalid) do
  title { ""}
  detail { "詳細" }
  public { true }
  due_date { "2009/10/10" }
  start_time { Time.local(2009, 10, 10, 1, 1) }
  end_time { Time.local(2009, 10, 10, 23, 58) }
  author
end

SchedulePreference.blueprint do
  visibility { 1 }
end
