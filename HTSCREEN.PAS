UNIT HtScreen;
{$N+}
INTERFACE

USES Dos;

CONST

  { Common foreground attributes }
  Black       = $00;      DarkGray       = $08;
  Blue        = $01;      LightBlue      = $09;
  Green       = $02;      LightGreen     = $0A;
  Cyan        = $03;      LightCyan      = $0B;
  Red         = $04;      LightRed       = $0C;
  Magenta     = $05;      LightMagenta   = $0D;
  Brown       = $06;      Yellow         = $0E;
  LightGray   = $07;      White          = $0F;
  Blink       = $80;      SameAttr       = -1;

  { Common background attributes }
  BlackBG     = $00;
  BlueBG      = $10;
  GreenBG     = $20;
  CyanBG      = $30;
  RedBG       = $40;
  MagentaBG   = $50;
  BrownBG     = $60;
  LightGrayBG = $70;

  { Different border types }
  NoBorder     = 0;
  SingleBorder = 1;
  DoubleBorder = 2;
  DTopSSide    = 3;
  STopDSide    = 4;
  DTopSSideHang= 5;

  { Text fonts, 25 or 43/50 rows }
  EGA43Font   = 1;
  NormalFont  = 2;

VAR CRTRows,                 { Number of rows }
    CRTCols,                 { Number of columns }
    VideoMode : BYTE;        { Video-mode }
    Fk        : BOOLEAN;     { Function key pressed }

{ Cursor sizes, initialized by HtInit }
    CursorInitial,
    CursorOff,
    CursorUnderline,
    CursorHalfBlock,
    CursorBlock : WORD;


FUNCTION HtReadKey(VAR Fk:BOOLEAN) : CHAR;
PROCEDURE HtDelay(MS : REAL);
PROCEDURE GoToRC(Row,Col : BYTE);
FUNCTION EosCol : BYTE;
FUNCTION EosRow : BYTE;
PROCEDURE EosToRC(Row,Col : BYTE);
PROCEDURE GoToEos;
PROCEDURE GetCursor(VAR Cursor : WORD);
PROCEDURE SetCursor(Cursor : WORD);
FUNCTION HtReadAttr(Row,Col : BYTE) : BYTE;
FUNCTION HtReadChar(Row,Col : BYTE) : CHAR;
PROCEDURE HtWrite(Row,Col:BYTE; Attr:INTEGER; S : STRING);
PROCEDURE HtWriteEos(Attr : INTEGER; S : STRING);
PROCEDURE HtWriteC(Row,Col:BYTE; Attr:INTEGER; S : STRING);
PROCEDURE HtAttr(Row,Col,Rows,Cols,Attr : BYTE);
PROCEDURE HtFill(Row,Col,Rows,Cols,Attr : BYTE; C : CHAR);
PROCEDURE HtScrollUp(Row,Col,Rows,Cols,BlankAttr:BYTE);
PROCEDURE HtScrollDown(Row,Col,Rows,Cols,BlankAttr:BYTE);
PROCEDURE HtStoreToMem(Row,Col,Rows,Cols : BYTE; VAR Dest );
PROCEDURE HtStoreToScr(Row,Col,Rows,Cols : BYTE; VAR Source );
PROCEDURE HtClrScr;
FUNCTION ShadowAttr(Attr : BYTE) : BYTE;
PROCEDURE AddShadow(Row,Col,Rows,Cols : BYTE);
PROCEDURE Box(Row,Col,Rows,Cols,Attr,Border:BYTE;  Fill:CHAR);
PROCEDURE Explode(Row,Col,Rows,Cols,Attr,Border:BYTE);
PROCEDURE GetFont(VAR CRTRows : BYTE);
PROCEDURE SetFont(Font : BYTE);
FUNCTION GetVideoMode : BYTE;
PROCEDURE SetVideoMode(Mode : BYTE);
PROCEDURE HtInit;


IMPLEMENTATION

CONST
  EmptyBorder  = '      ';
  SBorder      = '⁄ƒø≥Ÿ¿';
  DBorder      = '…Õª∫º»';
  DSBorder     = '’Õ∏≥æ‘';
  SDBorder     = '÷ƒ∑∫Ω”';
  DSBorderHang = '∏Õ’≥æ‘';

  { Error message }
  ErrorStr    : String[20] = ('Wrong video mode');

VAR EosOfs    : WORD;        { Offset of EndOfString marker }
    Regs      : REGISTERS;   { Register variable }
    VideoSeg  : WORD;        { Video segment address }


PROCEDURE HtError(Num : BYTE);
{ Writes out the error message }
BEGIN
  WriteLn(ErrorStr[Num]);
  Halt;
END;


FUNCTION HtReadKey(VAR Fk:BOOLEAN) : CHAR;
{ Almost similar to TP ReadKey, except it checks if the key pressed is a }
{ function key, and in that case sets Fk = TRUE                          }
BEGIN
  Fk := FALSE;
  FillChar(Regs,SizeOf(Regs),0);
  Regs.AH := $00;
  Intr($16,Regs);
  IF Regs.AL <> 0 THEN
  HtReadKey := Chr(Regs.AL)
  ELSE BEGIN
    HtReadKey := Chr(Regs.AH);
    Fk := TRUE;
  END;
END;


PROCEDURE HtDelay(MS : REAL);
{ Similar to TP Delay }
VAR D1,D2,M : LONGINT;
BEGIN
  M := Round(MS*1000);
  D1 := M DIV 65536;
  D2 := M MOD 65536;
  FillChar(Regs,SizeOf(Regs),0);
  Regs.AH := $86;
  Regs.CX := D1;
  Regs.DX := D2;
  Intr($15,Regs);
END;


PROCEDURE GoToRC(Row,Col : BYTE);
{ Moves the cursor to row R and column C }
BEGIN
  FillChar(Regs,SizeOf(Regs),0);
  Regs.AH := $02;
  Regs.DH := Row-1;
  Regs.DL := Col-1;
  Intr($10,Regs);
END;


FUNCTION EosCol : BYTE;
{ Returns the column number for the End-Of-String marker }
BEGIN
  EosCol := (EosOfs MOD 80);
END;


FUNCTION EosRow : BYTE;
{ Returns the row number for the End-Of-String marker }
BEGIN
  EosRow := (EosOfs DIV 80);
END;


PROCEDURE EosToRC(Row,Col : BYTE);
{ Moves the End-Of-String marker to the current cursor position }
BEGIN
  EosOfs := (Row-1)*80 + (Col-1);
END;


PROCEDURE GoToEos;
{ Moves the cursor to the position of the End-Of-String marker }
BEGIN
  GoToRC(EosRow+1,EosCol+1);
END;


PROCEDURE GetCursor(VAR Cursor : WORD);
{ Returns the cursor size }
VAR S,E : BYTE;
BEGIN
  E := Mem[$0040:$0060];
  S := Mem[$0040:$0061];
  Cursor := (E SHL 4) + S;
END;


PROCEDURE SetCursor(Cursor : WORD);
{ Sets the cursor size }
BEGIN
  FillChar(Regs,SizeOf(Regs),0);
  Regs.AH := $01;
  Regs.CH := Cursor MOD 16;       { Start }
  Regs.CL := Cursor DIV 16;       { End }
  Intr($10,Regs);
  IF (Cursor = CursorOff) AND (VideoMode=$07) THEN GoToRC(1,81);
END;


FUNCTION HtReadAttr(Row,Col : BYTE) : BYTE;
{ Returns the attribute at position Row,Col }
VAR Offset : WORD;
BEGIN
  Offset := ((Row-1)*80 + (Col-1))*2;
  HtReadAttr := Mem[VideoSeg:Offset+1];
END;


FUNCTION HtReadChar(Row,Col : BYTE) : CHAR;
{ Returns the character at position Row,Col }
VAR Offset : WORD;
BEGIN
  Offset := ((Row-1)*80 + (Col-1))*2;
  HtReadChar := Chr(Mem[VideoSeg:Offset]);
END;


PROCEDURE HtWrite(Row,Col:BYTE; Attr:INTEGER; S : STRING);
{ Writes the string S at Row,Col using attributes Attr }
VAR I : BYTE;
    Offset : WORD;
BEGIN
  Offset := ((Row-1)*80 + (Col-1))*2;
  IF Attr = SameAttr THEN
  FOR I := 1 TO Length(S) DO
  BEGIN
    Mem[VideoSeg:Offset] := Ord(S[I]);
    Inc(Offset,2);
  END
  ELSE FOR I := 1 TO Length(S) DO
  BEGIN
    MemW[VideoSeg:Offset] := Attr SHL 8 + Ord(S[I]);
    Inc(Offset,2);
  END;
  EosOfs := Offset DIV 2;
END;


PROCEDURE HtWriteEos(Attr : INTEGER; S : STRING);
{ Writes the string S at the End-Of-String marker using attributes Attr }
VAR I : BYTE;
    Offset : WORD;
BEGIN
  Offset := EosOfs * 2;
  IF Attr = SameAttr THEN
  FOR I := 1 TO Length(S) DO
  BEGIN
    Mem[VideoSeg:Offset] := Ord(S[I]);
    Inc(Offset,2);
  END
  ELSE FOR I := 1 TO Length(S) DO
  BEGIN
    MemW[VideoSeg:Offset] := Attr SHL 8 + Ord(S[I]);
    Inc(Offset,2);
  END;
  EosOfs := Offset DIV 2;
END;


PROCEDURE HtWriteC(Row,Col:BYTE; Attr:INTEGER; S : STRING);
{ Writes the string S centered about Col at Row }
VAR L : BYTE;
BEGIN
  L := Length(S) DIV 2;
  HtWrite(Row,Col-L,Attr,S);
END;


PROCEDURE HtAttr(Row,Col,Rows,Cols,Attr : BYTE);
{ Changes the attributes in Row,Col,Rows,Cols to Attr }
VAR I,J : BYTE;
    Offset : WORD;
BEGIN
  IF Rows<1 THEN Exit;
  IF Cols<1 THEN Exit;
  FOR J := Row TO Row+Rows-1 DO
  FOR I := Col TO Col+Cols-1 DO
  BEGIN
    Offset := ((J-1)*80 + (I-1))*2;
    Mem[VideoSeg:Offset+1] := Attr;
  END;
END;


PROCEDURE HtFill(Row,Col,Rows,Cols,Attr : BYTE; C : CHAR);
{ Fills a window with Attr and C }
VAR I,J : BYTE;
    Offset : WORD;
BEGIN
  IF Rows<1 THEN Exit;
  IF Cols<1 THEN Exit;
  FOR J := Row TO Row+Rows-1 DO
  FOR I := Col TO Col+Cols-1 DO
  BEGIN
    Offset := ((J-1)*80 + (I-1))*2;
    MemW[VideoSeg:Offset] := Attr SHL 8 + Ord(C);
  END;
END;


PROCEDURE HtScrollUp(Row,Col,Rows,Cols,BlankAttr:BYTE);
{ Scrolls a window up }
BEGIN
  FillChar(Regs,SizeOf(Regs),0);
  Regs.AH := $06;
  Regs.AL := $01;
  Regs.BH := BlankAttr;
  Regs.CH := Row-1;
  Regs.CL := Col-1;
  Regs.DH := Row+Rows-2;
  Regs.DL := Col+Cols-2;
  Intr($10,Regs);
END;


PROCEDURE HtScrollDown(Row,Col,Rows,Cols,BlankAttr:BYTE);
{ Scrolls a window down }
BEGIN
  FillChar(Regs,SizeOf(Regs),0);
  Regs.AH := $07;
  Regs.AL := $01;
  Regs.BH := BlankAttr;
  Regs.CH := Row-1;
  Regs.CL := Col-1;
  Regs.DH := Row+Rows-2;
  Regs.DL := Col+Cols-2;
  Intr($10,Regs);
END;


PROCEDURE HtStoreToMem(Row,Col,Rows,Cols : BYTE; VAR Dest );
{ Stores the background to variable Dest }
VAR I,J : BYTE;
    Offs,Value,Segment,Offset : WORD;
BEGIN
  Segment := Seg(Dest);
  Offset := Ofs(Dest);
  FOR J := Row TO Row+Rows-1 DO
  FOR I := Col TO Col+Cols-1 DO
  BEGIN
    Offs := ((J-1)*80 + (I-1))*2;
    MemW[Segment:Offset] := MemW[VideoSeg:Offs];
    Inc(Offset,2);
  END;
END;


PROCEDURE HtStoreToScr(Row,Col,Rows,Cols : BYTE; VAR Source );
{ Draws the stored values in Source to screen }
VAR I,J : BYTE;
    Offs,Value,Segment,Offset : WORD;
BEGIN
  Segment := Seg(Source);
  Offset := Ofs(Source);
  FOR J := Row TO Row+Rows-1 DO
  FOR I := Col TO Col+Cols-1 DO
  BEGIN
    Offs := ((J-1)*80 + (I-1))*2;
    MemW[VideoSeg:Offs] := MemW[Segment:Offset];
    Inc(Offset,2);
  END;
END;


PROCEDURE HtClrScr;
{ Similar to TP ClrScr }
BEGIN
  HtFill(1,1,25,80,LightGray+BlackBG,' ');
  GoToRC(1,1);
END;


FUNCTION ShadowAttr(Attr : BYTE) : BYTE;
{ Returns the appropriate attribute for a shadow }
VAR Tmp : BYTE;
BEGIN
  Tmp := Attr AND $0F;
  IF Tmp > 8 THEN
  Tmp := Tmp - 8;
  ShadowAttr := Tmp;
END;


PROCEDURE AddShadow(Row,Col,Rows,Cols : BYTE);
{ Adds a shadow to a box }
VAR I : BYTE;
    Tmp : BYTE;
BEGIN
  FOR I := Row TO Row+Rows+1 DO
  BEGIN
    Tmp := HtReadAttr(I,Col+Cols+1);
    HtAttr(I,Col+Cols+1,1,1,ShadowAttr(Tmp));
    Tmp := HtReadAttr(I,Col+Cols+2);
    HtAttr(I,Col+Cols+2,1,1,ShadowAttr(Tmp));
  END;
  FOR I := Col+1 TO Col+Cols DO
  BEGIN
    Tmp := HtReadAttr(Row+Rows+1,I);
    HtAttr(Row+Rows+1,I,1,1,ShadowAttr(Tmp));
  END;
END;


PROCEDURE Box(Row,Col,Rows,Cols,Attr,Border:BYTE;  Fill:CHAR);
{ Draws a box }
VAR  I : BYTE;
     B : STRING[6];
BEGIN
  IF Fill <> #0 THEN
    HtFill(Row,Col,Rows,Cols,Attr,Fill);
  CASE Border OF
    NoBorder     : B := EmptyBorder;
    SingleBorder : B := SBorder;
    DoubleBorder : B := DBorder;
    DTopSSide    : B := DSBorder;
    STopDSide    : B := SDBorder;
    DTopSSideHang: B := DSBorderHang;
  END;
  IF Rows=0 THEN Exit;
  FOR I := 0 TO Rows-1 DO
  BEGIN
    HtWrite(Row+I,Col-1,Attr,B[4]);
    HtWrite(Row+I,Col+Cols,Attr,B[4]);
  END;
  IF Cols=0 THEN Exit;
  FOR I := 0 TO Cols-1 DO
  BEGIN
    If Border<5 then
       HtWrite(Row-1,Col+I,Attr,B[2])
    else
       HtWrite(Row-1,Col+I,Attr,#32);
    HtWrite(Row+Rows,Col+I,Attr,B[2]);
  END;
  HtWrite(Row-1,Col-1,Attr,B[1]);
  HtWrite(Row-1,Col+Cols,Attr,B[3]);
  HtWrite(Row+Rows,Col-1,Attr,B[6]);
  HtWrite(Row+Rows,Col+Cols,Attr,B[5]);
END;


PROCEDURE Explode(Row,Col,Rows,Cols,Attr,Border:BYTE);
{ Explodes a box }
VAR I,R1,R2,C1,C2 : BYTE;
    MR,MC,DR,DC : SINGLE;
BEGIN
  DR := Rows/11;
  DC := Cols/11;
  MR := Row+Rows/2;
  MC := Col+Cols/2;
  FOR I := 1 TO 5 DO
  BEGIN
    R1 := Trunc(MR-I*DR);  R2 := Trunc(2*I*DR);
    C1 := Trunc(MC-I*DC);  C2 := Trunc(2*I*DC);
    Box(R1,C1,R2,C2,Attr,Border,' ');
    HtDelay(10);
  END;
  Box(Row,Col,Rows,Cols,Attr,Border,' ');
END;


PROCEDURE GetFont(VAR CRTRows : BYTE);
{ Gets the number of rows on the screen }
BEGIN
  FillChar(Regs,SizeOf(Regs),0);
  Regs.AH := $11;
  Regs.AL := $30;
  Regs.BH := $02;
  Intr($10,Regs);
  CRTRows := Regs.DL+1;
END;


PROCEDURE SetFont(Font : BYTE);
{ Sets the number of rows on the screen : 25 or 43/50 }
BEGIN
  IF Font=NormalFont THEN
  BEGIN
    FillChar(Regs,SizeOf(Regs),0);
    Regs.AH := $00;
    Regs.AL := VideoMode;
    Intr($10,Regs);
    CRTRows := 25;
  END
  ELSE BEGIN
    FillChar(Regs,SizeOf(Regs),0);
    Regs.AH := $11;
    Regs.AL := $12;
    Regs.BH := $00;
    Intr($10,Regs);
    GetFont(CRTRows);
  END;
END;


FUNCTION GetVideoMode : BYTE;
{ Returns the Video Mode }
BEGIN
  FillChar(Regs,SizeOf(Regs),0);
  Regs.AH := $0F;
  Intr($10,Regs);
  GetVideoMode := Regs.AL;
END;


PROCEDURE SetVideoMode(Mode : BYTE);
{ Sets the video mode }
BEGIN
  IF NOT Mode IN [$02,$03,$07] THEN Exit;
  FillChar(Regs,SizeOf(Regs),0);
  Regs.AH := $00;
  Regs.AL := Mode;
  Intr($10,Regs);
END;


PROCEDURE HtInit;
{ Initializes some variables }
BEGIN
  VideoMode := GetVideoMode;
  IF NOT VideoMode IN [$02,$03,$07] THEN HtError(0);  { Wrong video mode }
  GetCursor(CursorInitial);
  CRTCols := 80;
  CASE VideoMode OF
    $02,$03 : BEGIN
            CursorUnderline := 118;  { 6-7 }
            CursorHalfBlock := 116;  { 4-7 }
            CursorBlock     := 113;  { 1-7 }
            CursorOff       := 1;    { 0-1 }
            VideoSeg        := $B800;
          END;
    $07 : BEGIN
            CursorUnderline := 203;  { 11-12 }
            CursorHalfBlock := 198;  {  6-12 }
            CursorBlock     := 193;  {  1-12 }
            CursorOff       := 1;    {  0- 1 }
            VideoSeg        := $B000;
          END;
  END;
  GetFont(CRTRows);
END;


BEGIN
  HtInit;
END.
