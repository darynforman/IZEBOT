using GLib;

// Code Generator for PBASIC
class CodeGenerator {
    private unowned List<KeyMapping> mappings;

    public CodeGenerator(List<KeyMapping> mappings) {
        this.mappings = mappings;
    }

    public string generate() {
        StringBuilder code = new StringBuilder();

        // HEADER BLOCK
        code.append("'{$STAMP BS2p}\n");
        code.append("'{$PBASIC 2.5}\n");
        code.append("KEY       VAR     Byte\n");
        code.append("Main:     DO\n");
        code.append("            SERIN 3,2063,250,Timeout,[KEY]\n\n");

        // BODY BLOCK - Button assignments
        foreach (var mapping in mappings) {
            string routine = routine_name(mapping.movement);
            code.append(@"            IF KEY = \"$(mapping.key)\" OR KEY = \"$(mapping.key.down())\" THEN GOSUB $(routine)\n");
        }
        code.append("\n");

        // FOOTER 1 Code
        code.append("          LOOP\n");
        code.append("Timeout:  GOSUB Motor_OFF\n");
        code.append("          GOTO Main\n\n");
        code.append("'+++++ Movement Procedure ++++++++++++++++++++++++++++++++\n\n");

        // SUBROUTINES (include only used)
        var used = new List<string>();
        foreach (var m in mappings) {
            bool found = false;
            foreach (var u in used) { if (u == m.movement) { found = true; break; } }
            if (!found) used.append(m.movement);
        }

        if (contains(used, "DRVF")) code.append("Forward:   HIGH 13 : LOW 12 : HIGH 15 : LOW 14 : RETURN\n");
        if (contains(used, "DRVB")) code.append("Backward:  HIGH 12 : LOW 13 : HIGH 14 : LOW 15 : RETURN\n");
        if (contains(used, "TRNL")) code.append("TurnLeft:  HIGH 13 : LOW 12 : LOW 15 : LOW 14 : RETURN\n");
        if (contains(used, "TRNR")) code.append("TurnRight: LOW 13 : LOW 12 : HIGH 15 : LOW 14 : RETURN\n");
        if (contains(used, "SPNL")) code.append("SpinLeft:  HIGH 13 : LOW 12 : HIGH 14 : LOW 15 : RETURN\n");
        if (contains(used, "SPNR")) code.append("SpinRight: HIGH 12 : LOW 13 : HIGH 15 : LOW 14 : RETURN\n");

        code.append("\n");
        code.append("Motor_OFF: LOW  13 : LOW 12 : LOW  15 : LOW 14 : RETURN\n");
        code.append("'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n");

        return code.str;
    }

    private bool contains(List<string> list, string item) {
        foreach (var it in list) { if (it == item) return true; }
        return false;
    }

    private string routine_name(string movement) {
        switch (movement) {
            case "DRVF": return "Forward";
            case "DRVB": return "Backward";
            case "TRNL": return "TurnLeft";
            case "TRNR": return "TurnRight";
            case "SPNL": return "SpinLeft";
            case "SPNR": return "SpinRight";
            default: return "Motor_OFF";
        }
    }
}
