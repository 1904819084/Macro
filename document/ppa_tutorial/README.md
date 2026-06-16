# DAC25-ReMaP 从 `mp_out` 到 PPA 指标完整教程

这个目录是给你以后自己复现实验用的。主线分成两步：

1. 用 `ReMaP` 跑 case，生成每个 design 的 `mp_out`。
2. 把 `mp_out` 放到 `OpenROAD-PPA-evaluation/results/nangate45/<design>/ReMaP/mp_out`，再用 Docker 跑 OpenROAD PPA，得到 `WNS`、`TNS`、`Wirelength`、`Power`、`overflow`、`DRC_errors`。

当前这台 macOS 上，ReMaP 本体是本地 Python/C++ CPU 运行；PPA/OpenROAD 建议用 Docker 运行。

## 0. 项目目录

当前项目根目录：

```bash
/Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP
```

ReMaP 算法目录：

```bash
/Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP/ReMaP
```

PPA 目录：

```bash
/Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP/OpenROAD-PPA-evaluation
```

Python 虚拟环境：

```bash
/Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP/.venv
```

## 1. 现在到底是 Docker 还是本地依赖

这份工程现在是混合方式：

- `ReMaP`：本地运行，不需要 CUDA，使用 `.venv` 里的 Python、torch、networkit。
- `OpenROAD PPA`：Docker 运行，使用 `openroad/orfs:latest` 镜像。
- 不需要安装 OpenRouter。OpenRouter 是大模型 API 服务，和这个项目跑 ReMaP/PPA 没关系。

已经验证过的本地依赖：

```text
Python 3.9.6
torch 2.8.0
networkit 11.2
torch.cuda.is_available() = False
```

已经验证过的 Docker 镜像：

```text
openroad/orfs:latest
```

在 Apple Silicon Mac 上需要加：

```bash
--platform linux/amd64
```

## 2. 跑一个 ReMaP case 生成 `mp_out`

进入 ReMaP 目录：

```bash
cd /Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP/ReMaP
```

跑 `bp_be`：

```bash
bash single_case.sh bp_be
```

可选 case：

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

跑全部 case：

```bash
cd /Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP/ReMaP
bash run.sh
```

结果会生成在：

```bash
ReMaP/install/results/YYYYMMDD/<case_name>/<HHMMSS>/
```

例如：

```bash
ReMaP/install/results/20260616/bp_be/124052/mp_out
```

查某个 case 最近生成的 `mp_out`：

```bash
cd /Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP
find ReMaP/install/results -path '*/bp_be/*/mp_out' -type f | sort
```

## 3. 把 `mp_out` 复制到 PPA 需要的位置

PPA 的输入目录格式必须是：

```bash
OpenROAD-PPA-evaluation/results/nangate45/<design>/ReMaP/mp_out
```

case 名和 PPA design 名的对应关系：

```text
ariane133       -> ariane133
ariane136       -> ariane136
black_parrot    -> bp
bp_be           -> bp_be
bp_fe           -> bp_fe
bp_multi        -> bp_multi
bp_quad         -> bp_quad
swerv_wrapper   -> swerv_wrapper
```

单独复制一个 `bp_be`：

```bash
cd /Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP
mkdir -p OpenROAD-PPA-evaluation/results/nangate45/bp_be/ReMaP
cp ReMaP/install/results/20260616/bp_be/124052/mp_out \
  OpenROAD-PPA-evaluation/results/nangate45/bp_be/ReMaP/mp_out
```

如果你所有 case 都已经跑完，可以直接用本教程附带的脚本复制每个 case 最新的 `mp_out`：

```bash
cd /Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP
bash document/ppa_tutorial/scripts/copy_latest_mp_out.sh
```

检查是否都复制好了：

```bash
cd /Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP
find OpenROAD-PPA-evaluation/results/nangate45 -path '*/ReMaP/mp_out' -type f | sort
```

你应该看到：

```text
OpenROAD-PPA-evaluation/results/nangate45/ariane133/ReMaP/mp_out
OpenROAD-PPA-evaluation/results/nangate45/ariane136/ReMaP/mp_out
OpenROAD-PPA-evaluation/results/nangate45/bp/ReMaP/mp_out
OpenROAD-PPA-evaluation/results/nangate45/bp_be/ReMaP/mp_out
OpenROAD-PPA-evaluation/results/nangate45/bp_fe/ReMaP/mp_out
OpenROAD-PPA-evaluation/results/nangate45/bp_multi/ReMaP/mp_out
OpenROAD-PPA-evaluation/results/nangate45/bp_quad/ReMaP/mp_out
OpenROAD-PPA-evaluation/results/nangate45/swerv_wrapper/ReMaP/mp_out
```

## 4. 用 Docker 跑一个 PPA case

先进入 PPA 目录：

```bash
cd /Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP/OpenROAD-PPA-evaluation
```

如果 `docker` 命令找不到，在当前 Mac 上用完整路径：

```bash
/opt/homebrew/bin/docker ps
```

跑 `bp_be` 的 PPA：

```bash
/opt/homebrew/bin/docker run --rm --platform linux/amd64 \
  -v /Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP:/work \
  -w /work/OpenROAD-PPA-evaluation \
  openroad/orfs:latest \
  bash -lc 'source /OpenROAD-flow-scripts/env.sh; unset FLOW_HOME DESIGN_HOME PLATFORM_HOME WORK_HOME UTILS_DIR SCRIPTS_DIR TEST_DIR; make do-2_4_floorplan_macro DESIGN_CONFIG=./designs/nangate45/bp_be_top/config.mk OPENROAD_EXE=/OpenROAD-flow-scripts/tools/install/OpenROAD/bin/openroad YOSYS_CMD=/OpenROAD-flow-scripts/tools/install/yosys/bin/yosys; make do-macroflow DESIGN_CONFIG=./designs/nangate45/bp_be_top/config.mk OPENROAD_EXE=/OpenROAD-flow-scripts/tools/install/OpenROAD/bin/openroad YOSYS_CMD=/OpenROAD-flow-scripts/tools/install/yosys/bin/yosys'
```

这条命令做了两件事：

- `make do-2_4_floorplan_macro`：根据 `mp_out` 做 macro floorplan。
- `make do-macroflow`：继续跑 placement、CTS、routing、report。

本教程也提供了简化脚本。跑 `bp_be`：

```bash
cd /Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP
bash document/ppa_tutorial/scripts/run_ppa_docker.sh bp_be
```

其他 case 同理：

```bash
bash document/ppa_tutorial/scripts/run_ppa_docker.sh ariane133
bash document/ppa_tutorial/scripts/run_ppa_docker.sh ariane136
bash document/ppa_tutorial/scripts/run_ppa_docker.sh bp
bash document/ppa_tutorial/scripts/run_ppa_docker.sh bp_fe
bash document/ppa_tutorial/scripts/run_ppa_docker.sh bp_multi
bash document/ppa_tutorial/scripts/run_ppa_docker.sh bp_quad
bash document/ppa_tutorial/scripts/run_ppa_docker.sh swerv_wrapper
```

注意：`black_parrot` 在 PPA 里叫 `bp`。如果你想跑 black\_parrot 的 PPA，用：

```bash
bash document/ppa_tutorial/scripts/run_ppa_docker.sh bp
```

## 5. 跑全部 PPA case

确认所有 `mp_out` 已经复制好：

```bash
cd /Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP
find OpenROAD-PPA-evaluation/results/nangate45 -path '*/ReMaP/mp_out' -type f | sort
```

然后依次跑：

```bash
cd /Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP
bash document/ppa_tutorial/scripts/run_ppa_docker.sh ariane133
bash document/ppa_tutorial/scripts/run_ppa_docker.sh ariane136
bash document/ppa_tutorial/scripts/run_ppa_docker.sh bp
bash document/ppa_tutorial/scripts/run_ppa_docker.sh bp_be
bash document/ppa_tutorial/scripts/run_ppa_docker.sh bp_fe
bash document/ppa_tutorial/scripts/run_ppa_docker.sh bp_multi
bash document/ppa_tutorial/scripts/run_ppa_docker.sh bp_quad
bash document/ppa_tutorial/scripts/run_ppa_docker.sh swerv_wrapper
```

PPA 会比较慢，建议先跑一个 `bp_be` 验证流程。

## 6. 每个 PPA case 的 config 路径

```text
ariane133      -> ./designs/nangate45/ariane133/config.mk
ariane136      -> ./designs/nangate45/ariane136/config.mk
bp             -> ./designs/nangate45/black_parrot/config.mk
bp_be          -> ./designs/nangate45/bp_be_top/config.mk
bp_fe          -> ./designs/nangate45/bp_fe_top/config.mk
bp_multi       -> ./designs/nangate45/bp_multi_top/config.mk
bp_quad        -> ./designs/nangate45/bp_quad/config.mk
swerv_wrapper  -> ./designs/nangate45/swerv_wrapper/config.mk
```

## 7. PPA 输出文件在哪里

一个 case 跑完以后，看这个目录：

```bash
OpenROAD-PPA-evaluation/logs/nangate45/<design>/ReMaP/
```

例如 `bp_be`：

```bash
OpenROAD-PPA-evaluation/logs/nangate45/bp_be/ReMaP/
```

关键文件：

```text
5_1_grt.log       # global route 日志，里面提取 overflow
5_2_route.json    # detail route 指标，里面提取 wirelength 和 DRC_errors
6_report.json     # final report，里面提取 WNS、TNS、Power
```

检查 `bp_be` 是否跑出了指标文件：

```bash
cd /Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP
ls -lh OpenROAD-PPA-evaluation/logs/nangate45/bp_be/ReMaP/5_1_grt.log
ls -lh OpenROAD-PPA-evaluation/logs/nangate45/bp_be/ReMaP/5_2_route.json
ls -lh OpenROAD-PPA-evaluation/logs/nangate45/bp_be/ReMaP/6_report.json
```

## 8. 提取 WNS、TNS、WL 等指标

本教程提供了标准库版 Python 脚本，不需要 pandas：

```bash
cd /Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP
.venv/bin/python document/ppa_tutorial/scripts/extract_ppa_metrics.py
```

输出文件：

```bash
my_remap_metrics_all.csv
```

这个 CSV 的列是：

```text
Dataset,Method,Wirelength,WNS,TNS,Power,#overflow,DRC_errors
```

每个字段来自哪里：

```text
Wirelength  -> OpenROAD-PPA-evaluation/logs/nangate45/<design>/ReMaP/5_2_route.json
WNS         -> OpenROAD-PPA-evaluation/logs/nangate45/<design>/ReMaP/6_report.json
TNS         -> OpenROAD-PPA-evaluation/logs/nangate45/<design>/ReMaP/6_report.json
Power       -> OpenROAD-PPA-evaluation/logs/nangate45/<design>/ReMaP/6_report.json
#overflow   -> OpenROAD-PPA-evaluation/logs/nangate45/<design>/ReMaP/5_1_grt.log
DRC_errors  -> OpenROAD-PPA-evaluation/logs/nangate45/<design>/ReMaP/5_2_route.json
```

当前已经实测 `bp_be` 跑出了这些指标：

```text
Dataset      = bp_be
Method       = ReMaP
Wirelength   = 3926157
WNS          = -2.39609
TNS          = -1776.96
Power        = 0.107064
#overflow    = 3803
DRC_errors   = 6895
```

如果某个 case 没出现在 CSV 里，说明它缺少下面三个文件中的至少一个：

```text
5_1_grt.log
5_2_route.json
6_report.json
```

可以这样查：

```bash
cd /Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP
find OpenROAD-PPA-evaluation/logs/nangate45/<design>/ReMaP -maxdepth 1 -type f | sort
```

把 `<design>` 换成 `bp_be`、`ariane133` 等。

## 9. Windows 电脑怎么运行

推荐方案是 Windows + WSL2 Ubuntu + Docker Desktop。不要直接在原生 Windows CMD 里编译这个项目，EDA/Python/C++/OpenROAD 相关路径会很麻烦。

### 9.1 安装 WSL2 Ubuntu

在 Windows PowerShell 管理员模式运行：

```powershell
wsl --install -d Ubuntu
```

安装完重启，打开 Ubuntu，设置 Linux 用户名和密码。

### 9.2 安装 Docker Desktop

安装 Docker Desktop for Windows，并打开：

```text
Settings -> Resources -> WSL Integration -> Enable integration with Ubuntu
```

在 Ubuntu 里测试：

```bash
docker ps
docker pull openroad/orfs:latest
```

### 9.3 在 WSL2 里准备项目

推荐把项目放在 WSL2 自己的 Linux 文件系统，例如：

```bash
mkdir -p ~/projects
cd ~/projects
git clone https://github.com/xiaosiCU/DAC25-ReMaP.git
cd DAC25-ReMaP
```

如果你把项目放在 Windows `C:` 盘，路径会变成：

```bash
/mnt/c/Users/<你的用户名>/Documents/DAC25-ReMaP
```

能跑，但通常比 `~/projects/DAC25-ReMaP` 慢。

### 9.4 Windows/WSL2 的 Python 环境

在 Ubuntu 里：

```bash
sudo apt update
sudo apt install -y python3 python3-venv python3-pip git build-essential cmake flex bison libomp-dev pkg-config
cd ~/projects/DAC25-ReMaP
python3 -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip setuptools wheel
python -m pip install torch networkit numpy scipy matplotlib cairocffi
```

验证 CPU torch：

```bash
python - <<'PY'
import torch
import networkit
print("torch:", torch.__version__)
print("cuda available:", torch.cuda.is_available())
print("networkit:", networkit.__version__)
PY
```

期望看到：

```text
cuda available: False
```

### 9.5 Windows/WSL2 跑 ReMaP

```bash
cd ~/projects/DAC25-ReMaP/ReMaP
bash single_case.sh bp_be
```

如果你是在 WSL2 里重新 clone 的原始仓库，可能还没有本机这份 CPU 兼容改动。建议直接把当前这份已经改好的项目整体复制到 Windows，或者把本机改动提交成 git commit 后在 Windows 拉取。

### 9.6 Windows/WSL2 跑 Docker PPA

假设项目在：

```bash
~/projects/DAC25-ReMaP
```

进入项目：

```bash
cd ~/projects/DAC25-ReMaP
```

复制最新 `mp_out`：

```bash
bash document/ppa_tutorial/scripts/copy_latest_mp_out.sh
```

跑 `bp_be` PPA：

```bash
bash document/ppa_tutorial/scripts/run_ppa_docker.sh bp_be
```

如果不用脚本，手写 Docker 命令时 Linux/WSL2 路径写法如下：

```bash
docker run --rm \
  -v ~/projects/DAC25-ReMaP:/work \
  -w /work/OpenROAD-PPA-evaluation \
  openroad/orfs:latest \
  bash -lc 'source /OpenROAD-flow-scripts/env.sh; unset FLOW_HOME DESIGN_HOME PLATFORM_HOME WORK_HOME UTILS_DIR SCRIPTS_DIR TEST_DIR; make do-2_4_floorplan_macro DESIGN_CONFIG=./designs/nangate45/bp_be_top/config.mk OPENROAD_EXE=/OpenROAD-flow-scripts/tools/install/OpenROAD/bin/openroad YOSYS_CMD=/OpenROAD-flow-scripts/tools/install/yosys/bin/yosys; make do-macroflow DESIGN_CONFIG=./designs/nangate45/bp_be_top/config.mk OPENROAD_EXE=/OpenROAD-flow-scripts/tools/install/OpenROAD/bin/openroad YOSYS_CMD=/OpenROAD-flow-scripts/tools/install/yosys/bin/yosys'
```

WSL2/Linux 通常不需要 `--platform linux/amd64`，除非你的电脑也是 ARM 架构。

## 10. 常见问题

### 10.1 `docker: command not found`

macOS 当前机器可以用：

```bash
/opt/homebrew/bin/docker ps
```

或者加环境变量：

```bash
export PATH="/opt/homebrew/bin:$PATH"
```

Windows/WSL2 里需要打开 Docker Desktop 的 WSL Integration。

### 10.2 Docker 没启动

报错类似：

```text
Cannot connect to the Docker daemon
```

解决：先打开 Docker Desktop，等状态变成 Running，再执行：

```bash
docker ps
```

### 10.3 `No such file or directory: mp_out`

说明你还没有把 ReMaP 输出复制到 PPA 输入目录。

执行：

```bash
cd /Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP
bash document/ppa_tutorial/scripts/copy_latest_mp_out.sh
```

再检查：

```bash
find OpenROAD-PPA-evaluation/results/nangate45 -path '*/ReMaP/mp_out' -type f | sort
```

### 10.4 `FLOW_HOME`、`DESIGN_HOME` 等变量污染

OpenROAD Docker 里 `/OpenROAD-flow-scripts/env.sh` 会设置一些变量，但这个仓库自己的 Makefile 也需要自己的路径。Docker 命令里已经加了：

```bash
unset FLOW_HOME DESIGN_HOME PLATFORM_HOME WORK_HOME UTILS_DIR SCRIPTS_DIR TEST_DIR
```

不要删掉这段。

### 10.5 `PDN-0179`

`PDN-0179` 是 PDN repair/power grid 相关警告或错误。当前 `bp_be` 实测出现过，但后续仍然生成了 `5_2_route.json` 和 `6_report.json`，因此可以提取 PPA 指标。

判断是否能用结果，不是只看有没有 `PDN-0179`，而是看这三个文件是否存在：

```text
5_1_grt.log
5_2_route.json
6_report.json
```

### 10.6 `string pointer is null` 或 GUI/save\_image 相关错误

当前工程已经把 final report 里的 GUI 截图保存默认关掉。只有设置：

```bash
ENABLE_SAVE_IMAGES=1
```

才会尝试保存图片。正常跑 PPA 不需要设置它。

### 10.7 缺 `1_synth.v` 或 `2_3_floorplan_tdms.odb`

PPA 需要原作者提供的综合后 netlist/ODB 数据。如果报这些文件缺失，需要确认数据包已经下载并解压到正确目录。

当前本机曾下载过：

```bash
downloads/openroad_ppa_synth_netlists.zip
```

你可以在项目根目录检查：

```bash
cd /Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP
find OpenROAD-PPA-evaluation -name '1_synth.v' -o -name '2_3_floorplan_tdms.odb'
```

## 11. 最推荐的日常命令顺序

只跑一个 `bp_be`：

```bash
cd /Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP/ReMaP
bash single_case.sh bp_be

cd /Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP
bash document/ppa_tutorial/scripts/copy_latest_mp_out.sh
bash document/ppa_tutorial/scripts/run_ppa_docker.sh bp_be
.venv/bin/python document/ppa_tutorial/scripts/extract_ppa_metrics.py
```

跑全部：

```bash
cd /Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP/ReMaP
bash run.sh

cd /Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP
bash document/ppa_tutorial/scripts/copy_latest_mp_out.sh
bash document/ppa_tutorial/scripts/run_ppa_docker.sh ariane133
bash document/ppa_tutorial/scripts/run_ppa_docker.sh ariane136
bash document/ppa_tutorial/scripts/run_ppa_docker.sh bp
bash document/ppa_tutorial/scripts/run_ppa_docker.sh bp_be
bash document/ppa_tutorial/scripts/run_ppa_docker.sh bp_fe
bash document/ppa_tutorial/scripts/run_ppa_docker.sh bp_multi
bash document/ppa_tutorial/scripts/run_ppa_docker.sh bp_quad
bash document/ppa_tutorial/scripts/run_ppa_docker.sh swerv_wrapper
.venv/bin/python document/ppa_tutorial/scripts/extract_ppa_metrics.py
```

