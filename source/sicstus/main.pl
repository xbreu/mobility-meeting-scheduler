:- consult('./constraints.pl').
:- consult('./data.pl').
:- consult('./utils.pl').
:- consult('./variables.pl').
:- use_module(library(clpfd)).
:- use_module(library(system)).

% -----------------------------------------------------------------------------
% Main function
% -----------------------------------------------------------------------------

main :-
    % Input
    format('Reading data...', []),
    % Read all data
    read_data(Data),
    % Calculate size of inputs
    format('Done~n', []),

    % Variables
    format('Creating variables...', []),
    create_variables(Data, Variables),
    format('Done~n', []),

    % Contraints
    format('Constraining variables...', []),
    constrain_variables(Data, Variables),
    format('Done~n', []),

    % Enumeration
    format('Finding a solution...', []),
    flatten_variables(Variables, LabelVariables),
    variables_cost(Variables, Cost),
    labeling([time_out(10000, Flag), minimize(Cost)], LabelVariables), !,
    format('Done~n~n', []),

    % Output
    print_result(Flag, Data, Variables).

% -----------------------------------------------------------------------------
% Final output
% -----------------------------------------------------------------------------

print_result(Flag, Data, Variables) :-
    format('Result: ~p~n', [Flag]),
    variables_total_cost(Variables, TotalCost),
    format('Total Cost: ~d \x20AC\~n', [TotalCost]),
    variables_useful_time(Variables, UsefulTime),
    UsefulTimeDays is UsefulTime // 86400,
    UsefulTimeHours is (UsefulTime mod 86400) // 3600,
    UsefulTimeMinutes is (UsefulTime mod 3600) // 60,
    UsefulTimeSeconds is UsefulTime mod 60,
    format('Useful Time: ~`0t~d~16+ days, ~`0t~d~9+ hours ~`0t~d~9+ minutes and ~`0t~d~15+ seconds~n',
        [UsefulTimeDays, UsefulTimeHours, UsefulTimeMinutes, UsefulTimeSeconds]),
    variables_cost(Variables, Cost),
    format('Cost Function: ~d \x20AC\ per day~n~n', [Cost]),
    data_flight_origins(Data, Origins),
    data_flight_destinations(Data, Destinations),
    data_flight_departures(Data, Departures),
    data_flight_arrivals(Data, Arrivals),
    data_flight_prices(Data, Prices),
    data_locations(Data, Locations),
    variables_outgoing_trips(Variables, OutgoingTrips),
    variables_incoming_trips(Variables, IncomingTrips),
    print_student_plans(1, Origins-Destinations-Departures-Arrivals-Prices-Locations, OutgoingTrips-IncomingTrips).

print_student_plans(_, _, []-_).
print_student_plans(I, Data, [OutgoingTrip | OutgoingTrips]-[IncomingTrip | IncomingTrips]) :-
    format('Student ~d:~n', [I]),
    format('    Outgoing Trip: ', []),
    print_plan(Data, OutgoingTrip),
    format('    Incoming Trip: ', []),
    print_plan(Data, IncomingTrip),
    In is I + 1,
    print_student_plans(In, Data, OutgoingTrips-IncomingTrips).

print_plan(Origins-Destinations-Departures-Arrivals-Prices-Locations, Trip) :-
    nth1(Trip, Origins, TripOriginIndex),
    nth1(Trip, Destinations, TripDestinationIndex),
    nth1(Trip, Departures, TripDepartureTimestampI),
    nth1(Trip, Arrivals, TripArrivalTimestampI),
    nth1(Trip, Prices, TripPrice),
    nth1(TripOriginIndex, Locations, TripOrigin),
    nth1(TripDestinationIndex, Locations, TripDestination),
    TripDepartureTimestamp is TripDepartureTimestampI - 3600,
    TripArrivalTimestamp is TripArrivalTimestampI - 3600,
    datime(TripDepartureTimestamp,
        datime(DepartureY, DepartureM, DepartureD, DepartureHr, DepartureMin, DepartureSec)),
    datime(TripArrivalTimestamp,
        datime(ArrivalY, ArrivalM, ArrivalD, ArrivalHr, ArrivalMin, ArrivalSec)),
    Format = '~+~p~t~8+ at ~`0t~d~8+/~`0t~d~3+/~`0t~d~3+ ~`0t~d~3+:~`0t~d~3+:~`0t~d~3+',
    format(Format, [TripOrigin, DepartureY, DepartureM, DepartureD, DepartureHr, DepartureMin, DepartureSec]),
    format(' -> ', []),
    format(Format, [TripDestination, ArrivalY, ArrivalM, ArrivalD, ArrivalHr, ArrivalMin, ArrivalSec]),
    format(' - ~+~t~d~4+ \x20AC\~n', [TripPrice]).
