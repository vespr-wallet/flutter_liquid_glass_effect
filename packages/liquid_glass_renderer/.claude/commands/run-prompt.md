---
name: run-prompt
description: Delegate one or more prompts to fresh sub-task contexts with parallel or sequential execution
argument-hint: <prompt-number(s)-or-name> [--parallel|--sequential]
allowed-tools: [Read, Task, Bash(ls:*), Bash(mv:*), Bash(git:*), Bash(mkdir:*), Bash(dart:*), Bash(flutter:*), Bash(sh:*)]
---

<context>
Git status: !`git status --short`
Recent prompts: !`ls -t .prompts/*.md 2>/dev/null | head -5 || echo "No prompts found"`
</context>

<objective>
Execute one or more prompts from `.prompts/` as delegated sub-tasks with fresh context. Supports single prompt execution, parallel execution of multiple independent prompts, and sequential execution of dependent prompts.

This is optimized for VESPR Wallet development workflow, including automatic code generation and validation steps.
</objective>

<input>
The user will specify which prompt(s) to run via $ARGUMENTS, which can be:

**Single prompt:**
- Empty (no arguments): Run the most recently created prompt (default behavior)
- A prompt number (e.g., "001", "5", "42")
- A partial filename (e.g., "user-auth", "dashboard")

**Multiple prompts:**
- Multiple numbers (e.g., "005 006 007")
- With execution flag: "005 006 007 --parallel" or "005 006 007 --sequential"
- If no flag specified with multiple prompts, default to --sequential for safety (VESPR often has code generation dependencies)
</input>

<process>
<step1_parse_arguments>
Parse $ARGUMENTS to extract:
- Prompt numbers/names (all arguments that are not flags)
- Execution strategy flag (--parallel or --sequential)

<examples>
- "005" → Single prompt: 005
- "005 006 007" → Multiple prompts: [005, 006, 007], strategy: sequential (default)
- "005 006 007 --parallel" → Multiple prompts: [005, 006, 007], strategy: parallel
- "005 006 007 --sequential" → Multiple prompts: [005, 006, 007], strategy: sequential
- "" (empty) → Find most recent prompt
- "auth" → Find prompts containing "auth" in filename
</examples>
</step1_parse_arguments>

<step2_resolve_files>
For each prompt number/name:

- If empty or "last": Find with `!ls -t .prompts/*.md | head -1`
- If a number: Find file matching that zero-padded number (e.g., "5" matches "005-*.md", "42" matches "042-*.md")
- If text: Find files containing that string in the filename

<matching_rules>
- If exactly one match found: Use that file
- If multiple matches found: List them and ask user to choose
- If no matches found: Report error and list available prompts
</matching_rules>
</step2_resolve_files>

<step3_execute>
<single_prompt>
1. Read the complete contents of the prompt file
2. Delegate as sub-task using Task tool with subagent_type="general-purpose"
   - Include VESPR context: "This is VESPR Wallet, a Flutter Cardano wallet. Follow CLAUDE.md conventions."
3. Wait for completion
4. **Post-execution validation** (VESPR-specific):
   - If prompt created/modified models: Run `sh ./scripts/gen_models.sh`
   - If prompt modified database: Run drift schema commands
   - Run `dart analyze` to verify no new errors
5. Archive prompt to `.prompts/completed/` with completion timestamp
6. Commit all work:
   - Stage files modified by the sub-agent with `git add [file]` (never `git add .`)
   - Determine appropriate commit type based on changes (fix|feat|refactor|style|docs|test|chore)
   - Reference Linear issue if mentioned in prompt: `[VES-XXX]`
   - Commit with format: `[type]: [description]` or `[VES-XXX] [type]: [description]`
7. Return results with summary
</single_prompt>

<parallel_execution>
1. Read all prompt files
2. **Check for dependencies** - warn if prompts might conflict:
   - Same files being modified
   - One creates models another uses
   - Database schema changes
3. **Spawn all Task tools in a SINGLE MESSAGE** (critical for parallel execution):
   <example>
   Use Task tool for prompt 005 with subagent_type="general-purpose"
   Use Task tool for prompt 006 with subagent_type="general-purpose"
   Use Task tool for prompt 007 with subagent_type="general-purpose"
   (All in one message with multiple tool calls)
   </example>
4. Wait for ALL to complete
5. **Post-execution validation** (VESPR-specific):
   - Run `sh ./scripts/build.sh` if any prompt created models
   - Run `dart analyze` to verify no conflicts
   - If analysis fails, report which prompts may have conflicted
6. Archive all prompts with metadata
7. Commit all work:
   - Stage files modified with `git add [file]` (never `git add .`)
   - Single commit combining all changes if related, or separate commits if distinct features
   - Format: `[type]: [description]` (lowercase, specific, concise)
8. Return consolidated results
</parallel_execution>

<sequential_execution>
1. For each prompt in order:
   a. Read prompt file
   b. Spawn Task tool with subagent_type="general-purpose"
   c. Wait for completion
   d. **Intermediate validation** (VESPR-specific):
      - If prompt created models: Run `sh ./scripts/gen_models.sh` BEFORE next prompt
      - If prompt modified database: Run drift schema commands BEFORE next prompt
      - Run `dart analyze` - if fails, STOP and report
   e. Archive prompt
   f. If analysis failed, stop sequential execution and report which step failed
2. After all prompts complete:
   - Final `dart analyze` check
   - Run `flutter test` if tests were affected
3. Commit all work:
   - Can be single commit or per-prompt commits depending on scope
   - Format: `[type]: [description]`
4. Return consolidated results showing progression
</sequential_execution>
</step3_execute>

<vespr_post_execution>
**Code Generation Detection**:
After sub-task completion, check if code generation is needed:

1. **Module model changes** (triggers `gen_models.sh`):
   - New/modified files in `modules/models/`
   - New/modified files in `modules/pre_models/`
   - New/modified files in `core/` with Freezed/JsonSerializable
   - New/modified files in `critical/` with Freezed/JsonSerializable

2. **App/feature code generation** (triggers `build.sh`):
   - New/modified files in `lib/features/*/domain/models/` (feature domain models)
   - New/modified files in `lib/features/*/presentation/models/` (presentation models)
   - New/modified files in `lib/features/*/presentation/notifiers/` (Freezed states)
   - New/modified files in `lib/` with `@freezed` or `@JsonSerializable` annotations
   - Files with `part '*.freezed.dart'` or `part '*.g.dart'` in lib/
   - New pages with `@RoutePage()` annotation in `lib/features/*/presentation/pages/`
   - Changes to `lib/routes/` (AutoRoute)

3. **Database changes** (triggers drift commands):
   - Changes to `core/lib/persistence/`
   - New tables or schema modifications

4. **Web worker/platform changes** (triggers `build.sh`):
   - Changes to `lib/workers/` (Squadron workers, marshalers)
   - Changes to `lib_service/` (Chrome extension background service)
   - Changes to files matching `*.web.dart` (web-specific implementations)
   - Changes to files matching `*.vm.dart` that affect platform abstraction

**Validation Commands**:
```bash
# After module model changes (modules/, core/, critical/)
sh ./scripts/gen_models.sh

# After app/feature code generation (lib/, lib/features/, routes, workers)
sh ./scripts/build.sh

# After database schema changes (run from core/ directory)
dart run drift_dev schema dump lib/persistence/database_impl/vespr_database_impl.vm.dart drift_schemas/
dart run drift_dev schema steps drift_schemas/ lib/persistence/schema_versions.dart

# Always run analysis
dart analyze

# If tests might be affected
flutter test
```
</vespr_post_execution>
</process>

<context_strategy>
By delegating to a sub-task, the actual implementation work happens in fresh context while the main conversation stays lean for orchestration and iteration.

**VESPR-specific context injection**: Each sub-task receives:
- Reference to CLAUDE.md for project conventions
- Awareness of module structure (core/, critical/, modules/, lib/, lib/features/, lib_service/)
- Feature-folder architecture requirement for new features
- Build command requirements for code generation
</context_strategy>

<output>
<single_prompt_output>
✓ Executed: .prompts/005-implement-feature.md
✓ Post-validation: dart analyze passed
✓ Archived to: .prompts/completed/005-implement-feature.md
✓ Committed: feat: implement [feature description]

<results>
[Summary of what the sub-task accomplished]

Files created (feature-folder structure):
- lib/features/[feature]/presentation/notifiers/[feature]_notifier.dart
- lib/features/[feature]/presentation/pages/[feature]_page.dart
- lib/features/[feature]/presentation/widgets/[feature]_widget.dart
- lib/routes/app_router.dart (modified)
</results>
</single_prompt_output>

<parallel_output>
✓ Executed in PARALLEL:
  - .prompts/005-implement-auth.md → Success
  - .prompts/006-implement-api.md → Success
  - .prompts/007-implement-ui.md → Success

✓ Post-validation: dart analyze passed
✓ All archived to .prompts/completed/
✓ Committed: feat: implement auth, api, and ui components

<results>
[Consolidated summary of all sub-task results]

Prompt 005 (auth):
- Created lib/features/auth/presentation/...
- Created lib/features/auth/domain/...

Prompt 006 (api):
- Created lib/features/api_integration/...

Prompt 007 (ui):
- Created lib/features/dashboard/presentation/...
</results>
</parallel_output>

<sequential_output>
✓ Executed SEQUENTIALLY:
  1. .prompts/005-create-feature-structure.md → Success
     ↳ Created lib/features/[feature]/
     ↳ Ran: sh ./scripts/build.sh
  2. .prompts/006-implement-domain.md → Success
     ↳ Created domain/models/, domain/services/
     ↳ Ran: dart analyze (passed)
  3. .prompts/007-implement-presentation.md → Success
     ↳ Created presentation/pages/, presentation/notifiers/

✓ Final validation: dart analyze passed
✓ All archived to .prompts/completed/
✓ Committed: feat: implement [feature] with domain and presentation layers

<results>
[Consolidated summary showing progression through each step]

Step 1 (structure): Created lib/features/[feature]/ folder structure
Step 2 (domain): Created domain models and services with Freezed
Step 3 (presentation): Created page, notifiers, and widgets with Riverpod
</results>
</sequential_output>

<error_output>
✗ Execution stopped at prompt 006

<error_details>
Prompt: .prompts/006-implement-domain.md
Stage: Post-validation (dart analyze)
Error:
  lib/features/[feature]/domain/services/feature_service.dart:12:5 - error - The name 'FeatureModel' isn't defined

Root cause: Model generation may not have run after creating Freezed models

Suggested fix:
1. Run: sh ./scripts/build.sh
2. Re-run: /run-prompt 006 007 --sequential
</error_details>

Prompts NOT executed:
- .prompts/007-implement-presentation.md (skipped due to earlier failure)
</error_output>
</output>

<critical_notes>
- For parallel execution: ALL Task tool calls MUST be in a single message
- For sequential execution: Wait for each Task to complete AND validate before starting next
- Archive prompts only after successful completion
- If any prompt fails, stop sequential execution and report error with recovery steps
- Always run `dart analyze` after execution to catch issues early
- Run code generation BETWEEN sequential prompts if models were created
- Never use `git add .` - always stage specific files
- Reference Linear issues in commits when mentioned in prompts (e.g., `[VES-XXX]`)
</critical_notes>

<task_delegation_template>
When spawning Task tools, use this context injection:

```
Execute the following prompt for VESPR Wallet (Flutter, Cardano blockchain).

IMPORTANT CONTEXT:
- Read @CLAUDE.md for project conventions before implementing
- Module structure: core/ (persistence), critical/ (security), modules/ (models), lib/ (legacy), lib/features/ (NEW FEATURES), lib_service/ (web extension)

FEATURE-FOLDER ARCHITECTURE (REQUIRED for new features):
- All new features MUST go in lib/features/[feature_name]/
- Structure: domain/ (optional: models, services, use_cases) + presentation/ (pages, modals, widgets, notifiers)
- Reference implementations: lib/features/currency/, lib/features/deeplinks/, lib/features/midnight_redemption/
- Reuse common code from: lib/ui_components/, lib/utils/, lib/repo/

TECHNICAL PATTERNS:
- Use Riverpod + Freezed sealed classes for state management
- Notifier pattern: @freezed sealed class + BaseStateNotifierV2 + snpAutoDispose provider
- Use AutoRoute for navigation (never Navigator.of)
- Use ConsumerWidget or HookConsumerWidget with @RoutePage()
- Line length: 120 chars, trailing commas, final by default, EdgeInsetsDirectional for RTL

CODE GENERATION:
- After creating Freezed models/notifiers: sh ./scripts/build.sh
- After creating pages with @RoutePage(): sh ./scripts/build.sh

PROMPT:
[Insert prompt content here]
```
</task_delegation_template>
