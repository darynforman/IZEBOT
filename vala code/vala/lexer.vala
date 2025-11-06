using GLib;

// Lexer for tokenization
class Lexer {
    private string input;
    private int position;
    private int line;
    private int column;

    public Lexer(string input) {
        this.input = input;
        this.position = 0;
        this.line = 1;
        this.column = 1;
    }

    private char current_char() {
        if (position >= input.length) {
            return '\0';
        }
        return input[position];
    }

    private void advance() {
        if (current_char() == '\n') {
            line++;
            column = 1;
        } else {
            column++;
        }
        position++;
    }

    private void skip_whitespace() {
        while (current_char().isspace()) {
            advance();
        }
    }

    private string read_word() {
        StringBuilder sb = new StringBuilder();
        while (current_char().isalnum() || current_char() == '_') {
            sb.append_c(current_char());
            advance();
        }
        return sb.str;
    }

    public List<Token> tokenize() {
        var tokens = new List<Token>();

        while (current_char() != '\0') {
            skip_whitespace();

            if (current_char() == '\0') {
                break;
            }

            int token_line = line;
            int token_column = column;

            if (current_char().isalpha()) {
                string word = read_word();
                if (word == "EXEC") {
                    tokens.append(new Token(TokenType.EXEC, word, token_line, token_column));
                } else if (word == "HALT") {
                    tokens.append(new Token(TokenType.HALT, word, token_line, token_column));
                } else if (word == "key") {
                    tokens.append(new Token(TokenType.KEY, word, token_line, token_column));
                } else if (word == "DRVF" || word == "DRVB" || word == "TRNL" ||
                           word == "TRNR" || word == "SPNL" || word == "SPNR") {
                    tokens.append(new Token(TokenType.MOVEMENT, word, token_line, token_column));
                } else if (word.length == 1 && word[0] >= 'A' && word[0] <= 'D') {
                    tokens.append(new Token(TokenType.IDENTIFIER, word, token_line, token_column));
                } else {
                    tokens.append(new Token(TokenType.INVALID, word, token_line, token_column));
                }
            } else if (current_char() == '=') {
                advance();
                tokens.append(new Token(TokenType.EQUALS, "=", token_line, token_column));
            } else if (current_char() == '>') {
                advance();
                tokens.append(new Token(TokenType.ARROW, ">", token_line, token_column));
            } else {
                string invalid = current_char().to_string();
                advance();
                tokens.append(new Token(TokenType.INVALID, invalid, token_line, token_column));
            }
        }

        tokens.append(new Token(TokenType.EOF, "", line, column));
        return tokens;
    }
}
