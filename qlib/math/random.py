# 1d
def phi(n: int) -> float:
    #assert(n > 0, `n must be > 0`);
    power = 1 / (n+1)
    y = 2
    while True:
        y_next = (1 + y)**power
        if y_next == y:
            return y_next
        y = y_next

INV_PHI1 = 1 / phi(1)

RAND1 = INV_PHI1
rand_state = 0

def rand() -> float:
    global rand_state
    rand_state += 1
    return (rand_state * RAND1 % 1)

def rand_seed(x: float):
    global rand_state
    rand_state = x

# 2d
RAND2 = [1 / phi(2)**v for v in [1, 2]]

def rand2() -> tuple[float, float]:
    global rand_state
    rand_state += 1
    return rand_state * RAND2[0] % 1, rand_state * RAND2[1] % 1
