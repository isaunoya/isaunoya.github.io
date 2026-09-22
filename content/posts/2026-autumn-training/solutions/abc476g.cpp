#include "noya/head.hpp"

#include <bit>

using namespace noya;

constexpr int B = 60;
ll C[B + 1][B + 1];

void solve() {
  ll L, R;
  cin >> L >> R;
  R++;
  ll dp[B + 2]{};
  while (L < R) {
    int k = min(countr_zero(ull(L)), int(bit_width(ull(R - L))) - 1);
    int c = popcount(ull(L));
    for (int j = c + k; j >= 0; j--) {
      if (j >= c) dp[j] += C[k][j - c];
      cmax(dp[j], dp[j + 1]);
    }
    L += 1LL << k;
  }
  cout << dp[0] << "\n";
}

int main() {
  ios_base::sync_with_stdio(false);
  cin.tie(nullptr);
  rep(k, B + 1) {
    C[k][0] = 1;
    rep(j, 1, k + 1) C[k][j] = C[k - 1][j - 1] + C[k - 1][j];
  }
  int t;
  cin >> t;
  while (t--) solve();
  return 0;
}
