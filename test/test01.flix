
def main(_args: Array[String]) : Int32 & Impure = 
    test01();
    test02();
    test03();
    test04();
    test05();
    0

def test01(): Unit & Impure =     
    let parser = FlixParsec/Combinators.many(FlixParsec/Char.anyChar());
    FlixParsec/Prim.parsesString(parser, "ABC") |> println;
    ()

def test02(): Unit & Impure =     
    let parser = FlixParsec/Literal.charLiteral();
    FlixParsec/Prim.parsesString(parser, "'+'") |> println;
    FlixParsec/Prim.parsesString(parser, "'\u00B1'") |> println;        /// Plus_minus
    FlixParsec/Prim.parsesString(parser, "'\u0041'") |> println;        /// upper A
    FlixParsec/Prim.parsesString(parser, "'\u00CA'") |> println;        /// upper E^ circumflex
    FlixParsec/Prim.parsesString(parser, "'\u0077'") |> println;        /// lower w
    FlixParsec/Prim.parsesString(parser, "'\t'") |> println;            /// tab
    ()

def test03(): Unit & Impure =     
    let dquote = '\u0022';
    let parser = FlixParsec/Literal.stringLiteral();
    FlixParsec/Prim.parsesString(parser, "${dquote}abc${dquote}") |> println;
    ()

/// Do we need "try"...
def test04(): Unit & Impure =
    use FlixParsec/Prim.{flatMap, return};
    use FlixParsec/Combinators.{alt};
    use FlixParsec/Char.{char};
    let p1 = { let* _ = char('a'); let* _ = char('b'); let* _ = char('a'); return("aba")};
    let p2 = { let* _ = char('a'); let* _ = char('b'); let* _ = char('c'); return("abc")};
    let parser = alt(p1, p2);
    FlixParsec/Prim.parsesString(parser, "abc") |> println;
    ()

def test05(): Unit & Impure =     
    let langDef = FlixParsec/Language.emptyDef();
    let parens = FlixParsec/Token.parens(langDef);
    let symbol = FlixParsec/Token.symbol(langDef);
    let parser = parens(symbol("Hello"));
    FlixParsec/Prim.parsesString(parser, "(Hello)") |> println;
    ()
