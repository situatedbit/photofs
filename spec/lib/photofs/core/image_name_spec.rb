require 'photofs/core/image_name'

describe :ImageName do
  subject { PhotoFS::Core::ImageName }

  describe :extensions do
    it { expect(subject.extensions 'a.jpg').to eq('.jpg') }
    it { expect(subject.extensions '1/2/a.jpg').to eq('.jpg') }
    it { expect(subject.extensions '1/2/a').to eq('') }
    it { expect(subject.extensions '1/2/.git').to eq('') }
    it { expect(subject.extensions '1/2/.git.old').to eq('.old') }
    it { expect(subject.extensions '1/2/a.').to eq('') }
    it { expect(subject.extensions '1/2/a.jpg.tif').to eq('.jpg.tif') }
  end

  describe :frame do
    # irregular names
    it { expect(subject.frame 'a/b/1234.jpg').to eq('1234') }

    it { expect(subject.frame 'a/b/IMG_1234.jpg').to eq('1234') }
    it { expect(subject.frame 'a/b/DSC1234.jpg').to eq('1234') }
    it { expect(subject.frame 'a/b/IMG_1234.small.xcf.jpg').to eq('1234') }

    it { expect(subject.frame 'a/b/some-name-blah.jpg').to eq('some-name-blah') }

    # for irregular names, do not recognize hyphenated notes
    it { expect(subject.frame 'a/b/IMG_1234-something.jpg').to eq('IMG_1234-something') }

    # normalized names
    it { expect(subject.frame 'a/b/1984-01-23-1.jpg').to eq('1') }
    it { expect(subject.frame 'a/b/1984-01-23-001.jpg').to eq('001') }
    it { expect(subject.frame 'a/b/1984-01-23abc-001.jpg').to eq('001') }
    it { expect(subject.frame 'a/b/1984-01-23-001-8x10-scan.xcf.jpg').to eq('001') }
  end

  describe :normalized_prefix do
    it 'respects single digit months' do
      expect(subject.normalized_prefix '2017-9-04').to eq('2017-9-04')
    end

    it 'respects single digit days' do
      expect(subject.normalized_prefix '2017-10-4').to eq('2017-10-4')
    end

    it 'ignores anything after the date' do
      expect(subject.normalized_prefix '2017-10-04 whatever').to eq('2017-10-04')
    end

    it 'is empty when parent does not match pattern' do
      expect(subject.normalized_prefix 'blah blah').to eq('')
    end

    it 'rejects year-month dates that are missing a day' do
      expect(subject.normalized_prefix '2017-10 london').to eq('')
    end

    it 'keeps any characters appended to day number' do
      expect(subject.normalized_prefix '2017-10-04abc').to eq('2017-10-04abc')
    end

    it 'drops any characters not appended to day number' do
      expect(subject.normalized_prefix '2017-10-04abc blah').to eq('2017-10-04abc')
    end
  end

  describe :notes do
    # notes not supported in irregular names
    it { expect(subject.notes 'a/b/IMG_1234.jpg').to eq('') }
    it { expect(subject.notes 'a/b/IMG_1234-note.jpg').to eq('') }

    # normalized names
    it { expect(subject.notes 'a/b/1986-05-23a-04-small-square.xcf').to eq('-small-square') }
    it { expect(subject.notes 'a/b/1982-08-22-001-p234-8x10-1200dpi.tiff.jpg').to eq('-p234-8x10-1200dpi') }
  end

  describe :prefix do
    # irregular names
    it { expect(subject.prefix 'a/b/1234.jpg').to eq('') }

    it { expect(subject.prefix 'a/b/IMG_1234.jpg').to eq('') }
    it { expect(subject.prefix 'a/b/DSC1234.jpg').to eq('') }
    it { expect(subject.prefix 'a/b/IMG_1234.small.xcf.jpg').to eq('') }

    it { expect(subject.prefix 'a/b/some-name-blah.jpg').to eq('') }

    # for irregular names, do not recognize hyphenated notes
    it { expect(subject.prefix 'a/b/IMG_1234-something.jpg').to eq('') }

    # normalized names
    it { expect(subject.prefix 'a/b/1984-01-23-1.jpg').to eq('1984-01-23') }
    it { expect(subject.prefix 'a/b/1984-01-23-001.jpg').to eq('1984-01-23') }
    it { expect(subject.prefix 'a/b/1984-01-23abc-001.jpg').to eq('1984-01-23abc') }
    it { expect(subject.prefix 'a/b/1984-01-23-001-8x10-scan.xcf.jpg').to eq('1984-01-23') }
  end

  describe :reference_name do
    # irregular names
    it { expect(subject.reference_name 'a/b/1234.jpg').to eq('1234') }

    it { expect(subject.reference_name 'a/b/IMG_1234.jpg').to eq('1234') }
    it { expect(subject.reference_name 'a/b/DSC1234.jpg').to eq('1234') }
    it { expect(subject.reference_name 'a/b/IMG_1234.small.xcf.jpg').to eq('1234') }

    it { expect(subject.reference_name 'a/b/some-name-blah.jpg').to eq('some-name-blah') }

    # for irregular names, do not recognize hyphenated notes
    it { expect(subject.reference_name 'a/b/IMG_1234-something.jpg').to eq('IMG_1234-something') }

    # normalized names
    it { expect(subject.reference_name 'a/b/1984-01-23-1.jpg').to eq('1984-01-23-1') }
    it { expect(subject.reference_name 'a/b/1984-01-23-001.jpg').to eq('1984-01-23-001') }
    it { expect(subject.reference_name 'a/b/1984-01-23abc-001.jpg').to eq('1984-01-23abc-001') }
    it { expect(subject.reference_name 'a/b/1984-01-23-001-8x10-scan.xcf.jpg').to eq('1984-01-23-001') }
  end

  describe :reference_path do
    # irregular names
    it { expect(subject.reference_path 'a/b/1234.jpg').to eq('a/b/1234') }

    it { expect(subject.reference_path 'a/b/IMG_1234.jpg').to eq('a/b/1234') }
    it { expect(subject.reference_path 'a/b/DSC1234.jpg').to eq('a/b/1234') }
    it { expect(subject.reference_path 'a/b/IMG_1234.small.xcf.jpg').to eq('a/b/1234') }

    it { expect(subject.reference_path 'a/b/some-name-blah.jpg').to eq('a/b/some-name-blah') }

    # for irregular names, do not recognize hyphenated notes
    it { expect(subject.reference_path 'a/b/IMG_1234-something.jpg').to eq('a/b/IMG_1234-something') }

    # normalized names
    it { expect(subject.reference_path 'a/b/1984-01-23-1.jpg').to eq('a/b/1984-01-23-1') }
    it { expect(subject.reference_path 'a/b/1984-01-23-001.jpg').to eq('a/b/1984-01-23-001') }
    it { expect(subject.reference_path 'a/b/1984-01-23abc-001.jpg').to eq('a/b/1984-01-23abc-001') }
    it { expect(subject.reference_path 'a/b/1984-01-23-001-8x10-scan.xcf.jpg').to eq('a/b/1984-01-23-001') }
  end
end
