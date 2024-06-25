module {
    public let openaiUrlBase = "https://api.openai.com/";
    public let openaiRequestHeaders = [ // Same-named headers are not supported.
        {name = "Content-Type"; value = "application/json"},
        {name = "Authorization"; value = "Bearer XXX"},
    ];
}