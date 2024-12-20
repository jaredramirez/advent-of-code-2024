module { now, toMillisSinceEpoch, line, readUtf8 } -> [Conf, run, stub, identity, partition]

# Runner

Conf result1 err1 result2 err2 : {
    inputFiles : List Str,
    solve1 : Str -> Result result1 err1,
    solve2 : Str -> Result result2 err2,
}

run : Conf result1 err1 result2 err2 -> Task {} _ where result1 implements Inspect.Inspect, result2 implements Inspect.Inspect, err1 implements Inspect.Inspect, err2 implements Inspect.Inspect
run = \conf ->
    Task.forEach conf.inputFiles \fileName ->
        line! (Str.concat "Processing file " fileName)
        contents = readUtf8! fileName

        result1Before = now! {} |> toMillisSinceEpoch
        result1 = conf.solve1 contents
        result1After = now! {} |> toMillisSinceEpoch
        [
            "Part 1:",
            Inspect.toStr result1,
            Str.joinWith
                [
                    "(",
                    Num.toStr (result1After - result1Before),
                    " ms)",
                ]
                "",
        ]
        |> Str.joinWith " "
        |> line!

        result2Before = now! {} |> toMillisSinceEpoch
        result2 = conf.solve2 contents
        result2After = now! {} |> toMillisSinceEpoch
        [
            "Part 2:",
            Inspect.toStr result2,
            Str.joinWith
                [
                    "(",
                    Num.toStr (result2After - result2Before),
                    " ms)",
                ]
                "",
        ]
        |> Str.joinWith " "
        |> line!

stub : Str -> Result Str {}
stub = \_ -> Ok "TODO"

# Common

identity : val -> val
identity = \val -> val

partition : List val, (val -> Bool) -> (List val, List val)
partition = \list, pred ->
    List.walk list ([], []) \(passes, failes), cur ->
        if pred cur then
            (List.append passes cur, failes)
        else
            (passes, List.append failes cur)
