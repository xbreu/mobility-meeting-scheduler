:- use_module(library(json)).
:- use_module(library(lists)).

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
    date(Y, M, D), ", ", time(Hs, Ms, Ss).

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

atom_to_time(A, time(Hs, Ms, Ss)) :-
    atom_string(A, S),
    phrase(time(Hs, Ms, Ss), S).

% -----------------------------------------------------------------------------
% Json to PROLOG's native structures
% -----------------------------------------------------------------------------

object_attribute_value(json(J), K, V) :-
    member(K=V, J).

json_to_list_of_trips([], []).
json_to_list_of_trips([J | Js], [T | Ts]) :-
    json_to_trip(J, T),
    json_to_list_of_trips(Js, Ts).

json_to_trip(J,
    trip(Origin, Destination, Departure, Arrival, Duration, Price, Stops)) :-
    object_attribute_value(J, origin, Origin),
    object_attribute_value(J, destination, Destination),
    object_attribute_value(J, departure, DepartureAtom),
    object_attribute_value(J, arrival, ArrivalAtom),
    object_attribute_value(J, duration, Duration),
    object_attribute_value(J, price, PriceAtom),
    object_attribute_value(J, stops, Stops),

    % Parsing of some attributes
    atom_to_datetime(DepartureAtom, Departure),
    atom_to_datetime(ArrivalAtom, Arrival),
    atom_to_number(PriceAtom, Price).
