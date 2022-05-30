insert(L, E, L) :-
    member(E, L), !.
insert(L, E, [E | L]).

date_to_hours(Dts, Hts) :-
    Hts is Dts mod 86400.

% New constraint, elements in List, accessed by each index in Indices result
% in the list Values.
% index_access(List, Indices, Values)
indices_access(_, [], []).
indices_access(List, [Index | Indices], [Value | Values]) :-
    element(Index, List, Value),
    indices_access(List, Indices, Values).
