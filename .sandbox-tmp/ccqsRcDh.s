	.file	"voice_allocator.cpp"
	.text
.Ltext0:
	.file 0 "/home/synth/projects/05-active-dev/open-synth/build-debug" "/home/synth/projects/05-active-dev/open-synth/dsp/voice_allocator.cpp"
	.section	.text._ZNK9opensynth8Envelope5stateEv,"axG",@progbits,_ZNK9opensynth8Envelope5stateEv,comdat
	.align 2
	.weak	_ZNK9opensynth8Envelope5stateEv
	.hidden	_ZNK9opensynth8Envelope5stateEv
	.type	_ZNK9opensynth8Envelope5stateEv, @function
_ZNK9opensynth8Envelope5stateEv:
.LFB2027:
	.file 1 "/home/synth/projects/05-active-dev/open-synth/include/envelope.h"
	.loc 1 35 11
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	movq	%rdi, -8(%rbp)
	.loc 1 35 34
	movq	-8(%rbp), %rax
	movl	(%rax), %eax
	.loc 1 35 42
	popq	%rbp
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE2027:
	.size	_ZNK9opensynth8Envelope5stateEv, .-_ZNK9opensynth8Envelope5stateEv
	.section	.text._ZN9opensynth8EnvelopeC2Ev,"axG",@progbits,_ZN9opensynth8EnvelopeC5Ev,comdat
	.align 2
	.weak	_ZN9opensynth8EnvelopeC2Ev
	.hidden	_ZN9opensynth8EnvelopeC2Ev
	.type	_ZN9opensynth8EnvelopeC2Ev, @function
_ZN9opensynth8EnvelopeC2Ev:
.LFB2104:
	.loc 1 18 5
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	movq	%rdi, -8(%rbp)
.LBB10:
	.loc 1 18 5
	movq	-8(%rbp), %rax
	movl	$0, (%rax)
	movq	-8(%rbp), %rax
	pxor	%xmm0, %xmm0
	movss	%xmm0, 4(%rax)
	movq	-8(%rbp), %rax
	pxor	%xmm0, %xmm0
	movss	%xmm0, 8(%rax)
	movq	-8(%rbp), %rax
	movss	.LC1(%rip), %xmm0
	movss	%xmm0, 12(%rax)
	movq	-8(%rbp), %rax
	movss	.LC2(%rip), %xmm0
	movss	%xmm0, 16(%rax)
	movq	-8(%rbp), %rax
	movss	.LC3(%rip), %xmm0
	movss	%xmm0, 20(%rax)
	movq	-8(%rbp), %rax
	movss	.LC4(%rip), %xmm0
	movss	%xmm0, 24(%rax)
	movq	-8(%rbp), %rax
	pxor	%xmm0, %xmm0
	movss	%xmm0, 28(%rax)
	movq	-8(%rbp), %rax
	pxor	%xmm0, %xmm0
	movss	%xmm0, 32(%rax)
	movq	-8(%rbp), %rax
	pxor	%xmm0, %xmm0
	movss	%xmm0, 36(%rax)
	movq	-8(%rbp), %rax
	movl	$0, 40(%rax)
	movq	-8(%rbp), %rax
	movl	$0, 44(%rax)
	movq	-8(%rbp), %rax
	movl	$0, 48(%rax)
.LBE10:
	nop
	popq	%rbp
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE2104:
	.size	_ZN9opensynth8EnvelopeC2Ev, .-_ZN9opensynth8EnvelopeC2Ev
	.weak	_ZN9opensynth8EnvelopeC1Ev
	.hidden	_ZN9opensynth8EnvelopeC1Ev
	.set	_ZN9opensynth8EnvelopeC1Ev,_ZN9opensynth8EnvelopeC2Ev
	.section	.text._ZN9opensynth11FilterStateC2Ev,"axG",@progbits,_ZN9opensynth11FilterStateC5Ev,comdat
	.align 2
	.weak	_ZN9opensynth11FilterStateC2Ev
	.hidden	_ZN9opensynth11FilterStateC2Ev
	.type	_ZN9opensynth11FilterStateC2Ev, @function
_ZN9opensynth11FilterStateC2Ev:
.LFB2107:
	.file 2 "/home/synth/projects/05-active-dev/open-synth/include/filter.h"
	.loc 2 18 8
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	movq	%rdi, -8(%rbp)
.LBB11:
	.loc 2 18 8
	movq	-8(%rbp), %rax
	pxor	%xmm0, %xmm0
	movss	%xmm0, (%rax)
	movq	-8(%rbp), %rax
	pxor	%xmm0, %xmm0
	movss	%xmm0, 4(%rax)
	movq	-8(%rbp), %rax
	pxor	%xmm0, %xmm0
	movss	%xmm0, 8(%rax)
.LBE11:
	nop
	popq	%rbp
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE2107:
	.size	_ZN9opensynth11FilterStateC2Ev, .-_ZN9opensynth11FilterStateC2Ev
	.weak	_ZN9opensynth11FilterStateC1Ev
	.hidden	_ZN9opensynth11FilterStateC1Ev
	.set	_ZN9opensynth11FilterStateC1Ev,_ZN9opensynth11FilterStateC2Ev
	.section	.text._ZN9opensynth13BodyResonanceC2Ev,"axG",@progbits,_ZN9opensynth13BodyResonanceC5Ev,comdat
	.align 2
	.weak	_ZN9opensynth13BodyResonanceC2Ev
	.hidden	_ZN9opensynth13BodyResonanceC2Ev
	.type	_ZN9opensynth13BodyResonanceC2Ev, @function
_ZN9opensynth13BodyResonanceC2Ev:
.LFB2114:
	.file 3 "/home/synth/projects/05-active-dev/open-synth/include/instrument_realism.h"
	.loc 3 26 8
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	movq	%rdi, -8(%rbp)
.LBB12:
	.loc 3 26 8
	movq	-8(%rbp), %rax
	pxor	%xmm0, %xmm0
	movups	%xmm0, (%rax)
	movq	%xmm0, 16(%rax)
.LBE12:
	nop
	popq	%rbp
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE2114:
	.size	_ZN9opensynth13BodyResonanceC2Ev, .-_ZN9opensynth13BodyResonanceC2Ev
	.weak	_ZN9opensynth13BodyResonanceC1Ev
	.hidden	_ZN9opensynth13BodyResonanceC1Ev
	.set	_ZN9opensynth13BodyResonanceC1Ev,_ZN9opensynth13BodyResonanceC2Ev
	.section	.text._ZN9opensynth17KeyClickGeneratorC2Ev,"axG",@progbits,_ZN9opensynth17KeyClickGeneratorC5Ev,comdat
	.align 2
	.weak	_ZN9opensynth17KeyClickGeneratorC2Ev
	.hidden	_ZN9opensynth17KeyClickGeneratorC2Ev
	.type	_ZN9opensynth17KeyClickGeneratorC2Ev, @function
_ZN9opensynth17KeyClickGeneratorC2Ev:
.LFB2117:
	.loc 3 71 8
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	movq	%rdi, -8(%rbp)
.LBB13:
	.loc 3 71 8
	movq	-8(%rbp), %rax
	movb	$0, (%rax)
	movq	-8(%rbp), %rax
	pxor	%xmm0, %xmm0
	movss	%xmm0, 4(%rax)
	movq	-8(%rbp), %rax
	movss	.LC5(%rip), %xmm0
	movss	%xmm0, 8(%rax)
	movq	-8(%rbp), %rax
	movss	.LC6(%rip), %xmm0
	movss	%xmm0, 12(%rax)
	movq	-8(%rbp), %rax
	movss	.LC7(%rip), %xmm0
	movss	%xmm0, 16(%rax)
	movq	-8(%rbp), %rax
	pxor	%xmm0, %xmm0
	movss	%xmm0, 20(%rax)
	movq	-8(%rbp), %rax
	movl	$0, 24(%rax)
.LBE13:
	nop
	popq	%rbp
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE2117:
	.size	_ZN9opensynth17KeyClickGeneratorC2Ev, .-_ZN9opensynth17KeyClickGeneratorC2Ev
	.weak	_ZN9opensynth17KeyClickGeneratorC1Ev
	.hidden	_ZN9opensynth17KeyClickGeneratorC1Ev
	.set	_ZN9opensynth17KeyClickGeneratorC1Ev,_ZN9opensynth17KeyClickGeneratorC2Ev
	.section	.text._ZN9opensynth20SympatheticResonatorC2Ev,"axG",@progbits,_ZN9opensynth20SympatheticResonatorC5Ev,comdat
	.align 2
	.weak	_ZN9opensynth20SympatheticResonatorC2Ev
	.hidden	_ZN9opensynth20SympatheticResonatorC2Ev
	.type	_ZN9opensynth20SympatheticResonatorC2Ev, @function
_ZN9opensynth20SympatheticResonatorC2Ev:
.LFB2123:
	.loc 3 89 8
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$16, %rsp
	movq	%rdi, -8(%rbp)
.LBB14:
	.loc 3 89 8
	movq	-8(%rbp), %rax
	movl	$288, %edx
	movl	$0, %esi
	movq	%rax, %rdi
	call	memset@PLT
	movl	$0, %edx
.L9:
	.loc 3 89 8 is_stmt 0 discriminator 1
	movq	-8(%rbp), %rcx
	movq	%rdx, %rax
	addq	%rax, %rax
	addq	%rdx, %rax
	salq	$3, %rax
	addq	%rcx, %rax
	addq	$20, %rax
	movss	.LC8(%rip), %xmm0
	movss	%xmm0, (%rax)
	cmpq	$11, %rdx
	je	.L10
	.loc 3 89 8 discriminator 2
	addq	$1, %rdx
	jmp	.L9
.L10:
.LBE14:
	.loc 3 89 8 discriminator 3
	nop
	.loc 3 89 8
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE2123:
	.size	_ZN9opensynth20SympatheticResonatorC2Ev, .-_ZN9opensynth20SympatheticResonatorC2Ev
	.weak	_ZN9opensynth20SympatheticResonatorC1Ev
	.hidden	_ZN9opensynth20SympatheticResonatorC1Ev
	.set	_ZN9opensynth20SympatheticResonatorC1Ev,_ZN9opensynth20SympatheticResonatorC2Ev
	.section	.text._ZN9opensynth17InstrumentRealismC2Ev,"axG",@progbits,_ZN9opensynth17InstrumentRealismC5Ev,comdat
	.align 2
	.weak	_ZN9opensynth17InstrumentRealismC2Ev
	.hidden	_ZN9opensynth17InstrumentRealismC2Ev
	.type	_ZN9opensynth17InstrumentRealismC2Ev, @function
_ZN9opensynth17InstrumentRealismC2Ev:
.LFB2125:
	.loc 3 141 8 is_stmt 1
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$16, %rsp
	movq	%rdi, -8(%rbp)
.LBB15:
	.loc 3 141 8
	movq	-8(%rbp), %rax
	movq	%rax, %rdi
	call	_ZN9opensynth13BodyResonanceC1Ev
	.loc 3 141 8 is_stmt 0 discriminator 1
	movq	-8(%rbp), %rax
	addq	$24, %rax
	movq	%rax, %rdi
	call	_ZN9opensynth17KeyClickGeneratorC1Ev
	.loc 3 141 8 discriminator 2
	movq	-8(%rbp), %rax
	addq	$52, %rax
	movq	%rax, %rdi
	call	_ZN9opensynth20SympatheticResonatorC1Ev
	.loc 3 141 8 discriminator 3
	movq	-8(%rbp), %rax
	movl	$0, 340(%rax)
	movq	-8(%rbp), %rax
	pxor	%xmm0, %xmm0
	movss	%xmm0, 344(%rax)
	movq	-8(%rbp), %rax
	pxor	%xmm0, %xmm0
	movss	%xmm0, 348(%rax)
	movq	-8(%rbp), %rax
	pxor	%xmm0, %xmm0
	movss	%xmm0, 352(%rax)
	movq	-8(%rbp), %rax
	movl	$0, 356(%rax)
	movq	-8(%rbp), %rax
	pxor	%xmm0, %xmm0
	movss	%xmm0, 360(%rax)
.LBE15:
	nop
	.loc 3 141 8
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE2125:
	.size	_ZN9opensynth17InstrumentRealismC2Ev, .-_ZN9opensynth17InstrumentRealismC2Ev
	.weak	_ZN9opensynth17InstrumentRealismC1Ev
	.hidden	_ZN9opensynth17InstrumentRealismC1Ev
	.set	_ZN9opensynth17InstrumentRealismC1Ev,_ZN9opensynth17InstrumentRealismC2Ev
	.section	.text._ZN9opensynth13MpeVoiceStateC2Ev,"axG",@progbits,_ZN9opensynth13MpeVoiceStateC5Ev,comdat
	.align 2
	.weak	_ZN9opensynth13MpeVoiceStateC2Ev
	.hidden	_ZN9opensynth13MpeVoiceStateC2Ev
	.type	_ZN9opensynth13MpeVoiceStateC2Ev, @function
_ZN9opensynth13MpeVoiceStateC2Ev:
.LFB2128:
	.file 4 "/home/synth/projects/05-active-dev/open-synth/include/mpe_voice.h"
	.loc 4 16 8 is_stmt 1
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	movq	%rdi, -8(%rbp)
.LBB16:
	.loc 4 16 8
	movq	-8(%rbp), %rax
	pxor	%xmm0, %xmm0
	movss	%xmm0, (%rax)
	movq	-8(%rbp), %rax
	pxor	%xmm0, %xmm0
	movss	%xmm0, 4(%rax)
	movq	-8(%rbp), %rax
	pxor	%xmm0, %xmm0
	movss	%xmm0, 8(%rax)
	movq	-8(%rbp), %rax
	movb	$0, 12(%rax)
	movq	-8(%rbp), %rax
	movl	$0, 16(%rax)
	movq	-8(%rbp), %rax
	movl	$0, 20(%rax)
.LBE16:
	nop
	popq	%rbp
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE2128:
	.size	_ZN9opensynth13MpeVoiceStateC2Ev, .-_ZN9opensynth13MpeVoiceStateC2Ev
	.weak	_ZN9opensynth13MpeVoiceStateC1Ev
	.hidden	_ZN9opensynth13MpeVoiceStateC1Ev
	.set	_ZN9opensynth13MpeVoiceStateC1Ev,_ZN9opensynth13MpeVoiceStateC2Ev
	.section	.text._ZN9opensynth5VoiceC2Ev,"axG",@progbits,_ZN9opensynth5VoiceC5Ev,comdat
	.align 2
	.weak	_ZN9opensynth5VoiceC2Ev
	.hidden	_ZN9opensynth5VoiceC2Ev
	.type	_ZN9opensynth5VoiceC2Ev, @function
_ZN9opensynth5VoiceC2Ev:
.LFB2130:
	.file 5 "/home/synth/projects/05-active-dev/open-synth/include/voice.h"
	.loc 5 13 8
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$16, %rsp
	movq	%rdi, -8(%rbp)
.LBB17:
	.loc 5 13 8
	movq	-8(%rbp), %rax
	movb	$0, (%rax)
	movq	-8(%rbp), %rax
	movb	$0, 1(%rax)
	movq	-8(%rbp), %rax
	movl	$69, 4(%rax)
	movq	-8(%rbp), %rax
	movss	.LC6(%rip), %xmm0
	movss	%xmm0, 8(%rax)
	movq	-8(%rbp), %rax
	movss	.LC9(%rip), %xmm0
	movss	%xmm0, 12(%rax)
	movq	-8(%rbp), %rax
	pxor	%xmm0, %xmm0
	movups	%xmm0, 16(%rax)
	movups	%xmm0, 32(%rax)
	movq	-8(%rbp), %rax
	pxor	%xmm0, %xmm0
	movups	%xmm0, 48(%rax)
	movups	%xmm0, 64(%rax)
	movq	-8(%rbp), %rax
	addq	$80, %rax
	movq	%rax, %rdi
	call	_ZN9opensynth8EnvelopeC1Ev
	.loc 5 13 8 is_stmt 0 discriminator 1
	movq	-8(%rbp), %rax
	addq	$132, %rax
	movq	%rax, %rdi
	call	_ZN9opensynth8EnvelopeC1Ev
	.loc 5 13 8 discriminator 2
	movq	-8(%rbp), %rax
	addq	$184, %rax
	movq	%rax, %rdi
	call	_ZN9opensynth8EnvelopeC1Ev
	.loc 5 13 8 discriminator 3
	movq	-8(%rbp), %rax
	pxor	%xmm0, %xmm0
	movsd	%xmm0, 240(%rax)
	movq	-8(%rbp), %rax
	pxor	%xmm0, %xmm0
	movsd	%xmm0, 248(%rax)
	movq	-8(%rbp), %rax
	addq	$256, %rax
	movq	%rax, %rdi
	call	_ZN9opensynth11FilterStateC1Ev
	.loc 5 13 8 discriminator 4
	movq	-8(%rbp), %rax
	pxor	%xmm0, %xmm0
	movss	%xmm0, 268(%rax)
	movq	-8(%rbp), %rax
	pxor	%xmm0, %xmm0
	movss	%xmm0, 272(%rax)
	movq	-8(%rbp), %rax
	movl	$0, 276(%rax)
	movq	-8(%rbp), %rax
	addq	$280, %rax
	movq	%rax, %rdi
	call	_ZN9opensynth18PhysicalModelVoiceC1Ev@PLT
	.loc 5 13 8 discriminator 5
	movq	-8(%rbp), %rax
	addq	$608, %rax
	movq	%rax, %rdi
	call	_ZN9opensynth17InstrumentRealismC1Ev
	.loc 5 13 8 discriminator 6
	movq	-8(%rbp), %rax
	addq	$972, %rax
	movq	%rax, %rdi
	call	_ZN9opensynth13MpeVoiceStateC1Ev
.LBE17:
	.loc 5 13 8 discriminator 7
	nop
	.loc 5 13 8
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE2130:
	.size	_ZN9opensynth5VoiceC2Ev, .-_ZN9opensynth5VoiceC2Ev
	.weak	_ZN9opensynth5VoiceC1Ev
	.hidden	_ZN9opensynth5VoiceC1Ev
	.set	_ZN9opensynth5VoiceC1Ev,_ZN9opensynth5VoiceC2Ev
	.section	.text._ZN9opensynth5VoiceD2Ev,"axG",@progbits,_ZN9opensynth5VoiceD5Ev,comdat
	.align 2
	.weak	_ZN9opensynth5VoiceD2Ev
	.hidden	_ZN9opensynth5VoiceD2Ev
	.type	_ZN9opensynth5VoiceD2Ev, @function
_ZN9opensynth5VoiceD2Ev:
.LFB2133:
	.loc 5 13 8 is_stmt 1
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$16, %rsp
	movq	%rdi, -8(%rbp)
.LBB18:
	.loc 5 13 8
	movq	-8(%rbp), %rax
	addq	$280, %rax
	movq	%rax, %rdi
	call	_ZN9opensynth18PhysicalModelVoiceD1Ev@PLT
.LBE18:
	.loc 5 13 8 is_stmt 0 discriminator 1
	nop
	.loc 5 13 8
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE2133:
	.size	_ZN9opensynth5VoiceD2Ev, .-_ZN9opensynth5VoiceD2Ev
	.weak	_ZN9opensynth5VoiceD1Ev
	.hidden	_ZN9opensynth5VoiceD1Ev
	.set	_ZN9opensynth5VoiceD1Ev,_ZN9opensynth5VoiceD2Ev
	.section	.text._ZNSt5arrayIN9opensynth5VoiceELm128EEC2Ev,"axG",@progbits,_ZNSt5arrayIN9opensynth5VoiceELm128EEC5Ev,comdat
	.align 2
	.weak	_ZNSt5arrayIN9opensynth5VoiceELm128EEC2Ev
	.hidden	_ZNSt5arrayIN9opensynth5VoiceELm128EEC2Ev
	.type	_ZNSt5arrayIN9opensynth5VoiceELm128EEC2Ev, @function
_ZNSt5arrayIN9opensynth5VoiceELm128EEC2Ev:
.LFB2135:
	.file 6 "/usr/include/c++/16.1.1/array"
	.loc 6 102 12 is_stmt 1
	.cfi_startproc
	.cfi_personality 0x9b,DW.ref.__gxx_personality_v0
	.cfi_lsda 0x1b,.LLSDA2135
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	pushq	%r13
	pushq	%r12
	pushq	%rbx
	subq	$24, %rsp
	.cfi_offset 13, -24
	.cfi_offset 12, -32
	.cfi_offset 3, -40
	movq	%rdi, -40(%rbp)
.LBB19:
	.loc 6 102 12
	movq	-40(%rbp), %rbx
	movl	$127, %r12d
	movq	%rbx, %r13
	jmp	.L16
.L17:
	.loc 6 102 12 is_stmt 0 discriminator 1
	movq	%r13, %rdi
.LEHB0:
	call	_ZN9opensynth5VoiceC1Ev
.LEHE0:
	.loc 6 102 12 discriminator 2
	subq	$1, %r12
	addq	$1000, %r13
.L16:
	.loc 6 102 12 discriminator 3
	testq	%r12, %r12
	jns	.L17
.LBE19:
	.loc 6 102 12 discriminator 4
	jmp	.L22
.L21:
.LBB20:
	.loc 6 102 12 discriminator 5
	movq	%rax, %r13
	testq	%rbx, %rbx
	je	.L19
	.loc 6 102 12 discriminator 6
	movl	$127, %eax
	subq	%r12, %rax
	imulq	$1000, %rax, %rax
	leaq	(%rbx,%rax), %r12
.L20:
	.loc 6 102 12 discriminator 7
	cmpq	%rbx, %r12
	je	.L19
	.loc 6 102 12 discriminator 8
	subq	$1000, %r12
	movq	%r12, %rdi
	call	_ZN9opensynth5VoiceD1Ev
	.loc 6 102 12 discriminator 9
	jmp	.L20
.L19:
	movq	%r13, %rax
	movq	%rax, %rdi
.LEHB1:
	call	_Unwind_Resume@PLT
.LEHE1:
.L22:
.LBE20:
	.loc 6 102 12
	addq	$24, %rsp
	popq	%rbx
	popq	%r12
	popq	%r13
	popq	%rbp
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE2135:
	.section	.gcc_except_table._ZNSt5arrayIN9opensynth5VoiceELm128EEC2Ev,"aG",@progbits,_ZNSt5arrayIN9opensynth5VoiceELm128EEC5Ev,comdat
.LLSDA2135:
	.byte	0xff
	.byte	0xff
	.byte	0x1
	.uleb128 .LLSDACSE2135-.LLSDACSB2135
.LLSDACSB2135:
	.uleb128 .LEHB0-.LFB2135
	.uleb128 .LEHE0-.LEHB0
	.uleb128 .L21-.LFB2135
	.uleb128 0
	.uleb128 .LEHB1-.LFB2135
	.uleb128 .LEHE1-.LEHB1
	.uleb128 0
	.uleb128 0
.LLSDACSE2135:
	.section	.text._ZNSt5arrayIN9opensynth5VoiceELm128EEC2Ev,"axG",@progbits,_ZNSt5arrayIN9opensynth5VoiceELm128EEC5Ev,comdat
	.size	_ZNSt5arrayIN9opensynth5VoiceELm128EEC2Ev, .-_ZNSt5arrayIN9opensynth5VoiceELm128EEC2Ev
	.weak	_ZNSt5arrayIN9opensynth5VoiceELm128EEC1Ev
	.hidden	_ZNSt5arrayIN9opensynth5VoiceELm128EEC1Ev
	.set	_ZNSt5arrayIN9opensynth5VoiceELm128EEC1Ev,_ZNSt5arrayIN9opensynth5VoiceELm128EEC2Ev
	.section	.text._ZNSt5arrayIN9opensynth5VoiceELm128EED2Ev,"axG",@progbits,_ZNSt5arrayIN9opensynth5VoiceELm128EED5Ev,comdat
	.align 2
	.weak	_ZNSt5arrayIN9opensynth5VoiceELm128EED2Ev
	.hidden	_ZNSt5arrayIN9opensynth5VoiceELm128EED2Ev
	.type	_ZNSt5arrayIN9opensynth5VoiceELm128EED2Ev, @function
_ZNSt5arrayIN9opensynth5VoiceELm128EED2Ev:
.LFB2138:
	.loc 6 102 12 is_stmt 1
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	pushq	%rbx
	subq	$24, %rsp
	.cfi_offset 3, -24
	movq	%rdi, -24(%rbp)
.LBB21:
	.loc 6 102 12
	movq	-24(%rbp), %rax
	testq	%rax, %rax
	je	.L24
	.loc 6 102 12 is_stmt 0 discriminator 3
	movq	-24(%rbp), %rax
	leaq	128000(%rax), %rbx
.L26:
	.loc 6 102 12 discriminator 4
	movq	-24(%rbp), %rax
	cmpq	%rax, %rbx
	je	.L25
	.loc 6 102 12 discriminator 7
	subq	$1000, %rbx
	movq	%rbx, %rdi
	call	_ZN9opensynth5VoiceD1Ev
	.loc 6 102 12 discriminator 8
	jmp	.L26
.L25:
	.loc 6 102 12 discriminator 9
	nop
.L24:
.LBE21:
	.loc 6 102 12 discriminator 10
	nop
	.loc 6 102 12
	movq	-8(%rbp), %rbx
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE2138:
	.size	_ZNSt5arrayIN9opensynth5VoiceELm128EED2Ev, .-_ZNSt5arrayIN9opensynth5VoiceELm128EED2Ev
	.weak	_ZNSt5arrayIN9opensynth5VoiceELm128EED1Ev
	.hidden	_ZNSt5arrayIN9opensynth5VoiceELm128EED1Ev
	.set	_ZNSt5arrayIN9opensynth5VoiceELm128EED1Ev,_ZNSt5arrayIN9opensynth5VoiceELm128EED2Ev
	.text
	.align 2
	.globl	_ZN9opensynth14VoiceAllocatorC2Ev
	.hidden	_ZN9opensynth14VoiceAllocatorC2Ev
	.type	_ZN9opensynth14VoiceAllocatorC2Ev, @function
_ZN9opensynth14VoiceAllocatorC2Ev:
.LFB2140:
	.file 7 "/home/synth/projects/05-active-dev/open-synth/dsp/voice_allocator.cpp"
	.loc 7 6 1 is_stmt 1
	.cfi_startproc
	.cfi_personality 0x9b,DW.ref.__gxx_personality_v0
	.cfi_lsda 0x1b,.LLSDA2140
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	pushq	%rbx
	subq	$56, %rsp
	.cfi_offset 3, -24
	movq	%rdi, -56(%rbp)
.LBB22:
	.loc 7 6 32
	movq	-56(%rbp), %rax
	movq	%rax, %rdi
.LEHB2:
	call	_ZNSt5arrayIN9opensynth5VoiceELm128EEC1Ev
.LEHE2:
	.loc 7 6 32 is_stmt 0 discriminator 1
	movq	-56(%rbp), %rax
	movb	$0, 128000(%rax)
	movq	-56(%rbp), %rax
	movl	$0, 128004(%rax)
	movq	-56(%rbp), %rax
	movl	$0, 128008(%rax)
.LBB23:
.LBB24:
	.loc 7 7 20 is_stmt 1
	movq	-56(%rbp), %rax
	movq	%rax, -40(%rbp)
	movq	-40(%rbp), %rax
	movq	%rax, %rdi
	call	_ZNSt5arrayIN9opensynth5VoiceELm128EE5beginEv
	movq	%rax, -48(%rbp)
	.loc 7 7 20 is_stmt 0 discriminator 1
	movq	-40(%rbp), %rax
	movq	%rax, %rdi
	call	_ZNSt5arrayIN9opensynth5VoiceELm128EE3endEv
	movq	%rax, -32(%rbp)
	.loc 7 7 5 is_stmt 1 discriminator 2
	jmp	.L28
.L29:
	.loc 7 7 16 discriminator 3
	movq	-48(%rbp), %rax
	movq	%rax, -24(%rbp)
	.loc 7 8 16
	movq	-24(%rbp), %rax
	movq	%rax, %rdi
.LEHB3:
	call	_ZN9opensynth5Voice5resetEv@PLT
	.loc 7 9 29
	movq	-24(%rbp), %rax
	leaq	280(%rax), %rdx
	movq	.LC11(%rip), %rax
	movl	$4096, %esi
	movq	%rax, %xmm0
	movq	%rdx, %rdi
	call	_ZN9opensynth18PhysicalModelVoice4initEdi@PLT
.LEHE3:
	.loc 7 7 5 discriminator 4
	addq	$1000, -48(%rbp)
.L28:
	.loc 7 7 20 discriminator 5
	movq	-48(%rbp), %rax
	cmpq	-32(%rbp), %rax
	jne	.L29
.LBE24:
.LBE23:
.LBE22:
	.loc 7 11 1
	jmp	.L32
.L31:
.LBB25:
	.loc 7 11 1 is_stmt 0 discriminator 1
	movq	%rax, %rbx
	movq	-56(%rbp), %rax
	movq	%rax, %rdi
	call	_ZNSt5arrayIN9opensynth5VoiceELm128EED1Ev
	movq	%rbx, %rax
	movq	%rax, %rdi
.LEHB4:
	call	_Unwind_Resume@PLT
.LEHE4:
.L32:
.LBE25:
	.loc 7 11 1
	movq	-8(%rbp), %rbx
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE2140:
	.section	.gcc_except_table,"a",@progbits
.LLSDA2140:
	.byte	0xff
	.byte	0xff
	.byte	0x1
	.uleb128 .LLSDACSE2140-.LLSDACSB2140
.LLSDACSB2140:
	.uleb128 .LEHB2-.LFB2140
	.uleb128 .LEHE2-.LEHB2
	.uleb128 0
	.uleb128 0
	.uleb128 .LEHB3-.LFB2140
	.uleb128 .LEHE3-.LEHB3
	.uleb128 .L31-.LFB2140
	.uleb128 0
	.uleb128 .LEHB4-.LFB2140
	.uleb128 .LEHE4-.LEHB4
	.uleb128 0
	.uleb128 0
.LLSDACSE2140:
	.text
	.size	_ZN9opensynth14VoiceAllocatorC2Ev, .-_ZN9opensynth14VoiceAllocatorC2Ev
	.globl	_ZN9opensynth14VoiceAllocatorC1Ev
	.hidden	_ZN9opensynth14VoiceAllocatorC1Ev
	.set	_ZN9opensynth14VoiceAllocatorC1Ev,_ZN9opensynth14VoiceAllocatorC2Ev
	.align 2
	.globl	_ZN9opensynth14VoiceAllocator6noteOnEifii
	.hidden	_ZN9opensynth14VoiceAllocator6noteOnEifii
	.type	_ZN9opensynth14VoiceAllocator6noteOnEifii, @function
_ZN9opensynth14VoiceAllocator6noteOnEifii:
.LFB2142:
	.loc 7 13 92 is_stmt 1
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	pushq	%rbx
	subq	$120, %rsp
	.cfi_offset 3, -24
	movq	%rdi, -104(%rbp)
	movl	%esi, -108(%rbp)
	movss	%xmm0, -112(%rbp)
	movl	%edx, -116(%rbp)
	movl	%ecx, -120(%rbp)
.LBB26:
	.loc 7 15 5
	cmpl	$0, -120(%rbp)
	js	.L34
.LBB27:
.LBB28:
	.loc 7 16 24
	movq	-104(%rbp), %rax
	movq	%rax, -48(%rbp)
	movq	-48(%rbp), %rax
	movq	%rax, %rdi
	call	_ZNSt5arrayIN9opensynth5VoiceELm128EE5beginEv
	movq	%rax, -88(%rbp)
	.loc 7 16 24 is_stmt 0 discriminator 1
	movq	-48(%rbp), %rax
	movq	%rax, %rdi
	call	_ZNSt5arrayIN9opensynth5VoiceELm128EE3endEv
	movq	%rax, -40(%rbp)
	.loc 7 16 9 is_stmt 1 discriminator 2
	jmp	.L35
.L38:
	.loc 7 16 20 discriminator 3
	movq	-88(%rbp), %rax
	movq	%rax, -32(%rbp)
	.loc 7 17 19
	movq	-32(%rbp), %rax
	movzbl	(%rax), %eax
	.loc 7 17 13
	testb	%al, %al
	je	.L36
	.loc 7 17 31 discriminator 1
	movq	-32(%rbp), %rax
	movl	4(%rax), %eax
	.loc 7 17 26 discriminator 1
	cmpl	%eax, -108(%rbp)
	jne	.L36
	.loc 7 17 61 discriminator 2
	movq	-32(%rbp), %rax
	movl	992(%rax), %eax
	.loc 7 17 52 discriminator 2
	cmpl	%eax, -120(%rbp)
	jne	.L36
	.loc 7 18 25
	movl	-112(%rbp), %ecx
	movl	-108(%rbp), %edx
	movq	-32(%rbp), %rax
	movd	%ecx, %xmm0
	movl	%edx, %esi
	movq	%rax, %rdi
	call	_ZN9opensynth5Voice6noteOnEif@PLT
	.loc 7 19 29
	movq	-32(%rbp), %rax
	movl	-116(%rbp), %edx
	movl	%edx, 276(%rax)
	.loc 7 20 38
	movq	-32(%rbp), %rax
	movl	-120(%rbp), %edx
	movl	%edx, 992(%rax)
	.loc 7 21 25
	movq	-32(%rbp), %rax
	jmp	.L37
.L36:
	.loc 7 16 9 discriminator 4
	addq	$1000, -88(%rbp)
.L35:
	.loc 7 16 24 discriminator 5
	movq	-88(%rbp), %rax
	cmpq	-40(%rbp), %rax
	jne	.L38
	jmp	.L39
.L34:
.LBE28:
.LBE27:
.LBB29:
.LBB30:
	.loc 7 26 24
	movq	-104(%rbp), %rax
	movq	%rax, -72(%rbp)
	movq	-72(%rbp), %rax
	movq	%rax, %rdi
	call	_ZNSt5arrayIN9opensynth5VoiceELm128EE5beginEv
	movq	%rax, -80(%rbp)
	.loc 7 26 24 is_stmt 0 discriminator 1
	movq	-72(%rbp), %rax
	movq	%rax, %rdi
	call	_ZNSt5arrayIN9opensynth5VoiceELm128EE3endEv
	movq	%rax, -64(%rbp)
	.loc 7 26 9 is_stmt 1 discriminator 2
	jmp	.L40
.L42:
	.loc 7 26 20 discriminator 3
	movq	-80(%rbp), %rax
	movq	%rax, -56(%rbp)
	.loc 7 27 19
	movq	-56(%rbp), %rax
	movzbl	(%rax), %eax
	.loc 7 27 13
	testb	%al, %al
	je	.L41
	.loc 7 27 31 discriminator 1
	movq	-56(%rbp), %rax
	movl	4(%rax), %eax
	.loc 7 27 26 discriminator 1
	cmpl	%eax, -108(%rbp)
	jne	.L41
	.loc 7 27 57 discriminator 2
	movq	-56(%rbp), %rax
	movl	276(%rax), %eax
	.loc 7 27 52 discriminator 2
	cmpl	%eax, -116(%rbp)
	jne	.L41
	.loc 7 28 25
	movl	-112(%rbp), %ecx
	movl	-108(%rbp), %edx
	movq	-56(%rbp), %rax
	movd	%ecx, %xmm0
	movl	%edx, %esi
	movq	%rax, %rdi
	call	_ZN9opensynth5Voice6noteOnEif@PLT
	.loc 7 29 29
	movq	-56(%rbp), %rax
	movl	-116(%rbp), %edx
	movl	%edx, 276(%rax)
	.loc 7 30 25
	movq	-56(%rbp), %rax
	jmp	.L37
.L41:
	.loc 7 26 9 discriminator 4
	addq	$1000, -80(%rbp)
.L40:
	.loc 7 26 24 discriminator 5
	movq	-80(%rbp), %rax
	cmpq	-64(%rbp), %rax
	jne	.L42
.L39:
.LBE30:
.LBE29:
.LBE26:
	.loc 7 36 28
	movq	-104(%rbp), %rax
	movq	%rax, %rdi
	call	_ZNK9opensynth14VoiceAllocator13findFreeVoiceEv
	movl	%eax, -92(%rbp)
.LBB31:
	.loc 7 37 5
	cmpl	$0, -92(%rbp)
	jns	.L43
.LBB32:
	.loc 7 38 35
	movq	-104(%rbp), %rax
	movq	%rax, %rdi
	call	_ZN9opensynth14VoiceAllocator10stealVoiceEv
	.loc 7 38 35 is_stmt 0 discriminator 1
	movq	%rax, -24(%rbp)
	.loc 7 39 23 is_stmt 1
	movl	-112(%rbp), %ecx
	movl	-108(%rbp), %edx
	movq	-24(%rbp), %rax
	movd	%ecx, %xmm0
	movl	%edx, %esi
	movq	%rax, %rdi
	call	_ZN9opensynth5Voice6noteOnEif@PLT
	.loc 7 40 27
	movq	-24(%rbp), %rax
	movl	-116(%rbp), %edx
	movl	%edx, 276(%rax)
	.loc 7 41 9
	cmpl	$0, -120(%rbp)
	js	.L44
	.loc 7 42 36
	movq	-24(%rbp), %rax
	movb	$1, 984(%rax)
	.loc 7 43 40
	movq	-24(%rbp), %rax
	movl	-120(%rbp), %edx
	movl	%edx, 992(%rax)
.L44:
	.loc 7 45 16
	movq	-24(%rbp), %rax
	jmp	.L37
.L43:
.LBE32:
.LBE31:
	.loc 7 48 16
	movq	-104(%rbp), %rax
	movl	-92(%rbp), %edx
	movslq	%edx, %rdx
	movq	%rdx, %rsi
	movq	%rax, %rdi
	call	_ZNSt5arrayIN9opensynth5VoiceELm128EEixEm
	movq	%rax, %rcx
	.loc 7 48 24 discriminator 1
	movl	-112(%rbp), %edx
	movl	-108(%rbp), %eax
	movd	%edx, %xmm0
	movl	%eax, %esi
	movq	%rcx, %rdi
	call	_ZN9opensynth5Voice6noteOnEif@PLT
	.loc 7 49 28
	movl	-116(%rbp), %ebx
	.loc 7 49 16
	movq	-104(%rbp), %rax
	movl	-92(%rbp), %edx
	movslq	%edx, %rdx
	movq	%rdx, %rsi
	movq	%rax, %rdi
	call	_ZNSt5arrayIN9opensynth5VoiceELm128EEixEm
	.loc 7 49 28 discriminator 1
	movl	%ebx, 276(%rax)
	.loc 7 50 5
	cmpl	$0, -120(%rbp)
	js	.L45
	.loc 7 51 20
	movq	-104(%rbp), %rax
	movl	-92(%rbp), %edx
	movslq	%edx, %rdx
	movq	%rdx, %rsi
	movq	%rax, %rdi
	call	_ZNSt5arrayIN9opensynth5VoiceELm128EEixEm
	.loc 7 51 37 discriminator 1
	movb	$1, 984(%rax)
	.loc 7 52 41
	movl	-120(%rbp), %ebx
	.loc 7 52 20
	movq	-104(%rbp), %rax
	movl	-92(%rbp), %edx
	movslq	%edx, %rdx
	movq	%rdx, %rsi
	movq	%rax, %rdi
	call	_ZNSt5arrayIN9opensynth5VoiceELm128EEixEm
	.loc 7 52 41 discriminator 1
	movl	%ebx, 992(%rax)
.L45:
	.loc 7 54 24
	movq	-104(%rbp), %rax
	movl	-92(%rbp), %edx
	movslq	%edx, %rdx
	movq	%rdx, %rsi
	movq	%rax, %rdi
	call	_ZNSt5arrayIN9opensynth5VoiceELm128EEixEm
.L37:
	.loc 7 55 1
	movq	-8(%rbp), %rbx
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE2142:
	.size	_ZN9opensynth14VoiceAllocator6noteOnEifii, .-_ZN9opensynth14VoiceAllocator6noteOnEifii
	.align 2
	.globl	_ZN9opensynth14VoiceAllocator7noteOffEiii
	.hidden	_ZN9opensynth14VoiceAllocator7noteOffEiii
	.type	_ZN9opensynth14VoiceAllocator7noteOffEiii, @function
_ZN9opensynth14VoiceAllocator7noteOffEiii:
.LFB2143:
	.loc 7 57 75
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$64, %rsp
	movq	%rdi, -40(%rbp)
	movl	%esi, -44(%rbp)
	movl	%edx, -48(%rbp)
	movl	%ecx, -52(%rbp)
.LBB33:
	.loc 7 58 20
	movq	-40(%rbp), %rax
	movq	%rax, -24(%rbp)
	movq	-24(%rbp), %rax
	movq	%rax, %rdi
	call	_ZNSt5arrayIN9opensynth5VoiceELm128EE5beginEv
	movq	%rax, -32(%rbp)
	.loc 7 58 20 is_stmt 0 discriminator 1
	movq	-24(%rbp), %rax
	movq	%rax, %rdi
	call	_ZNSt5arrayIN9opensynth5VoiceELm128EE3endEv
	movq	%rax, -16(%rbp)
	.loc 7 58 5 is_stmt 1 discriminator 2
	jmp	.L47
.L54:
	.loc 7 58 16 discriminator 3
	movq	-32(%rbp), %rax
	movq	%rax, -8(%rbp)
	.loc 7 59 15
	movq	-8(%rbp), %rax
	movzbl	(%rax), %eax
	.loc 7 59 9
	testb	%al, %al
	je	.L48
	.loc 7 59 27 discriminator 1
	movq	-8(%rbp), %rax
	movl	4(%rax), %eax
	.loc 7 59 22 discriminator 1
	cmpl	%eax, -44(%rbp)
	jne	.L48
	.loc 7 60 13
	cmpl	$0, -48(%rbp)
	js	.L49
	.loc 7 60 37 discriminator 1
	movq	-8(%rbp), %rax
	movl	276(%rax), %eax
	.loc 7 60 32 discriminator 1
	cmpl	%eax, -48(%rbp)
	jne	.L55
.L49:
	.loc 7 61 13
	cmpl	$0, -52(%rbp)
	js	.L50
	.loc 7 61 42 discriminator 1
	movq	-8(%rbp), %rax
	movl	992(%rax), %eax
	.loc 7 61 33 discriminator 1
	cmpl	%eax, -52(%rbp)
	jne	.L56
.L50:
	.loc 7 62 17
	movq	-40(%rbp), %rax
	movzbl	128000(%rax), %eax
	.loc 7 62 13
	testb	%al, %al
	je	.L51
	.loc 7 63 29
	movq	-8(%rbp), %rax
	movb	$1, 1(%rax)
	.loc 7 67 13
	jmp	.L46
.L51:
	.loc 7 65 26
	movq	-8(%rbp), %rax
	movq	%rax, %rdi
	call	_ZN9opensynth5Voice7noteOffEv@PLT
	.loc 7 67 13
	jmp	.L46
.L55:
	.loc 7 60 61 discriminator 2
	nop
	jmp	.L48
.L56:
	.loc 7 61 72 discriminator 2
	nop
.L48:
	.loc 7 58 5 discriminator 4
	addq	$1000, -32(%rbp)
.L47:
	.loc 7 58 20 discriminator 5
	movq	-32(%rbp), %rax
	cmpq	-16(%rbp), %rax
	jne	.L54
.L46:
.LBE33:
	.loc 7 70 1
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE2143:
	.size	_ZN9opensynth14VoiceAllocator7noteOffEiii, .-_ZN9opensynth14VoiceAllocator7noteOffEiii
	.align 2
	.globl	_ZN9opensynth14VoiceAllocator11allNotesOffEi
	.hidden	_ZN9opensynth14VoiceAllocator11allNotesOffEi
	.type	_ZN9opensynth14VoiceAllocator11allNotesOffEi, @function
_ZN9opensynth14VoiceAllocator11allNotesOffEi:
.LFB2144:
	.loc 7 72 49
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$48, %rsp
	movq	%rdi, -40(%rbp)
	movl	%esi, -44(%rbp)
.LBB34:
	.loc 7 73 20
	movq	-40(%rbp), %rax
	movq	%rax, -24(%rbp)
	movq	-24(%rbp), %rax
	movq	%rax, %rdi
	call	_ZNSt5arrayIN9opensynth5VoiceELm128EE5beginEv
	movq	%rax, -32(%rbp)
	.loc 7 73 20 is_stmt 0 discriminator 1
	movq	-24(%rbp), %rax
	movq	%rax, %rdi
	call	_ZNSt5arrayIN9opensynth5VoiceELm128EE3endEv
	movq	%rax, -16(%rbp)
	.loc 7 73 5 is_stmt 1 discriminator 2
	jmp	.L58
.L61:
	.loc 7 73 16 discriminator 3
	movq	-32(%rbp), %rax
	movq	%rax, -8(%rbp)
	.loc 7 74 15
	movq	-8(%rbp), %rax
	movzbl	(%rax), %eax
	.loc 7 74 9
	testb	%al, %al
	je	.L59
	.loc 7 75 13
	cmpl	$0, -44(%rbp)
	js	.L60
	.loc 7 75 37 discriminator 1
	movq	-8(%rbp), %rax
	movl	276(%rax), %eax
	.loc 7 75 32 discriminator 1
	cmpl	%eax, -44(%rbp)
	jne	.L63
.L60:
	.loc 7 76 22
	movq	-8(%rbp), %rax
	movq	%rax, %rdi
	call	_ZN9opensynth5Voice7noteOffEv@PLT
	jmp	.L59
.L63:
	.loc 7 75 61 discriminator 2
	nop
.L59:
	.loc 7 73 5 discriminator 4
	addq	$1000, -32(%rbp)
.L58:
	.loc 7 73 20 discriminator 5
	movq	-32(%rbp), %rax
	cmpq	-16(%rbp), %rax
	jne	.L61
.LBE34:
	.loc 7 79 5
	cmpl	$0, -44(%rbp)
	jns	.L64
	.loc 7 79 33 discriminator 1
	movq	-40(%rbp), %rax
	movb	$0, 128000(%rax)
.L64:
	.loc 7 80 1
	nop
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE2144:
	.size	_ZN9opensynth14VoiceAllocator11allNotesOffEi, .-_ZN9opensynth14VoiceAllocator11allNotesOffEi
	.align 2
	.globl	_ZN9opensynth14VoiceAllocator7sustainEb
	.hidden	_ZN9opensynth14VoiceAllocator7sustainEb
	.type	_ZN9opensynth14VoiceAllocator7sustainEb, @function
_ZN9opensynth14VoiceAllocator7sustainEb:
.LFB2145:
	.loc 7 82 39
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$48, %rsp
	movq	%rdi, -40(%rbp)
	movb	%sil, -41(%rbp)
	.loc 7 83 14
	movq	-40(%rbp), %rax
	movzbl	-41(%rbp), %edx
	movb	%dl, 128000(%rax)
.LBB35:
	.loc 7 84 9
	movzbl	-41(%rbp), %eax
	xorl	$1, %eax
	.loc 7 84 5
	testb	%al, %al
	je	.L70
.LBB36:
.LBB37:
	.loc 7 86 24
	movq	-40(%rbp), %rax
	movq	%rax, -24(%rbp)
	movq	-24(%rbp), %rax
	movq	%rax, %rdi
	call	_ZNSt5arrayIN9opensynth5VoiceELm128EE5beginEv
	movq	%rax, -32(%rbp)
	.loc 7 86 24 is_stmt 0 discriminator 1
	movq	-24(%rbp), %rax
	movq	%rax, %rdi
	call	_ZNSt5arrayIN9opensynth5VoiceELm128EE3endEv
	movq	%rax, -16(%rbp)
	.loc 7 86 9 is_stmt 1 discriminator 2
	jmp	.L67
.L69:
	.loc 7 86 20 discriminator 3
	movq	-32(%rbp), %rax
	movq	%rax, -8(%rbp)
	.loc 7 87 19
	movq	-8(%rbp), %rax
	movzbl	(%rax), %eax
	.loc 7 87 13
	testb	%al, %al
	je	.L68
	.loc 7 87 31 discriminator 1
	movq	-8(%rbp), %rax
	movzbl	1(%rax), %eax
	.loc 7 87 26 discriminator 1
	testb	%al, %al
	je	.L68
	.loc 7 88 26
	movq	-8(%rbp), %rax
	movq	%rax, %rdi
	call	_ZN9opensynth5Voice7noteOffEv@PLT
.L68:
	.loc 7 86 9 discriminator 4
	addq	$1000, -32(%rbp)
.L67:
	.loc 7 86 24 discriminator 5
	movq	-32(%rbp), %rax
	cmpq	-16(%rbp), %rax
	jne	.L69
.L70:
.LBE37:
.LBE36:
.LBE35:
	.loc 7 92 1
	nop
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE2145:
	.size	_ZN9opensynth14VoiceAllocator7sustainEb, .-_ZN9opensynth14VoiceAllocator7sustainEb
	.align 2
	.globl	_ZNK9opensynth14VoiceAllocator16activeVoiceCountEv
	.hidden	_ZNK9opensynth14VoiceAllocator16activeVoiceCountEv
	.type	_ZNK9opensynth14VoiceAllocator16activeVoiceCountEv, @function
_ZNK9opensynth14VoiceAllocator16activeVoiceCountEv:
.LFB2146:
	.loc 7 94 46
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$64, %rsp
	movq	%rdi, -56(%rbp)
	.loc 7 95 9
	movl	$0, -36(%rbp)
.LBB38:
	.loc 7 96 26
	movq	-56(%rbp), %rax
	movq	%rax, -24(%rbp)
	movq	-24(%rbp), %rax
	movq	%rax, %rdi
	call	_ZNKSt5arrayIN9opensynth5VoiceELm128EE5beginEv
	movq	%rax, -32(%rbp)
	.loc 7 96 26 is_stmt 0 discriminator 1
	movq	-24(%rbp), %rax
	movq	%rax, %rdi
	call	_ZNKSt5arrayIN9opensynth5VoiceELm128EE3endEv
	movq	%rax, -16(%rbp)
	.loc 7 96 5 is_stmt 1 discriminator 2
	jmp	.L72
.L74:
	.loc 7 96 22 discriminator 3
	movq	-32(%rbp), %rax
	movq	%rax, -8(%rbp)
	.loc 7 97 15
	movq	-8(%rbp), %rax
	movzbl	(%rax), %eax
	.loc 7 97 9
	testb	%al, %al
	je	.L73
	.loc 7 97 28 discriminator 1
	addl	$1, -36(%rbp)
.L73:
	.loc 7 96 5 discriminator 4
	addq	$1000, -32(%rbp)
.L72:
	.loc 7 96 26 discriminator 5
	movq	-32(%rbp), %rax
	cmpq	-16(%rbp), %rax
	jne	.L74
.LBE38:
	.loc 7 99 12
	movl	-36(%rbp), %eax
	.loc 7 100 1
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE2146:
	.size	_ZNK9opensynth14VoiceAllocator16activeVoiceCountEv, .-_ZNK9opensynth14VoiceAllocator16activeVoiceCountEv
	.align 2
	.globl	_ZNK9opensynth14VoiceAllocator13findFreeVoiceEv
	.hidden	_ZNK9opensynth14VoiceAllocator13findFreeVoiceEv
	.type	_ZNK9opensynth14VoiceAllocator13findFreeVoiceEv, @function
_ZNK9opensynth14VoiceAllocator13findFreeVoiceEv:
.LFB2147:
	.loc 7 102 43
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$32, %rsp
	movq	%rdi, -24(%rbp)
.LBB39:
	.loc 7 103 14
	movl	$0, -4(%rbp)
	.loc 7 103 5
	jmp	.L77
.L80:
	.loc 7 104 23
	movq	-24(%rbp), %rax
	movl	-4(%rbp), %edx
	movslq	%edx, %rdx
	movq	%rdx, %rsi
	movq	%rax, %rdi
	call	_Z