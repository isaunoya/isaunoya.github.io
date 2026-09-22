#include "noya/head.hpp"

#include "noya/modint.hpp"

using namespace noya;

using mi = mint107;

vc<vc<mi>> block_probabilities(const vl &L, const vl &R, int k) {
  int N = sz(L), m = N - 1, q = min(k, m);
  vc<mi> il(N);
  rep(i, N) il[i] = mi(R[i] - L[i]).inv();

  vc<vc<mi>> w(m, vc<mi>(q + 1));
  rep(l, m) {
    w[l][0] = 1;
    rep(t, 1, min(q, m - l) + 1) {
      int r = l + t + 1;
      ll ml = L[r - 1], mr = R[r - 1];
      mi prod = 1;
      for (int s = r - 1; s >= l; s--) {
        cmax(ml, L[s]);
        cmin(mr, R[s]);
        prod *= il[s];
        mi c = mi(max(mr - ml, ll(0))) * prod;
        mi pre = s == l ? mi(1) : w[l][s - l - 1];
        if ((r - s - 1) & 1)
          w[l][t] -= pre * c;
        else
          w[l][t] += pre * c;
      }
    }
  }
  return w;
}

vc<mi> factorial_moments(const vc<vc<mi>> &w, int k) {
  int m = sz(w), q = min(k, m);
  vc<vc<mi>> dp(m + 1, vc<mi>(q + 1));
  dp[0][0] = 1;
  rep(i, 1, m + 1) {
    dp[i] = dp[i - 1];
    rep(j, 1, min(i, q) + 1) {
      rep(t, 1, min(i, j) + 1) {
        int l = i - t;
        mi pre = l == 0 ? mi(j == t) : dp[l - 1][j - t];
        dp[i][j] += pre * w[l][t];
      }
    }
  }
  return dp[m];
}

mi expected_moment(const vl &L, const vl &R, int k) {
  assert(k >= 0 && !L.empty() && sz(L) == sz(R));
  auto w = block_probabilities(L, R, k);
  auto a = factorial_moments(w, k);
  int q = sz(a) - 1;
  vc<mi> s(q + 1);
  s[0] = 1;
  rep(n, k) {
    for (int j = min(n + 1, q); j > 0; j--) {
      s[j] = s[j - 1] + mi(j) * s[j];
    }
    s[0] = 0;
  }
  mi fac = 1, ans = s[0] * a[0];
  rep(j, 1, q + 1) {
    fac *= j;
    ans += s[j] * fac * a[j];
  }
  return ans;
}

void solve(int k = 2) {
  int n;
  cin >> n;
  vl L(n), R(n);
  rep(i, n) cin >> L[i];
  rep(i, n) {
    cin >> R[i];
    R[i]++;
  }
  L.push_back(0);
  R.push_back(1);

  cout << expected_moment(L, R, k).val() << "\n";
}

int main() {
  ios_base::sync_with_stdio(false);
  cin.tie(nullptr);
  solve();
  return 0;
}
