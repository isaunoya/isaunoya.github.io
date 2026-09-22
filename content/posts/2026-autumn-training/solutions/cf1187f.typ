#import "/.typst-blog/typst/blog.typ" as blog

考虑计算 $E[B^k]$，其中 $k>=1$，原题对应 $k=2$。下标从 $0$ 开始，取值区间转为 $[L_i,R_i)$，末尾补充哨兵区间 $[0,1)$。记此时共有 $N$ 个变量、$m=N-1$ 条边，$upright("il")_i=(R_i-L_i)^(-1)$。令 $Y_i=[X_i != X_(i+1)]$，则段数 $B=sum_(i=0)^(m-1)Y_i$。

展开 $B^k$ 时，每项至多涉及 $k$ 条不同的边，而总边数为 $m$，故只需统计 $j<=q=min(k,m)$ 条边的贡献。每个选中连续段的长度不超过总选边数 $j$，因此连续段长度也只需计算到 $q$。

先求 $w_(l,t)$，表示边段 $[l,l+t)$ 全部满足 $Y_i=1$ 的概率。

#blog.math-fold(title: "连续段概率的容斥")[
变量区间 $[s,r)$ 全部相等的概率为

$ c(s,r)=max(0,min_(s <= i < r)R_i-max_(s <= i < r)L_i) product_(i=s)^(r-1) upright("il")_i. $

令 $r=l+t+1$。在相等事件的容斥展开中，按包含 $X_(r-1)$ 的连通块 $[s,r)$ 分类。块内 $r-s-1$ 条边均选入容斥集合；若 $s>l$，分隔边 $s-1$ 未选。因此

$ w_(l,t)=sum_(s=l)^(r-1)(-1)^(r-s-1)c(s,r) cases(1 & quad s=l, w_(l,s-l-1) & quad s>l). $

初值 $w_(l,0)=1$。未选入容斥集合的边不施加相等约束。

按 $t$ 递增计算，固定 $r$ 后向左枚举 $s$，维护区间交集与逆元乘积，即可常数时间更新 $c(s,r)$。
]

再求 $upright("dp")_(i,j)$，表示边前缀 $[0,i)$ 中所有大小为 $j$ 的边集同时变化的概率之和。将选中的边分解为极大连续段，不同段之间至少空出一条边，依赖的原变量集合不交，因此联合概率为各段概率之积。

#blog.math-fold(title: "DP 转移")[
按末边是否被选分类。若被选，枚举最后一个极大连续段的长度 $t$，其前一条边必须未选：

$ upright("dp")_(i,j)=upright("dp")_(i-1,j)+sum_(t=1)^(min(i,j))w_(i-t,t) cases([j=t] & quad i=t, upright("dp")_(i-t-1,j-t) & quad i>t). $

初值 $upright("dp")_(0,0)=1$，其余状态为 $0$。
]

令 $a_j=upright("dp")_(m,j)=E[binom(B,j)]$。指示变量的重复幂可以合并，按不同下标的数量分组，用第二类 Stirling 数还原：

$ E[B^k]=sum_(j=0)^q S(k,j)j!a_j. $

其中 $S(k,j)=S(k-1,j-1)+j S(k-1,j)$，$S(0,0)=1$，其余边界状态为 $0$。代码用 $s_j$ 倒序滚动计算，最后得到 $s_j=S(k,j)$。

总时间为 $O(m q^2+k q)$，空间为 $O(m q)$。原题 $k=2$ 时为线性规模。

#blog.code(lang: "cpp", label: "C++")[
#raw(read("cf1187f.cpp"), lang: "cpp", block: true)
]
