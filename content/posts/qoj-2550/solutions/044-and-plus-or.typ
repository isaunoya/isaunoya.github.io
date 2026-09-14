把下标看成其二进制表示中值为 $1$ 的位置组成的集合，定义

$ D(X, Y) = A_(X inter Y) + A_(X union Y) - A_X - A_Y. $

只要存在 $D(X, Y) > 0$ 的集合对，就一定存在只相差两个二进制位的解。

若 $abs(X backslash Y) > 1$，取 $X inter Y subset.neq Z subset.neq X$，则

$ D(X, Y) = D(Z, Y) + D(X, Z union Y). $

展开后 $A_Z$ 与 $A_(Z union Y)$ 抵消即可验证。右侧至少有一项为正，且两项中集合的对称差都更小。对 $Y backslash X$ 同理，因此反复分解可使两个差集都只剩一个元素；具有包含关系时 $D(X, Y) = 0$，不会成为正值解。

于是枚举两个二进制位 $a < b$，以及不含这两位的集合 $S$，检查

$ A_(S union {a}) + A_(S union {b}) < A_S + A_(S union {a, b}). $

满足时输出 $S union {a}$ 与 $S union {b}$；均不满足则输出 $-1$。时间复杂度为 $O(N^2 2^N)$，空间复杂度为 $O(2^N)$。

*实现* #link("https://qoj.ac/submission/2955576")[QOJ 提交 2955576]。
