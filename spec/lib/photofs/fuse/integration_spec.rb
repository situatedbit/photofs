require 'photofs/data/image'
require 'photofs/fs/test'
require 'photofs/fs'
require 'photofs/fuse'
require 'photofs/fuse/file_monitor'
require 'rfuse'

=begin
          filler = instance_double('Filler')

          allow(filler).to receive(:push) do |name|
            puts("#{name}\n")
          end

          fuse.readdir(context, '/t', filler, 0, 0)
=end

describe 'integration for' do
  let(:source_path) { '/home/me/photos' }
  let(:mountpoint) { '/home/me/p' }
  let(:context) { instance_double('Context', {:gid => 500, :uid => 500}) }

  let(:file_system) { PhotoFS::FS::Test.new({ :dirs => [source_path, mountpoint], :files => [] }) }

  let(:fuse) { PhotoFS::Fuse::Fuse.new({:source => source_path, :mountpoint => mountpoint, :env => 'test'}) }
  let(:image_monitor) { instance_double('PhotoFS::FileMonitor', :paths => []) }

  before(:example) do
    allow(PhotoFS::FS).to receive(:file_system).and_return(file_system)

    allow(PhotoFS::Fuse::FileMonitor).to receive(:new).and_return(image_monitor)

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

    context 'when the tag still has images in it in a different source directory' do
      let(:image_directories) { ['/a', '/b'].map {|p| "#{source_path}#{p}"} }
      let(:image_files) { ['/a/1.jpg', '/b/2.jpg'].map {|p| "#{source_path}#{p}"} }
      let(:image_monitor) { instance_double('PhotoFS::FileMonitor', :paths => image_files) }

      before(:example) do
        file_system.add({:dirs => image_directories, :files => image_files})

        fuse.mkdir(context, '/t/good', 0)
        fuse.rename(context, '/o/a/1.jpg', '/o/a/tags/good/1.jpg')
      end

      it 'should not be permitted' do
        expect { fuse.rmdir context, '/o/b/tags/good' }.to raise_error(Errno::EPERM)
      end
    end
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
    let(:image_files) { [ '/a/1a.jpg', '/a/2a.jpg', '/a/b/1b.jpg', '/c/1c.JPG', '/a/photo.jpg', '/c/photo.jpg'].map {|p| "#{source_path}#{p}"} }
    let(:image_monitor) { instance_double('PhotoFS::FileMonitor', :paths => image_files) }

    before(:example) do
      file_system.add({:dirs => image_directories, :files => image_files})

      fuse.mkdir(context, '/t/good', 0)
    end

    describe 'with symlink' do
      # when copying file from o/ to a tag directory with thunar, thunar tries to create a symlink
      # to the original file.
      context 'when tagging within a subdirectory with an image from that directory' do
        let(:target) { '/o/a/tags/good/1a.jpg' }
        let(:source) { "#{source_path}/a/1a.jpg" }

        it 'should tag the image' do
          fuse.symlink(context, source, target)

          expect(fuse.getattr(context, "/o/a/tags/good/1a.jpg")).not_to be nil
        end
      end

      context 'when tagging within a subdirectory with an image from the global collection' do
        let(:target) { '/o/a/tags/good/1c.JPG' }
        let(:source) { "#{source_path}/c/1c.JPG" }

        it 'should raise a permission error' do
          expect { fuse.symlink(context, source, target) }.to raise_error(Errno::EPERM)
        end
      end

      context 'when tagging at the top level with an image in the global collection' do
        let(:target) { '/t/good/1c.JPG' }
        let(:source) { "#{source_path}/c/1c.JPG" }

        it 'should tag the image' do
          fuse.symlink(context, source, target)

          expect(fuse.getattr(context, "/t/good/1c.JPG")).not_to be nil
        end
      end

      context 'when the symlink does not reference an image in the global collection' do
        let(:target) { '/o/a/tags/good/something-else.jpg' }
        let(:source) { "/some/other/path/something-else.jpg" }

        it 'should raise permission error' do
          expect { fuse.symlink(context, source, target) }.to raise_error(Errno::EPERM)
        end
      end
    end # 'with symlink'

    describe 'to top-level tag directory' do
      it 'should result in image link in tag directory' do
        fuse.rename(context, '/o/a/1a.jpg', '/t/good/1a.jpg')

        expect(fuse.readlink(context, '/t/good/1a.jpg', 0)).to eq("#{source_path}/a/1a.jpg")
      end
    end

    describe 'to mirrored directory sub tag directories' do
      it 'should result in image link to original image in tag sub directory' do
        fuse.rename(context, '/o/a/1a.jpg', '/o/a/tags/good/1a.jpg')

        expect(fuse.readlink(context, '/o/a/tags/good/1a.jpg', 0)).to eq("#{source_path}/a/1a.jpg")
      end
    end

    describe 'tagging multiple images with a single tag' do
      before(:example) do
        fuse.rename(context, '/o/a/1a.jpg', '/o/a/tags/good/1a.jpg')
        fuse.rename(context, '/o/c/1c.JPG', '/o/c/tags/good/1c.JPG')
      end

      it 'should result in both images in t/' do
        expect(fuse.readlink(context, '/t/good/1a.jpg', 0)).to eq("#{source_path}/a/1a.jpg")
        expect(fuse.readlink(context, '/t/good/1c.JPG', 0)).to eq("#{source_path}/c/1c.JPG")
      end
    end

    describe 'an image is tagged twice' do
      before(:example) do
        fuse.mkdir(context, '/t/better', 0)

        fuse.rename(context, '/o/a/1a.jpg', '/t/good/1a.jpg')
        fuse.rename(context, '/o/a/1a.jpg', '/t/better/1a.jpg')
      end

      it 'should result in image link in /t/good/better/' do
        expect(fuse.readlink(context, '/t/good/better/1a.jpg', 0)).to eq("#{source_path}/a/1a.jpg")
      end

      it 'should result in image link in /t/better/good/' do
        expect(fuse.readlink(context, '/t/good/better/1a.jpg', 0)).to eq("#{source_path}/a/1a.jpg")
      end

      it 'should result in image link in source tags directory' do
        expect(fuse.readlink(context, '/o/a/tags/good/better/1a.jpg', 0)).to eq("#{source_path}/a/1a.jpg")
      end
    end

    describe 'duplicate base file names within the same tag' do
      before(:example) do
        fuse.rename(context, '/o/a/photo.jpg', '/t/good/photo.jpg')
        fuse.rename(context, '/o/c/photo.jpg', '/t/good/photo.jpg')
      end

      it 'should result in one image retaining the base name' do
        expect(fuse.readlink(context, '/t/good/photo.jpg', 0)).to eq("#{source_path}/a/photo.jpg")
      end

      it 'the second image should include the payload hash' do
        expect(fuse.readlink(context, '/t/good/photo-home-me-photos-c.jpg', 0)).to eq("#{source_path}/c/photo.jpg")
      end

      context 'when the image with the base name is removed' do
        before(:example) do
          fuse.unlink(context, '/t/good/photo.jpg')
        end

        it 'should result in an image with the base name pointing to the image formerly with the hashed name' do
          expect(fuse.readlink(context, '/t/good/photo.jpg', 0)).to eq("#{source_path}/c/photo.jpg")
        end
      end

      context 'when the image with the hash is removed' do
        before(:example) do
          fuse.unlink(context, '/t/good/photo-home-me-photos-c.jpg')
        end

        it 'should result in the original image retaining the base name' do
          expect(fuse.readlink(context, '/t/good/photo.jpg', 0)).to eq("#{source_path}/a/photo.jpg")
        end
      end
    end # duplicate base file names within the same tag
  end # :tagging_images

  describe 'untagging images' do
    let(:image_directories) { ["/a", "/a/b", "/c"].map {|p| "#{source_path}#{p}"} }
    let(:image_files) { ['/a/1a.jpg', '/a/2a.jpg', '/c/1c.JPG'].map {|p| "#{source_path}#{p}"} }
    let(:image_monitor) { instance_double('PhotoFS::FileMonitor', :paths => image_files) }

    before(:example) do
      file_system.add({:dirs => image_directories, :files => image_files})

      fuse.mkdir(context, '/t/good', 0)
      fuse.rename(context, '/o/a/1a.jpg', '/o/a/tags/good/1a.jpg')
    end

    context 'when an image is removed from single tag' do
      it 'should not be listed under that tag' do
        expect(fuse.getattr(context, '/t/good/1a.jpg')).not_to be nil

        fuse.unlink(context, '/t/good/1a.jpg')

        expect{ fuse.getattr(context, '/t/good/1a.jpg') }.to raise_error(Errno::ENOENT)
      end
    end

    context 'when an image is removed from nested tag directories' do
      before(:example) do
        fuse.mkdir(context, '/t/bad', 0)
        fuse.rename(context, '/o/a/1a.jpg', '/o/a/tags/bad/1a.jpg')
      end

      it 'should not be listed under either tag' do
        expect(fuse.getattr(context, '/o/a/tags/bad/1a.jpg')).not_to be nil
        expect(fuse.getattr(context, '/o/a/tags/good/1a.jpg')).not_to be nil

        fuse.unlink(context, '/t/good/bad/1a.jpg')

        expect{ fuse.getattr(context, '/o/a/tags/bad/1a.jpg') }.to raise_error(Errno::ENOENT)
        expect{ fuse.getattr(context, '/o/a/tags/good/1a.jpg') }.to raise_error(Errno::ENOENT)
      end
    end
  end # untagging images

  describe 'persisting images' do
    context 'when an image is present in the source tree during initialization' do
      let(:image_directories) { ['/a'].map {|p| "#{source_path}#{p}"} }
      let(:image_files) { ['/a/1.jpg'].map {|p| "#{source_path}#{p}"} }
      let(:file_system) { PhotoFS::FS::Test.new({ :dirs => [source_path, mountpoint] + image_directories, :files => image_files }) }
      let(:image_monitor) { instance_double('PhotoFS::FileMonitor', :paths => image_files) }

      it 'should be persisted in the database' do
        expect(PhotoFS::Data::Image.first.jpeg_file.path).to eq(image_files.first)
      end
    end
  end # persisting images

end
