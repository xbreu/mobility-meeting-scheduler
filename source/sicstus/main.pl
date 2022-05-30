:- consult('./input.pl').
:- consult('./utils.pl').

:- use_module(library(clpfd)).

main :-
    % Input
    format('Reading data...', []),
    % Read all data
    read_data(
        [Origins, Destinations, Departures, Arrivals, Durations, Prices, Stopss],
        PossibleDestinations, [Cities, AvailabilityStarts, AvailabilityEnds,
        MaximumConnections, MaximumDurations, EarliestDepartures, LatestArrivals],
        MinimumUsefulTime, Locations
    ),
    % Calculate size of inputs
    length(Origins, FlightsSize),
    length(Cities, StudentsSize),
    format('Done~n', []),

    % Variables
    format('Creating variables...', []),
    % Final destination variable
    Destination in_set PossibleDestinations,
    % List of pairs with indices of outgoing and incoming trip, 0 represents none
    create_plans(FlightsSize, StudentsSize, Plans, OutgoingTrips, IncomingTrips),
    % List of which availability interval was chosen for each student
    create_availability_indices(AvailabilityStarts, AvailabilityIndices),
    % Cost of each student
    create_costs(Plans, Prices, Costs),
    % Total cost of trips
    sum(Costs, #=, TotalCost),
    % Useful time, in second
    create_useful_time(Departures-Arrivals, OutgoingTrips-IncomingTrips,
                       _, UsefulTime),
    % List of booleans, 1 means the student needs to take a trip
    create_needs_trips(Cities, Destination, NeedsTrips),
    format('Done~n', []),

    % Contraints
    format('Creating constraints...', []),
    % Individual restrictions
    restrict_students([Origins, Destinations, Departures, Arrivals, Durations,
        Prices, Stopss], Cities, AvailabilityStarts, AvailabilityEnds,
        MaximumConnections, MaximumDurations, EarliestDepartures, LatestArrivals,
        NeedsTrips, AvailabilityIndices, Plans, Destination
    ),
    % Global restrictions
    restrict_global(UsefulTime-MinimumUsefulTime, TotalCost, Goal),
    format('Done~n', []),

    % Enumeration
    format('Finding a solution...', []),
    flatten(Plans, Variables),
    labeling([time_out(10000, Flag), minimize(Goal)], [Destination | Variables]), !,
    format('Done~n~n', []),

    % Output solution
    show_results(Flag, Locations, Origins-Destinations, Departures-Arrivals, Destination, Plans).


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
    domain(P, 0, N),
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

create_needs_trips(Cities, Destination, NeedsTrips) :-
    create_needs_trips(Cities, Destination, [], NeedsTrips).

create_needs_trips([], _, Acc, Acc).
create_needs_trips([City | Cities], Destination, Acc, NeedsTrips) :-
    City #\= Destination #<=> B,
    append(Acc, [B], Accn),
    create_needs_trips(Cities, Destination, Accn, NeedsTrips).

% -----------------------------------------------------------------------------
% Constraints
% -----------------------------------------------------------------------------

restrict_students(_, [], _, _, _, _, _, _, _, _, _, _) :- !.
restrict_students([Origins, Destinations, Departures, Arrivals, Durations,
    Prices, Stopss], [City | Cities], [AvailabilityStarts | AvailabilityStartss],
    [AvailabilityEnds | AvailabilityEndss], [MaximumConnections | MaximumConnectionss],
    [MaximumDuration | MaximumDurations], [EarliestDeparture | EarliestDepartures],
    [LatestArrival | LatestArrivals], [NeedsTrips | NeedsTripss],
    [AvailabilityIndex | AvailabilityIndices], [[OutgoingTrip, IncomingTrip] | Plans],
    Destination) :-
        % The trips needs to start on the student city and end in it again,
        % they also need to lead the student to the destination.
        restrict_student_flight_locations(NeedsTrips, Origins-Destinations,
            City-Destination, OutgoingTrip-IncomingTrip),
        % The trip needs to take place during a time the student is available
        % and inside their hours
        restrict_student_availability(NeedsTrips, AvailabilityIndex,
            AvailabilityStarts-AvailabilityEnds,
            Departures-Arrivals, OutgoingTrip-IncomingTrip),
        % Maximum number of stops
        restrict_student_maximum_number_of_stops(NeedsTrips, Stopss, MaximumConnections,
            OutgoingTrip-IncomingTrip),
        % Maximum duration
        restrict_student_maximum_duration(NeedsTrips, Durations, MaximumDuration,
            OutgoingTrip-IncomingTrip),
        % Recursion
        restrict_students([Origins, Destinations, Departures, Arrivals, Durations,
            Prices, Stopss], Cities, AvailabilityStartss, AvailabilityEndss,
            MaximumConnectionss, MaximumDurations, EarliestDepartures, LatestArrivals,
            NeedsTripss, AvailabilityIndices, Plans, Destination).

restrict_student_flight_locations(NeedsTrips, Origins-Destinations, City-Destination,
    OutgoingTrip-IncomingTrip) :-
    (NeedsTrips #= 1) #=> (
        element(OutgoingTrip, Origins, OutgoingOrigin) #/\
        element(OutgoingTrip, Destinations, OutgoingDestination) #/\
        element(IncomingTrip, Origins, IncomingOrigin) #/\
        element(IncomingTrip, Destinations, IncomingDestination) #/\
        OutgoingOrigin #= City #/\
        IncomingDestination #= City #/\
        OutgoingDestination #= Destination #/\
        IncomingOrigin #= Destination
    ).

restrict_student_availability(NeedsTrips, AvailabilityIndex, AvailabilityStarts-AvailabilityEnds,
    Departures-Arrivals, OutgoingTrip-IncomingTrip) :-
    (NeedsTrips #= 1) #=> (
        element(OutgoingTrip, Departures, OutgoingDeparture) #/\
        element(OutgoingTrip, Arrivals, OutgoingArrival) #/\
        element(IncomingTrip, Departures, IncomingDeparture) #/\
        element(IncomingTrip, Arrivals, IncomingArrival) #/\
        element(AvailabilityIndex, AvailabilityStarts, AvailabilityStart) #/\
        element(AvailabilityIndex, AvailabilityEnds, AvailabilityEnd) #/\
        OutgoingDeparture #>= AvailabilityStart #/\
        IncomingArrival #=< AvailabilityEnd #/\
        IncomingDeparture #> OutgoingArrival
    ).


restrict_student_maximum_number_of_stops(NeedsTrips, Stops, MaximumStops, OutgoingTrip-IncomingTrip) :-
    (NeedsTrips #= 1) #=> (
        element(OutgoingTrip, Stops, OutgoingStops) #/\
        element(IncomingTrip, Stops, IncomingStops) #/\
        OutgoingStops #=< MaximumStops #/\
        IncomingStops #=< MaximumStops
    ).

restrict_student_maximum_duration(NeedsTrips, Durations, MaximumDuration, OutgoingTrip-IncomingTrip) :-
    (NeedsTrips #= 1) #=> (
        element(OutgoingTrip, Durations, OutgoingDuration) #/\
        element(IncomingTrip, Durations, IncomingDuration) #/\
        OutgoingDuration #=< MaximumDuration #/\
        IncomingDuration #=< MaximumDuration
    ).

restrict_global(UsefulTime-MinimumUsefulTime, TotalCost, Goal) :-
    UsefulTime #>= MinimumUsefulTime,
    Goal #= (86400 * TotalCost) / UsefulTime.

% -----------------------------------------------------------------------------
% Output
% -----------------------------------------------------------------------------

show_results(Flag, Locations, Origins-Destinations, Departures-Arrivals, Destination, Plans) :-
    format('Result: ~p~n', [Flag]),
    nth1(Destination, Locations, DestinationValue),
    format('Destination: ~p~n', [DestinationValue]),
    show_plans(1, Locations, Origins-Destinations, Departures-Arrivals, Plans).

show_plans(_, _, _, _, []).
show_plans(I, Locations, Origins-Destinations, Departures-Arrivals, [[Outgoing, Incoming] | Plans]) :-
    format('Student ~d:~n', [I]),
    nth1(Outgoing, Departures, OutgoingDeparture),
    nth1(Outgoing, Arrivals, OutgoingArrival),
    nth1(Outgoing, Origins, OutgoingOriginI),
    nth1(Outgoing, Destinations, OutgoingDestinationI),
    nth1(OutgoingOriginI, Locations, OutgoingOrigin),
    nth1(OutgoingDestinationI, Locations, OutgoingDestination),
    format('    ~p at ~p -> ~p at ~p~n', [OutgoingOrigin, OutgoingDeparture, OutgoingDestination, OutgoingArrival]),
    nth1(Incoming, Departures, IncomingDeparture),
    nth1(Incoming, Arrivals, IncomingArrival),
    nth1(Incoming, Origins, IncomingOriginI),
    nth1(Incoming, Destinations, IncomingDestinationI),
    nth1(IncomingOriginI, Locations, IncomingOrigin),
    nth1(IncomingDestinationI, Locations, IncomingDestination),
    format('    ~p at ~p -> ~p at ~p~n', [IncomingOrigin, IncomingDeparture, IncomingDestination, IncomingArrival]),
    In is I + 1,
    show_plans(In, Locations, Origins-Destinations, Departures-Arrivals, Plans).
