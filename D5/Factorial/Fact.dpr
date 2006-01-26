program Fact;

uses
  Forms,
  ConsoleForm,
  FT in 'FT.pas';

{$R *.RES}

begin
  Application.Initialize;
  Application.CreateForm(TConsoleMainForm, ConsoleMainForm);
  Application.Run;
end.
