"""Checks for the newly added exact stack model and GCD search argument."""
from itertools import product
from math import gcd,log2
from fractions import Fraction

def reduce_word(word):
    st=[]
    for x in word:
        if st and st[-1]==-x:st.pop()
        else:st.append(x)
    return st

def canonical_prefix_ids(word):
    nodes=[(None,None)];intern={};ids=[0];cur=0
    for x in word:
        parent,top=nodes[cur]
        if top==-x:cur=parent
        else:
            pair=(cur,x)
            if pair not in intern:
                intern[pair]=len(nodes);nodes.append(pair)
            cur=intern[pair]
        ids.append(cur)
    return ids

def search_probability(a):
    states={(0,0):Fraction(1)}
    for x in a:
        next_states={}
        for (g,h),p in states.items():
            if gcd(g,x)==g:choices=[((g,gcd(h,x)),p)]
            elif gcd(h,x)==h:choices=[((gcd(g,x),h),p)]
            else:choices=[((gcd(g,x),h),p/2),((g,gcd(h,x)),p/2)]
            for key,value in choices:next_states[key]=next_states.get(key,0)+value
        states=next_states
    return states.get((1,1),0)

def possible(a):
    for mask in range(1,(1<<len(a))-1):
        g=h=0
        for i,x in enumerate(a):
            if mask>>i&1:g=gcd(g,x)
            else:h=gcd(h,x)
        if g==h==1:return True
    return False

checks=0
for n in range(8):
    for word in product([-2,-1,1,2],repeat=n):
        ids=canonical_prefix_ids(word)
        for l in range(n+1):
            for r in range(l,n+1):
                assert (ids[l]==ids[r])==(reduce_word(word[l:r])==[]),(word,l,r)
                checks+=1
print(f'canonical stack: {checks} exact interval comparisons passed')

count=0;minimum=Fraction(1)
for n in range(2,6):
    for a in product(range(1,7),repeat=n):
        p=search_probability(a)
        if possible(a):
            lower=Fraction(1,2**(2+2*int(log2(max(a)))))
            assert p>=lower,(a,p,lower)
            minimum=min(minimum,p)
        else:assert not p
        count+=1
print(f'GCD search: {count} arrays checked against exhaustive partitions; minimum success probability on feasible tested arrays: {minimum}')
