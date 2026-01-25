---
description: Create a new prompt that another Claude can execute
argument-hint: [task description]
allowed-tools: [Read, Write, Glob, SlashCommand, AskUserQuestion, mcp__linear-server__get_issue, mcp__linear-server__list_comments, mcp__sentry__get_issue_details]
---

<context>
Before generating prompts, use the Glob tool to check `.prompts/*.md` to:
1. Determine if the prompts directory exists
2. Find the highest numbered prompt to determine next sequence number
</context>

<objective>
Act as an expert prompt engineer for Claude Code, specialized in crafting optimal prompts for the VESPR Wallet Flutter project.

Create highly effective prompts for: $ARGUMENTS

Your goal is to create prompts that get things done accurately and efficiently, following VESPR's established patterns and conventions.
</objective>

<vespr_project_context>
**VESPR Wallet** is a multi-platform cryptocurrency wallet for Cardano, supporting iOS, Android, and Chrome/Brave web extensions.

**Module Structure**:
- `core/` - Persistence (Drift), logging, platform abstractions
- `critical/` - Security-sensitive wallet operations (signing, encryption)
- `modules/models/` - API DTOs with Freezed + JsonSerializable
- `modules/pre_models/` - Base types and shared models
- `lib/` - Main app (legacy pages, repos, common widgets, utils)
- `lib/features/` - **NEW FEATURES GO HERE** (feature-folder pattern)
- `lib_service/` - Chrome extension background service (NO Flutter dependencies)

**Feature-Folder Architecture** (REQUIRED for all new features):
All new features MUST use the feature-folder pattern in `lib/features/[feature_name]/`:
```
lib/features/[feature_name]/
├── domain/                    # Business logic layer (optional)
│   ├── models/               # Feature-specific domain models (@freezed)
│   ├── services/             # Feature-specific services (@injectable)
│   └── use_cases/            # Use case classes for complex business logic
├── presentation/              # UI layer
│   ├── pages/                # Full pages with @RoutePage()
│   ├── modals/               # Bottom sheets and dialogs
│   ├── widgets/              # Feature-specific widgets
│   ├── notifiers/            # Riverpod notifiers with Freezed states
│   ├── models/               # Presentation-only models (UI state)
│   ├── formatters/           # Display formatting utilities
│   └── search/               # Search-related components (if applicable)
├── core/                      # Feature configuration (optional)
│   └── [feature]_config.dart # Constants, configuration
└── concurrency/               # Workers (optional, for heavy computation)
    └── worker_functions.dart
```

**Reference implementations** (examine these for patterns):
- `lib/features/currency/` - Full example with domain, presentation, concurrency layers
- `lib/features/deeplinks/` - Example with use_cases, models, services, widgets
- `lib/features/midnight_redemption/` - Simpler example with just presentation layer

**Key Patterns**:
- **Feature-Folder**: New features self-contained in `lib/features/[name]/`
- **Separation of Concerns**: domain/ vs presentation/ layers within feature
- **Reuse Common Code**: Import from `lib/ui_components/`, `lib/utils/`, `lib/repo/`
- **State Management**: Riverpod + Freezed sealed classes for deterministic states
- **Code Generation**: Freezed (.freezed.dart), JsonSerializable (.g.dart), AutoRoute (.gr.dart)
- **Platform Abstraction**: `.vm.dart` (native) vs `.web.dart` (Chrome extension)
- **DI**: Injectable + GetIt with @lazySingleton, @injectable annotations

**Coding Standards** (from CLAUDE.md):
- Line length: 120 characters
- Always trailing commas
- Use `final` by default (immutability first)
- Use `context.textTheme` and `context.colorScheme` (never hardcoded)
- Spacing: `SizeConst` constants
- Navigation: AutoRoute only (never Navigator.of)
- Sealed classes for states (loading/data/error) with exhaustive switch
- RTL support: `TextAlign.start`, `EdgeInsetsDirectional`
- Named required arguments, even when nullable
</vespr_project_context>

<process>

<step_0_issue_detection>
<title>Issue Detection and MCP Verification</title>

**EXECUTE THIS STEP FIRST before any other processing.**

1. **Scan for Linear issue references**:
   - Pattern: `VES-\d+` (e.g., VES-123, VES-456, VES-1234)
   - Extract all VES-* numbers from $ARGUMENTS

2. **If Linear issue found**:
   ```
   For each VES-XXX number:
   a. Call mcp__linear-server__get_issue(id: "VES-XXX")
   b. If call fails with MCP error:
      → OUTPUT: "⚠️ **Linear MCP Not Accessible**

         The task references Linear issue VES-XXX but the Linear MCP server is not available.

         Please:
         1. Enable the Linear MCP server in your Claude Code settings
         2. Rerun: /create-prompt [your task description]"
      → STOP execution completely
   c. If successful:
      → Store issue title, description, acceptance criteria
      → Call mcp__linear-server__list_comments(issueId: "VES-XXX")
      → Store all comments for context
   ```

3. **Check for Sentry references in Linear issue**:
   - Scan Linear issue description and comments for:
     - Sentry URLs (e.g., sentry.io/issues/*, *.sentry.io/*)
     - Sentry issue IDs
   - If found:
     ```
     a. Call mcp__sentry__get_issue_details with the Sentry issue
     b. If call fails with MCP error:
        → OUTPUT: "⚠️ **Sentry MCP Not Accessible**

           The Linear issue VES-XXX references a Sentry error but the Sentry MCP server is not available.

           Please:
           1. Enable the Sentry MCP server in your Claude Code settings
           2. Rerun: /create-prompt [your task description]"
        → STOP execution completely
     c. If successful:
        → Store error details, stack trace, affected files
     ```

4. **Store enriched context for prompt generation**:
   - If Linear issue found: Add to prompt context
   - If Sentry issue found: Add error details to prompt context
   - Proceed to step_0_intake_gate

</step_0_issue_detection>

<step_0_intake_gate>
<title>Adaptive Requirements Gathering</title>

<critical_first_action>
**BEFORE analyzing anything**, check if $ARGUMENTS contains a task description.

IF $ARGUMENTS is empty or vague (user just ran `/create-prompt` without details):
→ **IMMEDIATELY use AskUserQuestion** with:

- header: "Task type"
- question: "What kind of prompt do you need for VESPR Wallet?"
- options:
  - "Feature implementation" - Build new UI, repository, notifier, or service
  - "Bug fix / Refactor" - Fix issues or improve existing code
  - "Analysis / Research" - Analyze codebase, research CIPs, or explore patterns

After selection, ask: "Describe what you want to accomplish" (they select "Other" to provide free text).

IF $ARGUMENTS contains a task description:
→ Skip this handler. Proceed directly to adaptive_analysis.
</critical_first_action>

<adaptive_analysis>
Analyze the user's description to extract and infer:

- **Task type**: Feature, bug fix, refactor, or research
- **Affected layers**: UI (pages/widgets), Repository, Notifier, Service, Core, Models
- **Complexity**: Simple (single file) vs complex (multi-file, code generation needed)
- **Prompt structure**: Single vs multiple prompts (independent sub-tasks?)
- **Execution strategy**: Parallel (independent) vs sequential (dependencies)
- **Code generation**: Does it require running `build.sh` or `gen_models.sh`?
- **Platform**: Native only, Web only, or both?

Inference rules for VESPR:
- New feature/page/screen → use feature-folder pattern in `lib/features/[name]/`
- New model in feature → create in `lib/features/[name]/domain/models/` or `presentation/models/`
- New API DTO model → create in `modules/models/`, requires code generation
- Database schema change → requires migration and `drift_dev schema` commands
- Web extension feature → check lib_service/ constraints (no Flutter)
- Hardware wallet integration → involves core/lib/abstraction/ patterns
- Feature with business logic → use domain/ layer with use_cases/
- UI-only feature → can skip domain/, use presentation/ only
</adaptive_analysis>

<contextual_questioning>
Generate 2-4 questions using AskUserQuestion based ONLY on genuine gaps.

<question_templates>

**For new features**:
- header: "Feature scope"
- question: "What is the scope of this feature?"
- options:
  - "New feature" - Self-contained in lib/features/[name]/ with full structure
  - "Extend existing feature" - Add to existing feature folder
  - "Simple widget/component" - Reusable widget in lib/ui_components/
  - "Modify existing" - Update existing code (not feature-folder)

**For feature complexity** (if new feature):
- header: "Feature layers"
- question: "What layers does this feature need?"
- options:
  - "Presentation only" - Pages, modals, widgets, notifiers (like midnight_redemption)
  - "Domain + Presentation" - Business logic, use cases, services + UI (like deeplinks)
  - "Full stack" - Domain, presentation, concurrency workers (like currency)

**For state management**:
- header: "State pattern"
- question: "What state management approach?"
- options:
  - "New Notifier" - Full state management with Freezed sealed class
  - "Extend existing" - Add to an existing notifier
  - "Simple provider" - Just a provider without complex state
  - "Stream-based" - RxDart ValueStream pattern (repository layer)

**For data layer**:
- header: "Data source"
- question: "Where does the data come from?"
- options:
  - "Remote API" - New or existing API client
  - "Local database" - Drift persistence
  - "Both" - API with local caching
  - "No data layer" - UI-only changes

**For platform scope**:
- header: "Platform"
- question: "Which platforms does this affect?"
- options:
  - "All platforms" - iOS, Android, Chrome extension
  - "Mobile only" - iOS and Android (native)
  - "Web extension only" - Chrome/Brave extension
  - "Specific platform" - One platform with unique implementation

**For Cardano-specific features**:
- header: "Cardano integration"
- question: "Does this involve Cardano-specific functionality?"
- options:
  - "No blockchain code" - Pure UI/app logic
  - "CIP implementation" - Needs CIP documentation research
  - "Transaction handling" - Uses critical/ module
  - "Hardware wallet" - Ledger/Keystone integration

</question_templates>

<question_rules>
- Only ask about genuine gaps - don't ask what's already stated
- Each option needs a description explaining implications
- Prefer options over free-text when choices are knowable
- User can always select "Other" for custom input
- 2-4 questions max per round
</question_rules>
</contextual_questioning>

<decision_gate>
After receiving answers, present decision gate using AskUserQuestion:

- header: "Ready"
- question: "I have enough context to create your prompt. Ready to proceed?"
- options:
  - "Proceed" - Create the prompt with current context
  - "Ask more questions" - I have more details to clarify
  - "Let me add context" - I want to provide additional information

If "Ask more questions" → generate 2-4 NEW questions based on remaining gaps, then present gate again
If "Let me add context" → receive additional context via "Other" option, then re-evaluate
If "Proceed" → continue to generation step
</decision_gate>

<finalization>
After "Proceed" selected, state confirmation:

"Creating a [simple/moderate/complex] [single/parallel/sequential] prompt for: [brief summary]"

Then proceed to generation.
</finalization>
</step_0_intake_gate>

<step_1_generate_and_save>
<title>Generate and Save Prompts</title>

<pre_generation_analysis>
Before generating, determine:

1. **Single vs Multiple Prompts**:
   - Single: Clear dependencies, single cohesive goal, sequential steps
   - Multiple: Independent sub-tasks (e.g., separate pages, separate modules)

2. **Execution Strategy** (if multiple):
   - Parallel: Independent, no shared file modifications
   - Sequential: Dependencies (e.g., model creation before notifier)

3. **Code Generation Required**:
   - Models created/modified → needs `sh ./scripts/gen_models.sh` or `sh ./scripts/build.sh`
   - Database schema changed → needs Drift migration commands

4. **Files likely to be touched**: Identify specific paths using VESPR structure
</pre_generation_analysis>

Create the prompt(s) and save to the prompts folder.

**For single prompts:**
- Generate one prompt file following the VESPR-specific patterns below
- Save as `.prompts/[number]-[name].md`

**For multiple prompts:**
- Determine how many prompts are needed (typically 2-4)
- Generate each prompt with clear, focused objectives
- Save sequentially: `.prompts/[N]-[name].md`, `.prompts/[N+1]-[name].md`, etc.
- Each prompt should be self-contained and executable independently

**Prompt Construction Rules**

Always Include:
- XML tag structure with clear, semantic tags
- Reference to VESPR patterns and conventions from CLAUDE.md
- Explicit file paths using VESPR module structure
- Success criteria with verification steps
- Code generation commands when models are created/modified

Conditionally Include (based on analysis):
- **Extended thinking triggers** for complex architecture decisions
- **Platform considerations** when native/web diverge
- **CIP documentation** reading when implementing Cardano standards
- **Build commands** when code generation is needed

<prompt_patterns>

**For New Feature Tasks (Page/Screen/Modal)**:

```xml
<objective>
[Clear statement of what feature needs to be built]
This feature will [explain user value and context].
</objective>

<context>
Project: VESPR Wallet (Flutter, Cardano blockchain)
Module: lib/features/[feature_name]/ (feature-folder architecture)

Read project conventions:
@CLAUDE.md

Examine reference implementations for patterns:
@lib/features/currency/ (full domain + presentation layers)
@lib/features/deeplinks/ (use_cases, services, widgets)
@lib/features/midnight_redemption/ (simpler presentation-only)

Reuse common code from:
- `lib/ui_components/` - Shared UI components (CoreRow, CoreButton, etc.)
- `lib/utils/` - Utility functions and extensions
- `lib/repo/` - Existing repositories (if data layer needed)
</context>

<requirements>
Functional:
- [Specific UI requirements]
- [User interactions]
- [Navigation flow]

Technical (VESPR Standards):
- Use feature-folder pattern: all code in `lib/features/[feature_name]/`
- Use Riverpod with Freezed sealed state class (loading/data/error pattern)
- Follow AutoRoute for navigation (never Navigator.of)
- Use context.textTheme and context.colorScheme for theming
- Use SizeConst for spacing
- Use EdgeInsetsDirectional for RTL support
- Line length: 120 characters, trailing commas
</requirements>

<implementation>
Feature folder structure to create:

```
lib/features/[feature_name]/
├── domain/                              # (if business logic needed)
│   ├── models/
│   │   └── [feature]_data.dart         # Domain models (@freezed)
│   ├── services/
│   │   └── [feature]_service.dart      # Business services (@injectable)
│   └── use_cases/
│       └── [feature]_use_case.dart     # Use case classes
├── presentation/
│   ├── notifiers/
│   │   └── [feature]_notifier.dart     # State + Notifier (Freezed sealed class)
│   ├── pages/
│   │   └── [feature]_page.dart         # Main page (@RoutePage, ConsumerWidget)
│   ├── modals/
│   │   └── [feature]_modal.dart        # Bottom sheets/dialogs
│   └── widgets/
│       └── [feature]_widget.dart       # Feature-specific widgets
└── core/                                # (optional)
    └── [feature]_config.dart           # Constants, configuration
```

**Notifier pattern** (in presentation/notifiers/):
```dart
part "[feature]_notifier.freezed.dart";

@freezed
sealed class [Feature]State with _$[Feature]State {
  const [Feature]State._();
  const factory [Feature]State.loading() = [Feature]State_Loading;
  const factory [Feature]State.error() = [Feature]State_Error;
  const factory [Feature]State.data({
    required [DataType] data,
  }) = [Feature]State_Data;
}

final [feature]NotifierProvider = snpAutoDispose<[Feature]Notifier, [Feature]State>();

@injectable
class [Feature]Notifier extends BaseStateNotifierV2<[Feature]State, void> {
  [Feature]Notifier() : super(const [Feature]State.loading());
}
```

**Page pattern** (in presentation/pages/):
```dart
@RoutePage()
class [Feature]Page extends ConsumerWidget {
  const [Feature]Page({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch([feature]NotifierProvider);
    return switch (state) {
      [Feature]State_Loading() => const LoadingWidget(),
      [Feature]State_Error() => const ErrorWidget(),
      [Feature]State_Data(:final data) => _DataContent(data: data),
    };
  }
}
```

**Route registration** (add to lib/routes/app_router.dart):
```dart
AutoRoute(page: [Feature]Route.page),
```
</implementation>

<verification>
Before declaring complete:
1. Run `sh ./scripts/build.sh` to generate Freezed code
2. Run `dart analyze` - no errors or warnings
3. Run `dart format lib/features/[feature_name] --line-length=120`
4. Verify AutoRoute registration in app_router.dart
5. Test on hot reload: `flutter run -d [device]`
</verification>

<success_criteria>
- [ ] Feature folder created at lib/features/[feature_name]/
- [ ] Separation of concerns: domain/ (optional) vs presentation/
- [ ] Notifier uses Freezed sealed state with exhaustive switch
- [ ] Notifier is @injectable with proper provider definition
- [ ] Page uses ConsumerWidget with @RoutePage()
- [ ] Common code reused from lib/ui_components/, lib/utils/
- [ ] Theme values from context (no hardcoded colors)
- [ ] RTL-compatible spacing (EdgeInsetsDirectional)
- [ ] Code analysis passes
</success_criteria>
```

**For Repository/Data Layer Tasks**:

```xml
<objective>
[What data operation needs to be implemented]
This enables [explain how this supports the app].
</objective>

<context>
Project: VESPR Wallet
Module: lib/repo/ (repositories), core/lib/persistence/ (database)

Examine existing patterns:
@lib/repo/wallet_repository.dart
@lib/repo/ada_repository.dart
@core/lib/persistence/database_impl/vespr_database_impl.vm.dart
</context>

<requirements>
Data Flow:
- [Source: API, Database, or both]
- [Caching strategy if applicable]
- [Stream vs one-shot retrieval]

Technical Patterns:
- Use ValueStream<CachedAsyncValue<T>> for reactive cached data
- Repository should be @lazySingleton
- Use RxDart combineWith/transform patterns for computed streams
</requirements>

<implementation>
1. **API Client** (if remote data):
   `./lib/api/[feature]_api.dart`

2. **Repository**:
   `./lib/repo/[feature]_repository.dart`
   - @lazySingleton annotation
   - Inject dependencies via constructor
   - Use late final ValueStream for reactive data

3. **Database** (if local persistence needed):
   - Add table in `./core/lib/persistence/`
   - Create DAO in `./core/lib/persistence/dao/`
   - Update schema version

If database schema changed:
```bash
cd core
dart run drift_dev schema dump lib/persistence/database_impl/vespr_database_impl.vm.dart drift_schemas/
dart run drift_dev schema steps drift_schemas/ lib/persistence/schema_versions.dart
```
</implementation>

<verification>
1. Run `sh ./scripts/build.sh` if models created
2. Run `dart analyze`
3. Test data flow manually or with unit test
</verification>
```

**For Model/DTO Tasks**:

```xml
<objective>
[What data model needs to be created]
Used for [explain where this model is used].
</objective>

<context>
Project: VESPR Wallet
Module: modules/models/ (API DTOs) or modules/pre_models/ (base types)

Examine existing patterns:
@modules/models/lib/src/[category]/[example].dart
</context>

<requirements>
- Use @freezed for immutable models
- Use @JsonSerializable for API DTOs
- Follow naming: PascalCase for classes, snake_case for JSON keys
</requirements>

<implementation>
Create model file:
`./modules/models/lib/src/[category]/[model_name].dart`

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part '[model_name].freezed.dart';
part '[model_name].g.dart';

@freezed
class ModelName with _$ModelName {
  const factory ModelName({
    required String fieldName,
    @JsonKey(name: 'json_field') String? optionalField,
  }) = _ModelName;

  factory ModelName.fromJson(Map<String, dynamic> json) => _$ModelNameFromJson(json);
}
```

After creating:
```bash
sh ./scripts/gen_models.sh
```
</implementation>

<verification>
1. Generated files exist: .freezed.dart and .g.dart
2. No analysis errors
3. JSON serialization works correctly
</verification>
```

**For Bug Fix Tasks**:

```xml
<objective>
Fix: [Clear description of the bug]
Expected behavior: [What should happen]
Actual behavior: [What currently happens]
</objective>

<context>
Affected files:
@[path/to/affected/file.dart]

Related code:
@[path/to/related/file.dart]
</context>

<!-- Include this section if Linear issue was fetched -->
<linear_context>
**Issue**: [VES-XXX] [Issue Title]
**Description**: [Full issue description from Linear]
**Acceptance Criteria**: [If present in Linear]
**Comments**: [Relevant comments from team members]
**Related Issues**: [Any linked issues]
</linear_context>

<!-- Include this section if Sentry error was fetched -->
<sentry_context>
**Error Type**: [Exception/Error type]
**Error Message**: [Full error message]
**Stack Trace**:
```
[Stack trace from Sentry]
```
**Affected Files**: [Files mentioned in stack trace]
**Frequency**: [How often this error occurs]
**First/Last Seen**: [When error was first/last reported]
</sentry_context>

<investigation>
1. Understand the current behavior by reading affected files
2. Identify root cause (not just symptoms)
3. Consider side effects of the fix
4. [If Sentry context] Analyze stack trace to pinpoint exact failure point
5. [If Linear context] Review all comments for additional context from team
</investigation>

<requirements>
- Fix must not break existing functionality
- Follow VESPR coding standards
- Prefer minimal, focused changes
- [If Linear issue] Address all acceptance criteria from Linear
</requirements>

<implementation>
[Specific fix approach]
</implementation>

<verification>
1. Bug is resolved
2. Related functionality still works
3. `dart analyze` passes
4. Consider adding test if regression-prone
5. [If Linear issue] Update Linear issue status after fix
</verification>

<commit_reference>
[VES-XXX] fix: [brief description of fix]
</commit_reference>
```

**For CIP Implementation Tasks**:

```xml
<objective>
Implement CIP-[NUMBER]: [CIP Title]
[Brief description of what this CIP enables]
</objective>

<context>
Project: VESPR Wallet (Cardano blockchain)

**CRITICAL**: Read CIP documentation first:
Fetch: https://raw.githubusercontent.com/cardano-foundation/CIPs/refs/heads/master/CIP-[NUMBER]/README.md

If the CIP is a draft (not merged to master), ask user for the PR URL.
</context>

<requirements>
- Implement according to CIP specification
- Follow existing CIP implementation patterns in codebase
- Consider backward compatibility
</requirements>

<implementation>
[After reading CIP documentation, specify implementation approach]
</implementation>

<verification>
1. Implementation matches CIP specification
2. Interoperates with other Cardano tools/wallets
3. Reference CIP number in code comments and commit message
</verification>
```

</prompt_patterns>

Output Format:

1. Generate prompt content with XML structure
2. Save to: `.prompts/[number]-[descriptive-name].md`
   - Number format: 001, 002, 003, etc. (check existing files in .prompts/ to determine next number)
   - Name format: lowercase, hyphen-separated, max 5 words describing the task
   - Example: `.prompts/001-implement-favorites-page.md`
3. File should contain ONLY the prompt, no explanations or metadata
</step_1_generate_and_save>

<decision_tree>
After saving the prompt(s), present this decision tree to the user:

---

**Prompt(s) created successfully!**

<single_prompt_scenario>
If you created ONE prompt (e.g., `.prompts/005-implement-feature.md`):

✓ Saved prompt to .prompts/005-implement-feature.md

What's next?

1. Run prompt now
2. Review/edit prompt first
3. Save for later
4. Other

Choose (1-4): _

If user chooses #1, invoke via SlashCommand tool: `/run-prompt 005`
</single_prompt_scenario>

<parallel_scenario>
If you created MULTIPLE prompts that CAN run in parallel:

✓ Saved prompts:
  - .prompts/005-implement-models.md
  - .prompts/006-implement-api.md
  - .prompts/007-implement-ui.md

Execution strategy: These prompts can run in PARALLEL (independent tasks)

What's next?

1. Run all prompts in parallel now (launches sub-agents simultaneously)
2. Run prompts sequentially instead
3. Review/edit prompts first
4. Other

Choose (1-4): _

If user chooses #1, invoke: `/run-prompt 005 006 007 --parallel`
If user chooses #2, invoke: `/run-prompt 005 006 007 --sequential`
</parallel_scenario>

<sequential_scenario>
If you created MULTIPLE prompts that MUST run sequentially:

✓ Saved prompts:
  - .prompts/005-create-models.md (must run first - generates code)
  - .prompts/006-implement-repository.md (depends on models)
  - .prompts/007-implement-ui.md (depends on repository)

Execution strategy: These prompts must run SEQUENTIALLY (dependencies: 005 → 006 → 007)

What's next?

1. Run prompts sequentially now (one completes before next starts)
2. Run first prompt only (005-create-models.md)
3. Review/edit prompts first
4. Other

Choose (1-4): _

If user chooses #1, invoke: `/run-prompt 005 006 007 --sequential`
If user chooses #2, invoke: `/run-prompt 005`
</sequential_scenario>

---

</decision_tree>
</process>

<success_criteria>
- Intake gate completed (AskUserQuestion used for clarification if needed)
- User selected "Proceed" from decision gate
- Prompt(s) generated with VESPR-specific patterns and conventions
- Files saved to .prompts/[number]-[name].md with correct sequential numbering
- Decision tree presented to user based on single/parallel/sequential scenario
- User choice executed (SlashCommand invoked if user selects run option)
</success_criteria>

<meta_instructions>
- **Issue detection first**: ALWAYS run step_0_issue_detection before anything else. If VES-* pattern found, MCP calls are MANDATORY.
- **MCP failures are blocking**: If Linear or Sentry MCP is not accessible when needed, STOP immediately and inform user. Do NOT proceed with prompt creation.
- **Intake second**: After issue detection, complete step_0_intake_gate. Use AskUserQuestion for structured clarification.
- **Decision gate loop**: Keep asking questions until user selects "Proceed"
- Use Glob tool with `.prompts/*.md` to find existing prompts and determine next number in sequence
- If .prompts/ doesn't exist, use Write tool to create the first prompt (Write will create parent directories)
- Keep prompt filenames descriptive but concise
- Always include VESPR-specific patterns (Riverpod, Freezed, AutoRoute, etc.)
- Include build commands when code generation is needed
- **Linear context in prompts**: If Linear issue was fetched, include <linear_context> section in generated prompt
- **Sentry context in prompts**: If Sentry issue was fetched, include <sentry_context> section in generated prompt
- **Commit references**: If Linear issue present, include commit message template with [VES-XXX] prefix
- After saving, present the decision tree as inline text (not AskUserQuestion)
- Use the SlashCommand tool to invoke /run-prompt when user makes their choice
</meta_instructions>
