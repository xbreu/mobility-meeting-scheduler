:- use_module(library(clpfd)).

% -----------------------------------------------------------------------------
% Year operations
% -----------------------------------------------------------------------------

leap_year(Y) :-
    0 = Y mod 4,
    0 \= Y mod 100.

% -----------------------------------------------------------------------------
% Month operations
% -----------------------------------------------------------------------------

days_month(_, 1, 31).
days_month(Y, 2, 29) :-
    leap_year(Y), !.
days_month(_, 2, 28).
days_month(_, 3, 31).
days_month(_, 4, 30).
days_month(_, 5, 31).
days_month(_, 6, 30).
days_month(_, 7, 31).
days_month(_, 8, 31).
days_month(_, 9, 30).
days_month(_, 10, 31).
days_month(_, 11, 30).
days_month(_, 12, 31).

% -----------------------------------------------------------------------------
% Date structure
% -----------------------------------------------------------------------------

% date(Y, M, D)

date_year(date(Y, _, _), Y).
date_month(date(_, M, _), M).
date_day(date(_, _, D), D).

date_to_days(date(Y, M, D), N) :-
    N #= D + 31 * (M + 12 * Y).

earlier_date(date(Y1, M1, D1), date(Y2, M2, D2), date(Y1, M1, D1)) :-
    (
        (
            Y1 < Y2
        ); (
            Y1 = Y2,
            M1 < M2
        ); (
            Y1 = Y2,
            M1 = M2,
            D1 < D2
        )
    ), !.
earlier_date(_, D, D).

later_date(date(Y1, M1, D1), date(Y2, M2, D2), date(Y1, M1, D1)) :-
    (
        (
            Y1 > Y2
        ); (
            Y1 = Y2,
            M1 > M2
        ); (
            Y1 = Y2,
            M1 = M2,
            D1 > D2
        )
    ), !.
later_date(_, D, D).

predecessor_date(date(Y, M, D), date(Y, M, Dr)) :-
    D > 2, !,
    Dr is D - 1.
predecessor_date(date(Y, M, D), date(Y, Mr, Dr)) :-
    M > 2, !,
    Mr is M - 1,
    days_month(Y, Mr, Dr).
predecessor_date(date(Y, M, D), date(Yr, 12, 31)) :-
    Yr is Y - 1.

successor_date(date(Y, M, D), date(Y, M, Dr)) :-
    days_month(Y, M, Dm),
    D < Dm - 1, !,
    Dr is D + 1.
successor_date(date(Y, M, D), date(Y, Mr, 1)) :-
    M < 12, !,
    Mr is M + 1.
successor_date(date(Y, M, D), date(Yr, 1, 1)) :-
    Yr is Y + 1.

% -----------------------------------------------------------------------------
% Time structure
% -----------------------------------------------------------------------------

% time(Hs, Ms, Ss)

time_hours(time(H, _, _), H).
time_minutes(time(_, M, _), M).
time_seconds(time(_, _, S), S).

time_to_seconds(time(H, M, S), N) :-
    N #= S + 60 * (M + 60 * H).

earlier_hour(time(H1, M1, S1), time(H2, M2, S2), time(H1, M1, S1)) :-
    (
        (
            H1 < H2
        ); (
            H1 = H2,
            M1 < M2
        ); (
            H1 = H2,
            M1 = M2,
            S1 < S2
        )
    ), !.
earlier_hour(_, H, H).

later_hour(time(H1, M1, S1), time(H2, M2, S2), time(H1, M1, S1)) :-
    (
        (
            H1 > H2
        ); (
            H1 = H2,
            M1 > M2
        ); (
            H1 = H2,
            M1 = M2,
            S1 > S2
        )
    ), !.
later_hour(_, H, H).

restrict_earlier_time(time(H1, M1, S1), time(H2, M2, S2)) :-
    (H1 - H2) * 60 + (M1 - M2) * 60 + S1 - S2 #=< 0.

restrict_later_time(time(H1, M1, S1), time(H2, M2, S2)) :-
    (H1 - H2) * 60 + (M1 - M2) * 60 + S1 - S2 #>= 0.

% -----------------------------------------------------------------------------
% Datetime structure
% -----------------------------------------------------------------------------

% datetime(date(Y, M, D), time(Hs, Ms, Ss))

datetime_date(datetime(D, _), D).
datetime_time(datetime(_, T), T).
datetime_year(datetime(date(Y, _, _), _), Y).
datetime_month(datetime(date(_, M, _), _), M).
datetime_day(datetime(date(_, _, D), _), D).
datetime_hours(datetime(_, time(H, _, _)), H).
datetime_minutes(datetime(_, time(_, M, _)), M).
datetime_seconds(datetime(_, time(_, _, S)), S).

datetime_to_seconds(datetime(D, T), N) :-
    date_to_days(D, Nd),
    time_to_seconds(T, Nt),
    N #= Nt + 86400 * Nd.

earlier_datetime(datetime(D1, T1), datetime(D2, T2), datetime(D1, T1)) :-
    (
        (
            earlier_date(D1, D2, D1)
        ); (
            D1 = D2,
            earlier_hour(H1, H2, H1)
        )
    ), !.
earlier_datetime(_, D, D).

later_datetime(datetime(D1, T1), datetime(D2, T2), datetime(D1, T1)) :-
    (
        (
            later_date(D1, D2, D1)
        ); (
            D1 = D2,
            later_hour(H1, H2, H1)
        )
    ), !.
later_datetime(_, D, D).

extreme_datetimes([Datetime | Datetimes], Min, Max) :-
    extreme_datetimes(Datetimes, Datetime, Datetime, Min, Max).

extreme_datetimes([], Min, Max, Min, Max).
extreme_datetimes([H | T], AMin, AMax, Min, Max) :-
    earlier_datetime(AMin, H, IMin),
    later_datetime(AMax, H, IMax),
    extreme_datetimes(T, IMin, IMax, Min, Max).

earliest_datetime([H | T], R) :-
    earliest_datetime(T, H, R).

earliest_datetime([], A, A).
earliest_datetime([H | T], A, R) :-
    earlier_datetime(A, H, I),
    earliest_datetime(T, I, R).

latest_datetime([H | T], R) :-
    latest_datetime(T, H, R).

latest_datetime([], A, A).
latest_datetime([H | T], A, R) :-
    later_datetime(A, H, I),
    latest_datetime(T, I, R).
