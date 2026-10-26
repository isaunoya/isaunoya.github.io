from math import isqrt
import json
V=10**6
largest=[0]*(V+1);prime=[]
for p in range(2,V+1):
 if largest[p]==0:
  prime.append(p)
  for x in range(p,V+1,p):largest[x]=p
pi=[0]*(V+1)
for n in range(1,V+1):pi[n]=pi[n-1]+(largest[n]==n and n>1)
S=0
for n in range(1,V+1):
 r=isqrt(n)
 if largest[n]>r:S+=1
 if r*r==n and r>=2 and largest[r]==r:S-=r-1
 if n>=200:
  assert S>=n//2,(n,S)
  assert pi[n]-pi[n//2]>=r-1,(n,pi[n]-pi[n//2],r)
print(json.dumps({'range':[200,V],'independent_weight_sum_at_least_half':True,'unit_weights_cover_largest_weight':True}))
