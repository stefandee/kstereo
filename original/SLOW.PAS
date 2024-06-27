PROGRAM
       STEREOGRAM;

{$M 65520, 0, 655360}

USES
    DOS, CRT, GRAPH;

{$I svga256.inc}
{$I sincos.inc}
{$I 3d.inc}

{$L tfdv.obj}
{$F+}
procedure tfdv;external;
{$F-}

TYPE
    tvectors = record
           l1,m1,n1 : longint;
           l2,m2,n2 : longint;
           det1     : longint;
          end;
    atvectors = array[1..2000] of tvectors;
CONST
     MaxImx   = 480;
     ZMax     = 255;
     MaxColor = 255;
     MaxEx : integer = 320;
     MaxEy : integer = 240;
     Dif   : integer = 42;
     NpCol : integer = 80;

VAR
   Ecul,Shape       : array[-maximx..maximx] of integer;
   Mcul             : array[0..maximx] of byte;
   Xst,Xdr,XModel,A : integer;
   ObjInScene       : integer;
   gd,gm            : integer;
   max,i,j          : integer;
   vectors          : ^atvectors;
   x1,y1,z1         : longint;
   Pal              : DacPalette256;
   Texture          : array[1..80,1..80] of byte;
   F                : file;
   c                : byte;

procedure ShapeGenerare(y : longint);
const
     r = 235.0;
var
   x : longint;
   u : real;
begin
  for x := -maxex to maxex-1 do
      begin
        u := sqr(r)-sqr(x)-sqr(y);
        if u<=0 then shape[x] := round(r)
           else shape[x] := round(r-sqrt(u));
      end;
end;

procedure StereoGenerare;
var
   x,y,k : integer;
   c     : byte;
   startx,colory,checkerx,checkery : byte;
begin
  checkery := 0;colory := 0;checkerx := 0;
  randomize;
  fillchar(MCul,sizeof(MCul),0);
  a := zmax div dif;
  for y := maxey downto -maxey+1 do
      begin
        {inc(checkery);
        if checkery>10
           then begin
                  checkery := 0;
                  startx := (startx+1) mod 2;
                end;
        fillchar(MCul,sizeof(MCul),0);
        checkerx := 0;
        for k := 1 to npcol do
            begin
              inc(checkerx);
              if checkerx>10
                 then begin
                        checkerx := 0;
                        colory := (colory+1) mod 2;
                      end;
              MCul[k+startx*10] := colory*15;
            end;}
        for k := 1 to npcol do MCul[k] := random(maxcolor);
        shapegenerare(y);
        fillchar(ECul,sizeof(ECul),0); xmodel := 0;
        for xst := -maxex-npcol div 2 to maxex-1 do
            begin
              xmodel := xmodel mod npcol + 1;
              xdr := xst+npcol-dif+shape[xst+npcol div 2] div a;
              if ecul[xst] = 0 then ecul[xst] := xmodel;
              ecul[xdr] := ecul[xst];
            end;
        for x := -maxex to maxex-1 do
            putpixel(x+maxex,maxey-y,mcul[ecul[x]]);
      end;
end;

procedure TrackASceneLine(yc : longint);
var
   xc   : longint;
   i,j : integer;
   zclose : single;
   det2,det3 : longint;
   alfa,beta : single; { coordonate relative la triunghi }
begin
  { optimizations }
  for xc := -maxex to maxex-1 do
      begin
        shape[xc] := zmax;
        for i := 1 to ObjInScene do
                   for j := 1 to Obj3D[i].ObjData^.FC do
                       begin
                         { track the proxima Z coordinate }
                         det2 :=
                              (xc-Obj3D[i].ObjData^.Vertex[Obj3D[i].ObjData^.Face[j].p1].x-Obj3D[i].ObjPos.x)*vectors^[j].m2-
                              (yc-Obj3D[i].ObjData^.Vertex[Obj3D[i].ObjData^.Face[j].p1].y-Obj3D[i].ObjPos.y)*vectors^[j].l2;

                         det3 :=
                              (xc-Obj3D[i].ObjData^.Vertex[Obj3D[i].ObjData^.Face[j].p1].x-Obj3D[i].ObjPos.x)*vectors^[j].m1-
                              (yc-Obj3D[i].ObjData^.Vertex[Obj3D[i].ObjData^.Face[j].p1].y-Obj3D[i].ObjPos.y)*vectors^[j].l1;

                         if (vectors^[j].det1 <> 0) {and (vectors[j].n1*det2-vectors[j].n2*det3 <> 0)}
                            then begin
                                   alfa := det2/vectors^[j].det1;
                                   beta := -det3/vectors^[j].det1;
                                   { verifica daca (x,y,zclose) e in interiorul triunghiului }
                                   if ((alfa>0) and (alfa<1{vectors[j].mod1}) and (beta>0) and (beta<1{vectors[j].mod2}) and
                                       (alfa+beta<=1))
                                      then begin
                                             zclose := Obj3D[i].ObjData^.Vertex[Obj3D[i].ObjData^.Face[j].p1].z+
                                                       Obj3D[i].ObjPos.z+vectors^[j].n1*alfa+vectors^[j].n2*beta;
                                             if shape[xc]>zclose then shape[xc] := round(zclose);
                                          end;
                                 end;
                       end;
      end;
end;

procedure MyStereo;
var
   x,y,k : integer;
   c     : byte;
begin
  randomize;
  fillchar(MCul,sizeof(MCul),0);
  a := zmax div dif;
  for y := maxey downto -maxey+1 do
      begin
        for k := 1 to npcol do MCul[k] := Texture[(y+320) mod 80+1][k];
        TrackASceneLine(y);
        fillchar(ECul,sizeof(ECul),0); xmodel := 0;
        for xst := -maxex-npcol div 2 to maxex-1 do
            begin
              xmodel := xmodel mod npcol + 1;
              xdr := xst+npcol-dif+shape[xst+npcol div 2] div a;
              if ecul[xst] = 0 then ecul[xst] := xmodel;
              ecul[xdr] := ecul[xst];
            end;
        for x := -maxex to maxex-1 do
            putpixel(x+maxex,maxey-y,mcul[ecul[x]]);
      end;
end;

procedure Paralel;
var
   x,y : longint;
begin
  for y:=maxey div 2 downto -maxey div 2 do
      begin
        TrackASceneLine(2*y);
        for x := -maxex to maxex-1 do
            if shape[x]<>zmax then putpixel(x+maxex,maxey-2*y,shape[x])
               else putpixel(x+maxex,maxey-2*y,4);
      end;
end;

BEGIN
  { start init objects }
  InitSinCos;
  ObjInScene := 1;ScaleFactor := 1;new(WorkObj);
  EyePos := Center;
  new(Obj3d[1].ObjData);
  InitObj(Addr(tfdv),Obj3d[1].ObjData);
  with Obj3d[1] do
       begin
         ObjPos.x := 0;ObjPos.y := 0;ObjPos.z := 190;
         {Ang.X := 0; Ang.Y := 200; Ang.Z := 240;}
         Ang.X := 240; Ang.Y := 130; Ang.Z := 40;

         WorkObj^ := ObjData^;
         RotateObj(Ang.X, Ang.Y, Ang.Z, ObjData^.VC, ObjData^.FC);
         ObjData^ := WorkObj^;
         {DepthSort(ObjData,EyePos,ObjPos);}

         new(vectors);
         for i:=1 to Obj3d[1].ObjData^.FC do
             with vectors^[i] do
                  begin
                    x1 := Obj3d[1].ObjData^.Vertex[Obj3d[1].ObjData^.Face[i].p1].x+Obj3d[1].ObjPos.x;
                    y1 := Obj3d[1].ObjData^.Vertex[Obj3d[1].ObjData^.Face[i].p1].y+Obj3d[1].ObjPos.y;
                    z1 := Obj3d[1].ObjData^.Vertex[Obj3d[1].ObjData^.Face[i].p1].z+Obj3d[1].ObjPos.z;

                    l1 := Obj3d[1].ObjData^.Vertex[Obj3d[1].ObjData^.Face[i].p2].x+Obj3d[1].ObjPos.x-x1;
                    m1 := Obj3d[1].ObjData^.Vertex[Obj3d[1].ObjData^.Face[i].p2].y+Obj3d[1].ObjPos.y-y1;
                    n1 := Obj3d[1].ObjData^.Vertex[Obj3d[1].ObjData^.Face[i].p2].z+Obj3d[1].ObjPos.z-z1;

                    l2 := Obj3d[1].ObjData^.Vertex[Obj3d[1].ObjData^.Face[i].p3].x+Obj3d[1].ObjPos.x-x1;
                    m2 := Obj3d[1].ObjData^.Vertex[Obj3d[1].ObjData^.Face[i].p3].y+Obj3d[1].ObjPos.y-y1;
                    n2 := Obj3d[1].ObjData^.Vertex[Obj3d[1].ObjData^.Face[i].p3].z+Obj3d[1].ObjPos.z-z1;

                    det1 := l1*m2-l2*m1;
                  end;
       end;
  { end init objects }

  { start init video mode }
  GD := InstallUserDriver('SVGA256',NIL);
  GM := SVGA640x480x256;
  InitGraph(GD,GM,'');
  assign(F,'GFX/turbl.pal');reset(f,1);blockread(f,Pal,768);SetVGAPalette256(Pal);close(F);
  assign(F,'GFX/turbl.raw');reset(f,1);blockread(f,Texture,6400);close(F);
  { end init video mode }
  {StereoGenerare;}
  MyStereo;
  {Paralel;}
  assign(f,'GATA/tfdv.dat');
  rewrite(f,1);
  for j:=0 to 479 do
      for i:=0 to 639 do
          begin
            c := getpixel(i,j);
            blockwrite(f,c,1);
          end;
  close(f);
  readln;
  CloseGraph;
END.

