:- consult('./data.pl').
:- consult('./variables.pl').
:- use_module(library(clpfd)).

constrain_variables(Data, Variables) :-
    constrain_global_restrictions(Data, Variables),
    constrain_students_restrictions(Data, Variables).

% -----------------------------------------------------------------------------
% Global constraints
% -----------------------------------------------------------------------------

constrain_global_restrictions(Data, Variables) :-
    constrain_minimum_useful_time(Data, Variables).

constrain_minimum_useful_time(Data, Variables) :-
    data_minimum_useful_time(Data, MinimumUsefulTime),
    variables_useful_time(Variables, UsefulTime),
    UsefulTime #>= MinimumUsefulTime.

% -----------------------------------------------------------------------------
% Student constraints
% -----------------------------------------------------------------------------

constrain_students_restrictions(Data, Variables) :-
    data_flight_origins(Data, Origins),
    data_flight_destinations(Data, Destinations),
    data_flight_departures(Data, Departures),
    data_flight_arrivals(Data, Arrivals),
    data_flight_durations(Data, Durations),
    data_flight_prices(Data, Prices),
    data_flight_connections(Data, Stops),
    data_students_cities(Data, Cities),
    data_students_availability_starts(Data, AvailabilityStarts),
    data_students_availability_ends(Data, AvailabilityEnds),
    data_students_maximum_connections(Data, MaximumConnections),
    data_students_maximum_durations(Data, MaximumDurations),
    data_students_earliest_departures(Data, EarliestDepartures),
    data_students_latest_arrivals(Data, LatestArrivals),
    variables_destination(Variables, Destination),
    variables_outgoing_trips(Variables, OutgoingTrips),
    variables_incoming_trips(Variables, IncomingTrips),
    constrain_students_restrictions(
        Origins-Destinations-Departures-Arrivals-Durations-Prices-Stops, Destination,
        OutgoingTrips-IncomingTrips, Cities, AvailabilityStarts, AvailabilityEnds,
        MaximumConnections, MaximumDurations, EarliestDepartures, LatestArrivals).

constrain_students_restrictions(_, _, _, [], _, _, _, _, _, _).
constrain_students_restrictions(
    Origins-Destinations-Departures-Arrivals-Durations-Prices-Stops,
    Destination, [OutgoingTrip | OutgoingTrips]-[IncomingTrip | IncomingTrips], [City | Cities],
    [AvailabilityStarts | AvailabilityStartss], [AvailabilityEnds | AvailabilityEndss],
    [MaximumConnections | MaximumConnectionss], [MaximumDuration | MaximumDurations],
    [EarliestDeparture | EarliestDepartures], [LatestArrival | LatestArrivals]) :-
        constrain_student_flight_locations(Origins-Destinations, Destination,
            OutgoingTrip-IncomingTrip, City),
        constrain_student_availability(Departures-Arrivals, OutgoingTrip-IncomingTrip,
            AvailabilityStarts, AvailabilityEnds),
        constrain_student_maximum_number_of_connections(Stops, OutgoingTrip-IncomingTrip,
            MaximumConnections),
        constrain_student_maximum_duration(Durations, OutgoingTrip-IncomingTrip,
            MaximumDuration),
        constrain_students_restrictions(
            Origins-Destinations-Departures-Arrivals-Durations-Prices-Stops, Destination,
            OutgoingTrips-IncomingTrips, Cities, AvailabilityStartss, AvailabilityEndss,
            MaximumConnectionss, MaximumDurations, EarliestDepartures, LatestArrivals).

% The trips needs to start on the student city and end in it again, and they
% also need to lead the student to the destination.
constrain_student_flight_locations(Origins-Destinations, Destination,
    OutgoingTrip-IncomingTrip, City) :-
    element(OutgoingTrip, Origins, OutgoingOrigin),
    element(OutgoingTrip, Destinations, OutgoingDestination),
    element(IncomingTrip, Origins, IncomingOrigin),
    element(IncomingTrip, Destinations, IncomingDestination),
    OutgoingOrigin #= City,
    IncomingDestination #= City,
    OutgoingDestination #= Destination,
    IncomingOrigin #= Destination.

% The trip needs to take place during a time the student is available and
% inside their hours.
constrain_student_availability(Departures-Arrivals, OutgoingTrip-IncomingTrip,
    AvailabilityStarts, AvailabilityEnds) :-
    element(OutgoingTrip, Departures, OutgoingDeparture),
    element(OutgoingTrip, Arrivals, OutgoingArrival),
    element(IncomingTrip, Departures, IncomingDeparture),
    element(IncomingTrip, Arrivals, IncomingArrival),
    element(AvailabilityIndex, AvailabilityStarts, AvailabilityStart),
    element(AvailabilityIndex, AvailabilityEnds, AvailabilityEnd),
    OutgoingDeparture #>= AvailabilityStart,
    IncomingArrival #=< AvailabilityEnd,
    IncomingDeparture #> OutgoingArrival.

% Maximum number of stops
constrain_student_maximum_number_of_connections(Stops, OutgoingTrip-IncomingTrip,
    MaximumConnections) :-
    element(OutgoingTrip, Stops, OutgoingStops),
    element(IncomingTrip, Stops, IncomingStops),
    OutgoingStops #=< MaximumStops,
    IncomingStops #=< MaximumStops.

% Maximum duration
constrain_student_maximum_duration(Durations, OutgoingTrip-IncomingTrip,
    MaximumDuration) :-
    element(OutgoingTrip, Durations, OutgoingDuration),
    element(IncomingTrip, Durations, IncomingDuration),
    OutgoingDuration #=< MaximumDuration,
    IncomingDuration #=< MaximumDuration.
