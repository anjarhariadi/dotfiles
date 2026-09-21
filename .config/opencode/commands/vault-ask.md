---
description: Answer a question by searching this Obsidian vault
---

Answer this question using only information found in this vault: $ARGUMENTS

Vault folder structure:
- 00_Personal — personal info, bio, preferences, identity
- 01_Learn — learning notes, courses, study material
- 02_Project — project docs, plans, specs
- 03_Work — work-related notes, meetings, tasks

Steps:
1. Guess which folder(s) are most likely relevant based on the question.
2. Search filenames and content in those folders first (grep/glob). If nothing turns up, widen the search to the whole vault.
3. Open and read the most relevant file(s) in full — don't answer from a filename or snippet alone.
4. Give a direct answer, then list which file(s) it came from (relative path).
5. If nothing relevant exists in the vault, say so plainly instead of guessing or making something up.
