:- consult('./input.pl').

object_attribute_value(json(J), K, V) :-
    member(K=V, J).

main :-
    read_flights_json(Rs),
    % select_all(data(Rs), origin, Vs),
    % print(Vs),
    filter_attributes(data(Rs), [zagreb], origin, data(Rfs)),
    select_all(data(Rfs), origin, Vfs).

select_all(data(Rs), K, Vs) :-
    setof(V, R^(
        member(R, Rs),
        object_attribute_value(R, K, V)
    ), Vs).

filter_attributes(data(D), O, K, data(Df)) :-
    findall(X, (
        member(X, D),
        object_attribute_value(X, K, V),
        member(V, O)
    ), Df).

print_elements([]) :- !.
print_elements([H | T]) :-
    print(H), nl,
    print_elements(T).
