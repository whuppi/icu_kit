<!--
============================================================================
AUTO-GENERATED — DO NOT EDIT
============================================================================
This file is rendered by:
  /Users/deepanshu/personal1/whuppi/.claude/scripts/stamp-agents.sh
from:
  /Users/deepanshu/personal1/whuppi/AGENTS.template.md
  with per-repo data inlined in the stamper itself.

To change content:
  - Workspace-wide: edit AGENTS.template.md, then re-run the stamper.
  - One repo only:  edit the `repo_data` case for "icu_kit" in stamp-agents.sh,
                    then re-run the stamper.
Manual edits to this file will be overwritten on the next stamp.
============================================================================
-->

# icu_kit

> **Public AI agent contract** for icu_kit — read by Cursor, OpenAI Codex, Aider, Devin, JetBrains Junie, and any AI tool that follows the [agents.md](https://agents.md) convention.
>
> Claude Code reads the deeper workspace config at `whuppi/.claude/rules/` and `whuppi/.claude/memory/` automatically — this AGENTS.md exists for every *other* AI tool.
>
> Stamped from `whuppi/AGENTS.template.md`. Per-repo content lives in the placeholder sections; everything else is identical workspace-wide.

---

## What this tool does

icu_kit is pure-Dart bindings to ICU4X for full ECMA-402 / Unicode
internationalization — number formatting, plural rules, date/time,
lists, collation, segmentation, normalization, bidi, case mapping,
IDNA. Native platforms load icu_capi via dart:ffi (the build hook
compiles it from the vendored ICU4X source); web loads a ~1 MB
WebAssembly build via dart:js_interop. One facade, six platforms, no
Flutter dependency, independent of unicode.org's own Dart package.
CLDR data ships bundled by default or loads lazily per-locale
(`bundleCldrData: false` + `IcuData.lazy`).

This repo is one tool inside the **whuppi** workspace — a multi-tool monorepo. The workspace ships shared engineering standards, code conventions, brand identity, and build patterns that apply across every tool. They're documented in three layers:

- **Repo-specific architecture, design, reference:** `./docs/`
- **Workspace human-readable standards:** `../docs/` (when this repo is cloned as part of the whuppi workspace) — engineering principles, decision frameworks, secret/CI patterns
- **Workspace AI-only directives:** `../.claude/rules/` (Claude Code reads these automatically; other AI tools can read them as supplementary context)

If you're working on this tool standalone (cloned outside the workspace), the in-repo `./docs/` is your authority; ignore the workspace pointers.

---

## Build and test commands

Run these after every code change. A failing test or analyzer error means the task is not done — don't suppress with `// ignore:`, `# noqa`, or `--no-verify`. Fix the underlying issue.

```bash
# Setup (needs FVM + the Rust toolchain — the build hook compiles icu_capi)
make hooks           # activate git hooks (once after cloning)
fvm install
fvm dart pub get
make check           # lint-shell + analyze (dart + rust patch gate) +
                     # analyze-floor + platforms + test-guards +
                     # VM tests + Chrome tests
make build-wasm      # rebuild web_assets/icu4x.wasm (nightly Rust + wasm-opt)
```

---

## Code style

Match the style of existing code in this repo first. Workspace-wide standards live at:

- **Engineering standards** (seven questions before every decision, env-blind code, twelve-factor checklist): `../docs/universal/development-standards.md`
- **Secrets and environments** (GitHub Environments, branch=env, security walls, files-not-env-vars): `../docs/universal/secrets-and-environments.md`
- **Python tools** (SDK/CLI/MCP three-layer pattern, ruff config, hatchling): `../.claude/rules/python-shared/sdk-cli-mcp-pattern.md`
- **Flutter packages** (opaque boundaries, async at edges, dependency flow): `../.claude/rules/flutter-shared/package-design.md`
- **Comments and doc-comments** (what earns a comment, what doesn't): `../.claude/rules/universal/comments.md`
- **Renaming anything** (sweep all references in one session): `../.claude/rules/universal/rename-hygiene.md`

When in doubt, read existing code in this repo and match it. Per-repo style consistency beats general-best-practice consistency.

---

## Tool-specific notes

- **vendor/icu4x is a fork with a patch branch — the fork contract is
  law.** Three refs only: `main` (clean upstream mirror), the patch
  branch `icu_kit/<version>-patches`, and the `icu@*` base tags. Every
  hand-edit to upstream files sits between `── icu_kit patch ──` /
  `── end icu_kit patch ──` markers; entirely-new files carry a
  whole-file marker line. `grep -rl "icu_kit patch"` inside the vendor
  IS the authoritative patch inventory. Recipes in docs/UPDATING.md.
- **Generated code is never hand-edited.** `lib/src/ffi/bindings/` and
  the vendor's `ffi/dart`+`ffi/npm` outputs come from Diplomat via
  `make regen-bindings`; fixes go in the generator post-step in
  tool/regen_bindings.dart, not the .g.dart files.
- **The Rust warning gate (make analyze) checks OUR patched lines
  only**, in both native feature configs (bundled CLDR on/off). An
  import used by one config must be cfg-gated, not left warning in the
  other.
- **`compiled_data` is a build-time choice, not a runtime one.**
  Consumers flip `bundleCldrData: false` in their pubspec user_defines
  for the lean binary and must then init `IcuData.lazy(...)`.

---

## Data, secrets, and gitignore

This repo's `.gitignore` is stamped from `../.gitignore.template` (workspace canonical). It already covers:

- `data/.env` and every other `.env` flavor (only `.env.example` / `.env.template` / `.env.sample` are committed)
- `data/auth/` (captured tokens, cookies, OAuth credentials)
- `data/db/*.sqlite*` (full app state — irreplaceable)
- `cookies*.json`, `*.token`, `*.pem`, `*.key`
- `output/`, `debug/`, `logs/`, `cache/`

Never commit a sensitive file even if it's somehow not gitignored — surface to the maintainer instead. The gitignore is defense-in-depth, not the only check.

---

## Working with AI agents

- **Run the test suite before claiming completion.** Always.
- **Don't add `TODO` comments as a substitute for fixing things.** If you found it, you own it — fix in this pass or surface to the maintainer.
- **Don't add backwards-compat shims** for code that hasn't shipped. Code assumes the latest schema and contracts; migrations handle old data once.
- **Don't refactor "for cleanliness" without a stated reason.** Surface the suggestion before changing surrounding code.
- **No co-authored-by AI in commits.** The maintainer is the author.
- **Never force-push protected branches** (`prod`, `main`, `dev`). Never skip pre-commit hooks.

For the engineering philosophy that informs every line of code in this workspace, see `../.claude/rules/universal/dc-engineering-philosophy.md` if available.

---

*This file is stamped from `whuppi/AGENTS.template.md`. The placeholder sections (`{{...}}`) are the only parts customized per repo. Re-stamping refreshes the shared content; per-repo placeholders are preserved.*
