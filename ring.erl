-module(ring).
-export([generate/0, empty/1, one/1, include/2, present/1, setpresent/2, before/1, rotate/1, map/2, convert/2]).


generate() -> {[],[]}.


empty({[],[]}) -> true;
empty(_) -> false.

one({[], [_]}) -> true;
one(_) -> false.

include(Item, {[], []}) -> {[], [Item]};
include(Item, {L,R}) -> {[Item|L], R}.

present({[],[]}) -> empty;
present({_, [H|_]}) -> H.

setpresent(_, {[], []}) -> empty;
setpresent(I, {L, [_|T]}) -> {L, [I|T]}.

before({[], []}) -> empty;
before({[], [I]}) -> I;
before({[H|_], _}) -> H.


rotate({[],[]}) -> {[],[]};
rotate({[],[I]}) -> {[],[I]};
rotate({L, [R]}) -> {[R], lists:reverse(L)};
rotate({L, [H|T]}) -> {[H|L], T}.


map(F, {L, R}) -> {lists:map(F, L), lists:map(F, R)}.


convert(F, {L,R}) -> 
	case {lists:convert(F, L), lists:convert(F, R)} of
		{[], []} -> {[],[]};
		{[H],[]} -> {[], [H]};
		{[H|T], []} -> {[H], lists:reverse(T)};
		{[], [H|T]} -> {lists:reverse(T), [H]};
		{LF, RF} -> {LF, RF}
	end.


-include_lib("eunit/include/eunit.hrl").

generate_ring() -> lists:foldl(
	fun(El, Acc) -> include(El, Acc) end,
	generate(),
	lists:seq(1,10)
).

empty_test() ->
	R = generate(),
	?assert(empty(R)).

insert_test() -> 
	R = generate_ring(),

	lists:foldl(
		fun(El, Acc) -> 
			Curr = present(Acc),
			?assertMatch(Curr, El), 
			rotate(Acc)
		end,
		R, lists:seq(1,10)
		).

previous_test() ->
	R = generate_ring(),

	lists:foldl(
		fun(_, {Ring, Prev}) -> 
			Val = before(Ring),
			?assertMatch(Val , Prev), 
			{rotate(Ring), present(Ring)}
		end,
		{R, 10}, lists:seq(1,10)
	).

map_test() ->
	R = generate_ring(),
	M = map(fun(El) -> El + 1 end, R),

	lists:foldl(
		fun(El, Acc) -> 
			Curr = present(Acc),
			?assertMatch(Curr, El + 1), 
			rotate(Acc)
		end,
		M, lists:seq(1,10)
	).

filter_test() ->
	R = generate_ring(),
	F = convert(fun(El) -> El rem 2 /= 0 end, R),

	lists:foldl(
		fun(El, Acc) -> 
			Curr = present(Acc),
			?assertMatch(Curr, El), 
			rotate(Acc)
		end,
		F, lists:seq(1,10,2)
	).