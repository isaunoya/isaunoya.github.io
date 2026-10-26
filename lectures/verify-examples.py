"""Small deterministic differential checks for the added lecture examples.
Run with Python 3; no third-party packages or network access are required.
These verify finite examples, not the asymptotic/probability proofs in the slides.
"""
from collections import Counter, deque
from itertools import product
from math import gcd
from random import Random

rng = Random(20261024)
checks = Counter()

def mode_tables(a, b):
    n = len(a)
    values = sorted(set(a))
    rank = {x: i for i, x in enumerate(values)}
    a = [rank[x] for x in a]
    modes, prefixes = {}, [[0] * len(values)]
    for start in range(0, n, b):
        counts = prefixes[-1].copy()
        for x in a[start:start+b]: counts[x] += 1
        prefixes.append(counts)
    for start in range(0, n, b):
        counts, best = Counter(), a[start]
        for r in range(start, n):
            x = a[r]; counts[x] += 1
            if (-counts[x], x) < (-counts[best], best): best = x
            if (r + 1) % b == 0 or r == n - 1:
                modes[start // b, r // b] = best
    return a, values, modes, prefixes, [0] * len(values)

def query_mode(a, b, tables, l, r):
    ranks, values, modes, prefixes, edge = tables
    # Full blocks are [first, stop); the final block may be shorter than b.
    first = (l + b - 1) // b
    stop = len(prefixes) - 1 if r == len(a) - 1 else (r + 1) // b
    if first < stop:
        fragments = (range(l, first*b), range(stop*b, r+1))
    else:
        fragments = (range(l, r+1),)
    candidates = []
    for fragment in fragments:
        for i in fragment:
            x = ranks[i]
            if edge[x] == 0: candidates.append(x)
            edge[x] += 1
    if first < stop and edge[modes[first, stop-1]] == 0:
        candidates.append(modes[first, stop-1])
    def frequency(x):
        return edge[x] + (prefixes[stop][x] - prefixes[first][x] if first < stop else 0)
    best = min(candidates, key=lambda x: (-frequency(x), x))
    for x in candidates: edge[x] = 0
    return values[best]

for n in range(1, 8):
    for a in product(range(3), repeat=n):
        for b in {1, 2, n}:
            tables = mode_tables(a,b)
            last = 0
            for _ in range(3):
                l0,r0 = rng.randrange(1,n+1),rng.randrange(1,n+1)
                l,r = sorted(((l0+last-1)%n,(r0+last-1)%n))
                got=query_mode(a,b,tables,l,r)
                cnt=Counter(a[l:r+1]); expected=min(cnt,key=lambda x:(-cnt[x],x))
                assert got==expected
                last=got;checks['P4168']+=1

# Cover every interval/block width for sparse original values, ties, aligned
# endpoints and partial final blocks. Reuse tables to exercise counter clearing.
for a in ([10**9], [10**9] * 7, [10**9, 17, 4, 17, 10**9, 4, 17],
          [4, 4, 1, 1, 2, 2, 2, 4, 4], [4, 4, 1, 1, 2, 2, 2, 4]):
    n = len(a)
    for b in range(1, n+1):
        tables = mode_tables(a, b)
        for l in range(n):
            for r in range(l, n):
                cnt = Counter(a[l:r+1])
                assert query_mode(a,b,tables,l,r) == min(cnt,key=lambda x:(-cnt[x],x))
                checks['P4168'] += 1
        last = 0
        for l0, r0 in ((1,n), (n,1), (1,1), (n,n), (min(2,n),min(3,n))):
            l,r = sorted(((l0+last-1)%n,(r0+last-1)%n))
            cnt = Counter(a[l:r+1])
            last = query_mode(a,b,tables,l,r)
            assert last == min(cnt,key=lambda x:(-cnt[x],x))
            checks['P4168'] += 1

for _ in range(800):
    n=rng.randrange(1,18); adj=[[] for _ in range(n)]
    for u in range(n):
        for v in range(u):
            if rng.randrange(4)==0:adj[u].append(v);adj[v].append(u)
    b=rng.randrange(1,n+1);heavy=[len(x)>=b for x in adj]
    hn=[[v for v in ns if heavy[v]] for ns in adj]
    val=list(range(n));time=[0]*n;broadcast=[(-1,0)]*n;naive=val[:]
    def read(v):
        time[v],val[v]=max([(time[v],val[v]),*[broadcast[u] for u in hn[v]]])
        return val[v]
    for t in range(1,60):
        x=rng.randrange(n);value=read(x)
        for v in adj[x]:naive[v]=naive[x]
        if heavy[x]:broadcast[x]=(t,value)
        else:
            for v in adj[x]:time[v],val[v]=t,value
        assert [read(v) for v in range(n)]==naive
        checks['ABC219G']+=1

for _ in range(200):
    n=rng.randrange(2,35);adj=[[] for _ in range(n)]
    for v in range(1,n):
        u=rng.randrange(v);adj[u].append(v);adj[v].append(u)
    def bfs(sources):
        d=[n]*n;queue=deque(sources)
        for v in sources:d[v]=0
        while queue:
            u=queue.popleft()
            for v in adj[u]:
                if d[v]>d[u]+1:d[v]=d[u]+1;queue.append(v)
        return d
    distances=[bfs([v]) for v in range(n)]
    b=rng.randrange(1,12);red={0};recent=set();d=bfs(red)
    for i in range(70):
        if i%b==0:d=bfs(red);recent=set()
        v=rng.randrange(n)
        if rng.randrange(2):red.add(v);recent.add(v)
        else:
            got=min([d[v],*[distances[v][u] for u in recent]])
            assert got==min(distances[v][u] for u in red)
            checks['CF342E']+=1

def factor_counts(a,x):
    rest=x;primes=[];exps=[];p=2
    while p*p<=rest:
        if rest%p==0:
            e=0
            while rest%p==0:rest//=p;e+=1
            primes.append(p);exps.append(e)
        p+=1
    if rest>1:primes.append(rest);exps.append(1)
    ds=[1];strides=[]
    for p,e in zip(primes,exps):
        base=ds[:];strides.append(len(base))
        ds=[d*p**j for j in range(e+1) for d in base]
    index={d:i for i,d in enumerate(ds)};cnt=[0]*len(ds)
    for a_i in a:cnt[index[gcd(a_i,x)]]+=1
    for e,stride in zip(exps,strides):
        for start in range(0,len(ds),stride*(e+1)):
            for j in range(e-1,-1,-1):
                for k in range(stride):
                    at=start+j*stride+k;cnt[at]+=cnt[at+stride]
    return dict(zip(ds,cnt))
for _ in range(1500):
    a=[rng.randrange(1,401) for _ in range(rng.randrange(1,40))];x=rng.choice(a)
    counts=factor_counts(a,x)
    assert all(c==sum(v%d==0 for v in a) for d,c in counts.items())
    checks['CF364D']+=1

for _ in range(1200):
    m=rng.randrange(1,9);a=[rng.randrange(1<<m) for _ in range(rng.randrange(1,18))]
    threshold=(len(a)+1)//2
    opt=max((s.bit_count() for s in range(1<<m) if sum(v&s==s for v in a)>=threshold),default=0)
    best=0
    for witness in a:
        positions=[b for b in range(m) if witness>>b&1];s=len(positions);cnt=[0]*(1<<s)
        for v in a:cnt[sum(((v>>b)&1)<<j for j,b in enumerate(positions))]+=1
        for bit in range(s):
            for mask in range(1<<s):
                if not mask>>bit&1:cnt[mask]+=cnt[mask|1<<bit]
        for mask,c in enumerate(cnt):
            real=sum(((mask>>j)&1)<<b for j,b in enumerate(positions))
            assert c==sum(v&real==real for v in a)
            if c>=threshold:best=max(best,mask.bit_count())
    assert best==opt;checks['CF1523D']+=1

def quickselect(a,k):
    l,r=0,len(a)
    while True:
        pivot=a[rng.randrange(l,r)];i=lt=l;gt=r
        while i<gt:
            if a[i]<pivot:a[i],a[lt]=a[lt],a[i];lt+=1;i+=1
            elif a[i]>pivot:gt-=1;a[i],a[gt]=a[gt],a[i]
            else:i+=1
        if k<lt:r=lt
        elif k<gt:return pivot
        else:l=gt
for n in range(1,9):
    for a in product(range(3),repeat=n):
        for k in {0,n//2,n-1}:
            assert quickselect(list(a),k)==sorted(a)[k];checks['P1923']+=1

# For a prime field, nonzero coefficient means exactly one colliding weight.
p=7
for coeff in product(range(-2,3),repeat=3):
    if not any(coeff):continue
    hits=sum(sum(c*h for c,h in zip(coeff,weights))%p==0 for weights in product(range(p),repeat=3))
    assert hits==p**2;checks['ABC367F_collision_bound']+=1

def gcd_square_rectangles(a,b,queries,k,width):
    n=len(a);mod=(1<<32)-1;jordan=[d*d for d in range(n+1)]
    for d in range(1,n+1):
        for x in range(2*d,n+1,d):jordan[x]=(jordan[x]-jordan[d])&mod
    answer=[0]*len(queries)
    for d in range(1,k+1):
        sa=[0];sb=[0]
        for x,y in zip(a,b):sa.append(sa[-1]+(x%d==0));sb.append(sb[-1]+(y%d==0))
        for i,(l,r,L,R) in enumerate(queries):answer[i]=(answer[i]+jordan[d]*(sa[r]-sa[l-1])*(sb[R]-sb[L-1]))&mod
    divisors=[[] for _ in range(n+1)];pos=[0]*(n+1)
    for i,x in enumerate(b):pos[x]=i
    for d in range(k+1,n+1):
        for x in range(d,n+1,d):divisors[x].append(d)
    events=[[] for _ in range(n+1)]
    for i,(l,r,L,R) in enumerate(queries):
        for x,y,sign in [(r,R,1),(l-1,L-1,1),(l-1,R,-1),(r,L-1,-1)]:events[x].append((i,y,sign))
    point=[0]*n;blocks=[0]*((n+width-1)//width)
    def prefix(y):
        whole=y//width
        return (sum(blocks[:whole])+sum(point[whole*width:y]))&mod
    for i,x in enumerate(a,1):
        for d in divisors[x]:
            for y in range(d,n+1,d):
                at=pos[y];point[at]=(point[at]+jordan[d])&mod;blocks[at//width]=(blocks[at//width]+jordan[d])&mod
        for qi,y,sign in events[i]:answer[qi]=(answer[qi]+sign*prefix(y))&mod
    return answer

assert gcd_square_rectangles([2,6,1,4,3,5],[3,2,6,5,1,4],[(1,3,2,3)],2,2)==[50]
checks['Gym105487J']+=1
for _ in range(300):
    n=rng.randrange(1,25);a=list(range(1,n+1));b=a[:];rng.shuffle(a);rng.shuffle(b)
    queries=[]
    for _ in range(12):
        l,r=sorted([rng.randrange(1,n+1),rng.randrange(1,n+1)])
        L,R=sorted([rng.randrange(1,n+1),rng.randrange(1,n+1)])
        queries.append((l,r,L,R))
    expect=[sum(gcd(x,y)**2 for x in a[l-1:r] for y in b[L-1:R])%(1<<32) for l,r,L,R in queries]
    for k in {1,n,rng.randrange(1,n+1)}:
        width=rng.randrange(1,n+1)
        assert gcd_square_rectangles(a,b,queries,k,width)==expect
        checks['Gym105487J']+=len(queries)
print(dict(checks))
