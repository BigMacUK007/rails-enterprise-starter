FactoryBot.define do
  factory :user do
    account
    identity
    sequence(:name) { |n| "Person #{n}" }
    role { "member" }

    trait :member do
      role { "member" }
    end

    trait :admin do
      role { "admin" }
    end

    trait :owner do
      role { "owner" }
    end
  end
end
