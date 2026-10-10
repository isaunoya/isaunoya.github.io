#include "noya/head.hpp"

#include "noya/geometry/minkowski_sum.hpp"

using namespace noya;
using pt = point<ll>;

void solve() {
  int n;
  ll p, q;
  cin >> n >> p >> q;
  vc<pt> P(n), candidates;
  for (auto &[x, y] : P) cin >> x >> y;

  auto divide = [&](auto &&self, int l, int r) -> void {
    if (r - l <= 1) return;
    int m = (l + r) / 2;
    vc<pt> left(P.begin() + l, P.begin() + m);
    vc<pt> right(P.begin() + m, P.begin() + r);
    for (auto &v : left) v *= q;
    for (auto &v : right) v *= p;
    auto hull = minkowski_sum(move(left), move(right));
    candidates.insert(candidates.end(), all(hull));
    self(self, l, m);
    self(self, m, r);
  };
  divide(divide, 0, n);

  auto hull = convex_hull(move(candidates));
  ll numerator = 0;
  rep(i, 1, sz(hull) - 1) {
    numerator += cross(hull[0], hull[i], hull[i + 1]);
  }
  ll denominator = 2 * (p + q) * (p + q);
  ll g = gcd(numerator, denominator);
  cout << numerator / g << ' ' << denominator / g << '\n';
}

int main() {
  ios_base::sync_with_stdio(false);
  cin.tie(nullptr);
  solve();
  return 0;
}
