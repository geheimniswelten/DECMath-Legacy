Delphi Encryption Compendium
Version 5.1
Part I & II
Copyright (c) Hagen Reddmann
HaReddmann at t-online dot de
Delphi 5,6,7

Datei:  DEC_5_1.zip

Installation:
- download DEC_5_1.zip
- entpacke Datei mit Ordnern in zb. d:\dec\
- sicherstellen das der Compiler keinen Zugriff auf alte DEC Installationen mehr hat
- Delphi starten und je nach Version zb. für D5 im Ordner d:\dec\d5\ arbeiten


Copyrights:

Part I ist weiterhin Freeware mit Sourcen. Im Ordner \DEC\Part_I\ findet man die Sourcen.

Part II, bekannt unter dem Namen DECMath ist keine Freeware und in dieser Distributation für private und akademische Zwecke verwendbar. Alles ausserhalb dieses Rahmens muß mit dem Autor schriftlich vereinbart werden.
Private Zwecke bedeutet im Klartext das man in einer privaten Freeware an der keinerlei Profit gemacht wird den Part II benutzen darf. Eine Weitergabe der kompilierten Units oder der Datei DECMath.dcp ist aber untersagt bzw. muß mit mir vorher abgesprochen werden. Die Weitergabe der Datei DECMath.bpl ist aber im Zusammenhang mit der eigenen Freeware erlaubt.

WICHTIG UND BITTE DREIMAL LESEN !
Part II ist nicht im vollständigen Source enthalten, es ist eine binäre vorkompilierte Version und die enthaltenen Source Dateien im Ordner LibIntf sind geschnittene Interface Sektionen der originalen Sourcen, als Dokumentation. Sie können nicht recompiled werden !!

Ich bitte hiermit um Verständis das ich diesen Distributationsweg eingeschlagen habe, da ansich eine Veröffentlichung vom Part II nicht geplant war. Auf Anfrage im Forum der Delphi Praxis habe ich mich denoch entschlossen diesen Weg einzuschlagen. Ansonsten ist die precompiled Version vom Part II voll funktionsfähig und ohne weitere Einschränkungen.



Inhalt:

\dec\D5\                - prekompilierte Delphi 5 Version mit Demos
\dec\D6\                - prekompilierte Delphi 6 Version mit Demos
\dec\D7\                - prekompilierte Delphi 7 Version mit Demos

\dec\Part_I\            - Sourcen vom Part I
\dec\Part_I\DECTest\    - Test-/Demoprogram zum Part I, Überprüfung-/Speedtests der symmetrischen Algorithmen

\dec\Part_II\           - freie Sourcen IsPrimeHRUnit.pas, NCombi.pas, NInt_1.pas
\dec\Part_II\LibIntf\   - Interfaces der PASCAL Sourcen vom Part II, nicht kompilierbar dienen als Dokumentation

In den einzelenen Ordnern der prekompilierten Versionen finden sich

\DECTest\               - Test-/Demoprogram zum Part I, Überprüfung-/Speedtests der symmetrischen Algorithmen
\Demo\                  - Part II, DECMath Demo
\Factorial\             - Part II, Demo zur schnellen Berechnung verschiedener kombinatorischer Aufgaben mit dem DECMath.




Die PASCAL Dateien im einzelnen:

Part I:

DECUtil.pas             - Basis Unit des DECs, enthält grundlegene Utilities
DECHash.pas             - Hash Algorithmen, TDECHash & Derivate
DECHash.inc             - Include für DECHash.pas, Assemblerroutinen für die Hashalgos.
DECCipher.pas           - sym. Verschlüsselungen, TDECCipher & Derivate
DECData.pas             - gemeinsam durch DECHash/DECCipher benutzte Lookup Tabellen
DECFmt.pas              - Datenkonvertierungen
DECRandom.pas           - installierbarer Yarrow Zufallsgenerator, kryptographisch sicher

ASN1.pas                - einige ASN1 Utility Function
CPU.pas                 - CPU Utility Function, Ermittlung der CPU und CPU Taktfrequenz, hilfreich fürs Profiling
CRC.pas                 - Cyclic Redundance Checksums, unterstützt jede Art der CRCs in GF(2)
LHSZ.pas                - Stand Alone Komprimierungsfunktionen mit Verschlüsselung und Prüfsummen, LZW und Huffman,
                          optimiert auf minimalste Codegröße und Speicherverbrauch im BSS/DATA Segment. Ideal für kompakte
                          selbstextrahierende Archive.
TypeInfoEx.pas          - ermittelt alle TypInfos, sprich RTTIs eines Modules, dynamisch
Ver.inc                 - Standard Include zur Verwaltung/bedingten Kompilierung in Delphi



Part I enthält nachfolgende Algortihmen:

8 Konvertierungen:

TFormat_HEX             - Hexadezimal Uppercase
TFormat_HEXL            - Hexadezimal Lowercase
TFormat_MIME32          - Internet MIME Base 32
TFormat_MIME64          - Internet MIME Base 64    
TFormat_PGP             - PGP mit PGP-prohibitärer Prüfsumme
TFormat_UU              - UNIX UU Format
TFormat_XX              - UNIX XX Format
TFormat_ESCAPE          - Escaped

26 Hashalgorithmen

THash_MD2               - MD2  
THash_MD4               - MD4
THash_MD5               - MD5
THash_SHA               - SHA
THash_SHA1              - SHA 1
THash_SHA256            - SHA 256 bit 
THash_SHA384            - SHA 384 bit
THash_SHA512            - SHA 512 bit
THash_Sapphire          - Sapphire
THash_Panama            - Panama
THash_Tiger             - Tiger
THash_RipeMD128         - RIPE MD 128 bit 
THash_RipeMD160         - RIPE MD 160 bit
THash_RipeMD256         - RIPE MD 256 bit
THash_RipeMD320         - RIPE MD 320 bit
THash_Haval128          - Haval 128 Bit
THash_Haval160          - Haval 160 Bit
THash_Haval192          - Haval 192 Bit
THash_Haval224          - Haval 224 Bit
THash_Haval256          - Haval 256 Bit
THash_Whirlpool         - Whirlpool
THash_Whirlpool1        - Whirlpool 1
THash_Square            - Square
THash_Snefru128         - Snefru 128 Bit 
THash_Snefru256         - Snefru 256 Bit

Die Hashalgortihmen unterstützen verschiedene KDFs = Key Derivation Functions und MGFs = Mask Generation Functions.
Maximale Datengröße ist 2^192-1 Bits.


30 sym. Verschlüsselungen

TCipher_Blowfish        - Blowfish
TCipher_Twofish         - Twofish
TCipher_IDEA            - IDEA, attention patented 
TCipher_Cast256         - Cast 256 
TCipher_Mars            - Mars, IBM 
TCipher_RC4             - RC4, Rivest
TCipher_RC6             - RC6, Rivest
TCipher_Rijndael        - Rijndael, AES Winner 
TCipher_Square          - Square
TCipher_SCOP            - SCOP, fast streamcipher 
TCipher_Sapphire        - Sapphire 
TCipher_1DES            - any DES variant
TCipher_2DES
TCipher_3DES
TCipher_2DDES
TCipher_3DDES
TCipher_3TDES
TCipher_3Way            - 3 Way 
TCipher_Cast128         - Cast 128
TCipher_Gost            - Gost, russian GOV
TCipher_Misty           - Misty
TCipher_NewDES          - NewDES, attention no DES dependencies
TCipher_Q128            - Q128  
TCipher_RC2             - RC2, Rivest 
TCipher_RC5             - RC5, Rivest
TCipher_SAFER           - SAFER & SAFER SK any variants
TCipher_Shark           - Shark
TCipher_Skipjack        - Skipjack 
TCipher_TEA             - TEA, very small
TCipher_TEAN            - TEA new

Die sym. Cipher unterstützen die Cipher Modis:

CTSx = double CBC, with CFS8 padding of truncated final block
CBCx = Cipher Block Chainung, with CFB8 padding of truncated final block
CFB8 = 8bit Cipher Feedback mode
CFBx = CFB on Blocksize of Cipher
OFB8 = 8bit Output Feedback mode
OFBx = OFB on Blocksize bytes
CFS8 = 8Bit CFS, double CFB
CFSx = CFS on Blocksize bytes
ECBx = Electronic Code Book




Part II:

IsPrimeHRUnit.pas       - sehr effiziente Ermittlung ob eine Zahl < 2^32 eine Primzahl ist
NCombi.pas              - kombinatorische Funktionen, enthält alle bekanten Algorithmen zur Berechnung der Fakultät.
                          Fakultät, Produkt, Binomial, Primorial, Permutation, Comporial
NInt_1.pas              - transzendale Konstanten wie Ln2, Ln10, ArcTan, ArcTanh, Cos, Sin, Exp und Pi. Alles natürlich mit
                          großer Auflösung und exakter Genauigkeit.

Nachfolgende Dateien aus dem Ordner \LibIntf\ sind PASCAL Dateien die ohne deren Implementation sind:

NMath.pas               - Basis Funktionen für das Speicher-/Computationmanagament vom DECMath
NInts.pas               - vorzeichenbehaftete supergroße Ganzzahlen -> IInteger und alle notwenigen Funktionen
NRats.pas               - gebrochene Zahlen -> IRational, Bruchrechnungen
NPolys.pas              - modulare Polynome, werden zur Erzeugung/Faktorization eigener Eliptischer Kurven benötigt
NGFPs.pas               - Elliptische Kurven über GF(p) nach der Weierstrass Form y^2 = x^3 + ax + b
NGFPBld.pas             - Erzeugung Elliptischer Kurven nach dem Standard P1363
NGFPTab.pas             - Utility zur Speicherung von vorberechneten irreduciblen Class Polynoms die zur Erzeugung von ECC nötig
                          sind
IDPrimes.pas            - ID basierte Primzahlen Erzeugnung, diese werden besonders in Kryptosystemen basierend auf dem
                          Logarithmusproblem hilfreich sein. Ermöglichen die Verifizierung der Nicht-Speziellen-Form einer
                          Primzahl
Prime.pas               - schnelles Sieb zur Erzeugung aller Primzahlen bis 2^32, wird zb. in NInts.pas benötigt zur 
                          Trial Division, Primzahl Erzeugung
NIntM.pas               - Modulare Cardinals


Wer in DECMath reinschnuppern möchte beginnt am besten mit der DEMO. Dazu startet er nach dem Entpacken seine bevorzugte Delphi Version und öffnet zb. für Delphi 5 die Datei \DEC\D5\Demo\Test.bpg. In der Datei TestUnit.pas finden sich dann Einiges an Beispielen im Umgang mit den IInteger, IRational und IGPF. Enthalten ist auch eine vollständige Implementirung des Secure Remote Password Protocolls basierend auf SRP-6 allerdings mit Verbesserungen.
Demonstriert werden Schlüsselaustausch nach Diffie Hellman DH in Z(p) == IInteger und GF(p) == Elliptische Kurven.
Die Verschlüsselung nach PSEC (Japanischer Standard) mit Hilfe von Elliptischen Kurven.
Die RSA Verschlüsselung und auch 2 Varianten wie man RSA wieder knacken kann, bzw. der technische Beweis das RSA immer unsicher sein muß wenn man die RSA Schlüsselerzeugung nicht 100%'tig unter Kontrolle hat, zb. bei TrustCentern, MS CryptoAPI, SmartCards.

Im Ordner \Factorial\ findet man eine fertige Anwendung mit der man zb. die Fakultät einer Zahl ausrechnen kann.


Gruß Hagen


   










