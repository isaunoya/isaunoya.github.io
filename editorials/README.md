# 比赛部分题目讲评

四份讲评仅收录作者参与命题且正式采用的题目，不覆盖整场比赛。

课件使用 Touying 0.8.0 的 Stargazer 主题，正文为 23pt。唯一正文源为各目录的
`slides.typ`；题面先展示，提示与解法在 `#pause` 后出现。每个题目有目录入口与正式题目链接。

| 目录 | 收录题目 |
| --- | --- |
| `2024-ccpc-women` | D、E、I、J |
| `2025-sichuan` | A、C、I、L |
| `2025-guangxi` | E、F、L |
| `2025-online-2` | C、D、J、L |

在网站根目录运行 `npm run build:editorials` 编译四份讲评；`npm run build` 同时编译
两份专题课件与四份比赛讲评，再构建网站。需要 Typst 0.15 与 PingFang SC 或 Noto Sans CJK SC。

输出为 `public/solutions/{slug}.pdf`，构建时复制到 `dist/solutions/`。
About 保留每场比赛的原题链接，另设题解 PDF 入口；不生成独立 HTML 题解页。
生成的 PDF 不提交 Git。
`[AI rewrite]` 仅标在入口上，课件封面与正文不重复说明，也不显示修订日期。

来源、与本地题稿的差异以及验证记录见 `../docs/ai-rewrite-sources.md`。
广西 F 采用原题解后半的二分哈希做法，先证明前缀封闭性，再给完整执行顺序和错误率界。

主线保留决定算法的观察、正确性与复杂度；较长证明和常规实现说明放在可跳转、
可返回的附录。四川 C 的主线为七张逻辑页，整数证书和一般规模解析界仍完整保留；
女生赛 D 的随机判零细节、广西 F 的首次错误概率分析及 Online II C 的增广路
解释也可从正文直接访问。新增图示解释 LIS/LDS 交点、字符串复制的饱和贡献、
MST 替代路径与树中心的端点分组。

验证关键转移与四川 C 的轮数证书：

```sh
python3 editorials/verify-editorials.py
python3 editorials/verify-contest-solutions.py
c++ -O2 -std=c++20 editorials/verify-sichuan-c-bound.cpp -o /tmp/verify-sichuan-c
/tmp/verify-sichuan-c
```

前两项穷举小实例并对照独立算法；最后一项用 64 位整数向上取整，覆盖所有
`N <= 100000`，验证第 40 轮统一上界小于 10。数学推导见讲评及
`../docs/sichuan-c-iteration-bound.md`。测试不替代正确性证明。

Online II L 同时给出简洁分块与可持久化 Trie 思路，具体节点表示放在
`2025-online-2/xor-mirror.cpp`。默认编译即为正式输入格式的完整实现；
使用 `-DSELF_TEST` 可运行暴力差分，`-DSTRESS_TEST` 可检查最大规模的节点池：

```sh
c++ -O2 -std=c++20 -DSELF_TEST editorials/2025-online-2/xor-mirror.cpp -o /tmp/verify-xor-mirror
/tmp/verify-xor-mirror
```

Trie 采用定期整体展开并重建，避免无界保留历史节点；修改均摊 O(log N)、
查询最坏 O(log N)、空间 O(N)。普通不回收的持久化节点池不满足此空间界。
