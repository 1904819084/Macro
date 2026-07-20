# TAP-ReMaP：面向 WNS/TNS 与线长优化的时序感知递归宏布局算法

## 摘要

宏单元布局是数字芯片物理设计流程中的关键早期决策。宏单元位置一旦确定，后续标准单元全局布局、时钟树综合、全局布线、详细布线以及最终静态时序分析都会受到显著影响。传统宏布局方法通常以 HPWL、连接强度、密度、拥塞或宏间重叠作为主要优化目标，但最终 PPA 结果中的 WNS 和 TNS 并不是由所有网络的平均线长决定，而往往由少量关键时序路径主导。因此，一个总线长较短的宏布局方案仍可能因为关键路径上的宏单元距离过远、关键标准单元簇被拉散、或关键路径周围局部拥塞严重而导致较差的 setup timing。

本文在 DAC'25 ReMaP 项目的递归宏布局框架基础上，提出一种面向 WNS/TNS 和线长联合优化的时序感知宏布局方法，称为 TAP-ReMaP，即 Timing-Aware Path-Guided ReMaP。原始 ReMaP 通过递归 prototyping 和 relocating，逐步固定宏位置，并在每一轮固定部分宏后重新进行标准单元布局，从而获得较高质量的宏布局结果。本文进一步将 OpenROAD 后端流程产生的静态时序分析反馈引入 ReMaP 的图构建、宏排序、角度优化器和候选位置选择过程。具体而言，本文提出 critical path extraction、slack-aware net reweighting、critical path hypergraph、timing-aware macro ordering、Pareto candidate selection 以及 PPA feedback loop 六个模块，使宏布局目标从传统 connectivity-driven 优化转变为 timing-criticality-driven 优化。

基于项目自带 OpenROAD-PPA-evaluation/eval_metadata 的真实结果，原始 ReMaP 相比 DREAMPlace 在 bp_quad 上将 WNS 从 -1.30537 改善到 -0.926841，TNS 从 -21669.8 改善到 -14139.2，分别对应 29.00% 和 34.75% 的改善，同时 overflow 从 28822 降低到 4629。本文方法的目标是在保留 ReMaP 递归布局优势的基础上，进一步优化关键路径物理距离，在 WL guardrail 约束下继续提升 WNS/TNS。

关键词：宏布局；静态时序分析；WNS；TNS；线长优化；OpenROAD；ReMaP；关键路径；递归布局

## 1. 引言

在现代数字芯片设计中，宏单元通常包括 SRAM、寄存器文件、IP block、cache memory 或其他大面积 hard macro。与标准单元相比，宏单元面积大、位置自由度低、布线阻挡强，对芯片整体物理实现质量具有放大效应。宏布局如果不合理，会带来以下问题：

1. 关键路径跨越过长距离，造成 setup timing violation。
2. 宏之间通道过窄，造成局部 routing congestion。
3. 标准单元被宏单元分割成多个孤立区域，导致 cell placement 质量下降。
4. 时钟树绕行严重，增加 clock insertion delay 和 skew。
5. 详细布线阶段发生大量 overflow 或 DRC violation。

因此，宏布局不是单纯的几何问题，也不是单纯的 HPWL 最小化问题，而是物理实现早期对最终 WNS、TNS、WL、congestion 和 runtime 的综合预判问题。

ReMaP 提出了一种递归宏布局思路。其核心思想是：先利用 DREAMPlace 生成全局布局原型，然后基于网表连接构建设计图，将标准单元和宏单元组织成 cluster，再通过角度优化和 grid-guided distribution 逐步固定部分宏单元的位置。每固定一批宏单元后，ReMaP 将这些宏作为 blockages 写回 DEF，再重新运行全局布局，让标准单元和剩余宏在新的约束下重新分布。这个过程不断递归，直到所有宏单元固定。

该方法已经在多个 OpenROAD-flow-scripts case 上表现出较强的 WNS/TNS 改善能力。例如在项目自带结果中，ReMaP 相比 DREAMPlace 在 bp_fe 上将 WNS 从 -0.652084 改善到 -0.272749，TNS 从 -43.2785 改善到 -6.88318，分别改善 58.17% 和 84.10%。然而，原始 ReMaP 仍主要依赖连接关系和线长代理目标，而没有直接使用后端 STA 反馈。因此，对于那些由少量关键路径主导的 case，仍存在进一步优化空间。

本文的基本观点是：

> 宏布局优化不应只关注所有网络的平均物理距离，而应优先关注关键时序路径上宏、标准单元簇和关键网络之间的物理紧凑性。

基于这一观点，本文提出 TAP-ReMaP。该方法不是简单调参，而是在算法结构上将时序信息反馈到 ReMaP 的核心递归布局循环中，使得宏布局过程显式感知 WNS/TNS 相关的 critical nets 和 critical paths。

## 2. 原始 ReMaP 方法详解

### 2.1 输入与输出

原始 ReMaP 的输入包括：

```text
1. LEF 文件：描述标准单元和宏单元几何信息。
2. LIB 文件：描述单元时序和功耗信息。
3. DEF 文件：描述设计实例、网络和初始 floorplan。
4. JSON 参数文件：描述 DREAMPlace 与 ReMaP 的运行参数。
```

对于每个 OpenROAD case，例如 bp_be，对应参数文件为：

```text
ReMaP/test/or_cases/bp_be.json
```

其中包含关键参数：

```json
{
  "num_bins_x": 1024,
  "num_bins_y": 1024,
  "global_place_stages": [
    {
      "num_bins_x": 1024,
      "num_bins_y": 1024,
      "iteration": 1000,
      "learning_rate": 0.01,
      "wirelength": "weighted_average",
      "optimizer": "nesterov"
    }
  ],
  "target_density": 0.91,
  "density_weight": 8e-5,
  "gamma": 4.0,
  "macro_halo_x": 60,
  "macro_halo_y": 60,
  "l_overlap_penalty": 6e-3,
  "macros2place_each_step": 0
}
```

输出为：

```text
ReMaP/install/results/YYYYMMDD/<case>/<time>/mp_out
```

该 `mp_out` 文件随后被复制到 OpenROAD-PPA-evaluation 的结果目录，由 OpenROAD flow 执行 floorplan、placement、CTS、routing 和 report，最终得到 WNS、TNS、wirelength、power 和 overflow。

### 2.2 原始 ReMaP 主流程

原始 ReMaP 主要入口在：

```text
ReMaP/dreamplace/Placer.py
```

整体流程可以抽象为：

```text
Algorithm Original-ReMaP

Input:
    design DEF/LEF/LIB
    DREAMPlace parameters
    ReMaP parameters

Output:
    mp_out

1. 读取设计数据库 placedb。
2. 调用 DREAMPlace NonLinearPlace 进行初始全局布局。
3. 提取所有 movable macros。
4. 根据 placedb 构建设计图 graph。
5. 使用 networkit PLM 对 graph 做 community detection。
6. 根据 community 结果构造 cluster adjacency matrix。
7. 调用 ABPlacer 优化宏单元的角度分布。
8. 调用 GridGuideDistributor 在 layout grid 上固定一批宏。
9. 将已固定宏作为 blockages 写入 DEF。
10. 重新读取 DEF 并重新运行 global placement。
11. 重复步骤 7 到 10，直到所有宏固定。
12. 将最终 DEF 转换为 OpenROAD macro placement 格式 mp_out。
```

### 2.3 初始 DREAMPlace 全局布局

ReMaP 首先调用 DREAMPlace 的 NonLinearPlace：

```python
placer = NonLinearPlace.NonLinearPlace(params, placedb, timer)
metrics = placer(params, placedb)
```

DREAMPlace 的全局布局目标大致可以理解为：

```text
minimize:
    wirelength_cost + density_weight * density_cost
```

其中 wirelength 使用 weighted-average 或 log-sum-exp 平滑近似，density cost 用于避免 cell overlap 和 density overflow。该阶段为后续 ReMaP 提供一个物理上较合理的初始原型。

### 2.4 图构建与社区划分

ReMaP 使用 `GraphBuilder` 将 netlist 转换为图。原始逻辑是：

```python
for net_index, pins in enumerate(self.net2pin_map):
    weight = self.net_weights[net_index]
    connected_nodes = set()
    for pin_id in pins:
        node_index = self.pin2node_map[pin_id]
        connected_nodes.add(node_index)

    if len(connected_nodes) > 1:
        virtual_node_index = self.graph.addNode()
        for node_index in connected_nodes:
            self.graph.addEdge(virtual_node_index, node_index, weight)
```

这里的含义是：每条 net 被转换成一个虚拟节点，所有连接到该 net 的实例节点都与虚拟节点相连。这样可以避免高扇出 net 被直接展开成完全图，降低图构建复杂度。

随后 ReMaP 调用 networkit 的 PLM 算法：

```python
plm = nk.community.PLM(g, gamma=10, par='none')
plm.run()
communities = plm.getPartition()
```

得到 community 后，每个 community 对应一个 cluster。宏单元通常被保留为特殊 cluster，标准单元则根据连接关系聚合成多个 cell clusters。

### 2.5 ABPlacer：角度驱动的宏分布优化

ReMaP 的 ABPlacer 将宏单元映射到一个椭圆边界附近。每个可移动宏使用一个角度参数 theta 表示位置：

```text
x = half_width  * cos(theta) + half_width
y = half_height * sin(theta) + half_height
```

ABPlacer 的原始目标函数为：

```text
L_old = L_conn + lambda_overlap * L_overlap
```

其中：

```text
L_conn = sum_{i,j} link_strength(i,j) * distance(i,j)
```

`L_overlap` 惩罚宏之间的重叠。代码中对应：

```python
weighted_distance = (torch.sum(im_wdist) + torch.sum(mn_wdist)) / 2
overlap_penalty = torch.sum(H_overlap * V_overlap) / 2

obj = torch.tensor(0.0).to(self.device)
obj += weighted_distance
obj += overlap_penalty * l_overlap_penalty
```

这个目标函数的优点是简单、可微、运行速度快。但它的核心问题是：`link_strength` 主要来自连接数量或 net weight，而不是来自 STA criticality。因此，它会倾向于缩短强连接，但并不知道哪些连接真正决定 WNS/TNS。

### 2.6 GridGuideDistributor：逐步固定宏位置

ABPlacer 给出宏的大致相对方向后，GridGuideDistributor 在二维 grid 中为宏选择合法位置。其流程为：

```text
1. 根据已放置宏生成 placed_mask。
2. 对每个未放置宏构造 position_mask。
3. 排除与已放置宏冲突的位置。
4. 从合法候选点中选择 score 最好的点。
5. 固定该宏。
6. 每轮固定 macros2place_each_step 个宏。
```

原始宏顺序主要由连接强度决定：

```python
scores_lnk = np.sum(unplaced_lnk_s[:, :self.num_macros][:, self.unplaced_macro_mask], axis=1) \
           + np.sum(unplaced_lnk_s[:, self.num_macros:], axis=1)
scores = scores_lnk
order = self.unplaced_macro_index[np.argsort(scores)]
```

候选点评分主要使用加权距离：

```python
def get_score(_x, _y):
    distance = np.sqrt(np.abs(self.node_x - _x) ** 2 + np.abs(self.node_y - _y) ** 2)
    weighted_distance = lnk_s * distance
    weighted_distance[:self.num_macros][self.unplaced_macro_mask] = 0
    return np.sum(weighted_distance)
```

该方法同样没有显式考虑 critical path。

### 2.7 原始 ReMaP 已有指标

项目自带 `OpenROAD-PPA-evaluation/eval_metadata` 中包含 RTLMP、Hier-RTLMP、DREAMPlace 和 ReMaP 的 PPA 结果。以下数字来自这些真实 metadata。

| Dataset | Baseline | Baseline WNS | ReMaP WNS | WNS 改善 | Baseline TNS | ReMaP TNS | TNS 改善 | WL 变化 |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| ariane133 | RTLMP | -1.10824 | -1.07171 | 3.30% | -2839.00 | -2615.74 | 7.86% | +10.70% |
| ariane136 | RTLMP | -2.07192 | -2.04304 | 1.39% | -6315.44 | -6085.84 | 3.64% | -4.36% |
| bp | RTLMP | -4.97936 | -4.67469 | 6.12% | -1102.72 | -1090.18 | 1.14% | -3.98% |
| bp_be | DREAMPlace | -0.915962 | -0.898607 | 1.89% | -111.727 | -98.003 | 12.28% | +2.43% |
| bp_fe | DREAMPlace | -0.652084 | -0.272749 | 58.17% | -43.2785 | -6.88318 | 84.10% | +2.97% |
| bp_multi | DREAMPlace | -5.94884 | -5.81846 | 2.19% | -6735.01 | -6190.78 | 8.08% | -16.97% |
| bp_quad | DREAMPlace | -1.30537 | -0.926841 | 29.00% | -21669.8 | -14139.2 | 34.75% | +4.57% |
| swerv_wrapper | DREAMPlace | -1.41003 | -1.11854 | 20.67% | -1364.19 | -979.029 | 28.23% | -16.62% |

可以看到，ReMaP 对 WNS/TNS 已经有明显改善，尤其是 bp_fe、bp_quad 和 swerv_wrapper。但也可以看到，部分 case 的 wirelength 会增加，例如 bp_quad 的 WL 增加 4.57%，ariane133 的 WL 增加 10.70%。这说明原始 ReMaP 在时序和线长之间仍存在优化空间。

## 3. 原始方法的局限性

### 3.1 连接强度不等价于时序关键性

原始 ReMaP 中，graph edge weight 主要来自 net weight 或连接结构。连接强的网络会被认为重要，但在时序意义上并不一定重要。例如某些控制信号连接很多 cell，但路径 slack 充足；而某些连接较少的 macro-to-macro 数据路径可能是 setup critical path。若仅靠连接强度，算法可能会把物理资源分配给非关键连接，导致 WNS/TNS 优化效率不足。

### 3.2 Net-level 优化不等价于 path-level 优化

WNS 是最坏路径 slack，TNS 是所有 violating endpoint slack 的累加。它们本质上是 path-level 指标。原始 ReMaP 的 objective 更接近 net-level wirelength 优化：

```text
sum net_weight * net_distance
```

但一条 critical path 由多个 nets 和 cells 串联组成。即使每条 net 都不是特别长，整个 path 的物理跨度仍可能很大。反过来，单独缩短某一条 net，也不一定能显著改善整条 path。

### 3.3 递归固定顺序没有利用 timing priority

ReMaP 的递归过程具有顺序性。越早固定的 macro，对后续布局的影响越大。如果 critical macro 较晚被固定，它可能只能在剩余空间中选择次优位置，从而损害关键路径。而原始排序主要基于 link score，没有显式使用 slack 或 criticality。

### 3.4 候选位置选择过于贪心

GridGuideDistributor 对每个 macro 倾向于选择当前局部最优位置。这种 greedy 策略在宏数量较多、布局区域复杂、通道资源紧张的 case 中容易早期做出不可逆选择。对于 bp_quad 这类大规模 case，早期某个宏的位置可能决定后续多个宏的通道和关键路径走向。

### 3.5 缺少后端 PPA 闭环反馈

真实 WNS/TNS 只有经过 OpenROAD placement、CTS、routing 和 final report 后才能得到。原始 ReMaP 一次性生成 `mp_out`，后端结果只用于评估，没有反向指导下一轮布局。因此，算法无法根据真实 STA 报告自动修正布局策略。

## 4. 本文提出的 TAP-ReMaP 方法

### 4.1 总体思想

TAP-ReMaP 的核心思想是：

> 使用 OpenROAD STA 反馈识别真正影响 WNS/TNS 的 critical paths 和 critical nets，并将这些信息注入 ReMaP 的 graph construction、ABPlacer objective、macro ordering 和 candidate selection 中。

整体流程如下：

```text
Algorithm TAP-ReMaP

Input:
    design files
    baseline ReMaP config
    OpenROAD flow
    iteration budget T

Output:
    optimized mp_out

1. Run baseline ReMaP to generate initial mp_out.
2. Run OpenROAD PPA flow.
3. Extract WNS, TNS, WL, overflow and timing paths.
4. Compute path criticality from slack.
5. Convert path criticality into net criticality and node criticality.
6. Build timing-aware macro graph.
7. Construct critical path hypergraph.
8. Run recursive timing-aware macro placement.
9. Generate new mp_out.
10. Run OpenROAD PPA again.
11. Accept result if WNS/TNS improve and WL guardrail is satisfied.
12. Repeat until iteration budget is exhausted.
```

### 4.2 时序关键性建模

对于 OpenROAD STA 报告中的每条 path，提取 slack：

```text
slack(p)
```

定义 path criticality：

```text
crit(p) = exp(-slack(p) / tau)
```

其中 `tau` 是温度参数。`tau` 越小，算法越关注最差路径；`tau` 越大，算法越平滑地关注更多 near-critical paths。对于负 slack 路径，`crit(p)` 会明显放大。

为了避免单条极端路径支配整个布局，对 criticality 做归一化：

```text
crit_norm(p) = crit(p) / max_p crit(p)
```

对于 net：

```text
crit(e) = sum_{p contains e} crit_norm(p)
crit_norm(e) = crit(e) / max_e crit(e)
```

对于 instance 或 macro：

```text
crit(v) = sum_{p contains v} crit_norm(p)
crit_norm(v) = crit(v) / max_v crit(v)
```

### 4.3 Critical Net Reweighting

原始 graph edge weight：

```text
w_old(e) = base_net_weight(e)
```

TAP-ReMaP 中：

```text
w_new(e) = w_old(e) * (1 + alpha * crit_norm(e))
```

其中 `alpha` 控制时序权重强度。若 `alpha=0`，算法退化为原始 ReMaP；若 `alpha` 太大，算法可能过拟合少数 critical nets，导致全局 WL 恶化。因此实际实验中建议 sweep：

```text
alpha in {1, 2, 4, 8}
```

### 4.4 Critical Path Hypergraph

为了从 net-level 优化提升到 path-level 优化，本文将每条 critical path 转换成一个 hyperedge：

```text
H_p = {v_1, v_2, ..., v_k}
```

其中 `v_i` 可以是 macro，也可以是由 community detection 得到的标准单元 cluster。

定义 path spread：

```text
Spread(H_p) =
    max_x(v in H_p) - min_x(v in H_p)
  + max_y(v in H_p) - min_y(v in H_p)
```

path-level loss：

```text
L_path = sum_p crit_norm(p) * Spread(H_p)
```

该项的物理意义是：关键路径经过的宏和标准单元簇应尽量保持物理紧凑，避免 path 被宏布局拉成长距离。

### 4.5 Timing-Aware ABPlacer Objective

原始 ABPlacer：

```text
L_old =
    L_conn
  + lambda_overlap * L_overlap
```

TAP-ReMaP 改为：

```text
L_new =
    L_conn
  + alpha * L_critical_net
  + beta  * L_path
  + gamma * L_overlap
  + eta   * L_congestion
```

其中：

```text
L_conn = sum_e w_base(e) * distance(e)

L_critical_net = sum_e crit_norm(e) * distance(e)

L_path = sum_p crit_norm(p) * Spread(H_p)

L_overlap = macro overlap penalty

L_congestion = estimated local routing demand penalty
```

若暂时不实现 congestion proxy，可以先使用：

```text
L_new =
    L_conn
  + alpha * L_critical_net
  + beta  * L_path
  + gamma * L_overlap
```

这是第一版最容易落地且最直接影响 WNS/TNS 的版本。

### 4.6 Timing-Aware Macro Ordering

原始 ReMaP 中，宏放置顺序主要来自连接强度。本文改为：

```text
OrderScore(m) =
    a * ConnScore(m)
  + b * CritScore(m)
  + c * PathCentrality(m)
  - d * CongestionRisk(m)
```

其中：

```text
ConnScore(m) = sum_e incident_to_m w_base(e)

CritScore(m) = sum_e incident_to_m crit_norm(e)

PathCentrality(m) = sum_{p contains m} crit_norm(p)

CongestionRisk(m) = estimated demand around m
```

在第一版实现中，可以忽略 congestion risk：

```text
OrderScore(m) =
    ConnScore(m)
  + b * CritScore(m)
  + c * PathCentrality(m)
```

该策略的意义是：先固定 timing-critical macro，让它们优先占据物理上更有利的位置。

### 4.7 Pareto Candidate Selection

原始 GridGuideDistributor 为每个 macro 选择单个局部最优候选点。TAP-ReMaP 改为为每个宏保留 top-k candidates：

```text
C_m = {c_1, c_2, ..., c_k}
```

候选点评分：

```text
Score(c) =
    a * DeltaWL(c)
  + b * DeltaCriticalPath(c)
  + c * CongestionPenalty(c)
  + d * OverlapPenalty(c)
  + e * BoundaryPenalty(c)
```

其中：

```text
DeltaWL(c) = macro 放到 c 后的普通连接距离代价

DeltaCriticalPath(c) = macro 放到 c 后 critical path 物理跨度变化

CongestionPenalty(c) = c 附近 routing demand 或 macro channel 风险

OverlapPenalty(c) = 与已固定 macro 的几何冲突

BoundaryPenalty(c) = 靠近不利边界或 pin access 差的位置惩罚
```

为了控制复杂度，可使用 beam search：

```text
Algorithm BeamCandidateSelection

Input:
    macro order
    candidate set per macro
    beam width B

1. beam = {empty placement}
2. for macro in macro_order:
3.     new_beam = []
4.     for partial_solution in beam:
5.         for candidate in top_k_candidates(macro):
6.             solution = partial_solution + candidate
7.             score = evaluate(solution)
8.             new_beam.append(solution, score)
9.     beam = keep best B solutions from new_beam
10. return best solution in beam
```

如果为了第一版实现简单，也可以先不做完整 beam search，只做单宏 top-k candidate ranking，然后选得分最优者。这仍然比原始单一距离评分更时序感知。

### 4.8 WL Guardrail

由于本文优先优化 WNS/TNS，必须防止算法为了压缩 critical paths 而牺牲过多总线长。定义 baseline WL 为原始 ReMaP 结果：

```text
WL_base = WL(ReMaP)
```

接受新结果的条件：

```text
WL_new <= WL_base * (1 + delta)
```

其中：

```text
delta = 0.03 或 0.05
```

推荐选择规则：

```text
1. 若 TNS 明显改善且 WL 满足 guardrail，接受。
2. 若 TNS 接近，选择 WNS 更好的结果。
3. 若 WNS/TNS 接近，选择 WL 更低的结果。
4. 若 overflow 明显恶化，拒绝。
```

## 5. 关键代码设计

### 5.1 TimingFeedback 数据结构

新增模块：

```text
ReMaP/remap/TimingFeedback.py
```

代码设计：

```python
import math
import json
from collections import defaultdict


class TimingFeedback:
    def __init__(self, tau=0.2, alpha=5.0):
        self.tau = tau
        self.alpha = alpha
        self.paths = []
        self.net_criticality = defaultdict(float)
        self.node_criticality = defaultdict(float)

    def add_path(self, slack, nets, instances):
        criticality = math.exp(-slack / self.tau)
        path = {
            "slack": slack,
            "criticality": criticality,
            "nets": list(nets),
            "instances": list(instances),
        }
        self.paths.append(path)

        for net_name in nets:
            self.net_criticality[net_name] += criticality

        for inst_name in instances:
            self.node_criticality[inst_name] += criticality

    def normalize(self):
        max_net = max(self.net_criticality.values(), default=1.0)
        max_node = max(self.node_criticality.values(), default=1.0)

        if max_net <= 0:
            max_net = 1.0
        if max_node <= 0:
            max_node = 1.0

        for net_name in list(self.net_criticality):
            self.net_criticality[net_name] /= max_net

        for inst_name in list(self.node_criticality):
            self.node_criticality[inst_name] /= max_node

    def net_weight_multiplier(self, net_name):
        criticality = self.net_criticality.get(net_name, 0.0)
        return 1.0 + self.alpha * criticality

    def node_criticality_score(self, inst_name):
        return self.node_criticality.get(inst_name, 0.0)

    def dump(self, path):
        with open(path, "w") as f:
            json.dump(
                {
                    "paths": self.paths,
                    "net_criticality": dict(self.net_criticality),
                    "node_criticality": dict(self.node_criticality),
                },
                f,
                indent=2,
            )
```

### 5.2 OpenROAD Timing Report 解析伪代码

不同 OpenROAD report 格式可能略有差异，因此解析模块需要保持可扩展。伪代码如下：

```text
function parse_timing_report(report_path, max_paths, slack_threshold):
    content = read file
    blocks = split content into timing path blocks
    feedback = TimingFeedback()

    for block in blocks:
        slack = extract slack from block

        if slack is None:
            continue

        if slack > slack_threshold:
            continue

        nets = extract net names from block
        instances = extract instance names from block

        feedback.add_path(slack, nets, instances)

        if number_of_paths reaches max_paths:
            break

    feedback.normalize()
    return feedback
```

实际代码草案：

```python
import re
from remap.TimingFeedback import TimingFeedback


def parse_openroad_timing_report(report_path, max_paths=200, slack_threshold=0.0):
    with open(report_path, "r", encoding="utf-8", errors="ignore") as f:
        content = f.read()

    blocks = re.split(r"\n\s*Startpoint:", content)
    feedback = TimingFeedback()

    for block in blocks:
        slack_match = re.search(r"slack\s+\(?VIOLATED\)?\s+(-?\d+(?:\.\d+)?)", block)
        if not slack_match:
            slack_match = re.search(r"slack.*?(-?\d+(?:\.\d+)?)", block)

        if not slack_match:
            continue

        slack = float(slack_match.group(1))
        if slack > slack_threshold:
            continue

        nets = set(re.findall(r"\bnet[: ]([A-Za-z0-9_./\[\]\\]+)", block))
        instances = set(re.findall(r"\b([A-Za-z0-9_./\[\]\\]+)/(?:[A-Za-z0-9_]+)\b", block))

        feedback.add_path(slack, nets, instances)

        if len(feedback.paths) >= max_paths:
            break

    feedback.normalize()
    return feedback
```

### 5.3 Timing-Aware GraphBuilder

原始 GraphBuilder 中，每条 net 使用原始 weight。修改后：

```python
class TimingAwareGraphBuilder(GraphBuilder):
    def __init__(self, placedb, timing_feedback=None):
        super().__init__(placedb)
        self.timing_feedback = timing_feedback

    def get_net_name(self, net_index):
        net_name = self.net_names[net_index]
        if isinstance(net_name, bytes):
            net_name = net_name.decode("utf-8")
        return net_name

    def get_net_weight(self, net_index):
        if net_index < len(self.net_weights):
            base_weight = self.net_weights[net_index]
        else:
            base_weight = 1.0

        if self.timing_feedback is None:
            return base_weight

        net_name = self.get_net_name(net_index)
        return base_weight * self.timing_feedback.net_weight_multiplier(net_name)

    def add_edges(self):
        for net_index, pins in enumerate(self.net2pin_map):
            weight = self.get_net_weight(net_index)
            connected_nodes = set()

            for pin_id in pins:
                node_index = self.pin2node_map[pin_id]
                connected_nodes.add(node_index)

            if len(connected_nodes) > 1:
                virtual_node_index = self.graph.addNode()
                for node_index in connected_nodes:
                    self.graph.addEdge(virtual_node_index, node_index, weight)
```

该改动的影响是：critical net 在 community detection 和 adjacency matrix 中权重更高，critical macro 与 critical cell cluster 更容易被拉近。

### 5.4 Path Spread Loss

在 ABPlacer 中增加：

```python
def path_spread_loss(node_x, node_y, path_groups, path_weights):
    loss = node_x.new_tensor(0.0)

    for group, weight in zip(path_groups, path_weights):
        if len(group) <= 1:
            continue

        group_x = node_x[group]
        group_y = node_y[group]

        x_span = torch.max(group_x) - torch.min(group_x)
        y_span = torch.max(group_y) - torch.min(group_y)

        loss = loss + weight * (x_span + y_span)

    return loss
```

修改 ABPlacer objective：

```python
obj = torch.tensor(0.0).to(self.device)
obj += weighted_distance
obj += overlap_penalty * l_overlap_penalty

if self.timing_path_groups is not None:
    path_loss = path_spread_loss(
        macro_x,
        macro_y,
        self.timing_path_groups,
        self.timing_path_weights,
    )
    obj += self.path_loss_weight * path_loss
```

### 5.5 Timing-Aware Macro Ordering

新增函数：

```python
def compute_timing_aware_macro_order(
    unplaced_macro_index,
    link_strength,
    macro_names,
    timing_feedback,
    timing_order_weight=5.0,
):
    order_scores = []

    for macro_id in unplaced_macro_index:
        conn_score = float(np.sum(link_strength[macro_id]))

        macro_name = macro_names[macro_id]
        if isinstance(macro_name, bytes):
            macro_name = macro_name.decode("utf-8")

        crit_score = timing_feedback.node_criticality_score(macro_name)
        score = conn_score + timing_order_weight * crit_score

        order_scores.append((macro_id, score))

    order_scores.sort(key=lambda item: item[1], reverse=True)
    return [macro_id for macro_id, score in order_scores]
```

原始代码：

```python
order = self.unplaced_macro_index[np.argsort(scores)]
```

替换为：

```python
if self.timing_feedback is not None:
    order = compute_timing_aware_macro_order(
        self.unplaced_macro_index,
        self.lnk_s,
        self.node_names,
        self.timing_feedback,
    )
else:
    order = self.unplaced_macro_index[np.argsort(scores)]
```

### 5.6 Timing-Aware Candidate Scoring

原始候选点评分：

```python
def get_score(_x, _y):
    distance = np.sqrt(np.abs(self.node_x - _x) ** 2 + np.abs(self.node_y - _y) ** 2)
    weighted_distance = lnk_s * distance
    weighted_distance[:self.num_macros][self.unplaced_macro_mask] = 0
    return np.sum(weighted_distance)
```

修改后：

```python
def get_timing_aware_score(_x, _y, macro_id):
    distance = np.sqrt((self.node_x - _x) ** 2 + (self.node_y - _y) ** 2)

    wl_score = np.sum(self.lnk_s[macro_id] * distance)

    if self.critical_lnk_s is not None:
        timing_score = np.sum(self.critical_lnk_s[macro_id] * distance)
    else:
        timing_score = 0.0

    congestion_score = estimate_congestion_penalty(_x, _y)
    boundary_score = estimate_boundary_penalty(_x, _y)

    return (
        self.wl_weight * wl_score
        + self.timing_candidate_weight * timing_score
        + self.congestion_weight * congestion_score
        + self.boundary_weight * boundary_score
    )
```

第一版可以先实现：

```text
score = wl_score + timing_candidate_weight * timing_score
```

这样改动最小，同时最贴近 WNS/TNS 优化目标。

## 6. 实验设计

### 6.1 测试集

使用项目中已有 8 个 ORFS case：

```text
ariane133
ariane136
black_parrot / bp
bp_be
bp_fe
bp_multi
bp_quad
swerv_wrapper
```

### 6.2 对比方法

```text
1. RTLMP
2. Hier-RTLMP
3. DREAMPlace
4. 原始 ReMaP
5. TAP-ReMaP
```

### 6.3 指标

核心指标：

```text
WNS
TNS
Detailed route wirelength
Global route overflow
Power
Runtime
```

本文优化优先级：

```text
1. TNS
2. WNS
3. WL
4. Overflow
5. Runtime
```

### 6.4 消融实验

为了证明每个模块有效，应设计如下 ablation：

| 方法 | Critical Net Reweighting | Path Hypergraph | Timing Ordering | Candidate Scoring | PPA Feedback |
| --- | --- | --- | --- | --- | --- |
| ReMaP | 否 | 否 | 否 | 否 | 否 |
| TAP-A | 是 | 否 | 否 | 否 | 否 |
| TAP-B | 是 | 是 | 否 | 否 | 否 |
| TAP-C | 是 | 是 | 是 | 否 | 否 |
| TAP-D | 是 | 是 | 是 | 是 | 否 |
| TAP-Full | 是 | 是 | 是 | 是 | 是 |

预期：

```text
TAP-A 主要改善 WNS。
TAP-B 主要改善 TNS。
TAP-C 改善大规模 case 稳定性。
TAP-D 降低 WL regression。
TAP-Full 在 WNS/TNS 上最好，但 runtime 最大。
```

### 6.5 参数设置

建议 sweep：

```text
alpha critical net weight: {1, 2, 4, 8}
beta path loss weight: {0.1, 0.5, 1.0, 2.0}
timing_order_weight: {2, 5, 10}
timing_candidate_weight: {2, 5, 10}
WL guardrail delta: {0.03, 0.05}
```

先在小 case 上搜索：

```text
bp_be
bp_fe
```

再迁移到：

```text
bp_multi
bp_quad
swerv_wrapper
```

## 7. 指标变化分析

### 7.1 原始 ReMaP 相比 baseline 的实际变化

根据项目 metadata，原始 ReMaP 已经带来如下变化：

```text
bp_quad:
    DREAMPlace WNS = -1.30537
    ReMaP WNS      = -0.926841
    WNS 改善       = 29.00%

    DREAMPlace TNS = -21669.8
    ReMaP TNS      = -14139.2
    TNS 改善       = 34.75%

    DREAMPlace WL  = 51924038
    ReMaP WL       = 54296360
    WL 变化        = +4.57%

    DREAMPlace overflow = 28822
    ReMaP overflow      = 4629
    overflow 改善       = 83.94%
```

```text
bp_fe:
    DREAMPlace WNS = -0.652084
    ReMaP WNS      = -0.272749
    WNS 改善       = 58.17%

    DREAMPlace TNS = -43.2785
    ReMaP TNS      = -6.88318
    TNS 改善       = 84.10%

    DREAMPlace WL  = 2577774
    ReMaP WL       = 2654428
    WL 变化        = +2.97%
```

```text
swerv_wrapper:
    DREAMPlace WNS = -1.41003
    ReMaP WNS      = -1.11854
    WNS 改善       = 20.67%

    DREAMPlace TNS = -1364.19
    ReMaP TNS      = -979.029
    TNS 改善       = 28.23%

    DREAMPlace WL  = 5333005
    ReMaP WL       = 4446593
    WL 变化        = -16.62%
```

这些数字说明 ReMaP 的递归宏布局框架本身是有效的，但部分 case 存在 WL 上升。因此 TAP-ReMaP 的目标不是推翻 ReMaP，而是在其成功基础上进一步做时序定向优化。

### 7.2 TAP-ReMaP 的预期指标变化

由于 TAP-ReMaP 尚需实际实现和完整 OpenROAD PPA 验证，本文不将预期值写成已验证结果。建议目标如下：

```text
相对原始 ReMaP：
    WNS 再改善 5% 到 15%
    TNS 再改善 8% 到 20%
    WL 控制在 ReMaP +3% 以内，最好下降
    overflow 不显著恶化
```

例如对 bp_quad，可设定实验目标：

```text
ReMaP:
    WNS = -0.926841
    TNS = -14139.2
    WL  = 54296360

TAP-ReMaP 目标：
    WNS > -0.88
    TNS > -13000
    WL  <= 55925250    # ReMaP WL * 1.03
```

对 bp_fe：

```text
ReMaP:
    WNS = -0.272749
    TNS = -6.88318
    WL  = 2654428

TAP-ReMaP 目标：
    WNS > -0.25
    TNS > -6.0
    WL  <= 2734060    # ReMaP WL * 1.03
```

这些目标是实验验收标准，不是已验证结论。

## 8. 为什么这些优化能改善 WNS/TNS/WL

### 8.1 Critical net reweighting 对 WNS 的作用

WNS 是最差路径 slack。若最差路径中的某些 macro-to-macro 或 macro-to-cluster net 被缩短，则该路径 wire delay 下降，WNS 有机会改善。Critical net reweighting 直接提高这些 nets 在布局目标中的权重，因此 ABPlacer 和 Distributor 会倾向于缩短它们。

### 8.2 Path hypergraph 对 TNS 的作用

TNS 是所有 violating endpoint 的 slack 累加。很多 violating paths 可能共享相同的 macro group 或标准单元 cluster。Path hypergraph 不只是缩短单个 net，而是降低整个 path group 的物理跨度，因此更可能同时改善一组相关 violating paths，从而改善 TNS。

### 8.3 Timing-aware ordering 对递归布局的作用

递归宏布局中的早期决策影响后续空间分配。如果 critical macro 先被放置，它们能够优先占据靠近关键 cell cluster 或关键 I/O 的位置。相反，如果非关键宏先占据这些位置，critical macro 后续可能只能被放到边缘，导致关键路径拉长。

### 8.4 Pareto candidate selection 对 WL 的作用

单纯追求 critical path 可能会拉长普通 nets。Pareto candidate selection 将 WL delta 作为候选点评分的一部分，并通过 WL guardrail 限制最终结果，从而避免 WNS/TNS 改善伴随过大 WL regression。

### 8.5 PPA feedback 对真实指标的作用

placement proxy 与真实后端 STA 不完全一致。PPA feedback loop 让算法根据真实 OpenROAD 结果调整 criticality，使下一轮优化更贴近最终指标。这比纯代理模型更可靠。

## 9. 结论

本文提出 TAP-ReMaP，一种面向 WNS/TNS 与线长联合优化的时序感知递归宏布局方法。原始 ReMaP 已经通过递归 prototyping 和 relocating 显著改善多个 benchmark 的时序与拥塞指标，但其核心优化目标仍偏向 connectivity 和 wirelength proxy。本文进一步引入 OpenROAD STA feedback，将 critical path、critical net 和 slack 信息注入宏布局流程，使宏布局从 connectivity-driven 转向 timing-criticality-driven。

TAP-ReMaP 的主要创新包括：

```text
1. Slack-aware critical net reweighting。
2. Critical path hypergraph loss。
3. Timing-aware recursive macro ordering。
4. Timing-aware candidate scoring。
5. WL guardrail。
6. OpenROAD PPA feedback loop。
```

这些模块共同作用，使算法能够优先优化真正影响 WNS/TNS 的物理结构，同时控制总线长和拥塞风险。基于现有 metadata，原始 ReMaP 已在 bp_quad 上相对 DREAMPlace 带来 29.00% WNS 改善和 34.75% TNS 改善；TAP-ReMaP 的目标是在这一基础上继续提升 WNS/TNS，并将 WL 控制在 ReMaP 结果的 3% 到 5% 范围内。

后续工作应实现上述模块，并通过完整 OpenROAD PPA flow 对 8 个 ORFS case 进行验证，补充 TAP-ReMaP 相比 ReMaP 的最终 WNS、TNS、WL、overflow 和 runtime 实测结果。
