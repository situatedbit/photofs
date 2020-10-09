require 'photofs/cli/export_tags_command'
require 'photofs/fs/test'

describe PhotoFS::CLI::ExportTagsCommand do
  let(:command) { PhotoFS::CLI::ExportTagsCommand }

  describe :matcher do
    it { expect(command.match? ['export', 'tags']).to be true }

    it { expect(command.match? ['export', 'tags', './some/file/']).to be false }
    it { expect(command.match? ['export', 'file']).to be false }
    it { expect(command.match? ['export', 'tag']).to be false }
    it { expect(command.match? ['something', 'else', 'entirely']).to be false }
  end
end
