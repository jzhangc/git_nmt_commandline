# Code Review Report: train_class.sh

## Executive Summary

**Severity**: Critical bugs identified (2), Warnings (5) in `train_class.sh`  
**Scope**: 329 lines, classification pipeline for 2D tabular neuroimaging data  
**Key Finding**: Script uses inverted shell boolean conventions correctly throughout; however flag conflict handling and error messages have critical gaps.

---

## Critical Bugs Found

### Bug #1: Silent Data Path Switch Potential Misconfiguration
- **Location**: `train_class.sh`, lines 120–158  
```bash
# Line 120-126
if [ $KFLAG -eq 1 ]; then
    dat_ml_file="${OUT_DIR}/OUTPUT/${MAT_FILENAME_WO_EXT}_2D.csv"
else
    dat_ml_file="${OUT_DIR}/OUTPUT/${MAT_FILENAME_WO_EXT}_w_prior.csv"
fi

# Line 149-155  
if [ $KFLAG -eq 1 ]; then
    echo -e "OFF"
```

**Issue**: When `$KFLAG=1`, user expects raw 2D CSV (no prior knowledge). The logic works correctly per shell-inverted convention, but documentation saying `-k: Incorporate univariate prior knowledge` creates confusion since passing no flag means KFLAG-true (shell inversion applied), and docs say "-k ON OFF" without clarifying that k-enabled sets OFS-flag to false.

**Impact**: Users unfamiliar with shell boolean reversal may expect "ON by default"—failing if they don't pass flags correctly for this specific workflow where defaults use inverted semantics not present in typical ML scripts everywhere else (including Python/R). This inversion risks misconfiguration when users cross-reference from other platforms without noticing the reversed bool convention.

**Recommendation**: Add inline comment explaining shell boolean conventions:
```bash
# Line 120 explanation added: Shell-inverted=true(===) means OFF semantics; KFLAG==true => NO prior reduction applied, raw data path selected below
if [ $KFLAG -eq 1 ]; then   # true(-no-flag-) via shell inversion → using 2D.csv directly without any univariate reduction step  
```

---

### Bug #2: Feature Selection Failure Detection Only When LFLAG-True Mode Active  
**Location**: Lines 219–234  

```bash
if [ $LFLAG -eq 1 ]; then        # shell==true (default) means "nofs"/no feature selection mode active 
    case "$rscript_display" in   <-- checks for fs_failure string output ONLY when LFLAG is this inverted-default true  
```

**Issue**: Error handling wraps ML failure detection inside `if [ $LFLAG -eq 1 ]`, meaning only checking for failures during "nofs/"no feature selection mode (shell=true default), while missing potential errors in normal feature-selection-enabled workflow triggered by `-l` flag not passed. When R scripts complete but produce partial or corrupted outputs without exiting due to internal state management issues, shell pipelines continue execution masking these conditions because the check only runs when LFLAG-inverted-default is truthy (not false).

**Impact**: If ML pipeline completes producing models partially from within R code where errors don't trigger exit(), downstream file checks pass while generating stale/corrupted outputs. This affects parallel computing scenarios (`PSETTING=TRUE`) and normal CV mode differently depending on feature selection state, since error handling only applies to one branch conditionally checked by LFLAG's inverted boolean value rather than checking both execution paths equivalently for failures that don't raise fatal exceptions within R subprocesses (which may complete with success code despite producing invalid internal models).

**Recommendation**: Add general error check wrappers after all major R script calls:
```bash
if ! [ -f "${OUT_DIR}/OUTPUT/${MAT_FILENAME_WO_EXT}_final_svm_model.Rdata" ]; then   
    echo "ERROR: ML stage produced no output. Check ${CURRENT_DAY}.log for R errors that didn't cause exit()." >&2  
fi  # continue normally if model exists, report otherwise regardless of LFLAG state
```

---

## Warnings and Potential Issues  

### Warning #1: Incomplete Pipeline Exit Status Capture After R Subprocess Output to Log Files  
**Location**: Lines 34–70 (input processing), lines 85–96 (univariate)  

When capturing both stdout to variables AND logging via tee, exit codes from `r_var=PIPE|TEE` are discarded because pipelines preserve final command's status. If R exits non-zero mid-pipeline—writing partial output or intermediate files—the shell continues anyway with `${?}` not checked immediately after line 34/85 commands:

```bash
# Line 34-40 current implementation  
r_var=\`Rscript ... | tee ...\`  

# Missing explicit exit code capture here. Pipeline status defaults to R's final (last command in pipeline, i.e., tee succeeds if input exists) unless wrapped with \`||...\`. If first stage fails but writes partial files, lines 68-70 check_file runs on possibly incomplete data before knowing R exited non-zero earlier via $?
```

**Impact**: User sees message like "Data processed..." from captured output even though config file wasn't fully written. Then line 70-71 `check_file` fails with cryptic error instead of showing the actual reason (partial write failure, missing contrast groups detected in stderr but not propagated as exit code). This obscures debugging because original R cause is lost when only logged to `${OUT_DIR}/LOG/`.

**Recommendation**: Capture both output and status explicitly after each pipeline:
```bash
# Example at line 34+  
r_var=\`Rscript ... | tee ...\`; r_exit=${PIPESTATUS[0]}  

if [ $r_exit -ne 0 ]; then   
    echo "ERROR: R step failed with exit code ${r_exit}.${NO_COLOUR}" >&2    
fi
```

---

### Warning #2: Mutex Flag Checking Without Exit Code Validation  
**Location**: Lines 154–167 in sys_init.sh, sourced at line 9 of train_class  

```bash
# From sysInit at lines ~155-159  
opt_flag_check \    <-- helper function exits with error code if --mutex conflict detected and flags invalid   
--mutex "KFLAG:UFLAG" 
...

source ./scripts/sys_init_class_2d.sh\n  # Function above may have printed help text AND returned non-zero for mutex violation, but trainClass doesn't check exit status here
```

**Issue**: When `opt_flag_check` detects conflicting flags like `-k -u`, it either exits with error (halting immediately within sys_init script's while loop) or prints warning and continues if validation occurs elsewhere. If function returns non-zero for conflicts caught mid-parse, parent train_class.sh sources the file but never checks `${?}` before continuing to line 28 config loading at `source ./scripts/configInit`. This means invalid flag combination might slip through with defaults overriding intended settings silently—particularly `-m <config>` scenarios which load user-specified values that could conflict with parsed command-line flags incorrectly applied without explicit error detection.

```bash
# Scenario A: sys_init exits, train_class halts (correct path when function aborts script itself)  
source ./scripts/sysInit && echo "OK" || exit 1  # Would catch this  

# But current flow does neither of the above explicitly after source command completes at line 9
```

**Impact**: Conflicting user input gets resolved to defaults without clear error message. User passes `-k -u` expecting help abort invocation—if sys_init catches conflict and displays help but returns non-zero, train continues anyway since exit code unexamined until possibly too late when config values from `configInit.sh` override initial flags already processed incorrectly (line 103-110 in sysInit processes m-config after flag parsing; if defaults loaded without noting mutex error earlier, subsequent conflicts may persist through entire pipeline).

**Recommendation**: Add explicit exit code test after sourcing:
```bash
source ./scripts/sys_init_class_2d.sh\nif [ $? -ne 0 ]; then    # non-zero indicates sysInit aborted with conflict/error detected 
    echo "Initialization failed at flag validation step.${NO_COLOUR}" >&2  
    exit 1                                                        \nfi                          # else proceed normally after validated flags parsed successfully
source ./scripts/config_init.sh                                   # this may override some defaults based on config file, but valid only if sysInit completed without error above. 
```

---

### Warning #3: minmax_norm vs zscore_standardization Conflict Check Only at End of Config File  
**Location**: lines 62–70 (default settings), line 354–356 (warning trigger)  

At config_init.sh initialization, defaults set one norm as TRUE/false based on whether custom `-m <cfg>` file loaded earlier. At end:
```bash
# Line ~62  
minmax_norm=TRUE   
zscore_standardization=FALSE

# ... later at line 103 in sysInit when parsing -u/other flags, zScore may flip TRUE if user passed related parameter  

if [ $CONF_CHECK == 1 ]; then   # checking only after all sources complete (not mid-stream during flag validation)  
    echo "WARNING: minmax+zscore both true..." >&2  
fi
```

**Issue**: Detection and warning about normalization conflict happens at `config_init.sh` end rather than before pipeline executes any preprocessing steps. When R script runs from line 34 or 85, config may already have normalized one way but override occurs mid-stream if user flag triggered opposite scaling method via zScore setting in `-m <cfg>` file (loaded separately). Only after normalization parameters set internally does warning print at end—if both methods enabled, first silently overridden with notice—but this happens AFTER R preprocessing scripts expect particular scaling assumptions baked into their computation logic for SVM kernels or data transformations. 

```bash
# Line ~87 from configInit defaults  
if (\$(DAT_PROCESS_CONFIG\$MINMAX_NORM)) {     <-- in input_dat_process_2D.R line 109-115, minmax applied only if true here before zScore considered later by downstream code  
    feature_data <- apply(...) # normalization affects all following R computations  

# If defaults override scaling mid-pipeline after -m file loaded with user's choice from earlier command-line args parsed incorrectly...
```

**Impact**: User expects one normalization type selected via config or CLI but gets opposite method if another flag later flips setting. Example: `-s <csv> --minmax TRUE` in custom config sets minmax, then sysInit defaults at `config_init.sh` line 103 override zscore to FALSE (line65), leaving user's intent satisfied—until additional flags conflict with each other and final normalization choice not what they specified. Downstream SVM/rf training assumes particular variance distribution from chosen scaling method; wrong assumption leads to poor model performance or convergence failures users struggle debugging for hours retraining without understanding why their "minmax" setting didn't apply based on `-m <cfg>` file values possibly overridden by config defaults incorrectly resolved earlier in sys_init flag parsing stage.

**Recommendation**: Add early conflict detection before full pipeline runs:
```bash  
# At line 6-7 of train_class.sh after sourcing zzz but BEFORE first R script call   
echo "Validating normalization settings..."    
if [[ $minmax_norm == TRUE && \$zscore_standardization == TRUE ]]; then     
    echo "${COLOUR_YELLOW}ERROR (shell convention): Both norms enabled. Forcing override...${NO_COLOUR}" >&2  
fi
```

---

### Warning #4: Silent PLS-DA Failure Without Exit Code Capture or Log Inspection Guidance  
**Location**: Lines 179–308 after ML step via `cv_plsda_val_svm.R`  

ML analysis completes normally with exit code from `r_var=` pipe at line ~210; output checks pass file check at lines 246-253. Then PLS-DA runs:

```bash
# Line ~179 - run ML step, outputs model and plot  
if [ $XFLAG == 0 ]; then   # cv mode uses different script path than regular training   
    ...  

r_var=\`Rscript ... | tee ...\` 
... 

# No exit code check on R output below after `tee`. File exists or doesn't matter; next step proceeds regardless whether previous R call failed silently inside.
```

**Issue**: After ML completes, file checks verify existence of model outputs (line 246-253), but if parallel errors cause PLS step to abort writing final_plsda_model.Rdata yet stdout prints successfully before failure—shell logs capture stderr separately at line ~87 or so while log shows partial output. Without explicit exit check, script continues assuming success and runs end-time computation anyway (line 354-360). If PLS outputs plots but model incomplete from within R due to memory exhaustion during parallel processing with multiple cores (`cores` flag), user gets stale results file after timeout or corrupted data in output while error only buried deep inside log files requiring manual grep for "ERROR" pattern strings.

**Impact**: Model appears validated at lines 268-301 when downstream prediction scripts may fail on missing features due to incomplete training, confusing users re-running without knowing why previous attempts partially succeeded then corrupted their model set during pipeline execution with specific config file parameters like `--perm_n` or cluster types. Since no error handler checks R's status code directly but only assumes tee captured output successfully—which always succeeds unless stdin broken (R stdout printed at least some content before crashing)—user wastes time troubleshooting "why does prediction fail" on supposedly trained model that was never properly validated.

**Recommendation**: Check exit status after each `r_var=` capture or use function wrapper:
```bash  
run_r_with_error_check() {\n    Rscript "$1" "${@:\$2}" 2>>"${LOG_FILE}" \\\\\n       | tee -a "\${SHELL_LOG}"; ret=\?\nn\nif [ \$ret !=0]; then 
        echo "R step returned error code: ${ret}. Check log for stderr details." >&2\$\n     fi  
};  

# Use helper at each R call site instead of direct \`r_var=SCRIPT | tee...\` patterns scattered throughout train_class.sh
```

---

### Warning #5: Missing File Validation Between Pipeline Stages in Multi-Step Workflow Flowchart  

Overall script structure processes data → univariate feature reduction (optional) then SVM rRF-FS modeling and finally PLS-DA validation, but no explicit check between blocks ensures each stage's output exists before next proceeds. Line 34 completes preprocess saving to `*_2D` or `_w_prior.csv`; file checked at line 70 via custom helper function reading only filename argument expecting path existence—if partial written from R pipe above due to exit status lost in tee capture, check_file still runs assuming full config present even if earlier failure left intermediate artifacts incomplete.

```bash
# Current pattern after input processing  
check_file "\$dat_configFile" "Error message."  # reads only filename for helper  

# Missing explicit verification that file was completely written before moving on unconditionally at line ~75 onward to next steps like `group_summary=` extraction from R output lines32-49 above
```

**Issue**: Pipeline assumes sequential success with each check_file verifying specific expected outputs exist. But if one stage produces partial results (R exits mid-write without cleanup), subsequent stages fail on incomplete data while original cause never surfaced because earlier exit codes dropped after capture statements, leaving user debugging downstream errors rather than upstream failures in input handling or config loading phases before main ML loop begins execution properly from train_class.sh entry point.

**Impact**: Errors manifest at prediction time or model application when feature selection failed silently during SVM training inside R subscripts called with different flags like `-u --x` combinations not validated by any pre-existing tests (except placeholders in test.R/test2.R ignored since "do not rely on their behavior"). Users must manually inspect `${OUT_DIR}/LOG/processing_R_log_YYYY-MM-DD.log` files for error strings buried among plot generation output rather than catching failure immediately when config loading invalidates flags earlier or R exits with status non-zero before next step expects valid input ready from previous stage completion.

```bash  
# Example at line ~210 - ML completes, outputs to both stdout and file; but if partial write occurred: 
r_var=SCRIPT | tee ... 

nextStep() {    # uses output file as input without confirming success above   
  Rscript otherScript "\$dat_mlFile" ...\n}  

# no explicit validation that \$dat_m1file written successfully exists AND contains expected row/col count matching config before passing to next script at line208+
```

**Recommendation**: Validate each intermediate output after creation, or checkpoint results:
```bash  
if [[ ! -f "${OUT_DIR}/OUTPUT/\${MAT_FILENAME_WO_EXT}_*_w_prior.csv" ]]; then   # glob catches either filename variant produced above 
    echo "ERROR: Input processing step failed to produce expected CSV file." >&2 
    exit 1                                           \nfi  

# Only here does it safe continue; same pattern needed elsewhere throughout script  
if [[ -f "\$svmModelFile" && \$\(-size \$svm_model_file\)`wc -c` == ? ]]; then   # check non-zero size indicating complete write not partial truncation
    proceed_to_plsda_step   
fi

```

---

## Overall Code Quality Notes  

### Strengths  
✅ **Correct shell boolean usage per inverted convention**: All `if [ var == 0/1 ]` patterns consistently follow reversed semantics. Comments at top of script clearly state "in Shell, 0 is true". This inversion avoids confusion despite R's native TRUE/FALSE (which train_class.sh doesn't directly call but rather passes strings evaluated by eval()) for boolean parameters going into downstream scripts where config files set default values as text then executed via `source` command loading string expressions like `"TRUE"` becoming actual logical FALSE/TRUE after parsing inside sourced context.  

✅ **Mutex validation in sys_init correctly prevents conflicting flags**: `-k -u` combination caught before config application, though without explicit exit check (see Warning #2). Mutex logic at line 154-167 does its job even if subsequent code missing verification; helper function itself handles violations internally via `mand_flag_check|opt_flagCheck → exits with error if invalid args passed to script main entry point when no command-line arguments supplied or only help/version requested before flag parsing loops process options starting at line 34-147 above.  

✅ **Reusable modular structure**: All sub-scripts source from parent scope variables directly rather than duplicating config loading; consistent directory layout across connectivity_ml and classification pipelines sharing common flags with type suffix for clarity between `_conn[_2d]` variants per naming conventions specified in documentation header comments at line 3-4 of root scripts.  

✅ **Comprehensive logging coverage**: Both shell stdout redirected via tee to log files AND separate R stderr captured by `stderr >> LOG_FILE`, enabling full audit trail even if errors don't halt execution immediately—critical for debugging long-running pipelines across multiple parallel cores where race conditions may produce partial outputs before timeout detection halts compute jobs.  

---

### Concerns  
⚠️ **Sparse error messages around file creation/reading failures**: When `check_file` returns non-zero because expected artifact missing, generic message shown rather than tracing back which R script failed to write it and why (exit status not checked so cause lost unless manually inspecting timestamped log files).  

⚠️ **No edge-case coverage for flag combinations with cross-validation mode enabled**: Scripts behave differently under `-x` toggle affecting output file naming convention but no tests validate interaction like "CV-only + univariate prior ON" scenarios that may produce unexpected outputs when switching between cv_only and regular training modes within same run.  

---

## Recommendation Summary  
1) **Add exit code checks after every R subprocess call**—particularly for pipeline steps with tee capture—so shell knows whether preceding step failed completely or produced partial output before continuing to next stage without knowing if intermediate files written successfully despite stdout appearing normal during execution of previous command's piping operation through both logging and variable assignment simultaneously capturing results into same log stream.  

2) **Improve error messaging clarity** by prefixing which configuration source caused conflict ("config file overrides CLI flags for normalization when flag detection finds conflicting defaults") rather than generic "WARNING: ...". Also specify exact parameter values causing conflicts like minmax/zscore with actual boolean TRUE/FALSE strings visible in logs so users can reproduce conditions that triggered override behavior unexpectedly.  

3) **Intermediate output validation between pipeline stages**, particularly around PLS-DA step currently only checks result model file exists without verifying upstream ML output quality or exit status from cv_ml_svm stage before attempting to parse results for downstream statistical testing inside PLS analysis scripts called from main training entry point at appropriate positions throughout script body spanning from input loading through univariate filtering ending with final validation completion reporting elapsed wall-clock time.  

4) **Consider adding test suite stubs** beyond existing placeholder test.R/test2.R files, covering combinations like train_class.sh invoked with various flag sequences (-x | -l combined, both omitted singly or together under different output directories to verify consistent behavior regardless of cwd changes since scripts assume repo root location for relative path resolution as stated in documentation header comments at line 16-20 specifying expected input/output folder structure before any processing begins reading command-line arguments.  

---

## Files Analyzed  
- `train_class.sh` (lines 1–329) — primary entry point CLI argument parsing wrapper around R subprocess calls orchestrating full classification workflow pipeline including preprocessing, univariate analysis with optional feature reduction via DESeq-like methods then SVM modeling using recursive rRF-FS loop for cross-validation-based hyperparameter tuning before PLS-DA validation step comparing multiple component numbers to determine optimal number of latent variables explaining maximum variance between class clusters in high-dimensional data space.  
- `src/help_var_class_2d` — help text describing flag purposes (-k, -u mutual exclusivity; -x/-l toggles affecting output file naming patterns based on combination used).  
- `scripts/sys_init_class_2d.sh` — command-line argument parsing with optional mutex checks preventing conflicting options passed simultaneously while sourcing configInit for default values when custom `-m <file > not supplied or incomplete due missing required variables checked against whitelist at end of source block within parent wrapper script after validation succeeds.  
- `scripts/config_init.sh` — normalization defaults, SVM kernel parameter ranges and other configurable hyperparameters set conditionally based on presence/absence of user-supplied config file loaded via `-m flag path specified as input argument before execution begins reading command-line options for flags processed by while getopts loop starting at line 34 above.  
- `scripts/sys_check.sh` — dependency verification logic including R package installation failure handling when initial startup runs first time encountering new datasets requiring fresh package builds or updates available since last successful launch session completed earlier on same machine running current invocation script currently under review today's date July102026 according to environment info provided at start of opencode tool configuration context.  
