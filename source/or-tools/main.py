from datetime import datetime
from typing import List
from ortools.sat.python import cp_model
from ortools.constraint_solver import pywrapcp
from flight import Flight
from student import Student
import json

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
    departure = int(datetime.strptime(
        flight['departure'], date_format).strftime('%Y%m%d%H%M%S'))
    arrival = int(datetime.strptime(
        flight['arrival'], date_format).strftime('%Y%m%d%H%M%S'))
    flights.append(Flight(flight['origin'], flight['destination'], departure,
                   arrival, flight['duration'], int(flight['price']), flight['stops']))

students: List[Student] = []
for student in json_students:
    availability = [int(datetime.strptime(
        date, "%d/%m/%Y").strftime('%Y%m%d%H%M%S')) for date in student['availability']]
    students.append(Student(student['city'], availability, student['maxConnections'],
                    student['maxDuration'], student['earliestDeparture'], student['latestArrival']))

# model = cp_model.CpModel()
model = pywrapcp.Solver('CPSimple')

chosen_flights = []
for i in range(len(flights)):
    chosen_flights.append(model.IntVar(
        -1, 2*len(students) - 1, 'chosen_flight' + str(i)))

# -1 for unused flights
model.Add(model.AllDifferentExcept(chosen_flights, -1))

for i in range(len(students)):
    for j in range(len(flights)):
        if (students[i].city == flights[j].origin):
            model.Add(chosen_flights[j] == i or chosen_flights[j] == -1)
        # elif (students[i].city == flights[j].destination):
        #     model.Add(chosen_flights[j] == i + len(students) - 1 or chosen_flights[j] == -1)

decision_builder = model.Phase(
    chosen_flights, model.CHOOSE_RANDOM, model.ASSIGN_RANDOM_VALUE)
count = 0
model.NewSearch(decision_builder)
while count < 10 and model.NextSolution():
    count += 1
    solution = 'Solution {}:\n'.format(count)
    for i in range(len(flights)):
        if chosen_flights[i].Value() != -1:
            solution += str(flights[i]) + '\n'
    print(solution)
model.EndSearch()
