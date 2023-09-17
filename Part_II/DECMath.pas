{Copyright:      Hagen Reddmann  HaReddmann at T-Online dot de
 Author:         Hagen Reddmann
 Remarks:        this Copyright must be included
 known Problems: none
 Version:        5.1,  Part II from Delphi Encryption Compendium
                 Delphi 7

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
unit DECMath;

interface

uses
  TypInfo, SysUtils, Classes;

type
  RetString = AnsiString;  // see DECMath_InitMemoryStringHooks

{$REGION 'ASN1 : SysUtils, Classes'}                               {$ENDREGION}
{$REGION 'CRC : '}                                                 {$ENDREGION}
{$REGION 'CPU : SysUtils, Windows'}                                {$ENDREGION}
{$REGION 'DECData : '}                                             {$ENDREGION}
{$REGION 'DECUtil : CRC, SysUtils, Classes, Windows'}              {$ENDREGION}
{$REGION 'DECHash : DECData, DECUtil, DECFmt, SysUtils, Classes'}

type
  TDECHashClass = Pointer;

  // predefined Standard CRC Types
  TCRCType = (CRC_8, CRC_10, CRC_12, CRC_16, CRC_16CCITT, CRC_16XModem, CRC_24,
              CRC_32, CRC_32CCITT, CRC_32ZModem);

{$ENDREGION}
{$REGION 'DECFmt : CRC, DECUtil, SysUtils, Classes, Windows'}      {$ENDREGION}

{$REGION 'NMath : SysUtils, Windows'}

type
  // user defined periodical callback, called from inside of calculation code
  IPoolNotify = interface
    ['{126BE0F8-061D-4067-9E0A-E2A490AF5CEA}']
    function DoIdle: Boolean;
  end;

  // stack management, speedup 10% IIntegers
  IPool = interface
    ['{126BE0F0-061D-4067-9E0A-E2A490AF5CEA}']
    function Clear: Boolean;
    function SetLimit(Count: Cardinal = 64; Size: Cardinal = $10000): Boolean;
    function SetFlags(Flags: Cardinal): Cardinal;
    function GetFlags: Cardinal;
    function CurCount: Cardinal;
    function MaxCount: Cardinal;
    function CurSize:  Cardinal;
    function MaxSize:  Cardinal;
    function ThreadID: Cardinal;

    function SetIdle(const Notify: IPoolNotify = nil; Delay: Cardinal = 100): IPoolNotify;
    function GetIdle(out Notify: IPoolNotify; out Delay: Cardinal): Boolean;
  end;

  // direct access to one-dimensional Interfaces such as IIntegers
  IDigitAccess = interface
    ['{126BE000-061D-4067-9E0A-E2A490AF5CEA}']
    function Count: Integer;
    function GetDigit(Index: Integer): Cardinal;
    function Alloc(Count: Integer): Pointer;
    function Digits: Pointer;
    procedure SetDigits(Digits: Pointer; Count: Integer);
    procedure Normalize;
  end;

  EMath        = class(Exception);
  EDigitAccess = class(EMath);
  EMathAbort   = class(EAbort);

function  IsEqualGUID(const GUID1, GUID2: TGUID): Boolean; external 'DECMath.dll' name 'NMath_IsEqualGUID_GuGu';
function  NPool(ThreadID: Cardinal = 0): IPool;            external 'DECMath.dll' name 'NMath_NPool_Ca';
procedure NCalcCheck;                                      external 'DECMath.dll' name 'NMath_NCalcCheck_';
// make entry unique
procedure NUnique(var Entry);                              external 'DECMath.dll' name 'NMath_NUnique_Va';
// add Intf to release it in same time with the internal threaded stack pool
procedure NAutoRelease(const Intf: IUnknown);              external 'DECMath.dll' name 'NMath_NAutoRelease_II';

{ remarks: How work Stacks/Queue here ?

   The stacks here use "backpropagation" and two linked list of available Entry Types.
   1. TStackEntry
   2. TRefEntry

   TStackEntry manage a Pointer of a long memorychunk with preallocation. Most cases
   this memory chunk is overallocated to avoid to many calls to the Memorymanager
   if we need more space. Such entries are used for a single Interface such as IInteger.
   The TStack manage a linked list of available (freed/unused) TStackEntry's. This
   list use a FILO Method (Queue), means First In Last Out, because the large allocated
   memorychunk ISN'T automatically freed. Instead we preserve it for the next needed
   allocation of a TStackEntry. With a FILO Stack the Entries itself "rotate" into
   this list and so on repeated allocations/deallocations each preserved Entry becomes
   the same probabilty of use. So we avoid efficiently follow situation:

     On the Stack are 4 Enries preserved, each with 1024 Bytes memorychunk. The maximal
     memory space that manage the Stack is 4 * 1024 bytes. The next 5. entry that should
     preserved on this stack must be now free it memoryspace, because the preserved
     space excide 4 * 1024 bytes. Now let us assume a FIFO Stack, then the next allocated
     Stack entry is number 5. The memorychunk is freed. The outer procs must reallocate
     this chunk, play with it and frees again this 5. entry. The Stackhandler must now again
     free this prior allocated Memorychunk and insert 5. entry to stacklist as entry #5.
     We see such a FIFO Stack preserve now 4096 unused bytes and is rater inefficent,
     because it use on repeated reallocation always a bad entry.

     A FILO Stack gets back the first allocated entry no 1. and put this entry after
     deallocation as no 5. The next allocated entry is no 2 and so on. Means the
     allocated memorychunk of each entry is better used.

  TStack supports limit for preserved Stack Entries. One limit of count of entries into
  linked list and one limit of memoryusage of all preserved entries.
  If the current count of StackEntry on deallocation excide the MaxCount then this
  entry is fully freed, include the memorychunk.
  If the current memorysize excide then only the full memorychunk is released but
  the stackentry is inserted to the list.

  TRefEntry are now a Interface with upto 6 Interface members of type TStackEntry,
  and some additional infos into reserved Cardinal fields.
  TRefEntry are only limitated per MaxCount.
  TRefEntry use a FIFO linked list, because these are of fixed sizes and
  contains no additional memorychunk.

  All important operation (insertion, limit checks, stack allocation) are done
  on Entry-deallocation and for each possible thread into a own stack. Each
  such allocated thread stack is linked into a list of all process stacks. So we
  can on termination destroy ALL stacks. If a Thread don't use IIntegers or other
  objects from this library then NO stack exists.

  IMPORTANT ! each Thread that want to use IIntegers must at least
  free the stack by a call to NPool.Clear, otherwise all reallocated Stackentries
  are first on processtermination destroyed.
  That's the ONLY one bad point of the design, but I don't known a realy better
  alternative for this. Some methods of hooking are to inpredictable, unsafe or
  complicated. I think about an additional method of checking if a Thread-Stack
  is valid, and if not we free it. Then we could periodical call this function.
  This should be easily adapted in above code.

  If the limits of a stack are set to 0,0 then only the stack itself are allocated.
  That could be an additional alternative for threads, but then we lost about >10
  percent speed. (ie. for GF(p) we speedup with stacks 20% !!!)

  The third task for the TStack are the Calculation Management. Here we apply a
  asynchrone callback to a userdefined interface. TStack contains now
  all this needed stuff. We can abort any calculation.
  Both features are important if we known how long a computation of PI to 1 million
  decimals digits take, and MUL, DIV and so on...

  This calculation design avoid some disadvantages if we must periodicaly call
  a userdefined procedure, eg. Application.PrcessMessages. Then this would be
  to many times called and reduce dramatical the runtime speed.

  To use such a callback use the IPoolNotify Interface. For each thread only ONE
  such a callback can be installed, but we can preserve the current installed one.

  as example

  type
    TMyForm = class(TForm, IPoolNotify)
    private
      FMustAbort: Boolean;

      function DoIdle: Boolean;
      procedure DoCalc;
    end;

  function TMyForm.DoIdle: Boolean;
  begin
    Result := not FMustAbort;
    Application.ProcessMessages;
  end;

  procedure TMyForm.DoCalc;
  var
    Notify: IPoolNotify;
  begin
    with NPool do
    try
      Notify := SetIdle(Self);
      SetLimit
      ... compuation

    finally
      Clear;
      SetIdle(Notify);

      // or to uninstall all
      SetIdle;

    end;
  end;

  .DoCalc can be now recursively called, or intercept another outer calculation
  with its own callback. But only the last one can be active.

  Hm thats all, i hope i could it understandable write with my bad english :)
}

{$ENDREGION}
{$REGION 'NInts : NMath, Prime, ASN1, CPU, CRC, DECFmt, DECHash, DECUtil, TypInfo, SysUtils, Classes, Windows, Variants'}

type
  TBase = type Word;// 0= Default or Parse, 2..64= valid StringFormats, 256= Byte copying

  TIntegerFormat = (ifASN1, ifDEC, ifCRC, ifPGP, ifPlain, ifFast);

  TNAFArray = array of Integer;

  TPiece = (piBit, piByte, piWord, piLong);

  Long96 = array[0..2] of Cardinal;

  IInteger = interface
    ['{126BE010-061D-4067-9E0A-E2A490AF5CEA}']
    function Count: Integer;
    function GetDigit(Index: Integer): Cardinal;

    property Digit[Index: Integer]: Cardinal read GetDigit; default;
  end;

  I2Point = packed record
    X, Y: IInteger;
  end;

  I3Point = packed record
    X, Y, Z: IInteger;
  end;

  IIntegerArray = array of IInteger;

  EInteger = class(EMath);

  TIIntegerPrimeCallback = function(const P: IInteger): Boolean; register;
  TIIntegerSortCompare = function(const A, B: IInteger): Integer; register;
  TIIntegerForEachCallback = function(var A: IInteger): Boolean; register;

  TIIntegerSplitData = packed record
    P, Q, A, B: IInteger;
  end;

  TIIntegerBinarySplittingCallback = procedure(N: Cardinal; var P: TIIntegerSplitData); register;

  TStrFormat = packed record                // String-Convertion structure
    Base: TBase;                            // Numberbase
    Plus: array[0..15] of AnsiChar;         // String for positive IInteger (+)
    Minus: array[0..15] of AnsiChar;        // String for negative IInteger (-)
    Zero: array[0..15] of AnsiChar;         // String for zero              (0)
    Comma: AnsiChar;
    DigitsPerBlock: Word;                   // Digits on one Block
    BlockSep: array[0..15] of AnsiChar;     // separator between two blocks (Space)
    BlockPadding: AnsiChar;                 // left padding char of first block
    DigitsPerLine: Word;                    // count of digits in one line
    LineSep: array[0..15] of AnsiChar;      // separator after one line (CR+LF)
    LinePadding: AnsiChar;                  // left padding char of first line
    DigitsChars: array[0..63] of AnsiChar;  // possible Digits of a valid Numberstring
    FormatChars: array[0..63] of AnsiChar;  // Numberstrings can contain these chars, but should be ignored
    LeftAlign: Boolean;
    Offset: Integer;                        // Offset to first char that contains digits, NSet(string)
    Precision: Integer;
  end;

  {$SCOPEDENUMS ON}
  TTrialDivision = (IsPrime, NotDivisible, Divisible);
  {$SCOPEDENUMS OFF}

  IPowModPrecomputation = interface
    ['{126BE018-061D-4067-9E0A-E2A490AF5CEA}']
    procedure Precompute(const B, M: IInteger; EMaxBitSize: Integer; EIsNeg: Boolean);
    function  PowMod  (var A: IInteger; const B, E, M: IInteger; var Res: Boolean): Boolean;
    function  PowMod2k(var A: IInteger; const B, E: IInteger; K: Cardinal; var Res: Boolean): Boolean;
    procedure Save(Stream: TStream);
    procedure Load(Stream: TStream);
  end;

procedure NSet(var A: IInteger; B: Integer); overload;                                                     external 'DECMath.dll' name 'NInts_NSet_IIIn';
procedure NSet(var A: IInteger; B: Int64); overload;                                                       external 'DECMath.dll' name 'NInts_NSet_III6';
procedure NSet(var A: IInteger; B: Extended); overload;                                                    external 'DECMath.dll' name 'NInts_NSet_IIEx';
procedure NSet(var A: IInteger; const B: IInteger = nil; Abs: Boolean = False); overload;                  external 'DECMath.dll' name 'NInts_NSet_IIIIBo';
function  NSet(var A: IInteger; const B: AnsiString; const Format: TStrFormat): Integer; overload;         external 'DECMath.dll' name 'NInts_NSet_IIStSF';
procedure NSet(var A: IInteger; const B: AnsiString; Base: TBase = 0); overload;                           external 'DECMath.dll' name 'NInts_NSet_IIStBa';
procedure NSet(var A: IInteger; const B; Size: Integer; Bits: Integer = 0); overload;                      external 'DECMath.dll' name 'NInts_NSet_IIBInIn';
procedure NSet(var A: IInteger; Stream: TStream; Format: TIntegerFormat = ifASN1); overload;               external 'DECMath.dll' name 'NInts_NSet_IIStIF';
procedure NSet(var A: IInteger; const B: TVarRec); overload;                                               external 'DECMath.dll' name 'NInts_NSet_IIVR';
procedure NSet(var A: IIntegerArray; const B: array of const); overload;                                   external 'DECMath.dll' name 'NInts_NSet_IAAC';
procedure NSet(var A: IIntegerArray; const B: IIntegerArray); overload;                                    external 'DECMath.dll' name 'NInts_NSet_IAIA';
procedure NRnd(var A: IInteger; Bits: Integer = 0; Sign: Boolean = False); overload;                       external 'DECMath.dll' name 'NInts_NRnd_IIInBo';
function  NInt(A: Integer = 0): IInteger; overload;                                                        external 'DECMath.dll' name 'NInts_NInt_In';
function  NInt(A: Int64): IInteger; overload;                                                              external 'DECMath.dll' name 'NInts_NInt_I6';
function  NInt(A: Extended): IInteger; overload;                                                           external 'DECMath.dll' name 'NInts_NInt_Ex';
function  NInt(const A: IInteger; Abs: Boolean = False): IInteger; overload;                               external 'DECMath.dll' name 'NInts_NInt_IIBo';
function  NInt(const A; Size: Integer; Bits: Integer = 0): IInteger; overload;                             external 'DECMath.dll' name 'NInts_NInt_AInIn';
function  NInt(const A: AnsiString; Base: TBase = 0): IInteger; overload;                                  external 'DECMath.dll' name 'NInts_NInt_StBa';
function  NInt(Stream: TStream; Format: TIntegerFormat = ifASN1): IInteger; overload;                      external 'DECMath.dll' name 'NInts_NInt_StIF';
function  NInt(const A: array of const): IIntegerArray; overload;                                          external 'DECMath.dll' name 'NInts_NInt_AC';
function  NSgn(const  A: IInteger; Extended: Boolean = False): Integer;  overload;                         external 'DECMath.dll' name 'NInts_NSgn_IIBo';
procedure NSgn(var    A: IInteger;                       Sign: Integer); overload;                         external 'DECMath.dll' name 'NInts_NSgn_IIIn';
function  NOdd(const  A: IInteger):     Boolean;           overload;                                       external 'DECMath.dll' name 'NInts_NOdd_II';
function  NOdd(var    A: IInteger; Odd: Boolean): Boolean; overload;                                       external 'DECMath.dll' name 'NInts_NOdd_IIBo';
function  NNeg(var    A: IInteger):          Boolean; overload;                                            external 'DECMath.dll' name 'NInts_NNeg_II';
function  NNeg(var    A: IInteger; Negative: Boolean): Boolean; overload;  {??}                            external 'DECMath.dll' name 'NInts_NNeg_IIBo';
function  NAbs(var    A: IInteger): Boolean; overload;                                                     external 'DECMath.dll' name 'NInts_NAbs_II';
function  NBit(const  A: IInteger; Index: Integer):       Boolean; overload;                               external 'DECMath.dll' name 'NInts_NBit_IIIn';
procedure NBit(var    A: IInteger; Index: Integer; Value: Boolean); overload;                              external 'DECMath.dll' name 'NInts_NBit_IIInBo';
function  NLow(const  A: IInteger; Piece: TPiece = piBit): Integer; {overload;}                            external 'DECMath.dll' name 'NInts_NLow_IIPi';
function  NHigh(const A: IInteger; Piece: TPiece = piBit): Integer; {overload;}                            external 'DECMath.dll' name 'NInts_NHigh_IIPi';
function  NSize(const A: IInteger; Piece: TPiece = piBit): Integer; {overload;}                            external 'DECMath.dll' name 'NInts_NSize_IIPi';
function  NCmp(const A, B: IInteger;                          Abs: Boolean = False): Integer; overload;    external 'DECMath.dll' name 'NInts_NCmp_IIIIBo';
function  NCmp(const A: IInteger; B: Integer;                 Abs: Boolean = False): Integer; overload;    external 'DECMath.dll' name 'NInts_NCmp_IIInBo';
function  NCmp(const A,           B: IInteger; Bits: Integer; Abs: Boolean = False): Integer; overload;    external 'DECMath.dll' name 'NInts_NCmp_IIIIInBo';
function  NCRC(const A: IInteger;      CRC: TCRCType = CRC_32CCITT): Cardinal; overload;                   external 'DECMath.dll' name 'NInts_NCRC_IITC';
function  NCRC(const A: IIntegerArray; CRC: TCRCType = CRC_32CCITT): Cardinal; overload;                   external 'DECMath.dll' name 'NInts_NCRC_IATC';
function  NParity(const A: IInteger): Boolean; {overload;}                                                 external 'DECMath.dll' name 'NInts_NParity_II';
function  NWeight(const A: IInteger): Integer; {overload;}                                                 external 'DECMath.dll' name 'NInts_NWeight_II';
function  NBitPos(const A: IInteger; Bit: Integer): Integer; {overload;}                                   external 'DECMath.dll' name 'NInts_NBitPos_IIIn';
//procedure NBitAdd(var A: IInteger; const B: IInteger; Bits: Integer); {overload;}                        external 'DECMath.dll' name 'NInts_NBitAdd_IIIIIn';
procedure NSplit(var A: IInteger; const B: IInteger; Bits: Byte); {overload;}                              external 'DECMath.dll' name 'NInts_NSplit_IIIIBy';
procedure NSwp(var A,                 B: IInteger); overload;                                              external 'DECMath.dll' name 'NInts_NSwp_IIII';
procedure NSwp(var A: IInteger;                    Piece: TPiece; Normalize: Boolean = True); overload;    external 'DECMath.dll' name 'NInts_NSwp_IIPiBo';
procedure NSwp(var A: IInteger; const B: IInteger; Piece: TPiece; Normalize: Boolean = True); overload;    external 'DECMath.dll' name 'NInts_NSwp_IIIIPiBo';
procedure NCpy(var A: IInteger;                    Count: Integer; Start: Integer = 0); overload;          external 'DECMath.dll' name 'NInts_NCpy_IIInIn';
procedure NCpy(var A: IInteger; const B: IInteger; Count: Integer; Start: Integer = 0); overload;          external 'DECMath.dll' name 'NInts_NCpy_IIIIInIn';
procedure NShl(var A: IInteger;                    Shift: Integer); overload;                              external 'DECMath.dll' name 'NInts_NShl_IIIn';
procedure NShl(var A: IInteger; const B: IInteger; Shift: Integer); overload;                              external 'DECMath.dll' name 'NInts_NShl_IIIIIn';
procedure NShr(var A: IInteger;                    Shift: Integer); overload;                              external 'DECMath.dll' name 'NInts_NShr_IIIn';
procedure NShr(var A: IInteger; const B: IInteger; Shift: Integer); overload;                              external 'DECMath.dll' name 'NInts_NShr_IIIIIn';
function  NShr(var A: IInteger):                    Integer; overload;                                     external 'DECMath.dll' name 'NInts_NShr_II';
function  NShr(var A: IInteger; const B: IInteger): Integer; overload;                                     external 'DECMath.dll' name 'NInts_NShr_IIII';
procedure NCut(var A: IInteger;                         Bits: Integer); overload;                          external 'DECMath.dll' name 'NInts_NCut_IIIn';
procedure NCut(var A: IInteger; const B: IInteger;      Bits: Integer); overload;                          external 'DECMath.dll' name 'NInts_NCut_IIIIIn';
procedure NCat(var A: IInteger; const B: IIntegerArray; Bits: Integer = 0);                                external 'DECMath.dll' name 'NInts_NCat_IIIAIn';
procedure NNot(var A: IInteger;                       Bits: Integer = 0; Sign: Boolean = False); overload; external 'DECMath.dll' name 'NInts_NNot_IIInBo';
procedure NNot(var A: IInteger; const B:    IInteger; Bits: Integer = 0; Sign: Boolean = False); overload; external 'DECMath.dll' name 'NInts_NNot_IIIIInBo';
procedure NXor(var A: IInteger; const B:    IInteger; Bits: Integer = 0; Sign: Boolean = False); overload; external 'DECMath.dll' name 'NInts_NXor_IIIIInBo';
procedure NXor(var A: IInteger; const B, C: IInteger; Bits: Integer = 0; Sign: Boolean = False); overload; external 'DECMath.dll' name 'NInts_NXor_IIIIIIInBo';
procedure NAnd(var A: IInteger; const B:    IInteger; Bits: Integer = 0; Sign: Boolean = False); overload; external 'DECMath.dll' name 'NInts_NAnd_IIIIInBo';
procedure NAnd(var A: IInteger; const B, C: IInteger; Bits: Integer = 0; Sign: Boolean = False); overload; external 'DECMath.dll' name 'NInts_NAnd_IIIIIIInBo';
procedure NOr (var A: IInteger; const B:    IInteger; Bits: Integer = 0; Sign: Boolean = False); overload; external 'DECMath.dll' name 'NInts_NOr_IIIIInBo';
procedure NOr (var A: IInteger; const B, C: IInteger; Bits: Integer = 0; Sign: Boolean = False); overload; external 'DECMath.dll' name 'NInts_NOr_IIIIIIInBo';
procedure NCpl(var A: IInteger;                    Bits: Integer = 0; Sign: Boolean = False); overload;    external 'DECMath.dll' name 'NInts_NCpl_IIInBo';
procedure NCpl(var A: IInteger; const B: IInteger; Bits: Integer = 0; Sign: Boolean = False); overload;    external 'DECMath.dll' name 'NInts_NCpl_IIIIInBo';
procedure NInc(var A: IInteger;       B:    Cardinal = 1); overload;                                       external 'DECMath.dll' name 'NInts_NInc_IICa';
procedure NDec(var A: IInteger;       B:    Cardinal = 1); overload;                                       external 'DECMath.dll' name 'NInts_NDec_IICa';
procedure NAdd(var A: IInteger;       B:    Integer);  overload;                                           external 'DECMath.dll' name 'NInts_NAdd_IIIn';
procedure NAdd(var A: IInteger; const B:    IInteger); overload;                                           external 'DECMath.dll' name 'NInts_NAdd_IIII';
procedure NAdd(var A: IInteger; const B, C: IInteger); overload;                                           external 'DECMath.dll' name 'NInts_NAdd_IIIIII';
procedure NSub(var A: IInteger;       B:    Integer);  overload;                                           external 'DECMath.dll' name 'NInts_NSub_IIIn';
procedure NSub(var A: IInteger; const B:    IInteger); overload;                                           external 'DECMath.dll' name 'NInts_NSub_IIII';
procedure NSub(var A: IInteger; const B, C: IInteger); overload;                                           external 'DECMath.dll' name 'NInts_NSub_IIIIII';
procedure NMul(var A: IInteger;       B:              Integer);  overload;                                 external 'DECMath.dll' name 'NInts_NMul_IIIn';
procedure NMul(var A: IInteger;       B:              Int64);    overload;                                 external 'DECMath.dll' name 'NInts_NMul_III6';
procedure NMul(var A: IInteger; const B: IInteger; C: Int64);    overload;                                 external 'DECMath.dll' name 'NInts_NMul_IIIII6';
procedure NMul(var A: IInteger; const B: IInteger; C: Integer);  overload;                                 external 'DECMath.dll' name 'NInts_NMul_IIIIIn';
procedure NMul(var A: IInteger; const B: IInteger);              overload;                                 external 'DECMath.dll' name 'NInts_NMul_IIII';
procedure NMul(var A: IInteger; const B,           C: IInteger); overload;                                 external 'DECMath.dll' name 'NInts_NMul_IIIIII';
procedure NSqr(var A: IInteger); overload;                                                                 external 'DECMath.dll' name 'NInts_NSqr_II';
procedure NSqr(var A: IInteger; const B: IInteger); overload;                                              external 'DECMath.dll' name 'NInts_NSqr_IIII';
function  NMod (const A: IInteger; M: Integer): Integer; overload;                                         external 'DECMath.dll' name 'NInts_NMod_IIIn';
function  NModU(const A: IInteger; M: Cardinal): Cardinal; overload;                                       external 'DECMath.dll' name 'NInts_NModU_IICa';
procedure NMod (var   A: IInteger; const M:    IInteger); overload;                                        external 'DECMath.dll' name 'NInts_NMod_IIII';
procedure NMod (var   A: IInteger; const B, M: IInteger); overload;                                        external 'DECMath.dll' name 'NInts_NMod_IIIIII';
function  NRem (const A: IInteger; B: Integer): Integer; overload;                                         external 'DECMath.dll' name 'NInts_NRem_IIIn';
procedure NRem (var   A: IInteger; const B:    IInteger); overload;                                        external 'DECMath.dll' name 'NInts_NRem_IIII';
procedure NRem (var   A: IInteger; const B, C: IInteger); overload;                                        external 'DECMath.dll' name 'NInts_NRem_IIIIII';
function  NDiv (var   Q: IInteger; A: Integer): Integer; overload;                                         external 'DECMath.dll' name 'NInts_NDiv_IIIn';
function  NDivU(var   Q: IInteger; A: Cardinal): Cardinal; {overload;0                                     external 'DECMath.dll' name 'NInts_NDivU_IICa';
procedure NDiv (var   Q: IInteger; const A: IInteger); overload;                                           external 'DECMath.dll' name 'NInts_NDiv_IIII';
function  NDiv (var   Q: IInteger; const A: IInteger; B: Integer): Integer; overload;                      external 'DECMath.dll' name 'NInts_NDiv_IIIIIn';
function  NDivU(var   Q: IInteger; const A: IInteger; B: Cardinal): Cardinal; {overload;}                  external 'DECMath.dll' name 'NInts_NDivU_IIIICa';
procedure NDiv (var   Q: IInteger; const A, B: IInteger); overload;                                        external 'DECMath.dll' name 'NInts_NDiv_IIIIII';
procedure NDivRem  (var Q, R: IInteger; const A, B: IInteger); overload;                                   external 'DECMath.dll' name 'NInts_NDivRem_IIIIIIII';
procedure NDivMod  (var Q, R: IInteger; const A, B: IInteger); overload;                                   external 'DECMath.dll' name 'NInts_NDivMod_IIIIIIII';
procedure NAddMod  (var A: IInteger; const B, C, M: IInteger); overload;                                   external 'DECMath.dll' name 'NInts_NAddMod_IIIIIIII';
procedure NAddMod  (var A: IInteger; const B,    M: IInteger); overload;                                   external 'DECMath.dll' name 'NInts_NAddMod_IIIIII';
procedure NSubMod  (var A: IInteger; const B, C, M: IInteger); overload;                                   external 'DECMath.dll' name 'NInts_NSubMod_IIIIIIII';
procedure NSubMod  (var A: IInteger; const B,    M: IInteger); overload;                                   external 'DECMath.dll' name 'NInts_NSubMod_IIIIII';
procedure NMulMod  (var A: IInteger; const B, C, M: IInteger); overload;                                   external 'DECMath.dll' name 'NInts_NMulMod_IIIIIIII';
procedure NMulMod  (var A: IInteger; const B,    M: IInteger); overload;                                   external 'DECMath.dll' name 'NInts_NMulMod_IIIIII';
procedure NMulMod2k(var A: IInteger; const B, C: IInteger; K: Cardinal); overload;                         external 'DECMath.dll' name 'NInts_NMulMod2k_IIIIIICa';
procedure NMulMod2k(var A: IInteger; const B:    IInteger; K: Cardinal); overload;                         external 'DECMath.dll' name 'NInts_NMulMod2k_IIIICa';
procedure NSqrMod  (var A: IInteger; const B, M: IInteger); overload;                                      external 'DECMath.dll' name 'NInts_NSqrMod_IIIIII';
procedure NSqrMod  (var A: IInteger; const    M: IInteger); overload;                                      external 'DECMath.dll' name 'NInts_NSqrMod_IIII';
procedure NSqrMod2k(var A: IInteger; const B:    IInteger; K: Cardinal); overload;                         external 'DECMath.dll' name 'NInts_NSqrMod2k_IIIICa';
procedure NSqrMod2k(var A: IInteger; K: Cardinal); overload;                                               external 'DECMath.dll' name 'NInts_NSqrMod2k_IICa';
function  NInvMod  (var A: IInteger; const    M: IInteger): Boolean; overload;                                                       external 'DECMath.dll' name 'NInts_NInvMod_IIII';
function  NInvMod  (var A: IInteger; const B, M: IInteger): Boolean; overload;                                                       external 'DECMath.dll' name 'NInts_NInvMod_IIIIII';
function  NInvMod  (var A: IIntegerArray; const B: IIntegerArray; const M: IInteger; Inv2k: Cardinal = 0): Boolean; overload;        external 'DECMath.dll' name 'NInts_NInvMod_IAIAIICa';
function  NInvMod  (var A: IIntegerArray; const M: IInteger; Inv2k: Cardinal = 0): Boolean; overload;                                external 'DECMath.dll' name 'NInts_NInvMod_IAIICa';
function  NInvMod2k(var A: IInteger; K: Cardinal): Boolean; overload;                                                                external 'DECMath.dll' name 'NInts_NInvMod2k_IICa';
function  NInvMod2k(var A: IInteger; const B: IInteger; K: Cardinal): Boolean; overload;                                             external 'DECMath.dll' name 'NInts_NInvMod2k_IIIICa';
function  NPowMod  (var A: IInteger; const    E, M: IInteger; const P: IPowModPrecomputation = nil): Boolean; overload;              external 'DECMath.dll' name 'NInts_NPowMod_IIIIIIMP';
function  NPowMod  (var A: IInteger; const B, E, M: IInteger; const P: IPowModPrecomputation = nil): Boolean; overload;              external 'DECMath.dll' name 'NInts_NPowMod_IIIIIIIIMP';
function  NPowMod  (var A: IInteger; const B, E: IIntegerArray; const M: IInteger): Boolean; overload;                               external 'DECMath.dll' name 'NInts_NPowMod_IIIAIAII';
function  NPowMod2k(var A: IInteger; const B, E: IInteger; K: Cardinal; const P: IPowModPrecomputation = nil): Boolean; overload;    external 'DECMath.dll' name 'NInts_NPowMod2k_IIIIIICaMP';
function  NPowMod2k(var A: IInteger; const    E: IInteger; K: Cardinal; const P: IPowModPrecomputation = nil): Boolean; overload;    external 'DECMath.dll' name 'NInts_NPowMod2k_IIIICaMP';
procedure NPow(var A: IInteger;    E: Integer); overload;                                                                            external 'DECMath.dll' name 'NInts_NPow_IIIn';
procedure NPow(var A: IInteger; B, E: Integer); overload;                                                                            external 'DECMath.dll' name 'NInts_NPow_IIInIn';
procedure NPow(var A: IInteger; const B: IInteger; E: Integer); overload;                                                            external 'DECMath.dll' name 'NInts_NPow_IIIIIn';
function  NGCD1(const A:    IIntegerArray): Boolean; overload;                                                                       external 'DECMath.dll' name 'NInts_NGCD1_IA';
function  NGCD1(const A, B: IInteger): Boolean; overload;                                                                            external 'DECMath.dll' name 'NInts_NGCD1_IIII';
function  NGCD(A, B: Integer): Integer; overload;                                                                                    external 'DECMath.dll' name 'NInts_NGCD_InIn';
function  NGCD(var D: IInteger; const A, B: IInteger): Boolean; overload;                                                            external 'DECMath.dll' name 'NInts_NGCD_IIIIII';
function  NGCD(var D: IInteger; const A: IIntegerArray): Boolean; overload;                                                          external 'DECMath.dll' name 'NInts_NGCD_IIIA';
function  NGCD(var D, U, V: IInteger; const A, B: IInteger): Boolean; overload;                                                      external 'DECMath.dll' name 'NInts_NGCD_IIIIIIIIII';
procedure NLCM(var L: IInteger; const A, B: IInteger); {overload;}                                                                   external 'DECMath.dll' name 'NInts_NLCM_IIIIII';
function  NCRT(var A: IInteger; const R, M: IIntegerArray): Boolean; overload;                                                       external 'DECMath.dll' name 'NInts_NCRT_IIIAIA';
function  NCRT(var A: IInteger; const R, M, U: IIntegerArray): Boolean; overload;                                                    external 'DECMath.dll' name 'NInts_NCRT_IIIAIAIA';
function  NCRT(var U: IIntegerArray; const M: IIntegerArray): Boolean; overload;                                                     external 'DECMath.dll' name 'NInts_NCRT_IAIA';
function  NSqrt(var A: IInteger; const B: IInteger): Boolean; overload;  {1.}                                                        external 'DECMath.dll' name 'NInts_NSqrt_IIII';
function  NSqrt(var A: IInteger): Boolean; overload;                                                                                 external 'DECMath.dll' name 'NInts_NSqrt_II';
function  NSqrt(var A, R: IInteger; const B: IInteger): Boolean; overload;                                                           external 'DECMath.dll' name 'NInts_NSqrt_IIIIII';
function  NSqrtMod2k(var A: IInteger; K: Cardinal): Boolean; overload;                                                               external 'DECMath.dll' name 'NInts_NSqrtMod2k_IICa';
function  NSqrtMod2k(var A: IInteger; const B: IInteger; K: Cardinal): Boolean; overload;                                            external 'DECMath.dll' name 'NInts_NSqrtMod2k_IIIICa';
function  NSqrtMod(var A: IInteger; const P: IInteger; Check: Boolean = False): Integer; overload;                                   external 'DECMath.dll' name 'NInts_NSqrtMod_IIIIBo';
function  NRoot(var A, R: IInteger; const B: IInteger; E: Integer): Boolean; overload;  {1.}                                         external 'DECMath.dll' name 'NInts_NRoot_IIIIIIIn';
function  NRoot(var A: IInteger; E: Integer): Boolean; overload;                                                                     external 'DECMath.dll' name 'NInts_NRoot_IIIn';
function  NRoot(var A: IInteger; const B: IInteger; E: Integer): Boolean; overload;                                                  external 'DECMath.dll' name 'NInts_NRoot_IIIIIn';
function  NRootMod2k(var A: IInteger; const    E: IInteger; K: Cardinal): Boolean; overload;                                         external 'DECMath.dll' name 'NInts_NRootMod2k_IIIICa';
function  NRootMod2k(var A: IInteger; const B, E: IInteger; K: Cardinal): Boolean; overload;                                         external 'DECMath.dll' name 'NInts_NRootMod2k_IIIIIICa';
function  NIsPerfectSqr(const A: IInteger; FullTest: Boolean = True): Boolean; overload;                                             external 'DECMath.dll' name 'NInts_NIsPerfectSqr_IIBo';
function  NIsPerfectSqr(const N: Int64): Boolean; overload;                                                                          external 'DECMath.dll' name 'NInts_NIsPerfectSqr_I6';
function  NIsPerfectPower(var B: IInteger; const N: IInteger; Bound: Cardinal = 0): Cardinal; overload;  {1.}                        external 'DECMath.dll' name 'NInts_NIsPerfectPower_IIIICa';
function  NIsPerfectPower(const N: IInteger; Bound: Cardinal = 0): Cardinal; overload;                                               external 'DECMath.dll' name 'NInts_NIsPerfectPower_IICa';
function  NIsPower(const N:    IInteger; B, E: Integer):  Boolean; overload;                                                         external 'DECMath.dll' name 'NInts_NIsPower_IIInIn';
function  NIsPower(const N, B: IInteger;    E: Integer):  Boolean; overload;                                                         external 'DECMath.dll' name 'NInts_NIsPower_IIIIIn';
function  NIsPower(const N, B,              E: IInteger): Boolean; overload;                                                         external 'DECMath.dll' name 'NInts_NIsPower_IIIIII';
function  NIsPowerOf2(const A: IInteger): Integer; overload;                                                                         external 'DECMath.dll' name 'NInts_NIsPowerOf2_II';
function  NIsDivisible(const A: IInteger; B: Cardinal): Boolean; overload;                                                           external 'DECMath.dll' name 'NInts_NIsDivisible_IICa';
function  NTrialDivision(const A: IInteger; Bound: Cardinal = $FFFF): TTrialDivision; overload;                                      external 'DECMath.dll' name 'NInts_NTrialDivision_IICa';
function  NSmallFactor(const A: IInteger; Bound: Cardinal = 0): Cardinal; overload;                                                  external 'DECMath.dll' name 'NInts_NSmallFactor_IICa';
function  NSPP(const N: IInteger; const Bases: array of Integer): Boolean;                                                           external 'DECMath.dll' name 'NInts_NSPP_IIAI';
function  NIsProbablePrime(const A: IInteger): Boolean; overload;                                                                    external 'DECMath.dll' name 'NInts_NIsProbablePrime_II';
function  NIsProbablePrime(const A: IInteger; const Bases: array of Integer): Boolean; overload;                                     external 'DECMath.dll' name 'NInts_NIsProbablePrime_IIAI';
function  NMakePrime(var P: IInteger; const Bases: array of Integer): Integer; overload;                                             external 'DECMath.dll' name 'NInts_NMakePrime_IIAI';
function  NMakePrime(var P: IInteger; const Bases: array of Integer;
                  Residue, Modulus: Integer;  Callback: TIIntegerPrimeCallback = nil): Integer; overload;                            external 'DECMath.dll' name 'NInts_NMakePrime_IIAIInInPC';
function  NMakePrime(var P: IInteger; const Bases: array of Integer;
            const Residue, Modulus: IInteger; Callback: TIIntegerPrimeCallback = nil): Integer; overload;                            external 'DECMath.dll' name 'NInts_NMakePrime_IIAIIIIIPC';
procedure NLimLeePrime(var P: IInteger; var F: IIntegerArray; PBitSize: Integer; QBitSize: Integer = 0); overload;                   external 'DECMath.dll' name 'NInts_NLimLeePrime_IIIAInIn';
procedure NLimLeePrime(var P, Q: IInteger; PBitSize: Integer; QBitSize: Integer = 0); overload;                                      external 'DECMath.dll' name 'NInts_NLimLeePrime_IIIIInIn';
function  NJacobi(A, B: Int64): Integer; overload;                                                                                   external 'DECMath.dll' name 'NInts_NJacobi_I6I6';
function  NJacobi(A, B: Integer): Integer; overload;                                                                                 external 'DECMath.dll' name 'NInts_NJacobi_InIn';
function  NJacobi(A: Integer; const B: IInteger): Integer; overload;                                                                 external 'DECMath.dll' name 'NInts_NJacobi_InII';
function  NJacobi(const A: IInteger; B: Integer): Integer; overload;                                                                 external 'DECMath.dll' name 'NInts_NJacobi_IIIn';
function  NJacobi(const A, B: IInteger): Integer; overload;                                                                          external 'DECMath.dll' name 'NInts_NJacobi_IIII';
procedure NLucas(var    V: IInteger;    const K:             IInteger); overload;                                                    external 'DECMath.dll' name 'NInts_NLucas_IIII';
procedure NLucas(var U, V: IInteger;    const K:             IInteger); overload;                                                    external 'DECMath.dll' name 'NInts_NLucas_IIIIII';
procedure NLucas(var    V: IInteger;    const K, P,    Q:    IInteger); overload;                                                    external 'DECMath.dll' name 'NInts_NLucas_IIIIIIII';
procedure NLucas(var U, V: IInteger;    const K, P,    Q:    IInteger); overload;                                                    external 'DECMath.dll' name 'NInts_NLucas_IIIIIIIIII';
procedure NLucasMod(var V: IInteger;    const K, P,       M: IInteger); overload;                                                    external 'DECMath.dll' name 'NInts_NLucasMod_IIIIIIII';
procedure NLucasMod(var V: IInteger;    const K, P,    Q, M: IInteger); overload;                                                    external 'DECMath.dll' name 'NInts_NLucasMod_IIIIIIIIII';
procedure NLucasMod(var U, V: IInteger; const K, P,    Q, M: IInteger); overload;                                                    external 'DECMath.dll' name 'NInts_NLucasMod_IIIIIIIIIIII';
function  NInvLucasMod(var A: IInteger; const K, N, P, Q:    IInteger): Boolean; overload;                                           external 'DECMath.dll' name 'NInts_NInvLucasMod_IIIIIIIIII';
function  NInvLucasMod(var A: IInteger; const K, N, P, Q, U: IInteger): Boolean; overload;                                           external 'DECMath.dll' name 'NInts_NInvLucasMod_IIIIIIIIIIII';

procedure NFermat   (var A: IInteger; N: Cardinal; const M: IInteger = nil); {overload;}                                             external 'DECMath.dll' name 'NInts_NFermat_IICaII';
procedure NFibonacci(var R: IInteger; N: Cardinal; const M: IInteger = nil); {overload;}                                             external 'DECMath.dll' name 'NInts_NFibonacci_IICaII';

function  NDigitCount(FromBase, ToBase: TBase; Digits: Cardinal): Cardinal; overload;                                                external 'DECMath.dll' name 'NInts_NDigitCount_BaBaCa';
function  NDigitCount(const A: IInteger; Base: TBase = 10; Exactly: Boolean = True): Cardinal; overload;                             external 'DECMath.dll' name 'NInts_NDigitCount_IIBaBo';
function  NLn   (const A: IInteger; Base: Cardinal = 1; ErrorCheck: Boolean = False): Extended; overload;                            external 'DECMath.dll' name 'NInts_NLn_IICaBo';
function  NDigit(const A: IInteger; Index: Integer;                  Piece: TPiece = piByte): Cardinal; overload;                    external 'DECMath.dll' name 'NInts_NDigit_IIInPi';
procedure NDigit(var   A: IInteger; Index: Integer; Value: Cardinal; Piece: TPiece = piByte); overload;                              external 'DECMath.dll' name 'NInts_NDigit_IIInCaPi';
procedure NAF(var A: TNAFArray; const B: IInteger; W: Byte = 2); {overload;}                                                         external 'DECMath.dll' name 'NInts_NAF_NAIIBy';
function  NStr(const A: IInteger; Base: TBase = 0): RetString; overload;                                                             external 'DECMath.dll' name 'NInts_NStr_IIBa';
function  NStr(const A: IInteger; const Format: TStrFormat): RetString; overload;                                                    external 'DECMath.dll' name 'NInts_NStr_IISF';
function  NInt32(const A: IInteger; RangeCheck: Boolean = True): Integer; overload;                                                  external 'DECMath.dll' name 'NInts_NInt32_IIBo';
function  NInt64(const A: IInteger; RangeCheck: Boolean = True): Int64; overload;                                                    external 'DECMath.dll' name 'NInts_NInt64_IIBo';
function  NLong (const A: IInteger; RangeCheck: Boolean = True): Cardinal; overload;                                                 external 'DECMath.dll' name 'NInts_NLong_IIBo';
function  NFloat(const A: IInteger; RangeCheck: Boolean = True): Extended; overload;                                                 external 'DECMath.dll' name 'NInts_NFloat_IIBo';
function  NRange(const A: IInteger; Range: PTypeInfo; RaiseError: Boolean = False): Boolean; overload;                               external 'DECMath.dll' name 'NInts_NRange_IITIBo';
procedure NSave (const A: IInteger; Stream: TStream;        Format: TIntegerFormat = ifASN1); overload;                              external 'DECMath.dll' name 'NInts_NSave_IIStIF';
procedure NSave (const A: IInteger; const FileName: AnsiString; Format: TIntegerFormat = ifASN1); overload;                          external 'DECMath.dll' name 'NInts_NSave_IIStIF';
procedure NLoad   (var R: IInteger; Stream: TStream;        Format: TIntegerFormat = ifASN1); overload;                              external 'DECMath.dll' name 'NInts_NLoad_IIStIF';
procedure NLoad   (var R: IInteger; const FileName: AnsiString; Format: TIntegerFormat = ifASN1); overload;                          external 'DECMath.dll' name 'NInts_NLoad_IIStIF';
procedure NHash   (var A: IInteger;                    Hash: TDECHashClass = nil; Bits: Integer = 0; Index: Cardinal = 0); overload; external 'DECMath.dll' name 'NInts_NHash_IIHCInCa';
procedure NHash   (var A: IInteger; const B: IInteger; Hash: TDECHashClass = nil; Bits: Integer = 0; Index: Cardinal = 0); overload; external 'DECMath.dll' name 'NInts_NHash_IIIIHCInCa';

function  NMont(const                          M: IInteger):   Cardinal;  overload;                                                  external 'DECMath.dll' name 'NInts_NMont_II';
procedure NMont(var A: IInteger;      const    M: IInteger; R: Cardinal); overload;                                                  external 'DECMath.dll' name 'NInts_NMont_IIIICa';
procedure NMont(var A: IInteger;      const B, M: IInteger; R: Cardinal); overload;                                                  external 'DECMath.dll' name 'NInts_NMont_IIIIIICa';
procedure NMont(var A: IIntegerArray; const B: IIntegerArray; const M: IInteger; Inv2k: Cardinal = 0); overload;                     external 'DECMath.dll' name 'NInts_NMont_IAIAIICa';
procedure NMont(var A: IIntegerArray; const    M: IInteger;                      Inv2k: Cardinal = 0); overload;                     external 'DECMath.dll' name 'NInts_NMont_IAIICa';
procedure NRedc(var A: IInteger;      const    M: IInteger; R: Cardinal); overload;                                                  external 'DECMath.dll' name 'NInts_NRedc_IIIICa';
procedure NRedc(var A: IInteger;      const B, M: IInteger; R: Cardinal); overload;                                                  external 'DECMath.dll' name 'NInts_NRedc_IIIIIICa';
procedure NRedc(var A: IIntegerArray; const B: IIntegerArray; const M: IInteger; Inv2k: Cardinal = 0); overload;                     external 'DECMath.dll' name 'NInts_NRedc_IAIAIICa';
procedure NRedc(var A: IIntegerArray; const    M: IInteger;                      Inv2k: Cardinal = 0); overload;                     external 'DECMath.dll' name 'NInts_NRedc_IAIICa';

procedure NSet (var   P: IPowModPrecomputation; const B, M: IInteger; EMaxBitSize: Integer; EIsNeg: Boolean = False); overload;      external 'DECMath.dll' name 'NInts_NSet_MPIIIIInBo';
procedure NSave(const P: IPowModPrecomputation; Stream: TStream); overload;                                                          external 'DECMath.dll' name 'NInts_NSave_MPSt';
procedure NLoad(var   P: IPowModPrecomputation; Stream: TStream); overload;                                                          external 'DECMath.dll' name 'NInts_NLoad_MPSt';

function  NSum(const A: IInteger): Long96; overload;                                                                                 external 'DECMath.dll' name 'NInts_NSum_II';
function  NMod(const A: Long96; B: Cardinal): Cardinal; overload;                                                                    external 'DECMath.dll' name 'NInts_NMod_L9Ca';
procedure NSumModFactors(var Factors: IInteger; Bit: Integer); {overload;}                                                           external 'DECMath.dll' name 'NInts_NSumModFactors_IIIn';
procedure NSumModModulis(var Modulis: IInteger; const Factors: IInteger); {overload;}                                                external 'DECMath.dll' name 'NInts_NSumModModulis_IIII';
function  NInvMod2k32(      A: Cardinal):                                  Cardinal; overload;  { A^-1 mod 2^32 }                    external 'DECMath.dll' name 'NInts_NInvMod2k32_Ca';
function  NInvMod2k32(const A: IInteger; B: Cardinal; BInv: Cardinal = 0): Cardinal; overload;                                       external 'DECMath.dll' name 'NInts_NInvMod2k32_IICaCa';
function  NInvMul2k32(      A,           B: Cardinal; BInv: Cardinal = 0): Cardinal; overload;                                       external 'DECMath.dll' name 'NInts_NInvMul2k32_CaCaCa';

procedure NInsert(var A: IInteger; B: Cardinal; Duplicates: Boolean = False); overload;                                              external 'DECMath.dll' name 'NInts_NInsert_IICaBo';
function  NFind(const A: IInteger; B: Cardinal; var Index: Integer): Boolean; overload;                                              external 'DECMath.dll' name 'NInts_NFind_IICaIn';
function  NFind(const A: IInteger; B: Cardinal):           Integer; overload;                                                        external 'DECMath.dll' name 'NInts_NFind_IICa';
procedure NSort(var A: IInteger); overload;                                                                                          external 'DECMath.dll' name 'NInts_NSort_II';
procedure NSort(var A: IIntegerArray; Compare: TIIntegerSortCompare); overload;                                                      external 'DECMath.dll' name 'NInts_NSort_IASC';
procedure NSort(var A: IIntegerArray; Abs: Boolean = False; Descending: Boolean = False); overload;                                  external 'DECMath.dll' name 'NInts_NSort_IABoBo';
function  NForEach(const A: IIntegerArray; Callback: TIIntegerForEachCallback): IInteger; overload;                                  external 'DECMath.dll' name 'NInts_NForEach_IAIC';
function  NBinarySplitting(var P, Q: IInteger; Count: Integer;
            Callback: TIIntegerBinarySplittingCallback; ImplicitShift: Boolean = True): Cardinal; {overload;}                        external 'DECMath.dll' name 'NInts_NBinarySplitting_XXX';
function  NConfig(Flag: Cardinal = 3): Cardinal;                                                                                     external 'DECMath.dll' name 'NInts_NConfig_Ca';

procedure NRaise(Msg: PResStringRec; const Param: AnsiString); overload;     external 'DECMath.dll' name 'NInts_NRaise_SRSt';
procedure NRaise(Msg: PResStringRec; const Param: array of const); overload; external 'DECMath.dll' name 'NInts_NRaise_SRAC';
procedure NRaise(Msg: PResStringRec = nil); overload;                        external 'DECMath.dll' name 'NInts_NRaise_SR';
procedure NRaise_DivByZero; overload;                                        external 'DECMath.dll' name 'NInts_NRaise_DivByZero_';

procedure NParseFormat(var F: TStrFormat; const B: AnsiString);              external 'DECMath.dll' name 'NInts_NParseFormat_SFSt';
function  NLog2     (A: Cardinal): Integer;                                  external 'DECMath.dll' name 'NInts_NLog2_Ca';
function  NBitWeight(A: Cardinal): Integer; {overload;}                      external 'DECMath.dll' name 'NInts_NBitWeight_Ca';
function  NBitSwap  (A: Cardinal): Cardinal; {overload;}                     external 'DECMath.dll' name 'NInts_NBitSwap_Ca';
function  NGrayCodeTo(    N: Cardinal): Cardinal; overload;                  external 'DECMath.dll' name 'NInts_NGrayCodeTo_Ca';
procedure NGrayCodeTo(var A: IInteger; const B: IInteger); overload;         external 'DECMath.dll' name 'NInts_NGrayCodeTo_IIII';
function  NToGrayCode(    N: Cardinal): Cardinal; overload;                  external 'DECMath.dll' name 'NInts_NToGrayCode_Ca';
procedure NToGrayCode(var A: IInteger; const B: IInteger); overload;         external 'DECMath.dll' name 'NInts_NToGrayCode_IIII';

function  NGreenCodeTo(    N: Cardinal): Cardinal; overload;                 external 'DECMath.dll' name 'NInts_NGreenCodeTo_Ca';
procedure NGreenCodeTo(var A: IInteger; const B: IInteger); overload;        external 'DECMath.dll' name 'NInts_NGreenCodeTo_IIII';
function  NToGreenCode(    N: Cardinal): Cardinal; overload;                 external 'DECMath.dll' name 'NInts_NToGreenCode_Ca';
procedure NToGreenCode(var A: IInteger; const B: IInteger); overload;        external 'DECMath.dll' name 'NInts_NToGreenCode_IIII';

// predefined and fast constant
function  NNull:     IInteger;  {  0 }                                       external 'DECMath.dll' name 'NInts_NNull';
function  NOne:      IInteger;  { +1 }                                       external 'DECMath.dll' name 'NInts_NOne';
function  NMinusOne: IInteger;  { -1 }                                       external 'DECMath.dll' name 'NInts_NMinusOne';
function  NTwo:      IInteger;  { +2 }                                       external 'DECMath.dll' name 'NInts_NTwo';
function  NMinusTwo: IInteger;  { -2 }                                       external 'DECMath.dll' name 'NInts_NMinusTwo';

function  NBreakEven(Index: Integer): Cardinal;                              external 'DECMath.dll' name 'NInts_NBreakEven_In';

// points
procedure NSwp(var A,                B: I2Point); overload;                  external 'DECMath.dll' name 'NInts_NSwp_2P2P';
procedure NSwp(var A,                B: I3Point); overload;                  external 'DECMath.dll' name 'NInts_NSwp_3P3P';
procedure NSet(var A: I2Point; const B: I2Point); overload;                  external 'DECMath.dll' name 'NInts_NSet_2P2P';
procedure NSet(var A: I3Point; const B: I3Point); overload;                  external 'DECMath.dll' name 'NInts_NSet_3P3P';

//var
//  NStrFormat: TStrFormat = (
//    Base: 10;
//    Plus: '';
//    Minus: '-';
//    Zero: '';
//    Comma: ',';
//    DigitsPerBlock: 5;
//    BlockSep: ' ';
//    BlockPadding: ' ';
//    DigitsPerLine: 0;
//    LineSep: #13#10;
//    LinePadding: #0;
//    DigitsChars: '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz+/';
//    FormatChars: ' /\-+;:#~"()[]?_<>!§$%&{}'''#13#10#9;
//    LeftAlign: False;
//    Offset: 0;
//    Precision: 0;
//   );
function  GetNStrFormat:         TStrFormat;  external 'DECMath.dll' name 'NInts_GetNStrFormat';
procedure SetNStrFormat(const F: TStrFormat); external 'DECMath.dll' name 'NInts_SetNStrFormat';

function NNorm (const A: IInteger): Pointer; overload;          external 'DECMath.dll' name 'NInts_NNorm_II';
function NValid(const A: array of IInteger): Boolean; overload; external 'DECMath.dll' name 'NInts_NValid_AI';
function NValid(const A: IIntegerArray):     Boolean; overload; external 'DECMath.dll' name 'NInts_NValid_IA';

{$ENDREGION}
{$REGION 'NIntM : NInts'}

type
  IModulus = packed record
    M: Cardinal; // Modulus
    U: Cardinal; // inverse for Montgomery, if <> 0 M use Montgomery
    C: Cardinal; // value to compute Montgomery
    O: Cardinal; // One in Normal or Montgomery Domain
  end;

procedure NSet   (var M: IModulus; Modulus: Cardinal); overload;           external 'DECMath.dll' name 'NIntM_NSet_IMCa';
function  NSet    (A:    Cardinal; const M: IModulus): Cardinal; overload; external 'DECMath.dll' name 'NIntM_NSet_CaIM';
function  NGet    (A:    Cardinal; const M: IModulus): Cardinal; overload; external 'DECMath.dll' name 'NIntM_NGet_CaIM';
function  NAddMod (A, B: Cardinal; const M: IModulus): Cardinal; overload; external 'DECMath.dll' name 'NIntM_NAddMod_CaCaIM';
function  NSubMod (A, B: Cardinal; const M: IModulus): Cardinal; overload; external 'DECMath.dll' name 'NIntM_NSubMod_CaCaIM';
function  NMulMod (A, B: Cardinal; const M: IModulus): Cardinal; overload; external 'DECMath.dll' name 'NIntM_NMulMod_CaCaIM';
function  NPowMod (A, E: Cardinal; const M: IModulus): Cardinal; overload; external 'DECMath.dll' name 'NIntM_NPowMod_CaCaIM';
function  NSqrtMod(A:    Cardinal; const M: IModulus): Cardinal; overload; external 'DECMath.dll' name 'NIntM_NSqrtMod_CaIM';
function  NSqrtMod(A, P: Cardinal):    Cardinal; overload;                 external 'DECMath.dll' name 'NIntM_NSqrtMod_CaCa';
function  NInvMod (A,    M: Cardinal): Cardinal; overload;                 external 'DECMath.dll' name 'NIntM_NInvMod_CaCa';
function  NMulMod (A, B, M: Cardinal): Cardinal; overload;                 external 'DECMath.dll' name 'NIntM_NMulMod_CaCaCa';
function  NAddMod (A, B, M: Cardinal): Cardinal; overload;                 external 'DECMath.dll' name 'NIntM_NAddMod_CaCaCa';
function  NSubMod (A, B, M: Cardinal): Cardinal; overload;                 external 'DECMath.dll' name 'NIntM_NSubMod_CaCaCa';

{$ENDREGION}
{$REGION 'NInt_1 : -NMath,- NInts, SysUtils (FULL-SOURCE)'}

type
  TCFEFunc = function(Index: Integer): Integer; register;
  TIIntegerPIMethod = (piFastChudnovsky, piIterChudnovsky, piAGM, piFastMachin, piIterMachin);

procedure NCFE(var P, Q: IInteger; CFEFunc: TCFEFunc; Last: Integer);          external 'DECMath.dll' name 'NInt1_NCFE_IIIIFuIn';

function  CFE_Euler(Index: Integer): Integer;                                  external 'DECMath.dll' name 'NInt1_CFE_Euler_In';
function  CFE_GoldenRatio(Index: Integer): Integer;                            external 'DECMath.dll' name 'NInt1_CFE_GoldenRatio_In';
function  CFE_Tan1(Index: Integer): Integer;                                   external 'DECMath.dll' name 'NInt1_CFE_Tan1_II';

procedure NLn2    (var R: IInteger);                                           external 'DECMath.dll' name 'NInt1_NLn2_II';
procedure NLn10   (var R: IInteger);                                           external 'DECMath.dll' name 'NInt1_NLn10_II';
procedure NArcTan (var R: IInteger; const U, V: IInteger); overload;           external 'DECMath.dll' name 'NInt1_NArcTan_IIIIII';
procedure NArcTan (var R: IInteger;          V: Integer);  overload;           external 'DECMath.dll' name 'NInt1_NArcTan_IIII';
procedure NArcTanh(var R: IInteger; const    V: IInteger);                     external 'DECMath.dll' name 'NInt1_NArcTanh_IIII';
procedure NSin    (var R: IInteger; const U, V: IInteger);                     external 'DECMath.dll' name 'NInt1_NSin_IIIIII';
procedure NSinh   (var R: IInteger; const U, V: IInteger);                     external 'DECMath.dll' name 'NInt1_NSinh_IIIIII';
procedure NCos    (var R: IInteger; const U, V: IInteger);                     external 'DECMath.dll' name 'NInt1_NCos_IIIIII';
procedure NCosh   (var R: IInteger; const U, V: IInteger);                     external 'DECMath.dll' name 'NInt1_NCosh_IIIIII';
procedure NTan    (var R: IInteger; const U, V: IInteger);                     external 'DECMath.dll' name 'NInt1_NTan_IIIIII';
procedure NTanh   (var R: IInteger; const U, V: IInteger);                     external 'DECMath.dll' name 'NInt1_NTanh_IIIIII';
procedure NExp    (var A: IInteger; U: Integer = 1; V: Integer = 1); overload; external 'DECMath.dll' name 'NInt1_NExp_IIInIn';
procedure NExp    (var A: IInteger; const U, V: IInteger); overload;           external 'DECMath.dll' name 'NInt1_NExp_IIIIII';
function  NPi     (var A: IInteger; Decimals: Cardinal; Method: TIIntegerPIMethod = piFastChudnovsky): Cardinal; external 'DECMath.dll' name 'NInt1_NPi_IICaTM';

procedure NFactorial1(var A: IInteger; N: Cardinal);                           external 'DECMath.dll' name 'NInt1_NFactorial1_IICa';

{$ENDREGION}
{$REGION 'NRats : NMath, NInts, SysUtils'}

type
  IRational = interface
    ['{126BE020-061D-4067-9E0A-E2A490AF5CEA}']
    function N: IInteger;
    function D: IInteger;
    function Precision(Base: TBase = 10): Cardinal;
  end;

  IRationalArray = array of IRational;

  TIRationalSortCompare = function(const A, B: IRational): Integer; register;
  TIRationalForEachCallback = function(var A: IRational): Boolean; register;

  TIRationalResult = (rrValue, rrNominator, rrDenominator);

procedure NSet(var   A:    IRational; const N: IInteger; const D: IInteger = nil); overload;    external 'DECMath.dll' name 'NRats_NSet_IRIIII';
procedure NSet(var   A:    IRational; const N: Integer;  const D: Integer = 1); overload;       external 'DECMath.dll' name 'NRats_NSet_IRInIn';
procedure NSet(var   A:    IRational; const N: Int64;    const D: Int64 = 1); overload;         external 'DECMath.dll' name 'NRats_NSet_IRI6I6';
procedure NSet(var   A:    IRational; const B: IRational); overload;                            external 'DECMath.dll' name 'NRats_NSet_IRIR';
procedure NSet(var   A:    IRational; const B: Extended); overload;                             external 'DECMath.dll' name 'NRats_NSet_IREx';
procedure NSet(var   A:    IRational; const B: AnsiString; const Format: TStrFormat); overload; external 'DECMath.dll' name 'NRats_NSet_IRStSF';
procedure NSet(var   A:    IRational; const B: AnsiString); overload;                           external 'DECMath.dll' name 'NRats_NSet_IRSt';
procedure NSet(var   A:    IRationalArray; const B: array of IRational); overload;              external 'DECMath.dll' name 'NRats_NSet_IAAR';
function  NRat(const N:    IInteger): IRational; overload;                                      external 'DECMath.dll' name 'NRats_NRat_II';
function  NRat(const N, D: IInteger): IRational; overload;                                      external 'DECMath.dll' name 'NRats_NRat_IIII';
function  NRat(const N:    Integer):  IRational; overload;                                      external 'DECMath.dll' name 'NRats_NRat_In';
function  NRat(const N, D: Integer):  IRational; overload;                                      external 'DECMath.dll' name 'NRats_NRat_InIn';
function  NRat(const N:    Int64):    IRational; overload;                                      external 'DECMath.dll' name 'NRats_NRat_I6';
function  NRat(const N, D: Int64):    IRational; overload;                                      external 'DECMath.dll' name 'NRats_NRat_I6I6';
function  NRat(const A:    Extended): IRational; overload;                                      external 'DECMath.dll' name 'NRats_NRat_Ex';
function  NRat(const A:    AnsiString; const Format: TStrFormat): IRational; overload;          external 'DECMath.dll' name 'NRats_NRat_StSF';
function  NRat(const A:    AnsiString): IRational; overload;                                    external 'DECMath.dll' name 'NRats_NRat_St';
function  NRat(const A:    array of IRational): IRationalArray; overload;                       external 'DECMath.dll' name 'NRats_NRat_AR';
function  NInt(const A:    IRational; What: TIRationalResult = rrValue): IInteger; overload;    external 'DECMath.dll' name 'NRats_NRat_IRRR';
function  NSgn(const A:    IRational):          Integer; overload;                              external 'DECMath.dll' name 'NRats_NSng_IR';
procedure NSgn(var   A:    IRational; Sign:     Integer); overload;                             external 'DECMath.dll' name 'NRats_NSng_IRIn';
function  NNeg(var   A:    IRational):          Boolean; overload;                              external 'DECMath.dll' name 'NRats_NNeg_IR';
function  NNeg(var   A:    IRational; Negative: Boolean): Boolean; overload;                    external 'DECMath.dll' name 'NRats_NNeg_IRBo';
function  NAbs(var   A:    IRational): Boolean; overload;                                       external 'DECMath.dll' name 'NRats_NAbs_IR';
procedure NSwp(var   A, B: IRational); overload;                                                external 'DECMath.dll' name 'NRats_NSwp_IRIRBo';
function  NCmp(const A, B: IRational; Abs: Boolean = False): Integer; overload;                 external 'DECMath.dll' name 'NRats_NCmp_IRCa';
procedure NInc (var A: IRational;       B:    Cardinal = 1); overload;                          external 'DECMath.dll' name 'NRats_NInc_IRCa';
procedure NDec (var A: IRational;       B:    Cardinal = 1); overload;                          external 'DECMath.dll' name 'NRats_NDec_IRIn';
procedure NAdd (var A: IRational;       B:    Integer);      overload;                          external 'DECMath.dll' name 'NRats_NAdd_IRBo';
procedure NAdd (var A: IRational; const B:    IRational;       C: Integer);  overload;          external 'DECMath.dll' name 'NRats_NAdd_IRIRIn';
procedure NAdd (var A: IRational; const B:    IInteger);                     overload;          external 'DECMath.dll' name 'NRats_NAdd_IRII';
procedure NAdd (var A: IRational; const B:    IRational; const C: IInteger); overload;          external 'DECMath.dll' name 'NRats_NAdd_IRIRII';
procedure NAdd (var A: IRational; const B:    IRational); overload;                             external 'DECMath.dll' name 'NRats_NAdd_IRIR';
procedure NAdd (var A: IRational; const B, C: IRational); overload;                             external 'DECMath.dll' name 'NRats_NAdd_IRIRIR';
procedure NSub (var A: IRational;       B: Integer);      overload;                             external 'DECMath.dll' name 'NRats_NSub_IRIn';
procedure NSub (var A: IRational; const B: IRational;       C: Integer);  overload;             external 'DECMath.dll' name 'NRats_NSub_IRIRIn';
procedure NSub (var A: IRational; const B: IInteger);                     overload;             external 'DECMath.dll' name 'NRats_NSub_IRII';
procedure NSub (var A: IRational; const B: IRational; const C: IInteger); overload;             external 'DECMath.dll' name 'NRats_NSub_IRIRIn';
procedure NSub (var A: IRational; const B: IRational);    overload;                             external 'DECMath.dll' name 'NRats_NSub_IRIR';
procedure NSub (var A: IRational; const B, C: IRational); overload;                             external 'DECMath.dll' name 'NRats_NSub_IRIRIR';
procedure NShl (var A: IRational;                     Shift: Integer); overload;                external 'DECMath.dll' name 'NRats_NShl_IRIn';
procedure NShl (var A: IRational; const B: IRational; Shift: Integer); overload;                external 'DECMath.dll' name 'NRats_NShl_IRIRIn';
procedure NShr (var A: IRational;                     Shift: Integer); overload;                external 'DECMath.dll' name 'NRats_NShr_IRIn';
procedure NShr (var A: IRational; const B: IRational; Shift: Integer); overload;                external 'DECMath.dll' name 'NRats_NShr_IRIRIn';
procedure NMul (var A: IRational;       B: Integer);                      overload;             external 'DECMath.dll' name 'NRats_NMul_IRIn';
procedure NMul (var A: IRational; const B: IRational;       C: Integer);  overload;             external 'DECMath.dll' name 'NRats_NMul_IRIRIn';
procedure NMul (var A: IRational; const B: IInteger);                     overload;             external 'DECMath.dll' name 'NRats_NMul_IRII';
procedure NMul (var A: IRational; const B: IRational; const C: IInteger); overload;             external 'DECMath.dll' name 'NRats_NMul_IRIRIn';
procedure NMul (var A: IRational; const B: IRational);    overload;                             external 'DECMath.dll' name 'NRats_NMul_IRIR';
procedure NMul (var A: IRational; const B, C: IRational); overload;                             external 'DECMath.dll' name 'NRats_NMul_IRIRIR';
procedure NSqr (var A: IRational);                        overload;                             external 'DECMath.dll' name 'NRats_NSqr_IR';
procedure NSqr (var A: IRational; const B: IRational);    overload;                             external 'DECMath.dll' name 'NRats_NSqr_IRIR';
procedure NSqrt(var A: IRational);                        overload;                             external 'DECMath.dll' name 'NRats_NSqrt_IR';
procedure NSqrt(var A: IRational; const B: IRational);    overload;                             external 'DECMath.dll' name 'NRats_NSqrt_IRIR';
procedure NDiv (var A: IRational;       B: Integer);      overload;                             external 'DECMath.dll' name 'NRats_NDiv_IRIn';
procedure NDiv (var A: IRational; const B: IRational;       C: Integer);  overload;             external 'DECMath.dll' name 'NRats_NDiv_IRIRIn';
procedure NDiv (var A: IRational; const B: IInteger);                     overload;             external 'DECMath.dll' name 'NRats_NDiv_IRII';
procedure NDiv (var A: IRational; const B: IRational; const C: IInteger); overload;             external 'DECMath.dll' name 'NRats_NDiv_IRIRII';
procedure NDiv (var A: IRational; const B: IRational);                    overload;             external 'DECMath.dll' name 'NRats_NDiv_IRIR';
procedure NDiv (var A: IRational; const B, C: IRational); overload;                             external 'DECMath.dll' name 'NRats_NDiv_IRIRIR';
procedure NInv (var A: IRational);                        overload;                             external 'DECMath.dll' name 'NRats_NInv_IR';
procedure NInv (var A: IRational; const B: IRational);    overload;                             external 'DECMath.dll' name 'NRats_NInv_IRIR';
procedure NPow (var A: IRational;                     E: Integer); overload;                    external 'DECMath.dll' name 'NRats_NPow_IRIn';
procedure NPow (var A: IRational; const B: IRational; E: Integer); overload;                    external 'DECMath.dll' name 'NRats_NPow_IRIRIn';
procedure NExp (var A: IRational);                     overload;                                external 'DECMath.dll' name 'NRats_NExp_IR';
procedure NExp (var A: IRational; const B: IRational); overload;                                external 'DECMath.dll' name 'NRats_NExp_IRIR';

procedure NRnd    (var   A: IRational; Bits: Integer = 0; Sign: Boolean = False); overload;                     external 'DECMath.dll' name 'NRats_NRnd_IRInBo';
function  NStr    (const A: IRational; Base: TBase = 10; Precision: Cardinal = 0): RetString; overload;         external 'DECMath.dll' name 'NRats_NStr_IRTBCa';
function  NStr    (const A: IRational; const Format: TStrFormat; Precision: Cardinal = 0): RetString; overload; external 'DECMath.dll' name 'NRats_NStr_IRSFCa';
procedure NSort   (var   A: IRationalArray; Compare: TIRationalSortCompare); overload;                          external 'DECMath.dll' name 'NRats_NSort_IASC';
procedure NSort   (var   A: IRationalArray; Abs: Boolean = False; Descending: Boolean = False); overload;       external 'DECMath.dll' name 'NRats_NSort_IABoBo';
function  NForEach(const A: IRationalArray; Callback: TIRationalForEachCallback): IRational; overload;          external 'DECMath.dll' name 'NRats_NForEach_IARC';

function  NPrc(var A: IRational; Precision: Cardinal = 0; Base: TBase = 10): Cardinal; overload;                external 'DECMath.dll' name 'NRats_NPrc_IRCaTB';

//var
//  DefaultPrecision: Cardinal = 1024;

function  GetDefaultPrecision:   Cardinal;  external 'DECMath.dll' name 'NRats_GetDefaultPrecision';
procedure SetDefaultPrecision(P: Cardinal); external 'DECMath.dll' name 'NRats_SetDefaultPrecision';

{$ENDREGION}
{$REGION 'NPolys : NInts, CRC, SysUtils'}

type
  IPoly = type IIntegerArray;

procedure NSet(var A: IPoly; const B: IIntegerArray); overload;                                         external 'DECMath.dll' name 'NPolys_NSet_IPIA';
procedure NSet(var A: IPoly; const B: array of const); overload;                                        external 'DECMath.dll' name 'NPolys_NSet_IPAC';
procedure NSet(var A: IPoly; const B: IPoly); overload;                                                 external 'DECMath.dll' name 'NPolys_NSet_IPIP';
procedure NSet(var A: IInteger; const B: IPoly; const X: IInteger; const M: IInteger = nil); overload;  external 'DECMath.dll' name 'NPolys_NSet_IIIPIIII';
function  NInt(const A:  IPoly; const X: IInteger; const M: IInteger = nil): IInteger; overload;        external 'DECMath.dll' name 'NPolys_NInt_IPIIII';
procedure NSwp(var A, B: IPoly); overload;                                                              external 'DECMath.dll' name 'NPolys_NSwp_IPIP';
procedure NSwp(var A:    IPoly); overload;                                                              external 'DECMath.dll' name 'NPolys_NSwp_IP';
function  NPoly(const B: IIntegerArray):  IPoly; overload;                                              external 'DECMath.dll' name 'NPolys_NPoly_IA';
function  NPoly(const B: array of const): IPoly; overload;                                              external 'DECMath.dll' name 'NPolys_NPoly_AC';
function  NDegree(const A:    IPoly): Integer; overload;                                                external 'DECMath.dll' name 'NPolys_NDegree_IP';
function  NCmp   (const A, B: IPoly): Integer; overload;                                                external 'DECMath.dll' name 'NPolys_NCmp_IPIP';
procedure NAdd(var A: IPoly; const B:    IPoly); overload;                                              external 'DECMath.dll' name 'NPolys_NAdd_IPIP';
procedure NAdd(var A: IPoly; const B, C: IPoly); overload;                                              external 'DECMath.dll' name 'NPolys_NAdd_IPIPIP';
procedure NSub(var A: IPoly; const B:    IPoly); overload;                                              external 'DECMath.dll' name 'NPolys_NSub_IPIP';
procedure NSub(var A: IPoly; const B, C: IPoly); overload;                                              external 'DECMath.dll' name 'NPolys_NSub_IPIPIP';
procedure NInc(var A: IPoly; const B:    Cardinal = 1); overload;                                       external 'DECMath.dll' name 'NPolys_NInc_IPCa';
procedure NDec(var A: IPoly; const B:    Cardinal = 1); overload;                                       external 'DECMath.dll' name 'NPolys_NDec_IPCa';
procedure NMul(var A: IPoly; const B:    IPoly); overload;                                              external 'DECMath.dll' name 'NPolys_NMul_IPIP';
procedure NMul(var A: IPoly; const B, C: IPoly); overload;                                              external 'DECMath.dll' name 'NPolys_NMul_IPIPIP';
procedure NMul(var A: IPoly; const B:    IInteger); overload;                                           external 'DECMath.dll' name 'NPolys_NMul_IPII';
procedure NMul(var A: IPoly; const B:    IPoly; const C: IInteger); overload;                           external 'DECMath.dll' name 'NPolys_NMul_IPIPII';
procedure NMul(var A: IPoly;       B:    Integer); overload;                                            external 'DECMath.dll' name 'NPolys_NMul_IPIn';
procedure NMul(var A: IPoly; const B:    IPoly; C: Integer); overload;                                  external 'DECMath.dll' name 'NPolys_NMul_IPIPIn';
procedure NSqr(var A: IPoly); overload;                                                                 external 'DECMath.dll' name 'NPolys_NSqr_IP';
procedure NSqr(var A: IPoly; const B:    IPoly); overload;                                              external 'DECMath.dll' name 'NPolys_NSqr_IPIP';
procedure NRem(var A: IPoly; const M:    IInteger); overload;                                           external 'DECMath.dll' name 'NPolys_NRem_IPII';
procedure NMod(var A: IPoly; const M:    IInteger); overload;                                           external 'DECMath.dll' name 'NPolys_NMod_IPII';
function  NRem(var A: IPoly; const B:    IPoly; const M: IInteger): Boolean; overload;                  external 'DECMath.dll' name 'NPolys_NRem_IPIPII';
function  NRem(var A: IPoly; const B, C: IPoly; const M: IInteger): Boolean; overload;                  external 'DECMath.dll' name 'NPolys_NRem_IPIPIPII';
function  NDiv(var A: IPoly; const B:    IPoly; const M: IInteger): Boolean; overload;                  external 'DECMath.dll' name 'NPolys_NDiv_IPIPII';
function  NDiv(var A: IPoly; const B, C: IPoly; const M: IInteger): Boolean; overload;                  external 'DECMath.dll' name 'NPolys_NDiv_IPIPIPII';
function  NDivRem  (var Q, R: IPoly; const A, B: IPoly; const M: IInteger): Boolean; overload;          external 'DECMath.dll' name 'NPolys_NDivRem_IPIPIPIPII';
procedure NDivXk   (var A:    IPoly;                 K: Cardinal = 1); overload;                        external 'DECMath.dll' name 'NPolys_NDivXk_IPCa';
procedure NDivXk   (var A:    IPoly; const B: IPoly; K: Integer = 1); overload;                         external 'DECMath.dll' name 'NPolys_NDivXk_IPIPIn';
procedure NDivRemXk(var Q, R: IPoly; const B: IPoly; K: Integer = 1); overload;                         external 'DECMath.dll' name 'NPolys_NDivRemXk_IPIPIPIn';
procedure NRemXk (var A: IPoly;                    K: Integer = 1); overload;                           external 'DECMath.dll' name 'NPolys_NRemXk_IPIn';
procedure NRemXk (var A: IPoly; const B:    IPoly; K: Integer = 1); overload;                           external 'DECMath.dll' name 'NPolys_NRemXk_IPIPIn';
procedure NMulXk (var A: IPoly;                    K: Integer = 1); overload;                           external 'DECMath.dll' name 'NPolys_NMulXk_IPIn';
procedure NMulXk (var A: IPoly; const    B: IPoly; K: Integer = 1); overload;                           external 'DECMath.dll' name 'NPolys_NMulXk_IPIPIn';
function  NGCD   (var D: IPoly; const A, B: IPoly; const M: IInteger): Boolean; overload;               external 'DECMath.dll' name 'NPolys_NGCD_IPIPIPII';
procedure NPowRem(var A: IPoly; const E: IInteger; const B: IPoly; const M: IInteger); overload;        external 'DECMath.dll' name 'NPolys_NPowRem_IPIIIPII';
procedure NPowMod(var A: IPoly; const E: IInteger; const B: IPoly; const M: IInteger); overload;        external 'DECMath.dll' name 'NPolys_NPowMod_IPIIIPII';
procedure NRnd   (var A: IPoly; Degree: Cardinal; const M: IInteger; Monic: Boolean = False); overload; external 'DECMath.dll' name 'NPolys_NRnd_IPCaIIBo';
procedure NFactor(var A: IPoly; const B: IPoly; K: Integer; const M: IInteger); overload;               external 'DECMath.dll' name 'NPolys_NFactor_IPIPInII';
function  NStr (const A: IPoly; Base: TBase = 0): RetString; overload;                                  external 'DECMath.dll' name 'NPolys_NStr_IPBa';
function  NStr (const A: IPoly; const Format: TStrFormat): RetString; overload;                         external 'DECMath.dll' name 'NPolys_NStr_IPSF';
function  NCRC (const A: IPoly; CRC: TCRCType = CRC_32CCITT): Cardinal; overload;                       external 'DECMath.dll' name 'NPolys_NCRC_IPCT';
procedure NNorm  (var A: IPoly); overload;                                                              external 'DECMath.dll' name 'NPolys_NNorm_IP';

{$ENDREGION}
{$REGION 'Prime : CRC, SysUtils, Classes, Windows'}
// Description: Small Primes upto 2^32-1
// Remarks:     codesize 6415 bytes, datasize 48 bytes if all methods are used
{
 some usefull primeconstant:

 if SPP(n <= x, [bases]) then n is prime,              HEX(x)
   SPP(           1.373.653, [2, 3]),                   $00000000 0014F5D5
   SPP(           9.080.191, [31, 73]),                 $00000000 008A8D7F
   SPP(          25.326.001  [2, 3, 5]),                $00000000 018271B1
   SPP(       4.759.123.141, [2, 7, 61]),               $00000001 1BAA74C5
   SPP(   1.000.000.000.000, [2, 13, 23, 1662803]),     $000000E8 D4A51000

   SPP(   2.152.302.898.747, [2, 3, 5, 7, 11]),         $000001F5 1F3FEE3B
   SPP(   3.474.749.660.383, [2, 3, 5, 7, 11, 13]),     $00000329 07381CDF
   SPP( 341.550.071.728.321, [2, 3, 5, 7, 11, 13, 17]), $000136A3 52B2C8C1

   http://www.utm.edu/research/primes/glossary/Pseudoprime.html

 a Carmichel, (Bleichenbacher)
 x = 18.215.745.452.589.259.639 * 4.337.082.250.616.490.391 * 867.416.450.123.298.079
   = 68.528.663.395.046.912.244.223.605.902.738.356.719.751.082.784.386.681.071
 is a SPP(x, [2..100]) ->
   X.IsProbablePrime([2, -100]) = true,  a SPP(2 upto  97)
   X.IsProbablePrime([ 101])    = false, a SPP(101)
 but
   X.IsProbablePrime([1, 2])    = false, a SPP(2)-PSW Test is performed

 Table of Primecount
                             10                           4
                            100                          25
                          1.000                         168
                         10.000                       1.229
                        100.000                       9.592
                      1.000.000                      78.498
                     10.000.000                     664.579
                    100.000.000                   5.761.455
                  1.000.000.000                  50.847.534
                 10.000.000.000                 455.052.511
                100.000.000.000               4.118.054.813
              1.000.000.000.000              37.607.912.018
             10.000.000.000.000             346.065.536.839
            100.000.000.000.000           3.204.941.750.802
          1.000.000.000.000.000          29.844.570.422.669
         10.000.000.000.000.000         279.238.341.033.925
        100.000.000.000.000.000       2.623.557.157.654.233
      1.000.000.000.000.000.000      24.739.954.287.740.860
     10.000.000.000.000.000.000     234.057.667.276.344.607
    100.000.000.000.000.000.000   2.220.819.602.560.918.840
  1.000.000.000.000.000.000.000  21.127.269.486.018.731.928
}

type
  ISmallPrimeSieve = interface
    ['{897D56D7-7514-4473-917E-3DEFCD9A54E3}']
    function MinPrime: Cardinal;  // min. Prime, allways 2
    function MaxPrime: Cardinal;  // max. possible Prime, dependend from Compiler Version
    function MinIndex: Cardinal;  // min. Index, allways 1
    function MaxIndex: Cardinal;  // max. Index, see MaxPrime

    function Count(LowerBound, UpperBound: Cardinal): Cardinal;  // compute Primecount beetwen Bounds
    function IndexOf(Value: Cardinal; LowerBound: Boolean = False): Cardinal;  // give Primeindex of Value

    procedure LoadCache(const FileName: AnsiString);  // load a Prime Cache
    procedure BuildCache(const FileName: AnsiString; Bound: Cardinal);  // create and save a Cache

    function GetPrime(Index: Cardinal): Cardinal;
    property Prime[Index: Cardinal]: Cardinal read GetPrime; default;  // return Prime with Index

    function CacheMaxPrime: Cardinal;  // max. cached Prime
    function CacheMaxIndex: Cardinal;  // max. cached Index of max. Prime
                                       // cached min. Values are allways equal to MinPrime, MinIndex
  end;

function Primes: ISmallPrimeSieve;          external 'DECMath.dll' name 'Prime_Primes';
function IsPrime(Value: Cardinal): Boolean; external 'DECMath.dll' name 'Prime_IsPrime';  // fast check if Value is Prime

{$ENDREGION}
{$REGION 'IsPrimeHRUnit (FULL-SOURCE)'}

function HRIsPrime(N: Cardinal): Boolean;   external 'DECMath.dll' name 'IsPrimeHRUnit_IsPrime_Ca';

{$ENDREGION}
{$REGION 'IDPrimes : NInts, ASN1, CRC, DECHash, DECUtil, SysUtils, Classes'}
{
  Description:
    ID based Prime system to generate verifyable secure primes
    Such ID Primes have some important features
    - can't be forged
    - verifyable
    - use a known and common computation way
    - storage is incomparable shorter as the described prime self
    - primes are secure random choosen
    - there exists no known way to produce or forge primes to well
      choosen weak primes
    - fast, incomparable faster as the recreation of the prime
    - the ID Prime datastructure is self checked
    - supports binary and plain readable formats
    - use many different secure hash function, eg portable
    - binary format use Big Endian Notation
    - binary dataformat use most only 8 - 16 Bytes, most 13/14 bytes
      in comparsion a 1024 Bit prime requiere 131 Bytes storage.

  how works:
    NMake() create an random SeedBitSize great seed value. This seed is expanded
    with an indexed repeated Hash computation (MGF) and produce a concatenated Value P of
    BitSize Bits. The indexed hash use internal an Index called HashIndex to ensure
    that with another choosen HashIndex we get absolutly other outputs. Important
    is here the fact that in contrast to the outer seed we change with this HashIndex
    the internal working state of the indexed Hash algorithm.
    Now we can use P as BitSize seed to compute the prime. The Prime is congruent
    to Residue mod Modulus, eg P == R mod M. There exists two exceptions:
    1.) R=+1 and M=1 will produce a Safe Prime so called Sophie Germain Prime into P
        P = 2Q +1 where Q and P is prime.
    2.) R=-1 and M=1 will produce a Strong Lucas Prime a safe prime in modular lucas sequences
        P = 2Q -1 where Q and P is prime
    After creation of the prime, the maincomputation, we store the skipped Residuecount
    eg. ID.Count. This give us on recreation a direct way to compute P based on S directly.
    Basicaly ID.Count * M + R is the Offset that we must add to the seed to get P.
    Now we compute a Hash C over the Prime as secure checksum. This hash is to long
    and need to many space if we want it to store. To avoid this we compute a CRC 16Bit ZModem
    over C and store it into ID.CRC. This CRC requiere now only 2 Bytes and provide us
    with a range of 65535 possible Databits.

    About ID-Prime Stringformats:
    The format looks like this
      342:3:4:SHA1:1:EBBFBBD3:745E:8
    eg.
      Prime Bitsize : Residue : Modulus : Hash Algo : HashIndex : Seed : CRC : Count
        decimal     :   dec   :   dec   :  alpha    :    dec    : hex  : hex : dec
         < 65535    :   > 0   :  >Res.  :           :   < 65535 :  >0  :16Bit: >= 0

    and are a
      342 Bit prime congruent to P == 3 mod 4 created with SHA1 and HashIndex 1
      based on a 32 Bit Seed $EBBFBBD3 and have a hashed CRC 16 Checksum of $745E
      based from the hashed seed we have < 3 + 4 * 8 to add the get the prime.

    If You want to use the binary Dataformat then ensure that SeedBitSize is
    SeedBitSize = SeedBytes * 8 -1. This save always one Byte in the Datasize
    and reduce only 1 bit the seed.

    in binary:
      1024:1:2:MD4:1:79758AA3:02D4:10

      $04 $00 $21 $04 $79 $75 $8A $A3 $04 $01 $02 $D4 $0A

      $0400            = 1024
      $21              = 1 mod 2
      $04 $79758AA3    = ASN1 Length encoded tag of 4 bytes seed in big endian
      $04              = predefined ID for Hash MD4, if custom an ASN1 String are here
      $01              = ASN1 Length encoded tag for HashIndex
      $02D4            = 16 Bit CRC
      $0A              = ASN1 Length encoded tag for Count
}

type
  IIDPrime = interface
    ['{126BE110-061D-4067-9E0A-E2A490AF5CEA}']
    function BitSize: Word;
    function Residue: IInteger;
    function Modulus: IInteger;
    function Seed: IInteger;
    function HashClass: TDECHashClass;
    function HashIndex: Word;
    function CRC: Word;
    function Count: Cardinal;
  end;

// compute the verifyable Prime dependend of ID into P,
// if RaiseError = False then Result contains Errorcode or ZERO for success
function  NSet(var P: IInteger; const ID: IIDPrime; CheckPrimality: Boolean = False;
            RaiseError: Boolean = True): Integer; overload;                                         external 'DECMath.dll' name 'IDPrimes_NSet_IIDPBoBo';
// same as above, but as function and raise always an error on bad parameters
function  NInt(const ID: IIDPrime; CheckPrimality: Boolean = False): IInteger; overload;            external 'DECMath.dll' name 'IDPrimes_NInt_DPBo';
// setup ID to ID-Prime formated string
function  NSet(var ID: IIDPrime; const S: AnsiString;
            RaiseError: Boolean = False): Integer; overload;                                        external 'DECMath.dll' name 'IDPrimes_NSet_DPStBo';
// setuo ID, same as above but as fucntion and raise always an error on bad parameters
function  NIDPrime(const ID: AnsiString): IIDPrime; overload;                                       external 'DECMath.dll' name 'IDPrimes_NIDPrime_St';
// converts ID into an ID-Prime formatted string
function  NStr(const ID: IIDPrime): RetString; overload;                                            external 'DECMath.dll' name 'IDPrimes_NStr_DP';
// save ID into stream
procedure NSave(const ID: IIDPrime; Stream: TStream); overload;                                     external 'DECMath.dll' name 'IDPrimes_NSave_DPSt';
// load ID from stream
function  NLoad(var ID: IIDPrime; Stream: TStream; RaiseError: Boolean = False): Integer; overload; external 'DECMath.dll' name 'IDPrimes_NLoad_DPStBo';
// load a ID Prime from Stream
function  NIDPrime(Stream: TStream): IIDPrime; overload;                                            external 'DECMath.dll' name 'IDPrimes_NIDPrime_St';
// created an ID Prime and correspondending Prime as result
function  NMake(var ID: IIDPrime; BitSize: Word; SeedBitSize: Word = 31;
            const Residue: IInteger = nil; const Modulus: IInteger = nil;
            HashIndex: Word = 1; HashClass: TDECHashClass = nil;
            Callback: TIIntegerPrimeCallback = nil): IInteger; overload;                            external 'DECMath.dll' name 'IDPrimes_NMake_XXX';

const
  // Identities for some Hash Algorithms, intern used in binary Dataformat
  // placed here to support custom Identities
  IDPrimeHash: array[0..$11] of Cardinal =
    (        0, $FED1656F,         0,         0, $90762D4A, $E7711DDC,         0,
     $09C97F2E, $637E3218, $A3767AB7, $04962372, $AC6A2448, $C6DD697E, $AF4B149D,
     $A79AD63A, $06D521D1, $CFD609CC, $F625D933);
  // $00 == custom use Identity
  // $01 == SHA1-160
  // $02 == SHA1-256
  // $03 == MD2
  // $04 == MD4
  // $05 == MD5-128
  // $06 == MD5-256
  // $07 == RipeMD-128
  // $08 == RipeMD-160
  // $09 == RipeMD-256
  // $0A == RipeMD-320
  // $0B == Haval-128
  // $0C == Haval-160
  // $0D == Haval-192
  // $0E == Haval-224
  // $0F == Haval-256
  // $10 == Tiger
  // $11 == Square

{$ENDREGION}
{$REGION 'NCombi : NMath, NInts, Prime, SysUtils, -Math- (FULL-SOURCE)'}

procedure NFactorial_Moessner        (var A: IInteger; N: Cardinal); external 'DECMath.dll' name 'NCombi_NFactorial_Moessner_IICa';
procedure NFactorial_Naive           (var A: IInteger; N: Cardinal); external 'DECMath.dll' name 'NCombi_NFactorial_Naive_IICa';
procedure NFactorial_Recursive       (var A: IInteger; N: Cardinal); external 'DECMath.dll' name 'NCombi_NFactorial_Recursive_IICa';
procedure NFactorial_DivideAndConquer(var A: IInteger; N: Cardinal); external 'DECMath.dll' name 'NCombi_NFactorial_DivideAndConquer_IICa';
procedure NFactorial_Binomial        (var A: IInteger; N: Cardinal); external 'DECMath.dll' name 'NCombi_NFactorial_Binomial_IICa';
procedure NFactorial_Jason_GMP       (var A: IInteger; N: Cardinal); external 'DECMath.dll' name 'NCombi_NFactorial_Jason_GMP_IICa';

procedure NFactorial   (var A: IInteger; N:    Cardinal; const M: IInteger = nil); {overload;}           external 'DECMath.dll' name 'NCombi_NFactorial_IICaII';
procedure NComporial   (var A: IInteger; N:    Cardinal; const M: IInteger = nil); {overload;}           external 'DECMath.dll' name 'NCombi_NComporial_IICaII';
procedure NBinomial    (var A: IInteger; N, K: Cardinal; const M: IInteger = nil); {overload;}           external 'DECMath.dll' name 'NCombi_NBinomial_IICaCaII';
procedure NProduct     (var A: IInteger; N, K: Cardinal; const M: IInteger = nil); {overload;}           external 'DECMath.dll' name 'NCombi_NProduct_IICaCaII';
procedure NPermutation (var A: IInteger; N, K: Cardinal; const M: IInteger = nil); {overload;0           external 'DECMath.dll' name 'NCombi_NPermutation_IICaCaII';
function  NOddFactorial(var A: IInteger; N:    Cardinal; const M: IInteger = nil): Cardinal; {overload;} external 'DECMath.dll' name 'NCombi_NOddFactorial_IICaII';
procedure NPrimorial   (var A: IInteger; K, N: Cardinal; const M: IInteger = nil); {overload;}           external 'DECMath.dll' name 'NCombi_NPrimorial_IICaCaII';

procedure NHalfFactorial(var A: IInteger; N: Cardinal; const M: IInteger = nil); overload; external 'DECMath.dll' name 'NCombi_NHalfFactorial_IICaII';
procedure NHalfComporial(var A: IInteger; N: Cardinal; const M: IInteger = nil); overload; external 'DECMath.dll' name 'NCombi_NHalfComporial_IICaII';
procedure NHalfPrimorial(var A: IInteger; N: Cardinal; const M: IInteger = nil); overload; external 'DECMath.dll' name 'NCombi_NHalfPrimorial_IICaII';
procedure NHalfBinomial (var A: IInteger; N: Cardinal; const M: IInteger = nil); overload; external 'DECMath.dll' name 'NCombi_NHalfBinomial_IICaII';

function  NFactorialTrailingZeros(const N: Int64; Base: Cardinal): Int64; external 'DECMath.dll' name 'NCombi_NFactorialTrailingZeros_I6Ca';

procedure NTestCombi(N: Cardinal = 200); {overload;}                      external 'DECMath.dll' name 'NCombi_NTestCombi_Ca';

// internal most used stuff
type
  TPowerTable = array of record
    B: Cardinal;  // base
    E: Cardinal;  // exponent
  end;

function NPowerTable(var T: TPowerTable; N: Cardinal; L: Cardinal = 0; K: Cardinal = 0): Cardinal; overload;    external 'DECMath.dll' name 'NCombi_NPowerTable_PTCaCaCa';
function NPowerTable(var A: IInteger;    N: Cardinal; L: Cardinal = 0; K: Cardinal = 0;
                                          Shift: Boolean = False; const M: IInteger = nil): Cardinal; overload; external 'DECMath.dll' name 'NCombi_NPowerTable_IICaCaCaBoII';
function NPrd(var A: IInteger; const T: TPowerTable; E: Cardinal; const M: IInteger = nil): Boolean; overload;  external 'DECMath.dll' name 'NCombi_NPrd_IIPTCaII';
function NPrd(var A: IInteger; const T: TPowerTable;              const M: IInteger = nil): Boolean; overload;  external 'DECMath.dll' name 'NCombi_NPrd_IIPTII';

{$ENDREGION}
{$REGION 'NGFPs : NMath, NInts, IDPrimes, Classes'}

type
  // Elliptic Curve over GF(p)
  // Weierstrass form  y^2 = x^3 + ax + b
  // where a and b are integers modulo p and  4a^3 + 27b^2 <> 0 mod p
  IGFpEC = packed record
    P, A, B: IInteger;
  end;

  TECState = (Empty, WrongField, WrongCoefficients, WrongBasePoint, WrongOrder,
              WrongCofactor, FailsMOVCondition, PointHaveWrongOrder, PointNotOnCurve,
              WrongPoint, Valid);

  IGFpECC = packed record
    EC: IGFpEC;     // field and curve
    ID: IIDPrime;   // verifiable ID of EC.P
    G:  I2Point;    // basepoint
    R:  IInteger;   // order, prime  {called n in EC-DSA}
    K:  IInteger;   // cofactor      {called h in EC-DSA}
  end;              // FR = field representation
                    // d  = private key IInteger
                    // Q  = public key I2point

  // per convention the GF(p)EC point at infinity O = identity is NEmpty(G) = True = (G.X = nil and G.Y = nil)
  // all other points are finite points
  IGFpMulPrecomputation = interface
    ['{126BE0A0-061D-4067-9E0A-E2A490AF5CEA}']
    procedure Precompute           (const B: I2Point;                    const E: IGFpEC; CMaxBitSize: Integer);
    function  Mul  (var A: I2Point; const B: I2Point; const C: IInteger; const E: IGFpEC; var Res: Boolean): Boolean;
    function  Mul2k(var A: I2Point; const B: I2Point;       K: Cardinal; const E: IGFpEC; var Res: Boolean): Boolean;
    procedure Save(Stream: TStream);
    procedure Load(Stream: TStream);
  end;

procedure NECRaise(State: TECState); {overload;}                                                                                                  external 'DECMath.dll' name 'NGFPs_NECRaise_ES';
function  NECCheck(const E: IGFpEC;  RaiseException: Boolean = False): TECState; overload;                                                        external 'DECMath.dll' name 'NGFPs_NECCheck_FCBo';
function  NECCheck(const E: IGFpECC; RaiseException: Boolean = False): TECState; overload;                                                        external 'DECMath.dll' name 'NGFPs_NECCheck_GCBo';
function  NECCheck(const P: array of I2Point; const E: IGFpEC;  RaiseException: Boolean = False): TECState; overload;                             external 'DECMath.dll' name 'NGFPs_NECCheck_APFCBo';
function  NECCheck(const P: array of I2Point; const E: IGFpECC; RaiseException: Boolean = False): TECState; overload;                             external 'DECMath.dll' name 'NGFPs_NECCheck_APGCBo';
function  NECCheckMOVCondition               (const E: IGFpECC; RaiseException: Boolean = False): TECState; {overload;}                           external 'DECMath.dll' name 'NGFPs_NECCheckMOVCondition_FCBo';
procedure NSwp  (var A, B: IGFpEC); overload;                                                                                                     external 'DECMath.dll' name 'NGFPs_NSwp_FCFC';
function  NSet  (var A: I2Point;  const X: IInteger; YIsOdd: Boolean;  const E: IGFpEC): TECState; overload;                                      external 'DECMath.dll' name 'NGFPs_NSet_2PIIBoFC';
procedure NSet  (var A: IGFpEC;   const B: IGFpEC);  overload;                                                                                    external 'DECMath.dll' name 'NGFPs_NSet_FCFC';
procedure NSet  (var A: IInteger; const B: I2Point); overload;                                                                                    external 'DECMath.dll' name 'NGFPs_NSet_II2P';
function  NSet  (var A: I2Point;  const B: IInteger;                   const E: IGFpEC): TECState; overload;                                      external 'DECMath.dll' name 'NGFPs_NSet_2PIIFC';
function  NAdd  (var A: I2Point;  const B: I2Point;                    const E: IGFpEC): Boolean; overload;                                       external 'DECMath.dll' name 'NGFPs_NAdd_2P2PFC';
function  NSub  (var A: I2Point;  const B: I2Point;                    const E: IGFpEC): Boolean; overload;                                       external 'DECMath.dll' name 'NGFPs_NSub_2P2PFC';
function  NMul  (var A: I2Point;  const B: IInteger;                   const E: IGFpEC; const P: IGFpMulPrecomputation = nil): Boolean; overload; external 'DECMath.dll' name 'NGFPs_NMul_2PIIFCMP';
function  NMul  (var A: I2Point;  const B: I2Point; const C: IInteger; const E: IGFpEC; const P: IGFpMulPrecomputation = nil): Boolean; overload; external 'DECMath.dll' name 'NGFPs_NMul_2P2PIIFCMP';
function  NMul2k(var A: I2Point;                   K: Cardinal;        const E: IGFpEC; const P: IGFpMulPrecomputation = nil): Boolean; overload; external 'DECMath.dll' name 'NGFPs_NMul2k_2PCaFCMP';
function  NMul2k(var A: I2Point; const B: I2Point; K: Cardinal;        const E: IGFpEC; const P: IGFpMulPrecomputation = nil): Boolean; overload; external 'DECMath.dll' name 'NGFPs_NMul2k_2P2PCaFCMP';
function  NInv  (var A: I2Point; const E: IGFpEC): Boolean; overload;                                                                             external 'DECMath.dll' name 'NGFPs_NInv_2PFC';
procedure NRnd  (var A: I2Point; const E: IGFpEC); overload;                                                                                      external 'DECMath.dll' name 'NGFPs_NRnd_2PFC';
procedure NRnd  (                  var E: IGFpEC; FieldBitSize: Integer = 168); overload;                                                         external 'DECMath.dll' name 'NGFPs_NRnd_FCIn';
function  NEmpty(const A: I2Point): Boolean; overload;                                                                                            external 'DECMath.dll' name 'NGFPs_NEmpty_2P';
function  NEmpty(const A: I3Point): Boolean; overload;                                                                                            external 'DECMath.dll' name 'NGFPs_NEmpty_3P';
// modified Brickell's precomputation for mul
procedure NSet   (var P: IGFpMulPrecomputation; const B: I2Point; const E: IGFpEC; CMaxBitSize: Integer); overload;                               external 'DECMath.dll' name 'NGFPs_NSet_MP2PFCIn';
procedure NSave(const P: IGFpMulPrecomputation; Stream: TStream); overload;                                                                       external 'DECMath.dll' name 'NGFPs_NSave_MPSt';
procedure NLoad  (var P: IGFpMulPrecomputation; Stream: TStream); overload;                                                                       external 'DECMath.dll' name 'NGFPs_NLoad_MPSt';

function NMul_MontPB  (var A: I2Point; const B: I2Point; const C: IInteger; const E: IGFpEC): Boolean;                                            external 'DECMath.dll' name 'NGFPs_NMul_MontPB_2P2PIIFC';
function NMul_Affine  (var A: I2Point; const B: I2Point;       C: IInteger; const E: IGFpEC): Boolean;                                            external 'DECMath.dll' name 'NGFPs_NMul_Affine_2P2PIIFC';
function NMul_Proj    (var A: I2Point; const B: I2Point; const C: IInteger; const E: IGFpEC): Boolean;                                            external 'DECMath.dll' name 'NGFPs_NMul_Proj_2P2PIIFC';
function NMul2k_Normal(var A: I2Point; const B: I2Point;       K: Cardinal; const E: IGFpEC): Boolean; {overload;}                                external 'DECMath.dll' name 'NGFPs_NMul2k_Normal_2P2PCaFC';
function NMul2k_Mont  (var A: I2Point; const B: I2Point;       K: Cardinal; const E: IGFpEC): Boolean;                                            external 'DECMath.dll' name 'NGFPs_NMul2k_Mont_2P2PCaFC';

{$ENDREGION}
{$REGION 'NGFPBld : NMath, NInts, NPolys, Prime, IDPrimes, NGFPs, DECHash'}

type
  IGFpECPolyTable = interface
    ['{126BE100-061D-4067-9E0A-E2A490AF5CEA}']
    function Get(var A: IPoly; Discriminant: Cardinal): Integer;
    function Coefficients(var A, B: IInteger; Discriminant: Cardinal): Integer;
  end;

  TGFpECGetPoly = function: IGFpECPolyTable;

  TECBuildFlag = (Normal, Coefficient_AM3);

const // result codes for IGFpECPolyTable .Get/.Coefficients
  CM_Found       =  0;
  CM_NotFound    = -1;
  CM_OutOfBounds = -2;

function NECBuild(var E: IGFpECC; FieldBitSize: Integer = 168; CofactorBitSize: Integer = 1;
           Flag: TECBuildFlag = Normal; SeedBitSize: Word = 31; HashClass: TDECHashClass = nil;
           MinCM: Cardinal = 0; MaxCM: Cardinal = MaxInt): Cardinal; external 'DECMath.dll' name 'NECBuild_XXX';
function NECRegisterPolyTable  (GetPoly: TGFpECGetPoly): Boolean;    external 'DECMath.dll' name 'NGFPBld_NECRegisterPolyTable_GP';
function NECUnregisterPolyTable(GetPoly: TGFpECGetPoly): Boolean;    external 'DECMath.dll' name 'NGFPBld_NECUnregisterPolyTable_GP';
function NECPolyTable: IGFpECPolyTable;                              external 'DECMath.dll' name 'NGFPBld_NECPolyTable';

{$ENDREGION}
{$REGION 'NGFPTab : NInts, NPolys, NGFPBld, NGFPs, ASN1, CRC, SysUtils, Classes, Windows'}

//var
//  SupportsPolyTableFiles: Boolean = False;
//  PolyTableFilePath: AnsiString = '';

// if TRUE scans for *.TAB files in APP path and subdirs.

procedure SetSupportsPolyTableFiles(Value: Boolean = False);  external 'DECMath.dll' name 'NGFPTab_SetSupportsPolyTableFiles';
procedure SetPolyTableFilePath(const Value: AnsiString = ''); external 'DECMath.dll' name 'NGFPTab_SetPolyTableFilePath';

// P1003.res    250 Class-Polynoms from Discriminant 0 upto  1003,  8.912 Bytes
// P4984.res    503 Class-Polynoms from Discriminant 0 upto  4984, 22.681 Bytes
// P8248.res    316 Class-Polynoms from Discriminant 0 upto  8248, 11.403 Bytes
// P9172.res    380 Class-Polynoms from Discriminant 0 upto  9182, 14.556 Bytes
// P9988.res   1000 Class-Polynoms from Discriminant 0 upto  9988, 69.346 Bytes
// P14008.res   507 Class-Polynoms from Discriminant 0 upto 14008, 32.768 Bytes

{$ENDREGION}

implementation

{$REGION 'Hooks'}

type
  THookRefs = packed record
    {$WARN SYMBOL_DEPRECATED OFF}
    MemoryManager: TMemoryManager;
    {$WARN SYMBOL_DEPRECATED ON}
    NewAnsiString: procedure(var Dest: AnsiString; Source: PAnsiChar; CharCount: Integer; CodePage: Word);
  end;

procedure MyLStrFromPCharLen(var Dest: AnsiString; Source: PAnsiChar; CharCount: Integer; CodePage: Word);
begin
  SetString(Dest, Source, CharCount);  // the compiler magic goes to System._LStrFromPCharLen(Dest, Source, CharCount, CP_ACP);
end;

procedure DECMath_InitMemoryStringHooks(const Refs: THookRefs); external 'DECMath.dll' name 'DECMath_InitMemoryStringHooks';
procedure DECMath_RemoveMemoryStringHooks;                      external 'DECMath.dll' name 'DECMath_RemoveMemoryStringHooks';

{$ENDREGION}

initialization
  var HookRefs: THookRefs;
  {$WARN SYMBOL_DEPRECATED OFF}
  GetMemoryManager(HookRefs.MemoryManager);
  {$WARN SYMBOL_DEPRECATED ON}
  HookRefs.NewAnsiString := @MyLStrFromPCharLen;
  DECMath_InitMemoryStringHooks(HookRefs);

finalization
  DECMath_RemoveMemoryStringHooks;

end.

