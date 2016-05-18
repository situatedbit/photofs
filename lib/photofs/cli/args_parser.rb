module PhotoFS
  module CLI
    class ArgsParser
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
        Token = Struct.new(:name, :pattern)

        def initialize(tokens, options = {})
          @tokens = tokens.map do |token|
            token.respond_to?(:keys) ? Token.new(token.keys.first, token[token.keys.first]) : Token.new(nil, token)
          end

          @opt_expand_tail = options[:expand_tail]
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
        def parse_with_token(args, token, limit_first_arg = false)
          matches = args.map { |arg| arg.match(token.pattern) ? arg : raise(ParseError) }

          { token.name => (limit_first_arg ? matches.first : matches) }
        end

        class ParseError < Exception
        end
      end # end Pattern
    end
  end
end
