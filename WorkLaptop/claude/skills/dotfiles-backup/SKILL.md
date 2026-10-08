---
name: dotfiles-backup
description: Back up the work laptop configs (WezTerm, GlazeWM, Zebar, keys, shells, Zellij, git, Windows Terminal, yazi, generic Claude Code skills and plugins) to the DotFiles repo, then commit and push a branch for a PR. Trigger when the user says "backup my config", "backup dotfiles", "sync dotfiles", "push my configs", or "/dotfiles-backup".
---

# Dotfiles Backup

Copy the live configs into `WorkLaptop/` in the DotFiles repo, commit them, and push a branch.

- Repo: `C:\Users\CongHa\Documents\DotFiles` (remote `github.com/Cong-Ha/DotFiles`, **public**).
- File list: `manifest.tsv` in this skill folder.
- Copy, clean, and scan: `backup.sh` in this skill folder.

## Rules

- The repo is public. No company data and no secrets go in.
- Do not change the live config files. Change only the repo copies.
- Do not change the git config. Use `-c user.name="Cong Ha" -c user.email="hausmc@live.com"` on the commit, because the global email is the work email.
- Do not push to `main`. Push a branch and give the user the PR link.
- Use the `pr-description` template for the PR text.

## Step 1: Prepare the repo

1. Run `git -C <repo> status --porcelain`. If there are uncommitted changes, stop and tell the user.
2. Run `git -C <repo> checkout main` and `git -C <repo> pull --ff-only`.
3. Run `git -C <repo> checkout -b backup/work-laptop-<YYYY-MM-DD>`. If the branch exists, add `-2`, `-3`, and so on.

## Step 2: Look for new configs

Compare the machine with `manifest.tsv`. Look for these items:
- New folders in `~/.claude/skills/` other than `synced`.
- New tool folders in `~/.config/`, `~/.glzr/`, `%APPDATA%`, and `%LOCALAPPDATA%` that hold user config (for example, a new yazi, nvim, or lazygit config).
- New files in `~/.local/bin/` that are scripts, not programs.

Do not ask about these items. The user said no:
- The work skills: blastradius, epicart, explain-changes, handoff, investigation, lattice-weekly-update, log-hours.
- Zed (`%APPDATA%\Zed`): its settings hold an API token and the work MCP servers.

If you find a candidate, ask the user if it goes in. Before you ask, read it and tell the user about company data, secrets, or credentials in it.
- Never add credential files, token databases, caches, logs, or `.bak` copies.
- Never add skills or files that contain company data (the employer name, Jira or Atlassian IDs, internal hosts, telemetry settings).
- If the user says yes, add a line to `manifest.tsv`. Use a trailing slash for a folder.
- If the new file needs cleaning, add a `sed` line to the clean section of `backup.sh`.

## Step 3: Copy, clean, and scan

Run `bash ~/.claude/skills/dotfiles-backup/backup.sh <repo>`.

- Exit 0: all files are copied and the scan is clean.
- Exit 1: a file in the manifest is missing. Tell the user, and ask if the line comes out of the manifest.
- Exit 2: the scan found a match. Show the matches. Do not commit. Clean the repo copy, or remove the file from the manifest, then run the script again.

## Step 4: Review the changes

1. Run `git -C <repo> add WorkLaptop` and `git -C <repo> diff --cached --stat`.
2. Make sure that all staged paths are under `WorkLaptop/`.
3. If nothing is staged, tell the user that the backup is current. Delete the branch, go back to `main`, and stop.
4. Show the user the file list, with one line for each file that changed.

## Step 5: Commit and push

1. Commit:
   ```
   git -C <repo> -c user.name="Cong Ha" -c user.email="hausmc@live.com" commit -m "Back up WorkLaptop configs (<YYYY-MM-DD>)" -m "<one line for each tool that changed>"
   ```
2. Run `git -C <repo> push -u origin <branch>`. If GitHub returns a 500 error, try again one time. If it fails again, stop, and give the user the push command to run with `!`.
3. Print the PR link: `https://github.com/Cong-Ha/DotFiles/compare/main...<branch>?expand=1`.
4. Print the PR description with the `pr-description` template. In What, write one bullet for each changed file and describe the change from the diff.
