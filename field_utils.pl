:- use_module(library(clpfd)).

% Relates the current coordinates with the new ones in accordance to the move.
old_action_new(X, Y, move_up, XN, YN) :-
  XN #= X,
  YN #= Y + 1.
old_action_new(X, Y, move_down, XN, YN) :-
  XN #= X,
  YN #= Y - 1.
old_action_new(X, Y, move_left, XN, YN) :-
  XN #= X - 1,
  YN #= Y.
old_action_new(X, Y, move_right, XN, YN) :-
  XN #= X + 1,
  YN #= Y.

% Relates the current coordinates with the new ones in accordance to the pass.
old_action_new(X, Y, pass_up, XN, YN) :-
  XN #= X,
  human(XN, YN),
  within_bounds(X, Y),
  YN #> Y,
  YO #>= Y,
  YO #=< YN,
  \+ orc(X, YO).
old_action_new(X, Y, pass_down, XN, YN) :-
  XN #= X,
  human(XN, YN),
  within_bounds(X, Y),
  YN #< Y,
  YO #=< Y,
  YO #>= YN,
  \+ orc(X, YO).
old_action_new(X, Y, pass_left, XN, YN) :-
  YN #= Y,
  human(XN, YN),
  within_bounds(X, Y),
  XN #< X,
  XO #=< X,
  XO #>= XN,
  \+ orc(XO, Y).
old_action_new(X, Y, pass_right, XN, YN) :-
  YN #= Y,
  human(XN, YN),
  within_bounds(X, Y),
  XN #> X,
  XO #>= X,
  XO #=< XN,
  \+ orc(XO, Y).
old_action_new(X, Y, pass_right_up, XN, YN) :-
  human(XN, YN),
  within_bounds(X, Y),
  K #> 0,
  XN #= X + K,
  YN #= Y + K,
  KO #>= 0,
  XO #= X + KO,
  YO #= Y + KO,
  \+ orc(XO, YO).
old_action_new(X, Y, pass_right_down, XN, YN) :-
  human(XN, YN),
  within_bounds(X, Y),
  K #> 0,
  XN #= X + K,
  YN #= Y - K,
  KO #>= 0,
  XO #= X + KO,
  YO #= Y - KO,
  \+ orc(XO, YO).
old_action_new(X, Y, pass_left_down, XN, YN) :-
  human(XN, YN),
  within_bounds(X, Y),
  K #> 0,
  XN #= X - K,
  YN #= Y - K,
  KO #>= 0,
  XO #= X - KO,
  YO #= Y - KO,
  \+ orc(XO, YO).
old_action_new(X, Y, pass_left_up, XN, YN) :-
  human(XN, YN),
  within_bounds(X, Y),
  K #> 0,
  XN #= X - K,
  YN #= Y + K,
  KO #>= 0,
  XO #= X - KO,
  YO #= Y + KO,
  \+ orc(XO, YO).


% Checks whether the coordinates are within the field's bounds.
within_bounds(X, Y) :-
  field_size(FieldSize),
  X #>= 0,
  Y #>= 0,
  X #< FieldSize,
  Y #< FieldSize.


% Overload for pairs instead of two separated coordinates.
within_bounds(X-Y) :-
  within_bounds(X, Y).
