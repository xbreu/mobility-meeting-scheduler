:- use_module(library(clpfd)).
:- consult('./data/data.pl').
:- consult('./data/datetime.pl').
:- consult('./data/plan.pl').
:- consult('./data/trip.pl').
:- consult('./utils.pl').

calculate_cost(Data, Plans, Cost) :-
    calculate_cost(Data, Plans, Cost, _, _, _).

calculate_cost(Data, Plans, Cost, TotalCost, UsefulTime, AloneTimesAverage) :-
    calculate_useful_time(Data, Plans, UsefulTime),
    calculate_alone_times(Data, Plans, AloneTimes),
    calculate_individual_costs(Data, Plans, IndividualCosts),
    length(Plans, Students),
    sum(AloneTimes, #=, AloneTimesSum),
    AloneTimesAverage #= AloneTimesSum / Students,
    sum(IndividualCosts, #=, TotalCost),
    Cost #= (2592000 * TotalCost) / (100 * UsefulTime - AloneTimesAverage).

% Returns the number of seconds all of the students will be in the destination.
calculate_useful_time(Data, Plans, UsefulTime) :-
    calculate_last_arrival(Data, Plans, LastArrival),
    calculate_earliest_departure(Data, Plans, EarliestDeparture),
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
calculate_alone_times(Data, Plans, AloneTimes) :-
    data_trips(Data, Trips),
    calculate_last_arrival(Data, Plans, LastArrival),
    calculate_earliest_departure(Data, Plans, EarliestDeparture),
    get_alone_times(Trips, Plans, LastArrival-EarliestDeparture, AloneTimes).

get_alone_times(Trips, Plans, Start-End, Result) :-
    map(trip_departure, Trips, TripDeparturesI),
    map(trip_arrival, Trips, TripArrivalsI),
    map(datetime_to_seconds, TripDeparturesI, TripDepartures),
    map(datetime_to_seconds, TripArrivalsI, TripArrivals),
    map(trip_homogeneous, Trips, Hs),
    get_alone_times(TripDepartures-TripArrivals-Hs, Plans, Start-End, [], Result).

get_alone_times(_, [], _, Acc, Acc).
get_alone_times(Departures-Arrivals-Hs, [Plan | Plans], Start-End, Acc, Result) :-
    plan_outgoing_trip(Plan, Toi),
    plan_incoming_trip(Plan, Tii),
    element(Toi, Arrivals, Arrival),
    element(Tii, Departures, Departure),
    element(Toi, Hs, Homogeneous),
    Homogeneous #=> (
        AloneTime #= 0
    ),
    #\Homogeneous #=> (
        AloneTime #= (Start - Arrival) + (Departure - End)
    ),
    append(Acc, [AloneTime], AccI),
    get_alone_times(Departures-Arrivals-Hs, Plans, Start-End, AccI, Result).

% Returns the arrival of the last person.
calculate_last_arrival(Data, Plans, LastArrival) :-
    data_trips(Data, Trips),
    map(trip_arrival, Trips, TripArrivalsI),
    map(datetime_to_seconds, TripArrivalsI, TripArrivals),
    map(trip_heterogeneous, Trips, Heterogeneity),
    map(plan_outgoing_trip, Plans, OutgoingTripIndices),
    indices_access(TripArrivals, OutgoingTripIndices, OutgoingTrips),
    indices_access(Heterogeneity, OutgoingTripIndices, OutgoingHeterogeneity),
    maximum_heterogeneous(OutgoingHeterogeneity, OutgoingTrips, LastArrival).

% Returns the departure of the first person.
calculate_earliest_departure(Data, Plans, EarliestDeparture) :-
    data_trips(Data, Trips),
    map(trip_departure, Trips, TripDeparturesI),
    map(datetime_to_seconds, TripDeparturesI, TripDepartures),
    map(trip_heterogeneous, Trips, Heterogeneity),
    map(plan_incoming_trip, Plans, IncomingTripIndices),
    indices_access(TripDepartures, IncomingTripIndices, IncomingTrips),
    indices_access(Heterogeneity, IncomingTripIndices, IncomingHeterogeneity),
    minimum_heterogeneous(IncomingHeterogeneity, IncomingTrips, EarliestDeparture).

maximum_heterogeneous([H | Hs], [X | Xs], R) :-
    Ri #= X * H,
    maximum_heterogeneous(Hs, Xs, Ri, R).

maximum_heterogeneous([], [], A, A).
maximum_heterogeneous([H | Hs], [X | Xs], A, R) :-
    H #=> (
        (X #> A #=> Ri #= X)
        #/\ (X #=< A #=> Ri #= A)
    ),
    #\H #=> (Ri #= A),
    maximum_heterogeneous(Hs, Xs, Ri, R).

minimum_heterogeneous([H | Hs], [X | Xs], R) :-
    H #=> Ri #= X,
    #\H #=> Ri #= 999999,
    minimum_heterogeneous(Hs, Xs, Ri, R).

minimum_heterogeneous([], [], A, A).
minimum_heterogeneous([H | Hs], [X | Xs], A, R) :-
    H #=> (
        (X #< A #=> Ri #= X)
        #/\ (X #>= A #=> Ri #= A)
    ),
    #\H #=> (Ri #= A),
    minimum_heterogeneous(Hs, Xs, Ri, R).
