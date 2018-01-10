%%%-------------------------------------------------------------------
%%% @author maksymilian
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 05. Jan 2018 18:49
%%%-------------------------------------------------------------------
-module(cw2).
-author("maksymilian").

%% API
-export([run/3, createProducers/1, createConsumers/1]).

run(NumOfProd, NumOfCons, BufferSize) ->
  start_buffer(BufferSize),
  createConsumers(NumOfCons),
  createProducers(NumOfProd).

start_buffer(N) ->
  register(buffer, spawn(fun() -> empty_buffer(N) end)).

createProducers(NumOfProd) ->
  if
    NumOfProd > 0 -> spawn(fun() -> start_producer() end), createProducers(NumOfProd - 1);
    true -> io:format("producers created~n")
  end.

createConsumers(NumOfCons) ->
  if
    NumOfCons > 0 -> spawn(fun() -> start_consumer() end), createConsumers(NumOfCons - 1);
    true -> io:format("consumers created~n")
  end.

buffer([H|T], MaxN) ->
  receive
    {add, Value, Pid} ->
%%      io:format("got add request~n"),
      Pid ! ok,
      if
        length([H|T]) + 1 == MaxN -> full_buffer([H|T] ++ [Value]);
        true -> buffer([H|T] ++ [Value], MaxN)
      end;

    {get, Pid} ->
%%      io:format("got get request~n"),
      Pid ! H,
      if
        length(T) == 0 -> empty_buffer(MaxN);
        true -> buffer(T, MaxN)
      end
  end.

full_buffer([H|T]) ->
  receive
    {get, Pid} ->
      Pid ! H,
      buffer(T, length([H|T]))
  end.

empty_buffer(MaxN) ->
  receive
    {add, Value, Pid} ->
      Pid ! ok,
      buffer([Value], MaxN)
  end.

start_producer() ->
  random:seed(crypto:bytes_to_integer(crypto:strong_rand_bytes(12))),
  producer().

start_consumer() ->
  random:seed(crypto:bytes_to_integer(crypto:strong_rand_bytes(12))),
  consumer().

consumer() ->
  timer:sleep(500),
  buffer ! {get, self()},
  receive
    Value -> io:format("consuming ~w~n", [Value]),
      consumer()
%%  after
%%    2000 -> io:format("waited 2 sec!~n"),
%%      consumer()
  end.

producer() ->
  timer:sleep(500),
  Value = random:uniform(1000),
  buffer ! {add, Value, self()},
  receive
    ok -> io:format("produced ~w~n", [Value]),
      producer()
%%  after
%%    2000 -> io:format("waited 2 sec!~n"),
%%      producer()
  end.