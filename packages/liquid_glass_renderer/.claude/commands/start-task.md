# Start Task Command

## Overview

This command initiates work on a Linear task by fetching task details, analyzing requirements, creating a feature branch, and executing the implementation with proper planning and atomic commits.

## Command Execution Flow

### 1. Task Retrieval and Analysis

Using Linear MCP, retrieve the task details for $ARGUMENTS (can be task ID or URL):

- Fetch the task using `mcp__linear__get_issue` with the provided task identifier
- Extract and display:
  - Task title and description
  - Acceptance criteria
  - Related comments and discussions
  - Linked issues or dependencies
  - Labels and priority
  - Any attached files or screenshots

### 2. Sentry Integration (if applicable)

If the task mentions Sentry issues, errors, or bug reports:

- Extract Sentry issue IDs or URLs from the task description/comments
- Use `mcp__Sentry__analyze_issue_with_seer` to get root cause analysis
- Use `mcp__Sentry__get_issue_details` for error details and stack traces
- Incorporate findings into the implementation plan

### 3. Branch Safety Check and Creation

**CRITICAL: Always check current branch before any work begins.**

#### Pre-Flight Branch Check (MANDATORY)

Run `git branch --show-current` to determine the current branch.

**If on `develop` or `main` branch:**
- You MUST create a feature branch before any implementation work
- Never commit directly to protected branches
- Proceed with the branch creation steps below

**If already on a feature branch (e.g., `daniil/VES-*`):**
- Verify the branch matches the task you're working on
- If it's a different task's branch, still create a new branch from develop

#### Branch Naming Convention

```
{user}/{task-id}-{short-title}
```

Example:

- Task ID: VES-123
- Task Title: "Remove wave over proximity sensor feature"
- Branch Name: `daniil/VES-123-remove-wave-gesture`

#### Branch Creation Steps

1. Check current branch: `git branch --show-current`
2. If on develop/main or wrong feature branch:
   - Switch to develop: `git checkout develop`
   - Pull latest changes: `git pull origin develop`
   - Create and checkout new branch: `git checkout -b {branch-name}`
3. Confirm you're on the correct feature branch before proceeding

**⚠️ NEVER proceed to implementation phase while on develop or main branch.**

### 4. Task Planning Phase

Before implementation, create a comprehensive plan:

1. **Use TodoWrite tool** to create a detailed task breakdown:
   - Analyze requirements and create subtasks
   - Identify affected files and components
   - Note any potential risks or dependencies
   - Plan testing approach

2. **Codebase Analysis**:
   - Search for related code using Grep/Glob tools
   - Review existing implementations
   - Check for similar patterns in the codebase
   - Identify files that need modification

3. **Clarification Questions**:
   - Ask the user about any ambiguous requirements
   - Confirm understanding of edge cases
   - Verify UI/UX expectations if applicable
   - Discuss any architectural decisions needed

### 5. Implementation Phase

Execute the plan with these principles:

1. **Atomic Commits**:
   - Each commit should represent one logical change
   - Commits must strictly follow guidelines from file `.ai/guidelines/commit.md`

2. **Incremental Progress**:
   - Implement one subtask at a time
   - Run relevant tests after each change
   - Mark todos as completed in TodoWrite tool

3. **Code Quality**:
   - Follow project coding standards (see CLAUDE.md)
   - Run formatting: `dart format $(find lib -name "*.dart" -not \( -name "*.*freezed.dart" -o -name "*.*g.dart" -o -name "*.gr.dart" \) ) --line-length=120`
   - Ensure no lint warnings

### 6. Testing and Verification

After implementation:

1. Use `sh ./scripts/build.sh` to ensure builds pass
2. Run all relevant tests
3. Verify the fix/feature works as expected
4. Check for any regressions
5. Update or add tests as needed

### 7. Final Steps

1. Push the branch: `git push -u origin {branch-name}`
2. Prepare for PR creation (use create-pr command when ready)

## Important Guidelines

- **NEVER work on develop/main** - Always verify you're on a feature branch before any implementation
- **Always use TodoWrite** for task planning and tracking
- **Fetch fresh task data** from Linear at the start
- **Investigate Sentry issues** thoroughly if referenced
- **Ask questions** before making assumptions
- **Keep commits atomic** - one logical change per commit
- **Test incrementally** - don't wait until the end
- **Follow commits guidelines** strictly (see `.ai/guidelines/commit.md`)
- **Follow project conventions** strictly (see `CLAUDE.md`)
- **Document complex changes** in code when necessary

## Error Handling

If you encounter issues:

- Build failures: Check CLAUDE.md for build commands
- Test failures: Analyze and fix before proceeding
- Unclear requirements: Always ask the user for clarification
- Sentry errors: Use analyze_issue_with_seer for root cause analysis

## Example Workflow

```bash
# 1. Start by fetching task details
mcp__linear__get_issue(id="VES-123")

# 2. MANDATORY: Check current branch first
git branch --show-current
# If output is "develop" or "main" → MUST create feature branch
# If output is a feature branch → verify it matches this task

# 3. Create feature branch (always when on develop/main)
git checkout develop
git pull origin develop
git checkout -b daniil/VES-123-remove-wave-gesture

# 4. Verify you're on the correct branch before proceeding
git branch --show-current  # Should show: daniil/VES-123-remove-wave-gesture

# 5. Plan work with TodoWrite
TodoWrite([
  { content: "Remove wave gesture listener from lock screen", ... },
  { content: "Update settings to remove proximity option", ... },
  { content: "Clean up unused gesture detection code", ... }
])

# 6. Implement with atomic commits
# ... make changes ...
git add -A
git commit -m "[VES-123][LockScreen] Remove wave gesture listener"

# 7. Continue until all todos are complete
```
