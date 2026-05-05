# Code Base Streamlining Plan

**Project:** Neuro-ML-tools (NMT)  
**Date:** May 2026

---

## Repository Overview

**Type:** Bash/R-based machine learning tool for MEG connectivity and 2D data analysis

**Structure:**
- `/scripts/` - System init scripts for flag validation (11 files)
- `/R_files/` - R scripts for ML operations (~20 files)
- `/src/` - Utility functions, global variables, and help variables
- `/config_file_templates/` - Configuration templates
- `/zzz` - Main config file
- Root `.sh` scripts - Main application entry points (20+)

---

## Key Observations

### 1. Version Fragmentation
Multiple version suffixes creating duplicates:
- `_v2` scripts (major versions)
- `_nofs` variants (no feature selection)
- `_x` variants (combined CV + regular modes)

**Impact:** 60% code duplication between similar functionality

### 2. Helper Function Silos
11 separate `help_var_*.sh` files with similar flag validation logic, plus:
- `sys_init_*.sh` scripts handling duplicate flag parsing
- Common validation repeated across all init scripts

### 3. R Script Duplication
Parallel file pairs:
- `ml_svm.R` / `ml_svm_nofs.R` 
- `cv_ml_svm.R` / `cv_ml_svm_nofs.R`
- `univariate.R` / `univariate_2d.R`

**Impact:** ~30-40% code duplication in R files

### 4. Configuration Template Overlap
Multiple template directories with overlapping purposes:
- `config_template_for_classification`
- `config_template_for_reg`
- `config_template_for_pred_classification`
- `ptsd_mtbi_multiclass_power_command`

---

## Recommended Streamlining Plan

### Phase 1: Consolidation (High Priority)

1. **Merge `nofs` variants into base implementations**
   - Use config flag to enable/disable FS instead of separate scripts
   - Target: Eliminate ~40% of R file duplication

2. **Consolidate `_x` and `_v2` scripts**
   - Remove version suffixes where functionality identical
   - Keep `_x` variants for backwards compatibility, mark deprecated

3. **Unify helper variable scripts**
   - Merge all `help_var_*.sh` into single `app_config.sh`
   - Target: Reduce 11 files to 1-2 files

4. **Refactor sys_init scripts**
   - Create shared `validate_args.sh` with argument parsing
   - Each module sources common functions instead of duplicating

---

### Phase 2: Modularization (Medium Priority)

5. **Extract common R functions**
   - Create `R_files/common/` for shared utilities
   - Move duplicate code from R pairs to common library
   - Use R packages (e.g., methods, utils) for better encapsulation

6. **Unified config system**
   - Single JSON/YAML schema for all configurations
   - Deprecate separate config files for v2/nofs
   - Add validation via `./scripts/config_validate.sh`

7. **Standardize error handling**
   - Create `app_error.sh` with color-coded messages
   - All bash scripts source this instead of inline echo statements

---

### Phase 3: Optimization (Low Priority)

8. **Dependency audit**
   - Document all package requirements (R and bash)
   - Create `requirements.txt` equivalent

9. **Documentation cleanup**
   - Version History has inconsistencies (typos, repeated points)
   - Add `DEVELOPMENT.md` with contribution guidelines
   - Add `QUICKSTART.md` for new users

10. **Test suite**
    - Create minimal test cases for critical paths
    - Use a simple test runner script

---

## Potential Impact

| Action | Code Reduction | Maintenance Reduction | Risk |
|--------|-------------------|-------------------------|------|
| Merge nofs variants | ~40% R files | High | Medium (backwards compat) |
| Consolidate help_var scripts | ~80% lines | High | Low |
| Unified sys_init | ~60% lines | Medium | Medium |
| Common R library | ~35% R duplication | High | Low |

---

## Key Questions

1. **Backwards compatibility:** Is it critical to maintain all `_v2` / `_nofs` / `_x` command variants for existing users?

2. **Scope:** Should we focus on bash scripts first, R files next, or tackle them together?

3. **Timeline:** Is this a short-term refactor (1-2 sprints) or gradual migration over months?

4. **Documentation:** Should we prioritize documentation improvements along with the refactoring?
