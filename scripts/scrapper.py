from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.chrome.service import Service

import json
import time
from datetime import datetime, timedelta
from dateutil.relativedelta import relativedelta

NUM_DAYS = 31

ORIGINS = ['Budapest', 'Zagreb', 'Krakow']
DESTINATIONS = ORIGINS + ['Wien']

def input_fields(origin, destination, date):
    # Origin
    driver.find_element(By.XPATH, '//*[@id="i15"]/div[1]/div/div/div[1]/div/div/input').click()
    time.sleep(0.5)
    input_box = driver.find_element(By.XPATH, '//*[@id="i15"]/div[6]/div[2]/div[2]/div[1]/div/input')
    input_box.send_keys(Keys.CONTROL + "a")
    input_box.send_keys(Keys.DELETE)
    input_box.send_keys(origin)
    input_box.send_keys(Keys.ENTER)

    # Destination
    driver.find_element(By.XPATH, '//*[@id="i15"]/div[4]/div/div/div[1]/div/div/input').click()
    time.sleep(0.5)
    input_box = driver.find_element(By.XPATH, '//*[@id="i15"]/div[6]/div[2]/div[2]/div[1]/div/input')
    input_box.send_keys(Keys.CONTROL + "a")
    input_box.send_keys(Keys.DELETE)
    input_box.send_keys(destination)
    input_box.send_keys(Keys.ENTER)

    driver.find_element(By.XPATH, '//button[contains(@aria-label, "Change ticket type")]').click()
    driver.find_element(By.XPATH, '//li[contains(text(), "One way")]').click()
    # Dates
    driver.find_element(By.CSS_SELECTOR, 'input[aria-label="Departure"][aria-describedby="i25"]').click()

    time.sleep(0.5)
    # Departure Date
    input_box = driver.find_element(By.CSS_SELECTOR, 'input[aria-label="Departure"][aria-describedby="i25"]')
    input_box.send_keys(Keys.CONTROL + "a")
    input_box.send_keys(Keys.DELETE)
    input_box.send_keys(date)

    # Search Button
    time.sleep(2)
    driver.find_element(By.XPATH, '//button[starts-with(@aria-label, "Done.")]').click()
    time.sleep(2)


def get_flight_info(origin, destination, date):
    best_flights = driver.find_element(By.XPATH, '//h3[contains(text(), "Best flights")]/../../../..')
    departure_times = best_flights.find_elements(By.XPATH, './/span[starts-with(@aria-label, "Departure time")]')
    arrival_times = best_flights.find_elements(By.XPATH, './/span[starts-with(@aria-label, "Arrival time")]')
    durations = best_flights.find_elements(By.XPATH, './/div[starts-with(@aria-label, "Total duration")]')
    prices = best_flights.find_elements(By.XPATH, './/span[contains(@aria-label, "euros")]')

    flights = []
    for i in range(len(durations)):
        departure = datetime.strptime('2022 ' + date + ' ' + departure_times[(i+1)*2-2].text, "%Y %m/%d %H:%M %p")
        if '+1' in arrival_times[(i+1)*2-2].text: # If it has +1 it means arrival is on the next day
            arrival = datetime.strptime('2022 ' + date + ' ' + arrival_times[(i+1)*2-2].text[:-2], "%Y %m/%d %H:%M %p") + timedelta(days=1)
        else:
            arrival = datetime.strptime('2022 ' + date + ' ' + arrival_times[(i+1)*2-2].text, "%Y %m/%d %H:%M %p")
        
        flights.append({
            "origin": origin,
            "destination": destination,
            "departure": departure.strftime('%d/%m/%Y, %H:%M:%S'),
            "arrival": arrival.strftime('%d/%m/%Y, %H:%M:%S'),
            "duration": durations[i].text,
            "price": prices[(i+1)*3-3].text # Price appears 3 times (2 are empty) 0, 3, 6
        })
    
    return flights

    

def find_flights(origin, destination):
    driver.get("https://www.google.com/travel/flights")
    time.sleep(1)
    date = '5/5'
    input_fields(origin, destination, date)
    i = 0
    while(i < 5):
        try :
            time.sleep(3)
            flights = get_flight_info(origin, destination, date)
            break
        except Exception as e:
            print(e)
        finally:
            i += 1
            
    return flights

def write_origin_flights(flights, origin):
    origin_flights = [x for x in flights if x["origin"] == origin]
    other_flights = [x for x in flights if x["origin"] != origin]
    print(origin_flights)
    flights_json = json.dumps(origin_flights, indent = 4)[1:-2]
    if ORIGINS: flights_json = flights_json + ","
    FILE.write(flights_json)
    return other_flights


FILE = open('../data/flights.json', 'w', encoding='utf-8')
FILE.write("[")

s = Service('/usr/bin/chromedriver')
driver = webdriver.Chrome(service = s)

# Remove Google consent message
driver.get("https://www.google.com/")
time.sleep(1)
driver.find_element(By.ID, 'L2AGLb').click()

flights = []

for origin in ORIGINS:
    for destination in DESTINATIONS:
        if origin == destination: continue
        flights = flights + find_flights(origin, destination)

    DESTINATIONS.remove(origin)
    flights = write_origin_flights(flights, origin)

driver.quit()

FILE.write("]")
FILE.close()
