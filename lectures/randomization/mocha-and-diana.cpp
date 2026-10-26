#include <algorithm>
#include <iostream>
#include <numeric>
#include <utility>
#include <vector>
using namespace std;

struct DSU {
    vector<int> parent, size;

    explicit DSU(int n) : parent(n), size(n, 1) {
        iota(parent.begin(), parent.end(), 0);
    }

    int find(int x) {
        while (x != parent[x]) {
            parent[x] = parent[parent[x]];
            x = parent[x];
        }
        return x;
    }

    void unite(int x, int y) {
        x = find(x);
        y = find(y);
        if (x == y) return;
        if (size[x] < size[y]) swap(x, y);
        parent[y] = x;
        size[x] += size[y];
    }
};

int main() {
    ios::sync_with_stdio(false);
    cin.tie(nullptr);

    int n, m0, m1;
    cin >> n >> m0 >> m1;
    DSU d0(n), d1(n);
    for (int i = 0; i < m0; ++i) {
        int u, v;
        cin >> u >> v;
        d0.unite(u - 1, v - 1);
    }
    for (int i = 0; i < m1; ++i) {
        int u, v;
        cin >> u >> v;
        d1.unite(u - 1, v - 1);
    }

    vector<pair<int, int>> answer;
    answer.reserve(n - 1);
    auto add = [&](int u, int v) {
        d0.unite(u, v);
        d1.unite(u, v);
        answer.emplace_back(u, v);
    };

    for (int v = 1; v < n; ++v) {
        if (d0.find(0) != d0.find(v) && d1.find(0) != d1.find(v)) {
            add(0, v);
        }
    }

    vector<int> a, b;
    const int root0 = d0.find(0), root1 = d1.find(0);
    for (int v = 0; v < n; ++v) {
        if (d0.find(v) == v && v != root0) a.push_back(v);
        if (d1.find(v) == v && v != root1) b.push_back(v);
    }
    for (int i = 0; i < (int)min(a.size(), b.size()); ++i) {
        add(a[i], b[i]);
    }

    cout << answer.size() << '\n';
    for (auto [u, v] : answer) cout << u + 1 << ' ' << v + 1 << '\n';
    return 0;
}
