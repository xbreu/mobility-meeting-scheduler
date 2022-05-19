:- consult('./data-structures.pl').

main :-
    read_data(Data),
    data_students(Data, Students),
    length(Students, N),
    create_plans(N, Plans),
    print(Plans).

% student("budapest", ["05/05/2022", "06/05/2022"], 1, 600, "05:30:00", "23:30:00")
% trip("wien", "zagreb", "09/05/2022, 10:10:00", "09/05/2022, 10:55:00", 45, 212, 0)

print_elements([]) :- !.
print_elements([H | T]) :-
    print(H), nl,
    print_elements(T).
