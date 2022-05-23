% -----------------------------------------------------------------------------
% Data structure
% -----------------------------------------------------------------------------

% data(Trips, Destinations, Students, MinimumUsefulTime, Locations)

data_trips(data(T, _, _, _, _), T).
data_destinations(data(_, D, _, _, _), D).
data_students(data(_, _, S, _, _), S).
data_minimum_useful_time(data(_, _, _, M, _), M).
data_locations(data(_, _, _, _, L), L).
