# Scan-queue review-sidecar schema

`reports/scan_queue/` is the review sidecar location for the scan-ingest flow,
mirroring how `reports/deep-dives/` holds deep-dive dossiers. The
**`lrgdm-ingest-scans`** skill (which runs on the Claude Code subscription and
reads images directly with vision) writes, per scanned item:

- `reports/scan_queue/<scan_id>.json` — the structured sidecar described here.
- `reports/scan_queue/<scan_id>.md` — a human-readable rendering for review.

`scripts/apply_scan.py` reads **only** the JSON. It does **no** model calls — all
transcription / extraction happens in the skill session; apply is deterministic.

## `scan_id`

A slug naming the scanned item, e.g. `1956-marriage-cert-kenny` or
`grandma-records-p12`. Used as the sidecar basename. Keep it filesystem-safe
(`[A-Za-z0-9._-]`).

## Workflow contract

1. Skill writes the sidecar with `"status": "proposed"`.
2. John reviews the `.md`, corrects the `.json` (fix transcription, confirm or
   drop citations, fix subject_ids), and flips `"status"` to `"approved"`.
3. `python3 scripts/apply_scan.py <scan_id> --apply` writes to Postgres + stores
   the original. `apply_scan.py` refuses to apply a sidecar whose status is not
   `"approved"` (dry-run shows the plan regardless).

## JSON shape

Every field is mapped to a real column in
`db/migrations/0002_sources_media.sql` (`source`, `media`, `media_link`,
`citation`). Field → column mapping is noted inline.

```json
{
  "scan_id": "1956-marriage-cert-kenny",
  "status": "proposed",

  "scan": {
    "inbox_file": "media/_inbox/1956_marriage_cert.jpg",
    "sha256": "…64 hex…",
    "bytes": 482113,
    "mime_type": "image/jpeg",
    "media_type": "scan",
    "suggested_blob_key": "scans/1956-marriage-cert-kenny/1956_marriage_cert.jpg"
  },

  "source": {
    "source_type": "marriage_record",
    "title": "Marriage certificate — John Kenny & Leah Rae, Cook County, 1956",
    "informant": null,
    "repository": "Cook County Clerk",
    "url": null,
    "citation": "Cook County, Illinois, marriage certificate no. 12345 (1956)…",
    "source_date": "1956",
    "accessed_date": "2026-06-07",
    "confidence": "high",
    "notes": "Scanned from the June 7 family records box."
  },

  "media": {
    "title": "1956 marriage certificate (scan)",
    "caption": "Original certificate, front side",
    "captured_date": "1956",
    "role": "document_scan"
  },

  "transcription": "STATE OF ILLINOIS … This certifies that John Kenny … and Leah Rae … were united in marriage on the [illegible] day of June, 1956 …",

  "links": [
    { "subject_type": "person", "subject_id": "P-0056", "role": "document_scan" },
    { "subject_type": "event",  "subject_id": "E-0213", "role": "document_scan" }
  ],

  "citations": [
    {
      "subject_type": "person",
      "subject_id": "P-0056",
      "subject_field": "birth_date",
      "claim": "Born 18 Jul 1934, Chicago",
      "confidence": "high",
      "conflicts_flag": false,
      "locator": "certificate body, line 3"
    }
  ]
}
```

## Field reference

### `status`
`"proposed"` | `"approved"`. `apply_scan.py --apply` requires `"approved"`.

### `scan` — the inbox file (drives the `media` row's integrity fields)
| field | type | maps to | notes |
|---|---|---|---|
| `inbox_file` | string | (none) | repo-relative path to the file in `media/_inbox/`. `apply_scan.py` hashes this file. |
| `sha256` | string | `media.sha256` | recomputed by `apply_scan.py`; sidecar value is advisory. Dedup key against `media`. |
| `bytes` | int | `media.bytes` | recomputed by `apply_scan.py`. |
| `mime_type` | string | `media.mime_type` | e.g. `image/jpeg`, `application/pdf`. |
| `media_type` | string | `media.media_type` | one of `image` \| `scan` \| `pdf` \| `audio` \| `video` (CHECK in 0002). |
| `suggested_blob_key` | string | (advisory) | optional; the blob backend derives the real key from `LRGDM_BLOB_PREFIX` + source_id + filename. |

### `source` — becomes one `source` row
| field | type | maps to | notes |
|---|---|---|---|
| `source_type` | string | `source.source_type` | FK to `source_type(code)`. Seeded codes: `census`, `vital_record`, `birth_certificate`, `death_record`, `marriage_record`, `obituary`, `findagrave`, `grave_marker`, `ssdi`, `numident`, `oral_history`, `newspaper`, `book`, `website`, `photo`, `military`, `immigration`, `naturalization`, `directory`, `church_record`, `draft_registration`, `other`. `apply_scan.py` upserts unknown codes (like `parse_dossiers.py`). |
| `title` | string | `source.title` | **required** (NOT NULL). |
| `informant` | string\|null | `source.informant` | e.g. who gave an oral history. |
| `repository` | string\|null | `source.repository` | holding institution. |
| `url` | string\|null | `source.url` | external link if any (usually null for a home scan). |
| `citation` | string\|null | `source.citation` | full Evidence-Explained-style citation text. |
| `source_date` | string\|null | `source.source_date` | fuzzy date the record documents. |
| `accessed_date` | date\|null | `source.accessed_date` | ISO date the scan was made/retrieved. |
| `confidence` | string\|null | `source.confidence` | `high` \| `med` \| `low` (CHECK). |
| `notes` | string\|null | `source.notes` | |

### `media` — becomes one `media` row (combined with `scan`)
| field | type | maps to | notes |
|---|---|---|---|
| `title` | string\|null | `media.title` | |
| `caption` | string\|null | `media.caption` | |
| `captured_date` | string\|null | `media.captured_date` | fuzzy genealogical date the artifact was made. |
| `role` | string | `media_link.role` for the **default** media→source link | e.g. `document_scan`, `portrait`, `headstone`, `gallery`. |

`media.file_path` / `media.url` / `media.media_id` are set by `apply_scan.py`
(see its docstring); they are not in the sidecar.

### `transcription` — plain text
Full verbatim transcription of the document. Not a DB column by itself; the skill
also folds the relevant pieces into `source.citation` / `citations[].claim`.
`apply_scan.py` appends it to `source.notes` so the verbatim text is preserved
alongside the source row.

### `links` — extra `media_link` rows (M:N media ↔ subject)
List of `{ subject_type, subject_id, role }`. `apply_scan.py` **always** creates
the default link media→the new `source` (role = `media.role`); each entry here is
an **additional** link.
| field | maps to | notes |
|---|---|---|
| `subject_type` | `media_link.subject_type` | one of `person` \| `event` \| `place` \| `source` (CHECK). |
| `subject_id` | `media_link.subject_id` | must exist in the target table. |
| `role` | `media_link.role` | UNIQUE `(media_id, subject_type, subject_id, role)`; dup links `ON CONFLICT DO NOTHING`. |

### `citations` — extracted facts, each becomes one `citation` row
Only include human-confirmed facts grounded in what is visible on the document.
| field | maps to | notes |
|---|---|---|
| `subject_type` | `citation.subject_type` | one of `person` \| `event` \| `place` \| `relationship` (CHECK). |
| `subject_id` | `citation.subject_id` | must exist; the polymorphic FK **trigger** rejects unknown ids. |
| `subject_field` | `citation.subject_field` | e.g. `birth_date`, `death_place`; null = whole record. |
| `claim` | `citation.claim` | the asserted fact. |
| `confidence` | `citation.confidence` | `high` \| `med` \| `low` (CHECK). |
| `conflicts_flag` | `citation.conflicts_flag` | boolean; true if it conflicts with current DB data. |
| `locator` | `citation.locator` | where on the document (line, field, page). |

All `citations[]` rows share the one `source` minted from `source` above.

## Notes on `media_type` vs `source_type`
- `media_type` describes the **digital artifact** (`scan`/`image`/`pdf`).
- `source_type` describes the **record in the world** (`marriage_record`, etc.).
A photographed marriage certificate is `media_type = "scan"` (or `image`) with
`source_type = "marriage_record"`.
