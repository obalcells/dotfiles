# Jupyter Notebook Editing Rules

## ⚠️ CRITICAL: Two Rules You Must Follow

### Rule 1: Cell Insertion - ALWAYS Specify cell_id

**The Problem:** NotebookEdit without `cell_id` inserts at TOP (almost never what users want)

**The Solution:**
```bash
# Get last cell ID first
cat notebook.ipynb | jq -r '.cells[-1] | .id'

# Then insert with cell_id
NotebookEdit(
    notebook_path="notebook.ipynb",
    edit_mode="insert",
    cell_id="cell-xyz",  # ← REQUIRED! Insert AFTER this cell
    cell_type="code",
    new_source="..."
)
```

**Default behavior:** When location is unspecified, ALWAYS append to END (not beginning)

---

### Rule 2: Cell Type - Match Content Type

**Simple decision:**
- Contains Python code (import, def, print, variables, function calls)? → `cell_type="code"`
- Markdown headers (##, ###) or documentation text? → `cell_type="markdown"`

**Common mistake:**
- ❌ `# comment\ncode()` with `cell_type="markdown"` → WRONG (Python comments are code)
- ✅ `# comment\ncode()` with `cell_type="code"` → CORRECT
- ❌ `## Header` with `cell_type="code"` → WRONG (markdown header)
- ✅ `## Header` with `cell_type="markdown"` → CORRECT

**Quick check before NotebookEdit:**
"Will this be executed as Python?"
- YES → `cell_type="code"`
- NO → `cell_type="markdown"`

---

## Examples

### ✅ CORRECT
```python
# Append to end: Get last cell first
cat notebook.ipynb | jq -r '.cells[-1] | .id'  # Returns "cell-24"

# Code cell (has imports and function calls)
NotebookEdit(
    notebook_path="notebook.ipynb",
    edit_mode="insert",
    cell_id="cell-24",
    cell_type="code",
    new_source="import pandas as pd\ndata = pd.read_csv('data.csv')"
)

# Markdown cell (section header + text)
NotebookEdit(
    notebook_path="notebook.ipynb",
    edit_mode="insert",
    cell_id="cell-25",
    cell_type="markdown",
    new_source="## Data Loading\n\nThis section loads the data."
)

# Code cell (Python comments + code)
NotebookEdit(
    notebook_path="notebook.ipynb",
    edit_mode="insert",
    cell_id="cell-26",
    cell_type="code",
    new_source="# Load model\nmodel = load_model('model.pth')"
)
```

### ❌ WRONG
```python
# Missing cell_id - will insert at TOP
NotebookEdit(
    edit_mode="insert",  # NO cell_id!
    cell_type="code",
    new_source="..."
)

# Python code in markdown cell
NotebookEdit(
    cell_id="cell-1",
    cell_type="markdown",  # WRONG! This is Python code
    new_source="import torch\nmodel = Model()"
)

# Markdown in code cell
NotebookEdit(
    cell_id="cell-2",
    cell_type="code",  # WRONG! This is markdown
    new_source="## Section 1\n\nExplanation here."
)
```

---

## Quick Reference Table

| Content | cell_type | Example |
|---------|-----------|---------|
| Python imports | `"code"` | `import torch` |
| Function definitions | `"code"` | `def foo():` |
| Variable assignments | `"code"` | `x = 5` |
| Function calls | `"code"` | `print("hello")` |
| Python comments + code | `"code"` | `# Load\ndata = load()` |
| Markdown headers | `"markdown"` | `## Section 1` |
| Documentation text | `"markdown"` | `This notebook...` |
| Formatted text | `"markdown"` | `**bold** text` |

---

**Remember:** Before EVERY NotebookEdit call:
1. Get cell_id (usually last cell for appending)
2. Check content: Python code? → "code". Documentation? → "markdown"