param(
    [switch]$Gpu,
    [string]$VenvPath = ".venv"
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

$pythonCommand = Get-Command python -ErrorAction SilentlyContinue
if (-not $pythonCommand) {
    throw "Python was not found. Install Python 3.10+ and retry."
}

if (-not (Test-Path (Join-Path $VenvPath "Scripts\python.exe"))) {
    python -m venv $VenvPath
}

$python = Join-Path $VenvPath "Scripts\python.exe"
& $python -m pip install --upgrade pip

if ($Gpu) {
    & $python -m pip install -r requirements-gpu-cu124.txt --timeout 120 --retries 5
} else {
    & $python -m pip install -r requirements-cpu.txt --timeout 120 --retries 5
}

& $python -c "import torch; print('PyTorch:', torch.__version__); print('CUDA available:', torch.cuda.is_available())"
