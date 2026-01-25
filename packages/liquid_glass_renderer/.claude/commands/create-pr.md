# Create Pull Request Command

## Instructions

Create a Pull Request (PR) for the current branch. Analyze all code changes and summarize them in a clear, easy-to-understand format following the template below.

## Steps to Execute

1. Run `git diff` to analyze all changes between the current branch and the base branch
2. Identify the main purpose and scope of changes
3. Categorize changes by type (features, fixes, refactoring, etc.)
4. Create PR title following conventional commit format
5. Generate PR description using the template below
6. Use `gh pr create` with the generated title and description

## PR Template

### PR Title Format

`[TICKET-ID] Brief description of changes`

Example: `[VES-306] Add drag-and-drop reordering for bookmarked websites`

### PR Description Template

```markdown
### 🎯 Overview
[Provide a clear, concise summary of what this PR accomplishes and why it's needed]

### ✨ Key Features
- **[Feature Name]**: [Brief description of the feature]
- **[Feature Name]**: [Brief description of the feature]
[Add more as needed]

### 🔧 Technical Changes

#### [Component/Module Name]
- [Specific change or addition]
- [Specific change or addition]

#### [Component/Module Name]
- [Specific change or addition]
- [Specific change or addition]

[Add more sections as needed based on the scope of changes]

### 🧪 Testing
- [Description of tests added/updated]
- [Manual testing performed]
- [Any specific testing considerations]

### 📱 User Experience
- [How this impacts end users]
- [UI/UX improvements]
- [Any behavioral changes]

### 📝 Additional Notes (Optional)
[Any additional context, dependencies, or considerations]

**Resolves:** [TICKET-ID]
```

## Important Guidelines

- Keep the overview concise but informative
- Group related changes together under clear headings
- Focus on the "why" and "what" rather than implementation details
- Highlight user-facing changes prominently
- Include ticket reference at the end
- Use emojis sparingly for section headers only
