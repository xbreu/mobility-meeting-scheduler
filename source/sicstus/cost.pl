:- use_module(library(clpfd)).
:- consult('./data/data.pl').
:- consult('./data/datetime.pl').
:- consult('./data/plan.pl').
:- consult('./data/trip.pl').
:- consult('./utils.pl').

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
