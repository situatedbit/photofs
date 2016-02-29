# https://github.com/thoughtbot/factory_girl/blob/master/GETTING_STARTED.md

require 'photofs/data/file'
require 'photofs/data/image'

FactoryGirl.define do
  factory :file, class: PhotoFS::Data::File do
    path '/null/void'
  end

  factory :image, class: PhotoFS::Data::Image do
    association :jpeg_file, factory: :file, strategy: :build
  end
end
