if not exist ./obj mkdir obj

@rem debug build: this also enabled the ingame editor
fpc -Mobjfpc -g -gl -S2 -Sg -Sc -Sh -XS -Xt -FU./obj ExtractVARFromOBJ.pas

@rem release build
@rem fpc -Mobjfpc -S2 -Sg -Sc -Sh -XS -Xt -FU./obj -Fu"../SDL2-for-Pascal/units" KStereo.PAS

@if %ERRORLEVEL% GEQ 1 EXIT /B %ERRORLEVEL%

ExtractVARFromOBJ.EXE ..\original\x29.OBJ .\data\obj3d\x29.var