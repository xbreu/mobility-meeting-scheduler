insert(L, E, L) :-
    member(E, L), !.
insert(L, E, [E | L]).

date_to_hours(Dts, Hts) :-
    Hts is Dts mod 86400.
