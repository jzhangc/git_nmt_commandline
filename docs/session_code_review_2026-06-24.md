# Session Summary — NMT Codebase Comprehensive Review

**Session Date:** 2026-06-24 07:48 UTC
**Scope:** Full review of neuro-ml-tools (NMT) codebase, excluding `data/`, `conda_env_nmt/`, `z_legacy/`.
**Conversation Turns:** 3 (initial exploration + 3 targeted reviews + final request)

---

## Key Actions

1. **Project-wide exploration** — Mapped the full directory tree, identified all 34 tracked files, documented the architecture: a bash-orchestrated ML pipeline calling 23 R scripts across 6 entry-point scripts for classification/regression on 2D tabular and 3D connectivity data.

2. **Shell script review (10 files)** — Analyzed `src/global_var`, `src/utils`, `scripts/config_init.sh`, `scripts/config_init_reg.sh`, `scripts/sys_check.sh`, all 4 `sys_init_*.sh` scripts, and `trigger_help_info.sh`. Found critical security issues, OS detection bugs, and widespread anti-patterns.

3. **R code review (20 files)** — Analyzed all 20 R scripts in `R_files/`. Found a critical regression-vs-classification model swap bug, broken loop logic in ROC-AUC extraction, and pervasive code duplication.

4. **Shell entry-point review (6 files)** — Reviewed all 6 entry scripts (`train_class_x.sh`, `train_reg_x.sh`, `predict_class.sh`, `connectivity_ml_x.sh`, `connectivity_ml_reg_x.sh`, `connectivity_predict.sh`). Found variable-before-assignment bugs and pipe data-flow issues.

5. **Config and docs review** — Reviewed all 7 config templates, `.gitignore`, and `README.md`. Found outdated references, missing parameters, and pervasive typos.

6. **Delivered consolidated findings report** with 30 categorized issues (3 critical, 7 high, 10 medium, 10 low).

---

## Summary of Critical Findings

| # | Severity | Finding |
|---|----------|---------|
| 1 | Critical | `source "$CONFIG_FILE"` allows arbitrary code execution via user-provided config |
| 2 | Critical | All 4 regression scripts call `rbioClass_svm` (classifier) instead of `rbioClass_svr` (regressor) |
| 3 | Critical | ROC-AUC extraction loops always process only the first element due to broken `next`/`break` logic |
| 4 | Critical | Predict scripts check variables (`nsamples_to_pred`, `mat_dim`) before assigning them from R output |
| 5 | High | Unconditional double normalization in prediction script produces inconsistent preprocessing |
| 6 | High | `quit()` on error paths lacks `status = 1`, so shells see success exit codes |
| 7 | High | `Rscript \| tee` inside backticks masks R exit status |
| 8 | High | OS detection bug: `[ $UNAMESTR=="Darwin" ]` always matches due to missing spaces |

---

## Efficiency Insights

- **Parallel exploration was effective** — Launching 4 review subagents (shell scripts, R files, entry points, config/docs) simultaneously completed the analysis in 4 parallel tracks instead of 4 sequential ones.
- **Task delegation worked well** for bulk review of large file groups. The main agent handled scoping, synthesis, and final consolidation.
- **The first exploration pass** correctly identified the project architecture (18 ML R files, 6 entry scripts, 4 data processing variants), which informed all subsequent targeted reviews.

---

## Process Improvements

1. **Add `set -euo pipefail`** to all shell scripts immediately — would have caught many of the unquoted variable bugs automatically.
2. **Run `shellcheck`** as part of any CI — would catch most bash anti-patterns (backticks, unquoted variables, wrong test operators).
3. **Add R linting** (`lintr` package) to catch typos, unused variables, and style inconsistencies early.
4. **Write integration tests** — the predict scripts' bug (checking var before assignment) would be caught by a simple end-to-end test.
5. **DRY refactor** should be a priority — 60-80% code duplication across R modeling scripts means any bug fix requires 12+ simultaneous edits.
6. **Config file parsing replacement** is the highest-security priority — replace `source "$CONFIG"` with a safe key=value parser.

---

## Interesting Observations

- The project uses a **shell-as-orchestrator** pattern where bash scripts call R as subprocesses, passing 60-77 positional parameters. This is a common pattern in bioinformatics but makes the code fragile.
- **18 R modeling scripts** share 60-80% identical code. The only variations are with/without feature selection, classification vs regression, and train vs CV mode — clear candidates for parameterizing into a single script or shared R module.
- **Self-hosted R packages** (`RBioFS`, `RBioArray`) are the core ML dependencies, fetched from GitHub at install time. This creates deployment fragility if the repos change.
- The `.gitignore` contains **12+ references to non-existent scripts** (v2 naming, `cv_train_class.sh`, etc.) from a pre-consolidation refactoring that wasn't fully cleaned up.
- The project has **no automated tests** — only ad-hoc `test.R` stubs and commented-out diagnostic code scattered throughout files.

---

## Total Session Cost

**Conversations:** 1
**Turns:** 3 (1 exploration + 3 targeted parallel reviews + 1 summary request)
**Subagents launched:** 4 (all in parallel in 1 batch)
**Files reviewed:** 46 unique files