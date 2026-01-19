# File Issue Command

File a standardized issue for bugs, features, or improvements.

## Usage

```
/project:file-issue [description]
```

## Examples

```bash
# Interactive (no description)
/project:file-issue

# With inline description
/project:file-issue camera freezes after dismissing error dialog

# With full context
/project:file-issue camera freezes after error, should resume preview, see screenshot IMG_1234.png
```

## What Happens

1. **Gather info** - Accept inline description, ask for missing critical info
2. **Classify** - Propose type, priority, component (you confirm or override)
3. **File** - Write to `docs/issues/YYYY-MM-DD-<slug>.md`
4. **Update index** - Add to `docs/.doc-index.json` with status "Open"
5. **Route** - Bugs → ready for dispatch; Features → start brainstorming

## Instructions

Invoke the `file-issue` skill with source=manual:

```
Skill(skill="file-issue", args="--source manual")
```

Then follow the skill instructions exactly.

If user provided a description in the command args, pass it to the skill as initial context.

## Post-Filing: Update Doc Index

After creating the issue file, update the documentation index:

```bash
./scripts/update_doc_index.py add docs/issues/<filename>.md --status Open
```

This ensures the issue is tracked in `docs/.doc-index.json` and will be flagged for archival when closed.
