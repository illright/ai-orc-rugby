:- dynamic runner/2.

field_size(5).
runner(0, 0, up).
available_moves([
  move_up,
  move_down,
  move_left,
  move_right,
  pass_ball_up,
  pass_ball_up_right,
  pass_ball_right,
  pass_ball_right_down,
  pass_ball_down,
  pass_ball_left_down,
  pass_ball_left,
  pass_ball_left_up
]).

:- [knowledge_base].


get_random_move(Move) :-
  available_moves(AvailableMoves),
  random_member(Move, AvailableMoves).


coordinates_within_field(X, Y) :-
  field_size(FieldSize),
  X >= 0, Y >= 0,
  X < FieldSize, Y < FieldSize.


random_search_scores :-
  runner(X, Y, Facing),
  choose_random_move(X, Y, Facing, []).


do_random_move(move_up, X, Y, Moves) :-
  XN is X,
  YN is Y + 1,
  (
    \+ coordinates_within_field(X, Y),
      get_random_move(Move),
      do_random_move(Move, X, Y, Moves)
  ;
    orc(XN, YN), fail
  ;
    touchdown(XN, YN)
  ;
    human(XN, YN),
      get_random_move(Move),
      do_random_move(Move, XN, YN, Moves)
  ;
    get_random_move(Move),
    do_random_move(Move, XN, YN, [move_up | Moves])
  ).
