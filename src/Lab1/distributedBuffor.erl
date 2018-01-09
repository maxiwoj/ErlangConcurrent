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
-export([run/5]).


run(NumOfProd, NumOfCons, NumOfBuffers, SingleBufferSize, ResourcesRange) ->
  BufferIds = createBuffers(NumOfBuffers, SingleBufferSize, #{}),
  createConsumers(NumOfCons, BufferIds, ResourcesRange),
  createProducers(NumOfProd, BufferIds, ResourcesRange).


createProducers(NumOfProd, BufferIds, ResourcesRange) ->
  if
    NumOfProd > 0 ->
      spawn(fun() -> start_producer(BufferIds, ResourcesRange) end),
      createProducers(NumOfProd - 1, BufferIds, ResourcesRange);
    true -> io:format("producers created~n")
  end.

createConsumers(NumOfCons, BufferIds, ResourcesRange) ->
  if
    NumOfCons > 0 ->
      spawn(fun() -> start_consumer(BufferIds, ResourcesRange) end),
      createConsumers(NumOfCons - 1, BufferIds, ResourcesRange);
    true -> io:format("consumers created~n")
  end.

start_producer(BufferPids, ResourcesRange) ->
  random:seed(crypto:bytes_to_integer(crypto:strong_rand_bytes(12))),
  producer(BufferPids, ResourcesRange).

start_consumer(BufferPids, ResourcesRange) ->
  random:seed(crypto:bytes_to_integer(crypto:strong_rand_bytes(12))),
  consumer(BufferPids, ResourcesRange).

consumer(BufferPids, ResourcesRange) ->
  timer:sleep(500),
  BufferPid = list_to_atom("buffer" ++ integer_to_list(resourceHash(maps:size(BufferPids), ResourcesRange, random:uniform(ResourcesRange)))),
  BufferPid ! {get, self()},
  receive
    Value -> io:format("consuming ~w~n", [Value]),
      consumer(BufferPids, ResourcesRange)
  end.

producer(BufferPids, ResourcesRange) ->
  timer:sleep(500),
  Value = random:uniform(ResourcesRange),
  BufferPid = list_to_atom("buffer" ++ integer_to_list(resourceHash(maps:size(BufferPids), ResourcesRange, random:uniform(ResourcesRange)))),
  BufferPid ! {add, Value, self()},
  receive
    ok -> io:format("produced ~w~n", [Value]),
      producer(BufferPids, ResourcesRange)
  end.


resourceHash(NumOfBuffers, ResourcesRange, Value) ->
  ValuesPerBuffer = (ResourcesRange div NumOfBuffers) + 1,
  ResourcesRange div ValuesPerBuffer.


createBuffers(0, _, BufferMap) -> BufferMap;
createBuffers(NumOfBuffers, SingleBufferSize, BufferMap) ->
  NewBufferMap = maps:put(NumOfBuffers, start_buffer(SingleBufferSize, list_to_atom("buffer" ++ integer_to_list(NumOfBuffers))), BufferMap),
  createBuffers(NumOfBuffers - 1, SingleBufferSize, NewBufferMap).

start_buffer(N, BufferName) -> register(BufferName, spawn(fun() -> empty_buffer(N) end)).

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