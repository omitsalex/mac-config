# Obsidian note templates

## session → sessions/YYYY-MM-DD-HHMM-topic.md
```markdown
---
date: {YYYY-MM-DD HH:MM}
topic: {short topic}
status: {in-progress | completed | blocked}
---
# Session: {topic}
## Context loaded
## Goal
## Work log
- [HH:MM] {action or finding}
## Outcomes
## New memory written
```

## research → research/{topic}.md
```markdown
---
created: {YYYY-MM-DD}
updated: {YYYY-MM-DD}
tags: [research, {technology}, {area}]
---
# {Topic}
## Question
## Answer
## Evidence
## Implications for this project
```

## decision → decisions/{NNNN}-{slug}.md
```markdown
---
date: {YYYY-MM-DD}
status: {proposed | accepted | superseded}
---
# {NNNN}. {Decision title}
## Context
## Options considered
## Decision
## Consequences
```

## bug → bugs/{slug}.md
```markdown
---
status: {open | fixed | wontfix}
severity: {low | medium | high}
---
# {Bug title}
## Symptom
## Root cause
## Fix
## Related
```

## pattern → patterns/{slug}.md
```markdown
---
created: {YYYY-MM-DD}
tags: [pattern, {technology}, {area}]
---
# {Pattern title}
## Problem
## Solution
## Example
## When to use
```
