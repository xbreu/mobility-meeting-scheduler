:- use_module(library(clpfd)).

insert(L, E, L) :-
    member(E, L), !.
insert(L, E, [E | L]).

date_to_hours(Dts, Hts) :-
    Hts #= Dts mod 86400.

% New constraint, elements in List, accessed by each index in Indices result
% in the list Values.
% index_access(List, Indices, Values)
indices_access(_, [], []).
indices_access(List, [Index | Indices], [Value | Values]) :-
    element(Index, List, Value),
    indices_access(List, Indices, Values).

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
