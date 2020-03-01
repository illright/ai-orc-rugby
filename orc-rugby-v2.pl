field_size(5).
runner(0, 0).
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

:- use_module(library(clpfd)).
:- [knowledge_base].

% State transitioning
state(S), [S] --> [S].
state(S0, S), [S] --> [S0].

num_leaves(Tree, N) :-
      phrase(num_leaves_(Tree), [0], [N]).

num_leaves_(nil) --> state(N0, N), { N #= N0 + 1 }.
num_leaves_(node(_,Left,Right)) -->
        num_leaves_(Left),
        num_leaves_(Right).

solve(Path) :-
  runner(X, Y),
  from_x_y_path(X, Y, Path).


old_move_new(X, Y, up, XN, YN) :-
  XN #= X,
  YN #= Y + 1.
old_move_new(X, Y, down, XN, YN) :-
  XN #= X,
  YN #= Y - 1.
old_move_new(X, Y, left, XN, YN) :-
  XN #= X - 1,
  YN #= Y.
old_move_new(X, Y, right, XN, YN) :-
  XN #= X + 1,
  YN #= Y.


path, [XN-YN, Move] -->
  {
    available_moves(AvailableMoves),
    random_member(Move, AvailableMoves),
    old_move_new(X, Y, Move, XN, YN)
  },
  [Move, X-Y],
  path.


random_search(Path) :-
  runner(X, Y),
  phrase(path, [X-Y], Path).





go_straight(Path) :-
  runner(X, Y),
  phrase(straight_path, [X-Y], PathReversed),
  reverse(PathReversed, Path).

straight_path -->
  [X-Y],
  {
    Y #> 5
  }.

straight_path, [XN-YN] -->
  [X-Y],
  {
    XN #= X,
    YN #= Y + 1
  },
  straight_path.
