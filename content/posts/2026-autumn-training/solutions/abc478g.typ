#import "/.typst-blog/typst/blog.typ" as blog

将坐标放大 $p+q$ 倍，只需计算整数点 $S_(i,j)=q P_i+p P_j$ 的凸包，最后将面积除以 $(p+q)^2$。

按下标做 CDQ 分治。对区间 $[l,r)$，取中点 $m$，递归处理左右两半。跨区间的点对自动满足 $i<j$；将左半的点乘 $q$、右半的点乘 $p$，两者凸包的 Minkowski 和即为这部分点对的凸包。收集各分治结点得到的凸包顶点，最后再求一次凸包即可。

每层产生 $O(N)$ 个候选点，共 $O(N log N)$ 个。使用排序求凸包，总时间为 $O(N log^2 N)$，空间为 $O(N log N)$。

用叉积求出放大后凸包的二倍面积 $D$，答案为 $D/(2(p+q)^2)$，约分后输出。全程使用 $64$ 位整数。

#blog.code(lang: "cpp", label: "C++")[
#raw(read("abc478g.cpp"), lang: "cpp", block: true)
]
