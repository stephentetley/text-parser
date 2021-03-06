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


namespace FlixParsec/Combinators {

    use FlixParsec.{GenParser};
    use FlixParsec/Prim.{return, flatMap, fail, map, ap, bind, ifThenElse, lookahead};

    /// Alias for `seqRight`
    pub def *>(p1: GenParser[ka1, st, a], p2: GenParser[ka1, st, b]): GenParser[ka1, st, b] = 
        seqRight(p1, p2)

    /// Alias for `seqLeft`
    pub def <*(p1: GenParser[ka1, st, a], p2: GenParser[ka1, st, b]): GenParser[ka1, st, a] = 
        seqLeft(p1, p2)

    pub def <!>(p1: GenParser[ka1, st, a], p2: GenParser[ka1, st, a]): GenParser[ka1, st, a] =
        alt(p1, p2)

    // Haskell's <$>
    pub def <&>(f: a -> b, p2: GenParser[ka1, st, a]): GenParser[ka1, st, b] =
        map(f, p2)

    pub def <&(x: b, p1: GenParser[ka1, st, a]): GenParser[ka1, st, b] =
        p1 *> return(x)

    pub def &>(p1: GenParser[ka1, st, a], x: b): GenParser[ka1, st, b] =
        p1 *> return(x)

    /// Flipped <&>
    pub def <&&>(p2: GenParser[ka1, st, a], f: a -> b): GenParser[ka1, st, b] =
        map(f, p2)


    // Haskell's ap <*>
    pub def <*>(mf: GenParser[ka1, st, a -> b], p2: GenParser[ka1, st, a]): GenParser[ka1, st, b] =
        ap(mf, p2)

    /// Flipped <*>
    pub def <**>(p2: GenParser[ka1, st, a], mf: GenParser[ka1, st, a -> b]): GenParser[ka1, st, b] =
        ap(mf, p2)        


    pub def >>=(p: GenParser[ka1, st, a], k: a -> GenParser[ka1, st, b]): GenParser[ka1, st, b] =
        bind(p, k)


    pub def =<<(k: a -> GenParser[ka1, st, b], p: GenParser[ka1, st, a]): GenParser[ka1, st, b] =
        bind(p, k)

    pub def >=>(f1: a -> GenParser[ka1, st, b], f2: b -> GenParser[ka1, st, c], x: a): GenParser[ka1, st, c] =
        kleisliLeft(f1, f2, x)

    pub def <=<(f1: b -> GenParser[ka1, st, c], f2: a -> GenParser[ka1, st, b], x: a): GenParser[ka1, st, c] = 
        kleisliRight(f1, f2, x)

    /// `alt` rolls back the parser state (including the position) if `p` fails.
    pub def alt(p: GenParser[ka1, st, a], q: GenParser[ka1, st, a]): GenParser[ka1, st, a] =
        ifThenElse(p, return, q)

    pub def seqLeft(p: GenParser[ka1, st, a], q: GenParser[ka1, st, b]): GenParser[ka1, st, a] =
        let* a = p;
        let* _ = q;
        return(a)

    pub def seqRight(p: GenParser[ka1, st, a], q: GenParser[ka1, st, b]): GenParser[ka1, st, b] =
        let* _ = p;
        let* b = q;
        return(b)


    pub def kleisliLeft(f1: a -> GenParser[ka1, st, b], f2: b -> GenParser[ka1, st, c], x: a): GenParser[ka1, st, c] =
        let* b  = f1(x);
        let* c  = f2(b);
        return(c)

    pub def kleisliRight(f1: b -> GenParser[ka1, st, c], f2: a -> GenParser[ka1, st, b], x: a): GenParser[ka1, st, c] =
        kleisliLeft(f2, f1, x)


    pub def notFollowedBy(p: GenParser[ka1, st, a]): GenParser[ka1, st, Unit] =
        ifThenElse(p, _ -> fail("notFollowedBy"), return()) 
        



    pub def choice(ps: List[GenParser[ka1, st, a]]): GenParser[ka1, st, a] =
        match ps {
            case p1 :: rs => ifThenElse(p1, return, choice(rs))
            case Nil => fail("choice")
        }

    pub def optional(p: GenParser[ka1, st, a]): GenParser[ka1, st, Option[a]] = 
        alt(map(Some,p), return(None))

    pub def optionalWithDefault(p: GenParser[ka1, st, a], d: a): GenParser[ka1, st, a] = 
        alt(p, return(d))



    pub def ignore(p: GenParser[ka1, st, a]): GenParser[ka1, st, Unit] =
        map(constant(), p)


    pub def between(openp: GenParser[ka1, st, open], closep: GenParser[ka1, st, close], p: GenParser[ka1, st, a]): GenParser[ka1, st, a] = 
        let* _ = openp;
        let* a = p;
        let* _ = closep;
        return(a)

    pub def satisfies(p: GenParser[ka1, st, a], test: a -> Bool): GenParser[ka1, st, a] = 
        let* a = p;
        if (test(a))
            return(a)
        else
            fail("satisfies")
            
    /// `p` is run with `lookahead`, no text is consumed
    pub def succeeds(p: GenParser[ka1, st, a]): GenParser[ka1, st, Bool] = 
        alt(seqRight(lookahead(p), return(true)), return(false))


    pub def countWith(combine: (ac, a) -> ac, acc: ac, n: Int32, p: GenParser[ka1, st, a]): GenParser[ka1, st, ac] = 
        if (n <= 0)
            return(acc)
        else {
            let* a = p;
            countWith(combine, combine(acc, a), n-1, p)
        }

    pub def count(n: Int32, p: GenParser[ka1, st, a]): GenParser[ka1, st, List[a]] = 
        use Chain.{empty, snoc, toList};
        countWith(snoc, empty(), n, p) |> map(toList)
    


    pub def manyWith(combine: (ac, a) -> ac, acc: ac, p: GenParser[ka1, st, a]): GenParser[ka1, st, ac] = 
        ifThenElse(p, a -> manyWith(combine, combine(acc, a), p), return(acc))


    pub def many(p: GenParser[ka1, st, a]): GenParser[ka1, st, List[a]] = 
        use Chain.{empty, snoc, toList};
        manyWith(snoc, empty(), p) |> map(toList)
        
    pub def many1With(combine: (ac, a) -> ac, acc: ac, p: GenParser[ka1, st, a]): GenParser[ka1, st, ac] = 
        bind(p, x -> manyWith(combine, combine(acc, x), p))
        
    pub def many1(p: GenParser[ka1, st, a]): GenParser[ka1, st, List[a]] = 
        use Chain.{empty, snoc, toList};
        many1With(snoc, empty(), p) |> map(toList)


    /// Count how many times parser `p` succeeds
    pub def ntimes(p: GenParser[ka1, st, a]): GenParser[ka1, st, Int32] = 
        manyWith((ac, _) -> ac + 1, 0, p)


    pub def manyTillWith(combine: (ac, a) -> ac, 
                            acc: ac, 
                            p: GenParser[ka1, st, a], 
                            endp: GenParser[ka1, st, end]): GenParser[ka1, st, ac] = 
        ifThenElse(endp, _ -> return(acc), bind(p, a -> manyTillWith(combine, combine(acc, a), p, endp)))

    pub def manyTill(p: GenParser[ka1, st, a], endp: GenParser[ka1, st, end]): GenParser[ka1, st, List[a]] = 
        use Chain.{empty, snoc, toList};
        manyTillWith(snoc, empty(), p, endp) |> map(toList)
        
    pub def many1TillWith(combine: (ac, a) -> ac, 
                            acc: ac, 
                            p: GenParser[ka1, st, a], 
                            endp: GenParser[ka1, st, end]): GenParser[ka1, st, ac] = 
        bind(p, x -> manyTillWith(combine, combine(acc, x), p, endp))
        
    pub def many1Till(p: GenParser[ka1, st, a], endp: GenParser[ka1, st, end]): GenParser[ka1, st, List[a]] = 
        use Chain.{empty, snoc, toList};
        many1TillWith(snoc, empty(), p, endp) |> map(toList)
    

    pub def sepByWith(combine: (ac, a) -> ac, 
                        acc: ac, 
                        p: GenParser[ka1, st, a], 
                        sep: GenParser[ka1, st, sep]): GenParser[ka1, st, ac] = 
        ifThenElse(p, x -> sepByWithHelper(combine, combine(acc, x), p, sep), return(acc))
    
    // Initial p has been consumed
    def sepByWithHelper(combine: (ac, a) -> ac, 
                        acc: ac, 
                        p: GenParser[ka1, st, a], 
                        sep: GenParser[ka1, st, sep]): GenParser[ka1, st, ac] = 
        ifThenElse(seqRight(sep, p), x -> sepByWithHelper(combine, combine(acc, x), p, sep), return(acc))

    pub def sepBy(p: GenParser[ka1, st, a], sep: GenParser[ka1, st, sep]): GenParser[ka1, st, List[a]] = 
        use Chain.{empty, snoc, toList};
        sepByWith(snoc, empty(), p, sep) |> map(toList)

    pub def sepBy1With(combine: (ac, a) -> ac, 
                        acc: ac, 
                        p: GenParser[ka1, st, a], 
                        sep: GenParser[ka1, st, sep]): GenParser[ka1, st, ac] = 
        bind(p, x -> sepByWithHelper(combine, combine(acc, x), p, sep))
    
    pub def sepBy1(p: GenParser[ka1, st, a], sep: GenParser[ka1, st, sep]): GenParser[ka1, st, List[a]] = 
        use Chain.{empty, snoc, toList};
        sepBy1With(snoc, empty(), p, sep) |> map(toList)

    pub def endByWith(combine: (ac, a) -> ac, 
                        acc: ac, 
                        p: GenParser[ka1, st, a], 
                        sep: GenParser[ka1, st, sep]): GenParser[ka1, st, ac] = 
        manyWith(combine, acc, seqLeft(p, sep))

    pub def endBy(p: GenParser[ka1, st, a], sep: GenParser[ka1, st, sep]): GenParser[ka1, st, List[a]] = 
        use Chain.{empty, snoc, toList};
        endByWith(snoc, empty(), p, sep) |> map(toList)

    pub def endBy1With(combine: (ac, a) -> ac, 
                        acc: ac, 
                        p: GenParser[ka1, st, a], 
                        sep: GenParser[ka1, st, sep]): GenParser[ka1, st, ac] = 
        bind(seqLeft(p, sep), x -> endByWith(combine, combine(acc, x), p, sep))

    pub def endBy1(p: GenParser[ka1, st, a], sep: GenParser[ka1, st, sep]): GenParser[ka1, st, List[a]] = 
        use Chain.{empty, snoc, toList};
        endBy1With(snoc, empty(), p, sep) |> map(toList)

    // seperated and optionally terminated with sep.
    pub def sepEndByWith(combine: (ac, a) -> ac, 
                            acc: ac, 
                            p: GenParser[ka1, st, a], 
                            sep: GenParser[ka1, st, sep]): GenParser[ka1, st, ac] = 
        let* xs = sepByWith(combine, acc, p, sep);
        ifThenElse(sep, _ -> return(xs), return(xs))

    // seperated and optionally terminated with sep.
    pub def sepEndBy(p: GenParser[ka1, st, a], sep: GenParser[ka1, st, sep]): GenParser[ka1, st, List[a]] = 
        use Chain.{empty, snoc, toList};
        map(toList, sepEndByWith(snoc, empty(), p, sep))

    // seperated and optionally terminated with sep.
    pub def sepEndBy1With(combine: (ac, a) -> ac, 
                            acc: ac, 
                            p: GenParser[ka1, st, a], 
                            sep: GenParser[ka1, st, sep]): GenParser[ka1, st, ac] = 
        let* xs = sepBy1With(combine, acc, p, sep);
        ifThenElse(sep, _ -> return(xs), return(xs))

    // seperated and optionally terminated with sep.
    pub def sepEndBy1(p: GenParser[ka1, st, a], sep: GenParser[ka1, st, sep]): GenParser[ka1, st, List[a]] = 
        use Chain.{empty, snoc, toList};
        sepEndBy1With(snoc, empty(), p, sep) |> map(toList)

    /// Count how many times parser `p` succeeds
    pub def ntimesSepBy(p: GenParser[ka1, st, a], sep: GenParser[ka1, st, sep]): GenParser[ka1, st, Int32] = 
        sepByWith((ac, _) -> ac + 1, 0, p, sep)

    /// Count how many times parser `p` succeeds
    pub def ntimesEndBy(p: GenParser[ka1, st, a], sep: GenParser[ka1, st, sep]): GenParser[ka1, st, Int32] = 
        endByWith((ac, _) -> ac + 1, 0, p, sep)

    /// Count how many times parser `p` succeeds
    pub def ntimesSepEndBy(p: GenParser[ka1, st, a], sep: GenParser[ka1, st, sep]): GenParser[ka1, st, Int32] = 
        sepEndByWith((ac, _) -> ac + 1, 0, p, sep)

    /// p1 must succeed, p2 parsers zero-or-more
    pub def manyTill2With(combine: (ac, a) -> ac, 
                            acc: ac, 
                            p1: GenParser[ka1, st, a], 
                            p2: GenParser[ka1, st, a], 
                            endp: GenParser[ka1, st, end]): GenParser[ka1, st, ac] = 
        bind(p1, x -> manyTillWith(combine, combine(acc, x), p2, endp))
        
    /// p1 must succeed, p2 parsers zero-or-more
    pub def manyTill2(p1: GenParser[ka1, st, a], 
                      p2: GenParser[ka1, st, a], 
                      endp: GenParser[ka1, st, end]): GenParser[ka1, st, List[a]] = 
        use Chain.{empty, snoc, toList};
        manyTill2With(snoc, empty(), p1, p2, endp) |> map(toList)

    /// p1 must succeed, p2 parsers one-or-more
    pub def many1Till2With(combine: (ac, a) -> ac, acc: ac, 
                            p1: GenParser[ka1, st, a], 
                            p2: GenParser[ka1, st, a], 
                            endp: GenParser[ka1, st, end]): GenParser[ka1, st, ac] = 
        bind(p1, x -> many1TillWith(combine, combine(acc, x), p2, endp))
        
    /// p1 must succeed, p2 parsers one-or-more
    pub def many1Till2(p1: GenParser[ka1, st, a], 
                        p2: GenParser[ka1, st, a], 
                        endp: GenParser[ka1, st, end]): GenParser[ka1, st, List[a]] = 
        use Chain.{empty, snoc, toList};
        many1Till2With(snoc, empty(), p1, p2, endp) |> map(toList)



    pub def skipMany(p: GenParser[ka1, st, a]): GenParser[ka1, st, Unit] = 
        ifThenElse(p, _ -> skipMany(p), return())

    pub def skipMany1(p: GenParser[ka1, st, a]): GenParser[ka1, st, Unit] = 
        bind(p, _ -> skipMany(p))


    pub def skipManyTill(p: GenParser[ka1, st, a], endp: GenParser[ka1, st, end]): GenParser[ka1, st, Unit] = 
        ifThenElse(endp, _ -> return(), bind(p, _ -> skipManyTill(p, endp)))

    pub def skipMany1Till(p: GenParser[ka1, st, a], endp: GenParser[ka1, st, end]): GenParser[ka1, st, Unit] = 
        bind(p, _ -> skipManyTill(p, endp))


    pub def chainl1(p: GenParser[ka1, st, a], op: GenParser[ka1, st, (a, a) -> a]): GenParser[ka1, st, a] = 
        bind(p, v1 -> chainl1Helper(p, op, v1))
        
    def chainl1Helper(p: GenParser[ka1, st, a], op: GenParser[ka1, st, (a, a) -> a], x: a): GenParser[ka1, st, a] = 
        alt(bind(op, f -> bind(p, v1 -> chainl1Helper(p, op, f(x, v1)))), 
            return(x))

    pub def chainl(p: GenParser[ka1, st, a], op: GenParser[ka1, st, (a, a) -> a], x: a): GenParser[ka1, st, a] = 
        alt(chainl1(p,op), return(x))


    def chainr1Helper(p: GenParser[ka1, st, a], op: GenParser[ka1, st, (a, a) -> a], x: a): GenParser[ka1, st, a] = 
        alt(chainr1Step(p, op, x), return(x))

    def chainr1Step(p: GenParser[ka1, st, a], op: GenParser[ka1, st, (a, a) -> a], x: a): GenParser[ka1, st, a] = 
        bind(op, f -> 
            bind(bind(p, v1 -> chainr1Helper(p, op, v1)), y -> 
                bind(chainr1Helper(p,op, f(x,y)), ans -> return(ans))))

    pub def chainr1(p: GenParser[ka1, st, a], op: GenParser[ka1, st, (a, a) -> a]): GenParser[ka1, st, a] = 
        bind(p, v1 -> chainr1Helper(p, op, v1))

    pub def chainr(p: GenParser[ka1, st, a], op: GenParser[ka1, st, (a, a) -> a], x: a): GenParser[ka1, st, a] = 
        alt(chainr1(p, op), return(x))

    pub def tuple2(p1: GenParser[ka1, st, a], p2: GenParser[ka1, st, b]): GenParser[ka1, st, (a, b)] =
        let* a = p1; 
        let* b = p2;
        return((a, b))

    pub def tuple3(p1: GenParser[ka1, st, a], 
                    p2: GenParser[ka1, st, b], 
                    p3: GenParser[ka1, st, c]): GenParser[ka1, st, (a, b, c)] =
        let* a = p1; 
        let* b = p2;
        let* c = p3;
        return((a, b, c))

    pub def tuple4(p1: GenParser[ka1, st, a], 
                    p2: GenParser[ka1, st, b], 
                    p3: GenParser[ka1, st, c], 
                    p4: GenParser[ka1, st, d]): GenParser[ka1, st, (a, b, c, d)] =
        let* a = p1; 
        let* b = p2;
        let* c = p3;
        let* d = p4;
        return((a, b, c, d))


    pub def tuple5(p1: GenParser[ka1, st, a], 
                    p2: GenParser[ka1, st, b], 
                    p3: GenParser[ka1, st, c], 
                    p4: GenParser[ka1, st, d], 
                    p5: GenParser[ka1, st, e]): GenParser[ka1, st, (a, b, c, d, e)] =
        let* a = p1; 
        let* b = p2;
        let* c = p3;
        let* d = p4;
        let* e = p5;
        return((a, b, c, d, e))

    pub def tuple6(p1: GenParser[ka1, st, a], 
                    p2: GenParser[ka1, st, b], 
                    p3: GenParser[ka1, st, c], 
                    p4: GenParser[ka1, st, d], 
                    p5: GenParser[ka1, st, e], 
                    p6: GenParser[ka1, st, f]): 
                    GenParser[ka1, st, (a, b, c, d, e, f)] =
        let* a = p1; 
        let* b = p2;
        let* c = p3;
        let* d = p4;
        let* e = p5;
        let* f = p6;
        return((a, b, c, d, e, f))

    pub def tuple7(p1: GenParser[ka1, st, a], 
                    p2: GenParser[ka1, st, b], 
                    p3: GenParser[ka1, st, c], 
                    p4: GenParser[ka1, st, d], 
                    p5: GenParser[ka1, st, e], 
                    p6: GenParser[ka1, st, f], 
                    p7: GenParser[ka1, st, g]): GenParser[ka1, st, (a, b, c, d, e, f, g)] =
        let* a = p1; 
        let* b = p2;
        let* c = p3;
        let* d = p4;
        let* e = p5;
        let* f = p6;
        let* g = p7;
        return((a, b, c, d, e, f, g))

    pub def tuple8(p1: GenParser[ka1, st, a], 
                    p2: GenParser[ka1, st, b], 
                    p3: GenParser[ka1, st, c], 
                    p4: GenParser[ka1, st, d], 
                    p5: GenParser[ka1, st, e], 
                    p6: GenParser[ka1, st, f], 
                    p7: GenParser[ka1, st, g], 
                    p8: GenParser[ka1, st, h]): GenParser[ka1, st, (a, b, c, d, e, f, g, h)] =
        let* a = p1; 
        let* b = p2;
        let* c = p3;
        let* d = p4;
        let* e = p5;
        let* f = p6;
        let* g = p7;
        let* h = p8;
        return((a, b, c, d, e, f, g, h))

    pub def tuple9(p1: GenParser[ka1, st, a], 
                    p2: GenParser[ka1, st, b], 
                    p3: GenParser[ka1, st, c], 
                    p4: GenParser[ka1, st, d], 
                    p5: GenParser[ka1, st, e], 
                    p6: GenParser[ka1, st, f], 
                    p7: GenParser[ka1, st, g], 
                    p8: GenParser[ka1, st, h], 
                    p9: GenParser[ka1, st, i]): GenParser[ka1, st, (a, b, c, d, e, f, g, h, i)] =
        let* a = p1; 
        let* b = p2;
        let* c = p3;
        let* d = p4;
        let* e = p5;
        let* f = p6;
        let* g = p7;
        let* h = p8;
        let* i = p9;
        return((a, b, c, d, e, f, g, h, i))

    pub def tuple10(p1: GenParser[ka1, st, a], 
                    p2: GenParser[ka1, st, b], 
                    p3: GenParser[ka1, st, c], 
                    p4: GenParser[ka1, st, d], 
                    p5: GenParser[ka1, st, e], 
                    p6: GenParser[ka1, st, f], 
                    p7: GenParser[ka1, st, g], 
                    p8: GenParser[ka1, st, h], 
                    p9: GenParser[ka1, st, i], 
                    p10: GenParser[ka1, st, j]): GenParser[ka1, st, (a, b, c, d, e, f, g, h, i, j)] =
        let* a = p1; 
        let* b = p2;
        let* c = p3;
        let* d = p4;
        let* e = p5;
        let* f = p6;
        let* g = p7;
        let* h = p8;
        let* i = p9;
        let* j = p10;
        return((a, b, c, d, e, f, g, h, i, j))

}
