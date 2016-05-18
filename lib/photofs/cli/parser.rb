module PhotoFS
  module CLI
    class Parser
      def initialize(patterns)
        @patterns = patterns
      end

      def match?(args)
        !matching_pattern(args).nil?
      end

      def parse(args)
        matching_pattern(args).parse(args)
      end

      private

      def matching_pattern(args)
        @patterns.select { |p| p.match? args }.first
      end

      class Pattern
        Token = Struct.new(:name, :pattern) # each arg is matched against one of these

        def initialize(tokens, options = {})
          @tokens = tokens.map { |token| token.respond_to?(:keys) ? hash_to_token(token) : string_to_token(token) }

          @opt_expand_tail = options[:expand_tail] || false
        end

        def match?(args)
          !!parse(args)
        end

        def parse(args)
          return {} if @tokens.empty? && args.empty?
          return false if @tokens.length > args.length
          return false if args.length > @tokens.length && !@opt_expand_tail

          matches = {}

          begin
            @tokens.each_index do |i|
              matches = matches.merge parse_with_token([args[i]], @tokens[i], true)
            end

            if @opt_expand_tail
              tail_args = args[(@tokens.length - 1)..-1]

              matches = matches.merge parse_with_token(tail_args, @tokens.last)
            end

            matches.delete nil # unnamed tokens will be saved under nil

            matches
          rescue ParseError
            return false
          end
        end

        private
        def full_string_pattern(pattern)
          "\\A#{pattern}\\z"
        end

        def hash_to_token(hash)
          name = hash.keys.first

          Token.new name, full_string_pattern(hash[name])
        end

        def parse_with_token(args, token, limit_first_arg = false)
          matches = args.map { |arg| arg.match(token.pattern) ? arg : raise(ParseError) }

          { token.name => (limit_first_arg ? matches.first : matches) }
        end

        def string_to_token(str)
          Token.new nil, full_string_pattern(str)
        end

        class ParseError < Exception
        end
      end # end Pattern
    end
  end
end
