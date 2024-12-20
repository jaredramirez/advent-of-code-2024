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
            "src/day4Inputs/sample.txt",
            "src/day4Inputs/input.txt",
        ],
        solve1: solve1,
        solve2: solve2,
    }

# Algo - Part 1

solve1 : Str -> Result U64 Str
solve1 = \str ->
    grid = buildGrid str
    xs =
        grid
        |> Dict.keepIf (\(_k, v) -> v == 'X')
        |> Dict.keys
    (
        List.map xs \xPoint ->
            List.map directions \dir ->
                isXmasInDirection grid dir xPoint
    )
    |> List.join
    |> List.keepIf identity
    |> List.len
    |> Ok

Point : (I32, I32)

Grid : Dict Point U8

Direction : [Up, Down, Left, Right, UpRight, DownRight, UpLeft, DownLeft]

directions : List Direction
directions = [Up, Down, Left, Right, UpRight, DownRight, UpLeft, DownLeft]

isXmasInDirection : Grid, Direction, Point -> Bool
isXmasInDirection = \grid, dir, xPoint ->
    when calcXmasInDirection grid dir xPoint is
        Ok bool -> bool
        Err _ -> Bool.false

calcXmasInDirection : Grid, Direction, Point -> Result Bool [KeyNotFound]
calcXmasInDirection = \grid, dir, xPoint ->
    masPoints = directionToPoints dir xPoint
    m = try Dict.get grid masPoints.m
    a = try Dict.get grid masPoints.a
    s = try Dict.get grid masPoints.s
    Ok (m == 'M' && a == 'A' && s == 'S')

directionToPoints : Direction, Point -> { m : Point, a : Point, s : Point }
directionToPoints = \dir, (x, y) ->
    when dir is
        Up -> { m: (x, y + 1), a: (x, y + 2), s: (x, y + 3) }
        Down -> { m: (x, y - 1), a: (x, y - 2), s: (x, y - 3) }
        Right -> { m: (x + 1, y), a: (x + 2, y), s: (x + 3, y) }
        Left -> { m: (x - 1, y), a: (x - 2, y), s: (x - 3, y) }
        UpRight -> { m: (x + 1, y + 1), a: (x + 2, y + 2), s: (x + 3, y + 3) }
        UpLeft -> { m: (x - 1, y + 1), a: (x - 2, y + 2), s: (x - 3, y + 3) }
        DownLeft -> { m: (x - 1, y - 1), a: (x - 2, y - 2), s: (x - 3, y - 3) }
        DownRight -> { m: (x + 1, y - 1), a: (x + 2, y - 2), s: (x + 3, y - 3) }

buildGrid : Str -> Grid
buildGrid = \str ->
    lines = Str.splitOn str "\n"
    grid = List.map lines Str.toUtf8
    (
        List.mapWithIndex grid \row, rowIndex ->
            List.mapWithIndex row \val, colIndex ->
                ((Num.toI32 rowIndex, Num.toI32 colIndex), val)
    )
    |> List.join
    |> Dict.fromList

identity : val -> val
identity = \val -> val

# Algo - Part 2

solve2 : Str -> Result U64 Str
solve2 = \str ->
    grid = buildGrid str
    xs =
        grid
        |> Dict.keepIf (\(_k, v) -> v == 'A')
        |> Dict.keys

    (
        List.map xs \(x, y) ->
            firstDiagonal = ((x + 1, y + 1), (x - 1, y - 1))
            secondDiagonal = ((x + 1, y - 1), (x - 1, y + 1))

            List.all
                [
                    calcXDashmasInDirection grid firstDiagonal
                    |> Result.withDefault Bool.false,
                    calcXDashmasInDirection grid secondDiagonal
                    |> Result.withDefault Bool.false,
                ]
                identity

    )
    |> List.keepIf identity
    |> List.len
    |> Ok

calcXDashmasInDirection : Grid, (Point, Point) -> Result Bool [KeyNotFound]
calcXDashmasInDirection = \grid, (firstPoint, secondPoint) ->
    firstVal = try Dict.get grid firstPoint
    secondVal = try Dict.get grid secondPoint
    Ok ((firstVal == 'M' && secondVal == 'S') || (secondVal == 'M' && firstVal == 'S'))

