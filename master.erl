-module(master).
-include("defs.hrl").

-export([init/1]).

init(Path) -> %Path es la carpeta que contiene usuario_i y config.txt
    %Leer el fichero clave valor config.txt
    {ok, F} = file:open(filename:join(Path, "config.txt"), [read]),
    {ok, "NUsuarios " ++ SNusuarios} = file:read_line(F),
    {ok, "MaxSeed " ++ SMaxSeed} = file:read_line(F),
    {ok, "MaxDownload " ++ SMaxDownload} = file:read_line(F),
    {ok, "TimeOutWaitingSeeder " ++ STimeOutWaitingSeeder} = file:read_line(F),
    {ok, "TimeOutWaitingPetition " ++ STimeOutWaitingPetition} = file:read_line(F),
    {ok, "ChunkSize " ++ SChunkSize} = file:read_line(F),
    {NUsuarios, []} = string:to_integer(string:strip(SNusuarios, both, $\n)),
    {MaxSeed, []} = string:to_integer(string:strip(SMaxSeed, both, $\n)),
    {MaxDownload, []} = string:to_integer(string:strip(SMaxDownload, both, $\n)),
    {TimeOutWaitingSeeder, []} = string:to_integer(string:strip(STimeOutWaitingSeeder, both, $\n)),
    {TimeOutWaitingPetition, []} = string:to_integer(string:strip(STimeOutWaitingPetition, both, $\n)),
    {ChunkSize, []} = string:to_integer(string:strip(SChunkSize, both, $\n)),
    Config = #config{ nusuarios = NUsuarios, 
		      maxseed = MaxSeed,
		      maxdownload = MaxDownload,
		      toseed = TimeOutWaitingSeeder,
		      topetition = TimeOutWaitingPetition,
		      chunksize = ChunkSize },
    file:close(F),
    %Crear un proceso servidor sin parametros
    PidServidor = spawn(servidor, init, []),
    %Crear NUsuarios procesos usuario
    lists:map(fun(Id) -> spawn(usuario, init, [Path, Config, PidServidor, Id]) end, lists:seq(1, NUsuarios)),
    PidServidor.
