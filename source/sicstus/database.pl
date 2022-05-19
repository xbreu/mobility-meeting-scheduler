:- consult('./input.pl').

% -----------------------------------------------------------------------------
% Trip structure
% -----------------------------------------------------------------------------

trip_origin(trip(Origin, _, _, _, _, _, _), Origin).
trip_destination(trip(_, Destination, _, _, _, _, _), Destination).
trip_departure(trip(_, _, Departure, _, _, _, _), Departure).
trip_arrival(trip(_, _, _, Arrival, _, _, _), Arrival).
trip_duration(trip(_, _, _, _, Duration, _, _), Duration).
trip_price(trip(_, _, _, _, _, Price, _), Price).
trip_stops(trip(_, _, _, _, _, _, Stops), Stops).

main :-
    read_flights_json(J),
    json_to_list_of_trips(J, Ts),
    % print_elements(Ts),
    nth1(1, Ts, T),
    print(T), nl.

% student("budapest", ["05/05/2022", "06/05/2022"], 1, 600, "05:30:00", "23:30:00")
% trip("wien", "zagreb", "09/05/2022, 10:10:00", "09/05/2022, 10:55:00", 45, 212, 0)

print_elements([]) :- !.
print_elements([H | T]) :-
    print(H), nl,
    print_elements(T).
