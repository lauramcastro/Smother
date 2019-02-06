-module(smother_annotater).

-export([annotate/2, get_forms/1, make_tmp_file/2, get_tmp/0]).

-include_lib("wrangler/include/wrangler.hrl").

annotate(_File, FDict) ->
    io:format("~p~n", [FDict]).

get_forms(Code) ->
    {ok, Ts, _} = erl_scan:string(Code),
    {MTs,ETs,FTs} = sift_terms(split_exprs(Ts,[],[]),{[],[],[]}),
    io:format("~p~n",[{MTs,ETs,FTs}]),
    {ok,MFs} =  erl_parse:parse_form(MTs),
    {ok,EFs} =  erl_parse:parse_form(ETs),
    {ok,FFs} =  erl_parse:parse_form(FTs),
    {MFs,EFs,FFs}.

sift_terms([],{MTs,ETs,FTs}) ->
    {
      lists:flatten(lists:reverse(MTs))
      ,lists:flatten(lists:reverse(ETs))
      ,lists:flatten(lists:reverse(FTs))
    };
sift_terms([[{'-',Line},{atom,Line,module}| _Mod] = M| More], {MTs,ETs,FTs}) ->
    sift_terms(More, {[M|MTs], ETs, FTs});
sift_terms([[{'-',Line},{atom,Line,export} | _Ex] = E| More], {MTs,ETs,FTs}) ->
    sift_terms(More, {MTs, [E|ETs], FTs});
sift_terms([[{'-',Line},{atom,Line,include}| _Inc] = M| More], {MTs,ETs,FTs}) ->
    io:format("Caught ~p~n",[M]),
    sift_terms(More, {[M|MTs], ETs, FTs});
sift_terms([[{'-',Line},{atom,Line,include_lib}| _Inc] = M| More], {MTs,ETs,FTs}) ->
    io:format("Caught ~p~n",[M]),
    sift_terms(More, {[M|MTs], ETs, FTs});
sift_terms([F | More], {MTs,ETs,FTs}) ->
    sift_terms(More, {MTs, ETs, [F|FTs]}).


split_exprs([], Current, Results) ->
    lists:reverse([Current | Results]);
split_exprs([{dot,Line} | More], Current, Results) ->
    split_exprs(More, [], [lists:reverse([{dot,Line}|Current]) | Results]);
split_exprs([E | More], Current, Results) ->
    split_exprs(More, [E | Current], Results).

make_tmp_file(ModName,Code) ->
    FName = get_tmp() ++ atom_to_list(ModName) ++ ".erl",
    io:format("Making ~p~n",[FName]),
    file:write_file(FName,Code++"\n"),
    FName.

get_tmp() ->
    case os:getenv("TMPDIR") of
	false ->
	    case os:getenv("TMP") of
		false ->
		    "/tmp/";
		Dir ->
		    Dir
		end;
	Dir ->
	    Dir
    end.
