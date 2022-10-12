from time import sleep as _sleep, time_ns as _time, perf_counter_ns as _perf_counter_ns, process_time_ns as _process_time_ns
from .math_ import floor

def sleep(ns: int):
    _sleep(ns / NS_PER_S)

def process_time():
    # return time spent executing inside this process
    return _process_time_ns()

def cpu_time():
    # return a monotonic counter quickly
    return _perf_counter_ns()

def posix_time():
    # return POSIX timestamp in seconds
    return _time()

NS_PER_US = 1_000
NS_PER_MS = NS_PER_US * 1_000
NS_PER_S = NS_PER_MS * 1_000
NS_PER_M = NS_PER_S * 60
NS_PER_H = NS_PER_M * 60

class Duration:
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

def tprint_duration(value: int) -> str:
    acc = value
    acc, ns = divmod(acc, 1_000)
    acc, us = divmod(acc, 1_000)
    acc, ms = divmod(acc, 1_000)
    acc, s = divmod(acc, 60)
    acc, m = divmod(acc, 60)
    acc, h = divmod(acc, 24)
    acc_str = ""
    if h > 0: acc_str += f"{h} h "
    if m > 0: acc_str += f"{m} m "
    if s > 0: acc_str += f"{s} s "
    if ms > 0: acc_str += f"{ms} ms "
    if us > 0: acc_str += f"{us} us "
    if ns > 0: acc_str += f"{ns} ns "
    return acc_str[:-1]

def _isLeapYear(year):
    return ((year % 4) == 0) - ((year % 100) == 0) + ((year % 400) == 0)

def _daysBeforeYear(yearMinusOne):
    return yearMinusOne*365 + (yearMinusOne//4) - (yearMinusOne//100) + (yearMinusOne//400)

def _daysBeforeYearMonth(yearMinusOne, monthMinusOne):
    acc_yearMinusOne = yearMinusOne + (monthMinusOne//12)
    acc_monthMinusOne = monthMinusOne % 12
    k = 30 + 0.5/1 + 0.5/8
    monthDays = floor(acc_monthMinusOne*k + 0.5) - (acc_monthMinusOne > 1) * (2 - _isLeapYear(acc_yearMinusOne + 1))
    return _daysBeforeYear(acc_yearMinusOne) + monthDays

def _utcToGregorian(year, month=1, day=1, hour=0, minute=0, second=0, ms=0):
    return (_daysBeforeYearMonth(year - 1, month - 1) + (day-1)) * 86400 + hour*3600 + minute*60 + second + ms/1000

_AVERAGE_DAYS_PER_YEAR = 365 + 1/4 - 1/100 + 1/400

def _gregorianToUtc(gregorianSecond): # TODO: use ns
    acc_seconds = gregorianSecond
    yearMinusOneOrTwo = floor(acc_seconds / 86400 / _AVERAGE_DAYS_PER_YEAR)
    yearMinusOne = yearMinusOneOrTwo + (_daysBeforeYear(yearMinusOneOrTwo + 1) * 86400 <= gregorianSecond)
    acc_seconds -= _daysBeforeYear(yearMinusOne) * 86400
    days = acc_seconds // 86400
    monthMinusOne = floor((days + (days > 40) * (2 - _isLeapYear(yearMinusOne + 1)) - 0.5 * (days > 240)) / 30.5)
    acc_seconds = gregorianSecond - _daysBeforeYearMonth(yearMinusOne, monthMinusOne) * 86400
    dayMinusOne, acc_seconds = divmod(acc_seconds, 86400)
    hour, acc_seconds = divmod(acc_seconds, 3600)
    minute, acc_seconds = divmod(acc_seconds, 60)
    second = floor(acc_seconds)
    acc_seconds -= second
    ms = floor(acc_seconds * 1000)
    weekday = (_daysBeforeYearMonth(yearMinusOne, monthMinusOne) + dayMinusOne + 1) % 7
    return [yearMinusOne + 1, monthMinusOne + 1, dayMinusOne + 1, hour, minute, second, ms, weekday]

# TODO: https://www.timeanddate.com/time/zones/
# TODO: Locale

# POSIX doesn't define what a second is, so people just slow down/speed up time
# whenever a leap seconds happens to make computations easier,
# therefore time is always broken across leap seconds
#JULIAN_CALENDAR_EPOCH_YEAR = -44 # 1 January AUC 709
#GREGORIAN_CALENDAR_EPOCH_YEAR = 1583 # October 1582
TAI_EPOCH_YEAR = 1958
#UTC_V1_EPOCH_YEAR = 1961 # UTC_V1 = TAI + x fractional leap seconds
POSIX_EPOCH_YEAR = 1970 # POSIX = UTC # 1 January 1970
UTC_EPOCH_YEAR = 1972 # UTC = TAI + n integer leap seconds # 1 January 1972
#GPS_EPOCH = 1980 # set to UTC in 1980, updated as atomic

class DateTime:
    def __init__(self, year, month=1, day=1, hour=0, minute=0, second=0, ms=0):
        self.gregorianSecond = _utcToGregorian(year, month, day, hour, minute, second, ms)

    def toParts(self):
        return _gregorianToUtc(self.gregorianSecond)

    def toPosixTimeStamp(self):
        return self.gregorianSecond - _utcToGregorian(POSIX_EPOCH_YEAR)

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
