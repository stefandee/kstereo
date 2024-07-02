Program ExtractVARFromOBJ;

Uses
    Crt;

Var
    fIn, fOut : File;
    code: UInt8;
    size: UInt16;
    inFilePos, dataSize: UInt32;
    data, allData: array of UInt8;
    i: integer;
    count: UInt16;

    seg: UInt8;
    off: UInt16;

    checksum: UInt8;

procedure AppendData(inData: array of UInt8);
var
    i, prevOutSize, inDataSize: integer;
begin
    inDataSize := length(inData);

    if allData = nil then
        prevOutSize := 0
    else 
        prevOutSize := length(allData);

    writeln('prevOutSize= ', prevOutSize, ' ', inDataSize);
    setLength(allData, prevOutSize + inDataSize);
    writeln('length= ', length(allData));

    for i := 0 to inDataSize - 1 do
        allData[prevOutSize + i] := inData[i];

    writeln('length= ', length(allData));
end;    

(* 
    OBJ files have VertexCount and FaceCount at the start of file
    VAR files have VertexCount - Vertex Data - FaceCount - FaceData 
    So we need to do a bit of shifting
*)
procedure PostProcessData(var inData: array of UInt8);
Var
    VertexCount, VertexDataSize, FaceCountIndex: integer;
    tmp: array of UInt8;
begin
    VertexCount := inData[0] + 256 * inData[1];
    writeln('VertexCount: ', VertexCount);

    VertexDataSize := VertexCount * 6; { 6 bytes per vertex - x, y, z of UInt16 each }

    { save face count bytes }
    setLength(tmp, 2);
    tmp[0] := inData[2];
    tmp[1] := inData[3];

    writeln('FaceCount: ', tmp[0] + 256 * tmp[1]);

    { shift the vertex data by 2 bytes to the left } 
    for i := 0 to VertexDataSize - 1 do
        inData[i + 2] := inData[i + 2 + 2];

    { copy the face count to its correct place }
    FaceCountIndex := 2 + VertexDataSize;
    inData[FaceCountIndex] := tmp[0];
    inData[FaceCountIndex + 1] := tmp[1];
end;

begin
    if ParamCount <> 2 then
        Halt;

    { input file }
    writeln(ParamStr(1));

    Assign(fIn, ParamStr(1));
    Reset(fIn, 1);

    inFilePos := 0;

    { basic OMF 16 parser }
    while not EOF(fIn) do
    begin
        blockread(fIn, code, 1);
        writeln(code);

        case code of
            $80:
            begin
            blockread(fIn, size, 2);
            writeln('$80 - THEADR of size ', size);
            setLength(data, size);
            blockread(fIn, data[0], size);
            end;

            $96:
            begin
            blockread(fIn, size, 2);
            writeln('$96 - LNAMES of size ', size);
            setLength(data, size);
            blockread(fIn, data[0], size);
            end;

            $98:
            begin
            blockread(fIn, size, 2);
            writeln('$98 - SEGDEF of size ', size);
            setLength(data, size);
            blockread(fIn, data[0], size);
            end;

            $90:
            begin
            blockread(fIn, size, 2);
            writeln('$90 - PUBNAMES of size ', size);
            setLength(data, size);
            blockread(fIn, data[0], size);
            end;

            $A0:
            begin
            blockread(fIn, size, 2);
            writeln('$90 - LEDATA of size ', size);

            blockread(fIn, seg, 1);
            blockread(fIn, off, 2);
            writeln('segindex/off= ', seg, '/', off);

            dataSize := size - 4;
            writeln('record length= ', dataSize);

            setLength(data, dataSize);
            blockread(fIn, data[0], dataSize);
            
            {blockwrite(fOut, data[0], dataSize);}
            AppendData(data);

            blockread(fIn, checksum, 1);

            inc(inFilePos, 2 + size);
            end;
        end;
    end;

    Close(fIn);

    PostProcessData(allData);

    { output file }
    Assign(fOut, ParamStr(2));
    Rewrite(fOut, 1);
    BlockWrite(fOut, allData[0], length(allData));
    Close(fOut);
end.
