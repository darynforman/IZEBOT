using GLib;

class Program {
    public static int main(string[] args) {
        stdout.printf("\n%s\n\n", string.nfill(70, '='));
        stdout.printf("           iZEBOT Meta-Language Compiler v1.0\n");
        stdout.printf("           CMPS3111 Programming Project 2\n\n");
        stdout.printf("%s\n\n", string.nfill(70, '='));

        stdout.printf("Enter meta-language sentences (or 'QUIT' to exit)\n");
        stdout.printf("You can enter multi-line input. Press Enter on an empty line to process.\n\n");

        while (true) {
            // Show grammar on every loop-back to (a)
            GrammarDisplay.show();
            stdout.printf(">>> ");
            stdout.flush();

            string? line = stdin.read_line();
            if (line == null) break;
            line = line.strip();

            // Exit is case-sensitive: only exact "QUIT" terminates the program
            if (line == "QUIT") {
                stdout.printf("\nGoodbye!\n\n");
                break;
            }

            // Accept program input starting with EXEC (case-insensitive)
            if (line.up().has_prefix("EXEC")) {
                StringBuilder input = new StringBuilder();
                input.append(line);
                input.append_c('\n');

                while (true) {
                    stdout.printf("... ");
                    stdout.flush();

                    string? next_line = stdin.read_line();
                    if (next_line == null) break;
                    next_line = next_line.strip();

                    if (next_line == "") break;

                    input.append(next_line);
                    input.append_c('\n');

                    // Stop collecting once HALT (case-insensitive) is provided
                    if (next_line.up() == "HALT") break;
                }

                // Run full compile pipeline for the collected multi-line program
                Compiler.compile(input.str);
            } else if (line != "") {
                stdout.printf("[!] Input should start with 'EXEC'. Try again or type 'QUIT' to exit.\n\n");
            }
        }

        return 0;
    }
}
