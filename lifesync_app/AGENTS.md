# GEMINI AGENT RULES — FLUTTER/DART

## PRIMARY RULE

Only modify what the user explicitly requests.

Preserve all unrelated features, screens, UI, business logic, navigation, API contracts, database behavior, dependencies, configuration, and existing user changes.

Minimal diff. No unrelated refactoring. No unauthorized feature changes.

## BEFORE CODING

1. Inspect project structure, `pubspec.yaml`, architecture, and relevant source files.
2. Trace the requested feature from UI to state management, services, repositories, and API or database layers as applicable.
3. Identify exact files requiring changes and explain why.
4. Inspect Git status and existing diffs. Never overwrite unrelated user changes.
5. Establish expected behavior and relevant regression tests.

For significant changes, present an implementation plan before editing. Ask for approval if scope or impact is unclear.

## STRICT SCOPE

- Modify only files necessary for the requested fix.
- Do not refactor unrelated code or rewrite entire files unnecessarily.
- Do not modify unrelated screens, widgets, routes, providers, controllers, services, models, or repositories.
- Do not change UI design, colors, spacing, typography, animations, or navigation unless requested.
- Do not change state management architecture or introduce new patterns without approval.
- Do not add, remove, or upgrade packages in `pubspec.yaml` unless necessary and authorized.
- Do not modify API endpoints, request/response formats, authentication, authorization, or backend contracts without approval.
- Do not change database schemas, local storage formats, migrations, or existing user data without authorization.
- Do not modify Android or iOS native configuration unless required by the task.
- Do not edit signing configuration, secrets, `.env` files, or release settings without explicit authorization.
- Do not fix unrelated bugs automatically. Report them separately.

## FLUTTER/DART SAFETY

Preserve existing project conventions and architecture.

- Maintain widget behavior, navigation, state lifecycle, and existing public interfaces.
- Preserve loading, empty, success, and error states.
- Avoid unnecessary widget rebuilds and unrelated UI changes.
- Preserve null safety, validation, error handling, and asynchronous behavior.
- Handle `BuildContext` safely across asynchronous gaps.
- Do not introduce memory leaks, duplicate requests, or unnecessary subscriptions.
- Preserve existing platform behavior and permissions.
- Follow existing formatting, linting, naming conventions, and dependency choices.

## SHARED CODE AND DEPENDENCIES

Before changing shared widgets, utilities, providers, models, or services, identify their consumers.

Prefer a local fix over a shared-code change when both are safe.

If a shared change could alter unrelated feature behavior, stop and request approval.

Do not assume a change is safe merely because it compiles.

## DATABASE AND DATA SAFETY

Never reset, truncate, or delete existing user data to resolve a bug.

Do not perform destructive migrations or change persistence formats without explicit approval.

Preserve backward compatibility whenever possible.

Explain migration risks and rollback requirements before any approved destructive or incompatible change.

## TESTING

After implementation:

1. Review the complete diff.
2. Run `dart format` on modified Dart files when appropriate.
3. Run `flutter analyze`.
4. Run relevant tests using `flutter test`.
5. Run an appropriate build when needed and feasible.
6. Inspect test output and fix regressions caused by the requested change only.
7. Report every test or build that was not executed.

Do not claim tests or builds passed unless they actually succeeded.

Do not weaken or delete tests merely to obtain a passing result.

## STOP CONDITIONS

Stop and ask for approval if:

- Requirements are ambiguous.
- The requested fix requires unrelated feature changes.
- A shared component change has uncertain side effects.
- Data loss, destructive migration, security, or compatibility risks exist.
- Dependency upgrades or architectural changes appear necessary.
- Existing user changes could be overwritten.

Do not expand task scope without permission.

## FINAL REPORT

Report:

1. Root cause.
2. Files modified and reasons.
3. Exact behavior changed.
4. Tests and builds actually executed, with results.
5. Regression checks performed.
6. Remaining risks and unverified behavior.
7. Unrelated issues intentionally left untouched.

## FINAL REQUIREMENT

Fix the requested problem and preserve everything else.

Every modification must be justified by the requested task. If a change is unnecessary, do not make it.