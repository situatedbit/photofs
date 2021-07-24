require 'photofs/cli'

describe PhotoFS::CLI do
  let(:cli_module) { PhotoFS::CLI }

  describe :parse do
    it 'should return a bad command if args are garbage' do
      expect(cli_module.parse(['garbage', 'in'])).to be_instance_of(PhotoFS::CLI::BadCommand)
    end
  end
end
