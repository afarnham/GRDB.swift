/// An FTS3 tokenizer, suitable for FTS3 and FTS4 table definitions:
///
///     db.create(virtualTable: "books", using: FTS4()) { t in
///         t.tokenizer = FTS3TokenizerRequest.simple
///     }
///
/// See https://www.sqlite.org/fts3.html#tokenizer
public struct FTS3TokenizerRequest {
    let name: String
    let arguments: [String]
    
    /// Creates an FTS3 tokenizer.
    ///
    /// Unless you use a custom tokenizer, you don't need this constructor:
    ///
    /// Use FTS3TokenizerRequest.simple, FTS3TokenizerRequest.porter, or
    /// FTS3TokenizerRequest.unicode61() instead.
    public init(_ name: String, arguments: [String] = []) {
        self.name = name
        self.arguments = arguments
    }
    
    /// The "simple" tokenizer.
    ///
    ///     db.create(virtualTable: "books", using: FTS4()) { t in
    ///         t.tokenizer = .simple
    ///     }
    ///
    /// See https://www.sqlite.org/fts3.html#tokenizer
    public static let simple = FTS3TokenizerRequest("simple")
    
    /// The "porter" tokenizer.
    ///
    ///     db.create(virtualTable: "books", using: FTS4()) { t in
    ///         t.tokenizer = .porter
    ///     }
    ///
    /// See https://www.sqlite.org/fts3.html#tokenizer
    public static let porter = FTS3TokenizerRequest("porter")
    
    /// The "unicode61" tokenizer.
    ///
    ///     db.create(virtualTable: "books", using: FTS4()) { t in
    ///         t.tokenizer = .unicode61()
    ///     }
    ///
    /// - parameters:
    ///     - removeDiacritics: If true (the default), then SQLite will strip
    ///       diacritics from latin characters.
    ///     - separators: Unless empty (the default), SQLite will consider these
    ///       characters as token separators.
    ///     - tokenCharacters: Unless empty (the default), SQLite will consider
    ///       these characters as token characters.
    ///
    /// See https://www.sqlite.org/fts3.html#tokenizer
    public static func unicode61(removeDiacritics: Bool = true, separators: Set<Character> = [], tokenCharacters: Set<Character> = []) -> FTS3TokenizerRequest {
        var arguments: [String] = []
        if !removeDiacritics {
            arguments.append("remove_diacritics=0")
        }
        if !separators.isEmpty {
            // TODO: test "=" and "\"", "(" and ")" as separators, with both FTS3Pattern(matchingAnyTokenIn:tokenizer:) and Database.create(virtualTable:using:)
            arguments.append("separators=" + separators.sorted().map { String($0) }.joined(separator: ""))
        }
        if !tokenCharacters.isEmpty {
            // TODO: test "=" and "\"", "(" and ")" as tokenCharacters, with both FTS3Pattern(matchingAnyTokenIn:tokenizer:) and Database.create(virtualTable:using:)
            arguments.append("tokenchars=" + tokenCharacters.sorted().map { String($0) }.joined(separator: ""))
        }
        return FTS3TokenizerRequest("unicode61", arguments: arguments)
    }
}

extension Database {
    
    /// Returns an array of tokens found in the string argument.
    ///
    ///     try db.tokenize(string: "foo bar", with: .simple) // ["foo", "bar"]
    public func tokenize(string: String, with tokenizer: FTS3TokenizerRequest) throws -> [String] {
        var tokenizerChunks: [String] = []
        tokenizerChunks.append(tokenizer.name)
        for option in tokenizer.arguments {
            tokenizerChunks.append("\"\(option)\"")
        }
        let tokenizerSQL = tokenizerChunks.joined(separator: ", ")
        try execute("CREATE VIRTUAL TABLE __fts3tokens USING fts3tokenize(\(tokenizerSQL))")
        let strings = String.fetchAll(self, "SELECT token FROM __fts3tokens WHERE input = ? ORDER BY position", arguments: [string])
        try execute("DROP TABLE __fts3tokens")
        return strings
    }
}