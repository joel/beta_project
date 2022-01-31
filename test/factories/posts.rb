FactoryBot.define do
  factory :post do
    sequence(:name) { |n| "Post no #{n}-#{rand(100_000)}" }
  end
end
