:- use_module(library(clpfd)).
:- consult('./data-structures.pl').

restrict_outgoing_origins(_, [], []).
restrict_outgoing_origins(Data, [S | Ss], [P | Ps]) :-
    data_plan_outgoing_trip(Data, P, T),
    trip_origin(T, O),
    student_city(S, C),
    O #= C.
