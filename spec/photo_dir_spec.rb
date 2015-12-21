require 'spec_helper'
require 'photo_dir'

describe PhotoDir do
  let(:name) { 'iidabashi' }
  let(:dir) { PhotoDir.new name }

  describe 'top-level instance' do
    it 'should have a name' do
      expect(dir.name).to eq(name)
    end

    it 'should not have a parent' do
      expect(dir.parent).to be nil
    end

    it 'should be a directory' do
      expect(dir.directory?).to be true
    end

    it 'should not have any nodes' do
      expect(dir.nodes).to be_empty
    end

    it 'should not have any node names' do
      expect(dir.node_names).to be_empty
    end

    context 'when a child node is added' do
      let(:subdir_name) { 'kamiyacho' }
      let(:subdir) { PhotoDir.new subdir_name }

      before(:each) do
        dir.add_node(subdir)
      end

      describe 'nodes method' do
        it 'should return one child' do
          expect(dir.nodes).to contain_exactly(subdir)
        end
      end

      describe 'node_names method' do
        it 'should return one node name' do
          expect(dir.node_names).to contain_exactly(subdir_name)
        end
      end
    end # end context a child node is added'

    context 'when several child nodes are added' do
      let(:names) { ['shinjuku', 'shibuya', 'ikebukuro'] }
      let(:subdirs) { names.map { |name| PhotoDir.new(name, dir) } }

      before(:each) do
        subdirs.each { |subdir| dir.add_node(subdir) }
      end

      describe 'add_node method' do
        context 'duplicate adds' do
          let(:original_node) { subdirs[0] }
          let(:duplicate_node) { PhotoDir.new(original_node.name, dir) }

          before(:each) do
            dir.add_node(duplicate_node)
          end

          it 'should include the latest added node' do
            expect(dir.nodes).to include(duplicate_node)
          end

          it 'should not include the original added node' do
            expect(dir.nodes).not_to include(original_node)
          end
        end
      end

      describe 'nodes method' do
        it 'should return all nodes' do
          expect(dir.nodes).to contain_exactly(*subdirs)
        end
      end

      describe 'node_names method' do
        it 'should return all node names' do
          expect(dir.node_names).to contain_exactly(*names)
        end
      end
    end # end several child nodes are added

  end # top level instance
end
