require "stringio"

class JP
  class Token
    InEnd 	=   0
    InUexp =    1
    Lbrace 	=   2
    Rbrace 	=   3
    Colon 	=   4
    Comma 	=   5
    String  =   6
    Lsbrac  =   7
    Rsbrac  =   8
    Int     =   9
    Float   =  10
    Null    =  11
    Bool    =  12

    VEC = 1
    VHC = 2
    IJC = 4
    ValCharLookup =
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
      when InEnd
        return "end_of_input"
      when InUexp
        return "unexpected_input"
      when Lbrace
        return "left_flower_bracket"
      when Rbrace
        return "right_flower_bracket"
      when Lsbrac
        return "left_square_bracket"
      when Rsbrac
        return "right_square_bracket"
      when Null
        return "null"
      when Colon
        return "colon"
      when Comma
        return "comma"
      when Int
        return "integer"
      when Float
        return "floating_point_number"
      when String
        return "string"
      when Bool
        return "boolean"
      else
        raise "unreachable"
      end
    end

    def to_utf8
      bytes.pack("C*").force_encoding("UTF-8")
    end
  end

  class Lexer
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
      while @cursor < @content_len && ["\s".ord, "\n".ord, "\r".ord, "\t".ord].include?(@content[@cursor])
        @cursor += 1
      end

      return create_token(Token::InEnd, []) if @cursor >= @content_len

      case @content[@cursor]
      when "{".ord
        token = create_token(Token::Lbrace, @content[@cursor, 1])
        @cursor += 1
        return token
      when "}".ord
        token = create_token(Token::Rbrace, @content[@cursor, 1])
        @cursor += 1
        return token
      when "[".ord
        token = create_token(Token::Lsbrac, @content[@cursor, 1])
        @cursor += 1
        return token
      when "]".ord
        token = create_token(Token::Rsbrac, @content[@cursor, 1])
        @cursor += 1
        return token
      when ":".ord
        token = create_token(Token::Colon, @content[@cursor, 1])
        @cursor += 1
        return token
      when ",".ord
        token = create_token(Token::Comma, @content[@cursor, 1])
        @cursor += 1
        return token
      when "\"".ord
        @cursor += 1
        start = @cursor

        while true
          if @cursor >= @content_len
            return create_token(Token::InUexp, @content[start, (@cursor - start)])
          end

          if @content[@cursor] == "\"".ord
            token = create_token(Token::String, @content[start, (@cursor - start)])
            @cursor += 1
            return token
          elsif @content[@cursor] == "\\".ord
            @cursor += 1

            if @cursor >= @content_len
              return create_token(Token::InUexp, @content[start, (@cursor - start)])
            end

            if @content[@cursor] == "u".ord
              4.times do |i|
                @cursor += 1

                if @cursor >= @content_len
                  return create_token(Token::InUexp, @content[start, (@cursor - start)])
                end

                if Token::ValCharLookup[@content[@cursor].ord] & Token::VHC == 0
                  return create_token(Token::InUexp, @content[start, (@cursor - start)])
                end
              end

              @cursor += 1
            else
              if Token::ValCharLookup[@content[@cursor].ord] & Token::VEC != 0
                @cursor += 1
              end
            end
          else
            if Token::ValCharLookup[@content[@cursor].ord] & Token::IJC != 0
              token = create_token(Token::InUexp, @content[start, (@cursor - start)])
              @cursor += 1
              return token
            end

            @cursor += 1
          end
        end
      when "n".ord
        start = @cursor
        rest = "ull".bytes
        rest_cursor = 0
        @cursor += 1

        while rest_cursor < rest.size
          if @cursor < @content_len && @content[@cursor] == rest[rest_cursor]
            @cursor += 1
            rest_cursor += 1
          else
            return create_token(Token::InUexp, @content[start, (@cursor - start)])
          end
        end

        return create_token(Token::Null, @content[start, 4])
      when "t".ord
        start = @cursor
        rest = "rue".bytes
        rest_cursor = 0
        @cursor += 1

        while rest_cursor < rest.size
          if @cursor < @content_len && @content[@cursor] == rest[rest_cursor]
            @cursor += 1
            rest_cursor += 1
          else
            return create_token(Token::InUexp, @content[start, (@cursor - start)])
          end
        end

        return create_token(Token::Bool, @content[start, 4])
      when "f".ord
        start = @cursor
        rest = "alse".bytes
        rest_cursor = 0
        @cursor += 1

        while rest_cursor < rest.size
          if @cursor < @content_len && @content[@cursor] == rest[rest_cursor]
            @cursor += 1
            rest_cursor += 1
          else
            return create_token(Token::InUexp, @content[start, (@cursor - start)])
          end
        end

        return create_token(Token::Bool, @content[start, 5])
      when "0".ord, "1".ord, "2".ord, "3".ord, "4".ord, "5".ord, "6".ord, "7".ord, "8".ord, "9".ord, "-".ord
        start = @cursor
        is_float = false

        if @content[@cursor] == "-".ord
          @cursor += 1
          if @cursor >= @content_len
            return create_token(Token::InUexp, @content[start, (@cursor - start)])
          end
        end

        if @content[@cursor] == "0".ord
          @cursor += 1

          if @cursor >= @content_len
            return create_token(Token::Int, @content[start, (@cursor - start)])
          end
        elsif @content[@cursor] >= "1".ord && @content[@cursor] <= "9".ord
          @cursor += 1

          if @cursor >= @content_len
            return create_token(Token::Int, @content[start, (@cursor - start)])
          end

          while @cursor < @content_len && @content[@cursor] >= "0".ord && @content[@cursor] <= "9".ord
            @cursor += 1

            if @cursor >= @content_len
              return create_token(Token::Int, @content[start, (@cursor - start)])
            end
          end
        else
          return create_token(Token::InUexp, @content[@cursor, 1])
        end

        if @content[@cursor] == ".".ord
          is_float = true
          @cursor += 1

          if @cursor >= @content_len
            return create_token(Token::InUexp, @content[start, (@cursor - start)])
          end

          digits_after_mark = 0
          while @content[@cursor] >= "0".ord && @content[@cursor] <= "9".ord
            digits_after_mark += 1
            @cursor += 1

            if @cursor >= @content_len
              return create_token(Token::Float, @content[start, (@cursor - start)])
            end
          end

          if digits_after_mark == 0
            return create_token(Token::InUexp, @content[@cursor, 1])
          end
        end

        if @content[@cursor] == "e".ord || @content[@cursor] == "E".ord
          is_float = true
          @cursor += 1

          if @cursor >= @content_len
            return create_token(Token::InUexp, @content[start, (@cursor - start)])
          end

          if @content[@cursor] == "-".ord || @content[@cursor] == "+".ord
            @cursor += 1

            if @cursor >= @content_len
              return create_token(Token::InUexp, @content[start, (@cursor - start)])
            end
          end

          digits_after_mark = 0
          while @content[@cursor] >= "0".ord && @content[@cursor] <= "9".ord
            digits_after_mark += 1
            @cursor += 1

            if @cursor >= @content_len
              return create_token(Token::Float, @content[start, (@cursor - start)])
            end
          end

          if digits_after_mark == 0
            return create_token(Token::InUexp, @content[@cursor], 1)
          end
        end

        if is_float
          return create_token(Token::Float, @content[start, (@cursor - start)])
        else
          return create_token(Token::Int, @content[start, (@cursor - start)])
        end
      else
        token = create_token(Token::InUexp, @content[@cursor, 1])
        @cursor += 1
        return token
      end
    end
  end

  class Parser
    def unexpected_token?
      @current_token.kind == Token::InEnd || @current_token.kind == Token::InUexp
    end

    def parse2(input)
      json_raw = StringIO.new(input)
      @stack = []
      @state = :start
      @result_stack = []

      loop do
        chunk = json_raw.read(1024)
        break unless chunk

        chunk.each_byte do |byte|
          case @state
          when :start
            puts "start"
            start_value(byte)
          when :start_object
            puts "start_object"
            case byte
            when "}".ord
              puts "end_object"
              raise "unexpected byte: #{byte}" if @stack.pop != :object
            end
          end
        end
      end
    end

    def start_value(byte)
      case byte
      when "{".ord
        @stack << :object
        @result_stack << {}
        @state = :start_object
      end
    end

    def parse(input)
      @lexer = JP::Lexer.new(input)
      @current_token = @lexer.next
      parse_value
    end

    def parse_value
      case @current_token.kind
      when Token::Lbrace
        parse_object
      when Token::Lsbrac
        parse_array
      when Token::Bool
        @current_token.to_utf8 == "true"
      when Token::Null
        nil
      when Token::Int
        @current_token.to_utf8.to_i
      when Token::String
        @current_token.to_utf8
      when Token::Float
        @current_token.to_utf8.to_f
      when Token::InUexp
        raise "unexpected token: #{@current_token.jp_token_name}"
      else
        raise "unimplemented token: #{@current_token.jp_token_name}"
      end
    end

    def parse_object
      parsed_object = {}
      @current_token = @lexer.next

      raise "unexpected token: #{@current_token.jp_token_name}" if unexpected_token?
      return parsed_object if @current_token.kind == Token::Rbrace

      member_key, member_value = parse_member
      parsed_object[member_key] = member_value
      @current_token = @lexer.next

      raise "unexpected token: #{@current_token.jp_token_name}" if unexpected_token?
      return parsed_object if @current_token.kind == Token::Rbrace

      if @current_token.kind == Token::Comma
        @current_token = @lexer.next
        loop do
          member_key, member_value = parse_member
          parsed_object[member_key] = member_value
          @current_token = @lexer.next

          raise "unexpected token: #{@current_token.jp_token_name}" if unexpected_token?
          return parsed_object if @current_token.kind == Token::Rbrace

          if @current_token.kind == Token::Comma
            @current_token = @lexer.next
          else
            raise "members must be separated by comma but was #{@current_token.jp_token_name}"
          end
        end
      else
        raise "members must be separated by comma but was #{@current_token.jp_token_name}"
      end
    end

    def parse_array
      parsed_array = []
      @current_token = @lexer.next

      raise "unexpected token: #{@current_token.jp_token_name}" if unexpected_token?   
      return parsed_array if @current_token.kind == Token::Rsbrac

      parsed_array << parse_value
      @current_token = @lexer.next

      raise "unexpected token: #{@current_token.jp_token_name}" if unexpected_token?
      return parsed_array if @current_token.kind == Token::Rsbrac

      if @current_token.kind == Token::Comma
        @current_token = @lexer.next
        loop do
          parsed_array << parse_value
          @current_token = @lexer.next

          raise "unexpected token: #{@current_token.jp_token_name}" if unexpected_token?
          return parsed_array if @current_token.kind == Token::Rsbrac

          if @current_token.kind == Token::Comma
            @current_token = @lexer.next
          else
            raise "elements must be separated by comma but was #{@current_token.jp_token_name}"
          end
        end
      else
        raise "elements must be separated by comma but was #{@current_token.jp_token_name}"
      end
    end

    def parse_member
      if @current_token.kind != Token::String
        raise "member key must be a string but was #{@current_token.jp_token_name}"
      end

      member_key = @current_token.to_utf8
      @current_token = @lexer.next

      raise "unexpected token: #{@current_token.jp_token_name}" if unexpected_token?
      if @current_token.kind != Token::Colon
        raise "member key and value should be separated by colon but was #{@current_token.jp_token_name}"
      end

      @current_token = @lexer.next
      member_value = parse_value
      [member_key, member_value]
    end
  end
end

# json_raw = '{"s": {"x": "pranav surya", "t": 23}, "n":"yt", "b":12, "c": 13.23, "d": -13.23, "e": 0.32e-23, "world": false, "find": true, "a": [12, -132, -13.0e+23, null, true, false]}'
begin
  json_raw = File.read("/Users/prsurya/Desktop/jp/json-data.json")
  pp JP::Parser.new.parse(json_raw)

rescue StandardError => e
  puts "unexpected error: #{e.message}"
ensure
  # json_raw.close
end