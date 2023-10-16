-module(server).

-export([show_timeline/3,
		 show_tweets/3,
		 tweets/3]).

-spec show_timeline(pid(), integer(), integer()) -> [{tweets, integer(), erlang:time_used(), string()}].
show_timeline(ServerPid, UserId, Page) ->
	ServerPid ! {self(), show_timeline, UserId, Page},
	receive
		{timeline, Timeline} -> Timeline
	end.

-spec show_tweets(pid(), integer(), integer()) -> [{tweets, integer(), erlang:time_used(), string()}].
show_tweets(ServerPid, UserId, Page) ->
	ServerPid ! {self(), show_tweets, UserId, Page},
	receive
		{tweets, Tweets} -> Tweets
	end.


-spec tweets(pid(), integer(), string()) -> erlang:time_used(). 
tweets(ServerPid, UserId, Tweet) ->
	ServerPid ! {self(), tweets, UserId, Tweet},
	receive
		{tweet_accepted, Timestamp} -> Timestamp
	end.
