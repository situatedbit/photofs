require 'photofs/core/tag_set'
require 'photofs/fuse/tag_dir_root'
require 'photofs/fuse/stats_file'

describe PhotoFS::Fuse::TagDirRoot do
  let(:tags) { PhotoFS::Core::TagSet.new }
  let(:tag_dir) { PhotoFS::Fuse::TagDirRoot.new 't', tags }

  describe :add do
    it { expect { tag_dir.add('a node', double('Node')) }.to raise_error(Errno::EPERM) }
  end

  describe :mkdir do
    let(:tag_name) { 'おさか' }
    let(:tag) { PhotoFS::Core::Tag.new tag_name }
    let(:tags) { double('TagSet', :include? => false) }

    context 'when dir is the top-most tag directory' do
      context 'when the tag does not exist' do
        before(:example) do
          allow(tag_dir).to receive(:tags).and_return(tags)
        end

        it 'should create a new tag' do
          expect(tags).to receive(:add?).with(tag)

          tag_dir.mkdir tag_name
        end
      end

      context 'when the tag exists' do
        before(:example) do
          allow(tag_dir).to receive(:tags).and_return(double('TagSet', :include? => true))
        end

        it 'should throw an error' do
          expect { tag_dir.mkdir tag_name }.to raise_error(Errno::EEXIST)
        end
      end
    end
  end # :mkdir

  describe :rmdir do
    let(:tags) { PhotoFS::Core::TagSet.new }
    let(:dir) { PhotoFS::Fuse::TagDirRoot.new('t', tags) }
    let(:tag_name) { 'ほっかいど' }
    let(:tag) { PhotoFS::Core::Tag.new tag_name }

    context 'when the tag does not exist' do
      before(:example) do
        allow(dir).to receive(:tags).and_return(tags)
        allow(tags).to receive(:find_by_name).and_return(nil)
      end

      it 'should throw an error' do
        expect { dir.rmdir tag_name }.to raise_error(Errno::ENOENT)
      end
    end

    context 'when the tag exists' do
      before(:example) do
        allow(dir).to receive(:tags).and_return(tags)
        allow(tags).to receive(:find_by_name).with(tag_name).and_return(tag)
      end

      it 'should remove the tag from the tag set' do
        expect(tags).to receive(:delete).with(tag)

        dir.rmdir tag_name
      end

      context 'but it still contains images' do
        before(:example) do
          allow(tag).to receive(:images).and_return(double('images', :empty? => false))
        end

        it 'should raise an error' do
          expect { dir.rmdir tag_name }.to raise_error(Errno::EPERM)
        end
      end # it is at the top level
    end # : the tag exists
  end # :rmdir

  describe :stats_file do
    let(:dir) { PhotoFS::Fuse::TagDirRoot.new('日本', PhotoFS::Core::TagSet.new) }
    let(:rename_name) { 'to' }
    let(:rename_parent_node) { double('PhotoFS::Fuse::Dir') }

    it { expect { dir.rename 'stats', rename_parent_node, rename_name }.to raise_error(Errno::EPERM) }

    it { expect(dir.send :additional_files).to include('stats' => an_instance_of(PhotoFS::Fuse::StatsFile)) }
  end # stats file

  describe :soft_move do
    it { expect { tag_dir.soft_move('a node', double('Node')) }.to raise_error(Errno::EPERM) }
  end

  describe :symlink do
    it { expect { tag_dir.symlink(double('Image'), 'link-name') }.to raise_error(Errno::EPERM) }
  end
end
