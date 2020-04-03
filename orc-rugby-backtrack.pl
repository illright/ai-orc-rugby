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


:- use_module(library(clpfd)).
:- [map, field_utils].


% Relates an action with its type (m for moves, p for passes).
action_type(Action, m) :- moves(Moves), member(Action, Moves).
action_type(Action, p) :- moves(Passes), member(Action, Passes).


% Ensure that we do not add handoffs to the path.
ensure_no_handoff(m, X, Y) -->
  { \+ human(X, Y) },
  [m-X-Y].

ensure_no_handoff(_, X, Y) -->
  { human(X, Y) }.


% Case 1: Standing on a touchdown point, do not make any more actions.
actions(X, Y, _, _, _) -->
  {
    touchdown(X, Y),
    \+ orc(X, Y)
  }.


% Case 2: Path before ends by passing to a human, so no more passes allowed.
actions(X, Y, no_pass, _, _) -->
  {
    \+ orc(X, Y),
    \+ touchdown(X, Y),
    human(X, Y),
    moves(Moves),
    member(NewAction, Moves),
    action_type(NewAction, ActionType),
    old_action_new(X, Y, NewAction, XN, YN),
    within_bounds(XN, YN)
  },
  ensure_no_handoff(ActionType, XN, YN),
  actions(XN, YN, no_pass, X, Y).


% Case 3: Path ends by stepping on a human, so the last action of the path should be discarded.
%    3.1: The next action will be a move
actions(X, Y, has_pass, OX, OY) -->
  {
    \+ orc(X, Y),
    \+ touchdown(X, Y),
    human(X, Y),
    % Make sure that this human is not us
    (dif(X, OX); dif(Y, OY)),
    moves(Moves),
    member(NewAction, Moves),
    old_action_new(X, Y, NewAction, XN, YN),
    within_bounds(XN, YN)
  },
  ensure_no_handoff(m, XN, YN),
  actions(XN, YN, has_pass, OX, OY).


% Case 3: Path ends by stepping on a human, so the last action of the path should be discarded.
%    3.2: The next action will be a pass
actions(X, Y, has_pass, OX, OY) -->
  {
    \+ orc(X, Y),
    \+ touchdown(X, Y),
    human(X, Y),
    % Make sure that this human is not us
    (dif(X, OX); dif(Y, OY)),
    passes(Passes),
    member(NewAction, Passes),
    old_action_new(X, Y, NewAction, XN, YN),
    % Disallow passing to (0; 0) (since we only have one pass, this never makes sense)
    runner(RunnerX, RunnerY),
    (dif(XN, RunnerX); dif(YN, RunnerY)),
    within_bounds(XN, YN)
  },
  [p-XN-YN],
  actions(XN, YN, no_pass, XN, YN).


% Case 4: Path ends on nothing particular
%    4.1: Still have a pass, but will do a move
actions(X, Y, has_pass, OX, OY) -->
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
    member(NewAction, Moves),
    old_action_new(X, Y, NewAction, XN, YN),
    within_bounds(XN, YN)
  },
  ensure_no_handoff(m, XN, YN),
  actions(XN, YN, has_pass, OX, OY).


% Case 4: Path ends on nothing particular
%    4.2: Still have a pass, will do a pass
actions(X, Y, has_pass, OX, OY) -->
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
    passes(Passes),
    member(NewAction, Passes),
    old_action_new(X, Y, NewAction, XN, YN),
    % Disallow passing to (0; 0) (since we only have one pass, this never makes sense)
    runner(RunnerX, RunnerY),
    (dif(XN, RunnerX); dif(YN, RunnerY)),
    within_bounds(XN, YN)
  },
  [p-XN-YN],
  actions(XN, YN, no_pass, XN, YN).


% Case 4: Path ends on nothing particular
%    4.3: Don't have a pass anymore
actions(X, Y, no_pass, OX, OY) -->
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
    member(NewAction, Moves),
    old_action_new(X, Y, NewAction, XN, YN),
    within_bounds(XN, YN)
  },
  ensure_no_handoff(m, XN, YN),
  actions(XN, YN, no_pass, OX, OY).


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
  field_size(FieldSize),
  % Use iterative deepening to find the shortest solution
  length(Path, Length),
  % The length of the path should never exceed the square of the field size
  (Length #> FieldSize * FieldSize -> !, fail; true),
  phrase(actions(X, Y, has_pass, X, Y), Path),
  statistics(walltime, [_ | [ExecutionTime]]),
  !,
  phrase(path(Path), PathString),
  phrase(execution_time(ExecutionTime), TimeString),
  format("~s~s", [PathString, TimeString]).
