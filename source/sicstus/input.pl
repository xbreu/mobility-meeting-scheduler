:- use_module(library(json)).
:- use_module(library(lists)).
:- consult('../utils.pl').
:- consult('./data/datetime.pl').
:- consult('./data/trip.pl').

% -----------------------------------------------------------------------------
% Reading from files
% -----------------------------------------------------------------------------

eof(-1).

read_until_eof(Content, Content) :-
    peek_code(C),
    eof(C), !.
read_until_eof(A, R) :-
    get_code(C),
    read_until_eof([C | A], R).

read_until_eof(R) :-
    read_until_eof([], Rev),
    reverse(Rev, R).

read_file(F, R) :-
    see(F),
    read_until_eof(R),
    seen.

read_json_file(F, R) :-
    read_file(F, Cs),
    json_from_codes(Cs, R).

read_flights_json(R) :-
    read_json_file('data/flights.json', R).

read_students_json(R) :-
    read_json_file('data/students.json', R).

% -----------------------------------------------------------------------------
% Datetime parsing
% -----------------------------------------------------------------------------

digits_to_number(L, N) :-
    digits_to_number(L, 0, N).

digits_to_number([], N, N).
digits_to_number([H | T], A, N) :-
    B is A * 10 + H,
    digits_to_number(T, B, N).

datetime(date(Y, M, D), time(Hs, Ms, Ss)) -->
    date(Y, M, D), ", ", time(Hs, Ms, Ss), " ".

date(Y, M, D) --> number(D), "/", number(M), "/", number(Y).

time(Hs, Ms, Ss) --> number(Hs), ":", number(Ms), ":", number(Ss).

number(N) --> digits(Ds), {digits_to_number(Ds, N)}.

digits([D]) --> digit(D).
digits([D | N]) --> digit(D), digits(N).

digit(X) --> [C], {"0" =< C, C =< "9", X is C - "0"}.

chars_codes([], []).
chars_codes([H | T], [C | Cs]) :-
    char_code(H, C),
    chars_codes(T, Cs).

atom_string(A, S) :-
    atom_chars(A, C),
    chars_codes(C, S).

atom_to_number(A, N) :-
    atom_string(A, S),
    phrase(number(N), S).

atom_to_datetime(A, datetime(date(Y, M, D), time(Hs, Ms, Ss))) :-
    atom_string(A, S),
    phrase(datetime(date(Y, M, D), time(Hs, Ms, Ss)), S).

atom_to_date(A, date(Y, M, D)) :-
    atom_string(A, S),
    phrase(date(Y, M, D), S).

atom_to_time(A, time(Hs, Ms, Ss)) :-
    atom_string(A, S),
    phrase(time(Hs, Ms, Ss), S).

list_of_atoms_to_list_of_dates([], []).
list_of_atoms_to_list_of_dates([A | As], [D | Ds]) :-
    atom_to_date(A, D),
    list_of_atoms_to_list_of_dates(As, Ds).

% -----------------------------------------------------------------------------
% Json to PROLOG's native structures
% -----------------------------------------------------------------------------

object_attribute_value(json(J), K, V) :-
    member(K=V, J).

json_to_list_of_trips(_, [], []).
json_to_list_of_trips(Ls, [J | Js], [T | Ts]) :-
    json_to_trip(Ls, J, T),
    json_to_list_of_trips(Ls, Js, Ts).

json_to_list_of_students(_, [], []).
json_to_list_of_students(Ls, [J | Js], [S | Ss]) :-
    json_to_student(Ls, J, S),
    json_to_list_of_students(Ls, Js, Ss).

json_to_list_of_destinations(_, [], []).
json_to_list_of_destinations(Ls, [J | Js], [D | Ds]) :-
    json_to_destination(Ls, J, D),
    json_to_list_of_destinations(Ls, Js, Ds).

json_to_trip(Locations, J,
    [Origin, Destination, Departure, Arrival, Duration, Price, Stops]) :-
    object_attribute_value(J, origin, OriginValue),
    nth1(Origin, Locations, OriginValue),
    object_attribute_value(J, destination, DestinationValue),
    nth1(Destination, Locations, DestinationValue),
    object_attribute_value(J, departure, DepartureAtom),
    object_attribute_value(J, arrival, ArrivalAtom),
    object_attribute_value(J, duration, Duration),
    object_attribute_value(J, price, PriceAtom),
    object_attribute_value(J, stops, Stops),

    % Parsing of some attributes
    atom_to_datetime(DepartureAtom, Departure),
    atom_to_datetime(ArrivalAtom, Arrival),
    atom_to_number(PriceAtom, Price).

json_to_student(Locations, J, student(City, Availability, MaxConnections,
    MaxDuration, EarliestDeparture, LatestArrival)) :-
    object_attribute_value(J, city, CityValue),
    nth1(City, Locations, CityValue),
    object_attribute_value(J, availability, AvailabilityAtoms),
    object_attribute_value(J, maxConnections, MaxConnections),
    object_attribute_value(J, maxDuration, MaxDuration),
    object_attribute_value(J, earliestDeparture, EarliestDepartureAtom),
    object_attribute_value(J, latestArrival, LatestArrivalAtom),

    % Parsing of some attributes
    list_of_atoms_to_list_of_dates(AvailabilityAtoms, Availability),
    atom_to_time(EarliestDepartureAtom, EarliestDeparture),
    atom_to_time(LatestArrivalAtom, LatestArrival).

json_to_destination(Locations, Name, Destination) :-
    nth1(Destination, Locations, Name).

% -----------------------------------------------------------------------------
% Program input
% -----------------------------------------------------------------------------

read_data(data(Trips, Destinations, Students, MinimumUsefulTime, Locations)) :-
    read_flights_json(Jf),
    setof(Location, Trip^Attribute^(
        member(Trip, Jf),
        member(Attribute, [origin, destination]),
        object_attribute_value(Trip, Attribute, Location)
    ), Locations),
    read_students_json(Js),
    object_attribute_value(Js, students, Ss),
    object_attribute_value(Js, minimumTime, MinimumUsefulTime),
    object_attribute_value(Js, destinations, Ds),
    json_to_list_of_destinations(Locations, Ds, Destinations),
    json_to_list_of_trips(Locations, Jf, HeterogeneousTrips),
    add_homogeneous_trips(HeterogeneousTrips, Locations, Trips),
    json_to_list_of_students(Locations, Ss, Students).

add_homogeneous_trips(Trips, Locations, FinalTrips) :-
    % Calculate the earlier and latest dates
    map(trip_departure, Trips, Departures),
    map(trip_arrival, Trips, Arrivals),
    append(Departures, Arrivals, Datetimes),
    extreme_datetimes(Datetimes, MinDatetime, MaxDatetime),
    datetime_date(MinDatetime, MinDate),
    datetime_date(MaxDatetime, MaxDate),
    predecessor_date(MinDate, DepartureDate),
    successor_date(MaxDate, ArrivalDate),
    DepartureDatetime = datetime(DepartureDate, time(23, 59, 59)),
    ArrivalDatetime = datetime(ArrivalDate, time(0, 0, 0)),
    % Create the dummy trips
    length(Locations, Ls),
    get_homogeneous_trips(Ls, DepartureDatetime, ArrivalDatetime, Th),
    append(Trips, Th, FinalTrips).

get_homogeneous_trips(0, _, _, []).
get_homogeneous_trips(Location, O, I, [To, Ti | Ts]) :-
    To = [Location, Location, O, O, 0, 0, 0],
    Ti = [Location, Location, I, I, 0, 0, 0],
    NextLocation is Location - 1,
    get_homogeneous_trips(NextLocation, O, I, Ts).
