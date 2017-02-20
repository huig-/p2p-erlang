-module(lector).

-export([init/2, loop/3, recibir_mensaje/4]).

init(Pid, Path) -> %Path es usuario_i
    {ok, F} = file:open(filename:join(Path, "files.txt"), [read]),   
    loop(Pid, F, Path),
    file:close(F).
    
loop(Pid, F, Path) ->
    case file:read_line(F) of
	{ok, Data} ->
	    Filename = string:strip(Data, both, $\n),
	    case filelib:is_file(filename:join([Path, "completed", Filename])) of
		true -> loop(Pid, F, Path);
		false ->
		    Pid ! {self(), download, Filename},
		    recibir_mensaje(Pid, Filename, F, Path)
	    end;
	eof ->
	    ok;
	{error, Reason} ->
	    Reason
    end.

recibir_mensaje(Pid, Filename, F, Path) ->
    receive
	{Pid, accepted, Filename} ->
	    loop(Pid, F, Path);
	{Pid, rejected, Filename} ->
	    Pid ! {self(), download, Filename},
	    recibir_mensaje(Pid, Filename, F, Path);
	close ->
	    ok
    end.
