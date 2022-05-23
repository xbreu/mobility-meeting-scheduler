:- consult('./datetime.pl').

% -----------------------------------------------------------------------------
% Trip structure
% -----------------------------------------------------------------------------

% [Origin, Destination, Departure, Arrival, Duration, Price, Stops]

trip_origin([O, _, _, _, _, _, _], O).
trip_destination([_, D, _, _, _, _, _], D).
trip_departure([_, _, D, _, _, _, _], D).
trip_arrival([_, _, _, A, _, _, _], A).
trip_duration([_, _, _, _, D, _, _], D).
trip_price([_, _, _, _, _, P, _], P).
trip_stops([_, _, _, _, _, _, S], S).

trip_departure_date(Trip, Date) :-
    trip_departure(Trip, Departure),
    datetime_date(Departure, Date).

trip_arrival_date(Trip, Date) :-
    trip_arrival(Trip, Arrival),
    datetime_date(Arrival, Date).

trip_departure_time(Trip, Hour) :-
    trip_departure(Trip, Departure),
    datetime_time(Departure, Hour).

trip_arrival_time(Trip, Hour) :-
    trip_arrival(Trip, Arrival),
    datetime_time(Arrival, Hour).
