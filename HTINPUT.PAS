UNIT HTINPUT;
(*****************************************************************************)
(*                                                                           *)
(*   KeyBoard inneholder to rutiner som gj›r input fra tastaturet enklere.   *)
(*                                                                           *)
(*****************************************************************************)

{-----------------------------------------------------------------------------}
INTERFACE
{-----------------------------------------------------------------------------}

USES HtScreen;

TYPE  KeyType = (NullKey,F1,F2,F3,F4,F5,F6,F7,F8,F9,F10,
		 Return,TabKey,ShiftTabKey,BackSpaceKey,UpArrow,
                 DownArrow,RightArrow,LeftArrow,DelKey,
                 InsertKey,HomeKey,EndKey,TextKey,NumberKey,
                 SpaceKey,PgUp,PgDn,Escape);
   KeySetType = SET OF KeyType;

VAR   Key  : KeyType;
      Ch   : CHAR;
      Fk   : BOOLEAN;
      InsertOn : BOOLEAN;

PROCEDURE InKey(VAR Ch:CHAR; VAR Fk:BOOLEAN; VAR Key:KeyType);

FUNCTION InputString(VAR S:STRING; R,C,L,ML:BYTE; Attr:INTEGER; KeySet:KeySetType):KeyType;
FUNCTION InputBool(VAR B:BOOLEAN; R,C:BYTE; Attr:INTEGER; KeySet:KeySetType):KeyType;
FUNCTION InputYNAsk(VAR B:Byte; R,C:BYTE; Attr:INTEGER; KeySet:KeySetType):KeyType;
{-----------------------------------------------------------------------------}
IMPLEMENTATION
{-----------------------------------------------------------------------------}

PROCEDURE InKey(VAR Ch:CHAR; VAR Fk:BOOLEAN; VAR Key:KeyType);
(*****************************************************************************)
(*                                                                           *)
(*   F†r en tast fra bruker og returnerer karakt eren. Setter Fk=TRUE hvis   *)
(*   funksjons-tast.  Returnerer ogs† taste-typen.                           *)
(*                                                                           *)
(*****************************************************************************)
BEGIN
  Ch:=HtReadKey(Fk);
  IF Fk THEN
  CASE Ch OF
    #72 : Key:=UpArrow;
    #80 : Key:=DownArrow;
    #82 : Key:=InsertKey;
    #75 : Key:=LeftArrow;
    #77 : Key:=RightArrow;
    #73 : Key:=PgUp;
    #81 : Key:=PgDn;
    #71 : Key:=HomeKey;
    #79 : Key:=EndKey;
    #83 : Key:=DelKey;
    #82 : Key:=InsertKey;
    #59 : Key:=F1;
    #60 : Key:=F2;
    #61 : Key:=F3;
    #62 : Key:=F4;
    #63 : Key:=F5;
    #64 : Key:=F6;
    #65 : Key:=F7;
    #66 : Key:=F8;
    #67 : Key:=F9;
    #68 : Key:=F10;
    Else Writeln(Ord(Ch));
  END
  ELSE
  CASE Ch OF
     #8 : Key:=BackSpaceKey;
     #9 : Key:=TabKey;
    #13 : Key:=Return;
    #27 : Key:=Escape;
    #32 : Key:=SpaceKey;
    #33..#47,
    #58..#255 : Key:=TextKey;
    #48..#57 : Key:=NumberKey;
  END;
END;


Function InputString(VAR S:STRING; R,C,L,ML:BYTE; Attr:INTEGER; KeySet:KeySetType):KeyType;
(*****************************************************************************)
(*                                                                           *)
(*   Tillater brukeren † lese inn en streng S ved koordinater X:Y med max    *)
(*   lengde L. Strengen vises i attributtene Attr.                           *)
(*   KeySet er et sett av taster som bestemmer n†r innlesningen skal stoppes.*)
(*   Modified to return LAST KEY, so we can support TAB to next field, Down  *)
(*   Arrow to Field Below, Up Arror to Field Before, Shift-TAB prior field.  *)
(*   L=VISIBLE Length of Input Field, ML=MAX Length of the Input Field.      *)
(*                                                                           *)
(*****************************************************************************)
CONST Fill : CHAR = #0;
VAR   P : BYTE;
      I,J : WORD;
      Ch : CHAR;
      Fk : BOOLEAN;
BEGIN
  InsertOn := FALSE;
  I:=Length(S)+1;
  IF I>L THEN S:=Copy(S,1,L)
  ELSE BEGIN
    FOR J:=I TO L DO S[J]:=Fill;
    S[0]:=Chr(L);
  END;
  P:=1;
  REPEAT
    HtWrite(R,C,Attr,S);
    GoToRC(R,C+P-1);
    IF InsertOn THEN SetCursor(CursorBlock)
    ELSE SetCursor(CursorUnderline);
    InKey(Ch,Fk,Key);
    SetCursor(CursorOff);
    CASE Key OF
      TextKey,
      NumberKey,
      SpaceKey : BEGIN
                   IF InsertOn THEN BEGIN
                     Insert(Ch,S,P);
                     S[0]:=Chr(ML);
                     IF P<ML THEN Inc(P);
                   END
                   ELSE BEGIN
                     S[P]:=Ch;
                     IF P<ML THEN Inc(P);
                   END;
                 END;
      InsertKey: BEGIN
                   InsertOn:= NOT InsertOn;
                 END;
      DelKey   : BEGIN
                   Delete(S,P,1);
                   S:=S+Fill;
                 END;
      LeftArrow: BEGIN
                   IF P>1 THEN Dec(P);
                 END;
      RightArrow:BEGIN
                   IF (Pos(Fill,S)>0) THEN BEGIN
                     IF (P<Pos(Fill,S)) THEN Inc(P);
                   END
                   ELSE IF (P<ML) THEN Inc(P);
                 END;
    HomeKey     :P := 1;
    EndKey      :P := Pos(Fill,S);
    BackSpaceKey:BEGIN
                   IF P>1 THEN BEGIN
                     Dec(P);
                     Delete(S,P,1);
                     S:=S+Fill;
                   END;
                 END;
    END;
  UNTIL Key IN KeySet;
  I:=Pos(Fill,S);
  IF I>0 THEN S:=Copy(S,1,I-1);
  InputString:=Key;
  HtAttr(R,C,1,L,$1F);
END;

FUNCTION InputBool(VAR B:BOOLEAN; R,C:BYTE; Attr:INTEGER; KeySet:KeySetType):KeyType;
Var
   CH:Char;
   Key:KeyType;
   FK:Boolean;

Begin
   Repeat
      If B then HtWrite(R,C,Attr,'Yes')
      Else HtWrite(R,C,Attr,' No');
      InKey(Ch,Fk,Key);
      If not FK then
         If Ch in ['Y','y'] then B:=True
         else If Ch in ['N','n'] then B:=False
         else if Ch in ['+',#32,'-'] then B:=not B;
   Until Key in KeySet;
   InputBool:=Key;
   HtAttr(R,C,1,3,$1F);
End;

FUNCTION InputYNAsk(VAR B:Byte; R,C:BYTE; Attr:INTEGER; KeySet:KeySetType):KeyType;
Var
   CH:Char;
   Key:KeyType;
   FK:Boolean;

Begin
   Repeat
      If B=1 then HtWrite(R,C,Attr,'Yes')
      Else if B=0 then HtWrite(R,C,Attr,' No')
      Else HtWrite(R,C,Attr,'Ask');
      InKey(Ch,Fk,Key);
      If not FK then
         If Ch in ['Y','y'] then B:=1
         else If Ch in ['N','n'] then B:=0
         else If Ch in ['A','a'] then B:=255
         else if Ch in ['+',#32] then Begin
            Inc(B);
            If B>2 then B:=255;
         end
         else if Ch='-' then Begin
            If B=255 then B:=1
            Else if B=0 then B:=255
            Else Dec(B);
         End;
   Until Key in KeySet;
   InputYNAsk:=Key;
   HtAttr(R,C,1,3,$1F);
End;


BEGIN
  InsertOn:=FALSE;
  Key:=NullKey;
END.
