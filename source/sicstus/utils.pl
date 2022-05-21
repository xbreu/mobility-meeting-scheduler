:- use_module(library(clpfd)).

% True if FlatList is a non-nested version of NestedList.
% flatten(+NestedList, -FlatList)
flatten(List, FlatList) :-
    flatten(List, [], FlatList0),
    !,
    FlatList = FlatList0.

flatten(Var, Tl, [Var|Tl]) :-
    var(Var),
    !.
flatten([], Tl, Tl) :- !.
flatten([Hd|Tl], Tail, List) :-
    !,
    flatten(Hd, FlatHeadTail, List),
    flatten(Tl, Tail, FlatHeadTail).
flatten(NonList, Tl, [NonList|Tl]).

% True if R is a list of the results of the application of the predicate F
% using each element in Xs.
% map(Predicate, Xs, Ys)
map(F, Xs, R) :-
    map(F, Xs, [], R).

map(_, [], A, A).
map(F, [X | Xs], A, R) :-
    call(F, X, Y),
    append(A, [Y], An),
    map(F, Xs, An, R).

% New constraint, elements in List, accessed by each index in Indices result
% in the list Values.
% index_access(List, Indices, Values)
indices_access(_, [], []).
indices_access(List, [Index | Indices], [Value | Values]) :-
    element(Index, List, Value),
    indices_access(List, Indices, Values).
