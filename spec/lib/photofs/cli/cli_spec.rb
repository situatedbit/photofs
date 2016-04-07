require 'photofs/cli'

describe PhotoFS::CLI do
  let(:cli_module) { PhotoFS::CLI }

  describe :parse do
    it 'should return a bad comand if args are garbage' do
      expect(cli_module.parse(['garbage', 'in'])).to be_instance_of(PhotoFS::CLI::BadCommand)
    end

    it 'should return a proper match given a particular regular expression'
#       expect(cli_module.parse(['tag', 'a-tag', 'file-name'])).to be_instance_of(PhotoFS::CLI::Command)
# but don't use a real class.
  end
end
