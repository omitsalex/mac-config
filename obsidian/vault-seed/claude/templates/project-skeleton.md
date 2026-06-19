# Project skeleton

When creating a new project folder, scaffold this structure:

```
<project>/
├── _index.md              # Entry point — wikilinks to all notes
├── CLAUDE.md              # AI context for this project
├── architecture.md        # System design, key decisions, constraints
├── conventions.md         # Code style, patterns, naming rules
├── research/              # Investigation results — never redo existing research
├── decisions/             # ADR-style records
├── bugs/                  # Known bugs, fixes attempted, root causes
├── patterns/              # Reusable code patterns from this codebase
├── todo.md                # Open work items
└── sessions/              # YYYY-MM-DD-HHMM-short-name.md
```

## _index.md starter

```markdown
# {Project name}

{One-line description of the project.}

## Core docs
- [[architecture]] — system design, module structure
- [[conventions]] — code style and patterns
- [[todo]] — open items

## Research

## Decisions

## Bugs

## Patterns

## Recent sessions
```
