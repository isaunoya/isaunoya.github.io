"""Exact one-sided moment certificate. Run anywhere; JSON goes to stdout.

For independent uniform vertices, stage j has success probability
2*j*(j+9999)/100000**2. Stage waits are independent geometric variables
with support 1,2,... . We round each mean term down to 1/1000 and each
variance term upward to an integer before applying Cantelli.

The second row is a faster comparison process for independent uniform
32-bit words reduced modulo n: every vertex mass is at most ceil(2**32/n)
/2**32. It is not a proof that a seeded PRNG emits independent words.
"""
from fractions import Fraction
import json
n=100000;threshold=10000;delta=threshold-1;J=45000;T=2000000
assert 1+(J+delta)+J==n
scale=1000
results=[]
for name,one_vertex_prob in [('independent_uniform_vertices',Fraction(1,n)),('iid_uniform_32bit_before_modulo_upper_hazard',Fraction((2**32+n-1)//n,2**32))]:
 mean_floor=0;var_ceiling=0
 for j in range(1,J+1):
  p=2*j*(j+delta)*one_vertex_prob*one_vertex_prob
  assert 0<p<1
  mean=1/p
  var=(1-p)/(p*p)
  mean_floor+=(mean.numerator*scale)//mean.denominator
  var_ceiling+=(var.numerator+var.denominator-1)//var.denominator
 M=Fraction(mean_floor,scale);V=Fraction(var_ceiling,1);gap=M-T
 assert gap>0
 fail_lower=gap*gap/(V+gap*gap)
 assert fail_lower>Fraction(94,100)
 results.append({'model':name,'mean_lower':str(M),'mean_lower_decimal':float(M),'variance_upper':var_ceiling,'cantelli_failure_lower':str(fail_lower),'cantelli_failure_lower_decimal':float(fail_lower)})
report={'n':n,'initial_component_counts':[J+delta+1,J+1],'initial_large_component_sizes':[J+1,J+delta+1],'initial_isolated_counts':[J+delta,J],'successes_required':J,'query_budget':T,'guard_threshold':threshold,'results':results}
print(json.dumps(report,indent=2))
