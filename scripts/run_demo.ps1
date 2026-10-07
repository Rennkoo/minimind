param(
    [string]$VenvPath = ".venv"
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

$python = Join-Path (Join-Path $repoRoot $VenvPath) "Scripts\python.exe"
if (-not (Test-Path $python)) {
    throw "Virtual environment not found. Run scripts/setup_windows.ps1 first."
}

Push-Location trainer
try {
    & $python train_pretrain.py --device cpu --dtype bfloat16 --hidden_size 128 --num_hidden_layers 2 --batch_size 1 --max_seq_len 64 --num_workers 0 --epochs 1 --accumulation_steps 1 --log_interval 1 --save_interval 1 --data_path ../dataset/pretrain_demo.jsonl --save_weight demo_pretrain
    & $python train_full_sft.py --device cpu --dtype bfloat16 --hidden_size 128 --num_hidden_layers 2 --batch_size 1 --max_seq_len 64 --num_workers 0 --epochs 1 --accumulation_steps 1 --log_interval 1 --save_interval 1 --data_path ../dataset/sft_demo.jsonl --from_weight demo_pretrain --save_weight demo_full_sft
} finally {
    Pop-Location
}

& $python -c "import torch; from transformers import AutoTokenizer; from model.model_minimind import MiniMindConfig, MiniMindForCausalLM; tokenizer=AutoTokenizer.from_pretrained('model'); config=MiniMindConfig(hidden_size=128,num_hidden_layers=2,max_position_embeddings=512); model=MiniMindForCausalLM(config); model.load_state_dict(torch.load('out/demo_full_sft_128.pth',map_location='cpu')); inputs=tokenizer('你好',return_tensors='pt')['input_ids']; output=model.generate(inputs,max_new_tokens=4,do_sample=False); print(tokenizer.decode(output[0].tolist()))"
