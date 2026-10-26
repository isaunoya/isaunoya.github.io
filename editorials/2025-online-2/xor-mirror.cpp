#include <algorithm>
#include <cassert>
#include <cstdint>
#include <iostream>
#include <random>
#include <vector>
using i64 = std::int64_t;

struct View {
  int node = 0;
  unsigned mask = 0;
};
struct Node {
  View child[2];
  i64 sum = 0;
};
static_assert(sizeof(Node) == 24);

class XorMirror {
  int n, height, used = 0;
  std::vector<Node> pool;
  std::vector<i64> values;
  View root;
  View allocate(Node node) {
    int id = ++used;
    assert(id < int(pool.size()));
    pool[id] = node;
    return {id, 0};
  }
  View join(View a, View b) {
    return allocate({{a, b}, pool[a.node].sum + pool[b.node].sum});
  }
  View build(const std::vector<i64>& a, int l, int r) {
    if (r-l == 1) return allocate({{}, a[l]});
    int m = (l+r)/2;
    View x = build(a,l,m), y = build(a,m,r);
    return join(x,y);
  }
  View child(View v, int side, unsigned half) const {
    View answer = pool[v.node].child[side ^ bool(v.mask & half)];
    answer.mask ^= v.mask & (half-1);
    return answer;
  }
  View replace(View dst, View src, int l, int r, int ql, int qr) {
    if (qr<=l || r<=ql) return dst;
    if (ql<=l && r<=qr) return src;
    int m=(l+r)/2, half=(r-l)/2;
    View a=replace(child(dst,0,half),child(src,0,half),l,m,ql,qr);
    View b=replace(child(dst,1,half),child(src,1,half),m,r,ql,qr);
    return join(a,b);
  }
  i64 query(View v, int l, int r, int ql, int qr) const {
    if (qr<=l || r<=ql) return 0;
    if (ql<=l && r<=qr) return pool[v.node].sum;
    int m=(l+r)/2, half=(r-l)/2;
    return query(child(v,0,half),l,m,ql,qr)
         + query(child(v,1,half),m,r,ql,qr);
  }
  void extract(View v, int l, int r) {
    if (r-l==1) { values[l]=pool[v.node].sum; return; }
    int m=(l+r)/2, half=(r-l)/2;
    extract(child(v,0,half),l,m);
    extract(child(v,1,half),m,r);
  }
  void rebuild() {
    ++rebuilds;
    extract(root,0,n);
    used=0;
    root=build(values,0,n);
  }
public:
  int rebuilds=0;
  XorMirror(const std::vector<i64>& a): n(a.size()),height(0) {
    while ((1u<<height)<unsigned(n)) ++height;
    assert((1u<<height)==unsigned(n));
    pool.resize(4*n+2*height+1);
    values.resize(n);
    root=build(a,0,n);
  }
  void update(int l, int r, unsigned k) {
    // Rebuild only between operations, while there is just one current root.
    if (int(pool.size())-1-used<2*height) rebuild();
    View src=root;src.mask^=k;
    root=replace(root,src,0,n,l,r);
  }
  i64 sum(int l,int r) const { return query(root,0,n,l,r); }
};

#ifdef SELF_TEST
int main() {
  std::mt19937 rng(20261026);
  long long operations=0,query_checks=0,collections=0;
  for (int log=0; log<=7; ++log) {
    int n=1<<log;
    for (int trial=0; trial<60; ++trial) {
      std::vector<i64> a(n);
      for(auto& x:a)x=rng()%1048576+1;
      XorMirror trie(a);
      for(int step=0;step<1500;++step) {
        int l=rng()%n,r=rng()%n;if(l>r)std::swap(l,r);++r;
        unsigned k=rng()%n;
        if(step%5==0) { l=0;r=n; }
        if(step%7==0) k=0;
        if(step%9==0) r=l+1;
        if(step%11!=0) {
          auto old=a;
          for(int i=l;i<r;++i)a[i]=old[i^k];
          trie.update(l,r,k);++operations;
        }
        for(int j=0;j<3;++j) {
          int x=rng()%n,y=rng()%n;if(x>y)std::swap(x,y);++y;
          i64 expected=0;for(int i=x;i<y;++i)expected+=a[i];
          assert(trie.sum(x,y)==expected);++query_checks;
        }
      }
      collections+=trie.rebuilds;
    }
  }
  std::cout<<"PASS "<<operations<<" updates, "<<query_checks<<" queries, "<<collections<<" rebuilds\n";
}
#elif defined(STRESS_TEST)
int main() {
  constexpr int n=1<<18, q=200000;
  std::vector<i64>a(n);std::mt19937 rng(20261026);
  for(auto&x:a)x=rng()%1048576+1;
  XorMirror trie(a);
  i64 result=0;
  for(int i=0;i<q;++i) {
    int l=1+(rng()%(n/2-1))*2;
    int r=1+(rng()%(n/2-1))*2;
    if(l>r)std::swap(l,r);if(l==r)++r;
    trie.update(l,r,rng()%n);
    if(i%10000==0)result^=trie.sum(l,r);
  }
  std::cout<<"checksum "<<result<<", rebuilds "<<trie.rebuilds<<"\n";
}
#else
int main() {
  std::ios::sync_with_stdio(false);std::cin.tie(nullptr);
  int t;std::cin>>t;
  while(t--) {
    int n,q;std::cin>>n>>q;std::vector<i64>a(n);
    for(auto& x:a)std::cin>>x;
    XorMirror trie(a);
    while(q--) {
      int op,l,r;std::cin>>op>>l>>r;
      if(op==1) {unsigned k;std::cin>>k;trie.update(l,r,k);}
      else std::cout<<trie.sum(l,r)<<'\n';
    }
  }
}
#endif
