"""Independent small-case oracles for the added lecture derivations."""
from functools import lru_cache
from itertools import product, combinations_with_replacement
import json
import random

RNG = random.Random(20261026)
checks = {}


def positive_subarrays(steps):
    p = less = ans = 0
    f = {0: 1}
    for change in steps:
        if change == 1:
            less += f.get(p, 0)
            p += 1
        else:
            p -= 1
            less -= f.get(p, 0)
        ans += less
        f[p] = f.get(p, 0) + 1
    return ans


count = 0
for n in range(0, 13):
    for steps in product((-1, 1), repeat=n):
        brute = sum(sum(steps[l:r]) > 0 for l in range(n) for r in range(l + 1, n + 1))
        assert positive_subarrays(steps) == brute, steps
        count += 1
checks['P4062_signed_prefix_sequences'] = count


def pairs(a, threshold, skip=-1):
    left, right, result = 0, len(a) - 1, 0
    while left < right:
        if left == skip:
            left += 1
        elif right == skip:
            right -= 1
        elif a[left] + a[right] >= threshold:
            result += 1
            left += 1
            right -= 1
        else:
            left += 1
    return result


def pair_and_leave(a, threshold):
    a = sorted(a)
    c = pairs(a, threshold)
    if len(a) == 2 * c:
        return c, 0
    lo, hi = 0, len(a)
    while lo + 1 < hi:
        mid = (lo + hi) // 2
        if pairs(a, threshold, mid) == c:
            lo = mid
        else:
            hi = mid
    return c, a[lo]


def brute_pair_and_leave(a, threshold):
    @lru_cache(None)
    def visit(mask):
        if not mask:
            return 0, 0
        i = (mask & -mask).bit_length() - 1
        rest = mask ^ (1 << i)
        c, leftover = visit(rest)
        best = c, max(leftover, a[i])
        for j in range(i + 1, len(a)):
            if rest >> j & 1 and a[i] + a[j] >= threshold:
                c, leftover = visit(rest ^ (1 << j))
                best = max(best, (c + 1, leftover))
        return best
    return visit((1 << len(a)) - 1)


count = 0
for threshold in range(1, 9):
    for size in range(0, 9):
        for a in combinations_with_replacement(range(1, threshold), size):
            actual = pair_and_leave(a, threshold)
            expected = brute_pair_and_leave(a, threshold)
            assert actual == expected, (threshold, a, actual, expected)
            feasible = [pairs(a, threshold, i) == actual[0] for i in range(size)]
            assert feasible == sorted(feasible, reverse=True)
            count += 1
checks['P5021_local_pairings'] = count


def tree_greedy(n, edges, threshold):
    graph = [[] for _ in range(n)]
    for u, v, w in edges:
        graph[u].append((v, w))
        graph[v].append((u, w))

    def dfs(u, parent):
        complete, short = 0, []
        for v, w in graph[u]:
            if v == parent:
                continue
            done, length = dfs(v, u)
            complete += done
            length += w
            if length >= threshold:
                complete += 1
            else:
                short.append(length)
        paired, leftover = pair_and_leave(short, threshold)
        return complete + paired, leftover

    return dfs(0, -1)[0]


def tree_oracle(n, edges, threshold):
    graph = [[] for _ in range(n)]
    for index, (u, v, w) in enumerate(edges):
        graph[u].append((v, w, 1 << index))
        graph[v].append((u, w, 1 << index))
    paths = []
    for start in range(n):
        stack = [(start, -1, 0, 0)]
        while stack:
            u, parent, mask, length = stack.pop()
            if u > start and length >= threshold:
                paths.append(mask)
            for v, w, bit in graph[u]:
                if v != parent:
                    stack.append((v, u, mask | bit, length + w))
    dp = {0: 0}
    for path in paths:
        for used, count in list(dp.items()):
            if not used & path:
                both = used | path
                dp[both] = max(dp.get(both, 0), count + 1)
    return max(dp.values())


count = 0
for n in range(2, 10):
    for trial in range(80):
        edges = [(v, RNG.randrange(v), RNG.randint(1, 7)) for v in range(1, n)]
        for threshold in range(1, sum(w for _, _, w in edges) + 2):
            actual = tree_greedy(n, edges, threshold)
            expected = tree_oracle(n, edges, threshold)
            assert actual == expected, (n, edges, threshold, actual, expected)
            count += 1
checks['P5021_tree_thresholds'] = count


def merge(a, b):
    sa, pa, ta, va = a
    sb, pb, tb, vb = b
    return sa + sb, max(pa, sa + pb), max(tb, sb + ta), max(va, vb, ta + pb)


def all_masks(a):
    if len(a) == 1:
        x = a[0]
        return [(x, max(0, x), max(0, x), max(0, x))]
    half = len(a) // 2
    left, right = all_masks(a[:half]), all_masks(a[half:])
    return [merge(left[i], right[i]) for i in range(half)] + [merge(right[i], left[i]) for i in range(half)]


count = 0
for exponent in range(0, 8):
    n = 1 << exponent
    for trial in range(100):
        a = [RNG.randrange(-10, 11) for _ in range(n)]
        table = all_masks(a)
        for mask, actual in enumerate(table):
            reordered = [a[i ^ mask] for i in range(n)]
            expected = (sum(reordered),
                        max(sum(reordered[:j]) for j in range(n + 1)),
                        max(sum(reordered[j:]) for j in range(n + 1)),
                        max(sum(reordered[l:r]) for l in range(n + 1) for r in range(l, n + 1)))
            assert actual == expected, (a, mask, actual, expected)
            assert merge((0, 0, 0, 0), actual) == actual
            assert merge(actual, (0, 0, 0, 0)) == actual
            count += 1
checks['CF1716E_mask_summaries'] = count


count = 0
for bits in range(1, 9):
    size = 1 << bits
    for trial in range(100):
        original = [RNG.randrange(10) for _ in range(size)]
        transformed = original[:]
        for bit in range(bits):
            for mask in range(size):
                if not mask >> bit & 1:
                    transformed[mask] += transformed[mask | 1 << bit]
        for mask in range(size):
            expected = sum(original[s] for s in range(size) if s & mask == mask)
            assert transformed[mask] == expected
            count += 1
checks['MONSTER_superset_damage_values'] = count

result = {'seed': 20261026, 'checks': checks, 'status': 'passed'}
print(json.dumps(result, indent=2))
