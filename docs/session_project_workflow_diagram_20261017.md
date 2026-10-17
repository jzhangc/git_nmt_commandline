# Session Summary: Project Workflow Diagram + AGENTS.md Update (leak-free data transform)

## Date & Scope
- **Date:** Sat Oct 17 2026
- **Topic:** Update `docs/project_workflow.dot` / `.svg` and `AGENTS.md` to reflect the
  leak-free data-transformation redesign captured in
  `session_data_transform_leakage_20261016.md` (the Oct 16 change that moved min-max / z-score
  out of the input-processing scripts and into the ML/CV/prediction scripts, fit on the
  training set only).
- **Goal of this session:** make the `project_workflow` figure an accurate, readable
  data-flow diagram of the new leak-free pipeline, and keep `AGENTS.md` in step with it.

---

## What the figure now shows (the data flow)

The rewrite replaces the old directory-structure tree with a **top-to-bottom pipeline**:

```
INPUT PROCESSING (RAW)
  input_dat_process*.R  /  reg_input_dat_process*.R          (NO transform here)
        |
        +--> _2D.csv  (RAW features)
        +--> _data_processing_config.RData  (MINMAX_NORM · ZSCORE_STAND flags)
        |
        |  -k on
        +--> UNIVARIATE / PRIOR KNOWLEDGE (optional)  univariate*.R  ->  _w_prior.csv (RAW)
        |
        +-- (raw _2D.csv when -k off) -->  ML / CV STAGE
                                          ml_svm* · reg_ml_svm* · cv_ml_svm*  (+ _nofs twins)
        |
        v
  train / test split   (unchanged)
     +--> training rows
     +--> test rows
        |
        v
  fit_dat_transform(training)              [fit on TRAIN only]
        |
        v
  = train + apply_dat_transform(test)      [same fitted params -> LEAK-FREE]
        |
        v
  model + dat_transform_param
  (saved into *_final_svm/svr_model.Rdata)
        |
        v
  model RData loaded (provides dat_transform_param)  +  new data (.mat / .csv)
        |
        v
  apply_dat_transform(newdata, param)       [APPLY only -> NO re-fit]
        |
        v
  pred_classif.R  ->  predictions
```

Two side notes (dashed): the shared helper `R_files/dat_transform.R` (sourced by every
ML/CV/pred script), and the CV-only (-x) caveat (no external split -> global fit on the whole
set, so existing CV numbers were preserved).

---

## Key points about how the transform is now applied

- **Single source of truth = the model RData.** The per-feature transform parameters object
  `dat_transform_param` is persisted inside `_final_svm_model.Rdata` /
  `_final_svr_model.Rdata`. Prediction loads the model RData and reuses those exact params.
- **Flags are carried separately.** The `MINMAX_NORM` / `ZSCORE_STAND` switches are written by
  the input-processing scripts into `_data_processing_config.RData`; the ML/CV scripts read them
  back via `load_dat_process_config()` and then call `transform_train_test()`.
- **Regular ML scripts** (`ml_svm*`, `reg_ml_svm*`): fit on the **training** rows only, apply
  the same params to train + test.
- **CV-only scripts** (`cv_ml_svm*`, `cv_reg_ml_svm*`): no external split, so a **global** fit
  on the whole set is applied (to keep CV numbers identical to before).
- **Prediction scripts** (`pred_dat_process*`): `apply_dat_transform()` on the new batch using
  the training-fit `dat_transform_param` — **never re-fit** (columns matched by name).
- **Known residual leakage (pre-existing, out of scope):** the `-k` / `_w_prior.csv`
  univariate reduction still uses the whole dataset before the split; nested-CV global
  pre-transform remains visible inside RBioFS CV.

---

## Two problems in the previous figure, and how they were fixed

### 1. HTML tags rendered as literal text
- **Cause:** node labels used the plain-text form `label="..."` but contained markup
  (`<b>…</b>`, `<br/>`, `<font point-size=9>…</font>`). Graphviz treated the whole thing as
  text, so the SVG showed `&lt;b&gt;Input processing&lt;/b&gt;&lt;br/&gt;…`.
- **Fix:** switch to **HTML-like labels** `label=<…>`. In this graphviz (v14.1.2):
  - line breaks use `<BR/>` (self-closing); non-self-closing `<BR>` fails.
  - characters to escape: `&gt;` for `>`, `&lt;` for `<`, `&mdash;` for a dash,
    `&#8594;` for `→`, `&#8789;` for the "similar to / maps to" glyph, `&#183;` for `·`.
  - **`<B>`, `<I>`, `<U>`, and `<FONT …>` are NOT accepted** by this graphviz build — they
    raise a "missing '>'? bad nesting?" parse error. Emphasis/size changes are not available;
    the layout is kept flat with caps + line breaks for emphasis.
  - **Unquoted edge labels that contain spaces** also fail to parse; every multi-word edge
    label must be either quoted (`label="write raw features"`) or HTML-like
    (`label=<…>`). A bare empty `label=` is a syntax error too.
- **Verification:** `grep -oE '&lt;[a-zA-Z]' docs/project_workflow.svg` returns nothing (no
  literal tags left), and `python3 -m xml.etree` parses the SVG as valid XML.

### 2. Messy layout
- **Cause:** an earlier attempt used `splines=ortho`, which forced the 1782pt-wide,
  side-to-side zig-zag; plus a long dashed `source()` edge that ran the full height of the
  diagram from the helper box down to the prediction step.
- **Fix:**
  - removed `splines=ortho` (default splines read much better for a vertical pipeline);
  - dropped the long dashed `helper -> applyp` edge — the helper box already states it is
    "sourced by every ML / CV / pred script", so the long routing is redundant;
  - kept the CV-only note as a small dashed side-annotation off the `ML / CV STAGE` box.
- Final dimensions: **697 pt wide × 965 pt tall** (was 1782 × 910 before). 17 nodes, 18 edges.

---

## Files changed

| File | Change |
|------|--------|
| `docs/project_workflow.dot` | Fully rewritten: HTML-like labels; new 4-stage top-to-bottom data-flow layout; helper box + CV-only note as side annotations. |
| `docs/project_workflow.svg`  | Regenerated from the new `.dot` via `dot -Tsvg`. |
| `AGENTS.md` | New `## Data transformation (leak-free)` section; added `dat_transform.R` to the R-files list; listed the new leak-free artifacts (`_data_processing_config.RData`, `dat_transform_param` in the model RData) under *Output structure*. |
| `docs/session_project_workflow_diagram_20261017.md` | This summary. |

---

## How to regenerate

```
dot -Tsvg docs/project_workflow.dot -o docs/project_workflow.svg
```

(graphviz 14.1.2 on this machine. The PNG preview used for visual QA was rendered with
`dot -Tpng -Gdpi=120`.)

---

## Verification performed
- `dot -Tsvg` and `dot -Tpng` both succeed; no parse or "bad nesting" errors.
- No literal `&lt;tag>` strings remain in the SVG (grep negative).
- SVG parses as valid XML (`xml.etree.ElementTree.parse`).
- Every claim in the summary was cross-checked against the source code in
  `R_files/dat_transform.R` and the consuming scripts (`grep` for `load_dat_process_config`,
  `transform_train_test`, `dat_transform_param`, `apply_dat_transform`).
