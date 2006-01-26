unit TestUnit;

interface

uses Windows, SysUtils, Classes, ConsoleForm, DECUtil, DECHash, DECRandom,
     NMath, NInts, NInt_1, NCombi, NRats, Prime, IDPrimes, DECCipher, DECFmt,
     comctrls, Controls, SRP, NPolys, NGFPs, NGFPBld, NGFPTab, CRC, Math;

implementation

function _Str(const A: IInteger = nil; const Base: Integer = 10): Variant;
// für Debugwatching
begin
  Result := NStr(A, Base);
end;


procedure Step1;
// basic usage of IInteger
var
  A,B,C: IInteger;
begin
// zuerst mal erzeugen wir zufällige werte für A und B
  NRnd(A, 1024);  // A hat 1024 Bit größe
  NRnd(B, 128);   // B 128 Bit
// num mal alle wichtigen Operatoren
  NAdd(A, B);	  // A = A + B
  NSub(A, B);	  // A = A - B
  NAdd(C, A, B);  // C = A + B
  NSub(C, A, B);  // C = A - B
  NNeg(C);	  // C = -C
  NOdd(C, True);  // C = C or 1, nun ist C ungerade
  NMul(C, A, B);  // C = A * B

  WriteLn(#2'Dezimal:'#0#13, NStr(C, 10) ); // display C in dezimal
  WriteLn(#2'Binär:'#0#13, NStr(B, 2)  ); // display B in binrär
  WriteLn(#2'Basis 7:'#0#13, NStr(B, 7)  ); // display B zur basis 7
  WriteLn(#2'HEX:'#0#13, NStr(B, 16) ); // nun HEX-decimal

  NSwp(B, piByte);
  WriteLn(#2'HEX geswappt:'#0#13, NStr(B, 16) );
end;


procedure Step2;
// NPi() selber ist die dritt schnellste Implementation zur Berechnung von Pi
// auf PC's in der Welt !
var
  Decimals: Integer;
  A: IInteger;
begin
  Write(#2'Anzahl Dezimalstellen von PI:'#0); Decimals := Trunc(ReadNumber); // auch 1e4 für 10000 möglich als Eingabe
  Write(#30);  // aktiviere Timer, das erste WriteLn zeigt dann die Millisekunden an

  NPi(A, Decimals);

  WriteLn;     // hier Timer anzeigen

  Write(#21);  // Console 1 aktivieren
  WriteLn(NStr(A));
  Write(#20);  // Console 0 aktivieren

 // #21 = Opcode zum Wechseln in Console 1
 // #20 = Opcode zum Wechseln in Console 0

end;

procedure NRoot(var R: IInteger; const A: IInteger; Root,Digits: Integer; Base: TBase = 10); overload;
// R = A^(1/Root) * Base^Digits
resourcestring
  sNRoot1 = 'NRoot(), invalid paramater Root, must be >= 2';
  sNRoot2 = 'NRoot(), invalid paramater Digits, must be >= 0';
var
  T: IInteger;
begin
  if Root < 2 then NRaise(@sNRoot1);
  if Digits < 0 then NRaise(@sNRoot2);
  NPow(T, Base, Digits);
  NPow(T, Root);
  NMul(R, T, A);
  while not Odd(Root) do
  begin
    NSqrt(R);
    Root := Root shr 1;
  end;
  if Root > 1 then NRoot(R, Root);
end;

procedure Step3;
var
  Decimals: Integer;
  C: Char;
  A: IInteger;
begin
  Write(#2'Anzahl Dezimalstellen der Quadratwurzel:'#0); ReadLn(Decimals);
  Write(#30);  // aktiviere Timer

  NRoot(A, NTwo, 2, Decimals, 10);

  Write(#3'Resultat hat ', NDigitCount(A, 10), ' Dezimalstellen, anzeigen (J/N)'#0); ReadLn(C);
  if UpCase(C) = 'J' then
  begin
    Write(#21);
    WriteLn(NStr(A, 10));
    Write(#20);
  end;
end;

procedure Step4;
var
  N: Integer;
  A: IInteger;
begin
  Write(#5'Fakultät von:'#0); ReadLn(N);
  Write(#30);

  NFactorial(A, N);

  WriteLn;
  Write(#21);
  WriteLn( NStr(A) );
  Write(#20);
end;

procedure Step5;
var
  R,S: IRational;
begin
  NSet(R, 1, 3);   // R = 1 / 3
  NSet(S, 4, 5);   // S = 4 / 5

  NMul(R, S);
  WriteLn(#4'1/3 * 4/5'#0#13, NStr(R) );

  NDiv(R, S);
  WriteLn(#5#14'1/3 * 4/5 / 4/5'#0#13, NStr(R) );
  WriteLn(#5#15'1/3 * 4/5 / 4/5'#0#13, NStr(R, 16, 32) );  // zur basis 16 und 32 signifikante Stellen

  NMul(R, 3);
  WriteLn(#6'1/3 * 3'#0#13, NStr(R) );

end;

procedure Step6;
var
  A,B,C: IPoly;
  M,X: IInteger;
begin
// erzeuge eine Primzahl
  NRnd(M, 256);
  NMakePrime(M, [1, 2]);
// erzeuge ein zufälliges degree 8 polynom
  NRnd(A, 8, M, True);
// ausgabe
  WriteLn(#2'Degree 8 random Polynom'#0#13, NStr(A) );

// finde einen Degree 4 Faktor des Degree 8 Polynoms in A
  NFactor(B, A, 4, M);

  WriteLn(#2'1. Faktor'#0#13, NStr(B) );

// dividire C = A / B mod M
  NDiv(C, A, B, M);
  WriteLn(#2'2. Faktor'#0#13, NStr(C) );

  NMul(A, C, B);
  NMod(A, M);
  WriteLn(#2'Result'#0#13, NStr(A) );

// berechne das Polynom, d.h. wir rechnen Y = X^8 +- a * X^7 +- b * X^6 .... + k mod M
  NRnd(X, 1024);
  WriteLn(#2'X:'#0#13, NStr(NInt(A, X, M)));
end;

procedure Step7;
// RSA 1024 Bit verschlüsselung
var
  P,Q: IInteger;     // primzahlen
  N: IInteger;	     // modulus
  E,D: IInteger;     // public/private exponent
  U,Dp,Dq: IInteger; // private values to speedup decryption by factor 4
  M,C: IInteger;     // Plaintext/Ciphertext
  X,Y: IInteger;     // helper
begin
  Write(#8);	     // clear screen

  repeat
  // erzeuge 512 Bit Primzahl P
    NRnd(P, 512);
    NBit(P, 512 -2, True);
    NMakePrime(P, [1, 2]);
  // erzeuge 512 Bit Primzahl Q
    repeat
      NRnd(Q, 512);
      NBit(Q, 512 -2, True);
      NMakePrime(Q, [1, 2]);
    until NCmp(P, Q) <> 0; // verhindere unwahrscheinlichen Fall das P gleich Q ist
    if NCmp(P, Q) < 0 then NSwp(P, Q);	// make sure P > Q
  // erzeuge public Modul N = 1024 Bit,  N = P * Q
    NMul(N, P, Q);
  until NSize(N) = 1024;  // verhindere unwahrscheinlichen Fall das N nicht wie gewünscht 1024 Bit groß ist

// erzeuge sicheren public Exponenten E, private Exponenten D zur entschlüsselung
  NDec(P);
  NDec(Q);
  NLCM(U, P, Q);       // U = LCM(P -1, Q -1)
  repeat
    repeat
      NRnd(E, NLog2(NSize(N)) * 4);    // Exponent sollte 4*Log2(Log2(N)) groß sein, zufällig und ungerade
      NOdd(E, True);
    until NGCD1(E, P) and NGCD1(E, Q); // Exponent darf keinen gemeinsammen Teiler mit P oder Q haben, sprich nicht durch P,Q teilbar sein
 // erzeuge private Entschlüsselungsexponent D, D sollte >= E sein und keinen gemeinsammen Teiler mit N haben
  until NInvMod(D, E, U) and (NSize(D) >= NSize(E)) and NGCD1(D, N);

  NMod(Dp, D, P);    // Dp = D mod (P -1), wird benötigt für Chinese Remainder Theorem CRT
  NMod(Dq, D, Q);    // Dq = Q mod (Q -1)
  NInc(P);
  NInc(Q);
  NInvMod(U, P, Q);  // U = P^-1 mod Q
// unser privater und öffentlicher Schlüssel sind nun fertig
// N,E ist der öffentliche Schlüssel
// N,D der private Schlüssel, wobei
// U,Dp,Dq,P,Q dazu gehören damit wir die Entschlüsselung um Faktor 4 beschleunigen können


// nun verschlüsseln wir M den PlainText
  NSet(M, 'Unser Geheimnis', 256);
  NCut(M, NHigh(N));		    // M muß kleiner public Modul N sein
// CipherText C = M^E mod N
  NPowMod(C, M, E, N);		    // C = M^E mod N

  Write(#21);
  WriteLn(#2'PlainText	: '#0, NStr(M, 16), ' = ', NStr(M, 256) );
  WriteLn(#3'CipherText : '#0, NStr(C, 16) );
  Write(#20#0);

// nun entschlüsseln wir auf herkömmliche Art,
//	  X = M = C^D mod N
  WriteLn(#2'normal entschlüsselt'#0#30);

  NPowMod(X, C, D, N);

  WriteLn( NStr(X, 256) );

// nun die schnelle Variante per CRT = Chinese Remainder Theorem ca. 4 mal schneller
  WriteLn(#10#2'per CRT entschlüsselt: '#0#30);

  NPowMod(X, C, Dp, P);
  NPowMod(Y, C, Dq, Q);
  NSub(Y, X);
  NMulMod(Y, U, Q);
  NMul(Y, P);
  NAdd(Y, X);

  WriteLn( NStr(Y, 256), ' = ', NStr(Y, 16));

// oder
  WriteLn(#30);
  NPowMod(X, C, Dp, P);
  NPowMod(Y, C, Dq, Q);
  NCRT(Y, NInt([X, Y]), NInt([Dp, Dq]), NInt([U]));
  WriteLn( NStr(Y, 256) );
end;


procedure SpeedTest;

  function XCRC(const A: IInteger): String;
  begin
    Result := IntToHEX( NCRC(A), 8);
  end;

var
  J,I: Integer;
  A,B,C,D,E,F,G: IInteger;
  CRC: Cardinal;
  P: IPowModPrecomputation;
begin
  J := 0;
  Write(#2'Iterationcount'#0); ReadLn(I); Write(#11);

  while J < I do
  begin
    CRC := 0;
    Inc(J);
    WriteLn(#2'Iteration #', J, '/', I, #0);

    Write('A = Fib(800000)      '); StartTimer;
    NFibonacci(A, 800000);
    Write(Ticks:9:0, ' ms, ', XCRC(A):10); Inc(CRC, NCRC(A));
    WriteLn(#1' Fibonacci(800000) = ', NDigitCount(A), ' Decimal digits'#0);

    Write('B = Fib(900000)      '); StartTimer;
    NFibonacci(B, 900000);
    Write(Ticks:9:0, ' ms, ', XCRC(B):10); Inc(CRC, NCRC(B));
    WriteLn(#1' Fibonacci(900000) = ', NDigitCount(B), ' Decimal digits'#0);

    Write('C = Sqrt(A)          '); StartTimer;
    NSqrt(C, A);
    Write(Ticks:9:0, ' ms, ', XCRC(C):10); Inc(CRC, NCRC(C));
    WriteLn(#1' Fib(800000)^0.5 = ', NDigitCount(C), ' Decimal digits'#0);

    Write('D = A * B            '); StartTimer;
    NMul(D, A, B);
    Write(Ticks:9:0, ' ms, ', XCRC(D):10); Inc(CRC, NCRC(D));
    WriteLn(#1' Fib(800000)*Fib(900000) = ', NDigitCount(D), ' Decimal digits'#0);

    Write('E = D * D            '); StartTimer;
    NSqr(E, D);
    Write(Ticks:9:0, ' ms, ', XCRC(E):10); Inc(CRC, NCRC(E));
    WriteLn(#1' (Fib(800000)*Fib(900000))^2 = ', NDigitCount(E), ' Decimal digits'#0);

    Write('B = B / A            '); StartTimer;
    NDiv(B, A);
    Write(Ticks:9:0, ' ms, ', XCRC(B):10); Inc(CRC, NCRC(B));
    WriteLn(#1' Fib(900000) div Fib(800000) = ', NDigitCount(B), ' Decimal digits'#0);

    Write('C = PI(10000)        '); StartTimer;
    NPi(E, 10000);
    Write(Ticks:9:0, ' ms, ', XCRC(E):10); Inc(CRC, NCRC(E));
    WriteLn(#1' computation of 10000 decimal digits of Pi = 3.14...'#0);

    Write('A = 100000!          '); StartTimer;
    NFactorial(A, 100000);
    Write(Ticks:9:0, ' ms, ', XCRC(A):10); Inc(CRC, NCRC(A));
    WriteLn(#1' Factorial(100000) = ', NDigitCount(A), ' Decimal digits'#0);

    Write('p(10000, 5000)       '); StartTimer;
    NProduct(A, 10000, 5000);
    Write(Ticks:9:0, ' ms, ', XCRC(A):10); Inc(CRC, NCRC(A));
    WriteLn(#1' Product(10000..5000) = ', NDigitCount(A), ' Decimal digits'#0);

    Write('C(1000000, 500000)   '); StartTimer;
    NBinomial(A, 1000000, 500000);
    Write(Ticks:9:0, ' ms, ', XCRC(A):10); Inc(CRC, NCRC(A));
    WriteLn(#1' Binomial(N=1000000,K=500000) = ', NDigitCount(A), ' Decimal digits'#0);

    Write('Primorial(2..500000) '); StartTimer;
    NPrimorial(A, 0, 500000);
    Write(Ticks:9:0, ' ms, ', XCRC(A):10); Inc(CRC, NCRC(A));
    WriteLn(#1' Primorial(2..', Primes[Primes.IndexOf(500000, True)],') = ', NDigitCount(A, 10), ' Decimal digits'#0);

    Write('e*10^10000           '); StartTimer;
    NPow(A, 10, 10000);
    NExp(A);
    Write(Ticks:9:0, ' ms, ', XCRC(A):10); Inc(CRC, NCRC(A));
    WriteLn(#1' computation of decimal digits of e = 2.71...'#0);

    Write('10^100000            '); StartTimer;
    NPow(A, 10, 100000);
    WriteLn(Ticks:9:0, ' ms, ', XCRC(A):10); Inc(CRC, NCRC(A));
    if CRC <> $E71B8A5B then Write(#3);
    WriteLn('CRC ? :  $E71B8A5B = $', IntToHEX(CRC, 8));

    NRnd(A, 1024);
    NRnd(B, 1024);
    if NCmp(A, B) < 0 then NSwp(A, B);
    NOdd(B, True);
    Write('A mod B              '); StartTimer;
    NMod(A, B);
    Write(Ticks:9:3, ' ms');
    WriteLn(#1' A,B are 1024 Bit random Integers'#0);

    NRnd(A, 1024);
    NRnd(B, 1024);
    NSet(C, 3);
    Write('A^3 mod B            '); StartTimer;
    NPowMod(A, B, C);
    Write(Ticks:9:2, ' ms');
    WriteLn(#1' A,B are 1024 Bit random Integers, 3 modular squaring'#0);

    NRnd(A, 1024);
    NRnd(B, 1024);
    NRnd(C, 1024);
    NOdd(C, True);
    Write('A^B mod C            '); StartTimer;
    NPowMod(A, B, C);
    Write(Ticks:9:0, ' ms');
    WriteLn(#1' A,B,C are 1024 Bit random Integers, 1024 modular sqr, ', NWeight(B), ' modular muls'#0);

    NSet(P, A, C, 1024, False);
    Write('A^B mod C (precomp.) '); StartTimer;
    NPowMod(A, B, C, P);
    Write(Ticks:9:0, ' ms');
    WriteLn(#1' A,B,C are 1024 Bit random Integers, 1024 modular sqr, ', NWeight(B), ' modular muls'#0);


    NRnd(A, 1024);
    NRnd(B, 1024);
    NRnd(C, 1024);
    NRnd(D, 1024);
    NRnd(E, 1024);
    NRnd(F, 1024);
    NRnd(G, 1024);
    NOdd(G, True);

    Write('A^D * B^E * C^F mod G '); StartTimer;
    NPowMod(A, NInt([A, B, C]), NInt([D, E, F]), G);
    Write(Ticks:8:0, ' ms');
    WriteLn(#1' A,B,C,D,E,F are 1024 Bit random Integers, 3072 modular sqr, ',
       NWeight(D) + NWeight(E) + NWeight(F) + 3,' modular muls'#0);

    NRnd(A, 1024 * 4);
    NRnd(B, 1024 * 4);
    Write('GCD(A, B)             '); StartTimer;
    NGCD(A, A, B);
    Write(Ticks:8:2, ' ms');
    WriteLn(#1' A,B are 4096 Bit random Integers'#0);

    NRnd(A, 1024 * 4);
    NRnd(B, 1024 * 4);
    Write('Extended GCD(A, B)    '); StartTimer;
    NGCD(C, D, E, A, B);
    Write(Ticks:8:2, ' ms');
    WriteLn(#1' A,B are 4096 Bit random Integers, C = D*A + E*B'#0);

    NRnd(A, 1024);
    NRnd(B, 1024);
    NRnd(C, 1024);
    NOdd(C, True);
    Write('V_k(P) mod M          '); StartTimer;
    NLucasMod(A, A, B, C);
    Write(Ticks:8:2, ' ms');
    WriteLn(#1' V of modular Lucas sequence, k,P,M are 1024 Bit random Integers'#0);

    Write(#12);
  end;
end;


procedure Vectors;

  function DoRND(var A: IInteger): Boolean; register;
  begin
    Result := False;
    NRnd(A, 0, True);  // randomized size + randomized sign
    NCut(A, 128);	// cut it, because we would read one line
  end;

  function DoPrint(var A: IInteger): Boolean; register;
  begin
    Result := False;
    WriteLn( NStr(A) );
  end;

var
  X: IInteger;

  function DoAdd(var A: IInteger): Boolean; register;
  begin
    Result := False; // set to true to abort iteration
    NAdd(A, X);  // here we access to own stack, thats legal here
  end;

  function DoAbs(var A: IInteger): Boolean; register;
  begin
    Result := False;
    NAbs(A);
    NAdd(X, A);
  end;

  function DoFind(var A: IInteger): Boolean; register;
  begin
    Result := NCmp(A, X) >= 0;
  end;

var
  V: IIntegerArray;
begin
  WriteLn(#2'generate a 10 entry random IInteger vector...'#0);
// initialize V with 10 randomize IInteger
  StartTimer;

  SetLength(V, 10);
  NForEach(V, @DoRND);

  WriteLn( Ticks:10:3, ' ms');
  WriteLn(#2'print out...'#0);

// print out the list
  NForEach(V, @DoPrint);

// now add a random value to each element
  WriteLn(#2'add a element...'#0);
  StartTimer;

  NRnd(X, 0, True);
  NCut(X, 128);
  NForEach(V, @DoAdd);

  WriteLn( Ticks:10:3, ' ms');

// now quick sort V
  WriteLn(#2'sorted vector...'#0);
  StartTimer;

  NSort(V);

  WriteLn( Ticks:10:3, ' ms');
  NForEach(V, @DoPrint);

  WriteLn(#2'sorted absolute descending vector...'#0);
  StartTimer;

  NSort(V, True, True);

  WriteLn( Ticks:10:3, ' ms');
  NForEach(V, @DoPrint);

  WriteLn(#2'make elements absolute and calc sum...'#0);
  StartTimer;

  NSet(X, 0);
  NForEach(V, @DoAbs);
  NSort(V);

  WriteLn( Ticks:10:3, ' ms');
  WriteLn(#2'Sum:'#0);
  WriteLn( NStr(X) );

  WriteLn(#2'find nearest greater element to sum / 10'#0);
  NDiv(X, 10);
  WriteLn(#2'Sum/10:'#0);
  WriteLn( NStr(X) );

  StartTimer;

  X := NForEach(V, @DoFind);

  WriteLn( Ticks:10:3, ' ms');
  WriteLn(#2'nearest element:'#0);
  WriteLn( NStr(X) );
  WriteLn(#2'list of element:'#0);

  NForEach(V, @DoPrint);
end;

const
  B: array[0..3] of Integer = (768, 1024, 1536, 2048);

procedure RSARandomE;
var
  P,Q,E,D,N,Dp,Dq,U: IInteger;
  M,C,X,Y: IInteger;
  T1,T2,T3,T4: Double;
  I,S: Integer;
  A: Char;
begin
  Write(#2'Do you want to display all params (Y/N)'#0); ReadLn(A); Write(#11);

  for I := Low(B) to High(B) do
  begin
    WriteLn(#4'Create ', B[I]:4,'Bit RSA Keypair...'#0);

    StartTimer;
    repeat
      S := B[I] shr 1;
      NRnd(P, S);
      NBit(P, S -2, True);
      NMakePrime(P, [1, 2]);
      S := B[I] - NSize(P);	// very rarely can P 1 Bit larger as wanted
      repeat
	NRnd(Q, S);
	NBit(Q, S -2, True);
	NMakePrime(Q, [1, 2]);
      until NCmp(P, Q) <> 0;  // make sure P <> Q
      if NCmp(P, Q) < 0 then NSwp(P, Q);  // make sure P > Q
      NMul(N, P, Q);
    until NSize(N) = B[I];
    NDec(P);
    NDec(Q);
    NLCM(U, P, Q);	 // U = LCM(P -1, Q -1)
    repeat
      repeat
	NRnd(E, NLog2(NSize(N)) * 4);
	NOdd(E, True);			  // E = public Exponent
      until NGCD1(E, P) and NGCD1(E, Q);  // not realy needed but safer
      // D = private Decryption Exponent, D = E^-1 mod LCM(P -1, Q -1)
    until NInvMod(D, E, U) and (NSize(D) >= NSize(E)) and NGCD1(D, N);
    NMod(Dp, D, P);    // Dp = D mod (P -1)
    NMod(Dq, D, Q);    // Dq = Q mod (Q -1)
    NInc(P);
    NInc(Q);
    NInvMod(U, P, Q);  // U = P^-1 mod Q

    T1 := Ticks;
    if UpCase(A) = 'Y' then
    begin
      WriteLn(#3, T1:10:2, ' ms'#0);
      WriteLn(#2'P  :'#1,NSize(P):4, 'Bit random prime'#0#10, NStr(P));
      WriteLn(#2'Q  :'#1,NSize(Q):4, 'Bit random prime'#0#10, NStr(Q));
      WriteLn(#2'N  :'#1,NSize(N):4, 'Bit public Modul, N = P * Q'#0#10, NStr(N));
      WriteLn(#2'E  :'#1' random odd public encryption Exponent'#0#10, NStr(E));
      WriteLn(#2'D  :'#1' D  = E^-1 mod LCM(P -1, Q -1), private decryption Exponent'#0#10, NStr(D));
      WriteLn(#2'U  :'#1' U  = P^-1 mod Q, private inverse to speedup RSA by CRT'#0#10, NStr(U));
      WriteLn(#2'Dp :'#1' Dp = D mod (P -1), private part for CRT-RSA'#0#10, NStr(Dp));
      WriteLn(#2'Dq :'#1' Dq = D mod (Q -1), private part for CRT-RSA'#0#10, NStr(Dq));
      WriteLn;

      WriteLn(#1'Publickey are N,E');
      WriteLn(#1'Privatekey are N,D and extended part for CRT are Dp,Dq,U,P,Q');
      WriteLn;

      WriteLn(#2'RSA Encryption, C = M^E mod N');
    end;
    NSet(M, 'RSA Public Key scheme with DEC', 256);
    StartTimer;

    NPowMod(C, M, E, N);

    T2 := Ticks;
    if UpCase(A) = 'Y' then
    begin
      WriteLn(#3, T2:10:2, ' ms'#0);
      WriteLn(#2'Plaintext  M = '#0, NStr(M, 256), #10, NStr(M, 16));
      WriteLn(#2'Ciphertext C = '#0#10, NStr(C, 16));

      WriteLn(#2'RSA Decryption, M = C^D mod N');
    end;
    StartTimer;

    NPowMod(X, C, D, N);

    T3 := Ticks;
    if UpCase(A) = 'Y' then
    begin
      WriteLn(#3, T3:10:2, ' ms'#0);
      WriteLn(#2'Plaintext  M = '#0, NStr(X, 256));

      WriteLn(#2'RSA-CRT Decryption, M = (C^Dp mod P - C^Dq mod Q) * P^-1 mod Q * P + C^Dp mod P');
    end;
    StartTimer;

    NPowMod(X, C, Dp, P);
    NPowMod(Y, C, Dq, Q);
    NSub(Y, X);
    NMulMod(Y, U, Q);
    NMul(Y, P);
    NAdd(Y, X);

    T4 := Ticks;
    if UpCase(A) = 'Y' then
    begin
      WriteLn(#3, T4:10:2, ' ms'#0);
      WriteLn(#2'Plaintext  M = '#0, NStr(Y, 256));
      WriteLn;
    end;
    WriteLn(#2'Results for ', NSize(N):4, 'Bit RSA:'#0);
    WriteLn('Keypair Generation  : ', T1:10:2, ' ms');
    WriteLn('public Encryption	 : ', T2:10:2, ' ms');
    WriteLn('slow Decryption	 : ', T3:10:2, ' ms');
    WriteLn('fast CRT Decryption : ', T4:10:2, ' ms');
    WriteLn(#12);
  end;
end;


var
  FixExponent: Integer = 17; // or 3, 17, $10001

procedure RSAFixE;
var
  P,Q,E,D,N,Dp,Dq,U: IInteger;
  M,C,X,Y: IInteger;
  T1,T2,T3,T4: Double;
  I,S: Integer;
  A: Char;
begin
  // Fixed public encryption exponents are weaker and speedup only the fast encryption
  // The speedup is NOT enough as the reduction of the security !!

  Write(#2'Do you want to display all params (Y/N)'#0); ReadLn(A); Write(#11);

  for I := 0 to 3 do
  begin
    WriteLn(#4'Create ', B[I]:4,'Bit RSA Keypair...'#0);

    StartTimer;
    NSet(E, FixExponent);
    repeat
      repeat
	S := B[I] shr 1;
	NRnd(P, S);
	NBit(P, S -2, True);
	if FixExponent = 3 then NMakePrime(P, [1, 2], 2, 3)
	  else NMakePrime(P, [1, 2]);
	S := B[I] - NSize(P);
	repeat
	  NRnd(Q, S);
	  NBit(Q, S -2, True);
	  if FixExponent = 3 then NMakePrime(Q, [1, 2], 2, 3)
	    else NMakePrime(Q, [1, 2]);
	until NCmp(P, Q) <> 0;		    // make sure P <> Q
	if NCmp(P, Q) < 0 then NSwp(P, Q);  // make sure P > Q
	NMul(N, P, Q);
      until NSize(N) = B[I];
      NDec(P);
      NDec(Q);
      NLCM(U, P, Q);	   // U = LCM(P -1, Q -1)
      // D = private Decryption Exponent, D = E^-1 mod LCM(P -1, Q -1)
    until NInvMod(D, E, U) and NGCD1(D, N);
    NMod(Dp, D, P);    // Dp = D mod (P -1)
    NMod(Dq, D, Q);    // Dq = Q mod (Q -1)
    NInc(P);
    NInc(Q);
    NInvMod(U, P, Q);  // U = P^-1 mod Q

    T1 := Ticks;
    if UpCase(A) = 'Y' then
    begin
      WriteLn(#3, T1:10:2, ' ms'#0);
      WriteLn(#2'P  :'#1,NSize(P):4, 'Bit random prime'#0#10, NStr(P));
      WriteLn(#2'Q  :'#1,NSize(Q):4, 'Bit random prime'#0#10, NStr(Q));
      WriteLn(#2'N  :'#1,NSize(N):4, 'Bit public Modul, N = P * Q'#0#10, NStr(N));
      WriteLn(#2'E  :'#1' random odd public encryption Exponent'#0#10, NStr(E));
      WriteLn(#2'D  :'#1' D  = E^-1 mod LCM(P -1, Q -1), private decryption Exponent'#0#10, NStr(D));
      WriteLn(#2'U  :'#1' U  = P^-1 mod Q, private inverse to speedup RSA by CRT'#0#10, NStr(U));
      WriteLn(#2'Dp :'#1' Dp = D mod (P -1), private part for CRT-RSA'#0#10, NStr(Dp));
      WriteLn(#2'Dq :'#1' Dq = D mod (Q -1), private part for CRT-RSA'#0#10, NStr(Dq));
      WriteLn;

      WriteLn(#1'Publickey are N,E');
      WriteLn(#1'Privatekey are N,D and extended part for CRT are Dp,Dq,U,P,Q');
      WriteLn;

      WriteLn(#2'RSA Encryption, C = M^E mod N');
    end;
    NSet(M, 'RSA Public Key scheme with DEC', 256);
    StartTimer;

    NPowMod(C, M, E, N);

    T2 := Ticks;
    if UpCase(A) = 'Y' then
    begin
      WriteLn(#3, T2:10:2, ' ms'#0);
      WriteLn(#2'Plaintext  M = '#0, NStr(M, 256), #10, NStr(M, 16));
      WriteLn(#2'Ciphertext C = '#0#10, NStr(C, 16));

      WriteLn(#2'RSA Decryption, M = C^D mod N');
    end;
    StartTimer;

    NPowMod(X, C, D, N);

    T3 := Ticks;
    if UpCase(A) = 'Y' then
    begin
      WriteLn(#3, T3:10:2, ' ms'#0);
      WriteLn(#2'Plaintext  M = '#0, NStr(X, 256));

      WriteLn(#2'RSA-CRT Decryption, M = (C^Dp mod P - C^Dq mod Q) * P^-1 mod Q * P + C^Dp mod P');
    end;
    StartTimer;

    NPowMod(X, C, Dp, P);
    NPowMod(Y, C, Dq, Q);
    NSub(Y, X);
    NMulMod(Y, U, Q);
    NMul(Y, P);
    NAdd(Y, X);

    T4 := Ticks;
    if UpCase(A) = 'Y' then
    begin
      WriteLn(#3, T4:10:2, ' ms'#0);
      WriteLn(#2'Plaintext  M = '#0, NStr(Y, 256));
      WriteLn;
    end;
    WriteLn(#2'Results for ', NSize(N):4, 'Bit RSA:'#0);
    WriteLn('Keypair Generation  : ', T1:10:3, ' ms');
    WriteLn('public Encryption	 : ', T2:10:3, ' ms');
    WriteLn('slow Decryption	 : ', T3:10:3, ' ms');
    WriteLn('fast CRT Decryption : ', T4:10:3, ' ms');
    WriteLn(#12);
  end;
end;


procedure Automorphic;
// automorphe Zahlen sind Zahlen deren Quadrat in den untersten Stellen identisch
// mit sich selber sind, also aus X wird X^2 und die untersten Stellen von X^2 sind
// identisch mit X.
const
  Decimals = 50;
var
  X,Y: IInteger;
begin
  NPow(X, 2, Decimals);
  NPow(Y, 5, Decimals);
  NInvMod(X, Y);
  NSub(Y, X);
  NShl(X, Decimals);
  NShl(Y, Decimals);
  NInc(Y);

  WriteLn(#2'X	:'#0#13, NStr(X) );
  NSqr(X);
  WriteLn(#2'X² :'#0#13, NStr(X) );

  WriteLn(#2'Y	:'#0#13, NStr(Y) );
  NSqr(Y);
  WriteLn(#2'Y² :'#0#13, NStr(Y) );
end;

procedure TestSPP;
var
  P: IInteger;
  R: Integer;
  I: Integer;
begin
  WriteLn(#1'test 1000 times a random odd 512 Bit Number'#0);
  R := 0;
  StartTimer;
  for I := 1 to 1000 do
  begin
    NRnd(P, 512);
    NOdd(P, True);
    if NIsProbablePrime(P) then Inc(R);
  end;
  WriteLn(Secs:10:1, ' secs' , Ticks/1000:10:1, ' ms per test', R:8, ' strong pseudo primes found');

  WriteLn(#1'test 1000 times a random odd 1024 Bit Number'#0);
  R := 0;
  StartTimer;
  for I := 1 to 1000 do
  begin
    NRnd(P, 1024);
    NOdd(P, True);
    if NIsProbablePrime(P) then Inc(R);
  end;
  WriteLn(Secs:10:1, ' secs' , Ticks/1000:10:1, ' ms per test', R:8, ' strong pseudo primes found');

  WriteLn;
  NSet(P, NIDPrime('1024:1:2:SHA1:1:4B96CC2C:A95A:424')); // short form for a verifiable prime

  WriteLn(#1'test 1024 Bit Prime to base 2'#0);
  StartTimer;
  Write( NIsProbablePrime(P, [2]):8); WriteLn(Ticks:10:0, ' ms');

  WriteLn(#1'test same Prime to bases {2,3,5,7,11}'#0);
  StartTimer;
  Write( NIsProbablePrime(P, [-11]):8); WriteLn(Ticks:10:0, ' ms');

  WriteLn(#1'test same Prime to bases {2,3,5,7,11,13}'#0);
  StartTimer; Write( NIsProbablePrime(P, [-13]):8); WriteLn(Ticks:10:0, ' ms');

  WriteLn(#1'test same Prime to base 2 and a Pomerance Baillie Selfridge Wagstaff Test'#0);
  StartTimer; Write( NIsProbablePrime(P, [1, 2]):8); WriteLn(Ticks:10:0, ' ms');

  WriteLn(#2'Last combined Test of SPP(2)+PSW are stronger as any SPP({...}) bases test.'#0);
  WriteLn(#2'Above show us that the SPP(2)PSW Test is always faster and stronger as a repeated SPP Test to more as 5 bases.'#0);
  WriteLn(#3'In fact it exists today no one known candidate that pass the SPP(2)PSW Test and is not prime.'#0);
  WriteLn;

  WriteLn(#2'Let us see this: ');
  WriteLn(#2, ' X = 18215745452589259639 * 4337082250616490391 * 867416450123298079');
  WriteLn(#1, ' X = 3 primes Carmichael Number by Bleichenbacher'#0);

  NSet(P, 'B10:68528663395046912244223605902738356719751082784386681071');

  StartTimer; Write( 'SPP(X, [ 2,3,5..97 ])    = ', NIsProbablePrime(P, [2, -97]):6);  WriteLn( Ticks:10:0, ' ms');
  StartTimer; Write( 'SPP(X, [ 2,3,5..101 ])   = ', NIsProbablePrime(P, [2, -101]):6); WriteLn( Ticks:10:0, ' ms');
  StartTimer; Write( 'SPP(X, [ 2 ]) and PSW(X) = ', NIsProbablePrime(P, [1, 2]):6); WriteLn( Ticks:10:0, ' ms');

end;

{
 Folgender Code demonstriert das man einer RSA Implementierung, deren Source man nicht kennt,
 niemals vertrauen darf !!
 Gerade bei einbruchsicherer Hardware wie SmartCards, Fritz-Chip oder Schlüsseln die
 durch Trustcenter erzeugt und verteilt werden, ist dies der Fall.

 Eine Bemerkung vorweg, da das heutige Patentwesen so bescheuert ist:
 Diese Idee ist mein geistiges Eigentum, sollte ich durch Zufall eine Algorithmus
 entdeckt haben der schon durch bestehende Patente geschützt wurde so sollte sich
 der Patentinhaber bei mir melden und mich davon in Kenntnis setzen.
 Da solche Algorithmen aber unter spezielle Beschränkungen fallen, dürften wenn
 überhaupt nur stille und unveröffentliche Patente existieren. Selbst wenn ich also
 in der Lage wäre alle Patente auf einen ähnlichen Algorithmus hin zu durchsuchen,
 so dürfte ein bestehendes Patent nicht öffentlich verfügbar sein.

 Nun zum Algo:
 Die Idee ist recht simpel und baut auf ein allgemeines Problem mit RSA auf.
 RSA funktioniert weil es eine Trapdoor-Funktion benutzt. D.h. es basiert auf einem
 mathematischen Problem, das es einerseits ermöglicht sehr schnell erzeugt zu werden
 aber nur extrem schwierig wieder gelösst zu werden.
 Das dahinterliegende Problem ist die Faktorisierung großer Zahlen, also die Zerlegung
 einer großen Zahl in deren eindeutige Primzahldarstellung.
 Jede Nicht-Primzahl kann in eine Serie von eindeutigen Primzahlexponenten zerlegt werden.

 Beim RSA erzeugt man also mindestens 2 Primzahlen und multipliziert diese um den
 öffentlichen Schlüssel zu erzeugen. Soviel dazu als absolut simplizistische Erklärung.

 Man hat also P und Q zwei Primzahlen und erzeugt das öffentliche Modul N mit
 N := P * Q.
 Wenn man also P und Q kennt so kann man N berechnen und hat somit das Wissen aus was
 der private Schlüssel besteht. Deshalb ist es wichtig P und Q nicht weiter zugeben.
 Im Normalfalle wird nach der Schlüsselerzeugung P und Q zerstört, sie werden auch
 normalerweise nicht mehr benötigt.
 Um ohne P und Q nur mit N wieder diese Primzahlen zu finden muß N faktorisiert
 werden. Bei 1024 Bit N's ist das heutzutage absolut unmöglich, es sein denn viele
 Experten haben da was verpasst :)
 Aber genau diesen Nachteil, das P,Q nicht öffentlich verifizierbar sind, nutzen wir
 mit nachfolgendem Algorithmus aus.
 Kurz gesagt: sollte der Algo. auf einer SmartCard benutzt werden und P,Q niemals die
 SmartCard verlassen so ist dieser Algo. schwerer zu entdecken und nachzuweisen als
 das öffentliche Modul N zu faktorisieren. Dies liegt daran das wenn man N in P,Q
 zerlegen könnte man dennoch NICHT die Manipulation erkennen könnte. Die Wahr-
 scheinlichkeiten dafür lassen sich mathematisch exakt berechnen und betragen
 ca. 1/2^528 bei einem 1024 Bit Schlüssel. Man müsste also durchschnittlich
 2^264 +1 verschiedene 1024Bit Schlüssel faktorisieren um überhaupt ein Muster in
 diesen Schlüsseln erkennen zu können. Da 2^128 heutzutage als magische Grenze
 für eine nicht mehr durchführbare Brute Force Attacke gelten (bis unser
 Sonnensystem implodiert) ist der Algo. enorm sicher vor Entdeckung.

 Die Idee des Algos. ist es Informationen in den Primzahlen einzubetten die es uns
 ermöglichen nur an Hand deren Produkt N sie direkt nachzuberechnen. D.h.
 wir benutzen das öffentliche Modul N um einen versteckten Kanal einzurichten der
 uns Passwortgeschütze Informationen überträgt mit deren Hilfe wir in der Lage sind
 N zu zerlegen ohne es echt faktorisieren zu müssen.

 Der Algo. muss Kontrolle über die Erzeugnung der Primzahlen haben.
 Die erzeugten Primzahlen wären dann von sogenannter "spezieller" Form, aber
 von einer Form die nicht ohne weiteres verraten wird das sie von "spezieller" Form
 sind !! Also selbst wenn diese Primzahlen analysiert würden wäre es mit eben der
 besagten Wahscheinlichkeit von 1/2^528 nicht möglich zu beweisen das sie diese
 spezielle Form besitzen.
 By the Way: niemals RSA benutzen mit Primzahlen von spezieller Form, auch wenn ein
 Mathematiker bewiesen hat das dies nicht wesentlich unsicherer ist (vielleicht hat
 er aus dem gleichen Grund ja diesen Beweis angeführt ??)

 Wie arbeitet der Algo. ?
 Anhand eines 1024 Bit Schlüssels will ich es erklären:
 Wir benötigen P und Q, also zwei Primzahlen die exakt 512 Bit groß sind und deren
 Produkt N eine Zahl mit 1024 Bits ist.

 Unser versteckter Kanal nutzt jeweils die 256 obersten Bit's von P und Q, und erzeugt
 durch Inkrementation der untersten 256 Bit eine Primzahl. Diese Primzahl hat natürlich
 nur industrielle Qualität, aber das ist eh heute üblich.

 Die obersten 256 Bits von P enthalten einen durch Zufall erzeugten Seed.
 Dieser Seed wird benutzt um die untersten 256 Bits von P und Q durch einen
 sicheren OTP zu erzeugen. D.h. ohne Wissen welche OTP Funktion angewendet wurde
 kann man selbst mit dem richtigen Seed nicht den richtigen OTP erzeugen.

 Die obersten 256 Bits von Q enthalten eine umgewandelte Form eines Passwortes.
 Über dieses 256 Bit Passwort kann also das fertige Modul N wieder zerlegt werden.
 Im folgenden Algo. gibt es insgesammt 65535 verschiedene sichere Sessionskeys die
 auf Grund des benutzten Passwortes berechnet werden können.
 Bevor dieses zufalls-gewählte Passwort in P eingearbeitet wird wird es mit unserem
 zufälligen Seed per OTP verschlüsselt. Der Seed selber dient also als Schlüssel
 um diesen Sessionkey (aus 65535 möglichen) zu tarnen. Dies wird gemacht um
 1.) das Verfahren mathematisch durchführbar zu machen
 2.) das Verfahren zu "Randomisieren"


 Ki   = zufälliger Index aus 65535 Elementen
 Ks   = Session Key
 K    = Passwort
 S    = zufälliges Seed
 OTP  = One Time Pad Funktion
 MGF  = Mask Generation Funktion basierend auf einem Hash

// erzeuge aus dem Schlüssel K einen sicheren Session Schlüssel aus einem Set von 65535 Möglichkeiten
 Ki = Random(MaxKeyVariation)
 Ks = MGF(K, Ki)
// erzeuge einen Zufallswert = Seed
 S  = Random(2^512)

// die Basisformel zur Einbettung in N
1.)  N	= S * (2*Ks - S)
// die Basisformel zur Entschlüsselung von S aus N
2.)  S	= ((Ks^2 - N * 4)^0.5 + Ks) / 2


In 1.) haben wir zwei Terme S und (2Ks -S) die jeweils in P und Q eingebettet werden.
Also

	   S		*		     (2Ks - S)		 = N'
	   P		*			 Q		 = N

   S*2^256 + MGF(S, 1)	*   OTP(2Ks - S) * 2^256 + MGF(S, 2)	 = N
   256MSB  || 256LSB		  256MSB	 ||   256 LSB

     PHigh    PLow		   QHigh	       QLow


 PHigh besteht aus unserem 256Bit Zufalls Wert S

 PLow  besteht aus einem Wert durch eine sichere Hashfunktion berechnet, als Indexed MGF betrieben.

 QHigh besteht aus unserem zufälligen Sessionkey der per Verküpfung mit einer
 Subtraktion durch Ks und Zufallswert S erzeugt wurde. Eine Subtraktion kann als
 XOR Operation angesehen werden, in fact in bestimmten Zahlensystemen zB. GF(2^m)
 IST die XOR verküpfung die Subtraktion/Addition.

 QLow wiederum wird so wie PLow berechnet aber diesmal mit einem anderen Index für die
 MGF(). Eine MGF() kann man auch als Passwortbasierendem Pseudozufallsgenerator
 verstehen, der aber kryptographisch sicher ist. Zumindestens so lange sicher wie
 man die benutzte Hashfunktion nicht knacken kann.

 Ki unser zufälliger Index in unser Set von möglichen Sessionkeys die auf unseren
 Schlüssel K basieren, muß nicht zufällig gewählt werden. Auf einer Smartcard könnte
 man auch einen einfachen Zähler benutzen der nach jeder Schlüssel Erzeugung
 inkrementiert wird. Auf jeden Fall bedeutet dies das man 65535 verschiedene
 Sessionkeys basierend auf dem gleichen Passwort erzeugen müsste um eine Mehrfach-
 verwendung des gleichen Sessionkeys zu erzwingen. Durch dieses Vorgehen müssen
 wir bei der Entschlüsselung des versteckten Kanals natürlich ermitteln mit welchem
 der 65535 verschiedenen Sessionkeys unser Modul N erzeugt wurde. Dies ist sehr clever
 da nun aus dem Verfahren ein "probalistisches" Verfahren, also ein Teilzufälliges
 Verfahren wird.
 Durch das Einbetten von Ks per Verknüpfung mit S wird erreicht das aus den 65535
 möglichen Sessionkeys eine Kombination entsteht die zu jedem dieser 65535 Sessionkeys
 2^512 verschiedene Formen erzeugt. Daher die Wahrscheinlichkeit von 1/2^528,
 2^512 * 2^16 = 2^528.

 Unser Seed S dient also in mehrfacher Hinsicht als zufälliges 512 Bit One Time Pad
 Passwort. Einmal in der Einbettung von Ks in P und zweimal als OTP zur Erzeugung
 der untersten 256 Bits von P und Q per sicheren MGF.
 ABER! ohne das Passwort Ks kann man nicht aus dem Modul N in vertretbarer Zeit
 diesen Seed S berechnen. Die Wahscheinlichket das man per Zufall dieses S ermittelt,
 und somit auch unseren Sessionkey Ks beträgt 1/2^512. Dies ist absolut ausreichend
 und nicht knackbar. Das heist nur wenn wir Ks kennen können wir auch das Modul N
 so zerlegen das wir die Primzahlen P und Q berechnen. Da aber unser Ks nicht das
 eigentliche Passwort ist, sondern nur eine umgewandelte und sichere Form aus einem
 Set von 65535 möglichen, wird eine Attacke unmöglich. Es sei denn mann kennt den
 Schlüssel K und das angewendete Verfahren. Selbst dann müssen im schlechtesten
 Falle 65535 Schlüssel ausprobiert werden um zu ermitteln welcher der richtige ist.
 Genau dies machen wir in der procedure RecoverRSAKey().

 Nun noch eine Erklärung der Multiplication von P * Q.
 Wir betten ja binär unsere Daten in P und Q ein. Wie bei einer Multiplikation üblich
 entstehen Überläufe einzelner Bits an die nächsthöhere Bitposition.
 In unserem Falle werden unsere Daten somit in den untersten Bits durch die
 Multiplikation P*Q zerstört. Das ist sehr gut da es uns eine erhöhte Sicherheit
 liefert. Aber wie stellen wir dann sicher das wir den korrekten Seed S extrahieren ?
 Es gibt mehrere Wege, zB. den Seed S nicht vollständig zufällig zu wählen und in den
 untersten 4 Bytes eine bekannte und feste Signatur zu verstecken. An Hand derer
 könnten wir dann sehr leicht ermitteln ob der getestete Seed einer von uns ist, oder
 ob das Modul N überhaupt mit unserem Verfahren erzeugt wurde. Der Nachteil ist aber
 das es einem Super-Angreifer, der ohne Probleme Zahlen faktorisieren kann, diese
 Signatur zu schnell auffallen dürfte. Eine Verschleierung dieser Signatur per redundanten
 Information bringt da auch nicht viel, da solche Verfahren nicht zufälliger Natur sind.
 Um dies zu verhindern erzeugen wir eine Signatur die von dem Seed und dem Sessionkey
 abhänig ist und durch eine MGF geschützt wird. Also S[0] = MGF(K || S shr 32, 3).
 Nun können wir sehr leicht und denoch randomisiert und sicher überprüfen ob der
 benutzte Sessionkey Ks und der Seed S von spezieller Form sind und durch das
 Verfahren erzeugt wurden.

 Als interessanter Bezug sei erwähnt das der math. Algorithmus zur Extraktion unserer
 Werte aus N auf einer bekannten Faktorisierungsmethode beruht. Mit dem Unterschied
 das einer der nötigen Werte, unser Sessionkey, für uns als "Angreifer" bekannt ist.
 

 So genug erklärt, jetzt kommt der Source.
}

const
  MaxKeyVariation  = 1024 * 16; // Anzahl der möglichen Sessionkeys zum Passwort
  MaxBitError      = 1024 * 1;  // power of 2 and > 2
  MGFpIndex	   = 1; 	// diese Indizes müssen unterschiedlich sein
  MGFqIndex	   = 2; 	// andere Werte lassen den Algortihmus komplett
  MGFsIndex	   = 3; 	// andere Zahlen erzeugen, ideal zur Serialisierung
// benutztes Password als binärer Wert (in EXE), einfach Strg+Shift+G drücken um ein anderes zu erzeugen
  Password: TGUID  = '{EB46DED5-7593-40F1-98DD-950860B73062}';

procedure BuildRSAPrimes(var P,Q: IInteger; KeySize: Integer; const S,K: IInteger);
// erzeugt die Primzahlen P und Q für einen KeySize Bits großen Schlüssel
// S ist der zufällige Seed
// K ist einer der Sessionkeys zum Passwort
var
  I: Integer;
  T: IInteger;
begin
  I := KeySize div 2 - KeySize div 4;

// erzeuge die untersten Bits von P und Q, der Index der benutzten MGF() muß für
// P und Q unterschiedlich sein. Der Seed S dient als OTP-Password für die MGF().
  NHash(P, S, THash_SHA1, -I, MGFpIndex);
  NHash(Q, S, THash_SHA1, -I, MGFqIndex);

// Seed S und die untersten Bits von P werden zum Startwert der Primzahl P zusammengefügt
  NCat(P, NInt([S, P]), I);
// sollte KeySize ungerade sein so müssen wir P mit 2 multiplizieren, damit wird sichergestellt
// das P * Q ein Modul N erzeugen das exakt KeySize Bits groß ist
  NShl(P, KeySize mod 2);
// nun wird P solange inkrementiert bis es eine Primzahl ist. Das verwendete Verfahren dazu ist
// eines der schnellsten und SICHERSTEN. D.h. es wird ein Strong Pseudo Primzahl Test zur
// festen Basis 2 durchgeführt PLUS einem Baillie-Selfridge-Wagstaff-Pomerance-
// Strong-Lucas-Pseudo-Primzahl-Test.
// Bei diesem PSW Test hat bisher, nach 10 Jahren, noch kein Mensch eine Zahl gefunden die
// diesen Test bestanden hat und KEINE Primzahl war. Es ist bewiesen das es solche
// Zahlen geben muß, man vermutet aber das das erst bei Zahlen größer 2^10000 der Fall sein
// dürfte !! Also die erzeugte Zahl ist mit an Sicherheit grenzender Wahrscheinlichkeit
// immer eine Primzahl. (nur soviel dazu :)
  NMakePrime(P, [1, 2]);
// nun verküpfen wir unseren SessionKey K mit dem zufalls-Seed S. S dient also als OTP
// um K zu verschleiern. Ohne K kann man nicht S berechnen und ohne S kann man nicht K
// berechnen. Da S bei 1024 Bit RSA Schlüsseln 256 Bit groß ist ist eine Brute Force
// Attacke ausgeschlossen.
  NSub(T, K, S);
// (2Ks-S) || Q, füge unsere Primzahl Q zusammen und erzeuge auch eine Primzahl :)
  NCat(Q, NInt([T, Q]), I);
  NMakePrime(Q, [1, 2]);
// fertig sind unsere Primes
end;

procedure BuildForgedRSAKey(var P,Q: IInteger; KeySize: Integer);
// diese Funktion erzeugt unseren RSA Schlüssel, bzw. dessen wichtigste Bestandteile die
// Primzahlen P und Q. Der Schlüssel N wird dann KeySize Bits groß sein, und durch
// das Passwort die versteckten Informationen in N schützen.
// Sozuagen ermöglicht das Verfahren eine Passwortgeschützte schnelle Direktfaktorisation
// einer Zahl :))
resourcestring
  sInvalidKeySize = 'KeySize muß >= 256 sein.';
var
  K,S,N,T: IInteger;
  I: Integer;
begin
  I := KeySize div 4;
  if I < 64 then NRaise(@sInvalidKeySize);
  repeat
    repeat
 // erzeuge den zufälligen Sessionkey zum Passwort
      NSet(K, Password, SizeOf(Password));
      NHash(K, THash_SHA1, I, Random(MaxKeyVariation));
 // dieses Bit wird gesetzt damit unser fertiges P,Q auch ein N erzeugen das exakt KeySize Bits groß ist
      NBit(K, I -2, True);
 // nun erzeugen wir den zufälligen Seed S mit Signature
      NRnd(S, I -32);
      NBit(S, I -34, True);
 // die Signatur besteht aus der Concatenation von MGF(K || S) mod 2^32
 // und ist demzufolge ebenfalls "zufällig"
      NShl(T, K, I -32);
      NAdd(T, S);
      NHash(T, THash_SHA1, 32, MGFsIndex); // 32 Bit indexed Hash function anwenden
 // hänge Signatur an S
      NShl(S, 32);
      NAdd(S, T);
    until NCmp(S, K) > 0;
    NShl(K, 1);
 // erzeuge die Primzahlen P,Q basierend aus Seed S und SessionKey K
    BuildRSAPrimes(P, Q, KeySize, S, K);
 // wir verifizieren unsere Arbeit
    NMul(N, P, Q);
    NShr(N, NSize(N) - I * 2 -2);
    NSqr(T, K);
    NSub(T, N);
    NAbs(T);
    NSqrt(T);
    NAdd(T, K);
    NShr(T, 1);
    NSub(T, S);
  until NCmp(T, MaxBitError, True) <= 0;
end;

function RecoverRSAKey(var P,Q: IInteger; const N: IInteger): Boolean;
// Reproduziere aus einem gegebenen öffentlichen Modul N die beiden Primzahlen P,Q
// wir extrahieren aus dem verdeckten Kanal unseren Seed S.
// Dieser Algo. und das Passwort sollten natürlich auf dem firmeneigenen Server oder
// im Tresor als Top Secret eingestuft werden.
// Wir müssen eine Trial&Error Methode verwenden da wir ja nicht wissen welcher
// der MaxKeyVariation möglichen SessionKeys tatsächlich benutzt wurde.
// Aber dies geht sehr schnell.
var
  C: Cardinal;
  I,J: Integer;
  S,M,K,T: IInteger;
begin
  Result := True;
  I := NSize(N) div 4;
  for J := 0 to MaxKeyVariation -1 do
  begin
// erzeuge SessionKey K
    NSet(K, Password, SizeOf(Password));
    NHash(K, THash_SHA1, I, J);
    NBit(K, I -2, True);
    NShl(T, K, I -32);
    NShl(K, 1);
// extrahiere in M die obersten Bits
    NShr(M, N, NSize(N) - I * 2 -2);
// wende Formel zur Extraktion des versteckten Kanals an
    NSqr(S, K);
    NSub(S, M);
    NAbs(S);
    NSqrt(S);
    NAdd(S, K);
    NShr(S, 1);
// erzeuge Signatur zur Überprüfung
    C := S[0];
    NShr(S, 32);
    NAdd(T, S);
    NHash(T, THash_SHA1, 32, MGFsIndex);
// korrigiere Bitfehler in S
    if Abs(C - T[0]) < MaxBitError then
    begin
      NShl(S, 32);
      NAdd(S, T);
// erzeuge Primzahlen
      BuildRSAPrimes(P, Q, NSize(N), S, K);
      NMul(M, P, Q);
      if NCmp(M, N) = 0 then Exit;
    end;
  end;
  Result := False;
end;

procedure BuildRealRSAKey(var P,Q: IInteger; KeySize: Integer);
// erzeugt einen echten, nicht manipulierten RSA Schlüssel
var
  I: Integer;
begin
  I := KeySize div 2;

  NRnd(P, KeySize - I);
  NBit(P, I -2, True);
  NMakePrime(P, [1,2]);

  NRnd(Q, I);
  NBit(Q, I -2, True);
  NMakePrime(Q, [1,2]);
end;

procedure ForgedRSA;
// Testfunktion um forged RSA zu demonstrieren,
// alle RSA Operationen sind nur partiell dargstellt um auf's Wesentliche zu
// kommen. Normalerweise erzeugt unsere Software mit obigem Verfahren ein
// vollständiges RSA Schlüsselpaar und zerstört P und Q.
// Der Inhaber des Schlüssels wird nun eine Nachricht an uns mit unserem öffentlichen RSA
// Schlüssel absetzen. Dazu unterschreibt er seine Nachricht mit seinem Privaten RSA
// Schlüssel und hängt seinen öffentlichen Schlüssel mit der Unterschrift zusammen
// an die Message dran. Wir bekommen also frei Haus das Modul N geliefert aber NICHT
// die Primzahlen P und Q. Nun nutzen wir RecoverRSAKey() und kommen so in Besitz
// des vollständigen RSA Schlüsselpaares des Inhabers. Wir können nun jede verschl.
// Kommunikation an diesen Inhaber sofort entschlüsseln oder seine elektonisch
// signierten Dokumente, wie zB. Verträge, manipulieren und erneut so unterschreiben
// als wären wir die jenige Person.  Oder wir können uns bei jeder Authentifizierung
// die auf diesem Schlüssel basiert einloggen und uns als diese Person ausgeben.
const
  KeySize = 1024;
var
  P,Q,N: IInteger;
  F: Boolean;
begin
  Write(#12#20);

  Write(#2'erzeuge forged RSA Schlüssel : '#0);
  StartTimer;

  BuildForgedRSAKey(P, Q, KeySize);
  NMul(N, P, Q);

  WriteLn(Ticks:10:2, ' ms');
  WriteLn(#0'N: '#1, NStr(N, 16) );

  Write (#2'knacke RSA Schlüssel         : ');

  StartTimer;
// lösche Primzahlen P,Q zur Demonstration
  NSet(P, 0);
  NSet(Q, 0);
  F := RecoverRSAKey(P, Q, N);

  WriteLn(Char(3 + Ord(F)), Ticks:10:2, ' ms, ', F);

  if F then
  begin
    WriteLn(#0'P: '#1, NStr(P, 16) );
    WriteLn(#0'Q: '#1, NStr(Q, 16) );
  end;

  Write(#13#12#2'erzeuge echten RSA Schlüssel : '#0);
  StartTimer;

  BuildRealRSAKey(P, Q, KeySize);
  NMul(N, P, Q);

  WriteLn(Ticks:10:2, ' ms');
  WriteLn(#0'N: '#1, NStr(N, 16) );

  Write (#2'knacke RSA Schlüssel         : ');

  StartTimer;
// lösche Primzahlen P,Q zur Demonstration
  NSet(P, 0);
  NSet(Q, 0);
  F := RecoverRSAKey(P, Q, N);

  WriteLn(Char(3 + Ord(F)), Ticks:10:2, ' ms, ', F);

  if F then
  begin
    WriteLn(#0'P: '#1, NStr(P, 16) );
    WriteLn(#0'Q: '#1, NStr(Q, 16) );
  end;
  WriteLn(#0);
end;

procedure TestRSAAttack;
const
  KeySize = 256;
  QSize   = KeySize div 2;
  PSize   = KeySize - QSize;

var
  P,Q,U: IInteger;
  N: IInteger;
  E1,D1,C1: IInteger;
  E2,D2,C2: IInteger;
  M,X,Y: IInteger;
begin
// bilde RSA Domain, P,Q,N
  repeat
    NRnd(P, PSize);
    NBit(P, PSize -2, True);
    NMakePrime(P, [1, 2]);
    repeat
      NRnd(Q, QSize);
      NBit(Q, QSize -2, True);
      NMakePrime(Q, [1, 2]);
    until NCmp(P, Q) <> 0;
    if NCmp(P, Q) < 0 then NSwp(P, Q);
    NMul(N, P, Q);
  until NSize(N) = KeySize;
  WriteLn('N  : ', NStr(N));

// erzeuge public/private Ver/Entschlüsselung Exponenten
  NDec(P);
  NDec(Q);
  NLCM(U, P, Q);
  repeat
    repeat
      NRnd(E1, NLog2(NSize(N)) * 4);
      NOdd(E1, True);
    until NGCD1(E1, P) and NGCD1(E1, Q);
  until NInvMod(D1, E1, U) and (NSize(D1) >= NSize(E1)) and NGCD1(D1, N);

  repeat
    repeat
      NRnd(E2, NLog2(NSize(N)) * 4);
      NOdd(E2, True);
    until NGCD1(E2, P) and NGCD1(E2, Q) and NGCD1(E1, E2);
  until NInvMod(D2, E2, U) and (NSize(D2) >= NSize(E2)) and NGCD1(D2, N);

  WriteLn('E1 : ', NStr(E1));
  WriteLn('E2 : ', NStr(E2));

  NSet(M, 'unser Geheimnis', 256);

  NPowMod(C1, M, E1, N); // verschlüssele M mit E1
  NPowMod(C2, M, E2, N); // verschlüssele M mit E2

  WriteLn('C1 : ', NStr(C1));
  WriteLn('C2 : ', NStr(C2));

  NGCD(U, X, Y, E1, E2); // erweitertr GCD()

  NPowMod(U, NInt([C1, C2]), NInt([X, Y]), N); // U = C1^X * C2^Y mod N

  WriteLn('M  : ', NStr(M, 256));
  WriteLn('M'' : ', NStr(U, 256)); // U = M
  WriteLn;
end;


// Folgender Code demonstriert den Elliptic Curve Algortihmus PSEC.
// PSEC ist ein Public Key Algorithmus der zur Verschlüsselung von
// Daten dienen kann und die Elliptischen Kurven über GF(p) nutzt.

const
  PSEC_HashClass: TDECHashClass = THash_SHA1;  // Hash Klasse die PSEC verwenden soll
  PSEC_HashIndex = 1;			    // Index der Hashbasierten MGF = Mask Generation Funktion

procedure PSEC_BuildCurve(var E: IGFpECC; Size: Integer = 192);
// erzeugt eine Elliptische Kurve für PSEC
begin
  NECBuild(E, Size, 1, Normal, 31, PSEC_HashClass);
end;

procedure PSEC_BuildKeyPair(var S,P: IInteger; const E: IGFpECC);
// erzeugt ein Schlüsselpaar
// S = secret key
// P = public key
// der Aufruf von NECCheck() kann überall entfernt werden wenn
// diese Überprüfung nach dem Laden der Kurve erfolgte, dies würde Zeit sparen
var
  T: I2Point;
begin
//  NECCheck(E.EC, True);
  NRnd(S, NSize(E.R));
  NMod(S, E.R);
  NMul(T, E.G, S, E.EC);
  NSet(P, T);
end;

procedure PSEC_OTP(var C: IInteger; const M,K: IInteger);
// Die symmetrische Verschlüsselungsfunktion im PSEC Verfahren.
// Hier nutzen wir eine OTP hashbased MGF Verschlüsselung
// Die Message M wird mit einem OTP der mithilfe einer MGF aus dem Schlüssel K erzeugt
// wurde verschlüsselt
var
  O: IInteger;
begin
  NHash(O, K, PSEC_HashClass, NSize(M, piByte) * 8, PSEC_HashIndex);
  NXor(C, M, O);
end;

procedure PSEC_Encrypt(var H: IInteger; const M,P: IInteger; const E: IGFpECC;
			 const PSEC_P: IGFpMulPrecomputation = nil;
			 const PSEC_G: IGFpMulPrecomputation = nil);
// verschlüsselt M mit dem public key P in H
// dabei wird in H zusätzlich eine Signatur über alle relevanten Information
// eingebettet
var
  R,L,O,C,K: IInteger;
  U: I2Point;
  HashSize,KeySize: Integer;
begin
  NSet(H, 0);			// sanity
//  NECCheck(E.EC, True);

  HashSize := PSEC_HashClass.DigestSize * 8;
  KeySize := NSize(E.EC.P);

  NRnd(R, KeySize);		// R, der wichtigste Teil ein Zufallskey
  NMod(R, E.EC.P);

  PSEC_OTP(K, M, R);		// mit dem verschlüsseln wir Message M per MGF-OTP

  NRnd(L, NSize(E.R));		// r, in den docus
  NMod(L, E.R);

  NSet(U, P, E.EC);		// expandiert die komprimierte Form eines Punktes in P
  NMul(U, L, E.EC, PSEC_P);	// T = r * pk, hier U genannt
  NXor(O, U.X, R);		// c'1 = xT xor R, c'1 ist hier O, nochmal ein OTP um T.X zu verstecken

  NMul(U, E.G, L, E.EC, PSEC_G);// C1 = r * P
  NSet(C, U);			// C = C1 laut docu, wir komprimieren die Darstellung eines Punktes auf der Kurve

  NCat(H, NInt([C, O, R, M]));	// Hash über alle relevanten Werte, dient als Unterschrift zur Überprüfung
  NHash(H, PSEC_HashClass);	// H = Hash(C || O || R || M);

  NShl(K, KeySize +1);		// H = K=OTP(M, R) || C(192 +1) || O(192) || Hash(C || O || R || M)
  NAdd(C, K);			// enthält alle Teile der Signature und verschlüsselten Daten
  NShl(C, KeySize);
  NAdd(O, C);
  NShl(O, HashSize);
  NAdd(H, O);

  NRnd(R, KeySize);		// R wird überschrieben

{ beide NMul()'s oben lassen sich beschleunigen, wenn man
  1. zum Public Key P des Empfängers eine Precomputation nutzt
  2. zum Basepoint G der Kurve eine Precomputation nutzt
  3. statt einer Precomputation könnte man eine multiple Multiplication nutzen, die
     ist aber nicht implementiert

  1. & 2. beschleunigen den Verschlüsselungsprocess um 50%
}
end;

function PSEC_Decrypt(var M: IInteger; const H,S: IInteger; const E: IGFpECC): Boolean;
// entschlüssle aus H mit dem secret key S die Message M
// zusätzlich wird überprüft ob die Message nicht verändert wurde, d.h. es wird die
// Authentizität überprüft.
var
  R,C,O,K: IInteger;
  U: I2Point;
  HashSize,KeySize: Integer;
begin
  NSet(M, 0);					  // sanity
//  NECCheck(E.EC, True);

  HashSize := PSEC_HashClass.DigestSize * 8;
  KeySize := NSize(E.EC.P);
						  // extrahiere aus H alle 3 relevanten Werte
  NCpy(O, H, KeySize, HashSize);		  // O = c'1 = T.x xor R
  NCpy(C, H, KeySize + 1, KeySize + HashSize);	  // C = C1 = r * P, kann invertiert werden durch S
  NCpy(K, H, MaxInt, KeySize * 2 + 1 + HashSize); // K = OTP(M, R), verschlüsselte Message

  NSet(U, C, E.EC);				  // expandiere C in Punkt
  NMul(U, S, E.EC);				  // math. Entschlüsselung von r * P
  NXor(R, O, U.X);				  // errechne den wichtigen Zufallswert R

  PSEC_OTP(M, K, R);				  // mit R als Key wird K zu M entschlüsselt

  NCat(C, NInt([C, O, R, M]));			  // aus allen Params wird nun die Signature erzeugt
  NHash(C, PSEC_HashClass);

  Result := NCmp(H, C, HashSize) = 0;		  // und mit der in der nachricht enthaltenen verglichen
end;

procedure PSEC_Precompute(var PPre, GPre: IGFpMulPrecomputation; const P: IInteger; const E: IGFpECC);
var
  T: I2Point;
begin
  NSet(T, P, E.EC);
  NSet(PPre, T, E.EC, NSize(E.EC.P));
  NSet(GPre, E.G, E.EC, NSize(E.EC.P));
end;

procedure PSEC;
// PSEC Scheme, im Grunde nichts anderes als ElGamal in EC, aber die NTT Experten nehmen sich wichtig.
var
  E: IGFpECC;  // Elliptische Kurve
  S: IInteger; // secret Key, random
  P: IInteger; // public Key
  M: IInteger; // plaintext message, input
  D: IInteger; // plaintext message, output
  C: IInteger; // ciphertext message

  PPre: IGFpMulPrecomputation;
  GPre: IGFpMulPrecomputation;

begin
  WriteLn(#12);

  StartTimer;

  PSEC_BuildCurve(E);		      // erzeuge eine Kurve, normalerweise werden Kurven gemeinsam benutzt
  PSEC_BuildKeyPair(S, P, E);	      // erzeuge ein EC Schlüsselpaar
  PSEC_Precompute(PPre, GPre, P, E);  // ausklammern für keine Precomputation, beschleunigt

  WriteLn('Schlüssel&EC Erzeugung :', Ticks:10:2, ' ms');
  WriteLn;

  NSet(M, 'ECC Verschlüsselung', 256); // Message die verschl. werden soll

  StartTimer;

  PSEC_Encrypt(C, M, P, E, PPre, GPre);

  WriteLn('PSEC Verschlüsselung   :', Ticks:10:2, ' ms');
  WriteLn('M   : ', NSize(M):4, ', ', NStr(M, 16));
  WriteLn('C   : ', NSize(C):4, ', ', NStr(C, 16), ', ', NSize(C, piByte));
  WriteLn;

  StartTimer;
  if PSEC_Decrypt(D, C, S, E) then
  begin
    WriteLn('PSEC Entschlüsselung   :', Ticks:10:2, ' ms');
    WriteLn('D	 : ', NSize(D):4, ', ', NStr(D, 16));
    WriteLn( NStr(D, 256) );
  end else WriteLn(#3'fehlgeschlagen !'#0);

end;

procedure DH;
// demonstriert den Diffie Hellman Schlüsselaustausch in Z(p)
var
  P,Q,G,T: IInteger;	  // Primzahl P und primitiver Generator G
  Sa,Sb: IInteger;    // secrets von Alice und Bob, empheral keys
  Pa,Pb: IInteger;    // publics von Alice und Bob über unsichere Leitung übertragen
  Ka,Kb: IInteger;    // secret key

//  ID: IIDPrime;
begin
// Erzeuge Primzahl P, wobei P eine Safe Prime ist eine sogenannte Sophie Germain Prime.
// Somit ist Q = (P-1)/2 ebenfalls eine Primzahl.
// Der Generator G muß primitiv zu P sein.
// Da P = 2*Q+1 ist die Order von G gleich Q.

  Write(#2'DH Parmeter	    : '#0);
  StartTimer;

// erzeuge Primzahl jedesmal zufällig neu, was länger dauert
//  NRnd(P, 1024);
//  NMakePrime(P, [1, 2], 1, 1);

// oder benutze vorgefertigte und verifizierbare ID basierte Primzahlen
  NSet(P, NIDPrime('1024:1:1:SHA1:1:52A3568A:E746:4206'));

// mit nachfolgendem Code werden solche ID Primes erzeugt, siehe IDPrimes.pas
//  P := NMake(ID, 1024, 31, NInt(1), NInt(1));
//  WriteLn( NStr(ID) );

// Erzeuge Generator G, dies sollte meiner Meinung nach jedesmal neu geschehen.
// D.h. das dadurch der Generator G auch explizit überprüft wird.
// Der Generator G muß ein eine primitve Wurzel in P sein. Da P eine Safe Prime ist
// wissen wir auch die Order von G. Sie ist exakt (P-1)/2 = Q, da Q ebenfalls prim ist.
// G^2 mod P <> 1 mod P und G^Q mod P <> 1 mod P sein.
  NSet(Q, P);
  NDec(Q);
  NDiv(Q, 2);
  NSet(G, 1);
  repeat
    NInc(G);
    NSqrMod(T, G, P);
    if NCmp(T, 1) = 0 then Continue;
    NPowMod(T, G, Q, P);
  until NCmp(T, 1) <> 0;

  WriteLn(Ticks:10:2, ' ms ');
  WriteLn('P  : ', NStr(P, 16) );
  WriteLn('G  : ', NStr(G, 16) );
  WriteLn;

// Alice erzeugt zufälliges Geheimnis Sa und berechnet Pa = G^Sa mod P
  Write(#2'Alice erzeugt Pa : '#0);
  StartTimer;

  repeat
    NRnd(Sa, NHigh(P));
  until NSgn(Sa) > 0;
  NPowMod(Pa, G, Sa, P);

  WriteLn(Ticks:10:2, ' ms');

// Bob erzeugt zufälliges Geheimnis Sb und berechnet Pb = G^Sb mod P
  Write(#2'Bob erzeugt Pb   : '#0);
  StartTimer;

  repeat
    NRnd(Sb, NHigh(P));
  until NSgn(Sb) > 0;
  NPowMod(Pb, G, Sb, P);

  WriteLn(Ticks:10:2, ' ms');

// Alice sendet Pa an Bob
// Bob sendet Pb an Alice

// Alice erzeugt geheimen Schlüssel Ka = Pb^Sa mod P
  Write(#2'Alice erzeugt Ka : '#0);
  StartTimer;

  NPowMod(Ka, Pb, Sa, P);

  WriteLn(Ticks:10:2, ' ms');
  WriteLn(#2'Ka : '#0, NStr(Ka, 16) );

// Bob erzeugt geheimen Schlüssel Kb = Pa^Sb mod P
  Write(#2'Bob erzeugt Kb   : '#0);
  StartTimer;

  NPowMod(Kb, Pa, Sb, P);

  WriteLn(Ticks:10:2, ' ms');
  WriteLn(#2'Kb : '#0, NStr(Kb, 16) );
  WriteLn;

// Ka,Kb können nun als Passwort zur Verschlüsselung der Daten benutzt werden.
// Auf eine ganz wichtige Sache muß noch hingewiesen werden. Das hier gezeigte
// Diffie Hellman Verfahren ist das Grundverfahren und ermöglicht spezielle Angriffe.
// Zb. die "Man in the middle attack" ist ein Angriff bei dem eine dritte Partei,
// genannt "NSA", die Kommunikation zu jeder Zeit zwischen Alice und Bob abfangen kann.
// NSA wird sich also als dritte unendeckte Partei am Schlüsselaustausch beteiligen.
// Dabei tritt er gegenüber Alice als Bob auf, und gegenüber Bob als Alice. Bei der
// anschließenden Datenübertragung von verschl. Daten von Alice zu Bob wird NSA
// die Nachricht von Alice entschlüsseln, verändern und mit dem Schlüssel für Bob
// wieder verschlüsseln und an Bob weiterleiten.
// Es gibt DH Verfahren die diesen Angriff von NSA abwehren können.

// Mit meiner Elliptic Curve Library ließe sich ein EC-DH umsetzen. Diese Version
// wäre wesentlich eiffizienter und würde mit z.b. 196 Bit Primzahlen die Sicherheit
// wie ein 1024 Bit DH hier gezeigt ermöglichen. D.h. die Sicherheit wäre mit
// kleineren Werte höher und dementsprechend der Datenaustausch schneller und
// er käme mit einer geringeren Datenmenge aus.

// Für die Erzeugung vom Generator G gibt es noch andere Verfahren, so ähnlich
// wie meine ID Primes. Dies ist von Vorteil bei Speichern und Austausch der
// festen DH Paramter P und G.

// nochmal kompakter
// DH Domain
  NSet(P, NIDPrime('1024:1:1:SHA1:1:52A3568A:E746:4206'));
  NSet(Q, P);
  NDec(Q);
  NDiv(Q, 2);
  NSet(G, 1);
  repeat
    NInc(G);
    NSqrMod(T, G, P);
    if NCmp(T, 1) <> 0 then
      NPowMod(T, G, Q, P);
  until NCmp(T, 1) <> 0;

// Alice
  repeat
    NRnd(Sa, NHigh(P));
  until NSgn(Sa) > 0;
  NPowMod(Pa, G, Sa, P);
// Bob
  repeat
    NRnd(Sb, NHigh(P));
  until NSgn(Sb) > 0;
  NPowMod(Pb, G, Sb, P);
  NPowMod(Kb, Pa, Sb, P);
// Alice
  NPowMod(Ka, Pb, Sa, P);

end;

procedure DHEC;
// Diffie Hellman Schlüsselaustausch in Elliptischen Kurven über GF(p).
// Eine 192 Bit Kurve ist weitaus sicherer als z.B. ein 1024 Bit DH in Z(p).
var
  E: IGFpECC;			 // elliptische Kurve über GF(p)
  C: IGFpMulPrecomputation;	 // Precomputation um die Multiplikation mit G als Basis zu beschleunigen
  Sa,Sb: IInteger;		 // secrets Alice&Bob, bilden den gemeinsammen Schlüssel K = G^(Sa*Sb) mod P
  Ta,Tb: IInteger;		 // öffentliche Austausch parameter von Alice und Bob
  Pa,Pb: I2Point;
  Ka,Kb: I2Point;		 // gemeinsamer berechneter Schlüssel
begin
  Write(#2'DH-EC Parmeter   : '#0);
  StartTimer;

  NECBuild(E, 192);
  NSet(C, E.G, E.EC, 192);

  WriteLn( Ticks:10:2 );

// Alice
  Write(#2'Alice erzeugt Pa : '#0);
  StartTimer;

  repeat
    NRnd(Sa, NSize(E.R));
  until NSgn(Sa) > 0;
  NMul(Pa, E.G, Sa, E.EC, C);
  NSet(Ta, Pa); 		   // komprimiert Punkt in Pa in Ta, dadurch 50% weniger Datenvolumnen

  WriteLn( Ticks:10:2 );

// Bob
  Write(#2'Bob erzeugt Pb   : '#0);
  StartTimer;

  repeat
    NRnd(Sb, NSize(E.R));
  until NSgn(Sb) > 0;
  NMul(Pb, E.G, Sb, E.EC, C);
  NSet(Tb, Pb);

  WriteLn( Ticks:10:2 );

// jetzt werden Ta und Tb untereinander zwischen Alice und Bob ausgetauscht

// Alice
  Write(#2'Alice erzeugt Ka : '#0);
  StartTimer;

  NSet(Ka, Tb, E.EC);
  NMul(Ka, Sa, E.EC);

  WriteLn( Ticks:10:2 );

// Bob
  Write(#2'Bob erzeugt Kb   : '#0);
  StartTimer;

  NSet(Kb, Ta, E.EC);
  NMul(Kb, Sb, E.EC);

  WriteLn( Ticks:10:2 );

  WriteLn(#2'Ka : '#0, NStr(Ka.X, 16));
  WriteLn(#2'Kb : '#0, NStr(Kb.X, 16));
end;

function NPollardRho(var D: IInteger; const N: IInteger): Boolean;
const
  MaxLoop = 2048;
  MaxProd = 100;
var
  X,Y,Z: IInteger;
  I,J,K: Cardinal;
begin
  Result := True;
  NRnd(X, NHigh(N));
  NSet(D, 1);
  K := 1;
  repeat
    NSet(Y, X);
    for I := 1 to K * MaxProd do
    begin
      NSqr(X);       // X := (X² + 1) mod N
      NInc(X);
      NMod(X, N);
    end;
    for I := 1 to K do
    begin
      for J := 1 to MaxProd do
      begin
        NSqr(X);       // X := (X² + 1) mod N
        NInc(X);
        NMod(X, N);
        NSub(Z, X, Y); // D := (X - Y) * D mod N
        NMulMod(D, Z, N);
      end;
      if not NGCD(D, D, N) then Exit;
    end;
    Inc(K, K);
  until K > MaxLoop;
  Result := False;
end;

function NPollardPM1(var D: IInteger; const N: IInteger; Bound: Cardinal = 0): Boolean;
const
  Delta = 16;
var
  X,E: IInteger;
  I,J,P: Cardinal;
  LnMax: Double;
begin
  Result := True;
  if Bound = 0 then Bound := Primes.MaxPrime;
  NRnd(X, NHigh(N));
  NSet(D, X);
  if not NGCD(D, D, N) then Exit;
  LnMax := Ln(Bound);
  I := 0;
  P := 0;
  repeat
    NSet(E, 1);
    for J := I +1 to I + Delta do
    begin
      P := Primes[J];
      NPow(D, P, Trunc(LnMax / Ln(P)));
      NMul(E, D);
    end;
    NPowMod(X, E, N);
    NSet(D, X);
    NDec(D);
    if not NGCD(D, D, N) then Exit;
    Inc(I, Delta);
  until P > Bound;
  Result := False;
end;

function NWilliamsPP1(var D: IInteger; const N: IInteger): Boolean;
const
  LoopCount = 16;
  MaxCount = LoopCount * 250;
var
  I: Cardinal;
  K: IInteger;
begin                                
  NRnd(D, NSize(N));
  NMod(D, N);
  NSet(K, 0);
  while NGCD1(D, N) and (NCmp(K, MaxCount) <= 0) do
  begin
    NInc(D, 2);
    for I := 1 to LoopCount do
    begin
      NInc(K);
      NLucasMod(D, K, NOne, N);
    end;
    NDec(D, 2);
  end;
  Result := (NCmp(D, 0) > 0) and not NGCD(D, D, N);
end;

procedure TestPollard;
var
  N,D: IInteger;
  R: Boolean;
begin
  NRnd(N, 256);
  NOdd(N, True);

  WriteLn( NIsProbablePrime(N), ', ', NStr(N) );
  StartTimer;
  R := NPollardRho(D, N);
  WriteLn(R, ', ', Ticks:10:2, ' ms, ', NStr(D));

  StartTimer;
  R := NPollardPM1(D, N, $10000);
  WriteLn(R, ', ', Ticks:10:2, ' ms, ', NStr(D));

  StartTimer;
  R := NWilliamsPP1(D, N);
  WriteLn(R, ', ', Ticks:10:2, ' ms, ', NStr(D));
  WriteLn;
end;

procedure TestSRP;
var
  Server: ISRPServer;
  Client: ISRPClient;
  Msg,RegistrationKey: WideString;
begin
  WriteLn(#13#10#2'Counter-SRP Test'#0#13#10);

  Server := SRPServer(SRPDatabase);
  Client := SRPClient;

// server registrate a new client an sends back a empheral registration passwort
  RegistrationKey := Server.RegisterClient('Hagen');

  WriteLn('Reg-Key    : ', String(RegistrationKey), #13#10);

// first login of client after registration with new password
  Msg := Client.Step0('Hagen', RegistrationKey, 'Password'); // Client sends Msg to Host
  Msg := Server.Step0(Msg);                                  // Server receive Msg and send new Msg to Client
  Msg := Client.Step1(Msg);                                  // and so on...
  Msg := Server.Step1(Msg);
  Msg := Client.Step2(Msg);
  WriteLn('Server-Key : ', String(Server.SharedSecret));
  WriteLn('Client-Key : ', String(Client.SharedSecret));

  Msg := Client.Step0('Hagen', 'Password');
  Msg := Server.Step0(Msg);
  Msg := Client.Step1(Msg);
  Msg := Server.Step1(Msg);
  Msg := Client.Step2(Msg);

  WriteLn('Server-Key : ', String(Server.SharedSecret));
  WriteLn('Client-Key : ', String(Client.SharedSecret));

  Msg := Client.Encrypt('Test Message to transmit to server');
  WriteLn('Ciphertext : ', String(Msg));
  Msg := Server.Decrypt(Msg);
  WriteLn('Plaintext  : ', String(Msg));
// second encryption with same message, show the use of Salt in encryption
  Msg := Client.Encrypt('Test Message to transmit to server');
  WriteLn('Ciphertext : ', String(Msg));
  Msg := Server.Decrypt(Msg);
  WriteLn('Plaintext  : ', String(Msg));

  StartTimer;
  Msg := Client.Step0('Hagen', 'Password', 'Password1');
  Msg := Server.Step0(Msg);
  Msg := Client.Step1(Msg);
  Msg := Server.Step1(Msg);
  Msg := Client.Step2(Msg);
  WriteLn( Ticks:10:2 );
  WriteLn('Server-Key : ', String(Server.SharedSecret));
  WriteLn('Client-Key : ', String(Client.SharedSecret));

  StartTimer;
  Msg := Client.Step0('Hagen', 'Password1');
  Msg := Server.Step0(Msg);
  Msg := Client.Step1(Msg);
  Msg := Server.Step1(Msg);
  Msg := Client.Step2(Msg);
  WriteLn( Ticks:10:2 );
  WriteLn('Server-Key : ', String(Server.SharedSecret));
  WriteLn('Client-Key : ', String(Client.SharedSecret));

// show invalid login Exception
  Msg := Client.Step0('Hagen', 'Password2', 'Password2');
  Msg := Server.Step0(Msg);
  Msg := Client.Step1(Msg);
  Msg := Server.Step1(Msg);
  Msg := Client.Step2(Msg);
  WriteLn('Server-Key : ', String(Server.SharedSecret));
  WriteLn('Client-Key : ', String(Client.SharedSecret));
end;


// demonstration of DEC's Progress Callback
type
  TProgress = class(TInterfacedObject, IDECProgress)
    FBar: TProgressBar;
    procedure Process(const Min,Max,Pos: Int64); stdcall;
    constructor Create;
    destructor Destroy; override;
  end;

procedure TProgress.Process(const Min,Max,Pos: Int64);
var
  P: Integer;
begin
  P := Trunc((Pos - Min) / (Max - Min) * 100);
  if P <> FBar.Position then
  begin
    FBar.Left := ConsoleMainForm.Status.Panels[0].Width +2;
    FBar.Position := P;
    FBar.Update;
  end;
  NCalcCheck;
end;

constructor TProgress.Create;
begin
  inherited Create;
  FBar := TProgressBar.Create(nil);
  FBar.BorderWidth := 2;
  FBar.Left := ConsoleMainForm.Status.Panels[0].Width +2;
  FBar.Top := 2;
  FBar.Height := ConsoleMainForm.Status.Height -2;
  FBar.Min := 0;
  FBar.Max := 100;
  FBar.Width := 208;
  FBar.Parent := ConsoleMainForm.Status;
  FBar.Update;
end;

destructor TProgress.Destroy;
begin
  FreeAndNil(FBar);
  inherited Destroy;
end;

procedure TestProgress;
var
  P: IDECProgress;
begin
  WriteLn(#2'Test Progressbar into Statusbar'#0);
  P := TProgress.Create;
  THash_SHA1.CalcFile('g:\win386.swp', TFormat_Copy, P);
  THash_SHA1.CalcFile('h:\primes.cache', TFormat_Copy, P);
end;


function NRootX(var A,R: IInteger; const B: IInteger; E: Integer): Boolean; overload;
var
  I: Integer;
  T,S: IInteger;
begin
  Result := True;
  I := E;
  NSet(T, B);
  while not Odd(I) do
  begin
    if not NSqrt(T) then Result := False;
    I := I shr 1;
  end;
  if I > 1 then
    if not NRoot(T, I) then Result := False;
  if not Result then
  begin
    NPow(S, T, E);
    NSub(R, B, S);
  end else NSet(R, 0);
  NSwp(T, A);
end;

procedure TestRoot;
var
  A,B,R: IInteger;
begin
  NRnd(A, 1024);
  NPow(A, 9);
  NInc(A);
  StartTimer;
  WriteLn(NRoot(B, R, A, 9));
  WriteLn(Ticks:10:3);
  WriteLn( NCRC(B):16, NCRC(R):16 );

  StartTimer;
  WriteLn(NRootX(B, R, A, 9));
  WriteLn(Ticks:10:3);
  WriteLn( NCRC(B):16, NCRC(R):16 );
end;


procedure NPiX(var A: IInteger; Decimals: Cardinal);

  function NSum(var N,D: IInteger; Precision: Cardinal): Cardinal;
  var
    S: array[0..3*32-1] of IInteger;
    I,J,K: Cardinal;
    C,E,P,Q,Alpha,Beta,Gamma,Delta,Eps,T,U: IInteger;
  begin
    Result := 0;
    NSet(E, 10939058860032000);
    NSet(Alpha, 1);
    NSet(Beta, 1);
    NSet(Gamma, 5);
    NSet(Delta, 53360);
    NSet(Eps, 13591409);
    NSet(Q, 1);
    K := 0;
    for I := 1 to (Precision + 197) div 94 do
    begin
      NMul(S[K], Alpha, Beta);
      NMul(S[K], Gamma);

      NSwp(S[K +1], Delta);

      NInc(Alpha, 2);
      NInc(Beta, 6);
      NInc(Gamma, 6);

      NAdd(P, Q);
      NInc(Q, 2);
      NAdd(C, E);

      NMul(Delta, P, C);

      NMul(T, Eps, Delta);
      NInc(Eps, 545140134);
      NMul(U, S[K], Eps);
      NSub(S[K +2], T, U);

      NMul(T, Alpha, Beta);
      NMul(U, S[K], Gamma);
      NMul(S[K], T, U);

      NMul(S[K +1], Delta);

      NInc(Alpha, 2);
      NInc(Beta, 6);
      NInc(Gamma, 6);

      NAdd(P, Q);
      NInc(Q, 2);
      NAdd(C, E);
      NMul(Delta, P, C);
      NInc(Eps, 545140134);

      J := I;
      while not Odd(J) do
      begin
        J := J shr 1;
        NMul(T, S[K +1], S[K -1]);
        NMul(S[K -1], S[K -3], S[K +2]);
        NAdd(S[K -1], T);                     // S[k-3] * S[k +2] + S[k +1] * S[k -1]
        NMul(S[K -3], S[K]);                  // S[k-3] * S[k]
        NMul(S[K -2], S[K +1]);               // S[k-2] * S[k +1]
        Dec(K, 3);
      end;
      Inc(K, 3);
    end;
    Dec(K, 3);
    while K <> 0 do
    begin
      Dec(K, 3);
      NMul(T, S[K +4], S[K +2]);
      NMul(S[K +2], S[K], S[K +5]);
      NAdd(S[K +2], T);             // S[k] * S[k +5] + S[k +2] * S[k +4]
      NMul(S[K +1], S[K +4]);
    end;
    NSwp(N, S[1]);
    NSwp(D, S[2]);
  end;

var
  N,D: IInteger;
begin
  NSet(A, 5);
  NPow(A, Decimals);
  NSum(N, D, Cardinal(NSize(A)) + Decimals);
  NSqr(A);
  NMul(A, 640320);
  NShl(A, Decimals + Decimals);
  NSqrt(A);
  NMul(A, N);
  NDiv(A, D);
end;

procedure Test;
begin

end;

initialization
  SetDefaultHashClass(THash_SHA1);


  RegisterProc('\Sqrt\Test Root', '', TestRoot, vk_F8);

  RegisterProc('\SRP\Counter-SRP Test', '', TestSRP);
  RegisterProc('\Faktorization\Test Pollard Rho', '', TestPollard);

  RegisterProc('\DH\Diffie Hellman in Z(p)', '', DH);
  RegisterProc('\DH\Diffie Hellman in GF(p)', '', DHEC);

  RegisterProc('\ECC\PSEC Verschlüsselung', '', PSEC);

  RegisterProc('\Test\Step 1 basic', '', Step1);
  RegisterProc('\Test\Step 2 Pi', '', Step2);
  RegisterProc('\Test\Step 3 Sqrt(2)', '', Step3);
  RegisterProc('\Test\Step 4 N!', '', Step4);
  RegisterProc('\Test\Step 5 Brüche', '', Step5);
  RegisterProc('\Test\Step 6 modulare Polynome', '', Step6);
  RegisterProc('\Test\Step 6 RSA Verschlüsselung', '', Step7);

  RegisterProc('\RSA\mit zufälligem Exponenten', '', RSARandomE);
  RegisterProc('\RSA\mit Exponent 17', '', RSAFixE);
  RegisterProc('\RSA\Attack', '', TestRSAAttack);
  RegisterProc('\RSA\don''t trust it anywhere', '', ForgedRSA);

  RegisterProc('\Others\Speed Test', '', SpeedTest);
  RegisterProc('\Others\Vectors', '', Vectors);
  RegisterProc('\Others\Automorphe Zahlen', '', Automorphic);
  RegisterProc('\Others\Primality tests', '', TestSPP);
  RegisterProc('\Others\Progress Test', '', TestProgress);
end.
