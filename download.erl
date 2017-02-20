-module(download).
-include("defs.hrl").

-export([init/5, loop/6, concatenar_chunks/2, eliminar_ficheros/2, obtener_numero_chunk/1]).

init(Path, Config, Filename, PIDUsuario, PIDServidor) -> %Path es usuario_i
    filelib:ensure_dir(filename:join([Path, "downloading", string:concat(Filename, "_dir"), "a"])),
    PIDServidor ! {self(), start, Filename},
    loop(Path, Config, Filename, PIDUsuario, PIDServidor, []).

loop(Path, Config, Filename, PIDUsuario, PIDServidor, DownloadFromSeedProcesses) ->
    receive
	{PidSeed, iseedyou, Filename, Nchunks} ->
	    PidDownloadFromSeed = spawn(downloadFromSeed, init, [self(), PidSeed, Path, Config, Filename, Nchunks]),
	    loop(Path, Config, Filename, PIDUsuario, PIDServidor, DownloadFromSeedProcesses ++ [PidDownloadFromSeed]);
	close ->
	    lists:map(fun(X) -> X ! close end, DownloadFromSeedProcesses);
	{_PidDownloadFromSeed, completed} -> 
	    concatenar_chunks(Path, Filename),
	    eliminar_ficheros(Path, Filename),
	    lists:map(fun(X) -> X ! close end, DownloadFromSeedProcesses),
	    PIDUsuario ! {self(), enddownload};
	{PidDownloadFromSeed, timeout} -> 
	    NewDownloadFromSeedProcesses = lists:delete(PidDownloadFromSeed, DownloadFromSeedProcesses),
	    case length(NewDownloadFromSeedProcesses) of
		0 ->
		    PIDServidor ! {self(), start, Filename},
		    loop(Path, Config, Filename, PIDUsuario, PIDServidor, []); 
		_ ->
		    loop(Path, Config, Filename, PIDUsuario, PIDServidor, NewDownloadFromSeedProcesses)
	    end
    end.
	    
concatenar_chunks(Path, Filename) -> %Path es usuario_i
    Dir = filename:join([Path, "downloading", string:concat(Filename, "_dir")]),
    {ok, Chunks} = file:list_dir(Dir),
    SortedChunks = lists:sort(fun(X,Y) -> obtener_numero_chunk(X) =< obtener_numero_chunk(Y) end, Chunks),
    lists:map(fun(X) -> file:copy(filename:join([Path, "downloading", string:concat(Filename, "_dir"), X]), {filename:join([Path, "completed", Filename]), [append]}) end, SortedChunks).

eliminar_ficheros(Path, Filename) -> %Path es usuario_i
    Dir = filename:join([Path, "downloading", string:concat(Filename, "_dir")]),
    {ok, Chunks} = file:list_dir(Dir),
    lists:map(fun(X) -> file:delete(filename:join([Path, "downloading", string:concat(Filename, "_dir"), X])) end, Chunks),
    ok = file:del_dir(Dir).

obtener_numero_chunk(Chunk) ->
    ["chunk", X] = string:tokens(Chunk, "_"),
    {N, _} = string:to_integer(X),
    N.
