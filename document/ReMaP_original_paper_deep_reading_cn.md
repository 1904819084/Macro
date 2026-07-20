# ReMaP 原论文深度解读：递归原型布局与外围引导重定位的宏布局方法

本文档用于帮助理解原论文：

```text
ReMaP: Macro Placement by Recursively Prototyping and Periphery-Guided Relocating
Yunqi Shi, Xi Lin, Siyuan Xu, Shixiong Kai, Ke Xue, Mingxuan Yuan, Chao Qian, Zhi-Hua Zhou
DAC 2025
```

对应 PDF：

```text
/Users/bytedance/Desktop/me/ReMaP_Macro_Placement_by_Recursively_Prototyping_and_Periphery-Guided_Relocating.pdf
```

这篇论文的核心不是提出一个更复杂的全局布局器，而是把“有经验的人类 floorplanner 怎么摆宏”的经验拆成几个可自动执行的步骤：

```text
1. 先用 mixed-size global placement 得到一个原型布局。
2. 从原型布局中观察宏和标准单元簇的大致相对关系。
3. 把宏先推到一个椭圆上做角度优化，让它们形成较好的外围分布。
4. 再根据外围代价和 dataflow 代价，把宏逐步放到芯片边缘附近的真实合法位置。
5. 每次只固定一部分宏，剩下的宏和标准单元重新做 mixed-size placement。
6. 不断递归，直到所有宏都固定。
```

如果只用一句话概括原论文：

> ReMaP 把宏布局问题拆成“混合尺寸原型布局 + 椭圆角度优化 + 外围引导重定位 + 递归固定宏”四件事，目标是自动模仿专家把宏规则地放到芯片外围，同时保留 dataflow 质量，从而提升后端 WNS/TNS。

## 1. 论文想解决的问题

### 1.1 为什么宏布局很难

宏布局，也就是 macro placement，指的是在芯片核心区域中摆放 SRAM、cache、register file、IP block 等大尺寸 hard macro。它比普通标准单元布局更难，原因有几个：

1. 宏单元面积大，一旦位置不好，会直接阻挡大片标准单元布局区域。
2. 宏单元通常不可随意 reshape，只能平移或旋转，几何自由度少。
3. 宏单元周围有 pin access、routing channel、power grid 等复杂约束。
4. 宏布局通常在后端流程较早阶段决定，但会影响 placement、CTS、routing 和最终 timing。
5. WNS/TNS 等 PPA 指标需要完整后端 flow 才能准确评估，无法直接作为简单可微目标优化。

论文 Introduction 中强调：不好的 macro placement 会阻塞芯片核心区域，造成拥挤和绕线，让 timing path 变长，也让标准单元难以摆放。随着芯片规模增加、宏数量增加，这个问题更严重。

### 1.2 人类专家通常怎么摆宏

论文特别强调 expert-quality placement。传统上，宏布局常常依赖人类专家。专家会综合考虑：

```text
1. dataflow：有强通信关系的模块尽量靠近。
2. periphery placement：把宏放到芯片外围，释放中间区域给标准单元。
3. regularity：同类、同尺寸宏尽量成组或阵列摆放，减少 notch/dead area。
4. pin access：宏不要堵住 I/O pin 区域，避免 pin access/routing 问题。
5. back-end feedback：根据 OpenROAD 或商业工具的后端结果反复调整。
```

这类人工过程可能需要几周甚至几个月。ReMaP 的目标就是把这些专家行为转成自动算法，减少 turnaround time。

### 1.3 论文特别区分 periphery 和 regularity

论文里有一个很重要的概念区分：

```text
periphery placement != regularity
```

外围放置的目标是：

```text
把宏放到芯片边缘附近，释放芯片中心给标准单元，减少拥塞和绕线。
```

规则性 regularity 的目标是：

```text
同类型、同大小宏尽量排成规则结构，减少 notch、dead area，有利于电源规划和布线。
```

这两个目标有关，但不是一回事。一个布局可以很靠外围但不规则，也可以很规则但没有保留好中心区域。ReMaP 试图同时兼顾二者，但它的主线更偏向“外围引导 + dataflow 保真”。

## 2. 摘要逐句解读

论文摘要主要传达四个信息。

### 2.1 ReMaP 是一个 framework

论文说它提出的是 ReMaP framework，而不是单个优化器。这个词很关键，因为 ReMaP 是由多个步骤拼起来的：

```text
clustering
dataflow extraction
mixed-size prototyping
ABPlace
periphery-guided relocating
recursive fixing
OpenROAD PPA evaluation
```

它不是像 DREAMPlace 那样只靠一个全局连续优化目标解决所有问题，而是把宏布局拆成多个更像专家操作的阶段。

### 2.2 核心机制是 recursively prototyping and relocating

论文标题中的两个关键词：

```text
Prototyping
Relocating
```

Prototyping 是指先做一次 mixed-size global placement，把宏和标准单元一起摆，得到一个“原型”。这个原型不一定最终可用，但能告诉算法：

```text
哪些宏和哪些标准单元簇靠近？
哪些 macro-cluster 之间通信强？
宏大致应该位于设计的哪个方向？
```

Relocating 是指根据这个原型，把宏搬到更符合专家经验的外围位置。不是简单最近边界投影，而是先通过 ABPlace 优化宏在椭圆上的角度，再用 heuristic 选择真实网格位置。

Recursive 是指这个过程不是一次性完成。每一轮只放一部分宏，把它们固定后再重新跑 mixed-size placement，让剩余宏和标准单元根据已固定宏重新调整位置。

### 2.3 ABPlace 是关键创新

摘要称 ABPlace 是 key innovation。它的含义是：

```text
Angle-Based Analytical Placement
```

ABPlace 将每个未放置宏约束到一个椭圆上，只优化它的角度 theta。这样原本二维的 `(x, y)` 优化变成一维角度优化：

```text
x = a cos(theta)
y = b sin(theta)
```

好处是：

```text
1. 每个宏只有一个变量，优化更稳定。
2. 宏天然靠近外围。
3. 仍然可以通过 dataflow 代价让强连接宏保持相对接近。
4. 可以加 overlap penalty，避免宏在椭圆上挤到一起。
```

### 2.4 实验主打 WNS/TNS

摘要声称 ReMaP 在 8 个 OpenROAD-flow-scripts case 上，WNS/TNS 都超过三个 leading macro placers，最大改善：

```text
WNS up to 34.15%
TNS up to 65.39%
```

这说明论文不是只看 placement 内部 HPWL，而是看 post-route PPA。这个评价方式更接近真实后端质量。

## 3. Fig. 1 的核心思想

Fig. 1 是理解整篇论文最重要的图。它展示了为什么不能直接把宏推到最近外围，以及 ReMaP 为什么要先做 ABPlace。

### 3.1 Fig. 1(a)：mixed-size placement prototype

图 1(a) 表示初始 mixed-size placement prototype。宏 A、B、C 和 cell cluster 混在一起，位置来自一次全局布局。这个布局可能不是最终宏布局，但它包含了 dataflow 信息。

可以把它理解成：

```text
DREAMPlace 告诉我们，如果不强行把宏放外围，宏和标准单元大概希望在哪里。
```

这个原型的价值在于保留电路连接关系和标准单元位置估计。

### 3.2 Fig. 1(b)：直接 periphery-pushing 的问题

图 1(b) 展示一种直觉做法：把每个宏直接推向最近角落或最近边缘。

这种做法看起来符合“宏放外围”的经验，但会破坏 dataflow。论文中说，不管 cell cluster 放在哪里，宏 A/B/C 之间的通信代价都很高，因为宏之间距离被拉得太远。

也就是说，简单最近外围投影会出现：

```text
1. 宏确实靠边了。
2. 但相互强连接的宏可能被推到不同角落。
3. dataflow 被破坏。
4. timing path 可能变长。
```

### 3.3 Fig. 1(c)：ABPlace 在椭圆上优化

图 1(c) 是 ReMaP 的关键步骤。它不是立刻把宏放到边界，而是先把宏限制在椭圆上，然后优化角度。

这样做的直觉是：

```text
宏已经大致处于外围方向，但仍可以沿椭圆移动，以减少强连接宏之间的距离和重叠。
```

这比直接推边缘更柔和。它把“靠外围”和“保 dataflow”放到同一个优化问题里。

### 3.4 Fig. 1(d)：外围引导重定位

图 1(d) 表示根据 ABPlace 的结果，把宏搬到真实外围 grid 位置。这里的关键是“guided”：ABPlace 给出宏的方向和相对关系，Relocating 再在这个方向附近找合法网格点。

因此 ReMaP 的逻辑不是：

```text
直接把宏推到边缘。
```

而是：

```text
先让宏在椭圆上形成合理外围原型，再把它们搬到真实可放置位置。
```

## 4. Related Work 怎么读

论文将宏布局方法分为三类：

```text
1. Zeroth-order methods
2. Analytical methods
3. Learning-based methods
```

### 4.1 Zeroth-order methods

Zeroth-order 方法适合处理黑盒 PPA，因为很多后端指标不可微、很慢、噪声也大。这类方法通常需要：

```text
1. solution representation：如何表示一个布局。
2. evaluation：如何评价布局好坏。
3. search algorithm：如何搜索更好的布局。
```

典型表示包括：

```text
corner block list
sequence pair
B*-tree
slicing tree
```

典型优化方法包括 simulated annealing 或 evolutionary algorithm。

论文认为这类方法的问题是：虽然可以表达宏拓扑和面积，但很难准确捕捉标准单元在后续 global placement 后的真实位置。

### 4.2 Analytical methods

Analytical methods 尝试把宏和标准单元作为连续变量同时优化，例如 DREAMPlace/RePlAce 类方法。优点是：

```text
1. 有全局 wirelength 视角。
2. 可以利用梯度。
3. 对大规模标准单元布局很有效。
```

问题是：

```text
1. mixed-size placement 容易出现宏和标准单元互相干扰。
2. 宏的最终 legal/regular 位置仍需要后处理。
3. 如果把标准单元固定，再细调宏，会损失性能。
```

ReMaP 的做法是借用 analytical placement 做原型，而不是完全依赖它做最终宏布局。

### 4.3 Learning-based methods

Learning-based 方法包括 Google Graph Placement、强化学习、decision transformer 等。论文指出它们的难点是 reward shaping：

```text
1. 如果只在所有宏放完后给 reward，反馈太稀疏。
2. 如果用 incremental wirelength 当 dense reward，又可能和最终 PPA 不一致。
```

ReMaP 相比学习方法更偏工程可控：没有训练模型，不依赖大量数据，主要靠专家启发式和解析优化。

## 5. Fig. 2：ReMaP 总流程

Fig. 2 展示完整 flow。可以拆成两个层次：

```text
第一层：ReMaP 自己的宏布局流程。
第二层：OpenROAD 后端 PPA 评估流程。
```

完整流程如下：

```text
.def + .lef + .v + .lib + .sdc
        |
Logic Synthesis by Yosys
        |
Louvain Clustering and Dataflow Extraction
        |
Mixed-Size Prototyping
        |
ABPlace: Angle-Based Analytical Macro Placement
        |
Periphery-Guided Macro Relocating
        |
All Macros Placed?
        | no
        v
Global Placement with Fixed Macros
        |
repeat
        |
        | yes
        v
.def Output
        |
OpenROAD: CTS + Routing + PPA Evaluation
```

这个图有两个重点：

1. ReMaP 内部每轮会 fixed macros，然后重新做 global placement。
2. 最终评价不是布局阶段内部指标，而是 OpenROAD 完整后端 flow 后的 WNS/TNS/WL/overflow。

## 6. Section III-A：Clustering and Dataflow Extraction

### 6.1 为什么要 clustering

直接在所有标准单元和宏之间优化太复杂。一个设计可能有几十万到上百万标准单元。如果直接让每个 cell 都参与宏布局优化，计算量和噪声都会很大。

所以 ReMaP 先把标准单元聚成 clusters。宏单元则被特殊处理：

```text
每个宏单独作为一个 cluster。
```

这样后续优化对象变成：

```text
宏 cluster + 标准单元 cluster
```

而不是所有 cell。

### 6.2 Star decomposition

论文说使用 star decomposition 将 net 拆成 individual edges，形成无向图。直观理解：

```text
一个多 pin net 不是展开成所有 pin 两两相连的 clique，
而是通过某种星形结构表示它和相关实例的连接。
```

在代码里也能看到类似思想：每条 net 可以生成虚拟节点，再连接到所有 pin 所属 node。这样可以避免高扇出 net 展开成过多边。

### 6.3 Louvain 社区发现

论文使用 modularity-based Louvain algorithm 找 communities。Louvain 的目标是找到图中连接紧密的节点集合。

在 ReMaP 语境中：

```text
连接紧密的一组标准单元可以视为一个 cell cluster。
```

这和宏布局目标相关，因为一个 cluster 的质心可以代表一组标准单元的位置需求。

### 6.4 Dataflow matrix A

clustering 后，论文会遍历初始图，计算每对 cluster 之间的直接 dataflow strength，形成矩阵 A：

```text
A[i, j] = cluster i 和 cluster j 之间的直接连接强度
```

这个矩阵后续会用于 ABPlace 和 relocating 的 dataflow cost。

论文还说明它只用了 direct connections，没有使用 one-hop/two-hop indirect connections。作者尝试过间接连接，但提升很小，还需要更多参数调节。因此最终选择更简单直接的 dataflow。

这点很重要：ReMaP 的强大并不来自复杂图特征，而来自后续递归原型和外围引导策略。

## 7. Section III-B：Mixed-Size Prototyping

### 7.1 为什么需要 mixed-size prototype

宏布局不能只看宏之间的关系。标准单元占据大量面积，而且连接宏。如果忽略标准单元，可能会出现：

```text
1. 宏之间距离短，但标准单元被挤到狭窄通道。
2. 宏把核心区域切碎，cell placement 困难。
3. 宏和 cell cluster 的真实连接关系没有被反映。
```

因此 ReMaP 先做 mixed-size global placement，让宏和标准单元一起摆放，得到一个初始原型。

### 7.2 为什么不用 soft block 同时优化

传统宏布局会把 cell clusters 当 soft blocks，然后与宏一起优化。但论文指出这个方法有两个问题：

```text
1. cell cluster 的面积和形状难以准确确定。
2. 最终真实标准单元位置可能和 soft block 优化结果不一致。
```

ReMaP 换了一个思路：

```text
先用真实 mixed-size global placement 得到标准单元位置，再用这些位置计算 cluster centroid。
```

这样 cell cluster 的位置来自实际 global placement，而不是手工假设的 soft block。

### 7.3 动态 target density

论文中有一个容易被忽略但很重要的设计：target density 会随递归过程改变。

初始阶段许多宏还是 movable：

```text
target density 较高，帮助 mixed-size placement 收敛。
```

随着更多宏被固定：

```text
target density 降低，更接近低利用率设计最终 cell placement。
```

论文在消融实验里比较了固定 target density 0.5、固定 0.91 和动态 density。结果显示默认动态设置整体更好。

这对应代码中的：

```text
target_density_decay = (target_density_lb / target_density) ** (1 / expected_steps)
params.target_density *= target_density_decay
```

也就是说，每轮递归会逐步降低 target density。

## 8. Section III-C：ABPlace 公式详解

### 8.1 椭圆定义

设芯片 core 宽高为：

```text
W, H
```

椭圆中心在芯片中心。第 k 轮的椭圆半轴为：

```text
a = beta * gamma^k * W / 2
b = beta * gamma^k * H / 2
```

椭圆方程：

```text
x^2 / a^2 + y^2 / b^2 = 1
```

其中：

```text
beta 是 scale factor，论文默认 0.9。
gamma 是 decay factor，需要按 case 调。
k 是当前递归迭代次数。
```

gamma 的作用是让椭圆逐轮缩小。初始椭圆较大，推动宏靠近外围；后续因为已有宏占据外围空间，椭圆逐渐缩小，适应剩余可用空间。

### 8.2 从原型位置映射到椭圆

给定宏 i 在 mixed-size prototype 中的位置：

```text
(x_i^0, y_i^0)
```

从芯片中心向该宏画一条射线，与椭圆交点就是初始映射位置。角度：

```text
theta_i = arctan(y_i^0 / x_i^0)
```

映射后：

```text
x_i = a cos(theta_i)
y_i = b sin(theta_i)
```

这个操作保留了宏相对中心的大致方向。例如 prototype 中在右上方的宏，映射后仍在右上方向的椭圆边界附近。

### 8.3 为什么只优化 theta

ABPlace 的关键是把宏固定在椭圆上，只优化角度向量：

```text
theta = [theta_1, theta_2, ..., theta_m]
```

这比直接优化每个宏的 `(x, y)` 更稳定：

```text
二维坐标优化：每个宏 2 个变量，容易偏离外围。
角度优化：每个宏 1 个变量，天然位于外围。
```

同时，由于所有宏都在椭圆上，宏不会被优化器推到芯片中心，从而保留中心区域给标准单元。

### 8.4 ABPlace 目标函数

论文的公式为：

```text
min_theta  sum_{i in M} sum_{j in N} dist(i, j) A[i, j]
         + lambda * sum_{i,j in M, i != j} overlap(i, j)
```

其中：

```text
M = 所有未放置宏
N = 所有宏 + 所有 cell clusters
A = dataflow matrix
dist(i, j) = 欧氏距离
lambda = overlap penalty 的拉格朗日乘子
```

第一项是 dataflow cost：

```text
强连接对象距离越远，代价越大。
```

第二项是 overlap cost：

```text
宏之间重叠越多，代价越大。
```

### 8.5 overlap penalty

两个宏 i 和 j 的 overlap 定义为：

```text
overlap(i, j)
= max((w_i + w_j)/2 - |x_i - x_j|, 0)
* max((h_i + h_j)/2 - |y_i - y_j|, 0)
```

这实际上是矩形重叠面积的近似：

```text
横向重叠长度 * 纵向重叠长度
```

如果两个宏在 x 或 y 方向没有重叠，则对应 max 为 0，总 overlap 为 0。

### 8.6 平滑绝对值

论文提到 max 函数和绝对值会带来不可导点，所以使用：

```text
sqrt(x^2 + epsilon^2) - epsilon
```

近似 `|x|`。这样梯度更平滑，PyTorch 优化更稳定。

### 8.7 lambda 怎么理解

lambda 是 ABPlace 里很关键的参数。

```text
lambda 大：更重视避免重叠和均匀分布，宏更规则。
lambda 小：更重视 dataflow，强连接宏可能更靠近。
```

论文后面也说 ReMaP 主要需要调两个参数：

```text
gamma：椭圆缩小速度。
lambda：ABPlace overlap penalty 权重。
```

## 9. Section III-D：Periphery-Guided Macro Relocating

ABPlace 只是把宏优化到椭圆上，但真实宏不能只停在椭圆上。它们需要放到合法、规则、靠外围的位置。因此论文提出 periphery-guided macro relocating。

这个阶段每一步解决两个问题：

```text
1. 先放哪个宏？
2. 把这个宏放到哪里？
```

### 9.1 宏放置顺序的两个标准

论文提出两个排序标准。

第一种：descending order of overlapping area。

含义是：

```text
在椭圆上更拥挤、重叠面积更大的宏优先放。
```

这样做有助于 regularity：

```text
1. 大宏先靠外围放，小宏留到内部或剩余区域。
2. 形状尺寸相似的宏更可能一起被处理，形成规则排布。
```

第二种：ascending order of dataflow strength。

含义是：

```text
dataflow 较弱的宏先放。
```

为什么弱连接宏先放？论文解释是：这样可以让强连接宏更晚放，从而在外围放置过程中保留更多选择空间，使强连接宏更靠近核心或更靠近相关 cluster，降低 dataflow 损失。

论文默认使用第二种，因为它通常带来更好的 timing。

### 9.2 可放置区域如何构造

Fig. 3 展示了一个宏的候选区域构造。步骤是：

```text
1. 宏 i 已经在椭圆上有一个优化后的位置。
2. 在该点作椭圆切线。
3. 从宏中心出发，分别在 x 和 y 方向距离 Delta_x、Delta_y 处画平行线。
4. 这些线和外围方向共同形成一个五边形可放置区域。
5. 将该区域离散成 grid。
6. 排除与已放置宏重叠的 grid。
```

直观理解：

```text
ABPlace 决定“宏大概应该朝哪个方向”。
Relocating 只在这个方向附近找外围合法位置。
```

这避免了宏被 relocation 阶段随意搬到完全不相关的区域。

### 9.3 periphery cost

论文定义：

```text
c_peri = min(W - x, x) + min(H - y, y)
```

这个代价衡量一个点离芯片边界有多近。

如果一个点靠近左边界：

```text
min(W - x, x) 很小
```

如果靠近底边界：

```text
min(H - y, y) 很小
```

所以 `c_peri` 越小，越靠近芯片角落或边界。

### 9.4 dataflow cost

论文定义：

```text
c_df = sum_{j in P} dist(i, j) A[i, j]
```

其中：

```text
P = 已放置宏 + 所有 cell clusters
```

这表示把宏 i 放到候选点后，它和已固定对象以及 cell clusters 之间的 dataflow 代价。

### 9.5 Pareto dominance

论文不是直接把 `c_peri + c_df` 混成一个加权和，而是先用 periphery cost 做 Pareto 过滤。

对于两个 grid：

```text
(x, y)
(x', y')
```

如果：

```text
min(W - x, x) <= min(W - x', x')
min(H - y, y) <= min(H - y', y')
```

则 `(x, y)` dominate `(x', y')`。

被 dominate 的点说明在水平和垂直方向都不如另一个点靠外围，因此可以丢弃。剩下的 non-dominated grids 形成候选集。

之后再在候选集中用 `c_df` 选最小值。

这个设计非常精巧：它避免了手动调 periphery 和 dataflow 的加权系数。流程变成：

```text
先保证足够外围，再在外围候选里选 dataflow 最好。
```

## 10. Algorithm 1 逐行解读

论文 Algorithm 1 是 ReMaP 的完整伪代码。

输入：

```text
.def, .lef, .v, .lib, .sdc
decay factor gamma
scale factor beta
k: 每轮放置多少个宏
n: 宏数量
```

输出：

```text
所有宏已经放置的 .def
```

### 10.1 Lines 1-3：预处理

```text
1. 用 Louvain 聚类所有宏和标准单元。
2. 提取 dataflow matrix A。
3. 将宏从 cluster 中分离出来，每个宏单独作为 cluster。
```

这三步只做一次。原因是 graph 和 dataflow 主要来自网表连接，而不是每轮位置。

### 10.2 Lines 5-6：每轮重新做 mixed-size placement

```text
while there remain unplaced macros:
    Perform preliminary mixed-size placement
    compute centroid of each cell cluster
```

这是 ReMaP 和很多一次性宏布局方法的核心区别。每轮固定一批宏后，剩余标准单元的位置会变化。因此 ReMaP 重新做 mixed-size placement，更新 cell cluster 质心。

### 10.3 Lines 7-8：更新椭圆并映射未放置宏

```text
a = beta * gamma^iter * W / 2
b = beta * gamma^iter * H / 2
Map each unplaced macro onto ellipse
```

随着 iter 增大，椭圆缩小。宏被映射到当前轮的椭圆上，保持从 prototype 得到的大致方向。

### 10.4 Line 9：执行 ABPlace

```text
Execute ABPlace
```

这里优化角度 theta，让未放置宏在椭圆上既保留 dataflow，又减少 overlap。

### 10.5 Line 10：选择 top-k 宏

```text
Rank macros by specified criteria and select top k
```

论文默认按 weaker dataflow first。k 决定了递归粒度：

```text
k 小：更精细，质量可能更好，runtime 更长。
k 大：更快，但一次固定太多宏，可能影响质量。
```

论文通常设：

```text
k = ceil(n / 10)
```

这样最多约 10 轮完成。

### 10.6 Lines 11-14：逐个宏选择 grid 并固定

```text
for each macro in top k:
    Select optimal grid considering dataflow and periphery cost.
    Place and fix macro.
```

这是 periphery-guided relocating 的核心。

### 10.7 Line 16：递归结束

当所有宏都固定后，ReMaP 输出最终 DEF，再交给 OpenROAD 做 PPA evaluation。

## 11. 两个关键参数：gamma 和 lambda

论文明确说 ReMaP 主要需要调两个参数：

```text
gamma: decay factor
lambda: Lagrange multiplier for overlap penalty
```

### 11.1 gamma

gamma 控制椭圆随轮次缩小的速度。

```text
gamma 接近 1：椭圆缩小慢，宏更倾向于持续靠外围。
gamma 小：椭圆缩小快，后续宏更容易进入内部区域。
```

如果 gamma 太大，后续宏可能仍被迫靠外围，造成外围拥挤或 dataflow 拉长。如果 gamma 太小，宏可能过早进入核心区域，影响标准单元布局和拥塞。

### 11.2 lambda

lambda 控制 ABPlace 中 overlap penalty 权重。

```text
lambda 大：宏更分散、更规则，但可能牺牲 dataflow。
lambda 小：更重视 dataflow，但宏可能在椭圆上拥挤。
```

论文 Table III 用 Bayesian optimization 自动调 gamma 和 lambda，并报告 ariane133 和 bp_be 上平均 WNS/TNS 改善 8.75%。

## 12. 实验设置解读

论文使用 8 个 OpenROAD-flow-scripts 设计：

```text
ariane133
ariane136
black_parrot
bp_be
bp_fe
bp_multi
bp_quad
swerv_wrapper
```

实验环境：

```text
52-core Intel Xeon CPU 2.60GHz
NVIDIA RTX 2080S GPU
128GB RAM
Nangate45 library
OpenROAD flow for final PPA
```

对比方法：

```text
RTL-MP
Hier-RTLMP
DREAMPlace 4.1.0 with macro placement enhancements
ReMaP
```

评估指标：

```text
rWL: routing wirelength
WNS
TNS
Power
Overflow
Runtime
```

重点是 post-route PPA，而不是 placement 阶段的 HPWL。

## 13. Table I 主结果怎么读

Table I 是整篇论文最重要的实验表。结论：

```text
ReMaP 在 8 个 case 上都取得最好的 WNS 和 TNS。
```

论文报告：

```text
平均 WNS 改善：8.39%
平均 TNS 改善：16.57%
最大 WNS 改善：34.15%
最大 TNS 改善：65.39%
```

这里的改善是相对每个 case 的 strongest baseline。

### 13.1 bp_quad

bp_quad 是最大的 case：

```text
Macros: 220
Cells: 1135K
Nets: 1448K
Frequency: 384.6 MHz
Utilization: 0.39
```

Table I 中：

```text
RTL-MP:      WNS -1.40, TNS -22767.70, Overflow 161655
Hier-RTLMP: WNS -0.99, TNS -16445.80, Overflow 11330
DREAMPlace: WNS -1.31, TNS -21669.80, Overflow 28822
ReMaP:      WNS -0.93, TNS -14139.20, Overflow 4629
```

这说明 ReMaP 在大规模宏数量多的设计上优势明显。它不仅 WNS/TNS 好，overflow 也显著降低。原因很可能是外围规则宏布局释放了核心区域，改善了 routing congestion。

### 13.2 bp_fe

bp_fe 较小，但 ReMaP timing 改善非常明显：

```text
DREAMPlace WNS -0.65, TNS -43.28
ReMaP      WNS -0.27, TNS -6.88
```

这说明对于某些 timing-sensitive 小 case，宏位置对关键路径影响极大。ReMaP 通过外围重定位和 dataflow 保护，显著改善了 timing。

### 13.3 swerv_wrapper

swerv_wrapper 中 ReMaP 同时改善 timing 和 wirelength：

```text
DREAMPlace rWL 5.33, WNS -1.41, TNS -1364.19
ReMaP      rWL 4.44, WNS -1.12, TNS -979.03
```

这说明 ReMaP 并不是必然牺牲线长换 timing。在某些设计上，规则外围布局也可以减少绕线。

### 13.4 ReMaP 的 runtime 排名

Table I 最后一行 average rank：

```text
rWL: 2.375
WNS: 1
TNS: 1
Power: 2.125
Overflow: 1.75
Runtime: 3.5
```

这说明 ReMaP 的主要代价是 runtime。它为了更好的 WNS/TNS，牺牲了一定速度。

## 14. Fig. 4：bp_quad 可视化

Fig. 4 展示 bp_quad 的四种方法布局：

```text
(a) RTL-MP
(b) Hier-RTLMP
(c) DREAMPlace
(d) ReMaP
```

论文解释：

```text
RTL-MP 规则性好，但 timing 差。
Hier-RTLMP timing 有改善，但布局不规则，有 large notch regions。
DREAMPlace 存在 timing 和 core congestion 问题。
ReMaP 同时有较好 timing 和 regularity。
```

这个图想强调：ReMaP 不是只靠把宏摆得好看，而是在规则性、外围性和 dataflow 之间找到平衡。

## 15. Table II 消融实验怎么读

Table II 比较了几种设置：

```text
Fix_Density_0.5
Fix_Density_0.91
Overlap_Criteria
Default
```

### 15.1 动态 density 的价值

论文默认使用动态 target density，从 0.91 降到 0.5。消融中固定 0.5 或固定 0.91 有时表现好，但整体不如默认稳定。

这说明：

```text
宏布局不同阶段对 placement density 的需求不同。
```

早期宏多且可动时，较高 density 有助于 mixed-size placement 收敛；后期宏固定后，较低 density 更符合最终低利用率 cell placement。

### 15.2 macro ordering 的价值

Overlap_Criteria 是按重叠面积排序，倾向于更规则布局。Default 是按弱 dataflow 先放。

论文发现：

```text
Overlap_Criteria 偶尔更好，但 Default 通常更好。
```

这说明 timing 目标下，保护强 dataflow 的宏更重要。弱 dataflow 宏先靠外围放，强 dataflow 宏保留更多位置选择空间，通常更有利于 WNS/TNS。

### 15.3 没有单一设置适合所有 case

Table II 也说明 macro placement 很 case-specific。同一个策略在不同设计上表现不同。这也是论文最后引入 Bayesian optimization 的原因。

## 16. Fig. 5 Runtime Breakdown

Fig. 5 展示 swerv_wrapper 和 bp_quad 的 runtime breakdown。组成包括：

```text
I/O
Clustering and Dataflow Extraction
DREAMPlace-Gradient
ABPlace and Macro Relocating
```

论文对 runtime 的解释：

```text
小 case 中，gradient calculation 占比较高，因为 recursive prototyping 重复调用 DREAMPlace。
大 case bp_quad 中，runtime 没有随规模急剧上升，因为 DREAMPlace 的梯度传播效率较高。
bp_quad 规模增加超过 10 倍，但 gradient 绝对时间只增加约 12.5%。
大 case 的主要 runtime 反而被 I/O 消耗，这是工程实现问题。
```

这说明 ReMaP 的算法思路具备扩展潜力，但代码工程上还有优化空间，尤其是递归调用带来的 I/O 和数据库重读写。

## 17. Table III 参数自动调优

Table III 用 Bayesian Optimization 调两个参数：

```text
gamma
lambda
```

例子：

```text
ariane133:
hand-crafted gamma=0.943, lambda=0.006, WNS=-1.07, TNS=-2615.74
50-round BO gamma=0.956, lambda=0.001, WNS=-1.02, TNS=-2484.17

bp_be:
hand-crafted gamma=0.943, lambda=0.006, WNS=-0.90, TNS=-98.00
50-round BO gamma=0.990, lambda=0.440, WNS=-0.78, TNS=-76.26
```

论文报告这两个 case 上 WNS/TNS 平均改善 8.75%。

这个结果说明：

```text
1. ReMaP 的参数空间较低维，适合自动调优。
2. gamma/lambda 对结果很敏感。
3. 手工调参已经不错，但 BO 还能继续挖质量。
```

## 18. ReMaP 的真正贡献

读完论文后，可以把 ReMaP 的贡献分成三层。

### 18.1 方法框架贡献

ReMaP 不是一次性宏布局，而是递归式：

```text
prototype -> relocate -> fix -> re-prototype -> relocate -> fix
```

这种递归结构的优势是：每次固定部分宏后，标准单元和剩余宏的位置可以重新适应，避免一次性决策带来的误差。

### 18.2 优化变量设计贡献

ABPlace 把二维宏位置问题变成一维角度问题：

```text
每个宏只优化 theta。
```

这既让宏天然靠外围，又提高优化稳定性。论文强调它在所有 test cases 上容易收敛。

### 18.3 启发式设计贡献

Periphery-guided relocating 把专家经验落成具体算法：

```text
1. 宏靠外围。
2. 强 dataflow 不要过早牺牲。
3. 用 Pareto dominance 先筛外围候选。
4. 再用 dataflow cost 选最终位置。
```

这个设计简单但有效，也解释了为什么 ReMaP 能在 WNS/TNS 上强于只优化 HPWL 的方法。

## 19. 论文的局限性

论文自己也提到一些限制，结合代码和实验可以总结为：

### 19.1 Runtime 偏慢

递归调用 mixed-size placement 会带来 runtime 开销。Table I 中 ReMaP 的 runtime 平均排名是 3.5，不是强项。

### 19.2 参数仍需调节

gamma 和 lambda 对结果影响明显。虽然 BO 可以自动调，但 50-round BO 本身也会增加总运行成本。

### 19.3 主要面向低利用率 ORFS case

论文脚注中提到动态 density 是为 OpenROAD-flow-scripts 中低利用率、低 target density benchmark 设计的。对于更高密度设计，作者表示未来会扩展。

### 19.4 没有显式 timing path 建模

ReMaP 虽然优化 WNS/TNS 很有效，但其内部主要用 dataflow matrix，而不是直接用 STA critical path。因此如果要继续优化，可以考虑把 OpenROAD timing report 反馈到 dataflow 权重中。

这一点也正是后续做 TAP-ReMaP 或 timing-aware ReMaP 的切入点。

## 20. 结合代码理解论文

在当前仓库中，可以将论文模块对应到代码：

```text
论文 Mixed-Size Prototyping
    -> ReMaP/dreamplace/Placer.py
    -> NonLinearPlace.NonLinearPlace(params, placedb, timer)

论文 Clustering and Dataflow Extraction
    -> ReMaP/dreamplace/Cluster.py
    -> GraphBuilder
    -> Plot.extract_adjacency_matrix

论文 ABPlace
    -> ReMaP/remap/ClusterPlacer.py
    -> class ABPlacer
    -> obj_fn(theta)

论文 Periphery-Guided Macro Relocating
    -> ReMaP/remap/MacroDistributor.py
    -> class GridGuideDistributor
    -> distribute()
    -> distribute_macro()

论文递归主循环
    -> ReMaP/dreamplace/Placer.py
    -> while np.any(movable_macro_mask[:num_macros])

论文输出 mp_out
    -> ReMaP/remap/utils/def2mp.py
```

重点阅读代码顺序建议：

```text
1. 先读 Placer.py 的 remap_flag 分支，理解递归主循环。
2. 再读 Cluster.py，理解 graph 怎么建。
3. 再读 ClusterPlacer.py 的 ABPlacer，理解公式怎么实现。
4. 再读 MacroDistributor.py，理解 Fig. 3 的候选区域和 grid selection。
5. 最后看 test/or_cases/*.json，理解 gamma、lambda、macro_halo、k 等参数。
```

## 21. 用自己的话复述 ReMaP

如果你要在组会或论文阅读汇报中讲 ReMaP，可以这样讲：

> ReMaP 的核心思想是模拟专家宏布局：专家通常会先看一次全局布局，理解宏和标准单元的相对关系；然后把宏摆到芯片外围，释放中间区域给标准单元；同时又不会简单把宏推到最近边，而是保留 dataflow 上强连接宏之间的相对关系。ReMaP 把这个过程自动化：它先用 DREAMPlace 得到 mixed-size prototype，再用 Louvain 聚类和 dataflow matrix 抽象宏与标准单元簇的关系；之后通过 ABPlace 把未放置宏约束在椭圆上，只优化角度，从而稳定地产生外围分布；最后使用 periphery-guided relocating 在离散 grid 中选择真实宏位置。每轮只固定一部分宏，然后重新做 mixed-size placement，直到所有宏固定。实验显示，这种递归原型和外围引导策略在 OpenROAD post-route WNS/TNS 上显著优于 RTL-MP、Hier-RTLMP 和 DREAMPlace。

## 22. 这篇论文最值得学习的点

### 22.1 不直接优化最终目标，而是设计结构性中间目标

WNS/TNS 很难直接优化。ReMaP 没有硬做 STA-driven optimization，而是设计了几个更稳定的 surrogate：

```text
dataflow cost
overlap penalty
periphery cost
recursive prototype quality
```

这些中间目标组合起来，最终改善了 WNS/TNS。

### 22.2 把专家经验形式化

论文最强的地方不是公式复杂，而是把专家经验拆解得很清楚：

```text
宏靠边
标准单元留中心
强连接不要拉太远
大宏和类似宏尽量规则
不要一次性固定所有宏
```

这些原则通过 ABPlace、grid candidate、Pareto dominance 和 recursion 被形式化。

### 22.3 降低优化难度

ABPlace 的一维角度变量设计非常巧。它没有试图在二维连续空间里解决复杂约束，而是先把宏限制到一个符合最终目标的低维 manifold 上：

```text
ellipse boundary
```

这是一种很典型的算法设计技巧：通过变量重参数化，把难问题变成更容易收敛的问题。

## 23. 读论文时容易误解的地方

### 23.1 ReMaP 不是单纯把宏放边缘

如果只是把宏放边缘，会出现 Fig. 1(b) 的问题。ReMaP 的关键在于：

```text
先在椭圆上优化 dataflow，再做外围重定位。
```

### 23.2 ABPlace 不是最终合法化

ABPlace 只是给出宏在椭圆上的相对分布。最终位置由 periphery-guided relocating 在 grid 中选择。

### 23.3 Louvain clustering 不是论文唯一核心

论文用了 Louvain，但作者也说 ReMaP 可以接入更高级的 clustering 方法。真正核心是后面的 recursive prototyping 和 relocating。

### 23.4 ReMaP 优化的是 post-route timing，不是 placement HPWL

Table I 看的是 OpenROAD routing 后的结果。ReMaP 的 rWL 不一定总是最小，但 WNS/TNS 最好。

## 24. 可以继续改进的方向

基于原论文，后续可以考虑：

```text
1. Timing-aware dataflow matrix：用 STA critical path 给 A 矩阵加权。
2. Congestion-aware relocating：candidate grid 加入 routing demand 估计。
3. Faster recursive I/O：避免每轮重复完整读写 DEF。
4. Adaptive k：不同阶段动态决定每轮固定多少宏。
5. Automatic gamma/lambda tuning：把 BO 集成到脚本中。
6. High-utilization extension：针对高利用率设计重新设计 target density schedule。
```

其中最自然的改进是 timing-aware dataflow，因为原论文已经证明 dataflow 对 WNS/TNS 重要，但还没有显式使用 critical path slack。

## 25. 总结

ReMaP 的思想可以总结为：

```text
专家宏布局经验
    -> 宏靠外围、中心留给标准单元、强连接尽量近、宏排布尽量规则

算法化表达
    -> mixed-size prototyping + Louvain dataflow + ABPlace + periphery-guided relocating

工程实现
    -> 每轮固定部分宏，重新跑 mixed-size placement，递归直到全部宏固定

实验验证
    -> 在 8 个 ORFS case 上取得最好的 post-route WNS/TNS
```

这篇论文的价值在于，它没有把宏布局完全交给黑盒学习或复杂全局优化，而是用非常清晰的结构化方法，把人类 floorplanning 经验转成可复现的算法流程。对于理解宏布局、改进 WNS/TNS、设计新的 placement heuristic，这篇论文都非常值得细读。
