-module(usuario).
-include("defs.hrl").

-export([init/4, loop/5, escribir_descargas/2, nombre_fichero/1]).

init(Path, Config, PIDServidor, ID) -> %Path es la carpeta que contiene usuario_i y config.txt
    PIDServidor ! {self(), register},
    receive 
	{PIDServidor, ack} ->
	    ok
    end,
    Dir = string:concat("usuario_", lists:flatten(io_lib:format("~p", [ID]))),
    %Asegurar que existen (o crear) las carpetas usuario_i, usuario_i/completed y usuario_i/downloading
    filelib:ensure_dir(filename:join([Path, Dir, "completed", "a"])),
    filelib:ensure_dir(filename:join([Path, Dir, "downloading", "a"])),
    %Revisar downloading
    {ok, Files} = file:list_dir(filename:join([Path, Dir, "downloading"])),
    escribir_descargas(Files, filename:join([Path, Dir, "files.txt"])), %escribe en files.txt los archivos que se estan descargando
    PidLector = spawn(lector, init, [self(), filename:join(Path, Dir)]), %lector parte de usuario_i como path
    loop(Config, {[], []}, PIDServidor, PidLector, filename:join(Path, Dir)).

loop(Config, {DownloadProcesses, SeedProcesses}, PIDServidor, PidLector, Path) -> %Path es usuario_i
    receive
	{PidLector, download, Filename} ->
	    N = length(DownloadProcesses),
	    case N < Config#config.maxdownload of
		true ->
		    PidLector ! {self(), accepted, Filename},
		    PidDownload = spawn(download, init, [Path, Config, Filename, self(), PIDServidor]), %Path es usuario_i
		    loop(Config, {DownloadProcesses ++ [PidDownload], SeedProcesses}, PIDServidor, PidLector, Path);
		false ->
		    PidLector ! {self(), rejected, Filename},
		    loop(Config, {DownloadProcesses, SeedProcesses}, PIDServidor, PidLector, Path)
	    end;
	{PID, seed, Filename} -> 
	    N = length(SeedProcesses),
	    case (N < Config#config.maxseed) and filelib:is_file(filename:join([Path, "completed", Filename])) of 
		true ->
		    PidSeed = spawn(seed, init, [Path, Config, Filename, self(), PID]),
		    loop(Config, {DownloadProcesses, SeedProcesses ++ [PidSeed]}, PIDServidor, PidLector, Path);
		false ->
		    loop(Config, {DownloadProcesses, SeedProcesses}, PIDServidor, PidLector, Path) 
	    end;
	{PID, endseed} ->
	    loop(Config, {DownloadProcesses, lists:delete(PID, SeedProcesses)}, PIDServidor, PidLector, Path);
	{PID, enddownload} ->
	    loop(Config, {lists:delete(PID, DownloadProcesses), SeedProcesses}, PIDServidor, PidLector, Path);
	close -> 
	    lists:map(fun(X) -> X ! close end, DownloadProcesses),
	    lists:map(fun(X) -> X ! close end, SeedProcesses),
	    PidLector ! close
    end.

escribir_descargas(Files, File) ->
    {ok, F} = file:open(File, [append]),
    lists:map(fun(X) -> file:write(F, string:concat(nombre_fichero(X), "\n")) end, Files),
    file:close(F).

nombre_fichero(Dir) ->
    [Name, "dir"] = string:tokens(Dir, "_"),
    Name.
