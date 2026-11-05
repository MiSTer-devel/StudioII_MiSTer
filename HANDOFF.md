# Project handoff

## Studio III NTSC provenance

- Objective: establish the origin of Emma 02's NTSC ROM and machine configuration.
- Baseline: the core models CDP1861, CDP1862, and CDP1863. Evidence for corresponding historical hardware remains unresolved.
- Verified: local `conic_ntsc.bin` and `studio3_ntsc.bin` are identical to Emma 02's current `data/Victory/studio3.rom` and `data/Conic/conic_ntsc.bin` (Git blob a1b0937b4ed62352caf2d7db0de62473d09b8ff8). Marcel added `data/Victory/studio3.rom` with Studio III NTSC support on 2018-04-19 and changed it on 2018-05-04. Emma 02 V1.27 announces an NTSC Studio III ROM.
- Andrew Modla says he modified the PAL resident ROM interrupt routine for NTSC: https://github.com/ajavamind/rca-studio2. His PAL image matches the first 2048 bytes of the local PAL image; his NTSC image changes one byte from his PAL image. Neither the initial nor current Emma 02 NTSC image matches his NTSC image in the first 2048 bytes. This does not establish authorship or provenance of Emma 02's version.
- Changes: `docs/development.md` distinguishes the implemented model from hardware evidence; `roadmap.md` tracks the provenance question.
- Verification: compared Git blob hashes and ROM bytes; no hardware or simulation tests run.
- Unresolved: FliP reports no known retail NTSC successor and identifies the Conic M-1200 as PAL. Marcel described an M-1200 with 1861/1862 in 2025; Andrew Modla also described NTSC and PAL Studio III clones in 2018. Their supporting evidence is unknown. A Hagley or TCNJ source for the NTSC ROM is plausible but unverified: Emma 02 V1.27 separately lists the ROM and software attributed to both collections. The NTSC audio filter remains provisional.
- Next: ask Marcel about the two 2018 ROM versions, their naming and sources, whether either came from Hagley or TCNJ, and the evidence for the NTSC Conic hardware configuration.
