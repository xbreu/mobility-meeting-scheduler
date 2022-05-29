% -----------------------------------------------------------------------------
% Student structure
% -----------------------------------------------------------------------------

% student(City, Availability, MaxConnections, MaxDuration,
%         EarliestDeparture, LatestArrival)

student_city(student(C, _, _, _, _, _), C).
student_availability(student(_, A, _, _, _, _), A).
student_max_connections(student(_, _, M, _, _, _), M).
student_max_duration(student(_, _, _, M, _, _), M).
student_earliest_departure(student(_, _, _, _, E, _), E).
student_latest_arrival(student(_, _, _, _, _, L), L).
