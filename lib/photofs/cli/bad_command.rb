require 'photofs/cli/command'

module PhotoFS
  module CLI
    class BadCommand < Command
      def execute
        # no op
      end
    end
  end
end
