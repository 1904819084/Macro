# DAC25-ReMaP CPU 版运行手册

本文档记录当前这份 `DAC25-ReMaP` 项目如何在本机运行，以及换到 Windows 电脑时如何重新搭环境运行。当前项目已经改成默认不需要 CUDA，使用 CPU 跑。

## 1. 当前项目位置

当前 macOS 机器上的项目根目录是：

```bash
/Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP
```

ReMaP 算法目录是：

```bash
/Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP/ReMaP
```

Python 虚拟环境目录是：

```bash
/Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP/.venv
```

benchmark 数据目录是：

```bash
/Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP/ReMaP/benchmarks/or_cases
```

已经验证过的依赖版本：

```text
Python 3.9.6
torch 2.8.0
networkit 11.2
torch.cuda.is_available() = False
```

## 2. 这份项目是本地运行，不是 Docker

当前这份工程使用本机依赖运行：

- Python 包安装在 `.venv`
- C++/CMake 产物安装到 `ReMaP/install`
- benchmark 数据放在 `ReMaP/benchmarks/or_cases`
- 没有用 Docker 容器

README 里推荐 Docker 是原作者方案，但当前这台机器上跑通的是本地 CPU 方案。

## 3. macOS 本机如何跑单个 case

进入 ReMaP 目录：

```bash
cd /Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP/ReMaP
```

跑单个 case，例如 `bp_be`：

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

例如跑 `ariane133`：

```bash
bash single_case.sh ariane133
```

例如跑 `bp_quad`：

```bash
bash single_case.sh bp_quad
```

## 4. macOS 本机如何跑全部 case

进入 ReMaP 目录：

```bash
cd /Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP/ReMaP
```

执行：

```bash
bash run.sh
```

`run.sh` 当前会依次跑：

```text
ariane133
ariane136
black_parrot
bp_be
bp_fe
bp_multi
swerv_wrapper
bp_quad
```

全量运行会比较久，建议先用 `single_case.sh bp_be` 或 `single_case.sh ariane133` 验证环境。

## 5. 运行结果在哪里

结果目录格式：

```bash
ReMaP/install/results/YYYYMMDD/<case_name>/<HHMMSS>/
```

例如：

```bash
/Users/bytedance/Documents/trae_projects/Remap/DAC25-ReMaP/ReMaP/install/results/20260616/bp_be/112313/
```

常看这些文件：

```text
<case_name>.gp.def
mp_out
gp.png
layout.png
runtime.json
```

例如 `bp_be`：

```text
bp_be.gp.def
mp_out
gp.png
layout.png
runtime.json
```

## 6. macOS 脚本里设置了哪些环境变量

`ReMaP/single_case.sh` 和 `ReMaP/run.sh` 会自动设置这些变量：

```bash
script_dir="$(cd "$(dirname "$0")" && pwd)"
python_bin="${script_dir}/../.venv/bin/python"
cmake_bin="${script_dir}/../.venv/bin/cmake"

export PATH="/opt/homebrew/opt/flex/bin:/opt/homebrew/opt/bison/bin:${script_dir}/../.venv/bin:${PATH}"
export MPLCONFIGDIR="${script_dir}/../.matplotlib"
export DYLD_FALLBACK_LIBRARY_PATH="/opt/homebrew/opt/cairo/lib:/opt/homebrew/lib:${DYLD_FALLBACK_LIBRARY_PATH}"
export PKG_CONFIG_PATH="/opt/homebrew/opt/cairo/lib/pkgconfig:/opt/homebrew/opt/libpng/lib/pkgconfig:/opt/homebrew/opt/freetype/lib/pkgconfig:/opt/homebrew/opt/fontconfig/lib/pkgconfig:/opt/homebrew/opt/pixman/lib/pkgconfig:${PKG_CONFIG_PATH}"
export LDFLAGS="-L/opt/homebrew/opt/libomp/lib -L/opt/homebrew/opt/bison/lib -L/opt/homebrew/opt/flex/lib ${LDFLAGS}"
export CPPFLAGS="-I/opt/homebrew/opt/libomp/include -I/opt/homebrew/opt/flex/include ${CPPFLAGS}"
export CFLAGS="-I/opt/homebrew/opt/libomp/include -I/opt/homebrew/opt/flex/include ${CFLAGS}"
export CXXFLAGS="-I/opt/homebrew/opt/libomp/include -I/opt/homebrew/opt/flex/include ${CXXFLAGS}"
```

这些变量的作用：

- `PATH`: 让脚本优先使用 Homebrew 的 `flex`、`bison` 和项目 `.venv` 里的 Python/CMake。
- `MPLCONFIGDIR`: 把 matplotlib 缓存放到项目目录，避免写 `/Users/bytedance/.matplotlib` 权限失败。
- `DYLD_FALLBACK_LIBRARY_PATH`: 让 `cairocffi` 找到 Homebrew 的 `libcairo.2.dylib`。
- `PKG_CONFIG_PATH`: 让 CMake/pkg-config 找到 Cairo、libpng、freetype、fontconfig、pixman。
- `LDFLAGS`/`CPPFLAGS`/`CFLAGS`/`CXXFLAGS`: 让编译器和链接器找到 Homebrew 的 OpenMP、bison、flex。

正常情况下你不需要手动 export，直接跑脚本即可。

## 7. macOS 如果从零开始重装依赖

如果换一台 macOS，推荐步骤如下。

安装 Homebrew 后，安装系统依赖：

```bash
brew install cmake ninja boost bison flex libomp cairo libpng freetype fontconfig pixman
```

进入项目根目录：

```bash
cd /path/to/DAC25-ReMaP
```

创建 Python 虚拟环境：

```bash
python3 -m venv .venv
source .venv/bin/activate
```

升级基础工具：

```bash
python -m pip install -U pip wheel setuptools
```

安装 Python 依赖：

```bash
python -m pip install torch networkit numpy scipy shapely matplotlib cairocffi pkgconfig pyunpack patool cmake ninja
```

确认依赖：

```bash
python - <<'PY'
import torch
import networkit as nk
import cairocffi
print("torch", torch.__version__)
print("cuda_available", torch.cuda.is_available())
print("networkit", nk.__version__)
print("cairocffi ok")
PY
```

benchmark 数据必须存在：

```bash
ls ReMaP/benchmarks/or_cases
```

应至少看到：

```text
ariane133
ariane136
black_parrot
bp_be
bp_fe
bp_multi
bp_quad
swerv_wrapper
nangate45
```

然后运行：

```bash
cd ReMaP
bash single_case.sh bp_be
```

## 8. Windows 电脑推荐方案：WSL2 Ubuntu

不建议在原生 Windows CMD/PowerShell 里直接跑这个项目。原因：

- 项目依赖 CMake/C++ extension
- 依赖 Linux/macOS 风格 shell 脚本
- 依赖 EDA/C++ 工具链
- 原生 Windows 上处理 Cairo、OpenMP、动态库和编译器会很麻烦

推荐在 Windows 上安装 WSL2 + Ubuntu，然后在 Ubuntu 里跑。

## 9. Windows 上安装 WSL2

在 Windows PowerShell 里以管理员身份执行：

```powershell
wsl --install -d Ubuntu-22.04
```

安装完成后重启电脑。

打开 Ubuntu 终端，第一次会让你创建 Linux 用户名和密码。

确认 WSL 版本：

```powershell
wsl -l -v
```

建议看到 Ubuntu 的版本是 `2`。

如果不是 WSL2：

```powershell
wsl --set-version Ubuntu-22.04 2
```

## 10. Windows/WSL2 里准备项目代码

推荐把项目放在 WSL 的 Linux 文件系统里，不要放在 `/mnt/c/...` 下。这样编译和文件 IO 会快很多。

在 WSL Ubuntu 里：

```bash
mkdir -p ~/projects
cd ~/projects
```

有两种方式放代码。

### 方式 A：复制当前已经改好的项目

把当前 macOS 上的 `DAC25-ReMaP` 整个文件夹复制到 Windows，再复制进 WSL 的：

```bash
~/projects/DAC25-ReMaP
```

注意：不要复用 macOS 的 `.venv`、`ReMaP/build`、`ReMaP/install` 到 Linux 上。它们是 macOS 编译产物，Linux 需要重建。

复制后建议删除这些目录：

```bash
cd ~/projects/DAC25-ReMaP
rm -rf .venv ReMaP/build ReMaP/install build build_cpu
```

如果你不想删 `ReMaP/benchmarks/or_cases`，可以保留，它是数据。

### 方式 B：重新 clone 仓库

```bash
cd ~/projects
git clone https://github.com/xiaosiCU/DAC25-ReMaP.git
cd DAC25-ReMaP
```

注意：原仓库没有当前这份 CPU 修改。你需要把当前修改过的文件同步过去，至少包括：

```text
ReMaP/dreamplace/Placer.py
ReMaP/dreamplace/params.json
ReMaP/dreamplace/PlaceDB.py
ReMaP/remap/device.py
ReMaP/single_case.sh
ReMaP/run.sh
```

更稳妥的做法是：在当前机器把修改 commit 到自己的分支，然后 Windows 上 clone 你的分支。

## 11. Windows/WSL2 安装系统依赖

在 WSL Ubuntu 中执行：

```bash
sudo apt update
sudo apt install -y \
  git \
  build-essential \
  cmake \
  ninja-build \
  bison \
  flex \
  libboost-all-dev \
  libomp-dev \
  libcairo2-dev \
  libfontconfig1-dev \
  libfreetype6-dev \
  libpng-dev \
  libpixman-1-dev \
  pkg-config \
  python3 \
  python3-venv \
  python3-pip \
  unzip \
  wget \
  curl
```

确认工具：

```bash
cmake --version
gcc --version
bison --version
flex --version
pkg-config --modversion cairo
```

`pkg-config --modversion cairo` 应该输出 Cairo 版本号。

## 12. Windows/WSL2 创建 Python 环境

进入项目根目录：

```bash
cd ~/projects/DAC25-ReMaP
```

创建虚拟环境：

```bash
python3 -m venv .venv
source .venv/bin/activate
```

升级基础工具：

```bash
python -m pip install -U pip wheel setuptools
```

安装 Python 包：

```bash
python -m pip install torch networkit numpy scipy shapely matplotlib cairocffi pkgconfig pyunpack patool cmake ninja
```

如果 `networkit` 安装失败，可以尝试：

```bash
python -m pip install --no-build-isolation networkit
```

验证：

```bash
python - <<'PY'
import torch
import networkit as nk
import cairocffi
print("torch", torch.__version__)
print("cuda_available", torch.cuda.is_available())
print("networkit", nk.__version__)
print("cairocffi ok")
PY
```

期望：

```text
cuda_available False
cairocffi ok
```

## 13. Windows/WSL2 准备 benchmark 数据

benchmark 数据必须在：

```bash
~/projects/DAC25-ReMaP/ReMaP/benchmarks/or_cases
```

如果你是复制当前整个项目过去，并且保留了 `ReMaP/benchmarks/or_cases`，这一步可以跳过。

如果需要重新下载，README 中的 ReMaP benchmark 包来自 Google Drive。当前本机下载后的压缩包名是：

```text
downloads/remap_benchmarks.zip
```

你可以把这个 zip 复制到 Windows/WSL2 的项目里，然后解压：

```bash
cd ~/projects/DAC25-ReMaP
mkdir -p ReMaP/benchmarks
unzip downloads/remap_benchmarks.zip -d ReMaP/benchmarks
```

解压后确认：

```bash
find ReMaP/benchmarks/or_cases -maxdepth 2 -name "*.def" | sort
```

应看到 8 个 `.def`：

```text
ReMaP/benchmarks/or_cases/ariane133/ariane133.def
ReMaP/benchmarks/or_cases/ariane136/ariane136.def
ReMaP/benchmarks/or_cases/black_parrot/black_parrot.def
ReMaP/benchmarks/or_cases/bp_be/bp_be.def
ReMaP/benchmarks/or_cases/bp_fe/bp_fe.def
ReMaP/benchmarks/or_cases/bp_multi/bp_multi.def
ReMaP/benchmarks/or_cases/bp_quad/bp_quad.def
ReMaP/benchmarks/or_cases/swerv_wrapper/swerv_wrapper.def
```

## 14. Windows/WSL2 运行前环境变量

Linux/WSL2 不需要 macOS 的 `DYLD_FALLBACK_LIBRARY_PATH`。推荐设置这些：

```bash
cd ~/projects/DAC25-ReMaP
source .venv/bin/activate

export MPLCONFIGDIR="$PWD/.matplotlib"
export PKG_CONFIG_PATH="/usr/lib/x86_64-linux-gnu/pkgconfig:/usr/share/pkgconfig:${PKG_CONFIG_PATH}"
export LD_LIBRARY_PATH="/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH}"
export OMP_NUM_THREADS="$(nproc)"
```

含义：

- `MPLCONFIGDIR`: matplotlib 缓存目录。
- `PKG_CONFIG_PATH`: 让 CMake/pkg-config 找到系统库。
- `LD_LIBRARY_PATH`: 让运行时找到 Linux 动态库。
- `OMP_NUM_THREADS`: OpenMP 线程数，通常设成 CPU 核心数。

可以把这些写进 `~/.bashrc`，但第一次建议手动 export，便于排查。

## 15. Windows/WSL2 编译和运行

进入 ReMaP 目录：

```bash
cd ~/projects/DAC25-ReMaP/ReMaP
```

如果你使用的是当前这份 macOS 脚本，里面有 `/opt/homebrew/...`，在 WSL2 中不适用。推荐新建 Linux 专用脚本 `single_case_linux.sh`：

```bash
cat > single_case_linux.sh <<'SH'
#!/usr/bin/env bash
set -e

script_dir="$(cd "$(dirname "$0")" && pwd)"
python_bin="${script_dir}/../.venv/bin/python"
cmake_bin="${script_dir}/../.venv/bin/cmake"

export MPLCONFIGDIR="${script_dir}/../.matplotlib"
export PKG_CONFIG_PATH="/usr/lib/x86_64-linux-gnu/pkgconfig:/usr/share/pkgconfig:${PKG_CONFIG_PATH}"
export LD_LIBRARY_PATH="/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH}"
export OMP_NUM_THREADS="${OMP_NUM_THREADS:-$(nproc)}"

orig="$(pwd)"
cd "${script_dir}"
mkdir -p build
cd build

if [ ! -f Makefile ]; then
    "${cmake_bin}" .. \
        -DCMAKE_INSTALL_PREFIX=../install \
        -DPython_EXECUTABLE="${python_bin}" \
        -DCMAKE_POLICY_VERSION_MINIMUM=3.5
fi

make -j"$(nproc)"
make -j"$(nproc)" install

cd ../install
for design in "$@"
do
    "${python_bin}" dreamplace/Placer.py "test/or_cases/${design}.json"
done

cd "${orig}"
SH

chmod +x single_case_linux.sh
```

跑单个 case：

```bash
./single_case_linux.sh bp_be
```

跑另一个 case：

```bash
./single_case_linux.sh ariane133
```

## 16. Windows/WSL2 跑全部 case

可以新建 `run_linux.sh`：

```bash
cat > run_linux.sh <<'SH'
#!/usr/bin/env bash
set -e

script_dir="$(cd "$(dirname "$0")" && pwd)"
designs=("ariane133" "ariane136" "black_parrot" "bp_be" "bp_fe" "bp_multi" "swerv_wrapper" "bp_quad")

for design in "${designs[@]}"
do
    "${script_dir}/single_case_linux.sh" "${design}"
done
SH

chmod +x run_linux.sh
```

执行：

```bash
./run_linux.sh
```

全量 case 会跑很久，建议先单独跑一个 case 验证。

## 17. Windows/WSL2 结果目录

结果在：

```bash
~/projects/DAC25-ReMaP/ReMaP/install/results/YYYYMMDD/<case_name>/<HHMMSS>/
```

查看最近结果：

```bash
find ~/projects/DAC25-ReMaP/ReMaP/install/results -maxdepth 4 -type f | sort | tail -50
```

## 18. 常见错误和解决

### 18.1 cairocffi 找不到 cairo

报错类似：

```text
OSError: no library called "cairo-2" was found
cannot load library 'libcairo.2.dylib'
```

macOS 解决：

```bash
brew install cairo
export DYLD_FALLBACK_LIBRARY_PATH="/opt/homebrew/opt/cairo/lib:/opt/homebrew/lib:${DYLD_FALLBACK_LIBRARY_PATH}"
```

当前 `single_case.sh` 已经内置这个变量。

WSL2/Ubuntu 解决：

```bash
sudo apt install -y libcairo2-dev pkg-config
export LD_LIBRARY_PATH="/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH}"
```

验证：

```bash
python - <<'PY'
import cairocffi
print("cairocffi ok")
PY
```

### 18.2 Matplotlib 无法写缓存

报错类似：

```text
mkdir -p failed for path ~/.matplotlib
Fontconfig error: No writable cache directories
```

解决：

```bash
export MPLCONFIGDIR="$PWD/.matplotlib"
mkdir -p "$MPLCONFIGDIR"
```

当前 macOS 脚本已经内置：

```bash
export MPLCONFIGDIR="${script_dir}/../.matplotlib"
```

### 18.3 误用了系统 Python

症状：

```text
ModuleNotFoundError: No module named torch
ModuleNotFoundError: No module named networkit
```

解决：使用项目 `.venv`：

```bash
cd /path/to/DAC25-ReMaP
source .venv/bin/activate
which python
python -c "import torch, networkit; print('ok')"
```

期望 `which python` 指向：

```text
/path/to/DAC25-ReMaP/.venv/bin/python
```

### 18.4 找不到 benchmark

报错可能类似：

```text
No such file or directory: benchmarks/or_cases/...
```

确认目录：

```bash
ls ReMaP/benchmarks/or_cases
```

必须有：

```text
ariane133
ariane136
black_parrot
bp_be
bp_fe
bp_multi
bp_quad
swerv_wrapper
nangate45
```

### 18.5 脚本从错误目录执行

推荐总是这样执行：

```bash
cd /path/to/DAC25-ReMaP/ReMaP
bash single_case.sh bp_be
```

不要在 `ReMaP/install` 里直接执行，除非你已经手动设置好所有环境变量。

### 18.6 仍然出现 CUDA 相关问题

当前项目默认 CPU：

```json
"gpu": {
    "default": 0
}
```

位置：

```text
ReMaP/dreamplace/params.json
```

运行时可检查：

```bash
cd /path/to/DAC25-ReMaP
.venv/bin/python - <<'PY'
import torch
print(torch.cuda.is_available())
PY
```

期望输出：

```text
False
```

## 19. 最小验证清单

每次换机器后，按顺序验证：

```bash
cd /path/to/DAC25-ReMaP
source .venv/bin/activate
```

验证 Python 包：

```bash
python - <<'PY'
import torch
import networkit as nk
import cairocffi
print("torch", torch.__version__)
print("cuda_available", torch.cuda.is_available())
print("networkit", nk.__version__)
print("cairocffi ok")
PY
```

验证 benchmark：

```bash
find ReMaP/benchmarks/or_cases -maxdepth 2 -name "*.def" | sort
```

验证单 case：

macOS：

```bash
cd ReMaP
bash single_case.sh bp_be
```

WSL2/Linux：

```bash
cd ReMaP
./single_case_linux.sh bp_be
```

验证输出：

```bash
find install/results -maxdepth 4 -type f | sort | tail -30
```

看到 `.gp.def`、`mp_out`、`gp.png`、`layout.png`、`runtime.json` 就说明流程跑起来了。

