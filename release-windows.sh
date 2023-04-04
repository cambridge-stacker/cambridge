#!/bin/sh

./package.sh
mkdir dist
mkdir dist/windows
mkdir dist/win32
mkdir dist/other
cat dist/windows/love.exe cambridge.love > dist/windows/cambridge.exe
zip dist/cambridge_windows_x64.zip dist/windows/* SOURCES.md LICENSE.md
cat dist/win_aarch64/love.exe cambridge.love > dist/windows/cambridge.exe
zip dist/cambridge_windows_aarch64_experimental.zip dist/windows/* SOURCES.md LICENSE.md
cat dist/win32/love.exe cambridge.love > dist/win32/cambridge.exe
zip dist/cambridge_windows_x86.zip dist/win32/* SOURCES.md LICENSE.md
zip dist/cambridge_other.zip cambridge.love libs/discord-rpc.* SOURCES.md LICENSE.md
