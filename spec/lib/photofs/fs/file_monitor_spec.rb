require 'photofs/fs'
require 'photofs/fs/file_monitor'

describe PhotoFS::FS::FileMonitor do
  let(:images_root_path) { '/home/user/photos' }
  let(:search_path) { '/home/user/photos/subfolder' }
  let(:file_system) { PhotoFS::FS.file_system }
  let(:monitor) { PhotoFS::FS::FileMonitor.new({ search_path: search_path, images_root_path: images_root_path, file_system: file_system }) }

  describe :paths do
    let(:glob) { ['a/b/c.jpg', '1/2/3.jpg', '1/2/3.CR2'] }
    let(:monitor_paths) do
      glob.map { |g| "subfolder/#{g}" }
    end

    before(:example) do
      allow(monitor).to receive(:glob).and_return(glob)
    end

    it 'should be an array of joined paths' do
      expect(monitor.paths).to contain_exactly(*monitor_paths)
    end
  end
end
