app [main] {
    pf: platform "https://github.com/roc-lang/basic-cli/releases/download/0.17.0/lZFLstMUCUvd5bjnnpYromZJXkQUrdhbva4xdBInicE.tar.br",
    parser: "https://github.com/lukewilliamboswell/roc-parser/releases/download/0.9.0/w8YKp2YAgQt5REYk912HfKAHBjcXsrnvtjI0CBzoAT4.tar.br",
}

import pf.File
import pf.Stdout as Stdout
import pf.Utc

import parser.Parser as P exposing [Parser]
import parser.String as PS

import Common {
    now: Utc.now,
    toMillisSinceEpoch: Utc.toMillisSinceEpoch,
    line: Stdout.line,
    readUtf8: File.readUtf8,
}

main =
    Common.run! {
        inputFiles: [
            "src/day3Inputs/sample.txt",
            "src/day3Inputs/input.txt",
        ],
        solve1: solve1,
        solve2: solve2,
    }

# Algo - Part 1

Mul : [Mul U64 U64]

solve1 : Str -> Result U64 [ParsingFailure Str]
solve1 = \raw ->
    muls =
        parseInput1 raw
        |> try
    product = List.walk muls 0 \state, Mul a b -> (a * b) + state
    Ok product

parseInput1 : Str -> Result (List Mul) [ParsingFailure Str]
parseInput1 = \str ->
    when PS.parseStrPartial parseMuls (Str.trim str) is
        Err e -> Err e
        Ok a -> Ok a.val

parseMuls :
    Parser
        (List U8)
        (List Mul)
parseMuls =
    P.const (\x -> x)
    |> P.skip (P.chompUntil 'm')
    |> P.keep
        (
            P.oneOf [
                P.map parseMul (\mul -> Ok mul),
                P.map (PS.string "m") (\_ -> Err {}),
            ]
        )
    |> P.many
    |> P.map (\mulResults -> List.keepOks mulResults (\x -> x))

parseMul : Parser (List U8) Mul
parseMul =
    P.const (\numA -> \numB -> Mul numA numB)
    |> P.skip (PS.string "mul(")
    |> P.keep PS.digits
    |> P.skip (PS.string ",")
    |> P.keep PS.digits
    |> P.skip (PS.string ")")

# Algo - Part 2

solve2 : Str -> Result U64 [ParsingFailure Str]
solve2 = \str ->
    mulsAndDoDonts = try PS.parseStrPartial parseMulsOrDoDont (Str.trim str)
    (product, _) = List.walk mulsAndDoDonts.val (0, Do) \(productSoFar, doDont), step ->
        when step is
            DoDont Do -> (productSoFar, Do)
            DoDont Dont -> (productSoFar, Dont)
            Mul (Mul a b) ->
                when doDont is
                    Do -> (productSoFar + (a * b), Do)
                    Dont -> (productSoFar, Dont)
    Ok product

parseMulsOrDoDont :
    Parser
        (List U8)
        (List [Mul Mul, DoDont DoDont])
parseMulsOrDoDont =
    P.const (\x -> x)
    |> P.skip (P.chompWhile (\cp -> cp != 'm' && cp != 'd'))
    |> P.keep
        (
            P.oneOf [
                P.map parseMul (\mul -> Ok (Mul mul)),
                P.map parseDoDont (\doDont -> Ok (DoDont doDont)),
                P.map (PS.string "m") (\_ -> Err {}),
                P.map (PS.string "d") (\_ -> Err {}),
            ]
        )
    |> P.many
    |> P.map (\mulResults -> List.keepOks mulResults (\x -> x))

DoDont : [Do, Dont]

parseDoDont : Parser (List U8) DoDont
parseDoDont =
    PS.oneOf [
        PS.string "don't("
        |> P.map (\_ -> Dont),
        PS.string "do"
        |> P.map (\_ -> Do),
    ]

