:- consult('./input.pl').

object_attribute_value(json(J), K, V) :-
    member(K=V, J).

read_database(data(Fs)) :-
    read_flights_json(Fs).

select_all(data([]), _, Vs) :- !.
select_all(data([R | Rs]), K, Vs) :-
    object_attribute_value(R, K, V),
    member(V, Vs),
    select_all(data(Rs), K, Vs).

% Selects all value of a key in the entire flight database
select_all(Rs, K, Vs) :-
    select_all(Rs, K, Vs).
