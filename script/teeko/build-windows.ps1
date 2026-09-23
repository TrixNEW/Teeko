$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true

$target = 'x86_64-pc-windows-msvc'
$env:ZED_BUNDLE = 'true'
$env:RELEASE_CHANNEL = (Get-Content crates/zed/RELEASE_CHANNEL -Raw).Trim()
$versionLine = Select-String -Path crates/zed/Cargo.toml -Pattern '^version = "([^"]+)"'
$env:RELEASE_VERSION = $versionLine.Matches[0].Groups[1].Value
$env:LIBCLANG_PATH = 'C:\Program Files\LLVM\bin'
if (-not (Test-Path "$env:LIBCLANG_PATH\libclang.dll")) {
    throw 'The Windows runner must have LLVM/libclang installed.'
}
rustup target add $target
cargo --config .cargo/bundle-config.toml build --locked --release --target $target --package zed --bin zed --package cli --bin cli --package auto_update_helper --bin auto_update_helper

$out = "target/$target/release"
$stage = 'target/teeko-windows'
if (Test-Path $stage) { Remove-Item $stage -Recurse -Force }
New-Item -ItemType Directory -Force "$stage/bin", "$stage/tools", "$stage/x64", 'dist' | Out-Null
Copy-Item "$out/zed.exe" "$stage/Zed.exe"
Copy-Item "$out/cli.exe" "$stage/bin/zed.exe"
Copy-Item "$out/auto_update_helper.exe" "$stage/tools/auto_update_helper.exe"
Copy-Item "$out/conpty.dll" "$stage/conpty.dll"
Copy-Item "$out/OpenConsole.exe" "$stage/OpenConsole.exe"
Copy-Item "$out/OpenConsole.exe" "$stage/x64/OpenConsole.exe"
Copy-Item assets/licenses.md "$stage/licenses.md"
Copy-Item LICENSE* $stage

$agsZip = 'target/teeko-ags.zip'
$agsDir = 'target/teeko-ags'
Invoke-WebRequest 'https://codeload.github.com/GPUOpen-LibrariesAndSDKs/AGS_SDK/zip/refs/tags/v6.3.0' -OutFile $agsZip
Expand-Archive $agsZip -DestinationPath $agsDir -Force
Copy-Item "$agsDir/AGS_SDK-6.3.0/ags_lib/lib/amd_ags_x64.dll" $stage
Copy-Item "$agsDir/AGS_SDK-6.3.0/LICENSE.txt" "$stage/AMD-AGS-LICENSE.txt"
Compress-Archive -Path "$stage/*" -DestinationPath 'dist/Teeko-windows-x86_64.zip' -Force
