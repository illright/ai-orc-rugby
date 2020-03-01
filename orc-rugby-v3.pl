% Convenient alias for exiting the Prolog shell
exit :- halt.

field_size(5).
runner(0, 0).
available_moves([
  move_up,
  move_down,
  move_left,
  move_right,
  pass_up,
  pass_up_right,
  pass_right,
  pass_right_down,
  pass_down,
  pass_left_down,
  pass_left,
  pass_left_up
]).
passes([
  pass_up,
  pass_up_right,
  pass_right,
  pass_right_down,
  pass_down,
  pass_left_down,
  pass_left,
  pass_left_up
]).

:- use_module(library(clpfd)).
:- [map].


% Relates the current coordinates with the new ones in accordance to the move.
% TESTED
old_move_new(X, Y, move_up, XN, YN) :-
  XN #= X,
  YN #= Y + 1.
old_move_new(X, Y, move_down, XN, YN) :-
  XN #= X,
  YN #= Y - 1.
old_move_new(X, Y, move_left, XN, YN) :-
  XN #= X - 1,
  YN #= Y.
old_move_new(X, Y, move_right, XN, YN) :-
  XN #= X + 1,
  YN #= Y.


% Relates the current coordinates with the new ones in accordance to the pass.
% TESTED
old_move_new(X, Y, pass_up, XN, YN) :-
  XN #= X,
  human(XN, YN),
  within_bounds(X, Y),
  YN #> Y,
  YO #>= Y,
  YO #=< YN,
  \+ orc(X, YO).
old_move_new(X, Y, pass_down, XN, YN) :-
  XN #= X,
  human(XN, YN),
  within_bounds(X, Y),
  YN #< Y,
  YO #=< Y,
  YO #>= YN,
  \+ orc(X, YO).
old_move_new(X, Y, pass_left, XN, YN) :-
  YN #= Y,
  human(XN, YN),
  within_bounds(X, Y),
  XN #< X,
  XO #=< X,
  XO #>= XN,
  \+ orc(XO, Y).
old_move_new(X, Y, pass_right, XN, YN) :-
  YN #= Y,
  human(XN, YN),
  within_bounds(X, Y),
  XN #> X,
  XO #>= X,
  XO #=< XN,
  \+ orc(XO, Y).
% TODO: diagonal passes


% Checks whether the coordinates are within the field's bounds
% TESTED
within_bounds(X, Y) :-
  field_size(FieldSize),
  X #>= 0,
  Y #>= 0,
  X #< FieldSize,
  Y #< FieldSize.


% Returns a random move from the available moves, backtracking infinitely
% TESTED
random_move_infinite(Move) :-
  available_moves(AvailableMoves),
  repeat,
  random_member(Move, AvailableMoves).


% Relates the paths before and after the random move.
% Case 1: Path before ends on a touchdown point, do not make any more moves.
random_move([(X-Y)-Move-Origin | PathBefore], PathAfter) :-
  touchdown(X, Y),
  PathAfter = [(X-Y)-Move-Origin | PathBefore].


% Relates the paths before and after the random move.
% Case 2: Path before ends by passing to a human, so no more passes allowed.
random_move([(X-Y)-(Move-Type)-(OX-OY) | PathBefore], PathAfter) :-
  human(X, Y),
  % Make sure that the last move was a pass
  passes(Passes),
  member(Move, Passes),
  random_move_infinite(NewMove),
  writeln(NewMove),
  % No more passes allowed
  \+ member(NewMove, Passes),
  old_move_new(X, Y, NewMove, XN, YN),
  within_bounds(XN, YN),
  !,
  random_move(
    [(XN-YN)-(NewMove-regular)-(X-Y), (X-Y)-(Move-Type)-(OX-OY) | PathBefore],
    PathAfter
  ).


% Relates the paths before and after the random move.
% Case 3: Path ends by stepping on a human, so the last move of the path should be discarded.
random_move([(X-Y)-_-(OX-OY) | PathBefore], PathAfter) :-
  runner(RunnerX, RunnerY),
  human(X, Y),
  % Make sure that this human is not us
  (dif(X, OX); dif(Y, OY)),
  passes(Passes),
  random_move_infinite(NewMove),
  old_move_new(X, Y, NewMove, XN, YN),
  % Disallow passing to (0; 0)
  (
    \+ member(NewMove, Passes)
  ;
    (dif(XN, RunnerX); dif(YN, RunnerY))
  ),
  % If the attempted move is a pass,
  %   do not allow backtracking in case of a failed pass
  (member(NewMove, Passes) -> !; true),
  within_bounds(XN, YN),
  !,
  (
    member(NewMove, Passes)
  ->
    NOX #= XN,
    NOY #= YN
  ;
    NOX #= OX,
    NOY #= OY
  ),
  random_move(
    [(XN-YN)-(NewMove-handoff)-(NOX-NOY) | PathBefore],
    PathAfter
  ).


% Relates the paths before and after the random move.
% Case 4: The runner originates at (0; 0), so passes are still allowed.
random_move([(X-Y)-(Move-Type)-(OX-OY) | PathBefore], PathAfter) :-
  runner(OX, OY),
  \+ orc(X, Y),
  (human(X, Y) -> OX = X, OY = Y; true),
  passes(Passes),
  random_move_infinite(NewMove),
  old_move_new(X, Y, NewMove, XN, YN),
  % Disallow passing to (0; 0)
  (
    \+ member(NewMove, Passes)
  ;
    (dif(XN, OX); dif(YN, OY))
  ),
  % If the attempted move is a pass,
  %   do not allow backtracking in case of a failed pass
  (member(NewMove, Passes) -> !; true),
  within_bounds(XN, YN),
  !,
  (
    member(NewMove, Passes)
  ->
    NOX #= XN,
    NOY #= YN
  ;
    NOX #= OX,
    NOY #= OY
  ),
  random_move(
    [(XN-YN)-(NewMove-regular)-(NOX-NOY), (X-Y)-(Move-Type)-(OX-OY) | PathBefore],
    PathAfter
  ).


% Run the first attempt of random search, the resulting path will be in Path
% Fails if the search attempt failed
random_search(1, Path) :-
  runner(X, Y),
  random_move([(X-Y)-(spawn-regular)-(X-Y)], PathReversed),
  reverse(PathReversed, Path),
  !.


% Run the K+1-th attempt of random search and compare the result with the K-th attempt
random_search(AttemptsLeft, BestPath) :-
  AttemptsLeft \== 1,
  runner(X, Y),
  OneLessAttempt #= AttemptsLeft - 1,
  (
    random_move([(X-Y)-(spawn-regular)-(X-Y)], PathReversed),
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


path([]) --> [].


path([(X-Y)-(Move-_) | RestOfPath]) -->
  {
    passes(Passes),
    member(Move, Passes)
  },
  format_("P ~t~w~2+~t~w~2+~n", [X, Y]),
  path(RestOfPath).


path([(X-Y)-(Move-_) | RestOfPath]) -->
  {
    passes(Passes),
    \+ member(Move, Passes)
  },
  format_("  ~t~w~2+~t~w~2+~n", [X, Y]),
  path(RestOfPath).


path_debug([]) --> [].


path_debug([(X-Y)-(Move-regular) | RestOfPath]) -->
  format_("~t~w~2+~t~w~2+: ~w~n", [X, Y, Move]),
  path_debug(RestOfPath).


path_debug([(X-Y)-(Move-handoff) | RestOfPath]) -->
  format_("~t~w~2+~t~w~2+: ~w (handoff)~n", [X, Y, Move]),
  path_debug(RestOfPath).


path_real_debug([]) --> [].


path_real_debug([Elem | Rest]) -->
  format_("~w~n", [Elem]),
  path_real_debug(Rest).


actual_solve :-
  random_search(100, BestPath),
  phrase(path_real_debug(BestPath), PathString),
  !,
  format("~s", [PathString]).
