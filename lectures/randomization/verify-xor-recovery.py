#!/usr/bin/env python3
"""Deterministic recovery/interaction checks for the user's CF1364E algorithm.

The fake oracle is a fixed permutation and returns only legal OR answers.
This checks correctness, exact query accounting and the budget boundary; it is
not a probability proof. See verify-xor-tail.py for the separate finite tail certificate.

Reusable entry points:
  run_xor_recovery(p, pairs=None, candidate_choice=None, budget=4269, rng=None)
  recover_xor(p, pairs=None, **kwargs) -> (answer_or_None, queries)
  check_xor() -> (completed_test_cases, largest_query_count)
"""

from collections import Counter
from dataclasses import dataclass
from itertools import permutations, repeat
from pathlib import Path
from random import Random
import hashlib
import json


@dataclass
class RecoveryResult:
    answer: list | None
    queries: int
    probes: int
    phase_queries: dict
    bit_path: tuple
    a_value: int | None
    zero: int | None
    failure: str | None
    failure_phase: str | None


class QueryBudgetExhausted(Exception):
    pass


def run_xor_recovery(p, pairs=None, *, candidate_choice=None, budget=4269, rng=None):
    """Run the original query schedule against p, with uniform default choices.

    p is available to the oracle and invariant auditor only. The recovery code
    obtains hidden values through ask(). p[] marks only pivots/final zero, as in
    the user's C++; no additional cache is introduced. pairs may be a scripted
    iterable (including an infinite one). candidate_choice(sub) returns an index.
    A budget is checked BEFORE the next query; exactly-budget completion succeeds.
    """
    truth = tuple(p)
    n = len(truth)
    assert 3 <= n <= 2048
    assert sorted(truth) == list(range(n))
    assert budget is None or budget >= 0
    rng = rng if rng is not None else Random(1364)
    pair_iterator = iter(pairs) if pairs is not None else None
    known = [-1] * n
    values = [-1] * n
    queries = probes = 0
    phase = "probe"
    phase_queries = Counter()
    bit_path = []
    zero = None

    def ask(i, j):
        nonlocal queries
        assert 0 <= i < n and 0 <= j < n and i != j
        if budget is not None and queries == budget:
            raise QueryBudgetExhausted
        queries += 1
        phase_queries[phase] += 1
        return truth[i] | truth[j]

    def audit(pivot, candidates, previous_mask=None):
        mask = known[pivot]
        assert mask == truth[pivot]
        assert all(value == -1 or value == truth[i] for i, value in enumerate(known))
        expected = {
            i for i, value in enumerate(truth)
            if i != pivot and value & mask == value
        }
        assert len(candidates) == len(set(candidates))
        assert set(candidates) == expected
        assert len(candidates) == (1 << mask.bit_count()) - 1
        if previous_mask is not None:
            assert mask != previous_mask and mask & previous_mask == mask
        bit_path.append(mask.bit_count())

    def result(answer=None, a_value=None, failure=None):
        return RecoveryResult(
            answer, queries, probes, dict(phase_queries), tuple(bit_path),
            a_value, zero, failure, phase if failure else None,
        )

    try:
        while True:
            if pair_iterator is None:
                a = rng.randrange(n)
                b = (a + 1 + rng.randrange(n - 1)) % n
            else:
                try:
                    a, b = next(pair_iterator)
                except StopIteration:
                    return result(failure="sample-stream-exhausted")
            answer = ask(a, b)
            probes += 1
            if answer.bit_count() <= 6:
                u = a
                values[b] = answer
                break

        phase = "initial-row"
        known[u] = 2047
        for i in range(n):
            if i != u:
                if values[i] == -1:
                    values[i] = ask(u, i)
                known[u] &= values[i]
        assert phase_queries["initial-row"] == n - 2
        sub = [i for i in range(n) if i != u and values[i] == known[u]]
        audit(u, sub)
        assert bit_path[0] <= 6

        phase = "descent"
        while len(sub) >= 2:
            values = [-1] * n
            new_u = candidate_choice(tuple(sub)) if candidate_choice else rng.choice(sub)
            assert new_u in sub and known[new_u] == -1
            old_mask = known[u]
            known[new_u] = old_mask
            for i in sub:
                if i != new_u:
                    values[i] = ask(i, new_u)
                    known[new_u] &= values[i]
            new_sub = [i for i in sub if i != new_u and values[i] == known[new_u]]
            u, sub = new_u, new_sub
            audit(u, sub, old_mask)

        zero = u if not sub else sub[0]
        assert truth[zero] == 0
        known[zero] = 0
        marked_before_restore = sum(value != -1 for value in known)
        assert marked_before_restore == len(bit_path) + (bit_path[-1] == 1)

        phase = "restore"
        for i in range(n):
            if known[i] == -1:
                known[i] = ask(zero, i)

        assert known == list(truth)
        assert phase_queries["restore"] == n - marked_before_restore
        a_value = phase_queries["descent"] - (marked_before_restore - 1)
        expected_a = sum((1 << k) - 3 for k in bit_path[:-1]) - (bit_path[-1] == 1)
        assert a_value == expected_a
        assert a_value <= [0, -1, 1, 6, 19, 48, 109][bit_path[0]]
        assert queries == probes + 2 * n - 3 + a_value
        assert queries == sum(phase_queries.values())
        assert budget is None or queries <= budget
        return result(answer=known, a_value=a_value)
    except QueryBudgetExhausted:
        assert queries == budget == sum(phase_queries.values())
        return result(failure="budget-exhausted")


def recover_xor(p, pairs=None, **kwargs):
    """Tuple adapter matching the existing verify-interactive.py entry point."""
    result = run_xor_recovery(p, pairs, **kwargs)
    return result.answer, result.queries


def verify_all_recovery_cases():
    completed = 0
    high_water = 0
    initial_bits_seen = set()
    terminal_bits_seen = set()

    def accept(p, **kwargs):
        nonlocal completed, high_water
        result = run_xor_recovery(p, **kwargs)
        assert result.answer == list(p) and result.failure is None
        completed += 1
        high_water = max(high_water, result.queries)
        initial_bits_seen.add(result.bit_path[0])
        terminal_bits_seen.add(result.bit_path[-1])
        return result

    # Every small permutation; seeds are fixed test data, not a tail estimate.
    small_count = 0
    for n in range(3, 9):
        for index, p in enumerate(permutations(range(n))):
            accept(p, rng=Random(1364 * n + index))
            small_count += 1
    assert small_count == 46230

    rng = Random(20261027)
    large_count = 0
    for n in [31, 63, 64, 65, 127, 128, 129, 511, 512, 1023, 1024, 2047, 2048]:
        for case in range(22):
            p = list(range(n))
            if case == 1:
                p.reverse()
            elif case >= 2:
                rng.shuffle(p)
            accept(p, rng=Random(1364 * n + case))
            large_count += 1

    # Force every possible initial k. The source intentionally repeats a zero
    # pivot's first-row queries at restoration, so k=0 tests the exact count.
    p = list(range(128))
    for k in range(7):
        pivot = (1 << k) - 1
        other = 1 if k == 0 else 0
        first = accept(p, pairs=[(pivot, other)], candidate_choice=min)
        assert first.bit_path[0] == k
        assert first.a_value == (0 if k == 0 else -1 if k == 1 else (1 << k) - 3)
    assert initial_bits_seen == set(range(7))
    assert terminal_bits_seen == {0, 1}

    # Longest expensive path: 6->5->4->3->2->0, with max A6=109.
    p = list(range(2048))

    def expensive_choice(sub):
        largest_bits = max(p[i].bit_count() for i in sub)
        return 0 if largest_bits == 1 else max(sub, key=lambda i: (p[i].bit_count(), p[i]))

    rejected = (127, 128)  # OR=255 has eight bits.
    success = (63, 0)
    exact_budget = accept(
        p, pairs=[rejected] * 66 + [success], candidate_choice=expensive_choice, budget=4269,
    )
    assert exact_budget.bit_path == (6, 5, 4, 3, 2, 0)
    assert (exact_budget.probes, exact_budget.a_value, exact_budget.queries) == (67, 109, 4269)

    # One extra rejected probe makes the uncapped count exactly 4270.
    one_over = run_xor_recovery(
        p, pairs=[rejected] * 67 + [success], candidate_choice=expensive_choice, budget=4269,
    )
    assert one_over.answer is None and one_over.queries == 4269
    assert one_over.failure == "budget-exhausted" and one_over.failure_phase == "restore"
    unlimited = accept(
        p, pairs=[rejected] * 67 + [success], candidate_choice=expensive_choice, budget=None,
    )
    assert unlimited.queries == 4270

    # A perpetual rejected stream must stop at the common counter, with no answer.
    forever = run_xor_recovery(p, pairs=repeat(rejected), budget=4269)
    assert forever.answer is None and forever.queries == forever.probes == 4269
    assert forever.failure == "budget-exhausted" and forever.failure_phase == "probe"

    # Budget checks apply to every phase, not only the random probing loop.
    # Use one deterministic completed trace and cut inside each phase.
    reference = accept(p, pairs=[success], candidate_choice=expensive_choice)
    boundaries = {
        "probe": 0,
        "initial-row": 1,
        "descent": 1 + 2046,
        "restore": 1 + 2046 + reference.phase_queries["descent"],
    }
    for phase, budget in boundaries.items():
        cut = run_xor_recovery(p, pairs=[success], candidate_choice=expensive_choice, budget=budget)
        assert cut.answer is None and cut.queries == budget
        assert cut.failure == "budget-exhausted" and cut.failure_phase == phase
    exactly = accept(p, pairs=[success], candidate_choice=expensive_choice, budget=reference.queries)
    assert exactly.queries == reference.queries
    short = run_xor_recovery(
        p, pairs=[success], candidate_choice=expensive_choice, budget=reference.queries - 1,
    )
    assert short.answer is None and short.failure == "budget-exhausted"

    return {
        "exhaustive_small_permutations": small_count,
        "large_deterministic_cases": large_count,
        "completed_cases": completed,
        "largest_completed_query_count_including_uncapped_control": high_water,
        "exact_budget_completed_queries": exact_budget.queries,
        "max_A6_path": list(exact_budget.bit_path),
        "max_A6": exact_budget.a_value,
        "initial_bits_covered": sorted(initial_bits_seen),
        "terminal_bits_covered": sorted(terminal_bits_seen),
        "cutoff_phases_checked": list(boundaries),
        "perpetual_rejection_queries": forever.queries,
        "all_invariants_passed": True,
        "probability_proof": False,
    }


def check_xor():
    """Adapter for the old verification script's printed case-count summary."""
    report = verify_all_recovery_cases()
    return report["completed_cases"], report["exact_budget_completed_queries"]


if __name__ == "__main__":
    report = verify_all_recovery_cases()
    report["script_sha256"] = hashlib.sha256(Path(__file__).read_bytes()).hexdigest()
    print(json.dumps(report, ensure_ascii=False, indent=2))
