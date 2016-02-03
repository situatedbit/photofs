require 'fuse'
require 'file_monitor'
require 'rfuse'
require 'fs/test'

describe 'integration for' do
  let(:source_path) { '/home/me/photos' }
  let(:mountpoint) { '/home/me/p' }
  let(:context) { instance_double('Context', {:gid => 500, :uid => 500}) }

  let(:file_system) { PhotoFS::FS::Test.new({ :dirs => [source_path, mountpoint], :files => [] }) }

  let(:fuse) { PhotoFS::Fuse.new({:source => source_path, :mountpoint => mountpoint}) }
  let(:image_monitor) { instance_double('PhotoFS::FileMonitor', :paths => []) }

  before(:example) do
    allow(PhotoFS::Fuse).to receive(:fs).and_return(file_system)

    allow(PhotoFS::FileMonitor).to receive(:new).and_return(image_monitor)

    allow(fuse).to receive(:log) # swallow log messages

    fuse.init(context, nil)
  end

  describe 'tags ' do
    describe 'top level dir: ' do
      it 'should exist' do
        expect(fuse.getattr(context, '/t')).not_to be nil
      end

      context 'when I try to create /t/good/bad' do
        it 'should not be permitted' do
          expect { fuse.mkdir(context, '/t/good/bad', 0777) }.to raise_error(Errno::ENOENT)
        end
      end

      context 'when I make a new dir under /t' do
        it 'should be permitted' do
          expect { fuse.mkdir(context, '/t/good-tag', 0777) }.not_to raise_error
        end

        it 'should exist in the file system' do
          fuse.mkdir(context, '/t/good-tag', 0777)

          expect(fuse.getattr(context, '/t/good-tag').mode & RFuse::Stat::S_IFMT).to equal(RFuse::Stat::S_IFDIR)
        end
      end

      describe 'removing tag' do
        before(:example) do
          fuse.mkdir(context, '/t/good-tag', 0777)
        end

        it 'should be permitted' do
          expect { fuse.rmdir(context, '/t/good-tag') }.not_to raise_error
        end

        it 'should no longer exist in the file system' do
          fuse.rmdir(context, '/t/good-tag')

          expect { fuse.getattr(context, '/t/good-tag') }.to raise_error(Errno::ENOENT)
        end
      end

    end # :tags:top_level_dir
  end # :tags

  describe :mirrored_dirs do
    describe 'initialization' do
      let(:image_directories) { ["/a", "/a/b", "/c"].map {|p| "#{source_path}#{p}"} }
      let(:image_files) { [ '/a/1a.jpg', '/a/2a.jpg', '/a/b/1b.jpg', '/c/1c.JPG'].map {|p| "#{source_path}#{p}"} }

      before(:example) do
        file_system.add({:dirs => image_directories, :files => image_files})
      end

      it 'should list a file for each jpg in its path' do
        expect(fuse.getattr(context, '/o/a/1a.jpg')).not_to be nil
        expect(fuse.getattr(context, '/o/a/2a.jpg')).not_to be nil
        expect(fuse.getattr(context, '/o/a/b/1b.jpg')).not_to be nil
        expect(fuse.getattr(context, '/o/c/1c.JPG')).not_to be nil
        expect{ fuse.getattr(context, '/o/a/not-exist.jpg') }.to raise_error(Errno::ENOENT)
      end

      it 'should list a directory for each sub directory in the path' do
        expect(fuse.getattr(context, '/o/a')).not_to be nil
        expect(fuse.getattr(context, '/o/a/b')).not_to be nil
        expect(fuse.getattr(context, '/o/c')).not_to be nil
        expect{ fuse.getattr(context, '/o/a/not-exist') }.to raise_error(Errno::ENOENT)
      end
    end
  end # :mirrored_dirs

  describe :tagging_images do
    let(:image_directories) { ["/a", "/a/b", "/c"].map {|p| "#{source_path}#{p}"} }
    let(:image_files) { [ '/a/1a.jpg', '/a/2a.jpg', '/a/b/1b.jpg', '/c/1c.JPG'].map {|p| "#{source_path}#{p}"} }
    let(:image_monitor) { instance_double('PhotoFS::FileMonitor', :paths => image_files) }

    before(:example) do
      file_system.add({:dirs => image_directories, :files => image_files})
    end

    context 'there is a good tag' do
      before(:example) do
        fuse.mkdir(context, '/t/good', 0)
      end

      describe 'to top-level tag directory' do
        it 'should result in image link in tag directory' do
          fuse.rename(context, '/o/a/1a.jpg', '/t/good/1a.jpg')

          expect(fuse.readlink(context, '/t/good/home-me-photos-a-1a.jpg', 0)).to eq("#{source_path}/a/1a.jpg")
        end
      end

      describe 'to mirrored directory sub tag directories' do
        it 'should result in image link to original image in tag sub directory' do
          fuse.rename(context, '/o/a/1a.jpg', '/o/a/tags/good/1a.jpg')

          expect(fuse.readlink(context, '/o/a/tags/good/home-me-photos-a-1a.jpg', 0)).to eq("#{source_path}/a/1a.jpg")
        end
      end

      describe 'an image is tagged twice' do
        before(:example) do
          fuse.mkdir(context, '/t/better', 0)

          fuse.rename(context, '/o/a/1a.jpg', '/t/better/1a.jpg')
        end

        it 'should result in image link in /t/good/better/' do
          expect(fuse.readlink(context, '/t/good/better/home-me-photos-a-1a.jpg', 0)).to eq("#{source_path}/a/1a.jpg")
        end

        it 'should result in image link in /t/better/good/' do
          expect(fuse.readlink(context, '/t/good/better/home-me-photos-a-1a.jpg', 0)).to eq("#{source_path}/a/1a.jpg")
        end

        it 'should result in image link in source tags directory' do
          expect(fuse.readlink(context, '/o/a/tags/good/better/home-me-photos-a-1a.jpg', 0)).to eq("#{source_path}/a/1a.jpg")
        end
      end
    end # /t/good
    
  end # :tagging_images
end
