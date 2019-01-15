unit Unit1;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, Vcl.Forms, Vcl.StdCtrls,
  Vcl.Controls;

type
  TForm1 = class(TForm)
    Button1: TButton;
    Label1: TLabel;
    procedure Button1Click(Sender: TObject);
    procedure check_install;
    procedure FormShow(Sender: TObject);
  private

    { Private declarations }
  public

    { Public declarations }
  end;

var
  Form1: TForm1;
  install:bool;

implementation

{$R *.dfm}

function GetDosOutput(CommandLine: string; Work: string = 'C:\' ): string;
var
  SA: TSecurityAttributes;
  SI: TStartupInfo;
  PI: TProcessInformation;
  StdOutPipeRead, StdOutPipeWrite: THandle;
  WasOK: Boolean;
  Buffer: array [0..255] of AnsiChar;
  BytesRead: DWord;
  WorkDir: string;
  Handle: Boolean;
begin
  Result := '';
  with SA do begin
    nLength := SizeOf(SA);
    bInheritHandle := True;
    lpSecurityDescriptor := nil;
  end;
  CreatePipe(StdOutPipeRead, StdOutPipeWrite, @SA, 0);
  try
    with SI do
    begin
      FillChar(SI, SizeOf(SI), 0);
      cb := SizeOf(SI);
      dwFlags := STARTF_USESHOWWINDOW or STARTF_USESTDHANDLES;
      wShowWindow := SW_HIDE;
      hStdInput := GetStdHandle(STD_INPUT_HANDLE); // don't redirect stdin
      hStdOutput := StdOutPipeWrite;
      hStdError := StdOutPipeWrite;
    end;
    WorkDir := Work;
    Handle := CreateProcess(nil, PChar('cmd.exe /C ' + CommandLine),
                            nil, nil, True, 0, nil,
                            PChar(WorkDir), SI, PI);
    CloseHandle(StdOutPipeWrite);
    if Handle then
      try
        repeat
          WasOK := ReadFile(StdOutPipeRead, Buffer, 255, BytesRead, nil);
          if BytesRead > 0 then
          begin
            Buffer[BytesRead] := #0;
            OemToAnsi(Buffer,Buffer);
            Result := Result + string(Buffer);
          end;
        until not WasOK or (BytesRead = 0);
        WaitForSingleObject(PI.hProcess, INFINITE);
      finally
        CloseHandle(PI.hThread);
        CloseHandle(PI.hProcess);
      end;
  finally
    CloseHandle(StdOutPipeRead);
  end;
end;

procedure TForm1.Button1Click(Sender: TObject);
var rStream: TResourceStream;
    windir,appdata,res: string;
begin

  if install=false then begin
    rStream := TResourceStream.Create(hInstance, 'cleanram', RT_RCDATA) ;
    windir:=GetEnvironmentVariable('WINDIR')+'\';
    appdata:=GetEnvironmentVariable('APPDATA')+'\';
    rStream.SaveToFile(windir+'MemoryPurgeStandbyList.exe');
    rStream.CleanupInstance;
    rStream :=TResourceStream.Create(hInstance, 'MemoryPurgeStandbyList', RT_RCDATA);
    rStream.SaveToFile(appdata+'MemoryPurgeStandbyList.xml');
    rStream.Free;
    res:=GetDosOutput('schtasks /create /xml "'+appdata+'MemoryPurgeStandbyList.xml" /tn "MemoryPurgeStandbyList"');
    check_install;
    MessageBox(handle, PChar(res),PChar('Окошечько'), MB_ICONINFORMATION+MB_OK+MB_DEFBUTTON1);
  end else begin
    WinExec(pansichar('cmd /c del %windir%\MemoryPurgeStandbyList.exe /f'), 0);
    WinExec(pansichar('cmd /c del %appdata%\MemoryPurgeStandbyList.xml /f'), 0);
    WinExec(pansichar('cmd /c schtasks /delete /tn MemoryPurgeStandbyList /f'), 0);
    install:=false;
    check_install;
    MessageBox(handle, PChar('Скрипт из планировщика заданий и файлы удалены'),PChar('Окошечько'), MB_ICONINFORMATION+MB_OK+MB_DEFBUTTON1);
  end;

end;

procedure TForm1.check_install;
var file1,file2,res:string;
begin
  Form1.Label1.Caption:='';
  file1:=GetEnvironmentVariable('WINDIR')+'\MemoryPurgeStandbyList.exe';
  file2:=GetEnvironmentVariable('APPDATA')+'\MemoryPurgeStandbyList.xml';
  res:=GetDosOutput('schtasks /query /tn MemoryPurgeStandbyList');
  if ( FileExists(file1) or FileExists(file2) or (Pos('rgeStan',res)>0)) then install:=true;
  if install=true then begin
    Form1.button1.Caption:='Удалить скрипт нахуй';
    Form1.Label1.Caption:='СКРИПТ НЕ УСТАНОВЛЕН';
  end else begin
    Form1.Button1.Caption:='Добавить в планировщик заданий очистку ОЗУ';
    Form1.Label1.Caption:='СКРИПТ УСТАНОВЛЕН';
  end;
end;

procedure TForm1.FormShow(Sender: TObject);
begin
  install:=false;
  check_install;
end;

end.
