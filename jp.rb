class JP
  class Token
    IN_END 	     = 0
    IN_UEXP      = 1
    LBRACE 	     = 2
    RBRACE 	     = 3
    COLON 	     = 4
    COMMA 	     = 5
    STRING       = 6
    LSBRAC       = 7
    RSBRAC       = 8
    NUMBER       = 9
    NULL         = 10
    BOOL         = 11

    VEC = 1
    VHC = 2
    IJC = 4
    CHAR_LOOKUP =
      [
          IJC,    IJC,    IJC,    IJC,    IJC,    IJC,    IJC,    IJC,          #   00      07
          IJC,    IJC,    IJC,    IJC,    IJC,    IJC,    IJC,    IJC,          #   08      15
          IJC,    IJC,    IJC,    IJC,    IJC,    IJC,    IJC,    IJC,          #   16      23
          IJC,    IJC,    IJC,    IJC,    IJC,    IJC,    IJC,    IJC,          #   24      31
            0,      0,IJC|VEC,      0,      0,      0,      0,      0,          #   32      39
            0,      0,      0,      0,      0,      0,      0,    VEC,          #   40      47
          VHC,    VHC,    VHC,    VHC,    VHC,    VHC,    VHC,    VHC,          #   48      55
          VHC,      0,      0,      0,      0,      0,      0,      0,          #   56      63
            0,    VHC,    VHC,    VHC,    VHC,    VHC,    VHC,      0,          #   64      71
            0,      0,      0,      0,      0,      0,      0,      0,          #   72      79
            0,      0,      0,      0,      0,      0,      0,      0,          #   80      87
            0,      0,      0,      0,IJC|VEC,      0,      0,      0,          #   88      95
            0,    VHC,VEC|VHC,    VHC,    VHC,    VHC,VEC|VHC,      0,          #   96     103
            0,      0,      0,      0,      0,      0,    VEC,      0,          #  104     111
            0,      0,    VEC,      0,    VEC,      0,      0,      0,          #  112     119
            0,      0,      0,      0,      0,      0,      0,      0,          #  120     127
            0,      0,      0,      0,      0,      0,      0,      0,          #  128     135
            0,      0,      0,      0,      0,      0,      0,      0,          #  136     143
            0,      0,      0,      0,      0,      0,      0,      0,          #  144     151
            0,      0,      0,      0,      0,      0,      0,      0,          #  152     159
            0,      0,      0,      0,      0,      0,      0,      0,          #  160     167
            0,      0,      0,      0,      0,      0,      0,      0,          #  168     175
            0,      0,      0,      0,      0,      0,      0,      0,          #  176     183
            0,      0,      0,      0,      0,      0,      0,      0,          #  184     191
            0,      0,      0,      0,      0,      0,      0,      0,          #  192     199
            0,      0,      0,      0,      0,      0,      0,      0,          #  200     207
            0,      0,      0,      0,      0,      0,      0,      0,          #  208     215
            0,      0,      0,      0,      0,      0,      0,      0,          #  216     223
            0,      0,      0,      0,      0,      0,      0,      0,          #  224     231
            0,      0,      0,      0,      0,      0,      0,      0,          #  232     239
            0,      0,      0,      0,      0,      0,      0,      0,          #  240     247
            0,      0,      0,      0,      0,      0,      0,      0,          #  248     255
      ]

    attr_accessor :kind,
                  :bytes


    def jp_token_name
      case @kind
      when IN_END
        return "end_of_input"
      when IN_UEXP
        return "unexpected_input"
      when LBRACE
        return "left_flower_bracket"
      when RBRACE
        return "right_flower_bracket"
      when LSBRAC
        return "left_square_bracket"
      when RSBRAC
        return "right_square_bracket"
      when NULL
        return "null"
      when COLON
        return "colon"
      when COMMA
        return "comma"
      when NUMBER
        return "number"
      when STRING
        return "string"
      when BOOL
        return "boolean"
      else
        raise "unreachable"
      end
    end
  end

  class Lexer
    attr_accessor :content,
                  :content_len,
                  :cursor

    def initialize(content)
      @content = content.bytes
      @content_len = @content.size
      @cursor = 0
    end

    def create_token(kind, bytes)
      token = Token.new
      token.kind = kind
      token.bytes = bytes
      token
    end

    def next
      while @cursor < @content_len && [?\s.ord, ?\n.ord, ?\r.ord, ?\t.ord].include?(@content[@cursor])
        @cursor += 1
      end

      return create_token(Token::IN_END, []) if @cursor >= @content_len

      case @content[@cursor]
      when ?{.ord
        token = create_token(Token::LBRACE, @content[@cursor, 1])
        @cursor += 1
        return token
      when ?}.ord
        token = create_token(Token::RBRACE, @content[@cursor, 1])
        @cursor += 1
        return token
      when ?[.ord
        token = create_token(Token::LSBRAC, @content[@cursor, 1])
        @cursor += 1
        return token
      when ?].ord
        token = create_token(Token::RSBRAC, @content[@cursor, 1])
        @cursor += 1
        return token
      when ?:.ord
        token = create_token(Token::COLON, @content[@cursor, 1])
        @cursor += 1
        return token
      when ?,.ord
        token = create_token(Token::COMMA, @content[@cursor, 1])
        @cursor += 1
        return token
      when ?".ord
        start = @cursor
        @cursor += 1

        while true
          if @cursor >= @content_len
            return create_token(Token::IN_UEXP, @content[start, (@cursor - start)])
          end

          if @content[@cursor] == ?".ord
            @cursor += 1
            return create_token(Token::STRING, @content[start, (@cursor - start)])
          elsif @content[@cursor] == ?\\.ord
            @cursor += 1

            if @cursor >= @content_len
              return create_token(Token::IN_UEXP, @content[start, (@cursor - start)])
            end

            if @content[@cursor] == ?u.ord
              4.times do |i|
                @cursor += 1

                if @cursor >= @content_len
                  return create_token(Token::IN_UEXP, @content[start, (@cursor - start)])
                end

                if Token::CHAR_LOOKUP[@content[@cursor].ord] & Token::VHC == 0
                  return create_token(Token::IN_UEXP, @content[start, (@cursor - start)])
                end
              end

              @cursor += 1
            else
              if Token::CHAR_LOOKUP[@content[@cursor].ord] & Token::VEC != 0
                @cursor += 1
              end
            end
          else
            if Token::CHAR_LOOKUP[@content[@cursor].ord] & Token::IJC != 0
              token = create_token(Token::IN_UEXP, @content[start, (@cursor - start)])
              @cursor += 1
              return token
            end

            @cursor += 1
          end
        end
      when ?n.ord
        start = @cursor
        rest = "ull".bytes
        rest_cursor = 0

        @cursor += 1

        while rest_cursor < rest.size
          if @cursor < @content_len && @content[@cursor] == rest[rest_cursor]
            @cursor += 1
            rest_cursor += 1
          else
            return create_token(Token::IN_UEXP, @content[start, (@cursor - start)])
          end
        end

        return create_token(Token::NULL, @content[start, 4])
      when ?t.ord
        start = @cursor
        rest = "rue".bytes
        rest_cursor = 0

        @cursor += 1

        while rest_cursor < rest.size
          if @cursor < @content_len && @content[@cursor] == rest[rest_cursor]
            @cursor += 1
            rest_cursor += 1
          else
            return create_token(Token::IN_UEXP, @content[start, (@cursor - start)])
          end
        end

        return create_token(Token::BOOL, @content[start, 4])
      when ?f.ord
        start = @cursor
        rest = "alse".bytes
        rest_cursor = 0

        @cursor += 1

        while rest_cursor < rest.size
          if @cursor < @content_len && @content[@cursor] == rest[rest_cursor]
            @cursor += 1
            rest_cursor += 1
          else
            return create_token(Token::IN_UEXP, @content[start, (@cursor - start)])
          end
        end

        return create_token(Token::BOOL, @content[start, 5])
      when ?0.ord, ?1.ord, ?2.ord, ?3.ord, ?4.ord, ?5.ord, ?6.ord, ?7.ord, ?8.ord, ?9.ord, ?-.ord
        start = @cursor
        if @content[@cursor] == ?-.ord
          @cursor += 1
          if @cursor >= @content_len
            return create_token(Token::IN_UEXP, @content[start, (@cursor - start)])
          end
        end

        if @content[@cursor] == ?0.ord
          @cursor += 1

          if @cursor >= @content_len
            return create_token(Token::NUMBER, @content[start, (@cursor - start)])
          end
        elsif @content[@cursor] >= ?1.ord && @content[@cursor] <= ?9.ord
          @cursor += 1

          if @cursor >= @content_len
            return create_token(Token::NUMBER, @content[start, (@cursor - start)])
          end

          while @cursor < @content_len && @content[@cursor] >= ?1.ord && @content[@cursor] <= ?9.ord
            @cursor += 1

            if @cursor >= @content_len
              return create_token(Token::NUMBER, @content[start, (@cursor - start)])
            end
          end
        else
          return create_token(Token::IN_UEXP, @content[@cursor, 1])
        end

        if @content[@cursor] == ?..ord
          @cursor += 1

          if @cursor >= @content_len
            return create_token(Token::IN_UEXP, @content[start, (@cursor - start)])
          end

          digits_after_mark = 0
          while @content[@cursor] >= ?1.ord && @content[@cursor] <= ?9.ord
            digits_after_mark += 1
            @cursor += 1

            if @cursor >= @content_len
              return create_token(Token::NUMBER, @content[start, (@cursor - start)])
            end
          end

          if digits_after_mark == 0
            return create_token(Token::IN_UEXP, @content[@cursor, 1])
          end
        end

        if @content[@cursor] == ?e.ord || @content[@cursor] == ?E.ord
          @cursor += 1

          if @cursor >= @content_len
            return create_token(Token::IN_UEXP, @content[start, (@cursor - start)])
          end

          if @content[@cursor] == ?-.ord || @content[@cursor] == ?+.ord
            @cursor += 1

            if @cursor >= @content_len
              return create_token(Token::IN_UEXP, @content[start, (@cursor - start)])
            end
          end

          digits_after_mark = 0
          while @content[@cursor] >= ?1.ord && @content[@cursor] <= ?9.ord
            digits_after_mark += 1
            @cursor += 1

            if @cursor >= @content_len
              return create_token(Token::NUMBER, @content[start, (@cursor - start)])
            end
          end

          if digits_after_mark == 0
            return create_token(Token::IN_UEXP, @content[@cursor], 1)
          end
        end

        return create_token(Token::NUMBER, @content[start, (@cursor - start)])
      else
        token = create_token(Token::IN_UEXP, @content[@cursor, 1])
        @cursor += 1
        return token
      end
    end
  end
end

input = '{"ns":"yt","el":null,"cpn":["xlxtyyVs😇we9iCQKy"],"ver":2.3e1,"cmt":true,"fmt":false,"fs":"0","rt":-32.213e32'
lexer = JP::Lexer.new(input)
token = lexer.next
while token.kind != JP::Token::IN_END
  puts "token kind:#{token.kind.to_s.rjust(5)} bytes: #{token.bytes}"
  token = lexer.next
end
