require 'photofs/data/image'
require 'photofs/fs'
require 'photofs/fs/test'
require 'photofs/fuse'
require 'rfuse'

=begin
  # If you need to read the contents of a directory,
  filler = instance_double('Filler')

  allow(filler).to receive(:push) do |name|
    puts("#{name}\n")
  end

  fuse.readdir(context, '/t', filler, 0, 0)
=end

describe 'integration for', :type => :locking_behavior do
  let(:source_path) { '/home/me/photos' }
  let(:mountpoint) { '/home/me/p' }
  let(:context) { instance_double('Context', {gid: 500, uid: 500}) }

  let(:file_system) { PhotoFS::FS::Test.new(dirs: [source_path, mountpoint]) }

  let(:fuse) { PhotoFS::Fuse::Fuse.new(source: source_path, mountpoint: mountpoint, env: 'test') }

  before(:example) do
    allow(PhotoFS::FS).to receive(:file_system).and_return(file_system)

    allow(fuse).to receive(:initialize_database) # initialization happens within spec helper
    allow(fuse).to receive(:log) # swallow log messages

    fuse.init(context, nil)
  end

  describe 'link to .photofs' do
    it 'should point to real .photofs' do
      expect(fuse.readlink(context, '/.photofs', 0)).to eq("#{source_path}/.photofs")
    end
  end

  describe 'tags ' do
    describe 'top level dir: ' do
      it 'should exist' do
        expect(fuse.getattr(context, '/t')).to be_a_directory
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

          expect(fuse.getattr(context, '/t/good-tag')).to be_a_directory
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
      let(:image_paths) { ['a/1.jpg', 'b/2.jpg'] }
      let(:image_files) { image_paths.map {|p| "#{source_path}/#{p}"} }

      before(:example) do
        create_images image_paths
        file_system.add(files: image_files)

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
      let(:image_files) { [ '/a/1a.jpg', '/a/2a.jpg', '/a/b/1b.jpg', '/c/1c.JPG'].map {|p| "#{source_path}#{p}"} }

      before(:example) do
        file_system.add(files: image_files)
      end

      it 'should list a file for each jpg in its path' do
        expect(fuse.getattr(context, '/o/a/1a.jpg')).to be_a_link
        expect(fuse.getattr(context, '/o/a/2a.jpg')).to be_a_link
        expect(fuse.getattr(context, '/o/a/b/1b.jpg')).to be_a_link
        expect(fuse.getattr(context, '/o/c/1c.JPG')).to be_a_link
        expect{ fuse.getattr(context, '/o/a/not-exist.jpg') }.to raise_error(Errno::ENOENT)
      end

      it 'should list a directory for each sub directory in the path' do
        expect(fuse.getattr(context, '/o/a')).to be_a_directory
        expect(fuse.getattr(context, '/o/a/b')).to be_a_directory
        expect(fuse.getattr(context, '/o/c')).to be_a_directory
        expect{ fuse.getattr(context, '/o/a/not-exist') }.to raise_error(Errno::ENOENT)
      end
    end
  end # :mirrored_dirs

  describe :recently_tagged_dir do
    let(:image_paths) { ['a/1.jpg', 'a/2.jpg'] }
    let(:image_files) { image_paths.map { |p| "#{source_path}/#{p}" } }

    before(:example) do
      create_images image_paths

      file_system.add(files: image_files)
    end

    it 'should include most recent tag' do
      fuse.mkdir(context, '/t/tree', 0)
      fuse.rename(context, '/o/a/1.jpg', '/t/tree/1.jpg')

      expect(fuse.getattr context, '/recent/tree').to be_a_directory
    end

    it 'should include all tagged items in its tag directories' do
        fuse.mkdir(context, '/t/tree', 0)
        fuse.rename(context, '/o/a/1.jpg', '/t/tree/1.jpg')

        expect(fuse.getattr context, '/recent/tree/1.jpg').to be_a_link
    end

    it 'should not include tags that have not been applied' do
      fuse.mkdir(context, '/t/shrub', 0)

      expect{ fuse.getattr context, '/recent/shrub' }.to raise_error(Errno::ENOENT)
    end

    context 'when five or more tags have been applied' do
      let(:tags) { Array(1..6).map { |d| d.to_s } }

      before(:example) do
        tags.each do |tag|
          fuse.mkdir(context, "/t/#{tag}", 0)
          fuse.rename(context, '/o/a/1.jpg', "/t/#{tag}/1.jpg")
        end
      end

      it 'should include as many as five of the most recently applied tags' do
        tags.each do |tag|
          expect(fuse.getattr context, "/recent/#{tag}").to be_a_directory
        end
      end

      it 'should include the latest tags applied, uniquely' do
        tags.each do |tag|
          fuse.rename(context, '/o/a/2.jpg', "/t/#{tag}/2.jpg")
        end

        tags.each do |tag|
          expect(fuse.getattr context, "/recent/#{tag}").to be_a_directory
        end
      end
    end
  end # :recently_tagged_dir

  describe :tagging_images do
    let(:image_paths) { ['a/1a.jpg', 'a/2a.jpg', 'a/b/1b.jpg', 'c/1c.JPG', 'a/photo.jpg', 'c/photo.jpg'] }
    let(:image_files) { image_paths.map { |p| "#{source_path}/#{p}" } }

    before(:example) do
      create_images image_paths

      file_system.add(files: image_files)

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

          expect(fuse.getattr(context, "/o/a/tags/good/1a.jpg")).to be_a_link
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

          expect(fuse.getattr(context, "/t/good/1c.JPG")).to be_a_link
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

      it 'should not result in the image showing up at the top-level' do
        fuse.rename(context, '/o/a/1a.jpg', '/t/good/1a.jpg')

        expect{ fuse.getattr(context, '/t/1a.jpg') }.to raise_error(Errno::ENOENT)
      end

      it 'should result in the image existing only under the tags subdirectory within its source directory' do
        fuse.rename(context, '/o/a/1a.jpg', '/t/good/1a.jpg')
        fuse.rename(context, '/o/c/1c.JPG', '/t/good/1c.JPG')

        expect(fuse.getattr(context, "/o/c/tags/good/1c.JPG")).to be_a_link
        expect{ fuse.getattr(context, "/o/c/tags/good/1a.jpg") }.to raise_error(Errno::ENOENT)
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
        expect(fuse.readlink(context, '/t/good/photo-c.jpg', 0)).to eq("#{source_path}/c/photo.jpg")
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
          fuse.unlink(context, '/t/good/photo-c.jpg')
        end

        it 'should result in the original image retaining the base name' do
          expect(fuse.readlink(context, '/t/good/photo.jpg', 0)).to eq("#{source_path}/a/photo.jpg")
        end
      end
    end # duplicate base file names within the same tag
  end # :tagging_images

  describe 'untagging images' do
    let(:image_paths) { ['a/1a.jpg', 'a/2a.jpg', 'c/1c.JPG'] }
    let(:image_files) { image_paths.map {|p| "#{source_path}/#{p}"} }

    before(:example) do
      create_images image_paths
      file_system.add(files: image_files)

      fuse.mkdir(context, '/t/good', 0)
      fuse.rename(context, '/o/a/1a.jpg', '/o/a/tags/good/1a.jpg')
    end

    context 'when an image is removed from single tag' do
      it 'should not be listed under that tag' do
        expect(fuse.getattr(context, '/t/good/1a.jpg')).to be_a_link

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
        expect(fuse.getattr(context, '/o/a/tags/bad/1a.jpg')).to be_a_link
        expect(fuse.getattr(context, '/o/a/tags/good/1a.jpg')).to be_a_link

        fuse.unlink(context, '/t/good/bad/1a.jpg')

        expect{ fuse.getattr(context, '/o/a/tags/bad/1a.jpg') }.to raise_error(Errno::ENOENT)
        expect{ fuse.getattr(context, '/o/a/tags/good/1a.jpg') }.to raise_error(Errno::ENOENT)
      end
    end
  end # untagging images

  describe 'persisting images' do
    context 'when an image is present in the source tree during initialization' do
      let(:image_paths) { ['a/1.jpg'] }
      let(:image_files) { image_paths.map { |p| "#{source_path}/#{p}"} }

      before(:example) do
        create_images image_paths
        file_system.add(files: image_files)
      end

      it 'should be persisted in the database' do
        expect(PhotoFS::Data::Image.first.path).to eq(image_paths.first)
      end
    end
  end # persisting images

  describe :sidecars do
    before(:example) do
      create_image "a/1.jpg"
      file_system.add(files: ["#{source_path}/a/1.jpg"])

      fuse.mkdir(context, '/t/good', 0)
    end

    it 'should not exist at tags root' do
      expect{ fuse.getattr context, 't/sidecars' }.to raise_error(Errno::ENOENT)
    end

    context 'when there are no files tagged with good' do
      let(:filler) { double('Filler') }

      before(:each) do
        allow(filler).to receive(:push)
      end

      it 'should not exist' do
        expect{ fuse.getattr context, '/t/good/sidecars' }.to raise_error(Errno::ENOENT)
      end
    end

    context 'when a non-raw file has been tagged' do
      before(:example) do
        fuse.rename(context, '/o/a/1.jpg', '/t/good/1.jpg')
      end

      context 'when a sidecar file does not exist in the database' do
        it 'sidecars/ should still exist' do
          expect(fuse.getattr context, '/t/good/sidecars').to be_a_directory
        end

        context 'when another tagged image has a sidecar file' do
          before(:example) do
            create_images ["a/2.jpg", "a/2.c2r"]
            file_system.add(files: ["#{source_path}/a/2.jpg", "#{source_path}/a/2.c2r"])

            fuse.rename(context, '/o/a/2.jpg', '/t/good/2.jpg')
          end

          it 'the sidecar for the second image should be in sidecars/' do
            expect(fuse.readlink(context, '/t/good/sidecars/2.c2r', 0)).to eq("#{source_path}/a/2.c2r")
          end
        end
      end

      context 'when a sidecar file does exist in the database' do
        before(:example) do
          create_image "a/1.c2r"
          file_system.add(files: ["#{source_path}/a/1.c2r"])
        end

        it 'should exist in the sidecars directory' do
          expect(fuse.readlink(context, '/t/good/sidecars/1.c2r', 0)).to eq("#{source_path}/a/1.c2r")
        end

        context 'when the sidecar file is also in the tag' do
          before(:example) do
            fuse.rename(context, '/o/a/1.c2r', '/t/good/1.c2r')
          end

          it 'should not contain a corresponding sidecar' do
            expect { fuse.getattr(context, '/t/good/sidecars/1.c2r') }.to raise_error(Errno::ENOENT)
          end
        end
      end
    end

    context 'when a raw file has been tagged and a sidecar exists' do
      before(:example) do
        create_image "a/1.c2r"
        file_system.add(files: ["#{source_path}/a/1.c2r"])

        fuse.rename(context, '/o/a/1.c2r', '/t/good/1.c2r')
      end

      it 'should include the non-raw sidecar in sidecars/' do
        expect(fuse.readlink(context, '/t/good/sidecars/1.jpg', 0)).to eq("#{source_path}/a/1.jpg")
      end
    end
  end # :sidecars

  describe 'stats file' do
    let(:image_paths) { ['a/1.jpg', 'a/2.jpg', 'a/3.jpg'] }
    let(:image_files) { image_paths.map { |p| "#{source_path}/#{p}"} }
    let(:stats_file_path) { '/o/a/tags/stats' }

    before(:example) do
      create_images image_paths

      file_system.add(files: image_files)

      fuse.mkdir(context, '/t/good', 0)
      fuse.mkdir(context, '/t/bad', 0)
    end

    it { expect(fuse.getattr(context, stats_file_path)).to be_a_file }

    it { expect(fuse.read(context, stats_file_path, 1024, 0, nil)).to be_empty }

    context 'when files have been tagged' do
      before(:example) do
        fuse.rename(context, '/o/a/1.jpg', '/o/a/tags/good/1.jpg')
        fuse.rename(context, '/o/a/2.jpg', '/o/a/tags/good/2.jpg')
        fuse.rename(context, '/o/a/3.jpg', '/o/a/tags/bad/3.jpg')
      end

      it { expect(fuse.read(context, stats_file_path, 1024, 0, nil)).to eq("bad: 1\ngood: 2") }
    end
  end # stats file

end
