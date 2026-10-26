from itertools import product, combinations_with_replacement
from collections import Counter
from fractions import Fraction as F
from math import gcd
from pathlib import Path
import random,json
rng=random.Random(20261026)
report={}

def elimination_brute(s):
    answer=0
    for t in {s[i:j] for i in range(len(s)) for j in range(i+1,len(s)+1)}:
        start=0; k=len(t)
        while t:
            at=s.find(t,start)
            if at<0: break
            start=at+1; t=t[:-1]
        if not t: answer=max(answer,k)
    return answer

def elimination_rolling(s):
    n=len(s); lcp=[0]*(n+1); f=[1]*n
    for i in range(n-1,-1,-1):
        for j in range(i+1,n):
            lcp[j]=lcp[j+1]+1 if s[i]==s[j] else 0
            f[i]=max(f[i],1+min(f[j],lcp[j]))
    return max(f)

def elimination_binary(s,hashed=False):
    p=2**61-1; bases=[911382323,972663749]; n=len(s)
    hs=[]; powers=[]
    for b in bases:
        h=[0];pw=[1]
        for c in s: h.append((h[-1]*b+ord(c))%p);pw.append(pw[-1]*b%p)
        hs.append(h);powers.append(pw)
    def key(l,r):
        if not hashed:return s[l:r]
        return (r-l,)+tuple((h[r]-h[l]*pw[r-l])%p for h,pw in zip(hs,powers))
    seen=set(); answer=0; exact=set()
    for i in range(n-1,-1,-1):
        lo=0;hi=n-i
        while hi-lo>1:
            m=(lo+hi)//2
            if key(i,i+m) in seen:lo=m
            else:hi=m
        length=lo+1; seen.add(key(i,i+length));exact.add(s[i:i+length])
        assert all(t[:j] in exact for t in exact for j in range(1,len(t)+1))
        answer=max(answer,length)
    return answer

count=0
for n in range(1,8):
    for t in product('abc',repeat=n):
        s=''.join(t);ans=elimination_brute(s)
        assert ans==elimination_rolling(s)==elimination_binary(s)==elimination_binary(s,True),s
        count+=1
report['E_F_brute_rolling_binary_hash']=count

def mst_full(a):
    n=len(a);d=[10**30]*n;d[0]=0;used=[False]*n;ans=0
    for _ in a:
        u=min((i for i in range(n) if not used[i]),key=d.__getitem__)
        used[u]=True;ans+=d[u]
        for v in range(n):
            if not used[v]:
                g=gcd(a[u],a[v]);d[v]=min(d[v],g+a[u]*a[v]//g)
    return ans

def mst_candidates(a):
    freq=Counter(a);xs=sorted(freq);first={};edges=[]
    for i,x in enumerate(xs):
        for d in range(1,x+1):
            if x%d:continue
            if d in first:
                j=first[d];edges.append((d+x*xs[j]//d,i,j))
            else:first[d]=i
    parent=list(range(len(xs)));least=[10**30]*len(xs);ans=0
    def root(i):
        while parent[i]!=i:i=parent[i]
        return i
    for w,u,v in sorted(edges):
        ru,rv=root(u),root(v)
        if ru!=rv:
            parent[ru]=rv;ans+=w;least[u]=min(least[u],w);least[v]=min(least[v],w)
    for i,x in enumerate(xs):
        true=min((gcd(x,y)+x*y//gcd(x,y) for y in xs if y!=x),default=10**30)
        assert least[i]==true
        ans+=(freq[x]-1)*min(2*x,least[i])
    return ans

count=0
for n in range(1,8):
    for a in combinations_with_replacement(range(1,11),n):
        assert mst_full(a)==mst_candidates(a),a
        count+=1
report['L_MST_with_duplicates']=count

def product_path(n,edges,rolling):
    A=max(e[2] for e in edges);S=(n-1)*A;inf=10**9
    rows=A+1 if rolling else S+1
    dp=[[inf]*n for _ in range(rows)];dp[0][0]=0;ans=(10**30,0,0)
    for s in range(S+1):
        row=dp[s%rows]
        if row[-1]!=inf:ans=min(ans,(s*row[-1],s,row[-1]))
        for u,v,a,b in edges:
            if s+a<=S and row[u]!=inf:dp[(s+a)%rows][v]=min(dp[(s+a)%rows][v],row[u]+b)
        if rolling:dp[s%rows]=[inf]*n
    return ans

def product_brute(n,edges):
    adj=[[] for _ in range(n)]
    for u,v,a,b in edges:adj[u].append((v,a,b))
    ans=(10**30,0,0)
    def dfs(u,mask,a,b):
        nonlocal ans
        if u==n-1:ans=min(ans,(a*b,a,b));return
        for v,x,y in adj[u]:
            if not mask>>v&1:dfs(v,mask|1<<v,a+x,b+y)
    dfs(0,1,0,0);return ans

for _ in range(1500):
    n=rng.randint(2,6);edges=[]
    for u in range(n):
        for v in range(n):
            if u!=v and (v==u+1 or rng.random()<.3):edges.append((u,v,rng.randint(1,5),rng.randint(1,5)))
    assert product_brute(n,edges)==product_path(n,edges,False)==product_path(n,edges,True)
report['A_layered_and_circular_DP']=1500

def diff_sum(s,a,b,bucket):
    v=[0]
    for c in s:v.append(v[-1]+(c==a)-(c==b))
    count=total=ans=0
    groups=sorted(Counter(v).items()) if bucket else [(x,1) for x in sorted(v)]
    for x,c in groups:ans+=c*(x*count-total);count+=c;total+=c*x
    return ans

def abc_fast(s,bucket):
    length=lambda m:m*(m+1)*(m+2)//6
    ans=sum(diff_sum(s,a,b,bucket) for a,b in [('a','b'),('a','c'),('b','c')])//2
    for z in 'abc':
        a,b=[c for c in 'abc' if c!=z]
        for part in s.split(z):ans-=(length(len(part))-diff_sum(part,a,b,bucket))//2
    i=0
    while i<len(s):
        j=i+1
        while j<len(s) and s[j]==s[i]:j+=1
        ans-=length(j-i);i=j
    return ans

def abc_brute(s):
    ans=0
    for i in range(len(s)):
        freq=Counter()
        for j in range(i,len(s)):
            freq[s[j]]+=1;ans+=max(freq.values())-min(freq.values())
    return ans
count=0
for n in range(1,9):
    for t in product('abc',repeat=n):
        s=''.join(t);assert abc_brute(s)==abc_fast(s,False)==abc_fast(s,True),s;count+=1
report['L_abc_sort_and_bucket']=count

def gauss(a):
    n=len(a)
    for i in range(n):
        j=next(j for j in range(i,n) if a[j][i]);a[i],a[j]=a[j],a[i]
        v=a[i][i];a[i]=[x/v for x in a[i]]
        for j in range(n):
            if j!=i and a[j][i]:
                v=a[j][i];a[j]=[x-v*y for x,y in zip(a[j],a[i])]
    return [F(0)]+[a[i][-1] for i in range(n)]

policies=0
for n in range(1,9):
    sets=[[]]+[[y for y in range(1,n+1) if x%y==0 or y%x==0] for x in range(1,n+1)]
    opt=[F(0)]+[F(n*n+1)]*n
    for mask in range(1<<n):
        matrix=[]
        for x in range(1,n+1):
            row=[F(0)]*(n+1);row[x-1]=F(1);row[-1]=F(1)
            choices=sets[x] if mask>>(x-1)&1 else [x]
            for y in choices:
                if y>1:row[y-2]-=F(1,len(choices))
            matrix.append(row)
        val=gauss(matrix);opt=[min(x,y) for x,y in zip(opt,val)];policies+=1
    h=[F(x) for x in range(n+1)]
    for _ in range(15):
        g=[F(0)]+[1+min(h[x-1],sum(h[y-1] for y in sets[x])/len(sets[x])) for x in range(1,n+1)]
        delta=max(x-y for x,y in zip(h,g))
        for x in range(n+1):assert h[x]/(1+delta)<=opt[x]<=g[x]<=h[x]
        h=g
report['C_exact_policy_enumeration']=policies
print(json.dumps(report,indent=2))

assert 1000 * 9**259 * 10**8 < 10**259
print("Exact integer inequality for the 300-update bound: passed")
