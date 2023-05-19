%%%-------------------------------------------------------------------
%%% @author maksymilian
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 17. Jan 2018 00:27
%%%-------------------------------------------------------------------
-module(peertopeer).
-author("maksymilian").

%% API
-export([run/2]).

run(NumOfProd, NumOfCons) ->
  register(manager, spawn(fun () -> manager() end)),
  createConsumers(NumOfCons),
  createProducers(NumOfProd).


%% manager connects producers and consumers
manager() -> receive
               {consumer, ConsumerPid} ->
                 receive
                   {producer, ProducerPid} -> ProducerPid ! ConsumerPid
                 end;
               {producer, ProducerPid} ->
                 receive
                   {consumer, ConsumerPid} -> ProducerPid ! ConsumerPid
                 end
             end,
  manager().

%% producers signal to the manager that they want to produce, then wait until manager sends them consumer
producer() ->
  manager ! {producer, self()},
  Resource = random:uniform(1000),
  receive
    ConsumerPid -> ConsumerPid ! Resource,
      io:format("producing resource ~w~n", [Resource]),
      producer()
  end.


%% consumers signal to the manager that they want to consume, then wait until someone sends them resource
consumer() ->
  manager ! {consumer, self()},
  receive
    Resource -> io:format("consuming resource ~w~n", [Resource]),
      consumer()
  end.


%% creating given number of producers
createProducers(0) -> 0;
createProducers(NumOfProd) ->
  spawn(fun () -> start_producer() end),
  createProducers(NumOfProd - 1).

%% creating given number of consumers
createConsumers(0) -> 0;
createConsumers(NumOfCons) ->
  spawn(fun () -> start_consumer() end),
  createProducers(NumOfCons - 1).

%% just for making sure, that randoms are randoms
start_producer() ->
  random:seed(crypto:bytes_to_integer(crypto:strong_rand_bytes(12))),
  producer().

start_consumer() ->
  random:seed(crypto:bytes_to_integer(crypto:strong_rand_bytes(12))),
  consumer().

