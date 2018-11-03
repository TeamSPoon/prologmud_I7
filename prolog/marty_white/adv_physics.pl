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


in_model(E, L):- member(E, L).
thought_model(E, L):- in_model(model(E), L).


get_open_traverse(Open, Sense, Traverse, Spatial, OpenTraverse):- get_open_traverse(Traverse, Spatial, OpenTraverse),
 nop((ignore(Open=open), ignore(Sense=see))).

get_open_traverse(_Need, Spatial, OpenTraverse):- ignore(OpenTraverse = open_traverse(_Prep, Spatial)).

%% equals_efffectly(Type, Model, Value).
equals_efffectly(sense, see, _).
equals_efffectly(model, spatial, _).
equals_efffectly(_, Value, Value).



% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CODE FILE SECTION
:- nop(ensure_loaded('adv_relation')).
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

never_equal(Sense,Thing):-
 notrace((freeze(Thing, (dmust(Thing\==Sense))), freeze(Sense, (dmust(Thing\==Sense))))).

cant( Action, cant( sense(Agent, Sense, Thing, Why)), State) :-
 never_equal(Sense,Thing),
 act_verb_thing_model_sense(Agent, Action, Verb, Thing, Spatial, Sense),
 psubsetof(Verb, _),
 \+ in_scope(Spatial, Thing, Agent, State),
 (Why = (\+ in_scope(Spatial, Thing, Agent))).


cant( Action, cant( sense(Agent, Sense, Thing, Why)), State) :-
 never_equal(Sense,Thing),
 % sensory_model(Sense, Spatial),
 act_verb_thing_model_sense(Agent, Action, Verb, Thing, _Spatial, Sense),
 psubsetof(Verb, examine(Agent, Sense)),
 \+ can_sense( Sense, Thing, Agent, State),
 (Why = ( \+ can_sense( Sense, Thing, Agent))).

/*
cant( Agent, Action, cant( reach(Agent, Spatial, Thing)), State) :-
 act_verb_thing_model_sense(Agent, Action, Verb, Thing, Spatial, _Sense),
 psubsetof(Verb, touch),
 \+ reachable(Spatial, Thing, Agent, State).
*/

cant( Action, cant( move(Agent, Spatial, Thing)), State) :-
 act_verb_thing_model_sense(Agent, Action, Verb, Thing, Spatial, _Sense),
 psubsetof(Verb, move),
 getprop(Thing, can_be(move, f), State).

cant( Action, musthave( Thing), State) :-
 act_verb_thing_model_sense(Agent, Action, Verb, Thing, Spatial, _Sense),
 get_open_traverse(Verb, Spatial, OpenTraverse),
 psubsetof(Verb, drop),
 \+ related(Spatial, OpenTraverse, Thing, Agent, State).

cant( Action, cant( manipulate(Spatial, self)), _) :-
 Action =.. [Verb, Agent, Agent |_],
 psubsetof(Verb, touch(Spatial)).
cant( take(Agent, Thing), alreadyhave(Thing), State) :-
 related(_Spatial, descended, Thing, Agent, State).
cant( take(Agent, Thing), mustgetout(Thing), State) :-
 related(_Spatial, descended, Agent, Thing, State).
cant( put(_Agent, _Spatial, Thing1, _Prep, Thing1), self_relation( Thing1), _S0).
cant( put(_Agent, Spatial, Thing1, _Prep, Thing2), moibeus_relation( Thing1, Thing2), S0) :-
 related(Spatial, descended, Thing2, Thing1, S0).
cant( throw(_Agent, Thing1, _Prep, Thing1), self_relation( Thing1), _S0).
cant( throw(_Agent, Thing1, _Prep, Thing2), moibeus_relation( Thing1, Thing2), S0) :-
 related(_Spatial, descended, Thing2, Thing1, S0).



cant( look(Agent, Spatial), TooDark, State) :-
 sensory_model_problem_solution(Sense, _Spatial, TooDark, _EmittingLight),
 % Perhaps this should return a logical description along the lines of
 % failure(look(Agent, Spatial), requisite(look(Agent, Spatial), getprop(SomethingNearby, EmittingLight)))
 \+ has_sensory(Spatial, Sense, Agent, State).

% Can always know inventory
%cant( Agent, inventory, TooDark, State) :- equals_efffectly(sense, Sense, look),
% sensory_model_problem_solution(Sense, Spatial, TooDark, _EmittingLight),
% \+ has_sensory(Spatial, Sense, Agent, State).

cant( examine(Agent, Sense, Thing), cant( sense( Agent, Sense, Thing, TooDark)), State) :- equals_efffectly(sense, Sense, see),
 never_equal(Sense,Thing),
 sensory_model_problem_solution(Sense, Spatial, TooDark, _EmittingLight),
 \+ has_sensory(Spatial, Sense, Agent, State).

cant( examine(Agent, Sense, Thing), cant( sense( Agent, Sense, Thing, Why)), State) :-
 never_equal(Sense,Thing),
 \+ can_sense( Sense, Thing, Agent, State),
 (Why = ( \+ can_sense( Sense, Thing, Agent, State))).


cant( goto(Agent, _Walk, _Dir, _Relation, Object), mustdrop(Object), State) :- nonvar(Object),
 related(_Spatial, descended, Object, Agent, State).

cant( EatCmd, cantdothat(Verb), State) :-
 act_verb_thing_model_sense(Agent, EatCmd, Verb, _Thing, _Spatial, _Sense),
 getprop(Agent, can_do(Verb, f), State).

cant( EatCmd, cantdothat_verb(EatVerb, EatCmd), State) :-
 act_verb_thing_model_sense(Agent, EatCmd, EatVerb, _Thing, _Spatial, _Sense),
 getprop(Agent, can_do(EatVerb, f), State).




% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CODE FILE SECTION
:- nop(ensure_loaded('adv_relation')).
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

related_with_prop(Spatial, Prep, Object, Place, Prop, State) :-
 related(Spatial, Prep, Object, Place, State),
 getprop(Object, Prop, State).

is_state(~(Open), Object, State) :- ground(Open),!,
 getprop(Object, state(Open, f), State).
is_state(Open, Object, State) :-
 getprop(Object, state(Open, t), State).
% getprop(Object, can_be(open, State),
% \+ getprop(Object, state(open, t), State).

in_scope(_Spatial, Thing, _Agent, _State) :- Thing == '*', !.
in_scope(Spatial, Thing, Agent, State) :-
 get_open_traverse(_Open, _See, _Traverse, Spatial, OpenTraverse),
 related(Spatial, OpenTraverse, Agent, Here, State),
 (Thing=Here; related(Spatial, OpenTraverse, Thing, Here, State)).
in_scope(Spatial, Thing, Agent, _State):- bugout(pretending_in_scope(Spatial, Thing, Agent)).

reachable(_Spatial, Star, _Agent, _State) :- Star == '*', ! .
reachable(Spatial, Thing, Agent, State) :-
 get_open_traverse(touch, Spatial, OpenTraverse),
 related(Spatial, child, Agent, Here, State), % can't reach out of boxes, etc.
 (Thing=Here; related(Spatial, OpenTraverse, Thing, Here, State)).


% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CODE FILE SECTION
:- nop(ensure_loaded('adv_relation')).
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


subrelation(in, child).
subrelation(on, child).
%subrelation(under, in).
subrelation(reverse(on), child).
subrelation(worn_by, child).
subrelation(held_by, child).

has_rel(Spatial, How, X, State) :-
 getprop(X, has_rel(Spatial, How), State).
has_rel(Spatial, How, X, State) :-
 getprop(X, has_rel(Spatial, Specific), State),
 subrelation(Specific, How).

%related(_Spatial, How, _X, _Y, _State) :- assertion(nonvar(How)), fail.
related(_Spatial, _How, _X, _Y, []) :- !, fail.
related(Spatial, How, X, Y, State):- quietly(related_hl(Spatial, How, X, Y, State)).


related_hl(Spatial, How, X, Y, State) :- declared(h(Spatial, How, X, Y), State).
related_hl(_Spatial, How, _X, _Y, _State) :- var(How), !, fail.
related_hl(Spatial, child, X, Y, State) :- subrelation(How, child), related_hl(Spatial, How, X, Y, State).
related_hl(Spatial, descended, X, Z, State) :-
 related_hl(Spatial, child, X, Z, State).
related_hl(Spatial, descended, X, Z, State) :-
 related_hl(Spatial, child, Y, Z, State),
 related_hl(Spatial, descended, X, Y, State).
related_hl(Spatial, open_traverse(Traverse, Spatial), X, Z, State) :- (nonvar(X);nonvar(Z)),
 get_open_traverse(_Traverse, Spatial, open_traverse(Traverse, Spatial)),
 related_hl(Spatial, child, X, Z, State).
related_hl(Spatial, open_traverse(Traverse, Spatial), X, Z, State) :- !, fail,  (nonvar(X);nonvar(Z)),
 get_open_traverse(Open, _See, _Traverse, Spatial, open_traverse(Traverse, Spatial)),
 related_hl(Spatial, child, Y, Z, State),
 \+ is_state(~(Open), Y, State),
 related_hl(Spatial, open_traverse(Traverse, Spatial), X, Y, State).

related_hl(Spatial, inside, X, Z, State) :- related_hl(Spatial, in, X, Z, State).
related_hl(Spatial, inside, X, Z, State) :- related_hl(Spatial, in, Y, Z, State),
        related_hl(Spatial, descended, X, Y, State).
related_hl(Spatial, exit(out), Inner, Outer, State) :-
 related_hl(Spatial, child, Inner, Outer, State),
 has_rel(Spatial, in, Inner, State),
 has_rel(Spatial, child, Outer, State),
 get_open_traverse(Open, _See, _Traverse, Spatial, _OpenTraverse),
 \+ is_state(~(Open), Inner, State).
related_hl(Spatial, exit(off), Inner, Outer, State) :-
 related_hl(Spatial, child, Inner, Outer, State),
 has_rel(Spatial, on, Inner, State),
 has_rel(Spatial, child, Outer, State).
related_hl(Spatial, exit(escape), Inner, Outer, State) :-
 related_hl(Spatial, child, Inner, Outer, State),
 has_rel(Spatial, child, Inner, State),
 has_rel(Spatial, child, Outer, State).




% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CODE FILE SECTION
:- nop(ensure_loaded('adv_action')).
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

moveto(Spatial, Object, Prep, Dest, Vicinity, Msg, State, S9) :-
 undeclare(h(Spatial, _, Object, Here), State, VoidState),
 declare(h(Spatial, Prep, Object, Dest), VoidState, S2),
 queue_local_event(Spatial, [moved( Object, Here, Prep, Dest), Msg], Vicinity, S2, S9).

moveallto(_Spatial, [], _R, _D, _V, _M, S, S).
moveallto(Spatial, [Object|Tail], Relation, Destination, Vicinity, Msg, S0, S2) :-
 moveto(Spatial, Object, Relation, Destination, Vicinity, Msg, S0, S1),
 moveallto(Spatial, Tail, Relation, Destination, Vicinity, Msg, S1, S2).

disgorge(Spatial, Container, Prep, Here, Vicinity, Msg, S0, S9) :-
 findall(Inner, related(Spatial, child, Inner, Container, S0), Contents),
 bugout('~p contained ~p~n', [Container, Contents], general),
 moveallto(Spatial, Contents, Prep, Here, Vicinity, Msg, S0, S9).
disgorge(_Spatial, _Container, _Prep, _Here, _Vicinity, _Msg, S0, S0).

thrown( Thing, _Target, Prep, Here, Vicinity, S0, S9) :-
 getprop(Thing, fragile(Broken), S0),
 bugout('object ~p is fragile~n', [Thing], general),
 undeclare(h(Spatial, _, Thing, _), S0, S1),
 declare(h(Spatial, Prep, Broken, Here), S1, S2),
 queue_local_event(Spatial, [transformed(Thing, Broken)], Vicinity, S2, S3),
 disgorge(Spatial, Thing, Prep, Here, Vicinity, 'Something falls out.', S3, S9).
thrown( Thing, _Target, Prep, Here, Vicinity, S0, S9) :-
 moveto(spatial, Thing, Prep, Here, Vicinity, 'Thrown.', S0, S9).

hit(Spatial, Target, _Thing, Vicinity, S0, S9) :-
 Spatial = spatial,
 getprop(Target, fragile(Broken), S0),
 bugout('target ~p is fragile~n', [Target], general),
 undeclare(h(Spatial, Prep, Target, Here), S0, S1),
 queue_local_event(Spatial, [transformed(Target, Broken)], Vicinity, S1, S2),
 declare(h(Spatial, Prep, Broken, Here), S2, S3),
 disgorge(Spatial, Target, Prep, Here, Vicinity, 'Something falls out.', S3, S9).
hit(_Spatial, _Target, _Thing, _Vicinity, S0, S0).




act_verb_thing_model_sense(Agent, Action, Verb, Thing, Spatial, Sense):-
 never_equal(Sense,Thing),
 notrace(act_verb_thing_model_sense0(Agent, Action, Verb, Thing, Spatial, Sense)), !.

act_verb_thing_model_sense0(Agent, goto(Agent, _Walk, _Dir, _Rel, Thing), goto, Thing, spatial, see):-!.
act_verb_thing_model_sense0(Agent, look(Agent, spatial), look, *, spatial, see):-!.
act_verb_thing_model_sense0(Agent, look(Agent, spatial, spatial), look, *, spatial, see):-!.
act_verb_thing_model_sense0(Agent, look(Agent), look, *, spatial, see):-!.
act_verb_thing_model_sense0(Agent, look(Agent), look, *, spatial, Sense):- is_sense(Sense), !.

act_verb_thing_model_sense0(Agent, Action, Verb, Thing, W1, Sense):-
  Action=..[Verb,Agent, W1|Rest],
  W1 == spatial, !,
  Action2=..[Verb,Agent|Rest],
  act_verb_thing_model_sense(Agent, Action2, Verb, Thing, _Spatial, Sense).
act_verb_thing_model_sense0(Agent, Action, Verb, Thing, Spatial, Sense):-
  Action=..[Verb,Agent, Sense|Rest],
  is_sense(Sense), !,
  Action2=..[Verb,Agent|Rest],
  act_verb_thing_model_sense0(Agent, Action2, Verb, Thing, Spatial, _Sense).
act_verb_thing_model_sense0(Agent, Action, Verb, Thing, Spatial, Sense):-
  Action=..[Verb,Agent, W1|Rest],
  atom(W1), atom_concat(W2, 'ly', W1), !,
  Action2=..[Verb,Agent, W2|Rest],
  act_verb_thing_model_sense0(Agent, Action2, Verb, Thing, Spatial, Sense).
act_verb_thing_model_sense0(Agent, Action, Verb, Thing, Spatial, Sense):-
  Action=..[Verb,Agent, Prep|Rest],
  preposition(Spatial, Prep), !,
  Action2=..[Verb,Agent|Rest],
  act_verb_thing_model_sense0(Agent, Action2, Verb, Thing, _Spatial, Sense).
act_verb_thing_model_sense0(Agent, Action, Verb, Thing, Spatial, Sense):-
  Action=..[Verb,Agent, Thing|_], !,
  act_verb_thing_model_sense0(Agent, Verb, _UVerb, _UThing, Spatial, Sense).
act_verb_thing_model_sense0(Agent, Action, Verb, '*', Spatial, Sense):-
 Action=..[Verb,Agent], dmust((action_sensory(Verb, Sense), action_model(Verb, Spatial))), !.


