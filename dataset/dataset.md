# MiniMind 数据集

训练数据不随代码仓库提交。请将官方数据文件下载后放入当前目录：

```text
dataset/
├── pretrain_t2t_mini.jsonl
├── sft_t2t_mini.jsonl
├── rlaif.jsonl
└── dpo.jsonl
```

快速复现只需要：

- `pretrain_t2t_mini.jsonl`
- `sft_t2t_mini.jsonl`

可以使用 ModelScope Python API 下载：

```powershell
python -c "from modelscope.hub.snapshot_download import dataset_snapshot_download; dataset_snapshot_download('gongjy/minimind_dataset', allow_file_pattern=['pretrain_t2t_mini.jsonl','sft_t2t_mini.jsonl'], local_dir='dataset')"
```

数据集文件可能较大，已通过 `.gitignore` 排除。提交自有数据前请确认数据授权、隐私和许可证符合要求。
