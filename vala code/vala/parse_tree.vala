using GLib;

// Parse tree node
class ParseNode {
    public string symbol;
    public List<ParseNode> children;
    public bool is_terminal;

    public ParseNode(string symbol, bool is_terminal = false) {
        this.symbol = symbol;
        this.is_terminal = is_terminal;
        this.children = new List<ParseNode>();
    }

    public void add_child(ParseNode child) {
        children.append(child);
    }
}
