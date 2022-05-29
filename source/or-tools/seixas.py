from ortools.sat.python import cp_model
import json
from datetime import datetime


SOLVER_TIME_LIMIT = 2000

MAXIMUM_FLIGHT_COST = 2500
MAXIMUM_USEFUL_TIME = 2628288
MAX_INT = 99999999999999
# Import students information
file = open('../../data/students.json')

input = json.load(file)

DESTINATIONS = input['destinations']
MINIMUM_USEFUL_TIME = input['minimumTime']
STUDENTS_INFO = input['students']
N_STUDENTS = len(STUDENTS_INFO)

STUDENTS_ORIGINS = [DESTINATIONS.index(x) for x in [student["city"] for student in STUDENTS_INFO]]
STUDENTS_STOPS = [student["maxConnections"] for student in STUDENTS_INFO]
STUDENTS_DURATIONS = [student["maxDuration"] for student in STUDENTS_INFO]
STUDENTS_DEPARTURES = [int(round(datetime.strptime(student["earliestDeparture"], '%H:%M:%S').timestamp())) for student in STUDENTS_INFO]
STUDENTS_ARRIVALS = [int(round(datetime.strptime(student["latestArrival"], '%H:%M:%S').timestamp())) for student in STUDENTS_INFO]

STUDENTS_START_AVAILABILITIES = []
STUDENTS_END_AVAILABILITIES = []
for student in STUDENTS_INFO:
    studentStarts = []
    studentEnds = []
    for start, end in student["availability"]:
        studentStarts.append(int(round(datetime.strptime(start, '%d/%m/%Y').timestamp())))
        studentEnds.append(int(round(datetime.strptime(end, '%d/%m/%Y').timestamp())))
    STUDENTS_START_AVAILABILITIES.append(studentStarts)
    STUDENTS_END_AVAILABILITIES.append(studentEnds)

N_MAX_INTERVALS = max([int(len(x) / 2) for x in STUDENTS_START_AVAILABILITIES])

print("Imported", N_STUDENTS, "students,", len(DESTINATIONS), "destinations and the minimum time.")


# Import flights
file = open('../../data/flights2.json')

FLIGHTS = json.load(file)

FLIGHTS_ORIGINS = [DESTINATIONS.index(x) for x in [flight["origin"] for flight in FLIGHTS]]
FLIGHTS_DESTINATIONS = [DESTINATIONS.index(x) for x in [flight["destination"] for flight in FLIGHTS]]

FLIGHTS_DEPARTURES = [int(round(datetime.strptime(flight["departure"], '%d/%m/%Y, %H:%M:%S').timestamp())) for flight in FLIGHTS]
FLIGHTS_DEPARTURE_TIMES = [int(round(datetime.strptime(datetime.fromtimestamp(departure).time().isoformat(), '%H:%M:%S').timestamp())) for departure in FLIGHTS_DEPARTURES]

FLIGHTS_ARRIVALS = [int(round(datetime.strptime(flight["arrival"], '%d/%m/%Y, %H:%M:%S').timestamp())) for flight in FLIGHTS]
FLIGHTS_ARRIVAL_TIMES = [int(round(datetime.strptime(datetime.fromtimestamp(arrival).time().isoformat(), '%H:%M:%S').timestamp())) for arrival in FLIGHTS_ARRIVALS]

FLIGHTS_DURATIONS = [flight["duration"] for flight in FLIGHTS]
FLIGHTS_COSTS = [int(flight["price"]) for flight in FLIGHTS]
FLIGHTS_STOPS = [flight["stops"] for flight in FLIGHTS]

print("Imported", len(FLIGHTS), "flights!")


model = cp_model.CpModel()

# Chosen Destination
Destination = model.NewIntVar(0, len(DESTINATIONS) - 1, 'Destination') #model.integer_var(0, len(DESTINATIONS) - 1, "Destination")

# Indexes of the flights each student has to take
StudentsFlights = [[model.NewIntVar(0, len(FLIGHTS) - 1, 'Outgoing_Flight'), model.NewIntVar(0, len(FLIGHTS) - 1, 'Incoming_Flight')] for _ in range(N_STUDENTS)] #[model.integer_var_list(2, 0, len(FLIGHTS) - 1) for i in range(N_STUDENTS)]

# Student avaliability interval
StudentsAvailabilityIntervals = [model.NewIntVar(0, N_MAX_INTERVALS, 'Interval') for _ in range(N_STUDENTS)] #model.integer_var_list(N_STUDENTS, 0, N_MAX_INTERVALS, "Interval")

# Cost for each of the students
StudentsCosts = [model.NewIntVar(0, MAXIMUM_FLIGHT_COST, 'StudentCost') for _ in range(N_STUDENTS)] #model.integer_var_list(N_STUDENTS, 0, MAXIMUM_FLIGHT_COST, "StudentCost")

# Total trip cost
TotalCost = model.NewIntVar(0, MAXIMUM_FLIGHT_COST*N_STUDENTS, 'TotalCost') #model.integer_var(0, MAXIMUM_FLIGHT_COST * N_STUDENTS, "TotalCost")

# Useful time
UsefulTime = model.NewIntVar(MINIMUM_USEFUL_TIME, MAXIMUM_USEFUL_TIME, 'UsefulTime') #model.integer_var(0, MAXIMUM_USEFUL_TIME, "UsefulTime")

# Separated Time
SeparatedTime = model.NewIntVar(-MAX_INT, MAX_INT, 'SeparatedTime') #model.integer_var(0, MAXIMUM_USEFUL_TIME, "SeparatedTime")

def element(model, vars, index):
    t = model.NewIntVar(-MAX_INT, MAX_INT, 'temp')
    model.AddElement(index, vars, t)
    return t

first_outgoing_times = [model.NewIntVar(0, MAX_INT, 'first_out_time') for i in range(N_STUDENTS)]
last_outgoing_times = [model.NewIntVar(0, MAX_INT, 'last_out_time') for i in range(N_STUDENTS)]
first_incoming_times = [model.NewIntVar(0, MAX_INT, 'first_inc_time') for i in range(N_STUDENTS)]
last_incoming_times = [model.NewIntVar(0, MAX_INT, 'last_inc_time') for i in range(N_STUDENTS)]
for i in range(N_STUDENTS):
    Outgoing, Incoming = StudentsFlights[i]
    StudentOrigin = STUDENTS_ORIGINS[i]

    student_from_outside_destination = model.NewBoolVar('student_from_outside_destination')
    model.Add(StudentOrigin != Destination).OnlyEnforceIf(student_from_outside_destination)
    model.Add(StudentOrigin == Destination).OnlyEnforceIf(student_from_outside_destination.Not())

    # Origin of the flights
    out = element(model, FLIGHTS_ORIGINS, Outgoing)
    inc = element(model, FLIGHTS_ORIGINS, Incoming)
    model.Add(out == StudentOrigin).OnlyEnforceIf(student_from_outside_destination)
    model.Add(inc == Destination).OnlyEnforceIf(student_from_outside_destination)

    # Destination of the flights
    out = element(model, FLIGHTS_DESTINATIONS, Outgoing)
    inc = element(model, FLIGHTS_DESTINATIONS, Incoming)
    model.Add(out == Destination).OnlyEnforceIf(student_from_outside_destination)
    model.Add(inc == StudentOrigin).OnlyEnforceIf(student_from_outside_destination)

    # Availability
    startAvailability = element(model, STUDENTS_START_AVAILABILITIES[i], StudentsAvailabilityIntervals[i])
    endAvailability = element(model, STUDENTS_END_AVAILABILITIES[i], StudentsAvailabilityIntervals[i])
    out = element(model, FLIGHTS_DEPARTURES, Outgoing)
    inc = element(model, FLIGHTS_ARRIVALS, Incoming)
    model.Add(out >= startAvailability)
    model.Add(inc <= endAvailability)

    # Outgoing arrival time must be before Incoming departure time
    out = element(model, FLIGHTS_ARRIVALS, Outgoing)
    inc = element(model, FLIGHTS_DEPARTURES, Incoming)
    model.Add(out < inc).OnlyEnforceIf(student_from_outside_destination) 

    # Earliest departure
    out = element(model, FLIGHTS_DEPARTURE_TIMES, Outgoing)
    inc = element(model, FLIGHTS_DEPARTURE_TIMES, Incoming)
    student_departure = element(model, STUDENTS_DEPARTURES, i)
    model.Add(out >= student_departure).OnlyEnforceIf(student_from_outside_destination)
    model.Add(inc >= student_departure).OnlyEnforceIf(student_from_outside_destination)

    # Latest arrival
    out = element(model, FLIGHTS_ARRIVAL_TIMES, Outgoing)
    inc = element(model, FLIGHTS_ARRIVAL_TIMES, Incoming)
    student_arrival = element(model, STUDENTS_ARRIVALS, i)
    model.Add(out <= student_arrival).OnlyEnforceIf(student_from_outside_destination)
    model.Add(inc <= student_arrival).OnlyEnforceIf(student_from_outside_destination)

    # Maximum number of stops
    out = element(model, FLIGHTS_STOPS, Outgoing)
    inc = element(model, FLIGHTS_STOPS, Incoming)
    student_stops = element(model, STUDENTS_STOPS, i)
    model.Add(out <= student_stops).OnlyEnforceIf(student_from_outside_destination)
    model.Add(inc <= student_stops).OnlyEnforceIf(student_from_outside_destination)

    # Maximum flight duration
    out = element(model, FLIGHTS_DURATIONS, Outgoing)
    inc = element(model, FLIGHTS_DURATIONS, Incoming)
    student_duration = element(model, STUDENTS_DURATIONS, i)
    model.Add(out < student_duration).OnlyEnforceIf(student_from_outside_destination)
    model.Add(inc < student_duration).OnlyEnforceIf(student_from_outside_destination)

    # Student Cost
    out_cost = element(model, FLIGHTS_COSTS, StudentsFlights[i][0])
    inc_cost = element(model, FLIGHTS_COSTS, StudentsFlights[i][1])
    model.Add(inc_cost + out_cost == StudentsCosts[i]).OnlyEnforceIf(student_from_outside_destination)
    model.Add(StudentsCosts[i] == 0).OnlyEnforceIf(student_from_outside_destination.Not())

    # First outgoing times 
    out_time = element(model, first_outgoing_times, i)
    time = element(model, FLIGHTS_ARRIVALS, StudentsFlights[i][0])
    model.Add(out_time == time).OnlyEnforceIf(student_from_outside_destination)
    model.Add(out_time == MAX_INT).OnlyEnforceIf(student_from_outside_destination.Not())

    # Last outgoing times 
    out_time = element(model, last_outgoing_times, i)
    time = element(model, FLIGHTS_ARRIVALS, StudentsFlights[i][0])
    model.Add(out_time == time).OnlyEnforceIf(student_from_outside_destination)
    model.Add(out_time == 0).OnlyEnforceIf(student_from_outside_destination.Not())

    # First incoming times
    inc_time = element(model, first_incoming_times, i)
    time = element(model, FLIGHTS_DEPARTURES, StudentsFlights[i][1])
    model.Add(inc_time == time).OnlyEnforceIf(student_from_outside_destination)
    model.Add(inc_time == MAX_INT).OnlyEnforceIf(student_from_outside_destination.Not())

    # Last incoming times
    inc_time = element(model, last_incoming_times, i)
    time = element(model, FLIGHTS_DEPARTURES, StudentsFlights[i][1])
    model.Add(inc_time == time).OnlyEnforceIf(student_from_outside_destination)
    model.Add(inc_time == 0).OnlyEnforceIf(student_from_outside_destination.Not())


firstOutgoingTime = model.NewIntVar(0, MAX_INT, 'first_out')
model.AddMinEquality(firstOutgoingTime, first_outgoing_times)
lastOutgoingTime = model.NewIntVar(0, MAX_INT, 'last_out')
model.AddMaxEquality(lastOutgoingTime, last_outgoing_times)
firstIncomingTime = model.NewIntVar(0, MAX_INT, 'first_inc')
model.AddMinEquality(firstIncomingTime, first_incoming_times)
lastIncomingTime = model.NewIntVar(0, MAX_INT, 'last_inc')
model.AddMaxEquality(lastIncomingTime, last_incoming_times)

# Useful Time
model.Add(UsefulTime == firstIncomingTime - lastOutgoingTime)
model.Add(UsefulTime >= MINIMUM_USEFUL_TIME)

# Separated Time
model.Add(SeparatedTime == (lastOutgoingTime - firstOutgoingTime) + (lastIncomingTime - firstIncomingTime))

# Total cost
model.Add(TotalCost == sum(StudentsCosts))

# Minimize function
function = model.NewIntVar(0, MAX_INT, 'function')
# model.Add(function == TotalCost + UsefulTime - SeparatedTime)
model.AddDivisionEquality(function, TotalCost*1000000000, UsefulTime)
model.Minimize(function)


solver = cp_model.CpSolver()
status = solver.Solve(model)
# print(solver._CpSolver__solution)
print(solver.ResponseStats())
# print("status: " + solver.StatusName())
# print("wallTime: " + str(solver.WallTime()))
# print("userTime: " + str(solver.UserTime()))
if status == cp_model.OPTIMAL or status == cp_model.FEASIBLE:
    print("--> Function: " + str(solver.Value(function)))
    print("--> Destination: " + DESTINATIONS[solver.Value(Destination)])
    print("--> Total Cost: " + str(solver.Value(TotalCost)))
    print("--> Useful Time: " + str(solver.Value(UsefulTime)))
    print("--> Separated Time: " + str(solver.Value(SeparatedTime)))
    print("--> Students:")

    for i in range(N_STUDENTS):
        Outgoing, Incoming = StudentsFlights[i]

        print("    --> Student " + str(i + 1) + " departing from " + STUDENTS_INFO[i]["city"] + ":")

        if STUDENTS_ORIGINS[i] == solver.Value(Destination):
            print("       - Student need not to take any flights!")
        else:
            print("       -", list(FLIGHTS[solver.Value(Outgoing)].items())[2:])
            print("       -", list(FLIGHTS[solver.Value(Incoming)].items())[2:])