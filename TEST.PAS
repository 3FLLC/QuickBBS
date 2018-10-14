Program ExSetup;
(* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *    PROGRAM: EXCHANGEBBS SETUP                                           *
 *    AUTHORS: G.E. OZZ NIXON JR.                                          *
 * ASSISTANCE: PETER KLING, DAVID SMART, DALE BARNES, FRED RICCIO          *
 *      ABOUT: INSPIRED/INFLUENCED BY QCONFIG FOR QUICKBBS V2.8, THEN BY   *
 *             SUPERBBS V1173, REMOTE ACCESS 2.6 AND PCBOARD 14 SETUP      *
 *             SCREENS. I DECIDED TO DROP THE BULK OF OPRO AND WENT WITH A *
 *             MORE STREAMLINE/BASIC SCREEN AND KEYBOARD CODE. EXTENDED BY *
 *             ME TO MAKE A SETUP SCREEN MUCH EASIER AND SMALLER EXE SIZE. *
 *  COPYRIGHT: 2018 BY BRAIN PATCHWORK DX, LLC. (WWW.BPDX.COM)             *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *)

USES
   HTSCREEN,
   HTSTRING,
   HTINPUT;

CONST
{$IFDEF OVR}
   OVRSTR = ' OVR';
{$ELSE}
   OVRSTR = '';
{$ENDIF}
   BETASTR = ' (Alpha-1)';
   VERSIONSTR = '3.0'+OvrStr+BetaStr;

Type
   InputScreen = Packed Record
      X,Y:Word;
      Prompt:String;
      R,C,L:Byte;
      Attr:Integer;
   End;
   VertMenuItem = Packed Record
      Prompt:String[15];
      Hint:String[78];
      Selected,
      Opened:Boolean;
   End;
   HorzMenuItem = Packed Record
      X,Y:Word;
      Prompt:String[15];
      Hint:String[78];
      NormAttr,
      SelAttr:Integer;
      Selected,
      Opened:Boolean;
      SubWidth,
      SubHeight:Word;
      SubMenu:Array[0..19] of VertMenuItem;
   End;

Var
   MainMenu:Array[0..9] of HorzMenuItem;
   ScreenArr:Array[0..63] of InputScreen;

Procedure PressAnyKey(Row:Byte);
Var
   C:Char;
Begin
   SetCursor(CursorOff);
   HtWriteC(Row,40,Yellow+Blink+RedBG,' Press ANY Key ');
   {HtWriteC(Row,40,White+Blink+MagentaBG,' Press ANY Key ');}
   C:=HtReadKey(Fk);
   SetCursor(CursorInitial);
   If C=#27 then Halt(1);
End;

Procedure OKButton(Row, Col:Byte);
Var
   C:Char;
Begin
   HtWrite(Row,Col,Black+GreenBG,'  OK  ');
   Repeat
      C:=HtReadKey(Fk);
   Until C=#13;
End;

Procedure BuildScreen(Rec,X,Y:Word;P:String;R,C,L:Byte;Attr:Integer);
Begin
   ScreenArr[Rec].X:=X;
   ScreenArr[Rec].Y:=Y;
   ScreenArr[Rec].Prompt:=P;
   ScreenArr[Rec].R:=R;
   ScreenArr[Rec].C:=C;
   ScreenArr[Rec].L:=L;
   ScreenArr[Rec].Attr:=Attr;
End;

Procedure BuildMainMenu(Rec,X,Y:Word;P,H:String;NA,SA:Integer;S,O:Boolean;SW,SH:Word);
Begin
   MainMenu[Rec].X:=X;
   MainMenu[Rec].Y:=Y;
   MainMenu[Rec].Prompt:=P;
   MainMenu[Rec].Hint:=H;
   MainMenu[Rec].NormAttr:=NA;
   MainMenu[Rec].SelAttr:=SA;
   MainMenu[Rec].Selected:=S;
   MainMenu[Rec].Opened:=O;
   MainMenu[Rec].SubWidth:=SW;
   MainMenu[Rec].SubHeight:=SH;
End;

Procedure AddSubMenu(Rec,Sub:Word;P,H:String;S,O:Boolean);
Begin
   MainMenu[Rec].SubMenu[Sub].Prompt:=P;
   MainMenu[Rec].SubMenu[Sub].Hint:=H;
   MainMenu[Rec].SubMenu[Sub].Selected:=S;
   MainMenu[Rec].SubMenu[Sub].Opened:=O;
End;

Procedure BuildWindow;
Begin
   HtInit;
   HtClrScr;
   SetCursor(CursorOff);
   HtFill(1,1,25,80,$78,#177);
   HtFill(1,1,1,80,$1F,#32);
   HtWriteC(1,40,$1F,'ExchangeBBS Configuration v'+VersionStr+' (c) 2018 by G.E. Ozz Nixon Jr.');
   HtFill(2,1,1,80,$1E,#32);
   HtFill(3,1,1,80,$13,#205);
   HtFill(25,1,1,80,$70,#32);
   BuildMainMenu(0,4,2,'Registration','Overall System Information and Basic Settings',$1E,$3E,True,False,12,3);
     AddSubMenu(0,0,'Information ','Author, Copyright and Support/Contact Information',True,False);
     AddSubMenu(0,1,'Registration','Contact and System Information for Software License',False,False);
     AddSubMenu(0,2,'What is New ','Report of changes and bug fixes applied to this build',False,False);
   BuildMainMenu(1,19,2,'General','General System Configuration Settings',$1E,$3E,False,False,10,9);
     AddSubMenu(1,0,'Languages ','Language Configuration, Text and Supporting Settings',True,False);
     AddSubMenu(1,1,'File Paths','Specify File Locations, Root Paths, Sub-Folders, Etc.',False,False);
     AddSubMenu(1,2,'Modem     ','Specify Manufacturer, Model, and Communication Settings',False,False);
     AddSubMenu(1,3,'Protocols ','Select which file transfer protocols you wish to support',False,False);
     AddSubMenu(1,4,'Events    ','Specify System Events to automate periodic tasks',False,False);
     AddSubMenu(1,5,'Color     ','Setup default application and online colors',False,False);
     AddSubMenu(1,6,'Security  ','System Security Parameters',False,False);
     AddSubMenu(1,7,'Verifier  ','Setup Automated User Verification Processes',False,False);
     AddSubMenu(1,8,'Other     ','Additional System Configurations',False,False);
   BuildMainMenu(2,29,2,'User','User Related Configuration Settings',$1E,$3E,False,False,12,3);
     AddSubMenu(2,0,'Limits      ','Define user limits and ratios',True,False);
     AddSubMenu(2,1,'Restrictions','Specify user restrictions by time of day',False,False);
     AddSubMenu(2,2,'New User    ','Setup new user defaults, program features and prompts',False,False);
   BuildMainMenu(3,36,2,'Messages','Message Area Related Configuration Settings',$1E,$3E,False,False,15,4);
     AddSubMenu(3,0,'Netmail        ','Specify Fido type network Addresses and Netmail message area',True,False);
     AddSubMenu(3,1,'Message Boards ','Configure individual message areas, paths, permissions and more',False,False);
     AddSubMenu(3,2,'External Editor','Define an optional full screen editor application',False,False);
     AddSubMenu(3,3,'Origin Line    ','Setup the signature line for echo mail message from your system',False,False);
   BuildMainMenu(4,47,2,'Files','File Area Related Configuration Settings',$1E,$3E,False,False,11,2);
     AddSubMenu(4,0,'TIC Areas  ','TIC Network Address, AKA''s and Magic Names',True,False);
     AddSubMenu(4,1,'File Boards','Configure individual file areas, paths, permissions and more',False,False);
   BuildMainMenu(5,55,2,'Interfaces','External Software and System Related Configuration Settings',$1E,$3E,False,False,8,3);
     AddSubMenu(5,0,'Fidonet ','Specify optional front-end mailer path to import configuration information',True,False);
     AddSubMenu(5,1,'Email   ','Specify optional email server infromation to give users Internet email',False,False);
     AddSubMenu(5,2,'Realtime','Implement realtime network, allowing node to node chat and more',False,False);
   BuildMainMenu(6,68,2,'Exit','Save or not to Save Configuration Settings then Terminate',$1E,$3E,False,False,6,3);
     AddSubMenu(6,0,'Save  ','Save all changes to disk and terminate',True,False);
     AddSubMenu(6,1,'Quit  ','Abort, do not save changes to disk, just terminate',False,False);
     AddSubMenu(6,2,'Reload','Reload previous configuration settings before any changes this session',False,False);
   BuildMainMenu(7,0,0,'','',0,0,False,False,0,0);
End;

{$I REGINFO.INC}
{$I LICENSE.INC}

Procedure ShowScreen(Selected, SubSelected:Word);
Var
   Screen:ARRAY[1..50,1..80] OF WORD;

Begin
   HtStoreToMem(1,1,CrtRows,CrtCols,Screen);
   Case Selected of
      0:Case SubSelected of
         0:RegInfo;
         1:License;
      End;
   End;
   HtStoreToScr(1,1,CrtRows,CrtCols,Screen);
End;

Procedure ProcessMainMenu;
Var
   Loop,MaxMenu,Selected,SubSelected,MaxSubMenu:Byte;
   C:Char;
   F:Boolean;
   K:KeyType;

Begin
{   K:=[Return,UpArrow,DownArrow,LeftArrow,RightArrow,HomeKey,EndKey,SpaceKey,Escape];}

   For Loop:=0 to 9 do begin
      If MainMenu[Loop].X=0 then break;
      If MainMenu[Loop].Selected then begin
         HtWrite(MainMenu[Loop].Y, MainMenu[Loop].X, MainMenu[Loop].SelAttr, MainMenu[Loop].Prompt);
         HtAttr(MainMenu[Loop].Y, MainMenu[Loop].X, 1, 1, MainMenu[Loop].SelAttr+1);
         Selected:=Loop;
      end
      Else begin
         HtWrite(MainMenu[Loop].Y, MainMenu[Loop].X, MainMenu[Loop].NormAttr, MainMenu[Loop].Prompt);
         HtAttr(MainMenu[Loop].Y, MainMenu[Loop].X, 1, 1, MainMenu[Loop].NormAttr+1);
      End;
   End;

   MaxMenu:=Loop-1;
   Repeat
      InKey(C,F,K);
      Case K of
         LeftArrow:Begin
            If MainMenu[Selected].Opened then begin
               MainMenu[Selected].Opened:=False;
               HtFill(3,MainMenu[Selected].X-2,1,MainMenu[Selected].SubWidth+4,$13,#205);
               HtFill(4,MainMenu[Selected].X-2,MainMenu[Selected].SubHeight+2,MainMenu[Selected].SubWidth+6,$78,#177);
            End;
            HtAttr(MainMenu[Selected].Y,MainMenu[Selected].X,1,Length(MainMenu[Selected].Prompt),MainMenu[Selected].NormAttr);
            HtAttr(MainMenu[Selected].Y,MainMenu[Selected].X,1,1,MainMenu[Selected].NormAttr+1);
            If Selected=0 then Selected:=MaxMenu
            Else Dec(Selected);
            HtAttr(MainMenu[Selected].Y,MainMenu[Selected].X,1,Length(MainMenu[Selected].Prompt),MainMenu[Selected].SelAttr);
            HtAttr(MainMenu[Selected].Y,MainMenu[Selected].X,1,1,MainMenu[Selected].SelAttr+1);
            MaxSubMenu:=0;
            HtFill(25,1,1,80,$70,#32);
            HtWrite(25,3,$70,MainMenu[Selected].Hint);
         End;

         RightArrow:Begin
            If MainMenu[Selected].Opened then begin
               MainMenu[Selected].Opened:=False;
               HtFill(3,MainMenu[Selected].X-2,1,MainMenu[Selected].SubWidth+4,$13,#205);
               HtFill(4,MainMenu[Selected].X-2,MainMenu[Selected].SubHeight+2,MainMenu[Selected].SubWidth+6,$78,#177);
            End;
            HtAttr(MainMenu[Selected].Y,MainMenu[Selected].X,1,Length(MainMenu[Selected].Prompt),MainMenu[Selected].NormAttr);
            HtAttr(MainMenu[Selected].Y,MainMenu[Selected].X,1,1,MainMenu[Selected].NormAttr+1);
            If Selected=MaxMenu then Selected:=0
            Else Inc(Selected);
            HtAttr(MainMenu[Selected].Y,MainMenu[Selected].X,1,Length(MainMenu[Selected].Prompt),MainMenu[Selected].SelAttr);
            HtAttr(MainMenu[Selected].Y,MainMenu[Selected].X,1,1,MainMenu[Selected].SelAttr+1);
            MaxSubMenu:=0;
            HtFill(25,1,1,80,$70,#32);
            HtWrite(25,3,$70,MainMenu[Selected].Hint);
         End;

         DownArrow,Return:Begin
            If MainMenu[Selected].Opened then begin
               {pick item or scroll high lighter}
               If K=Return then Begin
                  {ShowScreen!}
                  ShowScreen(Selected, SubSelected);
               End
               Else Begin
                  HtWrite(MainMenu[Selected].Y+(SubSelected+2),MainMenu[Selected].X-1,MainMenu[Selected].NormAttr,
                     #32+MainMenu[Selected].SubMenu[SubSelected].Prompt+#32);
                  HtAttr(MainMenu[Selected].Y+(SubSelected+2),MainMenu[Selected].X,1,1,MainMenu[Selected].NormAttr+1);
                  If SubSelected=MaxSubMenu then SubSelected:=0
                  Else Inc(SubSelected);
                  HtWrite(MainMenu[Selected].Y+(SubSelected+2),MainMenu[Selected].X-1,MainMenu[Selected].SelAttr,
                     #32+MainMenu[Selected].SubMenu[SubSelected].Prompt+#32);
                  HtAttr(MainMenu[Selected].Y+(SubSelected+2),MainMenu[Selected].X,1,1,MainMenu[Selected].SelAttr+1);
                  HtFill(25,1,1,80,$70,#32);
                  HtWrite(25,3,$70,MainMenu[Selected].SubMenu[SubSelected].Hint);
               End;
            End
            Else Begin
               MainMenu[Selected].Opened:=True;
               Explode(MainMenu[Selected].Y+2,MainMenu[Selected].X-1,MainMenu[Selected].SubHeight,
                  MainMenu[Selected].SubWidth+2,$13,5);
               AddShadow(MainMenu[Selected].Y+2,MainMenu[Selected].X-1,MainMenu[Selected].SubHeight,
                  MainMenu[Selected].SubWidth+2);
               MaxSubMenu:=0;
               If MainMenu[Selected].SubHeight>0 then
                  MaxSubMenu:=MainMenu[Selected].SubHeight-1;
               For Loop:=0 to MainMenu[Selected].SubHeight-1 do begin
                  If MainMenu[Selected].SubMenu[Loop].Selected then begin
                     SubSelected:=Loop;
                     HtWrite(MainMenu[Selected].Y+(Loop+2),MainMenu[Selected].X-1,MainMenu[Selected].SelAttr,
                        #32+MainMenu[Selected].SubMenu[Loop].Prompt+#32);
                     HtAttr(MainMenu[Selected].Y+(Loop+2),MainMenu[Selected].X,1,1,MainMenu[Selected].SelAttr+1);
                  End
                  Else Begin
                     HtWrite(MainMenu[Selected].Y+(Loop+2),MainMenu[Selected].X-1,MainMenu[Selected].NormAttr,
                        #32+MainMenu[Selected].SubMenu[Loop].Prompt+#32);
                     HtAttr(MainMenu[Selected].Y+(Loop+2),MainMenu[Selected].X,1,1,MainMenu[Selected].NormAttr+1);
                  End;
               End;
               HtFill(25,1,1,80,$70,#32);
               HtWrite(25,3,$70,MainMenu[Selected].SubMenu[SubSelected].Hint);
            End;
         End;

         UpArrow:Begin
            If MainMenu[Selected].Opened then begin
               {scroll high lighter}
               HtWrite(MainMenu[Selected].Y+(SubSelected+2),MainMenu[Selected].X-1,MainMenu[Selected].NormAttr,
                  #32+MainMenu[Selected].SubMenu[SubSelected].Prompt+#32);
               HtAttr(MainMenu[Selected].Y+(SubSelected+2),MainMenu[Selected].X,1,1,MainMenu[Selected].NormAttr+1);
               If SubSelected=0 then SubSelected:=MaxSubMenu
               Else Dec(SubSelected);
               HtWrite(MainMenu[Selected].Y+(SubSelected+2),MainMenu[Selected].X-1,MainMenu[Selected].SelAttr,
                  #32+MainMenu[Selected].SubMenu[SubSelected].Prompt+#32);
               HtAttr(MainMenu[Selected].Y+(SubSelected+2),MainMenu[Selected].X,1,1,MainMenu[Selected].SelAttr+1);
               HtFill(25,1,1,80,$70,#32);
               HtWrite(25,3,$70,MainMenu[Selected].SubMenu[SubSelected].Hint);
            End;
         End;

         Else Case C of
            'R','r':Begin
            End;
         End;
      End;
   Until K=Escape;
End;

Begin
   BuildWindow;
   ProcessMainMenu;
   BuildScreen(0,4,2,'Ask for Email Address:',2,27,1,$1F);
   BuildScreen(1,4,3,'Ask for Date of Birth:',3,27,1,$1F);
   BuildScreen(2,0,0,'',0,0,0,0);
   PressAnyKey(24);
   SetCursor(CursorInitial);
End.
