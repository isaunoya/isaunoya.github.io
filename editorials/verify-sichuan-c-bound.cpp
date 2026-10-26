#include <algorithm>
#include <cstdint>
#include <iostream>
#include <vector>
using i64 = std::int64_t;

int main() {
  constexpr int n = 100000;
  constexpr i64 scale = 1000000;
  std::vector<i64> h(n+1), g(n+1), divisors(n+1);
  std::vector<int> count(n+1);
  for (int d=1; d<=n; ++d)
    for (int x=d; x<=n; x+=d) ++count[x];
  for (int x=1; x<=n; ++x) h[x]=i64(x)*scale;
  auto step = [&] {
    std::fill(divisors.begin(), divisors.end(), 0);
    for (int d=1; d<=n; ++d)
      for (int x=d; x<=n; x+=d) divisors[x]+=h[d-1];
    for (int x=1; x<=n; ++x) {
      i64 sum=divisors[x]; int cnt=count[x];
      i64 worst=(sum+cnt-1)/cnt;
      for (int y=2*x; y<=n; y+=x) {
        sum+=h[y-1]; ++cnt;
        worst=std::max(worst, (sum+cnt-1)/cnt);
      }
      g[x]=scale+std::min(h[x-1],worst);
    }
  };
  for (int round=1; round<=40; ++round) {
    step();
    for (int x=1; x<=n; ++x) {
      if (g[x]>h[x]) { std::cerr<<"nonmonotone\n"; return 1; }
    }
    h.swap(g);
    if (round==1 || round==10 || round==20 || round==40)
      std::cout<<"round "<<round<<" H_scaled "<<*std::max_element(h.begin(),h.end())<<"\n";
  }
  step();
  for (int x=1; x<=n; ++x) {
    if (g[x]>h[x]) { std::cerr<<"not a supersolution\n"; return 1; }
  }
  if (*std::max_element(h.begin(),h.end()) >= 10*scale) return 2;
  std::cout<<"PASS: exact-integer robust supersolution for every N <= "<<n<<"\n";
}
