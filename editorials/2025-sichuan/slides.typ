#import "@preview/touying:0.8.0": *
#import themes.stargazer: *
#let lecture-outline(level: none) = components.custom-progressive-outline(
  level: level, depth: 1, alpha: 55%,
  numbered: (false,), filled: (false,), paged: (false,),
  indent: (0em,), vspace: (0.42em,),
  text-style: ((size: 24pt, weight: "bold", fill: rgb("#005bac")),),
)
#show: stargazer-theme.with(
  aspect-ratio: "16-9",
  align: top,
  header-right: none,
  footer-columns: (23%, 0pt, 1fr, 6em),
  footer-a: [isaunoya],
  footer-b: none,
  config-info(
    title: [2025 四川省赛部分题目讲评],
    subtitle: none,
    author: [isaunoya],
    institution: [Hangzhou Dianzi University],
    date: none,
  ),
  config-common(new-section-slide-fn: (body) => slide(title: [目录])[
    #lecture-outline(level: 1)
    #body
  ]),
  config-page(margin: (x: 42pt, top: 96pt, bottom: 37pt)),
  config-colors(neutral-darkest: rgb("#172434")),
  config-store(header: self => if self.store.title != none {
    block(width: 100%, height: 1.8em,
      fill: gradient.linear(self.colors.primary, self.colors.neutral-darkest),
      place(left + horizon, dx: 42pt,
        text(fill: self.colors.neutral-lightest, weight: "bold", size: 1.3em,
          utils.call-or-display(self, self.store.title)),
      ),
    )
  }),
)
#set text(font: ("PingFang SC", "Noto Sans CJK SC"), size: 23pt, lang: "zh")
#set par(justify: false, leading: 0.42em, spacing: 0.65em)
#set math.equation(numbering: none)
#show math.equation: set text(font: "New Computer Modern Math")
#show link: it => if type(it.dest) == str or type(it.dest) == label { text(fill: rgb("#005bac"), it) } else { it }
#show raw: set text(size: 0.83em)
#set list(indent: 1em, body-indent: 0.5em, spacing: 0.6em)
#set enum(indent: 1em, body-indent: 0.5em, spacing: 0.6em)
#let ink=rgb("#005bac")
#let amber=rgb("#a96620")
#let ice=rgb("#eaf2f8")
#let warm=rgb("#fbf1e2")
#let pale=rgb("#f1f4f7")
#let card(title, core, note, tint: ice) = block(
  width: 100%, height: 150pt, fill: tint, radius: 6pt, inset: 14pt,
)[
  #set par(leading: 0.2em, spacing: 0pt)
  #grid(columns: (1fr,), rows: (27pt, 37pt, 44pt), row-gutter: 7pt, align: center + horizon,
    text(19pt, weight: "bold", fill: ink, title),
    text(24pt, fill: rgb("#1d2b3a"), core),
    text(18pt, fill: rgb("#405065"), note),
  )
]
#let step(title, note) = block(
  width: 100%, height: 78pt, fill: pale, radius: 6pt, inset: 12pt,
)[
  #set par(leading: 0.2em, spacing: 0pt)
  #grid(columns: (1fr,), rows: (25pt, 24pt), row-gutter: 5pt, align: center + horizon,
    text(19pt, weight: "bold", fill: ink, title),
    text(17pt, fill: rgb("#405065"), note),
  )
]
#let tile(body, tint: ice, height: 84pt) = block(
  width: 100%, height: height, fill: tint, radius: 6pt, inset: 14pt,
)[
  #set par(leading: 0.2em, spacing: 0pt)
  #align(center + horizon, body)
]
#set table(
  stroke: (left: none, right: none, top: none, bottom: 0.6pt + rgb("#d4dfe8")),
  fill: (x, y) => if y == 0 { ice } else if calc.even(y) { rgb("#f6f8fa") } else { white },
  align: (x, y) => if x == 0 { center + horizon } else { left + horizon },
)
#show table.cell.where(y: 0): set text(weight: "bold", fill: ink)
#title-slide()

== 目录

#lecture-outline()

= A. 最小乘积

== A. 最小乘积：题意

#link("https://codeforces.com/gym/105949/problem/A")[2025 四川省赛 A]。有向边有两个正权 $a_e,b_e$，路径代价为

$ (sum_(e in P)a_e)(sum_(e in P)b_e). $

#box[$n<=300$]，#box[$m<=1000$]，#box[$1<=a_e,b_e<=200$]。多组数据，#box[$sum n<=1000$]、#box[$sum m<=2000$]，保证 $1$ 能到达 $n$。

输出最优路径的两个权值和；乘积相同时，优先输出较小的 $a$ 权和。

#pause

固定其中一个和，另一个和就成为可加的代价。

== A：为什么不能只保存当前最小乘积

前缀路径的两个和记为 $(A,B)$，接上边 $(a,b)$ 后，乘积为

$ (A+a)(B+b)=A B+a B+b A+a b. $

后续不仅依赖 $A B$，还分别依赖 $A,B$。当前乘积更小的前缀，接上相同边以后不一定更优。

但在 $A$ 相同的条件下，较小的 $B$ 始终占优。因此保留“到达顶点与 $A$ 权和”即可进行可靠的状态合并。

== A：按第一种权值分层

令 $f_(s,u)$ 为到达 $u$、$a$ 权和恰为 $s$ 时最小的 $b$ 权和。

初始 $f_(0,1)=0$，其他状态为无穷。对边 $(u,v,a,b)$，转移

$ f_(s+a,v) arrow.l min(f_(s+a,v),f_(s,u)+b). $

因为 $a>0$，所有转移严格增加层数。按 $s$ 递增扫描即可；同一层内部没有依赖，不需要再运行最短路。

== A：层数的上界

若一条路径含环，删去环会同时减小两个正权之和，乘积也会变小。因此最优路径可以取为简单路径，最多包含 $n-1$ 条边。

令 $A=max_e a_e$，只需计算到

$ S=(n-1)A. $

扫描所有有限的 $f_(s,n)$，按二元组 $(s f_(s,n),s)$ 取最小，保存对应的两个和。题目要求输出这两个和，不是它们的乘积。

== A：正确性与复杂度 <a-main>

所有转移只生成实际路径；任何最优简单路径也落在上述层数范围内。

对同一 $(s,u)$，丢掉较大的第二种权值和不会影响任意后续延伸。因此 DP 枚举到最优解，并且不会产生比真实最优解更小的答案。

完整表空间为 $O(S n)$；转移共 $O(S m)$，加上初始化为 $O(S(n+m))$。乘积比较使用 64 位整数。

$n=1$ 时空路径给出 $(0,0)$。不可达状态不做加法，避免无穷哨兵溢出。

#link(<a-circular-detail>)[选讲：循环层数组的空间优化]

= C. 最优时间

== C. 最优时间：题意

#link("https://codeforces.com/gym/105949/problem/C")[2025 四川省赛 C]。状态为 $x$，每秒选择保持不变，或等概率变成 $x$ 的约数及不超过 $N$ 的倍数之一；随后状态减一。

给定 $N$ 与 $Q$ 次初始状态询问，求到达零的最小期望时间。#box[$N,Q<=10^5$]，允许 #box[$10^(-6)$] 的绝对或相对误差。

#pause

随机一步可能跳到更大的状态，按状态大小递推会形成循环依赖。

== C：Bellman 方程与同步迭代

令 $S(x)$ 为随机动作可选的集合，$f(0)=0$。每个动作先花一秒，再进入下一状态：

$ f(x)=1+min(f(x-1),1/abs(S(x)) sum_(y in S(x))f(y-1)). $

将右侧记为算子 $T$。从一直等待的策略 $h_0(x)=x$ 出发，同步计算 $h_(t+1)=T h_t$。

$h_t$ 表示前 $t$ 步允许最优决策、之后一直等待的代价。由 $T$ 保序且 $T h_0<=h_0$，有

$ f<=h_(t+1)<=h_t. $

== C：为什么极限就是最优值

任意策略在接下来 $N$ 步中，若始终等待，则必然结束；否则看第一次随机操作，它选到 $1$ 的概率至少为 $1/N$，随后立即到达零。

因此每 $N$ 步至少有 $1/N$ 的概率结束。反复分段可知任意策略的结束时间尾部趋于零，且期望有限。

把最优策略截断在第 $t$ 步，之后改为等待；残余代价至多为 $N$ 乘尚未结束的概率，随 $t$ 趋于零。

故 $h_t$ 收敛到 $f$。仅有“单调、有下界”还不足以说明极限是所需最优值。

== C：残差给出的答案区间 <c-residual-main>

对旧数组 $h$ 完整计算 $g=T h$，令 $delta=max_(x>0)(h(x)-g(x))$。任意动作都满足 $h(x)<=1+E[h(X')]+delta$；沿最优策略累加到零，得到

$ h(x)<=(1+delta)f(x), quad frac(h(x),1+delta)<=f(x)<=h(x). $

因此检查所有状态的区间宽度

$ frac(h(x)delta,1+delta)<=epsilon. $

若通过，输出这份旧数组 $h$；否则交换为 $g$ 继续。浮点计算取 $epsilon=10^(-8)$ 留出余量。残差是事后精度证书，还需证明它会在有限轮内通过。

== C：每轮汇总约数与倍数

对每个 $x$，先把自身 $x$ 计入 $S(x)$。再枚举严格整除关系 $d<y$、$d divides y$：$y$ 加入 $S(d)$，$d$ 加入 $S(y)$，分别累加旧值 $h(y-1)$ 与 $h(d-1)$。

每个成员只计一次。关系总数为 $O(N log N)$，集合大小可以预处理；据此在同一轮重新计算等待与随机两个动作。

一轮时间 $O(N log N)$、空间 $O(N)$。预处理后每个询问查表；状态零始终为零，$N=1$ 时初始策略已最优。

#link(<c-sync-detail>)[同步更新与停止条件的完整顺序]

== C：势函数控制迭代轮数 <c-rate-main>

沿最优策略，在非零状态有 $E[f(X')]=f(x)-1$。若 $f<=H$，则 #box[$f(x)-1<=(1-1/H)f(x)$]，从而吸收时间 $tau$ 满足

$ Pr(tau>k)<=H(1-1/H)^k. $

若某一轮已知 $f<=h_t<=H$，先按最优策略走 $k$ 步、再改用 $h_t$ 对应的策略，可得

$ 0<=h_(t+k)-f<=H^2(1-1/H)^k. $

残差不超过当前误差，答案区间宽度因而至多 $H^3(1-1/H)^k$。

#link(<c-tail-proof>)[几何尾界与残差界的推导] · #link(<c-analytic-proof>)[一般规模的纯解析轮数界]

== C：本题范围内的轮数保证 <c-main-result>

对所有 $N<=10^5$，用向上取整的整数算子完整验证，可得 $h_40(x)<10$。取 $H=10$，第 300 次更新检查旧数组 $h_299$，其区间宽度至多

$ 10^3(9/10)^259<10^(-8). $

因此在精确算术下，最多 300 次更新即可通过残差判据。总时间 $O(K N log N+Q)$，本题范围内 $K<=300$；空间 $O(N)$。

这个常数依赖完整有限范围的整数验证，浮点实现仍检查残差并保留精度余量。纯解析分析另给出 $O(sqrt(N)log(N/epsilon))$ 轮上界。

#link(<c-range-certificate>)[整数上界算子与可复验结论]

= I. 本质不同后缀

== I. 本质不同后缀：题意

#link("https://codeforces.com/gym/105949/problem/I")[2025 四川省赛 I]。给若干小写字母串，总长度不超过 #box[$3 times 10^5$]，求所有非空后缀去重后的个数。

#pause

反转是双射，不改变两个字符串是否相等。原串的后缀，恰好变成反转串的前缀。

问题因此等价于：将所有反转串插入 Trie，统计不同的非空前缀。

== I：每个非根节点就是一个答案

Trie 中每个非根节点对应根到它的唯一路径，即一个不同的非空前缀。每个插入串的每个前缀，也都会经过某个节点。

两者一一对应，所以答案等于 Trie 节点数减一。

不只统计标记为字符串结尾的节点；一个前缀即使不是任何完整输入串，也对应一个合法后缀。

重复插入不会创建新路径，自动完成去重；空串只对应根，因此需要排除根。

== I：线性实现

从每个字符串末尾向前读字符，直接沿 Trie 转移，不必实际复制反串。缺少转移时创建节点，并将所有出边初始化为空。

设输入总长度为 $L$，最多创建 $L$ 个非根节点。使用从零开始的根编号时，容量至少为 $L+1$；若另留零作为空指针，还要额外预留哨兵位置。

固定 26 个小写字母，时间与空间均为 $O(L)$。最后输出创建的非根节点总数。

= L. abc

== L. abc：题意

#link("https://codeforces.com/gym/105949/problem/L")[2025 四川省赛 L]。给定仅含 `a`、`b`、`c` 的字符串，长度 #box[$n<=2 times 10^5$]。

每个非空子串的价值为：出现最多的字符次数，减去出现最少的*已出现字符*次数。求所有子串价值之和。

#pause

未出现字符的零次数不参与最小值。先允许零参与计算，再分别扣除两种字符、单种字符的多算量。

== L：三个计数转成三组差值

设一个子串的计数为 $a,b,c$。将三者排序为 $x<=y<=z$，有

$ abs(a-b)+abs(a-c)+abs(b-c)=2(z-x). $

所以允许零次数参与时，价值为

$ (abs(a-b)+abs(a-c)+abs(b-c))/2. $

分别求三个绝对差在所有子串上的总和，最后除以二即可。三个数之间的大小关系不需要分类维护。

== L：绝对差转成前缀和对

以 $a-b$ 为例，把 `a` 记为 $1$、`b` 记为 $-1$、`c` 记为 $0$，得到前缀和 $p_0,dots,p_n$。

子串 $[i,j)$ 的计数差为 $p_j-p_i$，需要计算

$ D=sum_(0<=i<j<=n) abs(p_j-p_i). $

每对不同前缀下标对应唯一非空子串。绝对值对称，因此可以把所有前缀值排序，而不用保留原下标顺序。

== L：排序后的贡献

排序后有 $v_0<=dots<=v_n$。扫描到 $v_j$ 时，它和之前所有前缀产生的贡献为

$ sum_(i<j)(v_j-v_i)=j v_j-sum_(i<j)v_i. $

维护之前的数量与数值和，即可线性完成扫描。整个过程连同排序为 $O(n log n)$。

相同前缀值的贡献是零，不需要去重；删掉重复值会丢失它们与其他前缀组成的合法下标对。

== L：两种字符的多算量

若子串只包含两种字符，正计数为 $a,b$。第一步因第三种计数为零而算成 $max(a,b)$，实际应为 $max(a,b)-min(a,b)$。

所以应扣除 $min(a,b)$。固定缺失字符，例如 `c`，将原串切成不含 `c` 的极长段。

每个不含 `c` 的子串唯一属于其中一段。段内可利用

$ min(a,b)=((a+b)-abs(a-b))/2. $

== L：一个二字符段的扣除量

长度为 $m$ 的段，其所有非空子串长度之和为

$ F(m)=sum_(k=1)^m k(m-k+1)=m(m+1)(m+2)/6. $

设该段按前缀和方法算出的绝对差总和为 $D$，需要扣除

$ (F(m)-D)/2. $

对三个缺失字符分别切段并累计。单色子串虽然可能落入两种切分，但其 $min(a,b)=0$，不会重复扣除非零贡献。

== L：最后处理单色子串

单色子串的真实价值为零，第一步却把其长度计入；第二步的最小计数为零，尚未扣掉它。

枚举每个相同字符的极长连续段，长度为 $m$ 时，再减去 $F(m)$。

这就完成互斥的三类核对：三种字符直接正确；两种字符扣掉较小正计数；一种字符扣掉整段长度贡献。

长度为一以及整个串只有一种字符的情况，都自然得到零。

== L：用值域桶替代排序

一个长度 $m$ 的段，前缀和的最大值与最小值之差至多 $m$。每段从零重新求前缀，将桶下标整体加 $m$，或减去该段最小前缀值；统计各值次数，按值递增扫描。

设当前值为 $x$，出现 $c$ 次；之前已有 $C$ 个前缀，数值总和为 $S$，则本组贡献为

$ c(x C-S). $

随后更新 $C arrow.l C+c$、$S arrow.l S+c x$。组内值相同，互相贡献为零。

每次只初始化当前段长度对应的桶，不能对每个短段清空整个长度 $n$ 的数组。

== L：合并各阶段与总复杂度

+ 三组计数差的全串绝对差和相加，除以二。
+ 对每个缺失字符的极长段，扣除 $(F(m)-D)/2$。
+ 对所有单色极长段，扣除 $F(m)$。

每一种切分中，所有段长度之和不超过 $n$。因此排序实现共 $O(n log n)$；值域桶实现共 $O(n)$，空间都是 $O(n)$。

总答案为 $O(n^3)$，所有累计值与 $F(m)$ 都使用 64 位整数；乘法先提升类型，再进行整数除法。

= 附录

== 证明与实现索引

- #link(<c-tail-proof>)[C：最优值势函数与几何收敛]
- #link(<c-range-certificate>)[C：覆盖所有允许规模的整数上界]
- #link(<c-analytic-proof>)[C：不依赖有限验证的解析轮数界]
- #link(<c-sync-detail>)[C：同步更新与残差的实现顺序]
- #link(<a-circular-detail>)[A：循环层数组]

#link(<c-main-result>)[返回 C 的轮数结论]

== C：迭代轮数与吸收时间 <c-tail-proof>

残差能说明某次停止时足够精确，却不能单独说明什么时候会停止。下面补充轮数上界。

先取最优平稳策略，记吸收时间为 $tau$、第 $k$ 步状态为 $X_k$。若对所有状态都有 $f(x)<=H$，则在非零状态

$ E[f(X_(k+1)) mid X_k]=f(X_k)-1. $

每步花费一秒，最优策略后续仍然最优，因此可以用 $f$ 本身作为势函数。

== C：势函数给出几何尾界

由于 $f(x)<=H$，有

$ f(x)-1<=(1-1/H)f(x). $

状态零的势函数为零。迭代条件期望得到

$ E[f(X_k)]<=H(1-1/H)^k. $

非零状态至少还要花一秒，所以 $f(x)>=1$。于是

$ Pr(tau>k)<=E[f(X_k)]<=H(1-1/H)^k. $

== C：从尾界到迭代误差

假设某一轮 $h_t$ 已满足 $f<=h_t<=H$。先执行最优策略 $k$ 步，再按 $h_t$ 对应的策略继续，是 $h_(t+k)$ 可选的方案。

与始终执行最优策略相比，只有第 $k$ 步还未结束时才可能增加代价，且增加量至多 $H$。因此

$ 0<=h_(t+k)-f<=H^2(1-1/H)^k. $

同时，$h-T h<=h-f$，停止区间宽度至多

$ H^3(1-1/H)^k. $

#link(<c-rate-main>)[返回 C 的收敛速度]

== C：统一覆盖所有允许的 N <c-range-certificate>

要取得较小的 $H$，对 #box[$N_*=10^5$] 定义一个更保守的算子。随机动作的平均值，取所有允许上界 $M$ 中最差的一个：

$ A_h (x)=max_(x<=M<=N_*) 1/abs(S_M (x)) sum_(y in S_M (x))h(y-1), $

$ (R h)(x)=1+min(h(x-1),A_h (x)). $

它逐项不小于任意具体规模的 Bellman 算子。由相同初值 $h_0(x)=x$ 出发，$R$ 的迭代因此同时支配所有 $N<=N_*$ 的迭代。

== C：把上界计算变成整数验证

取尺度 $s=10^6$，初始 $u_0(x)=s x$。每个平均数都向上取整，再执行

$ u_(t+1)(x)=s+min(u_t (x-1),ceil(A_(u_t)(x))). $

只用整数加法、除法和比较；向上取整的方向保证

$ h_t^(N)(x)<=frac(u_t (x),s) quad (x<=N<=N_*). $

枚举 $M$ 不需要二重循环：约数部分固定，随 $M$ 变化的只是倍数列表的前缀。逐个加入倍数，并维护最大平均值即可，一轮仍为 $O(N_* log N_*)$。

== C：有限范围证书给出的数值

对全部 #box[$1<=x<=10^5$] 执行上述整数迭代，40 轮后逐项检查得到

$ max_x u_40(x)=9788341<10^7. $

因此对*所有* $N<=10^5$ 都有 $h_40^(N)(x)<10$，可以在误差界中取 $H=10$。

这一步是覆盖完整有限范围的整数验证，不是随机抽样或浮点实验。验证程序给出完整算子、取整方向和断言，可单独重新运行。

#link(<c-main-result>)[返回 C 的轮数结论]

== C：一个纯解析的较松上界 <c-analytic-proof>

取阈值 $B$：状态不超过 $B$ 时一直等待；否则一直随机，直到进入小状态或结束。若 $B>=N$，直接使用等待策略。

令 $D_B=max_(x>B)abs(S(x))$。每次高状态操作直接选到一的概率至少为 $1/D_B$，所以该策略期望至多 $B+D_B$。

记 $upright("tau")(x)$ 为约数个数。取 $B=ceil(sqrt(N))$，利用 $upright("tau")(x)<=2sqrt(N)$，可得

$ max f<=B+2sqrt(N)+N/B<=4sqrt(N)+1. $

这是对最优值 $f$ 的上界，初始数组 $h_0(x)=x$ 尚不满足这个较小上界；还需要区分初始代价和势函数的范围。

== C：一般上界如何用于初始数组

令 $H=4sqrt(N)+1$。势函数尾界仍给出 #box[$Pr(tau>k)<=H(1-1/H)^k$]，但截断后改为等待的代价至多为 $N$，因此

$ 0<=h_k-f<=N H(1-1/H)^k. $

又因为 $h_k<=N$、残差不超过当前误差，停止区间宽度至多

$ N^2 H(1-1/H)^k. $

于是 #box[$O(sqrt(N) log(N/epsilon))$] 轮足以达到所需误差；每轮成本仍需另乘。这个纯解析界适用于一般规模，有限范围整数验证则把本题的上界进一步收紧。

#link(<c-rate-main>)[返回 C 的收敛速度]

== C：同步值迭代的核心 <c-sync-detail>

```text
h[x] = x; h[0] = 0
repeat:
    sum = aggregate_divisors_and_multiples(h)
    for x = 1, ..., N:
        g[x] = 1 + min(h[x-1], sum[x]/cnt[x])
    delta = max_x(h[x]-g[x])
    if max_x(h[x])*delta/(1+delta) <= tolerance:
        break
    swap(h, g)
```

等待动作每轮也必须重新计算。只比较旧的 $h(x)$ 与随机动作，会漏掉“先等待一步，再使用已经改善的后续策略”。

== C：停止条件对应哪一份数组

区间宽度为

$ h(x)delta/(1+delta). $

一次迭代先用旧数组 $h$ 算出新数组 $g=T h$，再由二者计算 $delta$。上述区间是对*旧数组* $h$ 的保证。

若所有状态的宽度已经足够小，可直接输出这份 $h$；否则交换数组继续。不要交换后混用旧残差和另一份上界。

实现可用 `long double`，将阈值取到 #box[$10^(-8)$] 留出舍入余量。固定迭代轮数不提供这个精度判断。

#link(<c-residual-main>)[返回 C 的残差证书]

== A：可选的循环层数组 <a-circular-detail>

每次转移跨越 $1,dots,A$ 层，因此只保留 $A+1$ 个槽，层 $s$ 使用槽 #box[$s mod (A+1)$]。

处理当前层时，先记录到终点的候选答案，再完成所有出边转移，最后清空当前槽。

未来目标层都在 $s+1,dots,s+A$ 中，与当前槽不同；当前槽下一次使用于 $s+A+1$，因此不会覆盖尚未使用的状态。

空间降为 $O(A n)$，时间界不变。层数上界及越界转移的检查仍然保留。

#link(<a-main>)[返回 A 的复杂度]
