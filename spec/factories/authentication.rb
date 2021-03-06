FactoryGirl.define do
  factory :authentication do
    provider { SecureRandom.hex(3) }
    uid { SecureRandom.hex(3) }

    factory :authentication_with_user do
      user
    end
  end  
end