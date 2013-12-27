
-module(trpc_sup).

-behaviour(supervisor).

%% API
-export([start_link/0]).

%% Supervisor callbacks
-export([init/1]).

-include("trpc.hrl").

%% Helper macro for declaring children of supervisor
-define(CHILD(I, Type), {I, {I, start_link, []}, permanent, 5000, Type, [I]}).

%% ===================================================================
%% API functions
%% ===================================================================
start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).



%% ===================================================================
%% Supervisor callbacks
%% ===================================================================
init([]) ->
    io:format("start trp client...~n", []),
    {ok, { {one_for_one, 10, 10}, [?CHILD(trpc_tcp_conn, worker)]} }.
            

