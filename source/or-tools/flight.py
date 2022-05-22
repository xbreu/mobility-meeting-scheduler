from dataclasses import dataclass
from datetime import datetime


@dataclass
class Flight:
    origin: str
    destination: str
    departure: datetime
    arrival: datetime
    duration: int
    price: int
    stops: int


