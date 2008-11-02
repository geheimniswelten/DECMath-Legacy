{Copyright:      Hagen Reddmann  mailto:HaReddmann@T-Online.de
 Author:         Hagen Reddmann
 Remarks:        public domain
 known Problems: none
 Version:        1.4, Delphi 5
 Description:    different Algortihms to compute the Factorial N! to arbitary value

 Comments:       Thanks to Peter Luchny, my employer :)
                 All below factorial functions are based on the JAVA Sources at
                 http://www.luschny.de/math/factorial/FastFactorialFunctions.htm

                 The math library use for multiplication and squaring the
                 School Method, COMBA, Karatsuba, Toom-Cook-3 and
                 Schönhage/Strassen modular FFT
                   "Schnelle Multiplikation grosser Zahlen"
                   by Arnold Schönhage and Volker Strassen, Computing 7, p. 281-292, 1971.
                 For the Division we use Knuth Normalized Method and Karatsuba Division
                   "Fast Recursive Division"
                   Christoph Burnikel & Joachim Ziegler
                   MPI-I-98-1-022        October 1998
                   Forschungsbericht     Research Report
                   Max Planck Institut für Informatik
                 where a asymmetric splitting method is used without shifts, contrary to above paper.
                 The Square Root use a recursive karatsuba square root with remainder
                   INRIA, "Karatsuba Square Root" by Paul Zimmermann
                   Research Report No 3805, file: RR-3805.ps
                 where we asymmetric split.
                 All above methods works generaly asymmetric each for his own numberrange.

                 The library runs on Intel PC and Windows and is currently NOT portable :(
                 All sources use Delphi-Pascal and assmbler.

 * THIS SOFTWARE IS PROVIDED BY THE AUTHORS ''AS IS'' AND ANY EXPRESS
 * OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHORS OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
 * BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
 * OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
 * EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
}

unit FT;

interface

implementation

uses Math, Windows, SysUtils, IniFiles, ConsoleForm, NMath, NInts, NCombi, Prime;

type
  TFactorial = procedure(var A: IInteger; N: Cardinal; const M: IInteger = nil);

var
  R: IInteger;  // last computed result, as global var make's things easier

procedure DoDisplay;
// display last computed result as decimal String
var
  C: Char;
  S: String;
begin
  Write(#20);
  WriteLn( Ticks:10:0, ' ms, ', NDigitCount(R, NStrFormat.Base, False), ' Digits, CRC = ', IntToHEX(NCRC(R), 8));
  Write(#2, 'do You want to display the number (Y,N):', #0); ReadLn(C);
  Write(#11);
  if UpCase(C) = 'Y' then
  begin
    StartTimer;
    S := NStr(R);
    WriteLn( Ticks:10:0, ' ms for string conversion' );
    WriteLn( S );
  end;
end;

procedure DoShow;
// shows last computed result again, but now we can choose the Numberbase
var
  B: Byte;
  S: String;
begin
  Write(#20);
  Write(#2, 'please input Number Base (2-64):', #0); ReadLn(B);
  StartTimer;
  S := NStr(R, B);
  WriteLn( Ticks:10:0, ' ms for string conversion' );
  WriteLn( S );
end;

resourcestring
  sNToBig = 'N must be 0 <= N < 2^32';
  sKToBig = 'K must be 0 <= K < 2^32';

const
  MaxCardinal = $FFFFFFFF;

procedure DoFactorial(Factorial: TFactorial);
// Wrapper to call the different Factorial procedures
var
  N,Step: Double;
  Mul,I: Integer;
  S: String;
  D,T: Double;
begin
  Write(#20);
  Write(#2, 'Input N (12, 1e5, 2^8) :', #0); N := Abs(Trunc(ReadNumber));
  if N > MaxCardinal then NRaise(@sNtoBig);
  Write(#2, 'Repeat by  (+1000, *2) :', #0); ReadLn(S);
  Step := 0;
  S := Trim(S);
  if S <> '' then
  begin
    Mul := Pos('*', S);
    if Mul > 0 then Delete(S, 1, Mul);
    I := Pos('^', S);
    if I > 0 then Step := Power(StrToFloat(Copy(S, 1, I-1)), StrToFloat(Copy(S, I +1, MaxInt)))
      else Step := StrToFloat(S);
  end else
  begin
    Mul := 0;
    Write(#11#11);
  end;
  WriteLn(#3'compute ',N:10:0,'!'#0, ', press ESC to abort');
  D := 0;
  repeat
    StartTimer;
    Factorial(R, Round(N));
    T := Ticks;
    if Step <> 0 then
    begin
      Write(Round(N):10, '!', T:10:2, ' ms, ', NDigitCount(R):10, ' digits, ', IntToHEX(NCRC(R), 8):12);
      if D <> 0 then Write( T / D:10:2);
      WriteLn;
      D := T;
      if Mul > 0 then N := N * Step
        else N := N + Step;
    end else
    begin
      N := 0;
      DoDisplay;
    end;
  until (N < 1) or (N > MaxCardinal);
end;

// wrappers for the Console Menusystem
procedure Moessner;
begin
  DoFactorial(@NFactorial_Moessner);
end;

procedure Naive;
begin
  DoFactorial(@NFactorial_Naive);
end;

procedure Recursive;
begin
  DoFactorial(@NFactorial_Recursive);
end;

procedure DivideAndConquer;
begin
  DoFactorial(@NFactorial_DivideAndConquer);
end;

procedure FactBinomial;
begin
  DoFactorial(@NFactorial_Binomial);
end;

procedure FactJason_GMP;
begin
  DoFactorial(@NFactorial_Jason_GMP);
end;

procedure Schoenhage;
begin
  DoFactorial(@NFactorial);
end;

type
  TProcN  = procedure(var A: IInteger; N: Cardinal; const M: IInteger = nil);
  TProcNK = procedure(var A: IInteger; N,K: Cardinal; const M: IInteger = nil);

procedure DoN(Proc: TProcN; const Name: String);
var
  N,Step: Double;
  Mul: Integer;
  S: String;
  C,D: Char;
  M: IInteger;
begin
  Write(#20);
  C := #0;
  Write(#2, 'Input N  (12, 1e5, 2^8) :', #0); N := Abs(Trunc(ReadNumber));
  if N > Maxcardinal then NRaise(@sNtoBig);
  Write(#2, 'Repeat by   (+1000, *2) :', #0); ReadLn(S);
  Step := 0;
  S := Trim(S);
  if S <> '' then
  begin
    Mul := Pos('*', S);
    if Mul > 0 then Delete(S, 1, Mul);
    Step := StrToFloat(S);
    Write(#2, 'Display results   (Y/N) :', #0); ReadLn(C);
    if UpCase(C) = 'Y' then
    begin
      Write(#2, 'mod 1e10          (Y/N) :', #0); ReadLn(D);
      if UpCase(D) = 'Y' then NPow(M, 10, 10);
    end;
  end else
  begin
    Mul := 0;
    Write(#11#11);
  end;
  WriteLn(#3'compute ',Name,'(',Round(N),')'#0, ', press ESC to abort');
  repeat
    StartTimer;
    Proc(R, Round(N), M);
    Cycles;
    if Step <> 0 then
    begin
      WriteLn(Round(N):10, Ticks:10:2, ' ms, ', NDigitCount(R):10, ' digits, ', IntToHEX(NCRC(R), 8):12);
      if UpCase(C) = 'Y' then WriteLn(#1, NStr(R), #0);
      if Mul > 0 then N := N * Step
        else N := N + Step;
    end else
    begin
      N := 0;
      DoDisplay;
    end;
  until N < 1;
end;

procedure DoNK(Proc: TProcNK; const Name: String);
var
  N,K,Step: Double;
  Mul: Integer;
  S: String;
  C,D: Char;
  M: IInteger;
  IsPrimorial: Boolean;
begin
  Write(#20);
  C := #0;
  IsPrimorial := @Proc = @NPrimorial;
  if IsPrimorial then
  begin
    Write(#2, 'Input K (12, 1e5, 2^8) :', #0); N := Abs(Trunc(ReadNumber));
    if N > MaxCardinal then NRaise(@sNtoBIG);
    Write(#2, 'Input N                :', #0); K := Abs(Trunc(ReadNumber));
    if K > MaxCardinal then NRaise(@sKtoBIG);
  end else
  begin
    Write(#2, 'Input N (12, 1e5, 2^8) :', #0); N := Abs(Trunc(ReadNumber));
    if N > MaxCardinal then NRaise(@sNtoBIG);
    Write(#2, 'Input K                :', #0); K := Abs(Trunc(ReadNumber));
    if K > MaxCardinal then NRaise(@sKtoBIG);
  end;
  Write(#2, 'Repeat by  (+1000, *2) :', #0); ReadLn(S);
  Step := 0;
  S := Trim(S);
  if S <> '' then
  begin
    Mul := Pos('*', S);
    if Mul > 0 then Delete(S, 1, Mul);
    Step := StrToFloat(S);
    Write(#2, 'Display results  (Y/N) :', #0); ReadLn(C);
    if UpCase(C) = 'Y' then
    begin
      Write(#2, 'mod 1e10         (Y/N) :', #0); ReadLn(D);
      if UpCase(D) = 'Y' then NPow(M, 10, 10);
    end;
  end else
  begin
    Mul := 0;
    Write(#11#11#11);
  end;
  WriteLn(#3'compute ',Name,'(',Round(N),',',Round(K),')'#0, ', press ESC to abort');
  repeat
    StartTimer;
    Proc(R, Round(N), Round(K), M);
    Cycles;
    if Step <> 0 then
    begin
      WriteLn(Round(N):10, Round(K):10, Ticks:10:2, ' ms, ', NDigitCount(R):10, ' digits, ', IntToHEX(NCRC(R), 8):12);
      if UpCase(C) = 'Y' then WriteLn(#1, NStr(R), #0);
      if IsPrimorial then
        if Mul > 0 then N := N * Step
          else N := N + Step
      else
        if Mul > 0 then K := K * Step
          else K := K + Step;
    end else
    begin
      if IsPrimorial then K := 0 else N := 0;
      DoDisplay;
    end;
    if IsPrimorial then
      if (N < 1) or (N > K) then Break else
    else
      if (K < 1) or (K > N) then Break;
  until False;
end;

procedure OddFactorial;
begin
  DoN(@NOddFactorial, 'OddFactorial');
end;

procedure Factorial;
begin
  DoN(@NFactorial, 'Factorial');
end;

procedure Primorial;

  procedure DoPrimorial(var A: IInteger; N: Cardinal; const M: IInteger);
  begin
    NPrimorial(A, 1, N, M);
  end;

begin
  DoN(@DoPrimorial, 'Primorial');
end;

procedure Binomial;
begin
  DoNK(@NBinomial, 'Binomial');
end;

procedure Product;
begin
  DoNK(@NProduct, 'Product');
end;

procedure PrimeProduct;
begin
  DoNK(@NPrimorial, 'Primorial');
end;

procedure Permutation;
begin
  DoNK(@NPermutation, 'Permutation');
end;

procedure Comporial;
begin
  DoN(@NComporial, 'Comporial');
end;

procedure HalfFactorial;
begin
  DoN(@NHalfFactorial, 'HalfFactorial');
end;

procedure HalfComporial;
begin
  DoN(@NHalfComporial, 'HalfComporial');
end;

procedure HalfPrimorial;
begin
  DoN(@NHalfPrimorial, 'HalfPrimorial');
end;

procedure HalfBinomial;
begin
  DoN(@NHalfBinomial, 'HalfBinomial');
end;

procedure SelfTest;
begin
  WriteLn(#20'Selftest of Factorial procedures runs, please wait...');
  NTestCombi;
  WriteLn(#4'all ok :)'#0);
end;

procedure SpeedTest;
var
  A,B: IInteger;
  T1,T2,S1,S2: Double;
  N,I: Cardinal;
  C1,C2: Char;
begin
  Write(#22);
  WriteLn(#4'Karatsuba'#0', '#2'Toom-3'#0', '#3'Schönhage Strassen FFT'#0);
  WriteLn('Bit Size':10, 'Sqr (ms)':10, 'Mul (ms)':10, 'Ratio':8, 'Sqr/Digit':14, 'Mul/Digit':14);
  S1 := 0;
  S2 := 0;
  N := 32;
  repeat
    I := N div 32;
    C1 := #0;
    if I >= NBreakEven(5) then C1 := #4;
    if I >= NBreakEven(6) then C1 := #2;
    if I >= NBreakEven(7) then C1 := #3;
    C2 := #0;
    if I >= NBreakEven(1) then C2 := #4;
    if I >= NBreakEven(2) then C2 := #2;
    if I >= NBreakEven(3) then C2 := #3;
    NRnd(A, N);
    StartTimer;
    NSqr(A);
    T1 := Ticks;
    NRnd(A, N);
    NRnd(B, N);
    StartTimer;
    NMul(A, B);
    Cycles;
    T2 := Ticks;
    WriteLn(#22, N:10, C1, T1:10:4,#0, C2, T2:10:4,#0, T1/T2:8:2, T1 / N * 32:14:6, T2 / N * 32:14:6);
    S1 := S1 + T1;
    S2 := S2 + T2;
    WriteLn( #29, S1 / S2:14:6);
    Inc(N, N);
  until N > 1024 * 1024 * 128;
end;

procedure About;
begin
  WriteLn(#22);
  WriteLn(  '------------------------------------------------');
  WriteLn(#3'Different algorithms to compute the factorial N!');
  WriteLn(  '    and similar functions to arbitary value.'#0);
  WriteLn(  '------------------------------------------------');
  WriteLn;
  WriteLn(  'Copyright : '#2'Hagen Reddmann'#0);
  WriteLn(  'Author    : '#2'Hagen Reddmann, mailto:HaReddman@T-Online.de'#0);
  WriteLn;
  WriteLn(  'Remarks   : public domain');
  WriteLn(  'Version   : 1.6, Delphi 5');
  WriteLn(  'Released  : 9.3.2002');
  WriteLn;
  with TIniFile.Create(ChangeFileExt(ParamStr(0), '.ini')) do
  try
    WriteLn(  'URL       : ', ReadString('Options', 'URL', 'unknown'));
  finally
    Free;
  end;
end;

function NPrd(var A: IInteger; const T: array of Integer; const M: IInteger = nil): Boolean;
var
  I,J,K,L,N: Integer;
  BreakEven: Integer;
  P: IInteger;
  S: array[0..32] of IInteger; // 32 + 1 IInteger for max. range
begin
  BreakEven := NBreakEven(1) * 2;
  J := 0;
  K := 0;
  N := 0;
  NSet(P, 1);
  for I := Low(T) to High(T) do
    if T[I] > 0 then
    begin
      NMul(P, T[I]);
      if M <> nil then NMod(P, M);
      if NSize(P, piLong) >= BreakEven then
      begin
        if M <> nil then NMod(P, M);
        NSwp(P, S[J]);
        Inc(J);
        Inc(K);
        L := K;
        while L and 1 = 0 do
        begin
          Dec(J);
          NMul(S[J -1], S[J]);
          if M <> nil then NMod(S[J -1], M);
          L := L shr 1;
        end;
        NSet(P, 1);
      end;
      Inc(N);
    end;
  if M <> nil then NMod(P, M);
  NSwp(S[J], P);
  while J > 0 do
  begin
    NMul(S[J -1], S[J]);
    if M <> nil then NMod(S[J -1], M);
    Dec(J);
  end;
  NSwp(S[0], A);
  Result := N > 0;
end;


procedure NLuschny_Factorial(var A: IInteger; N: Cardinal);

  function omegaSwingHighBound(N: Integer): Integer;
  begin
    if n < 4 then Result := 6
      else Result := Floor(Sqrt(N) + N / (Log2(n) -1));
  end;

var
  listLength: array of Integer;
  listPrime: array of array of Integer;
  tower: array of Integer;
  bound: array of Integer;

  procedure PrimeFactors(N: Integer);
  var
    maxBound, lastList, start, list, prime, i, np, k, q: Integer;
    sieve: TSmallPrimeSieve;
  begin
    maxBound := N div 3;
    lastList := Length(listPrime) -1;
    if tower[1] = 2 then start := 1 else start := 0;
    sieve := Primes;
    NAutoRelease(sieve);
    i := 2;
    prime := sieve[i];
    for list := start to Length(listPrime) -1 do
    begin
      while Prime <= tower[list +1] do
      begin
        listPrime[list, listLength[list]] := prime;
        inc(listLength[list]);
        if prime <= maxBound then
        begin
          np := n;
          repeat
            k := lastList;
            np := np div prime;
            q := np;
            repeat
              if Odd(q) then
              begin
                listPrime[k, listLength[k]] := prime;
                inc(listlength[k]);
              end;
              Dec(k);
              q := q shr 1;
            until (q = 0) or (prime > bound[k]);
          until prime > np;
        end;
        inc(I);
        prime := sieve[I];
      end;
    end;
  end;

  procedure iterQuad;
  var
    init,i,listLen: Integer;
    B: IInteger;
  begin
    if listLength[0] = 0 then init := 1 else init := 3;
    NSet(A, init);
    listLen := Length(listPrime);
    for i := 1 to listLen -1 do
    begin
      NSqr(A);
      SetLength(listPrime[i], listlength[i]);
      NPrd(B, listPrime[I]);
      NMul(A, B);
    end;
  end;

var
  lgN,j,hN: Integer;
begin
  if N < 20 then
  begin
    NFactorial(A, N);
    Exit;
  end;

  lgN := NLog2(N);
  j := lgN;
  hN := N;

  SetLength(listPrime, lgN);
  SetLength(listLength, lgN);
  SetLength(bound, lgN);
  SetLength(tower, lgN +1);

  while True do
  begin
    tower[j] := hn;
    if hN = 1 then Break;
    Dec(j);
    bound[j] := hN div 3;
    SetLength(listPrime[j], omegaSwingHighBound(hN));
    hN := hN shr 1;
  end;
  tower[0] := 2;
  primeFactors(N);
  iterQuad;
  NShl(A, N - Cardinal(NBitWeight(N)));
end;

procedure Luschny;
begin
  DoFactorial(@NLuschny_Factorial);
end;

procedure ShortestPath;
var
  N,E: Cardinal;
  T: TPowerTable;
  I,L,J,P: Integer;
  S,K,V: String;
begin
  Write(#2'Input N!'#0); N := Trunc(ReadNumber);
  N := NPowerTable(T, N);
  E := 0;
  for I := 0 to High(T) do
    if (T[I].B > 0) and (T[I].E > E) then
      E := T[I].E;
  if E > 0 then
  begin
    S := '';
    E := 1 shl NLog2(E);
    while E <> 0 do
    begin
      if S <> '' then S := #3'('#0 + S + #3')'#0'^2 * '#10;
      K := StringOfChar('*', 1024 *8);
      P := 1;
      L := Length(K);
      for I := 0 to High(T) do
        if T[I].E and E <> 0 then
        begin
          V := IntToStr(T[I].B);
          J := Length(V);
          if P + J > L then
          begin
            K := K + StringOfChar('*', 1024 *8);
            L := Length(K);
          end;
          Move(V[1], K[P], J);
          Inc(P, J +1);
          NCalcCheck;
        end;
      SetLength(K, P -2);
      S := S + #1 + K + #0;
      E := E shr 1;
    end;
    S := S + ' * 2^' + IntToStr(N);
  end else
    S := '2^' + IntToStr(N);
  WriteLn(S);
end;

resourcestring
  sFactorial = 'Factorial\';
  sOthers    = 'Others(n)\';
  sOthersKN  = 'Others(k,n)\';
  sOthersH   = 'Others([n/2])\';
  sSpecial   = 'Special\';
initialization
  SysUtils.DecimalSeparator := '.';

  RegisterProc(sFactorial + 'Moessner', '', Moessner);
  RegisterProc(sFactorial + 'Naive', '', Naive);
  RegisterProc(sFactorial + 'Recursive Product', '', Recursive);
  RegisterProc(sFactorial + 'Divide and Conquer', '', DivideAndConquer);
  RegisterProc(sFactorial + 'Jason GMP', '', FactJason_GMP);
  RegisterProc(sFactorial + 'Binomial', '', FactBinomial);
  RegisterProc(sFactorial + 'Schönhage', '', Schoenhage);
  RegisterProc(sFactorial + 'Luschny', '', Luschny);
  RegisterProc(sFactorial + 'N1');
  RegisterProc(sFactorial + 'Display last result', '', DoShow);
  RegisterProc(sFactorial + 'Display shortest Primepower path for N!', '', ShortestPath);

  RegisterProc(sOthers + 'OddFactorial, n! / 2^i', '', OddFactorial);
  RegisterProc(sOthers + 'Factorial, n!', '', Factorial);
  RegisterProc(sOthers + 'Comporial, n! / Pr(2,n)', '', Comporial);
  RegisterProc(sOthers + 'Primorial, Pr(2,N)', '', Primorial);

  RegisterProc(sOthersKN + 'Product, n! / k!', '', Product);
  RegisterProc(sOthersKN + 'Primorial, Pr(k, n)', '', PrimeProduct);
  RegisterProc(sOthersKN + 'Binomial, n! / (k!(n-k)!)', '', Binomial);
  RegisterProc(sOthersKN + 'Permutation,  n! / (n-k)!', '', Permutation);

  RegisterProc(sOthersH + 'Half Factorial, n! / [n/2]!', '', HalfFactorial);
  RegisterProc(sOthersH + 'Half Comporial, n! / ([n/2]! Pr([n/2]+1,n))', '', HalfComporial);
  RegisterProc(sOthersH + 'Half Primorial, Pr(n) / Pr([n/2]+1)', '', HalfPrimorial);
  RegisterProc(sOthersH + 'Half Binomial,  n! / ([n/2]! (n-[n/2])!)', '', HalfBinomial);

  RegisterProc(sSpecial + 'About', '', About);
  RegisterProc(sSpecial + 'Combinatoric Selftest', '', SelfTest);
  RegisterProc(sSpecial + 'Speedcomparsion Sqr and Mul', '', SpeedTest);

//  Primes.LoadCache('d:\prime.cache');
end.


