:- consult('./data.pl').

% -----------------------------------------------------------------------------
% Plan structure
% -----------------------------------------------------------------------------

% [OutgoingTripIndex, IncomingTripIndex]

plan_outgoing_trip([O, _], O).
plan_incoming_trip([_, I], I).

create_plans(Data, Plans) :-
    data_students(Data, Students),
    length(Students, PlansSize),
    length(Plans, PlansSize).

% -----------------------------------------------------------------------------
% Structure combinations
% -----------------------------------------------------------------------------

data_plan_outgoing_trip(Data, Plan, Trip) :-
    plan_outgoing_trip(Plan, O),
    data_trips(Data, Trips),
    nth1(O, Trips, Trip).

data_plan_incoming_trip(Data, Plan, Trip) :-
    plan_incoming_trip(Plan, I),
    data_trips(Data, Trips),
    nth1(I, Trips, Trip).
