from time import time_ns as _time_ns, perf_counter_ns as _perf_counter_ns, process_time_ns as _process_time_ns
from .math_ import floor

def time_spent_executing():
    return _process_time_ns()

def perf_time():
    return _perf_counter_ns()

def time():
    return _time_ns()

def _isLeapYear(year):
    return ((year % 4) == 0) - ((year % 100) == 0) + ((year % 400) == 0)

def _daysBeforeYear(yearMinusOne):
    return yearMinusOne*365 + (yearMinusOne//4) - (yearMinusOne//100) + (yearMinusOne//400)

def _daysBeforeMonth(_yearMinusOne, _monthMinusOne):
    yearMinusOne = _yearMinusOne + (_monthMinusOne//12)
    yearDays = _daysBeforeYear(yearMinusOne)
    monthMinusOne = _monthMinusOne % 12
    k = 30 + 0.5/1 + 0.5/8
    monthDays = floor(monthMinusOne*k + 0.5) - (monthMinusOne > 1) * (2 - _isLeapYear(yearMinusOne + 1))
    return yearDays + monthDays

def _dateToGregorianSecond(year, month=1, day=1, hour=0, minute=0, second=0, ms=0):
    return (_daysBeforeMonth(year - 1, month - 1) + (day-1)) * 86400 + hour*3600 + minute*60 + second + ms/1000

def _gregorianSecondToDate(gregorianSecond):
    # TODO: fix 13/00 at the end of every year
    AVERAGE_DAYS_PER_YEAR = 365 + 1/4 - 1/100 + 1/400
    acc_seconds = gregorianSecond
    yearMinusOneOrTwo = floor(acc_seconds / 86400 / AVERAGE_DAYS_PER_YEAR)
    yearMinusOne = yearMinusOneOrTwo + (_daysBeforeYear(yearMinusOneOrTwo + 1) * 86400 <= gregorianSecond)
    acc_seconds -= _daysBeforeYear(yearMinusOne) * 86400
    accDays = acc_seconds / 86400
    print("days", accDays, yearMinusOne, _isLeapYear(yearMinusOne + 1))
    monthMinusOne = (accDays >= 31) * floor((accDays + (2 - _isLeapYear(yearMinusOne + 1))) / 30.5) # TODO: check this
    acc_seconds = gregorianSecond - _daysBeforeMonth(yearMinusOne, monthMinusOne) * 86400
    dayMinusOne = floor(acc_seconds / 86400)
    acc_seconds -= dayMinusOne * 86400
    hour = floor(acc_seconds / 3600)
    acc_seconds -= hour * 3600
    minute = floor(acc_seconds / 60)
    acc_seconds -= minute * 60
    second = floor(acc_seconds)
    acc_seconds -= second
    ms = floor(acc_seconds * 1000)
    print(acc_seconds * 1000)
    return [yearMinusOne + 1, monthMinusOne + 1, dayMinusOne + 1, hour, minute, second, ms, dayMinusOne % 7] # TODO: check weekday

# TODO: https://www.timeanddate.com/time/zones/
# TODO: Locale
#GREGORIAN_CALENDAR_EPOCH_YEAR = 1583 # Gregorian calendar Epoch = October 1582
#TAI_EPOCH_YEAR = 1958
# POSIX doesn't define what a second is, so people just slow down/speed up time
# whenever a leap seconds happens to make computations easier,
# therefore time is always broken past the previous leap second
POSIX_EPOCH_YEAR = 1970
UTC_EPOCH_YEAR = 1972 # UTC = TAI + (N leap seconds) + (10 unlisted leap seconds)

class DateTime:
    def __init__(self, year, month=1, day=1, hour=0, minute=0, second=0, ms=0):
        self.gregorianSecond = _dateToGregorianSecond(year, month, day, hour, minute, second, ms)

    def toParts(self):
        return _gregorianSecondToDate(self.gregorianSecond)

    def toUTCTimeStamp(self):
        return self.gregorianSecond - _dateToGregorianSecond(POSIX_EPOCH_YEAR)

    def __repr__(self):
        [year, month, day, h, m, s, ms, weekday] = self.toParts()
        dateString = f"{year:04}-{month:02}-{day:02}"
        timeString = f"T{h:02}:{m:02}:{s:02}" if (year >= UTC_EPOCH_YEAR) else ""
        msString = f".{floor(ms):03}" if ms > 0 else ""
        timezoneString = "Z" if (year > UTC_EPOCH_YEAR) else ""
        return f"{dateString}{timeString}{msString}{timezoneString}"

    def toHistoricString(self):
        [year, *_] = self.toParts()
        return f"{year} AD" if (year > 0) else f"{1-year} BC"

NS_PER_US = 1_000
NS_PER_MS = NS_PER_US * 1_000
NS_PER_S = NS_PER_MS * 1_000
NS_PER_M = NS_PER_S * 60
NS_PER_H = NS_PER_M * 60

class Duration: # TODO: tests
    @staticmethod
    def ofHours(hours):
        return hours * NS_PER_H

    @staticmethod
    def ofMinutes(minutes):
        return minutes * NS_PER_M

    @staticmethod
    def ofSeconds(seconds):
        return seconds * NS_PER_S

    @staticmethod
    def ofMs(ms):
        return ms * NS_PER_MS

    @staticmethod
    def ofUs(us):
        return us * NS_PER_US

def tprint_time(value: int) -> str:
    acc = value
    acc, ns = divmod(acc, 1_000)
    acc, us = divmod(acc, 1_000)
    acc, ms = divmod(acc, 1_000)
    acc, s = divmod(acc, 60)
    acc, m = divmod(acc, 60)
    acc, h = divmod(acc, 24)
    acc, days = divmod(acc, 30)
    acc, months = divmod(acc, 12)
    years = acc
    acc_str = ""
    if years > 0: acc_str += f"{years} years "
    if months > 0: acc_str += f"{months} months "
    if days > 0: acc_str += f"{days} days "
    if h > 0: acc_str += f"{h} h "
    if m > 0: acc_str += f"{m} m "
    if s > 0: acc_str += f"{s} s "
    if ms > 0: acc_str += f"{ms} ms "
    if us > 0: acc_str += f"{us} us "
    if ns > 0: acc_str += f"{ns} ns "
    return acc_str[:-1]
