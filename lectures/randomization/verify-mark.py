"""Local transcript simulator; no network and no actual judge queries."""
from itertools import product
import json, random
from pathlib import Path


def run(secret, initial):
    n = len(secret)
    u = list(range(0, n, 2))
    v = list(range(1, n, 2))
    base = [list(initial), list(initial)]
    for i in v:
        base[1][i] ^= 1
    known = [None] * n
    calls = 0
    solved = False

    def query(which, flipped=()):
        nonlocal calls, solved
        guess = base[which].copy()
        for i in flipped:
            guess[i] ^= 1
        calls += 1
        assert calls <= 675
        score = sum(x == y for x, y in zip(guess, secret))
        if score == n:
            solved = True
        return score

    s0 = query(0)
    if solved:
        return calls
    s1 = query(1)
    if solved:
        return calls
    full_u, full_v = u.copy(), v.copy()
    while len(u) + len(v) >= 3:
        assert abs(len(u) - len(v)) <= 1 and u and v
        i, j = u.pop(), v.pop()
        delta0 = query(0, (i, j)) - s0
        if solved:
            return calls
        if delta0:
            assert delta0 in (-2, 2)
            known[i] = base[0][i] ^ (delta0 > 0)
            known[j] = base[0][j] ^ (delta0 > 0)
        else:
            pool = u if len(u) >= len(v) else v
            k = pool.pop()
            delta1 = query(1, (i, j, k)) - s1
            if solved:
                return calls
            assert delta1 in (-3, -1, 1, 3)
            alpha = 1 if delta1 > 0 else -1
            beta = delta1 - 2 * alpha
            known[i] = base[1][i] ^ (alpha > 0)
            known[j] = base[1][j] ^ (alpha > 0)
            known[k] = base[1][k] ^ (beta > 0)
        for k, bit in enumerate(known):
            assert bit is None or bit == secret[k]

    correct_u = (s0 + s1 - len(full_v)) // 2
    correct_v = (s0 - s1 + len(full_v)) // 2
    assert (s0 + s1 - len(full_v)) % 2 == 0
    for all_positions, remaining, target in [(full_u, u, correct_u), (full_v, v, correct_v)]:
        matched = sum(known[k] == base[0][k] for k in all_positions if known[k] is not None)
        residual = target - matched
        assert len(remaining) <= 1
        if remaining:
            assert residual in (0, 1)
            k = remaining[0]
            known[k] = base[0][k] ^ (residual == 0)
        else:
            assert residual == 0
    assert known == list(secret)
    calls += 1  # Final complete answer is also a query.
    assert calls <= 2 * n // 3 + 3 and calls <= 669
    return calls


if __name__ == '__main__':
    cases = 0
    exhaustive_max = {}
    # Test both hidden answers and random baselines; this includes early exits.
    for n in range(1, 9):
        worst = 0
        for secret in product((0, 1), repeat=n):
            for initial in product((0, 1), repeat=n):
                worst = max(worst, run(secret, initial))
                cases += 1
        exhaustive_max[n] = worst
    # Fixed secret + every baseline, exploiting xor symmetry of the algorithm.
    for n in range(9, 15):
        worst = 0
        for initial in product((0, 1), repeat=n):
            worst = max(worst, run([0] * n, initial))
            cases += 1
        exhaustive_max[n] = worst
    rng = random.Random(1705)
    trial_queries = []
    for _ in range(2000):
        secret = [rng.randrange(2) for _ in range(1000)]
        initial = [rng.randrange(2) for _ in range(1000)]
        trial_queries.append(run(secret, initial))
    # Force every pair into the two-query branch, with varying orientations.
    forced = [0] * 1000
    left, right = list(range(0, 1000, 2)), list(range(1, 1000, 2))
    step = 0
    while len(left) + len(right) >= 3:
        i, j = left.pop(), right.pop()
        forced[i], forced[j] = step % 2, 1 - step % 2
        pool = left if len(left) >= len(right) else right
        forced[pool.pop()] = (step // 2) % 2
        step += 1
    forced_queries = run(forced, [0] * 1000)
    assert forced_queries == 669
    g = [0.0] * 1001
    for n in range(3, 1001):
        g[n] = .5 * (1 + g[n - 2]) + .5 * (2 + g[n - 3])
        assert .6 * n - 1.2 - 1e-9 <= g[n] <= .6 * n + 1e-9
    result = {
        'exhaustive_cases': cases,
        'exhaustive_max_queries': exhaustive_max,
        'n1000_random_trials': len(trial_queries),
        'n1000_observed_mean_queries': sum(trial_queries) / len(trial_queries),
        'n1000_observed_max_queries': max(trial_queries),
        'n1000_forced_two_query_branches': forced_queries,
        'n1000_recurrence_loop_expectation': g[1000],
        'hard_query_bound_all_n_le_1000': 669,
        'note': 'Simulations check transcript signs, recovery and stopping. Hard bound is a proof, not an empirical guarantee.'
    }
    print(json.dumps(result, indent=2))
