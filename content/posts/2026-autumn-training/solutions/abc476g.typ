#import "/.typst-blog/typst/blog.typ" as blog

由 Dilworth 定理，答案等于 popcount 序列的最长不升子序列长度，相等值可以连续选取。

令 $B=60$，将输入区间转为 $[L,R)$。按照线段树查询的方式，从左到右拆成 $O(B)$ 个二进制对齐块。每次取不越过 $R$、且 $L$ 为其长度倍数的最大块 $[L,L+2^k)$。令 $c=upright("popcount")(L)$，块内值为 $c+upright("popcount")(x)$，其中 $0<=x<2^k$；值 $c+t$ 出现 $C_(k,t)=binom(k,t)$ 次。

块内任意不升子序列，都可以替换为其最小值与最大值之间某一层的全部元素，长度不减，且不影响与两侧拼接。

#blog.math-fold(title: "块内只需选择一层的证明")[
将低 $k$ 位视为子集。若 $S subset T$，则对应整数及 popcount 均严格递增，不能同时出现在不升子序列中。因此所选集合族 $cal(F)$ 构成反链。

随机排列这 $k$ 个位，并依次加入，所得包含链至多经过 $cal(F)$ 中的一个集合。每个集合 $S$ 被经过的概率为 $binom(k,abs(S))^(-1)$，故

$ sum_(S in cal(F)) binom(k,abs(S))^(-1) <= 1. $

若选中元素的 popcount 均位于 $[u,v]$，则

$ abs(cal(F)) <= max_(u <= c+t <= v) C_(k,t). $

取允许范围内最大的完整层即可达到上界。该层的值仍在 $[u,v]$，因此不破坏两侧的不升关系。
]

令 $upright("dp")_j$ 为已处理前缀中末项至少为 $j$ 的最长不升子序列长度，初值均为 $0$，表示空序列。追加一块时，选取值为 $j$ 的整层，贡献为 $C_(k,j-c)$；再对末值取后缀最大值。按 $j=c+k,dots,0$ 逆序更新：

$ upright("dp")_j arrow.l max(upright("dp")_j+C_(k,j-c), upright("dp")_(j+1)). $

其中 $t<0$ 或 $t>k$ 时 $C_(k,t)=0$。更新时 $upright("dp")_j$ 仍是旧状态，$upright("dp")_(j+1)$ 已是新状态，可直接原地转移。最终答案为 $upright("dp")_0$。

预处理二项式系数需 $O(B^2)$ 时间与空间；每组需 $O(B^2)$ 时间、$O(B)$ 额外空间。

#blog.code(lang: "cpp", label: "C++")[
#raw(read("abc476g.cpp"), lang: "cpp", block: true)
]
