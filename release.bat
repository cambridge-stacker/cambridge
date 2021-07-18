call package.bat

mkdir dist
mkdir dist\windows
mkdir dist\windows\libs
mkdir dist\win32
mkdir dist\win32\libs
mkdir dist\other
mkdir dist\other\libs

copy /b dist\windows\love.exe+cambridge.love dist\windows\cambridge.exe
copy /b dist\win32\love.exe+cambridge.love dist\win32\cambridge.exe
copy /b cambridge.love dist\other\cambridge.love

copy libs\discord-rpc.dll dist\windows\libs
copy libs\discord-rpc.dll dist\win32\libs
copy libs\discord-rpc.* dist\other\libs

copy SOURCES.md dist\windows
copy LICENSE.md dist\windows
copy SOURCES.md dist\win32
copy LICENSE.md dist\win32
copy SOURCES.md dist\other
copy LICENSE.md dist\other

cd dist\windows
tar -a -c -f ..\cambridge-windows.zip cambridge.exe *.dll libs *.md
cd ..\..

cd dist\win32
tar -a -c -f ..\cambridge-win32.zip cambridge.exe *.dll libs *.md
cd ..\..

cd dist\other
tar -a -c -f ..\cambridge-other.zip cambridge.love libs *.md
cd ..\..