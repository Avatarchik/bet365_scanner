program bet365_scanner;

uses
  Vcl.Forms,
  ceflib,
  Unit1 in 'Unit1.pas' {Form1};

{$R *.res}

begin
  CefCache := 'cache';
  CefUserAgent := 'Mozilla/5.0 (Linux; U; Android 4.0.3; ko-kr; LG-L160L Build/IML74K) AppleWebkit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30';
  CefSingleProcess := False;
  if not CefLoadLibDefault then
    Exit;

  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
