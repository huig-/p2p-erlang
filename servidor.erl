-module(servidor).

-export([init/0, loop/1]).

init() ->
    loop([]).

loop(Usuarios) ->
    receive
	{PIDUsuario, register} ->
	    PIDUsuario ! {self(), ack},
	    loop(Usuarios ++ [PIDUsuario]);
	{PIDUsuario, start, Filename} ->
	    lists:map(fun(X) -> X ! {PIDUsuario, seed, Filename} end, Usuarios),
	    loop(Usuarios);
	close ->
	    lists:map(fun(X) -> X ! close end, Usuarios)
    end.
