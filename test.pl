/* sentence --> noun_phrase, verb_phrase.
noun_phrase --> det, noun.
verb_phrase --> verb, noun_phrase.
det --> [the].
det --> [a].
noun --> [cat].
noun --> [bat].
verb --> [eats].

% **IF** B - A is a noun and Z - B is a verb **THEN** A - Z is a sentence
sentence(A,Z) :- noun_phrase(A,B), verb_phrase(B,Z).
noun_phrase(A,Z) :- det(A,B), noun(B,Z).
verb_phrase(A,Z) :- verb(A,B), noun_phrase(B,Z).
det([the|X], X).
det([a|X], X).
noun([cat|X], X).
noun([bat|X], X).
verb([eats|X], X).








tree_nodes(nil, Ls, Ls) --> [].
tree_nodes(node(Name, Left, Right), [_|Ls0], Ls) -->
        tree_nodes(Left, Ls0, Ls1),
        [Name],
        tree_nodes(Right, Ls1, Ls). */


% **IF** B - A is the tree nodes of the left subtree
% **AND** C - B is the current node
% **AND** Z - C is the tree nodes of the right subtree
% **THEN** Z - A is the tree nodes of the entire tree
% current_node(Name, [Name | X], X).
% tree_nodes(nil, A, A).
% tree_nodes(node(Name, Left, Right), [El | A], Z) :-
%         tree_nodes(Left, A, B),
%         current_node(Name, [El | X], X),
%         tree_nodes(Right, B, Z).

tree_nodes(nil, Ls, Ls) --> [].
tree_nodes(node(Name, Left, Right), [_|Ls0], Ls) -->
        tree_nodes(Left, Ls0, Ls1),
        [Name],
        tree_nodes(Right, Ls1, Ls).
