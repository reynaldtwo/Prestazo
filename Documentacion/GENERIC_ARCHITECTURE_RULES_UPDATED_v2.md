---
trigger: always_on
---

# Generic Flutter Project - Coding Standards & Architecture Rules

> **Critical**: These rules are **mandatory** for all code contributions. Violations must be corrected before merging.


## 0. Assistant Communication & Output Rules (MANDATORY)

These rules apply to the AI agent (Antigravity) whenever it responds or delivers work for this project.

- **Language**: Always respond in **Spanish**.
- **Brevity**: Be **short, precise, and actionable**. Avoid unnecessary explanations; prioritize steps, commands, and file paths.
- **No Guessing**: Never invent details. If information is missing, state assumptions explicitly or ask for the minimum required input.
- **Consistency**: Use the project’s terminology and established naming conventions; do not introduce new terms without justification.

## 1. Architecture Patterns

### 1.1 Feature-First Structure

We organize code by **feature**, not by layer. This ensures scalability and modularity.

- **Rule**: Create a root folder for every major feature in `lib/features/`.
- **Example**: `auth`, `profile`, `feed`, `settings`.

### 1.2 Clean Architecture Layers

Inside *every* feature folder, you must implement strict **Clean Architecture** layers:

```
lib/features/<feature_name>/
├── domain/              # PURE DART. Business Rules & Entities.
│   ├── entities/        # Immutable model objects.
│   ├── repositories/    # ABSTRACT interfaces (contracts).
│   └── services/        # Domain logic/use-cases.
├── data/                # DATA HANDLERS. API, DB, DTOs.
│   ├── models/          # DTOs (Data Transfer Objects).
│   ├── repositories/    # CONCRETE implementations of interfaces.
│   └── datasources/     # Remote/Local data sources (Http, Sqlite).
├── presentation/        # FLUTTER UI. Visuals & State.
│   ├── bloc/            # State Management (Events, States).
│   ├── pages/           # Scaffold widgets (Screens).
│   └── widgets/         # Reusable components.
```

### 1.3 The Repository Pattern

Strictly decouple business logic from data retrieval.

1.  **Domain Definition**: Define the interface `abstract class IFeatureRepository` in `domain/repositories/`.
2.  **Data Implementation**: Implement the class `class FeatureRepository implements IFeatureRepository` in `data/repositories/`.
3.  **Dependency**: The **Presentation** layer (BLoC) must **ONLY** depend on the **Domain Interface**. It must NEVER know about the Data implementation.

### 1.4 Dependency Rules (CRITICAL)

```
Presentation → Application (BLoC) → Domain ← Data
```

- ✅ **Allowed**: `presentation` imports `bloc`, `bloc` imports `domain`, `data` imports `domain`.
- ❌ **Forbidden**: `domain` imports anything from outside, `data` imports `presentation`, `bloc` imports `data`.

## 2. Code Harmonization (CRITICAL)

**Consistency is Key.** All features must look and behave identically in terms of code structure.

- **Structural Harmony**: If Feature A strictly separates `entities` and `models`, Feature B cannot mix them.
- **Pattern Harmony**: If one BLoC uses `Sealed Classes` for state, **ALL** BLoCs must use Sealed Classes.
- **Naming Harmony**:
    - Repositories: `IFeatureRepository`, `FeatureRepository`.
    - BLoCs: `FeatureBloc`, `FeatureEvent`, `FeatureState`.
    - Pages: `FeaturePage`.

## 3. Design System (MANDATORY)

### Typography - NEVER use `Text()` directly

Create and use a standardized text widget (e.g., `AppText` or `DesignSystemText`).

```dart
// ✅ CORRECT
AppText('Title', variant: TextVariant.titleLarge)

// ❌ WRONG
Text('Title', style: TextStyle(fontSize: 24))
```

### Colors - NEVER hardcode colors

Use the `Theme.of(context).colorScheme` or a dedicated semantic color extension.

```dart
// ✅ CORRECT
Container(color: Theme.of(context).colorScheme.primary)

// ❌ WRONG
Container(color: Colors.blue)
Container(color: Color(0xFF123456))
```

### Spacing

Use standard spacing constants or 8-point grid increments.

```dart
const SizedBox(height: 8)
const SizedBox(height: 16)
const EdgeInsets.all(16)
```


### Layout & Information Architecture (MANDATORY)

- **Logical field order**: Inputs must follow a natural sequence (e.g., identity → contact → details → confirmation).
- **Grouping**: Group related fields into clearly separated sections with headings (e.g., “Datos del cliente”, “Detalles del préstamo”).
- **Required vs optional**: Required fields must be visually clear (label, hint, and validation message).
- **Validation placement**: Show validation close to the field, with a specific message and a corrective hint.
- **Focus flow**: Keyboard/tab order must match the visual order; avoid jumps that confuse the user.

### Text Overflow & Visual Harmony (MANDATORY)

- **No overflow is acceptable**: Text must never exceed the bounds of cards/components or cause pixel overflow.
- **Use constraints**: Prefer `Flexible/Expanded`, and enforce `maxLines` + `overflow: TextOverflow.ellipsis` where appropriate.
- **Responsive typography**: Do not use excessively large or tiny text. Use Design System variants and keep hierarchy consistent.
- **Consistency across screens**: Keep spacing, headings, and component density consistent with the first screens already implemented.
- **Long-language safety**: Always consider that translations can be longer; design must still look clean in all supported locales.


## 4. Localization (l10n)

**NEVER** hardcode UI strings. All user-facing text must be in ARB files.

```dart
// ✅ CORRECT
AppText(context.l10n.helloWorld)

// ❌ WRONG
Text('Hello World')
```


### Multi-language From Day 1 (STRICT)

- Every feature must be implemented as **multi-language** from the start. It is not a “later task”.
- **Definition of Done (DoD)** for any UI change:
  - All user-visible strings are in ARB and wired through `context.l10n.*`.
  - Keys exist for **all supported locales** (at minimum `es` and `en`).
  - The UI is verified in **at least two locales** (one being Spanish).
  - Layout remains stable with longer translations (no clipping/overflow).


## 5. Code Quality Standards

### File Size Limits (STRICT)

- **Limit**: Files should not exceed **300 lines**.
- **Action**: If a file exceeds this limit, **IMMEDIATELY refactor**.
- **Strategy**: Extract widgets, move logic to BLoC/Domain, or create helper classes.

### Linting - Zero Tolerance


#### Baseline Ruleset (MANDATORY): `very_good_analysis`

To enforce consistent linting (including documentation discipline), the project must use `very_good_analysis`.

- Add dependency in `pubspec.yaml` (dev dependency):
  - `dev_dependencies:`
    - `very_good_analysis: ^10.0.0`
- If you intentionally want the newest **pre-release** (not recommended for production), check pub.dev versions.

- In `analysis_options.yaml`, include the ruleset:
  - `include: package:very_good_analysis/analysis_options.yaml`
- **Policy**:
  - `flutter analyze` must be clean before delivery.
  - Treat relevant warnings as blockers (especially documentation and unused/unsafe patterns).

> Note: Some documentation lints apply primarily to **public** APIs (e.g., `public_member_api_docs`). Private helpers still require comments when logic is non-trivial (see Documentation Standards).


- The project must pass `flutter analyze` with **zero** issues.
- No unused imports, variables, or unawaited futures.

### Performance

- Use `const` constructors whenever possible.
- Use `const` collections.

## 6. Tooling & Refactoring (MCP)

**Mandatory Usage of Dart MCP**:

- Use **Dart MCP (Model Context Protocol)** tools for all analysis and refactoring tasks to ensure safety and correctness.
- **Analyze First**: Run analysis before and after applying changes.
- **Automated Refactoring**: Rely on tools for renaming, extracting methods/widgets, and fixing implementation details.

## 7. Testing Requirements

- **Domain**: 100% coverage (Unit tests).
- **Application (BLoC)**: 80%+ coverage (Bloc tests).
- **Presentation**: Critical user flows (Widget/Integration tests).

## 8. File Organization & Naming

- **Files**: `snake_case.dart`
- **Classes**: `PascalCase`
- **Variables**: `camelCase`
- **Imports**: Sorted alphabetically.

## 9. Error Handling Pattern

### BLoC Error States

Always define explicit error states:

```dart
sealed class FeatureState extends Equatable {}

final class FeatureError extends FeatureState {
  const FeatureError(this.message, {this.exception});
  final String message;
  final Exception? exception;
  
  @override
  List<Object?> get props => [message, exception];
}
```

### Try-Catch in BLoCs

Never swallow exceptions silently:

```dart
// ✅ CORRECT
Future<void> _onLoad(LoadEvent event, Emitter<State> emit) async {
  emit(const Loading());
  try {
    final data = await _repository.getData();
    emit(Loaded(data));
  } catch (e, stackTrace) {
    emit(FeatureError('Failed to load data: $e'));
    // Optionally log: _logger.error(e, stackTrace);
  }
}

// ❌ WRONG - Silent failure
try {
  await doSomething();
} catch (e) {
  // Empty catch block
}
```

## 10. Async/Await Best Practices

### Always await or explicitly ignore

```dart
// ✅ CORRECT - Awaited
await _repository.saveData(data);

// ✅ CORRECT - Fire and forget (explicit)
unawaited(_analytics.logEvent('action'));

// ❌ WRONG - Unawaited future (lint error)
_repository.saveData(data);  // Missing await!
```

### Stream Subscriptions

Always cancel subscriptions in `dispose()` or `close()`:

```dart
class FeatureBloc extends Bloc<Event, State> {
  StreamSubscription<Data>? _subscription;

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
```

## 11. Dependency Injection

### Provider/GetIt Pattern

Register dependencies at app initialization:

```dart
// ✅ CORRECT - Inject via constructor
class FeatureBloc extends Bloc<Event, State> {
  FeatureBloc({required IFeatureRepository repository})
      : _repository = repository,
        super(const Initial());

  final IFeatureRepository _repository;
}

// ❌ WRONG - Direct instantiation
class FeatureBloc extends Bloc<Event, State> {
  FeatureBloc() : super(const Initial()) {
    _repository = FeatureRepository(); // Hard dependency!
  }
}
```

## 12. Documentation Standards


### Business Rules Register (MANDATORY)

Business rules must be documented in a human-readable and developer-friendly way, with examples.

- Maintain a single source of truth:
  - `Documentation/BUSINESS_RULES.md`
- For every feature/fix that changes behavior, update the register with:
  - **Rule name** (short)
  - **Description** (clear and explicit)
  - **Rationale** (why it exists)
  - **Examples** (inputs/outputs and UI examples)
  - **Edge cases** (what can go wrong, validations, limits)
  - **Related screens/flows** (links/paths)
  - **Data impact** (DB fields, API contracts, migrations)

Recommended format:

```md
## <Feature> / <Module>

### Rule: <Short name>
- Description:
- Rationale:
- Example(s):
- Edge cases:
- Data impact:
- Notes:
```

### Code Commenting Standard (STRICT)

- **All new or modified code must be understandable without reverse-engineering.**
- Add documentation for:
  - Every **class** and **public method** (`///` Dart doc comments).
  - Every **non-trivial method** (public or private): short comment describing intent (“what/why”, not “how”).
  - Complex blocks/algorithms: inline comments explaining the logic and assumptions.

**Enforcement**:
- Use `very_good_analysis` as the baseline lint ruleset.
- If analysis reports missing documentation for public APIs, documentation must be added immediately.


### Public API Documentation

Every public class, method, and property must have `///` doc comments:

```dart
/// Manages product catalog operations.
///
/// Provides CRUD operations for products including
/// filtering by category and search functionality.
class CatalogBloc extends Bloc<CatalogEvent, CatalogState> {
  /// Creates a [CatalogBloc] with the given [repository].
  CatalogBloc({required IProductRepository repository});

  /// The current list of products.
  List<Product> get products => state.products;
}
```

### Comment Styles

- `///` for public API documentation (Dart doc comments).
- `//` for inline implementation notes.
- `// TODO(username):` for pending work.
- `// FIXME:` for known bugs.

## 13. Development Workflow

### Before Starting a Feature

1. **Impact Review (MANDATORY)**: Before writing code, do a quick impact analysis and write it down (5–10 lines):
   - What screens/flows will change?
   - What data/contracts will change (models, repositories, APIs, local DB)?
   - What i18n keys must be added/updated (ARB)?
   - What Design System components/tokens will be reused or extended?
   - Backward-compatibility risks (especially DB migrations / restored backups).

2. Read the feature requirements end-to-end (including edge cases).
3. Check if similar features already exist (reuse the same patterns).
4. Create/confirm the folder structure: `domain/`, `data/`, `presentation/`.
5. If the change touches persistence (local DB / API contracts), plan the migration/versioning upfront (see “Database Changes” below).

### During Development

1. **Domain First**: Define entities and repository interfaces.
2. **Data Layer**: Implement repositories and data sources.
3. **Presentation**: Build state management, then Pages, then Widgets.
4. **No Hardcoding (STRICT)**:
   - No hardcoded strings in UI (must be i18n keys).
   - No hardcoded URLs/endpoints/IDs/ports/environment values (must come from configuration).
   - No hardcoded styles/colors (must use the Design System).
5. **Localization (MANDATORY)**: Add/update ARB keys for *every* new/changed user-visible label.
6. **Design Consistency (MANDATORY)**: Reuse existing components/tokens. If a new variant is needed, add it to the Design System once and reuse it everywhere.
7. **Tests (MANDATORY)**: Add or update tests for the new behavior (at least one happy-path + one edge case when feasible).
8. **Documentation (MANDATORY)**: Add short `///` docs and comments for non-trivial logic so another developer can maintain it.

### Worklog & Task Tracking (MANDATORY)

- Maintain a **single** ongoing worklog file:
  - `Documentation/DEV_WALKTHROUGH.md`
  - Append updates under a daily header, e.g.:
    - `## 2025-12-30`
      - What changed, why, files touched, migration notes, follow-ups.
- Maintain a **single** task list:
  - `Documentation/TASKS.md`
  - Keep it current; do not create scattered “todo” documents.

### Database Changes & Migrations (CRITICAL)

Whenever you add/rename/remove a column, table, index, or any persisted contract:

1. **Schema + Version Bump (MANDATORY)**:
   - Update the schema definition *and* bump the DB/schema version used by the app.
2. **Migration (MANDATORY)**:
   - Implement the migration in the project’s migration mechanism (e.g., `onUpgrade` for `sqflite`, or the equivalent for your ORM).
3. **Migration Smoke Test (MANDATORY)**:
   - Verify upgrade from the previous version to the new version works without crashes.
   - Verify the “restore backup” scenario (restored older DB opened by the new app) also migrates cleanly.
4. **Definition of Done**:
   - If the version is not bumped and the migration is not implemented/tested, the change is **incomplete** and must not be shipped.


### QA Build Delivery (MANDATORY)

For every fix/feature/task, when the implementation is complete and passes quality gates, deliver a **fresh** APK build to QA.

1. **Remove previous APK artifacts**:
   - Delete any previously generated `.apk` you created for this task (do not reuse it).
2. **Clean the workspace**:
   ```bash
   flutter clean
   flutter pub get
   ```
3. **Rebuild from scratch (Android)**:
   - Debug APK (typical for functional QA):
     ```bash
     flutter build apk --debug
     ```
   - Release APK (only when explicitly requested):
     ```bash
     flutter build apk --release
     ```
4. **Deliverable rule**:
   - QA must always test the APK produced **after** the clean rebuild, never an incremental artifact.


### Before Committing

```bash
# 1) Format
dart format lib test

# 2) Static analysis (must be clean)
flutter analyze

# 3) Tests (must pass)
flutter test

# 4) Build smoke test (pick the relevant target for the task)
# flutter build apk --debug
# flutter build web --debug
# flutter build windows --debug

# 5) Manual review
# - No hardcoded strings/URLs/styles
# - All new UI text is localized (ARB)
# - Design System consistency maintained
# - DB version/migrations present (if schema changed)
```

## 14. Git Conventions

### Commit Messages

Use conventional commits:

- `feat:` New feature.
- `fix:` Bug fix.
- `refactor:` Code restructuring.
- `docs:` Documentation changes.
- `test:` Adding tests.
- `chore:` Build/tooling changes.

**Example**: `feat(catalog): add product filtering by category`

### Branch Naming

- `feature/<name>` for new features.
- `fix/<issue-id>-<description>` for bug fixes.
- `refactor/<area>` for refactoring.

---

## Summary Checklist

1. ✅ **Feature-First Clean Architecture**: Strict folder structure.
2. ✅ **Repository Pattern**: Interface in Domain, Impl in Data.
3. ✅ **Code Harmonization**: Consistent patterns across features.
4. ✅ **Design System**: No hardcoded styles/colors.
5. ✅ **Localization**: No hardcoded strings.
6. ✅ **File Size**: < 300 lines, refactor immediately.
7. ✅ **Error Handling**: Explicit error states, no silent failures.
8. ✅ **Async Safety**: Await or `unawaited()`, cancel subscriptions.
9. ✅ **Dependency Injection**: Constructor injection only.
10. ✅ **Documentation**: `///` on all public APIs.
11. ✅ **MCP Tools**: Use for analysis and refactoring.
12. ✅ **Git Discipline**: Conventional commits, clean branches.
