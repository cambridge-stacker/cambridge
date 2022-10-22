#!/bin/sh

./package.sh
mkdir dist
mkdir dist/windows
mkdir dist/win32
mkdir dist/other
cat dist/windows/love.exe cambridge.love > dist/windows/cambridge.exe
zip dist/cambridge-windows.zip dist/windows/* SOURCES.md LICENSE.md
cat dist/win32/love.exe cambridge.love > dist/win32/cambridge.exe
zip dist/cambridge-win32.zip dist/win32/* SOURCES.md LICENSE.md
cp cambridge.love dist/other/
zip dist/cambridge-other.zip cambridge.love libs/discord-rpc.* SOURCES.md LICENSE.md
