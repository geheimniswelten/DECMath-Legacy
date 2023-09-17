library DECMath;

uses
  Windows, Messages, SysUtils, Variants, Classes, TypInfo,
  ASN1, Console, ConsoleForm, CPU, CRC,
  DECCipher, DECData, DECFmt, DECHash, DECRandom, DECUtil,
  IDPrimes, IsPrimeHRUnit, LHSZ,
  NCombi, NGFPBld, NGFPs, NGFPTab, NIntM, NInts, NInt_1,
  NMath, NPolys, NRats, Prime;

{$R *.res}
{$I VER.INC}

type
  RetString = AnsiString;  // see DECMath_InitMemoryStringHooks

(***** Hooks (Declaration) *****)

type
  THookRefs = packed record
    MemoryManager: TMemoryManager;
    NewAnsiString: procedure(var Dest: {AnsiString}Pointer; Source: PAnsiChar; CharCount: Integer; CodePage: Word);
  end;

var
  OldHookRefs: THookRefs;
  CurHookRefs: THookRefs;

(***** --LHSZ *** SysUtils-- *****)
(***** ASN1 *** SysUtils, Classes *****)
(***** CRC *****)
(***** CPU *** SysUtils, Windows *****)
(***** DECData *****)
(***** DECUtil *** CRC, SysUtils, Classes, Windows *****)
(***** DECHash *** DECData, DECUtil, DECFmt, SysUtils, Classes *****)
(***** --DECRandom *** DECUtil, DECHash, DECFmt, SysUtils-- *****)
(***** DECFmt *** CRC, DECUtil, SysUtils, Classes, Windows *****)
(***** --DECCipher *** DECData, DECUtil, DECFmt, SysUtils, Classes, TypInfo-- *****)
(***** --Console *** SysUtils, Classes, Windows, Messages, Graphics, Controls, StdCtrls, RichEdit, Forms-- *****)
(***** --ConsoleForm *** NMath, Console, SysUtils, Classes, Windows, Messages, Math, Graphics, Controls, StdCtrls, ComCtrls, CommCtrl, ExtCtrls, Forms, Dialogs, Menus, ImgList, ToolWin, IniFiles-- *****)

(***** NMath *** SysUtils, Windows *****)

exports
  NMath.IsEqualGUID  name 'NMath_IsEqualGUID_GuGu',
  NMath.NPool        name 'NMath_NPool_Ca',
  NMath.NCalcCheck   name 'NMath_NCalcCheck_',
  NMath.NUnique      name 'NMath_NUnique_Va',
  NMath.NAutoRelease name 'NMath_NAutoRelease_II';

(***** NInts *** NMath, Prime, ASN1, CPU, CRC, DECFmt, DECHash, DECUtil, TypInfo, SysUtils, Classes, Windows, Variants *****)

// overloaded functions with typeless parameters cannot be exported directly
procedure _ABSB_NSet(var A: IInteger; const B; Size: Integer; Bits: Integer);
begin
  NInts.NSet(A, B, Size, Bits);
end;

function _ASB_NInt(const A; Size: Integer; Bits: Integer): IInteger;
begin
  Result := NInts.NInt(A, Size, Bits);
end;

function _IIBa_NStr(const A: IInteger; Base: TBase): RetString;
var
  Temp: AnsiString;
begin
  Temp := NInts.NStr(A, Base);
  CurHookRefs.NewAnsiString(Pointer(Result), Pointer(Temp), Length(Temp), CP_ACP);
end;

function _IISF_NStr(const A: IInteger; const Format: TStrFormat): RetString;
var
  Temp: AnsiString;
begin
  Temp := NInts.NStr(A, Format);
  CurHookRefs.NewAnsiString(Pointer(Result), Pointer(Temp), Length(Temp), CP_ACP);
end;

function _GetNStrFormat: TStrFormat;
begin
  Result := NInts.NStrFormat;
end;

procedure _SetNStrFormat(const F: TStrFormat);
begin
  NInts.NStrFormat := F;
end;

exports
  NInts.NSet(var A: IInteger; B: Integer)                                                               name 'NInts_NSet_IIIn',
  NInts.NSet(var A: IInteger; B: Int64)                                                                 name 'NInts_NSet_III6',
  NInts.NSet(var A: IInteger; B: Extended)                                                              name 'NInts_NSet_IIEx',
  NInts.NSet(var A: IInteger; const B: IInteger; Abs: Boolean)                                          name 'NInts_NSet_IIIIBo',
  NInts.NSet(var A: IInteger; const B: AnsiString; const Format: TStrFormat)                            name 'NInts_NSet_IIStSF',
  NInts.NSet(var A: IInteger; const B: AnsiString; Base: TBase)                                         name 'NInts_NSet_IIStBa',
  _ABSB_NSet{var A: IInteger; const B; Size: Integer; Bits: Integer}                                    name 'NInts_NSet_IIBInIn',
  NInts.NSet(var A: IInteger; Stream: TStream; Format: TIntegerFormat)                                  name 'NInts_NSet_IIStIF',
  NInts.NSet(var A: IInteger; const B: TVarRec)                                                         name 'NInts_NSet_IIVR',
  NInts.NSet(var A: IIntegerArray; const B: array of const)                                             name 'NInts_NSet_IAAC',
  NInts.NSet(var A: IIntegerArray; const B: IIntegerArray)                                              name 'NInts_NSet_IAIA',
  NInts.NRnd(var A: IInteger; Bits: Integer; Sign: Boolean)                                             name 'NInts_NRnd_IIInBo',
  NInts.NInt(A: Integer)                                                                                name 'NInts_NInt_In',
  NInts.NInt(A: Int64)                                                                                  name 'NInts_NInt_I6',
  NInts.NInt(A: Extended)                                                                               name 'NInts_NInt_Ex',
  NInts.NInt(const A: IInteger; Abs: Boolean)                                                           name 'NInts_NInt_IIBo',
   _ASB_NInt{const A; Size: Integer; Bits: Integer}                                                     name 'NInts_NInt_AInIn',
  NInts.NInt(const A: AnsiString; Base: TBase)                                                          name 'NInts_NInt_StBa',
  NInts.NInt(Stream: TStream; Format: TIntegerFormat)                                                   name 'NInts_NInt_StIF',
  NInts.NInt(const A: array of const)                                                                   name 'NInts_NInt_AC',
  NInts.NSgn(const A: IInteger; Extended: Boolean)                                                      name 'NInts_NSgn_IIBo',
  NInts.NSgn(var A: IInteger; Sign: Integer)                                                            name 'NInts_NSgn_IIIn',
  NInts.NOdd(const A: IInteger)                                                                         name 'NInts_NOdd_II',
  NInts.NOdd(var A: IInteger; Odd: Boolean)                                                             name 'NInts_NOdd_IIBo',
  NInts.NNeg(var A: IInteger)                                                                           name 'NInts_NNeg_II',
  NInts.NNeg(var A: IInteger; Negative: Boolean)                                                        name 'NInts_NNeg_IIBo',
  NInts.NAbs(var A: IInteger)                                                                           name 'NInts_NAbs_II',
  NInts.NBit(const A: IInteger; Index: Integer)                                                         name 'NInts_NBit_IIIn',
  NInts.NBit(var A: IInteger; Index: Integer; Value: Boolean)                                           name 'NInts_NBit_IIInBo',
  NInts.NLow(const A: IInteger; Piece: TPiece)                                                          name 'NInts_NLow_IIPi',
  NInts.NHigh(const A: IInteger; Piece: TPiece)                                                         name 'NInts_NHigh_IIPi',
  NInts.NSize(const A: IInteger; Piece: TPiece)                                                         name 'NInts_NSize_IIPi',
  NInts.NCmp(const A, B: IInteger; Abs: Boolean)                                                        name 'NInts_NCmp_IIIIBo',
  NInts.NCmp(const A: IInteger; B: Integer; Abs: Boolean)                                               name 'NInts_NCmp_IIInBo',
  NInts.NCmp(const A, B: IInteger; Bits: Integer; Abs: Boolean)                                         name 'NInts_NCmp_IIIIInBo',
  NInts.NCRC(const A: IInteger; CRC: TCRCType)                                                          name 'NInts_NCRC_IITC',
  NInts.NCRC(const A: IIntegerArray; CRC: TCRCType)                                                     name 'NInts_NCRC_IATC',
  NInts.NParity(const A: IInteger)                                                                      name 'NInts_NParity_II',
  NInts.NWeight(const A: IInteger)                                                                      name 'NInts_NWeight_II',
  NInts.NBitPos(const A: IInteger; Bit: Integer)                                                        name 'NInts_NBitPos_IIIn',
  //NInts.NBitAdd(var A: IInteger; const B: IInteger; Bits: Integer)                                    name 'NInts_NBitAdd_IIIIIn',
  NInts.NSplit(var A: IInteger; const B: IInteger; Bits: Byte)                                          name 'NInts_NSplit_IIIIBy',
  NInts.NSwp(var A, B: IInteger)                                                                        name 'NInts_NSwp_IIII',
  NInts.NSwp(var A: IInteger; Piece: TPiece; Normalize: Boolean)                                        name 'NInts_NSwp_IIPiBo',
  NInts.NSwp(var A: IInteger; const B: IInteger; Piece: TPiece; Normalize: Boolean)                     name 'NInts_NSwp_IIIIPiBo',
  NInts.NCpy(var A: IInteger; Count: Integer; Start: Integer)                                           name 'NInts_NCpy_IIInIn',
  NInts.NCpy(var A: IInteger; const B: IInteger; Count: Integer; Start: Integer)                        name 'NInts_NCpy_IIIIInIn',
  NInts.NShl(var A: IInteger; Shift: Integer)                                                           name 'NInts_NShl_IIIn',
  NInts.NShl(var A: IInteger; const B: IInteger; Shift: Integer)                                        name 'NInts_NShl_IIIIIn',
  NInts.NShr(var A: IInteger; Shift: Integer)                                                           name 'NInts_NShr_IIIn',
  NInts.NShr(var A: IInteger; const B: IInteger; Shift: Integer)                                        name 'NInts_NShr_IIIIIn',
  NInts.NShr(var A: IInteger)                                                                           name 'NInts_NShr_II',
  NInts.NShr(var A: IInteger; const B: IInteger)                                                        name 'NInts_NShr_IIII',
  NInts.NCut(var A: IInteger; Bits: Integer)                                                            name 'NInts_NCut_IIIn',
  NInts.NCut(var A: IInteger; const B: IInteger; Bits: Integer)                                         name 'NInts_NCut_IIIIIn',
  NInts.NCat{var A: IInteger; const B: IIntegerArray; Bits: Integer}                                    name 'NInts_NCat_IIIAIn',
  NInts.NNot(var A: IInteger; Bits: Integer; Sign: Boolean)                                             name 'NInts_NNot_IIInBo',
  NInts.NNot(var A: IInteger; const B: IInteger; Bits: Integer; Sign: Boolean)                          name 'NInts_NNot_IIIIInBo',
  NInts.NXor(var A: IInteger; const B: IInteger; Bits: Integer; Sign: Boolean)                          name 'NInts_NXor_IIIIInBo',
  NInts.NXor(var A: IInteger; const B, C: IInteger; Bits: Integer; Sign: Boolean)                       name 'NInts_NXor_IIIIIIInBo',
  NInts.NAnd(var A: IInteger; const B: IInteger; Bits: Integer; Sign: Boolean)                          name 'NInts_NAnd_IIIIInBo',
  NInts.NAnd(var A: IInteger; const B, C: IInteger; Bits: Integer; Sign: Boolean)                       name 'NInts_NAnd_IIIIIIInBo',
  NInts.NOr (var A: IInteger; const B: IInteger; Bits: Integer; Sign: Boolean)                          name 'NInts_NOr_IIIIInBo',
  NInts.NOr (var A: IInteger; const B, C: IInteger; Bits: Integer; Sign: Boolean)                       name 'NInts_NOr_IIIIIIInBo',
  NInts.NCpl(var A: IInteger; Bits: Integer; Sign: Boolean)                                             name 'NInts_NCpl_IIInBo',
  NInts.NCpl(var A: IInteger; const B: IInteger; Bits: Integer; Sign: Boolean)                          name 'NInts_NCpl_IIIIInBo',
  NInts.NInc(var A: IInteger; B: Cardinal)                                                              name 'NInts_NInc_IICa',
  NInts.NDec(var A: IInteger; B: Cardinal)                                                              name 'NInts_NDec_IICa',
  NInts.NAdd(var A: IInteger; B: Integer)                                                               name 'NInts_NAdd_IIIn',
  NInts.NAdd(var A: IInteger; const B: IInteger)                                                        name 'NInts_NAdd_IIII',
  NInts.NAdd(var A: IInteger; const B, C: IInteger)                                                     name 'NInts_NAdd_IIIIII',
  NInts.NSub(var A: IInteger; B: Integer)                                                               name 'NInts_NSub_IIIn',
  NInts.NSub(var A: IInteger; const B: IInteger)                                                        name 'NInts_NSub_IIII',
  NInts.NSub(var A: IInteger; const B, C: IInteger)                                                     name 'NInts_NSub_IIIIII',
  NInts.NMul(var A: IInteger; B: Integer)                                                               name 'NInts_NMul_IIIn',
  NInts.NMul(var A: IInteger; B: Int64)                                                                 name 'NInts_NMul_III6',
  NInts.NMul(var A: IInteger; const B: IInteger; C: Int64)                                              name 'NInts_NMul_IIIII6',
  NInts.NMul(var A: IInteger; const B: IInteger; C: Integer)                                            name 'NInts_NMul_IIIIIn',
  NInts.NMul(var A: IInteger; const B: IInteger)                                                        name 'NInts_NMul_IIII',
  NInts.NMul(var A: IInteger; const B, C: IInteger)                                                     name 'NInts_NMul_IIIIII',
  NInts.NSqr(var A: IInteger)                                                                           name 'NInts_NSqr_II',
  NInts.NSqr(var A: IInteger; const B: IInteger)                                                        name 'NInts_NSqr_IIII',
  NInts.NMod(const A: IInteger; M: Integer)                                                             name 'NInts_NMod_IIIn',
  NInts.NModU(const A: IInteger; M: Cardinal)                                                           name 'NInts_NModU_IICa',
  NInts.NMod(var A: IInteger; const M: IInteger)                                                        name 'NInts_NMod_IIII',
  NInts.NMod(var A: IInteger; const B, M: IInteger)                                                     name 'NInts_NMod_IIIIII',
  NInts.NRem(const A: IInteger; B: Integer)                                                             name 'NInts_NRem_IIIn',
  NInts.NRem(var A: IInteger; const B: IInteger)                                                        name 'NInts_NRem_IIII',
  NInts.NRem(var A: IInteger; const B, C: IInteger)                                                     name 'NInts_NRem_IIIIII',
  NInts.NDiv(var Q: IInteger; A: Integer)                                                               name 'NInts_NDiv_IIIn',
  NInts.NDivU(var Q: IInteger; A: Cardinal)                                                             name 'NInts_NDivU_IICa',
  NInts.NDiv(var Q: IInteger; const A: IInteger)                                                        name 'NInts_NDiv_IIII',
  NInts.NDiv(var Q: IInteger; const A: IInteger; B: Integer)                                            name 'NInts_NDiv_IIIIIn',
  NInts.NDivU(var Q: IInteger; const A: IInteger; B: Cardinal)                                          name 'NInts_NDivU_IIIICa',
  NInts.NDiv(var Q: IInteger; const A, B: IInteger)                                                     name 'NInts_NDiv_IIIIII',
  NInts.NDivRem(var Q, R: IInteger; const A, B: IInteger)                                               name 'NInts_NDivRem_IIIIIIII',
  NInts.NDivMod(var Q, R: IInteger; const A, B: IInteger)                                               name 'NInts_NDivMod_IIIIIIII',
  NInts.NAddMod(var A: IInteger; const B, C, M: IInteger)                                               name 'NInts_NAddMod_IIIIIIII',
  NInts.NAddMod(var A: IInteger; const B, M: IInteger)                                                  name 'NInts_NAddMod_IIIIII',
  NInts.NSubMod(var A: IInteger; const B, C, M: IInteger)                                               name 'NInts_NSubMod_IIIIIIII',
  NInts.NSubMod(var A: IInteger; const B, M: IInteger)                                                  name 'NInts_NSubMod_IIIIII',
  NInts.NMulMod(var A: IInteger; const B, C, M: IInteger)                                               name 'NInts_NMulMod_IIIIIIII',
  NInts.NMulMod(var A: IInteger; const B, M: IInteger)                                                  name 'NInts_NMulMod_IIIIII',
  NInts.NMulMod2k(var A: IInteger; const B, C: IInteger; K: Cardinal)                                   name 'NInts_NMulMod2k_IIIIIICa',
  NInts.NMulMod2k(var A: IInteger; const B: IInteger; K: Cardinal)                                      name 'NInts_NMulMod2k_IIIICa',
  NInts.NSqrMod(var A: IInteger; const B, M: IInteger)                                                  name 'NInts_NSqrMod_IIIIII',
  NInts.NSqrMod(var A: IInteger; const M: IInteger)                                                     name 'NInts_NSqrMod_IIII',
  NInts.NSqrMod2k(var A: IInteger; const B: IInteger; K: Cardinal)                                      name 'NInts_NSqrMod2k_IIIICa',
  NInts.NSqrMod2k(var A: IInteger; K: Cardinal)                                                         name 'NInts_NSqrMod2k_IICa',
  NInts.NInvMod(var A: IInteger; const M: IInteger)                                                     name 'NInts_NInvMod_IIII',
  NInts.NInvMod(var A: IInteger; const B, M: IInteger)                                                  name 'NInts_NInvMod_IIIIII',
  NInts.NInvMod(var A: IIntegerArray; const B: IIntegerArray; const M: IInteger; Inv2k: Cardinal)       name 'NInts_NInvMod_IAIAIICa',
  NInts.NInvMod(var A: IIntegerArray; const M: IInteger; Inv2k: Cardinal)                               name 'NInts_NInvMod_IAIICa',
  NInts.NInvMod2k(var A: IInteger; K: Cardinal)                                                         name 'NInts_NInvMod2k_IICa',
  NInts.NInvMod2k(var A: IInteger; const B: IInteger; K: Cardinal)                                      name 'NInts_NInvMod2k_IIIICa',
  NInts.NPowMod(var A: IInteger; const E, M: IInteger; const P: IPowModPrecomputation)                  name 'NInts_NPowMod_IIIIIIMP',
  NInts.NPowMod(var A: IInteger; const B, E, M: IInteger; const P: IPowModPrecomputation)               name 'NInts_NPowMod_IIIIIIIIMP',
  NInts.NPowMod(var A: IInteger; const B, E: IIntegerArray; const M: IInteger)                          name 'NInts_NPowMod_IIIAIAII',
  NInts.NPowMod2k(var A: IInteger; const B, E: IInteger; K: Cardinal; const P: IPowModPrecomputation)   name 'NInts_NPowMod2k_IIIIIICaMP',
  NInts.NPowMod2k(var A: IInteger; const E: IInteger; K: Cardinal; const P: IPowModPrecomputation)      name 'NInts_NPowMod2k_IIIICaMP',
  NInts.NPow(var A: IInteger; E: Integer)                                                               name 'NInts_NPow_IIIn',
  NInts.NPow(var A: IInteger; B, E: Integer)                                                            name 'NInts_NPow_IIInIn',
  NInts.NPow(var A: IInteger; const B: IInteger; E: Integer)                                            name 'NInts_NPow_IIIIIn',
  NInts.NGCD1(const A: IIntegerArray)                                                                   name 'NInts_NGCD1_IA',
  NInts.NGCD1(const A, B: IInteger)                                                                     name 'NInts_NGCD1_IIII',
  NInts.NGCD(A, B: Integer)                                                                             name 'NInts_NGCD_InIn',
  NInts.NGCD(var D: IInteger; const A, B: IInteger)                                                     name 'NInts_NGCD_IIIIII',
  NInts.NGCD(var D: IInteger; const A: IIntegerArray)                                                   name 'NInts_NGCD_IIIA',
  NInts.NGCD(var D, U, V: IInteger; const A, B: IInteger)                                               name 'NInts_NGCD_IIIIIIIIII',
  NInts.NLCM(var L: IInteger; const A, B: IInteger)                                                     name 'NInts_NLCM_IIIIII',
  NInts.NCRT(var A: IInteger; const R, M: IIntegerArray)                                                name 'NInts_NCRT_IIIAIA',
  NInts.NCRT(var A: IInteger; const R, M, U: IIntegerArray)                                             name 'NInts_NCRT_IIIAIAIA',
  NInts.NCRT(var U: IIntegerArray; const M: IIntegerArray)                                              name 'NInts_NCRT_IAIA',
  NInts.NSqrt(var A: IInteger; const B: IInteger)                                                       name 'NInts_NSqrt_IIII',
  NInts.NSqrt(var A: IInteger)                                                                          name 'NInts_NSqrt_II',
  NInts.NSqrt(var A, R: IInteger; const B: IInteger)                                                    name 'NInts_NSqrt_IIIIII',
  NInts.NSqrtMod2k(var A: IInteger; K: Cardinal)                                                        name 'NInts_NSqrtMod2k_IICa',
  NInts.NSqrtMod2k(var A: IInteger; const B: IInteger; K: Cardinal)                                     name 'NInts_NSqrtMod2k_IIIICa',
  NInts.NSqrtMod(var A: IInteger; const P: IInteger; Check: Boolean)                                    name 'NInts_NSqrtMod_IIIIBo',
  NInts.NRoot(var A, R: IInteger; const B: IInteger; E: Integer)                                        name 'NInts_NRoot_IIIIIIIn',
  NInts.NRoot(var A: IInteger; E: Integer)                                                              name 'NInts_NRoot_IIIn',
  NInts.NRoot(var A: IInteger; const B: IInteger; E: Integer)                                           name 'NInts_NRoot_IIIIIn',
  NInts.NRootMod2k(var A: IInteger; const E: IInteger; K: Cardinal)                                     name 'NInts_NRootMod2k_IIIICa',
  NInts.NRootMod2k(var A: IInteger; const B, E: IInteger; K: Cardinal)                                  name 'NInts_NRootMod2k_IIIIIICa',
  NInts.NIsPerfectSqr(const A: IInteger; FullTest: Boolean)                                             name 'NInts_NIsPerfectSqr_IIBo',
  NInts.NIsPerfectSqr(const N: Int64)                                                                   name 'NInts_NIsPerfectSqr_I6',
  NInts.NIsPerfectPower(var B: IInteger; const N: IInteger; Bound: Cardinal)                            name 'NInts_NIsPerfectPower_IIIICa',
  NInts.NIsPerfectPower(const N: IInteger; Bound: Cardinal)                                             name 'NInts_NIsPerfectPower_IICa',
  NInts.NIsPower(const N: IInteger; B, E: Integer)                                                      name 'NInts_NIsPower_IIInIn',
  NInts.NIsPower(const N, B: IInteger; E: Integer)                                                      name 'NInts_NIsPower_IIIIIn',
  NInts.NIsPower(const N, B, E: IInteger)                                                               name 'NInts_NIsPower_IIIIII',
  NInts.NIsPowerOf2(const A: IInteger)                                                                  name 'NInts_NIsPowerOf2_II',
  NInts.NIsDivisible(const A: IInteger; B: Cardinal)                                                    name 'NInts_NIsDivisible_IICa',
  NInts.NTrialDivision(const A: IInteger; Bound: Cardinal)                                              name 'NInts_NTrialDivision_IICa',
  NInts.NSmallFactor(const A: IInteger; Bound: Cardinal)                                                name 'NInts_NSmallFactor_IICa',
  NInts.NSPP{const N: IInteger; const Bases: array of Integer}                                          name 'NInts_NSPP_IIAI',
  NInts.NIsProbablePrime(const A: IInteger)                                                             name 'NInts_NIsProbablePrime_II',
  NInts.NIsProbablePrime(const A: IInteger; const Bases: array of Integer)                              name 'NInts_NIsProbablePrime_IIAI',
  NInts.NMakePrime(var P: IInteger; const Bases: array of Integer)                                      name 'NInts_NMakePrime_IIAI',
  NInts.NMakePrime(var P: IInteger; const Bases: array of Integer; Residue, Modulus: Integer; Callback: TIIntegerPrimeCallback)        name 'NInts_NMakePrime_IIAIInInPC',
  NInts.NMakePrime(var P: IInteger; const Bases: array of Integer; const Residue, Modulus: IInteger; Callback: TIIntegerPrimeCallback) name 'NInts_NMakePrime_IIAIIIIIPC',
  NInts.NLimLeePrime(var P: IInteger; var F: IIntegerArray; PBitSize: Integer; QBitSize: Integer)       name 'NInts_NLimLeePrime_IIIAInIn',
  NInts.NLimLeePrime(var P, Q: IInteger; PBitSize: Integer; QBitSize: Integer)                          name 'NInts_NLimLeePrime_IIIIInIn',
  NInts.NJacobi(A, B: Int64)                                                                            name 'NInts_NJacobi_I6I6',
  NInts.NJacobi(A, B: Integer)                                                                          name 'NInts_NJacobi_InIn',
  NInts.NJacobi(A: Integer; const B: IInteger)                                                          name 'NInts_NJacobi_InII',
  NInts.NJacobi(const A: IInteger; B: Integer)                                                          name 'NInts_NJacobi_IIIn',
  NInts.NJacobi(const A, B: IInteger)                                                                   name 'NInts_NJacobi_IIII',
  NInts.NLucas(var V: IInteger; const K: IInteger)                                                      name 'NInts_NLucas_IIII',
  NInts.NLucas(var U, V: IInteger; const K: IInteger)                                                   name 'NInts_NLucas_IIIIII',
  NInts.NLucas(var V: IInteger; const K, P, Q: IInteger)                                                name 'NInts_NLucas_IIIIIIII',
  NInts.NLucas(var U, V: IInteger; const K, P, Q: IInteger)                                             name 'NInts_NLucas_IIIIIIIIII',
  NInts.NLucasMod(var V: IInteger; const K, P, M: IInteger)                                             name 'NInts_NLucasMod_IIIIIIII',
  NInts.NLucasMod(var V: IInteger; const K, P, Q, M: IInteger)                                          name 'NInts_NLucasMod_IIIIIIIIII',
  NInts.NLucasMod(var U, V: IInteger; const K, P, Q, M: IInteger)                                       name 'NInts_NLucasMod_IIIIIIIIIIII',
  NInts.NInvLucasMod(var A: IInteger; const K, N, P, Q: IInteger)                                       name 'NInts_NInvLucasMod_IIIIIIIIII',
  NInts.NInvLucasMod(var A: IInteger; const K, N, P, Q, U: IInteger)                                    name 'NInts_NInvLucasMod_IIIIIIIIIIII',
  NInts.NFermat(var A: IInteger; N: Cardinal; const M: IInteger)                                        name 'NInts_NFermat_IICaII',
  NInts.NFibonacci(var R: IInteger; N: Cardinal; const M: IInteger)                                     name 'NInts_NFibonacci_IICaII',
  NInts.NDigitCount(FromBase, ToBase: TBase; Digits: Cardinal)                                          name 'NInts_NDigitCount_BaBaCa',
  NInts.NDigitCount(const A: IInteger; Base: TBase; Exactly: Boolean)                                   name 'NInts_NDigitCount_IIBaBo',
  NInts.NLn(const A: IInteger; Base: Cardinal; ErrorCheck: Boolean)                                     name 'NInts_NLn_IICaBo',
  NInts.NDigit(const A: IInteger; Index: Integer; Piece: TPiece)                                        name 'NInts_NDigit_IIInPi',
  NInts.NDigit(var A: IInteger; Index: Integer; Value: Cardinal; Piece: TPiece)                         name 'NInts_NDigit_IIInCaPi',
  NInts.NAF(var A: TNAFArray; const B: IInteger; W: Byte)                                               name 'NInts_NAF_NAIIBy',
  _IIBa_NStr{const A: IInteger; Base: TBase): RetString}                                                name 'NInts_NStr_IIBa',
  _IISF_NStr{const A: IInteger; const Format: TStrFormat): RetString}                                   name 'NInts_NStr_IISF',
  NInts.NInt32(const A: IInteger; RangeCheck: Boolean)                                                  name 'NInts_NInt32_IIBo',
  NInts.NInt64(const A: IInteger; RangeCheck: Boolean)                                                  name 'NInts_NInt64_IIBo',
  NInts.NLong(const A: IInteger; RangeCheck: Boolean)                                                   name 'NInts_NLong_IIBo',
  NInts.NFloat(const A: IInteger; RangeCheck: Boolean)                                                  name 'NInts_NFloat_IIBo',
  NInts.NRange(const A: IInteger; Range: PTypeInfo; RaiseError: Boolean)                                name 'NInts_NRange_IITIBo',
  NInts.NSave(const A: IInteger; Stream: TStream; Format: TIntegerFormat)                               name 'NInts_NSave_IIStIF',
  NInts.NSave(const A: IInteger; const FileName: AnsiString; Format: TIntegerFormat)                    name 'NInts_NSave_IIStIF',
  NInts.NLoad(var R: IInteger; Stream: TStream; Format: TIntegerFormat)                                 name 'NInts_NLoad_IIStIF',
  NInts.NLoad(var R: IInteger; const FileName: AnsiString; Format: TIntegerFormat)                      name 'NInts_NLoad_IIStIF',
  NInts.NHash(var A: IInteger; Hash: TDECHashClass; Bits: Integer; Index: Cardinal)                     name 'NInts_NHash_IIHCInCa',
  NInts.NHash(var A: IInteger; const B: IInteger; Hash: TDECHashClass; Bits: Integer; Index: Cardinal)  name 'NInts_NHash_IIIIHCInCa',
  NInts.NMont(const M: IInteger)                                                                        name 'NInts_NMont_II',
  NInts.NMont(var A: IInteger; const M: IInteger; R: Cardinal)                                          name 'NInts_NMont_IIIICa',
  NInts.NMont(var A: IInteger; const B, M: IInteger; R: Cardinal)                                       name 'NInts_NMont_IIIIIICa',
  NInts.NMont(var A: IIntegerArray; const B: IIntegerArray; const M: IInteger; Inv2k: Cardinal)         name 'NInts_NMont_IAIAIICa',
  NInts.NMont(var A: IIntegerArray; const M: IInteger; Inv2k: Cardinal)                                 name 'NInts_NMont_IAIICa',
  NInts.NRedc(var A: IInteger; const M: IInteger; R: Cardinal)                                          name 'NInts_NRedc_IIIICa',
  NInts.NRedc(var A: IInteger; const B, M: IInteger; R: Cardinal)                                       name 'NInts_NRedc_IIIIIICa',
  NInts.NRedc(var A: IIntegerArray; const B: IIntegerArray; const M: IInteger; Inv2k: Cardinal)         name 'NInts_NRedc_IAIAIICa',
  NInts.NRedc(var A: IIntegerArray; const M: IInteger; Inv2k: Cardinal)                                 name 'NInts_NRedc_IAIICa',
  NInts.NSet(var P: IPowModPrecomputation; const B, M: IInteger; EMaxBitSize: Integer; EIsNeg: Boolean) name 'NInts_NSet_MPIIIIInBo',
  NInts.NSave(const P: IPowModPrecomputation; Stream: TStream)                                          name 'NInts_NSave_MPSt',
  NInts.NLoad(var P: IPowModPrecomputation; Stream: TStream)                                            name 'NInts_NLoad_MPSt',
  NInts.NSum(const A: IInteger)                                                                         name 'NInts_NSum_II',
  NInts.NMod(const A: Long96; B: Cardinal)                                                              name 'NInts_NMod_L9Ca',
  NInts.NSumModFactors(var Factors: IInteger; Bit: Integer)                                             name 'NInts_NSumModFactors_IIIn',
  NInts.NSumModModulis(var Modulis: IInteger; const Factors: IInteger)                                  name 'NInts_NSumModModulis_IIII',
  NInts.NInvMod2k32(A: Cardinal)                                                                        name 'NInts_NInvMod2k32_Ca',
  NInts.NInvMod2k32(const A: IInteger; B: Cardinal; BInv: Cardinal)                                     name 'NInts_NInvMod2k32_IICaCa',
  NInts.NInvMul2k32(A, B: Cardinal; BInv: Cardinal)                                                     name 'NInts_NInvMul2k32_CaCaCa',
  NInts.NInsert(var A: IInteger; B: Cardinal; Duplicates: Boolean)                                      name 'NInts_NInsert_IICaBo',
  NInts.NFind(const A: IInteger; B: Cardinal; var Index: Integer)                                       name 'NInts_NFind_IICaIn',
  NInts.NFind(const A: IInteger; B: Cardinal)                                                           name 'NInts_NFind_IICa',
  NInts.NSort(var A: IInteger)                                                                          name 'NInts_NSort_II',
  NInts.NSort(var A: IIntegerArray; Compare: TIIntegerSortCompare)                                      name 'NInts_NSort_IASC',
  NInts.NSort(var A: IIntegerArray; Abs: Boolean; Descending: Boolean)                                  name 'NInts_NSort_IABoBo',
  NInts.NForEach(const A: IIntegerArray; Callback: TIIntegerForEachCallback)                            name 'NInts_NForEach_IAIC',
  NInts.NBinarySplitting(var P, Q: IInteger; Count: Integer; Callback: TIIntegerBinarySplittingCallback; ImplicitShift: Boolean) name 'NInts_NBinarySplitting_XXX',
  NInts.NConfig{Flag: Cardinal}                                                                         name 'NInts_NConfig_Ca',
  NInts.NRaise(Msg: PResStringRec; const Param: AnsiString)                                             name 'NInts_NRaise_SRSt',
  NInts.NRaise(Msg: PResStringRec; const Param: array of const)                                         name 'NInts_NRaise_SRAC',
  NInts.NRaise(Msg: PResStringRec)                                                                      name 'NInts_NRaise_SR',
  NInts.NRaise_DivByZero                                                                                name 'NInts_NRaise_DivByZero_',
  NInts.NParseFormat{var F: TStrFormat; const B: AnsiString}                                            name 'NInts_NParseFormat_SFSt',
  NInts.NLog2{A: Cardinal}                                                                              name 'NInts_NLog2_Ca',
  NInts.NBitWeight(A: Cardinal)                                                                         name 'NInts_NBitWeight_Ca',
  NInts.NBitSwap(A: Cardinal)                                                                           name 'NInts_NBitSwap_Ca',
  NInts.NGrayCodeTo(N: Cardinal)                                                                        name 'NInts_NGrayCodeTo_Ca',
  NInts.NGrayCodeTo(var A: IInteger; const B: IInteger)                                                 name 'NInts_NGrayCodeTo_IIII',
  NInts.NToGrayCode(N: Cardinal)                                                                        name 'NInts_NToGrayCode_Ca',
  NInts.NToGrayCode(var A: IInteger; const B: IInteger)                                                 name 'NInts_NToGrayCode_IIII',
  NInts.NGreenCodeTo(N: Cardinal)                                                                       name 'NInts_NGreenCodeTo_Ca',
  NInts.NGreenCodeTo(var A: IInteger; const B: IInteger)                                                name 'NInts_NGreenCodeTo_IIII',
  NInts.NToGreenCode(N: Cardinal)                                                                       name 'NInts_NToGreenCode_Ca',
  NInts.NToGreenCode(var A: IInteger; const B: IInteger)                                                name 'NInts_NToGreenCode_IIII',
  NInts.NNull                                                                                           name 'NInts_NNull',
  NInts.NOne                                                                                            name 'NInts_NOne',
  NInts.NMinusOne                                                                                       name 'NInts_NMinusOne',
  NInts.NTwo                                                                                            name 'NInts_NTwo',
  NInts.NMinusTwo                                                                                       name 'NInts_NMinusTwo',
  NInts.NBreakEven{Index: Integer}                                                                      name 'NInts_NBreakEven_In',
  NInts.NSwp(var A, B: I2Point)                                                                         name 'NInts_NSwp_2P2P',
  NInts.NSwp(var A, B: I3Point)                                                                         name 'NInts_NSwp_3P3P',
  NInts.NSet(var A: I2Point; const B: I2Point)                                                          name 'NInts_NSet_2P2P',
  NInts.NSet(var A: I3Point; const B: I3Point)                                                          name 'NInts_NSet_3P3P',
  NInts.NNorm(const A: IInteger)                                                                        name 'NInts_NNorm_II',
  _GetNStrFormat                                                                                        name 'NInts_GetNStrFormat',
  _SetNStrFormat{const F: TStrFormat}                                                                   name 'NInts_SetNStrFormat',
  NInts.NValid(const A: array of IInteger)                                                              name 'NInts_NValid_AI',
  NInts.NValid(const A: IIntegerArray)                                                                  name 'NInts_NValid_IA';

(***** NIntM *** NInts *****)

exports
  NIntM.NSet(var M: IModulus; Modulus: Cardinal)   name 'NIntM_NSet_IMCa',
  NIntM.NSet(A: Cardinal; const M: IModulus)       name 'NIntM_NSet_CaIM',
  NIntM.NGet(A: Cardinal; const M: IModulus)       name 'NIntM_NGet_CaIM',
  NIntM.NAddMod(A, B: Cardinal; const M: IModulus) name 'NIntM_NAddMod_CaCaIM',
  NIntM.NSubMod(A, B: Cardinal; const M: IModulus) name 'NIntM_NSubMod_CaCaIM',
  NIntM.NMulMod(A, B: Cardinal; const M: IModulus) name 'NIntM_NMulMod_CaCaIM',
  NIntM.NPowMod(A, E: Cardinal; const M: IModulus) name 'NIntM_NPowMod_CaCaIM',
  NIntM.NSqrtMod(A: Cardinal; const M: IModulus)   name 'NIntM_NSqrtMod_CaIM',
  NIntM.NSqrtMod(A, P: Cardinal)                   name 'NIntM_NSqrtMod_CaCa',
  NIntM.NInvMod(A, M: Cardinal)                    name 'NIntM_NInvMod_CaCa',
  NIntM.NMulMod(A, B, M: Cardinal)                 name 'NIntM_NMulMod_CaCaCa',
  NIntM.NAddMod(A, B, M: Cardinal)                 name 'NIntM_NAddMod_CaCaCa',
  NIntM.NSubMod(A, B, M: Cardinal)                 name 'NIntM_NSubMod_CaCaCa';

(***** FULL-SOURCE: NInt_1 *** {NMath,} NInts, SysUtils *****)

exports
  NInt_1.NCFE{var P, Q: IInteger; CFEFunc: TCFEFunc; Last: Integer}          name 'NInt1_NCFE_IIIIFuIn',
  NInt_1.CFE_Euler{Index: Integer}                                           name 'NInt1_CFE_Euler_In',
  NInt_1.CFE_GoldenRatio{Index: Integer}                                     name 'NInt1_CFE_GoldenRatio_In',
  NInt_1.CFE_Tan1{Index: Integer}                                            name 'NInt1_CFE_Tan1_II',
  NInt_1.NLn2{var R: IInteger}                                               name 'NInt1_NLn2_II',
  NInt_1.NLn10{var R: IInteger}                                              name 'NInt1_NLn10_II',
  NInt_1.NArcTan(var R: IInteger; const U, V: IInteger)                      name 'NInt1_NArcTan_IIIIII',
  NInt_1.NArcTan(var R: IInteger; V: Integer)                                name 'NInt1_NArcTan_IIII',
  NInt_1.NArcTanh{var R: IInteger; const V: IInteger}                        name 'NInt1_NArcTanh_IIII',
  NInt_1.NSin{var R: IInteger; const U, V: IInteger}                         name 'NInt1_NSin_IIIIII',
  NInt_1.NSinh{var R: IInteger; const U, V: IInteger}                        name 'NInt1_NSinh_IIIIII',
  NInt_1.NCos{var R: IInteger; const U, V: IInteger}                         name 'NInt1_NCos_IIIIII',
  NInt_1.NCosh{var R: IInteger; const U, V: IInteger}                        name 'NInt1_NCosh_IIIIII',
  NInt_1.NTan{var R: IInteger; const U, V: IInteger}                         name 'NInt1_NTan_IIIIII',
  NInt_1.NTanh{var R: IInteger; const U, V: IInteger}                        name 'NInt1_NTanh_IIIIII',
  NInt_1.NExp(var A: IInteger; U: Integer; V: Integer)                       name 'NInt1_NExp_IIInIn',
  NInt_1.NExp(var A: IInteger; const U, V: IInteger)                         name 'NInt1_NExp_IIIIII',
  NInt_1.NPi{var A: IInteger; Decimals: Cardinal; Method: TIIntegerPIMethod} name 'NInt1_NPi_IICaTM',
  NInt_1.NFactorial1{var A: IInteger; N: Cardinal}                           name 'NInt1_NFactorial1_IICa';

(***** NRats *** NMath, NInts, SysUtils *****)

function _IRTB_NStr(const A: IRational; Base: TBase; Precision: Cardinal): RetString;
var
  Temp: AnsiString;
begin
  Temp := NRats.NStr(A, Base, Precision);
  CurHookRefs.NewAnsiString(Pointer(Result), Pointer(Temp), Length(Temp), CP_ACP);
end;

function _IRSF_NStr(const A: IRational; const Format: TStrFormat; Precision: Cardinal): RetString;
var
  Temp: AnsiString;
begin
  Temp := NRats.NStr(A, Format, Precision);
  CurHookRefs.NewAnsiString(Pointer(Result), Pointer(Temp), Length(Temp), CP_ACP);
end;

function _GetDefaultPrecision: Cardinal;
begin
  Result := NRats.DefaultPrecision;
end;

procedure _SetDefaultPrecision(P: Cardinal);
begin
  NRats.DefaultPrecision := P;
end;

exports
  NRats.NSet(var A: IRational; const N: IInteger; const D: IInteger)           name 'NRats_NSet_IRIIII',
  NRats.NSet(var A: IRational; const N: Integer; const D: Integer)             name 'NRats_NSet_IRInIn',
  NRats.NSet(var A: IRational; const N: Int64; const D: Int64)                 name 'NRats_NSet_IRI6I6',
  NRats.NSet(var A: IRational; const B: IRational)                             name 'NRats_NSet_IRIR',
  NRats.NSet(var A: IRational; const B: Extended)                              name 'NRats_NSet_IREx',
  NRats.NSet(var A: IRational; const B: AnsiString; const Format: TStrFormat)  name 'NRats_NSet_IRStSF',
  NRats.NSet(var A: IRational; const B: AnsiString)                            name 'NRats_NSet_IRSt',
  NRats.NSet(var A: IRationalArray; const B: array of IRational)               name 'NRats_NSet_IAAR',
  NRats.NRat(const N: IInteger)                                                name 'NRats_NRat_II',
  NRats.NRat(const N, D: IInteger)                                             name 'NRats_NRat_IIII',
  NRats.NRat(const N: Integer)                                                 name 'NRats_NRat_In',
  NRats.NRat(const N, D: Integer)                                              name 'NRats_NRat_InIn',
  NRats.NRat(const N: Int64)                                                   name 'NRats_NRat_I6',
  NRats.NRat(const N, D: Int64)                                                name 'NRats_NRat_I6I6',
  NRats.NRat(const A: Extended)                                                name 'NRats_NRat_Ex',
  NRats.NRat(const A: AnsiString; const Format: TStrFormat)                    name 'NRats_NRat_StSF',
  NRats.NRat(const A: AnsiString)                                              name 'NRats_NRat_St',
  NRats.NRat(const A: array of IRational)                                      name 'NRats_NRat_AR',
  NRats.NInt(const A: IRational; What: TIRationalResult)                       name 'NRats_NRat_IRRR',
  NRats.NSgn(const A: IRational)                                               name 'NRats_NSng_IR',
  NRats.NSgn(var A: IRational; Sign: Integer)                                  name 'NRats_NSng_IRIn',
  NRats.NNeg(var A: IRational)                                                 name 'NRats_NNeg_IR',
  NRats.NNeg(var A: IRational; Negative: Boolean)                              name 'NRats_NNeg_IRBo',
  NRats.NAbs(var A: IRational)                                                 name 'NRats_NAbs_IR',
  NRats.NSwp(var A, B: IRational)                                              name 'NRats_NSwp_IRIRBo',
  NRats.NCmp(const A, B: IRational; Abs: Boolean)                              name 'NRats_NCmp_IRCa',
  NRats.NInc(var A: IRational; B: Cardinal)                                    name 'NRats_NInc_IRCa',
  NRats.NDec(var A: IRational; B: Cardinal)                                    name 'NRats_NDec_IRIn',
  NRats.NAdd(var A: IRational; B: Integer)                                     name 'NRats_NAdd_IRBo',
  NRats.NAdd(var A: IRational; const B: IRational; C: Integer)                 name 'NRats_NAdd_IRIRIn',
  NRats.NAdd(var A: IRational; const B: IInteger)                              name 'NRats_NAdd_IRII',
  NRats.NAdd(var A: IRational; const B: IRational; const C: IInteger)          name 'NRats_NAdd_IRIRII',
  NRats.NAdd(var A: IRational; const B: IRational)                             name 'NRats_NAdd_IRIR',
  NRats.NAdd(var A: IRational; const B, C: IRational)                          name 'NRats_NAdd_IRIRIR',
  NRats.NSub(var A: IRational; B: Integer)                                     name 'NRats_NSub_IRIn',
  NRats.NSub(var A: IRational; const B: IRational; C: Integer)                 name 'NRats_NSub_IRIRIn',
  NRats.NSub(var A: IRational; const B: IInteger)                              name 'NRats_NSub_IRII',
  NRats.NSub(var A: IRational; const B: IRational; const C: IInteger)          name 'NRats_NSub_IRIRIn',
  NRats.NSub(var A: IRational; const B: IRational)                             name 'NRats_NSub_IRIR',
  NRats.NSub(var A: IRational; const B, C: IRational)                          name 'NRats_NSub_IRIRIR',
  NRats.NShl(var A: IRational; Shift: Integer)                                 name 'NRats_NShl_IRIn',
  NRats.NShl(var A: IRational; const B: IRational; Shift: Integer)             name 'NRats_NShl_IRIRIn',
  NRats.NShr(var A: IRational; Shift: Integer)                                 name 'NRats_NShr_IRIn',
  NRats.NShr(var A: IRational; const B: IRational; Shift: Integer)             name 'NRats_NShr_IRIRIn',
  NRats.NMul(var A: IRational; B: Integer)                                     name 'NRats_NMul_IRIn',
  NRats.NMul(var A: IRational; const B: IRational; C: Integer)                 name 'NRats_NMul_IRIRIn',
  NRats.NMul(var A: IRational; const B: IInteger)                              name 'NRats_NMul_IRII',
  NRats.NMul(var A: IRational; const B: IRational; const C: IInteger)          name 'NRats_NMul_IRIRIn',
  NRats.NMul(var A: IRational; const B: IRational)                             name 'NRats_NMul_IRIR',
  NRats.NMul(var A: IRational; const B, C: IRational)                          name 'NRats_NMul_IRIRIR',
  NRats.NSqr(var A: IRational)                                                 name 'NRats_NSqr_IR',
  NRats.NSqr(var A: IRational; const B: IRational)                             name 'NRats_NSqr_IRIR',
  NRats.NSqrt(var A: IRational)                                                name 'NRats_NSqrt_IR',
  NRats.NSqrt(var A: IRational; const B: IRational)                            name 'NRats_NSqrt_IRIR',
  NRats.NDiv(var A: IRational; B: Integer)                                     name 'NRats_NDiv_IRIn',
  NRats.NDiv(var A: IRational; const B: IRational; C: Integer)                 name 'NRats_NDiv_IRIRIn',
  NRats.NDiv(var A: IRational; const B: IInteger)                              name 'NRats_NDiv_IRII',
  NRats.NDiv(var A: IRational; const B: IRational; const C: IInteger)          name 'NRats_NDiv_IRIRII',
  NRats.NDiv(var A: IRational; const B: IRational)                             name 'NRats_NDiv_IRIR',
  NRats.NDiv(var A: IRational; const B, C: IRational)                          name 'NRats_NDiv_IRIRIR',
  NRats.NInv(var A: IRational)                                                 name 'NRats_NInv_IR',
  NRats.NInv(var A: IRational; const B: IRational)                             name 'NRats_NInv_IRIR',
  NRats.NPow(var A: IRational; E: Integer)                                     name 'NRats_NPow_IRIn',
  NRats.NPow(var A: IRational; const B: IRational; E: Integer)                 name 'NRats_NPow_IRIRIn',
  NRats.NExp(var A: IRational)                                                 name 'NRats_NExp_IR',
  NRats.NExp(var A: IRational; const B: IRational)                             name 'NRats_NExp_IRIR',
  NRats.NRnd(var A: IRational; Bits: Integer; Sign: Boolean)                   name 'NRats_NRnd_IRInBo',
  _IRTB_NStr{const A: IRational; Base: TBase; Precision: Cardinal): RetString}              name 'NRats_NStr_IRTBCa',
  _IRSF_NStr{const A: IRational; const Format: TStrFormat; Precision: Cardinal): RetString} name 'NRats_NStr_IRSFCa',
  NRats.NSort(var A: IRationalArray; Compare: TIRationalSortCompare)           name 'NRats_NSort_IASC',
  NRats.NSort(var A: IRationalArray; Abs: Boolean; Descending: Boolean)        name 'NRats_NSort_IABoBo',
  NRats.NForEach(const A: IRationalArray; Callback: TIRationalForEachCallback) name 'NRats_NForEach_IARC',
  NRats.NPrc(var A: IRational; Precision: Cardinal; Base: TBase)               name 'NRats_NPrc_IRCaTB',
  _GetDefaultPrecision                                                         name 'NRats_GetDefaultPrecision',
  _SetDefaultPrecision{P: Cardinal}                                            name 'NRats_SetDefaultPrecision';

(***** NPolys *** NInts, CRC, SysUtils *****)

function _IPBa_NStr(const A: IPoly; Base: TBase): RetString;
var
  Temp: AnsiString;
begin
  Temp := NPolys.NStr(A, Base);
  CurHookRefs.NewAnsiString(Pointer(Result), Pointer(Temp), Length(Temp), CP_ACP);
end;

function _IPSF_NStr(const A: IPoly; const Format: TStrFormat): RetString;
var
  Temp: AnsiString;
begin
  Temp := NPolys.NStr(A, Format);
  CurHookRefs.NewAnsiString(Pointer(Result), Pointer(Temp), Length(Temp), CP_ACP);
end;

exports
  NPolys.NSet(var A: IPoly; const B: IIntegerArray)                                  name 'NPolys_NSet_IPIA',
  NPolys.NSet(var A: IPoly; const B: array of const)                                 name 'NPolys_NSet_IPAC',
  NPolys.NSet(var A: IPoly; const B: IPoly)                                          name 'NPolys_NSet_IPIP',
  NPolys.NSet(var A: IInteger; const B: IPoly; const X: IInteger; const M: IInteger) name 'NPolys_NSet_IIIPIIII',
  NPolys.NInt(const A: IPoly; const X: IInteger; const M: IInteger)                  name 'NPolys_NInt_IPIIII',
  NPolys.NSwp(var A, B: IPoly)                                                       name 'NPolys_NSwp_IPIP',
  NPolys.NSwp(var A: IPoly)                                                          name 'NPolys_NSwp_IP',
  NPolys.NPoly(const B: IIntegerArray)                                               name 'NPolys_NPoly_IA',
  NPolys.NPoly(const B: array of const)                                              name 'NPolys_NPoly_AC',
  NPolys.NDegree(const A: IPoly)                                                     name 'NPolys_NDegree_IP',
  NPolys.NCmp(const A, B: IPoly)                                                     name 'NPolys_NCmp_IPIP',
  NPolys.NAdd(var A: IPoly; const B: IPoly)                                          name 'NPolys_NAdd_IPIP',
  NPolys.NAdd(var A: IPoly; const B, C: IPoly)                                       name 'NPolys_NAdd_IPIPIP',
  NPolys.NSub(var A: IPoly; const B: IPoly)                                          name 'NPolys_NSub_IPIP',
  NPolys.NSub(var A: IPoly; const B, C: IPoly)                                       name 'NPolys_NSub_IPIPIP',
  NPolys.NInc(var A: IPoly; const B: Cardinal)                                       name 'NPolys_NInc_IPCa',
  NPolys.NDec(var A: IPoly; const B: Cardinal)                                       name 'NPolys_NDec_IPCa',
  NPolys.NMul(var A: IPoly; const B: IPoly)                                          name 'NPolys_NMul_IPIP',
  NPolys.NMul(var A: IPoly; const B, C: IPoly)                                       name 'NPolys_NMul_IPIPIP',
  NPolys.NMul(var A: IPoly; const B: IInteger)                                       name 'NPolys_NMul_IPII',
  NPolys.NMul(var A: IPoly; const B: IPoly; const C: IInteger)                       name 'NPolys_NMul_IPIPII',
  NPolys.NMul(var A: IPoly; B: Integer)                                              name 'NPolys_NMul_IPIn',
  NPolys.NMul(var A: IPoly; const B: IPoly; C: Integer)                              name 'NPolys_NMul_IPIPIn',
  NPolys.NSqr(var A: IPoly)                                                          name 'NPolys_NSqr_IP',
  NPolys.NSqr(var A: IPoly; const B: IPoly)                                          name 'NPolys_NSqr_IPIP',
  NPolys.NRem(var A: IPoly; const M: IInteger)                                       name 'NPolys_NRem_IPII',
  NPolys.NMod(var A: IPoly; const M: IInteger)                                       name 'NPolys_NMod_IPII',
  NPolys.NRem(var A: IPoly; const B: IPoly; const M: IInteger)                       name 'NPolys_NRem_IPIPII',
  NPolys.NRem(var A: IPoly; const B, C: IPoly; const M: IInteger)                    name 'NPolys_NRem_IPIPIPII',
  NPolys.NDiv(var A: IPoly; const B: IPoly; const M: IInteger)                       name 'NPolys_NDiv_IPIPII',
  NPolys.NDiv(var A: IPoly; const B, C: IPoly; const M: IInteger)                    name 'NPolys_NDiv_IPIPIPII',
  NPolys.NDivRem(var Q, R: IPoly; const A, B: IPoly; const M: IInteger)              name 'NPolys_NDivRem_IPIPIPIPII',
  NPolys.NDivXk(var A: IPoly; K: Cardinal)                                           name 'NPolys_NDivXk_IPCa',
  NPolys.NDivXk(var A: IPoly; const B: IPoly; K: Integer)                            name 'NPolys_NDivXk_IPIPIn',
  NPolys.NDivRemXk(var Q, R: IPoly; const B: IPoly; K: Integer)                      name 'NPolys_NDivRemXk_IPIPIPIn',
  NPolys.NRemXk(var A: IPoly; K: Integer)                                            name 'NPolys_NRemXk_IPIn',
  NPolys.NRemXk(var A: IPoly; const B: IPoly; K: Integer)                            name 'NPolys_NRemXk_IPIPIn',
  NPolys.NMulXk(var A: IPoly; K: Integer)                                            name 'NPolys_NMulXk_IPIn',
  NPolys.NMulXk(var A: IPoly; const B: IPoly; K: Integer)                            name 'NPolys_NMulXk_IPIPIn',
  NPolys.NGCD(var D: IPoly; const A, B: IPoly; const M: IInteger)                    name 'NPolys_NGCD_IPIPIPII',
  NPolys.NPowRem(var A: IPoly; const E: IInteger; const B: IPoly; const M: IInteger) name 'NPolys_NPowRem_IPIIIPII',
  NPolys.NPowMod(var A: IPoly; const E: IInteger; const B: IPoly; const M: IInteger) name 'NPolys_NPowMod_IPIIIPII',
  NPolys.NRnd(var A: IPoly; Degree: Cardinal; const M: IInteger; Monic: Boolean)     name 'NPolys_NRnd_IPCaIIBo',
  NPolys.NFactor(var A: IPoly; const B: IPoly; K: Integer; const M: IInteger)        name 'NPolys_NFactor_IPIPInII',
   _IPBa_NStr{const A: IPoly; Base: TBase): RetString}                               name 'NPolys_NStr_IPBa',
   _IPSF_NStr{const A: IPoly; const Format: TStrFormat): RetString}                  name 'NPolys_NStr_IPSF',
  NPolys.NCRC(const A: IPoly; CRC: TCRCType)                                         name 'NPolys_NCRC_IPCT',
  NPolys.NNorm(var A: IPoly)                                                         name 'NPolys_NNorm_IP';

(***** Prime *** CRC, SysUtils, Classes, Windows *****)

type
  ISmallPrimeSieve = interface
    ['{897D56D7-7514-4473-917E-3DEFCD9A54E3}']
    function MinPrime: Cardinal; // min. Prime, allways 2
    function MaxPrime: Cardinal; // max. possible Prime, dependend from Compiler Version
    function MinIndex: Cardinal; // min. Index, allways 1
    function MaxIndex: Cardinal; // max. Index, see MaxPrime

    function Count(LowerBound, UpperBound: Cardinal): Cardinal; // compute Primecount beetwen Bounds
    function IndexOf(Value: Cardinal; LowerBound: Boolean = False): Cardinal; // give Primeindex of Value

    procedure LoadCache(const FileName: AnsiString); // load a Prime Cache
    procedure BuildCache(const FileName: AnsiString; Bound: Cardinal); // create and save a Cache

    function GetPrime(Index: Cardinal): Cardinal;
    property Prime[Index: Cardinal]: Cardinal read GetPrime; default; // return Prime with Index

    function CacheMaxPrime: Cardinal; // max. cached Prime
    function CacheMaxIndex: Cardinal; // max. cached Index of max. Prime
                                      // cached min. Values are allways equal to MinPrime, MinIndex
  end;
  TSmallPrimeSieveIntf = class({TSmallPrimeSieve}TInterfacedObject, ISmallPrimeSieve)
    function MinPrime: Cardinal; 
    function MaxPrime: Cardinal;
    function MinIndex: Cardinal;
    function MaxIndex: Cardinal;

    function Count(LowerBound, UpperBound: Cardinal): Cardinal;
    function IndexOf(Value: Cardinal; LowerBound: Boolean = False): Cardinal;

    procedure LoadCache(const FileName: AnsiString);
    procedure BuildCache(const FileName: AnsiString; Bound: Cardinal);

    function GetPrime(Index: Cardinal): Cardinal;

    function CacheMaxPrime: Cardinal;
    function CacheMaxIndex: Cardinal;
  end;

var
  FPrimesIntf: ISmallPrimeSieve;

function PrimesIntf: ISmallPrimeSieve;
begin
  //Result := Prime.Primes as ISmallPrimeSieve;
  if not Assigned(FPrimesIntf) then
    FPrimesIntf := TSmallPrimeSieveIntf.Create;
  Result := FPrimesIntf;
end;

exports
  PrimesIntf name 'Prime_Primes',
  IsPrime    name 'Prime_IsPrime';

(***** FULL-SOURCE: IsPrimeHRUnit *****)

exports
  IsPrimeHRUnit.IsPrime name 'IsPrimeHRUnit_IsPrime_Ca';

(***** IDPrimes *** NInts, ASN1, CRC, DECHash, DECUtil, SysUtils, Classes *****)

function _IPrimDP_NStr(const ID: IIDPrime): RetString;
var
  Temp: AnsiString;
begin
  Temp := IDPrimes.NStr(ID);
  CurHookRefs.NewAnsiString(Pointer(Result), Pointer(Temp), Length(Temp), CP_ACP);
end;

exports
  IDPrimes.NSet(var P: IInteger; const ID: IIDPrime; CheckPrimality: Boolean; RaiseError: Boolean)  name 'IDPrimes_NSet_IIDPBoBo',
  IDPrimes.NInt(const ID: IIDPrime; CheckPrimality: Boolean)                                        name 'IDPrimes_NInt_DPBo',
  IDPrimes.NSet(var ID: IIDPrime; const S: AnsiString; RaiseError: Boolean)                         name 'IDPrimes_NSet_DPStBo',
  IDPrimes.NIDPrime(const ID: AnsiString)                                                           name 'IDPrimes_NIDPrime_St',
  _IPrimDP_NStr{const ID: IIDPrime): RetString}                                                     name 'IDPrimes_NStr_DP',
  IDPrimes.NSave(const ID: IIDPrime; Stream: TStream)                                               name 'IDPrimes_NSave_DPSt',
  IDPrimes.NLoad(var ID: IIDPrime; Stream: TStream; RaiseError: Boolean)                            name 'IDPrimes_NLoad_DPStBo',
  IDPrimes.NIDPrime(Stream: TStream)                                                                name 'IDPrimes_NIDPrime_St',
  IDPrimes.NMake(var ID: IIDPrime; BitSize: Word; SeedBitSize: Word; const Residue: IInteger; const
    Modulus: IInteger; HashIndex: Word; HashClass: TDECHashClass; Callback: TIIntegerPrimeCallback) name 'IDPrimes_NMake_XXX';

(***** FULL-SOURCE: NCombi *** NMath, NInts, Prime, SysUtils, -Math- *****)

exports
  NCombi.NFactorial_Moessner{var A: IInteger; N: Cardinal}                                                      name 'NCombi_NFactorial_Moessner_IICa',
  NCombi.NFactorial_Naive{var A: IInteger; N: Cardinal}                                                         name 'NCombi_NFactorial_Naive_IICa',
  NCombi.NFactorial_Recursive{var A: IInteger; N: Cardinal}                                                     name 'NCombi_NFactorial_Recursive_IICa',
  NCombi.NFactorial_DivideAndConquer{var A: IInteger; N: Cardinal}                                              name 'NCombi_NFactorial_DivideAndConquer_IICa',
  NCombi.NFactorial_Binomial{var A: IInteger; N: Cardinal}                                                      name 'NCombi_NFactorial_Binomial_IICa',
  NCombi.NFactorial_Jason_GMP{var A: IInteger; N: Cardinal}                                                     name 'NCombi_NFactorial_Jason_GMP_IICa',
  NCombi.NFactorial(var A: IInteger; N: Cardinal; const M: IInteger)                                            name 'NCombi_NFactorial_IICaII',
  NCombi.NComporial(var A: IInteger; N: Cardinal; const M: IInteger)                                            name 'NCombi_NComporial_IICaII',
  NCombi.NBinomial(var A: IInteger; N, K: Cardinal; const M: IInteger)                                          name 'NCombi_NBinomial_IICaCaII',
  NCombi.NProduct(var A: IInteger; N, K: Cardinal; const M: IInteger)                                           name 'NCombi_NProduct_IICaCaII',
  NCombi.NPermutation(var A: IInteger; N, K: Cardinal; const M: IInteger)                                       name 'NCombi_NPermutation_IICaCaII',
  NCombi.NOddFactorial(var A: IInteger; N: Cardinal; const M: IInteger)                                         name 'NCombi_NOddFactorial_IICaII',
  NCombi.NPrimorial(var A: IInteger; K, N: Cardinal; const M: IInteger)                                         name 'NCombi_NPrimorial_IICaCaII',
  NCombi.NHalfFactorial(var A: IInteger; N: Cardinal; const M: IInteger)                                        name 'NCombi_NHalfFactorial_IICaII',
  NCombi.NHalfComporial(var A: IInteger; N: Cardinal; const M: IInteger)                                        name 'NCombi_NHalfComporial_IICaII',
  NCombi.NHalfPrimorial(var A: IInteger; N: Cardinal; const M: IInteger)                                        name 'NCombi_NHalfPrimorial_IICaII',
  NCombi.NHalfBinomial(var A: IInteger; N: Cardinal; const M: IInteger)                                         name 'NCombi_NHalfBinomial_IICaII',
  NCombi.NFactorialTrailingZeros{const N: Int64; Base: Cardinal}                                                name 'NCombi_NFactorialTrailingZeros_I6Ca',
  NCombi.NTestCombi(N: Cardinal)                                                                                name 'NCombi_NTestCombi_Ca',
  NCombi.NPowerTable(var T: TPowerTable; N: Cardinal; L: Cardinal; K: Cardinal)                                 name 'NCombi_NPowerTable_PTCaCaCa',
  NCombi.NPowerTable(var A: IInteger; N: Cardinal; L: Cardinal; K: Cardinal; Shift: Boolean; const M: IInteger) name 'NCombi_NPowerTable_IICaCaCaBoII',
  NCombi.NPrd(var A: IInteger; const T: TPowerTable; E: Cardinal; const M: IInteger)                            name 'NCombi_NPrd_IIPTCaII',
  NCombi.NPrd(var A: IInteger; const T: TPowerTable; const M: IInteger)                                         name 'NCombi_NPrd_IIPTII';

(***** NGFPs *** NMath, NInts, IDPrimes, Classes *****)

exports
  NGFPs.NECRaise(State: TECState)                                                                                  name 'NGFPs_NECRaise_ES',
  NGFPs.NECCheck(const E: IGFpEC; RaiseException: Boolean)                                                         name 'NGFPs_NECCheck_FCBo',
  NGFPs.NECCheck(const E: IGFpECC; RaiseException: Boolean)                                                        name 'NGFPs_NECCheck_GCBo',
  NGFPs.NECCheck(const P: array of I2Point; const E: IGFpEC; RaiseException: Boolean)                              name 'NGFPs_NECCheck_APFCBo',
  NGFPs.NECCheck(const P: array of I2Point; const E: IGFpECC; RaiseException: Boolean)                             name 'NGFPs_NECCheck_APGCBo',
  NGFPs.NECCheckMOVCondition(const E: IGFpECC; RaiseException: Boolean)                                            name 'NGFPs_NECCheckMOVCondition_FCBo',
  NGFPs.NSwp(var A, B: IGFpEC)                                                                                     name 'NGFPs_NSwp_FCFC',
  NGFPs.NSet(var A: I2Point; const X: IInteger; YIsOdd: Boolean; const E: IGFpEC)                                  name 'NGFPs_NSet_2PIIBoFC',
  NGFPs.NSet(var A: IGFpEC; const B: IGFpEC)                                                                       name 'NGFPs_NSet_FCFC',
  NGFPs.NSet(var A: IInteger; const B: I2Point)                                                                    name 'NGFPs_NSet_II2P',
  NGFPs.NSet(var A: I2Point; const B: IInteger; const E: IGFpEC)                                                   name 'NGFPs_NSet_2PIIFC',
  NGFPs.NAdd(var A: I2Point; const B: I2Point; const E: IGFpEC)                                                    name 'NGFPs_NAdd_2P2PFC',
  NGFPs.NSub(var A: I2Point; const B: I2Point; const E: IGFpEC)                                                    name 'NGFPs_NSub_2P2PFC',
  NGFPs.NMul(var A: I2Point; const B: IInteger; const E: IGFpEC; const P: IGFpMulPrecomputation)                   name 'NGFPs_NMul_2PIIFCMP',
  NGFPs.NMul(var A: I2Point; const B: I2Point; const C: IInteger; const E: IGFpEC; const P: IGFpMulPrecomputation) name 'NGFPs_NMul_2P2PIIFCMP',
  NGFPs.NMul2k(var A: I2Point; K: Cardinal; const E: IGFpEC; const P: IGFpMulPrecomputation)                       name 'NGFPs_NMul2k_2PCaFCMP',
  NGFPs.NMul2k(var A: I2Point; const B: I2Point; K: Cardinal; const E: IGFpEC; const P: IGFpMulPrecomputation)     name 'NGFPs_NMul2k_2P2PCaFCMP',
  NGFPs.NInv(var A: I2Point; const E: IGFpEC)                                                                      name 'NGFPs_NInv_2PFC',
  NGFPs.NRnd(var A: I2Point; const E: IGFpEC)                                                                      name 'NGFPs_NRnd_2PFC',
  NGFPs.NRnd(var E: IGFpEC; FieldBitSize: Integer)                                                                 name 'NGFPs_NRnd_FCIn',
  NGFPs.NEmpty(const A: I2Point)                                                                                   name 'NGFPs_NEmpty_2P',
  NGFPs.NEmpty(const A: I3Point)                                                                                   name 'NGFPs_NEmpty_3P',
  NGFPs.NSet(var P: IGFpMulPrecomputation; const B: I2Point; const E: IGFpEC; CMaxBitSize: Integer)                name 'NGFPs_NSet_MP2PFCIn',
  NGFPs.NSave(const P: IGFpMulPrecomputation; Stream: TStream)                                                     name 'NGFPs_NSave_MPSt',
  NGFPs.NLoad(var P: IGFpMulPrecomputation; Stream: TStream)                                                       name 'NGFPs_NLoad_MPSt',
  NGFPs.NMul_MontPB{var A: I2Point; const B: I2Point; const C: IInteger; const E: IGFpEC}                          name 'NGFPs_NMul_MontPB_2P2PIIFC',
  NGFPs.NMul_Affine{var A: I2Point; const B: I2Point; C: IInteger; const E: IGFpEC}                                name 'NGFPs_NMul_Affine_2P2PIIFC',
  NGFPs.NMul_Proj{var A: I2Point; const B: I2Point; const C: IInteger; const E: IGFpEC}                            name 'NGFPs_NMul_Proj_2P2PIIFC',
  NGFPs.NMul2k_Normal(var A: I2Point; const B: I2Point; K: Cardinal; const E: IGFpEC)                              name 'NGFPs_NMul2k_Normal_2P2PCaFC',
  NGFPs.NMul2k_Mont{var A: I2Point; const B: I2Point; K: Cardinal; const E: IGFpEC}                                name 'NGFPs_NMul2k_Mont_2P2PCaFC';

(***** NGFPBld *** NMath, NInts, NPolys, Prime, IDPrimes, NGFPs, DECHash *****)

exports
  NECBuild(var E: IGFpECC; FieldBitSize: Integer; CofactorBitSize: Integer; Flag: TECBuildFlag; SeedBitSize: Word; HashClass: TDECHashClass; MinCM: Cardinal; MaxCM: Cardinal) name 'NECBuild_XXX',
  NGFPBld.NECRegisterPolyTable   name 'NGFPBld_NECRegisterPolyTable_GP',
  NGFPBld.NECUnregisterPolyTable name 'NGFPBld_NECUnregisterPolyTable_GP',
  NGFPBld.NECPolyTable           name 'NGFPBld_NECPolyTable';

(***** NGFPTab *** NInts, NPolys, NGFPBld, NGFPs, ASN1, CRC, SysUtils, Classes, Windows *****)

procedure _SetSupportsPolyTableFiles(Value: Boolean = False);
begin
  NGFPTab.SupportsPolyTableFiles := Value;
end;

procedure _SetPolyTableFilePath(const Value: AnsiString = '');
begin
  NGFPTab.PolyTableFilePath := Value;
end;

//{$R P8248.res}   //  316 Class-Polynoms from Discriminant 0 upto  8248, 11.403 Bytes

exports
  _SetSupportsPolyTableFiles name 'NGFPTab_SetSupportsPolyTableFiles',
  _SetPolyTableFilePath      name 'NGFPTab_SetPolyTableFilePath';

(***** Hooks-Predeclared *****)

procedure _InitMemoryStringHooks(const NewHookRefs: THookRefs);
begin
  FPrimesIntf := nil;
  if not IsMemoryManagerSet then begin
    GetMemoryManager(OldHookRefs.MemoryManager);
  end;
  SetMemoryManager(NewHookRefs.MemoryManager);
  CurHookRefs := NewHookRefs;
end;

procedure _RemoveMemoryStringHooks;
begin
  FPrimesIntf := nil;
  if IsMemoryManagerSet then begin
    SetMemoryManager(OldHookRefs.MemoryManager);
  end;
end;

exports
  _InitMemoryStringHooks   name 'DECMath_InitMemoryStringHooks',
  _RemoveMemoryStringHooks name 'DECMath_RemoveMemoryStringHooks';

(***** WRAPPER *****)

procedure TSmallPrimeSieveIntf.BuildCache(const FileName: AnsiString; Bound: Cardinal);
begin
  //Result := inherited BuildCache;
  Prime.Primes.BuildCache(FileName, Bound);
end;

function TSmallPrimeSieveIntf.CacheMaxIndex: Cardinal;
begin
  //Result := inherited CacheMaxIndex;
  Result := Prime.Primes.CacheMaxIndex;
end;

function TSmallPrimeSieveIntf.CacheMaxPrime: Cardinal;
begin
  //Result := inherited CacheMaxPrime;
  Result := Prime.Primes.CacheMaxIndex;
end;                        

function TSmallPrimeSieveIntf.Count(LowerBound, UpperBound: Cardinal): Cardinal;
begin
  //Result := inherited Count;
  Result := Prime.Primes.Count(LowerBound, UpperBound);
end;

function TSmallPrimeSieveIntf.GetPrime(Index: Cardinal): Cardinal;
begin
  //Result := inherited Prime[Index];
  Result := Prime.Primes[Index];
end;

function TSmallPrimeSieveIntf.IndexOf(Value: Cardinal; LowerBound: Boolean = False): Cardinal;
begin
  //Result := inherited IndexOf;
  Result := Prime.Primes.IndexOf(Value, LowerBound);
end;

procedure TSmallPrimeSieveIntf.LoadCache(const FileName: AnsiString);
begin
  //Result := inherited LoadCache;
  Prime.Primes.LoadCache(FileName);
end;

function TSmallPrimeSieveIntf.MaxIndex: Cardinal;
begin
  Result := Prime.TSmallPrimeSieve.MaxIndex;
end;

function TSmallPrimeSieveIntf.MaxPrime: Cardinal;
begin
  Result := Prime.TSmallPrimeSieve.MaxPrime;
end;

function TSmallPrimeSieveIntf.MinIndex: Cardinal;
begin
  Result := Prime.TSmallPrimeSieve.MinIndex;
end;

function TSmallPrimeSieveIntf.MinPrime: Cardinal;
begin
  Result := Prime.TSmallPrimeSieve.MinPrime;
end;

begin
end.

