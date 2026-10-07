# 本地安装与验证指南

## 环境要求

- Python 3.10 或更高版本
- CPU 可运行最小演示；正式训练建议使用 NVIDIA GPU
- Windows 用户建议使用 PowerShell 或 WSL2

## Windows 一键安装

在仓库根目录执行：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\setup_windows.ps1
```

默认安装 CPU 版 PyTorch。如果已安装 NVIDIA 驱动并希望使用 CUDA 12.4：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\setup_windows.ps1 -Gpu
```

安装完成后验证：

```powershell
.\.venv\Scripts\python.exe -c "import torch; print(torch.__version__); print('CUDA:', torch.cuda.is_available())"
```

## 运行最小闭环

该命令使用仓库中的小型演示数据，验证数据读取、预训练、SFT、权重保存和重新加载流程：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_demo.ps1
```

输出权重会写入 `out/`，断点会写入 `checkpoints/`。这些目录已被 Git 忽略。

## 使用官方数据训练

先按照 [数据集说明](../dataset/dataset.md) 下载数据，再执行：

```powershell
cd trainer
..\.venv\Scripts\python.exe train_pretrain.py --data_path ..\dataset\pretrain_t2t_mini.jsonl --save_weight pretrain
..\.venv\Scripts\python.exe train_full_sft.py --data_path ..\dataset\sft_t2t_mini.jsonl --from_weight pretrain --save_weight full_sft
cd ..
.\.venv\Scripts\python.exe eval_llm.py --weight full_sft
```

Linux 或 WSL2 将 `.venv\Scripts\python.exe` 替换为 `.venv/bin/python`，并使用正斜杠路径。

## GitHub 提交边界

应该提交源代码、配置、文档和 `*_demo.jsonl`。不应提交 `.venv/`、`out/`、`checkpoints/`、`*.pth` 或官方大数据集。提交前检查：

```powershell
git status --short --ignored
git diff --check
```
