# [DAC'25] ReMaP: Towards Expert-Quality Macro Placement by Recursively Prototyping and Relocating
This repository contains the code for ReMaP, a macro placement framework that generates expert-quality macro layout recursively with novel and well-designed flow of prototyping and relocating. Compared to state-of-the-art macro placers, ReMaP achieves the best WNS and TNS metrics across the eight test cases from the popular OpenROAD-flow-scripts (ORFS) infrastructure, with improvements of up to 34.15% in WNS and 65.39% in TNS.

We provide both implementation of our ReMaP framework, and the full scripts including evaluation metadata to replicate the **main table** in our paper.

## Quick Access to Our Meta-data and Results

Get the code and put it in folder `DAC25-ReMaP`.

```
git clone https://github.com/xiaosinju/DAC25-ReMaP.git
```

**Two line of code to replicate the main table:**

```
cd DAC25-ReMaP
python OpenROAD-PPA-evaluation/get_metrics.py
```

The results is presented at `DAC25-ReMaP/main_table.csv`.

| Dataset | Method     | Wirelength | WNS      | TNS      | Power   | #overflow |
| ------- | ---------- | ---------- | -------- | -------- | ------- | --------- |
| bp_quad | RTLMP      | 55350882   | -1.403   | -22767.7 | 1.80286 | 161655    |
| bp_quad | Hier-RTLMP | 44684974   | -0.99448 | -16445.8 | 1.80491 | 11330     |
| bp_quad | DREAMPlace | 51924038   | -1.30537 | -21669.8 | 1.82423 | 28822     |
| bp_quad | ReMaP      | 54296360   | -0.92684 | -14139.2 | 1.81184 | 4629      |
| ...     | ...        | ...        | ...      | ...      | ...     | ...       |

You can also access our evaluation meta-data of all baselines at `DAC25-ReMaP/OpenROAD-PPA-evaluation/eval_metadata`.

## Run ReMaP Algorithm

Below we provide detailed scripts to run the proposed ReMaP algorithm.

### Build with Docker

We highly recommend the use of Docker to enable a smooth environment configuration.

The following steps are borrowed from [DREAMPlace](https://github.com/limbo018/DREAMPlace) repository. We make minor revisions to make it more clear.

1. To ReMaP directory:

   ```
   cd ReMaP

2. Get the container:

- Option 1: pull from the cloud [limbo018/dreamplace](https://hub.docker.com/r/limbo018/dreamplace).

  ```
  docker pull limbo018/dreamplace:cuda
  ```

- Option 2: build the container.

  ```
  docker build . --file Dockerfile --tag your_name/dreamplace:cuda
  ```

3. Make sure you are in root directory of `ReMaP` (e.g. `/path-to-DAC25-ReMaP/ReMaP`). Enter bash environment of the container. Replace `limbo018` with your name if option 2 is chosen in the previous step.

   ```
   sudo docker run --gpus=all -it -v $(pwd):/workspace limbo018/dreamplace:cuda bash
   ```

4. Build.

   ```
   mkdir build
   cd build
   cmake .. -DCMAKE_INSTALL_PREFIX=../install
   make
   ```
   
5. We don't run `make install` here since we have to get benchmarks first. It is included in our following bash scripts.

### Get Benchmarks

In our experiments, we test our framework on cases from OpenROAD-flow-scripts (ORFS) [[Ajayi et al., DAC'19](https://github.com/The-OpenROAD-Project/OpenROAD-flow-scripts)], containing

- ariane133
- ariane136
- black_parrot
- bp_be
- bp_fe
- bp_multi
- bp_quad
- swerv_wrapper

We run ORFS to generate the synthesized netlist and dump DEFs for our placement task. You can download the cases [here](https://drive.google.com/file/d/1AilCFLZIBDdvmsS2VWqO9ttqNIopNnTq/view?usp=sharing).

Then unzip the package and put it under following the directory:

```
DAC25-ReMaP/ReMaP/benchmarks/
```

### Run Macro Placement Task

You can run our experiment on all 8 cases with shell script:

```
bash run.sh
```

Or, you can run single case by (ariane133 for example):

```
bash single_case.sh ariane133
```

The macro placement results are stored at the following directory:

```
DAC25-ReMaP/ReMaP/install/results/${date}/${design_name}/${time}
```

## Run OpenROAD-flow-scripts for PPA Evaluation

To evaluate PPA of the macro placement results, we provide all the scripts needed for replication.

### Installation

The installation of OpenROAD is required. We recommend use the [pre-built binary](https://openroad-flow-scripts.readthedocs.io/en/latest/user/BuildWithPrebuilt.html).

### Dataset Preparation

Assuming OpenROAD has been properly installed and the environment has been enabled, we should first prepare the synthesized netlist. Download the package [here](https://drive.google.com/file/d/1uweb4zQipCkS4b3uy_84UXch8XKfK8nd/view?usp=sharing) and unzip it under the following directory:

``` 
DAC25-ReMaP/OpenROAD-PPA-evaluation/
```

Then we put the previous generated macro placement result into the directory accordingly.

Macro placement result directory: `DAC25-ReMaP/ReMaP/install/results/${date}/${design_name}/${time}/mp_out`

Target directory: `DAC25-ReMaP/OpenROAD-PPA-evaluation/results/nangate45/${design_name}/ReMaP/mp_out`

If you failed to generate macro placement results, while wishing to run the evaluation scripts, we provide ours (which are exactly generated by the ReMaP code) under the following directory: `DAC25-ReMaP/ReMaP/benchmarks/or_cases/${design_name}/mp_out`. You can put it under the target directory.

### Run test

Run the evaluation script through the following bash script:

```
bash run-or.sh
```

To run specified cases, just modify the `run-or.sh` file.
