# https://github.com/thoughtbot/factory_bot/blob/master/GETTING_STARTED.md

require 'photofs/data/file'
require 'photofs/data/image'
require 'photofs/data/tag'
require 'photofs/data/tag_binding'

FactoryBot.define do
  factory :file, class: PhotoFS::Data::File do
    sequence :path do |n|
      "/null/void/#{n}.jpg"
    end
  end

  factory :image, class: PhotoFS::Data::Image do
    association :image_file, factory: :file, strategy: :build
  end

  factory :tag, class: PhotoFS::Data::Tag do
    sequence :name  do |n|
      "tag #{n}"
    end

    factory :tag_with_image do
      transient do
        images_count 1
      end

      after(:create) do |tag, evaluator|
        create_list(:tag_binding, evaluator.images_count, tag: tag)
      end
    end
  end # :tag

  factory :tag_binding, class: PhotoFS::Data::TagBinding do
    association :tag, factory: :tag, strategy: :build
    association :image, factory: :image, strategy: :build
  end
end
