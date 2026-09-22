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

2026 年秋季的做题记录，按题目持续补充。

#blog.problem[
= #link("https://codeforces.com/problemset/problem/1187/F")[CF1187F. Expected Square Beauty] <cf1187f>

*主题* 指示变量、局部相关性、组合矩与第二类 Stirling 数。由二次矩推广到 $k$ 次矩。

*题意* 给定 $n$ 个整数区间，每个 $X_i$ 独立、均匀地从对应区间中取值。令 $B$ 为序列的极大连续相等段数，求 $E[B^2]$，答案对 $P = 10^9 + 7$ 取模。

例如，序列 $(3, 3, 6, 1, 6, 6, 6)$ 有 $4$ 段。数据范围为 $1 <= n <= 2 times 10^5$，取值范围为 $1$ 到 $10^9$。

下文使用从 $0$ 开始的下标，并在读入时将题面的闭区间转为左闭右开区间 $[L_i, R_i)$。记 $d_i = R_i - L_i$，所有取值均为整数。

][
#include "solutions/cf1187f.typ"
]
