# 🛠️ Group 12 GitHub Guide

This guide keeps our team organized and prevents us from breaking each other's code.

---

## 💡 Concept Guide for Beginners

If you are new to Git, here are two simple definitions you must know:

* **What is a Feature?** A "feature" is simply a specific task, screen, or functional part of the app you are working on (e.g., building the login screen, fixing a bug, or adding the Firestore database connection).
* **What is a Branch?** Think of a branch as a private, cloned copy of the project's codebase. It allows you to write and test your code safely without affecting the main project until your work is fully ready and approved.

---

## 📌 1. Our Branches

* **`main`** — Production code. **Never touch or commit here directly!** ❌
* **`develop`** — Our main working area. Everything gets merged here first.
* **`feature/your-task-name`** — Your personal branch for your current task.

---

## 🌿 2. Step-by-Step Workflow

### 👉 Step A: Start a new task
Before you write any code, switch to develop, grab the latest changes from the team, and create your own personal branch:
```bash
git checkout develop
git pull origin develop
git checkout -b feature/your-task-name
``` 
### 👉 Step B: Save and push your work
Once you finish writing code, save it locally and upload it to GitHub:
```
git add .
git commit -m "feature: short description of what you did"
git push origin feature/your-task-name
```
### 🔀 3. Pull Request (PR) Rules
✅ Target Branch: Always merge your branch into develop (never straight into main).

✅ Review: At least 1 team member (Shehan) must check and approve your code before it gets merged.

✅ Local Check: Run your app locally to make sure it compiles with no errors before making a PR (Pull Request).

### 4.Commit Message Rules
To keep our history clean and searchable, always use these prefixes for your commit messages based on what you are doing:
```
**feat** (Adding a new feature or code) : git commit -m "feat: add facebook login button"
```
```
**fix** (Fixing a bug or build error) : git commit -m "fix: resolve firebase storage android crash"
```
```
**docs** (Documentation changes only) : git commit -m "docs: update github guide"
```
```
**style** (UI formatting, colors, padding changes) : git commit -m "style: change login button background to blue"
```
```
**refactor** (Rewriting code without changing how it works) : git commit -m "refactor: clean up firestore initialization"
```


### 🤖 5. GitHub Actions Plan
Phase 1: Auto-run code checks (flutter analyze) on every PR to catch formatting errors.

Phase 2: Auto-build test APKs later on.


## If things go wrong, stay calm! Use these terminal fixes
## 🚨 5. How to Fix Common Mistakes


### ❓ Mistake 1: You committed code directly to develop or main

👉 The Fix: Undo the accidental commit while keeping your code safe, then move it to a proper feature branch:
```
git reset --soft HEAD~1
git checkout -b feature/your-task-name
git commit -m "feat: your commit message"
```

### ❓ Mistake 2: You wrote code on the WRONG feature branch

👉 The Fix: Stash (hide) your uncommitted work, switch to the correct branch, and pop it back out:
```
git stash
git checkout feature/correct-branch-name
git stash pop
```

### ❓ Mistake 3: Your branch has "Merge Conflicts" on GitHub
👉 The Fix: Sync your local files with develop and fix conflicting lines in your IDE
```
git checkout develop
git pull origin develop
git checkout feature/your-task-name
git merge develop

Open your code editor, resolve conflicting code blocks, then run:
```
git add .
git commit -m "fix: resolve merge conflicts"
git push origin feature/your-task-name
```

### ❓ Mistake 4: You made a typo(spelling mistake) in your last commit message
👉 The Fix: Change the text of your last local commit instantly:
```
git commit --amend -m "your new correct commit message"
```
