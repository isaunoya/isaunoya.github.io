from pathlib import Path
import itertools, json, random, subprocess, time

import tempfile
ROOT = Path(__file__).parent
BUILD = Path(tempfile.mkdtemp(prefix="mocha-verify-"))
BINARY = BUILD / "mocha-and-diana"


class DSU:
    def __init__(self, n):
        self.p = list(range(n))
        self.k = n

    def find(self, x):
        while x != self.p[x]:
            self.p[x] = self.p[self.p[x]]
            x = self.p[x]
        return x

    def unite(self, x, y):
        x, y = self.find(x), self.find(y)
        if x == y:
            return False
        self.p[x] = y
        self.k -= 1
        return True


def partitions(n):
    def rec(a, high):
        if len(a) == n:
            yield tuple(a)
        else:
            for x in range(high + 2):
                yield from rec(a + [x], max(high, x))
    return list(rec([0], 0))


def forest(partition):
    seen = {}
    edges = []
    for v, label in enumerate(partition):
        if label in seen:
            edges.append((seen[label], v))
        else:
            seen[label] = v
    return edges


def validate(n, e0, e1, added):
    d = [DSU(n), DSU(n)]
    for ds, edges in zip(d, (e0, e1)):
        for u, v in edges:
            assert ds.unite(u, v)
    optimum = min(d[0].k, d[1].k) - 1
    for u, v in added:
        assert 0 <= u < n and 0 <= v < n and u != v
        assert d[0].find(u) != d[0].find(v)
        assert d[1].find(u) != d[1].find(v)
        d[0].unite(u, v)
        d[1].unite(u, v)
    assert len(added) == optimum, (n, e0, e1, added, optimum)


def test_cpp(n, e0, e1):
    data = f'{n} {len(e0)} {len(e1)}\n'
    data += ''.join(f'{u+1} {v+1}\n' for u, v in e0 + e1)
    result = subprocess.run([str(BINARY)], input=data, text=True,
                            capture_output=True, check=True)
    values = list(map(int, result.stdout.split()))
    assert values and len(values) == 1 + 2 * values[0]
    added = [(values[i]-1, values[i+1]-1) for i in range(1, len(values), 2)]
    validate(n, e0, e1, added)


def test_original_masks(n, p0, p1):
    # Exact root direction, cached-row aliasing, snapshot and re-check ordering.
    d = [DSU(n), DSU(n)]
    e0, e1 = forest(p0), forest(p1)
    for ds, edges in zip(d, (e0, e1)):
        for u, v in edges:
            ds.unite(u, v)
    k = min(x.k for x in d) - 1
    maps, rows = [], []
    for ds in d:
        rev = {x: i for i, x in enumerate(v for v in range(n) if ds.find(v) == v)}
        masks = [(1 << n) - 1] * len(rev)
        for v in range(n):
            masks[rev[ds.find(v)]] &= ~(1 << v)
        maps.append(rev)
        rows.append(masks)
    added, candidates, active = [], 0, 0
    for i in range(n):
        cached = [maps[j][d[j].find(i)] for j in range(2)]
        snapshot = rows[0][cached[0]] & rows[1][cached[1]]
        xs = [x for x in range(i+1, n) if snapshot >> x & 1]
        if xs:
            active += 1
        succeeded = 0
        for x in xs:
            candidates += 1
            if all(ds.find(i) != ds.find(x) for ds in d):
                added.append((i, x))
                succeeded += 1
                for j in range(2):
                    d[j].unite(i, x)
                    newrow = maps[j][d[j].find(x)]
                    merged = rows[j][cached[j]] & rows[j][newrow]
                    rows[j][cached[j]] = rows[j][newrow] = merged
                for j in range(2):
                    for v in range(n):
                        actual = rows[j][maps[j][d[j].find(v)]]
                        expected = sum(1 << w for w in range(n)
                                       if d[j].find(w) != d[j].find(v))
                        assert actual == expected
        assert not xs or succeeded >= 1
    assert active <= k and candidates <= n * k
    validate(n, e0, e1, added)


if __name__ == '__main__':
    started = time.monotonic()
    subprocess.run(['clang++', '-std=c++17', '-O2', '-Wall', '-Wextra',
                    str(ROOT/'mocha-and-diana.cpp'), '-o', str(BINARY)], check=True)
    cpp_cases = mask_cases = 0
    for n in range(1, 7):
        ps = partitions(n)
        for p0, p1 in itertools.product(ps, repeat=2):
            test_original_masks(n, p0, p1)
            mask_cases += 1
            if n <= 5:
                test_cpp(n, forest(p0), forest(p1))
                cpp_cases += 1
        print(f'n={n}: mask partition-pairs={len(ps)**2}', flush=True)
    rng = random.Random(1559)
    for _ in range(300):
        n = rng.randrange(2, 151)
        edges = []
        for j in range(2):
            ds, es = DSU(n), []
            for attempt in range(3*n):
                u, v = rng.randrange(n), rng.randrange(n)
                if rng.random() < .5 and ds.unite(u, v):
                    es.append((u, v))
            edges.append(es)
        test_cpp(n, *edges)
        cpp_cases += 1
    n = 100000
    # Maximal output, already-connected input, and the threshold counterexample.
    for e0, e1 in [([], []),
                   ([(i-1, i) for i in range(1, n)], []),
                   ([(i-1, i) for i in range(1, 90000)],
                    [(i-1, i) for i in range(2, n)])]:
        test_cpp(n, e0, e1)
        cpp_cases += 1
    result = {'cpp_cases': cpp_cases, 'original_mask_partition_pairs': mask_cases,
              'cpp_partition_pairs_n_max': 5, 'original_mask_partition_n_max': 6,
              'random_forests': 300, 'large_cases_n100000': 3,
              'validity_and_optimum': 'passed', 'candidate_bound_and_root_masks': 'passed',
              'wall_seconds': round(time.monotonic()-started, 3)}
    print(json.dumps(result, indent=2))
