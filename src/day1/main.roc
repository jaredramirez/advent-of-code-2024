app [main] { pf: platform "https://github.com/roc-lang/basic-cli/releases/download/0.17.0/lZFLstMUCUvd5bjnnpYromZJXkQUrdhbva4xdBInicE.tar.br" }

import pf.File
import pf.Stdout

main =
    Task.forEach inputFiles \fileName ->
        contents = File.readUtf8! fileName
        result = solve contents
        when result is
            Ok val ->
                [fileName, Num.toStr val.distance, Num.toStr val.similarity]
                |> Str.joinWith " "
                |> Stdout.line

            Err problem -> Task.err problem

inputFiles : List Str
inputFiles = ["src/day1/sample.txt", "src/day1/input.txt"]

# Solve

solve :
    Str
    ->
    Result
        { distance : I32, similarity : I32 }
        [CouldNotParseLine Str, InvalidNumStr, ListWasEmpty, NotFound [Left, Right] I32]
solve = \raw ->
    leftsRights = try parseInput raw
    dist = try getDistance leftsRights
    sim = getSimiliarity leftsRights
    Ok { distance: dist, similarity: sim }

# Parse

parseInput :
    Str
    -> Result
        (List I32, List I32)
        [CouldNotParseLine Str, InvalidNumStr]
parseInput = \str ->
    lines = Str.splitOn str "\n" |> List.keepIf \s -> s != ""
    List.walkTry lines ([], []) \(lefts, rights), curLine ->
        when Str.splitOn curLine "   " is
            [nextLeftStr, nextRightStr] ->
                nextLeft = try Str.toI32 nextLeftStr
                nextRight = try Str.toI32 nextRightStr
                Ok (List.prepend lefts nextLeft, List.prepend rights nextRight)

            _ -> Err (CouldNotParseLine curLine)

# Algo - Part 1

getDistance : (List I32, List I32) -> Result I32 [NotFound [Left, Right] I32]
getDistance = \leftsRights ->
    nextDistResult = getNextPairsDistance leftsRights
    when nextDistResult is
        Err ListWasEmpty -> Ok 0
        Err (NotFound letOrRight val) -> Err (NotFound letOrRight val)
        Ok (nextLeftsRights, dist) ->
            nextDist = try getDistance nextLeftsRights
            Ok (dist + nextDist)

getNextPairsDistance :
    (List I32, List I32)
    -> Result
        ((List I32, List I32), I32)
        [ListWasEmpty, NotFound [Left, Right] I32]
getNextPairsDistance = \(lefts, rights) ->
    nextSmallestLeft = try List.min lefts
    nextSmallestLeftIndex =
        List.findFirstIndex lefts (\elem -> elem == nextSmallestLeft)
        |> Result.mapErr (\NotFound -> NotFound Left nextSmallestRight)
        |> try

    nextSmallestRight = try List.min rights
    nextSmallestRightIndex =
        List.findFirstIndex rights (\elem -> elem == nextSmallestRight)
        |> Result.mapErr (\NotFound -> NotFound Right nextSmallestRight)
        |> try

    Ok (
        (
            List.dropAt lefts nextSmallestLeftIndex,
            List.dropAt rights nextSmallestRightIndex,
        ),
        Num.abs (nextSmallestLeft - nextSmallestRight),
    )

# Algo - Part 2

getSimiliarity : (List I32, List I32) -> I32
getSimiliarity = \(lefts, rights) ->
    lefts
    |> List.map \leftVal ->
        occurrencesInRight =
            rights
            |> List.keepIf (\rightVal -> rightVal == leftVal)
            |> List.len
            |> Num.toI32
        leftVal * occurrencesInRight
    |> List.sum
