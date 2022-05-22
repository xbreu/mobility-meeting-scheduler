:- consult('./input.pl').
:- consult('./data/datetime.pl').
:- consult('./data/trip.pl').

:- use_module(library(clpfd)).
:- use_module(library(lists)).

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
