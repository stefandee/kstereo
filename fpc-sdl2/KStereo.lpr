program StereogramGenerator_Slow;

uses
    DOS,
    CRT,
    SDLWrapper,
    SDL2,
    SDL2_image,
    SysUtils,
    Math,
    Scene,
    ThreeD,
    Logger,
    Graphics,
    SDL2_ttf;

type
    TWorkMode = (Preview, Generate);

const
    FONT_SIZE = 18;

    WorkMode: TWorkMode = TWorkMode.Generate;

var
    Ecul, Shape: array of integer;
    Mcul: array of UInt32;

    Xst, Xdr, XModel, A: longint;
    MaxEx, MaxEY: integer;
    i: integer;
    Texture: PSDL_Surface;
    Output: PSDL_Surface;

    CurrentScene: TScene;
    ExitRequested: boolean;

    PixelFormat: PSDL_PixelFormat;

    SceneFileName: string;
    event: TSDL_Event;

procedure ConvexSphereSDF(pos: Point3D; x, y: longint; r: longint);
var
    u: real;
    shapeValue: longint;
begin
        u := sqr(r) - sqr(x - pos.x) - sqr(y - pos.y);

        if u > 0 then
        begin
            shapeValue := round(pos.z - sqrt(u));

            if shape[x + maxex] > shapeValue then shape[x + maxex] := shapeValue;
        end;
end;

procedure ConcaveSphereSDF(pos: Point3D; x, y: longint; r: longint);
var
    u: real;
    shapeValue: longint;
begin
        u := sqr(r - pos.z) - sqr(x - pos.x) - sqr(y - pos.y);

        if u > 0 then
        begin
            shapeValue := round(pos.z + sqrt(u));

            if shape[x + maxex] > shapeValue then shape[x + maxex] := shapeValue;
        end;
end;

procedure TrackASceneLine(yc: longint);
var
    xc: longint;
    i, j: integer;
    zclose: single;
    det2, det3: longint;
    alfa, beta: single; { coordonate relative la triunghi }
begin
    with CurrentScene do
        for xc := -maxex to maxex - 1 do
        begin
            shape[xc + maxex] := ZBufferMax;
            for i := 1 to Obj3dCount do
                with Obj3D[i] do
                    case Obj3D[i].ObjType of
                        TObj3DType.Mesh:
                        begin
                            for j := 1 to ObjData^.FC do
                            begin
                                { track the closest Z coordinate }
                                det2 :=
                                    (xc - ObjData^.Vertex^
                                    [ObjData^.Face^[j].p1].x - ObjPos.x) * ObjData^.FaceParams^[j].m2 -
                                    (yc - ObjData^.Vertex^
                                    [ObjData^.Face^[j].p1].y - ObjPos.y) * ObjData^.FaceParams^[j].l2;

                                det3 :=
                                    (xc - ObjData^.Vertex^
                                    [ObjData^.Face^[j].p1].x - ObjPos.x) * ObjData^.FaceParams^[j].m1 -
                                    (yc - ObjData^.Vertex^
                                    [ObjData^.Face^[j].p1].y - ObjPos.y) * ObjData^.FaceParams^[j].l1;

                                if (ObjData^.FaceParams^[j].det1 <> 0)
                                {and (vectors[j].n1*det2-vectors[j].n2*det3 <> 0)} then
                                begin
                                    alfa := det2 / ObjData^.FaceParams^[j].det1;
                                    beta := -det3 / ObjData^.FaceParams^[j].det1;

                                    { verifica daca (x,y,zclose) e in interiorul triunghiului }
                                    if ((alfa > 0) and (alfa < 1{vectors[j].mod1}) and
                                        (beta > 0) and (beta < 1{vectors[j].mod2}) and
                                        (alfa + beta <= 1))
                                    then
                                    begin
                                        zclose :=
                                            ObjData^.Vertex^[ObjData^.Face^[j].p1].z + ObjPos.z + 
                                            ObjData^.FaceParams^[j].n1 * alfa + ObjData^.FaceParams^[j].n2 * beta;

                                        if shape[xc + maxex] > zclose then
                                            shape[xc + maxex] := round(zclose);
                                    end;
                                end;
                            end;
                        end;

                        TObj3DType.ConvexSphere:
                            ConvexSphereSDF(Obj3D[i].ObjPos, xc, yc, Obj3D[i].Scale.x);

                        TObj3DType.ConcaveSphere:
                            ConcaveSphereSDF(Obj3D[i].ObjPos, xc, yc, Obj3D[i].Scale.x);
                    end;
        end;
end;

procedure GenerateStereogram;
var
    x, y, k: integer;
    textureBpp, texturePitch: longint;
    outputBpp, outputPitch: longint;
    textureY: longint;
    texture2Screen: PSDL_Texture;
    TextureWidth: longint;
begin
    TextureWidth := Texture^.w;

    textureBpp := Texture^.format^.BytesPerPixel;
    texturePitch := Texture^.pitch;

    outputBpp := Output^.format^.BytesPerPixel;
    outputPitch := Output^.pitch;

    a := CurrentScene.ZBufferMax div CurrentScene.Dif;
    for y := maxey downto -maxey + 1 do
    begin
        textureY := (y + MaxEx) mod TextureWidth;

        for k := 0 to TextureWidth - 1 do
        begin
            MCul[k] := PUInt32(PUint8(Texture^.pixels) + textureY * texturePitch + k * textureBpp)^;
        end;

        TrackASceneLine(y);

        for k := 0 to sizeof(ECul) do
            ECul[k] := 0;

        xmodel := 0;

        for xst := -maxex to maxex do
        begin
            xmodel := (xmodel + 1) mod TextureWidth;
            xdr := xst + TextureWidth - CurrentScene.Dif + shape[xst + maxex + TextureWidth div 2] div a;

            if ecul[xst + maxex] = 0 then
            begin ecul[xst + maxex] := xmodel end;

            ecul[xdr + maxex] := ecul[xst + maxex];
        end;

        SDL_LockSurface(Output);

        for x := -maxex to maxex do
        begin
            if WorkMode = TWorkMode.Preview then
                PUInt32(PUint8(Output^.pixels) + (maxey - y) * outputPitch +
                    (x + maxex) * outputBpp)^ := ((255 * Abs(CurrentScene.ZBufferMax - shape[x + maxex]) div CurrentScene.ZBufferMax) shl 8) or $FF000000
            else
                PUInt32(PUint8(Output^.pixels) + (maxey - y) * outputPitch +
                    (x + maxex) * outputBpp)^ := mcul[ecul[x + maxex]];
        end;

        SDL_UnlockSurface(Output);

        { live preview }
        SDL_SetRenderDrawColor(SdlRenderer, $0, $0, $0, $FF);
        SDL_RenderClear(SdlRenderer);

        texture2Screen := SDL_CreateTextureFromSurface(SdlRenderer, Output);

        SDL_RenderCopy(SdlRenderer, texture2Screen, nil, nil);

        SDL_RenderPresent(SdlRenderer);

        SDL_DestroyTexture(texture2Screen);

        { tiny bit of delay to avoid unresponsive window - well, maybe }
        SDL_Delay(15);
    end;
end;

function LoadTexture(fileName: string; pixelFormat: PSDL_PixelFormat): PSDL_Surface;
var
    tmpSurface: PSDL_Surface;
begin
    tmpSurface := IMG_Load(PChar(fileName));

    if tmpSurface = nil then
    begin
        Log.LogError(
            Format('IMG_Load(%s) failed with error %s', [fileName, SDL_GetError]), 
            'LoadTexture');
        Halt;
    end;

    LoadTexture := SDL_ConvertSurface(tmpSurface, pixelFormat, 0);

    SDL_FreeSurface(tmpSurface);
end;

procedure RenderMenu;
const
    MARGIN = 5;
    statusBarY = SCREEN_HEIGHT - MARGIN;
    BAR_HEIGHT = MARGIN + FONT_SIZE * 3 div 2;
begin
    Bar(0, SCREEN_HEIGHT - BAR_HEIGHT, SCREEN_WIDTH, BAR_HEIGHT, $40000000);

    OutTextXY(MARGIN, statusBarY, CurrentScene.sceneName, FontMenu, COLOR_WHITE, BOTTOM);

    OutTextXY(SCREEN_WIDTH - MARGIN, statusBarY, '[G]enerate, [P]review, [R]eload, [S]ave, [ESC] Exit', FontMenu, COLOR_WHITE, BOTTOM or RIGHT, SDLRenderer);

    SDL_RenderPresent(SdlRenderer);
end;

procedure LoadScene(fileName: string);
begin
    { TODO cleanup the scene }
    CurrentScene := LoadSceneFromJSON(fileName);

    Log.LogStatus(Format('Scene %s %s', [fileName, CurrentScene.baseScenePath]), 'LoadScene');

    if Texture <> nil then
        SDL_FreeSurface(Texture);

    { load the texture }
    Texture := LoadTexture(ConcatPaths([CurrentScene.baseScenePath, CurrentScene.textureFileName]), PixelFormat);

    if Texture = nil then
        Halt;

    { setup the output surface }
    if Output <> nil then
        SDL_FreeSurface(Output);

    Output := SDL_CreateRGBSurfaceWithFormat(0, CurrentScene.outputResolution.x, CurrentScene.outputResolution.y, 32, SDL_PIXELFORMAT_RGBA32);

    { prepare the scene: scale, rotate and precompute the face params }
    with CurrentScene do
        for i := 1 to Obj3dCount do
            if Obj3D[i].ObjType = TObj3DType.Mesh then
            begin
                ScaleObj(Obj3D[i].ObjData, Obj3D[i].Scale.x, Obj3D[i].Scale.y, Obj3D[i].Scale.z);
                RotateObj(Obj3D[i].ObjData, Obj3D[i].Ang.x, Obj3D[i].Ang.y, Obj3D[i].Ang.z, ZERO);

                PrecomputeFaceValues(Obj3D[i]);
            end;
    
    { setup params used for generation }
    MaxEx := CurrentScene.outputResolution.x div 2;
    MaxEy := CurrentScene.outputResolution.y div 2;

    setLength(ECul, 2 * CurrentScene.outputResolution.y + 1);
    setLength(Shape, 2 * CurrentScene.outputResolution.y + 1);
    setLength(MCul, CurrentScene.outputResolution.y + 1);
end;

begin
    if ParamCount <> 1 then
        Halt;

    for i := 1 to ParamCount do
        Log.LogStatus(Format('%d %s', [i, ParamStr(i)]), 'Command Line');

    SceneFileName := ParamStr(1);

    { start init video mode }
    InitSDL('Stereogram Generator', SCREEN_WIDTH, SCREEN_HEIGHT);
    { end init video mode }

	FontMenu := TTF_OpenFont('fonts/RobotoCondensed-Light.ttf', FONT_SIZE);
	TTF_SetFontHinting(FontMenu, TTF_HINTING_NORMAL);

    PixelFormat := SDL_AllocFormat(SDL_PIXELFORMAT_RGBA32);

    LoadScene(SceneFileName);

    { TODO should we start with render the scene preview or let the use choose? }
    RenderMenu;

    ExitRequested := false;

    repeat    
        while SDL_PollEvent(@event) = 1 do
        begin
            case event.type_ of
                SDL_QUITEV:
                    ExitRequested := true;

                SDL_KEYDOWN:
                begin
                    case event.key.keysym.sym of
                        SDLK_ESCAPE:
                            ExitRequested := true;

                        SDLK_P:
                        begin
                            WorkMode := TWorkMode.Preview;
                            GenerateStereogram;
                            RenderMenu;
                        end;

                        SDLK_G:
                        begin
                            WorkMode := TWorkMode.Generate;
                            GenerateStereogram;
                            RenderMenu;
                        end;

                        SDLK_R:
                        begin
                            LoadScene(SceneFileName);
                        end;

                        SDLK_S:
                            IMG_SavePNG(Output, PChar(ConcatPaths([CurrentScene.baseScenePath, CurrentScene.outputFileName])));
                    end;
                end;
            end;
        end;
    until ExitRequested;

	TTF_CloseFont(FontMenu);
    SDL_FreeSurface(Texture);
    ShutDownSDL;
end.
