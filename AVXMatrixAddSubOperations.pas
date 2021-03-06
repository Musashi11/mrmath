// ###################################################################
// #### This file is part of the mathematics library project, and is
// #### offered under the licence agreement described on
// #### http://www.mrsoft.org/
// ####
// #### Copyright:(c) 2018, Michael R. . All rights reserved.
// ####
// #### Unless required by applicable law or agreed to in writing, software
// #### distributed under the License is distributed on an "AS IS" BASIS,
// #### WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// #### See the License for the specific language governing permissions and
// #### limitations under the License.
// ###################################################################


unit AVXMatrixAddSubOperations;

// ############################################################
// ##### Matrix addition/subtraction assembler optimized:
// ############################################################

interface

{$IFDEF CPUX64}
{$DEFINE x64}
{$ENDIF}
{$IFDEF cpux86_64}
{$DEFINE x64}
{$ENDIF}
{$IFNDEF x64}

uses MatrixConst;

procedure AVXMatrixAddAligned(dest : PDouble; const destLineWidth : TASMNativeInt; mt1, mt2 : PDouble; width : TASMNativeInt; height : TASMNativeInt; const LineWidth1, LineWidth2 : TASMNativeInt);
procedure AVXMatrixAddUnAligned(dest : PDouble; const destLineWidth : TASMNativeInt; mt1, mt2 : PDouble; width : TASMNativeInt; height : TASMNativeInt; const LineWidth1, LineWidth2 : TASMNativeInt);

procedure AVXMatrixSubAligned(dest : PDouble; const destLineWidth : TASMNativeInt; mt1, mt2 : PDouble; width : TASMNativeInt; height : TASMNativeInt; const LineWidth1, LineWidth2 : TASMNativeInt);
procedure AVXMatrixSubUnAligned(dest : PDouble; const destLineWidth : TASMNativeInt; mt1, mt2 : PDouble; width : TASMNativeInt; height : TASMNativeInt; const LineWidth1, LineWidth2 : TASMNativeInt);

procedure AVXMatrixSubT(A : PDouble; LineWidthA : TASMNativeInt; B : PDouble; LineWidthB : TASMNativeInt; width, height : TASMNativeInt);

procedure AVXMatrixSubVecAlignedVecRow(A : PDouble; LineWidthA : TASMNativeInt; B : PDouble; incX : TASMNativeInt; width, Height : TASMNativeInt);
procedure AVXMatrixSubVecAlignedRow(A : PDouble; LineWidthA : TASMNativeInt; B : PDouble; incX : TASMNativeInt; width, Height : TASMNativeInt);
procedure AVXMatrixSubVecAlignedCol(A : PDouble; LineWidthA : TASMNativeInt; B : PDouble; incX : TASMNativeInt; width, Height : TASMNativeInt);

procedure AVXMatrixSubVecUnalignedVecRow(A : PDouble; LineWidthA : TASMNativeInt; B : PDouble; incX : TASMNativeInt; width, Height : TASMNativeInt);
procedure AVXMatrixSubVecUnalignedRow(A : PDouble; LineWidthA : TASMNativeInt; B : PDouble; incX : TASMNativeInt; width, Height : TASMNativeInt);
procedure AVXMatrixSubVecUnalignedCol(A : PDouble; LineWidthA : TASMNativeInt; B : PDouble; incX : TASMNativeInt; width, Height : TASMNativeInt);

procedure AVXMatrixAddVecAlignedVecRow(A : PDouble; LineWidthA : TASMNativeInt; B : PDouble; incX : TASMNativeInt; width, Height : TASMNativeInt);
procedure AVXMatrixAddVecAlignedRow(A : PDouble; LineWidthA : TASMNativeInt; B : PDouble; incX : TASMNativeInt; width, Height : TASMNativeInt);
procedure AVXMatrixAddVecAlignedCol(A : PDouble; LineWidthA : TASMNativeInt; B : PDouble; incX : TASMNativeInt; width, Height : TASMNativeInt);

procedure AVXMatrixAddVecUnalignedVecRow(A : PDouble; LineWidthA : TASMNativeInt; B : PDouble; incX : TASMNativeInt; width, Height : TASMNativeInt);
procedure AVXMatrixAddVecUnalignedRow(A : PDouble; LineWidthA : TASMNativeInt; B : PDouble; incX : TASMNativeInt; width, Height : TASMNativeInt);
procedure AVXMatrixAddVecUnalignedCol(A : PDouble; LineWidthA : TASMNativeInt; B : PDouble; incX : TASMNativeInt; width, Height : TASMNativeInt);

{$ENDIF}

implementation

{$IFNDEF x64}

{$IFDEF FPC} {$ASMMODE intel} {$S-} {$ENDIF}

procedure AVXMatrixAddAligned(dest : PDouble; const destLineWidth : TASMNativeInt; mt1, mt2 : PDouble; width : TASMNativeInt; height : TASMNativeInt; const LineWidth1, LineWidth2 : TASMNativeInt);
var iters : TASMNativeInt;
begin
asm
   push ebx;
   push esi;
   push edi;

   //iters := -width*sizeof(double);
   mov eax, width;
   imul eax, -8;
   mov iters, eax;

   // helper registers for the mt1, mt2 and dest pointers
   mov ecx, dest;
   mov edi, mt2;
   mov esi, mt1;

   sub esi, eax;
   sub edi, eax;
   sub ecx, eax;

   // for y := 0 to height - 1:
   mov ebx, Height;
   @@addforyloop:
       // for x := 0 to w - 1;
       // prepare for reverse loop
       mov eax, iters;
       @addforxloop:
           add eax, 128;
           jg @loopEnd;

           // prefetch data...
           // prefetch [esi + eax];
           // prefetch [edi + eax];

           // addition:
           {$IFDEF FPC}vmovapd ymm0, [esi + eax - 128];{$ELSE}db $C5,$FD,$28,$44,$06,$80;{$ENDIF} 
           {$IFDEF FPC}vaddpd ymm0, ymm0, [edi + eax - 128];{$ELSE}db $C5,$FD,$58,$44,$07,$80;{$ENDIF} 

           {$IFDEF FPC}vmovapd ymm1, [esi + eax - 96];{$ELSE}db $C5,$FD,$28,$4C,$06,$A0;{$ENDIF} 
           {$IFDEF FPC}vaddpd ymm1, ymm1, [edi + eax - 96];{$ELSE}db $C5,$F5,$58,$4C,$07,$A0;{$ENDIF} 

           {$IFDEF FPC}vmovapd ymm2, [esi + eax - 64];{$ELSE}db $C5,$FD,$28,$54,$06,$C0;{$ENDIF} 
           {$IFDEF FPC}vaddpd ymm2, ymm2, [edi + eax - 64];{$ELSE}db $C5,$ED,$58,$54,$07,$C0;{$ENDIF} 

           {$IFDEF FPC}vmovapd ymm3, [esi + eax - 32];{$ELSE}db $C5,$FD,$28,$5C,$06,$E0;{$ENDIF} 
           {$IFDEF FPC}vaddpd ymm3, ymm3, [edi + eax - 32];{$ELSE}db $C5,$E5,$58,$5C,$07,$E0;{$ENDIF} 

           {$IFDEF FPC}vmovapd [ecx + eax - 128], ymm0;{$ELSE}db $C5,$FD,$29,$44,$01,$80;{$ENDIF} 
           {$IFDEF FPC}vmovapd [ecx + eax - 96], ymm1;{$ELSE}db $C5,$FD,$29,$4C,$01,$A0;{$ENDIF} 
           {$IFDEF FPC}vmovapd [ecx + eax - 64], ymm2;{$ELSE}db $C5,$FD,$29,$54,$01,$C0;{$ENDIF} 
           {$IFDEF FPC}vmovapd [ecx + eax - 32], ymm3;{$ELSE}db $C5,$FD,$29,$5C,$01,$E0;{$ENDIF} 
       jmp @addforxloop

       @loopEnd:

       sub eax, 128;

       jz @nextLine;

       @addforxloop2:
           add eax, 16;
           jg @loopEnd2;
           {$IFDEF FPC}vmovapd xmm0, [esi + eax - 16];{$ELSE}db $C5,$F9,$28,$44,$06,$F0;{$ENDIF} 
           {$IFDEF FPC}vaddpd xmm0, xmm0, [edi + eax - 16];{$ELSE}db $C5,$F9,$58,$44,$07,$F0;{$ENDIF} 

           {$IFDEF FPC}vmovapd [ecx + eax - 16], xmm0;{$ELSE}db $C5,$F9,$29,$44,$01,$F0;{$ENDIF} 
       jmp @addforxloop2;

       @loopEnd2:

       sub eax, 16;
       jz @nextLine;

       {$IFDEF FPC}vmovsd xmm0, [esi - 8];{$ELSE}db $C5,$FB,$10,$46,$F8;{$ENDIF} 
       {$IFDEF FPC}vmovsd xmm1, [edi - 8];{$ELSE}db $C5,$FB,$10,$4F,$F8;{$ENDIF} 
       {$IFDEF FPC}vaddsd xmm0, xmm0, xmm1;{$ELSE}db $C5,$FB,$58,$C1;{$ENDIF} 
       {$IFDEF FPC}vmovsd [ecx - 8], xmm0;{$ELSE}db $C5,$FB,$11,$41,$F8;{$ENDIF} 

       @nextLine:

       // next line:
       add esi, LineWidth1;
       add edi, LineWidth2;
       add ecx, destLineWidth;

   // loop y end
   dec ebx;
   jnz @@addforyloop;

   // epilog
   {$IFDEF FPC}vzeroupper;{$ELSE}db $C5,$F8,$77;{$ENDIF} 

   pop edi;
   pop esi;
   pop ebx;
end;
end;

procedure AVXMatrixAddUnAligned(dest : PDouble; const destLineWidth : TASMNativeInt; mt1, mt2 : PDouble; width : TASMNativeInt; height : TASMNativeInt; const LineWidth1, LineWidth2 : TASMNativeInt);
var iters : TASMNativeInt;
begin
asm
   push ebx;
   push esi;
   push edi;

   //iters := -width*sizeof(double);
   mov eax, width;
   imul eax, -8;
   mov iters, eax;

   // helper registers for the mt1, mt2 and dest pointers
   mov ecx, dest;
   mov edi, mt2;
   mov esi, mt1;

   sub esi, eax;
   sub edi, eax;
   sub ecx, eax;

   // for y := 0 to height - 1:
   mov ebx, Height;
   @@addforyloop:
       // for x := 0 to w - 1;
       // prepare for reverse loop
       mov eax, iters;
       @addforxloop:
           add eax, 128;
           jg @loopEnd;

           // prefetch data...
           // prefetch [esi + eax];
           // prefetch [edi + eax];

           // addition:
           {$IFDEF FPC}vmovupd ymm0, [esi + eax - 128];{$ELSE}db $C5,$FD,$10,$44,$06,$80;{$ENDIF} 
           {$IFDEF FPC}vmovupd ymm1, [edi + eax - 128];{$ELSE}db $C5,$FD,$10,$4C,$07,$80;{$ENDIF} 
           {$IFDEF FPC}vaddpd ymm0, ymm0, ymm1;{$ELSE}db $C5,$FD,$58,$C1;{$ENDIF} 
           {$IFDEF FPC}vmovupd [ecx + eax - 128], ymm0;{$ELSE}db $C5,$FD,$11,$44,$01,$80;{$ENDIF} 

           {$IFDEF FPC}vmovupd ymm0, [esi + eax - 96];{$ELSE}db $C5,$FD,$10,$44,$06,$A0;{$ENDIF} 
           {$IFDEF FPC}vmovupd ymm1, [edi + eax - 96];{$ELSE}db $C5,$FD,$10,$4C,$07,$A0;{$ENDIF} 
           {$IFDEF FPC}vaddpd ymm0, ymm0, ymm1;{$ELSE}db $C5,$FD,$58,$C1;{$ENDIF} 
           {$IFDEF FPC}vmovupd [ecx + eax - 96], ymm0;{$ELSE}db $C5,$FD,$11,$44,$01,$A0;{$ENDIF} 

           {$IFDEF FPC}vmovupd ymm0, [esi + eax - 64];{$ELSE}db $C5,$FD,$10,$44,$06,$C0;{$ENDIF} 
           {$IFDEF FPC}vmovupd ymm1, [edi + eax - 64];{$ELSE}db $C5,$FD,$10,$4C,$07,$C0;{$ENDIF} 
           {$IFDEF FPC}vaddpd ymm0, ymm0, ymm1;{$ELSE}db $C5,$FD,$58,$C1;{$ENDIF} 
           {$IFDEF FPC}vmovupd [ecx + eax - 64], ymm0;{$ELSE}db $C5,$FD,$11,$44,$01,$C0;{$ENDIF} 

           {$IFDEF FPC}vmovupd ymm0, [esi + eax - 32];{$ELSE}db $C5,$FD,$10,$44,$06,$E0;{$ENDIF} 
           {$IFDEF FPC}vmovupd ymm1, [edi + eax - 32];{$ELSE}db $C5,$FD,$10,$4C,$07,$E0;{$ENDIF} 
           {$IFDEF FPC}vaddpd ymm0, ymm0, ymm1;{$ELSE}db $C5,$FD,$58,$C1;{$ENDIF} 
           {$IFDEF FPC}vmovupd [ecx + eax - 32], ymm0;{$ELSE}db $C5,$FD,$11,$44,$01,$E0;{$ENDIF} 

       jmp @addforxloop

       @loopEnd:

       sub eax, 128;

       jz @nextLine;

       @addforxloop2:
           add eax, 16;
           jg @loopEnd2;

           {$IFDEF FPC}vmovupd xmm0, [esi + eax - 16];{$ELSE}db $C5,$F9,$10,$44,$06,$F0;{$ENDIF} 
           {$IFDEF FPC}vmovupd xmm1, [edi + eax - 16];{$ELSE}db $C5,$F9,$10,$4C,$07,$F0;{$ENDIF} 
           {$IFDEF FPC}vaddpd xmm0, xmm0, xmm1;{$ELSE}db $C5,$F9,$58,$C1;{$ENDIF} 

           {$IFDEF FPC}vmovupd [ecx + eax - 16], xmm0;{$ELSE}db $C5,$F9,$11,$44,$01,$F0;{$ENDIF} 
       jmp @addforxloop2;

       @loopEnd2:

       sub eax, 16;
       jz @nextLine;

       {$IFDEF FPC}vmovsd xmm0, [esi - 8];{$ELSE}db $C5,$FB,$10,$46,$F8;{$ENDIF} 
       {$IFDEF FPC}vmovsd xmm1, [edi - 8];{$ELSE}db $C5,$FB,$10,$4F,$F8;{$ENDIF} 
       {$IFDEF FPC}vaddsd xmm0, xmm0, xmm1;{$ELSE}db $C5,$FB,$58,$C1;{$ENDIF} 
       {$IFDEF FPC}vmovsd [ecx - 8], xmm0;{$ELSE}db $C5,$FB,$11,$41,$F8;{$ENDIF} 

       @nextLine:

       // next line:
       add esi, LineWidth1;
       add edi, LineWidth2;
       add ecx, destLineWidth;

   // loop y end
   dec ebx;
   jnz @@addforyloop;

   // epilog
   {$IFDEF FPC}vzeroupper;{$ELSE}db $C5,$F8,$77;{$ENDIF} 

   pop edi;
   pop esi;
   pop ebx;
end;
end;

procedure AVXMatrixSubAligned(dest : PDouble; const destLineWidth : TASMNativeInt; mt1, mt2 : PDouble; width : TASMNativeInt; height : TASMNativeInt; const LineWidth1, LineWidth2 : TASMNativeInt);
var iters : TASMNativeInt;
begin
asm
   push ebx;
   push esi;
   push edi;

   //iters := -width*sizeof(double);
   mov eax, width;
   imul eax, -8;
   mov iters, eax;

   // helper registers for the mt1, mt2 and dest pointers
   mov ecx, dest;
   mov edi, mt2;
   mov esi, mt1;

   sub esi, eax;
   sub edi, eax;
   sub ecx, eax;

   // for y := 0 to height - 1:
   mov ebx, Height;
   @@addforyloop:
       // for x := 0 to w - 1;
       // prepare for reverse loop
       mov eax, iters;
       @addforxloop:
           add eax, 128;
           jg @loopEnd;

           // prefetch data...
           // prefetch [esi + eax];
           // prefetch [edi + eax];

           // addition:
           {$IFDEF FPC}vmovapd ymm0, [esi + eax - 128];{$ELSE}db $C5,$FD,$28,$44,$06,$80;{$ENDIF} 
           {$IFDEF FPC}vsubpd ymm0, ymm0, [edi + eax - 128];{$ELSE}db $C5,$FD,$5C,$44,$07,$80;{$ENDIF} 

           {$IFDEF FPC}vmovapd ymm1, [esi + eax - 96];{$ELSE}db $C5,$FD,$28,$4C,$06,$A0;{$ENDIF} 
           {$IFDEF FPC}vsubpd ymm1, ymm1, [edi + eax - 96];{$ELSE}db $C5,$F5,$5C,$4C,$07,$A0;{$ENDIF} 

           {$IFDEF FPC}vmovapd ymm2, [esi + eax - 64];{$ELSE}db $C5,$FD,$28,$54,$06,$C0;{$ENDIF} 
           {$IFDEF FPC}vsubpd ymm2, ymm2, [edi + eax - 64];{$ELSE}db $C5,$ED,$5C,$54,$07,$C0;{$ENDIF} 

           {$IFDEF FPC}vmovapd ymm3, [esi + eax - 32];{$ELSE}db $C5,$FD,$28,$5C,$06,$E0;{$ENDIF} 
           {$IFDEF FPC}vsubpd ymm3, ymm3, [edi + eax - 32];{$ELSE}db $C5,$E5,$5C,$5C,$07,$E0;{$ENDIF} 

           {$IFDEF FPC}vmovapd [ecx + eax - 128], ymm0;{$ELSE}db $C5,$FD,$29,$44,$01,$80;{$ENDIF} 
           {$IFDEF FPC}vmovapd [ecx + eax - 96], ymm1;{$ELSE}db $C5,$FD,$29,$4C,$01,$A0;{$ENDIF} 
           {$IFDEF FPC}vmovapd [ecx + eax - 64], ymm2;{$ELSE}db $C5,$FD,$29,$54,$01,$C0;{$ENDIF} 
           {$IFDEF FPC}vmovapd [ecx + eax - 32], ymm3;{$ELSE}db $C5,$FD,$29,$5C,$01,$E0;{$ENDIF} 
       jmp @addforxloop

       @loopEnd:

       sub eax, 128;

       jz @nextLine;

       @addforxloop2:
           add eax, 16;
           jg @loopEnd2;

           {$IFDEF FPC}vmovapd xmm0, [esi + eax - 16];{$ELSE}db $C5,$F9,$28,$44,$06,$F0;{$ENDIF} 
           {$IFDEF FPC}vsubpd xmm0, xmm0, [edi + eax - 16];{$ELSE}db $C5,$F9,$5C,$44,$07,$F0;{$ENDIF} 

           {$IFDEF FPC}vmovapd [ecx + eax - 16], xmm0;{$ELSE}db $C5,$F9,$29,$44,$01,$F0;{$ENDIF} 
       jmp @addforxloop2;

       @loopEnd2:

       sub eax, 16;
       jz @nextLine;

       {$IFDEF FPC}vmovsd xmm0, [esi - 8];{$ELSE}db $C5,$FB,$10,$46,$F8;{$ENDIF} 
       {$IFDEF FPC}vmovsd xmm1, [edi - 8];{$ELSE}db $C5,$FB,$10,$4F,$F8;{$ENDIF} 
       {$IFDEF FPC}vsubsd xmm0, xmm0, xmm1;{$ELSE}db $C5,$FB,$5C,$C1;{$ENDIF} 
       {$IFDEF FPC}vmovsd [ecx - 8], xmm0;{$ELSE}db $C5,$FB,$11,$41,$F8;{$ENDIF} 

       @nextLine:

       // update pointers
       add esi, LineWidth1;
       add edi, LineWidth2;
       add ecx, destLineWidth;

   // loop y end
   dec ebx;
   jnz @@addforyloop;

   // epilog
   {$IFDEF FPC}vzeroupper;{$ELSE}db $C5,$F8,$77;{$ENDIF} 

   pop edi;
   pop esi;
   pop ebx;
end;
end;

procedure AVXMatrixSubUnAligned(dest : PDouble; const destLineWidth : TASMNativeInt; mt1, mt2 : PDouble; width : TASMNativeInt; height : TASMNativeInt; const LineWidth1, LineWidth2 : TASMNativeInt);
var iters : TASMNativeInt;
begin
asm
   push ebx;
   push esi;
   push edi;

   //iters := -width*sizeof(double);
   mov eax, width;
   imul eax, -8;
   mov iters, eax;

   // helper registers for the mt1, mt2 and dest pointers
   mov ecx, dest;
   mov edi, mt2;
   mov esi, mt1;

   sub esi, eax;
   sub edi, eax;
   sub ecx, eax;

   // for y := 0 to height - 1:
   mov ebx, Height;
   @@addforyloop:
       // for x := 0 to w - 1;
       // prepare for reverse loop
       mov eax, iters;
       @addforxloop:
           add eax, 128;
           jg @loopEnd;

           // prefetch data...
           // prefetch [esi + eax];
           // prefetch [edi + eax];

           // addition:
           {$IFDEF FPC}vmovupd ymm0, [esi + eax - 128];{$ELSE}db $C5,$FD,$10,$44,$06,$80;{$ENDIF} 
           {$IFDEF FPC}vmovupd ymm1, [edi + eax - 128];{$ELSE}db $C5,$FD,$10,$4C,$07,$80;{$ENDIF} 
           {$IFDEF FPC}vsubpd ymm0, ymm0, ymm1;{$ELSE}db $C5,$FD,$5C,$C1;{$ENDIF} 
           {$IFDEF FPC}vmovupd [ecx + eax - 128], ymm0;{$ELSE}db $C5,$FD,$11,$44,$01,$80;{$ENDIF} 

           {$IFDEF FPC}vmovupd ymm0, [esi + eax - 96];{$ELSE}db $C5,$FD,$10,$44,$06,$A0;{$ENDIF} 
           {$IFDEF FPC}vmovupd ymm1, [edi + eax - 96];{$ELSE}db $C5,$FD,$10,$4C,$07,$A0;{$ENDIF} 
           {$IFDEF FPC}vsubpd ymm0, ymm0, ymm1;{$ELSE}db $C5,$FD,$5C,$C1;{$ENDIF} 
           {$IFDEF FPC}vmovupd [ecx + eax - 96], ymm0;{$ELSE}db $C5,$FD,$11,$44,$01,$A0;{$ENDIF} 

           {$IFDEF FPC}vmovupd ymm0, [esi + eax - 64];{$ELSE}db $C5,$FD,$10,$44,$06,$C0;{$ENDIF} 
           {$IFDEF FPC}vmovupd ymm1, [edi + eax - 64];{$ELSE}db $C5,$FD,$10,$4C,$07,$C0;{$ENDIF} 
           {$IFDEF FPC}vsubpd ymm0, ymm0, ymm1;{$ELSE}db $C5,$FD,$5C,$C1;{$ENDIF} 
           {$IFDEF FPC}vmovupd [ecx + eax - 64], ymm0;{$ELSE}db $C5,$FD,$11,$44,$01,$C0;{$ENDIF} 

           {$IFDEF FPC}vmovupd ymm0, [esi + eax - 32];{$ELSE}db $C5,$FD,$10,$44,$06,$E0;{$ENDIF} 
           {$IFDEF FPC}vmovupd ymm1, [edi + eax - 32];{$ELSE}db $C5,$FD,$10,$4C,$07,$E0;{$ENDIF} 
           {$IFDEF FPC}vsubpd ymm0, ymm0, ymm1;{$ELSE}db $C5,$FD,$5C,$C1;{$ENDIF} 
           {$IFDEF FPC}vmovupd [ecx + eax - 32], ymm0;{$ELSE}db $C5,$FD,$11,$44,$01,$E0;{$ENDIF} 

       jmp @addforxloop

       @loopEnd:

       sub eax, 128;

       jz @nextLine;

       @addforxloop2:
           add eax, 16;
           jg @loopEnd2;

           {$IFDEF FPC}vmovupd xmm0, [esi + eax - 16];{$ELSE}db $C5,$F9,$10,$44,$06,$F0;{$ENDIF} 
           {$IFDEF FPC}vmovupd xmm1, [edi + eax - 16];{$ELSE}db $C5,$F9,$10,$4C,$07,$F0;{$ENDIF} 
           {$IFDEF FPC}vsubpd xmm0, xmm0, xmm1;{$ELSE}db $C5,$F9,$5C,$C1;{$ENDIF} 

           {$IFDEF FPC}vmovupd [ecx + eax - 16], xmm0;{$ELSE}db $C5,$F9,$11,$44,$01,$F0;{$ENDIF} 
       jmp @addforxloop2;

       @loopEnd2:

       sub eax, 16;
       jz @nextLine;

       {$IFDEF FPC}vmovsd xmm0, [esi - 8];{$ELSE}db $C5,$FB,$10,$46,$F8;{$ENDIF} 
       {$IFDEF FPC}vmovsd xmm1, [edi - 8];{$ELSE}db $C5,$FB,$10,$4F,$F8;{$ENDIF} 
       {$IFDEF FPC}vsubsd xmm0, xmm0, xmm1;{$ELSE}db $C5,$FB,$5C,$C1;{$ENDIF} 
       {$IFDEF FPC}vmovsd [ecx - 8], xmm0;{$ELSE}db $C5,$FB,$11,$41,$F8;{$ENDIF} 

       @nextLine:

       // next line:
       add esi, LineWidth1;
       add edi, LineWidth2;
       add ecx, destLineWidth;

   // loop y end
   dec ebx;
   jnz @@addforyloop;

   // epilog
   {$IFDEF FPC}vzeroupper;{$ELSE}db $C5,$F8,$77;{$ENDIF} 

   pop edi;
   pop esi;
   pop ebx;
end;
end;

procedure AVXMatrixSubT(A : PDouble; LineWidthA : TASMNativeInt; B : PDouble; LineWidthB : TASMNativeInt; width, height : TASMNativeInt);
begin
asm
   push esi;
   push edi;
   push ebx;

   // eax: iter := -width*sizeof(double)
   mov ecx, A;
   mov eax, width;
   imul eax, -8;
   sub ecx, eax;

   mov esi, B;
   mov edx, LineWidthB;

   // for y := 0 to height - 1
   @@foryloop:
      mov edi, esi;
      mov ebx, eax;

      // for x := 0 to width - 1
      @@forxloop:
         {$IFDEF FPC}vmovsd xmm0, [ecx + ebx];{$ELSE}db $C5,$FB,$10,$04,$19;{$ENDIF} 
         {$IFDEF FPC}vmovsd xmm1, [edi];{$ELSE}db $C5,$FB,$10,$0F;{$ENDIF} 
         {$IFDEF FPC}vsubsd xmm0, xmm0, xmm1;{$ELSE}db $C5,$FB,$5C,$C1;{$ENDIF} 
         {$IFDEF FPC}vmovsd [ecx + ebx], xmm0;{$ELSE}db $C5,$FB,$11,$04,$19;{$ENDIF} 

         add edi, edx;
      add ebx, 8;
      jnz @@forxloop;

      add ecx, LineWidthA;
      add esi, 8;
   dec height;
   jnz @@foryloop;

   // epilog
   {$IFDEF FPC}vzeroupper;{$ELSE}db $C5,$F8,$77;{$ENDIF} 

   pop ebx;
   pop edi;
   pop esi;
end;
end;

// ########################################################
// #### Matrix add, sub to vector operations
// ########################################################

procedure AVXMatrixSubVecAlignedVecRow(A : PDouble; LineWidthA : TASMNativeInt; B : PDouble; incX : TASMNativeInt; width, Height : TASMNativeInt);
begin
     asm
        push ebx;

        mov ebx, width;
        imul ebx, -8;

        mov ecx, A;
        mov edx, B;

        sub ecx, ebx;
        sub edx, ebx;

        @@foryloop:
           mov eax, ebx;

           @@forxloopUnrolled:
              add eax, 64;
              jg @@EndLoop1;

              {$IFDEF FPC}vmovapd ymm0, [ecx + eax - 64];{$ELSE}db $C5,$FD,$28,$44,$01,$C0;{$ENDIF} 
              {$IFDEF FPC}vsubpd ymm0, ymm0, [edx + eax - 64];{$ELSE}db $C5,$FD,$5C,$44,$02,$C0;{$ENDIF} 
              {$IFDEF FPC}vmovapd [ecx + eax - 64], ymm0;{$ELSE}db $C5,$FD,$29,$44,$01,$C0;{$ENDIF} 

              {$IFDEF FPC}vmovapd ymm2, [ecx + eax - 32];{$ELSE}db $C5,$FD,$28,$54,$01,$E0;{$ENDIF} 
              {$IFDEF FPC}vsubpd ymm2, ymm2, [edx + eax - 32];{$ELSE}db $C5,$ED,$5C,$54,$02,$E0;{$ENDIF} 
              {$IFDEF FPC}vmovapd [ecx + eax - 32], ymm2;{$ELSE}db $C5,$FD,$29,$54,$01,$E0;{$ENDIF} 

           jmp @@forxloopUnrolled;

           @@EndLoop1:

           sub eax, 64;

           jz @NextLine;

           @@forxloop:
              {$IFDEF FPC}vmovsd xmm0, [ecx + eax];{$ELSE}db $C5,$FB,$10,$04,$01;{$ENDIF} 
              {$IFDEF FPC}vmovsd xmm1, [edx + eax];{$ELSE}db $C5,$FB,$10,$0C,$02;{$ENDIF} 

              {$IFDEF FPC}vsubsd xmm0, xmm0, xmm1;{$ELSE}db $C5,$FB,$5C,$C1;{$ENDIF} 
              {$IFDEF FPC}vmovsd [ecx + eax], xmm0;{$ELSE}db $C5,$FB,$11,$04,$01;{$ENDIF} 

              add eax, 8;
           jnz @@forxloop;

           @NextLine:

           add ecx, LineWidthA;
        dec Height;
        jnz @@foryloop;

        {$IFDEF FPC}vzeroupper;{$ELSE}db $C5,$F8,$77;{$ENDIF} 

        pop ebx;
     end;
end;

procedure AVXMatrixSubVecAlignedRow(A : PDouble; LineWidthA : TASMNativeInt; B : PDouble; incX : TASMNativeInt; width, Height : TASMNativeInt);
var vecIter : integer;
begin
     asm
        push ebx;
        push edi;
        push esi;

        mov edi, incx;
        mov esi, width;

        imul esi, edi;
        imul esi, -1;
        mov vecIter, esi;

        mov ebx, width;
        imul ebx, -8;

        mov ecx, A;
        mov edx, B;

        sub ecx, ebx;
        sub edx, esi;

        @@foryloop:
           mov eax, ebx;
           mov esi, vecIter;

           @@forxloop:
              {$IFDEF FPC}vmovsd xmm0, [ecx + eax];{$ELSE}db $C5,$FB,$10,$04,$01;{$ENDIF} 
              {$IFDEF FPC}vmovsd xmm1, [edx + esi];{$ELSE}db $C5,$FB,$10,$0C,$32;{$ENDIF} 

              {$IFDEF FPC}vsubsd xmm0, xmm0, xmm1;{$ELSE}db $C5,$FB,$5C,$C1;{$ENDIF} 
              {$IFDEF FPC}vmovsd [ecx + eax], xmm0;{$ELSE}db $C5,$FB,$11,$04,$01;{$ENDIF} 

              add esi, edi;
              add eax, 8;
           jnz @@forxloop;

           @NextLine:

           add ecx, LineWidthA;
        dec Height;
        jnz @@foryloop;

        {$IFDEF FPC}vzeroupper;{$ELSE}db $C5,$F8,$77;{$ENDIF} 

        pop esi;
        pop edi;
        pop ebx;
     end;
end;

procedure AVXMatrixSubVecAlignedCol(A : PDouble; LineWidthA : TASMNativeInt; B : PDouble; incX : TASMNativeInt; width, Height : TASMNativeInt);
begin
     asm
        push ebx;

        mov ebx, width;
        imul ebx, -8;

        mov ecx, A;
        mov edx, B;

        sub ecx, ebx;

        @@foryloop:
           mov eax, ebx;

           {$IFDEF FPC}vbroadcastsd ymm1, [edx];{$ELSE}db $C4,$E2,$7D,$19,$0A;{$ENDIF} 

           @@forxloopUnrolled:
              add eax, 64;
              jg @@EndLoop1;

              {$IFDEF FPC}vmovapd ymm0, [ecx + eax - 64];{$ELSE}db $C5,$FD,$28,$44,$01,$C0;{$ENDIF} 
              {$IFDEF FPC}vsubpd ymm0, ymm0, ymm1;{$ELSE}db $C5,$FD,$5C,$C1;{$ENDIF} 
              {$IFDEF FPC}vmovapd [ecx + eax - 64], ymm0;{$ELSE}db $C5,$FD,$29,$44,$01,$C0;{$ENDIF} 

              {$IFDEF FPC}vmovapd ymm2, [ecx + eax - 32];{$ELSE}db $C5,$FD,$28,$54,$01,$E0;{$ENDIF} 
              {$IFDEF FPC}vsubpd ymm2, ymm2, ymm1;{$ELSE}db $C5,$ED,$5C,$D1;{$ENDIF} 
              {$IFDEF FPC}vmovapd [ecx + eax - 32], ymm2;{$ELSE}db $C5,$FD,$29,$54,$01,$E0;{$ENDIF} 

           jmp @@forxloopUnrolled;

           @@EndLoop1:

           sub eax, 64;

           jz @NextLine;

           @@forxloop:
              {$IFDEF FPC}vmovsd xmm0, [ecx + eax];{$ELSE}db $C5,$FB,$10,$04,$01;{$ENDIF} 

              {$IFDEF FPC}vsubsd xmm0, xmm0, xmm1;{$ELSE}db $C5,$FB,$5C,$C1;{$ENDIF} 
              {$IFDEF FPC}vmovsd [ecx + eax], xmm0;{$ELSE}db $C5,$FB,$11,$04,$01;{$ENDIF} 

              add eax, 8;
           jnz @@forxloop;

           @NextLine:

           add ecx, LineWidthA;
           add edx, incX;
        dec Height;
        jnz @@foryloop;

        {$IFDEF FPC}vzeroupper;{$ELSE}db $C5,$F8,$77;{$ENDIF} 

        pop ebx;
     end;
end;

procedure AVXMatrixSubVecUnalignedVecRow(A : PDouble; LineWidthA : TASMNativeInt; B : PDouble; incX : TASMNativeInt; width, Height : TASMNativeInt);
begin
     asm
        push ebx;

        mov ebx, width;
        imul ebx, -8;

        mov ecx, A;
        mov edx, B;

        sub ecx, ebx;
        sub edx, ebx;

        @@foryloop:
           mov eax, ebx;

           @@forxloopUnrolled:
              add eax, 64;
              jg @@EndLoop1;

              {$IFDEF FPC}vmovupd ymm0, [ecx + eax - 64];{$ELSE}db $C5,$FD,$10,$44,$01,$C0;{$ENDIF} 
              {$IFDEF FPC}vmovupd ymm1, [edx + eax - 64];{$ELSE}db $C5,$FD,$10,$4C,$02,$C0;{$ENDIF} 
              {$IFDEF FPC}vsubpd ymm0, ymm0, ymm1;{$ELSE}db $C5,$FD,$5C,$C1;{$ENDIF} 
              {$IFDEF FPC}vmovupd [ecx + eax - 64], ymm0;{$ELSE}db $C5,$FD,$11,$44,$01,$C0;{$ENDIF} 

              {$IFDEF FPC}vmovupd ymm2, [ecx + eax - 32];{$ELSE}db $C5,$FD,$10,$54,$01,$E0;{$ENDIF} 
              {$IFDEF FPC}vmovupd ymm3, [edx + eax - 32];{$ELSE}db $C5,$FD,$10,$5C,$02,$E0;{$ENDIF} 
              {$IFDEF FPC}vsubpd ymm2, ymm2, ymm3;{$ELSE}db $C5,$ED,$5C,$D3;{$ENDIF} 
              {$IFDEF FPC}vmovupd [ecx + eax - 32], ymm2;{$ELSE}db $C5,$FD,$11,$54,$01,$E0;{$ENDIF} 

           jmp @@forxloopUnrolled;

           @@EndLoop1:

           sub eax, 64;

           jz @NextLine;

           @@forxloop:
              {$IFDEF FPC}vmovsd xmm0, [ecx + eax];{$ELSE}db $C5,$FB,$10,$04,$01;{$ENDIF} 
              {$IFDEF FPC}vmovsd xmm1, [edx + eax];{$ELSE}db $C5,$FB,$10,$0C,$02;{$ENDIF} 

              {$IFDEF FPC}vsubsd xmm0, xmm0, xmm1;{$ELSE}db $C5,$FB,$5C,$C1;{$ENDIF} 
              {$IFDEF FPC}vmovsd [ecx + eax], xmm0;{$ELSE}db $C5,$FB,$11,$04,$01;{$ENDIF} 

              add eax, 8;
           jnz @@forxloop;

           @NextLine:

           add ecx, LineWidthA;
        dec Height;
        jnz @@foryloop;

        {$IFDEF FPC}vzeroupper;{$ELSE}db $C5,$F8,$77;{$ENDIF} 

        pop ebx;
     end;
end;

procedure AVXMatrixSubVecUnalignedRow(A : PDouble; LineWidthA : TASMNativeInt; B : PDouble; incX : TASMNativeInt; width, Height : TASMNativeInt);
var vecIter : integer;
begin
     asm
        push ebx;
        push edi;
        push esi;

        mov edi, incx;
        mov esi, width;

        imul esi, edi;
        imul esi, -1;
        mov vecIter, esi;

        mov ebx, width;
        imul ebx, -8;

        mov ecx, A;
        mov edx, B;

        sub ecx, ebx;
        sub edx, esi;

        @@foryloop:
           mov eax, ebx;
           mov esi, vecIter;

           @@forxloop:
              {$IFDEF FPC}vmovsd xmm0, [ecx + eax];{$ELSE}db $C5,$FB,$10,$04,$01;{$ENDIF} 
              {$IFDEF FPC}vmovsd xmm1, [edx + esi];{$ELSE}db $C5,$FB,$10,$0C,$32;{$ENDIF} 

              {$IFDEF FPC}vsubsd xmm0, xmm0, xmm1;{$ELSE}db $C5,$FB,$5C,$C1;{$ENDIF} 
              {$IFDEF FPC}vmovsd [ecx + eax], xmm0;{$ELSE}db $C5,$FB,$11,$04,$01;{$ENDIF} 

              add esi, edi;
              add eax, 8;
           jnz @@forxloop;

           add ecx, LineWidthA;
        dec Height;
        jnz @@foryloop;

        {$IFDEF FPC}vzeroupper;{$ELSE}db $C5,$F8,$77;{$ENDIF} 

        pop esi;
        pop edi;
        pop ebx;
     end;
end;

procedure AVXMatrixSubVecUnalignedCol(A : PDouble; LineWidthA : TASMNativeInt; B : PDouble; incX : TASMNativeInt; width, Height : TASMNativeInt);
begin
     asm
        push ebx;

        mov ebx, width;
        imul ebx, -8;

        mov ecx, A;
        mov edx, B;

        sub ecx, ebx;

        @@foryloop:
           mov eax, ebx;

           {$IFDEF FPC}vbroadcastsd ymm1, [edx];{$ELSE}db $C4,$E2,$7D,$19,$0A;{$ENDIF} 

           @@forxloopUnrolled:
              add eax, 64;
              jg @@EndLoop1;

              {$IFDEF FPC}vmovupd ymm0, [ecx + eax - 64];{$ELSE}db $C5,$FD,$10,$44,$01,$C0;{$ENDIF} 
              {$IFDEF FPC}vsubpd ymm0, ymm0, ymm1;{$ELSE}db $C5,$FD,$5C,$C1;{$ENDIF} 
              {$IFDEF FPC}vmovupd [ecx + eax - 64], ymm0;{$ELSE}db $C5,$FD,$11,$44,$01,$C0;{$ENDIF} 

              {$IFDEF FPC}vmovupd ymm2, [ecx + eax - 32];{$ELSE}db $C5,$FD,$10,$54,$01,$E0;{$ENDIF} 
              {$IFDEF FPC}vsubpd ymm2, ymm2, ymm1;{$ELSE}db $C5,$ED,$5C,$D1;{$ENDIF} 
              {$IFDEF FPC}vmovupd [ecx + eax - 32], ymm2;{$ELSE}db $C5,$FD,$11,$54,$01,$E0;{$ENDIF} 

           jmp @@forxloopUnrolled;

           @@EndLoop1:

           sub eax, 64;

           jz @NextLine;

           @@forxloop:
              {$IFDEF FPC}vmovsd xmm0, [ecx + eax];{$ELSE}db $C5,$FB,$10,$04,$01;{$ENDIF} 

              {$IFDEF FPC}vsubsd xmm0, xmm0, xmm1;{$ELSE}db $C5,$FB,$5C,$C1;{$ENDIF} 
              {$IFDEF FPC}vmovsd [ecx + eax], xmm0;{$ELSE}db $C5,$FB,$11,$04,$01;{$ENDIF} 

              add eax, 8;
           jnz @@forxloop;

           @NextLine:

           add ecx, LineWidthA;
           add edx, incX;
        dec Height;
        jnz @@foryloop;

        {$IFDEF FPC}vzeroupper;{$ELSE}db $C5,$F8,$77;{$ENDIF} 

        pop ebx;
     end;
end;


procedure AVXMatrixAddVecAlignedVecRow(A : PDouble; LineWidthA : TASMNativeInt; B : PDouble; incX : TASMNativeInt; width, Height : TASMNativeInt);
begin
     asm
        push ebx;

        mov ebx, width;
        imul ebx, -8;

        mov ecx, A;
        mov edx, B;

        sub ecx, ebx;
        sub edx, ebx;

        @@foryloop:
           mov eax, ebx;

           @@forxloopUnrolled:
              add eax, 64;
              jg @@EndLoop1;

              {$IFDEF FPC}vmovapd ymm0, [ecx + eax - 64];{$ELSE}db $C5,$FD,$28,$44,$01,$C0;{$ENDIF} 
              {$IFDEF FPC}vaddpd ymm0, ymm0, [edx + eax - 64];{$ELSE}db $C5,$FD,$58,$44,$02,$C0;{$ENDIF} 
              {$IFDEF FPC}vmovapd [ecx + eax - 64], ymm0;{$ELSE}db $C5,$FD,$29,$44,$01,$C0;{$ENDIF} 

              {$IFDEF FPC}vmovapd ymm2, [ecx + eax - 32];{$ELSE}db $C5,$FD,$28,$54,$01,$E0;{$ENDIF} 
              {$IFDEF FPC}vaddpd ymm2, ymm2, [edx + eax - 32];{$ELSE}db $C5,$ED,$58,$54,$02,$E0;{$ENDIF} 
              {$IFDEF FPC}vmovapd [ecx + eax - 32], ymm2;{$ELSE}db $C5,$FD,$29,$54,$01,$E0;{$ENDIF} 

           jmp @@forxloopUnrolled;

           @@EndLoop1:

           sub eax, 64;

           jz @NextLine;

           @@forxloop:
              {$IFDEF FPC}vmovsd xmm0, [ecx + eax];{$ELSE}db $C5,$FB,$10,$04,$01;{$ENDIF} 
              {$IFDEF FPC}vmovsd xmm1, [edx + eax];{$ELSE}db $C5,$FB,$10,$0C,$02;{$ENDIF} 

              {$IFDEF FPC}vaddsd xmm0, xmm0, xmm1;{$ELSE}db $C5,$FB,$58,$C1;{$ENDIF} 
              {$IFDEF FPC}vmovsd [ecx + eax], xmm0;{$ELSE}db $C5,$FB,$11,$04,$01;{$ENDIF} 

              add eax, 8;
           jnz @@forxloop;

           @NextLine:

           add ecx, LineWidthA;
        dec Height;
        jnz @@foryloop;

        {$IFDEF FPC}vzeroupper;{$ELSE}db $C5,$F8,$77;{$ENDIF} 

        pop ebx;
     end;
end;

procedure AVXMatrixAddVecAlignedRow(A : PDouble; LineWidthA : TASMNativeInt; B : PDouble; incX : TASMNativeInt; width, Height : TASMNativeInt);
var vecIter : integer;
begin
     asm
        push ebx;
        push edi;
        push esi;

        mov edi, incx;
        mov esi, width;

        imul esi, edi;
        imul esi, -1;
        mov vecIter, esi;

        mov ebx, width;
        imul ebx, -8;

        mov ecx, A;
        mov edx, B;

        sub ecx, ebx;
        sub edx, esi;

        @@foryloop:
           mov eax, ebx;
           mov esi, vecIter;

           @@forxloop:
              {$IFDEF FPC}vmovsd xmm0, [ecx + eax];{$ELSE}db $C5,$FB,$10,$04,$01;{$ENDIF} 
              {$IFDEF FPC}vmovsd xmm1, [edx + esi];{$ELSE}db $C5,$FB,$10,$0C,$32;{$ENDIF} 

              {$IFDEF FPC}vaddsd xmm0, xmm0, xmm1;{$ELSE}db $C5,$FB,$58,$C1;{$ENDIF} 
              {$IFDEF FPC}vmovsd [ecx + eax], xmm0;{$ELSE}db $C5,$FB,$11,$04,$01;{$ENDIF} 

              add esi, edi;
              add eax, 8;
           jnz @@forxloop;

           add ecx, LineWidthA;
        dec Height;
        jnz @@foryloop;

        {$IFDEF FPC}vzeroupper;{$ELSE}db $C5,$F8,$77;{$ENDIF} 

        pop esi;
        pop edi;
        pop ebx;
     end;
end;

procedure AVXMatrixAddVecAlignedCol(A : PDouble; LineWidthA : TASMNativeInt; B : PDouble; incX : TASMNativeInt; width, Height : TASMNativeInt);
begin
     asm
        push ebx;

        mov ebx, width;
        imul ebx, -8;

        mov ecx, A;
        mov edx, B;

        sub ecx, ebx;

        @@foryloop:
           mov eax, ebx;

           {$IFDEF FPC}vbroadcastsd ymm1, [edx];{$ELSE}db $C4,$E2,$7D,$19,$0A;{$ENDIF} 

           @@forxloopUnrolled:
              add eax, 64;
              jg @@EndLoop1;

              {$IFDEF FPC}vmovapd ymm0, [ecx + eax - 64];{$ELSE}db $C5,$FD,$28,$44,$01,$C0;{$ENDIF} 
              {$IFDEF FPC}vaddpd ymm0, ymm0, ymm1;{$ELSE}db $C5,$FD,$58,$C1;{$ENDIF} 
              {$IFDEF FPC}vmovapd [ecx + eax - 64], ymm0;{$ELSE}db $C5,$FD,$29,$44,$01,$C0;{$ENDIF} 

              {$IFDEF FPC}vmovapd ymm2, [ecx + eax - 32];{$ELSE}db $C5,$FD,$28,$54,$01,$E0;{$ENDIF} 
              {$IFDEF FPC}vaddpd ymm2, ymm2, ymm1;{$ELSE}db $C5,$ED,$58,$D1;{$ENDIF} 
              {$IFDEF FPC}vmovapd [ecx + eax - 32], ymm2;{$ELSE}db $C5,$FD,$29,$54,$01,$E0;{$ENDIF} 

           jmp @@forxloopUnrolled;

           @@EndLoop1:

           sub eax, 64;

           jz @NextLine;

           @@forxloop:
              {$IFDEF FPC}vmovsd xmm0, [ecx + eax];{$ELSE}db $C5,$FB,$10,$04,$01;{$ENDIF} 

              {$IFDEF FPC}vaddsd xmm0, xmm0, xmm1;{$ELSE}db $C5,$FB,$58,$C1;{$ENDIF} 
              {$IFDEF FPC}vmovsd [ecx + eax], xmm0;{$ELSE}db $C5,$FB,$11,$04,$01;{$ENDIF} 

              add eax, 8;
           jnz @@forxloop;

           @NextLine:

           add ecx, LineWidthA;
           add edx, incX;
        dec Height;
        jnz @@foryloop;

        {$IFDEF FPC}vzeroupper;{$ELSE}db $C5,$F8,$77;{$ENDIF} 

        pop ebx;
     end;
end;

procedure AVXMatrixAddVecUnalignedVecRow(A : PDouble; LineWidthA : TASMNativeInt; B : PDouble; incX : TASMNativeInt; width, Height : TASMNativeInt);
begin
     asm
        push ebx;

        mov ebx, width;
        imul ebx, -8;

        mov ecx, A;
        mov edx, B;

        sub ecx, ebx;
        sub edx, ebx;

        @@foryloop:
           mov eax, ebx;

           @@forxloopUnrolled:
              add eax, 64;
              jg @@EndLoop1;

              {$IFDEF FPC}vmovupd ymm0, [ecx + eax - 64];{$ELSE}db $C5,$FD,$10,$44,$01,$C0;{$ENDIF} 
              {$IFDEF FPC}vmovupd ymm1, [edx + eax - 64];{$ELSE}db $C5,$FD,$10,$4C,$02,$C0;{$ENDIF} 
              {$IFDEF FPC}vaddpd ymm0, ymm0, ymm1;{$ELSE}db $C5,$FD,$58,$C1;{$ENDIF} 
              {$IFDEF FPC}vmovupd [ecx + eax - 64], ymm0;{$ELSE}db $C5,$FD,$11,$44,$01,$C0;{$ENDIF} 

              {$IFDEF FPC}vmovupd ymm2, [ecx + eax - 32];{$ELSE}db $C5,$FD,$10,$54,$01,$E0;{$ENDIF} 
              {$IFDEF FPC}vmovupd ymm3, [edx + eax - 32];{$ELSE}db $C5,$FD,$10,$5C,$02,$E0;{$ENDIF} 
              {$IFDEF FPC}vaddpd ymm2, ymm2, ymm3;{$ELSE}db $C5,$ED,$58,$D3;{$ENDIF} 
              {$IFDEF FPC}vmovupd [ecx + eax - 32], ymm2;{$ELSE}db $C5,$FD,$11,$54,$01,$E0;{$ENDIF} 

           jmp @@forxloopUnrolled;

           @@EndLoop1:

           sub eax, 64;

           jz @NextLine;

           @@forxloop:
              {$IFDEF FPC}vmovsd xmm0, [ecx + eax];{$ELSE}db $C5,$FB,$10,$04,$01;{$ENDIF} 
              {$IFDEF FPC}vmovsd xmm1, [edx + eax];{$ELSE}db $C5,$FB,$10,$0C,$02;{$ENDIF} 

              {$IFDEF FPC}vaddsd xmm0, xmm0, xmm1;{$ELSE}db $C5,$FB,$58,$C1;{$ENDIF} 
              {$IFDEF FPC}vmovsd [ecx + eax], xmm0;{$ELSE}db $C5,$FB,$11,$04,$01;{$ENDIF} 

              add eax, 8;
           jnz @@forxloop;

           @NextLine:

           add ecx, LineWidthA;
        dec Height;
        jnz @@foryloop;

        {$IFDEF FPC}vzeroupper;{$ELSE}db $C5,$F8,$77;{$ENDIF} 

        pop ebx;
     end;
end;

procedure AVXMatrixAddVecUnalignedRow(A : PDouble; LineWidthA : TASMNativeInt; B : PDouble; incX : TASMNativeInt; width, Height : TASMNativeInt);
var vecIter : integer;
begin
     asm
        push ebx;
        push edi;
        push esi;

        mov edi, incx;
        mov esi, width;

        imul esi, edi;
        imul esi, -1;
        mov vecIter, esi;

        mov ebx, width;
        imul ebx, -8;

        mov ecx, A;
        mov edx, B;

        sub ecx, ebx;
        sub edx, esi;

        @@foryloop:
           mov eax, ebx;
           mov esi, vecIter;

           @@forxloop:
              {$IFDEF FPC}vmovsd xmm0, [ecx + eax];{$ELSE}db $C5,$FB,$10,$04,$01;{$ENDIF} 
              {$IFDEF FPC}vmovsd xmm1, [edx + esi];{$ELSE}db $C5,$FB,$10,$0C,$32;{$ENDIF} 

              {$IFDEF FPC}vaddsd xmm0, xmm0, xmm1;{$ELSE}db $C5,$FB,$58,$C1;{$ENDIF} 
              {$IFDEF FPC}vmovsd [ecx + eax], xmm0;{$ELSE}db $C5,$FB,$11,$04,$01;{$ENDIF} 

              add esi, edi;
              add eax, 8;
           jnz @@forxloop;

           add ecx, LineWidthA;
        dec Height;
        jnz @@foryloop;

        {$IFDEF FPC}vzeroupper;{$ELSE}db $C5,$F8,$77;{$ENDIF} 

        pop esi;
        pop edi;
        pop ebx;
     end;
end;

procedure AVXMatrixAddVecUnalignedCol(A : PDouble; LineWidthA : TASMNativeInt; B : PDouble; incX : TASMNativeInt; width, Height : TASMNativeInt);
begin
     asm
        push ebx;

        mov ebx, width;
        imul ebx, -8;

        mov ecx, A;
        mov edx, B;

        sub ecx, ebx;

        @@foryloop:
           mov eax, ebx;

           {$IFDEF FPC}vbroadcastsd ymm1, [edx];{$ELSE}db $C4,$E2,$7D,$19,$0A;{$ENDIF} 

           @@forxloopUnrolled:
              add eax, 64;
              jg @@EndLoop1;

              {$IFDEF FPC}vmovupd ymm0, [ecx + eax - 64];{$ELSE}db $C5,$FD,$10,$44,$01,$C0;{$ENDIF} 
              {$IFDEF FPC}vaddpd ymm0, ymm0, ymm1;{$ELSE}db $C5,$FD,$58,$C1;{$ENDIF} 
              {$IFDEF FPC}vmovupd [ecx + eax - 64], ymm0;{$ELSE}db $C5,$FD,$11,$44,$01,$C0;{$ENDIF} 

              {$IFDEF FPC}vmovupd ymm2, [ecx + eax - 32];{$ELSE}db $C5,$FD,$10,$54,$01,$E0;{$ENDIF} 
              {$IFDEF FPC}vaddpd ymm2, ymm2, ymm1;{$ELSE}db $C5,$ED,$58,$D1;{$ENDIF} 
              {$IFDEF FPC}vmovupd [ecx + eax - 32], ymm2;{$ELSE}db $C5,$FD,$11,$54,$01,$E0;{$ENDIF} 

           jmp @@forxloopUnrolled;

           @@EndLoop1:

           sub eax, 64;

           jz @NextLine;

           @@forxloop:
              {$IFDEF FPC}vmovsd xmm0, [ecx + eax];{$ELSE}db $C5,$FB,$10,$04,$01;{$ENDIF} 

              {$IFDEF FPC}vaddsd xmm0, xmm0, xmm1;{$ELSE}db $C5,$FB,$58,$C1;{$ENDIF} 
              {$IFDEF FPC}vmovsd [ecx + eax], xmm0;{$ELSE}db $C5,$FB,$11,$04,$01;{$ENDIF} 

              add eax, 8;
           jnz @@forxloop;

           @NextLine:

           add ecx, LineWidthA;
           add edx, incX;
        dec Height;
        jnz @@foryloop;

        {$IFDEF FPC}vzeroupper;{$ELSE}db $C5,$F8,$77;{$ENDIF} 

        pop ebx;
     end;
end;

{$ENDIF}

end.
