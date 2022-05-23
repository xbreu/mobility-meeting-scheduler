from datetime import datetime
from typing import List
from ortools.sat.python import cp_model
from flight import Flight
from student import Student
import json


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
    flights.append(Flight(flight['origin'], flight['destination'], outgoing,
                   incoming, flight['duration'], int(flight['price']), flight['stops']))

students: List[Student] = []
for student in json_students:
    availability = [datetime.strptime(date, "%d/%m/%Y")
                    for date in student['availability']]
    earliest_departure = datetime.strptime(
        student['earliestDeparture'], '%H:%M:%S')
    latest_arrival = datetime.strptime(student['latestArrival'], '%H:%M:%S')
    students.append(Student(student['city'], availability, student['maxConnections'],
                    student['maxDuration'], earliest_departure, latest_arrival))

model = cp_model.CpModel()

output_flights = [model.NewIntVar(-len(students), len(students), str(i))
                  for i in range(len(flights))]

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

        # departure during availability
        if (flights[i].departure.date() < students[j].availability[0].date()
                or flights[i].departure.date() > students[j].availability[-1].date()):
            model.Add(output_flights[i] != outgoing)

        # arrival during availability
        if (flights[i].arrival.date() < students[j].availability[0].date()
                or flights[i].arrival.date() > students[j].availability[-1].date()):
            model.Add(output_flights[i] != incoming)

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
            model.Add(output_destinations[j] == 0).OnlyEnforceIf(
                group_return.Not())
            model.Add(output_flights[i] <= 0).OnlyEnforceIf(group_return)

        # All incoming flights must have the same origin
        if (flights[i].origin != destinations[j]):
            group_return = model.NewBoolVar(f'group_return{str(i)}-{str(j)}')
            model.Add(output_destinations[j] == 1).OnlyEnforceIf(group_return)
            model.Add(output_destinations[j] == 0).OnlyEnforceIf(
                group_return.Not())
            model.Add(output_flights[i] >= 0).OnlyEnforceIf(group_return)



solver = cp_model.CpSolver()
status = solver.Solve(model)
# print(solver._CpSolver__solution)
print("status: " + solver.StatusName())
print("wallTime: " + str(solver.WallTime()))
print("userTime: " + str(solver.UserTime()))
print()
if status == cp_model.OPTIMAL or status == cp_model.FEASIBLE:
    for i in range(len(output_flights)):
        value = solver.Value(output_flights[i])
        if value != 0:
            print(f'{flights[i]} : {value}')
