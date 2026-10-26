from math import comb,isqrt
from fractions import Fraction
import json
T=420;S=10**6;OUT=10**18
rows=[]
for h in range(3,19):
 n=2**h-1;C=comb(n,3)
 def f(d):
  a=2**(h-d-1)-1;b=n-2*a-1
  return a*a*b+a*a+2*a*b
 fp=f(1);bounds=[];total=0
 assert sum((2**d)*f(d) for d in range(h))==C
 assert all(fp>f(d) for d in range(h) if d!=1)
 assert T+n-2<=n+420
 for d in range(h):
  if d==1:continue
  fq=f(d)
  if fq:
   k=isqrt((fp*S*S)//fq)
   r=Fraction(k,S)
   assert r>1
   mgf=Fraction(C-fp-fq,C)+Fraction(fp,C)/r+Fraction(fq,C)*r
  else:mgf=Fraction(C-fp,C)
  power=mgf**T
  ceiling=(power.numerator*OUT+power.denominator-1)//power.denominator
  contribution=2*(2**d)*ceiling
  total+=contribution
  bounds.append(dict(depth=d,vertices=2**d,median_count=fq,one_pair_bound_scaled=ceiling,contribution_scaled=contribution))
 rows.append(dict(h=h,n=n,triples=C,child_median_count=fp,child_probability=float(Fraction(fp,C)),union_bound_scaled=total,union_bound=float(Fraction(total,OUT)),depth_bounds=bounds))
print('h child_p failure_upper')
for row in rows:print(row['h'],format(row['child_probability'],'.12g'),format(row['union_bound'],'.12g'))
maxlarge=max(rows[1:],key=lambda r:r['union_bound_scaled'])
print('MAX h>=4:',maxlarge['h'],maxlarge['union_bound'])
assert maxlarge['union_bound_scaled'] < 4902*(OUT//10**8)
assert comb(7,3)+(7-2)<=7+420
import tempfile
from pathlib import Path
with (Path(tempfile.mkdtemp(prefix='cf1438f-bound-'))/'tail-bound.json').open('w') as f:json.dump(dict(T=T,rational_scale=S,output_scale=OUT,small_h3_queries=40,uniform_h4_to_h18_bound='4902 / 100000000',method='exact rational Markov bound, each summand rounded upward',rows=rows),f,indent=2)
