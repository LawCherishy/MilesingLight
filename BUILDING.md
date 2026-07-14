# Building MilesingLight

## Requirements

- Windows 10 or Windows 11, x64
- MSVC with C++20 support
- Windows SDK with Win32, Direct3D 11, Direct2D, DirectWrite, WIC, UI Automation, and BCrypt headers/libraries
- An x64 Native Tools Command Prompt for Visual Studio

No package manager, downloaded runtime, server, or network access is required by the build.

The seven source bodies intentionally use `.txt` extensions. `/TP` tells MSVC to compile `src/APP.txt` as C++, and its local includes assemble the other six bodies into one translation unit.

## Hardened release build

From the repository root:

```bat
mkdir build

cl.exe /nologo /std:c++20 /utf-8 /permissive- /Zc:__cplusplus /W4 /EHsc /O2 /MT /GS /sdl /guard:cf /Gy /Gw /TP ^
  /Fo:"build\MilesingLight.obj" /Fe:"build\MilesingLight.exe" "src\APP.txt" ^
  /link /SUBSYSTEM:WINDOWS /INCREMENTAL:NO /OPT:REF /OPT:ICF /DYNAMICBASE /NXCOMPAT /HIGHENTROPYVA ^
  /GUARD:CF /CETCOMPAT /RELEASE /Brepro /MANIFEST:EMBED ^
  /MANIFESTUAC:"level='asInvoker' uiAccess='false'"
```

## Constructive self-test

```bat
cl.exe /nologo /std:c++20 /utf-8 /permissive- /Zc:__cplusplus /W4 /EHsc /O2 /MT /GS /sdl /guard:cf /TP ^
  /DMILESING_OPERATOR_SELF_TEST ^
  /Fo:"build\MilesingLightSelfTest.obj" /Fe:"build\MilesingLightSelfTest.exe" "src\APP.txt" ^
  /link /SUBSYSTEM:CONSOLE /INCREMENTAL:NO /DYNAMICBASE /NXCOMPAT /HIGHENTROPYVA /GUARD:CF /CETCOMPAT

build\MilesingLightSelfTest.exe
```

Expected output:

```text
PASS 111/111 world-bound Light operator laws
PASS canonical codec: every Operand tag + 111 applied fixtures round-trip byte-exactly
PASS recoverable local writing: first + replacement + protected prior + SHA-256 + exact reopen
PASS canonical realization: attention + exact Editor restoration + replay-derived results
```

## Release evidence

For each public release, record:

- exact Git commit and annotated tag;
- compiler and Windows SDK versions;
- complete self-test output;
- executable byte size and SHA-256;
- PE architecture, subsystem, and mitigation flags;
- imported DLL boundary;
- Authenticode status.

The `v0.1.0-alpha` executable is unsigned. Signing can be added later without changing the source mathematics.
