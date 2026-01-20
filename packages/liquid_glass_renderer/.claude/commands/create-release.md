# Create Release Command

This command automates the entire release process from develop to main branch, including PR creation, changelog updates, and Linear ticket creation.

## Usage

```
/create-release
```

## What This Command Does

1. **Pre-flight Checks**
   - Verifies you're on the develop branch
   - Ensures develop is up to date with remote
   - Checks that the version in develop is higher than main
   - Validates no uncommitted changes exist

2. **Analyzes Changes**
   - Fetches all commits between main and develop
   - Groups changes by type (Security, Features, Fixes, Tech)
   - Extracts Linear ticket numbers and PR references
   - Identifies breaking changes and dependencies

3. **Creates Release PR**
   - Generates comprehensive PR description
   - Links all related Linear tickets and Sentry issues
   - Includes formatted changelog for the release
   - Creates PR from develop to main with proper labels

4. **Updates Documentation**
   - Creates a Linear ticket for changelog update
   - Creates a new branch from develop
   - Updates CHANGELOG.md with the new release
   - Commits changes with proper message
   - Creates PR to merge changelog back to develop

## Step-by-Step Process

### 1. Verify Prerequisites

```bash
# Check current branch
git branch --show-current | grep -q "develop" || echo "ERROR: Not on develop branch"

# Ensure develop is up to date
git fetch origin develop
git status | grep -q "Your branch is up to date" || echo "WARNING: develop is not up to date"

# Check for uncommitted changes
git status --porcelain | grep -q . && echo "ERROR: Uncommitted changes found"
```

### 2. Compare Versions

```bash
# Get version from develop
DEVELOP_VERSION=$(grep "version:" pubspec.yaml | sed 's/version: //' | sed 's/+.*//')
DEVELOP_BUILD=$(grep "version:" pubspec.yaml | sed 's/.*+//')

# Get version from main
git checkout main --quiet
MAIN_VERSION=$(grep "version:" pubspec.yaml | sed 's/version: //' | sed 's/+.*//')
MAIN_BUILD=$(grep "version:" pubspec.yaml | sed 's/.*+//')
git checkout develop --quiet

# Compare versions
# Ensure DEVELOP_VERSION > MAIN_VERSION or (same version but DEVELOP_BUILD > MAIN_BUILD)
```

### 3. Analyze Changes

```bash
# Get all commits between main and develop
COMMITS=$(git log main..develop --pretty=format:"%H|%s|%b" --reverse)

# Extract Linear tickets (VES-XXX)
LINEAR_TICKETS=$(echo "$COMMITS" | grep -oE "VES-[0-9]+" | sort -u)

# Extract PR numbers (#XXX)
PR_NUMBERS=$(echo "$COMMITS" | grep -oE "#[0-9]+" | sort -u)

# Group commits by type based on commit messages
# - Security: encryption, security, auth, vulnerability
# - New: feat, add, implement, introduce
# - Fix: fix, resolve, correct, repair
# - Tech: deps, update, refactor, chore, docs
```

### 4. Generate PR Description

The PR description should include:

```markdown
# Release X.X.X

This release includes [summary of major changes].

## 🔒 Security Enhancements
[List security-related changes with ticket numbers]

## ✨ New Features
[List new features with ticket numbers]

## 🐛 Bug Fixes
[List bug fixes with ticket numbers and Sentry issue IDs if applicable]

## 📦 Dependency Updates
[List major dependency changes]

## 🛠 Technical Improvements
[List technical changes, refactoring, documentation]

## 📋 Testing
All changes have been tested across:
- iOS
- Android
- Chrome/Brave Web Extension

## Breaking Changes
[List any breaking changes or "None"]

## Related Linear Tickets
[Comma-separated list of VES-XXX tickets]

## Related Sentry Issues
[List any VESPR-APP-XXX issues that were fixed]
```

### 5. Create Release PR

```bash
# Create the PR from develop to main
gh pr create \
  --base main \
  --head develop \
  --title "Release $DEVELOP_VERSION" \
  --body "$PR_DESCRIPTION" \
  --label "release" \
  --label "high-priority"
```

### 6. Create Linear Ticket for Changelog

Use Linear API to create a ticket:

```
Title: Update CHANGELOG.md for release X.X.X
Description: Update the CHANGELOG.md file to include release X.X.X with all changes from PR #XXX
Labels: documentation, release
```

### 7. Update Changelog

```bash
# Create a new branch from develop
BRANCH_NAME="chore/update-changelog-$DEVELOP_VERSION"
git checkout -b "$BRANCH_NAME"

# Update CHANGELOG.md
# Insert new release entry at the top, after the first line
```

Changelog entry format:
```markdown
# VESPR Wallet X.X.X + XXX | Month DD, YYYY

Flutter X.X.X

Security:
- [VES-XXX] Description (#PR)

New:
- [VES-XXX] Description (#PR)

Fix:
- [VES-XXX] Description (#PR)

Tech:
- [VES-XXX] Description (#PR)
```

### 8. Commit and Create Changelog PR

```bash
# Commit changes
git add CHANGELOG.md
git commit -m "chore: update CHANGELOG.md for release $DEVELOP_VERSION

- Added release entry for version $DEVELOP_VERSION
- Documented all changes from develop to main
- Updated with PR references and ticket numbers

Linear: VES-XXX"

# Push branch
git push origin "$BRANCH_NAME"

# Create PR to develop
gh pr create \
  --base develop \
  --head "$BRANCH_NAME" \
  --title "chore: update CHANGELOG.md for release $DEVELOP_VERSION" \
  --body "Updates CHANGELOG.md with release notes for version $DEVELOP_VERSION

Related to release PR: #XXX
Linear ticket: VES-XXX" \
  --label "documentation"
```

## Error Handling

The command should handle these scenarios:
- Not on develop branch → Prompt to switch
- Uncommitted changes → Prompt to commit or stash
- Version not incremented → Show error and current versions
- Network issues → Retry with exponential backoff
- PR already exists → Show existing PR link

## Success Output

```
✅ Release PR created: https://github.com/vespr-wallet/nft-craze-wallet/pull/XXX
✅ Linear ticket created: VES-XXX
✅ Changelog branch created: chore/update-changelog-X.X.X
✅ Changelog updated with X commits grouped into X categories
✅ Changelog PR created: https://github.com/vespr-wallet/nft-craze-wallet/pull/XXX

Next steps:
1. Review and approve the release PR
2. Review and merge the changelog PR to develop
3. After both PRs are merged, create and push the release tag
4. Deploy the release
```

## Additional Features

- **Dry Run Mode**: Add `--dry-run` to see what would happen without making changes
- **Custom Version**: Allow specifying version with `--version X.X.X`
- **Auto-detect Flutter Version**: Extract Flutter version from `.tool-versions` or `flutter --version`
- **Commit Message Templates**: Use standardized formats for all generated commits
- **Integration with CI/CD**: Trigger build pipelines after PR creation

## Implementation Notes

1. Use `gh` CLI for GitHub operations (requires authentication)
2. Use Linear API with proper authentication
3. Parse git log carefully to handle multi-line commit messages
4. Implement proper error handling and rollback on failures
5. Use TodoWrite to track progress through the multi-step process
6. Consider using parallel processing where possible (e.g., analyzing commits while checking versions)

## Example Linear Ticket Analysis

When analyzing Linear tickets from commits:
1. Fetch ticket details using `mcp__linear__get_issue`
2. Extract ticket title and status
3. Group related tickets by epic or project
4. Include ticket titles in the changelog for better context

## Version Comparison Logic

```python
def compare_versions(v1, v2):
    """
    Returns True if v1 > v2
    Handles semantic versioning: MAJOR.MINOR.PATCH
    """
    v1_parts = v1.split('.')
    v2_parts = v2.split('.')
    
    for i in range(max(len(v1_parts), len(v2_parts))):
        v1_num = int(v1_parts[i]) if i < len(v1_parts) else 0
        v2_num = int(v2_parts[i]) if i < len(v2_parts) else 0
        
        if v1_num > v2_num:
            return True
        elif v1_num < v2_num:
            return False
    
    return False
```

## Changelog Categories

Commits should be categorized as follows:

- **Security**: Changes related to encryption, authentication, vulnerabilities, secure storage
- **New**: New features, capabilities, or major additions
- **Fix**: Bug fixes, crash fixes, error corrections
- **Tech**: Dependency updates, refactoring, performance improvements, developer tools

## Best Practices

1. Always run this command with a clean working directory
2. Review the generated PR description before finalizing
3. Ensure all Linear tickets mentioned are actually closed/ready
4. Double-check version numbers match across all files
5. Consider running tests before creating the release PR
6. Tag the release after both PRs are merged

This command streamlines the release process while maintaining quality and traceability.