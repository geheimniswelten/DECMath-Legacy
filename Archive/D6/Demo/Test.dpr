program Test;

uses
  Forms,
  ConsoleForm,
  TestUnit in 'TestUnit.pas',
  SRP in 'SRP.pas';

{$R *.RES}
begin
  Application.Initialize;
  Application.CreateForm(TConsoleMainForm, ConsoleMainForm);
  Application.Run;
end.
