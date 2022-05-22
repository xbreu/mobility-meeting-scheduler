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
