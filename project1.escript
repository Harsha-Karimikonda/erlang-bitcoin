#!/usr/bin/env escript
%%! -smp enable

% Gator id used
-define(PREFIX, <<"hkarimkonda;">>).
% We are checking total 500k strings per work unit
-define(WORK_UNIT, 500000).

% The main entry point where the K is defined
% If K is not given but a ip address is given it will start running in worker mode
main([Target]) ->
    case string:to_integer(Target) of
        {K, []} when K >= 0, K =< 64 -> server(K);
        {_, []} -> halt(1);
        _ -> worker(Target)
    end.

% Main boss worker function that intializes the system
server(K) ->
    IP = local_ip({8, 8, 8, 8}),
    {ok, _} = net_kernel:start([list_to_atom("server@" ++ IP), longnames]),
    erlang:set_cookie(node(), bitcoin),
    Boss = spawn(fun() -> boss(1, K) end),
    register(boss, Boss),
    start_workers(Boss),
    timer:sleep(infinity).

% Worker function which runs in other machines
% It will connect to boss and submit results
worker(Host) ->
    {ok, ServerIP} = inet:getaddr(Host, inet),
    IP = inet:ntoa(ServerIP),
    LocalIP = local_ip(ServerIP),
    Name = "worker_" ++ os:getpid() ++ "@" ++ LocalIP,
    {ok, _} = net_kernel:start([list_to_atom(Name), longnames]),
    erlang:set_cookie(node(), bitcoin),
    Server = list_to_atom("server@" ++ IP),
    case net_adm:ping(Server) of
        pong -> start_workers({boss, Server}), timer:sleep(infinity);
        pang -> halt(1)
    end.

% Starts concurrent mining actors, only one boss process
start_workers(Boss) ->
    [spawn(fun() -> miner(Boss) end) || _ <- lists:seq(1, erlang:system_info(schedulers_online))].

% Central coordinator actor that prints found coins.
boss(Next, K) ->
    receive
        {get_work, Worker} ->
            Worker ! {work, Next, ?WORK_UNIT, K},
            boss(Next + ?WORK_UNIT, K);
        {found, Input, Hash} ->
            io:format("~s\t~s~n", [Input, Hash]),
            boss(Next, K)
    end.

% the workflow loop for each mining worker process
miner(Boss) ->
    Boss ! {get_work, self()},
    receive
        {work, Start, Unit, K} ->
            mine(Start, Start + Unit, K * 4, Boss),
            miner(Boss)
    end.

mine(Nonce, End, _, _) when Nonce >= End -> ok;
% This code generates the strings and then does hashing and does difficulty verification
mine(Nonce, End, Bits, Boss) ->
    Input = <<?PREFIX/binary, (integer_to_binary(Nonce, 36))/binary>>,
    Hash = crypto:hash(sha256, Input),
    case Hash of
        <<0:Bits, _/bitstring>> -> Boss ! {found, Input, binary:encode_hex(Hash, lowercase)};
        _ -> ok
    end,
    mine(Nonce + 1, End, Bits, Boss).

% gets the codes local ip
local_ip(Target) ->
    case os:getenv("MY_IP") of
        false ->
            {ok, Socket} = gen_udp:open(0),
            ok = gen_udp:connect(Socket, Target, 4369),
            {ok, {Address, _}} = inet:sockname(Socket),
            gen_udp:close(Socket),
            inet:ntoa(Address);
        IP -> IP
    end.
