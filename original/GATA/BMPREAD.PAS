program BMPReader;

uses crt,graph,dos;

const BI_RGB=0;
      BI_RLE8=8;
      BI_RLE4=4;
      VGAs=$a000;
      pal:array[1..16,1..4] of integer=(
                                         {black}      (0,0,0,0),
                                         {blue}       (1,0,0,31),
                                         {green}      (2,0,31,0),
                                         {cyan}       (3,0,31,31),
                                         {red}        (4,31,0,0),
                                         {magenta}    (5,31,0,31),
                                         {brown}      (6,31,15,0),
                                         {lightgray}  (7,31,31,31),
                                         {darkgray}   (56,15,15,15),
                                         {lightblue}  (57,0,0,63),
                                         {lightgreen} (58,0,63,0),
                                         {lightcyan}  (59,0,63,63),
                                         {lightred}   (60,63,0,0),
                                         {lightmagenta}(61,63,0,63),
                                         {yellow}      (62,63,63,0),
		                         {white}       (63,63,63,63));


type FILEHEADER = record
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

var h:FILEHEADER;
    i:INFOHEADER;
    fis:file;
    p:pointer;
    filename:string;
    ts:searchrec;

procedure Vga256;
begin
asm

   mov ax,$0013
   int $10

end
end;

Procedure DoneVga256;  { This procedure returns you to text mode.  }
begin
  asm
     mov        ax,0003h
     int        10h
  end;
end;

procedure Putpixel256(x,y:integer;color:byte);
begin
Mem [VGAs:X+(Y*320)]:=color;
end;

Procedure Cls;assembler;
  asm
  mov ax,vgas
  mov es,ax
  mov al,0
  mov ah,al
  mov si,0
  mov cx,32000
  rep stosw
  end;


procedure BITMAP256(x,y:integer);
var k,j:longint;
    b:byte;
    q:array[0..255] of RGBQUAD;

begin
vga256;
cls;
blockread(fis,q,sizeof(q));
for k:=0 to 255 do
    begin
    port[$3c8]:=k;
    port[$3c9]:=q[k].red shr 2;
    port[$3c9]:=q[k].green shr 2;
    port[$3c9]:=q[k].blue shr 2;
    end;
seek(fis,h.ofsdata);
blockread(fis,p^,i.height*i.width);
for k:=1 to i.height-1 do
    for j:=1 to i.width-1 do
        begin
        putpixel256(j+x,k+y,mem[seg(p^):ofs(p^)+k*i.width+j]);
        end;
readln;
donevga256;

end;

procedure BITMAP16(x,y:integer);

type RGBtrip = record
             blue,green,red:byte;
             end;
var xc,yc,pc:longint;
    k:byte;
    gd,gm:integer;
    s,o:word;
    q:array[0..15] of RGBquad;
begin
gd:=vga;
gm:=vgahi;
initgraph(gd,gm,'c:\bp\bgi');

blockread(fis,q,sizeof(q));

for k:=0 to 15 do
    begin
    port[$3c8]:=pal[k+1,1];
    port[$3c9]:=q[k].red shr 2;
    port[$3c9]:=q[k].green shr 2;
    port[$3c9]:=q[k].blue shr 2;
    end;

seek(fis,h.ofsdata);
blockread(fis,p^,i.height*i.width div 2);
pc:=0;
s:=seg(p^);
o:=ofs(p^);
for yc:=1 to i.height do
    begin
    xc:=0;
    repeat
        putpixel(xc+x,yc+y,mem[s:o+pc] shr 4);inc(xc);
        putpixel(xc+x,yc+y,mem[s:o+pc] and 15);inc(xc);
        inc(pc);
    until xc>=i.width-1;
    end;




readln;
closegraph;
end;

begin
clrscr;
if paramcount>0 then filename:=paramstr(1)
                else begin
                     writeln('BMP graphic files reader,by Karg of W.O.S.');
                     writeln('Parameter missing.');
                     halt;
                     end;
if filename[length(filename)-4]<>'.' then filename:=filename+'.bmp';
findfirst(filename,$3f,ts);
if doserror<>0 then begin
                    writeln('BMP graphic files reader,by Karg of W.O.S.');
                    writeln('An error has occured during execution.Exiting...');
                    halt;
                    end;

assign(fis,filename);
reset(fis,1);
blockread(fis,h,sizeof(h));
with h do
     begin
     writeln('BMP IDentifier : ',h.id);
     writeln('File size      : ',h.size);
     writeln('Reserved  I    : ',h.resv1);
     writeln('Reserved  II   : ',h.resv2);
     writeln('Offset for data: ',h.ofsdata);
     end;

blockread(fis,i,sizeof(i));
with i do
     begin
     writeln('info size        : ',infosize);
     writeln('width            : ',width);
     writeln('height           : ',height);
     writeln('planes           : ',planes);
     case compress of
     BI_RGB:writeln('compression type : none');
     end;
     writeln('bit count : ',bitcount);
     if compress=BI_RGB then writeln('size of image   : ',sizeimage);
     writeln('pixel per meter (X) : ',xpixmeter);
     writeln('pixel per meter (y) : ',ypixmeter);
     if clrused<>0 then writeln('colors used      : ',clrused)
                   else writeln('colors used      : 2^',bitcount);

     if clrimportant<>0 then writeln('important colors : ',clrimportant)
                        else writeln('important colors : all');
     end;
readln;
getmem(p,65535);
case i.bitcount of
8 : BITMAP256(100,100);
4 : BITMAP16(0,0);
end;

freemem(p,65535);
writeln('BMP graphic files reader,by Karg of W.O.S.');

end.