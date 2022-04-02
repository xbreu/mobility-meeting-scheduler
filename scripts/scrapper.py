from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.chrome.service import Service

import json
import time
import datetime
from dateutil.relativedelta import relativedelta

NUM_DAYS = 31

ORIGINS = ['Budapest', 'Zagreb', 'Krakow']
DESTINATIONS = ORIGINS + ['Wien']

def input_fields(origin, destination, date):
    # Origin
    driver.find_element(By.XPATH, '//*[@id="i7"]/div[1]/div/div/div[1]/div/div/input').click()
    time.sleep(0.5)
    input_box = driver.find_element(By.XPATH, '//*[@id="i7"]/div[6]/div[2]/div[2]/div[1]/div/input')
    input_box.send_keys(Keys.CONTROL + "a")
    input_box.send_keys(Keys.DELETE)
    input_box.send_keys(origin)
    input_box.send_keys(Keys.ENTER)

    # Destination
    driver.find_element(By.XPATH, '//*[@id="i7"]/div[4]/div/div/div[1]/div/div/input').click()
    time.sleep(0.5)
    input_box = driver.find_element(By.XPATH, '//*[@id="i7"]/div[6]/div[2]/div[2]/div[1]/div/input')
    input_box.send_keys(Keys.CONTROL + "a")
    input_box.send_keys(Keys.DELETE)
    input_box.send_keys(destination)
    input_box.send_keys(Keys.ENTER)

    # Dates
    driver.find_element(By.CSS_SELECTOR, 'input[aria-label="Departure date"][aria-describedby="i13"]').click()

    time.sleep(0.5)
    # Departure Date
    input_box = driver.find_element(By.CSS_SELECTOR, 'input[aria-label="Departure date"][aria-describedby="i14"]')
    input_box.send_keys(Keys.CONTROL + "a")
    input_box.send_keys(Keys.DELETE)
    input_box.send_keys(date)
    # Return Date
    input_box = driver.find_element(By.CSS_SELECTOR, 'input[aria-label="Return date"][aria-describedby="i14"]')
    input_box.send_keys(Keys.CONTROL + "a")
    input_box.send_keys(Keys.DELETE)
    input_box.send_keys(date)

    # Search Button
    driver.find_element(By.XPATH, '//button[starts-with(@aria-label, "Done.")]').click()
    time.sleep(2)

def parse_price(price, origin, destination):
    tokens = price.split(",")
    price = int(tokens[0][1:], 10)

    for token in tokens:
        if (token.find(' to ') != -1):
            dates = token.split(" to ")

    departure_date = datetime.datetime.strptime(dates[0].strip() + " " + str(datetime.date.today().year), '%b %d %Y').date()
    return_date = datetime.datetime.strptime(dates[1].strip() + " " + str(datetime.date.today().year), '%b %d %Y').date()

    if departure_date < datetime.date.today():
        departure_date = departure_date + relativedelta(years = 1)
        return_date = return_date + relativedelta(years = 1)

    return {
        "price": price,
        "origin": origin,
        "destination": destination,
        "departure_date": departure_date.strftime('%d/%m/%Y'),
        "departure_weekday": departure_date.weekday(),
        "return_date": return_date.strftime('%d/%m/%Y'),
        "return_weekday": return_date.weekday()
    }

def get_prices(origin, destination):
    grid_button = driver.find_element(By.CSS_SELECTOR, 'button[jsname="KqtnKd"]')
    grid_button.click()
    time.sleep(2)

    modal = driver.find_element(By.CSS_SELECTOR, 'div[jsname="rZHESd"]')
    next_button = modal.find_element(By.CSS_SELECTOR, 'button[jsname="m4eCTc"]')

    prices = []

    for k in range(NUM_DAYS):
        if k > 0:
            next_button.click()
            time.sleep(2)

        index = ((k + 1) % 9) + 1
        current_day = modal.find_element(By.XPATH, '//div[1]/div/div[2]/span/div/div[1]/div/c-wiz/div/div/c-wiz/div/div[1]/div[2]/div[1]/div/div[1]/div[' + str(index) + ']/div/div/span[2]').get_attribute("innerText")
        day_prices = modal.find_elements(By.XPATH, '//div[1]/div/div[2]/span/div/div[1]/div/c-wiz/div/div/c-wiz/div/div[1]/div[2]/div[1]/div/div[2]/div/div[contains(@aria-label, "' + current_day + ' to ")]')
        day_prices = [parse_price(x.get_attribute("aria-label"), origin, destination) for x in day_prices]

        prices = prices + day_prices


    cancel_button = driver.find_element(By.CSS_SELECTOR, "#yDmH0d > div.QLZdg > div.cedvUc.JdWsKb.AR8FUe.eXUIm > div.xkSIab > div.Bz9vRc.z0YF1 > div.WgNj4c > div:nth-child(1) > div > button")
    cancel_button.click()
    time.sleep(0.5)

    return prices

def find_flights(origin, destination):
    driver.get("https://www.google.com/travel/flights")
    time.sleep(1)
    input_fields(origin, destination, '3/4')
    flights = get_prices(origin, destination)

    if destination in ORIGINS:
        driver.find_element(By.CSS_SELECTOR, 'button[aria-label="Swap origin and destination."]').click()
        time.sleep(2)
        flights = flights + get_prices(destination, origin)

    return flights

def write_origin_flights(flights, origin):
    origin_flights = [x for x in flights if x["origin"] == origin]
    other_flights = [x for x in flights if x["origin"] != origin]
    print(origin_flights)
    flights_json = json.dumps(origin_flights, indent = 4)[1:-2]
    if ORIGINS: flights_json = flights_json + ","
    FILE.write(flights_json)
    return other_flights


FILE = open('data/flights.json', 'w', encoding='utf-8')
FILE.write("[")

s = Service('/usr/local/bin/chromedriver')
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
