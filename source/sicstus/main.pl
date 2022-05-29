:- use_module(library(clpfd)).
:- use_module(library(lists)).
:- consult('./data/plan.pl').
:- consult('./input.pl').
:- consult('./restrictions.pl').
:- consult('./utils.pl').

main :-
    % Variable creation
    format('Reading input...', []),
    read_data(Data),
    format('Done~n', []),
    create_plans(Data, Plans),

    % Constraints and cost calculation
    format('Creating restrictions...', []),
    restrict_hard_constraints(Data, Plans),
    format('Done~nCalculating cost...', []),
    calculate_cost(Data, Plans, Cost, TotalCost, UsefulTime, AloneTimesAverage),
    format('Done~n', []),

    % Label and output
    flatten(Plans, Variables),
    labeling([time_out(1800000, Result),minimize(Cost)], Variables),
    format('~nSolution~n~n', []),
    % format('\x256D\~12c\x252C\~15c\x252C\~15c\x256E\~n', ["\x2500\", "\x2500\", "\x2500\"]),
    print_plans(Data, Plans),
    % format('\x2570\~12c\x2534\~15c\x2534\~15c\x256F\~n', ["\x2500\", "\x2500\", "\x2500\"]),
    format('~nType: ~p~n', [Result]),
    nth1(1, Plans, Plan1),
    plan_outgoing_trip(Plan1, TripI),
    data_trips(Data, Trips),
    nth1(TripI, Trips, Trip),
    trip_destination(Trip, LocationI),
    data_locations(Data, Locations),
    nth1(LocationI, Locations, Destination),
    format('Destination: ~p~n', [Destination]),
    format('Cost: ~d~n', [Cost]),
    format('Total price: ~d \x20AC\~n', [TotalCost]),
    UsefulTimeHours is (UsefulTime // 3600) mod 24,
    UsefulTimeDays is (UsefulTime // 86400),
    format('Useful time: ~d days and ~d hours~n',
        [UsefulTimeDays, UsefulTimeHours]),
    print_statistics.

print_elements([]) :- !.
print_elements([H | T]) :-
    print(H), nl,
    print_elements(T).

print_plans(_, _, []).
print_plans(Data, I, [P | Ps]) :-
    plan_outgoing_trip(P, To),
    plan_incoming_trip(P, Ti),
    % format('\x2502\ Student ~`0t~d~12| ', [I]),
    % format('\x2502\ Outgoing ~`0t~d~28| ', [To]),
    % format('\x2502\ Incoming ~`0t~d~44| ', [Ti]),
    % format('\x2502\~n', []),
    data_trips(Data, Trips),
    nth1(To, Trips, Outgoing),
    nth1(Ti, Trips, Incoming),
    format('Student ~d:~n', [I]),
    format('    -> Outgoing: ~p~n', [Outgoing]),
    format('    -> Incoming: ~p~n', [Incoming]),
    I1 is I + 1,
    print_plans(Data, I1, Ps).

print_plans(D, Ps) :-
    print_plans(D, 1, Ps).

print_statistics :-
    format('~n~80c~n', ["\x2500\"]),
    format('~nStatistics~n~n', []),
    statistics,
    fd_statistics.
