# 发布到自己的 GitHub 仓库

当前目录仍保留原项目的 `origin` 地址。请先在 GitHub 创建一个新的空仓库，不要勾选初始化 README、License 或 `.gitignore`。

在仓库根目录执行：

```powershell
git remote -v
git remote set-url origin https://github.com/<你的用户名>/<你的仓库名>.git
git add .
git diff --cached --check
git commit -m "prepare local MiniMind reproduction"
git push -u origin master
```

如果你的 GitHub 默认分支使用 `main`，可以执行：

```powershell
git branch -M main
git push -u origin main
```

推送前确认没有将 `.venv/`、`out/`、`checkpoints/`、`*.pth` 或大数据集加入暂存区：

```powershell
git status --short
git diff --cached --stat
```

如果希望保留上游仓库用于同步，可以将原地址改名为 `upstream`，再把自己的仓库设置为 `origin`：

```powershell
git remote rename origin upstream
git remote add origin https://github.com/<你的用户名>/<你的仓库名>.git
```
