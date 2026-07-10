# Agent Skills

This project keeps Flutter and Dart agent skills in the standard universal
workspace location:

```text
.agents/skills/
```

Agents should use these skills with progressive disclosure: inspect the
available skill names, then read only the matching
`.agents/skills/<skill>/SKILL.md` for the current task.

## Installed Sources

| Source | Purpose | Installed command |
| --- | --- | --- |
| `flutter/skills` | Flutter workflows such as widget tests, integration tests, responsive layout, routing, localization, JSON serialization, and layout fixes. | `npx skills add flutter/skills --skill '*' --agent universal --yes` |
| `dart-lang/skills` | Dart workflows such as unit tests, static analysis, mocks, coverage, dependency conflicts, FFI, and pattern matching. | `npx skills add dart-lang/skills --skill '*' --agent universal --yes` |
| `anthropics/claude-plugins-official` | General code quality workflows such as code simplification and refinement. | `curl -fsSL https://raw.githubusercontent.com/anthropics/claude-plugins-official/main/plugins/code-simplifier/agents/code-simplifier.md -o .agents/skills/code-simplifier/SKILL.md` |
| `wondelai/skills` | Native iOS interface design guidance based on Apple Human Interface Guidelines; use for the Flutter app's iOS-style UI design, not SwiftUI implementation. | `python3 /Users/wangsicheng/.codex/skills/.system/skill-installer/scripts/install-skill-from-github.py --repo wondelai/skills --path ios-hig-design --dest .agents/skills --ref main` |

After installing or updating Flutter skills, remove
`.agents/skills/flutter-apply-architecture-best-practices` so the repository
continues to use its checked-in architecture rules.

The local install was populated from shallow Git clones because `npx` was not
available on the session PATH. If `npx` is available, prefer the commands above.
If not, use this fallback from the repository root:

```bash
rm -rf /tmp/flutter-agent-skills /tmp/dart-agent-skills
git clone --depth 1 https://github.com/flutter/skills.git /tmp/flutter-agent-skills
git clone --depth 1 https://github.com/dart-lang/skills.git /tmp/dart-agent-skills
mkdir -p .agents/skills
cp -R /tmp/flutter-agent-skills/skills/. .agents/skills/
cp -R /tmp/dart-agent-skills/skills/. .agents/skills/
rm -rf .agents/skills/flutter-apply-architecture-best-practices
```

## Installed Inventory

The generic `flutter-apply-architecture-best-practices` skill is intentionally
not installed. This repository already defines its architecture in
`docs/harness/ARCHITECTURE.md`; when architecture guidance is needed, use that
project-specific document as the source of truth.

Flutter skills:

- `flutter-add-integration-test`
- `flutter-add-widget-preview`
- `flutter-add-widget-test`
- `flutter-build-responsive-layout`
- `flutter-fix-layout-issues`
- `flutter-implement-json-serialization`
- `flutter-setup-declarative-routing`
- `flutter-setup-localization`
- `flutter-use-http-package`

Dart skills:

- `dart-add-unit-test`
- `dart-build-cli-app`
- `dart-collect-coverage`
- `dart-fix-runtime-errors`
- `dart-generate-test-mocks`
- `dart-migrate-to-checks-package`
- `dart-resolve-package-conflicts`
- `dart-run-static-analysis`
- `dart-setup-ffi-assets`
- `dart-use-ffigen`
- `dart-use-pattern-matching`

General skills:

- `code-simplifier`

iOS design skills:

- `ios-hig-design`

## Harness Rules

- Keep official skills in `.agents/skills/`, not under `lib/`.
- Do not use `flutter-add-widget-test` for UI behavior in this project. UI
  acceptance belongs in Maestro flows; use Flutter/Dart tests for non-UI logic,
  data mapping, BLoC behavior, repositories, configuration, and harness rules.
- Use project architecture rules from `docs/harness/ARCHITECTURE.md` when a
  generic Flutter skill conflicts with this repository's feature-first layout.
- Do not automatically update skills from `init.sh`; network updates should be
  deliberate and recorded in `progress.md` and `feature_list.json`.
- Use `ios-hig-design` for iOS-style UI design decisions in this Flutter app;
  apply its platform guidance without introducing SwiftUI implementation code.
- Run `fvm dart run tool/harness.dart structure` after adding, removing, or
  updating project-local skills.
