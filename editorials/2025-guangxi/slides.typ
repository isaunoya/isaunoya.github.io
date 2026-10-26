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
    title: [2025 广西邀请赛部分题目讲评],
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


= E. Elimination

== E. Elimination：题意

#link("https://ac.nowcoder.com/acm/contest/110811/E")[2025 广西邀请赛 E]。给定小写字母串 $S$，选择非空串 $T$。每次可以：

+ 删除 $T$ 的末字符；
+ 找到 $T$ 在当前 $S$ 中的一次出现，删除 $S$ 从开头到这次出现的*起点*，再删除 $T$ 的末字符。

最大化第二种操作的次数。多组数据，总长度不超过 $6000$。

#pause

一次匹配后只越过它的起点，*没有删掉整次出现*。后续匹配允许重叠，起点必须严格递增。

== E：只保留成功的匹配

若某个方案成功匹配 $k$ 次，第 $t$ 次匹配时，模式长度至少为 $k-t+1$。

将初始模式截成前 $k$ 个字符，删掉所有不产生匹配的操作；在原来的起点依次匹配长度 $k,k-1,dots,1$，每次仍然合法。

因此存在最优方案：初始模式长度等于答案，每次都成功匹配，然后删去末字符。

下面只需考虑这样的方案。数组下标从零开始，子串用半开区间表示。

== E：从首次匹配的起点转移

令 $f_i$ 为首次匹配起点是 $i$ 时，最多成功匹配多少次。若下一次从 $j>i$ 开始，剩余模式长度 $h$ 满足

$ h<=f_j, quad h<=upright("lcp")(i,j). $

于是

$ f_i=1+max_(j>i) min(f_j,upright("lcp")(i,j)). $

没有后继时最大值取零。倒序计算 $f_i$，答案为 $max_i f_i$。

== E：转移为何充分

长度 $f_j$ 的可行方案可以截短为任意 $h<=f_j$ 的方案：保留前 $h$ 次匹配，并将每次模式都缩成相应前缀。

若另外有 $h<=upright("lcp")(i,j)$，先在 $i$ 匹配 $S[i,i+h+1)$，再从 $j$ 继续这个长度 $h$ 的方案即可。

长度不会越界：归纳有 $f_j<=n-j$；由于 $j>i$，总有 $h+1<=n-i$。

反过来，任意非单次方案都有这样的第二个起点 $j$，故转移也不会漏掉最优方案。

== E：滚动维护 LCP

$ upright("lcp")(i,j)=cases(1+upright("lcp")(i+1,j+1) quad & S_i=S_j, 0 quad & S_i!=S_j). $

计算第 $i$ 行只依赖第 $i+1$ 行，可用一个数组 $L$。外层 $i$ 倒序，内层 $j=i+1,dots,n-1$ 正序，保证 $L[j+1]$ 仍是旧行的值。

更新 $L[j]$ 后，立即用 $1+min(f_j,L[j])$ 更新 $f_i$；每行从 $f_i=1$ 开始。$L[n]=0$ 作为边界。

两层循环各处理一对起点，时间 $O(n^2)$、空间 $O(n)$。状态 $f_j$ 不被覆盖，$n=1$ 时内层为空，答案自然为一。

= F. Faster Elimination

== F. Faster Elimination：题意

#link("https://ac.nowcoder.com/acm/contest/110811/F")[2025 广西邀请赛 F]。给定小写字母串 $S$，选择模式串 $T$；每次可以单独删去它的末字符，或匹配一次 $T$，越过这次出现的起点，再删去末字符。

最大化成功匹配次数。多组数据，总长度不超过 #box[$5 times 10^5$]；匹配可以重叠。

#pause

仍令 $f_i$ 为首次匹配从 $i$ 开始时的答案。二次转移已经成立；现在要快速求出所有已处理起点能提供的最长前缀。

== F：把转移变成字符串集合查询

处理 $i$ 前，对每个 $j>i$，将 $S[j,j+f_j)$ 及其全部前缀加入集合 $cal(P)$。

令 $L$ 为 $S[i,n)$ 属于 $cal(P)$ 的最长前缀长度，则

$ L=max_(j>i) min(f_j,upright("lcp")(i,j)), quad f_i=L+1. $

计算完 $f_i$ 后，将它对应的串及全部前缀插入。空串始终存在，因此第一次查询也有定义。

集合对前缀封闭；需要维护的不是任意一组字符串长度。

== F：不必显式插入全部前缀

令集合 $cal(P)$ 初始只含空串。每次查询最长已存在前缀 $L$，然后只插入长度 $L+1$ 的串。

若插入前集合对前缀封闭，则这个新串的长度 $L$ 前缀已经在集合中，它的更短前缀也已经在。因此插入后集合仍然对前缀封闭。

由归纳，每个位置只新增一个串，就等价于把它及全部前缀加入集合。整个过程中至多保存 $n$ 个非空串。

这一点使得普通哈希表就足够，不需要维护一棵字符串树。

== F：二分最长已存在前缀

对当前起点 $i$，判断 $S[i,i+k)$ 是否在集合中。由前缀封闭性，判断结果随 $k$ 增大必然先真后假。

长度零始终为真；长度 $n-i$ 为假，因为所有已处理起点 $j>i$ 插入的长度至多 $n-j<n-i$。

在这两个边界之间二分，得到最后一个真值 $L$。令 $f_i=L+1$，把 $S[i,i+f_i)$ 插入集合，再处理 $i-1$。

*必须先查询再插入*，否则当前串会被当成已经存在的后继方案。

== F：子串指纹与集合键

将 `a` 至 `z` 编码为 $1,dots,26$。取素数 $p$ 和随机底数 $b$，预处理幂与前缀哈希，以下运算均对 $p$ 取模：

$ H_(k+1)=H_k b+"code"(S_k), quad H_0=0. $

于是

$ "hash"(l,r)=H_r-H_l b^(r-l). $

使用两份独立底数得到两个指纹。哈希表的键为 $(r-l,h_1,h_2)$，长度也参与判等；查询时无需创建或复制子串。

模减法规范化到 $[0,p)$。哈希表自身的桶碰撞由键相等比较处理，与字符串指纹碰撞是不同的问题。

== F：从右向左维护前缀集合 <f-main-result>

先预处理两套前缀指纹。从右到左处理每个起点：在当前集合中二分最长可行前缀 $L$，令 $f_i=L+1$，再插入长度 $f_i$ 的一个串。答案为 $max_i f_i$。

每个位置新增一个键、进行 $O(log n)$ 次查询。哈希表操作均摊期望为常数时，总时间 $O(n log n)$、空间 $O(n)$。

两份底数独立均匀取自 $\{2,dots,p-2\}$，可取 $p=2^61-1$。对固定输入，首次错误之前沿精确执行路径作并集界；若查询数为 $Q$，全程误判至多

$ n Q ((n-1)/(p-3))^2, quad Q<=n ceil(log_2(n+1)). $

#link(<f-error-proof>)[自适应查询的错误率证明与参数约定]

= L. Lost in MST

== L. Lost in MST：题意

#link("https://ac.nowcoder.com/acm/contest/110811/L")[2025 广西邀请赛 L]。完全图有 $n$ 个点，第 $i$ 个点有正整数点权 $c_i$，边权为

$ w(x,y)=gcd(x,y)+upright("lcm")(x,y). $

#box[$n<=10^5$]，#box[$1<=c_i<=10^6$]，求最小生成树权值。

#pause

完全图无法显式建出。先合并相同点权，再为每个因子选择一个最小倍数作为代表；最后处理被合并的副本。

== L：因子代表与候选边

暂时假设所有点权互不相同。对每个因子 $d$，令 $z_d$ 为现有点权中最小的 $d$ 的倍数。

对每个满足 $d divides x$ 且 $x!=z_d$ 的点加入候选边 $(x,z_d)$，暂定边权为

$ W_d (x,z_d)=d+(x z_d)/d. $

同一对端点可以产生多条候选边，直接保留即可。候选权值不一定等于真实 gcd/lcm 边权，正确性需要单独证明。

== L：候选权值不会低估

取任意候选边 $(x,y)$，真实 gcd 为 $g$。因为 $d divides g$，有

$ 0<d<=g<=sqrt(x y). $

函数 $t+x y/t$ 在此区间单调不增，因此

$ w(x,y)=g+(x y)/g<=d+(x y)/d=W_d (x,y). $

候选图中阈值不超过 $t$ 的边，在原图中也不会超过 $t$。接下来证明，候选图也没有漏掉必须的连通关系。

== L：原图的一条边可由两条候选边替代

取原图边 $(x,y)$，令 $g=gcd(x,y)$，$z=z_g<=min(x,y)$。

#align(center)[#box(width: 650pt, height: 170pt)[
  #place(top + left, dx: 110pt, dy: 40pt)[#line(length: 430pt, stroke: (paint: rgb("#8194a6"), thickness: 1.5pt, dash: "dashed"))]
  #place(top + left, dx: 110pt, dy: 40pt)[#line(angle: 24.9deg, length: 237pt, stroke: 2.6pt + ink)]
  #place(top + left, dx: 325pt, dy: 140pt)[#line(angle: -24.9deg, length: 237pt, stroke: 2.6pt + ink)]
  #place(top + left, dx: 92pt, dy: 22pt)[#circle(radius: 18pt, fill: white, stroke: ink)[#align(center + horizon)[$x$]]]
  #place(top + left, dx: 522pt, dy: 22pt)[#circle(radius: 18pt, fill: white, stroke: ink)[#align(center + horizon)[$y$]]]
  #place(top + left, dx: 307pt, dy: 122pt)[#circle(radius: 18pt, fill: ice, stroke: ink)[#align(center + horizon)[$z$]]]
  #place(top + left, dx: 250pt, dy: 4pt)[#text(20pt)[$w(x,y)$]]
  #place(top + left, dx: 93pt, dy: 93pt)[#text(20pt, fill: ink)[$W_g (x,z)$]]
  #place(top + left, dx: 443pt, dy: 93pt)[#text(20pt, fill: ink)[$W_g (y,z)$]]
]]

$ max(W_g (x,z),W_g (y,z))<=g+(x y)/g=w(x,y). $

两条候选边都不比原边重，因此原图阈值 $t$ 下的一条边，可以换成候选图同一阈值下的路径。若 $z$ 恰好是端点，路径退化为一条边。

== L：阈值连通性决定 MST 权值

综合两个方向，两图在每个权值阈值下的连通块划分完全相同。

Kruskal 按边权递增合并。若权值 $t$ 处连通块数量减少 $k$，任何最小生成树都恰需在这一层付出 $k t$ 的代价。

所以两图最小生成树的总权值一致，可以直接用 $W_d$ 跑 Kruskal，无需为每条候选边再计算 gcd。

因子 $1$ 已把所有不同点权连接到最小值，候选图一定连通。

== L：候选边生成与复杂度

将不同点权从小到大扫描，枚举 $x$ 的所有约数 $d$。维护 $"first"[d]$：若已存在，就连边；否则记录 $x$。

设不同值集合为 $A$，$V=max c_i$，实际候选边数为 $E$，则

$ E<=sum_(x in A)upright("tau")(x)<=sum_(x=1)^V upright("tau")(x)=O(V log V). $

可用倍数筛预处理约数，或用最小质因子分解后生成约数。Kruskal 排序时间 $O(E log E)$，空间取决于实际保存的约数和边数。

不能把单个数的约数个数统一写成 $O(log V)$。

== L：重复点权的接入代价

值 $x$ 出现 $b_x$ 次。副本之间边权均为 $2x$，它们到任意外部顶点的边权也完全相同。

令 $m_x$ 为 $x$ 到其他不同值的最小边权；只有一种值时令 $m_x=oo$。额外副本每个增加的最优代价为

$ c_x=min(2x,m_x). $

阈值小于 $c_x$ 时，每个副本都孤立；达到 $c_x$ 后，它们或者内部连通，或者通过共同外部邻点连通。

因此额外的 $b_x-1$ 个连通块恰好在阈值 $c_x$ 消失。

== L：从已求出的树取得最小邻边

任意一棵 MST 中，顶点 $x$ 的最小树边权等于图中它的最小邻边权。

否则加入图中更轻的邻边，形成一个环；删去环上另一条与 $x$ 相接的树边，会严格减小总权值，矛盾。

候选图和原图具有相同的阈值连通性，顶点第一次不再孤立的阈值相同。因此扫描 Kruskal *选中的树边*，即可取得所有 $m_x$。

不需要为重复值另做一次完全图最短邻边搜索。

== L：合并答案与边界

$ upright("answer")=upright("MST")(A)+sum_(x in A)(b_x-1)min(2x,m_x). $

先按值压缩并记录出现次数；生成候选边；运行 Kruskal；统计每个代表的最小树边；最后加回副本代价。

只有一种值时答案为 $(n-1) times 2x$；$n=1$ 时答案为零。计算 $x y$、候选权值和总答案都使用 64 位整数。

若复用预处理处理多组数据，只清空本次访问过的因子代表；不要让上一组的 $"first"$ 留在下一组。

= 附录

== F：指纹碰撞如何影响答案 <f-error-proof>

在所有查询都正确的条件下，集合与二分严格实现前面的 DP。不同串指纹相同可能使集合产生假阳性，继而影响后续插入。

不能把这些受此前结果影响的查询直接当成独立试验。固定输入后，考虑*完全使用字符串判等的理想执行*；第一次发生错误时，程序此前仍与理想执行相同。

因此只需对理想执行中的查询与当时已存字符串对做并集界。若查询总数为 $Q$，需考虑的比较对至多 $n Q$。

== F：选取参数与实现边界

同长度不同串的差多项式次数小于 $n$。两份底数独立均匀取自 #box[$\{2,dots,p-2\}$]，则全程误判概率至多

$ n Q ((n-1)/(p-3))^2, quad Q<=n ceil(log_2(n+1)). $

可取 $p=2^61-1$，用两份独立随机底数；乘法用无符号 128 位中间值。两个固定底数没有这条随机试验保证。

哈希表预留容量、控制负载，并在测试间清空；整体正确性与哈希表的期望耗时分别分析。答案仍按原题输出整数。

#link(<f-main-result>)[返回 F 的算法与复杂度]
