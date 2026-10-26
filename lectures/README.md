# 课件

两份课件的唯一正文源分别为 `sqrt-decomposition/slides.typ` 和
`randomization/slides.typ`，使用 Touying 0.8.0 的 Stargazer 主题。原始 Typst / LaTeX 课件的
来源、正式选题范围与核验记录见 `../docs/ai-rewrite-sources.md`。

安装 Typst 0.15 与中文字体（macOS 的 PingFang SC 或 Linux 的 Noto Sans CJK SC）后，
在网站根目录运行：

```sh
npm run build:lectures  # 只编译两份课件
npm run build          # 编译课件、比赛讲评并构建整个网站
```

生成文件为 `public/lectures/sqrt-decomposition.pdf` 和
`public/lectures/randomization.pdf`，构建网站时复制到同名静态路径。
PDF 不提交到 Git；CI 使用相同命令重新生成。About 各提供一个直接 PDF 入口。

题目先显示题面，通过 Touying `#pause` 在下一步揭示提示或解法。
PDF 的物理页数因此可能多于页脚显示的逻辑页数。`[AI rewrite]` 仅标注在网页
的两个 PDF 入口；封面作者栏使用 `isaunoya`，封面与页脚均不展示修订日期。

根号专题的主讲依次为序列与值域分块、莫队与二次离线、参数与轻重分类、按时间
分块，到 PDF 第 51 页结束；其后六组拓展各列前置知识，并可跳回对应主讲。
随机化先讲 Quickselect，再引入指纹与见证抽样，到 PDF 第 35 页结束主讲；
数据结构应用、随机顺序的方法边界和构造证明分开选读。以上为阅读器中的物理页码。
原题与完整证明仍在同一 PDF 内，目录和附录入口可点击。

补充例题的小规模验证与完全乘性函数的有限范围核验：

```sh
python3 lectures/verify-examples.py
python3 lectures/verify-mos.py
python3 lectures/verify-random-foundations.py
python3 lectures/verify-sqrt-completion.py
python3 lectures/verify-random-completion.py
python3 lectures/randomization/verify-prime-cover.py
```

前五个脚本不需要额外依赖，检查例题转移、二次离线、可选解法与暴力答案
的一致性；最后一个脚本核验 200 至 1,000,000 的数论不等式。它们不代替课件中的正确性与概率证明。
