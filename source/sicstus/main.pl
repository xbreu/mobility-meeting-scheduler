:- consult('./data-structures.pl').
:- consult('./restrictions.pl').
:- consult('./utils.pl').

main :-
    % Variable Creation
    read_data(Data),
    create_plans(Data, Plans),

    % Hard Constraints
    restrict_start_and_end_in_current_city(Data, Plans),
    restrict_middle_location_is_the_same(Data, Plans),
    restrict_same_destination(Data, Plans),

    % Label and Output
    flatten(Plans, Variables),
    print(Variables), nl,
    labeling([], Variables),
    print_plans(Data, Plans).

print_elements([]) :- !.
print_elements([H | T]) :-
    print(H), nl,
    print_elements(T).

print_plans(_, _, []).
print_plans(Data, I, [P | Ps]) :-
    plan_outgoing_trip(P, To),
    plan_incoming_trip(P, Ti),
    format('| Student ~`0t~d~12| | Outgoing ~`0t~d~27| | Incoming ~`0t~d~42| |~n', [I, To, Ti]),
    I1 is I + 1,
    print_plans(Data, I1, Ps).

print_plans(D, Ps) :-
    print_plans(D, 1, Ps).
