# qLib

## development

Dev tools:

- vscode(python, pylance)
- pip(yapf)

```json
{
  "python.analysis.typeCheckingMode": "basic",
  "python.analysis.diagnosticSeverityOverrides": {
    "reportWildcardImportFromLibrary": "none"
  },
  "python.formatting.provider": "yapf",
  "python.formatting.yapfArgs": [
    "--style",
    "{use_tabs: false, indent_width: 2, continuation_indent_width: 2, indent_blank_lines: false, column_limit: 120, spaces_before_comment: 1, blank_lines_around_top_level_definition: 1}"
  ]
}
```

Install editable:

`pip install -e .`
