:- consult('./data-structures.pl').
:- consult('./utils.pl').

:- use_module(library(clpfd)).

% Each plan element must be a valid index for a trip in the database.
restrict_plans_domains(Data, Plans) :-
    data_locations(Data, Locations),
    length(Locations, LocationsSize),
    restrict_plans_domains_(LocationsSize, Plans).

restrict_plans_domains_(_, []).
restrict_plans_domains_(N, [P | Ps]) :-
    restrict_plan_domain(N, P),
    restrict_plans_domains_(N, Ps).

restrict_plan_domain(N, Plan) :-
    length(Plan, 2),
    domain(Plan, 1, N).

% The outgoing trip of each student must start in its current city, and the
% same is true for the end of the incoming trip.
restrict_start_and_end_in_current_city(Data, Plans) :-
    data_students(Data, Students),
    data_trips(Data, Trips),
    map(student_city, Students, Cities),
    restrict_start_in_current_city(Cities, Trips, Plans),
    restrict_end_in_current_city(Cities, Trips, Plans).

restrict_start_in_current_city(Cities, Trips, Plans) :-
    map(trip_origin, Trips, TripOrigins),
    map(plan_outgoing_trip, Plans, OutgoingTrips),
    indices_access(TripOrigins, OutgoingTrips, Cities).

restrict_end_in_current_city(Cities, Trips, Plans) :-
    map(trip_destination, Trips, TripDestinations),
    map(plan_incoming_trip, Plans, IncomingTrips),
    indices_access(TripDestinations, IncomingTrips, Cities).

% Every student needs to go to the same city
% restrict_destinations(_, [], _).
% restrict_destinations(Data, [P | Ps], D) :-
%     data_plan_outgoing_trip(Data, P, To),
%     data_plan_incoming_trip(Data, P, Ti),
%     trip_origin(Ti, Io),
%     trip_destination(To, Od),
%     Io #= Od,
%     Io #= D,
%     Od #= D,
%     restrict_destinations(Data, Ps, D).
