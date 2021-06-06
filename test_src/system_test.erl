%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description :  
%%% 
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(system_test).   
   
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
%-include_lib("eunit/include/eunit.hrl").
%% --------------------------------------------------------------------

-define(GitAppCatalogPath,"https://github.com/joq62/catalog.git").
-define(GitAppCatalogCmd,"git clone https://github.com/joq62/catalog.git").
-define(CatalogFileName,"application.catalog").
-define(CatalogDir,"catalog").


%% External exports
-export([start/0]). 


%% ====================================================================
%% External functions
%% ====================================================================


%% --------------------------------------------------------------------
%% Function:tes cases
%% Description: List of test cases 
%% Returns: non
%% --------------------------------------------------------------------
start()->
    io:format("~p~n",[{"Start setup",?MODULE,?FUNCTION_NAME,?LINE}]),
    ok=setup(),
    io:format("~p~n",[{"Stop setup",?MODULE,?FUNCTION_NAME,?LINE}]),

    io:format("~p~n",[{"Start pass_0()",?MODULE,?FUNCTION_NAME,?LINE}]),
    ok=pass_0(),
    io:format("~p~n",[{"Stop pass_0()",?MODULE,?FUNCTION_NAME,?LINE}]),

  %  io:format("~p~n",[{"Start pass_1()",?MODULE,?FUNCTION_NAME,?LINE}]),
  %  ok=pass_1(),
  %  io:format("~p~n",[{"Stop pass_1()",?MODULE,?FUNCTION_NAME,?LINE}]),

%    io:format("~p~n",[{"Start pass_2()",?MODULE,?FUNCTION_NAME,?LINE}]),
%    ok=pass_2(),
%    io:format("~p~n",[{"Stop pass_2()",?MODULE,?FUNCTION_NAME,?LINE}]),

%    io:format("~p~n",[{"Start pass_3()",?MODULE,?FUNCTION_NAME,?LINE}]),
%    ok=pass_3(),
%    io:format("~p~n",[{"Stop pass_3()",?MODULE,?FUNCTION_NAME,?LINE}]),

  %  io:format("~p~n",[{"Start pass_4()",?MODULE,?FUNCTION_NAME,?LINE}]),
  %  ok=pass_4(),
  %  io:format("~p~n",[{"Stop pass_4()",?MODULE,?FUNCTION_NAME,?LINE}]),

  %  io:format("~p~n",[{"Start pass_5()",?MODULE,?FUNCTION_NAME,?LINE}]),
  %  ok=pass_5(),
  %  io:format("~p~n",[{"Stop pass_5()",?MODULE,?FUNCTION_NAME,?LINE}]),
 
    
   
      %% End application tests
    io:format("~p~n",[{"Start cleanup",?MODULE,?FUNCTION_NAME,?LINE}]),
    ok=cleanup(),
    io:format("~p~n",[{"Stop cleaup",?MODULE,?FUNCTION_NAME,?LINE}]),
   
    io:format("------>"++atom_to_list(?MODULE)++" ENDED SUCCESSFUL ---------"),
    ok.


%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
pass_0()->
    % Decide which host to use as leader Host info
    HostId="c0",Ip="192.168.0.200",SshPort=22,
    UId="joq62",Pwd="festum01",
    % Set num controller nodes, cluster name , cookie , hosts list

   
    %% Create unique node name
  %  UniqueString=integer_to_list(erlang:system_time(second)),
    UniqueString="1",
    UniqueDir="controller_"++UniqueString,
    UniqueNodeName= list_to_atom(UniqueDir++"@"++HostId),
    UniqueNodeNameStr= UniqueDir++"@"++HostId,
    ssh:start(),
    rpc:call(UniqueNodeName,init,stop,[],2000),
    rpc:call(node(),my_ssh,ssh_send,[Ip,SshPort,UId,Pwd,"rm -rf controller_1",1*5000],2*5000),
    
    % Start an erlang vm on this host
    Cookie = "abc",
  %  ErlCmd="erl -pa "++UniqueDir++"/"++"*"++"ebin"++" -sname "++UniqueDir++" -detached"++" -setcookie "++Cookie,
    ErlCmd="erl "++" -sname "++UniqueDir++" -detached"++" -setcookie "++Cookie,
    Result=rpc:call(node(),my_ssh,ssh_send,[Ip,SshPort,UId,Pwd,ErlCmd,2*5000],3*5000),
    io:format("Result = ~p~n",[Result]),
    timer:sleep(5000),
    pong=net_adm:ping(UniqueNodeName),

    
    %-- Create the catalog
    GitAppCatalogPath=?GitAppCatalogPath,
    CatalogFileName=?CatalogFileName,
    CatalogDir=filename:join([UniqueDir,?CatalogDir]),
    CatalogFile=filename:join([CatalogDir,CatalogFileName]),
    
    rpc:call(UniqueNodeName,os,cmd,["rm -rf "++CatalogDir],2000),
    rpc:call(UniqueNodeName,os,cmd,["git clone "++GitAppCatalogPath++" "++CatalogDir],2000),
    {ok,CatalogInfo}= rpc:call(UniqueNodeName,file,consult,[CatalogFile],2000),
   % io:format("CatalogInfo = ~p~n",[CatalogInfo]),
    %-- Load Controller
    {"controller",GitPathController}=lists:keyfind("controller",1,CatalogInfo),
    ControllerDir=filename:join([UniqueDir,"controller"]),
    rpc:call(UniqueNodeName,os,cmd,["git clone "++GitPathController++" "++ControllerDir],5000), 
    true=rpc:call(UniqueNodeName,code,add_patha,[filename:join(ControllerDir,"ebin")],2000),

    %-- Load etcd
    {"etcd",GitPathEtcd}=lists:keyfind("etcd",1,CatalogInfo),
    EtcdDir=filename:join([UniqueDir,"etcd"]),
    rpc:call(UniqueNodeName,os,cmd,["git clone "++GitPathEtcd++" "++EtcdDir],5000),    
    true=rpc:call(UniqueNodeName,code,add_patha,[filename:join(EtcdDir,"ebin")],2000),					
    %-- Load support
    {"support",GitPathSupport}=lists:keyfind("support",1,CatalogInfo),
    SupportDir=filename:join([UniqueDir,"support"]),
    rpc:call(UniqueNodeName,os,cmd,["git clone "++GitPathSupport++" "++SupportDir],5000),   
    true=rpc:call(UniqueNodeName,code,add_patha,[filename:join(SupportDir,"ebin")],2000),	
   
    %-----Starta 
    ok=rpc:call(UniqueNodeName,application,start,[support],5000),
    {pong,UniqueNodeName,support}=rpc:call(UniqueNodeName,support,ping,[]),


    application:set_env([{controller,[{is_leader,true},
				{cluster_name,"test_cluster"},
				{cookie,"abc"},
				{num_controllers,3},
				{hosts,["c0","c1"]}]}]),
 

    ok=rpc:call(UniqueNodeName,application,set_env,[
						    [{controller,[{is_leader,true},
								  {cluster_name,"test_cluster"},
								  {cookie,"abc"},
								  {num_controllers,3},
								  {hosts,["c0","c1"]}]}]]),

    ok=rpc:call(UniqueNodeName,application,start,[controller],6*5000),
    timer:sleep(5000),
    {pong,UniqueNodeName,controller}=rpc:call(UniqueNodeName,controller,ping,[]),
    %%-- test purpose
    {ok,Files}=rpc:call(UniqueNodeName,file,list_dir,["controller_1"],2000),
    io:format("Files = ~p~n",[Files]),
    

    

  %  os:cmd("mkdir 
    
    ok.

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
-define(APP,controller). 
pass_1()->
    rpc:call(node(),application,stop,[?APP],10*5000),
    timer:sleep(500),
    application:set_env([{?APP,[{is_leader,true},
				{cluster_name,"test_cluster"},
				{cookie,"abc"},
				{num_controllers,3},
				{hosts,["c0","c1"]}]}]),
    ok=rpc:call(node(),application,start,[?APP],10*5000),
    {pong,_,?APP}=rpc:call(node(),?APP,ping,[],1*5000),	
    ok.

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
pass_2()->
   
    ok.

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
pass_5()->

    ok.

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
pass_3()->
  
    ok.

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
pass_4()->
  
    ok.



%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------

setup()->
 
    ok.


%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% -------------------------------------------------------------------    

cleanup()->
  
    application:stop(controller),
    ok.
%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
