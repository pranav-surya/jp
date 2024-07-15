class JP
  class Token
    IN_END 	     = 0
    IN_UEXP       = 1
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

    attr_accessor :kind,
                  :text,
                  :text_len
    def name
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
      @content = content
      @content_len = content.size
      @cursor = 0
    end

    def create_token(kind, text, text_len)
      token = Token.new
      token.kind = kind
      token.text = text
      token.text_len = text_len
      token
    end

    def next
      while @cursor < @content_len && [?\s, ?\n, ?\r, ?\t].include?(@content[@cursor])
        @cursor += 1
      end

      return create_token(Token::IN_END, "", 0) if @cursor >= @content_len

      case @content[@cursor]
      when ?{
        token = create_token(Token::LBRACE, @content[@cursor], 1)
        @cursor += 1
        return token
      when ?}
        token = create_token(Token::RBRACE, @content[@cursor], 1)
        @cursor += 1
        return token
      when ?[
        token = create_token(Token::LSBRAC, @content[@cursor], 1)
        @cursor += 1
        return token
      when ?]
        token = create_token(Token::RSBRAC, @content[@cursor], 1)
        @cursor += 1
        return token
      when ?:
        token = create_token(Token::COLON, @content[@cursor], 1)
        @cursor += 1
        return token
      when ?,
        token = create_token(Token::COMMA, @content[@cursor], 1)
        @cursor += 1
        return token
      when ?"
        @cursor += 1
        start = @cursor

        while @cursor < @content_len && @content[@cursor] != ?"
          @cursor += 1
        end

        token = create_token(Token::STRING, @content[start, (@cursor - start)], (@cursor - start))
        @cursor += 1
        return token
      when ?n
        start = @cursor
        rest = "ull"
        rest_cursor = 0

        @cursor += 1

        while rest_cursor < rest.size
          if @cursor < @content_len && @content[@cursor] == rest[rest_cursor]
            @cursor += 1
            rest_cursor += 1
          else
            return create_token(Token::IN_UEXP, @content[start, (@cursor - start)], (@cursor - start))
          end
        end

        return create_token(Token::NULL, @content[start, 4], 4)
      when ?t
        start = @cursor
        rest = "rue"
        rest_cursor = 0

        @cursor += 1

        while rest_cursor < rest.size
          if @cursor < @content_len && @content[@cursor] == rest[rest_cursor]
            @cursor += 1
            rest_cursor += 1
          else
            return create_token(Token::IN_UEXP, @content[start, (@cursor - start)], (@cursor - start))
          end
        end

        return create_token(Token::BOOL, @content[start, 4], 4)
      when ?f
        start = @cursor
        rest = "alse"
        rest_cursor = 0

        @cursor += 1

        while rest_cursor < rest.size
          if @cursor < @content_len && @content[@cursor] == rest[rest_cursor]
            @cursor += 1
            rest_cursor += 1
          else
            return create_token(Token::IN_UEXP, @content[start, (@cursor - start)], (@cursor - start))
          end
        end

        return create_token(Token::BOOL, @content[start, 5], 5)
      when ?0, ?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?-
        start = @cursor
        if @content[@cursor] == ?-
          @cursor += 1
          if @cursor >= @content_len
            return create_token(Token::IN_UEXP, @content[start, (@cursor - start)], (@cursor - start))
          end
        end

        if @content[@cursor] == ?0
          @cursor += 1

          if @cursor >= @content_len
            return create_token(Token::NUMBER, @content[start, (@cursor - start)], (@cursor - start))
          end
        elsif @content[@cursor] >= ?1 && @content[@cursor] <= ?9
          @cursor += 1

          if @cursor >= @content_len
            return create_token(Token::NUMBER, @content[start, (@cursor - start)], (@cursor - start))
          end

          while @cursor < @content_len && @content[@cursor] >= ?1 && @content[@cursor] <= ?9
            @cursor += 1

            if @cursor >= @content_len
              return create_token(Token::NUMBER, @content[start, (@cursor - start)], (@cursor - start))
            end
          end
        else
          return create_token(Token::IN_UEXP, @content[@cursor], 1)
        end

        if @content[@cursor] == ?.
          @cursor += 1

          if @cursor >= @content_len
            return create_token(Token::IN_UEXP, @content[start, (@cursor - start)], (@cursor - start))
          end

          digits_after_mark = 0
          while @content[@cursor] >= ?1 && @content[@cursor] <= ?9
            digits_after_mark += 1
            @cursor += 1

            if @cursor >= @content_len
              return create_token(Token::NUMBER, @content[start, (@cursor - start)], (@cursor - start))
            end
          end

          if digits_after_mark == 0
            return create_token(Token::IN_UEXP, @content[@cursor], 1)
          end
        end

        if @content[@cursor] == ?e || @content[@cursor] == ?E
          @cursor += 1

          if @cursor >= @content_len
            return create_token(Token::IN_UEXP, @content[start, (@cursor - start)], (@cursor - start))
          end

          if @content[@cursor] == ?- || @content[@cursor] == ?+
            @cursor += 1

            if @cursor >= @content_len
              return create_token(Token::IN_UEXP, @content[start, (@cursor - start)], (@cursor - start))
            end
          end

          digits_after_mark = 0
          while @content[@cursor] >= ?1 && @content[@cursor] <= ?9
            digits_after_mark += 1
            @cursor += 1

            if @cursor >= @content_len
              return create_token(Token::NUMBER, @content[start, (@cursor - start)], (@cursor - start))
            end
          end

          if digits_after_mark == 0
            return create_token(Token::IN_UEXP, @content[@cursor], 1)
          end
        end

        return create_token(Token::NUMBER, @content[start, (@cursor - start)], (@cursor - start))
      else
        token = create_token(Token::IN_UEXP, @content[@cursor], 1)
        @cursor += 1
        return token
      end
    end
  end
end

input = '{"ns":"yt","el":null,"cpn":["xlxtyyVswe9iCQKy"],"ver":2.3e1,"cmt":true,"fmt":false,"fs":"0","rt":-32.2e-32'
lexer = JP::Lexer.new(input)
token = lexer.next
while token.kind != JP::Token::IN_END
  puts "#{token.name.ljust(30)}: '#{token.text}'"
  token = lexer.next
end
