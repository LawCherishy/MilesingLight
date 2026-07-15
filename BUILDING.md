# Building MilesingLight

## Requirements

- Windows 10 or Windows 11, x64
- MSVC with C++20 support
- Windows SDK with Win32, Direct3D 11, Direct2D, DirectWrite, WIC, UI Automation, and BCrypt headers/libraries
- An x64 Native Tools Command Prompt for Visual Studio

No package manager, downloaded runtime, server, or network access is required by the build.

The seven implementation bodies intentionally use `.txt` extensions. `/TP` compiles `src/APP.txt` as C++, and its local includes assemble the other six bodies into one translation unit. [`src/Generated/SELF_NUMBER_BINDINGS.inc`](src/Generated/SELF_NUMBER_BINDINGS.inc) is a required generated data include, not an eighth implementation body.

The generated include contains 112 entries × 10 fields = 1,120 exact fields. Compilation and startup validation bind it to an 89,390-byte authoritative source snapshot with SHA-256 `2AB1027F230D63237422B75AC98371C1895237FA38DFFB84B49C37D83ED7E440` and cross-check catalog name, operation, codable symbol/signature, and origin.

The public checker reconstructs all 1,120 fields from the authoritative ledger and byte-compares the expected include:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File tools\Generate-SelfNumberBindings.ps1 -Mode Check
```

`-Mode Generate` writes a reviewable candidate under `tools/`; it never overwrites the tracked include implicitly.

## Hardened release build

Run from the repository root in the x64 MSVC developer environment:

```bat
mkdir build

cl.exe /nologo /std:c++20 /utf-8 /permissive- /Zc:__cplusplus /W4 /EHsc /O2 /MT /GS /sdl /guard:cf /Gy /Gw /TP ^
  /Fo:"build\MilesingLight.obj" /Fe:"build\MilesingLight.exe" "src\APP.txt" ^
  /link /SUBSYSTEM:WINDOWS /INCREMENTAL:NO /OPT:REF /OPT:ICF /DYNAMICBASE /NXCOMPAT /HIGHENTROPYVA ^
  /GUARD:CF /CETCOMPAT /RELEASE /Brepro /MANIFEST:EMBED ^
  /MANIFESTUAC:"level='asInvoker' uiAccess='false'"
```

The verified v0.2 toolchain is MSVC `19.51.36248`, toolset `14.51.36231`, and Windows SDK `10.0.26100.0`. The final GUI build completed with zero `/W4` warnings. Two independent executions of the hardened command produced byte-identical 1,504,256-byte GUI files with SHA-256 `C3C4AE2A85BBD812DD69A1067C0F7B5D4859723E3FE8EA2E6F6465A87A591F1E`.

## Constructive self-test

```bat
cl.exe /nologo /std:c++20 /utf-8 /permissive- /Zc:__cplusplus /W4 /EHsc /O2 /MT /GS /sdl /guard:cf /TP ^
  /DMILESING_OPERATOR_SELF_TEST ^
  /Fo:"build\MilesingLightSelfTest.obj" /Fe:"build\MilesingLightSelfTest.exe" "src\APP.txt" ^
  /link /SUBSYSTEM:CONSOLE /INCREMENTAL:NO /DYNAMICBASE /NXCOMPAT /HIGHENTROPYVA /GUARD:CF /CETCOMPAT

build\MilesingLightSelfTest.exe
```

Expected nine PASS suites (`<ticks>` are machine-specific measured values):

```text
PASS 112/112 finite executor verifications
PASS 112/112 exact authored bindings (1,120 fields)
PASS read-only Operations binding-sheet interactions
PASS live whole-self derivation: measured bits + duration + recursive SIZE/DESIGNING + LIGHT TREATMENT sheaf glue + recursively reusable MY LIGHT DivinandWhole(converse); acquisition=<ticks> ticks, adaptive period=<ticks> ticks
PASS authored LIGHT TREATMENT + MY LIGHT association: exact expressions + operands + receipts survive normal canonical workspace persistence
PASS canonical codec: every Operand tag + 112 applied self-number fixtures round-trip byte-exactly
PASS strict version-1 migration: 8 changed arities + exact receipt enrichment + current replay + stable v2 + 18 altered-result/arity/presence rejections
PASS recoverable local writing: first + replacement + protected prior + SHA-256 + exact reopen
PASS canonical realization: attention + exact Editor restoration + replay-derived results
```

The test also gates exact binding/catalog correspondence, read-only binding-sheet behavior, directly attached local-volume admission with existing-component reparse rejection, final save-target revalidation, measured-cost cadence, exact selected-bit ancestry, LIGHT TREATMENT sheaf agreement, reusable MY LIGHT ancestry, and canonical replay. Its strict published-v1 fixture covers all 111 historical tuples: the eight changed-arity routes must validate exact historical results before deterministic receipt enrichment and current replay, unchanged routes must carry results canonically equal to current replay, and accepted work must reserialize as stable canonical v2. The pathname checks are not handle-relative/no-follow race elimination; residual pathname TOCTOU remains.

## Optional static analysis

Run native-code analysis against the same public source input and resolve or document every emitted diagnostic before release:

```bat
cl.exe /nologo /std:c++20 /utf-8 /permissive- /Zc:__cplusplus /W4 /EHsc /MT /GS /sdl /analyze /TP ^
  /DMILESING_OPERATOR_SELF_TEST /Fo:"build\MilesingLightAnalyze.obj" /c "src\APP.txt"
```

## Release evidence

For each public release, record from the final public-tree artifacts:

- exact Git commit and annotated tag;
- `cl.exe` and Windows SDK versions;
- complete nine-suite self-test output;
- executable byte size and SHA-256;
- PE architecture and subsystem;
- high-entropy VA, ASLR, DEP/NX, CFG, and CET compatibility evidence;
- complete imported-DLL boundary, including an explicit check for `WS2_32`, `WINHTTP`, `WININET`, and `URLMON`;
- Authenticode status;
- manifest/UAC level.

Useful inspection commands in the same developer environment include:

```bat
dumpbin /headers build\MilesingLight.exe
dumpbin /loadconfig build\MilesingLight.exe
dumpbin /imports build\MilesingLight.exe
powershell -NoProfile -Command "Get-FileHash -Algorithm SHA256 -LiteralPath 'build\MilesingLight.exe'"
powershell -NoProfile -Command "Get-AuthenticodeSignature -LiteralPath 'build\MilesingLight.exe' | Format-List Status,StatusMessage,SignerCertificate"
```

## Verified `v0.2.0-alpha` evidence

The annotated tag `v0.2.0-alpha` designates the release. Its target is the release commit; no self-referential commit hash is embedded in that commit.

```text
Compiler: MSVC 19.51.36248
Toolset: 14.51.36231
Windows SDK: 10.0.26100.0
/W4 warnings: 0

MilesingLight.exe
  Size: 1,504,256 bytes
  SHA-256: C3C4AE2A85BBD812DD69A1067C0F7B5D4859723E3FE8EA2E6F6465A87A591F1E
  Reproducibility: two independent builds byte-identical
  Format: x64 PE32+, Windows GUI
  Mitigations: high-entropy VA, dynamic base/ASLR, NX/DEP,
               CFG instrumented with FID table, CET compatible, /GS
  Manifest: embedded, asInvoker, uiAccess=false
  Debug record: reproducible-build record present
  Certificate directory: empty
  Authenticode: NotSigned; SignTool reports no signature
  Imports: USER32.dll, ole32.dll, bcrypt.dll, d3d11.dll,
           dxgi.dll, d2d1.dll, DWrite.dll, KERNEL32.dll
  Forbidden imports: WS2_32, WINHTTP, WININET, URLMON absent

MilesingLightSelfTest.exe
  Size: 1,510,400 bytes
  SHA-256: 9B1A533120ED74830DB0D8295B13FC31AD49312A01FF6190A0D8714D3F0B2DEB
```

Build products remain excluded from the source-first Git tree. `MilesingLight.exe` is distributed separately as the tagged release asset; the self-test executable remains an untracked verification artifact.
