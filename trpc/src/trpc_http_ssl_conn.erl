%%% -------------------------------------------------------------------
%%% @author  xiaobin xu <xiaobin@firevale.com>
%%% @copyright  2012  xiaobin xu.
%%% @doc  
%%% -------------------------------------------------------------------

-module(trpc_http_ssl_conn).
-behaviour(gen_server).

%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------

-include("trpc.hrl").

%% --------------------------------------------------------------------
%% External exports
-export([start_link/3, stop/0]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-record(state, {web_socket=undefined, conn_id=undefined, connected=undefined}).

%% ====================================================================
%% External functions
%% ====================================================================
start_link(ConnId, WAddr, WPort) ->
    gen_server:start_link(?MODULE, [ConnId, WAddr, WPort], []).

stop() ->
    gen_server:cast(?MODULE, stop).

%% ====================================================================
%% Server functions
%% ====================================================================

%% --------------------------------------------------------------------
%% Function: init/1
%% Description: Initiates the server
%% Returns: {ok, State}          |
%%          {ok, State, Timeout} |
%%          ignore               |
%%          {stop, Reason}
%% --------------------------------------------------------------------
init([ConnId, WAddr, WPort]) ->
    {ok, WSock} = ssl:connect(WAddr, WPort, [{active, once}]), 
    {ok, #state{web_socket=WSock, conn_id=ConnId}}.


%% --------------------------------------------------------------------
%% Function: handle_call/3
%% Description: Handling call messages
%% Returns: {reply, Reply, State}          |
%%          {reply, Reply, State, Timeout} |
%%          {noreply, State}               |
%%          {noreply, State, Timeout}      |
%%          {stop, Reason, Reply, State}   | (terminate/2 is called)
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.

%% --------------------------------------------------------------------
%% Function: handle_cast/2
%% Description: Handling cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_cast({send_message, <<"\r\n">>}, #state{connected=undefined} = State) ->
%%     ok = gen_tcp:send(WSock, Msg),
    {noreply, State#state{connected=true}};

handle_cast({send_message, _Msg}, #state{connected=undefined} = State) ->
%%     ?DEBUG("send message to web server: ~n ~p ~n", [Msg]),
%%     ok = gen_tcp:send(WSock, Msg),
    {noreply, State};

handle_cast({send_message, Msg}, #state{web_socket=WSock, connected=true} = State) ->
    ?DEBUG("send message to web server: ~n ~p ~n", [Msg]),
    ok = ssl:send(WSock, Msg),
    {noreply, State};

handle_cast(_Msg, State) ->
    {noreply, State}.

%% --------------------------------------------------------------------
%% Function: handle_info/2
%% Description: Handling all non call/cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_info({ssl, Socket, Bin}, #state{web_socket=Socket, conn_id=ConnId} = State) ->
    ?DEBUG("receive message from web server: ~n ~p ~n", [Bin]),
    trpc_tcp_conn:send_message(Bin, ConnId),
    ssl:setopts(Socket, [{active, once}]),
    {noreply, State};

handle_info({ssl_closed, _}, #state{conn_id=ConnId} = State) ->
    trpc_tcp_conn:send_message(<<"disconn">>, ConnId), 
    {stop, normal, State};

handle_info(_Info, State) ->
    {noreply, State}.

%% --------------------------------------------------------------------
%% Function: terminate/2
%% Description: Shutdown the server
%% Returns: any (ignored by gen_server)
%% --------------------------------------------------------------------
terminate(_Reason, #state{web_socket=Sock, conn_id=ConnId}) ->
    trpc_tcp_conn:delete_conn(ConnId),
    ssl:close(Sock),
    ok.

%% --------------------------------------------------------------------
%% Func: code_change/3
%% Purpose: Convert process state when code is changed
%% Returns: {ok, NewState}
%% --------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------

