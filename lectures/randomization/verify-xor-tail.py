#!/usr/bin/env python3
"""Exact finite distributions + outward-rounded CF1364E query tail.

This is a finite calculation certificate, not Monte Carlo simulation.
The model uses independent uniform draws at each selection. The user source's
modulo-based PRNG sampling is outside this probabilistic certificate.

Run: python3 lectures/randomization/verify-xor-tail.py
Outputs: certificate.json and all-n-bounds.csv in a temporary directory.
Only Python's standard library is needed.
"""

from collections import defaultdict
from decimal import Context, Decimal, ROUND_CEILING, ROUND_FLOOR, localcontext
from fractions import Fraction
from math import comb
from pathlib import Path
import csv
import hashlib
import json

N_MAX = 2048
BUDGET = 4269
K_MAX = 6
PRECISION = 80
import tempfile
ROOT = Path(tempfile.mkdtemp(prefix="cf1364e-tail-"))


def fraction_record(value):
    return {"numerator": value.numerator, "denominator": value.denominator}


def distributions():
    """A = recursive queries minus subsequently marked p[] entries."""
    result = [{0: Fraction(1)}, {-1: Fraction(1)}]
    for k in range(2, K_MAX + 1):
        current = defaultdict(Fraction)
        for j in range(k):
            probability = Fraction(comb(k, j), (1 << k) - 1)
            for old_a, old_probability in result[j].items():
                current[(1 << k) - 3 + old_a] += probability * old_probability
        result.append(dict(sorted(current.items())))
    for distribution in result:
        assert sum(distribution.values()) == 1
        assert all(value > 0 for value in distribution.values())
    assert [max(d) for d in result] == [0, -1, 1, 6, 19, 48, 109]
    return result


def power_in_context(base, exponent):
    """Integer power using only correctly directed +/* decimal operations.

    Do not use Decimal.power, whose general transcendental implementation has
    a weaker rounding contract. Nonnegative multiplication is monotone.
    """
    assert exponent >= 0
    result = Decimal(1)
    while exponent:
        if exponent & 1:
            result *= base
        exponent >>= 1
        if exponent:
            base *= base
    return result


def endpoint(n, good, a_distribution, rounding):
    """One directed endpoint of sum Pr(A=a) q^(budget-2n+3-a)."""
    context = Context(
        prec=PRECISION,
        rounding=rounding,
        Emin=-999999999,
        Emax=999999999,
    )
    denominator = n * (n - 1)
    with localcontext(context):
        q = Decimal(denominator - good) / Decimal(denominator)
        answer = Decimal(0)
        for a, probability in sorted(a_distribution.items()):
            exponent = BUDGET - 2 * n + 3 - a
            assert exponent >= 67
            coefficient = Decimal(probability.numerator) / Decimal(probability.denominator)
            answer += coefficient * power_in_context(q, exponent)
        return answer


def main():
    distributions_a = distributions()
    popcount = [x.bit_count() for x in range(N_MAX)]
    # hist[k] counts successful ordered (x, y), x != y, whose first value has k bits.
    # Adding new maximum x visits each unordered pair exactly once. Add its two
    # ordered orientations separately; their pivot bit counts need not agree.
    hist = [0] * (K_MAX + 1)
    good = 0
    rows = []
    minimum_p = None
    minimum_p_n = []
    for n in range(2, N_MAX + 1):
        x = n - 1
        for y in range(x):
            if (x | y).bit_count() <= K_MAX:
                good += 2
                hist[popcount[x]] += 1
                hist[popcount[y]] += 1
        assert sum(hist) == good
        assert 0 < good <= n * (n - 1)
        if n < 3:
            continue
        p = Fraction(good, n * (n - 1))
        if minimum_p is None or p < minimum_p:
            minimum_p, minimum_p_n = p, [n]
        elif p == minimum_p:
            minimum_p_n.append(n)

        # Exact conditional mixture of A after the first successful trial.
        mixture = defaultdict(Fraction)
        for k, count in enumerate(hist):
            if count:
                weight = Fraction(count, good)
                for a, probability in distributions_a[k].items():
                    mixture[a] += weight * probability
        assert sum(mixture.values()) == 1
        low = endpoint(n, good, mixture, ROUND_FLOOR)
        high = endpoint(n, good, mixture, ROUND_CEILING)
        assert 0 <= low <= high <= 1
        rows.append({
            "n": n,
            "successful_ordered_pairs": good,
            "all_ordered_pairs": n * (n - 1),
            "pivot_histogram": list(hist),
            "lower": str(low),
            "upper": str(high),
        })

    # Independent combinatorial cross-check at the full 11-bit range.
    full_hist = [
        comb(11, k) * ((1 << k) * sum(comb(11 - k, t) for t in range(7 - k)) - 1)
        for k in range(7)
    ]
    full_good = sum(comb(11, s) * (3**s - 1) for s in range(1, 7))
    assert rows[-1]["pivot_histogram"] == full_hist
    assert rows[-1]["successful_ordered_pairs"] == full_good == sum(full_hist)

    # A unique maximizer is certified by disjoint directed intervals.
    winner = max(rows, key=lambda row: Decimal(row["lower"]))
    other_upper = max(
        Decimal(row["upper"]) for row in rows if row["n"] != winner["n"]
    )
    assert Decimal(winner["lower"]) > other_upper
    assert winner["n"] == 2048
    assert Decimal(winner["upper"]) < Decimal("4.70258e-7")
    assert minimum_p_n == [2048]

    csv_path = ROOT / "all-n-bounds.csv"
    with csv_path.open("w", newline="") as file:
        writer = csv.writer(file)
        writer.writerow(["n", "successful_ordered_pairs", "all_ordered_pairs", "lower", "upper"])
        for row in rows:
            writer.writerow([row[key] for key in [
                "n", "successful_ordered_pairs", "all_ordered_pairs", "lower", "upper"
            ]])

    certificate = {
        "model": "independent uniform selections; original source query schedule; no query caching beyond v[b]",
        "n_range": [3, N_MAX],
        "budget": BUDGET,
        "precision": PRECISION,
        "rounding": "ROUND_FLOOR and ROUND_CEILING; integer power by repeated multiplication",
        "A_distributions": [
            {str(a): fraction_record(probability) for a, probability in distribution.items()}
            for distribution in distributions_a
        ],
        "max_A_by_k": [max(d) for d in distributions_a],
        "minimum_success_probability": {"n": minimum_p_n, **fraction_record(minimum_p)},
        "maximum_tail": winner,
        "all_other_n_upper_bound": str(other_upper),
        "strict_global_bound": "4.70258e-7",
        "full_range_combinatorial_check": {
            "successful_ordered_pairs": full_good,
            "pivot_histogram": full_hist,
        },
        "all_n_csv_sha256": hashlib.sha256(csv_path.read_bytes()).hexdigest(),
        "verifier_sha256": hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
    }
    (ROOT / "certificate.json").write_text(json.dumps(certificate, ensure_ascii=False, indent=2) + "\n")
    print(json.dumps({
        "maximum_at_n": winner["n"],
        "maximum_tail_lower": winner["lower"],
        "maximum_tail_upper": winner["upper"],
        "other_n_upper_bound": str(other_upper),
        "minimum_success_probability": fraction_record(minimum_p),
        "full_range_histogram": full_hist,
        "certified": True,
    }, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
