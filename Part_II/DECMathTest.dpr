program DECMathTest;

{$APPTYPE CONSOLE}

{$IFnDEF WIN32}
  {$MESSAGE Error 'only for 32 bits'}
{$ENDIF}

uses
  {$IFDEF VER150}
    SysUtils,
    {ASN1, Console, ConsoleForm, CPU, CRC,
    DECCipher, DECData, DECFmt, DECHash, DECRandom, DECUtil,
    IDPrimes, IsPrimeHRUnit, LHSZ, NCombi, NGFPBld, NGFPs, NGFPTab,
    NIntM,} NInts {NInt_1, NMath, NPolys, NRats, Prime};
  {$ELSE}
    SysUtils,
    DECMath;
  {$ENDIF}

{$R *.res}

procedure Test;
var
  a, b, c, soll, z, sub: IInteger;
  start: TDateTime;
  duration: Double;
  nad, nsu: Int64;
  nn: Integer;
begin
  WriteLn;
  WriteLn('calc...');

  NSet(a,    '170141183460469231731687303715884105757');
  NSet(b,    '170141183460469231731687303715884105703');
  NSet(soll, '57896044618658097711785492504343953926634992332820282019728792003956564819968');
  NSet(z,    '340282366920938463463374607431768211455');
  NSet(sub,  '11111111111111111111111111111111111111111111111111111111111111111111111111111');

  nad   := 0;
  nsu   := 0;
  start := Now;
  for nn := 0 to 25000000 do begin
    NMul(c, a, b);
    while NCmp(c, soll) < 0 do begin
      NAdd(c, c, sub);
      Inc(nad);
    end;
    while NCmp(c, soll) > 0 do begin
      NSub(c, c, sub);
      Inc(nsu);
    end;
    NShr(a, c, 128);
    NAnd(b, c, z);
  end;
  duration := (Now - start) * SecsPerDay;

  WriteLn('c0=', NStr(c));
  WriteLn('ad=', nad, ' su=', nsu, ' in ', duration:1:8, ' sec');
  WriteLn;
  WriteLn('Press ENTER to end program');
  ReadLn;
end;

begin
  try
    Test;
  except
    on E: Exception do begin
      WriteLn(E.ClassName, ': ', E.Message);
      WriteLn('Press ENTER to end program');
      ReadLn;
    end;
  end;
end.

