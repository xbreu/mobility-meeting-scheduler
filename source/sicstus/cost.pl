:- use_module(library(clpfd)).
:- consult('./data/data.pl').
:- consult('./data/datetime.pl').
:- consult('./data/plan.pl').
:- consult('./data/trip.pl').
:- consult('./utils.pl').

calculate_cost(Data, Plans, Cost) :-
    calculate_useful_time(Data, Plans, UsefulTime),
    calculate_individual_costs(Data, Plans, IndividualCosts),
    calculate_alone_times(Data, Plans, AloneTimes),
    sum(IndividualCosts, #=, TotalCost),
    Cost #= UsefulTime / TotalCost.

% Returns the number of seconds all of the students will be in the destination.
% TODO: consider homogeneous trips.
calculate_useful_time(Data, Plans, UsefulTime) :-
    data_trips(Data, Trips),
    map(trip_arrival, Trips, TripArrivalsI),
    map(trip_departure, Trips, TripDeparturesI),
    map(datetime_to_seconds, TripArrivalsI, TripArrivals),
    map(datetime_to_seconds, TripDeparturesI, TripDepartures),
    map(plan_outgoing_trip, Plans, OutgoingTripIndices),
    map(plan_incoming_trip, Plans, IncomingTripIndices),
    indices_access(TripArrivals, OutgoingTripIndices, OutgoingTrips),
    indices_access(TripDepartures, IncomingTripIndices, IncomingTrips),
    maximum(LastArrival, OutgoingTrips),
    minimum(EarliestDeparture, IncomingTrips),
    UsefulTime #= EarliestDeparture - LastArrival.

% Returns a list with the price that each student will have to pay.
calculate_individual_costs(Data, Plans, IndividualCosts) :-
    data_trips(Data, Trips),
    map(trip_price, Trips, TripPrices),
    map(plan_outgoing_trip, Plans, OutgoingTrips),
    map(plan_incoming_trip, Plans, IncomingTrips),
    indices_access(TripPrices, OutgoingTrips, IndividualOutgoingCosts),
    indices_access(TripPrices, IncomingTrips, IndividualIncomingCosts),
    sum_elements(IndividualOutgoingCosts, IndividualIncomingCosts, IndividualCosts).

% Returns a list with the alone times for each student.
% TODO: finish implementation.
calculate_alone_times(Data, Plans, AloneTimes) :-
    data_trips(Data, Trips).
