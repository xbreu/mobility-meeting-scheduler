from dataclasses import dataclass
from typing_extensions import IntVar


@dataclass
class Flight:
    origin: str
    destination: str
    departure: int
    arrival: int
    duration: int
    price: int
    stops: int


