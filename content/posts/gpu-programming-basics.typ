#import "/.typst-blog/typst/blog.typ" as blog

#show: blog.post.with(
  title: "GPU Programming Basics",
  slug: "gpu-programming-basics",
  date: "2026-07-04",
  tags: ("gpu", "cuda", "ai-infra"),
  excerpt: "整理 CUDA / NVIDIA GPU 中 host-device 执行关系、kernel launch、thread/block/SM、occupancy、显存传输、stream、同步、访存模式、调试和性能测量等基础概念。",
  published: true,
)

#let refmark(n) = link(label("ref-" + str(n)), super("[" + str(n) + "]"))

= 分类方式

本文按七类组织：

#figure(
  table(
    columns: 2,
    inset: 8pt,
    [分类], [内容],
    [编程入口], [host / device、kernel launch、最小 kernel、错误检查],
    [执行模型], [thread、warp、block、cluster、grid、索引方式],
    [资源与调度], [SM、waves、occupancy、resident blocks / warps、register pressure],
    [内存模型与访存], [memory spaces、dynamic shared memory、host-device transfer、memset async、global memory coalescing、shared memory bank conflict],
    [同步与异步], [block 同步、warp 同步、atomic、memory fence、stream、event],
    [性能测量与调试], [effective bandwidth、event timing、CUPTI、Nsight、Compute Sanitizer],
    [CUDA / 硬件特性用法], [vectorized load / store、BF16x2 packed arithmetic、Tensor Core、compute capability],
  ),
  caption: [本文的分类边界。]
)

= 编程入口：host/device 与 kernel launch

CUDA 程序通常由 CPU 侧 host code 和 GPU 侧 device code 共同组成。host code 负责分配内存、搬运数据、配置 kernel launch，并在需要时等待结果；device code 在 GPU 上以大量 threads 的形式执行。CUDA C++ 中，`__global__` 函数表示从 host 发起、在 device 上执行的 kernel；`__device__` 函数只能在 device 侧调用；`__host__` 函数在 host 侧调用。#refmark(14)#refmark(15)

最小的 CUDA 程序路径可以概括为：

$ "allocate host/device memory" arrow.r "copy input to device" arrow.r "launch kernel" arrow.r "copy output to host" arrow.r "free memory" $

kernel launch 使用 execution configuration 指定 grid 和 block：

#blog.code(lang: "cuda")[
```cuda
// One-dimensional vector add.
__global__ void add_kernel(const float* a, const float* b, float* c, int n) {
  int i = blockIdx.x * blockDim.x + threadIdx.x;
  if (i < n) {
    c[i] = a[i] + b[i];
  }
}

int block = 256;
int grid = (n + block - 1) / block;
add_kernel<<<grid, block>>>(d_a, d_b, d_c, n);

```
]

这里 `grid` 决定启动多少个 blocks，`block` 决定每个 block 内有多少 threads。边界判断 `i < n` 很重要，因为常见写法会把 grid 向上取整，最后一个 block 可能有一部分 threads 没有对应数据。

例如 $n = 1000$、$upright("block") = 256$ 时：

$ upright("grid") = ceil(1000 / 256) = 4 $

总共会启动 $4 times 256 = 1024$ 个 threads，其中最后 $24$ 个 threads 没有对应元素。若 kernel 里没有 `if (i < n)`，这些 threads 就可能越界访问。

需要区分 kernel 参数传递和 host-device 数据传输。launch 时，CUDA runtime / driver 会把函数入口、execution configuration、stream 和实参值组织成一条提交给 device 的命令；标量参数 `n`、指针参数 `d_a`、`d_b`、`d_c` 的值会作为 kernel parameters 传到 device 可读的参数区。若实参是指针，传过去的是指针值本身，而不是该指针指向的数组内容。因此：

#blog.code(lang: "cuda")[
```cuda
cudaMemcpy(d_a, h_a, bytes, cudaMemcpyHostToDevice);
cudaMemcpy(d_b, h_b, bytes, cudaMemcpyHostToDevice);

add_kernel<<<grid, block>>>(d_a, d_b, d_c, n);

cudaMemcpy(h_c, d_c, bytes, cudaMemcpyDeviceToHost);

```
]

上面真正做 H2D / D2H 的是 `cudaMemcpy`；中间的 kernel launch 只让 kernel 收到 `d_a`、`d_b`、`d_c` 和 `n` 这些参数，并不自动把 `h_a` / `h_b` 搬到 device，也不自动把 `d_c` 拷回 host。若使用 Unified Memory、mapped pinned memory 或框架 allocator，数据迁移路径可能由运行时或框架隐藏，但这仍然不同于普通 kernel launch 自动执行 H2D / D2H copy。#refmark(15)#refmark(17)

kernel launch 相对 host 通常是异步的：launch 返回不表示 kernel 已经执行完成，只表示 launch 请求已经提交。检查 launch 配置错误可用 `cudaGetLastError()`；若要把 device 执行错误同步暴露到 host，常见做法是在调试阶段调用 `cudaDeviceSynchronize()`。生产路径中不应在每个 kernel 后无条件同步，否则会破坏异步流水线。#refmark(14)

kernel launch 存在固定提交开销，因为它不是一次普通函数调用，而是一次 GPU work submission。一次 warm launch 的 host 侧路径大致包括：进入 CUDA runtime / driver、整理 kernel 参数、检查 launch configuration、把 kernel command 放入目标 stream、维护 stream 顺序和依赖、记录错误状态，并把命令交给 driver 管理的 command buffer / work queue。随后 device 才能按 stream 依赖和资源可用性调度这个 kernel。这里的开销通常不随 kernel 内实际计算量线性增长，所以当 kernel 很短、launch 很频繁、或一次训练 / 推理 step 被拆成许多小 kernel 时，host 侧提交开销会变得明显。#refmark(14)#refmark(18)

还需要区分 warm launch 和 cold launch。第一次使用 CUDA context、第一次触发某个 module、或需要 JIT / lazy loading 时，launch 附近可能包含初始化、模块装载和代码准备成本；这些成本不代表每次 kernel 执行都需要同样时间。若只用 CPU timer 包住 `add_kernel<<<grid, block>>>(...)`，通常测到的是 enqueue latency；若 launch 后立刻调用 `cudaDeviceSynchronize()`，测到的则是提交开销、stream 中前序工作等待、kernel 执行、错误回传和同步等待的总和。测 device 执行时间时，更常用 CUDA events 或 profiler。#refmark(14)#refmark(18)#refmark(22)

CUDA Graphs 正是针对重复工作提交开销的一类机制：把一组 kernel、copy、memset 及其依赖先描述成 graph，再实例化为可重复 launch 的 executable graph。这样可以把一部分依赖分析、参数组织和调度准备从每次提交转移到 graph 构建 / 实例化阶段；对固定结构且反复执行的小 kernel 流水线，graph launch 往往比逐个 kernel launch 更适合控制 CPU 侧开销。它不改变 kernel 本身的计算量，也不自动减少 H2D / D2H 数据量，只是改变 host 向 GPU 提交工作的方式。#refmark(27)

= 执行模型

== 执行层级

GPU kernel 由 CPU 发起，GPU 同时启动大量 threads 执行它。CUDA 中最常见的执行层级是：

$ "thread" arrow.r "warp" arrow.r "block" arrow.r "cluster" arrow.r "grid" $

#figure(
  table(
    columns: 2,
    inset: 8pt,
    [层级], [含义],
    [thread], [最小执行单位],
    [warp], [一组一起调度的 threads，NVIDIA GPU 上通常是 32 个 threads#refmark(1)],
    [block], [多个 warps，放到一个 SM 上执行],
    [cluster], [多个 blocks，可以跨 SM 协作；Hopper / compute capability 9.0 引入#refmark(1)#refmark(2)],
    [grid], [一次 kernel 启动里的全部 blocks],
  ),
  caption: [GPU 执行层级，从小到大。]
)

在 CUDA API 语境中，device 通常指一块 CUDA 可见的 GPU 或 MIG 这类逻辑 GPU 实例，而不是某一个 SM。SM 是 device 内部的计算单元：kernel launch 面向的是整个 device，grid 中的 blocks 再由调度器分配到该 device 的多个 SM 上执行。因此，`cudaSetDevice(0)` 选择的是第 0 个 CUDA device，不是选择某个 SM；用户通常也不能在普通 CUDA kernel launch 中指定“这个 block 必须跑在哪个 SM 上”。#refmark(1)#refmark(37)#refmark(38)

SM 可视为 GPU 中实际执行计算的单元。基础阶段需要区分：device 是 API 看到的执行和内存管理对象，SM 是 device 内部承载 blocks / warps 的硬件资源；thread 是最小执行单位，warp 是调度单位，block 是常用协作单位。

NVIDIA 的执行模型通常称为 SIMT。一个 warp 内的 lanes 通常执行同一条指令；如果分支条件不同，就会产生 warp divergence，硬件需要分路径执行，部分 lanes 会暂时不参与有效计算。#refmark(1)

== cluster 的直观例子

普通 block 之间通常不能直接共享 shared memory。若一个 block 产生的中间结果要给另一个 block 使用，常见做法是写回 global memory，再由另一个 block 读回来。Hopper 的 thread block cluster 允许同一个 cluster 内的 blocks 通过 distributed shared memory 协作，并使用 cluster 级同步。#refmark(2)

这种能力只有在跨 block 数据复用足够明显时才有价值；否则 cluster 同步和资源约束本身也会带来开销。

#blog.code(lang: "cuda")[
```cuda
// Pseudo CUDA: compare data exchange paths.

// Without cluster:
// block A writes an intermediate tile to global memory.
global_memory[tile_id] = partial_tile;

// block B reads the tile back later.
next_tile = global_memory[tile_id];

// With cluster:
// blocks in the same cluster exchange through distributed shared memory.
cluster_shared[tile_id] = partial_tile;
cluster_barrier();
next_tile = cluster_shared[tile_id];

```
]

== 索引与维度

CUDA 里常见的三维索引有两组：

- $upright("threadIdx.x")$ / $upright("threadIdx.y")$ / $upright("threadIdx.z")$：表示一个 thread 在 block 内的位置。
- $upright("blockIdx.x")$ / $upright("blockIdx.y")$ / $upright("blockIdx.z")$：表示一个 block 在 grid 内的位置。

对应的尺寸由 $upright("blockDim")$ 和 $upright("gridDim")$ 给出。$upright("threadIdx")$ 的每一维都从 0 开始，最大值是对应维度减一。例如 $upright("threadIdx.x")$ 的范围是 0 到 $upright("blockDim.x") - 1$。$upright("blockIdx")$ 也是同理。#refmark(1)

#figure(
  table(
    columns: 3,
    inset: 8pt,
    [项目], [常见上限], [说明],
    [$upright("blockDim.x")$], [1024], [单个 block 的 x 维上限],
    [$upright("blockDim.y")$], [1024], [单个 block 的 y 维上限],
    [$upright("blockDim.z")$], [64], [单个 block 的 z 维上限],
    [$upright("blockDim.x") times upright("blockDim.y") times upright("blockDim.z")$], [1024], [单个 block 的总 threads 上限],
    [$upright("gridDim.x")$], [2147483647], [grid 的 x 维上限],
    [$upright("gridDim.y")$ / $upright("gridDim.z")$], [65535], [grid 的 y / z 维上限],
  ),
  caption: [现代 NVIDIA GPU 上常见的 CUDA 维度限制。#refmark(3)]
)

三维索引展平成一维时，通常按 x 最快、y 其次、z 最慢的顺序：

$ upright("thread_id") = upright("threadIdx.x") + upright("threadIdx.y") times upright("blockDim.x") + upright("threadIdx.z") times upright("blockDim.x") times upright("blockDim.y") $

$ upright("block_id") = upright("blockIdx.x") + upright("blockIdx.y") times upright("gridDim.x") + upright("blockIdx.z") times upright("gridDim.x") times upright("gridDim.y") $

二维 grid 中也常把 block 内索引和 block 索引组合成全局坐标：

#blog.code(lang: "cuda")[
```cuda
int x = blockIdx.x * blockDim.x + threadIdx.x;
int y = blockIdx.y * blockDim.y + threadIdx.y;
int offset = y * width + x;

if (x < width && y < height) {
  out[offset] = in[offset];
}

```
]

这只是索引展开方式，不等于实际调度顺序。不同 blocks 的执行顺序不应作为程序语义依赖；需要跨 block 同步时，应拆成多个 kernel 或使用更明确的同步机制。#refmark(1)

= 资源与调度

== SM、waves 与 occupancy

SM 数量是 GPU 型号的属性。一个 kernel 启动后，grid 里的 blocks 会被调度到这些 SM 上执行；SM 越多，同一时刻能并行承载的工作通常越多，但实际并行度还受每个 block 的资源占用限制。#refmark(3)

wave 可以理解为一批能同时填满全部 SM 的 blocks。若每个 SM 可驻留 $B_"resident"$ 个 blocks，GPU 有 $N_"SM"$ 个 SM，则一轮完整 wave 可容纳：

$ W_"full" = N_"SM" times B_"resident" $

若 grid 里有 $N_"blocks"$ 个 blocks，则 wave 数约为：

$ N_"waves" = ceil(N_"blocks" / W_"full") $

tail wave 通常不完整，部分 SM 会没有工作。对很短的 kernel 或 latency-sensitive 路径，grid 的 blocks 数若只比完整 wave 多一点，末尾利用率可能明显下降。

例如一张 GPU 有 $N_"SM" = 120$，每个 SM 可驻留 $B_"resident" = 2$ 个 blocks，则一轮完整 wave 是：

$ W_"full" = 120 times 2 = 240 $

若 kernel 只有 $N_"blocks" = 250$，它会形成一轮完整 wave 加一轮只有 $10$ 个 blocks 的 tail wave。第二轮中大部分 SM 没有工作，kernel 末尾的利用率会明显下降。

occupancy 描述一个 SM 上实际驻留的 warps 相对理论上限的比例。较高 occupancy 有助于隐藏访存延迟，但它不是唯一目标；如果为了提高 occupancy 而牺牲寄存器复用、shared memory 复用或 Tensor Core 利用率，整体性能未必更好。#refmark(4)

这些限制来自固定的硬件预算。对一张具体 GPU 来说，每个 SM 的寄存器文件大小、shared memory 容量、最大 resident warps / blocks 都是固定的；kernel 的 thread 数、寄存器使用量和 shared memory 使用量会共同决定实际能驻留多少工作。主要约束可写成：

$ B_"resident" <= min(B_"hw", floor(R_"SM" / R_"block"), floor(S_"SM" / S_"block"), floor(T_"SM" / T_"block")) $

这里 $R_"SM"$ / $S_"SM"$ / $T_"SM"$ 分别表示每个 SM 的寄存器、shared memory 和 threads 预算；$R_"block"$ / $S_"block"$ / $T_"block"$ 表示单个 block 的资源占用。真实上限还会受架构细节、寄存器分配粒度和编译结果影响。#refmark(3)#refmark(4)

给定数量级会更直观。CUDA Programming Guide 的 compute capability 表给出的现代架构资源大致如下；这里的 KB / K 按 NVIDIA 表格口径，均以 1024 为单位。#refmark(3)

#figure(
  table(
    columns: 4,
    inset: 8pt,
    [资源], [典型量级], [代表 compute capability], [含义],
    [32-bit registers / SM], [64 K 个 32-bit registers], [7.5 到 12.x 表中均为 64 K], [这是整个 SM 的 register file 预算，约等于 256 KiB 的 32-bit 槽位；会被驻留在该 SM 上的所有 blocks / warps 共享。],
    [32-bit registers / block], [最多 64 K 个], [7.5 到 12.x], [单个 block 不能独占超过这个数量；实际还受每 thread register 数和分配粒度限制。],
    [32-bit registers / thread], [最多 255 个], [7.5 到 12.x], [这是编译器可给单个 thread 分配的上限，不表示用到 255 个仍然高效。],
    [shared memory / SM], [约 64 KB 到 228 KB], [7.5: 64 KB；8.0 / 8.7: 164 KB；8.6 / 8.9 / 12.x: 100 KB；9.0 / 10.x / 11.0: 228 KB], [这是每个 SM 上可给 resident blocks 分配的 shared memory 总预算。],
    [shared memory / block], [约 64 KB、99 KB、163 KB 或 227 KB], [随 compute capability 变化], [超过 48 KB 的 per-block dynamic shared memory 通常需要显式 opt-in；不能只看 per-SM 总量。],
    [resident warps / SM], [约 32 到 64 个 warps], [现代架构常见范围], [这决定理论 occupancy 的分母之一；高 occupancy 不是唯一优化目标。],
    [resident threads / SM], [约 1024 到 2048 个 threads], [现代架构常见范围], [block size 和 resident block 数共同决定能否接近该上限。],
  ),
  caption: [每个 SM 的资源数量级。具体值应以目标 GPU 的 compute capability 和 `cudaGetDeviceProperties` 为准。]
)

上表是 per-SM 资源。实际做系统估算时，还需要知道整卡，也就是一个 CUDA device / accelerator 的显存容量、HBM 带宽和互联量级。下面只列 NVIDIA 官方公开页面能直接支撑的经典型号或系统形态；A100 / H100 / H200 是单 GPU 规格，B200 / B300 使用 NVIDIA 官方 HGX / GB 系统页面给出的系统级规格，避免把未明确标注的系统总量强行拆成 per-GPU 数字。#refmark(32)#refmark(33)#refmark(34)#refmark(35)#refmark(36)

#figure(
  table(
    columns: 5,
    inset: 8pt,
    [型号], [架构 / 形态], [显存量级], [HBM / 互联量级], [说明],
    [A100 80GB SXM], [Ampere], [80 GB HBM2e#refmark(36)], [2,039 GB/s HBM 带宽#refmark(36)], [上一代大规模训练 / 推理集群的经典基线；NVIDIA 同页还列出 A100 80GB PCIe，其 HBM 带宽为 1,935 GB/s。],
    [H100 SXM], [Hopper], [80 GB HBM3#refmark(35)], [3.35 TB/s HBM 带宽；NVLink 约 900 GB/s；PCIe Gen5 约 128 GB/s#refmark(35)], [Hopper 时代最典型的训练 / 推理 GPU。NVIDIA 还列出 H100 NVL 形态，显存和 NVLink 口径不同；这里只取常见 SXM 量级。],
    [H200 SXM], [Hopper + HBM3E], [141 GB#refmark(33)], [4.8 TB/s HBM 带宽；NVLink 约 900 GB/s；PCIe Gen5 约 128 GB/s#refmark(33)], [H100 之后的 memory-capacity / bandwidth 增强型 Hopper GPU，适合大模型推理和 memory-bound HPC 场景。],
    [HGX B200], [Blackwell；8x B200 SXM], [8 GPU 总 memory 1.4 TB#refmark(32)], [第五代 NVLink；GPU-to-GPU bandwidth 1.8 TB/s；系统 total NVLink bandwidth 14.4 TB/s#refmark(32)], [官方 HGX 页面给出的是 8 GPU 系统规格；本文不再自行拆分成单 GPU 数字。],
    [GB300 NVL72], [Blackwell Ultra；72 GPU rack-scale 系统], [GPU memory 20 TB#refmark(34)], [GPU memory bandwidth up to 576 TB/s；NVLink bandwidth 130 TB/s#refmark(34)], [官方页面给出的是 rack-scale 系统规格；用于说明 Blackwell Ultra 系统级 memory / interconnect 量级。],
  ),
  caption: [几个常见数据中心 GPU / accelerator 的整卡量级。系统形态、功耗档位、OEM 配置和软件栈会影响实际可用值。]
)

例如某个 kernel 每个 thread 使用 128 个 registers，block size 是 256，则单个 block 的 register 需求约为：

$ R_"block" = 128 times 256 = 32768 $

若该 SM 有 64 K 个 32-bit registers，单看 register 预算最多只能放下两个这样的 blocks。若同一个 block 还使用 80 KB shared memory，而目标架构每 SM shared memory 只有 100 KB，则 shared memory 会把 resident blocks 进一步限制为 1。由此可以看出，occupancy 不是抽象概念，而是这些 per-SM 资源预算共同取最小值的结果。

active warp 指已经驻留在 SM 上、尚未执行结束的 warp。active 不等于每个周期都在发射指令；warp 可能因为访存、同步或依赖关系暂时不能执行。在 Hopper 的 WGMMA 语境中还会遇到 warpgroup：它通常由 4 个 warps，也就是 128 个 threads 组成，用于 warpgroup 级矩阵指令。#refmark(5) active warpgroup 可以类比理解为已经驻留并参与这类协作的 warpgroup。基础阶段只需区分：warp 是常规调度单位，warpgroup 是部分 Tensor Core 指令的协作单位。

== register pressure、local memory 与 spill

寄存器是每个 thread 私有、延迟最低的存储资源。一个 kernel 每个 thread 使用的寄存器越多，同一个 SM 上可同时驻留的 warps 往往越少；寄存器不足时，编译器可能把部分变量 spill 到 local memory。local memory 不是片上的“本地 SRAM”，而是每个 thread 私有、地址空间上属于 device memory 的存储区域；它的访问路径更接近 global memory，在现代架构上通常经过 cache 层次，而不是 shared memory 这类显式管理的片上空间。#refmark(16)#refmark(28)

这里还要区分两类来源：一种是 register spill，即编译器本来希望把某些临时值留在寄存器里，但寄存器预算或 live range 压力过高，只能把它们放入 local memory；另一种是 thread-local object placement，即源代码中某些自动变量本身需要一个可寻址的 thread-private 存储对象，例如大型结构体或动态索引的局部数组。后者不一定会在 `ptxas -v` 里表现为 spill stores / spill loads。#refmark(28)

因此，kernel 中写 `float a[4]` 不等于一定得到 `a0`、`a1`、`a2`、`a3` 四个寄存器。若所有下标都是编译期常量，循环被完全展开，并且数组地址没有逃逸，编译器可能做 scalar replacement，把数组元素提升为独立寄存器：

#blog.code(lang: "cuda")[
```cuda
float a[4];
a[0] = x;
a[1] = y;
a[2] = a[0] + a[1];
a[3] = a[2] * scale;

out[i] = a[0] + a[1] + a[2] + a[3];

```
]

但这只是编译器优化结果，不是 CUDA 源码层面的保证。若下标来自运行时变量、数组较大、数组地址被传给函数，或寄存器压力已经很高，编译器就更可能为它分配 local memory：

#blog.code(lang: "cuda")[
```cuda
float a[16];

#pragma unroll
for (int k = 0; k < 16; ++k) {
  a[k] = base + k * scale;
}

int j = runtime_index & 15;
out[i] = a[j];

```
]

这个例子里的 `a[j]` 需要按运行时下标选择元素。对很小的数组，编译器有时仍能把它改写成一串 select；但只要优化器无法可靠完成这种标量替换，数组就需要一个真正可寻址的 thread-local 存储位置，也就是 local memory。由此可见，`0 bytes spill stores` / `0 bytes spill loads` 只能说明没有这类 spill slot，不等于整个 kernel 完全没有 local memory 访问。

因此，优化 kernel 时不能只看 occupancy。若降低寄存器使用量导致重复计算或更多访存，性能可能下降；若适度增加寄存器复用减少 global memory 访问，occupancy 降低也可能是值得的。实际判断应结合 Nsight Compute 中的 achieved occupancy、memory throughput、stall reasons 和指令统计，而不是只追求理论 occupancy 最大化。

一个常见信号是 `ptxas -v` 输出中的寄存器数和 spill 信息：

#blog.code(lang: "text")[
```text
ptxas info    : Used 96 registers, 0 bytes smem
ptxas info    : Function properties for my_kernel
ptxas info    : 32 bytes spill stores, 32 bytes spill loads

```
]

这里的 spill 表示部分 thread-local 状态被放到了 local memory。若 profiler 同时显示 local memory load / store 明显增加，就需要检查大型局部数组、动态索引的 thread-local 数组、过度展开、复杂表达式或 template 展开是否导致 local memory 访问增加。进一步确认时，可以看 `ptxas -v` 报告的 `lmem`，看 PTX 中是否出现 `.local` 对象、`ld.local` / `st.local` 指令，或在 SASS / Nsight Compute 中检查 local load / store 相关指标。

= 内存模型与访存

== memory spaces 与内存层级

GPU 性能瓶颈不一定来自计算吞吐，也可能来自数据移动。越靠近计算单元，访问越快，但容量通常越小。CUDA 编程时需要同时区分硬件层级和 CUDA memory spaces。#refmark(16)

下面表格里的 device 指 CUDA API 可见的 CUDA device / GPU 实例；在不讨论 MIG、虚拟化或多进程隔离时，可以近似理解为一张物理 GPU。SM、L1/shared memory、register 是这个 device 内部更小的执行和存储资源；global memory、constant memory、texture path 和 L2 的“整个 device”作用域，指同一个 CUDA device 内的 blocks / SMs 可以通过相应路径访问或共享，而不是跨多张 GPU 自动共享。

#figure(
  table(
    columns: 3,
    inset: 8pt,
    [层级 / 空间], [作用域], [典型用途],
    [register], [单个 thread], [临时变量、索引、局部累加],
    [local memory], [单个 thread], [寄存器 spill、大型或动态索引的 thread-local 数组],
    [shared memory / L1], [一个 block], [tile 缓存、block 内数据复用],
    [global memory / HBM], [整个 CUDA device], [主数据存储、跨 block 交换],
    [constant memory], [整个 CUDA device，只读], [小型只读参数，适合广播式访问],
    [texture / read-only path], [整个 CUDA device，只读], [有局部性或特殊访问模式的只读数据],
    [L2], [同一 CUDA device 内的 SMs 共享], [global memory 访问的共享 cache],
    [NVLink / PCIe], [多 CUDA devices 或 host-device], [跨设备或出卡通信#refmark(6)],
  ),
  caption: [CUDA 编程中常见的 memory spaces 和硬件层级。#refmark(16)]
)

shared memory 是程序显式管理的片上空间，常用于把 global memory 中的 tile 搬到更近的位置，再让一个 block 内的 threads 重复使用。constant memory 和 texture / read-only path 不是替代 shared memory 的通用缓存；它们适合特定只读访问模式。local memory 名字容易误导，它通常代表 thread-private 的 device memory 后备存储。

一个典型 shared memory 使用模式是先合作搬运，再同步，再复用：

#blog.code(lang: "cuda")[
```cuda
constexpr int BLOCK_SIZE = 256;

__shared__ float tile[BLOCK_SIZE];

int tid = threadIdx.x;
int global_i = blockIdx.x * BLOCK_SIZE + tid;
tile[tid] = input[global_i];
__syncthreads();

float left = tile[(tid + BLOCK_SIZE - 1) % BLOCK_SIZE];
float cur = tile[tid];
output[global_i] = left + cur;

```
]

这个例子只说明数据复用路径，并假设 launch 使用 `BLOCK_SIZE` 个 threads，且每个 thread 都有有效输入。真实 stencil 或 GEMM kernel 还要处理数组尾部、block 边界、halo、bank conflict 和访存合并。

== dynamic shared memory 与指针切片

前面的 `__shared__ float tile[BLOCK_SIZE]` 属于静态 shared memory，大小在编译期确定。若每个 block 需要的 shared memory 大小依赖运行期参数，可以使用 dynamic shared memory：kernel 内声明一个 `extern __shared__` buffer，launch 的第三个参数给出每个 block 分配多少字节。#refmark(16)

需要两个逻辑数组时，不应写两个 `extern __shared__` 声明并期待 CUDA 自动分配两段互不重叠的空间。dynamic shared memory 本质上是一块连续的 per-block buffer，通常从同一个 base 指针手动切片。若两个数组类型相同，最直接的写法是按元素数量做 pointer shift：

#blog.code(lang: "cuda")[
```cuda
__global__ void two_tile_kernel(const float* x, float* y, int tile_elems) {
  extern __shared__ float smem[];

  float* tile_a = smem;
  float* tile_b = tile_a + tile_elems;

  int tid = threadIdx.x;
  if (tid < tile_elems) {
    tile_a[tid] = x[tid];
    tile_b[tid] = x[tile_elems + tid];
  }
  __syncthreads();

  if (tid < tile_elems) {
    y[tid] = tile_a[tid] + tile_b[tid];
  }
}

size_t shared_bytes = 2 * tile_elems * sizeof(float);
two_tile_kernel<<<grid, block, shared_bytes>>>(x, y, tile_elems);

```
]

这里 `tile_b = tile_a + tile_elems` 的单位是 `float` 元素，而不是字节；launch 侧的 `shared_bytes` 才按字节计算。若同一块 dynamic shared memory 中混合不同类型，就应按 byte offset 切片，并让每一段起点满足对应类型的对齐要求：

#blog.code(lang: "cuda")[
```cuda
extern __shared__ __align__(16) unsigned char smem_bytes[];

float* values = reinterpret_cast<float*>(smem_bytes);

size_t offset = value_count * sizeof(float);
offset = (offset + alignof(int) - 1) & ~(alignof(int) - 1);
int* indices = reinterpret_cast<int*>(smem_bytes + offset);

```
]

这里把 byte buffer 的 base 至少按 16 bytes 对齐，是为了让后续把它转换成 `float*`、`int*` 这类 typed pointer 时有明确的对齐前提；若要放入对齐要求更高的类型，base 对齐和每个切片的 offset 都要相应提高。真实代码通常会把 `align_up` 写成小 helper，并把 padding 后的总字节数也计入 launch 的 dynamic shared memory 参数。否则第二个数组可能和第一个数组重叠，或因为对齐不满足而产生低效甚至错误的访问。

== host-device 分配与传输

独立 GPU 通常有自己的 device memory。host 指针不能直接当作 device 指针使用，device 指针也不能直接在普通 CPU 代码中解引用。最基本的显存管理路径包括 `cudaMalloc`、`cudaFree`、`cudaMemcpy` 和 `cudaMemset`。#refmark(17)#refmark(29)

`cudaMemcpyHostToDevice` 中的 device 也不是 SM。它表示目标指针属于 CUDA device address space；最常见的情况是目标指针由当前 device 上的 `cudaMalloc` 返回，对应这块 GPU 的 global memory / HBM 中的一段 allocation。H2D copy 把 host memory 中的字节搬到这个 device allocation 里，通常经由 PCIe / NVLink 和 copy engine / driver 路径完成；数据不会因为 copy 本身就进入某个 SM 的 register 或 shared memory。后续 kernel 被调度到 SM 上执行时，SM 再从 global memory 读取这些数据，放入 cache、register 或 shared memory 中使用。#refmark(16)#refmark(17)

#blog.code(lang: "cuda")[
```cuda
float *d_a = nullptr, *d_b = nullptr, *d_c = nullptr;
cudaMalloc(&d_a, n * sizeof(float));
cudaMalloc(&d_b, n * sizeof(float));
cudaMalloc(&d_c, n * sizeof(float));
cudaMemcpy(d_a, h_a, n * sizeof(float), cudaMemcpyHostToDevice);
cudaMemcpy(d_b, h_b, n * sizeof(float), cudaMemcpyHostToDevice);
add_kernel<<<grid, block>>>(d_a, d_b, d_c, n);
cudaMemcpy(h_c, d_c, n * sizeof(float), cudaMemcpyDeviceToHost);
cudaFree(d_a);
cudaFree(d_b);
cudaFree(d_c);

```
]

host-device 传输通常比 device 内部 HBM 访问慢得多，并且会引入额外同步。Best Practices Guide 的基本建议是减少不必要的 host-device 传输，把可在 GPU 上连续完成的步骤留在 GPU 上，并尽量批量搬运。#refmark(17)

pageable host memory 和 pinned host memory 也需要区分。普通 pageable memory 传输时，运行时可能需要额外 staging；pinned memory 不能被 OS 换出，通常能提供更高的 PCIe / NVLink host-device 传输吞吐，并且是异步 copy 与 compute overlap 的常见前提。但 pinned memory 会占用系统资源，不应无限制分配。#refmark(17)

使用 pinned memory 的基本形式是：

#blog.code(lang: "cuda")[
```cuda
float* h_a = nullptr;
cudaHostAlloc(&h_a, n * sizeof(float), cudaHostAllocDefault);

cudaMemcpyAsync(d_a, h_a, n * sizeof(float),
                cudaMemcpyHostToDevice, stream);

cudaStreamSynchronize(stream);
cudaFreeHost(h_a);

```
]

这里的 `cudaMemcpyAsync` 仍然只是提交异步 copy。释放或复用 `h_a` 之前，必须保证使用它的异步 copy 已经完成；示例中用 `cudaStreamSynchronize(stream)` 表达这个生命周期边界。真实流水线中通常不应在每次 copy 后立刻同步，而是用 event、stream 同步或更外层的 buffer 生命周期管理，在不破坏 overlap 的位置等待。是否真正和 kernel 重叠，需要看 stream 依赖、copy engine、数据大小和 profiler timeline。

== memset async 与批量化

`cudaMemset` / `cudaMemsetAsync` 的语义是把一段 device memory 的前 `count` 个字节设为同一个 byte value。需要注意，它不是按元素类型赋值：`cudaMemset(ptr, 1, n * sizeof(int))` 得到的是每个 byte 为 `0x01`，不是每个 `int` 为 1。因此，清零 buffer 常用 `cudaMemsetAsync`，但设置非零 FP32 / INT32 数组通常应使用 kernel 或库函数。#refmark(29)

`cudaMemsetAsync` 通常相对 host 是异步的：调用返回不表示 memset 已经完成，只表示操作已经提交到指定 stream；同一 stream 中，它和前后的 kernel / copy / event 遵守 stream 顺序。若传入 non-default stream，文档只承诺它可能和其他 streams 中的操作重叠。还需要注意，CUDA 同步行为文档明确提醒：`Async` 后缀不是 host 调用绝不阻塞的保证，具体同步 / 异步行为可能受参数和内部资源状态影响，未文档化的阻塞行为不应作为程序语义依赖。#refmark(29)#refmark(30)

#blog.code(lang: "cuda")[
```cuda
cudaMemsetAsync(d_flags, 0, num_flags * sizeof(int), stream);
kernel<<<grid, block, 0, stream>>>(d_flags, other_args);

```
]

这段代码中，`kernel` 在同一 stream 内排在 memset 之后，因此会看到 `d_flags` 已被清零。它不需要额外 `cudaDeviceSynchronize()`；只有 host 需要立即读取结果或复用相关 host-side 资源时，才需要 event 或 stream synchronization。

从实现角度看，不应把 `cudaMemsetAsync` 简化成“DMA”或“kernel launch”。在 CUDA API 层，它既不是用户写的 `<<<...>>>` kernel，也没有用户可见的 grid / block 配置；它是一条被 runtime / driver 提交到 stream 的 memory set operation。底层可能根据目标地址、大小、对齐、架构和驱动版本选择 copy / fill engine、内部 device routine 或其他命令形式。官方文档只给语义和同步行为，不保证某次 memset 一定由 DMA engine 或 SM kernel 完成；性能判断应以 Nsight Systems / Nsight Compute timeline 为准。

更稳健的 mental model 是：`cudaMemsetAsync` 是 stream 中的一个 memory command，而不是 C++ 层面的 kernel launch。它和 kernel 一样参与 stream ordering，所以后续同 stream kernel 能看到它的结果；但它没有 kernel launch syntax，也不把执行资源、并行度和实现路径暴露给用户。若 profiler 中看到某次 memset 占用 copy engine，可以把它当作该平台上的实现事实；若看到内部 kernel 或其他 device-side activity，也不应反推所有平台都如此。

截至 CUDA Runtime API v13.3.1，memory-management 文档中有 `cudaMemcpyBatchAsync`、`cudaMemcpy3DBatchAsync`、`cudaMemPrefetchBatchAsync`、`cudaMemDiscardBatchAsync` 等 batch 接口；其中前两类是批量 copy，后两类面向 managed memory 的 prefetch / discard，并不是 batch memset。该文档中没有名为 `cudaMemsetAsyncBatch` 或 `cudaMemsetBatchAsync` 的函数。#refmark(29) 因此，“批量 memset”通常有几种工程做法：

#figure(
  table(
    columns: 2,
    inset: 8pt,
    [做法], [适用场景],
    [合并区间], [多个区间物理连续且 value 相同，直接合并成一次 `cudaMemsetAsync`，提交开销和命令数最低。],
    [多次 `cudaMemsetAsync`], [区间数量少，代码简单；每次 API 调用和每条 stream operation 都有提交开销。],
    [CUDA Graph], [固定的一组 memset / copy / kernel 反复执行，把多个 memset 节点 capture 或显式加入 graph，实例化后 replay，降低重复 CPU 提交开销。#refmark(27)],
    [自定义 fill kernel], [很多小区间、区间列表每轮变化，或需要按元素类型设置非零值；一个 kernel 读取 descriptor 数组并填充多个 range，但会占用 SM 资源。],
  ),
  caption: [批量 memset 的常见实现选择。]
)

若业务里提到的 `memsetAsyncBatch` 指“把许多 memset 合成一次提交”，通常不是调用某个同名 Runtime API，而是在上表几种方法里选一种。固定拓扑时，CUDA Graph 可以捕获或显式创建多个 memset nodes，例如使用 `cudaGraphAddMemsetNode`，再把 graph 实例化后反复 replay；这样减少的是每轮 CPU 提交成本，不等于把多个物理写入自动合并成一次内存事务。#refmark(27)#refmark(31)

若 range 列表每轮变化，常见做法是写一个自定义 fill kernel。host 先准备一组 descriptor，device kernel 再按 descriptor 写多个区间：

#blog.code(lang: "cuda")[
```cuda
struct FillRange {
  unsigned char* ptr;
  size_t bytes;
  unsigned char value;
};

__global__ void batch_memset_kernel(const FillRange* ranges, int num_ranges) {
  int range_id = blockIdx.y;
  if (range_id >= num_ranges) {
    return;
  }

  FillRange r = ranges[range_id];
  size_t stride = size_t(gridDim.x) * blockDim.x;
  size_t i = size_t(blockIdx.x) * blockDim.x + threadIdx.x;

  for (; i < r.bytes; i += stride) {
    r.ptr[i] = r.value;
  }
}

dim3 block(256);
// Enough x tiles to cover the largest range in this batch.
dim3 grid(num_tiles_per_range, num_ranges);
batch_memset_kernel<<<grid, block, 0, stream>>>(d_ranges, num_ranges);

```
]

这个 kernel 的语义接近“byte-wise batch memset”，但它和 `cudaMemsetAsync` 的底层实现不是一回事：它会占用 SM，性能取决于 range 大小分布、对齐、coalescing、写入粒度和调度开销。真实实现通常会让对齐的大段使用 32-bit、64-bit 或 vectorized store，尾部再按 byte 处理；若要把 FP32 数组设为 1.0 或把结构体设为某个模式，也应写 typed fill kernel，而不是依赖 `cudaMemset` 的 byte value 语义。

`cudaMemcpyBatchAsync` 这类真正的 batch API 也不能理解为“自动保持列表顺序”。官方文档说明 batch 整体在 stream 中有顺序，但 batch 内部各 copy 没有固定执行顺序；如果某个 copy 依赖同一 batch 内另一个 copy 的结果，语义就是错误的。这个原则同样适合设计自定义 batch memset kernel：同一批操作之间最好互不重叠、互不依赖，否则应拆成多个 stream 阶段或显式建立依赖。#refmark(29)

Unified Memory 用 `cudaMallocManaged` 提供一个 host 和 device 都可访问的统一地址空间。它能降低编程复杂度，但页面迁移、prefetch、访问位置和 oversubscription 会影响性能。基础阶段可以把它理解为“简化地址管理的机制”，而不是自动消除数据移动成本的机制。#refmark(16)

例如：

#blog.code(lang: "cuda")[
```cuda
float* x = nullptr;
cudaMallocManaged(&x, n * sizeof(float));

initialize_on_host(x, n);

cudaMemLocation location{};
location.type = cudaMemLocationTypeDevice;
location.id = device_id;
cudaMemPrefetchAsync(x, n * sizeof(float), location, 0);

kernel<<<grid, block>>>(x, n);

```
]

`cudaMemPrefetchAsync` 的目的不是改变语义，而是提前把页面迁移到更可能访问它的处理器附近，减少 kernel 首次访问时的 page migration 开销。旧版 CUDA Toolkit 中也常见直接传 `device_id` 的签名；写示例代码时应以正在使用的 Toolkit 文档和头文件为准。#refmark(29)

== global memory coalescing

访存通常先按 warp 来看。理想情况是相邻 threads 访问相邻元素：

$ upright("addr")_i = upright("base") + i times upright("sizeof(T)") $

在 compute capability 6.0 及之后，warp 的 global memory 访问会合并成满足这些地址所需的 32-byte transactions。若 32 个 threads 读取连续的 4-byte 元素，通常需要 4 次 32-byte transactions；未对齐或 stride 访问会多读无用 segment。#refmark(7)

下面两个访问模式的差异在于相邻 lanes 是否访问相邻地址：

#blog.code(lang: "cuda")[
```cuda
// Coalesced: lane i reads x[base + i].
float a = x[base + threadIdx.x];

// Strided: lane i reads x[base + i * stride].
float b = x[base + threadIdx.x * stride];

```
]

若 `stride = 32`，一个 warp 的 32 个 lanes 会访问相隔很远的 32 个元素，内存系统通常需要更多 transactions，实际带宽会下降。

effective bandwidth 可以粗略写成：

$ B_"effective" = ("bytes read" + "bytes written") / T_"kernel" $

若理论 HBM 带宽很高，但 effective bandwidth 远低于预期，常见原因包括非合并访问、重复读写、cache 命中率低、低 occupancy 不能隐藏延迟，或 kernel 实际瓶颈不是带宽而是指令、同步或依赖。#refmark(22)

== shared memory bank conflict

shared memory 的瓶颈常见于 bank conflict。compute capability 5.x 及之后，shared memory 有 32 个 banks，连续 32-bit words 会映射到连续 banks；如果同一次 warp 请求里的多个地址落到同一个 bank，就会被拆成多次请求。多个 threads 读同一个地址属于 broadcast 例外。#refmark(9)

按 32-bit word 近似理解时，bank 映射可以写成：

$ upright("bank") = floor(upright("addr") / 4) mod 32 $

解决 bank conflict 的核心是让同一个 warp 的地址分散到不同 banks，而不是让逻辑上连续的访问固定映射到同一 bank。

#figure(
  table(
    columns: 2,
    inset: 8pt,
    [方法], [适用场景],
    [padding], [二维 shared memory tile 的列访问容易产生固定 stride。把 leading dimension 从 `TILE_DIM` 改为 `TILE_DIM + 1`，可把 stride 从 32 变成 33，从而打散 bank 映射。#refmark(9)],
    [swizzle], [不增加或少增加 shared memory 容量，而是改变逻辑坐标到物理 offset 的映射；常见实现会对 offset 的若干 bit 做 xor，使不同 lane 的访问落到更分散的 banks。CUTLASS / CuTe 用 layout 及其代数操作描述这类坐标到 offset 的映射。#refmark(10)#refmark(11)],
  ),
  caption: [bank conflict 的两类处理方式。]
)

二维 tile transpose 是 padding 的经典例子：

#blog.code(lang: "cuda")[
```cuda
constexpr int TILE_DIM = 32;

__shared__ float tile[TILE_DIM][TILE_DIM + 1];

int x = blockIdx.x * TILE_DIM + threadIdx.x;
int y = blockIdx.y * TILE_DIM + threadIdx.y;

tile[threadIdx.y][threadIdx.x] = input[y * width + x];
__syncthreads();

output[x * height + y] = tile[threadIdx.x][threadIdx.y];

```
]

这个片段假设矩阵尺寸是 `TILE_DIM` 的整数倍，并省略了边界判断。若第二维是 `TILE_DIM`，列方向访问容易让一个 warp 的多个 lanes 落到同一 bank；改成 `TILE_DIM + 1` 会改变 stride，从而打散 bank 映射。实际高性能 transpose 还会调整读写 tile 的 block 坐标，使 global memory 的读写都尽量 coalesced。

= 同步、stream 与异步执行

== block 内同步与可见性

`__syncthreads()` 是 block 内同步原语：同一个 block 中的 threads 都到达同步点后才能继续执行。它常用于 shared memory tile 的生产者和消费者之间，例如先把数据从 global memory 搬到 shared memory，再等待整个 tile 完成后做计算。#refmark(20)

#blog.code(lang: "cuda")[
```cuda
extern __shared__ float tile[];

tile[threadIdx.x] = input[global_i];
__syncthreads();

float x = tile[(threadIdx.x + 1) % blockDim.x];

```
]

更直观的例子是 block-local prefix sum。下面的 kernel 用两个 shared memory buffer 做 ping-pong：每一轮所有 threads 都从旧 buffer 读，写到新 buffer；等所有写入完成后，再交换读写角色。

#blog.code(lang: "cuda")[
```cuda
// Inclusive scan for one full block of BLOCK_SIZE elements.
// The block has BLOCK_SIZE threads; tails are omitted for clarity.
template <int BLOCK_SIZE>
__global__ void prefix_sum_pingpong(const float* input, float* output) {
  __shared__ float buf[2][BLOCK_SIZE];

  int tid = threadIdx.x;
  int base = blockIdx.x * BLOCK_SIZE;

  int src = 0;
  int dst = 1;
  buf[src][tid] = input[base + tid];
  __syncthreads();

  for (int offset = 1; offset < BLOCK_SIZE; offset <<= 1) {
    float v = buf[src][tid];
    if (tid >= offset) {
      v += buf[src][tid - offset];
    }

    buf[dst][tid] = v;
    __syncthreads();

    src ^= 1;
    dst ^= 1;
  }

  output[base + tid] = buf[src][tid];
}

```
]

若输入是 $x_0, x_1, ..., x_7$，第一轮 `offset = 1` 后，每个位置最多加上左边 1 个元素；第二轮 `offset = 2` 后，每个位置最多覆盖左边 3 个元素；第三轮 `offset = 4` 后得到 8 元素片段的 inclusive prefix sum。ping-pong buffer 的作用是让同一轮的读集合和写集合分开，避免 thread $i$ 读到 thread $i - upright("offset")$ 在本轮刚写出的新值。循环中的 `__syncthreads()` 仍然不能省略：它保证下一轮开始前，新 buffer 中所有位置都已经写完。该实现只计算每个 block 内部的前缀和；若要得到全数组 prefix sum，还需要额外 kernel 扫描各 block 的 block sum，再把 block offset 加回每个片段。

双调排序（bitonic sort）的 block-local 版本更能体现 `__syncthreads()` 的作用。下面的 kernel 假设每个 block 恰好处理 `BLOCK_SIZE` 个元素，并且 `BLOCK_SIZE` 是 2 的幂；所有元素先被协作加载到 shared memory，随后每一轮 compare-and-swap 都依赖上一轮已经稳定的 shared memory 状态。

#blog.code(lang: "cuda")[
```cuda
// Sort one block of BLOCK_SIZE elements in shared memory.
// BLOCK_SIZE must be a power of two, and the block has BLOCK_SIZE threads.
template <int BLOCK_SIZE>
__global__ void bitonic_sort_block(float* data) {
  __shared__ float tile[BLOCK_SIZE];

  int tid = threadIdx.x;
  int base = blockIdx.x * BLOCK_SIZE;

  tile[tid] = data[base + tid];
  __syncthreads();

  for (int k = 2; k <= BLOCK_SIZE; k <<= 1) {
    for (int j = k >> 1; j > 0; j >>= 1) {
      int ixj = tid ^ j;

      if (ixj > tid) {
        bool ascending = (tid & k) == 0;
        float a = tile[tid];
        float b = tile[ixj];

        if ((ascending && a > b) || (!ascending && a < b)) {
          tile[tid] = b;
          tile[ixj] = a;
        }
      }

      __syncthreads();
    }
  }

  data[base + tid] = tile[tid];
}

```
]

第一次 `__syncthreads()` 保证整个 tile 已经完成加载，避免后续线程读取尚未写入的 shared memory。内层循环末尾的 `__syncthreads()` 则把 compare-and-swap 划分成离散阶段：在进入下一组比较前，同一个 block 内所有线程都已经完成当前阶段的读写。需要注意的是，barrier 位于分支外，因为 `__syncthreads()` 必须被同一个 block 中所有未退出的 threads 共同到达；若只让参与交换的 threads 进入 barrier，就可能造成挂起或未定义行为。该实现只能独立排序每个 block 的片段；若要得到跨 blocks 的全局有序结果，还需要额外的 merge kernel，或改用面向全局排序的算法。实际工程实现还需要处理尾部长度、每个线程多个元素、shared memory bank conflict 以及 global memory 访存形态。

`__syncthreads()` 只同步同一个 block 内的 threads，不能同步整个 grid。普通 CUDA kernel 内没有跨所有 blocks 的全局 barrier；如果需要全局阶段边界，常见做法是拆成多个按顺序依赖的 kernels，例如放在同一 stream 中，或用 event 建立跨 stream 依赖。在这种执行顺序下，后一个 kernel 开始时可以看到前一个 kernel 已经写入 global memory 的结果。若不同 kernels 被提交到彼此无依赖的 streams，则不能把它们当作全局阶段边界。

== 跨 block 扩展：多 SM 与全局阶段

block-local 例子容易造成一个误解：似乎 prefix sum 或 bitonic sort 只能在一个 block 内完成。实际并非如此。若希望调用更多 SM，同一个 kernel 可以启动大量 blocks；CUDA 调度器会把这些 blocks 分配到不同 SM 上执行。限制不在于能否并行使用多个 SM，而在于普通 kernel 内不同 blocks 之间不能用 `__syncthreads()` 形成全局阶段边界。

因此，多 block 版本通常把算法拆成“block 内局部计算”和“跨 block 汇总”两个层次。以 prefix sum 为例，第一步让每个 block 对自己的片段做 scan，并把片段总和写入 `block_sums`；第二步扫描 `block_sums` 得到每个 block 的 offset；第三步把 offset 加回对应片段：

#blog.code(lang: "cuda")[
```cuda
// Stage 1: many blocks scan independent tiles and write tile sums.
scan_blocks<<<num_blocks, threads_per_block>>>(
    input, partial_output, block_sums, n);

// Stage 2: scan the array of per-block sums.
scan_block_sums<<<grid_sums, threads_per_block>>>(
    block_sums, block_offsets, num_blocks);

// Stage 3: add each block's prefix offset back to its tile.
add_block_offsets<<<num_blocks, threads_per_block>>>(
    partial_output, block_offsets, output, n);

```
]

这三个 kernels 可以各自启动许多 blocks，从而利用多个 SM。它们之间的依赖由 kernel 边界提供：在同一 stream 中顺序提交时，第二个 kernel 不会早于第一个 kernel 完成前开始，第三个 kernel 也不会早于第二个 kernel 完成前开始。这里的全局同步不是某个 device 端函数调用，而是 host 提交的 kernel 序列语义。

双调排序的全局版本也遵循同一原则。block 内阶段可以在 shared memory 中完成；一旦 compare-and-swap 的配对跨过 block 边界，就需要把数据放在 global memory 中，并把每一轮依赖拆成可顺序提交的 kernel 阶段。这个方法是可行的，但 kernel 数量、global memory 流量和同步边界都会增加。工程上若目标是大数组排序，通常会优先使用 CUB / Thrust 中的排序或 scan 原语，或采用更适合全局内存层级的 radix sort / merge sort，而不是直接把教学版 block-local bitonic sort 机械扩展到全数组。

CUDA 也提供更明确的跨 block 协作机制，例如 thread block cluster 及其 cluster 级同步，或 cooperative launch 下的 grid 级协作；但这些机制有架构、launch 方式和同时驻留资源等约束。基础写法中，更稳健的判断是：多 SM 并行依靠更多 blocks，跨 block 阶段同步依靠 kernel 边界或专门协作机制。#refmark(1)#refmark(2)#refmark(20)

warp 内可以使用 warp-level primitives 和 `__syncwarp()` 表达更细粒度协作。使用 warp-level 操作时，需要注意 active mask 和分支路径，否则部分 lanes 不参与会导致语义错误。#refmark(20)

例如处理数组尾部时，若当前 warp 是完整 active warp，一个安全的教学写法是让整个 warp 都执行 shuffle；没有有效元素的 lanes 使用 0 作为输入：

#blog.code(lang: "cuda")[
```cuda
// Assumes all 32 lanes in this warp are active.
unsigned full_mask = 0xffffffffu;
float v = (i < n) ? x[i] : 0.0f;

for (int offset = 16; offset > 0; offset /= 2) {
  v += __shfl_down_sync(full_mask, v, offset);
}

```
]

这里的前提是所有 32 个 lanes 都执行同一段 shuffle 代码，只是无效 lanes 的贡献为 0；执行完循环后，完整 warp 的总和只在 lane 0 的 `v` 中。实践中通常还会让 block size 是 32 的倍数，避免最后一个 warp 本身不完整。若把 warp-level primitive 放进分支内部，则不能随意使用 `0xffffffffu`；mask 应由同一分支条件通过 `__ballot_sync` 得到，并且 mask 中列出的 lanes 必须共同执行相同的 intrinsic。还需要注意，shuffle reduction 并不会自动把稀疏 lanes 压缩成连续分组；若参与 lanes 分散在 warp 内，需要使用更明确的压缩、分组规约或 CUB / cooperative groups 这类封装。

== atomic 与 memory fence

atomic operation 用于对某个地址执行不可分割的读改写，例如 `atomicAdd`、`atomicCAS`。它能避免多个 threads 同时更新同一地址时丢失更新，但不能自动把算法变快。高冲突 atomic 会串行化，常见优化是先在 warp 或 block 内归约，再用更少的 atomic 更新 global memory。#refmark(21)

例如统计总和时，最直接但冲突最高的写法是每个 thread 都更新同一个地址：

#blog.code(lang: "cuda")[
```cuda
atomicAdd(total, x[i]);

```
]

更常见的结构是先在 block 内做 shared memory reduction，再让每个 block 执行一次 global atomic：

#blog.code(lang: "cuda")[
```cuda
__shared__ float partial[256];
partial[threadIdx.x] = x[i];
__syncthreads();

for (int stride = blockDim.x / 2; stride > 0; stride /= 2) {
  if (threadIdx.x < stride) {
    partial[threadIdx.x] += partial[threadIdx.x + stride];
  }
  __syncthreads();
}

if (threadIdx.x == 0) {
  atomicAdd(total, partial[0]);
}

```
]

这个例子假设 `blockDim.x = 256` 且每个 thread 都对应有效元素；真实代码需要处理尾部和任意 block size。它牺牲了一部分 shared memory 和同步开销，但把 global atomic 次数从“每个元素一次”降到“每个 block 一次”。

memory fence 约束当前 thread 的内存操作可见顺序，例如 `__threadfence_block()`、`__threadfence()` 和 `__threadfence_system()`。fence 不等于 barrier：它约束顺序和可见性，但不会等待其他 threads 到达同一点。工程上需要区分：

- barrier：哪些执行流必须等在同一个阶段。
- fence：当前执行流前后的内存操作在什么范围内建立可见顺序。
- atomic：某个读改写操作是否不可分割。

这三个概念经常一起出现，但不能互相替代。

== streams 与 events

CUDA stream 是一条按顺序执行的 command queue。同一 stream 内的操作按提交顺序执行；不同 streams 中的操作可以并发或重叠，前提是硬件资源、依赖关系、memory copy engine 和 host memory 条件允许。默认 stream 的同步语义还取决于使用 legacy default stream 还是 per-thread default stream；需要明确并发时，显式创建 non-default streams 更不容易误判依赖。#refmark(18)

典型的 copy/compute overlap 结构是：

#blog.code(lang: "cuda")[
```cuda
cudaMemcpyAsync(d_a0, h_a0, bytes, cudaMemcpyHostToDevice, stream0);
kernel<<<grid, block, 0, stream0>>>(d_a0, d_c0);
cudaMemcpyAsync(h_c0, d_c0, bytes, cudaMemcpyDeviceToHost, stream0);

cudaMemcpyAsync(d_a1, h_a1, bytes, cudaMemcpyHostToDevice, stream1);
kernel<<<grid, block, 0, stream1>>>(d_a1, d_c1);
cudaMemcpyAsync(h_c1, d_c1, bytes, cudaMemcpyDeviceToHost, stream1);

```
]

这里的目标是让第一个 batch 的 kernel 执行和第二个 batch 的 H2D copy 尽量重叠。实际是否重叠，需要满足 pinned host memory、异步 API、不同 streams、硬件支持并发 copy/compute 等条件，并用 profiler 验证。

event 可以记录某个 stream 中的时间点，用于 stream 依赖和 timing。`cudaEventRecord` 把 event 插入 stream，`cudaEventSynchronize` 等待 event 完成，`cudaEventElapsedTime` 可测两个 events 之间的 elapsed time。event timing 比 CPU wall-clock 更接近 device 时间线，但仍应配合 warmup、重复运行和 profiler 使用。#refmark(19)

一个最小的 event timing 例子是：

#blog.code(lang: "cuda")[
```cuda
cudaEvent_t start, stop;
cudaEventCreate(&start);
cudaEventCreate(&stop);

cudaEventRecord(start, stream);
kernel<<<grid, block, 0, stream>>>(args);
cudaEventRecord(stop, stream);

cudaEventSynchronize(stop);
float ms = 0.0f;
cudaEventElapsedTime(&ms, start, stop);

```
]

这段代码测的是同一 stream 中 `start` 和 `stop` 之间的 device 时间，不包括未放入该 stream 的 host 侧工作。

= 性能测量与调试

== 计时与指标

优化 CUDA kernel 时，应先确认测量对象。常见层次包括：

- end-to-end latency：包含 host 调度、数据传输、kernel、同步和后处理。
- kernel time：只看 device 上某个 kernel 的执行时间。
- effective bandwidth：按实际读写字节数除以 kernel time。
- achieved occupancy：实际驻留和执行的 warps 情况。
- arithmetic throughput：FLOPs/s 或 Tensor Core utilization。

如果目标是优化一个 kernel，通常先用 events 或 profiler 测 kernel time；如果目标是优化服务或训练 step，则应看 end-to-end timeline。只看单个 kernel 的时间可能会忽略 host-device transfer、stream 同步、allocator、通信和框架调度开销。#refmark(22)

CUPTI 是 CUDA Profiling Tools Interface，所处层次比普通应用中的 event timing 更底层：它面向 profiler、tracer、框架 runtime 和自定义观测工具。CUPTI Activity API 可以收集 CUDA API、kernel、memory copy、synchronization 等 CPU/GPU 活动记录，用于还原时间线；Callback API 可在 CUDA Runtime / Driver API 调用入口和出口处插桩；Profiler、Range Profiling、PM Sampling 等接口则面向硬件指标和采样。Nsight Systems、Nsight Compute 这类工具可以看作更高层的产品化 profiler；直接使用 CUPTI 的场景通常是需要把 CUDA timeline 或 metrics 集成进自己的 runtime、服务监控或实验框架中。需要注意的是，CUPTI 插桩和 activity buffer 管理也会引入开销，因此它更适合系统级观测和 profiler 实现，不应把采集开销忽略为普通 kernel 执行时间的一部分。#refmark(26)

例如一个 vector add kernel 读取两个 FP32 数组并写一个 FP32 数组，元素数为 $n$，kernel 时间为 $T$，则读写字节数约为：

$ "bytes" = n times (4 + 4 + 4) $

若 $n = 100000000$ 且 $T = 1.5 " ms"$，则：

$ B_"effective" = (100000000 times 12) / (1.5 times 10^(-3)) approx 800 " GB/s" $

这个数字应和目标 GPU 的理论 HBM 带宽、profiler 中的 memory throughput 以及实际访问模式一起解释。

== 错误检查与调试工具

CUDA 错误有同步和异步两类。`cudaMalloc`、`cudaMemcpy` 这类 runtime API 的返回值可以立即检查；kernel 内部的非法访问、assert 或其他 device-side 错误通常要到后续同步点才暴露。调试阶段建议在关键 kernel 后使用：

#blog.code(lang: "cuda")[
```cuda
kernel<<<grid, block>>>(args);
cudaError_t launch_error = cudaGetLastError();
cudaError_t sync_error = cudaDeviceSynchronize();

```
]

这能把错误定位到更近的位置。性能路径中再移除不必要的全局同步。

实际工程里常用宏或小函数统一检查返回值：

#blog.code(lang: "cuda")[
```cuda
#define CUDA_CHECK(call)                                      \
  do {                                                        \
    cudaError_t err = (call);                                 \
    if (err != cudaSuccess) {                                 \
      fprintf(stderr, "CUDA error %s:%d: %s\n",               \
              __FILE__, __LINE__, cudaGetErrorString(err));   \
      abort();                                                \
    }                                                         \
  } while (0)

CUDA_CHECK(cudaMalloc(&d_a, bytes));
kernel<<<grid, block>>>(args);
CUDA_CHECK(cudaGetLastError());
CUDA_CHECK(cudaDeviceSynchronize());

```
]

Compute Sanitizer 可用于检查 memory access、race、initcheck、synccheck 等问题；CUPTI 是构建 profiler / tracer 的底层接口；Nsight Systems 更适合看 CPU/GPU 时间线、stream overlap 和系统级瓶颈；Nsight Compute 更适合分析单个 kernel 的 occupancy、memory throughput、warp stall、instruction mix 和 Tensor Core 利用率。#refmark(23)#refmark(24)#refmark(25)#refmark(26)

= CUDA / 硬件特性用法

这一类内容不是 GPU 执行模型本身，而是写 CUDA kernel 时可主动使用的能力。它们通常需要代码显式选择对应的数据类型、指令路径或 API。

== vectorized load / store

128-bit load / store 指每条访存指令搬 128 bit，也就是 16 bytes。常见做法是让每个 thread 一次读写一个 vector type，例如 `int4` / `float4`，编译器可生成 `LDG.E.128` / `STG.E.128`。这主要减少访存指令数；前提是数据布局连续，指针和偏移满足对齐要求。#refmark(8)

vectorized load / store 不是自动提升 bandwidth 的开关。如果访问本身没有 coalescing、地址不对齐、或额外 unpack 导致指令增加，收益可能消失。应结合 SASS、memory transactions 和 profiler 结果判断。

典型写法是让每个 thread 处理一个 16-byte 向量：

#blog.code(lang: "cuda")[
```cuda
const float4* x4 = reinterpret_cast<const float4*>(x);
float4 v = x4[i];

float sum = v.x + v.y + v.z + v.w;

```
]

这要求 `x` 的地址、偏移和元素数量满足对齐与整除条件；尾部不能整除的元素通常需要单独处理。若从标量指针强转到 vector pointer，还要确认项目的类型别名规则、allocator 对齐和编译器假设都允许这种访问；否则应让数据本身以 vector type 布局，或使用更保守的加载封装。

== BF16x2 packed arithmetic

BF16x2 是 CUDA 编程中的打包数据类型：两个 BF16 lane 被放在一个 32-bit 值里。CUDA 里的 `__nv_bfloat162` 可配合 `__hadd2`、`__hmul2`、`__hfma2`，对两个 BF16 lane 同时做加、乘、fma。它适合 bias、activation、residual 这类逐元素操作；大矩阵乘的主路径仍然应优先使用 Tensor Core。#refmark(12)

例如一个逐元素 fused multiply-add 可以写成：

#blog.code(lang: "cuda")[
```cuda
int j = 2 * pair_idx;
__nv_bfloat162 a2 = *reinterpret_cast<const __nv_bfloat162*>(&a[j]);
__nv_bfloat162 b2 = *reinterpret_cast<const __nv_bfloat162*>(&b[j]);
__nv_bfloat162 c2 = *reinterpret_cast<const __nv_bfloat162*>(&c[j]);

__nv_bfloat162 y2 = __hfma2(a2, b2, c2);
*reinterpret_cast<__nv_bfloat162*>(&y[j]) = y2;

```
]

这里 `pair_idx` 表示 BF16 pair 的编号，`j` 是底层 BF16 数组中的偶数元素偏移；相邻 threads 不应读取彼此重叠的 pair。实际代码仍要保证地址对齐、元素个数为偶数或单独处理尾部，并让类型别名处理符合代码规范。

== Tensor Core

CUDA Core 可视为通用计算单元。Tensor Core 是专门加速矩阵计算的硬件。#refmark(13) Transformer 里大量计算都是矩阵乘，因此 Tensor Core 利用率是训练和推理性能的关键因素。

低精度数据类型也是围绕这个目标来的：更少的 bit 可以降低显存占用和带宽压力，但也会降低数值精度或动态范围。具体数值格式整理见另一篇低精度笔记。

从代码路径看，Tensor Core 通常不是通过普通标量循环自动高效触发，而是通过 cuBLAS / cuDNN、CUTLASS、WMMA 或框架生成的 MMA kernel 使用。一个简化判断是：若工作负载可以表达为足够大的矩阵乘或卷积，并且数据类型、layout、对齐和维度满足硬件要求，就更可能走到 Tensor Core 路径；若只是少量标量运算或不规则索引，主要瓶颈通常不在 Tensor Core。

== compute capability 与 feature gate

compute capability 描述 GPU 架构暴露给 CUDA 的能力边界。thread block cluster、distributed shared memory、WGMMA、TMA、特定 Tensor Core 数据类型、最大 shared memory 容量等，都可能依赖具体 compute capability。#refmark(3)

因此，写 CUDA kernel 时需要区分三件事：

- CUDA toolkit 支持：编译器和 runtime 是否认识某个 API 或指令路径。
- GPU 架构支持：目标设备的 compute capability 是否支持该特性。
- kernel 实际路径：编译选项、数据类型、shape 和 alignment 是否让代码走到期望的指令。

基础篇只需要知道 feature gate 的存在。TMA、WGMMA、CUDA Graphs、cooperative groups、dynamic parallelism、virtual memory management、NCCL collectives、GPUDirect RDMA 以及 DeepEP / MoE dispatch 这类系统主题，都更适合放在进阶文章中展开。

实际代码中通常同时做编译期和运行期检查：

#blog.code(lang: "cuda")[
```cuda
#if __CUDA_ARCH__ >= 900
// Device code path for Hopper-class features.
#endif

cudaDeviceProp prop;
cudaGetDeviceProperties(&prop, device_id);
if (prop.major >= 9) {
  // Host side selects a kernel variant for newer architecture.
}

```
]

`__CUDA_ARCH__` 只在 device code 编译时有意义；host 侧选择设备能力仍需要查询 `cudaDeviceProp` 或由框架调度系统维护能力表。

= 参考资料

这里的上标对应下面的编号。

- #metadata(none) <ref-1> [1] #link("https://docs.nvidia.com/cuda/cuda-c-programming-guide/index.html#thread-hierarchy")[CUDA C++ Programming Guide: Thread Hierarchy]
- #metadata(none) <ref-2> [2] #link("https://developer.nvidia.com/blog/nvidia-hopper-architecture-in-depth/")[NVIDIA Hopper Architecture In-Depth]
- #metadata(none) <ref-3> [3] #link("https://docs.nvidia.com/cuda/cuda-programming-guide/05-appendices/compute-capabilities.html")[CUDA Programming Guide: Compute Capabilities]
- #metadata(none) <ref-4> [4] #link("https://docs.nvidia.com/cuda/cuda-c-best-practices-guide/index.html#occupancy")[CUDA C++ Best Practices Guide: Occupancy]
- #metadata(none) <ref-5> [5] #link("https://docs.nvidia.com/cuda/parallel-thread-execution/index.html#asynchronous-warpgroup-level-matrix-instructions")[Parallel Thread Execution ISA: Warpgroup Matrix Instructions]
- #metadata(none) <ref-6> [6] #link("https://www.nvidia.com/en-us/data-center/nvlink/")[NVIDIA NVLink and NVLink Switch]
- #metadata(none) <ref-7> [7] #link("https://docs.nvidia.com/cuda/cuda-c-best-practices-guide/index.html#coalesced-access-to-global-memory")[CUDA C++ Best Practices Guide: Coalesced Access to Global Memory]
- #metadata(none) <ref-8> [8] #link("https://developer.nvidia.com/blog/cuda-pro-tip-increase-performance-with-vectorized-memory-access/")[NVIDIA: Vectorized Memory Access]
- #metadata(none) <ref-9> [9] #link("https://docs.nvidia.com/cuda/cuda-c-best-practices-guide/index.html#shared-memory-and-memory-banks")[CUDA C++ Best Practices Guide: Shared Memory and Memory Banks]
- #metadata(none) <ref-10> [10] #link("https://docs.nvidia.com/cutlass/media/docs/cpp/cute/0x_gemm_tutorial.html")[CUTLASS CuTe dense matrix-matrix multiply tutorial]
- #metadata(none) <ref-11> [11] #link("https://docs.nvidia.com/cutlass/media/docs/cpp/cute/02_layout_algebra.html")[CUTLASS CuTe Layout Algebra]
- #metadata(none) <ref-12> [12] #link("https://docs.nvidia.com/cuda/cuda-math-api/cuda_math_api/group__CUDA__MATH____BFLOAT162__ARITHMETIC.html")[CUDA Math API: Bfloat162 Arithmetic Functions]
- #metadata(none) <ref-13> [13] #link("https://www.nvidia.com/en-us/data-center/tensor-cores/")[NVIDIA Tensor Cores]
- #metadata(none) <ref-14> [14] #link("https://docs.nvidia.com/cuda/cuda-c-programming-guide/index.html#programming-model")[CUDA C++ Programming Guide: Programming Model]
- #metadata(none) <ref-15> [15] #link("https://docs.nvidia.com/cuda/cuda-c-programming-guide/index.html#kernels")[CUDA C++ Programming Guide: Kernels]
- #metadata(none) <ref-16> [16] #link("https://docs.nvidia.com/cuda/cuda-c-programming-guide/index.html#memory-hierarchy")[CUDA C++ Programming Guide: Memory Hierarchy]
- #metadata(none) <ref-17> [17] #link("https://docs.nvidia.com/cuda/cuda-c-best-practices-guide/index.html#data-transfer-between-host-and-device")[CUDA C++ Best Practices Guide: Data Transfer Between Host and Device]
- #metadata(none) <ref-18> [18] #link("https://docs.nvidia.com/cuda/cuda-c-programming-guide/index.html#streams")[CUDA C++ Programming Guide: Streams]
- #metadata(none) <ref-19> [19] #link("https://docs.nvidia.com/cuda/cuda-runtime-api/group__CUDART__EVENT.html")[CUDA Runtime API: Event Management]
- #metadata(none) <ref-20> [20] #link("https://docs.nvidia.com/cuda/cuda-c-programming-guide/index.html#synchronization-functions")[CUDA C++ Programming Guide: Synchronization Functions]
- #metadata(none) <ref-21> [21] #link("https://docs.nvidia.com/cuda/cuda-c-programming-guide/index.html#atomic-functions")[CUDA C++ Programming Guide: Atomic Functions]
- #metadata(none) <ref-22> [22] #link("https://docs.nvidia.com/cuda/cuda-c-best-practices-guide/index.html#performance-metrics")[CUDA C++ Best Practices Guide: Performance Metrics]
- #metadata(none) <ref-23> [23] #link("https://docs.nvidia.com/compute-sanitizer/ComputeSanitizer/index.html")[NVIDIA Compute Sanitizer]
- #metadata(none) <ref-24> [24] #link("https://docs.nvidia.com/nsight-systems/UserGuide/index.html")[NVIDIA Nsight Systems User Guide]
- #metadata(none) <ref-25> [25] #link("https://docs.nvidia.com/nsight-compute/NsightCompute/index.html")[NVIDIA Nsight Compute User Guide]
- #metadata(none) <ref-26> [26] #link("https://docs.nvidia.com/cupti/main/main.html")[NVIDIA CUPTI Documentation]
- #metadata(none) <ref-27> [27] #link("https://docs.nvidia.com/cuda/cuda-c-programming-guide/index.html#cuda-graphs")[CUDA C++ Programming Guide: CUDA Graphs]
- #metadata(none) <ref-28> [28] #link("https://docs.nvidia.com/cuda/cuda-c-best-practices-guide/index.html#local-memory")[CUDA C++ Best Practices Guide: Local Memory]
- #metadata(none) <ref-29> [29] #link("https://docs.nvidia.com/cuda/cuda-runtime-api/group__CUDART__MEMORY.html")[CUDA Runtime API: Memory Management]
- #metadata(none) <ref-30> [30] #link("https://docs.nvidia.com/cuda/cuda-runtime-api/api-sync-behavior.html")[CUDA Runtime API: API Synchronization Behavior]
- #metadata(none) <ref-31> [31] #link("https://docs.nvidia.com/cuda/cuda-runtime-api/group__CUDART__GRAPH.html")[CUDA Runtime API: Graph Management]
- #metadata(none) <ref-32> [32] #link("https://www.nvidia.com/en-us/data-center/hgx/")[NVIDIA HGX Platform]
- #metadata(none) <ref-33> [33] #link("https://www.nvidia.com/en-us/data-center/h200/")[NVIDIA H200 Tensor Core GPU]
- #metadata(none) <ref-34> [34] #link("https://www.nvidia.com/en-us/data-center/gb300-nvl72/")[NVIDIA GB300 NVL72]
- #metadata(none) <ref-35> [35] #link("https://www.nvidia.com/en-us/data-center/h100/")[NVIDIA H100 Tensor Core GPU]
- #metadata(none) <ref-36> [36] #link("https://www.nvidia.com/en-us/data-center/a100/")[NVIDIA A100 Tensor Core GPU]
- #metadata(none) <ref-37> [37] #link("https://docs.nvidia.com/cuda/cuda-runtime-api/group__CUDART__DEVICE.html")[CUDA Runtime API: Device Management]
- #metadata(none) <ref-38> [38] #link("https://docs.nvidia.com/datacenter/tesla/mig-user-guide/")[NVIDIA Multi-Instance GPU User Guide]
