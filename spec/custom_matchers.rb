RSpec::Matchers.define :image_with_path do |expected_path|
  match { |actual| actual.path == expected_path }
end
