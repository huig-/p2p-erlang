-module(seed).
-include("defs.hrl").
-include_lib("kernel/include/file.hrl").

-export([init/5, loop/4]).

init(Path, Config, Filename, PidUsuario, PidDownload) -> %Path es usuario_i
    {ok, FileInfo} = file:read_file_info(filename:join([Path, "completed", Filename])),
    FileSize = FileInfo#file_info.size,
    Nfullchunks = FileSize div Config#config.chunksize,
    case (FileSize rem Config#config.chunksize) of
	0 -> Nchunks = Nfullchunks;
	_ -> Nchunks = 1 + Nfullchunks
    end,
    PidDownload ! {self(), iseedyou, Filename, Nchunks},
    loop(PidUsuario, Config, Path, Filename).

loop(PidUsuario, Config, Path, Filename) ->
    receive
	close -> 
	    ok;
	{PidSeed, askchunk, J, Filename} ->
	    Chunk = getChunk(filename:join([Path, "completed", Filename]), Config#config.chunksize, J),
	    PidSeed ! {self(), thechunk, J, Chunk},
	    loop(PidUsuario, Config, Path, Filename)
    after
	Config#config.topetition ->
	    PidUsuario ! {self(), endseed}
    end.

getChunk(Filename, ChunkSize, J) ->
    {ok, F} = file:open(Filename, [read]),
    {ok, _} = file:read(F, ChunkSize * (J-1)),
    {ok, Data} = file:read(F, ChunkSize),
    file:close(F),
    Data.
