using GLib;

// Parse Tree Visualizer
class TreeVisualizer {
    public static void print_tree(ParseNode node, string prefix = "", bool is_last = true) {
        string connector = is_last ? "+-- " : "|-- ";
        stdout.printf("%s%s%s\n", prefix, connector, node.symbol);

        string child_prefix = prefix + (is_last ? "    " : "|   ");
        uint count = node.children.length();
        uint i = 0;
        foreach (var child in node.children) {
            i++;
            bool last = (i == count);
            print_tree(child, child_prefix, last);
        }
    }

    // Textbook-style layout: compute subtree widths and place parents centered over children
    public static void print_tree_pretty(ParseNode root) {
        int spacing = 10; // wider spacing for neat alignment and readability

        int total_width = measure_width(root, spacing);
        // guard
        if (total_width < label_len(root)) total_width = label_len(root);

        // Collect positioned nodes level-by-level using a private array accumulator
        pos_accum = {};
        assign_positions(root, 0, 0, spacing);

        int max_level = 0;
        foreach (var p in pos_accum) if (p.level > max_level) max_level = p.level;

        // Build lines
        for (int lvl = 0; lvl <= max_level; lvl++) {
            // label line
            char[] line = make_line(total_width);
            foreach (var p in pos_accum) {
                if (p.level != lvl) continue;
                int start = p.x - p.label.length / 2;
                if (start < 0) start = 0;
                if (start + p.label.length > total_width) continue;
                for (int i = 0; i < p.label.length; i++) line[start + i] = p.label[i];
            }
            stdout.printf("%s\n", to_string(line));

            // connector lines between lvl and lvl+1
            if (lvl == max_level) break;

            // 1) slanted/horizontal connectors
            char[] link = make_line(total_width);
            // 2) child vertical bars
            char[] bars = make_line(total_width);

            foreach (var parent in pos_accum) {
                if (parent.level != lvl) continue;
                // collect children
                Positioned[] kids = positioned_children(pos_accum, parent);
                if (kids.length == 0) continue;
                int px = parent.x;
                // put parent vertical
                if (px >= 0 && px < total_width) link[px] = '|';
                foreach (var ch in kids) {
                    int cx = ch.x;
                    if (cx == px) {
                        // straight down
                        bars[cx] = '|';
                    } else if (cx > px) {
                        // draw from px to cx
                        if (px + 1 < total_width) link[px + 1] = '/';
                        for (int x = px + 2; x < cx; x++) link[x] = '-';
                        bars[cx] = '|';
                    } else { // cx < px
                        if (px - 1 >= 0) link[px - 1] = '\\';
                        for (int x = cx + 1; x < px - 1; x++) link[x] = '-';
                        bars[cx] = '|';
                    }
                }
            }
            stdout.printf("%s\n", to_string(link));
            stdout.printf("%s\n", to_string(bars));
        }
    }

    private static string center(string s, int width) {
        if (s.length >= width) return s;
        int left = (width - s.length) / 2;
        int right = width - s.length - left;
        StringBuilder sb = new StringBuilder();
        sb.append(string.nfill(left, ' '));
        sb.append(s);
        sb.append(string.nfill(right, ' '));
        return sb.str;
    }

    // ---- Textbook layout helpers ----
    private class Positioned {
        public ParseNode node;
        public int x;
        public int level;
        public string label;
        public Positioned(ParseNode n, int x, int level) {
            this.node = n; this.x = x; this.level = level;
            // Display nonterminals in lowercase angle brackets (e.g., <movement>)
            string core = n.is_terminal ? n.symbol : "<" + n.symbol.down() + ">";
            this.label = core;
        }
    }

    private static int label_len(ParseNode n) {
        string core = n.is_terminal ? n.symbol : "<" + n.symbol.down() + ">";
        return (int) core.length;
    }

    private static int measure_width(ParseNode n, int spacing) {
        int lbl = label_len(n);
        if (n.children.length() == 0) return lbl;
        int sum = 0;
        int idx = 0;
        foreach (var c in n.children) {
            int w = measure_width(c, spacing);
            sum += w;
            if (idx < (int) n.children.length() - 1) sum += spacing;
            idx++;
        }
        return (sum > lbl) ? sum : lbl;
    }

    private static int assign_positions(ParseNode n, int start_x, int level, int spacing) {
        // returns total width consumed starting at start_x
        int my_width = measure_width(n, spacing);
        if (n.children.length() == 0) {
            int center_x = start_x + my_width / 2;
            push_position(new Positioned(n, center_x, level));
            return my_width;
        }
        // place children left-to-right
        int cursor = start_x;
        int first_cx = -1;
        int last_cx = -1;
        foreach (var c in n.children) {
            int w = measure_width(c, spacing);
            int child_center = cursor + w / 2;
            // recurse (child subtree starts at cursor)
            int consumed = assign_positions(c, cursor, level + 1, spacing);
            child_center = cursor + consumed / 2;
            if (first_cx == -1) first_cx = child_center;
            last_cx = child_center;
            cursor += consumed + spacing;
        }
        if (last_cx == -1) last_cx = start_x + my_width / 2;
        int parent_x = (first_cx + last_cx) / 2;
        push_position(new Positioned(n, parent_x, level));
        return my_width;
    }

    private static char[] make_line(int width) {
        char[] line = new char[width];
        for (int i = 0; i < width; i++) line[i] = ' ';
        return line;
    }

    // Convert char array to Vala string
    private static string to_string(char[] arr) {
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < arr.length; i++) sb.append_c(arr[i]);
        return sb.str;
    }

    // Find positioned children of a parent by matching original parse tree children
    private static Positioned[] positioned_children(Positioned[] all, Positioned parent) {
        Positioned[] result = {};
        foreach (var child_node in parent.node.children) {
            foreach (var p in all) {
                if (p.level == parent.level + 1 && p.node == child_node) {
                    // append to result array
                    Positioned[] tmp = new Positioned[result.length + 1];
                    for (int i = 0; i < result.length; i++) tmp[i] = result[i];
                    tmp[result.length] = p;
                    result = tmp;
                    break;
                }
            }
        }
        return result;
    }

    // Private accumulator for positions and a push helper
    private static Positioned[] pos_accum = {};
    private static void push_position(Positioned p) {
        Positioned[] tmp = new Positioned[pos_accum.length + 1];
        for (int i = 0; i < pos_accum.length; i++) tmp[i] = pos_accum[i];
        tmp[pos_accum.length] = p;
        pos_accum = tmp;
    }
}
