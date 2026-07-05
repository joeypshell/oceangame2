# OceanGame Migration Notes

## Goal

Use OceanGame as a reference source without importing its visual instability or project structure problems into `oceangame2`.

## Migration Buckets

### Keep

- Strong mechanic ideas.
- World fantasy.
- Good names, places, or lore concepts.
- Any code that was isolated, understandable, and already working.
- Lessons learned from failed visual attempts.

### Reference Only

- Old screenshots.
- Map concepts.
- Prompt experiments.
- Partial systems.
- Scene compositions.
- Visual attempts that had one good idea but poor consistency.

### Do Not Import Early

- Old generated art.
- Tangled map scenes.
- Visual hacks.
- Code coupled to unstable scenes.
- Large systems not needed by the salvage proof-of-concept.

## Code Migration Rule

Copy the concept first. Copy the code only if it is cleaner than rewriting.

Before migrating any OceanGame code, answer:

1. What current problem does this solve?
2. What dependencies does it bring?
3. Can it be tested in isolation?
4. Does it depend on old visuals or scenes?
5. Is rewriting cheaper?

## Visual Migration Rule

Old OceanGame visuals are reference material only unless explicitly approved as assets under the new art bible and asset manifest.

