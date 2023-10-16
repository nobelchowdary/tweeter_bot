-module(mainclass).

-export([new_reg/0,start_tweeter/0,buffer/0,new_tweet/0,users_list/0,subscribe/0,signInOut/0,
myMentions/0,hashing_query/0,subscribe_tweets/0]).

new_reg()->
    io:format("~s~n",["Hi, Welcome to Tweeter"]),
    {ok,[Sign_in]}=io:fread("Enter S for signin or R for register","~ts"),
    if
        (Sign_in=="S")->
            register:sign_user();
        true->
            register:reg_user()
    end.
buffer()->
    receive
        % for Sign_in
        {Uname,Pass,Pid}->
            userregister ! {Uname,Pass,self(),Pid};
        % for Registeration    
        {Uname,PassWord,Email,Pid,register}->
            userregister ! {Uname,PassWord,Email,self(),Pid};
        % For receiving user's tweets and quering them        
        {Uname,Tweet,Pid,tweets}->
            if
                Uname==querying ->
                    hashTagMap!{Tweet,self(),Pid}; 
                Uname==queryingSubscribedTweets->
                    % Tweet is Uname
                    subscribeToUser!{Tweet,self(),Pid,tweets}; 
                true ->
                 receiveTweet !{Uname,Tweet,self(),Pid} 
            end;
        {Uname,Pid}->
            if 
                Pid==signOut->
                    [UserName1,RemoteNodePid]=Uname,
                    map_pid!{UserName1,RemoteNodePid,self(),randomShitAgain};
                true->
                 receiveTweet !{Uname,self(),Pid}
            end;     
        {Pid}->
            userregister ! {self(),Pid,"Hello"};    
        {Uname,CurrrentUserName,Pid,PidOfReceive}->
            subscribeToUser ! {Uname,CurrrentUserName,PidOfReceive,self(),Pid}
    end,
    receive
        {Message,Pid1}->
            Pid1 ! {Message},
            buffer()        
    end.    
start_tweeter()->
    List1 = [{"a","sample"}],
    List2=[{"nobel",["hi"]}],
    List3=[{"#Cr7","Good Player is #Cr7"}],
    List4=[{"a",[]}],
    List5=[{"Il","Random"}],
    Map1 = maps:from_list(List1),
    Map2 = maps:from_list(List2),
    Map3= maps:from_list(List3),
    Map4=maps:from_list(List4),
    Map6=maps:from_list(List4),
    Map5=maps:from_list(List5),
    register(userregister,spawn(list_to_atom("home@nobel"),register,rec_msg,[Map1])),
    register(receiveTweet,spawn(list_to_atom("home@nobel"),sendreceive,receive_tweet,[Map2])),
    register(hashTagMap,spawn(list_to_atom("home@nobel"),sendreceive,hashtag_tweet,[Map3])),
    register(subscribeToUser,spawn(list_to_atom("home@nobel"),register,user_map,[Map4,Map6])),
    register(map_pid,spawn(list_to_atom("home@nobel"),register,map_pid,[Map5])).
new_tweet()->
    Tweet1=io:get_line("Enter Your Tweet "),
    Tweet=lists:nth(1,string:tokens(Tweet1,"\n")),
    try sendreceive:transfer_tweet(Tweet)
    catch 
    error:_ -> 
      io:format("User Not Signed in~n") 
    end.   
users_list()->
    spawn(register,users_list,[]).  
subscribe()->
    UserName1=io:get_line("Enter User You want to subscribe to"),
    Uname=lists:nth(1,string:tokens(UserName1,"\n")),
    register:subscribeToUser(Uname).
signInOut()->
    register:logout_user().
myMentions()->
    sendreceive:myMentions().
hashing_query()->
    HashTag=io:get_line("Enter HashTag you want to query"),
    HashTag1=lists:nth(1,string:tokens(HashTag,"\n")),
    sendreceive:hashing_query(HashTag1).
subscribe_tweets()->
    sendreceive:subscribe_tweets().   




