﻿unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, System.Generics.Collections, System.IniFiles,
  ShellAPI, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, cefvcl, ceflib, Vcl.ExtCtrls, Vcl.StdCtrls,
  Vcl.ComCtrls, Vcl.Buttons, Vcl.Samples.Spin, System.DateUtils, Data.DB, MemDS,
  DBAccess, MyAccess, DALoader, MyLoader, Vcl.Menus, AdvProgr, AdvProgressBar,
  Vcl.Grids, AdvObj, BaseGrid, AdvGrid, Vcl.CheckLst, tmsAdvGridExcel;

type
  TSport = record
    Name:WideString;
    CName:WideString;
    HomeURL:string;
  end;

type
  TLeague = record
    Name:WideString;
    GamesURL:string;
    SportsKey:string;
  end;

type
  TGame = record
    LeagueName:WideString;
    GameID:string;
    GameName:WideString;
    GameDate:string;
    GameTime:string;
    HomeTeam:WideString;
    VisitTeam:WideString;
    Spread1:string;
    Spread2:string;
    Total_Over:string;
    Total_Under:string;
  end;

type
  TForm1 = class(TForm)
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    lbledt_basketball_url: TLabeledEdit;
    chrm_basketball: TChromium;
    btn_basketball_run: TBitBtn;
    tmr_game_refresh: TTimer;
    mmo_basketball_error: TMemo;
    tmr_odds_checkcrash: TTimer;
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    Panel4: TPanel;
    Panel5: TPanel;
    mmo_basketball_message: TMemo;
    PageControl2: TPageControl;
    TabSheet2: TTabSheet;
    TabSheet3: TTabSheet;
    GroupBox3: TGroupBox;
    lbl_message: TLabel;
    Panel6: TPanel;
    btn_clear: TButton;
    asg_basketball_scanresult: TAdvStringGrid;
    Panel7: TPanel;
    Panel8: TPanel;
    lbl_league: TLabel;
    btn_getgames: TButton;
    clb_league: TCheckListBox;
    cb_selectall: TCheckBox;
    grp2: TGroupBox;
    lbl1: TLabel;
    lbl_game_countdown: TLabel;
    chk_game_refresh: TCheckBox;
    se_game_update_interval: TSpinEdit;
    Panel9: TPanel;
    Button2: TButton;
    cb_sound: TCheckBox;
    chrm_tmp: TChromium;
    Button1: TButton;
    Button3: TButton;
    BitBtn1: TBitBtn;
    SaveDialog1: TSaveDialog;
    ageio_savetoexcel: TAdvGridExcelIO;
    Panel10: TPanel;
    lbl_league_message: TLabel;
    procedure btn_basketball_runClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure chrm_basketballLoadEnd(Sender: TObject; const browser: ICefBrowser;
      const frame: ICefFrame; httpStatusCode: Integer);
    procedure tmr_game_refreshTimer(Sender: TObject);
    procedure chk_game_refreshClick(Sender: TObject);
    procedure chrm_basketballLoadError(Sender: TObject; const browser: ICefBrowser;
      const frame: ICefFrame; errorCode: Integer; const errorText,
      failedUrl: ustring);
    procedure tmr_odds_checkcrashTimer(Sender: TObject);
    procedure lbledt_basketball_urlKeyPress(Sender: TObject; var Key: Char);
    procedure btn_clearClick(Sender: TObject);
    procedure chrm_basketballAddressChange(Sender: TObject;
      const browser: ICefBrowser; const frame: ICefFrame; const url: ustring);
    procedure btn_getgamesClick(Sender: TObject);
    procedure cb_selectallClick(Sender: TObject);
    procedure clb_leagueClickCheck(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure chrm_tmpLoadEnd(Sender: TObject; const browser: ICefBrowser;
      const frame: ICefFrame; httpStatusCode: Integer);
    procedure Button1Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure BitBtn1Click(Sender: TObject);
  private
    { Private declarations }
    function getGameSportKey(key:string):string;
    procedure getBasketballLeagueList(const str:ustring);
    procedure getBasketballGameList(const str:ustring);
    procedure refreshBasketballLeagueList(const str:ustring);
    procedure putTotalData(var GameList:TList<TGame>;TotalGameList:TList<TGame>);
    procedure doCompareGame(TmpGameList:TList<TGame>);
    procedure getSelectedLeagueList;
    procedure CopyToSelectedGameList_Old(Source:TList<TGame>);
  public
    { Public declarations }
    function ExtractDomain(URL:String):String;
    procedure writeOddsMessage(Content:WideString);
    function ConvertToFloat(str:string):Real;
  end;

var
  Form1: TForm1;
  Basketball:TSport;
  HomeURL:string='https://mobile.bet365.com/?#type=Home;key=0;ip=1;lng=2';
  LeagueList:TList<TLeague>;
  SelectedLeagueList:TList<TLeague>;
  GameList:TList<TGame>;
  GameList_Old:TList<TGame>;
  IsLogined:Boolean = false;
  GameStartIndex,GameEndIndex:integer;
  LeagueIndex:integer=0;
  CurrentRunTime, LastRumTime: TDateTime;
  CrashCount: Integer = 0;
  IsRunning: Boolean = false;
  IsGetLeagues: Boolean = false;

implementation

{$R *.dfm}

uses
  MSHTML, ActiveX, ComObj, StrUtils, MMSystem;

procedure TForm1.getSelectedLeagueList;
var
  i:integer;
begin
  SelectedLeagueList.Clear;
  for i := 0 to clb_league.Items.Count -1 do
  begin
    if clb_league.Checked[i] = True then
    begin
      SelectedLeagueList.Add(LeagueList[i]);
    end;
  end;
end;

function TForm1.getGameSportKey(key:string):string;
var
  i:integer;
  tmp:string;
  arrKey: TArray<String>;
begin
  arrKey:=key.Split(['-']);
  arrKey[2]:='48';
  arrKey[3]:='1';
  arrKey[4]:='36';
  tmp:='';
  for i := 0 to length(arrKey) -1 do
  begin
    tmp:=tmp+arrKey[i]+'-';
  end;
  tmp:=copy(tmp, 0, length(tmp)-1);

  result:=tmp;
end;

procedure TForm1.putTotalData(var GameList:TList<TGame>;TotalGameList:TList<TGame>);
var
  i,j:integer;
begin
  for i := 0 to TotalGameList.Count - 1 do
  begin
    for j := 0 to GameList.Count - 1 do
    begin
      if (TotalGameList[i].GameID = GameList[j].GameID) and (TotalGameList[i].GameName = GameList[j].GameName) then
      begin
        GameList.List[j].Total_Over:=TotalGameList[i].Total_Over;
        GameList.List[j].Total_Under:=TotalGameList[i].Total_Under;
      end;
    end;
  end;
end;

procedure TForm1.CopyToSelectedGameList_Old(Source:TList<TGame>);
var
  i:integer;
  tmp:TGame;
begin
  GameList_Old.Clear;
  for i := 0 to Source.Count - 1 do
  begin
    tmp.LeagueName:=Source[i].LeagueName;
    tmp.GameID:=Source[i].GameID;
    tmp.GameName:=Source[i].GameName;
    tmp.HomeTeam:=Source[i].HomeTeam;
    tmp.VisitTeam:=Source[i].VisitTeam;
    tmp.GameDate:=Source[i].GameDate;
    tmp.GameTime:=Source[i].GameTime;
    tmp.Spread1:=Source[i].Spread1;
    tmp.Spread2:=Source[i].Spread2;
    tmp.Total_Over:=Source[i].Total_Over;
    tmp.Total_Under:=Source[i].Total_Under;
    GameList_Old.Add(tmp);
  end;
end;

procedure TForm1.doCompareGame(TmpGameList:TList<TGame>);
var
  i,j:integer;
  IsChanged,IsExists:boolean;
begin
  IsChanged:=false;
  for i := 0 to TmpGameList.Count - 1 do
  begin
    IsExists:=False;
    for j := 0 to GameList_Old.Count - 1 do
    begin
      if (trim(TmpGameList[i].LeagueName) = trim(GameList_Old[j].LeagueName))
        and (trim(TmpGameList[i].HomeTeam) = trim(GameList_Old[j].HomeTeam))
        and (trim(TmpGameList[i].VisitTeam) = trim(GameList_Old[j].VisitTeam))
        and (trim(TmpGameList[i].GameDate) = trim(GameList_Old[j].GameDate))
        and (trim(TmpGameList[i].GameTime) = trim(GameList_Old[j].GameTime))
      then
      begin
        IsExists:=True;
        //有變化
        if (TmpGameList[i].Spread1 <> GameList_Old[j].Spread1)
          or (TmpGameList[i].Spread2 <> GameList_Old[j].Spread2)
          or (TmpGameList[i].Total_Over <> GameList_Old[j].Total_Over)
          or (TmpGameList[i].Total_Under <> GameList_Old[j].Total_Under)
        then
        begin
          asg_basketball_scanresult.Cells[0, asg_basketball_scanresult.RowCount]:=TmpGameList[i].LeagueName;
          asg_basketball_scanresult.Cells[1, asg_basketball_scanresult.RowCount]:=TmpGameList[i].HomeTeam;
          asg_basketball_scanresult.Cells[2, asg_basketball_scanresult.RowCount]:=TmpGameList[i].VisitTeam;
          asg_basketball_scanresult.Cells[3, asg_basketball_scanresult.RowCount]:=GameList_Old[j].Spread1;
          asg_basketball_scanresult.Cells[4, asg_basketball_scanresult.RowCount]:=TmpGameList[i].Spread1;
          asg_basketball_scanresult.Cells[5, asg_basketball_scanresult.RowCount]:=GameList_Old[j].Total_Over;
          asg_basketball_scanresult.Cells[6, asg_basketball_scanresult.RowCount]:=TmpGameList[i].Total_Over;
          asg_basketball_scanresult.Cells[7, asg_basketball_scanresult.RowCount]:=formatdatetime('hh:nn', now);
          //讓分有變化
          if (TmpGameList[i].Spread1 <> GameList_Old[j].Spread1) or (TmpGameList[i].Spread2 <> GameList_Old[j].Spread2) then
          begin
            asg_basketball_scanresult.Colors[3, asg_basketball_scanresult.RowCount]:=clYellow;
            asg_basketball_scanresult.Colors[4, asg_basketball_scanresult.RowCount]:=clYellow;
          end;
          //總分有變化
          if (TmpGameList[i].Total_Over <> GameList_Old[j].Total_Over) or (TmpGameList[i].Total_Under <> GameList_Old[j].Total_Under) then
          begin
            asg_basketball_scanresult.Colors[5, asg_basketball_scanresult.RowCount]:=clMoneyGreen;
            asg_basketball_scanresult.Colors[6, asg_basketball_scanresult.RowCount]:=clMoneyGreen;
          end;
          mmo_basketball_message.Lines.Add('***************************************************************************************************************************************************************************************************************************');
          mmo_basketball_message.Lines.Add('掃描結果(有不同): '+TmpGameList[i].LeagueName+', '+TmpGameList[i].HomeTeam+' vs '+TmpGameList[i].VisitTeam+' [讓分1: '+GameList_Old[j].Spread1+' => '+TmpGameList[i].Spread1+'] [讓分2: '+GameList_Old[j].Spread2+' => '+TmpGameList[i].Spread2+'] [總分高: '+GameList_Old[j].Total_Over+' => '+TmpGameList[i].Total_Over+'] [總分低: '+GameList_Old[j].Total_Under+' => '+TmpGameList[i].Total_Under+']');
          mmo_basketball_message.Lines.Add('***************************************************************************************************************************************************************************************************************************');
          asg_basketball_scanresult.RowCount:=asg_basketball_scanresult.RowCount + 1;
          IsChanged:=true;
        end
        //盤口相同
        else
        begin
          mmo_basketball_message.Lines.Add('-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------');
          mmo_basketball_message.Lines.Add('掃描結果(相同): '+TmpGameList[i].LeagueName+', '+TmpGameList[i].HomeTeam+' vs '+TmpGameList[i].VisitTeam+' [讓分1: '+GameList_Old[j].Spread1+' => '+TmpGameList[i].Spread1+'] [讓分2: '+GameList_Old[j].Spread2+' => '+TmpGameList[i].Spread2+'] [總分高: '+GameList_Old[j].Total_Over+' => '+TmpGameList[i].Total_Over+'] [總分低: '+GameList_Old[j].Total_Under+' => '+TmpGameList[i].Total_Under+']');
          mmo_basketball_message.Lines.Add('-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------');
        end;
      end;
    end;
    //如果賽事不存在GameList_Old
    if not IsExists then
    begin
      asg_basketball_scanresult.Cells[0, asg_basketball_scanresult.RowCount]:=TmpGameList[i].LeagueName;
      asg_basketball_scanresult.Cells[1, asg_basketball_scanresult.RowCount]:=TmpGameList[i].HomeTeam;
      asg_basketball_scanresult.Cells[2, asg_basketball_scanresult.RowCount]:=TmpGameList[i].VisitTeam;
      asg_basketball_scanresult.Cells[3, asg_basketball_scanresult.RowCount]:='';
      asg_basketball_scanresult.Cells[4, asg_basketball_scanresult.RowCount]:=TmpGameList[i].Spread1;
      asg_basketball_scanresult.Cells[5, asg_basketball_scanresult.RowCount]:='';
      asg_basketball_scanresult.Cells[6, asg_basketball_scanresult.RowCount]:=TmpGameList[i].Total_Over;
      asg_basketball_scanresult.Cells[7, asg_basketball_scanresult.RowCount]:=formatdatetime('hh:nn', now);
      asg_basketball_scanresult.RowCount:=asg_basketball_scanresult.RowCount + 1;
    end;
  end;
  //設定資料的位置
  for i := 1 to asg_basketball_scanresult.RowCount - 1 do
  begin
    //聯盟
    asg_basketball_scanresult.Alignments[0, i]:=taLeftJustify;
    //主隊
    asg_basketball_scanresult.Alignments[1, i]:=taLeftJustify;
    //客隊
    asg_basketball_scanresult.Alignments[2, i]:=taLeftJustify;
    //舊讓分
    asg_basketball_scanresult.Alignments[3, i]:=taLeftJustify;
    //新讓分
    asg_basketball_scanresult.Alignments[4, i]:=taLeftJustify;
    //舊總分
    asg_basketball_scanresult.Alignments[5, i]:=taLeftJustify;
    //新總分
    asg_basketball_scanresult.Alignments[6, i]:=taLeftJustify;
    //掃描時間
    asg_basketball_scanresult.Alignments[7, i]:=taRightJustify;
  end;
  if IsChanged then
  begin
    if cb_sound.Checked then
    begin
      sndPlaySound('sound.wav', SND_ASYNC);
    end;
    lbl_message.Font.Color:=clRed;
    lbl_message.Caption:='盤口有變化，請注意 !!';
  end
  else
  begin
    //lbl_message.Font.Color:=clBlack;
    //lbl_message.Caption:='盤口沒有變化 !!';
  end;
end;

procedure TForm1.cb_selectallClick(Sender: TObject);
begin
  if cb_selectall.Checked then
  begin
    clb_league.CheckAll(cbChecked);
  end
  else
  begin
    clb_league.CheckAll(cbUnChecked);
  end;
  getSelectedLeagueList;
end;

function TForm1.ExtractDomain(URL:String):String;
begin
  Result := LowerCase(URL);
  if (Pos('https://', Result) = 0) and (Pos('http://', Result) = 0) then
  Result := URL else
  if Pos('https://', URL) > 0 then
  Result := Copy(URL,1,PosEx('/', URL, 9)) else
  Result := Copy(URL, 1, PosEx('/', URL, 8));
  //here is needed to check about the www.
  if Pos('www.', Result) = 0 then
  begin
    //no have, is needed to remove the subdomain between "http://" or "https://" and .domain and put the www.
  end;
end;

procedure TForm1.chk_game_refreshClick(Sender: TObject);
begin
  if chk_game_refresh.Checked then
  begin
    tmr_game_refresh.Enabled:=True;
  end
  else
  begin
    tmr_game_refresh.Enabled:=false;
    CrashCount:=0;
  end;
end;

procedure TForm1.writeOddsMessage(Content:WideString);
begin
  mmo_basketball_message.Lines.Add('['+formatdatetime('yyyy-mm-dd hh:nn:ss.zzz',Now)+'] '+Trim(Content));
end;

procedure TForm1.btn_clearClick(Sender: TObject);
begin
  asg_basketball_scanresult.ClearRows(1, asg_basketball_scanresult.RowCount -1);
  asg_basketball_scanresult.RowCount:=1;
end;

procedure TForm1.btn_getgamesClick(Sender: TObject);
begin
  screen.Cursor:=crHourGlass;
  application.ProcessMessages;
  chrm_basketball.Browser.StopLoad;
  clb_league.Clear;
  LeagueList.Clear;
  GameList.Clear;
  IsGetLeagues:=True;
  IsRunning:=True;
  chrm_basketball.Load('about:blank');
  chrm_basketball.Load(Basketball.HomeURL);
end;

procedure TForm1.Button1Click(Sender: TObject);
var
  i:integer;
begin
  mmo_basketball_message.Lines.Add('=====================================================================================');
  for i := 0 to SelectedLeagueList.Count - 1 do
  begin
    mmo_basketball_message.Lines.Add(SelectedLeagueList[i].Name);
  end;
  mmo_basketball_message.Lines.Add('被鎖定的聯明共有'+inttostr(SelectedLeagueList.Count)+'筆');
  mmo_basketball_message.Lines.Add('=====================================================================================');
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
  mmo_basketball_message.Clear;
  mmo_basketball_error.Clear;
end;

procedure TForm1.Button3Click(Sender: TObject);
begin
  if cb_sound.Checked then
    sndPlaySound('sound.wav', SND_ASYNC)
  else
    showmessage('請勾選發出警告聲 !');
end;

procedure TForm1.BitBtn1Click(Sender: TObject);
var
  IsDeleted:Boolean;
begin
  if savedialog1.Execute then
  begin
    IsDeleted:=True;
    if fileexists(savedialog1.FileName) then
    begin
      if not deletefile(savedialog1.FileName) then
      begin
        IsDeleted:=False;
        messagedlg('無法將舊檔('+savedialog1.FileName+')刪除 !!', mterror, [mbok], 0);
      end;
    end;
    if IsDeleted then
    begin
      if ageio_savetoexcel.XLSExport(savedialog1.FileName) then
      begin
        showmessage('匯出Excel成功 !!');
      end
      else
      begin
        messagedlg('匯出Excel失敗 !', mterror, [mbok], 0);
      end;
    end;
  end;
end;

procedure TForm1.btn_basketball_runClick(Sender: TObject);
begin
  if (IsGetLeagues = False) and (IsRunning = False) then
  begin
    if (SelectedLeagueList.Count > 0) or (clb_league.Count = 0) then
    begin
      Screen.Cursor := crHourGlass;
      Application.ProcessMessages;
      chrm_basketball.Load('about:blank');
      chrm_basketball.Load(basketball.HomeURL);
    end
    else
    begin
      lbl_message.Font.Color:=clRed;
      lbl_message.Caption:='請選擇要鎖定的聯盟 !!';
      clb_league.SetFocus;
    end;
  end;
end;

procedure TForm1.chrm_basketballAddressChange(Sender: TObject;
  const browser: ICefBrowser; const frame: ICefFrame; const url: ustring);
begin
  lbledt_basketball_url.Text:=url;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  LeagueList:=TList<TLeague>.Create;
  SelectedLeagueList:=TList<TLeague>.Create;
  GameList:=TList<TGame>.Create;
  GameList_Old:=TList<TGame>.Create;
  //籃球賽事
  Basketball.Name:='basketball';
  Basketball.CName:='籃球';
  Basketball.HomeURL:='https://mobile.bet365.com/?#type=Splash;key=18;ip=0;lng=2';
  asg_basketball_scanresult.RowCount:=1;
end;

procedure TForm1.chrm_basketballLoadEnd(Sender: TObject; const browser: ICefBrowser;
  const frame: ICefFrame; httpStatusCode: Integer);
var EndTime: TTime;
begin
  //聯盟列表
  if AnsiContainsText(frame.Url, 'https://mobile.bet365.com/?#type=Splash;key=18;ip=0;lng=2') then
  begin
    lbl_message.Font.Color:=clBlack;
    lbl_message.Caption:='正在载入聯盟列表......';
    EndTime := IncSecond(Now, 2);
    repeat Application.ProcessMessages until (Now > EndTime);
    browser.MainFrame.GetSourceProc(getBasketballLeagueList);
  end
  //賽事及盤口列表
  else if AnsiContainsStr(frame.Url, 'https://mobile.bet365.com/?#type=Coupon') then
  begin
    lbl_message.Font.Color:=clBlack;
    lbl_message.Caption:='正在载入賽事列表......';
    EndTime := IncSecond(Now, 2);
    repeat Application.ProcessMessages until (Now > EndTime);
    browser.MainFrame.GetSourceProc(getBasketballGameList);
  end;
end;

procedure TForm1.chrm_basketballLoadError(Sender: TObject; const browser: ICefBrowser;
  const frame: ICefFrame; errorCode: Integer; const errorText,
  failedUrl: ustring);
begin
  mmo_basketball_error.Lines.Add('['+formatdatetime('yyyy-mm-dd hh:nn:ss.zzz',Now)+'] '+'LoadError errorCode = '+inttostr(errorCode)+', errorText = '+errorText+', failedUrl = '+failedUrl);
end;

procedure TForm1.chrm_tmpLoadEnd(Sender: TObject; const browser: ICefBrowser;
  const frame: ICefFrame; httpStatusCode: Integer);
var EndTime:TTime;
begin
  EndTime := IncSecond(Now, 2);
  repeat Application.ProcessMessages until (Now > EndTime);
  //聯盟列表
  if AnsiContainsText(frame.Url, 'https://mobile.bet365.com/?#type=Splash;key=18;ip=0;lng=2') then
  begin
    lbl_message.Font.Color:=clBlack;
    lbl_message.Caption:='更新聯盟列表......';
    browser.MainFrame.GetSourceProc(refreshBasketballLeagueList);
  end
end;

procedure TForm1.clb_leagueClickCheck(Sender: TObject);
begin
  if (IsGetLeagues = False) and (IsRunning = False) then
  begin
    //取得鎖定的聯盟
    getSelectedLeagueList;
  end
  else
  begin
    //賽事執行中，讓checkbox無效
    with TCheckListBox(Sender) do
    begin
      checked[ItemIndex]:=not checked[ItemIndex];
      lbl_message.Font.Color:=clRed;
      lbl_message.Caption:='正在掃描中，無法設定鎖定賽事，請等掃描結束後再設定 !';
    end;
  end;
end;

procedure TForm1.refreshBasketballLeagueList(const str:ustring);
var
  Document:IHTMLDocument2;
  Body:IHTMLElement2;
  Tags,EC_League:IHTMLElementCollection;
  Tag,Tmp,E_League:IHTMLElement;
  i,j:integer;
  v:Variant;
  League:TLeague;
  IsSelectedExists:Boolean;
  LeagueList_Old,LeagueList_New:TStrings;
  LeagueMessage:string;
begin
  //取得所有聯盟资料
  try
    CurrentRunTime:=Now();
    LeagueList.Clear;
    Document:=CreateComObject(Class_HTMLDOcument) as IHTMLDocument2;
    Document.designMode:='on';
    while Document.readyState <> 'complete' do Application.ProcessMessages;
    v:=VarArrayCreate([0, 0], varVariant);
    v[0]:=str;
    Document.write(PSafeArray(TVarData(v).VArray));
    Document.designMode:='off';
    while Document.readyState <> 'complete' do Application.ProcessMessages;
    Body:=Document.body as IHTMLElement2;
    Tags:=Body.getElementsByTagName('div');
    if Tags.length > 0 then
    begin
      for i:=0 to Pred(Tags.length) do
      begin
        Tag := Tags.item(i, EmptyParam) as IHTMLElement;
        //取得籃球聯列表元素
        if AnsiSameText(Tag.id, 'SplashContent') then
        begin
          EC_League:=(Tag.children as IHTMLElementCollection);
          for j := 0 to Pred(EC_League.length) do
          begin
            E_League:=EC_League.item(j, EmptyParam) as IHTMLElement;
            League.SportsKey:=getGameSportKey(trim(E_League.getAttribute('data-sportskey', 0)));
            Tmp:=((E_League.children as IHTMLElementCollection).item(0, 0)) as IHTMLElement;
            League.Name:=trim(Tmp.innerText);
            League.GamesURL:=ExtractDomain(chrm_basketball.Browser.MainFrame.Url)+'?#type=Coupon;key='+League.SportsKey+';ip=0;lng=2;anim=1';
            LeagueList.Add(League);
          end;
        end;
      end;
    end
  finally
    Document:=nil;
    Body:=nil;
    Tags:=nil;
    Tag:=nil;
    E_League:=nil;
    EC_League:=nil;
    Tmp:=nil;
    lbl_league.Caption:='鎖定聯盟('+inttostr(LeagueList.Count)+' '+FormatDateTime('hh:nn:ss',now)+')';
    mmo_basketball_message.Lines.Add('============================================================================');
    LeagueList_Old:=TStringList.Create;
    LeagueList_New:=TStringList.Create;
    //儲存原聯盟列表
    for i := 0 to clb_league.Count - 1 do
    begin
      LeagueList_Old.Add(clb_league.Items[i]);
    end;
    //將新聯盟更新到CheckListBox
    clb_league.Clear;
    for i := 0 to LeagueList.Count -1 do
    begin
      clb_league.Items.Add(LeagueList[i].Name);
      mmo_basketball_message.Lines.Add(LeagueList[i].Name+', '+LeagueList[i].GamesURL);
    end;
    mmo_basketball_message.Lines.Add('============================================================================');
    //將新增聯盟放到LeagueList_New
    for i := 0 to LeagueList.Count - 1 do
    begin
      if LeagueList_Old.IndexOf(LeagueList[i].Name) < 0 then
      begin
        LeagueList_New.Add(LeagueList[i].Name);
      end;
    end;
    //有新增的聯盟
    if LeagueList_New.Count > 0 then
    begin
      LeagueMessage:='有新增的聯盟';
      for i := 0 to LeagueList_New.Count - 1 do
      begin
        LeagueMessage:=LeagueMessage+'['+LeagueList_New[i]+'],';
      end;
      LeagueMessage:=copy(LeagueMessage, 1, length(LeagueMessage) - 1);
      lbl_league_message.Caption:=LeagueMessage;
    end;
    //將已鎖定的聯盟鎖定,不存在的聯盟移除
    for i := 0 to SelectedLeagueList.Count - 1 do
    begin
      IsSelectedExists:=False;
      //將已鎖定的聯盟鎖定
      for j := 0 to clb_league.Count - 1 do
      begin
        if trim(clb_league.Items[j]) = trim(SelectedLeagueList[i].Name) then
        begin
          clb_league.State[j]:=cbChecked;
          IsSelectedExists:=True;
        end;
      end;
      //如果被鎖定的聯盟不存在，則刪除鎖定聯盟
      if not IsSelectedExists then
      begin
        mmo_basketball_error.Lines.Add(SelectedLeagueList.Items[i].Name+' ('+inttostr(i)+') 需要刪除');
      end;
    end;
    lbl_message.Font.Color:=clBlack;
    lbl_message.Caption:='總共獲得聯盟數'+inttostr(LeagueList.Count)+'筆';
  end;
end;

//取得籃球聯盟列表並寫入LeagueList
procedure TForm1.getBasketballLeagueList(const str:ustring);
var
  Document:IHTMLDocument2;
  Body:IHTMLElement2;
  Tags,EC_League:IHTMLElementCollection;
  Tag,Tmp,E_League:IHTMLElement;
  i,j:integer;
  v:Variant;
  League:TLeague;
  LeagueList_Old,LeagueList_New,LeagueList_Del:TStrings;
  LeagueMessage:string;
  IsSelectedExists:Boolean;
  SportsKey:string;
  arrKey:TArray<String>;
begin
  //取得所有聯盟资料
  try
    IsRunning:=true;
    Screen.Cursor := crHourGlass;
    Application.ProcessMessages;
    CurrentRunTime:=Now();
    Document:=CreateComObject(Class_HTMLDOcument) as IHTMLDocument2;
    Document.designMode:='on';
    while Document.readyState <> 'complete' do Application.ProcessMessages;
    v:=VarArrayCreate([0, 0], varVariant);
    v[0]:=str;
    Document.write(PSafeArray(TVarData(v).VArray));
    Document.designMode:='off';
    while Document.readyState <> 'complete' do Application.ProcessMessages;
    Body:=Document.body as IHTMLElement2;
    Tags:=Body.getElementsByTagName('div');
    LeagueList.Clear;
    if Tags.length > 0 then
    begin
      for i:=0 to Pred(Tags.length) do
      begin
        Tag := Tags.item(i, EmptyParam) as IHTMLElement;
        //取得籃球聯列表元素
        if AnsiSameText(Tag.id, 'SplashContent') then
        begin
          EC_League:=(Tag.children as IHTMLElementCollection);
          for j := 0 to Pred(EC_League.length) do
          begin
            E_League:=EC_League.item(j, EmptyParam) as IHTMLElement;
            League.SportsKey:=getGameSportKey(trim(E_League.getAttribute('data-sportskey', 0)));
            arrKey:=League.SportsKey.Split(['-']);
            League.SportsKey:='18-'+arrKey[1]+'-48-1453-10-0-0-0-1-0-0-4305-0-0-1-0-0-0-0-0-1454-0-0';
            Tmp:=((E_League.children as IHTMLElementCollection).item(0, 0)) as IHTMLElement;
            League.Name:=trim(Tmp.innerText);
            League.GamesURL:=ExtractDomain(chrm_basketball.Browser.MainFrame.Url)+'?#type=Coupon;key='+League.SportsKey+';ip=0;lng=2;anim=1';
            LeagueList.Add(League);
          end;
        end;
      end;
    end;
  finally
    Document:=nil;
    Body:=nil;
    Tags:=nil;
    Tag:=nil;
    E_League:=nil;
    EC_League:=nil;
    Tmp:=nil;
    //沒有取得聯盟資料，重新載入聯盟頁面
    if LeagueList.Count <= 0 then
    begin
      chrm_basketball.Load('about:blank');
      chrm_basketball.Load(basketball.HomeURL);
    end
    //有取得聯盟資料
    else
    begin
      LeagueList_Old:=TStringList.Create;
      LeagueList_New:=TStringList.Create;
      LeagueList_Del:=TStringList.Create;
      lbl_league.Caption:='鎖定聯盟('+inttostr(LeagueList.Count)+')';
      mmo_basketball_message.Lines.Add('============================================================================');
      //聯盟資料已經存在了
      if clb_league.Count > 0 then
      begin
        //儲存原聯盟列表
        for i := 0 to clb_league.Count - 1 do
        begin
          LeagueList_Old.Add(clb_league.Items[i]);
        end;
        //將聯盟更新到CheckListBox
        clb_league.Clear;
        for i := 0 to LeagueList.Count -1 do
        begin
          clb_league.Items.Add(LeagueList[i].Name);
          mmo_basketball_message.Lines.Add(LeagueList[i].Name+', '+LeagueList[i].GamesURL);
        end;
        //將新增的聯盟放到LeagueList_New
        for i := 0 to LeagueList.Count - 1 do
        begin
          if LeagueList_Old.IndexOf(LeagueList[i].Name) < 0 then
          begin
            LeagueList_New.Add(LeagueList[i].Name);
            SelectedLeagueList.Add(LeagueList[i]);
          end;
        end;
        //有新增的聯盟
        if LeagueList_New.Count > 0 then
        begin
          LeagueMessage:='有新增的聯盟';
          for i := 0 to LeagueList_New.Count - 1 do
          begin
            LeagueMessage:=LeagueMessage+'['+LeagueList_New[i]+'],';
          end;
          LeagueMessage:=copy(LeagueMessage, 1, length(LeagueMessage) - 1);
          lbl_league_message.Caption:=LeagueMessage;
        end;
        //將已鎖定的聯盟鎖定
        for i := 0 to SelectedLeagueList.Count - 1 do
        begin
          for j := 0 to clb_league.Count - 1 do
          begin
            if trim(clb_league.Items[j]) = trim(SelectedLeagueList[i].Name) then
            begin
              clb_league.State[j]:=cbChecked;
            end;
          end;
        end;
        //取得已不存在的聯盟列表
        for i := 0 to SelectedLeagueList.Count -1 do
        begin
          if clb_league.Items.IndexOf(SelectedLeagueList[i].Name) < 0 then
          begin
            LeagueList_Del.Add(SelectedLeagueList[i].Name);
          end;
        end;
        //刪除不存在的聯盟
        for i := 0 to LeagueList_Del.Count - 1 do
        begin
          j:=0;
          while j <= SelectedLeagueList.Count - 1 do
          begin
            if SelectedLeagueList[j].Name = LeagueList_Del[i] then
            begin
              mmo_basketball_error.Lines.Add(LeagueList_Del[i]+'('+inttostr(j)+'/'+inttostr(SelectedLeagueList.Count-1)+') 已不存在鎖定的聯盟列表');
              SelectedLeagueList.Delete(j);
            end
            else
            begin
              inc(j);
            end;
          end;
        end;
        LeagueIndex:=0;
        chrm_basketball.Load('about:blank');
        chrm_basketball.Load(SelectedLeagueList[LeagueIndex].GamesURL);
      end
      //第一次取得聯盟資料
      else
      begin
        for i := 0 to LeagueList.Count -1 do
        begin
          clb_league.Items.Add(LeagueList[i].Name);
          mmo_basketball_message.Lines.Add(LeagueList[i].Name+', '+LeagueList[i].GamesURL);
        end;
        screen.Cursor:=crDefault;
        application.ProcessMessages;
        IsRunning:=False;
        IsGetLeagues:=False;
      end;
      mmo_basketball_message.Lines.Add('============================================================================');
      lbl_message.Font.Color:=clBlack;
      lbl_message.Caption:='總共獲得聯盟數'+inttostr(LeagueList.Count)+'筆';
    end;
  end;
end;

//取得籃球賽事列表並寫入GameList
procedure TForm1.getBasketballGameList(const str:ustring);
var
  Document:IHTMLDocument2;
  Body:IHTMLElement2;
  Tags,Games:IHTMLElementCollection;
  Tag,Tmp,GameElement,OddsElement,SpreadElement1,SpreadElement2:IHTMLElement;
  i,j:integer;
  v:Variant;
  Game:TGame;
  GameDate:string;
  TmpGameList:TList<TGame>;
  TotalGameList:TList<TGame>;
begin
  //取得聯盟中所有赛事资料
  try
    IsRunning:=true;
    TmpGameList:=TList<TGame>.Create;
    TotalGameList:=TList<TGame>.Create;
    Document:=CreateComObject(Class_HTMLDOcument) as IHTMLDocument2;
    Document.designMode:='on';
    while Document.readyState <> 'complete' do Application.ProcessMessages;
    v:=VarArrayCreate([0, 0], varVariant);
    v[0]:=str;
    Document.write(PSafeArray(TVarData(v).VArray));
    Document.designMode:='off';
    while Document.readyState <> 'complete' do Application.ProcessMessages;
    Body:=Document.body as IHTMLElement2;
    Tags:=Body.getElementsByTagName('div');
    if Tags.length > 0 then
    begin
      for i:=0 to Pred(Tags.length) do
      begin
        Tag := Tags.item(i, EmptyParam) as IHTMLElement;
        //取得賽事列表元素
        if AnsiSameText(Tag._className, 'enhancedPod tabbed cc_12_7') then
        begin
          //將全部賽事中的各個賽事取出
          Games:=(Tag.children as IHTMLElementCollection);
          for j := 0 to Pred(Games.length) do
          begin
            Tmp:=Games.item(j, EmptyParam) as IHTMLElement;
            //日期
            if AnsiContainsText(Tmp._className, 'podHeaderRow') then
            begin
              GameDate:=trim(((((Tag.children as IHTMLElementCollection).item(0, 0) as IHTMLElement).children as IHTMLElementCollection).item(0, 0) as IHTMLElement).innerText);
            end
            //盤口資料
            else if AnsiContainsText(Tmp._className, 'podEventRow') then
            begin
              Game.GameDate:=GameDate;
              //讓分
              if AnsiSameText(Tmp.getAttribute('data-plbtid', 0), '1453') then
              begin
                Game.LeagueName:=SelectedLeagueList[LeagueIndex].Name;
                Game.GameID:=trim(Tmp.getAttribute('data-parentfixtureid', 0));
                GameElement:=(Tmp.children as IHTMLElementCollection).item(0, 0) as IHTMLElement;
                OddsElement:=(Tmp.children as IHTMLElementCollection).item(1, 0) as IHTMLElement;
                Tmp:=(GameElement.children as IHTMLElementCollection).item(0, 0) as IHTMLElement;
                Game.HomeTeam:=trim(((Tmp.children as IHTMLElementCollection).item(0, 0) as IHTMLElement).innerText);
                Game.VisitTeam:=trim(((Tmp.children as IHTMLElementCollection).item(1, 0) as IHTMLElement).innerText);
                Game.GameTime:=trim(((((Tmp.children as IHTMLElementCollection).item(2, 0) as IHTMLElement).children as IHTMLElementCollection).item(0, 0) as IHTMLElement).innerText);
                SpreadElement1:=(OddsElement.children as IHTMLElementCollection).item(0, 0) as IHTMLElement;
                SpreadElement2:=(OddsElement.children as IHTMLElementCollection).item(1, 0) as IHTMLElement;
                Game.Spread1:=trim(((SpreadElement1.children as IHTMLElementCollection).item(0, 0) as IHTMLElement).innerText);
                Game.Spread2:=trim(((SpreadElement1.children as IHTMLElementCollection).item(1, 0) as IHTMLElement).innerText);
                TmpGameList.Add(Game);
              end
              //總分
              else if AnsiSameText(Tmp.getAttribute('data-plbtid', 0), '1454') then
              begin
                Game.GameID:=trim(Tmp.getAttribute('data-parentfixtureid', 0));
                Tmp:=(Tmp.children as IHTMLElementCollection).item(1, 0) as IHTMLElement;
                Tmp:=(Tmp.children as IHTMLElementCollection).item(0, 0) as IHTMLElement;
                Game.Total_Over:=trim(((Tmp.children as IHTMLElementCollection).item(0, 0) as IHTMLElement).innerText);
                Game.Total_Under:=trim(((Tmp.children as IHTMLElementCollection).item(1, 0) as IHTMLElement).innerText);
                TotalGameList.Add(Game);
              end;
            end;
          end;
        end;
      end;
    end;
  finally
    //有掃到賽事
    if TmpGameList.Count > 0 then
    begin
      //將總得分資料寫到TmpGameList
      putTotalData(TmpGameList,TotalGameList);
      //排除走地及無盤口
      i:=0;
      while i <= TmpGameList.Count - 1 do
      begin
        if (AnsiContainsText(TmpGameList[i].GameTime,'第')
          or (
            trim(TmpGameList[i].Spread1) = '')
            and (trim(TmpGameList[i].Spread2) = '')
            and (trim(TmpGameList[i].Total_Over) = '')
            and (trim(TmpGameList[i].Total_Under) = '')
          )
        then
        begin
          tmpGameList.Delete(i);
        end
        else
        begin
          inc(i);
        end;
      end;
      //將TmpGameList寫到GameList
      for i := 0 to TmpGameList.Count - 1 do
      begin
        GameList.Add(TmpGameList[i]);
      end;
      //跟GameListOld比對
      doCompareGame(TmpGameList);
    end
    //沒有掃到賽事
    else
    begin
      //將GameList_Old寫回GameList
      for i := 0 to GameList_Old.Count - 1 do
      begin
        if trim(GameList_Old[i].LeagueName) = trim(SelectedLeagueList[LeagueIndex].Name) then
        begin
          GameList.Add(GameList_Old[i]);
        end;
      end;
    end;
    lbl_message.Font.Color:=clBlack;
    lbl_message.Caption:='賽事聯盟['+SelectedLeagueList[LeagueIndex].Name+']共有賽事'+inttostr(TmpGameList.Count)+'筆 ('+inttostr(LeagueIndex + 1)+'/'+inttostr(SelectedLeagueList.Count)+')';
    //寫到訊息記錄
    for i := 0 to TmpGameList.Count - 1 do
    begin
      mmo_basketball_message.Lines.Add(
        TmpGameList[i].LeagueName+', '+
        TmpGameList[i].GameDate+', '+
        TmpGameList[i].GameTime+', '+
        TmpGameList[i].GameID+', '+
        TmpGameList[i].HomeTeam+', '+
        TmpGameList[i].VisitTeam+', '+
        TmpGameList[i].Spread1+', '+
        TmpGameList[i].Spread2+', '+
        TmpGameList[i].Total_Over+', '+
        TmpGameList[i].Total_Under
      );
    end;
    inc(LeagueIndex);
    //鎖定賽事仍有聯盟賽事
    if LeagueIndex <= SelectedLeagueList.Count -1 then
    begin
      Document:=nil;
      Body:=nil;
      Tags:=nil;
      Tag:=nil;
      TmpGameList.Destroy;
      TotalGameList.Destroy;
      chrm_basketball.Load('about:blank');
      chrm_basketball.Load(SelectedLeagueList[LeagueIndex].GamesURL);
      //chrm_basketball.Browser.Reload;
    end
    //所有鎖定都賽事都已掃描完畢，回頁首
    else
    begin
      //將賽事資料複制到SelectedGameList_Old
      CopyToSelectedGameList_Old(GameList);
      GameList.Clear;
      IsRunning:=False;
      IsGetLeagues:=False;
      Document:=nil;
      Body:=nil;
      Tags:=nil;
      Tag:=nil;
      TmpGameList.Destroy;
      TotalGameList.Destroy;
      Screen.Cursor:=crDefault;
      Application.ProcessMessages;
      chrm_basketball.Load(HomeURL);
    end;
  end;
end;

procedure TForm1.tmr_game_refreshTimer(Sender: TObject);
var
  myTime:TDateTime;
begin
  //倒數時間未到
  if lbl_game_countdown.Caption <> '00:00:00' then
  begin
    myTime:=StrToTime(lbl_game_countdown.Caption);
    myTime:=IncSecond(myTime, -1);
    Form1.Refresh;
  end
  //倒數時間已到
  else
  begin
    btn_basketball_run.Click;
    myTime:=StrToTime(lbl_game_countdown.Caption);
    myTime:=IncSecond(myTime, se_game_update_interval.Value);
  end;
  lbl_game_countdown.Caption:=FormatDateTime('hh:nn:ss',myTime);
  lbl_game_countdown.Refresh;
end;

procedure TForm1.tmr_odds_checkcrashTimer(Sender: TObject);
begin
  {if chk_game_refresh.Checked then
  begin
    if CurrentRunTime = LastRumTime then
    begin
      if CrashCount >= 5 then
      begin
        //ShowMessage('Restart Application');
        ShellExecute(Handle, nil, PChar(Application.ExeName), nil, nil, SW_SHOWNORMAL);
        Application.Terminate;
      end
      else
      begin
        inc(CrashCount);
      end;
    end
    else
    begin
      LastRumTime:=CurrentRunTime;
      CrashCount:=0;
    end;
  end;}
end;

procedure TForm1.lbledt_basketball_urlKeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #13 then
  begin
    chrm_basketball.Load(lbledt_basketball_url.Text);
  end;
end;

function TForm1.ConvertToFloat(str:string):Real;
begin
  if (str = '') or (str = Null) then
    Result:=0
  else
    Result:=StrToFloat(str);
end;

end.
