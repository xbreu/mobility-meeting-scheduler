:- consult('./input.pl').

:- use_module(library(clpfd)).

main :-
    % Input
    format('Reading data...', []),
    % Read all data
    read_data(
        [Origins, Destinations, Departures, Arrivals, Durations, Prices, Stopss],
        PossibleDestinations, [Cities, Availabilites, MaximumConnections,
        MaximumDurations, EarliestDepartures, LatestArrivals], MinimumUsefulTime,
        Locations
    ),
    % Calculate size of inputs
    length(Origins, FlightsSize),
    length(Cities, StudentsSize),
    format('Done~n', []),

    % Variables
    format('Creating variables...', []),
    % Final destination variable
    Destination in_set PossibleDestinations,
    % List of pairs with indices of outgoing and incoming trip
    create_plans(FlightsSize, StudentsSize, Plans, OutgoingTrips, IncomingTrips),
    % List of which availability interval was chosen for each student
    create_availability_indices(Availabilites, AvailabilityIndices),
    % Cost of each student
    create_costs(Plans, Prices, Costs),
    % Total cost of trips
    sum(Costs, #=, TotalCost),
    % Useful time
    create_useful_time(Departures-Arrivals, OutgoingTrips-IncomingTrips,
                       LastArrival-EarliestDeparture, UsefulTime),
    format('Done~n', []).

% -----------------------------------------------------------------------------
% Variables
% -----------------------------------------------------------------------------

create_plans(FlightsSize, StudentsSize, Plans, OutgoingPlans, IncomingPlans) :-
    length(Plans, StudentsSize),
    add_plan_domains(FlightsSize, Plans),
    split_plans(Plans, OutgoingPlans-IncomingPlans).

split_plans(Plan, OutgoingPlans-IncomingPlans) :-
    split_plans(Plan, []-OutgoingPlans, []-IncomingPlans).

split_plans([], Ao-Ao, Ai-Ai).
split_plans([[O, I] | Ps], Ao-Ro, Ai-Ri) :-
    append(Ao, [O], Aon),
    append(Ai, [I], Ain),
    split_plans(Ps, Aon-Ro, Ain-Ri).

add_plan_domains(_, []).
add_plan_domains(N, [P | Ps]) :-
    length(P, 2),
    domain(P, 1, N),
    add_plan_domains(N, Ps).

create_availability_indices(Availabilites, AvailabilityIndices) :-
    create_availability_indices(Availabilites, [], AvailabilityIndices).

create_availability_indices([], Acc, Acc).
create_availability_indices([As | Ass], Acc, R) :-
    length(As, Asl),
    domain([A], 1, Asl),
    append(Acc, [A], Accn),
    create_availability_indices(Ass, Accn, R).

create_costs(Plans, Prices, Costs) :-
    create_costs(Plans, Prices, [], Costs).

create_costs([], _, Acc, Acc).
create_costs([[Ti, To] | Ps], Prices, Acc, R) :-
    element(Ti, Prices, Pi),
    element(To, Prices, Po),
    P #= Pi + Po,
    append(Acc, [P], Accn),
    create_costs(Ps, Prices, Accn, R).

create_useful_time(Departures-Arrivals, OutgoingTrips-IncomingTrips, LastArrival-EarliestDeparture, UsefulTime) :-
    indices_access(Arrivals, OutgoingTrips, TripArrivals),
    indices_access(Departures, IncomingTrips, TripDepartures),
    maximum(LastArrival, TripArrivals),
    minimum(EarliestDeparture, TripDepartures),
    UsefulTime #= EarliestDeparture - LastArrival.
