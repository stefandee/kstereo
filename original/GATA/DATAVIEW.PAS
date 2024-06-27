PROGRAM
       DATAVIEWER;

USES
    DOS,CRT,GRAPH;
{$I svga256.inc}

VAR
   f     : FILE;
   GD,GM : integer;
   Pal   : DacPalette256;
   i,j   : integer;
   c     : byte;
BEGIN
  { start init video mode }
  GD := InstallUserDriver('SVGA256',NIL);
  GM := SVGA640x480x256;
  InitGraph(GD,GM,'');
  assign(F,'../GFX/greeny.pal');reset(f,1);blockread(f,Pal,768);SetVGAPalette256(Pal);close(F);
  assign(f,'karg.dat');
  reset(f,1);
  for j:=0 to 479 do
      for i:=0 to 639 do
          begin
            blockread(f,c,1);
            putpixel(i,j,c);
          end;
  close(f);
  readln;
  CloseGraph;

END.