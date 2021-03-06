/*
% NomicMUD: A MUD server written in Prolog
% Maintainer: Douglas Miles
% Dec 13, 2035
%
% Bits and pieces:
%
% LogicMOO, Inform7, FROLOG, Guncho, PrologMUD and Marty's Prolog Adventure Prototype
% 
% Copyright (C) 2004 Marty White under the GNU GPL 
% Sept 20,1999 - Douglas Miles
% July 10,1996 - John Eikenberry 
%
% Logicmoo Project changes:
%
% Main file.
%
*/


:- reexport(library(logicmoo_utils_all)).
ludef:- list_undefined([module_class([user,system,library,test,development])]).

:- export(simplify_dbug/2).
simplify_dbug(G,GG):- \+ compound(G),!,GG=G.
simplify_dbug({O},{O}):- !.
simplify_dbug(List,O):-
 ( is_list(List) -> clip_cons(List,'...'(_),O) ;
 ( List = [_|_], append(LeftSide,Open,List),
  ((var(Open);Open \= [_|_])), !, assertion(is_list(LeftSide)),
 clip_cons(LeftSide,'...'(Open),O))).
simplify_dbug(G,GG):- compound_name_arguments(G,F,GL), F\==percept_props, !,
 maplist(simplify_dbug,GL,GGL),!,compound_name_arguments(GG,F,GGL).
simplify_dbug(G,G).              

%:- system:import(simplify_dbug/2).
%:- listing(simplify_dbug/2).


is_state_list(G,_):- \+ compound(G),!,fail.
is_state_list([G1|_],{GG,'...'}):- compound(G1),G1=structure_label(GG),!.
is_state_list([_|G],GG):- is_state_list(G,GG).
clip_cons(G,GG):- is_state_list(G,GG),!.
clip_cons(List,ClipTail,{Len,LeftS,ClipTail}):- 
 length(List,Len),
 MaxLen = 5, Len>MaxLen,
 length(Left,MaxLen),
 append(Left,_,List),!,
 maplist(simplify_dbug,Left,LeftS).
clip_cons(Left,_,List):-maplist(simplify_dbug,Left,List).


found_bug(S0,open_list(Open)) :- \+is_list(S0),
  get_open_segement(S0,Open).
found_bug(S0,duplicated_object(X,R,L)) :-
 append(Left,[prop(X,R)|_],S0),
 member(prop(X,L),Left).

get_open_segement(S0,Open):- append(Left,_,S0),is_list(Left),length(Left,N),N>2,!,append([_,_],S1,S0),get_open_segement(S1,Open).
get_open_segement(S0,S0).


check4bugs(Why, S0):- found_bug(S0,Bug), pprint(S0, always), pprint(check4bugs_found_bug(Why,Bug),always),throw(check4bugs_failed(Bug)).
 % TODO: emergency save of S0, either here or better yet, in a catch().
check4bugs(_, _).



:- meta_predicate reset_prolog_flag(0,*,*,*).
:- meta_predicate reset_prolog_flag(0,*,*).
:- meta_predicate system_default_debug(0).

reset_prolog_flag(YN, Name, SystemValue):- 
  YN -> set_prolog_flag(Name, SystemValue) ; true.

reset_prolog_flag(YN, Name, SystemValue, OverrideValue):-
  YN -> set_prolog_flag(Name, SystemValue)
   ;  set_prolog_flag(Name, OverrideValue).

system_default_debug(YN):-
  reset_prolog_flag(YN, answer_format, '~p', '~q'), 
  reset_prolog_flag(YN, answer_write_options, [quoted(true), portray(true), max_depth(10), spacing(next_argument)], 
   [quoted(true), portray(true), max_depth(4), spacing(next_argument)]), 
  reset_prolog_flag(YN, debugger_write_options, [quoted(true), portray(true), max_depth(10), attributes(portray), spacing(next_argument)], 
   [quoted(true), portray(true), max_depth(4), attributes(portray), spacing(next_argument)]), 
  reset_prolog_flag(YN, print_write_options, [portray(true), quoted(true), numbervars(true)], 
   [portray(true), quoted(true), numbervars(true)]), 

  reset_prolog_flag(YN, backtrace, true), 
  reset_prolog_flag(YN, backtrace_depth, 20, 2000), 
  reset_prolog_flag(YN, backtrace_goal_depth, 3, 4), 
  reset_prolog_flag(YN, backtrace_show_lines, true), 
  reset_prolog_flag(YN, debug, false, true), 
  reset_prolog_flag(YN, debug_on_error, true), 
  reset_prolog_flag(YN, debugger_show_context, false, true), 

  reset_prolog_flag(YN, gc, true), 

  reset_prolog_flag(YN, last_call_optimisation, true, false), 
  reset_prolog_flag(YN, optimise, false), 
  reset_prolog_flag(YN, optimise_debug, default), 

  reset_prolog_flag(YN, prompt_alternatives_on, determinism), 
  reset_prolog_flag(YN, toplevel_goal, default), 
  reset_prolog_flag(YN, toplevel_mode, backtracking), 
  reset_prolog_flag(YN, toplevel_residue_vars, false, true), 
  reset_prolog_flag(YN, toplevel_print_anon, true), 
  reset_prolog_flag(YN, toplevel_print_factorized, false, true), 
  reset_prolog_flag(YN, write_attributes, ignore),

  reset_prolog_flag(YN, warn_override_implicit_import, true), 
  reset_prolog_flag(YN, access_level, user),
  reset_prolog_flag(YN, sandboxed_load, false), 
  reset_prolog_flag(YN, save_history, true), 
  !.

:- system_default_debug(false).

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CODE FILE SECTION
% :- nop(ensure_loaded('adv_debug')).
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

:- module_transparent(dshow_call/1).
:- module_transparent(dshow_true/1).
:- module_transparent(dshow_fail/1).
:- module_transparent(dmust_tracing/1).
:- module_transparent(if_tracing/1).

:- meta_predicate(dmust_tracing(*)).
dmust_tracing(G):- notrace((tracing,cls)),!,must_det(G).
dmust_tracing(G):- call(G).
:- meta_predicate(if_tracing(*)).
if_tracing(G):- tracing -> notrace(G) ; true.


% '$hide'(Pred) :- '$set_predicate_attribute'(Pred, trace, false).
never_trace(_Spec):- prolog_load_context(reloading,true),!.
never_trace(Spec):- '$hide'(Spec),'$iso'(Spec),ignore(trace(Spec, -all)).
:- call(ensure_loaded,library(lists)).
:- never_trace(lists:append(_,_,_)).
:- never_trace(lists:list_to_set/2).
:- never_trace(lists:member_(_,_,_)).
/*
:- never_trace(prolog_debug:assertion(_)).
*/


%:- never_trace(lists:member(_,_)).
%:- never_trace(lists:append(_,_,_)).
:- meta_predicate(dshow_call(*)).
dshow_call((G1,G2)):- !,dshow_fail(G1),dshow_fail(G2).
dshow_call(G):- simplify_dbug(G,GG), (G*->dmsg(success_dshow_call(GG));(dmsg(failed_dshow_call(GG)),!,fail)).

:- meta_predicate(dshow_fail(*)).
dshow_fail('\\+'(G1)):- !, \+ dshow_true(G1).
dshow_fail(G):- simplify_dbug(G,GG), (G*->true;(dmsg(failed_dshow_call(GG)),!,fail)).

:- meta_predicate(dshow_true(*)).
dshow_true('\\+'(G1)):- !, \+ dshow_fail(G1).
dshow_true(G):- simplify_dbug(G,GG),  (G*->dmsg(success_dshow_call(GG));fail).



:- multifile(user:portray/1).
:- dynamic(user:portray/1).
:- discontiguous(user:portray/1).
% user:portray





%:- set_prolog_flag(verbose_load,full).
:- set_prolog_flag(verbose,normal).
%:- set_prolog_flag(verbose_autoload,true).




