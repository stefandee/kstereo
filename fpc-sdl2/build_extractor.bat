if not exist ./obj mkdir obj

@rem debug build: this also enabled the ingame editor
fpc -Mobjfpc -g -gl -S2 -Sg -Sc -Sh -XS -Xt -FU./obj ExtractVARFromOBJ.pas

@rem release build
@rem fpc -Mobjfpc -S2 -Sg -Sc -Sh -XS -Xt -FU./obj -Fu"../SDL2-for-Pascal/units" KStereo.PAS

@if %ERRORLEVEL% GEQ 1 EXIT /B %ERRORLEVEL%

ExtractVARFromOBJ.EXE .\data\obj3d\BFLY.OBJ .\data\obj3d\butterfly.var