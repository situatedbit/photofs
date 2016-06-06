require 'photofs/data/tag_set'

describe PhotoFS::Data::TagSet do
  let(:tag_set) { PhotoFS::Data::TagSet.new }

  describe :add? do
    let!(:tag_record) { create :tag }
    let(:tag) { tag_record.to_simple }
    let(:record_object_map) { Hash.new }

    before(:example) do
      tag_set.instance_variable_set(:@record_object_map, record_object_map)
    end

    context 'the tag is not in the database' do
      let(:new_tag) { instance_double('PhotoFS::Core::Tag', :name => '新しい') }
      let(:new_tag_record) { build :tag, :name => new_tag.name }

      before(:example) do
        allow(PhotoFS::Data::Tag).to receive(:new_from_tag).with(new_tag).and_return(new_tag_record)
      end

      it 'should add the simple object to the cache' do
        expect(record_object_map).to receive(:[]=).with(new_tag_record, new_tag)

        tag_set.add? new_tag
      end

      it 'should save the new record to the database' do
        expect(new_tag_record).to receive(:save!)

        tag_set.add? new_tag
      end

      it 'should be the tag' do
        expect(tag_set.add? new_tag).to be new_tag
      end
    end

    context 'the tag is in the cache' do
      let(:record_object_map) { { tag_record => tag } }

      it 'should be nil' do
        expect(tag_set.add? tag).to be nil
      end
    end

    context 'the tag is in the database' do
      it 'should be nil' do
        expect(tag_set.add? tag).to be nil
      end
    end
  end # :add

  describe :delete do
    let(:tag_record) { create :tag }
    let(:tag) { instance_double('PhotoFS::Core::Tag', :name => tag_record.name) }
    let(:record_object_map) { { tag_record => tag } }

    before(:example) do
      allow(PhotoFS::Data::Tag).to receive(:from_tag).with(tag).and_return(tag_record)

      tag_set.instance_variable_set(:@record_object_map, record_object_map)
    end

    it 'should remove the tag from the cache' do
      expect(record_object_map).to receive(:delete).with(tag_record)

      tag_set.delete tag
    end

    it 'should remove the tag record from the database' do
      expect(tag_record).to receive(:destroy)

      tag_set.delete tag
    end
  end # :delete

  describe :find_by_images do
    let(:image_set) { PhotoFS::Core::ImageSet.new :set => [image].to_set }
    let(:image_record) { create_image '一.jpg' }
    let(:image) { image_record.to_simple }

    let(:tag_record) { create(:tag, :name => 'タグ') }
    let(:tag) { tag_record.to_simple }

    context "when there are no tags" do
      it "should return an empty collection" do
        expect(tag_set.find_by_images image_set).to be_empty
      end
    end

    context 'when there are no images' do
      before(:each) do
        tag_record.images << image_record
        tag_record.save
      end

      it { expect(tag_set.find_by_images PhotoFS::Core::ImageSet.new).to be_empty }
    end

    context "when passed a single image" do
      before(:each) do
        tag_record.images << image_record
        tag_record.save
      end

      it "should return the tags for that image" do
        expect(tag_set.find_by_images image_set).to contain_exactly(tag)
      end
    end

    context "when there are multiple images" do
      let(:image2_record) { create_image '二.jpg' }
      let(:image2) { image2_record.to_simple  }
      let!(:image_set) { PhotoFS::Core::ImageSet.new :set => [image, image2].to_set }

      let!(:tag_record) { create(:tag, :name => 'タグ') }
      let!(:tag2_record) { create :tag, :name => '三' }
      let!(:tag3_record) { create :tag, :name => '四' }

      before(:each) do
        tag_record.images << [image_record, image2_record]
        tag_record.save

        tag2_record.images << [image_record, image2_record]
        tag2_record.save
      end

      it "should return the union of tags from those images" do
        expect(tag_set.find_by_images image_set).to contain_exactly(tag_record.to_simple, tag2_record.to_simple)
      end
    end
  end # :find_by_images

  describe :save! do
    it 'should call the Data module method' do
      expect(tag_set).to receive(:save_record_object_map).with(tag_set.instance_variable_get(:@record_object_map))

      tag_set.save!
    end
  end

  # protected
  describe :tags do
    context 'when there are tags in the database' do
      let(:tag_records) { PhotoFS::Data::Tag.all }
      let(:tags) { { tag_records[0].name => tag_records[0].to_simple, tag_records[1].name => tag_records[1].to_simple } }

      before(:example) do
        2.times { create :tag }
      end

      it 'should return objects from the records in the database' do
        expect(tag_set.send(:tags)).to eq tags
      end
    end
  end # :tags

end
