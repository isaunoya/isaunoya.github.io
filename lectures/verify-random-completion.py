"""Independent small-case checks for the newly completed lecture algorithms."""
from itertools import product, permutations
from math import gcd
from functools import reduce
from random import Random
import json

rng = Random(20261026)
counts = {}

def stars(levels, wanted):
    convex, concave = [], []
    for i, (a, b) in enumerate(levels):
        if b >= 2*a:
            convex.extend([(a, 0, i), (b-a, 1, i)])
        else:
            concave.append((b, a, i))
    convex.sort(); concave.sort()
    cp = [0]
    for cost, _, _ in convex: cp.append(cp[-1] + cost)
    bp = [0]
    for b, _, _ in concave: bp.append(bp[-1] + b)
    inf = 10**30
    suf = [(inf, -1)]*(len(concave)+1)
    pre = [(inf, -1)]*(len(concave)+1)
    for j in range(len(concave)-1, -1, -1):
        suf[j] = min(suf[j+1], (concave[j][1], j))
    for j, (b, a, _) in enumerate(concave):
        pre[j+1] = min(pre[j], (a-b, j))
    best = (inf, None)
    for t, cv in enumerate(cp):
        r = wanted-t
        if not 0 <= r <= 2*len(concave): continue
        k, odd = divmod(r, 2)
        options = [(bp[k], -1, k)] if not odd else [
            (bp[k]+suf[k][0], suf[k][1], k),
            (bp[k+1]+pre[k][0], pre[k][1], k+1),
        ]
        for cost, single, full in options:
            if cv+cost < best[0]: best = (cv+cost, (t, single, full))
    t, single, full = best[1]
    plan = [0]*len(levels)
    for _, _, i in convex[:t]: plan[i] += 1
    for j, (_, _, i) in enumerate(concave):
        plan[i] = 1 if j == single else (2 if j < full else 0)
    assert sum(plan) == wanted
    assert sum((0, a, b)[v] for (a, b), v in zip(levels, plan)) == best[0]
    return best[0]

def brute_stars(levels):
    best = [10**30]*(2*len(levels)+1)
    for plan in product(range(3), repeat=len(levels)):
        cost = sum((0, a, b)[v] for (a, b), v in zip(levels, plan))
        best[sum(plan)] = min(best[sum(plan)], cost)
    return best

star_arrays = 0; star_queries = 0
types = [(1,2),(1,3),(2,3),(2,4),(2,5),(3,4)]
cases = [a for n in range(1,5) for a in product(types, repeat=n)]
for _ in range(600):
    levels=[]
    for _ in range(rng.randrange(5,9)):
        a=rng.randrange(1,20); levels.append((a,rng.randrange(a+1,40)))
    cases.append(levels)
for levels in cases:
    truth=brute_stars(levels)
    for w, answer in enumerate(truth):
        assert stars(levels,w)==answer,(levels,w,answer)
        star_queries+=1
    star_arrays+=1
counts['cf436e_arrays']=star_arrays;counts['cf436e_star_targets']=star_queries

def factors(v):
    out=[];p=2
    while p*p<=v:
        if v%p==0:
            out.append(p)
            while v%p==0:v//=p
        p+=1
    if v>1:out.append(v)
    return out

def group_gcd(a, ids):return reduce(gcd,(a[i] for i in ids),0)

def fixed_seeds(a, second):
    p,q=factors(a[0]),factors(a[second]);r=len(q)
    sequence=[(i,x) for i,x in enumerate(a) if i not in (0,second)]
    m=len(sequence);inf=m+1
    nxt={}
    for prime in set(p+q):
        v=[inf]*(m+1)
        for i in range(m-1,-1,-1):
            v[i]=i+1 if sequence[i][1]%prime else v[i+1]
        nxt[prime]=v
    masks=[(sum((x%z==0)<<i for i,z in enumerate(p)),
            sum((x%z==0)<<i for i,z in enumerate(q))) for _,x in sequence]
    size=1<<(len(p)+len(q));start=size-1
    earliest=[inf]*size;earliest[start]=0;previous={}
    for state in range(start,-1,-1):
        pos=earliest[state]
        if pos==inf:continue
        s,t=state>>r,state&((1<<r)-1)
        for group,(mask,primes) in enumerate(((s,p),(t,q))):
            for bit,prime in enumerate(primes):
                if not mask>>bit&1:continue
                h=nxt[prime][pos]
                if h==inf:continue
                u,v=masks[h-1]
                ns=((s&u)<<r)|t if group==0 else (s<<r)|(t&v)
                if h<earliest[ns]:
                    earliest[ns]=h;previous[ns]=(state,h,group)
    if earliest[0]==inf:return None
    groups=[{0},{second}];state=0
    while state!=start:
        prev,h,group=previous[state];groups[group].add(sequence[h-1][0]);state=prev
    groups[0].update(set(range(len(a)))-groups[0]-groups[1])
    assert all(groups) and not(groups[0]&groups[1])
    assert all(group_gcd(a,s)==1 for s in groups),(a,groups)
    return groups

def exact_groups(a):
    if reduce(gcd,a)!=1:return None
    support={0}
    for p in factors(a[0]):support.add(next(i for i,x in enumerate(a) if x%p))
    rest=set(range(len(a)))-support
    if group_gcd(a,rest)==1:return [support,rest]
    for second in sorted(support-{0}):
        answer=fixed_seeds(a,second)
        if answer is not None:return answer
    return None

def brute_groups(a,second=None):
    for mask in range(1,1<<len(a),2):
        if mask==(1<<len(a))-1 or second is not None and mask>>second&1:continue
        if group_gcd(a,[i for i in range(len(a)) if mask>>i&1])==1 and group_gcd(a,[i for i in range(len(a)) if not(mask>>i&1)])==1:return True
    return False

complete=0;fixed=0
for n in range(2,6):
    for a in product([1,2,3,6,10,15],repeat=n):
        assert (exact_groups(a) is not None)==brute_groups(a),a
        complete+=1
        for second in range(1,n):
            assert (fixed_seeds(a,second) is not None)==brute_groups(a,second),(a,second)
            fixed+=1
for _ in range(1500):
    n=rng.randrange(2,11);a=[rng.randrange(1,1000) for _ in range(n)]
    assert (exact_groups(a) is not None)==brute_groups(a),a
    complete+=1
counts['cf1198f_full_partitions']=complete;counts['cf1198f_fixed_seed_partitions']=fixed

holiday=0
for _ in range(500):
    n=rng.randrange(5,10);reach=[[False]*n for _ in range(n)]
    for i in range(n):
        for j in range(i):reach[i][j]=reach[j][i]=(rng.randrange(4)!=0)
    val=[0]+[rng.randrange(1,100) for _ in range(n-1)]
    top={b:sorted((a for a in range(1,n) if a!=b and reach[0][a] and reach[a][b]),key=lambda a:val[a],reverse=True)[:3] for b in range(1,n)}
    best=0
    for b,c in permutations(range(1,n),2):
        if reach[b][c]:
            for a in top[b]:
                for d in top[c]:
                    if len({a,b,c,d})==4:best=max(best,val[a]+val[b]+val[c]+val[d])
    truth=max((sum(val[x] for x in (a,b,c,d)) for a,b,c,d in permutations(range(1,n),4) if all((reach[0][a],reach[a][b],reach[b][c],reach[c][d],reach[d][0]))),default=0)
    assert best==truth,(reach,val,best,truth);holiday+=1
counts['holiday_top3_graphs']=holiday

order_checks=0
for x in range(300):
    for b in range(100):
        first=max((x+1)//2-b,0);second=(max(x-b,0)+1)//2
        assert first<=second;order_checks+=1
counts['halve_before_subtract_pairs']=order_checks

def quickselect(a,k):
    a=list(a);left,right=0,len(a)
    while True:
        pivot=a[rng.randrange(left,right)];lt=i=left;gt=right
        while i<gt:
            if a[i]<pivot:a[lt],a[i]=a[i],a[lt];lt+=1;i+=1
            elif a[i]==pivot:i+=1
            else:gt-=1;a[i],a[gt]=a[gt],a[i]
        if k<lt:right=lt
        elif k>=gt:left=gt
        else:return pivot
quick_checks=0
for n in range(1,31):
    for _ in range(100):
        a=[rng.randrange(-4,5) for _ in range(n)];k=rng.randrange(n)
        assert quickselect(a,k)==sorted(a)[k];quick_checks+=1
counts['quickselect_partitions']=quick_checks

def merge(a,b):
    if a[0]==b[0]:return (a[0],a[1]+b[1])
    if a[1]>=b[1]:return (a[0],a[1]-b[1])
    return (b[0],b[1]-a[1])
def candidate(a):
    if len(a)==1:return (a[0],1)
    m=len(a)//2;return merge(candidate(a[:m]),candidate(a[m:]))
majority_checks=0
for _ in range(400):
    a=[rng.randrange(5) for _ in range(rng.randrange(1,15))]
    for l in range(len(a)):
        for r in range(l+1,len(a)+1):
            part=a[l:r];value,_=candidate(part)
            true=next((x for x in set(part) if 2*part.count(x)>len(part)),None)
            answer=value if 2*part.count(value)>len(part) else None
            assert answer==true;majority_checks+=1
counts['majority_candidate_intervals']=majority_checks
print(json.dumps(counts,ensure_ascii=False,indent=2))
