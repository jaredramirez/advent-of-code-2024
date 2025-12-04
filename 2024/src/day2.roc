app [main] { pf: platform "https://github.com/roc-lang/basic-cli/releases/download/0.17.0/lZFLstMUCUvd5bjnnpYromZJXkQUrdhbva4xdBInicE.tar.br" }

import pf.File
import pf.Stdout as Stdout
import pf.Utc

import Common {
    now: Utc.now,
    toMillisSinceEpoch: Utc.toMillisSinceEpoch,
    line: Stdout.line,
    readUtf8: File.readUtf8,
}

main =
    Common.run! {
        inputFiles: [
            "src/day2Inputs/sample.txt",
            "src/day2Inputs/input.txt",
        ],
        solve1: solve1,
        solve2: solve2,
    }

# Algo - Part 1

solve1 : Str -> Result U64 [InvalidNumStr]
solve1 = \raw ->
    parsed = try parseInput raw
    numSafe = getNumSafe parsed
    Ok numSafe

# Parse

parseInput :
    Str
    -> Result
        (List (List I32))
        [InvalidNumStr]
parseInput = \str ->
    lines = Str.splitOn str "\n" |> List.keepIf \s -> s != ""
    List.mapTry lines \curLine ->
        split = Str.splitOn curLine " "
        List.mapTry split Str.toI32

# Algo - Part 1

getNumSafe : List (List I32) -> U64
getNumSafe = \reports ->
    reports
    |> List.keepOks checkIfReportSafe
    |> List.len

checkIfReportSafe :
    List I32
    -> Result {} [
        ListWasEmpty,
        InvalidDistance I32 I32,
        Expected [Asc, Desc] I32 I32,
    ]
checkIfReportSafe = \report ->
    head = try List.first report
    report
    |> List.dropFirst 1
    |> List.walkTry (head, Any) \(lastLevel, direction), thisLevel ->
        dist = Num.abs (lastLevel - thisLevel)
        if dist >= 1 && dist <= 3 then
            when direction is
                Any ->
                    Ok (
                        thisLevel,
                        if thisLevel > lastLevel then Asc else Desc,
                    )

                Asc ->
                    if thisLevel > lastLevel then
                        Ok (thisLevel, Asc)
                    else
                        Err (Expected Asc lastLevel thisLevel)

                Desc ->
                    if thisLevel < lastLevel then
                        Ok (thisLevel, Desc)
                    else
                        Err (Expected Desc lastLevel thisLevel)
        else
            Err (InvalidDistance lastLevel thisLevel)
    |> Result.map (\_ -> {})

# Algo - Part 2

solve2 : Str -> Result U64 [InvalidNumStr]
solve2 = \raw ->
    parsed = try parseInput raw
    numSafeWithDampener = getNumSafeWithDampener parsed
    Ok numSafeWithDampener

getNumSafeWithDampener : List (List I32) -> U64
getNumSafeWithDampener = \reports ->
    reports
    |> List.keepIf \report ->
        when checkIfReportSafe report is
            Ok {} -> Bool.true
            Err _ ->
                report
                |> makePermutations
                |> List.map checkIfReportSafe
                |> List.any Result.isOk
    |> List.len

# Given a list, return a list of lists where each element is removed
#
# Given [1, 2, 3], this would return
#   * [ 2, 3 ]
#   * [ 1, 3 ]
#   * [ 1, 2 ]
makePermutations : List val -> List (List val)
makePermutations = \list ->
    duped = List.repeat list (List.len list)
    List.mapWithIndex duped \elem, index ->
        List.dropAt elem index

