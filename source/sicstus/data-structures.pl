:- consult('./input.pl').

% -----------------------------------------------------------------------------
% Trip structure
% -----------------------------------------------------------------------------

% trip(Origin, Destination, Departure, Arrival, Duration, Price, Stops)

trip_origin(trip(O, _, _, _, _, _, _), O).
trip_destination(trip(_, D, _, _, _, _, _), D).
trip_departure(trip(_, _, D, _, _, _, _), D).
trip_arrival(trip(_, _, _, A, _, _, _), A).
trip_duration(trip(_, _, _, _, D, _, _), D).
trip_price(trip(_, _, _, _, _, P, _), P).
trip_stops(trip(_, _, _, _, _, _, S), S).

% -----------------------------------------------------------------------------
% Student structure
% -----------------------------------------------------------------------------

% student(City, Availability, MaxConnections, MaxDuration,
%         EarliestDeparture, LatestArrival)

student_city(student(C, _, _, _, _, _), C).
student_availability(student(_, A, _, _, _, _), A).
student_max_connections(student(_, _, M, _, _, _), M).
student_max_duration(student(_, _, _, M, _, _), M).
student_earliest_departure(student(_, _, _, _, E, _), E).
student_latest_arrival(student(_, _, _, _, _, L), L).

% -----------------------------------------------------------------------------
% Data structure
% -----------------------------------------------------------------------------

% data(Trips, Destinations, Students, MinimumUsefulTime)

data_trips(data(T, _, _, _), T).
data_destinations(data(_, D, _, _), D).
data_students(data(_, _, S, _), S).
data_minimum_useful_time(data(_, _, _, M), M).

% -----------------------------------------------------------------------------
% Plan structure
% -----------------------------------------------------------------------------

% [OutgoingTripIndex, IncomingTripIndex]

plan_outgoing_trip_index([O, _], O).
plan_incoming_trip_index([_, I], I).

create_plans(N, Plans) :-
    length(Plans, N),
    restrict_lengths(Plans, 2).

restrict_lengths([], _).
restrict_lengths([H | T], N) :-
    length(H, N),
    restrict_lengths(T, N).
