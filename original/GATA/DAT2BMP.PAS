PROGRAM
       DAT_TO_BMP;

USES
    DOS, CRT;

CONST
     BI_RGB=0;
     BI_RLE8=8;
     BI_RLE4=4;

TYPE
    FILEHEADER = record
                 id:packed array[1..2] of char;
                 size:longint;
                 resv1,resv2:word;
                 ofsdata:longint;
               end;
    INFOHEADER = record
                 infosize:longint;
                 width,height:longint;
                 planes:word;
                 bitcount:word;
                 compress:longint;
                 sizeimage:longint;
                 xpixmeter,ypixmeter:longint;
                 clrused,clrimportant:longint;
              end;
     RGBQUAD = record
               blue:byte;
               green:byte;
               red:byte;
               resv:byte;
             end;

VAR
    head : FILEHEADER;
    info : INFOHEADER;
    rgb : RGBQUAD;
    infile, palfile : string;
    fs, fd, fp : file;
    i : longint;
    data : byte;
    dataline : array[1..640] of byte;

BEGIN
  infile := 'karg';
  palfile := 'greeny';
  with head do
       begin
         id[1] := 'B';id[2] := 'M';
         size := 307200+1024+40+14;
         resv1 := 0;resv2 := 0;
         ofsdata := 1078;
       end;
  with info do
       begin
         infosize := 40;
         width := 640;height := 480;
         planes := 1;
         bitcount := 8;
         compress := BI_RGB;
         sizeimage := 307200;
         xpixmeter := 0;
         ypixmeter := 0;
         clrused := 256;
         clrimportant := 256;
       end;
  assign(fs, infile+'.dat');reset(fs, 1);
  assign(fd, '../FINAL/'+infile+'.bmp');rewrite(fd, 1);
  assign(fp, '../GFX/'+palfile+'.pal');reset(fp, 1);
  blockwrite(fd, head, sizeof(head));
  blockwrite(fd, info, sizeof(info));
  for i:=0 to 255 do
      begin
        blockread(fp, rgb.red, 1);
        blockread(fp, rgb.green, 1);
        blockread(fp, rgb.blue, 1);
        rgb.resv := 0;
        rgb.red := rgb.red*4;
        rgb.green := rgb.green*4;
        rgb.blue := rgb.blue*4;
        blockwrite(fd, rgb, sizeof(rgb));
      end;
  for i:=480 downto 1 do
      begin
        seek(fs, (i-1)*640);
        blockread(fs, dataline, 640);
        blockwrite(fd, dataline, 640);
      end;
  close(fp);
  close(fd);
  close(fs);
END.
