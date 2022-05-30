:- consult('./utils.pl').

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
    atom_list_timestamps(List, [], Timestamps).

atom_list_timestamps([], A, A).
atom_list_timestamps([[Start, End] | T], A, R) :-
    atom_start_of_date_timestamp(Start, Tss),
    atom_end_of_date_timestamp(Start, Tse),
    atom_list_timestamps(T, [[Tss, Tse] | A], R).

% -----------------------------------------------------------------------------
% Json to PROLOG's native structures
% -----------------------------------------------------------------------------

flights_to_lists(Json, Locations, Flights) :-
    flights_to_lists(Json, [], Locations, [[], [], [], [], [], [], []], Flights).

flights_to_lists([], Al, Al, Af, Af).
flights_to_lists([json([origin=Origin,destination=Destination,departure=Departure,arrival=Arrival,duration=Duration,price=Price,stops=Stops])
                 | Fs], Al, Rl, [Origins, Destinations, Departures, Arrivals, Durations, Prices, Stopss], Result) :-
    insert(Al, Origin, Alo),
    nth1(OriginI, Alo, Origin),
    insert(Alo, Destination, Aln),
    nth1(DestinationI, Aln, Destination),
    atom_timestamp(Departure, DepartureTs),
    atom_timestamp(Arrival, ArrivalTs),
    flights_to_lists(Fs, Aln, Rl, [[OriginI | Origins], [DestinationI | Destinations], [DepartureTs | Departures], [ArrivalTs | Arrivals], [Duration | Durations], [Price | Prices], [Stops | Stopss]], Result).

students_to_lists(Json, Locations, Students) :-
    students_to_lists(Json, Locations, [[], [], [], [], [], []], Students).

students_to_lists([], _, As, As).
students_to_lists([json([city=City,availability=Availability,maxConnections=MC,maxDuration=MD,earliestDeparture=ED,latestArrival=LA])
                  | Ss], Ls, As, Rs) :-
    nth1(Ci, Ls, C),
    atom_list_timestamps(Availability, Is),
    atom_hours_timestamp(ED, EDts),
    atom_hours_timestamp(LA, LAts),
    print([Ci, Is, MC, MD, EDts, LAts]).

% -----------------------------------------------------------------------------
% Input reading
% -----------------------------------------------------------------------------

read_data(data(Fs, Ss, MUT, Dis, Ls)) :-
    read_flights_json(Fj), !,
    read_students_json(json([students=Sj,minimumTime=MUT,destinations=Ds])), !,
    flights_to_lists(Fj, Ls, Fs),
    students_to_lists(Sj, Ls, Ss),
    Dis = Ds.
