{Copyright:      Hagen Reddmann  HaReddmann at T-Online dot de
 Author:         Hagen Reddmann
 Remarks:        Shareware, this Copyright must be included
 known Problems: none
 Version:        5.1, Delphi Encryption Compendium
                 Delphi 2-6, BCB 3-4, designed and testet under D3-6
 Description:    ASN.1 protocoll base routines

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
unit ASN1;

interface

uses Classes, SysUtils;

type
  EASN1 = class(Exception);

procedure ASN1_ChangeEndian(var Buffer; Size: LongInt);
function  ASN1_SwapEndian(Value: Integer): Integer; overload;
function  ASN1_SwapEndian(Value: Cardinal): Cardinal; overload;
function  ASN1_SwapEndian(Value: Word): Word; overload;
function  ASN1_CalcLen(var Len: LongInt): Byte;
function  ASN1_WriteLen(Stream: TStream; Len: LongInt): LongInt;
function  ASN1_ReadLen(Stream: TStream): LongInt;
function  ASN1_WriteStr(Stream: TStream; const Value: String): LongInt;
function  ASN1_ReadStr(Stream: TStream): String;
function  ASN1_WriteWStr(Stream: TStream; const Value: WideString): LongInt;
function  ASN1_ReadWStr(Stream: TStream): WideString;
function  ASN1_WriteBuf(Stream: TStream; const Buffer; Size: LongInt): LongInt;
function  ASN1_ReadBuf(Stream: TStream; var Buffer; Size: LongInt): LongInt;

var
  ASN1_Integer: Byte = $02;  // Tag for asn1 integer

implementation

// only <= 4 Bytes asn1 Length are supported
// we follow Borland Style and use LongInt for compatibility to TStream

procedure ASN1_ChangeEndian(var Buffer; Size: Integer); assembler; register;
// not fast, but easy
asm
       CMP    EDX,1
       JLE    @@3
       AND    EAX,EAX
       JZ     @@3
       PUSH   EBX
       MOV    ECX,EDX
       LEA    EDX,[EAX + ECX -1]
       SHR    ECX,1
@@1:   MOV    BL,[EAX]
       XCHG   BL,[EDX]
       DEC    EDX
       MOV    [EAX],BL
       INC    EAX
       DEC    ECX
       JNZ    @@1
@@2:   POP    EBX
@@3:
end;

function ASN1_SwapEndian(Value: Integer): Integer;
asm
       BSWAP  EAX
end;

function ASN1_SwapEndian(Value: Cardinal): Cardinal;
asm
       BSWAP  EAX
end;

function ASN1_SwapEndian(Value: Word): Word;
asm
       XCHG   AL,AH
end;

procedure ASN1_Raise(Msg: PResStringRec);
resourcestring
  sASN1LenCoding = 'Invalid ASN1 Length encoded Tag detected.';
var
  ErrorAddr: Pointer;
begin
  asm
       MOV   EAX,[EBP + 8]
       SUB   EAX,4
       MOV   ErrorAddr,EAX
  end;
  raise EASN1.Create(LoadResString(Msg)) at ErrorAddr;
end;

procedure ASN1_RaiseLen;
resourcestring
  sASN1LenCoding = 'Invalid ASN1 Length encoded Tag detected';
begin
  ASN1_Raise(@sASN1LenCoding);
end;

procedure ASN1_RaiseWrite;
resourcestring
  sASN1Writing = 'ASN1 stream write error';
begin
  ASN1_Raise(@sASN1Writing);
end;

procedure ASN1_RaiseRead;
resourcestring
  sASN1Reading = 'ASN1 stream read error';
begin
  ASN1_Raise(@sASN1Reading);
end;

function ASN1_CalcLen(var Len: LongInt): Byte;
begin
  if Len < 0 then ASN1_RaiseLen;
  if Len > $7F then
  begin
    if Len and $FFFFFF00 = 0 then Result := 1 else
      if Len and $FFFF0000 = 0 then Result := 2 else
        if Len and $FF000000 = 0 then Result := 3
          else Result := 4;
    ASN1_ChangeEndian(Len, Result);
    Result := Result or $80;
  end else Result := Len;
end;

function ASN1_WriteLen(Stream: TStream; Len: LongInt): LongInt;
var
  B: Byte;
begin
  B := ASN1_CalcLen(Len);
  if Stream.Write(B, SizeOf(B)) <> SizeOf(B) then ASN1_RaiseWrite;
  if B and $80 <> 0 then
  begin
    B := B and $7F;
    if Stream.Write(Len, B) <> B then ASN1_RaiseWrite;
    Result := B + SizeOf(B);
  end else Result := SizeOf(B);
end;

function ASN1_ReadLen(Stream: TStream): LongInt;
var
  B: Byte;
begin
  Result := 0;
  if Stream.Read(B, SizeOf(B)) <> SizeOf(B) then ASN1_RaiseRead;
  if B and $80 <> 0 then
  begin
    B := B and $7F;
    if B > 4 then ASN1_RaiseLen;
    if B > 0 then
    begin
      if Stream.Read(Result, B) <> B then ASN1_RaiseRead;
      ASN1_ChangeEndian(Result, B);
      if Result < 0 then ASN1_RaiseLen;
    end else Result := Stream.Size - Stream.Position;
  end else Result := B;
end;

function ASN1_WriteStr(Stream: TStream; const Value: String): LongInt;
var
  I: LongInt;
begin
  I := Length(Value);
  Result := ASN1_WriteLen(Stream, I) + I;
  if Stream.Write(PChar(Value)^, I) <> I then ASN1_RaiseWrite;
end;

function ASN1_ReadStr(Stream: TStream): String;
var
  I: LongInt;
begin
  I := ASN1_ReadLen(Stream);
  SetLength(Result, I);
  if Stream.Read(PChar(Result)^, I) <> I then ASN1_RaiseRead;
end;

function ASN1_WriteWStr(Stream: TStream; const Value: WideString): LongInt;
var
  I: LongInt;
begin
  I := Length(Value) * 2;
  Result := ASN1_WriteLen(Stream, I) + I;
  if Stream.Write(Pointer(Value)^, I) <> I then ASN1_RaiseWrite;
end;

function ASN1_ReadWStr(Stream: TStream): WideString;
var
  I: LongInt;
begin
  I := ASN1_ReadLen(Stream);
  SetLength(Result, I);
  if Stream.Read(Pointer(Result)^, I) <> I then ASN1_RaiseRead;
end;

function ASN1_WriteBuf(Stream: TStream; const Buffer; Size: LongInt): LongInt;
begin
  Result := ASN1_WriteLen(Stream, Size) + Size;
  if Stream.Write(Buffer, Size) <> Size then ASN1_RaiseWrite;
end;

function ASN1_ReadBuf(Stream: TStream; var Buffer; Size: LongInt): LongInt;
begin
  Result := ASN1_ReadLen(Stream);
  if Result > Size then ASN1_RaiseRead;
  if Stream.Read(Buffer, Result) <> Result then ASN1_RaiseRead;
end;

end.
