require 'photofs/cli/tag_json_parser'
require 'photofs/core/tag'

describe PhotoFS::CLI::TagJsonParser do
  let(:parser) { PhotoFS::CLI::TagJsonParser.new }

  describe :parse do
    context 'when string is not valid JSON' do
      let(:json) { 'invalid JSON' }

      it 'should throw an exception' do
        expect { parser.parse(json) }.to raise_error(PhotoFS::CLI::TagJsonParser::ParseException)
      end
    end

    context 'when JSON object is malformed' do
      context 'and lacks a top-level tags entity' do
        let(:json) { '{ "obj": [] }' }

        it 'should throw an exception' do
          expect { parser.parse(json) }.to raise_error(PhotoFS::CLI::TagJsonParser::ParseException)
        end
      end

      context 'and lacks a top-level tags array' do
        let(:json) { '{ "tags": "a string" }' }

        it 'should throw an exception' do
          expect { parser.parse(json) }.to raise_error(PhotoFS::CLI::TagJsonParser::ParseException)
        end
      end

      context 'and includes a tag without a name' do
        let(:json) { '"{ "tags": [ { "paths": ["a.jpg", "b.jpg"] } ] }"' }

        it 'should throw an exception' do
          expect { parser.parse(json) }.to raise_error(PhotoFS::CLI::TagJsonParser::ParseException)
        end
      end

      context 'and includes a tag without a paths attribute' do
        let(:json) { '{ "tags": [ { "name": "tree" } ] }' }

        it 'should assume it has no paths' do
          expect(parser.parse(json).find_by_name('tree').images).to be_empty
        end
      end

      context 'and includes a tag with a paths entity that is not an array' do
        let(:json) { '{ "tags": [ { "name": "tree", "paths": 3 } ] }' }

        it 'should interpret it as an empty array' do
          expect(parser.parse(json).find_by_name('tree').images).to be_empty
        end
      end

      context 'and includes a tag with a paths array that includes non-strings' do
        let(:json) { '{ "tags": [ { "name": "tree", "paths": ["1.jpg", 3] } ] }' }

        it 'should ignore them' do
          expect(parser.parse(json).find_by_name('tree').images.map { |i| i.path }).to contain_exactly('1.jpg')
        end
      end
    end

    context 'when string is valid JSON tags structure' do
      let(:json) do
<<-EOS
        { "tags": [
          { "name": "tree", "paths": ["a/b/c/1.jpg", "a/b/c/2.jpg"] },
          { "name": "cat", "paths": ["a/b/c/2.jpg"] },
          { "name": "dog", "paths": [] }
        ] }
EOS
      end

      it 'should parse multiple tags' do
        expect(parser.parse(json).size).to eq(3)
      end

      it 'should parse tags with no images' do
        expect(parser.parse(json).find_by_name('dog')).to be_an_instance_of(PhotoFS::Core::Tag)
      end

      it 'should parse tags with a single image' do
        expect(parser.parse(json).find_by_name('cat').images.length).to eq(1)
      end

      it 'should parse tags with multiple images' do
        expect(parser.parse(json).find_by_name('tree').images.length).to eq(2)
      end
    end
  end
end
