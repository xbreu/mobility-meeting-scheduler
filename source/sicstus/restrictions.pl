:- use_module(library(clpfd)).
:- consult('./cost.pl').
:- consult('./data/data.pl').
:- consult('./data/plan.pl').
:- consult('./data/student.pl').
:- consult('./data/trip.pl').
:- consult('./utils.pl').

restrict_hard_constraints(Data, Plans) :-
    restrict_start_and_end_in_current_city(Data, Plans),
    restrict_middle_location_is_the_same(Data, Plans),
    restrict_same_destination(Data, Plans),
    restrict_destination_in_list(Data, Plans),
    restrict_max_durations(Data, Plans),
    restrict_max_connections(Data, Plans),
    restrict_earliest_departures(Data, Plans),
    restrict_latest_arrivals(Data, Plans),
    restrict_minimum_useful_time(Data, Plans).

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

% The chosen destination needs to be a member of the provided list of possible
% destinations.
restrict_destination_in_list(Data, Plans) :-
    data_destinations(Data, PossibleDestinations),
    data_trips(Data, Trips),
    list_to_fdset(PossibleDestinations, PossibleDestinationSet),
    map(trip_destination, Trips, Destinations),
    nth1(1, Plans, Plan),
    plan_outgoing_trip(Plan, Trip),
    element(Trip, Destinations, FinalDestination),
    FinalDestination in_set PossibleDestinationSet.


% Each student will have trips that take less than their maximum possible
% duration.
restrict_max_durations(Data, Plans) :-
    data_students(Data, Students),
    data_trips(Data, Trips),
    map(student_max_duration, Students, MaxDurations),
    map(trip_duration, Trips, Durations),
    restrict_max_durations(Durations, MaxDurations, Plans).

restrict_max_durations(_, [], []).
restrict_max_durations(Durations, [Max | Tail], [Plan | Plans]) :-
    plan_incoming_trip(Plan, Incoming),
    plan_outgoing_trip(Plan, Outgoing),
    element(Incoming, Durations, IncomingDuration),
    element(Outgoing, Durations, OutgoingDuration),
    IncomingDuration #=< Max,
    OutgoingDuration #=< Max,
    restrict_max_durations(Durations, Tail, Plans).

% Each student will have trips that have at maximum the respective provided
% number of connections.
restrict_max_connections(Data, Plans) :-
    data_students(Data, Students),
    data_trips(Data, Trips),
    map(student_max_connections, Students, MaxConnections),
    map(trip_stops, Trips, Stops),
    restrict_max_connections(Stops, MaxConnections, Plans).

restrict_max_connections(_, [], []).
restrict_max_connections(Stops, [Max | Tail], [Plan | Plans]) :-
    plan_outgoing_trip(Plan, Outgoing),
    plan_incoming_trip(Plan, Incoming),
    element(Outgoing, Stops, OutgoingConnections),
    element(Incoming, Stops, IncomingConnections),
    OutgoingConnections #=< Max,
    IncomingConnections #=< Max,
    restrict_max_connections(Stops, Tail, Plans).

% Every student will leave their city after earliest departure.
restrict_earliest_departures(Data, Plans) :-
    data_students(Data, Students),
    data_trips(Data, Trips),
    map(student_earliest_departure, Students, Earliests),
    map(trip_departure_time, Trips, Departures),
    map(time_hours, Departures, Hours),
    map(time_minutes, Departures, Minutes),
    map(time_seconds, Departures, Seconds),
    restrict_earliest_departures(Hours, Minutes, Seconds, Earliests, Plans).

restrict_earliest_departures(_, _, _, [], []).
restrict_earliest_departures(Hs, Ms, Ss, [Earliest | Tail], [Plan | Plans]) :-
    plan_outgoing_trip(Plan, Trip),
    element(Trip, Hs, TripH),
    element(Trip, Ms, TripM),
    element(Trip, Ss, TripS),
    restrict_later_time(time(TripH, TripM, TripS), Earliest),
    restrict_earliest_departures(Hs, Ms, Ss, Tail, Plans).

% Every student will arrive in their city before their latest arrival.
restrict_latest_arrivals(Data, Plans) :-
    data_students(Data, Students),
    data_trips(Data, Trips),
    map(student_earliest_departure, Students, Latests),
    map(trip_arrival_time, Trips, Arrivals),
    map(time_hours, Arrivals, Hours),
    map(time_minutes, Arrivals, Minutes),
    map(time_seconds, Arrivals, Seconds),
    restrict_latest_arrivals(Hours, Minutes, Seconds, Latests, Plans).

restrict_latest_arrivals(_, _, _, [], []).
restrict_latest_arrivals(Hs, Ms, Ss, [Latest | Tail], [Plan | Plans]) :-
    plan_incoming_trip(Plan, Trip),
    element(Trip, Hs, TripH),
    element(Trip, Ms, TripM),
    element(Trip, Ss, TripS),
    restrict_earlier_time(time(TripH, TripM, TripS), Latest),
    restrict_latest_arrivals(Hs, Ms, Ss, Tail, Plans).

% Every student needs the trip to take place entirely within its available
% days.

% TODO

% The time all the students will spend together needs to be larger than the
% provided minimum useful time
restrict_minimum_useful_time(Data, Plans) :-
    data_minimum_useful_time(Data, MinimumUsefulTime),
    calculate_useful_time(Data, Plans, Time),
    Time #>= MinimumUsefulTime * 60.
