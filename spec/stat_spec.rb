require 'spec_helper'
require 'stat'
require 'rfuse'

describe PhotoFS::Stat do
  describe '#new' do
    context 'when there is no base stat' do
      let(:attributes) { {:mode => 0, :blocks => 0} }

      it 'should return a stat with attributes passed' do
        expect(PhotoFS::Stat.new(attributes).blocks).to be 0
      end
    end

    context 'when there is a base stat' do
      let(:base_stat) { RFuse::Stat.directory(0, {:blocks => 42}) }

      it 'should return a stat with attributes merged with base stat' do
        expect(PhotoFS::Stat.new({:mode => 0, :blocks => 99}, base_stat).blocks).to be 99
      end
    end

  end  
end
