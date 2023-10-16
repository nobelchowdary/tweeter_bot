% userView.erl
% Mathijs Saey
% Multicore Programming

% This module creates a custom view.
% This view is reponsible for updating and
% fetching user data

-module(userView).
-export([start/1, new_follower/2, new_subscription/2]).
-export([getFollowers/1, getSubscriptions/1]).

% --------- %
% Interface %
% --------- %

% Start a new group for this user
start(User) -> viewGroup:generate(
	"usr" ++ integer_to_list(account:id(User)),
	fun(Data, {Destination, Tag}) -> readData(Data, Destination, Tag) end,
	fun(Data, {Tag, New}) -> updateData(Data, New, Tag) end,
	User
	).

% Add a follower to a user view.
new_follower(Id, Follower) -> write(Id, {follower, Follower}).

% Add a subscription to a user view.
new_subscription(Id, Subscription) -> write(Id, {subscription, Subscription}).

% Get various user data from a view,
% and wait for the reply.
%
getFollowers(Id) -> 
	read(Id, {self(), follow}),
	receive {follow, Lst} -> Lst end.

getSubscriptions(Id) ->
	read(Id, {self(), subscribe}),
	receive {subscribe, Lst} -> Lst end.

% ----------- %
% Convenience %
% ----------- %

read(Id, Args) -> 
	Name = "usr" ++ integer_to_list(Id),
	viewGroup:read(Name, Args).
write(Id, Args) -> 
	Name = "usr" ++ integer_to_list(Id),
	viewGroup:write(Name, Args).

updateData(Data, New, follower) -> account:new_follower(Data, New);
updateData(Data, New, subscription) -> account:new_subscription(Data, New).

readData(Data, Dest, id) -> Dest ! {id, account:id(Data)}, ok;
readData(Data, Dest, follow) -> Dest ! {follow, account:follow(Data)}, ok;
readData(Data, Dest, subscribe) -> Dest ! {subscribe, account:subscribe(Data)}, ok.

% ---- %
% Test %
% ---- %

-include_lib("eunit/include/eunit.hrl").

basic_test() ->
	A = account:generate(0),
	start(A),

	?assertMatch([], getFollowers(0)),
	?assertMatch([], getSubscriptions(0)),

	new_follower(0, 1),
	new_follower(0, 2),
	new_subscription(0, 3),
	new_subscription(0, 4),

	timer:sleep(500),

	?assertMatch([2,1], getFollowers(0)),
	?assertMatch([4,3], getSubscriptions(0)).