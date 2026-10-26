"""Differential verification of all four batched second-offline formulas."""
from itertools import product, combinations
from math import gcd
import random

def solve(a, queries, bits, k, block):
    n=len(a); a=[0]+a; domain=1<<bits
    if k>bits:return [0]*len(queries)
    masks=[z for z in range(domain) if z.bit_count()==k]
    table=[0]*domain; C=[0]*(n+1); D=[0]*(n+1)
    for p in range(1,n+1):
        c=table[a[p]]
        for z in masks:table[a[p]^z]+=1
        d=table[a[p]]
        assert d==c+(k==0)
        C[p]=C[p-1]+c; D[p]=D[p-1]+d
    order=sorted(range(len(queries)),key=lambda j:((queries[j][0]-1)//block,queries[j][1]))
    changes=[0]*len(order); buckets=[[] for _ in range(n+1)]
    L,R=1,0
    moves=events=0
    def event(t,s,e,sign,j):
        nonlocal events,moves
        assert 0<=t<=n and 1<=s<=e<=n
        buckets[t].append((s,e,sign,j)); events+=1; moves+=e-s+1
    for j,orig in enumerate(order):
        l,r=queries[orig]
        if L>l:
            changes[j]-=D[L-1]-D[l-1]
            event(R,l,L-1,1,j); L=l
        if R<r:
            changes[j]+=C[r]-C[R]
            event(L-1,R+1,r,-1,j); R=r
        if L<l:
            changes[j]+=D[l-1]-D[L-1]
            event(R,L,l-1,-1,j); L=l
        if R>r:
            changes[j]-=C[R]-C[r]
            event(L-1,r+1,R,1,j); R=r
    assert events<=4*len(queries)
    table=[0]*domain
    for t in range(n+1):
        if t:
            for z in masks:table[a[t]^z]+=1
        for s,e,sign,j in buckets[t]:
            changes[j]+=sign*sum(table[a[p]] for p in range(s,e+1))
    ans=[0]*len(order); value=0
    for j,orig in enumerate(order):
        value+=changes[j];ans[orig]=value
    return ans

def brute(a,queries,k):
    return [sum((a[i]^a[j]).bit_count()==k for i in range(l-1,r) for j in range(i+1,r)) for l,r in queries]

def main():
    count=0
    for n in range(1,7):
        queries=[(l,r) for l in range(1,n+1) for r in range(l,n+1)]
        for a in product(range(4),repeat=n):
            a=list(a)
            for k in range(4):
                want=brute(a,queries,k)
                for block in {1,max(1,int(n**.5)),n}:
                    assert solve(a,queries,2,k,block)==want,(a,k,block)
                    count+=len(queries)
    rng=random.Random(4887)
    for _ in range(400):
        n=rng.randrange(1,25);bits=rng.randrange(1,6)
        a=[rng.randrange(1<<bits) for _ in range(n)]
        queries=[tuple(sorted((rng.randrange(1,n+1),rng.randrange(1,n+1)))) for _ in range(35)]
        k=rng.randrange(bits+2)
        assert solve(a,queries,bits,k,rng.randrange(1,n+1))==brute(a,queries,k)
        count+=len(queries)
    # The CF1891E counterexample has exactly one zero-cost k-subset.
    for k in range(1,4):
        n=8*k;a=[2 if i%2==0 else 3 for i in range(2*k+1)]+[2]*(n-2*k-1)
        zero=[]
        for chosen in combinations(range(n),k):
            b=a[:]
            for i in chosen:b[i]=0
            if all(gcd(b[i],b[i+1])!=1 for i in range(n-1)):zero.append(chosen)
        assert zero==[tuple(range(1,2*k,2))],(k,zero)
        assert k-(2*k+1)/8==(6*k-1)/8
    print(f'{count} second-offline query comparisons passed; CF1891E unique-optimum counterexamples passed for k=1,2,3')

if __name__=='__main__':main()
