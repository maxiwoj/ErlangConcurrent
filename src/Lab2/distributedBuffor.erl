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
-export([run/3]).


run(NumOfProd, NumOfCons, NumOfBuffers) ->
  register(producersManager, spawn(fun () -> producersManager() end)),
  register(consumersManager, spawn(fun () -> consumersManager() end)),
  createConsumers(NumOfCons),
  createProducers(NumOfProd),
  createBuffers(NumOfBuffers).




producersManager() -> receive
                        {emptyBuffer, BufferPid} ->
                          receive
                            {producer, ProducerPid} -> ProducerPid ! BufferPid,
                              producersManager()
                          end
                      end.

consumersManager() -> receive
                        {fullBuffer, BufferPid} ->
                          receive
                            {consumer, ConsumerPid} -> BufferPid ! ConsumerPid,
                              consumersManager()
                          end
                      end.

producer() ->
  producersManager ! {producer, self()},
  Resource = random:uniform(1000),
  receive
    BufferPid -> BufferPid ! Resource,
      io:format("producing resource ~w~n", [Resource]),
      producer()
  end.

consumer() ->
  consumersManager ! {consumer, self()},
  receive
    Resource -> io:format("consuming resource ~w~n", [Resource]),
      consumer()
  end.

buffer() ->
  producersManager ! {emptyBuffer, self()},
  receive
    Value -> consumersManager ! {fullBuffer, self()},
      receive
        ConsumerPid -> ConsumerPid ! Value,
          buffer()
      end
  end.



createProducers(0) -> 0;
createProducers(NumOfProd) ->
  spawn(fun () -> start_producer() end),
  createProducers(NumOfProd - 1).

createConsumers(0) -> 0;
createConsumers(NumOfCons) ->
  spawn(fun () -> start_consumer() end),
  createProducers(NumOfCons - 1).

createBuffers(0) -> 0;
createBuffers(NumOfBuffers) ->
  spawn(fun () -> buffer() end),
  createBuffers(NumOfBuffers - 1).

start_producer() ->
  random:seed(crypto:bytes_to_integer(crypto:strong_rand_bytes(12))),
  producer().

start_consumer() ->
  random:seed(crypto:bytes_to_integer(crypto:strong_rand_bytes(12))),
  consumer().

