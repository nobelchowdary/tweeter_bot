-module(account).
-export([generate/1]).
-export([new_subscription/2, new_follower/2]).
-export([id/1, subscribe/1, follow/1]).
-record (user, {id, subscribe = [], follow = []}).

generate(Id) -> #user{id = Id}.
subscribe(User) -> User#user.subscribe.
follow(User) -> User#user.follow.
id(User) -> User#user.id.

new_subscription(User, Sub) ->
	Subs = subscribe(User),
	New  = [Sub] ++ Subs,
	User#user{subscribe = New}.

new_follower(User, Follower) -> 
	Followers = follow(User),
	New  = [Follower] ++ Followers,
	User#user{follow = New}.