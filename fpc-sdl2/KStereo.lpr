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
    MaxImx = 768{480};
    MaxColor = 255;
    MaxEx: integer = 512; {320}
    MaxEy: integer = 384; {240}
    NpCol: integer = 80;

    WorkMode: TWorkMode = TWorkMode.Generate;

var
    Ecul, Shape: array[0..2 * maximx] of integer;
    Mcul: array[0..maximx] of UInt32;
    Xst, Xdr, XModel, A: longint;
    ObjInScene: integer;
    gd, gm: integer;
    max, i, j: integer;
    x1, y1, z1: longint;
    Texture: PSDL_Surface;
    Output: PSDL_Surface;
    F: file;
    c: byte;

    CurrentScene: TScene;
    ExitRequested: boolean;

    PixelFormat: PSDL_PixelFormat;

    event: TSDL_Event;

procedure SphereSDF(pos: Point3D; x, y: longint; r: longint);
var
    u: real;
    shapeValue: longint;
begin
        u := sqr(r - pos.z) - sqr(x - pos.x) - sqr(y - pos.y);

        if u > 0 then
        begin
            shapeValue := round(r - sqrt(u));

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
                            for j := 1 to Obj3D[i].ObjData^.FC do
                            begin
                                { track the closest Z coordinate }
                                det2 :=
                                    (xc - Obj3D[i].ObjData^.Vertex^
                                    [Obj3D[i].ObjData^.Face^[j].p1].x - Obj3D[i].ObjPos.x) * Obj3D[i].ObjData^.FaceParams^[j].m2 -
                                    (yc - Obj3D[i].ObjData^.Vertex^
                                    [Obj3D[i].ObjData^.Face^[j].p1].y - Obj3D[i].ObjPos.y) * Obj3D[i].ObjData^.FaceParams^[j].l2;

                                det3 :=
                                    (xc - Obj3D[i].ObjData^.Vertex^
                                    [Obj3D[i].ObjData^.Face^[j].p1].x - Obj3D[i].ObjPos.x) * Obj3D[i].ObjData^.FaceParams^[j].m1 -
                                    (yc - Obj3D[i].ObjData^.Vertex^
                                    [Obj3D[i].ObjData^.Face^[j].p1].y - Obj3D[i].ObjPos.y) * Obj3D[i].ObjData^.FaceParams^[j].l1;

                                if (Obj3D[i].ObjData^.FaceParams^[j].det1 <> 0)
                                {and (vectors[j].n1*det2-vectors[j].n2*det3 <> 0)} then
                                begin
                                    alfa := det2 / Obj3D[i].ObjData^.FaceParams^[j].det1;
                                    beta := -det3 / Obj3D[i].ObjData^.FaceParams^[j].det1;

                                    { verifica daca (x,y,zclose) e in interiorul triunghiului }
                                    if ((alfa > 0) and (alfa < 1{vectors[j].mod1}) and
                                        (beta > 0) and (beta < 1{vectors[j].mod2}) and
                                        (alfa + beta <= 1))
                                    then
                                    begin
                                        zclose :=
                                            Obj3D[i].ObjData^.Vertex^[Obj3D[i].ObjData^.Face^[j].p1].z +
                                            Obj3D[i].ObjPos.z +
                                            Obj3D[i].ObjData^.FaceParams^[j].n1 * alfa + Obj3D[i].ObjData^.FaceParams^[j].n2 * beta;

                                        if shape[xc + maxex] > zclose then
                                            shape[xc + maxex] := round(zclose);
                                    end;
                                end;
                            end;
                        end;

                        TObj3DType.Sphere:
                            SphereSDF(Obj3D[i].ObjPos, xc, yc, Obj3D[i].Scale.x);
                    end;
        end;
end;

procedure MyStereo;
var
    x, y, k: integer;
    c: byte;
    textureBpp, texturePitch: longint;
    outputBpp, outputPitch: longint;
    textureY: longint;
    texture2Screen: PSDL_Texture;
    DstRect: TSDL_Rect;
begin
    randomize;
    fillchar(MCul, sizeof(MCul), 0);

    textureBpp := Texture^.format^.BytesPerPixel;
    texturePitch := Texture^.pitch;

    outputBpp := Output^.format^.BytesPerPixel;
    outputPitch := Output^.pitch;

    SDL_LockSurface(Texture);

    a := CurrentScene.ZBufferMax div CurrentScene.Dif;
    for y := maxey downto -maxey + 1 do
    begin
        textureY := (y + MaxEx) mod npcol;

        SDL_LockSurface(Texture);
        for k := 0 to npcol - 1 do
            MCul[k] := PUInt32(PUint8(Texture^.pixels) + textureY * texturePitch + k * textureBpp)^;
        SDL_UnlockSurface(Texture);

        TrackASceneLine(y);

        fillchar(ECul, sizeof(ECul), 0);
        xmodel := 0;

        for xst := -maxex to maxex do
        begin
            xmodel := (xmodel + 1) mod npcol;
            xdr := xst + npcol - CurrentScene.Dif + shape[xst + maxex + npcol div 2] div a;

            if ecul[xst + maxex] = 0 then
            begin ecul[xst + maxex] := xmodel end;

              {Log.LogStatus(Format('shape/dif/a/npcol: %d %d %d %d', [shape[xst + maxex + npcol div 2], dif, a, npcol]), '3D');
              Log.LogStatus(Format('xst/ecul[xst]: %d %d', [xst + MaxEx, ecul[xst + maxex]]), '3D');
              Log.LogStatus(Format('xdr/ecul[xdr]: %d %d', [xdr + MaxEx, ecul[xdr + maxex]]), '3D');}

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

        SDL_SetRenderDrawColor(SdlRenderer, $0, $0, $0, $FF);
        SDL_RenderClear(SdlRenderer);

        texture2Screen := SDL_CreateTextureFromSurface(SdlRenderer, Output);

        SDL_RenderCopy(SdlRenderer, texture2Screen, nil, nil);

        SDL_RenderPresent(SdlRenderer);

        SDL_DestroyTexture(texture2Screen);
    end;

    SDL_UnlockSurface(Texture);
end;

function LoadTexture(fileName: string; format: PSDL_PixelFormat): PSDL_Surface;
var
    tmpSurface: PSDL_Surface;
begin
    tmpSurface := IMG_Load(PChar(fileName));

    if tmpSurface = nil then
    begin Halt end;

    LoadTexture := SDL_ConvertSurface(tmpSurface, format, 0);

    SDL_FreeSurface(tmpSurface);
end;

procedure RenderMenu;
const
    MARGIN = 5;
    statusBarY = SCREEN_HEIGHT - MARGIN;
    BAR_HEIGHT = MARGIN + FONT_SIZE * 3 div 2;
begin
    Bar(0, SCREEN_HEIGHT - BAR_HEIGHT, SCREEN_WIDTH, BAR_HEIGHT, COLOR_BLACK);

    OutTextXY(MARGIN, statusBarY, CurrentScene.sceneName, FontMenu, COLOR_WHITE, BOTTOM);

    OutTextXY(SCREEN_WIDTH - MARGIN, statusBarY, '[G]enerate, [P]review, [R]eload, [S]ave, [ESC] Exit', FontMenu, COLOR_WHITE, BOTTOM or RIGHT, SDLRenderer);

    SDL_RenderPresent(SdlRenderer);
end;

procedure LoadScene(fileName: string);
begin
    { TODO cleanup the scene }
    CurrentScene := LoadSceneFromJSON(ParamStr(1));

    if Texture <> nil then
        SDL_DestroyTexture(Texture);

    { load the texture }
    Texture := LoadTexture(CurrentScene.textureFileName, PixelFormat);

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
end;

begin
    if ParamCount <> 1 then
        Halt;

    for i := 1 to ParamCount do
        Log.LogStatus(Format('%d %s', [i, ParamStr(i)]), 'Command Line');

    { start init video mode }
    InitSDL('Stereogram Generator', SCREEN_WIDTH, SCREEN_HEIGHT);
    { end init video mode }

	FontMenu := TTF_OpenFont('fonts/RobotoCondensed-Light.ttf', FONT_SIZE);
	TTF_SetFontHinting(FontMenu, TTF_HINTING_NORMAL);

    PixelFormat := SDL_AllocFormat(SDL_PIXELFORMAT_RGBA32);

    LoadScene(ParamStr(1));

    RenderMenu;    

    ExitRequested := false;

    repeat    
        while SDL_PollEvent(@event) = 1 do
        begin
            case event.type_ of
                SDL_KEYDOWN:
                begin
                    case event.key.keysym.sym of
                        SDLK_ESCAPE:
                            ExitRequested := true;

                        SDLK_P:
                        begin
                            WorkMode := TWorkMode.Preview;
                            MyStereo;
                            RenderMenu;
                        end;

                        SDLK_G:
                        begin
                            WorkMode := TWorkMode.Generate;
                            MyStereo;
                            RenderMenu;
                        end;

                        SDLK_R:
                        begin
                            LoadScene(ParamStr(1));
                        end;

                        SDLK_S:
                            IMG_SavePNG(Output, PChar(CurrentScene.outputFileName));
                    end;
                end;
            end;
        end;
    until ExitRequested;

	TTF_CloseFont(FontMenu);
    SDL_FreeSurface(Texture);
    ShutDownSDL;
end.
