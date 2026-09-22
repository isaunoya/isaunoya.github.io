#import "/.typst-blog/typst/blog.typ" as blog

#show: blog.post.with(
  title: "2026 Autumn Training · 做题记录",
  author: "isaunoya",
  slug: "2026-autumn-training",
  date: "2026-09-22",
  tags: ("acm", "2026-autumn"),
  excerpt: "2026 秋季做题记录",
  published: true,
)

#blog.problem[
= #link("https://codeforces.com/problemset/problem/1187/F")[CF1187F. Expected Square Beauty] <cf1187f>

*题意* 独立均匀取整数 $X_i in [l_i,r_i]$，求极大连续相等段数的平方期望。

*数据范围* $1 <= n <= 2 times 10^5$，$1 <= l_i <= r_i <= 10^9$。

][
#include "solutions/cf1187f.typ"
]
