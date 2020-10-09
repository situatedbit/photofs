require 'photofs/cli/parser'

describe PhotoFS::CLI::Parser do
end

describe PhotoFS::CLI::Parser do
  let(:klass) { PhotoFS::CLI::Parser::Pattern }

  describe :parse do
    let(:args) { ['-r', 'def', 'exec'] }
    let(:pattern) {}
    subject { pattern.parse args }

    context 'when pattern is empty but there are args' do
      let(:pattern) { klass.new [] }

      it { is_expected.to be false }
    end

    context 'when both pattern and args are empty' do
      let(:pattern) { klass.new [] }
      let(:args) { [] }

      it { is_expected.to be_empty }
    end

    context 'when pattern matches but does not contain any named arguments' do
      let(:pattern) { klass.new ['-r', 'def', 'exec'] }

      it { is_expected.to be_empty }
    end

    context 'when there are fewer args than patterns' do
      let(:pattern) { klass.new ['-r', 'def', 'exec', 'extra-one'] }

      it { is_expected.to be false }
    end

    context 'when pattern does not match' do
      let(:pattern) { klass.new ['do not', 'match'] }

      it { is_expected.to be false }
    end

    context 'when pattern has named arguments' do
      let(:pattern) { klass.new [{ opt: /-./ }, 'def', 'exec'] }

      it { is_expected.to include(opt: '-r') }
    end

    context 'when the arg starts with the pattern but does not fully match' do
      let(:args) { ['attack'] }
      let(:pattern) { klass.new ['at'] }

      it { is_expected.to be false }
    end

    context 'when the arg ends with the pattern but does not fully match' do
      let(:args) { ['meerkat'] }
      let(:pattern) { klass.new ['at'] }

      it { is_expected.to be false }
    end

    context 'when there are more args than patterns and expand_tail is false' do
      let(:args) { ['tag', 'name', 'path', 'path2'] }
      let(:pattern) { klass.new ['tag', 'name', 'path'] }

      it { is_expected.to be false }
    end

    context 'when expand_tail is true' do
      let(:pattern) { klass.new ['cmd', {arg: 'arg1'}, {paths:  /path[\d]+/}], expand_tail:  true }

      context 'when the tail matches' do
        let(:args) { ['cmd', 'arg1', 'path1', 'path2', 'path3'] }

        it { is_expected.to include(arg: 'arg1') }
        it { is_expected.to include(paths:  ['path1', 'path2', 'path3']) }
      end

      context 'when last token does not match all arguments' do
        let(:args) { ['cmd', 'arg1', 'path1', 'path2', 'not-a-path'] }

        it { is_expected.to be false }
      end
    end
  end # parse
end
