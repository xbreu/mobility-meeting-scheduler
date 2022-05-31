:- consult('./data.pl').
:- consult('./utils.pl').
:- use_module(library(clpfd)).

% -----------------------------------------------------------------------------
% Variables
% -----------------------------------------------------------------------------

variables_destination([Destination | _], Destination).
variables_outgoing_trips([_, OutgoingPlans | _], OutgoingPlans).
variables_incoming_trips([_, _, IncomingPlans | _], IncomingPlans).
variables_individual_costs([_, _, _, IndividualCosts | _], IndividualCosts).
variables_total_cost([_, _, _, _, TotalCost | _], TotalCost).
variables_useful_time([_, _, _, _, _, UsefulTime | _], UsefulTime).
variables_cost([_, _, _, _, _, _, Cost | _], Cost).

flatten_variables(Variables, Plans) :-
    variables_outgoing_trips(Variables, OutgoingPlans),
    variables_incoming_trips(Variables, IncomingPlans),
    append(OutgoingPlans, IncomingPlans, Plans).

create_variables(Data, [Destination, OutgoingPlans, IncomingPlans, IndividualCosts, TotalCost, UsefulTime, Goal]) :-
    % Final destination variable
    data_possible_destinations(Data, PossibleDestinations),
    Destination in_set PossibleDestinations,
    % List of pairs with indices of outgoing and incoming trip, 0 represents none
    create_plans(Data, OutgoingPlans-IncomingPlans),
    % Cost of each student
    create_individual_costs(Data, OutgoingPlans-IncomingPlans, IndividualCosts),
    % Total costs
    sum(IndividualCosts, #=, TotalCost),
    % Useful time
    data_flight_departures(Data, Departures),
    data_flight_arrivals(Data, Arrivals),
    create_useful_time(Departures-Arrivals, OutgoingPlans-IncomingPlans, _, UsefulTime),
    % Minimization goal
    Goal #= (86400 * TotalCost) / UsefulTime.

create_plans(Data, OutgoingPlans-IncomingPlans) :-
    data_students_cities(Data, Students),
    data_flight_origins(Data, Flights),
    length(Students, StudentsSize),
    length(Flights, FlightsSize),
    length(OutgoingPlans, StudentsSize),
    length(IncomingPlans, StudentsSize),
    domain(OutgoingPlans, 1, FlightsSize),
    domain(IncomingPlans, 1, FlightsSize).

create_individual_costs(Data, OutgoingPlans-IncomingPlans, IndividualCosts) :-
    data_flight_prices(Data, Prices),
    create_individual_costs(Prices, OutgoingPlans-IncomingPlans, [], IndividualCosts).

create_individual_costs(_, []-[], Acc, Acc).
create_individual_costs(Prices, [Outgoing | Outgoings]-[Incoming | Incomings],
    Acc, Result) :-
    element(Outgoing, Prices, OutgoingPrice),
    element(Incoming, Prices, IncomingPrice),
    IndividualCost #= OutgoingPrice + IncomingPrice,
    append(Acc, [IndividualCost], Accn),
    create_individual_costs(Prices, Outgoings-Incomings, Accn, Result).

create_useful_time(Departures-Arrivals, OutgoingTrips-IncomingTrips, LastArrival-EarliestDeparture, UsefulTime) :-
    indices_access(Arrivals, OutgoingTrips, TripArrivals),
    indices_access(Departures, IncomingTrips, TripDepartures),
    maximum(LastArrival, TripArrivals),
    minimum(EarliestDeparture, TripDepartures),
    UsefulTime #= EarliestDeparture - LastArrival.
