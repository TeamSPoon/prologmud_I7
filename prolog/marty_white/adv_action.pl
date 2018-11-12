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
*/



:- dynamic(adv:agent_last_action/3).

time_since_last_action(Agent,When):- 
 (adv:agent_last_action(Agent,_Action,Last),clock_time(T),When is T - Last) *-> true; clock_time(When).

set_last_action(Agent,Action):- 
 clock_time(T),
 retractall(adv:agent_last_action(Agent,_,_)),
 assertz(adv:agent_last_action(Agent,Action,T)).




% drop -> move -> touch
subsetof(touch, touch).
subsetof(move, touch).
subsetof(drop, move).
subsetof(eat, touch).
subsetof(hit, touch).
subsetof(put, drop).
subsetof(give, drop).
subsetof(take, move).
subsetof(throw, drop).
subsetof(open, touch).
subsetof(close, touch).
subsetof(lock, touch).
subsetof(unlock, touch).
subsetof(switch, touch).


% feel <- taste <- smell <- look <- listen (by distance)
subsetof(examine, examine).
subsetof(listen, examine).
subsetof(look, examine).
% in order to smell it you have to at least be in sight distance
subsetof(smell, look).
subsetof(eat, taste).
subsetof(taste, smell).
subsetof(taste, feel).
subsetof(feel, examine).
subsetof(feel, touch).
subsetof(X,Y):- ground(subsetof(X,Y)),X=Y.

subsetof(SpatialVerb1, SpatialVerb2):- compound(SpatialVerb1), compound(SpatialVerb2), !,
 SpatialVerb1=..[Verb1,Arg1|_],
 SpatialVerb2=..[Verb2,Arg2|_],
 subsetof(Verb1, Verb2),
 subsetof(Arg1, Arg2).

subsetof(SpatialVerb, Verb2):- compound(SpatialVerb), functor(SpatialVerb, Verb, _), !,
 subsetof(Verb, Verb2).

subsetof(Verb, SpatialVerb2):- compound(SpatialVerb2), functor(SpatialVerb2, Verb2, _), !,
 subsetof(Verb, Verb2).

% proper subset - C may not be a subset of itself.
psubsetof(A, B):- A==B, !, fail.
psubsetof(A, B) :- subsetof(A, B).
psubsetof(A, C) :-
 subsetof(A, B),
 subsetof(B, C).


maybe_pause(Agent):- console_player(CP),(Agent==CP -> wait_for_input([user_input],_,0) ; true).

do_command(Agent, Action, S0, S1) :-
 quietly((do_metacmd(Agent, Action, S0, S1), 
 redraw_prompt(Agent))),!.

do_command(Agent, Action, _, _) :- set_last_action(Agent,Action), fail.
do_command(Agent, Action, S0, S1) :-
 do_action(Agent, Action, S0, S1), !.
 % nop(redraw_prompt(Agent)).
do_command(Agent, Action, S0, S0) :-
 player_format('Failed or No Such Command: ~w~n', Action), !,
 nop(redraw_prompt(Agent)).

% --------

do_todo(Agent, S0, S0):- 
 declared(memories(Agent, Mem0), S0),member(todo([]),Mem0),!.
do_todo(Agent, S0, S9) :- 
 undeclare(memories(Agent, Mem0), S0, S1),
 forget(todo(OldToDo), Mem0, Mem1),
 append([Action], NewToDo, OldToDo),
 memorize(todo(NewToDo), Mem1, Mem2),
 declare(memories(Agent, Mem2), S1, S2),
 set_last_action(Agent,Action),
 apply_first_arg_state(Agent, do_command(Action), S2, S9).
do_todo(_Agent, S0, S0).

%do_todo_while(Agent, S0, S9) :-
% declared(memories(Agent, Mem0), S0),
% thought(todo(ToDo), Mem0),
% append([Action], NewToDo, OldToDo),



% ---- apply_act( Action, State, NewState)
% where the states also contain Percepts.
% In Inform, actions work in the following order:
% game-wide preconditions
% Player preconditions
% objects-in-vicinity react_before conditions
% room before-conditions
% direct-object before-conditions
% verb
% objects-in-vicinity react_after conditions
% room after-conditions
% direct-object after-conditions
% game-wide after-conditions
% In TADS:
% "verification" methods perferm tests only

action_doer(Action,Agent):- \+ compound(Action),!,current_player(Agent),!.
action_doer(Action,Agent):- functor(Action,Verb,_),verbatum(Verb),current_player(Agent),!.
action_doer(Action,Agent):- arg(1,Action,Agent),nonvar(Agent), \+ preposition(_,Agent),!.
action_doer(Action,Agent):-
  dmust(act_verb_thing_model_sense(Agent, Action, _Verb, _Thing, _Spatial, _Sense)).


do_action(Agent, Action, S0, S3) :-
 quietly_must((
 undeclare(memories(Agent, Mem0), S0, S1),
 copy_term(Action,ActionG),
 numbervars(ActionG,999,_),
 memorize(did(ActionG), Mem0, Mem1),
 declare(memories(Agent, Mem1), S1, S2))),
 dmust_tracing(must_act( Action, S2, S3)), !.
 

trival_act(look(_)).
trival_act(goto(_,_,loc(_,_,_,_))).
trival_act(examine(_,see,_,depth(2))).
trival_act(examine(_,see,_,depth(1))).

apply_act( Action, _State, _NewState):- \+ trival_act(Action),notrace((bugout(apply_act( Action), action))),fail.

apply_act( Action, State, NewState) :- 
 act_verb_thing_model_sense(Agent, Action, _Verb, _Thing, _Spatial, _Sense),
 cant( Action, Reason, State),
 % log2eng(Agent, Reason, Eng),
 queue_agent_percept(Agent, [failure(Action, Reason)], State, NewState), !.

apply_act( Action, S0, S1) :- 
 action_doer(Action,Agent), 
 do_introspect(Agent,Action, Answer, S0),
 queue_agent_percept(Agent, [answer(Answer), Answer], S0, S1), !.
 %player_format('~w~n', [Answer]).

apply_act( Action, State, NewState):- act( Action, State, NewState), !.

apply_act( Action, State, NewState):- fail, 
  action_doer(Action, Agent),
  copy_term(Action,ActionG),
  related(Spatial, child, Agent, Here, State),  
  % queue_local_event(spatial, [attempting(Agent, Action)], [Here], S0, S1),
  act( Action, State, S0), !,
  queue_local_event(Spatial, [emoted(Agent, act, '*'(Here), ActionG)], [Here], S0, NewState).
  
apply_act( Act, State, NewState):- ((cmd_workarround(Act, NewAct) -> Act\==NewAct)), !, apply_act( NewAct, State, NewState).
apply_act( Action, State, State):- notrace((bugout(failed_act( Action), general))),!, \+ tracing,
  current_player(Agent),
  redraw_prompt(Agent).

must_act( Action, State, NewState):- dmust_tracing(apply_act( Action, State, NewState)) *-> ! ; fail.
% must_act( Action, S0, S1) :- rtrace(apply_act( Action, S0, S1)), !.
must_act( Action, S0, S1) :-
 action_doer(Action,Agent), 
 queue_agent_percept(Agent, [failure(Action, unknown_to(Agent,Action))], S0, S1).


:- discontiguous act/3.

act( wait(Agent), State, NewState) :-
 queue_agent_percept(Agent, [time_passes(Agent)], State, NewState).

act( inventory(Agent), State, NewState) :- !, act( examine(Agent, Agent), State, NewState).
/* Spatial = spatial,
 findall(What, related(Spatial, child, What, Agent, State), Inventory),
 queue_agent_percept(Agent, [carrying(Agent, Spatial, Inventory)], State, NewState).
*/
act( look(Agent), S0, S2) :- !, act( examine(Agent, see), S0, S2) .
act( look(Agent, spatial), S0, S2) :- !, act( examine(Agent, see), S0, S2) .
act( examine(Agent), S0, S2) :- !, act( examine(Agent, see), S0, S2).
act( examine(Agent, Sense), S0, S2) :- Sense == spatial, !, act( examine(Agent, see), S0, S2).
act( examine(Agent, Sense), S0, S2) :- 
   is_sense(Sense), !, 
   dmust(related(spatial, child, Agent, Place, S0)),
   act(examine(Agent, Sense, Place), S0, S2).


act( examine(Agent, Object), S0, S2) :- !, act( examine(Agent, see, Object, depth(3)), S0, S2).
act( examine(Agent, Sense, Object), S0, S2) :- act( examine(Agent, Sense, Object, depth(3)), S0, S2).
act( examine(Agent, Sense, Object, Depth), S0, S2) :- act_examine(Agent, Sense, Object, Depth, S0, S2). 
act( Action, S0, S2) :-
 Action=..[Verb,Agent|Args],
 sensory_verb(Sense, Verb), !, 
 NewAction=..[examine,Agent,Sense|Args],act( NewAction, S0, S2).

% Remember that Agent might be on the inside or outside of Object.
act( goto(Agent, Walk, TO), S0, S1):- !,  % loc(Agent, Dir, Relation, Place)
 (act_goto(Agent, Walk, TO, S0, S1)-> !;
 queue_agent_percept(Agent,
    [failure( goto(Agent, Walk, TO), 'can\'t go that way')],
    S0, S1)).


% sim(verb(args...), preconds, effects)
% Agent is substituted for $self.
% preconds are in the implied context of a State.
% In Inform, the following are implied context:
% actor, action, noun, second
% Need:
% actor/agent, verb/action, direct-object/obj1, indirect-object/obj2,
%  preposition-introducing-obj2
%sim( put(Agent, Spatial, Thing,Relation, Where),
% ( related(Spatial, descended, Thing, $self),
%  has_sensory(Spatial, Sense, $self, Where),
%  has_rel(Spatial, Relation, Where),
%  related(Spatial, descended, $self, Here)),
% moveto(Spatial, Thing, Relation, Where, [Here],
%  [cap(subj($self)), person('put the', 'puts a'),
%  Thing, Relation, the, Where, '.'])).

act( take(Agent, Thing), S0, S1) :-
 get_open_traverse(touch, Spatial, OpenTraverse),
 related(Spatial, OpenTraverse, Agent, Here, S0),  % Where is Agent now?
 moveto(Spatial, Thing, held_by, Agent, [Here],
 [silent(subj(Agent)), person('Taken.', [cap(Agent), 'grabs the', Thing, '.'])],
 S0, S1).
%act( get(Thing), State, NewState) :-
% act( take(Agent, Thing), State, NewState).
act( drop(Agent, Thing), State, NewState) :-
 related(Spatial, Relation, Agent, Here, State),
 has_rel(Spatial, Relation, Here, State),
 moveto(Spatial, Thing, Relation, Here, [Here],
 [cap(subj(Agent)), person('drop the', 'drops a'), Thing, '.'], State, NewState).


act( put(Agent, Thing1, Relation, Thing2), State, NewState) :-
 act( put(Agent, spatial, Thing1, Relation, Thing2), State, NewState).

act( put(Agent, Spatial, Thing1, Relation, Dest), State, NewState) :-
 has_rel(Spatial, Relation, Dest, State),
 get_open_traverse(Open, _See, _Traverse, Spatial, OpenTraverse),
 (Relation \= in ; \+ is_state(~(Open), Dest, State)),
 reachable(Spatial, Dest, Agent, State), % what if "under" an "untouchable" thing?
 % OK, put it
 related(Spatial, OpenTraverse, Agent, Here, State),
 moveto(Spatial, Thing1, Relation, Dest, [Here],
  [cap(subj(Agent)), person('put the', 'puts a'), Thing1,
   Relation, the, Dest, '.'],
  State, NewState).

 
act( give(Agent, Thing, Recipient), S0, S9) :-
 has_rel(Spatial, held_by, Recipient, S0),
 reachable(Spatial, Recipient, Agent, S0),
 get_open_traverse(give, Spatial, OpenTraverse),
 % OK, give it
 related(Spatial, OpenTraverse, Agent, Here, S0),
 moveto(Spatial, Thing, held_by, Recipient, [Here],
 msg([cap(subj(Agent)), person([give, Recipient, the], 'gives you a'), Thing, '.']),
 S0, S9).

act( throw(Agent, Thing, at, Target), S0, S9) :-
 equals_efffectly(sense, Sense, see),
 can_sense( Sense, Target, Agent, S0),
 get_open_traverse(_Open, Sense, throw, Spatial, _OpenTraverse),
 % OK, throw it
 related(Spatial, Relation, Agent, Here, S0),
 thrown( Thing, Target, Relation, Here, [Here], S0, S1),
 hit(Agent, Target, Thing, [Here], S1, S9).
act( throw(Agent, Thing, Dir), S0, S9) :-
 related(Spatial, _Relation, Agent, Here, S0),
 related(Spatial, exit(Dir), Here, There, S0),
 has_rel(Spatial, Relation, There, S0),
 thrown( Thing, There, Relation, There, [Here, There], S0, S9).

act( hit(Agent, Thing), S0, S9) :-
 related(spatial, _Relation, Agent, Here, S0),
 hit(Agent, Thing, Agent, [Here], S0, S1),
 queue_agent_percept(Agent, [true, 'OK.'], S1, S9).

act( dig(Agent, Hole, Where, Tool), S0, S9) :-
 memberchk(Hole, [hole, trench, pit, ditch]),
 memberchk(Where, [garden]),
 memberchk(Tool, [shovel, spade]),
 ((
 get_open_traverse(dig, Spatial, OpenTraverse),
 related(Spatial, OpenTraverse, Tool, Agent, S0),
 related(Spatial, in, Agent, Where, S0),
 \+ related(Spatial, _Relation, Hole, Where, S0),
 % OK, dig the hole.
 declare(h(Spatial, in, Hole, Where), S0, S1),
 setprop(Hole, has_rel(Spatial, in, t), S1, S2),
 setprop(Hole, can_be(move, f), S2, S3),
 declare(h(Spatial, in, dirt, Where), S3, S8),
 queue_event(
 [ created(Hole, Where),
  msg([cap(subj(Agent)), person(dig, digs), 'a', Hole, 'in the', Where, '.'])],
 S8, S9))).

act( eat(Agent, Thing), S0, S9) :-
 getprop(Thing, can_be(eat, t), S0),
 undeclare(h(_Spatial, _, Thing, _), S0, S1),
 queue_agent_percept(Agent, [destroyed(Thing), msg('Mmmm, good!')], S1, S9).

act( eat(Agent, Thing), S0, S9) :-
 queue_agent_percept(Agent, [failure(eat(Agent, Thing), msg(['It''s inedible!']))], S0, S9).

/*
act( switch(Open, Thing), S0, S) :-
 act_prevented_by(Open, TF),
 reachable(Spatial, Thing, Agent, S0),
 %getprop(Thing, can_be(open, S0),
 %\+ getprop(Thing, status(open, t), S0),
 Open = open, get_open_traverse(Open, Spatial, OpenTraverse),
 %delprop(Thing, status(Open, f), S0, S1),
 %setprop(Thing, status(open, t), S0, S1),
 setprop(Thing, status(Open, TF), S0, S2),
 related(Spatial, OpenTraverse, Agent, Here, S2),
 queue_local_event(Spatial, [setprop(Thing, status(Open, TF)),[Open,is,TF]], [Here, Thing], S2, S).

act( switch(OnOff, Thing), S0, S) :-
 reachable(Spatial, Thing, Agent, S0),
 getprop(Thing, can_be(switch, t), S0),
 getprop(Thing, effect(switch(OnOff), Term0), S0),
 subst(equivalent, $self, Thing, Term0, Term),
 call(Term, S0, S1),
 queue_agent_percept(Agent, [true, 'OK'], S1, S).
*/
% todo
act_required_posses('lock','key',$agent).
act_required_posses('unlock','key',$agent).

act_change_opposite('lock','unlock').
act_change_opposite('open','close').

act_change_state('lock','locked',t).
act_change_state('open','opened',t).
act_change_state(Unlock,Locked,f):- act_change_state(Lock,Locked,t),act_change_opposite(Lock,Unlock).
act_change_state(switch(on),'powered',t).
act_change_state(switch(off),'powered',f).

act_change_state(switch(Open),Opened,TF):- nonvar(Open), act_change_state(Open,Opened,TF).

% act_prevented_by(Open,Opened,TF):- act_change_state(Open,Opened,TF).
act_prevented_by('open','locked',t).
act_prevented_by('close','locked',t).

act_to_cmd_thing(Agent, OpenThing, Open, Thing) :- 
 OpenThing =.. [Open, Agent, Thing],!.
act_to_cmd_thing(Agent, SwitchOnThing, SwitchOn, Thing) :- 
 SwitchOnThing =.. [Switch, Agent, On, Thing],!,
 SwitchOn=.. [Switch,On].

:- meta_predicate maybe_when(0,0).
:- meta_predicate required_reason(*,0).
:- meta_predicate unless_reason(*,0,*).
maybe_when(If,Then):- If -> Then ; true.
unless_reason(_Agent, Then,_Msg):- Then,!.
unless_reason(Agent,_Then,Msg):- player_format(Agent,'~N~p~n',Msg),!,fail.

required_reason(_Agent, Required):- Required,!.
required_reason(Agent, Required):- simplify_reason(Required,CUZ), player_format(Agent,'~N~p~n',cant( cuz(CUZ))),!,fail.

simplify_reason(_:Required, CUZ):- !, simplify_dbug(Required, CUZ).
simplify_reason(Required, CUZ):- simplify_dbug(Required, CUZ).

act( OpenThing, S0, S) :- 
 act_to_cmd_thing(Agent, OpenThing,Open, Thing), 
 act_change_state(Open, Opened, TF),!,
 dshow_fail((

 maybe_when(psubsetof(Open, touch),
  required_reason(Agent, reachable(Spatial, Thing, Agent, S0))),
 
 %getprop(Thing, can_be(open, S0),
 %\+ getprop(Thing, status(open, t), S0),

 required_reason(Agent, \+ getprop(Thing, can_be(Open, f), S0)),

 ignore(dshow_fail(getprop(Thing, can_be(Open, t), S0))),
 
 forall(act_prevented_by(Open,Locked,Prevented), 
   required_reason(Agent, \+ getprop(Thing, status(Locked, Prevented), S0))),


  %act_verb_thing_model_sense(Agent, OpenThing, Verb, Thing, Spatial, _Sense),

 %delprop(Thing, status(Open, f), S0, S1),
 %setprop(Thing, status(open, t), S0, S1),
 get_open_traverse(Open, Spatial, OpenTraverse),
  related(Spatial, OpenTraverse, Agent, Here, S0),

 apply_forall(
  (getprop(Thing, effect(Open, Term0), S0),
  subst(equivalent,$self, Thing, Term0, Term1),
  subst(equivalent,$agent, Agent, Term1, Term2),
  subst(equivalent,$here, Here, Term2, Term)),
  call(Term),S0,S1),

 setprop(Thing, status(Opened, TF), S1, S2),

 queue_local_event(Spatial, [setprop(Thing, status(Opened, TF)),msg([Thing,is,TF,Opened])], [Here, Thing], S2, S))),!.

% used mainly to debug if things are reachable
act( touch(Agent, Thing), S0, S9) :-
 unless_reason(Agent, reachable(Spatial, Thing, Agent, S0),
   cant( reach(Agent, Spatial, Thing))),
 queue_agent_percept(Agent, [success(touch(Agent, Thing),'Ok.')], S0, S9).

act( print_(Agent, Msg), S0, S1) :-
 related(Spatial, descended, Agent, Here, S0),
 queue_local_event(Spatial, [msg(Msg)], [Here], S0, S1).

%act( say(Message), S0, S1) :-   % undirected message
% related(Spatial, OpenTraverse, Agent, Here, S0),
act( emote(Agent, EmoteType, Object, Message), S0, S1) :- !, % directed message
 dmust((
 action_sensory(EmoteType, Sense),
 sensory_model(Sense, Spatial), 
 can_sense( Sense, Object, Agent, S0),

 get_open_traverse(EmoteType, Spatial, OpenTraverse), related(Spatial, OpenTraverse, Agent, Here, S0), 
 queue_local_event(Spatial, [emoted(Agent, EmoteType, Object, Message)], [Here,Object], S0, S1))).


act(_Agent, true, S, S).




cmd_workarround(VerbObj, VerbObj2):-
 VerbObj=..VerbObjL,
 notrace(cmd_workarround_l(VerbObjL, VerbObjL2)),
 VerbObj2=..VerbObjL2.

cmd_workarround_l([Verb|ObjS], [Verb|ObjS2]):-
 append(ObjS2, ['.'], ObjS).
cmd_workarround_l([Verb|ObjS], [Verb|ObjS2]):- fail,
 append(Left, [L, R|More], ObjS), atom(L), atom(R),
 current_atom(Atom), atom_concat(L, RR, Atom), RR=R,
 append(Left, [Atom|More], ObjS2).
% look(Agent, Spatial) at screendoor
cmd_workarround_l([Verb, Relation|ObjS], [Verb|ObjS]):- is_ignorable(Relation), !.
% look(Agent, Spatial) at screen door
cmd_workarround_l([Verb1|ObjS], [Verb2|ObjS]):- verb_alias(Verb1, Verb2), !.

is_ignorable(Var):- var(Var),!,fail.
is_ignorable(at). is_ignorable(in). is_ignorable(to). is_ignorable(the). is_ignorable(a). is_ignorable(spatial).

verb_alias(look, examine) :- fail.



act_goto( Agent, Walk, loc(Agent, Dir, Relation, Object), S0, S9):- 
  dmust_tracing((act_goto( Agent, Walk, Dir, Relation, Object, S0, S9))).


target_default_prep(There, Relation, S0):-
 has_rel(_Spatial, Relation, There, S0), 
 Relation \= exit(_), !.
target_default_prep(_There, in, _S0).

% go in/on object
act_goto( Agent, Walk, _Dir, Relation, Object, S0, S9) :- nonvar(Object),   
 get_open_traverse(Walk, Spatial, OpenTraverse),
 ignore(target_default_prep(Object, Relation, S0)),
 related(Spatial, OpenTraverse, Agent, Here, S0),
 related(Spatial, OpenTraverse, Object, Here, S0),
 \+ is_state(~(open), Object, S0),
 moveto_verb(Walk, Agent, Here, reverse(Relation), Relation, Object, S0, S9).

% go n/s/e/w/u/d/in/out
act_goto( Agent, Walk, Dir, Relation, There, S0, S9) :- nonvar(Dir), 
 related(Spatial, child, Agent, Here, S0),
 related(Spatial, exit(Dir), Here, There, S0),!,
 %member(Relation, [*, to, at, through, thru]),
 target_default_prep(There,Relation,S0),  
 moveto_verb(Walk, Agent, Here, Dir, Relation, There, S0, S9).

% go in (adjacent) room
act_goto( Agent, Walk, Dir, Relation, There, S0, S9) :- nonvar(There),   
 ignore(target_default_prep(There, Relation, S0)),
 get_open_traverse(Relation, Spatial, OpenTraverse),
 related(Spatial, OpenTraverse, Agent, Here, S0),
 related(Spatial, exit(Dir), Here, There, S0),
 moveto_verb(Walk, Agent, Here, Dir, Relation, There, S0, S9).

 % go to (adjacent) room
act_goto( Agent, Walk, Dir, _To, There, S0, S9) :- nonvar(There),    
 has_rel(Spatial, Relation, There, S0),
 get_open_traverse(goto, Spatial, OpenTraverse),
 related(Spatial, OpenTraverse, Agent, Here, S0),
 related(Spatial, exit(Dir), Here, There, S0),
 moveto_verb(Walk, Agent, Here, Dir, Relation, There, S0, S9).

% [person(ed(Walk), s(Walk)), exiting, to, the, Dir]
moveto_verb(Walk, Agent, Here, Dir, Relation, There) -->  
    with_state(S0, (related(Spatial, exit(RDir), There, Here, S0)-> true ; reverse_dir(Dir,RDir,S0))),
   {nop(dmsg((moveto_verb(Walk, Agent, Here, Dir, Relation, RDir, There))))},
    undeclare(h(_OldSpatial,_OldRel,Agent,Here)),
    declare(h(Spatial, Relation, Agent,There)),
    queue_agent_percept(Agent,[moved( Agent, Here, Relation, There)]),    
    queue_local_event(Spatial, [emoted(Agent, act, '*'(Here), leaving(Agent, Walk, Here, Dir )) ], [Here]),
    queue_local_event(Spatial,[emoted(Agent, act, '*'(There), entering(Agent, Walk, There, RDir )) ], [There]),    
    add_look(Agent).
  

reverse_dir(Dir,RDir,S0):-
 related(Spatial, exit(Dir), Here, There, S0),
 related(Spatial, exit(RDir), There, Here, S0),!.
reverse_dir(Dir,RDir,S0):- 
 related(Spatial, Dir, Here, There, S0),
 related(Spatial, RDir, There, Here, S0),!.
reverse_dir(Dir,reverse(Dir),_).

add_agent_todo(Agent, Action, S0, S9):-  
  undeclare(memories(Agent, Mem0), S0, S1),
  add_todo(Action, Mem0, Mem1),
  declare(memories(Agent, Mem1), S1, S9).

add_look(Agent, S0, S9):- 
  related(_Spatial, inside, Agent, _Somewhere, S0),
  add_agent_todo(Agent, look(Agent), S0, S9).
% add_look(Agent, S1, S9):- dmust(act( look(Agent, spatial), S1, S9)).

