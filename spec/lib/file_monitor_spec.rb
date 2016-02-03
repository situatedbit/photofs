require 'spec_helper'
require 'file_monitor'

describe PhotoFS::FileMonitor do
  let(:path) { '/path' }
  let(:paths) { ['a/b/c.jpg', '1/2/3.jpg'] }
  let(:image_set) { PhotoFS::ImageSet.new }
  let(:monitor) { PhotoFS::FileMonitor.new path }

  before(:example) do
    allow(File).to receive(:expand_path).with(path).and_return(path)
  end

=begin
  describe :scan do
    before(:example) do
      allow(image_set).to receive(:find_by_path).with(paths[0]).and_return(nil)
      allow(image_set).to receive(:find_by_path).with(paths[1]).and_return(PhotoFS::Image.new(paths[1]))

      allow(monitor).to receive(:paths).and_return(paths)
    end

    it 'should add new images for paths not in set' do
      expect(image_set).to receive(:add).with(PhotoFS::Image.new(paths[0]))

      monitor.scan
    end

    it 'should ignore paths that are already in the set' do
      expect(image_set).not_to receive(:add).with(PhotoFS::Image.new(paths[1]))

      monitor.scan
    end
  end
=end
  describe :paths do
    let(:glob) { ['a/b/c.jpg', '1/2/3.jpg'] }

    before(:example) do
      allow(monitor).to receive(:glob).and_return(glob)
    end

    it 'should be an array of joined paths' do
      expect(monitor.paths).to contain_exactly("#{path}/#{glob[0]}", "#{path}/#{glob[1]}")
    end
  end
end
