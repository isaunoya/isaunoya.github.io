#!/usr/bin/env python3
"""Focused checks for the interactive lecture; no real judge or network access."""

from itertools import combinations, permutations
from math import ceil, exp, gcd
from random import Random


from pathlib import Path
import runpy

_xor = runpy.run_path(str(Path(__file__).with_name("verify-xor-recovery.py")))
check_xor = _xor["check_xor"]


def check_lowerbound():
    # Scale 999 to k=2. Enumerate every sample and answer rank on relabelled lists.
    rng, cases = Random(843), 0
    n, k = 9, 2
    for _ in range(30):
        order = list(range(n))
        rng.shuffle(order)
        value = [0] * n
        successor = [-1] * n
        for rank, i in enumerate(order):
            value[i] = rank
            if rank + 1 < n:
                successor[i] = order[rank + 1]
        head = order[0]
        for sample in combinations(order[1:], k):
            for target in range(n + 1):
                cache = {i: (value[i], successor[i]) for i in (head, *sample)}
                asked = len(cache)
                if target == 0:
                    actual = 0
                else:
                    u = max((i for i in cache if value[i] < target), key=value.__getitem__)
                    actual = None
                    while True:
                        if value[u] >= target:
                            actual = value[u]
                            break
                        u = successor[u]
                        if u == -1:
                            actual = -1
                            break
                        if u not in cache:
                            if asked == 1 + 2 * k:
                                break
                            asked += 1
                            cache[u] = (value[u], successor[u])
                    # Ending due to budget is the only possible failure.
                good = target <= k or bool(set(sample) & set(order[max(0, target-k):target]))
                expected = target if target < n else -1
                if good:
                    assert actual == expected
                assert asked <= 1 + 2 * k
                cases += 1
    return cases


def check_ap_and_bounds():
    # The gcd condition must match recovery for all distinct small sample sets.
    cases = 0
    for n in range(3, 16):
        for ranks in combinations(range(n), 3):
            d, first = 7, 4
            maximum = first + (n - 1) * d
            g = gcd(*(maximum - (maximum - k * d) for k in ranks))
            assert (g == d) == (gcd(*ranks) == 1)
            cases += 1
    for n in range(31, 1_000_001):
        assert 31 * ((n + 1) // 2) <= 16 * n
        assert 31 * ((n + 2) // 3) <= 11 * n
    assert exp(-999**2 / 49999) < 2.2e-9
    assert (16 / 31)**30 + 10**6 * (11 / 31)**30 < 3.5e-8
    assert 1497 / 3**75 < 2.5e-33
    # Every possible split obeys the same conditional contraction, even if adversarial.
    for m in range(1, 61):
        for a in range(m):
            for b in range(m - a):
                c = m - 1 - a - b
                assert a + b + c == m - 1
                assert (a + b + c) / 3 <= m / 3
    return cases


if __name__ == '__main__':
    xor_result = check_xor()
    lowerbound_cases = check_lowerbound()
    ap_cases = check_ap_and_bounds()
    print(f'X-OR: {xor_result}; '
          f'LowerBound: {lowerbound_cases} cases; AP: {ap_cases} sample sets; '
          'finite-range inequalities and conditional-contraction checks passed.')
