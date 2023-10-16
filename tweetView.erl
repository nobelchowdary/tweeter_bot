
-module(tweetView).
-export([start/2, read/4, write/3]).
start(Type, UserId) -> viewGroup:generate(
	atom_to_list(Type) ++ integer_to_list(UserId),
	fun(Data, {Dest, Tag, Page}) -> sendData(Dest, Tag, Data, Page) end,
	fun(Data, {Tweet}) -> tweets:include(Tweet, Data) end,
	[]
	).

read(Type, Id, DestPid, Page) -> 
	Name = atom_to_list(Type) ++ integer_to_list(Id),
	viewGroup:read(Name, {DestPid, Type, Page}).

write(Type, Id, Tweet) -> 
	Name = atom_to_list(Type) ++ integer_to_list(Id),
	viewGroup:write(Name, {Tweet}).


sendData(Dest, Tag, Data, Page) ->
	Dest ! {Tag, tweets:getPage(Data, Page)}.


-include_lib("eunit/include/eunit.hrl").

basic_test() ->
	start(tweets, 0),
	read(tweets, 0, self(), 0),
	T = tweets:generate(0, "No fun allowed"),

	receive
		Empty -> ?assertMatch({tweets, []}, Empty)
	end,

	write(tweets, 0, T),
	timer:sleep(500),

	read(tweets, 0, self(), 0),
	receive
		Data -> ?assertMatch({tweets, [T]}, Data)
	end.