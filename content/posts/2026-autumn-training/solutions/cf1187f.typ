#import "/.typst-blog/typst/blog.typ" as blog

考虑计算 $E[B^k]$，其中 $k>=1$，原题对应 $k=2$。采用从 $0$ 开始的下标，将取值区间转为 $[L_i,R_i)$，记 $d_i=R_i-L_i$。补充 $[L_n,R_n)=[0,1)$。定义 $Y_i=[X_i != X_(i+1)]$，则段数 $B=sum_(i=0)^(n-1)Y_i$。

令 $A_j=E[binom(B,j)]$，即所有大小为 $j$ 的边集同时满足 $Y_i=1$ 的概率之和。记 $q=min(k,n)$，由第二类 Stirling 数的恒等式得

$ E[B^k]=sum_(j=0)^q S(k,j)j!A_j. $

其中 $S(k,j)=S(k-1,j-1)+j S(k-1,j)$，$S(0,0)=1$，其余边界状态为 $0$。

将选中的边分解为极大连续段。不同段依赖的原变量集合不交，联合概率为各段概率之积。定义 $w_(l,t)$ 为边段 $[l,l+t)$ 全部满足 $Y_i=1$ 的概率，$D_(i,j)$ 为边前缀 $[0,i)$ 中所有大小为 $j$ 的边集的贡献之和，则 $A_j=D_(n,j)$。

#blog.math-fold(title: "DP 转移")[
按末边是否被选分类。若被选，枚举最后一个极大连续段的长度 $t$，其前一条边必须未选：

$ D_(i,j)=D_(i-1,j)+sum_(t=1)^(min(i,j))w_(i-t,t) cases([j=t] & i=t, D_(i-t-1,j-t) & i>t). $

初值 $D_(0,0)=1$，其余状态为 $0$。
]

#blog.math-fold(title: "连续段概率的容斥")[
变量区间 $[s,r)$ 全部相等的概率为

$ c(s,r)=(max(0,min_(s <= i < r)R_i-max_(s <= i < r)L_i))/(product_(i=s)^(r-1)d_i). $

令 $r=l+t+1$。在相等事件的容斥展开中，按包含 $X_(r-1)$ 的连通块 $[s,r)$ 分类。块内 $r-s-1$ 条边均选入容斥集合；若 $s>l$，分隔边 $s-1$ 未选。因此

$ w_(l,t)=sum_(s=l)^(r-1)(-1)^(r-s-1)c(s,r) cases(1 & s=l, w_(l,s-l-1) & s>l). $

初值 $w_(l,0)=1$。未选入容斥集合的边不施加相等约束。

按 $t$ 递增计算，固定 $r$ 后向左枚举 $s$，维护区间交集与逆元乘积，即可常数时间更新 $c(s,r)$。
]

总时间为 $O(n q^2+k q)$，空间为 $O(n q)$。原题 $k=2$ 时为线性规模。

#blog.code(lang: "cpp", label: "C++")[
#raw(read("cf1187f.cpp"), lang: "cpp", block: true)
]
