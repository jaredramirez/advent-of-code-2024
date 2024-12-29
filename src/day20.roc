app [main] {
    pf: platform "https://github.com/roc-lang/basic-cli/releases/download/0.17.0/lZFLstMUCUvd5bjnnpYromZJXkQUrdhbva4xdBInicE.tar.br",
}

import pf.File
import pf.Stdout
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
            "src/day20Inputs/sample.txt",
            "src/day20Inputs/input.txt",
        ],
        solve1: solve1,
        solve2: Common.stub,
    }

# Algo - Part 1

solve1 :
    Str
    -> Result U64 [
        InvalidGridElem Point,
        GridElemNotFound GridElem,
    ]
solve1 = \str ->
    grid = try buildGrid str
    startPoint = try getPointForElem grid Start
    paths = findPathsBase grid startPoint (Set.single startPoint)
    basePathLen =
        paths
        |> List.map getPathLen
        |> List.min
        |> Result.withDefault 0
    dbg basePathLen

    cheatPaths = findPathsCheat grid startPoint (Set.single startPoint) NotInCheat
    fasterCheats = List.keepIf cheatPaths \p ->
        getPathLen p < basePathLen
    cheatSpeedUps =
        fasterCheats
        |> List.walk
            (Dict.empty {})
            (\state, cheatPath ->
                Dict.update state (basePathLen - (getPathLen cheatPath)) \updatable ->
                    when updatable is
                        Ok existing -> Ok (existing + 1)
                        Err Missing -> Ok 1
            )
        |> Dict.toList
        |> List.keepIf (\(len, _numCheats) -> len <= 100)
        |> List.map (\(_len, numCheats) -> numCheats)
        |> List.sum
    dbg cheatSpeedUps
    Ok cheatSpeedUps

Point : (I32, I32)

Path : List Point

GridElem : [Track, Start, End, Wall]

Grid : Dict Point GridElem

CheatState : [AlreadyCheated, NotInCheat, InCheat]

getPathLen : Path -> U64
getPathLen = \path -> (List.len path) - 1

findPathsCheat : Grid, Point, Set Point, CheatState -> List Path
findPathsCheat = \grid, curPoint, visitedPoints, cheatState ->
    resultOrRecurse =
        when Dict.get grid curPoint is
            Ok End -> Result [[curPoint]]
            Ok Track | Ok Start ->
                when cheatState is
                    InCheat | AlreadyCheated ->
                        Recurse AlreadyCheated

                    NotInCheat ->
                        Recurse NotInCheat

            Ok Wall ->
                when cheatState is
                    NotInCheat ->
                        Recurse InCheat

                    InCheat | AlreadyCheated -> Result []

            Err _ -> Result []

    when resultOrRecurse is
        Result res -> res
        Recurse nextCheatState ->
            nextPoints =
                getPointsAround curPoint
                |> List.keepIf (\nextPoint -> !(Set.contains visitedPoints nextPoint))
            nextVisitedPoints = Set.insert visitedPoints curPoint
            List.joinMap nextPoints \nextPoint ->
                prependPaths = \paths -> List.map paths (\path -> List.prepend path curPoint)
                prependPaths (findPathsCheat grid nextPoint nextVisitedPoints nextCheatState)

findPathsBase : Grid, Point, Set Point -> List Path
findPathsBase = \grid, curPoint, visitedPoints ->
    dbg curPoint
    when Dict.get grid curPoint is
        Ok Wall | Err _ -> []
        Ok End -> [[curPoint]]
        Ok Track | Ok Start ->
            nextPoints =
                getPointsAround curPoint
                |> List.keepIf (\nextPoint -> !(Set.contains visitedPoints nextPoint))
            nextVisitedPoints = Set.insert visitedPoints curPoint
            List.joinMap nextPoints \nextPoint ->
                prependPaths = \paths -> List.map paths (\path -> List.prepend path curPoint)
                prependPaths (findPathsBase grid nextPoint nextVisitedPoints)

getPointsAround : Point -> List Point
getPointsAround = \(x, y) -> [
    (x + 1, y),
    (x - 1, y),
    (x, y + 1),
    (x, y - 1),
]

# Build a dict of Points -> GridElem, where the bottom, left is the origin
buildGrid : Str -> Result Grid [InvalidGridElem Point]
buildGrid = \str ->
    lines = Str.splitOn str "\n" |> List.keepIf (\s -> !(Str.isEmpty s))
    grid = List.map lines Str.toUtf8
    numLines = List.len lines
    (
        List.mapWithIndex grid \row, rowIndexBase ->
            rowIndex = numLines - 1 - rowIndexBase
            List.mapWithIndex row \val, colIndex ->
                point = (Num.toI32 colIndex, Num.toI32 rowIndex)
                mk = \elem -> Ok (point, elem)
                when val is
                    '.' -> mk Track
                    'S' -> mk Start
                    'E' -> mk End
                    '#' -> mk Wall
                    _ -> Err (InvalidGridElem point)
    )
    |> List.join
    |> List.mapTry Common.identity
    |> Result.map Dict.fromList

# Get the first point that an elem occurs in a grid
getPointForElem : Grid, GridElem -> Result Point [GridElemNotFound GridElem]
getPointForElem = \grid, elem ->
    grid
    |> Dict.keepIf (\(_k, v) -> v == elem)
    |> Dict.toList
    |> List.first
    |> Result.mapErr (\ListWasEmpty -> GridElemNotFound elem)
    |> Result.map (\(k, _v) -> k)
