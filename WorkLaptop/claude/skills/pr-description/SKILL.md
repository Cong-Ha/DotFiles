---
name: pr-description
description: Write a pull request description for the current branch and print it in the terminal for copy-paste. Uses a fixed template with three sections - What (one bullet per changed file), Why (one bullet per reason), and Release Notes (steps to release to lower environments and to production). Trigger when the user says "pr description", "write the PR description", "describe this PR", "/pr-description", or asks for PR text after a commit or push. Output only. Never create, update, or comment on a pull request in Bitbucket or any other service.
---

# PR Description

Print a pull request description in the terminal. The user copies it into Bitbucket.

## Rules

- Output only. Do not call Bitbucket, do not run `gh`, do not write files.
- Do not commit, push, or change the branch.
- Write all prose in Simplified Technical English (load the `simple-english` skill if it is not loaded).
- No em dashes, no arrow notation, no Jira ticket numbers inside bullets.
- Each fact must come from the diff, the commit messages, or the Jira ticket. Do not guess.

## Step 1: Find the scope

1. Get the current branch: `git rev-parse --abbrev-ref HEAD`.
2. Find the base branch. Use the first one that exists: `origin/main`, `origin/Main`, `origin/master`, `origin/develop`. If the user names a base, use it.
3. Run `git fetch origin` before the diff, so that the base is current.
4. Collect the change set:
   - `git log --oneline <base>...HEAD`
   - `git diff --stat <base>...HEAD`
   - `git diff <base>...HEAD`
5. If there are uncommitted changes (`git status --porcelain`), tell the user. Do not include them unless the user asks.

## Step 2: Get the ticket context

1. If the branch name contains a Jira key (pattern `[A-Z]+-\d+`), fetch the ticket with the Atlassian MCP.
2. Use the summary, description, and acceptance criteria as the source for the Why section.
3. If there is no key, or the fetch fails, use the commit messages only. Say so in one line above the output.

## Step 3: Write the sections

### What

- One bullet per changed file.
- Format: `` `relative/path/File.cs`: <what changed in this file> ``.
- Describe the change, not the file's purpose in general.
- Group files that only change for the same mechanical reason (for example, a rename across 10 test files) into one bullet that names the pattern and the count.
- Mark new files with `(new)` and deleted files with `(deleted)`.

### Why

- One bullet per reason. A reason can cover more than one file.
- State the problem or requirement, then the result of the change.
- Take reasons from the Jira ticket and the commit messages. Do not repeat the What bullets.

### Release Notes

Look in the diff for items that need action at release time:

- Database migrations (EF Core `Migrations/`, SQL scripts)
- New or changed configuration keys (`appsettings*.json`, environment variables, Helm values, Key Vault references)
- Infrastructure changes (Terraform, Bicep, pipeline YAML, Service Bus topics, queues, or subscriptions)
- Feature flags
- New or changed message contracts that other services consume
- Deployment order between services or repos

Write two subsections:

- **Lower environments (dev, test, QA):** the steps to release and to test.
- **Production:** the steps to release to production.

If production steps are the same as lower environments, write `Same as lower environments.` If they differ, list every difference.

If the diff has no release items, write `No special release steps. Deploy as normal.` for both subsections.

If an item needs a value that the diff does not show (for example, a secret or a per-environment setting), list it as an open item for the author. Do not invent the value.

## Step 4: Print the output

Print one fenced `markdown` block so that the user can copy it in one action:

```markdown
## What
- `path/to/FileA.cs`: <change>
- `path/to/FileB.cs` (new): <change>

## Why
- <reason>
- <reason>

## Release Notes
**Lower environments (dev, test, QA)**
- <step>

**Production**
- Same as lower environments.
```

After the block, print at most three lines:
- The base branch and the commit count used.
- Open items for the author, if there are any.

Do not add other commentary.
