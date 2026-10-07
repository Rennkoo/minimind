# MiniMind 用户使用指南

这份指南面向第一次使用本项目的用户。你可以先运行一个本地演示，再选择下载官方数据训练，或使用自己的数据训练领域模型。

## 1. 目录说明

```text
minimind/
├── model/          模型结构和 Tokenizer
├── dataset/        数据集目录
├── trainer/        预训练、SFT、LoRA、DPO、RL 训练脚本
├── scripts/        模型转换、安装和演示脚本
├── out/            训练输出权重，运行后生成
├── checkpoints/    断点续训文件，运行后生成
└── eval_llm.py     命令行推理入口
```

## 2. 安装环境

### Windows

在项目根目录打开 PowerShell：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\setup_windows.ps1
```

默认安装 CPU 版 PyTorch。若电脑有 NVIDIA GPU，可以安装 CUDA 版：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\setup_windows.ps1 -Gpu
```

检查环境：

```powershell
.\.venv\Scripts\python.exe -c "import torch; print(torch.__version__); print('CUDA:', torch.cuda.is_available())"
```

### Linux / WSL2

```bash
python3 -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip
pip install -r requirements-cpu.txt
```

如果使用 NVIDIA GPU，可改为：

```bash
pip install -r requirements-gpu-cu124.txt
```

## 3. 第一次运行

无需下载大数据集，直接运行小型演示：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_demo.ps1
```

Linux / WSL2：

```bash
source .venv/bin/activate
cd trainer
python train_pretrain.py --device cpu --hidden_size 128 --num_hidden_layers 2 --batch_size 1 --max_seq_len 64 --num_workers 0 --epochs 1 --data_path ../dataset/pretrain_demo.jsonl --save_weight demo_pretrain
python train_full_sft.py --device cpu --hidden_size 128 --num_hidden_layers 2 --batch_size 1 --max_seq_len 64 --num_workers 0 --epochs 1 --data_path ../dataset/sft_demo.jsonl --from_weight demo_pretrain --save_weight demo_full_sft
```

演示输出会生成在 `out/`，这些文件已被 Git 忽略，不会上传到 GitHub。

## 4. 下载官方数据

快速训练至少需要：

- `pretrain_t2t_mini.jsonl`
- `sft_t2t_mini.jsonl`

下载到 `dataset/`：

```powershell
.\.venv\Scripts\python.exe -c "from modelscope.hub.snapshot_download import dataset_snapshot_download; dataset_snapshot_download('gongjy/minimind_dataset', allow_file_pattern=['pretrain_t2t_mini.jsonl','sft_t2t_mini.jsonl'], local_dir='dataset')"
```

也可以从项目 README 提供的 ModelScope 或 Hugging Face 地址手动下载。完整数据集体积较大，请根据磁盘和显存选择 `mini` 版本或完整版本。

## 5. 从零训练对话模型

### 5.1 预训练

预训练让模型学习文本分布、词语关系和基础知识：

```powershell
cd trainer
..\.venv\Scripts\python.exe train_pretrain.py `
  --data_path ../dataset/pretrain_t2t_mini.jsonl `
  --save_weight pretrain `
  --epochs 2 `
  --device cuda:0
```

没有 CUDA 时改为 `--device cpu`，但速度会明显变慢。

默认输出：

```text
out/pretrain_768.pth
```

### 5.2 指令微调

SFT 让模型学会按照用户指令进行问答：

```powershell
..\.venv\Scripts\python.exe train_full_sft.py `
  --data_path ../dataset/sft_t2t_mini.jsonl `
  --from_weight pretrain `
  --save_weight full_sft `
  --epochs 2 `
  --device cuda:0
cd ..
```

默认输出：

```text
out/full_sft_768.pth
```

### 5.3 断点续训

训练中断后，可以使用：

```powershell
cd trainer
..\.venv\Scripts\python.exe train_pretrain.py --from_resume 1
```

断点文件位于 `checkpoints/`。如果修改了模型维度、数据格式或关键训练参数，不建议直接恢复旧断点。

## 6. 使用模型推理

在项目根目录运行：

```powershell
.\.venv\Scripts\python.exe eval_llm.py --weight full_sft
```

常用参数：

```powershell
.\.venv\Scripts\python.exe eval_llm.py `
  --weight full_sft `
  --max_new_tokens 256 `
  --temperature 0.7 `
  --top_p 0.8 `
  --device cuda:0
```

如果模型权重不在默认 `out/` 目录，可以指定：

```powershell
.\.venv\Scripts\python.exe eval_llm.py --save_dir .\out --weight full_sft
```

## 7. 使用自己的数据

### 7.1 预训练数据格式

创建 `dataset/pretrain_custom.jsonl`：

```jsonl
{"text":"这是第一篇领域文本。"}
{"text":"这是第二篇领域文本，建议保留完整段落和自然上下文。"}
```

每行必须是一个合法 JSON 对象，并包含 `text` 字段。

### 7.2 SFT 数据格式

创建 `dataset/sft_custom.jsonl`：

```jsonl
{"conversations":[{"role":"user","content":"什么是产品 A？"},{"role":"assistant","content":"产品 A 是面向企业用户的知识管理工具。"}]}
{"conversations":[{"role":"user","content":"请用三点介绍产品 A。"},{"role":"assistant","content":"第一，支持知识检索；第二，支持权限管理；第三，支持团队协作。"}]}
```

支持的角色通常包括：`system`、`user`、`assistant` 和 `tool`。

### 7.3 领域训练建议

推荐顺序：

1. 先用通用数据预训练。
2. 再加入通用 SFT 数据。
3. 使用自己的领域 SFT 数据进行验证。
4. 数据量较小时优先使用 LoRA。
5. 数据量足够且希望改变模型能力时，再考虑 Full SFT 或继续预训练。

不要只用少量领域问答覆盖全部训练数据，否则模型容易过拟合并丢失通用能力。

## 8. LoRA 领域微调

LoRA 适合快速训练医疗、法律、产品知识、企业助手等领域模型。它只保存增量参数，不直接修改基础模型。

具体参数可先查看：

```powershell
.\.venv\Scripts\python.exe trainer\train_lora.py --help
```

训练完成后，推理时同时指定基础权重和 LoRA 权重：

```powershell
.\.venv\Scripts\python.exe eval_llm.py --weight full_sft --lora_weight lora_custom
```

如果需要独立模型，可以使用 `scripts/convert_model.py` 中的 LoRA 合并流程。

## 9. 多卡训练

单机多卡可使用 PyTorch DDP：

```bash
cd trainer
torchrun --nproc_per_node=2 train_pretrain.py
```

将 `2` 替换为实际 GPU 数量。多卡训练前确保每张 GPU 的显存、CUDA 和 PyTorch 版本一致。

## 10. 模型转换与部署

MiniMind 支持转换为 Transformers 格式，之后可以接入常见推理生态：

- Transformers
- vLLM
- Ollama
- llama.cpp
- OpenAI 兼容 API
- Streamlit WebUI

转换前请确保已经生成与配置匹配的 `out/full_sft_*.pth`。转换脚本中的默认路径是相对于 `scripts` 目录解析的，因此需要先进入该目录。

转换入口：

```powershell
cd scripts
..\.venv\Scripts\python.exe convert_model.py
cd ..
```

WebUI 入口：

```powershell
cd scripts
..\.venv\Scripts\streamlit.exe run web_demo.py
```

## 11. 常见问题

### CUDA 显示为 False

检查 NVIDIA 驱动、PyTorch CUDA 版本和当前虚拟环境：

```powershell
nvidia-smi
.\.venv\Scripts\python.exe -c "import torch; print(torch.__version__); print(torch.version.cuda); print(torch.cuda.is_available())"
```

如果 PyTorch 版本带有 `+cpu`，说明安装的是 CPU 版，需要重新安装 CUDA 版依赖。

### 显存不足

依次降低：

```text
batch_size
max_seq_len
hidden_size
num_hidden_layers
```

也可以增加 `accumulation_steps`，用梯度累积保持较大的有效 batch size。

### Windows 下数据加载报错

先将：

```text
--num_workers 8
```

改为：

```text
--num_workers 0
```

确认单进程训练正常后，再逐步增加数据加载线程数。

### 训练后回答质量差

优先检查：

- 预训练数据是否过少或重复率过高；
- SFT 数据是否包含高质量答案；
- 训练和推理时模型维度是否一致；
- 是否误用了旧权重或错误的 Tokenizer；
- 是否设置了独立验证集和固定测试问题。

## 12. 文件提交建议

可以提交：

- 源代码；
- 文档；
- `*_demo.jsonl`；
- 依赖文件和安装脚本。

不要提交：

- `.venv/`；
- `out/`；
- `checkpoints/`；
- `*.pth`、`*.safetensors`；
- 未确认许可证的大型数据集；
- API Key、账号密码和本地配置文件。
