using GLib;

// Token types for lexical analysis
enum TokenType {
    EXEC,
    HALT,
    KEY,
    EQUALS,
    ARROW,
    IDENTIFIER,
    MOVEMENT,
    EOF,
    INVALID
}

// Token structure
class Token {
    public TokenType type;
    public string value;
    public int line;
    public int column;

    public Token(TokenType type, string value, int line, int column) {
        this.type = type;
        this.value = value;
        this.line = line;
        this.column = column;
    }
}
