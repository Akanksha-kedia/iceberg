# 9. Data Types

## Primitive types

| Iceberg type | Notes |
|---|---|
| `boolean` | |
| `int` | 32-bit signed |
| `long` | 64-bit signed |
| `float` | 32-bit IEEE 754 |
| `double` | 64-bit IEEE 754 |
| `decimal(P,S)` | Fixed precision `P`, scale `S` |
| `date` | Days since epoch, no time component |
| `time` | Microsecond precision, no date component |
| `timestamp` | Microsecond precision, no time zone |
| `timestamptz` | Microsecond precision, stored as UTC |
| `string` | UTF-8 |
| `uuid` | |
| `fixed(L)` | Fixed-length byte array of length `L` |
| `binary` | Variable-length byte array |

## Nested types

| Iceberg type | Notes |
|---|---|
| `struct` | Named, typed fields — each with its own field ID |
| `list` | Homogeneous element type; the element itself has a field ID |
| `map` | Key and value types; both key and value have field IDs |

## Field IDs: the mechanism behind safe schema evolution

Every field — top-level or nested — gets a permanent integer field ID the
moment it's added to the schema. This ID never changes for the lifetime of
the field, even across renames or reordering. Readers resolve columns by
ID against a data file's embedded schema, not by name or position, which
is what makes these operations safe without touching existing files:

- **Rename** — same ID, new name; old files render under the new name
  automatically.
- **Reorder** — same IDs, different positions; irrelevant to readers since
  they never used position.
- **Widen** — e.g. `int` → `long`, `float` → `double`: same ID, wider type;
  old files' narrower values are promoted on read.
- **Add** — new ID; old files simply have no value for it (read as `null`
  unless a default is configured).
- **Drop** — ID is retired; can be safely reused for something unrelated
  only after enough time/snapshot expiry that no live file still
  references it under the old meaning.

Nested field IDs matter just as much: adding a field inside a `struct` (or
changing a `map`'s value type) is exactly as safe and exactly as
metadata-only as a top-level change.

## `timestamp` vs `timestamptz` — the one that trips people up

`timestamp` has no time zone: `2024-01-01 12:00:00` means exactly that,
with no UTC offset attached, and every engine must agree on how to
interpret it (usually: don't mix session time zones across writers).
`timestamptz` is normalized to UTC internally and displayed in the
reader's local session zone — this is almost always the safer choice for
event timestamps that might be written and read from machines/sessions in
different time zones.

## Next

[Comparisons](10-comparisons.md) for how this type system and the rest of
Iceberg's design stacks up against Delta Lake and Hudi.
