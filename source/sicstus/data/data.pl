% -----------------------------------------------------------------------------
% Data structure
% -----------------------------------------------------------------------------

% data(Trips, Destinations, Students, MinimumUsefulTime, Locations)

data_trips(data(T, _, _, _, _, _), T).
data_destinations(data(_, D, _, _, _, _), D).
data_students(data(_, _, S, _, _, _), S).
data_minimum_useful_time(data(_, _, _, M, _, _), M).
data_locations(data(_, _, _, _, L, _), L).
data_number_of_heterogeneous_trips(data(_, _, _, _, _, H), H).
