CONST
     PI180 = pi/180;
     PI2   = pi*2;
VAR
   sintab,costab : array[0..359] of integer;

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