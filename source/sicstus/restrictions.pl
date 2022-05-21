:- consult('./data-structures.pl').
:- consult('./utils.pl').

:- use_module(library(clpfd)).

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

% In every plan, the end of the outgoing trip is the same as the origin of the
% incoming one.
restrict_middle_location_is_the_same(Data, Plans) :-
    data_trips(Data, Trips),
    map(trip_origin, Trips, TripOrigins),
    map(trip_destination, Trips, TripDestinations),
    restrict_middle_location_is_the_same(TripOrigins, TripDestinations, Plans).

restrict_middle_location_is_the_same(_, _, []).
restrict_middle_location_is_the_same(Origins, Destinations, [Plan | Plans]) :-
    plan_outgoing_trip(Plan, Outgoing),
    plan_incoming_trip(Plan, Incoming),
    element(Outgoing, Destinations, Destination),
    element(Incoming, Origins, Origin),
    Destination #= Origin,
    restrict_middle_location_is_the_same(Origins, Destinations, Plans).

% Every student needs to go to the same city.
restrict_same_destination(Data, Plans) :-
    data_trips(Data, Trips),
    map(trip_destination, Trips, TripDestinations),
    map(plan_outgoing_trip, Plans, OutgoingTrips),
    indices_access(TripDestinations, OutgoingTrips, Destinations),
    nvalue(1, Destinations).
