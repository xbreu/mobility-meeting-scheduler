:- consult('./utils.pl').

:- use_module(library(clpfd)).
:- use_module(library(json)).
:- use_module(library(lists)).
:- use_module(library(system)).

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

read_json_from_file(F, R) :-
    read_file(F, Cs),
    json_from_codes(Cs, R).

read_flights_json(R) :-
    read_json_from_file('data/old/flights.json', R).

read_students_json(R) :-
    read_json_from_file('data/old/students.json', R).

% -----------------------------------------------------------------------------
% Date parsing
% -----------------------------------------------------------------------------

digits_to_number(L, N) :-
    digits_to_number(L, 0, N).

digits_to_number([], N, N).
digits_to_number([H | T], A, N) :-
    B is A * 10 + H,
    digits_to_number(T, B, N).

number(N) --> digits(Ds), {digits_to_number(Ds, N)}.

digits([D]) --> digit(D).
digits([D | N]) --> digit(D), digits(N).

digit(X) --> [C], {"0" =< C, C =< "9", X is C - "0"}.

% "05/05/2022, 08:40:00" = Day/Month/Year, Hour:Minutes/Seconds
date(Y, Mon, D, Hr, Min, Sec) -->
    number(D), "/",
    number(Mon), "/",
    number(Y), ", ",
    number(Hr), ":",
    number(Min), ":",
    number(Sec).

chars_timestamp(S, Ts) :-
    phrase(date(Y, Mon, D, Hr, Min, Sec), S),
    datime(TsI, datime(Y, Mon, D, Hr, Min, Sec)),
    Ts is TsI + 3600.

atom_number(Atom, Number) :-
    atom_codes(Atom, S),
    phrase(number(Number), S).

atom_hours_timestamp(A, Ts) :-
    atom_codes(A, S),
    append("01/01/1970, ", S, Dt),
    chars_timestamp(Dt, Ts).

atom_start_of_date_timestamp(A, Ts) :-
    atom_codes(A, S),
    append(S, ", 00:00:00", Dt),
    chars_timestamp(Dt, Ts).

atom_end_of_date_timestamp(A, Ts) :-
    atom_codes(A, S),
    append(S, ", 23:59:59", Dt),
    chars_timestamp(Dt, Ts).

atom_timestamp(A, Ts) :-
    atom_codes(A, S),
    chars_timestamp(S, Ts).

atom_list_timestamps(List, Timestamps) :-
    atom_list_timestamps(List, []-[], Timestamps).

atom_list_timestamps([], A1-A2, A1-A2).
atom_list_timestamps([[Start, End] | T], A1-A2, R) :-
    atom_start_of_date_timestamp(Start, Tss),
    atom_end_of_date_timestamp(End, Tse),
    atom_list_timestamps(T, [Tss | A1]-[Tse | A2], R).

% -----------------------------------------------------------------------------
% Json to PROLOG's native structures
% -----------------------------------------------------------------------------

flights_to_lists(Json, Locations, Flights) :-
    flights_to_lists(Json, [], Locations, [[], [], [], [], [], [], []], Flights).

flights_to_lists([], Al, Al, Af, Af).
flights_to_lists([json([origin=Origin,destination=Destination,departure=Departure,arrival=Arrival,duration=Duration,price=PriceAtom,stops=Stops])
                 | Fs], Al, Rl, [Origins, Destinations, Departures, Arrivals, Durations, Prices, Stopss], Result) :-
    insert(Al, Origin, Alo),
    nth1(OriginI, Alo, Origin),
    insert(Alo, Destination, Aln),
    nth1(DestinationI, Aln, Destination),
    atom_timestamp(Departure, DepartureTs),
    atom_timestamp(Arrival, ArrivalTs),
    atom_number(PriceAtom, Price),
    flights_to_lists(Fs, Aln, Rl, [[OriginI | Origins], [DestinationI | Destinations], [DepartureTs | Departures], [ArrivalTs | Arrivals], [Duration | Durations], [Price | Prices], [Stops | Stopss]], Result).

students_to_lists(Json, Locations, Students) :-
    students_to_lists(Json, Locations, [[], [], [], [], [], [], []], Students).

students_to_lists([], _, As, As).
students_to_lists([json([city=City,availability=Availability,maxConnections=MC,maxDuration=MD,earliestDeparture=ED,latestArrival=LA])
                  | Ss], Ls, [Cities, Isss, Iess, MCs, MDs, EDs, LAs], Rs) :-
    nth1(Ci, Ls, City),
    atom_list_timestamps(Availability, Iss-Ies),
    atom_hours_timestamp(ED, EDts),
    atom_hours_timestamp(LA, LAts),
    students_to_lists(Ss, Ls, [[Ci | Cities], [Iss | Isss], [Ies | Iess], [MC | MCs], [MD | MDs], [EDts | EDs], [LAts | LAs]], Rs).

destinations_to_list(Destinations, Locations, Result) :-
    destinations_to_list(Destinations, Locations, [], Result).

destinations_to_list([], _, A, A).
destinations_to_list([D | Ds], Ls, A, R) :-
    nth1(Di, Ls, D),
    destinations_to_list(Ds, Ls, [Di | A], R).

% -----------------------------------------------------------------------------
% Dummy flights
% -----------------------------------------------------------------------------

homogeneous_flights([], _, Acc, Acc).
homogeneous_flights([City | Cities], [Iss | Isss]-[Ies | Iess]-[ED | EDs]-[LA | LAs], Acc, Result) :-
    add_flight_per_interval(City, ED-LA, Iss-Ies, Acc, Accn),
    homogeneous_flights(Cities, Isss-Iess-EDs-LAs, Accn, Result).

add_flight_per_interval(_, _, []-[], Acc, Acc).
add_flight_per_interval(City, ED-LA, [Is | Iss]-[Ie | Ies],
    [Origins, Destinations, Departures, Arrivals, Durations, Prices, Stopss], Result) :-
    Isd is Is + ED,
    Iea is Ie - (86400 - LA),
    add_flight_per_interval(City, ED-LA, Iss-Ies,
        [[City, City | Origins], [City, City | Destinations],
        [Isd, Iea | Departures], [Isd, Iea | Arrivals], [0, 0 | Durations],
        [0, 0 | Prices], [0, 0 | Stopss]], Result).

% -----------------------------------------------------------------------------
% Data structures
% -----------------------------------------------------------------------------

data_flight_origins([[Origins | _] | _], Origins).
data_flight_destinations([[_, Destinations | _] | _], Destinations).
data_flight_departures([[_, _, Departures | _] | _], Departures).
data_flight_arrivals([[_, _, _, Arrivals | _] | _], Arrivals).
data_flight_durations([[_, _, _, _, Durations | _] | _], Durations).
data_flight_prices([[_, _, _, _, _, Prices | _] | _], Prices).
data_flight_connections([[_, _, _, _, _, _, Stopss | _] | _], Stopss).

data_students_cities([_, _, [Cities | _] | _], Cities).
data_students_availability_starts([_, _, [_, AvailabilityStarts | _] | _], AvailabilityStarts).
data_students_availability_ends([_, _, [_, _, AvailabilityEnds | _] | _], AvailabilityEnds).
data_students_maximum_connections([_, _, [_, _, _, MaximumConnections | _] | _], MaximumConnections).
data_students_maximum_durations([_, _, [_, _, _, _, MaximumDurations | _] | _], MaximumDurations).
data_students_earliest_departures([_, _, [_, _, _, _, _, EarliestDepartures | _] | _], EarliestDepartures).
data_students_latest_arrivals([_, _, [_, _, _, _, _, _, LatestArrivals | _] | _], LatestArrivals).

data_possible_destinations([_, PossibleDestinations | _], PossibleDestinations).
data_minimum_useful_time([_, _, _, MinimumUsefulTime | _], MinimumUsefulTime).
data_locations([_, _, _, _, Locations | _], Locations).

read_data([Fs, Dis, [Cities, Isss, Iess, MCs, MDs, EDs, LAs], MUT, Ls]) :-
    read_flights_json(Fj), !,
    read_students_json(json([students=Sj,minimumTime=MUT,destinations=Ds])), !,
    flights_to_lists(Fj, Ls, FsHeterogeneous),
    students_to_lists(Sj, Ls, [Cities, Isss, Iess, MCs, MDs, EDs, LAs]),
    homogeneous_flights(Cities, Isss-Iess-EDs-LAs, FsHeterogeneous, Fs),
    destinations_to_list(Ds, Ls, DisI),
    list_to_fdset(DisI, Dis).
