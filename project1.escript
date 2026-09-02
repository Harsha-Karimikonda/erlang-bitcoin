#!/usr/bin/env escript
%%! -smp enable

-define(PREFIX, <<"hkarimkonda;">>).
-define(DEFAULT_WORK_UNIT, 50000).
-define(COOKIE, bitcoin).

main(Args) ->
    case Args of
        [Arg] ->
            parse_and_run(Arg, infinity, ?DEFAULT_WORK_UNIT);
        [Arg, LimitStr] ->
            parse_and_run(Arg, list_to_integer(LimitStr), ?DEFAULT_WORK_UNIT);
        [Arg, LimitStr, UnitStr] ->
            parse_and_run(Arg, list_to_integer(LimitStr), list_to_integer(UnitStr));
        _ ->
            io:format(standard_error, "Usage: ./project1 <k | server_ip> [coin_limit] [work_unit_size]~n", []),
            halt(1)
    end.

parse_and_run(Arg, Limit, Unit) ->
    case string:to_integer(Arg) of
        {K, []} when is_integer(K), K >= 0 ->
            start_server(K, Limit, Unit);
        _ ->
            start_worker(Arg)
    end.

start_server(K, Limit, Unit) ->
    IP = get_ip(),
    NodeName = list_to_atom("server@" ++ IP),
    net_kernel:start([NodeName, longnames]),
    erlang:set_cookie(node(), ?COOKIE),
    io:format(standard_error, "Server running at ~s (To connect a worker: ./project1 ~s)~n", [NodeName, IP]),
    statistics(runtime),
    statistics(wall_clock),
    BossPid = spawn(fun() -> boss_loop(1, K, Unit, 0, Limit) end),
    register(boss, BossPid),
    spawn_workers(BossPid, erlang:system_info(schedulers_online)),
    timer:sleep(infinity).

start_worker(ServerHost) ->
    WorkerNode = list_to_atom("worker_" ++ integer_to_list(erlang:unique_integer([positive])) ++ "@" ++ get_ip()),
    net_kernel:start([WorkerNode, longnames]),
    erlang:set_cookie(node(), ?COOKIE),
    ServerNode = case string:find(ServerHost, "@") of
        nomatch -> list_to_atom("server@" ++ ServerHost);
        _ -> list_to_atom(ServerHost)
    end,
    case net_adm:ping(ServerNode) of
        pong ->
            spawn_workers({boss, ServerNode}, erlang:system_info(schedulers_online)),
            timer:sleep(infinity);
        pang ->
            io:format(standard_error, "Cannot connect to server ~p~n", [ServerNode]),
            halt(1)
    end.

spawn_workers(Boss, Num) ->
    [spawn(fun() -> worker_loop(Boss) end) || _ <- lists:seq(1, Num)].

boss_loop(NextNonce, K, Unit, Found, Limit) ->
    receive
        {get_work, From} ->
            From ! {work, NextNonce, Unit, K},
            boss_loop(NextNonce + Unit, K, Unit, Found, Limit);
        {found, Str, Hash} ->
            io:format("~s\t~s~n", [Str, Hash]),
            NewFound = Found + 1,
            case Limit of
                infinity ->
                    boss_loop(NextNonce, K, Unit, NewFound, Limit);
                _ when NewFound >= Limit ->
                    {_, CpuTime} = statistics(runtime),
                    {_, WallClock} = statistics(wall_clock),
                    Ratio = case WallClock of 0 -> 1.0; _ -> CpuTime / WallClock end,
                    io:format(standard_error, "~nFound ~p coins.~nCPU Time: ~p ms~nReal Time: ~p ms~nCPU/Real Ratio: ~.2f~n",
                              [NewFound, CpuTime, WallClock, Ratio]),
                    halt(0);
                _ ->
                    boss_loop(NextNonce, K, Unit, NewFound, Limit)
            end
    end.

worker_loop(Boss) ->
    Boss ! {get_work, self()},
    receive
        {work, Start, Unit, K} ->
            mine_range(Start, Start + Unit, K, K * 4, Boss),
            worker_loop(Boss)
    end.

mine_range(Current, End, _K, _Bits, _Boss) when Current >= End -> ok;
mine_range(Current, End, K, Bits, Boss) ->
    Str = <<?PREFIX/binary, (integer_to_binary(Current, 36))/binary>>,
    Hash = crypto:hash(sha256, Str),
    case Hash of
        <<0:Bits, _/bitstring>> ->
            Boss ! {found, Str, to_hex(Hash)};
        _ -> ok
    end,
    mine_range(Current + 1, End, K, Bits, Boss).

to_hex(Bin) ->
    <<<<case B of _ when B < 10 -> B + $0; _ -> B - 10 + $a end>> || <<B:4>> <= Bin>>.

get_ip() ->
    {ok, IfList} = inet:getifaddrs(),
    case [IP || {_If, Opts} <- IfList,
                lists:member(up, proplists:get_value(flags, Opts, [])),
                lists:member(running, proplists:get_value(flags, Opts, [])),
                not lists:member(loopback, proplists:get_value(flags, Opts, [])),
                {addr, {A,_,_,_} = IP} <- Opts, A =/= 127] of
        [{A, B, C, D} | _] -> lists:flatten(io_lib:format("~B.~B.~B.~B", [A, B, C, D]));
        _ -> "127.0.0.1"
    end.
