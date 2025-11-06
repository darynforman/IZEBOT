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
                        " at line " + got.line.to_string() + ", column " + got.column.to_string() +
                        ".";
            throw new ParserError.SYNTAX_ERROR(msg);
        }
    }

    public ParseNode? parse(out List<string> steps) throws Error {
        derivation_steps = new List<string>();
        // Start with <Program>
        current_form = "<Program>";
        
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
        
        // Expand <Program> -> EXEC <KeyList> HALT
        current_form = replace_first(current_form, "<Program>", "EXEC <KeyList> HALT");
        derivation_steps.append("<Program> -> " + current_form);
        
        expect(TokenType.EXEC, "Expected 'EXEC' at start of program");
        node.add_child(new ParseNode("EXEC", true));
        advance_token();
        
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
        
        // Determine expansion based on lookahead
        int keys = remaining_keys();
        
        if (keys >= 2) {
            // Expand <KeyList> -> <KeyAssignment> <KeyList>
            current_form = replace_first(current_form, "<KeyList>", "<KeyAssignment> <KeyList>");
            derivation_steps.append("<KeyList> -> " + current_form);
            
            // Parse first assignment
            var key_assign = parse_key_assignment();
            node.add_child(key_assign);
            
            // Recursively parse remaining keylist
            var nested_keylist = parse_keylist();
            node.add_child(nested_keylist);
            
        } else if (keys == 1) {
            // Expand <KeyList> -> <KeyAssignment>
            current_form = replace_first(current_form, "<KeyList>", "<KeyAssignment>");
            derivation_steps.append("<KeyList> -> " + current_form);
            
            // Parse the single assignment
            var key_assign = parse_key_assignment();
            node.add_child(key_assign);
        }
        
        return node;
    }

    private ParseNode parse_key_assignment() throws Error {
        var node = new ParseNode("KeyAssignment");
        
        // Expand <KeyAssignment> -> key <Key> = <Movement> >
        current_form = replace_first(current_form, "<KeyAssignment>", "key <Key> = <Movement>>");
        derivation_steps.append("<KeyAssignment> -> " + current_form);
        
        expect(TokenType.KEY, "Expected 'key' keyword");
        node.add_child(new ParseNode("key", true));
        advance_token();
        
        expect(TokenType.IDENTIFIER, "Expected key identifier (A, B, C, or D)");
        var id_token = current_token();
        
        // Create <Key> non-terminal node with terminal child
        var key_node = new ParseNode("Key");
        key_node.add_child(new ParseNode(id_token.value, true));
        node.add_child(key_node);
        
        // Update derivation for <Key>
        current_form = replace_first(current_form, "<Key>", id_token.value);
        derivation_steps.append("<Key> -> " + current_form);
        advance_token();
        
        expect(TokenType.EQUALS, "Expected '=' after key identifier");
        node.add_child(new ParseNode("=", true));
        advance_token();
        
        expect(TokenType.MOVEMENT, "Expected movement (DRVF, DRVB, TRNL, TRNR, SPNL, SPNR)");
        var movement_token = current_token();
        
        // Create <Movement> non-terminal node with terminal child
        var movement_node = new ParseNode("Movement");
        movement_node.add_child(new ParseNode(movement_token.value, true));
        node.add_child(movement_node);
        
        // Update derivation for <Movement>
        current_form = replace_first(current_form, "<Movement>", movement_token.value);
        derivation_steps.append("<Movement> -> " + current_form);
        advance_token();
        
        expect(TokenType.ARROW, "Expected '>' after movement");
        node.add_child(new ParseNode(">", true));
        advance_token();
        
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
                // Look for Key node
                if (child.symbol == "Key" && child.children.length() > 0) {
                    var key_terminal = child.children.nth_data(0);
                    if (key_terminal.is_terminal) {
                        key = key_terminal.symbol;
                    }
                }
                // Look for Movement node
                if (child.symbol == "Movement" && child.children.length() > 0) {
                    var movement_terminal = child.children.nth_data(0);
                    if (movement_terminal.is_terminal) {
                        movement = movement_terminal.symbol;
                    }
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