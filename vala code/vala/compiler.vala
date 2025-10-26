using GLib;

// Main Compiler Orchestrator
class Compiler {
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
                stdout.printf("ERROR: Invalid token '%s' at line %d, column %d\n", token.value, token.line, token.column);
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

            stdout.printf("\nDerivation Steps:\n");
            int i = 1;
            foreach (var s in steps) {
                stdout.printf("  %d. %s\n", i++, s);
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
