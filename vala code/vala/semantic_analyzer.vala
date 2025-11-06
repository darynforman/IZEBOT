using GLib;

// Key-Movement pair
class KeyMapping {
    public string key;
    public string movement;

    public KeyMapping(string key, string movement) {
        this.key = key;
        this.movement = movement;
    }
}

// Semantic analyzer to extract key mappings from parse tree
class SemanticAnalyzer {
    // Backwards-compatible API: return list of mappings
    public static List<KeyMapping> extract_mappings(ParseNode root) {
        var list = new List<KeyMapping>();
        var table = extract_mapping_table(root);
        table.foreach((k, v) => {
            list.append(new KeyMapping(k, v));
        });
        return (owned) list;
    }

    // Preferred API: return semantic table key->movement
    public static HashTable<string,string> extract_mapping_table(ParseNode root) {
        var table = new HashTable<string,string>(str_hash, str_equal);
        extract_recursive_into_table(root, table);
        return (owned) table;
    }

    private static void extract_recursive_into_table(ParseNode node, HashTable<string,string> table) {
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
                // Store in semantic table (latest assignment wins if duplicates)
                table.insert(key, movement);
            }
        }

        foreach (var c in node.children) {
            extract_recursive_into_table(c, table);
        }
    }
}

