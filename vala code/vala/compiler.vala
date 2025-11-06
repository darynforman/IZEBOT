using GLib;

// Main Compiler Orchestrator
class Compiler {
    // Build a detailed error message for an invalid lexeme
    private static string describe_invalid(string lexeme) {
        string up = lexeme.up();
        string low = lexeme.down();

        // Keywords with case rules
        if (up == "EXEC" && lexeme != "EXEC")
            return "Keyword EXEC must be uppercase 'EXEC'";
        if (up == "HALT" && lexeme != "HALT")
            return "Keyword HALT must be uppercase 'HALT'";
        if (up == "KEY" && lexeme != "key")
            return "Keyword 'key' must be lowercase 'key'";

        // Movements
        string[] moves = {"DRVF","DRVB","TRNL","TRNR","SPNL","SPNR"};
        foreach (var m in moves) {
            if (up == m && lexeme != m)
                return "Movement '" + m + "' must be uppercase '" + m + "'";
        }

        // Identifiers are single uppercase letters A-D
        if (lexeme.length >= 1) {
            bool all_alpha = true;
            for (int i = 0; i < lexeme.length; i++) {
                if (!lexeme[i].isalpha()) { all_alpha = false; break; }
            }
            if (all_alpha) {
                if (lexeme.length == 1) {
                    char c = lexeme[0];
                    if (c >= 'a' && c <= 'd')
                        return "Identifiers must be uppercase A-D (got '" + lexeme + "')";
                    if (c < 'A' || c > 'D')
                        return "Only identifiers A, B, C, or D are allowed (got '" + lexeme + "')";
                } else {
                    return "Identifiers must be a single uppercase letter A-D (got '" + lexeme + "')";
                }
            }
        }

        // Unexpected symbols
        if (lexeme.length == 1 && !lexeme[0].isalnum() && lexeme != "=" && lexeme != ">")
            return "Unexpected character '" + lexeme + "'. Only '=' and '>' are valid symbols.";

        // Fallback
        return "Unrecognized word '" + lexeme + "'. Expected EXEC, HALT, key, A-D, or a movement (DRVF, DRVB, TRNL, TRNR, SPNL, SPNR).";
    }
    private static void pause(string msg = "Press Enter to continue...") {
        stdout.printf("\n%s\n", msg);
        stdout.flush();
        stdin.read_line();
    }
    public static bool compile(string input_text) {
        stdout.printf("\n%s\n", string.nfill(70, '='));
        stdout.printf("  PROCESSING INPUT\n");
        stdout.printf("%s\n\n", string.nfill(70, '='));

        // 1) Lexical Analysis
        stdout.printf("[1] LEXICAL ANALYSIS\n");
        var lexer = new Lexer(input_text);
        var tokens = lexer.tokenize();

        bool has_invalid = false;
        foreach (var token in tokens) {
            if (token.type == TokenType.INVALID) {
                has_invalid = true;
                string detail = describe_invalid(token.value);
                stdout.printf("ERROR: %s at line %d, column %d (token '%s')\n", detail, token.line, token.column, token.value);
            }
        }
        if (has_invalid) {
            stdout.printf("\n[X] LEXICAL ANALYSIS FAILED\nThe input contains invalid tokens.\n\n");
            pause();
            return false;
        }
        stdout.printf("[OK] Tokenization successful\n\n");

        // 2) Syntax Analysis
        stdout.printf("[2] SYNTAX ANALYSIS (LEFTMOST DERIVATION)\n");
        var parser = new Parser(tokens);
        try {
            List<string> steps;
            var parse_tree = parser.parse(out steps);

            stdout.printf("\nDerivation Steps:\n\n");
            // Print numbered steps with only the first line showing the LHS, others show just an aligned arrow
            string? prev = null;
            int i = 1;
            const int LHS_COL = 16; // width for left side
            bool first_line = true;
            foreach (var s in steps) {
                if (prev != null && s == prev) continue;

                int idx = s.index_of("->");
                if (idx >= 0) {
                    string lhs = s.substring(0, idx).strip();
                    string rhs = s.substring(idx + 2).strip();
                    if (first_line) {
                        int pad = LHS_COL - (int) lhs.length;
                        if (pad < 1) pad = 1;
                        stdout.printf("%02d  %s%s  ->  %s\n", i++, lhs, string.nfill(pad, ' '), rhs);
                        first_line = false;
                    } else {
                        // Print spaces to keep arrow aligned under first LHS column
                        stdout.printf("%02d  %s  ->  %s\n", i++, string.nfill(LHS_COL, ' '), rhs);
                    }
                } else {
                    // Fallback: print raw if format unexpected
                    stdout.printf("%02d  %s\n", i++, s);
                }
                prev = s;
            }
            stdout.printf("\n[OK] Derivation successful - Input is a VALID sentence\n\n");
            // Pause after successful derivation
            pause();

            // 3) Parse Tree (pretty, array-based layout)
            stdout.printf("[3] PARSE TREE\n\n");
            TreeVisualizer.print_tree_pretty(parse_tree);
            // Pause after displaying parse tree
            pause();

            // 4) Semantic Analysis
            stdout.printf("\n[4] SEMANTIC ANALYSIS\n\n");
            var table = SemanticAnalyzer.extract_mapping_table(parse_tree);
            stdout.printf("Key Mappings Extracted:\n");
            // Convert to list for generator
            var mappings = new List<KeyMapping>();
            table.foreach((k, v) => {
                stdout.printf("  * Key %s -> %s\n", k, v);
                mappings.append(new KeyMapping(k, v));
            });

            // 5) Code Generation
            stdout.printf("\n[5] CODE GENERATION\n\n");
            var gen = new CodeGenerator(mappings);
            string code = gen.generate();
            stdout.printf("Generated PBASIC Code:\n\n");
            stdout.printf("%s\n", string.nfill(70, '-'));
            stdout.printf("%s", code);
            stdout.printf("%s\n", string.nfill(70, '-'));

            // Save file
            try {
                FileUtils.set_contents("IZEBOT.BSP", code);
                stdout.printf("\n[OK] Code saved to IZEBOT.BSP\n\n");
            } catch (FileError e) {
                stdout.printf("\n[!] Warning: Could not save IZEBOT.BSP: %s\n\n", e.message);
            }

            // Pause after code generation and (attempted) save
            pause();

            stdout.printf("%s\n", string.nfill(70, '='));
            stdout.printf("  COMPILATION SUCCESSFUL\n");
            stdout.printf("%s\n\n", string.nfill(70, '='));
            return true;

        } catch (Error e) {
            stdout.printf("\n[X] SYNTAX ERROR: %s\n\n", e.message);
            stdout.printf("The input string does NOT conform to the meta-language grammar.\n\n");
            stdout.printf("%s\n", string.nfill(70, '='));
            stdout.printf("  COMPILATION FAILED\n");
            stdout.printf("%s\n\n", string.nfill(70, '='));
            pause();
            return false;
        }
    }
}
