:- use_module(library(clpfd)).

% -----------------------------------------------------------------------------
% Date structure
% -----------------------------------------------------------------------------

% date(Y, M, D)

date_year(date(Y, _, _), Y).
date_month(date(_, M, _), M).
date_day(date(_, _, D), D).

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

% -----------------------------------------------------------------------------
% Time structure
% -----------------------------------------------------------------------------

% time(Hs, Ms, Ss)

time_hours(time(H, _, _), H).
time_minutes(time(_, M, _), M).
time_seconds(time(_, _, S), S).

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

earliest_datetime([], A, A).
earliest_datetime([H | T], A, R) :-
    earlier_datetime(A, H, I),
    earliest_datetime(T, I, R).

latest_datetime([], A, A).
latest_datetime([H | T], A, R) :-
    later_datetime(A, H, I),
    latest_datetime(T, I, R).
