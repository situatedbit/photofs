require 'photofs/cli/data_utilities'

describe PhotoFS::CLI::DataUtilities do
  class PhotoFS::CLI::DataUtilities::TestCommand
    include PhotoFS::CLI::DataUtilities
  end

  let(:command) { PhotoFS::CLI::DataUtilities::TestCommand.new }

  describe :tag_images do
    let(:images) { double('ImageSet') }
    let(:tag) { double('Tag', :add_images => nil) }
    let(:tag_name) { 'a-tag' }
    let(:tag_set) { double('TagSet') }

    subject { command.tag_images(tag_set, tag_name, images) }

    after(:example) do
      subject
    end

    context 'if tag does not exist' do
      before(:example) do
        allow(PhotoFS::Core::Tag).to receive(:new).with(tag_name).and_return(tag)

        allow(tag_set).to receive(:find_by_name).and_return(nil)
        allow(tag_set).to receive(:add?).and_return(tag)
      end

      it { expect(tag_set).to receive(:add?).with(tag) }

      it { expect(tag).to receive(:add_images).with(images) }
    end

    context 'if tag exists' do
      before(:example) do
        allow(tag_set).to receive(:find_by_name).and_return(tag)
      end

      it { expect(tag_set).not_to receive(:add?) }

      it { expect(tag).to receive(:add_images).with(images) }
    end
  end

  describe :untag_images do
    let(:images) { double('ImageSet') }
    let(:tag_name) { 'a-tag' }
    let(:tag_set) { double('TagSet') }

    subject { command.untag_images tag_set, tag_name, images }

    context 'if tag does not exist' do
      before(:example) do
        allow(tag_set).to receive(:find_by_name).with(tag_name).and_return(nil)
      end

      it { expect(subject).to be nil }
    end

    context 'if the tag exists' do
      let(:tag) { double('Tag', :remove => nil) }

      before(:example) do
        allow(tag_set).to receive(:find_by_name).with(tag_name).and_return(tag)
      end

      it 'will remove images from the tag' do
        expect(tag).to receive(:remove).with(images)

        subject
      end
    end
  end # :untag_images
end
