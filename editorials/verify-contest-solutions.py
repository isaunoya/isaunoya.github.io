from itertools import permutations,product,combinations
from functools import lru_cache
from collections import deque
from math import gcd
import random,json,heapq
rng=random.Random(20261026); report={}
def monotone_sets(a,inc=True):
 good=[]
 for mask in range(1,1<<len(a)):
  v=[a[i] for i in range(len(a)) if mask>>i&1]
  if all((x<y if inc else x>y) for x,y in zip(v,v[1:])): good.append(mask)
 L=max(map(int.bit_count,good)); return L,[m for m in good if m.bit_count()==L]
def dp(a,w,p):
 n=len(a); l=[0]*n; r=l.copy(); u=l.copy(); v=l.copy()
 for i,x in enumerate(a):
  mx=max([l[j] for j in range(i) if a[j]<x],default=0)
  c=sum(u[j] for j in range(i) if a[j]<x and l[j]==mx) if mx else 1
  l[i]=mx+1; u[i]=w[i]*c%p
 for i in range(n-1,-1,-1):
  mx=max([r[j] for j in range(i+1,n) if a[j]>a[i]],default=0)
  c=sum(w[j]*v[j] for j in range(i+1,n) if a[j]>a[i] and r[j]==mx) if mx else 1
  r[i]=mx+1; v[i]=c%p
 L=max(l); C=sum(u[i] for i in range(n) if l[i]==L)%p
 return L,C,[u[i]*v[i]%p if l[i]+r[i]-1==L else 0 for i in range(n)]
cnt=0
for n in range(1,8):
 for a in permutations(range(n)):
  L,I=monotone_sets(a); D,J=monotone_sets(a,False)
  z=sum(not x&y for x in I for y in J)
  exact=len(I)*len(J)-sum(sum(x>>i&1 for x in I)*sum(y>>i&1 for y in J) for i in range(n))
  assert z==exact
  p=101; x=[rng.randrange(p) for _ in a]; y=[rng.randrange(p) for _ in a]
  l,c,h=dp(a,x,p); d,e,H=dp([-v for v in a],y,p)
  def weight(m,w):
   v=1
   for i in range(n):
    if m>>i&1:v=v*w[i]%p
   return v
  weighted=sum(weight(i,x)*weight(j,y) for i in I for j in J if not i&j)%p
  assert (l,d)==(L,D) and (c*e-sum(v*w for v,w in zip(h,H)))%p==weighted
  cnt+=1
report['female_D_permutations']=cnt
cnt=0
for n in range(1,9):
 for parents in product(*[range(i) for i in range(1,n)]):
  ch=[[] for _ in range(n)]
  for i,p in enumerate(parents,1):ch[p].append(i)
  sub=[{i} for i in range(n)]
  for i in range(n-1,0,-1):sub[parents[i-1]]|=sub[i]
  reps=[[rng.choice(sorted(sub[v])) for v in ch[u]] for u in range(n)]
  par=list(range(n)); size=[1]*n; root=list(range(n)); out=[]
  def find(x):
   while x!=par[x]:par[x]=par[par[x]];x=par[x]
   return x
  for u in range(n-1,-1,-1):
   for c in reps[u]:
    a,b=find(u),find(c); out.append((u,root[b]))
    if size[a]<size[b]:a,b=b,a
    par[b]=a;size[a]+=size[b];root[a]=min(root[a],root[b])
  assert sorted(out)==sorted((p,i) for i,p in enumerate(parents,1))
  cnt+=1
report['female_E_increasing_trees_arbitrary_subtree_representatives']=cnt
cnt=0
for n in range(1,9):
 for S in map(''.join,product('ab',repeat=n)):
  p=next(i for i in range(1,n+1) if n%i==0 and S==S[:i]*(n//i))
  vals=[]
  for m in range(1,7):
   t=S*m;vals.append(len({t[l:r] for l in range(len(t)) for r in range(l+1,len(t)+1)}))
  assert all(vals[m-1]==vals[1]+(m-2)*n*p for m in range(2,7))
  cnt+=5
report['female_I_copy_counts']=cnt
cnt=0
for n in range(1,35):
 for _ in range(12):
  a=list(range(1,n+1));b=a.copy();rng.shuffle(a);rng.shuffle(b)
  w=[i*i for i in range(n+1)]
  for d in range(1,n+1):
   for x in range(2*d,n+1,d):w[x]-=w[d]
  for K in {1,n,max(1,int(n**.5))}:
   qs=[]
   for _ in range(20):
    l,r=sorted(rng.sample(range(n+1),2));L,R=sorted(rng.sample(range(n+1),2));qs.append((l,r,L,R))
   ans=[sum(w[d]*sum(x%d==0 for x in a[l:r])*sum(y%d==0 for y in b[L:R]) for d in range(1,K+1)) for l,r,L,R in qs]
   events=[[] for _ in range(n+1)]
   for qi,(l,r,L,R) in enumerate(qs):
    for x,y,sgn in [(r,R,1),(l,R,-1),(r,L,-1),(l,L,1)]:events[x].append((y,sgn,qi))
   pos={v:i for i,v in enumerate(b)};arr=[0]*n
   for x in range(n+1):
    if x:
     v=a[x-1]
     for d in range(K+1,n+1):
      if v%d==0:
       for y in range(d,n+1,d):arr[pos[y]]+=w[d]
    for y,sgn,qi in events[x]:ans[qi]+=sgn*sum(arr[:y])
   for got,(l,r,L,R) in zip(ans,qs):
    assert got%(1<<32)==sum(gcd(x,y)**2 for x in a[l:r] for y in b[L:R])%(1<<32);cnt+=1
report['female_J_offline_rectangles']=cnt
cnt=0
for fs in list(product(range(2),repeat=7))+[tuple(rng.randrange(4) for _ in range(7)) for _ in range(500)]:
 states={(0,0,0)}
 for mask,f in enumerate(fs,1):
  for _ in range(f):
   new=set()
   for s in states:
    for j in range(3):
     if mask>>j&1:t=list(s);t[j]+=1;new.add(tuple(t))
   states=new
 brute=max(map(min,states));got=min(sum(f for mask,f in enumerate(fs,1) if mask&u)//u.bit_count() for u in range(1,8))
 assert got==brute;cnt+=1
report['online_C_assignments']=cnt
cnt=0
for n in range(1,7):
 for a in product(range(3),repeat=n):
  total=0
  for mask in range(1,1<<n):
   vals=tuple(a[i] for i in range(n) if mask>>i&1)
   @lru_cache(None)
   def opt(v):
    if len(v)==1:return v[0]
    return max(opt(tuple(v[j]+v[i] for j in range(len(v)) if j!=i)) for i in range(len(v)))
   total+=opt(vals)
  s=sorted(a);got=sum(v*2**(n-1-i)*(3**i+1)//2 for i,v in enumerate(s))
  assert total==got;cnt+=1
report['online_D_arrays_brute_sale_orders']=cnt
def graph_from_tree(n,edges):
 g=[[] for _ in range(n)]
 for u,v in edges:g[u].append(v);g[v].append(u)
 dist=[]
 for s in range(n):
  d=[-1]*n;d[s]=0;q=deque([s])
  while q:
   u=q.popleft()
   for v in g[u]:
    if d[v]<0:d[v]=d[u]+1;q.append(v)
  dist.append(d)
 D=max(map(max,dist));pairs=list(combinations(range(n),2))
 return sum(1<<i for i,(u,v) in enumerate(pairs) if dist[u][v]==D)
def construct(n,mask):
 pairs=list(combinations(range(n),2));adj=[0]*n;edges=[]
 for i,(u,v) in enumerate(pairs):
  if mask>>i&1:adj[u]|=1<<v;adj[v]|=1<<u;edges.append((u,v))
 pool=[i for i,x in enumerate(adj) if not x];groups={}
 for i,x in enumerate(adj):
  if x:groups.setdefault(x,[]).append(i)
 gs=list(groups.values());s=n-len(pool)
 if len(gs)<2:return None
 ids={u:j for j,C in enumerate(gs) for u in C}
 if any(adj[u].bit_count()!=s-len(C) for C in gs for u in C) or any(ids[u]==ids[v] for u,v in edges):return None
 if n==2:return [(0,1)]
 z=len(pool);r=len(gs)
 if r==2:
  if z<1 or (z==1 and any(len(C)!=1 for C in gs)):return None
  return list(zip(pool,pool[1:]))+[(pool[0],u) for u in gs[0]]+[(pool[-1],u) for u in gs[1]]
 if z==1 and all(len(C)==1 for C in gs):return [(pool[0],C[0]) for C in gs]
 if z<r+1:return None
 return [(pool[0],v) for v in pool[1:]]+[(pool[i+1],u) for i,C in enumerate(gs) for u in C]
cnt=trees=0
for n in range(2,7):
 feasible=set()
 for seq in product(range(n),repeat=n-2):
  deg=[1]*n
  for x in seq:deg[x]+=1
  es=[]
  for x in seq:
   y=next(i for i in range(n) if deg[i]==1);es.append((x,y));deg[x]-=1;deg[y]-=1
  es.append(tuple(i for i in range(n) if deg[i]==1));feasible.add(graph_from_tree(n,es));trees+=1
 for m in range(1,1<<(n*(n-1)//2)):
  es=construct(n,m)
  assert (es is not None)==(m in feasible),(n,m)
  if es is not None:assert len(es)==n-1 and graph_from_tree(n,es)==m
  cnt+=1
report['online_J_all_graphs']=cnt;report['online_J_prufer_trees']=trees
cnt=0;peak=0
for N in [1,2,4,8,16,32,64,128]:
 for B in [1]+[b for b in [2,4,8,16] if b<=N]:
  K=N//B;data=[None]*(K+2);sums=[0]*(K+2);refs=[0]*(K+2)
  a=[rng.randrange(100) for _ in range(N)];desc=[]
  for b in range(K):data[b]=a[b*B:(b+1)*B];sums[b]=sum(data[b]);refs[b]=1;desc.append((b,0))
  for _ in range(500):
   l,r=sorted(rng.sample(range(N+1),2));k=rng.randrange(N);old=desc.copy();new=old.copy()
   def get(i):
    j,m=old[i//B];return data[j][(i%B)^m]
   free=[i for i,v in enumerate(refs) if v==0]
   created=[]
   for b in range(K):
    s,e=b*B,(b+1)*B
    if r<=s or e<=l:continue
    if l<=s and e<=r:
     j,m=old[b^(k//B)];new[b]=(j,m^(k%B))
    else:
     j=free.pop();data[j]=[get(i^k) if l<=i<r else get(i) for i in range(s,e)];sums[j]=sum(data[j]);new[b]=(j,0);created.append(j)
   for j,m in new:refs[j]+=1
   for j,m in old:refs[j]-=1
   desc=new;a=[a[i^k] if l<=i<r else a[i] for i in range(N)]
   assert all(data[j][t^m]==a[b*B+t] for b,(j,m) in enumerate(desc) for t in range(B))
   assert all(refs[j]==sum(x==j for x,m in desc) for j in range(K+2))
   ql,qr=sorted(rng.sample(range(N+1),2));ans=0
   for b,(j,m) in enumerate(desc):
    s,e=b*B,(b+1)*B
    if ql<=s and e<=qr:ans+=sums[j]
    else:ans+=sum(data[j][(i%B)^m] for i in range(max(s,ql),min(e,qr)))
   assert ans==sum(a[ql:qr]);cnt+=1
report['online_L_snapshot_refcount_operations']=cnt
print(json.dumps(report,indent=2))
