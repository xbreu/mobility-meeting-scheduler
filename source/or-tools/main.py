from datetime import datetime
import math
from typing import List
from ortools.sat.python import cp_model
from flight import Flight
from student import Student
import json

epoch = datetime.utcfromtimestamp(0)

def count(model: cp_model.CpModel, vars, value):
    '''
    Returns the count of 'value' in 'vars' 
    '''
    value = model.NewConstant(value)
    trues = [model.NewIntVar(0, 1, 'true' + str(i)) for i in range(len(vars))]
    for i in range(len(vars)):
        equal = model.NewBoolVar('equal')
        model.Add(vars[i] == value).OnlyEnforceIf(equal)
        model.Add(vars[i] != value).OnlyEnforceIf(equal.Not())

        model.Add(trues[i] == 1).OnlyEnforceIf(equal)
        model.Add(trues[i] == 0).OnlyEnforceIf(equal.Not())

    return sum(trues)


f = open("../../data/flights.json")
json_flights = json.load(f)

f = open("../../data/students.json")
data = json.load(f)

json_students = data['students']
minimum_time = data['minimumTime']
destinations = data['destinations']
origins = [student['city'] for student in json_students]

date_format = '%d/%m/%Y, %H:%M:%S '


flights: List[Flight] = []
for flight in json_flights:
    outgoing = datetime.strptime(flight['departure'], date_format)
    incoming = datetime.strptime(flight['arrival'], date_format)
    flights.append(Flight(flight['origin'], flight['destination'], outgoing, incoming, flight['duration'], int(flight['price']), flight['stops']))

students: List[Student] = []
for student in json_students:
    availability = [[datetime.strptime(date1, "%d/%m/%Y"), (datetime.strptime(date2, "%d/%m/%Y"))] for [date1, date2] in student['availability']]
    earliest_departure = datetime.strptime(student['earliestDeparture'], '%H:%M:%S')
    latest_arrival = datetime.strptime(student['latestArrival'], '%H:%M:%S')
    students.append(Student(student['city'], availability, student['maxConnections'], student['maxDuration'], earliest_departure, latest_arrival))

model = cp_model.CpModel()

output_flights = [model.NewIntVar(-len(students), len(students), str(i)) for i in range(len(flights))]

output_destinations = [model.NewIntVar(
    0, 1, destination) for destination in destinations]

# Only 1 destination is the destination of the group
model.Add(count(model, output_destinations, 1) == 1)

# each student has 1 outgoing and 1 incoming flight
# this only applies if the destination is not the city the student lives in
for i in range(len(students)):
    for j in range(len(destinations)):
        if (students[i].city != destinations[j]):
            b = model.NewBoolVar('b')
            model.Add(output_destinations[j] == 1).OnlyEnforceIf(b)
            model.Add(output_destinations[j] == 0).OnlyEnforceIf(b.Not())
            model.Add(count(model, output_flights, i + 1) == 1).OnlyEnforceIf(b)
            model.Add(count(model, output_flights, -i - 1) == 1).OnlyEnforceIf(b)

for i in range(len(flights)):
    for j in range(len(students)):
        outgoing = j+1
        incoming = -j-1

        # origin must be student city
        if (flights[i].origin != students[j].city):
            model.Add(output_flights[i] != outgoing)
        # destination must be student city
        if (flights[i].destination != students[j].city):
            model.Add(output_flights[i] != incoming)
        # if destination is student city it can't be outgoing flight
        if (flights[i].destination == students[j].city):
            model.Add(output_flights[i] != outgoing)
        # if origin is student city it can't be incoming flight
        if (flights[i].origin == students[j].city):
            model.Add(output_flights[i] != incoming)

        # departure after earliest departure
        if (flights[i].departure.time() < students[j].earliest_departure.time()):
            model.Add(output_flights[i] != outgoing)
        # arrival before latest arrival
        if (flights[i].arrival.time() > students[j].latest_arrival.time()):
            model.Add(output_flights[i] != incoming)

        departure_during_availability = False
        arrival_during_availability = False
        for [d1, d2] in students[j].availability:
            # departure during availability
            if (flights[i].departure.date() < d1.date()
                    or flights[i].departure.date() > d2.date()):
                departure_during_availability = True

            # arrival during availability
            if (flights[i].arrival.date() < d1.date()
                    or flights[i].arrival.date() > d2.date()):
                arrival_during_availability = True
        if not departure_during_availability:
            model.Add(output_flights[i] != incoming)
        if not arrival_during_availability:
            model.Add(output_flights[i] != outgoing)

        # flight must have no more than max_connections
        if (flights[i].stops > students[j].max_connections):
            model.Add(output_flights[i] != outgoing)
            model.Add(output_flights[i] != incoming)

        # flight duration must be less or equal to max_duration
        if (flights[i].duration > students[j].max_duration):
            model.Add(output_flights[i] != outgoing)
            model.Add(output_flights[i] != incoming)


for i in range(len(flights)):
    for j in range(len(destinations)):
        # All outgoing flights must have the same destination
        if (flights[i].destination != destinations[j]):
            group_return = model.NewBoolVar(
                f'group_destination{str(i)}-{str(j)}')
            model.Add(output_destinations[j] == 1).OnlyEnforceIf(group_return)
            model.Add(output_destinations[j] == 0).OnlyEnforceIf(group_return.Not())
            model.Add(output_flights[i] <= 0).OnlyEnforceIf(group_return)

        # All incoming flights must have the same origin
        if (flights[i].origin != destinations[j]):
            group_return = model.NewBoolVar(f'group_return{str(i)}-{str(j)}')
            model.Add(output_destinations[j] == 1).OnlyEnforceIf(group_return)
            model.Add(output_destinations[j] == 0).OnlyEnforceIf(group_return.Not())
            model.Add(output_flights[i] >= 0).OnlyEnforceIf(group_return)

for i in range(len(flights)):
    for j in range(i, len(flights)):
        if (i == j): continue

        # True if flights have absolute equality i.e. either they are not used or are used by the same person
        same_person_flights = model.NewBoolVar(f'same_person_fligths_{str(i)}-{str(j)}')
        model.Add(output_flights[i] == -output_flights[j]).OnlyEnforceIf(same_person_flights)
        model.Add(output_flights[i] != -output_flights[j]).OnlyEnforceIf(same_person_flights.Not())

        # If i is outgoing and j is incoming
        if (flights[i].arrival < flights[j].departure):
            # If minimum time is not respected
            if (flights[j].departure - flights[i].arrival).total_seconds() < minimum_time*60:
                
                model.Add(output_flights[i] == 0).OnlyEnforceIf(same_person_flights)
            else:
                # Flight i must be positive and flight j negative, or both 0
                model.Add(output_flights[i] >= output_flights[j]).OnlyEnforceIf(same_person_flights)
        # If i is incoming and j is outgoing
        elif (flights[j].arrival < flights[i].departure):
            # If minimum time is not respected
            if (flights[i].departure - flights[j].arrival).total_seconds() < minimum_time*60:
                model.Add(output_flights[i] == 0).OnlyEnforceIf(same_person_flights)
            else:
                # Flight i must be negative and flight j positive, or both 0
                model.Add(output_flights[i] <= output_flights[j]).OnlyEnforceIf(same_person_flights)
        else:
            model.Add(output_flights[i] == 0).OnlyEnforceIf(same_person_flights)

# The cost of the trip for each of the students
students_cost = [model.NewIntVar(0, 99999999999999, 'student_cost_'+str(i)) for i in range(len(students))]
outgoing_times = [model.NewIntVar(0, 99999999999999, 'outgoing_time_'+str(i)) for i in range(len(students))]
incoming_times = [model.NewIntVar(0, 99999999999999, 'incoming_time_'+str(i)) for i in range(len(students))]
for i in range(len(students)):
    # The cost of each flight for the student, either all are 0 (no flights needed) or 2 are not 0 (incoming and outgoing)
    flights_cost_for_students = [model.NewIntVar(
        0, 99999999999999, 'flight_cost_for_' + str(i) + '-'+str(j)) for j in range(len(flights))]
    for j in range(len(flights)):
        outgoing = i+1
        incoming = -i-1

        '''
        if (output_flights[j] == outgoing or output_flights[i] == incoming) flight_cost_for_students[j] = flights[j].price
        if (output_flights[j] != outgoing and output_flights[i] != incoming) flight_cost_for_students[j] = 0

        if flight is incoming or outgoing it costs its price, else it costs 0 to the student
        '''
        outgoing_flight = model.NewBoolVar(f'outgoing_flight_{str(i)}-{str(j)}')
        incoming_flight = model.NewBoolVar(f'incoming_flight_{str(i)}-{str(j)}')
        student_paying_flight = model.NewBoolVar(f'paying_flight_{str(i)}-{str(j)}')
        model.Add(output_flights[j] == outgoing).OnlyEnforceIf(outgoing_flight)
        model.Add(output_flights[j] != outgoing).OnlyEnforceIf(outgoing_flight.Not())
        model.Add(output_flights[j] == incoming).OnlyEnforceIf(incoming_flight)
        model.Add(output_flights[j] != incoming).OnlyEnforceIf(incoming_flight.Not())
        model.Add(flights_cost_for_students[j] == 0).OnlyEnforceIf(outgoing_flight.Not(), incoming_flight.Not())
        model.Add(flights_cost_for_students[j] == flights[j].price).OnlyEnforceIf(incoming_flight, outgoing_flight)
        model.Add(flights_cost_for_students[j] == flights[j].price).OnlyEnforceIf(incoming_flight.Not(), outgoing_flight)
        model.Add(flights_cost_for_students[j] == flights[j].price).OnlyEnforceIf(incoming_flight, outgoing_flight.Not())

        model.Add(outgoing_times[i] == int(flights[j].arrival.timestamp())).OnlyEnforceIf(outgoing_flight)
        model.Add(incoming_times[i] == int(flights[j].departure.timestamp())).OnlyEnforceIf(incoming_flight)

    # Cost for a student is the sum of the cost of all flights used by the student
    model.Add(students_cost[i] == sum(flights_cost_for_students))

    # Outgoing flight must be before incoming flight. Usefull for non-flights student
    model.Add(outgoing_times[i] < incoming_times[i])


# Total cost for the group to travel
total_cost = sum(students_cost)

first_outgoing = model.NewIntVar(0, 99999999999999, 'first_outgoing')
last_outgoing = model.NewIntVar(0, 99999999999999, 'last_outgoing')
first_incoming = model.NewIntVar(0, 99999999999999, 'first_incoming')
last_incoming = model.NewIntVar(0, 99999999999999, 'last_incoming')
useful_time = model.NewIntVar(0, 99999999999999, 'useful_time')
model.AddMaxEquality(first_outgoing, outgoing_times)
model.AddMinEquality(last_outgoing, outgoing_times)
model.AddMaxEquality(first_incoming, incoming_times)
model.AddMinEquality(last_incoming, incoming_times)
model.Add(useful_time == first_incoming - last_outgoing)

separated_times = [model.NewIntVar(0, 99999999999999, 'separated_time_'+str(i)) for i in range(len(students))]
for i in range(len(students)):
    model.Add(separated_times[i] == (incoming_times[i] - last_incoming) + (outgoing_times[i] - first_outgoing))

time_waiting = model.NewIntVar(0, 99999999999999, 'time_waiting')
model.Add(time_waiting == sum(separated_times))

function = model.NewIntVar(-99999999999999, 99999999999999, 'cost_function')
model.Add(function == 10*total_cost + useful_time - time_waiting)
model.Minimize(function)
# model.Minimize(sum(separated_times))
# model.Maximize(useful_time)
# model.Minimize(total_cost)
# model.Minimize(students_cost[0])


solver = cp_model.CpSolver()
status = solver.Solve(model)
print(solver._CpSolver__solution)
# print("status: " + solver.StatusName())
# print("wallTime: " + str(solver.WallTime()))
# print("userTime: " + str(solver.UserTime()))
print()
if status == cp_model.OPTIMAL or status == cp_model.FEASIBLE:
    for i in range(len(output_flights)):
        value = solver.Value(output_flights[i])
        if value != 0:
            print(f'{flights[i]} : {value} : {i}')
    print(f'Total Cost: {solver.Value(total_cost)}')
    print(f'Useful Time: {solver.Value(useful_time)}')
    print(f'Time Waiting: {solver.Value(sum(separated_times))}')
    for i in range(len(students)):
        print('Student ' + str(i) + ':')
        if (solver.Value(students_cost[i]) != 0):
            print(f'\tCost = {str(solver.Value(students_cost[i]))}')
            print(f'\tIncoming Time = {datetime.fromtimestamp(solver.Value(incoming_times[i]))}')
            print(f'\tOutgoing Time = {datetime.fromtimestamp(solver.Value(outgoing_times[i]))}')
            print(f'\tSeparated Time = {str(int(solver.Value(separated_times[i]) / 60))} mins')
        else:
            print('\tNo needed flights')
