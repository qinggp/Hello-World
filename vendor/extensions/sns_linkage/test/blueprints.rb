SnsLinkage.blueprint do
  key { "http://#{Faker::Internet.domain_name}/?#{Faker.letterify('?'*40)}" }
  user
end
