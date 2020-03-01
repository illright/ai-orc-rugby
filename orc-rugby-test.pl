:- dynamic
    getAllPathsRec/2,
    agent/2,
    visited/2.

fieldSize(5).
runner(0, 0).

:- [knowledge_base].


getAllPaths :-
  runner(X, Y),
  getAllPathsRec(X, Y, [], []).

getAllPathsRec(X, Y, Positions, Moves) :-
  hashPos(X, Y, H),
  % Ensure that we haven't visited (X, Y) yet
  \+ member(H, Positions),
  append(Positions, [H], PositionsNew),
  (
    gold(X, Y)
  ,
    print(Moves)
  ;
    move(X, Y, VP, L)
  ).

% Hash H from h(X, Y)
hashPos(X, Y, H) :- fieldSize(Size), H is (X * Size + Y).

% Left
move(X, Y, V, L) :-
    XP is X - 1, XP > 0,
    append(L, [l], LP),
    getAllPathsRec(XP, Y, V, LP).

% Right
move(X, Y, V, L) :-
    XP is X + 1, fieldSize(MS), XP =< MS,
    append(L, [r], LP),
    getAllPathsRec(XP, Y, V, LP).

% Up
move(X, Y, V, L) :-
    YP is Y + 1, fieldSize(MS), YP =< MS,
    append(L, [u], LP),
    getAllPathsRec(X, YP, V, LP).

% Down
move(X, Y, V, L) :-
    YP is Y - 1, YP > 0,
    append(L, [d], LP),
    getAllPathsRec(X, YP, V, LP).
