__all__ = ["Duration"]

# TODO: time()

class Duration:
    years: int
    months: int
    days: int
    h: int
    m: int
    s: int
    ms: int

    @staticmethod
    def ofYears(years, months=0, days=0, h=0, m=0, s=0, ms=0):
        acc = Duration()
        acc.years = years
        acc.months = months
        acc.days = days
        acc.h = h
        acc.m = m
        acc.s = s
        acc.ms = ms
        return acc

    @staticmethod
    def ofMonths(months, days=0, h=0, m=0, s=0, ms=0):
        return Duration.ofYears(0, months, days, h, m, s, ms)

    @staticmethod
    def ofDays(days, h=0, m=0, s=0, ms=0):
        return Duration.ofYears(0, 0, days, h, m, s, ms)

    @staticmethod
    def ofHours(h, m=0, s=0, ms=0):
        return Duration.ofYears(0, 0, 0, h, m, s, ms)

    @staticmethod
    def ofMinutes(m, s=0, ms=0):
        return Duration.ofYears(0, 0, 0, 0, m, s, ms)

    @staticmethod
    def ofSeconds(s, ms=0):
        return Duration.ofYears(0, 0, 0, 0, 0, s, ms)

    @staticmethod
    def ofMs(ms):
        return Duration.ofYears(0, 0, 0, 0, 0, 0, ms)

    def __repr__(self):
        acc = ""
        acc += f"{self.years} years " if (self.years != 0) else ""
        acc += f"{self.months} months " if (self.months != 0) else ""
        acc += f"{self.days} days " if (self.days != 0) else ""
        acc += f"{self.h} h " if (self.h != 0) else ""
        acc += f"{self.m} m " if (self.m != 0) else ""
        acc += f"{self.s} s " if (self.s != 0) else ""
        acc += f"{self.ms} ms " if (self.ms != 0) else ""
        return acc[:-1]
