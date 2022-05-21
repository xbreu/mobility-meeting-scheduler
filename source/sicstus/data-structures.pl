:- consult('./input.pl').

:- use_module(library(clpfd)).
:- use_module(library(lists)).

% -----------------------------------------------------------------------------
% Date structure
% -----------------------------------------------------------------------------

% date(Y, M, D)

date_year(date(Y, _, _), Y).
date_month(date(_, M, _), M).
date_day(date(_, _, D), D).

% -----------------------------------------------------------------------------
% Time structure
% -----------------------------------------------------------------------------

% time(Hs, Ms, Ss)

time_hours(time(H, _, _), H).
time_minutes(time(_, M, _), M).
time_seconds(time(_, _, S), S).

% -----------------------------------------------------------------------------
% Datetime structure
% -----------------------------------------------------------------------------

% datetime(date(Y, M, D), time(Hs, Ms, Ss))

datetime_date(datetime(D, _), D).
datetime_time(datetime(_, T), T).
datetime_year(datetime(date(Y, _, _), _), Y).
datetime_month(datetime(date(_, M, _), _), M).
datetime_day(datetime(date(_, _, D), _), D).
datetime_hours(datetime(_, time(H, _, _)), H).
datetime_minutes(datetime(_, time(_, M, _)), M).
datetime_seconds(datetime(_, time(_, _, S)), S).

% -----------------------------------------------------------------------------
% Trip structure
% -----------------------------------------------------------------------------

% [Origin, Destination, Departure, Arrival, Duration, Price, Stops]

trip_origin([O, _, _, _, _, _, _], O).
trip_destination([_, D, _, _, _, _, _], D).
trip_departure([_, _, D, _, _, _, _], D).
trip_arrival([_, _, _, A, _, _, _], A).
trip_duration([_, _, _, _, D, _, _], D).
trip_price([_, _, _, _, _, P, _], P).
trip_stops([_, _, _, _, _, _, S], S).

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

% data(Trips, Destinations, Students, MinimumUsefulTime, Locations)

data_trips(data(T, _, _, _, _), T).
data_destinations(data(_, D, _, _, _), D).
data_students(data(_, _, S, _, _), S).
data_minimum_useful_time(data(_, _, _, M, _), M).
data_locations(data(_, _, _, _, L), L).

% -----------------------------------------------------------------------------
% Plan structure
% -----------------------------------------------------------------------------

% [OutgoingTripIndex, IncomingTripIndex]

plan_outgoing_trip([O, _], O).
plan_incoming_trip([_, I], I).

create_plans(Data, Plans) :-
    data_students(Data, Students),
    length(Students, PlansSize),
    length(Plans, PlansSize).

% -----------------------------------------------------------------------------
% Structure combinations
% -----------------------------------------------------------------------------

data_plan_outgoing_trip(Data, Plan, Trip) :-
    plan_outgoing_trip(Plan, O),
    data_trips(Data, Trips),
    nth1(O, Trips, Trip).

data_plan_incoming_trip(Data, Plan, Trip) :-
    plan_incoming_trip(Plan, I),
    data_trips(Data, Trips),
    nth1(I, Trips, Trip).
