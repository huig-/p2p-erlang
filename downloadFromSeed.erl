-module(downloadFromSeed).
-include("defs.hrl").

-export([init/6, chunk_rand/2]).

init(PidDownload, PidSeed, Path, Config, Filename, Nchunks) -> %Path es usuario_i
    {ok, CompletedChunks} = file:list_dir(filename:join([Path, "downloading", string:concat(Filename, "_dir")])), 
    case length(CompletedChunks) == Nchunks of
	true ->
	    PidDownload ! {self(), completed};
	false ->
	    J = chunk_rand(Nchunks, CompletedChunks),
	    PidSeed ! {self(), askchunk, J, Filename},
	    receive 
		close ->
		    ok;
		{PidSeed, thechunk, J, Chunk} -> 
		    {ok, F} = file:open(filename:join([Path, "downloading", string:concat(Filename, "_dir"), string:concat("chunk_", integer_to_list(J))]), [write]),
		    ok = file:write(F, Chunk),
		    file:close(F),
		    init(PidDownload, PidSeed, Path, Config, Filename, Nchunks)
	    after
		Config#config.toseed ->
		    PidDownload ! {self(), timeout}
	    end
    end.    

chunk_rand(Nchunks, CompletedChunks) ->
    LCompletedChunks = [I || {"Chunk", I} <- lists:map(fun(X) -> string:tokens(X, "_") end, CompletedChunks)],
    LChunks = lists:seq(1, Nchunks),
    PossibleChunks = lists:filter(fun(X) -> lists:member(X, LCompletedChunks) == false end, LChunks),
    Index = rand:uniform(length(PossibleChunks)),
    lists:nth(Index, PossibleChunks).
