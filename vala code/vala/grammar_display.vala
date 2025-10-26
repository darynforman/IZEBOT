using GLib;

// Grammar Display
class GrammarDisplay {
    public static void show() {
        stdout.printf("\n");
        stdout.printf("%s\n", string.nfill(70, '='));
        stdout.printf("          iZEBOT Meta-Language BNF Grammar\n");
        stdout.printf("%s\n\n", string.nfill(70, '='));
        stdout.printf("  <Program>        ::= EXEC <KeyList> HALT\n");
        stdout.printf("  <KeyList>        ::= <KeyAssignment> | <KeyAssignment> <KeyList>\n");
        stdout.printf("  <KeyAssignment>  ::= key <Key> = <Movement>>\n");
        stdout.printf("  <Key>            ::= A | B | C | D\n");
        stdout.printf("  <Movement>       ::= DRVF | DRVB | TRNL | TRNR | SPNL | SPNR\n\n");
        stdout.printf("  Where:\n");
        stdout.printf("    * DRVF = Drive Forward\n");
        stdout.printf("    * DRVB = Drive Backward\n");
        stdout.printf("    * TRNL = Turn Left\n");
        stdout.printf("    * TRNR = Turn Right\n");
        stdout.printf("    * SPNL = Spin Left\n");
        stdout.printf("    * SPNR = Spin Right\n\n");
        stdout.printf("%s\n\n", string.nfill(70, '='));
    }
}
