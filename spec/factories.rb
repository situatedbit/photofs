# https://github.com/thoughtbot/factory_girl/blob/master/GETTING_STARTED.md
FactoryGirl.define do
  factory :file do
    path '/null/void'
  end

  factory :image do
    association :jpeg_file, factory: :file
  end
end
