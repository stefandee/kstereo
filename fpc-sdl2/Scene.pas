unit Scene;

interface

uses
    ThreeD,
	fpjson,
	jsonparser,
	jsonConf,
    Logger,
    SysUtils,
    Classes;

type
    { Filenames are relative to path of the scene file (baseScenePath) }
    TScene = record
        baseScenePath: string;

        sceneName: UnicodeString; 

        outputFileName: string; 
        outputResolution: Point2D;

        textureFileName: UnicodeString;

        Obj3d: array[1..MaxObj] of TDefObj;

        Obj3dCount: integer;

        ZBufferMax: integer;
        Dif: integer;        
    end;

function LoadSceneFromJSON(fileName: string): TScene;

implementation

function LoadSceneFromJSON(fileName: string): TScene;
var
    Scene: TScene;
    c: TJSONConfig;
    ObjKeys: TStringList;
    TypeStr: UnicodeString;
    i: integer;
    ObjJSON: TJSONObject;
    TmpObjType: TObj3DType;
    ValidObjType: boolean;
    Obj3DFileName: UnicodeString;
    BaseObjKeyStr: string;
begin
    c := TJSONConfig.Create(Nil);
    ObjKeys := TStringList.Create;

    try
        //try/except to handle broken json file
        try
        c.Formatted:= true;
        c.Filename:= fileName;
        except
        exit;
        end;

        with Scene do
        begin
            baseScenePath := ExtractFilePath(ExpandFileName(fileName));

            sceneName := c.GetValue('/sceneName', 'New Scene');
            textureFileName := c.GetValue('/textureFileName', '');

            outputFileName := c.GetValue('/output/fileName', 'output.png');
            outputResolution.x := c.GetValue('/output/resolution/width', 640);
            outputResolution.y := c.GetValue('/output/resolution/height', 480);

            ZBufferMax := c.GetValue('/ZBufferMax', 256);
            Dif := c.GetValue('/Dif', 42);

            Log.LogStatus(Format('%s %d %d %d', [outputFileName, outputResolution.x, outputResolution.y, ZBufferMax]), 'SceneLoad');

            c.EnumSubKeys('/obj', ObjKeys);
            Log.LogStatus(Format('EnumSubKeys obj3d count %d', [ObjKeys.Count]), 'SceneLoad');

            Obj3dCount := 0;

            for i := 0 to ObjKeys.Count - 1 do
            begin
                BaseObjKeyStr := '/obj/' + ObjKeys[i];

                typeStr := c.GetValue(BaseObjKeyStr + '/type', '');
                Log.LogStatus(Format('key: %s', [ObjKeys[i]]), 'SceneLoad');

                ValidObjType := false;

                case typeStr of
                    'mesh':
                        begin
                            TmpObjType := TObj3DType.Mesh;
                            ValidObjType := true;
                            Log.LogStatus(Format('mesh %d', [TmpObjType]), 'SceneLoad');
                        end;

                    'concavesphere':
                        begin
                            TmpObjType := TObj3DType.ConcaveSphere;
                            ValidObjType := true;
                            Log.LogStatus(Format('sphere %d', [TmpObjType]), 'SceneLoad');
                        end;

                    'convexsphere':
                        begin
                            TmpObjType := TObj3DType.ConvexSphere;
                            ValidObjType := true;
                            Log.LogStatus(Format('sphere %d', [TmpObjType]), 'SceneLoad');
                        end;
                end;

                if not ValidObjType then continue;

                with Obj3D[Obj3dCount + 1] do
                begin
                    ObjType := TmpObjType;

                    ObjPos.x := c.GetValue(BaseObjKeyStr + '/pos/x', 0);
                    ObjPos.y := c.GetValue(BaseObjKeyStr + '/pos/y', 0);
                    ObjPos.z := c.GetValue(BaseObjKeyStr + '/pos/z', 0);

                    case ObjType of
                        TObj3DType.Mesh:
                            begin
                                Ang.x := c.GetValue(BaseObjKeyStr + '/angle/x', 0);
                                Ang.y := c.GetValue(BaseObjKeyStr + '/angle/y', 0);
                                Ang.z := c.GetValue(BaseObjKeyStr + '/angle/z', 0);

                                Scale.x := c.GetValue(BaseObjKeyStr + '/scale/x', 1);
                                Scale.y := c.GetValue(BaseObjKeyStr + '/scale/y', 1);
                                Scale.z := c.GetValue(BaseObjKeyStr + '/scale/z', 1);

                                Obj3DFileName := c.GetValue(BaseObjKeyStr + '/fileName', '');

                                if (ObjType = TObj3DType.Mesh) and (Obj3DFileName <> '') then
                                begin
                                    new(ObjData);

                                    Log.LogStatus(Format('obj3d path %s', [ConcatPaths([baseScenePath, Obj3DFileName])]), 'SceneLoad');
                                    InitObjFromVar(ConcatPaths([baseScenePath, Obj3DFileName]), ObjData);
                                end;
                            end;

                        TObj3DType.ConvexSphere, TObj3DType.ConcaveSphere:
                            begin
                                Scale.x := c.GetValue(BaseObjKeyStr + '/radius', 0);
                                Scale.y := Scale.x;
                                Scale.z := Scale.x;

                                Log.LogStatus(Format('sphere radius %d', [Scale.x]), 'SceneLoad');
                            end;
                    end;
                end;

                inc(Obj3dCount);
            end;

            Log.LogStatus(Format('Obj3d count %d', [Obj3dCount]), 'SceneLoad');
        end;
    finally
        c.Free;
        ObjKeys.Free;
    end;

    LoadSceneFromJSON := Scene;
end;

begin
end.