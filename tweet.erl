-module(tweets).
-export([user/1, content/1, time_used/1, include/2, getPage/2]).
-record (tweets, {time_used, user_id, content}).
-define(PAGE_LENGTH, 10).


user(Tweet) -> Tweet#tweets.user_id.
content(Tweet) -> Tweet#tweets.content.
time_used(Tweet) -> Tweet#tweets.time_used.
include(Tweet, [Head|_] = Lst) 
	when Tweet#tweets.time_used >= Head#tweets.time_used -> [Tweet| Lst];
include(Tweet, [Head|Tail]) -> [Head | include(Tweet, Tail)];
include(Tweet, []) -> [Tweet].
getPage(Lst, 0) -> Lst;
getPage(Lst, 1) -> lists:sublist(Lst, ?PAGE_LENGTH);
getPage(Lst, P) -> 
	Start_idx = ((P - 1) * ?PAGE_LENGTH) + 1,
	try   lists:sublist(Lst, Start_idx, ?PAGE_LENGTH)
	catch error:function_clause -> [] 
	end.

-include_lib("eunit/include/eunit.hrl").
order_test() ->
	T1 = tweets:generate(0, "First!"),
	T2 = tweets:generate(0, "Second"),
	T3 = tweets:generate(0, "Last:("),

	L = lists:foldl(
		fun(El, Acc) -> include(El, Acc) end,
		[],
		[T1, T2, T3] 
	),

	?assertMatch([T3, T2, T1], L).

page_test() ->
	L = lists:seq(1, 100),

	?assertMatch(L, getPage(L, 0)),
	?assertMatch([], getPage(L, 20)),
	?assertMatch([1, 2, 3, 4, 5, 6, 7, 8, 9, 10], getPage(L, 1)),	
	?assertMatch([31, 32, 33, 34, 35, 36, 37, 38, 39, 40], getPage(L, 4)).
