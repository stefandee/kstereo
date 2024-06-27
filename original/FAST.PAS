PROGRAM
       STEREOGRAM;
{$M 52000, 0, 655360}
{ A Z-Buffer style }

USES
    DOS, CRT, GRAPH;

{$I svga256.inc}
{$I sincos.inc}
{$I 3d.inc}

{$L Omega.obj}
{$F+}
procedure Omega;external;
{$F-}

TYPE
    PScreenFragment = ^ScreenFragment;
    ScreenFragment = array[1..100,-320..320] of byte;

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
   x1,y1,z1         : longint;
   Pal              : DacPalette256;
   Texture          : array[1..80,1..80] of byte;
   F                : file;
   c                : byte;
   Screen           : array[1..5] of PScreenFragment;

procedure ComputeZBuffer;
var
   z, i, j    : integer;
   zmin, zmax : integer;
   t1, t2, t3 : single;
   x1, x2     : single;
   y1, y2     : single;
   apart1     : boolean;
   apart2     : boolean;
   apart3     : boolean;
   found      : boolean;
   td, dist   : single;
   incr       : single;
   x, y       : single;
   xint, yint : integer;
   whatarray, whatyarray : integer;
begin
  for i:=1 to ObjInScene do
      begin
        with Obj3d[i].ObjData^ do
             for j:=1 to FC do
                 if (Vertex[Face[j].p1].z<>Vertex[Face[j].p2].z) and
                    (Vertex[Face[j].p1].z<>Vertex[Face[j].p3].z) and
                    (Vertex[Face[j].p2].z<>Vertex[Face[j].p3].z)
                    then begin
                           { find out the minimum z }
                           zmin := Vertex[Face[j].p1].z+Obj3d[i].ObjPos.z;
                           if zmin>Vertex[Face[j].p2].z+Obj3d[i].ObjPos.z then zmin := Vertex[Face[j].p2].z+Obj3d[i].ObjPos.z;
                           if zmin>Vertex[Face[j].p3].z+Obj3d[i].ObjPos.z then zmin := Vertex[Face[j].p3].z+Obj3d[i].ObjPos.z;
                           if zmin<0 then zmin := 0;
                           { find out the maximum z }
                           zmax := Vertex[Face[j].p1].z+Obj3d[i].ObjPos.z;
                           if zmax<Vertex[Face[j].p2].z+Obj3d[i].ObjPos.z then zmax := Vertex[Face[j].p2].z+Obj3d[i].ObjPos.z;
                           if zmax<Vertex[Face[j].p3].z+Obj3d[i].ObjPos.z then zmax := Vertex[Face[j].p3].z+Obj3d[i].ObjPos.z;
                           if zmax>255 then zmax := 255;
                           { here starts the REAL fun - z scan and updating the ScreenFragments }
                           for z:= zmin to zmax do
                               begin
                                 { ecuatiile parametrice ale dreptelor }
                                 { se afla parametrul t pentru care dreapta intersecteaza planul z = z0 }
                                 found := false;

                                 t1 := (z-(Vertex[Face[j].p1].z+Obj3d[i].ObjPos.z))/
                                       (Vertex[Face[j].p2].z-Vertex[Face[j].p1].z);
                                 t2 := (z-(Vertex[Face[j].p1].z+Obj3d[i].ObjPos.z))/
                                       (Vertex[Face[j].p3].z-Vertex[Face[j].p1].z);
                                 t3 := (z-(Vertex[Face[j].p2].z+Obj3d[i].ObjPos.z))/
                                       (Vertex[Face[j].p3].z-Vertex[Face[j].p2].z);

                                 apart1 := (t1>=0) and (t1<=1);
                                 apart2 := (t2>=0) and (t2<=1);
                                 apart3 := (t3>=0) and (t3<=1);

                                 if apart1
                                    then begin
                                           x1 := Vertex[Face[j].p1].x+Obj3d[i].ObjPos.x+
                                                 t1*(Vertex[Face[j].p2].x-Vertex[Face[j].p1].x);
                                           y1 := Vertex[Face[j].p1].y+Obj3d[i].ObjPos.y+
                                                 t1*(Vertex[Face[j].p2].y-Vertex[Face[j].p1].y);
                                           found := true;
                                           if apart2
                                              then begin
                                                     x2 := Vertex[Face[j].p1].x+Obj3d[i].ObjPos.x+
                                                           t2*(Vertex[Face[j].p3].x-Vertex[Face[j].p1].x);
                                                     y2 := Vertex[Face[j].p1].y+Obj3d[i].ObjPos.y+
                                                           t2*(Vertex[Face[j].p3].y-Vertex[Face[j].p1].y);
                                                   end
                                              else if apart3
                                                      then begin
                                                             x2 := Vertex[Face[j].p2].x+Obj3d[i].ObjPos.x+
                                                                   t3*(Vertex[Face[j].p3].x-Vertex[Face[j].p2].x);
                                                             y2 := Vertex[Face[j].p2].y+Obj3d[i].ObjPos.y+
                                                                   t3*(Vertex[Face[j].p3].y-Vertex[Face[j].p2].y);
                                                           end;
                                         end
                                    else if apart2
                                              then begin
                                                     found := true;
                                                     x1 := Vertex[Face[j].p1].x+Obj3d[i].ObjPos.x+
                                                           t2*(Vertex[Face[j].p3].x-Vertex[Face[j].p1].x);
                                                     y1 := Vertex[Face[j].p1].y+Obj3d[i].ObjPos.y+
                                                           t2*(Vertex[Face[j].p3].y-Vertex[Face[j].p1].y);
                                                     x2 := Vertex[Face[j].p2].x+Obj3d[i].ObjPos.x+
                                                           t3*(Vertex[Face[j].p3].x-Vertex[Face[j].p2].x);
                                                     y2 := Vertex[Face[j].p2].y+Obj3d[i].ObjPos.y+
                                                           t3*(Vertex[Face[j].p3].y-Vertex[Face[j].p2].y);
                                                   end;
                                 if found
                                    then begin
                                           { now we have the line of intersection }
                                           { we'll scan it and stock the z in Screen, coresponding to x and y }
                                           { no Bresenham - if I'll care, I'll optimize :-)) }
                                           if (x1<>x2) or (y1<>y2)
                                              then begin
                                                     { trace thy line }
                                                     dist := sqrt(((x2-x1)*(x2-x1)+(y2-y1)*(y2-y1)));
                                                     incr := 1/dist;
                                                     td   := 0;
                                                     {x := x1+Obj3d[i].ObjPos.x;y:=y1+Obj3d[i].ObjPos.y;}
                                                     x := x1+Obj3d[i].ObjPos.x;
                                                     y := y1+Obj3d[i].ObjPos.y;

                                                     repeat
                                                       if (x>=-320) and (x<=320) and (y>=-240) and (y<=240)
                                                          then begin
                                                                 yint := round(y)+241;
                                                                 whatarray := yint div 100+1;
                                                                 whatyarray := yint mod 100+1;
                                                                 xint := round(x);
                                                                 if z<=Screen[whatarray]^[whatyarray,xint]
                                                                    then Screen[whatarray]^[whatyarray,xint] := z;
                                                               end;

                                                       td := td + incr;
                                                       x := x1+Obj3d[i].ObjPos.x+(x2-x1)*td;
                                                       y := y1+Obj3d[i].ObjPos.y+(y2-y1)*td;
                                                     until (td>=1)
                                                   end;
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
        {TrackASceneLine(y);}
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

procedure Preview;
var
   x,y : longint;
   i   : integer;
begin
  for i:= 0 to 255 do
      begin
        Pal[i,0] := 0;
        Pal[i,1] := i div 4;
        Pal[i,2] := 0;
      end;
  SetVgaPalette256(Pal);
  ComputeZBuffer;

  for y:=1 to 100 do
      for x := -maxex to maxex-1 do
          if Screen[1]^[y,x]<>zmax then putpixel(x+maxex,y,255-Screen[1]^[y,x])
             else putpixel(x+maxex,y,0);

  for y:=1 to 100 do
      for x := -maxex to maxex-1 do
          if Screen[2]^[y,x]<>zmax then putpixel(x+maxex,y+100,255-Screen[2]^[y,x])
             else putpixel(x+maxex,y+100,0);

  for y:=1 to 100 do
      for x := -maxex to maxex-1 do
          if Screen[3]^[y,x]<>zmax then putpixel(x+maxex,y+200,255-Screen[3]^[y,x])
             else putpixel(x+maxex,y+200,0);

  for y:=1 to 100 do
      for x := -maxex to maxex-1 do
          if Screen[4]^[y,x]<>zmax then putpixel(x+maxex,y+300,255-Screen[4]^[y,x])
             else putpixel(x+maxex,y+300,0);

  for y:=0 to 80 do
      for x := -maxex to maxex-1 do
          if Screen[5]^[y,x]<>zmax then putpixel(x+maxex,y+400,255-Screen[5]^[y,x])
             else putpixel(x+maxex,y+400,0);
end;

BEGIN
  { start init screens }
  for i:= 1 to 5 do
      begin
        new(Screen[i]);
        fillchar(Screen[i]^, sizeof(Screen[i]^), zmax);
      end;
  { end init screens }

  { start init objects }
  InitSinCos;
  ObjInScene := 1;ScaleFactor := 1;new(WorkObj);
  EyePos := Center;
  new(Obj3d[1].ObjData);
  InitObj(Addr(Omega),Obj3d[1].ObjData);
  with Obj3d[1] do
       begin
         ObjPos.x := 0;ObjPos.y := 0;ObjPos.z := 190;
         Ang.X := 20; Ang.Y := 190; Ang.Z := 180;

         WorkObj^ := ObjData^;
         RotateObj(Ang.X, Ang.Y, Ang.Z, ObjData^.VC, ObjData^.FC);
         ObjData^ := WorkObj^;
       end;
  { end init objects }

  { start init video mode }
  GD := InstallUserDriver('SVGA256',NIL);
  GM := SVGA640x480x256;
  InitGraph(GD,GM,'');
  {assign(F,'GFX/complexa.pal');reset(f,1);blockread(f,Pal,768);SetVGAPalette256(Pal);close(F);
  assign(F,'GFX/complexa.raw');reset(f,1);blockread(f,Texture,6400);close(F);
  { end init video mode }
  {MyStereo;}
  Preview;
  {assign(f,'GATA/omega.dat');
  rewrite(f,1);
  for j:=0 to 479 do
      for i:=0 to 639 do
          begin
            c := getpixel(i,j);
            blockwrite(f,c,1);
          end;
  close(f);}
  readln;
  CloseGraph;
END.

