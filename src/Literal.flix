/*
 * Copyright 2020 Stephen Tetley
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */


namespace FlixParsec/Literal {

    use FlixParsec.{GenParser};
    use FlixParsec/Prim.{return, flatMap, map, swapError, liftResult};
    use FlixParsec/Combinators.{alt, choice, between, manyWith};
    use FlixParsec/Combinators.{*>};
    use FlixParsec/Char.{char, string, satisfy};
    use FlixParsec/Regex.{lookingAts};

    pub def stringLiteral(): GenParser[ka1, st, String] = 
        let step = (ac, x) -> match x { 
            case Some(c) => "${ac}${c}"
            case None => ac
        };
        between( char('\u0022'),  char('\u0022'), manyWith(step, "", stringChar())) 



    def stringChar(): GenParser[ka1, st, Option[Char]] = 
        alt(stringLetter() |> map(Some), stringEscape())

    /// Greater than "SUB"...
    def stringLetter(): GenParser[ka1, st, Char] = 
        satisfy(c -> (c != '\u0022') and (c != '\\') and (c > '\u001A'))

    def stringEscape(): GenParser[ka1, st, Option[Char]] =
        char('\\') *> (escapeCode() |> map(Some))

    pub def charLiteral(): GenParser[ka1, st, Char] = 
        between( char('\''),  char('\''), chararacterChar())

    def chararacterChar(): GenParser[ka1, st, Char] = alt(charLetter(), charEscape())

    def charEscape(): GenParser[ka1, st, Char] =
        char('\\') *> escapeCode()

    /// Greater than "SUB"...
    def charLetter(): GenParser[ka1, st, Char] = 
        satisfy(c -> (c != '\'') and (c != '\\') and (c > '\u001A'))

    def escapeCode(): GenParser[ka1, st, Char] = 
        choice(
            charUnicode() :: charEsc() :: Nil
        )
        /// charEsc <|> charNum <|> charAscii <|> charControl

    def charUnicode(): GenParser[ka1, st, Char] = 
        let* _      = alt(char('u'), char('U'));
        let* num    = hexNumber() |> map(Char.fromInt32);
        return(num) 


    def hexNumber(): GenParser[ka1, st, Int32] =  
        use FlixParsec/Combinators.{countWith};
        use FlixParsec/Char.{hexDigit};
        let step = (ac, ch) -> match asciiDigitToInt32(ch) {
            case Some(i) => ac * 16 + i
            case None => ac * 16
        };
        countWith(step, 0, 4, hexDigit())
        

    def charEsc(): GenParser[ka1, st, Char] = 
        choice(
                (char('t')  *> return('\u0009'))    /// tab
            :: (char('r')   *> return('\u000D'))    /// carriage return
            :: (char('n')   *> return('\u000A'))    /// line feed
            :: Nil
        )    

    def asciiDigitToInt32(c: Char): Option[Int32] = 
        match Char.toInt32(c) {
            case i if i >= 0x0030 and i <= 0x0039 => Some(i - 0x0030)        // '0'..'9'
            case i if i >= 0x0041 and i <= 0x0046 => Some(i - 0x0041)        // 'A'..'F'
            case i if i >= 0x0061 and i <= 0x0066 => Some(i - 0x0061)        // 'a'..'f'
            case _ => None
        }


    pub def int8(): GenParser[ka1, st, Int8] = 
        let* a = lookingAts("-?\d+");
        liftResult(Int8.fromString(a), constant("int8"))
        
    pub def int16(): GenParser[ka1, st, Int16] = 
        let* s = lookingAts("-?\d+");
        liftResult(Int16.fromString(s), constant("int16"))
    
    pub def int32(): GenParser[ka1, st, Int32] = 
        let* s = lookingAts("-?\d+");
        liftResult(Int32.fromString(s), constant("int32"))

    pub def int64(): GenParser[ka1, st, Int64] = 
        let* s = lookingAts("-?\d+");
        liftResult(Int64.fromString(s), constant("int64"))


    pub def bigInt(): GenParser[ka1, st, BigInt] = 
        let* s = lookingAts("-?\d+");
        liftResult(BigInt.fromString(s), constant("bigInt"))

    /// TODO - handle exponent notation...
    pub def float32(): GenParser[ka1, st, Float32] = 
        let* s = lookingAts("-?\d+\.\d+");
        liftResult(Float32.fromString(s), constant("float32"))

    /// TODO - handle exponent notation...
    pub def float64(): GenParser[ka1, st, Float64] = 
        let* s = lookingAts("-?\d+\.\d+");
        liftResult(Float64.fromString(s), constant("float64"))
        
    pub def hexInt32(): GenParser[ka1, st, Int32] = 
        alt(string("0X"), string("0x")) *> hexInt32Base()
        
    pub def hexInt32Base(): GenParser[ka1, st, Int32] =  
        use FlixParsec/Combinators.{many1With};
        use FlixParsec/Char.{hexDigit};
        let step = (ac, ch) -> match asciiDigitToInt32(ch) {
            case Some(i) => ac * 16 + i
            case None => ac * 16
        };
        many1With(step, 0, hexDigit())

    pub def octInt32(): GenParser[ka1, st, Int32] = 
        alt(string("0o"), string("0O")) *> octInt32Base()
        
    pub def octInt32Base(): GenParser[ka1, st, Int32] =  
        use FlixParsec/Combinators.{many1With};
        use FlixParsec/Char.{octDigit};
        let step = (ac, ch) -> match asciiDigitToInt32(ch) {
            case Some(i) => ac * 8 + i
            case None => ac * 8
        };
        many1With(step, 0, octDigit())        

}
