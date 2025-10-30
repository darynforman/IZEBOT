using GLib;

errordomain ParserError {
    SYNTAX_ERROR
}

// Parser with LEFTMOST derivation
class Parser {
    private unowned List<Token> tokens;
    private int current;
    private List<string> derivation_steps;
    private ParseNode? parse_tree;
    private string current_form;
    
    // Count remaining KEY tokens from current index (lookahead)
    private int remaining_keys() {
        int cnt = 0;
        for (int i = current; i < (int) tokens.length(); i++) {
            if (tokens.nth_data(i).type == TokenType.KEY) cnt++;
        }
        return cnt;
    }

    public Parser(List<Token> tokens) {
        this.tokens = tokens;
        this.current = 0;
        this.derivation_steps = new List<string>();
    }

    private Token current_token() {
        return tokens.nth_data(current);
    }

    private void advance_token() {
        current++;
    }

    private bool match(TokenType type) {
        return current_token().type == type;
    }

    private string token_display(Token t) {
        if (t.type == TokenType.EOF) return "EOF";
        if (t.value == null || t.value.length == 0) return t.type.to_string();
        return "'" + t.value + "'";
    }

    private string expected_hint(TokenType type) {
        switch (type) {
            case TokenType.EXEC: return "Expected keyword EXEC (uppercase)";
            case TokenType.HALT: return "Expected keyword HALT (uppercase)";
            case TokenType.KEY: return "Expected keyword 'key' (lowercase)";
            case TokenType.EQUALS: return "Expected '=' after identifier";
            case TokenType.ARROW: return "Expected '>' after movement";
            case TokenType.IDENTIFIER: return "Expected identifier A, B, C, or D (uppercase)";
            case TokenType.MOVEMENT: return "Expected movement: DRVF, DRVB, TRNL, TRNR, SPNL, or SPNR (uppercase)";
            case TokenType.EOF: return "Expected end of input";
            default: return "Unexpected token";
        }
    }

    private void expect(TokenType type, string error_msg) throws Error {
        if (!match(type)) {
            Token got = current_token();
            string msg = error_msg + ". " + expected_hint(type) + 
                         ". Found " + token_display(got) + 
                         " at line " + got.line.to_string() + ", column " + got.column.to_string() + ".";
            throw new ParserError.SYNTAX_ERROR(msg);
        }
    }

    public ParseNode? parse(out List<string> steps) throws Error {
        derivation_steps = new List<string>();
        // Start with <program> but do not record a bare line; only record expansions
        current_form = "<program>";

        // As soon as we parse program header, we will mutate current_form
        parse_tree = parse_program();

        // Copy steps to out param
        steps = new List<string>();
        foreach (var s in derivation_steps) {
            steps.append(s);
        }
        return parse_tree;
    }

    private ParseNode parse_program() throws Error {
        var node = new ParseNode("Program");

        expect(TokenType.EXEC, "Expected 'EXEC' at start of program");
        node.add_child(new ParseNode("EXEC", true));
        advance_token();

        // Expand <program> -> EXEC <keylist> HALT in the sentential form
        current_form = replace_first(current_form, "<program>", "EXEC <keylist> HALT");
        derivation_steps.append("<program> -> " + current_form);

        var keylist_node = parse_keylist();
        node.add_child(keylist_node);

        expect(TokenType.HALT, "Expected 'HALT' at end of program");
        node.add_child(new ParseNode("HALT", true));
        advance_token();

        expect(TokenType.EOF, "Unexpected tokens after HALT");
        return node;
    }

    private ParseNode parse_keylist() throws Error {
        var node = new ParseNode("KeyList");

        // Expand <keylist> BEFORE parsing the first assignment, based on lookahead
        int keys = remaining_keys(); // keys to process starting at current
        if (keys <= 0) {
            // Should not happen with a valid grammar; keep as is
        } else if (keys >= 2) {
            current_form = replace_first(current_form, "<keylist>", "<keyassignment> <keylist>");
            derivation_steps.append("<keylist> -> " + current_form);
        } else { // keys == 1
            current_form = replace_first(current_form, "<keylist>", "<keyassignment>");
            derivation_steps.append("<keylist> -> " + current_form);
        }

        // Parse the first assignment
        var key_assign = parse_key_assignment();
        node.add_child(key_assign);

        // For remaining assignments, do the same: expand <keylist> first, then parse
        while (match(TokenType.KEY)) {
            // How many keys remain including this one?
            int k = remaining_keys();
            if (k >= 2) {
                current_form = replace_first(current_form, "<keylist>", "<keyassignment> <keylist>");
                derivation_steps.append("<keylist> -> " + current_form);
            } else { // k == 1
                current_form = replace_first(current_form, "<keylist>", "<keyassignment>");
                derivation_steps.append("<keylist> -> " + current_form);
            }

            var next_assign = parse_key_assignment();
            node.add_child(next_assign);
        }
        return node;
    }

    private ParseNode parse_key_assignment() throws Error {
        var node = new ParseNode("KeyAssignment");

        expect(TokenType.KEY, "Expected 'key' keyword");
        node.add_child(new ParseNode("key", true));
        advance_token();

        expect(TokenType.IDENTIFIER, "Expected key identifier (A, B, C, or D)");
        var id_token = current_token();
        node.add_child(new ParseNode(id_token.value, true));
        advance_token();

        expect(TokenType.EQUALS, "Expected '=' after key identifier");
        node.add_child(new ParseNode("=", true));
        advance_token();

        expect(TokenType.MOVEMENT, "Expected movement (DRVF, DRVB, TRNL, TRNR, SPNL, SPNR)");
        var movement_token = current_token();
        node.add_child(new ParseNode(movement_token.value, true));
        advance_token();

        expect(TokenType.ARROW, "Expected '>' after movement");
        node.add_child(new ParseNode(">", true));
        advance_token();

        // Leftmost substitution in the current sentential form
        current_form = replace_first(current_form, "<keyassignment>", "key <key> = <movement> >");
        derivation_steps.append("<keyassignment> -> " + current_form);
        current_form = replace_first(current_form, "<key>", id_token.value);
        derivation_steps.append("<key> -> " + current_form);
        current_form = replace_first(current_form, "<movement>", node.children.nth_data(3).symbol);
        derivation_steps.append("<movement> -> " + current_form);

        return node;
    }

    // Replace first occurrence of needle in s with replacement
    private string replace_first(string s, string needle, string replacement) {
        int idx = s.index_of(needle);
        if (idx < 0) return s;
        StringBuilder sb = new StringBuilder();
        sb.append(s.substring(0, idx));
        sb.append(replacement);
        sb.append(s.substring(idx + (int) needle.length));
        return sb.str;
    }

    public List<KeyMapping> extract_mappings() {
        var mappings = new List<KeyMapping>();
        if (parse_tree == null) {
            return mappings;
        }
        extract_mappings_recursive(parse_tree, mappings);
        return mappings;
    }

    private void extract_mappings_recursive(ParseNode node, List<KeyMapping> mappings) {
        if (node.symbol == "KeyAssignment") {
            string? key = null;
            string? movement = null;
            foreach (var child in node.children) {
                if (child.is_terminal && child.symbol.length == 1 && child.symbol[0] >= 'A' && child.symbol[0] <= 'D') {
                    key = child.symbol;
                } else if (child.is_terminal && (child.symbol == "DRVF" || child.symbol == "DRVB" || child.symbol == "TRNL" || child.symbol == "TRNR" || child.symbol == "SPNL" || child.symbol == "SPNR")) {
                    movement = child.symbol;
                }
            }
            if (key != null && movement != null) {
                mappings.append(new KeyMapping(key, movement));
            }
        }
        foreach (var c in node.children) {
            extract_mappings_recursive(c, mappings);
        }
    }
}
