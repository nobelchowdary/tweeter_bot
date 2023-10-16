-module(register).

-export([reg_user/0,rec_msg/1,sign_user/0,users_list/0,user_map/2,subscribeToUser/1,map_pid/1
,logout_user/0]).

reg_user()->
    {ok,[Uname]}=io:fread("Enter Username","~ts"),
    {ok,[PassWord]}=io:fread("Enter Password","~ts"),
    {ok,[Email]}=io:fread("Enter Email","~ts"),
    ServerConnectionId=spawn(list_to_atom("home@nobel"),mainclass,buffer,[]),
    ServerConnectionId ! {Uname,PassWord,Email,self(),register},
    receive
        {Registered}->
            io:format("~s~n",[Registered])    
    end.


rec_msg(Map_pass)->
    receive
        % This function is for Registeration
        {Uname,PassWord,_,Pid,RemoteNodePid}->
            User=maps:find(Uname,Map_pass),
            if
                User==error->
                    NewUserMap=maps:put(Uname,PassWord,Map_pass), 
                    receiveTweet ! {Uname},
                    Pid ! {"User Registered",RemoteNodePid},                  
                    rec_msg(NewUserMap);
                true ->
                    Pid ! {"Issue Occured While Registring",RemoteNodePid},
                    rec_msg(Map_pass) 
            end;
        {Uname,Pass,Pid,RemoteNodePid}->
            UserPassword=maps:find(Uname,Map_pass),
            [Pass,Process]=Pass,
            ListPassWord={ok,Pass},
            if
                UserPassword==ListPassWord-> 
                   map_pid!{Uname,Process,"Morning Mate"}, 
                   Pid ! {"Signed In",RemoteNodePid}; 
                true ->
                    Pid ! {"Wrong Uname or Password",RemoteNodePid} 
            end,
            rec_msg(Map_pass);
        {Uname,Pid}->
            User=maps:find(Uname,Map_pass),
            if
                User==error->
                    Pid ! {"ok"};
                true ->
                    Pid ! {"not ok"}     
            end,
            rec_msg(Map_pass);
        {Pid,RemoteNodePid,_}->
            UserList=maps:to_list(Map_pass),
            Pid ! {UserList,RemoteNodePid},
            rec_msg(Map_pass) 
    end.
sign_user()->
    {ok,[Uname]}=io:fread("Enter Username","~ts"),
    {ok,[PassWord]}=io:fread("Enter Password","~ts"),
    ServerConnectionId=spawn(list_to_atom("home@nobel"),mainclass,buffer,[]),
    persistent_term:put("ServerId", ServerConnectionId),
    register(receive_tweet,spawn(sendreceive,receive_tweet,[])),

    ServerConnectionId!{Uname,[PassWord,whereis(receive_tweet)],self()},   
    receive
        {Registered}->
            if
                Registered=="Signed In"->
                    persistent_term:put("Uname",Uname),
                    persistent_term:put("SignedIn",true);
                true->
                    persistent_term:put("SignedIn",false)      
            end,
            io:format("~s~n",[Registered])  
    end.

users_list()->
    SignedIn=persistent_term:get("SignedIn"),
    if
        SignedIn==true-> 
            RemoteServerId=persistent_term:get("ServerId"),
            RemoteServerId!{self()},   
            receive
                {UserList}->
                    % io:format("~p~n",[Registered])  
                    printList(UserList,1)
            end;
        true->
            io:format("You should sign in to send tweets Call mainclass:new_reg() to complete signin~n")
    end.

user_map(UserSubscriberMap,SubscribersUserMap)->
    receive
    {Uname,CurrentUserName,CurrentUserPid,Pid,RemoteNodePid}->
        ListSubscribedTo=maps:find(CurrentUserName,SubscribersUserMap),
        ListSubscribers=maps:find(Uname,UserSubscriberMap),
        if
            ListSubscribers==error->
                NewUserSubscriberMap=maps:put(Uname,[{CurrentUserName,CurrentUserPid}],UserSubscriberMap),
                Pid ! {"Subscribed",RemoteNodePid},
                if
                    ListSubscribedTo==error ->
                        NewSubscriberUserMap=maps:put(CurrentUserName,[{Uname}],SubscribersUserMap), 

                        user_map(NewUserSubscriberMap,NewSubscriberUserMap);    
                    true ->
                        {ok,SubscribersTo}=ListSubscribedTo,
                        SubscribersTo1=lists:append(SubscribersTo,[{Uname}]),
                        io:format("~p~n",[SubscribersTo1]),
                        NewSubscriberUserMap=maps:put(CurrentUserName,SubscribersTo1,SubscribersUserMap),
                        user_map(NewUserSubscriberMap,NewSubscriberUserMap) 
                end;
            true ->
                {ok,Subscribers}=ListSubscribers,
                Subscribers1=lists:append(Subscribers,[{CurrentUserName,CurrentUserPid}]),
                NewUserSubscriberMap=maps:put(Uname,Subscribers1,UserSubscriberMap),
                Pid ! {"Subscribed",RemoteNodePid},
                if
                    ListSubscribedTo==error ->
                        NewSubscriberUserMap=maps:put(CurrentUserName,[{Uname}],SubscribersUserMap),                       
                        user_map(NewUserSubscriberMap,NewSubscriberUserMap);    
                    true ->
                        {ok,SubscribersTo}=ListSubscribedTo,
                        SubscribersTo1=lists:append(SubscribersTo,[{Uname}]),
                        io:format("~p~n",[SubscribersTo1]),
                        NewSubscriberUserMap=maps:put(CurrentUserName,SubscribersTo1,SubscribersUserMap),
                        user_map(NewUserSubscriberMap,NewSubscriberUserMap) 
                end 
        end;
    {Uname,Pid}->
        ListSubscribers=maps:find(Uname,UserSubscriberMap),
        if
            ListSubscribers==error->
                Pid !{[]};
            true->
                {ok,Subscribers}=ListSubscribers,
                Pid ! {Subscribers}     
        end,         
        user_map(UserSubscriberMap,SubscribersUserMap);
    {Uname,Pid,RemoteNodePid,tweets}->
        ListSubscribersTo=maps:find(Uname,SubscribersUserMap),
        io:format("I am here"),
        if
            ListSubscribersTo==error->
                Pid !{[]};
            true->
                {ok,SubscribersTo}=ListSubscribersTo,
                io:format("~p~n",[SubscribersTo]),
                fromTheTweets(UserSubscriberMap,SubscribersUserMap,
                SubscribersTo,[],1,Pid,RemoteNodePid)
        end,         
        user_map(UserSubscriberMap,SubscribersUserMap)        
    end.  

fromTheTweets(UserSubscriberMap,SubscribersUserMap,SubscribersTo,AllTweets,Index,Pid,RemoteNodePid)->
    if
        Index>length(SubscribersTo) ->
            Pid ! {AllTweets,RemoteNodePid}; 
        true ->
            CurrentUserName=lists:nth(Index,SubscribersTo),
            receiveTweet ! {CurrentUserName,self()},
            receive
                {Tweets}->
                    AppendTweet=[{CurrentUserName,Tweets}],
                    io:format("~p~n",[AppendTweet]),
                    AllTweets1=lists:append(AllTweets,AppendTweet),
                    fromTheTweets(UserSubscriberMap,SubscribersUserMap,SubscribersTo,AllTweets1,Index+1,Pid,RemoteNodePid)
            end       
     end.


printList(UserList,Index)->
    if
        Index>length(UserList)->
            ok;
        true->
            {Uname,_}=lists:nth(Index,UserList),
            io:format("~s~n",[Uname]),
            printList(UserList,Index+1)
    end.
subscribeToUser(Uname)->
    SignedIn=persistent_term:get("SignedIn"),
    if
        SignedIn==true-> 
            RemoteServerId=persistent_term:get("ServerId"),
            RemoteServerId!{Uname,persistent_term:get("Uname"),self(),whereis(receive_tweet)},   
            receive
                {Registered}->
                    io:format("~p~n",[Registered])  
            end;
        true->
            io:format("You should sign in to send tweets Call mainclass:new_reg() to complete signin~n")
    end.
map_pid(UserProcessIdMap)->
    receive
    {Uname,CurrentUserPid,_}->
        NewUserProcessIdMap=maps:put(Uname,CurrentUserPid,UserProcessIdMap),  
        io:format("~p~n",[NewUserProcessIdMap]),              
        map_pid(NewUserProcessIdMap); 
    {Uname,RemoteNodePid,Pid,_}->
        ListSubscribers=maps:find(Uname,UserProcessIdMap),
        if
            ListSubscribers==error->
                Pid ! {"",RemoteNodePid},
                map_pid(UserProcessIdMap); 
            true ->
                NewUserProcessIdMap=maps:remove(Uname,UserProcessIdMap),  
                Pid ! {"SignedOut",RemoteNodePid},    

                map_pid(NewUserProcessIdMap)     
        end;  
    {Uname,Tweet}->
        ListSubscribers=maps:find(Uname,UserProcessIdMap),
        if
            ListSubscribers==error->
                ok;
            true->
                {ok,ProcessId}=ListSubscribers,
                ProcessId ! {Tweet,Uname}   
        end,         
        map_pid(UserProcessIdMap)     
    end.  
logout_user()->
    SignedIn=persistent_term:get("SignedIn"),
    if
        SignedIn==true-> 
            RemoteServerId=persistent_term:get("ServerId"),
            RemoteServerId!{[persistent_term:get("Uname"),self()],signOut},
            receive
                {Registered}->
                    persistent_term:erase("Uname"),
                    io:format("~s~n",[Registered])  
            end;
        true->
            io:format("You should sign in to send tweets Call mainclass:new_reg() to complete signin~n")    
    end.        








