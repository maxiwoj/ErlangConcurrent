%%%-------------------------------------------------------------------
%%% @author maksymilian
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 08. Jan 2018 18:06
%%%-------------------------------------------------------------------
-module(distributedBuffor).
-author("maksymilian").

%% API
-export([]).


run(NumOfProd, NumOfCons, NumOfBuffers, SingleBufferSize) ->
  BufferIds = createBuffers(NumOfBuffers, SingleBufferSize, #{}),
  createConsumers(NumOfCons, BufferIds, NumOfCons div maps:size(BufferIds)),
  createProducers(NumOfProd, BufferIds, NumOfProd div maps:size(BufferIds)).


createProducers(NumOfProd, BufferIds, NumOfWorkersPerBuffer) ->
  if
    NumOfProd > 0 ->
      BufferId = maps:get((NumOfProd - 1) div NumOfWorkersPerBuffer,BufferIds),
      spawn(fun() -> start_producer(BufferId) end),
      createProducers(NumOfProd - 1, BufferIds, NumOfWorkersPerBuffer);
    true -> io:format("producers created~n")
  end.

createConsumers(NumOfCons, BufferIds, NumOfWorkersPerBuffer) ->
  if
    NumOfCons > 0 ->
      BufferId = maps:get((NumOfCons - 1) div NumOfWorkersPerBuffer,BufferIds),
      spawn(fun() -> start_consumer(BufferId) end),
      createConsumers(NumOfCons - 1, BufferIds, NumOfWorkersPerBuffer);
    true -> io:format("consumers created~n")
  end.

createBuffers(0, _, BufferMap) -> BufferMap.
createBuffers(NumOfBuffers, SingleBufferSize, BufferMap) ->
  NewBufferMap = maps:put(NumOfBuffers, start_buffer(NumOfBuffers, SingleBufferSize, list_to_atom("buffer" ++ integer_to_list(NumOfBuffers))), BufferMap),
  createBuffers(NumOfBuffers - 1, SingleBufferSize, NewBufferMap).


start_buffer(BufferNum, N, BufferName) -> register(BufferName, spawn(fun() -> empty_buffer(BufferNum, N) end)).

start_producer(BufferPid) ->
  random:seed(crypto:bytes_to_integer(crypto:strong_rand_bytes(12))),
  producer(BufferPid).

start_consumer(BufferPid) ->
  random:seed(crypto:bytes_to_integer(crypto:strong_rand_bytes(12))),
  consumer(BufferPid).

consumer(BufferPid) ->
  timer:sleep(500),
  BufferPid ! {get, self()},
  receive
    Value -> io:format("consuming ~w~n", [Value]),
      consumer(BufferPid)
  end.

producer(BufferPid) ->
  timer:sleep(500),
  Value = random:uniform(1000),
  BufferPid ! {add, Value, self()},
  receive
    ok -> io:format("produced ~w~n", [Value]),
      producer(BufferPid)
  end.





buffer([H|T], MaxN) ->
  receive
    {add, Value, Pid} ->
      Pid ! ok,
      if
        length([H|T]) + 1 == MaxN -> full_buffer([H|T] ++ [Value]);
        true -> buffer([H|T] ++ [Value], MaxN)
      end;

    {get, Pid} ->
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