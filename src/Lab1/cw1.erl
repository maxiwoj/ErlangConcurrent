%%%-------------------------------------------------------------------
%%% @author maksymilian
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 05. Jan 2018 18:20
%%%-------------------------------------------------------------------
-module(cw1).
-author("maksymilian").

%% API
-export([start/0, c3/0]).

start() ->
  register(c, spawn(fun() -> c2() end)),
  register(a, spawn(fun() -> a_loop(0) end)),
  register(b, spawn(fun() -> b_loop(0) end)).

c1_a() ->
  receive
    aaa -> io:format("got aaa!~n"),
      c1_b()
  end.

c1_b() ->
  receive
    bbb -> io:format("got bbb!~n"),
      c1_a()
  end.

c2() ->
  receive
    {aaa, N} -> io:format("got aaa in iter: ~B!~n", [N]),
      c2();
    {bbb, N} -> io:format("got bbb in iter: ~B!~n", [N]),
      c2()
  end.


c3() ->
  receive
    A -> io:format("got ~w~n", [A]),
      c3()
  end.

a_loop(N) ->
%%  timer:sleep(200),
  c ! {aaa, N},
  a_loop(N + 1).

b_loop(N) ->
%%  timer:sleep(200),
  c ! {bbb, N},
  b_loop(N + 1).


