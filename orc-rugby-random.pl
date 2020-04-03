% Convenient alias for exiting the Prolog shell
exit :- halt.

% Make sure the code won't crash on maps that lack humans, orcs, touchdowns.
:- discontiguous(human/2).
:- discontiguous(orc/2).
:- discontiguous(touchdown/2).

available_actions([
  move_up,
  move_down,
  move_left,
  move_right,
  pass_up,
  pass_right_up,
  pass_right,
  pass_right_down,
  pass_down,
  pass_left_down,
  pass_left,
  pass_left_up
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


% Returns a random action from the available actions, backtracking infinitely
random_action_infinite(Action) :-
  available_actions(AvailableActions),
  repeat,
  random_member(Action, AvailableActions).


% Determines whether the path had a pass action
no_pass_yet([]).
no_pass_yet([_-(Action-_)-_ | Rest]) :-
  passes(Passes),
  \+ member(Action, Passes),
  no_pass_yet(Rest).


% Relates the paths before and after the random action.
% Case 1: Path before ends on a touchdown point, do not make any more actions.
random_action([(X-Y)-Action-Origin | PathBefore], PathAfter) :-
  touchdown(X, Y),
  PathAfter = [(X-Y)-Action-Origin | PathBefore].


% Relates the paths before and after the random action.
% Case 2: Path before ends by passing to a human, so no more passes allowed.
random_action([(X-Y)-(Action-Type)-(OX-OY) | PathBefore], PathAfter) :-
  human(X, Y),
  % Make sure that the last action was a pass
  passes(Passes),
  member(Action, Passes),
  random_action_infinite(NewAction),
  % No more passes allowed
  \+ member(NewAction, Passes),
  old_action_new(X, Y, NewAction, XN, YN),
  within_bounds(XN, YN),
  !,
  random_action(
    [(XN-YN)-(NewAction-regular)-(X-Y), (X-Y)-(Action-Type)-(OX-OY) | PathBefore],
    PathAfter
  ).


% Relates the paths before and after the random action.
% Case 3: Path ends by stepping on a human, so the last action of the path should be discarded.
random_action([(X-Y)-_-(OX-OY) | PathBefore], PathAfter) :-
  runner(RunnerX, RunnerY),
  human(X, Y),
  % Make sure that this human is not us
  (dif(X, OX); dif(Y, OY)),
  passes(Passes),
  random_action_infinite(NewAction),
  old_action_new(X, Y, NewAction, XN, YN),
  % Disallow passing to (0; 0)
  (
    \+ member(NewAction, Passes)
  ;
    (dif(XN, RunnerX); dif(YN, RunnerY)),
    no_pass_yet([(X-Y)-_-(OX-OY) | PathBefore])
  ),
  % If the attempted action is a pass,
  %   do not allow backtracking in case of a failed pass
  (member(NewAction, Passes) -> !; true),
  within_bounds(XN, YN),
  !,
  (
    member(NewAction, Passes)
  ->
    NOX #= XN,
    NOY #= YN
  ;
    NOX #= OX,
    NOY #= OY
  ),
  random_action(
    [(XN-YN)-(NewAction-handoff)-(NOX-NOY) | PathBefore],
    PathAfter
  ).


% Relates the paths before and after the random action.
% Case 4: The runner originates at (0; 0), so passes are still allowed.
random_action([(X-Y)-(Action-Type)-(OX-OY) | PathBefore], PathAfter) :-
  runner(OX, OY),
  \+ orc(X, Y),
  (human(X, Y) -> OX = X, OY = Y; true),
  passes(Passes),
  random_action_infinite(NewAction),
  old_action_new(X, Y, NewAction, XN, YN),
  % Disallow passing to (0; 0)
  (
    \+ member(NewAction, Passes)
  ;
    (dif(XN, OX); dif(YN, OY)),
    no_pass_yet([(X-Y)-(Action-Type)-(OX-OY) | PathBefore])
  ),
  % If the attempted action is a pass,
  %   do not allow backtracking in case of a failed pass
  (member(NewAction, Passes) -> !; true),
  within_bounds(XN, YN),
  !,
  (
    member(NewAction, Passes)
  ->
    NOX #= XN,
    NOY #= YN
  ;
    NOX #= OX,
    NOY #= OY
  ),
  random_action(
    [(XN-YN)-(NewAction-regular)-(NOX-NOY), (X-Y)-(Action-Type)-(OX-OY) | PathBefore],
    PathAfter
  ).


% Relates the paths before and after the random action.
% Case 5: The runner originates at a different spot, so no passes are allowed.
random_action([(X-Y)-(Action-Type)-(OX-OY) | PathBefore], PathAfter) :-
  \+ orc(X, Y),
  passes(Passes),
  random_action_infinite(NewAction),
  old_action_new(X, Y, NewAction, XN, YN),
  \+ member(NewAction, Passes),
  within_bounds(XN, YN),
  !,
  random_action(
    [(XN-YN)-(NewAction-regular)-(OX-OY), (X-Y)-(Action-Type)-(OX-OY) | PathBefore],
    PathAfter
  ).


% Run the first attempt of random search, the resulting path will be in Path
% Fails if the search attempt failed
random_search(1, Path) :-
  runner(X, Y),
  random_action([(X-Y)-(spawn-regular)-(X-Y)], PathReversed),
  reverse(PathReversed, Path),
  !.


% Run the K+1-th attempt of random search and compare the result with the K-th attempt
random_search(AttemptsLeft, BestPath) :-
  AttemptsLeft \== 1,
  runner(X, Y),
  OneLessAttempt #= AttemptsLeft - 1,
  (
    random_action([(X-Y)-(spawn-regular)-(X-Y)], PathReversed),
    reverse(PathReversed, Path),
    length(Path, CurrentPathLength),
    (
      random_search(OneLessAttempt, CurrentBestPath),
      length(CurrentBestPath, CurrentBestPathLength),
      (
        CurrentPathLength >= CurrentBestPathLength,
          BestPath = CurrentBestPath
      ;
        CurrentPathLength < CurrentBestPathLength,
          BestPath = Path
      )
    ;
      BestPath = Path
    )
  ;
    random_search(OneLessAttempt, BestPath)
  ),
  !.


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
path([(X-Y)-(Action-_)-_ | RestOfPath]) -->
  {
    passes(Passes),
    member(Action, Passes)
  },
  format_("P ~t~w~2+~t~w~2+~n", [X, Y]),
  path(RestOfPath).

% Case 2: The action is a move
path([(X-Y)-(Action-_)-_ | RestOfPath]) -->
  {
    passes(Passes),
    \+ member(Action, Passes)
  },
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


% Main goal, initiates the random search
solve :-
  statistics(walltime, _),
  % Exclude the spawnpoint
  random_search(100, [_ | BestPath]),
  statistics(walltime, [_ | [ExecutionTime]]),
  phrase(path(BestPath), PathString),
  phrase(execution_time(ExecutionTime), TimeString),
  !,
  format("~s~s", [PathString, TimeString]).
