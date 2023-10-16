-module(sendreceive).

-export([transfer_tweet/1,receive_tweet/1,hashtag_tweet/1,parsing_tweet/5,receive_tweet/0,
split_tweet/4,myMentions/0,hashing_query/1,printTweets/2,subscribe_tweets/0]).

transfer_tweet(Tweet)->
    try persistent_term:get("SignedIn")
    catch 
    error:X ->
        io:format("~p~n",[X])
    end,  
    SignedIn=persistent_term:get("SignedIn"),
    if
        SignedIn==true-> 
            RemoteServerId=persistent_term:get("ServerId"),
            RemoteServerId!{persistent_term:get("Uname"),Tweet,self(),tweets},
            receive
                {Registered}->
                    io:format("~s~n",[Registered])  
            end;
        true->
            io:format("You should sign in to send tweets Call mainclass:new_reg() to complete signin~n")
    end. 


receive_tweet(UserTweetMap)->
    receive
        {Uname,Tweet,Pid,RemoteNodePid}->
            ListTweets=maps:find(Uname,UserTweetMap),
            if
                ListTweets==error->
                    Pid ! {"User Not present in Server Database",RemoteNodePid},
                    receive_tweet(UserTweetMap); 
                true ->
                    {ok,Tweets}=ListTweets,
                    io:format("~s~n",[Tweet]),
                    io:format("~p~n",[Tweets]),
                    Tweets1=lists:append(Tweets,[Tweet]),
                    io:format("~p~n",[Tweets1]),
                    NewUserTweetMap=maps:put(Uname,Tweets1,UserTweetMap), 
                    Pid ! {"Tweet Posted",RemoteNodePid},  
                    TweetSplitList=string:split(Tweet," ",all),
                    io:format("~p~n",[TweetSplitList]),
                    parsing_tweet(TweetSplitList,1,Tweet,Uname,"#"),
                    parsing_tweet(TweetSplitList,1,Tweet,Uname,"@"),
                    subscribeToUser ! {Uname,self()},
                    receive
                        {Subscribers}->
                          io:format("Subscribers are ~p~n",[Subscribers]),
                          spawn(sendreceive,split_tweet,[Subscribers,1,Tweet,Uname])
                    end,                  
                    receive_tweet(NewUserTweetMap)  
            end;
         {Uname}->
            NewUserTweetMap=maps:put(Uname,[],UserTweetMap),
            receive_tweet(NewUserTweetMap);
         {UserName1,Pid}->
            {Uname}=UserName1,
            ListTweets=maps:find(Uname,UserTweetMap),
            io:format("Uname=~p~n",[UserTweetMap]),
            if
                ListTweets==error->
                    Pid ! {[]};
                true ->
                    {ok,Tweets}=ListTweets,
                    Pid ! {Tweets}
            end,
            receive_tweet(UserTweetMap); 
         {Uname,Pid,RemoteNodePid}->
            ListTweets=maps:find(Uname,UserTweetMap),
            if
                ListTweets==error->
                    Pid ! {[],RemoteNodePid};
                true ->
                    {ok,Tweets}=ListTweets,
                    io:format("length= ~p~n",[length(Tweets)]),
                    Pid ! {Tweets,RemoteNodePid}
            end,
            receive_tweet(UserTweetMap)

    end. 


hashtag_tweet(HashTagTweetMap)->
   receive
    {HashTag,Tweet,Uname,addnewhashTag}->
        io:format("~s~n",[Tweet]),
        ListTweets=maps:find(HashTag,HashTagTweetMap),
        if
            ListTweets==error->
                NewHashTagTweetMap=maps:put(HashTag,[{Tweet,Uname}],HashTagTweetMap),
                hashtag_tweet(NewHashTagTweetMap); 
            true ->
                {ok,Tweets}=ListTweets,
                io:format("~p~n",[Tweets]),
                Tweets1=lists:append(Tweets,[{Tweet,Uname}]),
                io:format("~p~n",[Tweets1]),
                NewHashTagTweetMap=maps:put(HashTag,Tweets1,HashTagTweetMap),
                % io:format("~p",NewUserTweetMap),                
                hashtag_tweet(NewHashTagTweetMap)  
        end;
     {HashTag,Pid,RemoteNodePid}->
        ListTweets=maps:find(HashTag,HashTagTweetMap),
        if
            ListTweets==error->
                Pid ! {[],RemoteNodePid};
            true ->
                {ok,Tweets}=ListTweets,
                Pid ! {Tweets,RemoteNodePid}
        end,
        hashtag_tweet(HashTagTweetMap)
    end. 
parsing_tweet(SplitTweet,Index,Tweet,Uname,Tag)->
    if
        Index==length(SplitTweet)+1 ->
         ok;
        true ->
            CurrentString=string:find(lists:nth(Index,SplitTweet),Tag,trailing),
            io:format("~s~n",[CurrentString]),
            if
                CurrentString==nomatch ->
                  ok;  
                true ->
                    if
                        Tag=="@" ->
                            Username=string:sub_string(CurrentString,2,length(CurrentString)),
                            map_pid!{Username,Tweet};
                        true ->
                            ok
                    end,
                    hashTagMap ! {CurrentString,Tweet,Uname,addnewhashTag}  
            end,
            parsing_tweet(SplitTweet,Index+1,Tweet,Uname,Tag)
    end.

split_tweet(Subscribers,Index,Tweet,Uname)->
 if
    Index>length(Subscribers)->
            ok;
    true->
        {Username1,_}=lists:nth(Index,Subscribers),
        % io:format("~p~n",[Pid]),
        map_pid!{Username1,Tweet},
        split_tweet(Subscribers,Index+1,Tweet,Uname)
 end.       

receive_tweet()->
    receive
     {Message,Uname}->
        CurrentMessage=Uname++" : "++Message,
        io:format("~s~n",[CurrentMessage]),
        receive_tweet()
    end.
myMentions()->
    RemoteServerId=persistent_term:get("ServerId"),
    UserId="@"++persistent_term:get("Uname"),
    RemoteServerId!{querying,UserId,self(),tweets},
    receive
        {Tweets}->
            printTweets(Tweets,1) 
    end.
hashing_query(Tag)->
    RemoteServerId=persistent_term:get("ServerId"),
    RemoteServerId!{querying,Tag,self(),tweets},
    receive
        {Tweets}->
            printTweets(Tweets,1)  
    end.
printTweets(Tweets,Index)->
    if
        Index>length(Tweets) ->
            ok;
        true ->
            {Tweet,Uname}=lists:nth(Index,Tweets),
            io:format("~p : ~p ~n",[list_to_atom(Uname),list_to_atom(Tweet)]),
            printTweets(Tweets,Index+1)
    end.    
subscribe_tweets()->
    RemoteServerId=persistent_term:get("ServerId"),
    RemoteServerId!{queryingSubscribedTweets,persistent_term:get("Uname"),self(),tweets},
    receive
        {Tweets}->
            io:format("~p~n",[Tweets]) 
    end.




       



    



 