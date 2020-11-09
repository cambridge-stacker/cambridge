call package.bat

mkdir dist
mkdir dist\windows
mkdir dist\windows\libs
mkdir dist\win32
mkdir dist\win32\libs

copy /b dist\windows\love.exe+cambridge.love dist\windows\cambridge.exe
copy /b dist\win32\love.exe+cambridge.love dist\win32\cambridge.exe

copy libs\discord-rpc.dll dist\windows\libs
copy libs\discord-rpc.dll dist\win32\libs

copy SOURCES.md dist\windows
copy LICENSE.md dist\windows
copy SOURCES.md dist\win32
copy LICENSE.md dist\win32

cd dist\windows
tar -a -c -f ..\cambridge-windows.zip cambridge.exe *.dll libs *.md
cd ..\..

cd dist\win32
tar -a -c -f ..\cambridge-win32.zip cambridge.exe *.dll libs *.md
cd ..\..