unit ThreeD;

interface

uses
    Logger,
    SysUtils;

CONST
     MaxVertex = 4900;
     MaxFace   = 9000;
     MaxObj    = 25;
     ScaleFactor : byte = 1;

CONST
     PI180 = pi/180;
     PI2   = pi*2;

TYPE
    Point2D = record
              x,y : integer;
            end;

    Point3D = record
              x,y,z : integer;
            end;

    TVector = record
              x,y,z : integer;
            end;

    TFace3D = record
            P1,P2,P3 : integer;
            Color    : byte;
          end;

    TPrecomputedFaceValues = record
        l1, m1, n1: longint;
        l2, m2, n2: longint;
        det1: longint;
    end;

    TPrecomputedFaceValuesArray = array[1..MaxFace] of TPrecomputedFaceValues;
    PTPrecomputedFaceValuesArray = ^TPrecomputedFaceValuesArray;

    TVertexArray = array[1..MaxVertex] of Point3D;
    PTVertexArray = ^TVertexArray;

    TFaceArray = array[1..MaxFace] of TFace3D;
    PTFaceArray = ^TFaceArray;

    TObj3DType = (Mesh, ConvexSphere, ConcaveSphere);

    PTObj3D= ^TObj3D;
    TObj3D = record
             VC,FC: Word;             
             Vertex: PTVertexArray;
             {VertexN: array[1..MaxVertex] of TVector;}{ this is for Gouraud and Phong shading }
             Face: PTFaceArray;
             FaceParams: PTPrecomputedFaceValuesArray;
           end;

    PTPro  = ^TPro;
    TPro   = array[1..MaxVertex] of Point2D;
    TDefObj = record
              ObjData : PTObj3D;
              ObjPos  : Point3D;
              Ang     : Point3D;
              Scale   : Point3D;
              Dir     : Point3D;
              SupAng  : Point3D;
              ObjType : TObj3DType;
            end;

VAR
	ZERO : Point3D = (x: 0; y: 0; z: 0);
   {Obj3d    : array[1..MaxObj] of TDefObj;}
   WorkObj  : PTObj3D;
   Pro      : PTPro;
   LightPos : Point3D;
   EyePos   : Point3D;
   {ObjPos   : Point3D;}
   Center   : Point3D;
   Invert   : array[1..3,1..3] of longint;
   EyeDir   : TVector;
   LightDir : TVector;
   vi,vj,vk : TVector;
   sintab,costab : array[0..359] of integer;

procedure SetDefaultCenter;
procedure RotatePoint (VAR P : Point3D;x,y,z : integer; center: Point3D);
procedure RotateObj(var WhatObj : PTObj3D; xa,ya,za : integer; center: Point3D);
procedure InitObjFromVar(sourcefile : string;var WhatObj : PTObj3D);
procedure PrecomputeFaceValues(var DefObj: TDefObj);
procedure ScaleObj(var WhatObj : PTObj3D; sx, sy, sz: integer);

implementation

procedure SetDefaultCenter;
begin
	Center := ZERO;
end;

procedure RotatePoint (VAR P : Point3D;x,y,z : integer; center: Point3D);
VAR
   a,b,c : longint;
   PRot  : Point3D;

BEGIN
 x:=x mod 360;y:=y mod 360;z:=z mod 360;
 b:=costab[y];
 c:=P.x-center.x;
 a := b * c div 16384;
 {asm
   mov   ax,b
   imul  c
   sal   ax,1
   rcl   dx,1
   sal   ax,1
   rcl   dx,1
   mov   a,dx
 end;}
 b:=sintab[y];
 c:=P.z-center.z;
 a:=a + b * c div 16384;
 {asm
   mov   ax,b
   imul  c
   sal   ax,1
   rcl   dx,1
   sal   ax,1
   rcl   dx,1
   add   a,dx
 end;}
 PRot.x:=a;
 PRot.y:=P.y-center.y;
 b:=-sintab[y];
 c:=P.x-center.x;
 a:=b*c div 16384;
 {asm
   mov   ax,b
   imul  c
   sal   ax,1
   rcl   dx,1
   sal   ax,1
   rcl   dx,1
   mov   a,dx
 end;}
 b:=costab[y];
 c:=P.z-center.z;
 a:=a + (b*c div 16384);
 {asm
   mov   ax,b
   imul  c
   sal   ax,1
   rcl   dx,1
   sal   ax,1
   rcl   dx,1
   add   a,dx
 end;}
 PRot.z:=a+center.z;

 if x<>0 then BEGIN
   b:=costab[x];
   c:=PRot.y-center.y;
   a:=b*c div 16384;
   {asm
     mov   ax,b
     imul  c
     sal   ax,1
     rcl   dx,1
     sal   ax,1
     rcl   dx,1
     mov   a,dx
   end;}
   b:=sintab[x];
   c:=PRot.z-center.z;
   a:=a-(b*c div 16384);
   {asm
     mov   ax,b
     imul  c
     sal   ax,1
     rcl   dx,1
     sal   ax,1
     rcl   dx,1
     sub   a,dx
   end;}
   b:=sintab[x];
   c:=PRot.y-center.y;
   PRot.y:=a-center.y;
   a:=b*c div 16384;
   {asm
     mov   ax,b
     imul  c
     sal   ax,1
     rcl   dx,1
     sal   ax,1
     rcl   dx,1
     mov   a,dx
   end;}
   b:=costab[x];
   c:=PRot.z-center.z;
   a:=a+(b*c div 16384);
   {asm
     mov   ax,b
     imul  c
     sal   ax,1
     rcl   dx,1
     sal   ax,1
     rcl   dx,1
     add   a,dx
   end;}
   PRot.z:=a+center.z;
 END;

 if z<>0 then BEGIN
   b:=costab[z];
   c:=PRot.x-center.x;
   a:=b*c div 16384;
   {asm
     mov   ax,b
     imul  c
     sal   ax,1
     rcl   dx,1
     sal   ax,1
     rcl   dx,1
     mov   a,dx
   end;}
   b:=sintab[z];
   c:=PRot.y-center.y;
   a:=a-(b*c div 16384);
   {asm
     mov   ax,b
     imul  c
     sal   ax,1
     rcl   dx,1
     sal   ax,1
     rcl   dx,1
     sub   a,dx
   end;}
   b:=sintab[z];
   c:=PRot.x-center.x;
   PRot.x:=a+center.x;
   a:=b*c div 16384;
   {asm
     mov   ax,b
     imul  c
     sal   ax,1
     rcl   dx,1
     sal   ax,1
     rcl   dx,1
     mov   a,dx
   end;}
   b:=costab[z];
   c:=PRot.y-center.y;
   a:=a + (b * c div 16384);
   {asm
     mov   ax,b
     imul  c
     sal   ax,1
     rcl   dx,1
     sal   ax,1
     rcl   dx,1
     add   a,dx
   end;}
   PRot.y:=a-center.y;
 END;
 P:=PRot;
END;

{end procedure rotate point}

procedure RotateObj(var WhatObj : PTObj3D; xa,ya,za : integer; center: Point3D);
VAR i : integer;
    P : Point3D;
BEGIN
 { rotate every point }
 for i:=1 to WhatObj^.VC do
     begin
       RotatePoint(WhatObj^.Vertex^[i],xa,ya,za,center);
       {with WorkObj^.VertexN[i] do begin p.x:=x;p.y:=y;p.z:= z;end;
       RotatePoint(P,xa,ya,za);
       with WorkObj^.VertexN[i] do begin x:=p.x;y:=p.y;z:=p.z;end;}
     end;
 { rotate every normal }
 {for i:=1 to fc do
     begin
       with WorkObj^.Face[i].N do begin p.x:=x;p.y:=y;p.z:= z;end;
       RotatePoint(P,xa,ya,za);
       with WorkObj^.Face[i].N do begin x:=p.x;y:=p.y;z:=p.z;end;
     end;}
END;

procedure Inverter(vi,vj,vk : TVector);
BEGIN
 Invert[1,1]:=longint(vj.y)*longint(vk.z)-longint(vj.z)*longint(vk.y);
 Invert[1,2]:=longint(vi.z)*longint(vk.y)-longint(vi.y)*longint(vk.z);
 Invert[1,3]:=longint(vi.y)*longint(vj.z)-longint(vi.z)*longint(vj.y);
 Invert[2,1]:=longint(vj.z)*longint(vk.x)-longint(vj.x)*longint(vk.z);
 Invert[2,2]:=longint(vi.x)*longint(vk.z)-longint(vi.z)*longint(vk.x);
 Invert[2,3]:=longint(vj.x)*longint(vi.z)-longint(vi.x)*longint(vj.z);
 Invert[3,1]:=longint(vj.x)*longint(vk.y)-longint(vk.x)*longint(vj.y);
 Invert[3,2]:=longint(vk.x)*longint(vi.y)-longint(vi.x)*longint(vk.y);
 Invert[3,3]:=longint(vi.x)*longint(vj.y)-longint(vi.y)*longint(vj.x);
END;

procedure ProLook(BaseVC : integer;viewpoint,wherepoint : point3d);
var XPro,YPro,ZPro : longint;
    fpr : real;
    i : integer;
    difx,dify,difz,cdifx,cdify,cdifz,num : longint;
BEGIN
 difx:=(viewpoint.x-wherepoint.x);
 dify:=(viewpoint.y-wherepoint.y);
 difz:=(viewpoint.z-wherepoint.z);

 for i:=1 to BaseVC do
            begin
              cdifx:=WorkObj^.Vertex^[i].x+difx;
              cdify:=WorkObj^.Vertex^[i].y+dify;
              cdifz:=WorkObj^.Vertex^[i].z+difz;

              XPro:=
                     cdifx*Invert[1,1]+
                     cdify*Invert[2,1]+
                     cdifz*Invert[3,1];
              YPro:=
                     cdifx*Invert[1,2]+
                     cdify*Invert[2,2]+
                     cdifz*Invert[3,2];
              ZPro:=
                     cdifx*Invert[1,3]+
                     cdify*Invert[2,3]+
                     cdifz*Invert[3,3];
              if ZPro>0
                 then begin
                       Pro^[i].x:=(longint(XPro shl 7) div ZPro);
                       Pro^[i].y:=(longint(YPro shl 7) div ZPro);
                      end
                 else begin
                       Pro^[i].x:=160;
                       Pro^[i].y:=120;
                      end;
            end;
END;

procedure ProLookPoint(viewpoint,wherepoint : point3d);
var XPro,YPro,ZPro : longint;
    fpr : real;
    i : integer;
    difx,dify,difz,cdifx,cdify,cdifz,num : longint;
BEGIN
 cdifx:=(viewpoint.x-wherepoint.x);
 cdify:=(viewpoint.y-wherepoint.y);
 cdifz:=(viewpoint.z-wherepoint.z);

 XPro:=
        cdifx*Invert[1,1]+
        cdify*Invert[2,1]+
        cdifz*Invert[3,1];
 YPro:=
        cdifx*Invert[1,2]+
        cdify*Invert[2,2]+
        cdifz*Invert[3,2];
 ZPro:=
        cdifx*Invert[1,3]+
        cdify*Invert[2,3]+
        cdifz*Invert[3,3];

 if ZPro>0
    then begin
          Pro^[1].x:=((XPro shl 7) div ZPro);
          Pro^[1].y:=((YPro shl 7) div ZPro);
         end
    else begin
           Pro^[i].x:=160;
           Pro^[i].y:=120;
         end;
END;

procedure Normalize(var V : TVector;whatmodule : integer);
var
   modulus : longint;
begin
  modulus := round(sqrt(longint(V.x)*longint(V.x)+longint(V.y)*longint(V.y)+
             longint(V.z)*longint(V.z)));
  V.x := longint(longint(whatmodule)*longint(V.x)) div modulus;
  V.y := longint(longint(whatmodule)*longint(V.y)) div modulus;
  V.z := longint(longint(whatmodule)*longint(V.z)) div modulus;
end;

procedure InitObj(Data : pointer;var WhatObj : PTObj3D);
var
   dseg,dofs   : word;
   dofsaux     : word;
   dx2,dy2,dz2 : integer;
   dx1,dy1,dz1 : integer;
   modulus     : longint;
   i,j         : integer;
   failed      : integer;
   PWordData   : PWord;
begin
  { compute normals, read vertex, read faces }
  dseg := seg(Data^);dofs := ofs(Data^);
  failed := 0;
  PWordData := PWord(Data);
  WhatObj^.VC := PWordData^;
  for i:=1 to WhatObj^.VC do
      begin
        {WhatObj^.Vertex^[i].x := integer(memw[dseg:dofs+(i-1)*6+4])*ScaleFactor;
        WhatObj^.Vertex^[i].y := integer(memw[dseg:dofs+(i-1)*6+2+4])*ScaleFactor;
        WhatObj^.Vertex^[i].z := integer(memw[dseg:dofs+(i-1)*6+4+4])*ScaleFactor;}
        WhatObj^.Vertex^[i].x := (PWordData + (i-1)*6+4)^*ScaleFactor;
        WhatObj^.Vertex^[i].y := (PWordData + (i-1)*6+2+4)^*ScaleFactor;
        WhatObj^.Vertex^[i].z := (PWordData + (i-1)*6+4+4)^*ScaleFactor;
      end;
  dofsaux := WhatObj^.VC*6+4;
  WhatObj^.FC := (PWordData + dofsaux)^;
  {WhatObj^.FC := memw[dseg:dofsaux];}
  for i:=1 to WhatObj^.FC do
      with WhatObj^.Face^[i] do
           begin
             {p1 := memw[dseg:dofsaux+(i-1)*7];
             p2 := memw[dseg:dofsaux+(i-1)*7+2];
             p3 := memw[dseg:dofsaux+(i-1)*7+4];
             WhatObj^.Face^[i].color := mem[dseg:dofsaux+(i-1)*7+6];}
			 
             p1 := (PWordData + dofsaux+(i-1)*7)^;
             p2 := (PWordData + dofsaux+(i-1)*7+2)^;
             p3 := (PWordData + dofsaux+(i-1)*7+4)^;
             WhatObj^.Face^[i].color := (PUint8(Data) + dofsaux + (i-1) * 7 + 6)^;
			 
             dx1 := WhatObj^.Vertex^[p3].x-WhatObj^.Vertex^[p1].x;
             dx2 := WhatObj^.Vertex^[p2].x-WhatObj^.Vertex^[p1].x;
             dy1 := WhatObj^.Vertex^[p3].y-WhatObj^.Vertex^[p1].y;
             dy2 := WhatObj^.Vertex^[p2].y-WhatObj^.Vertex^[p1].y;
             dz1 := WhatObj^.Vertex^[p3].z-WhatObj^.Vertex^[p1].z;
             dz2 := WhatObj^.Vertex^[p2].z-WhatObj^.Vertex^[p1].z;
             { compute the normal vector }
             {N.x := dy2*dz1-dz2*dy1;
             N.y := dz2*dx1-dx2*dz1;
             N.z := dx2*dy1-dy2*dx1;}
             
			 { normalize this vector }
			 
             {modulus := round(sqrt(abs(longint(N.x)*longint(N.x)+longint(N.y)*longint(N.y)+
                        longint(N.z)*longint(N.z))));
             if modulus<>0
                then begin
                       N.x := longint(longint(63)*longint(N.x)) div modulus;
                       N.y := longint(longint(63)*longint(N.y)) div modulus;
                       N.z := longint(longint(63)*longint(N.z)) div modulus;
                     end;}
           end;
  { now we have all face normals, time to compute the resultant for each point }
  {with WhatObj^ do
    for i:=1 to VC do
        begin
          FillChar(VertexN[i],sizeof(TVector),0);
          for j:=1 to FC do
              begin
                if Face[j].P1 = i
                   then begin
                          inc(VertexN[i].x,Face[j].N.x);
                          inc(VertexN[i].y,Face[j].N.y);
                          inc(VertexN[i].z,Face[j].N.z);
                        end;
                if Face[j].P2 = i
                   then begin
                          inc(VertexN[i].x,Face[j].N.x);
                          inc(VertexN[i].y,Face[j].N.y);
                          inc(VertexN[i].z,Face[j].N.z);
                        end;
                if Face[j].P3 = i
                   then begin
                          inc(VertexN[i].x,Face[j].N.x);
                          inc(VertexN[i].y,Face[j].N.y);
                          inc(VertexN[i].z,Face[j].N.z);
                        end;
              end;}
          { normalize the VetexN[i] vector }
          {Normalize(VertexN[i],63);}
          {modulus := round(sqrt(longint(VertexN[i].X)*longint(VertexN[i].X)+
                     longint(VertexN[i].Y)*longint(VertexN[i].Y)+
                     longint(VertexN[i].Z)*longint(VertexN[i].Z)));
          if modulus<>0
             then begin
                    VertexN[i].X := longint(63*VertexN[i].X) div modulus;
                    VertexN[i].Y := longint(63*VertexN[i].Y) div modulus;
                    VertexN[i].Z := longint(63*VertexN[i].Z) div modulus;
                  end
             else begin
                    inc(Failed);
                  end;
        end;}
end;

{procedure Project(vc : integer);
var
   i       : integer;
   fpr     : single;
BEGIN
   for i:=1 to vc do
            begin
             if longint(longint(WorkObj^.Vertex[i].z)+abs(longint(ObjPos.z))+256)<>0
                then begin
                       fpr := 256/(longint(WorkObj^.Vertex[i].z)+abs(longint(ObjPos.z))+256);
                       Pro^[i].x:= round(fpr*(WorkObj^.Vertex[i].x+ObjPos.x));
                       Pro^[i].y:= round(fpr*(WorkObj^.Vertex[i].y+ObjPos.y));
                     end
            end;
END;}

function DotProduct(V1,V2 : TVector) : integer;
var
   aux : longint;
begin
  aux := (longint(V1.x)*longint(V2.x)+longint(V1.y)*longint(V2.y)+longint(V1.z)*longint(V2.z)) div 63;
  DotProduct := aux;
end;


{procedure DepthSort(Base : PTObj3D;var viewpoint,wherepoint : point3d);
 VAR i,j      : integer;
     temp     : TFace3D;
     a1,a2,a3 : longint;

procedure Kwik (first,last:integer);
var
    i,j   : integer;
    mid   : single;
begin
 i:=first;
 j:=last;
 mid:=WorkObj^.Face[(i+j) div 2].EyeDist;
 repeat
  while (WorkObj^.Face[i].EyeDist<mid) and (i<last) do inc(i);
  while (WorkObj^.Face[j].EyeDist>mid) and (j>first) do dec(j);
  if i<=j
     then begin
           temp:=WorkObj^.Face[i];
           WorkObj^.Face[i]:=WorkObj^.Face[j];
           WorkObj^.Face[j]:=temp;
           dec(j);
           inc(i);
          end;
 until i>j;
 if first<j then Kwik(first,j);
 if last>i  then Kwik(i,last);
end;

BEGIN
 for i:=1 to Base^.FC do
     with WorkObj^.Face[i] do
          begin
           a1:=-(WorkObj^.Vertex[P1].X+WorkObj^.Vertex[P2].X+WorkObj^.Vertex[P3].X) div 3-wherepoint.x+viewpoint.x;
           a2:=-(WorkObj^.Vertex[P1].Y+WorkObj^.Vertex[P2].Y+WorkObj^.Vertex[P3].Y) div 3-wherepoint.y+viewpoint.y;
           a3:=-(WorkObj^.Vertex[P1].Z+WorkObj^.Vertex[P2].Z+WorkObj^.Vertex[P3].Z) div 3-wherepoint.z+viewpoint.z;
           EyeDist:= a1*a1+a2*a2+a3*a3;
          end;
 Kwik(1,Base^.FC);
END;}

procedure InitObjFromVar(sourcefile : string;var WhatObj : PTObj3D);
var
   dseg,dofs   : word;
   dofsaux     : word;
   dx2,dy2,dz2 : integer;
   dx1,dy1,dz1 : integer;
   modulus     : longint;
   i,j         : integer;
   failed      : integer;
   f           : file;
   tmp         : Int16;
   color       : byte;
begin
  assign(f, sourcefile);
  reset(f, 1);
  { compute normals, read vertex, read faces }
  failed := 0;
  blockread(f, WhatObj^.VC, 2);
  Log.LogStatus(Format('Vertex count: %d', [WhatObj^.VC]), '3D');
  {WhatObj^.VC := memw[dseg:dofs];WhatObj^.FC := memw[dseg:dofs+2];}
  
  {if WhatObj^.Vertex = nil then}
    new(WhatObj^.Vertex);
  
  for i:=1 to WhatObj^.VC do
      begin
        blockread(f, tmp, 2);
        WhatObj^.Vertex^[i].x := tmp;
		{Log.LogStatus(Format('v.x: %d', [tmp]), '3D');}
		
        blockread(f, tmp, 2);
        WhatObj^.Vertex^[i].y := tmp;
		{Log.LogStatus(Format('v.y: %d', [tmp]), '3D');}
		
        blockread(f, tmp, 2);
        WhatObj^.Vertex^[i].z := tmp;
		{Log.LogStatus(Format('v.z: %d', [tmp]), '3D');}
		
        {
        WhatObj^.Vertex^[i].x := integer(memw[dseg:dofs+(i-1)*6+4])*ScaleFactor;
        WhatObj^.Vertex^[i].y := integer(memw[dseg:dofs+(i-1)*6+2+4])*ScaleFactor;
        WhatObj^.Vertex^[i].z := integer(memw[dseg:dofs+(i-1)*6+4+4])*ScaleFactor;
        }
      end;
  {dofsaux := dofs+WhatObj^.VC*6+4;}
  {WhatObj^.FC := memw[dseg:dofsaux];}
  blockread(f, WhatObj^.FC, 2);
  Log.LogStatus(Format('Face count: %d', [WhatObj^.FC]), '3D');
  
  {if WhatObj^.Face = nil then}
    new(WhatObj^.Face);
  
  for i:=1 to WhatObj^.FC do
      with WhatObj^.Face^[i] do
           begin
             blockread(f, tmp, 2);
			 p1 := tmp;
			 
             blockread(f, tmp, 2);
			 p2 := tmp;
			 
             blockread(f, tmp, 2);
			 p3 := tmp;			 
			 
             {p1 := memw[dseg:dofsaux+(i-1)*7];
             p2 := memw[dseg:dofsaux+(i-1)*7+2];
             p3 := memw[dseg:dofsaux+(i-1)*7+4];}
             
			 blockread(f, color, 1);			 
			 
             {WhatObj^.Face^[i].color := mem[dseg:dofsaux+(i-1)*7+6];
             dx1 := WhatObj^.Vertex^[p3].x-WhatObj^.Vertex^[p1].x;
             dx2 := WhatObj^.Vertex^[p2].x-WhatObj^.Vertex^[p1].x;
             dy1 := WhatObj^.Vertex^[p3].y-WhatObj^.Vertex^[p1].y;
             dy2 := WhatObj^.Vertex^[p2].y-WhatObj^.Vertex^[p1].y;
             dz1 := WhatObj^.Vertex^[p3].z-WhatObj^.Vertex^[p1].z;
             dz2 := WhatObj^.Vertex^[p2].z-WhatObj^.Vertex^[p1].z;}
           end;
  close(f);
end;

procedure InitSinCos;
var
   i : integer;
begin
  for i:=0 to 359 do
      begin
        sintab[i] := round(16384*sin(i*pi180));
        costab[i] := round(16384*cos(i*pi180));
      end;
end;

procedure ScaleObj(var WhatObj : PTObj3D; sx, sy, sz: integer);
var
    i: integer;
begin
    with WhatObj^ do
        for i := 1 to VC do
        begin
            Vertex^[i].x := Vertex^[i].x * sx;
            Vertex^[i].y := Vertex^[i].y * sy;
            Vertex^[i].z := Vertex^[i].z * sz;
        end;
end;

procedure PrecomputeFaceValues(var DefObj: TDefObj);
var
    i: integer;
    x1, y1, z1: longint;
begin
    with DefObj do
    begin
        with ObjData^ do
        begin
            {if FaceParams = nil then}
                new(FaceParams);

            for i := 1 to FC do
            begin 
                with FaceParams^[i] do
                begin
                    x1 := Vertex^[Face^[i].p1].x +
                        ObjPos.x;
                    y1 := Vertex^[Face^[i].p1].y +
                        ObjPos.y;
                    z1 := Vertex^[Face^[i].p1].z +
                        ObjPos.z;

                    l1 := Vertex^[Face^[i].p2].x +
                        ObjPos.x - x1;
                    m1 := Vertex^[Face^[i].p2].y +
                        ObjPos.y - y1;
                    n1 := Vertex^[Face^[i].p2].z +
                        ObjPos.z - z1;

                    l2 := Vertex^[Face^[i].p3].x +
                        ObjPos.x - x1;
                    m2 := Vertex^[Face^[i].p3].y +
                        ObjPos.y - y1;
                    n2 := Vertex^[Face^[i].p3].z +
                        ObjPos.z - z1;

                    det1 := l1 * m2 - l2 * m1;
                end 
            end;
        end;
    end;
end;

begin
    InitSinCos;
end.