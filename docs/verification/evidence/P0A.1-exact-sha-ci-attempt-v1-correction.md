# Correction to P0A.1 CI attempt v1

Recorded on 2026-09-16 before committing the byte-preservation repair.

The original attempt report contains transcription errors in the middle of both traceability SHA-256 values. Direct recomputation from `docs/verification/traceability-v1.yml` gives:

| Representation | Bytes | SHA-256 |
| --- | ---: | --- |
| Raw CRLF | 477167 | `939fa28c670fe55a320af7b1d879257b6ee28193309946aca29bb06caeb6db55` |
| CRLF replaced by LF | 477166 | `9fbb1075e92770e5259125e1d557b0aeb4cfb0fbf1179c306af8ebdb1696e894` |

These values supersede only the two SHA-256 literals in the original report's Root cause section. Its CI run identity, failure, byte lengths, and newline-conversion diagnosis remain valid. The implementation's frozen hash already uses the correct raw value; this correction changes no executable code or frozen input.
