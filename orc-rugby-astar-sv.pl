% Convenient alias for exiting the Prolog shell
exit :- halt.

% Make sure the code won't crash on maps that lack humans, orcs, touchdowns.
:- discontiguous(human/2).
:- discontiguous(orc/2).
:- discontiguous(touchdown/2).

moves([
  move_up,
  move_down,
  move_left,
  move_right
]).
passes([
  pass_up,
  pass_right_up,
  pass_right,
  pass_right_down,
  pass_down,
  pass_left_down,
  pass_left,
  pass_left_up
]).
available_actions(Actions) :-
  moves(Moves),
  passes(Passes),
  append(Moves, Passes, Actions).


:- use_module(library(clpfd)).
:- use_module(library(ordsets)).
:- [map, field_utils].


% Relates an action with its type (m for moves, p for passes).
action_type(Action, m) :- moves(Moves), member(Action, Moves).
action_type(Action, p) :- passes(Passes), member(Action, Passes).


% Ensure that we do not add handoffs to the path.
ensure_no_handoff(m, X, Y) -->
  { \+ human(X, Y) },
  [m-X-Y].

ensure_no_handoff(p, X, Y) -->
  [p-X-Y].

ensure_no_handoff(_, X, Y) -->
  { human(X, Y) }.


% Determine whether we still have a pass after the move.
can_pass_after_action(has_pass, p, no_pass).
can_pass_after_action(has_pass, m, has_pass).
can_pass_after_action(no_pass, _, no_pass).



% Extend the model with perceptions from (X; Y)
perceive(PerceivedCells, X, Y, NewPerceivedCells) :-
  XRight #= X + 1,
  XLeft #= X - 1,
  YUp #= Y + 1,
  YDown #= Y - 1,
  include(within_bounds, [X-YUp, X-YDown, XLeft-Y, XRight-Y], AddedCells),
  list_to_ord_set(AddedCells, AddedCellsSet),
  ord_union(PerceivedCells, AddedCellsSet, NewPerceivedCells).


% Compute the chessboard (Chebyshev's) distance between points (XA; YA), (XB; YB).
chessboard_distance(XA, YA, XB, YB, Distance) :-
  Distance #= max(abs(XA - XB), abs(YA - YB)).


% Standing at (X; Y) and preparing for Action, rank the cost of the action.
% Case 1. Penalize out-of-bound cells: 1000
action_heuristic(_VisitedCells, _PerceivedCells, X, Y, Action, 1000) :-
  old_action_new(X, Y, Action, XN, YN),
  \+ within_bounds(XN, YN).


% Standing at (X; Y) and preparing for Action, rank the cost of the action.
% Case 1.1. Penalize passes: 1000
%   We don't want passes for single-block vision since there's no certainty.
action_heuristic(_VisitedCells, _PerceivedCells, _X, _Y, Action, 1000) :-
  passes(Passes),
  member(Action, Passes).


% Standing at (X; Y) and preparing for Action, rank the cost of the action.
% Case 2. Penalize orc cells: 1000
action_heuristic(_VisitedCells, PerceivedCells, X, Y, Action, 1000) :-
  old_action_new(X, Y, Action, XN, YN),
  ord_memberchk(XN-YN, PerceivedCells),
  orc(XN, YN).


% Standing at (X; Y) and preparing for Action, rank the cost of the action.
% Case 3. Reward the touchdown: 0
action_heuristic(_VisitedCells, PerceivedCells, X, Y, Action, 0) :-
  old_action_new(X, Y, Action, XN, YN),
  ord_memberchk(XN-YN, PerceivedCells),
  touchdown(XN, YN).


% Standing at (X; Y) and preparing for Action, rank the cost of the action.
% Case 4. Penalize the visited cells: 1000
action_heuristic(VisitedCells, _PerceivedCells, X, Y, Action, 1000) :-
  old_action_new(X, Y, Action, XN, YN),
  ord_memberchk(XN-YN, VisitedCells).


% Standing at (X; Y) and preparing for Action, rank the cost of the action.
% Case 5. Reward humans (handoffs): 0.25
action_heuristic(VisitedCells, PerceivedCells, X, Y, Action, 0.25) :-
  moves(Moves),
  member(Action, Moves),
  old_action_new(X, Y, Action, XN, YN),
  \+ ord_memberchk(XN-YN, VisitedCells),
  ord_memberchk(XN-YN, PerceivedCells),
  human(XN, YN).


% Standing at (X; Y) and preparing for Action, rank the cost of the action.
% Case 6. Nothing is in the cell: 0.75 (default value)
action_heuristic(VisitedCells, PerceivedCells, X, Y, Action, 0.75) :-
  old_action_new(X, Y, Action, XN, YN),
  ord_memberchk(XN-YN, PerceivedCells),
  \+ ord_memberchk(XN-YN, VisitedCells),
  \+ orc(XN, YN),
  \+ human(XN, YN),
  \+ touchdown(XN, YN).


% Standing at (X; Y) and preparing for Action, rank the cost of the action.
% Case 7. No information about the cell: 0.5 (reward exploration)
action_heuristic(_VisitedCells, PerceivedCells, X, Y, Action, 0.5) :-
  moves(Moves),
  member(Action, Moves),
  old_action_new(X, Y, Action, XN, YN),
  within_bounds(XN, YN),
  \+ ord_memberchk(XN-YN, PerceivedCells).


% Compute the total cost of visiting a cell: move/distance + heuristic.
cost(VisitedCells, PerceivedCells, X, Y, Action, Cost-Action) :-
  action_heuristic(VisitedCells, PerceivedCells, X, Y, Action, Heuristic),
  old_action_new(X, Y, Action, XN, YN),
  chessboard_distance(X, Y, XN, YN, Distance),
  Cost is 1 / Distance + Heuristic.


% Compute the cost of doing an invalid move: not counting distance since the heuristic is large.
cost(VisitedCells, PerceivedCells, X, Y, Action, Heuristic-Action) :-
  action_heuristic(VisitedCells, PerceivedCells, X, Y, Action, Heuristic),
  \+ old_action_new(X, Y, Action, _XN, _YN).


% Case 1: Standing on a touchdown point, do not make any more actions.
actions(X, Y, _CanPass, _XOrigin, _YOrigin, _PerceivedCells, _VisitedCells) -->
  {
    touchdown(X, Y),
    \+ orc(X, Y)
  }.


% Case 2: Path before ends by passing to a human, so no more passes allowed.
actions(X, Y, no_pass, _XOrigin, _YOrigin, PerceivedCells, VisitedCells) -->
  {
    \+ orc(X, Y),
    \+ touchdown(X, Y),
    human(X, Y),
    moves(Moves),
    perceive(PerceivedCells, X, Y, NewPerceivedCells),
    maplist(cost(VisitedCells, NewPerceivedCells, X, Y), Moves, WeightedMoves),
    keysort(WeightedMoves, PrioritizedMoves),
    member(_-NewAction, PrioritizedMoves),
    action_type(NewAction, ActionType),
    old_action_new(X, Y, NewAction, XN, YN),
    within_bounds(XN, YN),
    ord_add_element(VisitedCells, XN-YN, NewVisitedCells)
  },
  ensure_no_handoff(ActionType, XN, YN),
  actions(XN, YN, no_pass, X, Y, NewPerceivedCells, NewVisitedCells).


% Case 3: Path ends by stepping on a human, so the last action of the path should be discarded.
actions(X, Y, has_pass, OX, OY, PerceivedCells, VisitedCells) -->
  {
    \+ orc(X, Y),
    \+ touchdown(X, Y),
    human(X, Y),
    % Make sure that this human is not us
    (dif(X, OX); dif(Y, OY)),
    available_actions(Actions),
    perceive(PerceivedCells, X, Y, NewPerceivedCells),
    maplist(cost(VisitedCells, NewPerceivedCells, X, Y), Actions, WeightedActions),
    keysort(WeightedActions, PrioritizedActions),
    member(_-NewAction, PrioritizedActions),
    old_action_new(X, Y, NewAction, XN, YN),
    % % Disallow passing to (0; 0) (since we only have one pass, this never makes sense)
    % runner(RunnerX, RunnerY),
    % passes(Passes),
    % (
    %   \+ member(NewAction, Passes),
    % ;
    %   (dif(XN, RunnerX); dif(YN, RunnerY))
    % ),
    within_bounds(XN, YN),
    action_type(NewAction, ActionType),
    can_pass_after_action(has_pass, ActionType, CanPass),
    ord_add_element(VisitedCells, XN-YN, NewVisitedCells)
  },
  ensure_no_handoff(ActionType, XN, YN),
  actions(XN, YN, CanPass, XN, YN, NewPerceivedCells, NewVisitedCells).


% Case 4: Path ends on nothing particular
%    4.1: Still have a pass
actions(X, Y, has_pass, OX, OY, PerceivedCells, VisitedCells) -->
  {
    \+ orc(X, Y),
    \+ touchdown(X, Y),
    % Make sure we didn't step on a different human (that is handled in case 3)
    (
      \+ human(X, Y)
    ;
      X = OX, Y = OY
    ),
    % Choose an action from the moves
    available_actions(Actions),
    perceive(PerceivedCells, X, Y, NewPerceivedCells),
    maplist(cost(VisitedCells, NewPerceivedCells, X, Y), Actions, WeightedActions),
    keysort(WeightedActions, PrioritizedActions),
    member(_-NewAction, PrioritizedActions),
    old_action_new(X, Y, NewAction, XN, YN),
    within_bounds(XN, YN),
    action_type(NewAction, ActionType),
    can_pass_after_action(has_pass, ActionType, CanPass),
    ord_add_element(VisitedCells, XN-YN, NewVisitedCells)
  },
  ensure_no_handoff(ActionType, XN, YN),
  actions(XN, YN, CanPass, XN, YN, NewPerceivedCells, NewVisitedCells).


% Case 4: Path ends on nothing particular
%    4.3: Don't have a pass anymore
actions(X, Y, no_pass, OX, OY, PerceivedCells, VisitedCells) -->
  {
    \+ orc(X, Y),
    \+ touchdown(X, Y),
    % Make sure we didn't step on a different human (that is handled in case 3)
    (
      \+ human(X, Y)
    ;
      X = OX, Y = OY
    ),
    % Choose an action from the moves
    moves(Moves),
    perceive(PerceivedCells, X, Y, NewPerceivedCells),
    maplist(cost(VisitedCells, NewPerceivedCells, X, Y), Moves, WeightedMoves),
    keysort(WeightedMoves, PrioritizedMoves),
    member(_-NewAction, PrioritizedMoves),
    old_action_new(X, Y, NewAction, XN, YN),
    within_bounds(XN, YN),
    ord_add_element(VisitedCells, XN-YN, NewVisitedCells)
  },
  ensure_no_handoff(m, XN, YN),
  actions(XN, YN, no_pass, OX, OY, NewPerceivedCells, NewVisitedCells).


% The following two predicates are used for describing output and are taken from here:
%   https://www.metalevel.at/prolog/dcg
format_(Format, Args) -->
  call(format_chars(Format, Args)).

format_chars(Format, Args, Cs0, Cs) :-
  format(chars(Cs0, Cs), Format, Args).


% Describe the path output format
% Case 0: Empty path
path([]) --> [].

% Case 1: The action is a pass
path([p-X-Y | RestOfPath]) -->
  format_("P ~t~w~2+~t~w~2+~n", [X, Y]),
  path(RestOfPath).

% Case 2: The action is a move
path([m-X-Y | RestOfPath]) -->
  format_("  ~t~w~2+~t~w~2+~n", [X, Y]),
  path(RestOfPath).


% Describe the path output format for debugging
% Case 0: Empty path
path_debug([]) --> [].

% Case 1: The path has at least one step
path_debug([Elem | Rest]) -->
  format_("~w~n", [Elem]),
  path_debug(Rest).


% Describe the execution time output format
execution_time(Time) -->
  format_("~g msec~n", [Time]).


% Main goal, initiates the backtracking search
solve :-
  statistics(walltime, _),
  runner(X, Y),
  list_to_ord_set([X-Y], PerceivedCells),
  phrase(actions(X, Y, has_pass, X, Y, PerceivedCells, [X-Y]), Path),
  statistics(walltime, [_ | [ExecutionTime]]),
  !,
  phrase(path(Path), PathString),
  phrase(execution_time(ExecutionTime), TimeString),
  format("~s~s", [PathString, TimeString]).
