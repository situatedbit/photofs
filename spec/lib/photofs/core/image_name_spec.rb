require 'photofs/core/image_name'

describe :ImageName do
  subject { PhotoFS::Core::ImageName }

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

  describe :extensions do
    it { expect(subject.extensions('a.jpg')).to eq('.jpg') }
    it { expect(subject.extensions('1/2/a.jpg')).to eq('.jpg') }
    it { expect(subject.extensions('1/2/a')).to eq('') }
    it { expect(subject.extensions('1/2/.git')).to eq('') }
    it { expect(subject.extensions('1/2/.git.old')).to eq('.old') }
    it { expect(subject.extensions('1/2/a.')).to eq('') }
    it { expect(subject.extensions('1/2/a.jpg.tif')).to eq('.jpg.tif') }
  end

  describe :normalized_names do
    describe :frame do
      it { expect(subject.parse('a/b/1984-01-23-1.jpg').frame).to eq('1') }
      it { expect(subject.parse('a/b/1984-01-23-001.jpg').frame).to eq('001') }
      it { expect(subject.parse('a/b/1984-01-23abc-001.jpg').frame).to eq('001') }
      it { expect(subject.parse('a/b/1984-01-23-001-8x10-scan.xcf.jpg').frame).to eq('001') }
    end

    describe :notes do
      it { expect(subject.parse('a/b/1986-05-23a-04.xcf').notes).to eq('') }
      it { expect(subject.parse('a/b/1986-05-23a-04-small-square.xcf').notes).to eq('-small-square') }
      it { expect(subject.parse('a/b/1982-08-22-001-p234-8x10-1200dpi.tiff.jpg').notes).to eq('-p234-8x10-1200dpi') }
    end

    describe :prefix do
      it { expect(subject.parse('a/b/1984-01-23-1.jpg').prefix).to eq('1984-01-23') }
      it { expect(subject.parse('a/b/1984-01-23-001.jpg').prefix).to eq('1984-01-23') }
      it { expect(subject.parse('a/b/1984-01-23abc-001.jpg').prefix).to eq('1984-01-23abc') }
      it { expect(subject.parse('a/b/1984-01-23-001-8x10-scan.xcf.jpg').prefix).to eq('1984-01-23') }
    end

    describe :reference_name do
      it { expect(subject.parse('a/b/1984-01-23-1.jpg').reference_name).to eq('1984-01-23-1') }
      it { expect(subject.parse('a/b/1984-01-23-001.jpg').reference_name).to eq('1984-01-23-001') }
      it { expect(subject.parse('a/b/1984-01-23abc-001.jpg').reference_name).to eq('1984-01-23abc-001') }
      it { expect(subject.parse('a/b/1984-01-23-001-8x10-scan.xcf.jpg').reference_name).to eq('1984-01-23-001') }
    end

    describe :reference_path do
      it { expect(subject.parse('a/b/1984-01-23-1.jpg').reference_path).to eq('a/b/1984-01-23-1') }
      it { expect(subject.parse('a/b/1984-01-23-001.jpg').reference_path).to eq('a/b/1984-01-23-001') }
      it { expect(subject.parse('a/b/1984-01-23abc-001.jpg').reference_path).to eq('a/b/1984-01-23abc-001') }
      it { expect(subject.parse('a/b/1984-01-23-001-8x10-scan.xcf.jpg').reference_path).to eq('a/b/1984-01-23-001') }
    end
  end

  describe :indexed_names do
    describe :frame do
      it { expect(subject.parse('a/b/IMG_1234.jpg').frame).to eq('1234') }
      it { expect(subject.parse('a/b/IMG_1234(1).jpg').frame).to eq('1234') }
      it { expect(subject.parse('a/b/DSC1234.jpg').frame).to eq('1234') }
      it { expect(subject.parse('a/b/IMG_1234.small.xcf.jpg').frame).to eq('1234') }
      it { expect(subject.parse('a/b/IMG_1234-something.jpg').frame).to eq('1234') }

      it { expect(subject.parse('a/b/IMG_20200131_123456.JPG').frame).to eq('20200131123456') }
      it { expect(subject.parse('a/b/IMG_20200131_123456-mono.JPG').frame).to eq('20200131123456') }
      it { expect(subject.parse('a/b/IMG_20200131_123456_1.JPG').frame).to eq('202001311234561') }
      it { expect(subject.parse('a/b/IMG_20200131_123456_1-mono.JPG').frame).to eq('202001311234561') }

      it { expect(subject.parse('a/b/signal-2010-03-23-098234.jpg').frame).to eq('20100323098234') }
      it { expect(subject.parse('a/b/signal-2010-03-23-098234-mono.jpg').frame).to eq('20100323098234') }
      it { expect(subject.parse('a/b/signal-2010-03-23-098234-1.jpg').frame).to eq('201003230982341') }
      it { expect(subject.parse('a/b/signal-2010-03-23-098234-1-mono-cropped.jpg').frame).to eq('201003230982341') }

      it { expect(subject.parse('a/b/1234.jpg').frame).to eq('1234') }
      it { expect(subject.parse('a/b/1234-mono.jpg').frame).to eq('1234') }
    end

    describe :notes do
      it { expect(subject.parse('a/b/IMG_1234.jpg').notes).to eq('') }
      it { expect(subject.parse('a/b/IMG_1234(1).jpg').notes).to eq('(1)') }
      it { expect(subject.parse('a/b/IMG_1234-cropped-mono.jpg').notes).to eq('-cropped-mono') }
      it { expect(subject.parse('a/b/IMG_1234-2400dpi.tiff').notes).to eq('-2400dpi') }

      it { expect(subject.parse('a/b/IMG_20200131_123456.JPG').notes).to eq('') }
      it { expect(subject.parse('a/b/IMG_20200131_123456-mono.JPG').notes).to eq('-mono') }
      it { expect(subject.parse('a/b/IMG_20200131_123456_1.JPG').notes).to eq('') }
      it { expect(subject.parse('a/b/IMG_20200131_123456_1-mono.JPG').notes).to eq('-mono') }

      it { expect(subject.parse('a/b/signal-2010-03-23-098234.jpg').notes).to eq('') }
      it { expect(subject.parse('a/b/signal-2010-03-23-098234-mono.jpg').notes).to eq('-mono') }
      it { expect(subject.parse('a/b/signal-2010-03-23-098234-1.jpg').notes).to eq('') }
      it { expect(subject.parse('a/b/signal-2010-03-23-098234-1-mono-cropped.jpg').notes).to eq('-mono-cropped') }

      it { expect(subject.parse('a/b/1234.jpg').notes).to eq('') }
      it { expect(subject.parse('a/b/1234-mono.jpg').notes).to eq('-mono') }
    end

    describe :prefix do
      it { expect(subject.parse('a/b/1234.jpg').prefix).to eq('') }

      it { expect(subject.parse('a/b/IMG_1234.jpg').prefix).to eq('') }
      it { expect(subject.parse('a/b/DSC1234.jpg').prefix).to eq('') }
      it { expect(subject.parse('a/b/IMG_1234.small.xcf.jpg').prefix).to eq('') }

      it { expect(subject.parse('a/b/IMG_20200131_123456.JPG').prefix).to eq('') }

      it { expect(subject.parse('a/b/signal-2010-03-23-098234-1.jpg').prefix).to eq('') }

      it { expect(subject.parse('a/b/1234.jpg').prefix).to eq('') }
    end

    describe :reference_name do
      it { expect(subject.parse('a/b/IMG_1234.jpg').reference_name).to eq('1234') }
      it { expect(subject.parse('a/b/DSC1234.jpg').reference_name).to eq('1234') }
      it { expect(subject.parse('a/b/IMG_1234.small.xcf.jpg').reference_name).to eq('1234') }

      it { expect(subject.parse('a/b/IMG_1234-something.jpg').reference_name).to eq('1234') }

      it { expect(subject.parse('a/b/IMG_20200131_123456_1.JPG').reference_name).to eq('202001311234561') }
      it { expect(subject.parse('a/b/IMG_20200131_123456-mono.JPG').reference_name).to eq('20200131123456') }

      it { expect(subject.parse('a/b/signal-2010-03-23-098234.jpg').reference_name).to eq('20100323098234') }
      it { expect(subject.parse('a/b/signal-2010-03-23-098234-1-mono-cropped.jpg').reference_name).to eq('201003230982341') }

      it { expect(subject.parse('a/b/1234.jpg').reference_name).to eq('1234') }
    end

    describe :reference_path do
      it { expect(subject.parse('a/b/IMG_1234.jpg').reference_path).to eq('a/b/1234') }
      it { expect(subject.parse('a/b/DSC1234.jpg').reference_path).to eq('a/b/1234') }
      it { expect(subject.parse('a/b/IMG_1234.small.xcf.jpg').reference_path).to eq('a/b/1234') }

      it { expect(subject.parse('a/b/IMG_1234-something.jpg').reference_path).to eq('a/b/1234') }

      it { expect(subject.parse('a/b/IMG_20200131_123456.JPG').reference_path).to eq('a/b/20200131123456') }
      it { expect(subject.parse('a/b/signal-2010-03-23-098234.jpg').reference_path).to eq('a/b/20100323098234') }

      it { expect(subject.parse('a/b/1234.jpg').reference_path).to eq('a/b/1234') }
    end
  end

  describe :irregular_names do
    describe :frame do
      it { expect(subject.parse('a/b/some-name-blah.jpg').frame).to eq('some-name-blah') }
    end

    describe :notes do
      it { expect(subject.parse('a/b/some-name-blah.jpg').notes).to eq('') }
    end

    describe :prefix do
      it { expect(subject.parse('a/b/some-name-blah.jpg').prefix).to eq('') }
    end

    describe :reference_name do
      it { expect(subject.parse('a/b/some-name-blah.jpg').reference_name).to eq('some-name-blah') }
    end

    describe :reference_path do
      it { expect(subject.parse('a/b/some-name-blah.jpg').reference_path).to eq('a/b/some-name-blah') }
    end
  end
end
