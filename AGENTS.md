# Agent Instructions

This project uses **bd** (beads) for issue tracking. Run `bd onboard` to get started.

## Quick Reference

```bash
bd ready              # Find available work
bd show <id>          # View issue details
bd update <id> --status in_progress  # Claim work
bd close <id>         # Complete work
bd sync               # Sync with git
```

## Landing the Plane (Session Completion)

**When ending a work session**, you MUST complete ALL steps below. Work is NOT complete until `git push` succeeds.

**MANDATORY WORKFLOW:**

1. **File issues for remaining work** - Create issues for anything that needs follow-up
2. **Run quality gates** (if code changed) - Tests, linters, builds
3. **Update issue status** - Close finished work, update in-progress items
4. **PUSH TO REMOTE** - This is MANDATORY:
   ```bash
   git pull --rebase
   bd sync
   git push
   git status  # MUST show "up to date with origin"
   ```
5. **Clean up** - Clear stashes, prune remote branches
6. **Verify** - All changes committed AND pushed
7. **Hand off** - Provide context for next session

**CRITICAL RULES:**
- Work is NOT complete until `git push` succeeds
- NEVER stop before pushing - that leaves work stranded locally
- NEVER say "ready to push when you are" - YOU must push
- If push fails, resolve and retry until it succeeds

## File Organization Rules

**MANDATORY STRUCTURE:**

1. **Shell Scripts** - ALL `.sh` files MUST be in `simulation/` directory
   - No shell scripts in project root
   - All automation scripts go to `simulation/`

2. **Documentation** - ALL `.md` files (except `AGENTS.md`) MUST be in `docs/` directory
   - Root level markdown is prohibited
   - README.md stays in root
   - All other documentation goes to `docs/`

3. **Python Scripts** - ALL `.py` files in `simulation/` directory
   - Python automation belongs in `simulation/`

**FOLLOW THESE RULES:**
- Before creating files, check if they belong in `simulation/` or `docs/`
- If creating shell scripts, always put them in `simulation/`
- If creating documentation, always put it in `docs/`
- If creating Python automation, put it in `simulation/`

