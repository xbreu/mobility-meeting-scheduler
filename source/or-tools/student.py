from dataclasses import dataclass


@dataclass
class Student:
    city: str
    avialability: list
    max_connections: int
    max_duration: int
    earliest_departure: int
    latest_arrival: int