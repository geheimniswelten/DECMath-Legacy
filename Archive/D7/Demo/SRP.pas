{Copyright:      Hagen Reddmann  HaReddmann at T-Online dot de
 Author:         Hagen Reddmann
 Remarks:        this Copyright must be included
 known Problems: none
 Version:        5.1,  Part II from Delphi Encryption Compendium
                 Delphi 5
 Description:    Counter-SRP, modified Secure Remote Password Protocoll
                 based on SRP-6a

                 All Interfaced are declared to support own DLL's to
                 other languages that supports COM Objects. Thus the use of
                 WideString.

                 Normaly the programmer provide a custom ISRPDatabase Interface
                 to he's own Database of Users. Such Database have only two
                 columns -> Identifier and Data of type String.

                 Here we provide two such ISRPDatabase Impelmentation:
                 - in textbased INI Files
                 - in Registry of current user

                 The ISRPDatabase Interface are most globaly used and must provide
                 a threadsafe way to access the records, eg. should use RTL-
                 Critical Sections.

                 The ISRPServer and ISRPClient are only allocated live in the
                 Connections Threads of our TCP/IP Library, as example iff we use
                 INDY componnents the we allocate these Interfaces in the threaded
                 TCP/IP Method of TidTCPServer and TidTCPClient.

                 This is because that a ISRPClient/ISRPSever Interface holds only
                 one current session of one attemp for secret sharing.

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
{$I VER.INC}
unit SRP;

interface

type
  ISRPDatabase = interface
    ['{FCFBEF2F-1C57-401D-BACC-10CDC6252A78}']
    function Lookup(const Ident: WideString): WideString; stdcall;
    procedure Store(const Ident, Data: WideString); stdcall;
    procedure Delete(const Ident: WideString); stdcall;
  end;

  TSRPState = (srpNone, srpStep0, srpStep1, srpFinish);

  ISRPServer = interface
    ['{82A45C14-A133-4C26-AF61-DA1DD59AB3EE}']
    function State: TSRPState; stdcall;
    function SharedSecret: WideString; stdcall;
    function Counter: Cardinal; stdcall;
    function Identifier: WideString; stdcall;
    function Encrypt(const Msg: WideString): WideString; stdcall;
    function Decrypt(const Msg: WideString): WideString; stdcall;
    function Step0(const Msg: WideString): WideString; stdcall;
    function Step1(const Msg: WideString): WideString; stdcall;
    function RegisterClient(const Name: WideString): WideString; stdcall;
  end;

  ISRPClient = interface
    ['{A690EE81-A46A-4FC9-B55F-88EE3D665E6C}']
    function State: TSRPState; stdcall;
    function SharedSecret: WideString; stdcall;
    function Counter: Cardinal; stdcall;
    function Identifier: WideString; stdcall;
    function Encrypt(const Msg: WideString): WideString; stdcall;
    function Decrypt(const Msg: WideString): WideString; stdcall;
    function Step0(const Name: WideString; const OldPassword: WideString; const NewPassword: WideString = ''): WideString; stdcall;
    function Step1(const Msg: WideString): WideString; stdcall;
    function Step2(const Msg: WideString): WideString; stdcall;
  end;

// these functions should be exported if a DLL is used
function SRPDatabase(InRegistry: Boolean = False): ISRPDatabase; stdcall;
function SRPServer(const ADatabase: ISRPDatabase): ISRPServer; stdcall;
function SRPClient: ISRPClient; stdcall;

implementation
(*
Counter-SRP-6

SecureBits            = integer
MGF([data])           = hash based Mask Generation Function, creates SecureBits length result
                        from a set of input parameters
MGF([data], index)    = MGF with Index > 0
OTP(data, key, index) = hash based One Time Pad, use an indexed KDF
RND()                 = secure random generator, produce SecureBits result

Name                  = plaintext Name of Client
I                     = Identifier of Client
S,S'                  = random Password Salt, SecureBits long
Sp                    = public OTP encrypted Salt
V,V'                  = Password Verifier
Vp                    = public OTP encrypted Verifier
P,P'                  = client passwords, old and new
C                     = incremental Counter, 32 Bits long, used as Index in the MGF
N                     = large Safe Prime, so called Sophie Germain Prime
g                     = Generator, > 3
k                     = hased security value
ID                    = string thats represent N,G,K in safe manner
b,B                   = empheral server keys, secret and public
a,A                   = empheral client keys, secret and public
K                     = shared secret key
Kd                    = derivate of K
???                   = question


 CLIENT                                   SERVER

 I  = MGF([Name])

                          -----------> I
                                          lookup I,S,V,C,ID in Database
                                          N,g = IDPrime(ID)
                                          k   = MGF([N, g])
                                          b   = RND()
                                          B   = k*V+g^b
                          S,C,B,ID <---
 B   = 0 ??? abort else ok

 N,g = IDPrime(ID)
 k   = MGF([N, g])

 x   = MGF([S, I, P], C)
 V   = g^x

 a   = RND()
 A   = g^a
 u   = MGF([A, B], C)
 K   = (B-k*V)^(a+u*x)

 S'  = RND()
 x'  = MGF([S', I, P'], C +1)
 V'  = g^x'

 Vp  = OTP(V', K, C +1)
 Sp  = OTP(S', K, C +1)

 Mc  = MGF([A, B, S', V'])
                          ----> Mc,A,Sp,Vp
                                         A  = 0 ??? abort else ok
                                         u  = MGF([A, B], C)
                                         K  = (A*V^u)^b

                                         S' = OTP(Sp, K, C +1)
                                         V' = OTP(Vp, K, C +1)

                                         M' = MGF([A, B, S', V'])
                                         M' = Mc ??? ok else abort

                                         Mh = MGF([A, B, S', V', Mc])
                                         store
                                           I,S=S',V=V',C=C+1
                          Mh <---------
 M' = MGF([A, B, S', V', Mc])
 M' = Mh ??? ok else abort

 Kd = MGF([K])                            Kd = MGF([K])
                          <-Data encrypted->
*)

uses Windows, SysUtils, Registry, INIFiles, DECUtil, DECFmt, DECHash, DECCipher,
     DECRandom, NMath, NInts, IDPrimes;

const
  SRP_HashClass   : TDECHashClass = THash_SHA1;
  SRP_CipherClass : TDECCipherClass = TCipher_Blowfish;
  SRP_SecureBits  : Integer = 256;
  SRP_Separator   : String = ';';                          // don't use same separator as for ID-Primes !!
  SRP_Format      : TStrFormat = (
    Base: 64;
    Plus: '';
    Minus: '';
    Zero: '';
    Comma: ',';
    DigitsPerBlock: 0;
    BlockSep: #0;
    BlockPadding: #0;
    DigitsPerLine: 0;
    LineSep: #13#10;
    LinePadding: #0;
    DigitsChars: 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    FormatChars: ' /\-+;:#~"()[]?_<>!§$%&{}'''#13#10#9;
    LeftAlign: False;
    Offset: 0;
    Precision: 0;
   );

// implementations
type
  ESRPException = class(Exception);

  TSRPDomain = packed record
    ID: String;
    N,Q,G,K: IInteger;
  end;

  TSRPBaseDatabase = class(TInterfacedObject)
  private
    FCriticalSection: TRTLCriticalSection;
    function DoLookup(const Ident: WideString): WideString; virtual; abstract;
    function DoStore(const Ident, Data: WideString): WideString; virtual; abstract;
    procedure DoDelete(const Ident: WideString); virtual; abstract;
  public
    function Lookup(const Ident: WideString): WideString; stdcall;
    procedure Store(const Ident, Data: WideString); stdcall;
    procedure Delete(const Ident: WideString); stdcall;
    constructor Create;
    destructor Destroy; override;
  end;

  TSRPDatabaseINI = class(TSRPBaseDatabase, ISRPDatabase)
  private
    FFile: TINIFile;
    function DoLookup(const Ident: WideString): WideString; override;
    function DoStore(const Ident, Data: WideString): WideString; override;
    procedure DoDelete(const Ident: WideString); override;
  public
    constructor Create;
    destructor Destroy; override;
  end;

  TSRPDatabaseRegistry = class(TSRPBaseDatabase, ISRPDatabase)
  private
    FFile: TRegINIFile;
    function DoLookup(const Ident: WideString): WideString; override;
    function DoStore(const Ident, Data: WideString): WideString; override;
    procedure DoDelete(const Ident: WideString); override;
  public
    constructor Create;
    destructor Destroy; override;
  end;

  TSRPBase = class(TInterfacedObject)
  private
    FDomain: TSRPDomain;         // domain parameters
    FState: TSRPState;           // current processing state
    FSharedSecret: Binary;       // shared secret for encryption
    procedure CheckSharedSecret;
  public
    function State: TSRPState; stdcall;
    function SharedSecret: WideString; stdcall;
    function Encrypt(const Msg: WideString): WideString; stdcall;
    function Decrypt(const Msg: WideString): WideString; stdcall;
    constructor Create;
    destructor Destroy; override;
  end;

  TSRPServer = class(TSRPBase, ISRPServer)
  private
    FDatabase: ISRPDatabase;     // link to User database
    FClient: packed record
      I: IInteger;               // Identifier
      S: IInteger;               // Password Salt
      V: IInteger;               // Password Verifier
      C: IInteger;               // Counter
    end;
    FEmpheralKey: packed record
      S: IInteger;               // secrect
      P: IInteger;               // public
    end;
  protected
    procedure StoreClient;
  public
    function RegisterClient(const Name: WideString): WideString; stdcall;
    function Step0(const Msg: WideString): WideString; stdcall;
    function Step1(const Msg: WideString): WideString; stdcall;
    function Counter: Cardinal; stdcall;
    function Identifier: WideString; stdcall;
    constructor Create(const ADatabase: ISRPDatabase);
  end;

  TSRPClient = class(TSRPBase, ISRPClient)
  private
    FKeys: packed record
      I: IInteger;                // identifier
      C: IInteger;                // Counter
      O: IInteger;                // old password
      N: IInteger;                // new password
      H: IInteger;                // server-hash to receive
    end;
  public
    function Step0(const Name: WideString; const OldPassword: WideString; const NewPassword: WideString = ''): WideString; stdcall;
    function Step1(const Msg: WideString): WideString; stdcall;
    function Step2(const Msg: WideString): WideString; stdcall;
    function Counter: Cardinal; stdcall;
    function Identifier: WideString; stdcall;
  end;

// Allocator functions
function SRPDatabase(InRegistry: Boolean = False): ISRPDatabase;
begin
  if InRegistry then Result := TSRPDatabaseRegistry.Create
    else Result := TSRPDatabaseINI.Create;
end;

function SRPServer(const ADatabase: ISRPDatabase): ISRPServer;
begin
  Result := TSRPServer.Create(ADatabase);
end;

function SRPClient: ISRPClient;
begin
  Result := TSRPClient.Create;
end;

// helper functions for common used stuff
procedure SRPRaise(const Msg: String); overload;
begin
  raise ESRPException.Create(Msg);
end;

procedure SRPRaise(const Msg: String; const Fmt: array of const); overload;
begin
  raise ESRPException.CreateFmt(Msg, Fmt);
end;

// follow overloads are needed because D5 Compiler produce wrong machinecode if
// we use a array of const followed by an preinitialized parameter !!!
procedure SRP_Hash(var A: IInteger; const Values: array of const; const C: IInteger);
// MGF = hash based indexed Mask Generation Function
begin
  NCat(A, NInt(Values));
  NHash(A, SRP_HashClass, SRP_SecureBits, NLong(C));
end;

procedure SRPHash(var A: IInteger; const Values: array of const; const C: IInteger); overload;
begin
  SRP_Hash(A, Values, C);
end;

procedure SRPHash(var A: IInteger; const Values: array of const); overload;
begin
  SRP_Hash(A, Values, NNull);
end;

function SRPHash(const Values: array of const; const C: IInteger): IInteger; overload;
begin
  SRP_Hash(Result, Values, C);
end;

function SRPHash(const Values: array of const): IInteger; overload;
begin
  SRP_Hash(Result, Values, NNull);
end;

procedure SRPDomain(var Domain: TSRPDomain); overload;
var
  T: IInteger;
begin
  NSet(Domain.N, NIDPrime(Domain.ID));
  NSet(Domain.Q, Domain.N);
  NDec(Domain.Q);
  NDiv(Domain.Q, 2);
  NSet(Domain.G, 3);
  repeat
    repeat
      NInc(Domain.G);
      NSqrMod(T, Domain.G, Domain.N);
    until NCmp(T, 1) <> 0;
    NPowMod(T, Domain.G, Domain.Q, Domain.N);
  until NCmp(T, 1) <> 0;
  SRPHash(Domain.K, [Domain.N, Domain.G]);
end;

procedure SRPDomain(var D: TSRPDomain; const ID: String); overload;
begin
  D.ID := ID;
  SRPDomain(D);
end;

procedure SRPOneTimePad(var M: IInteger; const A,C,K: IInteger; Bits: Integer); overload;
// One Time Pad en-/decryption based on a indexed KDF
// M := A xor KDF(K, c)
var
  P: IInteger;
begin
  NHash(P, K, SRP_HashClass, Bits, NLong(C));
  NXor(M, A, P, Bits);
end;

function SRPExtract(var Value: String; const Data: String): String; overload;
// extract in Value first string from beginning of Data upto first SRP_Separator char
var
  P: Integer;
begin
  Result := Data;
  P := Pos(SRP_Separator, Result) -1;
  if P <= 0 then P := MaxInt;
  Value := System.Copy(Result, 1, P);
  System.Delete(Result, 1, P + Length(SRP_Separator));
end;

function SRPExtract(var I: IInteger; const Data: String): String; overload;
var
  S: String;
begin
  Result := SRPExtract(S, Data);
  NSet(I, S, SRP_Format);
end;

function SRPStr(const Data: array of const): String;
// create an SRP_Separator separated and formated String
var
  I: Integer;
  P: IInteger;
  S: String;
begin
  Result := '';
  for I := Low(Data) to High(Data) do
    with Data[I] do
    begin
      S := '';
      case vType of
        vtInterface:
          if (VInterface <> nil) and
             (IUnknown(VInterface).QueryInterface(IInteger, P) = 0) then
            S := NStr(P, SRP_Format);
        vtAnsiString:
          if VAnsiString <> nil then
            S := AnsiString(VAnsiString);
        vtString:
          if VString <> nil then
            S := VString^;
        vtPChar:
          if VPChar <> nil then
            S := VPChar;
        vtChar:
          if VChar <> #0 then
            S := VChar;
        vtPWideChar:
          if VPWideChar <> nil then
            S := WideCharToString(VPWideChar);
        vtWideString:
          if VWideString <> nil then
            S := WideCharToString(VWideString);
      else
        SRPRaise('Invalid Datatype in SRPCompact');
      end;
      Result := Result + S + SRP_Separator;
    end;
  SetLength(Result, Length(Result) - Length(SRP_Separator));
end;

// implemenattions classes
// .TSRPBaseDatabase
function TSRPBaseDatabase.Lookup(const Ident: WideString): WideString;
begin
  EnterCriticalSection(FCriticalSection);
  try
    Result := DoLookup(Ident);
  finally
    LeaveCriticalSection(FCriticalSection);
  end;
  if Result = '' then
    SRPRaise('User with identifier "%s" is not registered', [Ident]);
end;

procedure TSRPBaseDatabase.Store(const Ident, Data: WideString);
begin
  EnterCriticalSection(FCriticalSection);
  try
    DoStore(Ident, Data);
  finally
    LeaveCriticalSection(FCriticalSection);
  end;
end;

procedure TSRPBaseDatabase.Delete(const Ident: WideString);
begin
  EnterCriticalSection(FCriticalSection);
  try
    DoDelete(Ident);
  finally
    LeaveCriticalSection(FCriticalSection);
  end;
end;

constructor TSRPBaseDatabase.Create;
begin
  inherited Create;
  InitializeCriticalSection(FCriticalSection);
end;

destructor TSRPBaseDatabase.Destroy;
begin
  DeleteCriticalSection(FCriticalSection);
  inherited Destroy;
end;

const
  sUsers: String = 'SRP_Users';

// .TSRPDatabaseINI
function TSRPDatabaseINI.DoLookup(const Ident: WideString): WideString;
begin
  Result := FFile.ReadString(sUsers, Ident, '');
end;

function TSRPDatabaseINI.DoStore(const Ident, Data: WideString): WideString;
begin
  FFile.WriteString(sUsers, Ident, Data);
end;

procedure TSRPDatabaseINI.DoDelete(const Ident: WideString);
begin
  FFile.DeleteKey(sUsers, Ident);
end;

constructor TSRPDatabaseINI.Create;
begin
  inherited Create;
  FFile := TINIFile.Create(ChangeFileExt(ParamStr(0), '.dbs'));
end;

destructor TSRPDatabaseINI.Destroy;
begin
  FreeAndNil(FFile);
  inherited Destroy;
end;

// .TSRPDatabaseRegistry
function TSRPDatabaseRegistry.DoLookup(const Ident: WideString): WideString;
begin
  Result := FFile.ReadString(sUsers, Ident, '');
end;

function TSRPDatabaseRegistry.DoStore(const Ident, Data: WideString): WideString;
begin
  FFile.WriteString(sUsers, Ident, Data);
end;

procedure TSRPDatabaseRegistry.DoDelete(const Ident: WideString);
begin
  FFile.DeleteKey(sUsers, Ident);
end;

constructor TSRPDatabaseRegistry.Create;
begin
  inherited Create;
  FFile := TRegINIFile.Create;
end;

destructor TSRPDatabaseRegistry.Destroy;
begin
  FreeAndNil(FFile);
  inherited Destroy;
end;

// .TSRPBase
procedure TSRPBase.CheckSharedSecret;
begin
  if (FState <> srpFinish) or (FSharedSecret = '') then
    SRPRaise('Shared secret is not valid');
end;

function TSRPBase.State: TSRPState;
begin
  Result := FState;
end;

function TSRPBase.SharedSecret: WideString;
begin
  CheckSharedSecret;
  Result := TFormat_HEX.Encode(FSharedSecret);
end;

function TSRPBase.Encrypt(const Msg: WideString): WideString;
begin
  CheckSharedSecret;
  with ValidCipher(SRP_CipherClass).Create do
  try
    Mode := cmCBCx;
    Init(FSharedSecret);
    Result := EncodeBinary(RandomBinary(16) + Msg, TFormat_MIME64);
  finally
    Free;
  end;
end;

function TSRPBase.Decrypt(const Msg: WideString): WideString;
begin
  CheckSharedSecret;
  with ValidCipher(SRP_CipherClass).Create do
  try
    Mode := cmCBCx;
    Init(FSharedSecret);
    Result := System.Copy(DecodeBinary(Msg, TFormat_MIME64), 17, MaxInt);
  finally
    Free;
  end;
end;

constructor TSRPBase.Create;
begin
  inherited Create;
  NPool.SetFlags(NPool.GetFlags or pfSecure);  // ensure safe erase of large IInteger's memory contents
end;

destructor TSRPBase.Destroy;
begin
  ProtectBinary(FSharedSecret);
  NPool.Clear;
  inherited Destroy;
end;

// .TSRPServer
procedure TSRPServer.StoreClient;
begin
  FDatabase.Store(SRPStr([FClient.I]), SRPStr([FClient.S, FClient.V, FClient.C, FDomain.ID]));
end;

function TSRPServer.RegisterClient(const Name: WideString): WideString;
// here it should be tested if another client wie same name exists in Database !!
const
  SRP_Domain       = '1024:1:1:SHA1:1:74FCBDC8:CC17:109224'; // can/should be changed
  SRP_CounterStart = 1;   // > 0 !
  SRP_RegKeyBits   = 128; // bit length of registration keys
var
  P: IInteger;  // empheral Client password, must be send to Client
  S: String;
begin
  try
    FState := srpNone;
  // initialize Domain
    SRPDomain(FDomain, SRP_Domain);
  // initialize new Client
    NSet(FClient.C, SRP_CounterStart);
    NRnd(FClient.S, SRP_SecureBits);
    NSet(FClient.I, AnsiUpperCase(String(Name)), 256);
    NHash(FClient.I, SRP_HashClass, SRP_SecureBits);
  // create random initial Password
    NRnd(P, SRP_RegKeyBits);
    S := NStr(P, SRP_Format);
    NSet(P, S, 256);
  // create Verifier
    NPowMod(FClient.V, FDomain.G, SRPHash([FClient.S, FClient.I, P], FClient.C), FDomain.N);
  // store new client
    StoreClient;
    Result := S;
  finally
    ProtectBinary(S);
  end;
end;

function TSRPServer.Counter: Cardinal;
begin
  Result := NLong(FClient.C);
end;

function TSRPServer.Identifier: WideString;
begin
  Result := SRPStr([FClient.I]);
end;

function TSRPServer.Step0(const Msg: WideString): WideString;
var
  M: String;
  T: IInteger;
begin
  FState := srpNone;
// extract Message, Client Identifier
  M := SRPExtract(FClient.I, Msg);
// lookup and load Client Record
  M := SRPExtract(FClient.S, FDatabase.Lookup(SRPStr([FClient.I])));
  M := SRPExtract(FClient.V, M);
  M := SRPExtract(FClient.C, M);
  M := SRPExtract(FDomain.ID, M); // M could be contain more custom data
// create Domain, Empheral Keys
  SRPDomain(FDomain);
  NRnd(FEmpheralKey.S, SRP_SecureBits);
  NPowMod(FEmpheralKey.P, FDomain.G, FEmpheralKey.S, FDomain.N);
  NMulMod(T, FDomain.K, FClient.V, FDomain.N);
  NAddMod(FEmpheralKey.P, T, FDomain.N);
// send Client Data and public Empheral Key
  Result := SRPStr([FClient.S, FClient.C, FEmpheralKey.P, FDomain.ID]);
  FState := srpStep0;
end;

function TSRPServer.Step1(const Msg: WideString): WideString;
var
  M: String;
  Client_H: IInteger;
  Client_P: IInteger;
  Client_Sp: IInteger;
  Client_Vp: IInteger;
  Shared_K: IInteger;
begin
  if FState <> srpStep0 then SRPRaise('Invalid processing order');
// extract Data
  M := SRPExtract(Client_H, Msg);
  M := SRPExtract(Client_P, M);
  M := SRPExtract(Client_Sp, M);
  M := SRPExtract(Client_Vp, M);
  if NCmp(Client_P, 0) = 0 then
    SRPRaise('Invalid empheral key received from client "%s"', [SRPStr([FClient.I])]);
// compute shared secret Key
  NPowMod(FClient.V, SRPHash([Client_P, FEmpheralKey.P], FClient.C), FDomain.N);
  NMulMod(FClient.V, Client_P, FDomain.N);
  NPowMod(Shared_K, FClient.V, FEmpheralKey.S, FDomain.N);
// decrypt new Verifier and Salt
  NInc(FClient.C);
  SRPOneTimePad(FClient.S, Client_Sp, FClient.C, Shared_K, SRP_SecureBits);
  SRPOneTimePad(FClient.V, Client_Vp, FClient.C, Shared_K, NSize(FDomain.N));
  if NCmp(FClient.S, 0) = 0 then
    SRPRaise('Invalid password salt received from client');
  if NCmp(FClient.V, 0) = 0 then
    SRPRaise('Invalid password verifier received from client');
// compare Results
  if NCmp(Client_H, SRPHash([Client_P, FEmpheralKey.P, FClient.S, FClient.V])) <> 0 then
    SRPRaise('Invalid login of user with identifier "%s"', [SRPStr([FClient.I])]);
// store new Verifier and Salt of Client
  StoreClient;
// create visible shared key
  FSharedSecret := NStr(SRPHash([Shared_K]), 256);
// response to client
  Result := SRPStr([SRPHash([Client_P, FEmpheralKey.P, FClient.S, FClient.V, Client_H])]);
  FState := srpFinish;
end;

constructor TSRPServer.Create(const ADatabase: ISRPDatabase);
begin
  inherited Create;
  if not Assigned(ADatabase) then SRPRaise('Can not create Sever without a Database');
  FDatabase := ADatabase;
end;

// .TSRPClient
function TSRPClient.Counter: Cardinal;
begin
  Result := NLong(FKeys.C);
end;

function TSRPClient.Identifier: WideString;
begin
  Result := SRPStr([FKeys.I]);
end;

function TSRPClient.Step0(const Name: WideString; const OldPassword: WideString; const NewPassword: WideString): WideString;
begin
  FState := srpNone;
  NSet(FKeys.I, AnsiUpperCase(String(Name)), 256);
  NHash(FKeys.I, SRP_HashClass, SRP_SecureBits);
  NSet(FKeys.O, String(OldPassword), 256);
  NSet(FKeys.N, String(NewPassword), 256);
  if NCmp(FKeys.N, 0) = 0 then NSet(FKeys.N, FKeys.O);
  Result := SRPStr([FKeys.I]);
  FState := srpStep0;
end;

function TSRPClient.Step1(const Msg: WideString): WideString;
var
  M: String;
  Client_S,Client_Sp: IInteger;
  Client_V,Client_Vp: IInteger;
  Client_X: IInteger;
  Server_P,Client_P: IInteger;
  Client_H: IInteger;
  Shared_K: IInteger;
begin
  if FState <> srpStep0 then SRPRaise('Invalid processing order');
// extract Data
  M := SRPExtract(Client_S, Msg);
  M := SRPExtract(FKeys.C, M);
  M := SRPExtract(Server_P, M);
  M := SRPExtract(FDomain.ID, M);
  if NCmp(Server_P, 0) = 0 then
    SRPRaise('Invalid empheral key received from server');
  if NCmp(Client_S, 0) = 0 then
    SRPRaise('Invalid password salt received from server');
  if NCmp(FKeys.C, 0) = 0 then
    SRPRaise('Invalid counter received from server');
// initlaize Domain
  SRPDomain(FDomain);
// compute Verifier from old Password
  SRPHash(Client_X, [Client_S, FKeys.I, FKeys.O], FKeys.C);
  NPowMod(Client_V, FDomain.G, Client_X, FDomain.N);
// create empheral Keys
  NRnd(Shared_K, SRP_SecureBits);
  NPowMod(Client_P, FDomain.G, Shared_K, FDomain.N);
// compute shared secret Key
  NMulMod(Client_V, FDomain.K, FDomain.N);
  NSubMod(Client_V, Server_P, Client_V, FDomain.N);
  NMulMod(Client_X, SRPHash([Client_P, Server_P], FKeys.C), FDomain.N);
  NAddMod(Client_X, Shared_K, FDomain.N);
  NPowMod(Shared_K, Client_V, Client_X, FDomain.N);
// create visible shared key
  FSharedSecret := NStr(SRPHash([Shared_K]), 256);
// create Verifier and Salt for new Password
  NInc(FKeys.C);
  NRnd(Client_S, SRP_SecureBits);
  NPowMod(Client_V, FDomain.G, SRPHash([Client_S, FKeys.I, FKeys.N], FKeys.C), FDomain.N);
  SRPOneTimePad(Client_Sp, Client_S, FKeys.C, Shared_K, SRP_SecureBits);
  SRPOneTimePad(Client_Vp, Client_V, FKeys.C, Shared_K, NSize(FDomain.N));
  SRPHash(Client_H, [Client_P, Server_P, Client_S, Client_V]);
// compute verifier hash of server response
  SRPHash(FKeys.H, [Client_P, Server_P, Client_S, Client_V, Client_H]);
// response
  Result := SRPStr([Client_H, Client_P, Client_Sp, Client_Vp]);
  FState := srpStep1;
end;

function TSRPClient.Step2(const Msg: WideString): WideString;
var
  H: IInteger;
begin
  if FState <> srpStep1 then SRPRaise('Invalid processing order');
  Result := SRPExtract(H, Msg);
  if NCmp(H, FKeys.H) <> 0 then SRPRaise('Invalid server authentification');
  FState := srpFinish;
end;

initialization
  ValidHash(SRP_HashClass).Register;
  RandomSeed;
// here should be reseeded the internal YARROW-RNG wir inpredictable datas
// RandomSeed(Data, SizeOf(Data));
end.
