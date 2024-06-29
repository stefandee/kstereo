unit Graphics;

interface

uses
    SDL2_ttf,
    SDL2,
    Logger,
    SysUtils,
    SDLWrapper,
    Math;

const
    COLOR_WHITE = $FFFFFFFF;
    COLOR_BLACK = $FF000000;

	HCENTER = $01;
	VCENTER = $02;
	RIGHT   = $04;
	BOTTOM  = $08;

var
    FontMenu: PTTF_Font;

procedure OutTextXY(x, y : Integer; str : string; font: PTTF_Font; color: LongWord; align : integer; renderer: PSDL_Renderer = nil);
procedure Bar(xb,yb,xf,yf:integer;color:LongWord; renderer: PSDL_Renderer = nil);

implementation

function GetA(color: LongWord): UInt8;
begin
	GetA := (color and $FF000000) shr 24;
end;

function GetR(color: LongWord): UInt8;
begin
	GetR := (color and $FF0000) shr 16;
end;

function GetG(color: LongWord): UInt8;
begin
	GetG := (color and $00FF00) shr 8;
end;

function GetB(color: LongWord): UInt8;
begin
	GetB := (color and $FF);
end;

procedure Bar(xb,yb,xf,yf:integer;color:LongWord; renderer: PSDL_Renderer = nil);
var
	rect: TSDL_RECT;
begin
	rect.x := Min(xb, xf);
	rect.y := Max(yb, yf);
	rect.w := Abs(xb - xf) + 1;
	rect.h := Abs(yb - yf) + 1;

	if renderer = nil then renderer := SDLRenderer;
	
	SDL_SetRenderDrawColor(renderer, GetR(color), GetG(color), GetB(color), GetA(color));
	SDL_RenderFillRect(renderer, @rect);	
end;

procedure OutTextXY(x, y : Integer; str : string; font: PTTF_Font; color: LongWord; align : integer; renderer: PSDL_Renderer = nil);
var
	DestRect : TSDL_Rect;
	strW, strH : LongWord;
	sdlSurface: PSDL_Surface;
	sdlTexture: PSDL_Texture;
	fontColor: TSDL_Color;
begin
	if (font = nil) then exit;

	if renderer = nil then renderer := SDLRenderer;

	if align > 0 then 
	begin
		TTF_SizeText(font, PChar(str), @strW, @strH);

		if (align and HCENTER <> 0) then x := x - strW div 2;

		if (align and VCENTER <> 0) then y := y - strH div 2;

		if (align and RIGHT <> 0) then x := x - strW;

		if (align and BOTTOM <> 0) then y := y - strH;
	end;

	fontColor.r := GetR(color);
	fontColor.g := GetG(color);
	fontColor.b := GetB(color);
	fontColor.a := GetA(color);

	{ get the surface }
	{ this is not very efficient, as it creates a surface and a texture each time it renders text }
	{ for static text labels, consider pre-render them, only dynamic text should use this method }
	{ alternatively, cache all glyphs, but probably we will lose ttf rendering capabilities }
	{sdlSurface := TTF_RenderText_Blended(font, PChar(str), fontColor);}
	sdlSurface := TTF_RenderText_Solid(font, PChar(str), fontColor);

	if (sdlSurface = nil) then 
	begin
		Log.LogError('Cannot create font surface', 'Graphics');
		exit;
	end;

	sdlTexture := SDL_CreateTextureFromSurface(renderer, sdlSurface);
	SDL_SetTextureAlphaMod(sdlTexture, 255);

	DestRect.x := x;
	DestRect.y := y;
	DestRect.w := sdlSurface^.w;
	DestRect.h := sdlSurface^.h;

	SDL_RenderCopy(renderer, sdlTexture, nil, @DestRect);
	
	SDL_FreeSurface(sdlSurface);
	SDL_DestroyTexture(sdlTexture);		
end;

begin
end.