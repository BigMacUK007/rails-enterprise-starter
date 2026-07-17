FactoryBot.define do
  factory :identity do
    sequence(:email_address) { |n| "person-#{n}@example.com" }

    trait :staff do
      staff { true }
    end
  end
end
