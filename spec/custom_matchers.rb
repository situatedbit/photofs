require 'rfuse'

RSpec::Matchers.define :be_a_directory do |expected|
  match { |actual| (actual.mode & RFuse::Stat::S_IFMT) == RFuse::Stat::S_IFDIR }
end

RSpec::Matchers.define :be_a_file do |expected|
  match { |actual| (actual.mode & RFuse::Stat::S_IFMT) == RFuse::Stat::S_IFREG }
end

RSpec::Matchers.define :be_a_link do |expected|
  match { |actual| (actual.mode & RFuse::Stat::S_IFMT) == RFuse::Stat::S_IFLNK }
end

RSpec::Matchers.define :image_with_path do |expected_path|
  match { |actual| actual.path == expected_path }
end
