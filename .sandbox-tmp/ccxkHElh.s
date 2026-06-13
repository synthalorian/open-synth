	.file	"drum_synth.cpp"
	.text
.Ltext0:
	.file 0 "/home/synth/projects/05-active-dev/open-synth/build-debug" "/home/synth/projects/05-active-dev/open-synth/dsp/drum_synth.cpp"
	.section	.text._ZSt3expf,"axG",@progbits,_ZSt3expf,comdat
	.weak	_ZSt3expf
	.hidden	_ZSt3expf
	.type	_ZSt3expf, @function
_ZSt3expf:
.LFB71:
	.file 1 "/usr/include/c++/16.1.1/cmath"
	.loc 1 227 3
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$16, %rsp
	movss	%xmm0, -4(%rbp)
	.loc 1 227 26
	movl	-4(%rbp), %eax
	movd	%eax, %xmm0
	call	expf@PLT
	.loc 1 227 33
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE71:
	.size	_ZSt3expf, .-_ZSt3expf
	.section	.text._ZSt4fabsf,"axG",@progbits,_ZSt4fabsf,comdat
	.weak	_ZSt4fabsf
	.hidden	_ZSt4fabsf
	.type	_ZSt4fabsf, @function
_ZSt4fabsf:
.LFB74:
	.loc 1 246 3
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	movss	%xmm0, -4(%rbp)
	.loc 1 246 31
	movss	-4(%rbp), %xmm0
	movss	.LC0(%rip), %xmm1
	andps	%xmm1, %xmm0
	.loc 1 246 34
	popq	%rbp
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE74:
	.size	_ZSt4fabsf, .-_ZSt4fabsf
	.section	.text._ZSt5floorf,"axG",@progbits,_ZSt5floorf,comdat
	.weak	_ZSt5floorf
	.hidden	_ZSt5floorf
	.type	_ZSt5floorf, @function
_ZSt5floorf:
.LFB77:
	.loc 1 265 3
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	movss	%xmm0, -4(%rbp)
	.loc 1 265 28
	movss	-4(%rbp), %xmm0
	movss	.LC1(%rip), %xmm1
	movaps	%xmm0, %xmm2
	movss	.LC0(%rip), %xmm0
	movaps	%xmm0, %xmm3
	movaps	%xmm2, %xmm0
	andps	%xmm3, %xmm0
	ucomiss	%xmm0, %xmm1
	jbe	.L6
	cvttss2sil	%xmm2, %eax
	pxor	%xmm0, %xmm0
	cvtsi2ssl	%eax, %xmm0
	movss	.LC2(%rip), %xmm4
	movaps	%xmm0, %xmm1
	cmpnless	%xmm2, %xmm1
	andps	%xmm4, %xmm1
	subss	%xmm1, %xmm0
	andnps	%xmm2, %xmm3
	movaps	%xmm3, %xmm1
	orps	%xmm1, %xmm0
	movaps	%xmm0, %xmm2
.L6:
	movaps	%xmm2, %xmm0
	.loc 1 265 35
	popq	%rbp
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE77:
	.size	_ZSt5floorf, .-_ZSt5floorf
	.section	.text._ZSt3powff,"axG",@progbits,_ZSt3powff,comdat
	.weak	_ZSt3powff
	.hidden	_ZSt3powff
	.type	_ZSt3powff, @function
_ZSt3powff:
.LFB96:
	.loc 1 384 3
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$16, %rsp
	movss	%xmm0, -4(%rbp)
	movss	%xmm1, -8(%rbp)
	.loc 1 384 26
	movss	-8(%rbp), %xmm0
	movl	-4(%rbp), %eax
	movaps	%xmm0, %xmm1
	movd	%eax, %xmm0
	call	powf@PLT
	.loc 1 384 38
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE96:
	.size	_ZSt3powff, .-_ZSt3powff
	.section	.text._ZSt3sinf,"axG",@progbits,_ZSt3sinf,comdat
	.weak	_ZSt3sinf
	.hidden	_ZSt3sinf
	.type	_ZSt3sinf, @function
_ZSt3sinf:
.LFB98:
	.loc 1 412 3
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$16, %rsp
	movss	%xmm0, -4(%rbp)
	.loc 1 412 26
	movl	-4(%rbp), %eax
	movd	%eax, %xmm0
	call	sinf@PLT
	.loc 1 412 33
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE98:
	.size	_ZSt3sinf, .-_ZSt3sinf
	.section	.text._ZSt8isfinitef,"axG",@progbits,_ZSt8isfinitef,comdat
	.weak	_ZSt8isfinitef
	.hidden	_ZSt8isfinitef
	.type	_ZSt8isfinitef, @function
_ZSt8isfinitef:
.LFB120:
	.loc 1 1134 3
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	movss	%xmm0, -4(%rbp)
	.loc 1 1134 30
	movss	-4(%rbp), %xmm0
	movss	.LC0(%rip), %xmm1
	andps	%xmm0, %xmm1
	movss	.LC3(%rip), %xmm0
	ucomiss	%xmm1, %xmm0
	setb	%al
	xorl	$1, %eax
	movzbl	%al, %eax
	.loc 1 1134 34
	testl	%eax, %eax
	setne	%al
	.loc 1 1134 37
	popq	%rbp
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE120:
	.size	_ZSt8isfinitef, .-_ZSt8isfinitef
	.section	.text._ZSt4fminff,"axG",@progbits,_ZSt4fminff,comdat
	.weak	_ZSt4fminff
	.hidden	_ZSt4fminff
	.type	_ZSt4fminff, @function
_ZSt4fminff:
.LFB196:
	.loc 1 2427 3
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$16, %rsp
	movss	%xmm0, -4(%rbp)
	movss	%xmm1, -8(%rbp)
	.loc 1 2427 27
	movss	-8(%rbp), %xmm0
	movl	-4(%rbp), %eax
	movaps	%xmm0, %xmm1
	movd	%eax, %xmm0
	call	fminf@PLT
	.loc 1 2427 39
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE196:
	.size	_ZSt4fminff, .-_ZSt4fminff
	.text
	.align 2
	.globl	_ZN9opensynth7DrumKit10midiToFreqEi
	.hidden	_ZN9opensynth7DrumKit10midiToFreqEi
	.type	_ZN9opensynth7DrumKit10midiToFreqEi, @function
_ZN9opensynth7DrumKit10midiToFreqEi:
.LFB1958:
	.file 2 "/home/synth/projects/05-active-dev/open-synth/dsp/drum_synth.cpp"
	.loc 2 11 37
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$16, %rsp
	movl	%edi, -4(%rbp)
	.loc 2 12 42
	movl	-4(%rbp), %eax
	subl	$69, %eax
	.loc 2 12 29
	pxor	%xmm0, %xmm0
	cvtsi2ssl	%eax, %xmm0
	movss	.LC4(%rip), %xmm1
	divss	%xmm1, %xmm0
	movaps	%xmm0, %xmm1
	movl	.LC5(%rip), %eax
	movd	%eax, %xmm0
	call	_ZSt3powff
	.loc 2 12 55 discriminator 1
	movss	.LC6(%rip), %xmm1
	mulss	%xmm1, %xmm0
	.loc 2 13 1
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE1958:
	.size	_ZN9opensynth7DrumKit10midiToFreqEi, .-_ZN9opensynth7DrumKit10midiToFreqEi
	.align 2
	.globl	_ZN9opensynth7DrumKit8fastRandERf
	.hidden	_ZN9opensynth7DrumKit8fastRandERf
	.type	_ZN9opensynth7DrumKit8fastRandERf, @function
_ZN9opensynth7DrumKit8fastRandERf:
.LFB1959:
	.loc 2 15 44
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$32, %rsp
	movq	%rdi, -24(%rbp)
	.loc 2 15 44
	movq	%fs:40, %rax
	movq	%rax, -8(%rbp)
	xorl	%eax, %eax
	.loc 2 17 16
	movq	-24(%rbp), %rax
	movl	(%rax), %eax
	movl	%eax, -16(%rbp)
	.loc 2 18 17
	movl	-16(%rbp), %eax
	imull	$1103515245, %eax, %eax
	.loc 2 18 31
	addl	$12345, %eax
	.loc 2 18 10
	movl	%eax, -16(%rbp)
	.loc 2 19 16
	movl	-16(%rbp), %edx
	movq	-24(%rbp), %rax
	movl	%edx, (%rax)
	.loc 2 20 40
	movl	-16(%rbp), %eax
	shrl	$16, %eax
	.loc 2 20 47
	andl	$32767, %eax
	.loc 2 20 15
	movl	%eax, %eax
	testq	%rax, %rax
	js	.L19
	pxor	%xmm0, %xmm0
	cvtsi2ssq	%rax, %xmm0
	jmp	.L20
.L19:
	movq	%rax, %rdx
	shrq	%rdx
	andl	$1, %eax
	orq	%rax, %rdx
	pxor	%xmm0, %xmm0
	cvtsi2ssq	%rdx, %xmm0
	addss	%xmm0, %xmm0
.L20:
	.loc 2 20 11
	movss	.LC7(%rip), %xmm1
	divss	%xmm1, %xmm0
	movss	%xmm0, -12(%rbp)
	.loc 2 21 14
	movss	-12(%rbp), %xmm0
	addss	%xmm0, %xmm0
	.loc 2 21 23
	movss	.LC2(%rip), %xmm1
	subss	%xmm1, %xmm0
	.loc 2 22 1
	movq	-8(%rbp), %rax
	subq	%fs:40, %rax
	je	.L22
	call	__stack_chk_fail@PLT
.L22:
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE1959:
	.size	_ZN9opensynth7DrumKit8fastRandERf, .-_ZN9opensynth7DrumKit8fastRandERf
	.type	_ZN9opensynthL13fastRandFloatERf, @function
_ZN9opensynthL13fastRandFloatERf:
.LFB1960:
	.loc 2 25 54
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$32, %rsp
	movq	%rdi, -24(%rbp)
	.loc 2 25 54
	movq	%fs:40, %rax
	movq	%rax, -8(%rbp)
	xorl	%eax, %eax
	.loc 2 27 16
	movq	-24(%rbp), %rax
	movl	(%rax), %eax
	movl	%eax, -16(%rbp)
	.loc 2 28 17
	movl	-16(%rbp), %eax
	imull	$1103515245, %eax, %eax
	.loc 2 28 31
	addl	$12345, %eax
	.loc 2 28 10
	movl	%eax, -16(%rbp)
	.loc 2 29 16
	movl	-16(%rbp), %edx
	movq	-24(%rbp), %rax
	movl	%edx, (%rax)
	.loc 2 30 40
	movl	-16(%rbp), %eax
	shrl	$16, %eax
	.loc 2 30 47
	andl	$32767, %eax
	.loc 2 30 15
	movl	%eax, %eax
	testq	%rax, %rax
	js	.L24
	pxor	%xmm0, %xmm0
	cvtsi2ssq	%rax, %xmm0
	jmp	.L25
.L24:
	movq	%rax, %rdx
	shrq	%rdx
	andl	$1, %eax
	orq	%rax, %rdx
	pxor	%xmm0, %xmm0
	cvtsi2ssq	%rdx, %xmm0
	addss	%xmm0, %xmm0
.L25:
	.loc 2 30 11
	movss	.LC7(%rip), %xmm1
	divss	%xmm1, %xmm0
	movss	%xmm0, -12(%rbp)
	.loc 2 31 14
	movss	-12(%rbp), %xmm0
	addss	%xmm0, %xmm0
	.loc 2 31 23
	movss	.LC2(%rip), %xmm1
	subss	%xmm1, %xmm0
	.loc 2 32 1
	movq	-8(%rbp), %rax
	subq	%fs:40, %rax
	je	.L27
	call	__stack_chk_fail@PLT
.L27:
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE1960:
	.size	_ZN9opensynthL13fastRandFloatERf, .-_ZN9opensynthL13fastRandFloatERf
	.type	_ZN9opensynthL9pinkNoiseERfS0_S0_S0_S0_S0_S0_S0_, @function
_ZN9opensynthL9pinkNoiseERfS0_S0_S0_S0_S0_S0_S0_:
.LFB1961:
	.loc 2 35 120
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$64, %rsp
	movq	%rdi, -24(%rbp)
	movq	%rsi, -32(%rbp)
	movq	%rdx, -40(%rbp)
	movq	%rcx, -48(%rbp)
	movq	%r8, -56(%rbp)
	movq	%r9, -64(%rbp)
	.loc 2 36 32
	movq	-24(%rbp), %rax
	movq	%rax, %rdi
	call	_ZN9opensynthL13fastRandFloatERf
	movd	%xmm0, %eax
	movl	%eax, -8(%rbp)
	.loc 2 37 21
	movq	-32(%rbp), %rax
	movss	(%rax), %xmm1
	.loc 2 37 19
	movss	.LC8(%rip), %xmm0
	mulss	%xmm0, %xmm1
	.loc 2 37 32
	movss	-8(%rbp), %xmm2
	movss	.LC9(%rip), %xmm0
	mulss	%xmm2, %xmm0
	.loc 2 37 24
	addss	%xmm1, %xmm0
	.loc 2 37 8
	movq	-32(%rbp), %rax
	movss	%xmm0, (%rax)
	.loc 2 38 21
	movq	-40(%rbp), %rax
	movss	(%rax), %xmm1
	.loc 2 38 19
	movss	.LC10(%rip), %xmm0
	mulss	%xmm0, %xmm1
	.loc 2 38 32
	movss	-8(%rbp), %xmm2
	movss	.LC11(%rip), %xmm0
	mulss	%xmm2, %xmm0
	.loc 2 38 24
	addss	%xmm1, %xmm0
	.loc 2 38 8
	movq	-40(%rbp), %rax
	movss	%xmm0, (%rax)
	.loc 2 39 21
	movq	-48(%rbp), %rax
	movss	(%rax), %xmm1
	.loc 2 39 19
	movss	.LC12(%rip), %xmm0
	mulss	%xmm0, %xmm1
	.loc 2 39 32
	movss	-8(%rbp), %xmm2
	movss	.LC13(%rip), %xmm0
	mulss	%xmm2, %xmm0
	.loc 2 39 24
	addss	%xmm1, %xmm0
	.loc 2 39 8
	movq	-48(%rbp), %rax
	movss	%xmm0, (%rax)
	.loc 2 40 21
	movq	-56(%rbp), %rax
	movss	(%rax), %xmm1
	.loc 2 40 19
	movss	.LC14(%rip), %xmm0
	mulss	%xmm0, %xmm1
	.loc 2 40 32
	movss	-8(%rbp), %xmm2
	movss	.LC15(%rip), %xmm0
	mulss	%xmm2, %xmm0
	.loc 2 40 24
	addss	%xmm1, %xmm0
	.loc 2 40 8
	movq	-56(%rbp), %rax
	movss	%xmm0, (%rax)
	.loc 2 41 21
	movq	-64(%rbp), %rax
	movss	(%rax), %xmm1
	.loc 2 41 19
	movss	.LC16(%rip), %xmm0
	mulss	%xmm0, %xmm1
	.loc 2 41 32
	movss	-8(%rbp), %xmm2
	movss	.LC17(%rip), %xmm0
	mulss	%xmm2, %xmm0
	.loc 2 41 24
	addss	%xmm1, %xmm0
	.loc 2 41 8
	movq	-64(%rbp), %rax
	movss	%xmm0, (%rax)
	.loc 2 42 21
	movq	16(%rbp), %rax
	movss	(%rax), %xmm1
	.loc 2 42 19
	movss	.LC18(%rip), %xmm0
	mulss	%xmm1, %xmm0
	.loc 2 42 32
	movss	-8(%rbp), %xmm2
	movss	.LC19(%rip), %xmm1
	mulss	%xmm2, %xmm1
	.loc 2 42 24
	subss	%xmm1, %xmm0
	.loc 2 42 8
	movq	16(%rbp), %rax
	movss	%xmm0, (%rax)
	.loc 2 43 17
	movq	-32(%rbp), %rax
	movss	(%rax), %xmm1
	.loc 2 43 22
	movq	-40(%rbp), %rax
	movss	(%rax), %xmm0
	.loc 2 43 20
	addss	%xmm0, %xmm1
	.loc 2 43 27
	movq	-48(%rbp), %rax
	movss	(%rax), %xmm0
	.loc 2 43 25
	addss	%xmm0, %xmm1
	.loc 2 43 32
	movq	-56(%rbp), %rax
	movss	(%rax), %xmm0
	.loc 2 43 30
	addss	%xmm0, %xmm1
	.loc 2 43 37
	movq	-64(%rbp), %rax
	movss	(%rax), %xmm0
	.loc 2 43 35
	addss	%xmm0, %xmm1
	.loc 2 43 42
	movq	16(%rbp), %rax
	movss	(%rax), %xmm0
	.loc 2 43 40
	addss	%xmm0, %xmm1
	.loc 2 43 47
	movq	24(%rbp), %rax
	movss	(%rax), %xmm0
	.loc 2 43 45
	addss	%xmm0, %xmm1
	.loc 2 43 58
	movss	-8(%rbp), %xmm2
	movss	.LC20(%rip), %xmm0
	mulss	%xmm2, %xmm0
	.loc 2 43 11
	addss	%xmm1, %xmm0
	movss	%xmm0, -4(%rbp)
	.loc 2 44 16
	movss	-8(%rbp), %xmm1
	movss	.LC21(%rip), %xmm0
	mulss	%xmm1, %xmm0
	.loc 2 44 8
	movq	24(%rbp), %rax
	movss	%xmm0, (%rax)
	.loc 2 45 18
	movss	-4(%rbp), %xmm1
	movss	.LC22(%rip), %xmm0
	mulss	%xmm1, %xmm0
	.loc 2 46 1
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE1961:
	.size	_ZN9opensynthL9pinkNoiseERfS0_S0_S0_S0_S0_S0_S0_, .-_ZN9opensynthL9pinkNoiseERfS0_S0_S0_S0_S0_S0_S0_
	.type	_ZN9opensynthL13pitchEnvelopeEfffff, @function
_ZN9opensynthL13pitchEnvelopeEfffff:
.LFB1962:
	.loc 2 49 108
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$48, %rsp
	movss	%xmm0, -20(%rbp)
	movss	%xmm1, -24(%rbp)
	movss	%xmm2, -28(%rbp)
	movss	%xmm3, -32(%rbp)
	movss	%xmm4, -36(%rbp)
	.loc 2 50 53
	movss	-32(%rbp), %xmm0
	movaps	%xmm0, %xmm1
	divss	-36(%rbp), %xmm1
	.loc 2 50 33
	movss	-20(%rbp), %xmm0
	divss	%xmm1, %xmm0
	movd	%xmm0, %eax
	movss	.LC2(%rip), %xmm1
	movd	%eax, %xmm0
	call	_ZSt4fminff
	movd	%xmm0, %eax
	movl	%eax, -8(%rbp)
	.loc 2 52 27
	movss	-8(%rbp), %xmm1
	movss	.LC23(%rip), %xmm0
	mulss	%xmm1, %xmm0
	movaps	%xmm0, %xmm1
	movl	.LC24(%rip), %eax
	movd	%eax, %xmm0
	call	_ZSt3powff
	movd	%xmm0, %eax
	movl	%eax, -4(%rbp)
	.loc 2 53 33
	movss	-24(%rbp), %xmm0
	subss	-28(%rbp), %xmm0
	.loc 2 53 44
	mulss	-4(%rbp), %xmm0
	.loc 2 53 46
	addss	-28(%rbp), %xmm0
	.loc 2 54 1
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE1962:
	.size	_ZN9opensynthL13pitchEnvelopeEfffff, .-_ZN9opensynthL13pitchEnvelopeEfffff
	.type	_ZN9opensynthL12multiModeOscEfPfPKfS2_if, @function
_ZN9opensynthL12multiModeOscEfPfPKfS2_if:
.LFB1963:
	.loc 2 58 77
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$64, %rsp
	movss	%xmm0, -20(%rbp)
	movq	%rdi, -32(%rbp)
	movq	%rsi, -40(%rbp)
	movq	%rdx, -48(%rbp)
	movl	%ecx, -24(%rbp)
	movss	%xmm1, -52(%rbp)
	.loc 2 59 11
	pxor	%xmm0, %xmm0
	movss	%xmm0, -8(%rbp)
.LBB2:
	.loc 2 60 14
	movl	$0, -4(%rbp)
	.loc 2 60 5
	jmp	.L33
.L36:
	.loc 2 61 21
	movl	-4(%rbp), %eax
	cltq
	leaq	0(,%rax,4), %rdx
	movq	-32(%rbp), %rax
	addq	%rdx, %rax
	movss	(%rax), %xmm1
	.loc 2 61 36
	movl	-4(%rbp), %eax
	cltq
	.loc 2 61 37
	leaq	0(,%rax,4), %rdx
	movq	-40(%rbp), %rax
	addq	%rdx, %rax
	movss	(%rax), %xmm0
	.loc 2 61 39
	mulss	-52(%rbp), %xmm0
	.loc 2 61 21
	movl	-4(%rbp), %eax
	cltq
	leaq	0(,%rax,4), %rdx
	movq	-32(%rbp), %rax
	addq	%rdx, %rax
	.loc 2 61 23
	addss	%xmm1, %xmm0
	movss	%xmm0, (%rax)
	.loc 2 62 24
	movl	-4(%rbp), %eax
	cltq
	.loc 2 62 25
	leaq	0(,%rax,4), %rdx
	movq	-32(%rbp), %rax
	addq	%rdx, %rax
	movss	(%rax), %xmm0
	.loc 2 62 9
	movss	.LC2(%rip), %xmm1
	comiss	%xmm1, %xmm0
	jb	.L34
	.loc 2 62 75 discriminator 1
	movl	-4(%rbp), %eax
	cltq
	.loc 2 62 76 discriminator 1
	leaq	0(,%rax,4), %rdx
	movq	-32(%rbp), %rax
	addq	%rdx, %rax
	.loc 2 62 63 discriminator 1
	movl	(%rax), %eax
	movd	%eax, %xmm0
	call	_ZSt5floorf
	movaps	%xmm0, %xmm1
	.loc 2 62 48 discriminator 2
	movl	-4(%rbp), %eax
	cltq
	leaq	0(,%rax,4), %rdx
	movq	-32(%rbp), %rax
	addq	%rdx, %rax
	movss	(%rax), %xmm0
	movl	-4(%rbp), %eax
	cltq
	leaq	0(,%rax,4), %rdx
	movq	-32(%rbp), %rax
	addq	%rdx, %rax
	.loc 2 62 50 discriminator 2
	subss	%xmm1, %xmm0
	movss	%xmm0, (%rax)
.L34:
	.loc 2 63 57
	movl	-4(%rbp), %eax
	cltq
	.loc 2 63 58
	leaq	0(,%rax,4), %rdx
	movq	-32(%rbp), %rax
	addq	%rdx, %rax
	movss	(%rax), %xmm1
	.loc 2 63 24
	movss	.LC26(%rip), %xmm0
	mulss	%xmm0, %xmm1
	movd	%xmm1, %eax
	movd	%eax, %xmm0
	call	_ZSt3sinf
	.loc 2 63 72 discriminator 1
	movl	-4(%rbp), %eax
	cltq
	.loc 2 63 73 discriminator 1
	leaq	0(,%rax,4), %rdx
	movq	-48(%rbp), %rax
	addq	%rdx, %rax
	movss	(%rax), %xmm1
	.loc 2 63 61 discriminator 1
	mulss	%xmm1, %xmm0
	.loc 2 63 13 discriminator 1
	movss	-8(%rbp), %xmm1
	addss	%xmm1, %xmm0
	movss	%xmm0, -8(%rbp)
	.loc 2 60 5 discriminator 1
	addl	$1, -4(%rbp)
.L33:
	.loc 2 60 23 discriminator 2
	movl	-4(%rbp), %eax
	cmpl	-24(%rbp), %eax
	jl	.L36
.LBE2:
	.loc 2 65 12
	movss	-8(%rbp), %xmm0
	.loc 2 66 1
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE1963:
	.size	_ZN9opensynthL12multiModeOscEfPfPKfS2_if, .-_ZN9opensynthL12multiModeOscEfPfPKfS2_if
	.section	.text._ZN9opensynth13DrumKitPresetC2Ev,"axG",@progbits,_ZN9opensynth13DrumKitPresetC5Ev,comdat
	.align 2
	.weak	_ZN9opensynth13DrumKitPresetC2Ev
	.hidden	_ZN9opensynth13DrumKitPresetC2Ev
	.type	_ZN9opensynth13DrumKitPresetC2Ev, @function
_ZN9opensynth13DrumKitPresetC2Ev:
.LFB1972:
	.file 3 "/home/synth/projects/05-active-dev/open-synth/include/drum_synth.h"
	.loc 3 77 8
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	movq	%rdi, -8(%rbp)
.LBB3:
	.loc 3 77 8
	movl	$0, %eax
.L41:
	.loc 3 77 8 is_stmt 0 discriminator 1
	movq	-8(%rbp), %rdx
	movq	%rax, %rcx
	salq	$4, %rcx
	addq	%rcx, %rdx
	addq	$8, %rdx
	movss	.LC2(%rip), %xmm0
	movss	%xmm0, (%rdx)
	movq	-8(%rbp), %rdx
	movq	%rax, %rcx
	salq	$4, %rcx
	addq	%rcx, %rdx
	addq	$12, %rdx
	movss	.LC2(%rip), %xmm0
	movss	%xmm0, (%rdx)
	movq	-8(%rbp), %rdx
	movq	%rax, %rcx
	salq	$4, %rcx
	addq	%rcx, %rdx
	addq	$16, %rdx
	movss	.LC27(%rip), %xmm0
	movss	%xmm0, (%rdx)
	movq	-8(%rbp), %rdx
	movq	%rax, %rcx
	salq	$4, %rcx
	addq	%rcx, %rdx
	addq	$20, %rdx
	movss	.LC28(%rip), %xmm0
	movss	%xmm0, (%rdx)
	cmpq	$15, %rax
	je	.L42
	.loc 3 77 8 discriminator 2
	addq	$1, %rax
	jmp	.L41
.L42:
.LBE3:
	.loc 3 77 8 discriminator 3
	nop
	.loc 3 77 8
	popq	%rbp
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE1972:
	.size	_ZN9opensynth13DrumKitPresetC2Ev, .-_ZN9opensynth13DrumKitPresetC2Ev
	.weak	_ZN9opensynth13DrumKitPresetC1Ev
	.hidden	_ZN9opensynth13DrumKitPresetC1Ev
	.set	_ZN9opensynth13DrumKitPresetC1Ev,_ZN9opensynth13DrumKitPresetC2Ev
	.text
	.align 2
	.globl	_ZN9opensynth7DrumKitC2Ed
	.hidden	_ZN9opensynth7DrumKitC2Ed
	.type	_ZN9opensynth7DrumKitC2Ed, @function
_ZN9opensynth7DrumKitC2Ed:
.LFB1974:
	.loc 2 70 1 is_stmt 1
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	pushq	%r12
	pushq	%rbx
	subq	$32, %rsp
	.cfi_offset 12, -24
	.cfi_offset 3, -32
	movq	%rdi, -40(%rbp)
	movsd	%xmm0, -48(%rbp)
.LBB4:
	.loc 2 71 29
	movq	-40(%rbp), %rax
	movl	$4736, %edx
	movl	$0, %esi
	movq	%rax, %rdi
	call	memset@PLT
	movl	$0, %eax
.L45:
	.loc 2 71 29 is_stmt 0 discriminator 1
	movq	-40(%rbp), %rcx
	imulq	$148, %rax, %rdx
	addq	%rcx, %rdx
	addq	$12, %rdx
	movss	.LC29(%rip), %xmm0
	movss	%xmm0, (%rdx)
	movq	-40(%rbp), %rcx
	imulq	$148, %rax, %rdx
	addq	%rcx, %rdx
	addq	$32, %rdx
	movss	.LC30(%rip), %xmm0
	movss	%xmm0, (%rdx)
	movq	-40(%rbp), %rcx
	imulq	$148, %rax, %rdx
	addq	%rcx, %rdx
	addq	$76, %rdx
	movss	.LC2(%rip), %xmm0
	movss	%xmm0, (%rdx)
	movq	-40(%rbp), %rcx
	imulq	$148, %rax, %rdx
	addq	%rcx, %rdx
	addq	$80, %rdx
	movss	.LC2(%rip), %xmm0
	movss	%xmm0, (%rdx)
	cmpq	$31, %rax
	je	.L44
	.loc 2 71 29 discriminator 2
	addq	$1, %rax
	jmp	.L45
.L44:
	.loc 2 71 7 is_stmt 1 discriminator 3
	movq	-40(%rbp), %rax
	movsd	-48(%rbp), %xmm0
	movsd	%xmm0, 4736(%rax)
	.loc 2 71 29 discriminator 3
	movq	-40(%rbp), %rax
	movss	.LC31(%rip), %xmm0
	movss	%xmm0, 4744(%rax)
	movq	-40(%rbp), %rax
	addq	$4752, %rax
	movl	$17, %ebx
	movq	%rax, %r12
	jmp	.L46
.L47:
	.loc 2 71 29 is_stmt 0 discriminator 4
	movq	%r12, %rdi
	call	_ZN9opensynth13DrumKitPresetC1Ev
	.loc 2 71 29 discriminator 5
	subq	$1, %rbx
	addq	$264, %r12
.L46:
	.loc 2 71 29 discriminator 6
	testq	%rbx, %rbx
	jns	.L47
	.loc 2 71 29 discriminator 7
	movq	-40(%rbp), %rax
	movl	$0, 9504(%rax)
.LBB5:
.LBB6:
	.loc 2 73 14 is_stmt 1
	movl	$0, -20(%rbp)
	.loc 2 73 5
	jmp	.L48
.L49:
	.loc 2 74 27
	movq	-40(%rbp), %rdx
	movl	-20(%rbp), %eax
	cltq
	imulq	$148, %rax, %rax
	addq	%rdx, %rax
	addq	$1, %rax
	movb	$0, (%rax)
	.loc 2 73 5 discriminator 1
	addl	$1, -20(%rbp)
.L48:
	.loc 2 73 23 discriminator 2
	cmpl	$31, -20(%rbp)
	jle	.L49
.LBE6:
	.loc 2 76 24
	movq	-40(%rbp), %rax
	addq	$4752, %rax
	.loc 2 76 23
	movq	%rax, %rdi
	call	_ZN9opensynth18initDrumKitPresetsEPNS_13DrumKitPresetE@PLT
	.loc 2 77 17
	movq	-40(%rbp), %rax
	movl	$0, %esi
	movq	%rax, %rdi
	call	_ZN9opensynth7DrumKit12setKitPresetEi
.LBE5:
.LBE4:
	.loc 2 78 1
	nop
	addq	$32, %rsp
	popq	%rbx
	popq	%r12
	popq	%rbp
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE1974:
	.size	_ZN9opensynth7DrumKitC2Ed, .-_ZN9opensynth7DrumKitC2Ed
	.globl	_ZN9opensynth7DrumKitC1Ed
	.hidden	_ZN9opensynth7DrumKitC1Ed
	.set	_ZN9opensynth7DrumKitC1Ed,_ZN9opensynth7DrumKitC2Ed
	.align 2
	.globl	_ZN9opensynth7DrumKit13findFreeVoiceEv
	.hidden	_ZN9opensynth7DrumKit13findFreeVoiceEv
	.type	_ZN9opensynth7DrumKit13findFreeVoiceEv, @function
_ZN9opensynth7DrumKit13findFreeVoiceEv:
.LFB1976:
	.loc 2 82 30
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	movq	%rdi, -24(%rbp)
.LBB7:
	.loc 2 83 14
	movl	$0, -16(%rbp)
	.loc 2 83 5
	jmp	.L51
.L54:
	.loc 2 84 25
	movq	-24(%rbp), %rdx
	movl	-16(%rbp), %eax
	cltq
	imulq	$148, %rax, %rax
	addq	%rdx, %rax
	addq	$1, %rax
	movzbl	(%rax), %eax
	.loc 2 84 13
	xorl	$1, %eax
	.loc 2 84 9
	testb	%al, %al
	je	.L52
	.loc 2 84 40 discriminator 1
	movl	-16(%rbp), %eax
	jmp	.L53
.L52:
	.loc 2 83 5 discriminator 1
	addl	$1, -16(%rbp)
.L51:
	.loc 2 83 23 discriminator 2
	cmpl	$31, -16(%rbp)
	jle	.L54
.LBE7:
	.loc 2 87 9
	movl	$0, -12(%rbp)
	.loc 2 88 11
	pxor	%xmm0, %xmm0
	movss	%xmm0, -8(%rbp)
.LBB8:
	.loc 2 89 14
	movl	$0, -4(%rbp)
	.loc 2 89 5
	jmp	.L55
.L58:
	.loc 2 90 24
	movq	-24(%rbp), %rdx
	movl	-4(%rbp), %eax
	cltq
	imulq	$148, %rax, %rax
	addq	%rdx, %rax
	addq	$8, %rax
	movss	(%rax), %xmm0
	.loc 2 90 9
	comiss	-8(%rbp), %xmm0
	jbe	.L56
	.loc 2 91 23
	movq	-24(%rbp), %rdx
	movl	-4(%rbp), %eax
	cltq
	imulq	$148, %rax, %rax
	addq	%rdx, %rax
	addq	$8, %rax
	movss	(%rax), %xmm0
	movss	%xmm0, -8(%rbp)
	.loc 2 92 23
	movl	-4(%rbp), %eax
	movl	%eax, -12(%rbp)
.L56:
	.loc 2 89 5 discriminator 1
	addl	$1, -4(%rbp)
.L55:
	.loc 2 89 23 discriminator 2
	cmpl	$31, -4(%rbp)
	jle	.L58
.LBE8:
	.loc 2 95 12
	movl	-12(%rbp), %eax
.L53:
	.loc 2 96 1
	popq	%rbp
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE1976:
	.size	_ZN9opensynth7DrumKit13findFreeVoiceEv, .-_ZN9opensynth7DrumKit13findFreeVoiceEv
	.align 2
	.globl	_ZN9opensynth7DrumKit14configureVoiceERNS_9DrumVoiceENS_8DrumTypeERKNS_15DrumSoundConfigEfi
	.hidden	_ZN9opensynth7DrumKit14configureVoiceERNS_9DrumVoiceENS_8DrumTypeERKNS_15DrumSoundConfigEfi
	.type	_ZN9opensynth7DrumKit14configureVoiceERNS_9DrumVoiceENS_8DrumTypeERKNS_15DrumSoundConfigEfi, @function
_ZN9opensynth7DrumKit14configureVoiceERNS_9DrumVoiceENS_8DrumTypeERKNS_15DrumSoundConfigEfi:
.LFB1977:
	.loc 2 100 57
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	movq	%rdi, -24(%rbp)
	movq	%rsi, -32(%rbp)
	movb	%dl, -33(%rbp)
	movq	%rcx, -48(%rbp)
	movss	%xmm0, -40(%rbp)
	movl	%r8d, -52(%rbp)
	.loc 2 101 12
	movq	-32(%rbp), %rax
	movzbl	-33(%rbp), %edx
	movb	%dl, (%rax)
	.loc 2 102 14
	movq	-32(%rbp), %rax
	movb	$1, 1(%rax)
	.loc 2 103 16
	movq	-32(%rbp), %rax
	movss	-40(%rbp), %xmm0
	movss	%xmm0, 4(%rax)
	.loc 2 104 21
	movq	-32(%rbp), %rax
	pxor	%xmm0, %xmm0
	movss	%xmm0, 8(%rax)
	.loc 2 105 16
	movq	-32(%rbp), %rax
	movl	-52(%rbp), %edx
	movl	%edx, 72(%rax)
	.loc 2 106 18
	movq	-32(%rbp), %rax
	movss	.LC2(%rip), %xmm0
	movss	%xmm0, 80(%rax)
	.loc 2 107 13
	movq	-32(%rbp), %rax
	pxor	%xmm0, %xmm0
	movss	%xmm0, 16(%rax)
	.loc 2 108 14
	movq	-32(%rbp), %rax
	pxor	%xmm0, %xmm0
	movss	%xmm0, 64(%rax)
	.loc 2 109 16
	movq	-32(%rbp), %rax
	pxor	%xmm0, %xmm0
	movss	%xmm0, 68(%rax)
	.loc 2 110 18
	movq	-32(%rbp), %rax
	pxor	%xmm0, %xmm0
	movss	%xmm0, 52(%rax)
	.loc 2 111 18
	movq	-32(%rbp), %rax
	movl	$0, 56(%rax)
	.loc 2 112 20
	movq	-32(%rbp), %rax
	pxor	%xmm0, %xmm0
	movss	%xmm0, 44(%rax)
	.loc 2 113 20
	movq	-32(%rbp), %rax
	pxor	%xmm0, %xmm0
	movss	%xmm0, 48(%rax)
	.loc 2 115 80
	movq	-32(%rbp), %rax
	pxor	%xmm0, %xmm0
	movss	%xmm0, 108(%rax)
	.loc 2 115 73
	movq	-32(%rbp), %rax
	movss	108(%rax), %xmm0
	.loc 2 115 69
	movq	-32(%rbp), %rax
	movss	%xmm0, 104(%rax)
	.loc 2 115 62
	movq	-32(%rbp), %rax
	movss	104(%rax), %xmm0
	.loc 2 115 58
	movq	-32(%rbp), %rax
	movss	%xmm0, 100(%rax)
	.loc 2 115 51
	movq	-32(%rbp), %rax
	movss	100(%rax), %xmm0
	.loc 2 115 47
	movq	-32(%rbp), %rax
	movss	%xmm0, 96(%rax)
	.loc 2 115 40
	movq	-32(%rbp), %rax
	movss	96(%rax), %xmm0
	.loc 2 115 36
	movq	-32(%rbp), %rax
	movss	%xmm0, 92(%rax)
	.loc 2 115 29
	movq	-32(%rbp), %rax
	movss	92(%rax), %xmm0
	.loc 2 115 25
	movq	-32(%rbp), %rax
	movss	%xmm0, 88(%rax)
	.loc 2 115 18
	movq	-32(%rbp), %rax
	movss	88(%rax), %xmm0
	.loc 2 115 14
	movq	-32(%rbp), %rax
	movss	%xmm0, 84(%rax)
.LBB9:
	.loc 2 117 14
	movl	$0, -16(%rbp)
	.loc 2 117 5
	jmp	.L61
.L62:
	.loc 2 117 49 discriminator 1
	movq	-32(%rbp), %rax
	movl	-16(%rbp), %edx
	movslq	%edx, %rdx
	addq	$28, %rdx
	pxor	%xmm0, %xmm0
	movss	%xmm0, (%rax,%rdx,4)
	.loc 2 117 5 discriminator 1
	addl	$1, -16(%rbp)
.L61:
	.loc 2 117 23 discriminator 2
	cmpl	$7, -16(%rbp)
	jle	.L62
.LBE9:
	.loc 2 118 17
	movq	-32(%rbp), %rax
	movl	$0, 144(%rax)
	.loc 2 120 43
	movl	-52(%rbp), %edx
	movl	%edx, %eax
	sall	$7, %eax
	subl	%edx, %eax
	movl	%eax, %ecx
	.loc 2 120 77
	movss	-40(%rbp), %xmm1
	movss	.LC32(%rip), %xmm0
	mulss	%xmm1, %xmm0
	.loc 2 120 51
	cvttss2sil	%xmm0, %eax
	.loc 2 120 49
	addl	%ecx, %eax
	.loc 2 120 11
	pxor	%xmm0, %xmm0
	cvtsi2ssl	%eax, %xmm0
	movss	%xmm0, -8(%rbp)
	.loc 2 121 36
	pxor	%xmm0, %xmm0
	ucomiss	-8(%rbp), %xmm0
	jp	.L131
	pxor	%xmm0, %xmm0
	ucomiss	-8(%rbp), %xmm0
	je	.L63
.L131:
	.loc 2 121 36 is_stmt 0 discriminator 1
	movss	-8(%rbp), %xmm0
	jmp	.L65
.L63:
	.loc 2 121 36 discriminator 2
	movss	.LC2(%rip), %xmm0
.L65:
	.loc 2 121 18 is_stmt 1 discriminator 3
	movq	-32(%rbp), %rax
	movss	%xmm0, 20(%rax)
	.loc 2 123 20
	movq	-48(%rbp), %rax
	movss	(%rax), %xmm0
	.loc 2 123 14
	movq	-32(%rbp), %rax
	movss	%xmm0, 76(%rax)
	.loc 2 124 11
	movq	-48(%rbp), %rax
	movss	(%rax), %xmm0
	movss	%xmm0, -4(%rbp)
	.loc 2 125 25
	movq	-48(%rbp), %rax
	movss	8(%rax), %xmm0
	.loc 2 125 40
	pxor	%xmm1, %xmm1
	comiss	%xmm1, %xmm0
	jb	.L148
	.loc 2 125 11 discriminator 1
	movq	-48(%rbp), %rax
	movss	8(%rax), %xmm0
	movss	%xmm0, -12(%rbp)
	jmp	.L68
.L148:
	.loc 2 125 11 is_stmt 0 discriminator 2
	movss	.LC27(%rip), %xmm0
	movss	%xmm0, -12(%rbp)
.L68:
	.loc 2 127 5 is_stmt 1
	cmpb	$14, -33(%rbp)
	je	.L69
	cmpb	$14, -33(%rbp)
	ja	.L164
	cmpb	$13, -33(%rbp)
	je	.L71
	cmpb	$13, -33(%rbp)
	ja	.L164
	cmpb	$12, -33(%rbp)
	je	.L72
	cmpb	$12, -33(%rbp)
	ja	.L164
	cmpb	$11, -33(%rbp)
	je	.L73
	cmpb	$11, -33(%rbp)
	ja	.L164
	cmpb	$10, -33(%rbp)
	je	.L74
	cmpb	$10, -33(%rbp)
	ja	.L164
	cmpb	$9, -33(%rbp)
	je	.L75
	cmpb	$9, -33(%rbp)
	ja	.L164
	cmpb	$8, -33(%rbp)
	je	.L76
	cmpb	$8, -33(%rbp)
	ja	.L164
	cmpb	$7, -33(%rbp)
	je	.L77
	cmpb	$7, -33(%rbp)
	ja	.L164
	cmpb	$6, -33(%rbp)
	je	.L78
	cmpb	$6, -33(%rbp)
	ja	.L164
	cmpb	$5, -33(%rbp)
	je	.L79
	cmpb	$5, -33(%rbp)
	ja	.L164
	cmpb	$4, -33(%rbp)
	je	.L80
	cmpb	$4, -33(%rbp)
	ja	.L164
	cmpb	$3, -33(%rbp)
	je	.L81
	cmpb	$3, -33(%rbp)
	ja	.L164
	cmpb	$2, -33(%rbp)
	je	.L82
	cmpb	$2, -33(%rbp)
	ja	.L164
	cmpb	$0, -33(%rbp)
	je	.L83
	cmpb	$1, -33(%rbp)
	je	.L84
	.loc 2 254 13
	jmp	.L164
.L83:
	.loc 2 129 43
	movss	-12(%rbp), %xmm0
	pxor	%xmm1, %xmm1
	comiss	%xmm1, %xmm0
	jb	.L149
	.loc 2 129 43 is_stmt 0 discriminator 1
	movss	-12(%rbp), %xmm0
	jmp	.L87
.L149:
	.loc 2 129 43 discriminator 2
	movss	.LC33(%rip), %xmm0
.L87:
	.loc 2 129 25 is_stmt 1 discriminator 3
	movq	-32(%rbp), %rax
	movss	%xmm0, 12(%rax)
	.loc 2 130 35
	movss	-4(%rbp), %xmm1
	movss	.LC34(%rip), %xmm0
	mulss	%xmm1, %xmm0
	.loc 2 130 26
	movq	-32(%rbp), %rax
	movss	%xmm0, 24(%rax)
	.loc 2 131 34
	movss	-4(%rbp), %xmm1
	movss	.LC35(%rip), %xmm0
	mulss	%xmm1, %xmm0
	.loc 2 131 26
	movq	-32(%rbp), %rax
	movss	%xmm0, 28(%rax)
	.loc 2 132 30
	movq	-32(%rbp), %rax
	movss	.LC36(%rip), %xmm0
	movss	%xmm0, 32(%rax)
	.loc 2 133 26
	movq	-32(%rbp), %rax
	movss	.LC37(%rip), %xmm0
	movss	%xmm0, 36(%rax)
	.loc 2 134 26
	movq	-32(%rbp), %rax
	movss	.LC2(%rip), %xmm0
	movss	%xmm0, 40(%rax)
	.loc 2 135 13
	jmp	.L88
.L84:
	.loc 2 138 43
	movss	-12(%rbp), %xmm0
	pxor	%xmm1, %xmm1
	comiss	%xmm1, %xmm0
	jb	.L150
	.loc 2 138 43 is_stmt 0 discriminator 1
	movss	-12(%rbp), %xmm0
	jmp	.L91
.L150:
	.loc 2 138 43 discriminator 2
	movss	.LC38(%rip), %xmm0
.L91:
	.loc 2 138 25 is_stmt 1 discriminator 3
	movq	-32(%rbp), %rax
	movss	%xmm0, 12(%rax)
	.loc 2 139 32
	movq	-48(%rbp), %rax
	movss	12(%rax), %xmm0
	.loc 2 139 26
	movq	-32(%rbp), %rax
	movss	%xmm0, 40(%rax)
	.loc 2 140 39
	movq	-48(%rbp), %rax
	movss	12(%rax), %xmm1
	.loc 2 140 33
	movss	.LC2(%rip), %xmm0
	subss	%xmm1, %xmm0
	.loc 2 140 26
	movq	-32(%rbp), %rax
	movss	%xmm0, 36(%rax)
	.loc 2 141 35
	movss	-4(%rbp), %xmm1
	movss	.LC39(%rip), %xmm0
	mulss	%xmm1, %xmm0
	.loc 2 141 26
	movq	-32(%rbp), %rax
	movss	%xmm0, 24(%rax)
	.loc 2 142 35
	movss	-4(%rbp), %xmm1
	movss	.LC40(%rip), %xmm0
	mulss	%xmm1, %xmm0
	.loc 2 142 26
	movq	-32(%rbp), %rax
	movss	%xmm0, 28(%rax)
	.loc 2 143 30
	movq	-32(%rbp), %rax
	movss	.LC41(%rip), %xmm0
	movss	%xmm0, 32(%rax)
	.loc 2 144 13
	jmp	.L88
.L82:
	.loc 2 147 43
	movss	-12(%rbp), %xmm0
	pxor	%xmm1, %xmm1
	comiss	%xmm1, %xmm0
	jb	.L151
	.loc 2 147 43 is_stmt 0 discriminator 1
	movss	-12(%rbp), %xmm0
	jmp	.L94
.L151:
	.loc 2 147 43 discriminator 2
	movss	.LC42(%rip), %xmm0
.L94:
	.loc 2 147 25 is_stmt 1 discriminator 3
	movq	-32(%rbp), %rax
	movss	%xmm0, 12(%rax)
	.loc 2 148 26
	movq	-32(%rbp), %rax
	movss	.LC2(%rip), %xmm0
	movss	%xmm0, 36(%rax)
	.loc 2 149 26
	movq	-32(%rbp), %rax
	pxor	%xmm0, %xmm0
	movss	%xmm0, 40(%rax)
	.loc 2 150 13
	jmp	.L88
.L81:
	.loc 2 153 43
	movss	-12(%rbp), %xmm0
	pxor	%xmm1, %xmm1
	comiss	%xmm1, %xmm0
	jb	.L152
	.loc 2 153 43 is_stmt 0 discriminator 1
	movss	-12(%rbp), %xmm0
	jmp	.L97
.L152:
	.loc 2 153 43 discriminator 2
	movss	.LC33(%rip), %xmm0
.L97:
	.loc 2 153 25 is_stmt 1 discriminator 3
	movq	-32(%rbp), %rax
	movss	%xmm0, 12(%rax)
	.loc 2 154 26
	movq	-32(%rbp), %rax
	movss	.LC2(%rip), %xmm0
	movss	%xmm0, 36(%rax)
	.loc 2 155 26
	movq	-32(%rbp), %rax
	pxor	%xmm0, %xmm0
	movss	%xmm0, 40(%rax)
	.loc 2 156 13
	jmp	.L88
.L80:
	.loc 2 159 43
	movss	-12(%rbp), %xmm0
	pxor	%xmm1, %xmm1
	comiss	%xmm1, %xmm0
	jb	.L153
	.loc 2 159 43 is_stmt 0 discriminator 1
	movss	-12(%rbp), %xmm0
	jmp	.L100
.L153:
	.loc 2 159 43 discriminator 2
	movss	.LC43(%rip), %xmm0
.L100:
	.loc 2 159 25 is_stmt 1 discriminator 3
	movq	-32(%rbp), %rax
	movss	%xmm0, 12(%rax)
	.loc 2 160 35
	movss	-4(%rbp), %xmm1
	movss	.LC44(%rip), %xmm0
	mulss	%xmm1, %xmm0
	.loc 2 160 26
	movq	-32(%rbp), %rax
	movss	%xmm0, 24(%rax)
	.loc 2 161 35
	movss	-4(%rbp), %xmm1
	movss	.LC45(%rip), %xmm0
	mulss	%xmm1, %xmm0
	.loc 2 161 26
	movq	-32(%rbp), %rax
	movss	%xmm0, 28(%rax)
	.loc 2 162 30
	movq	-32(%rbp), %rax
	movss	.LC46(%rip), %xmm0
	movss	%xmm0, 32(%rax)
	.loc 2 163 26
	movq	-32(%rbp), %rax
	movss	.LC41(%rip), %xmm0
	movss	%xmm0, 36(%rax)
	.loc 2 164 26
	movq	-32(%rbp), %rax
	movss	.LC2(%rip), %xmm0
	movss	%xmm0, 40(%rax)
	.loc 2 165 13
	jmp	.L88
.L79:
	.loc 2 168 43
	movss	-12(%rbp), %xmm0
	pxor	%xmm1, %xmm1
	comiss	%xmm1, %xmm0
	jb	.L154
	.loc 2 168 43 is_stmt 0 discriminator 1
	movss	-12(%rbp), %xmm0
	jmp	.L103
.L154:
	.loc 2 168 43 discriminator 2
	movss	.LC47(%rip), %xmm0
.L103:
	.loc 2 168 25 is_stmt 1 discriminator 3
	movq	-32(%rbp), %rax
	movss	%xmm0, 12(%rax)
	.loc 2 169 35
	movss	-4(%rbp), %xmm1
	movss	.LC48(%rip), %xmm0
	mulss	%xmm1, %xmm0
	.loc 2 169 26
	movq	-32(%rbp), %rax
	movss	%xmm0, 24(%rax)
	.loc 2 170 34
	movss	-4(%rbp), %xmm1
	movss	.LC49(%rip), %xmm0
	mulss	%xmm1, %xmm0
	.loc 2 170 26
	movq	-32(%rbp), %rax
	movss	%xmm0, 28(%rax)
	.loc 2 171 30
	movq	-32(%rbp), %rax
	movss	.LC36(%rip), %xmm0
	movss	%xmm0, 32(%rax)
	.loc 2 172 26
	movq	-32(%rbp), %rax
	movss	.LC41(%rip), %xmm0
	movss	%xmm0, 36(%rax)
	.loc 2 173 26
	movq	-32(%rbp), %rax
	movss	.LC2(%rip), %xmm0
	movss	%xmm0, 40(%rax)
	.loc 2 174 13
	jmp	.L88
.L78:
	.loc 2 177 43
	movss	-12(%rbp), %xmm0
	pxor	%xmm1, %xmm1
	comiss	%xmm1, %xmm0
	jb	.L155
	.loc 2 177 43 is_stmt 0 discriminator 1
	movss	-12(%rbp), %xmm0
	jmp	.L106
.L155:
	.loc 2 177 43 discriminator 2
	movss	.LC50(%rip), %xmm0
.L106:
	.loc 2 177 25 is_stmt 1 discriminator 3
	movq	-32(%rbp), %rax
	movss	%xmm0, 12(%rax)
	.loc 2 178 35
	movss	-4(%rbp), %xmm1
	movss	.LC51(%rip), %xmm0
	mulss	%xmm1, %xmm0
	.loc 2 178 26
	movq	-32(%rbp), %rax
	movss	%xmm0, 24(%rax)
	.loc 2 179 34
	movss	-4(%rbp), %xmm1
	movss	.LC52(%rip), %xmm0
	mulss	%xmm1, %xmm0
	.loc 2 179 26
	movq	-32(%rbp), %rax
	movss	%xmm0, 28(%rax)
	.loc 2 180 30
	movq	-32(%rbp), %rax
	movss	.LC53(%rip), %xmm0
	movss	%xmm0, 32(%rax)
	.loc 2 181 26
	movq	-32(%rbp), %rax
	movss	.LC41(%rip), %xmm0
	movss	%xmm0, 36(%rax)
	.loc 2 182 26
	movq	-32(%rbp), %rax
	movss	.LC2(%rip), %xmm0
	movss	%xmm0, 40(%rax)
	.loc 2 183 13
	jmp	.L88
.L77:
	.loc 2 186 43
	movss	-12(%rbp), %xmm0
	pxor	%xmm1, %xmm1
	comiss	%xmm1, %xmm0
	jb	.L156
	.loc 2 186 43 is_stmt 0 discriminator 1
	movss	-12(%rbp), %xmm0
	jmp	.L109
.L156:
	.loc 2 186 43 discriminator 2
	movss	.LC54(%rip), %xmm0
.L109:
	.loc 2 186 25 is_stmt 1 discriminator 3
	movq	-32(%rbp), %rax
	movss	%xmm0, 12(%rax)
	.loc 2 187 26
	movq	-32(%rbp), %rax
	movss	.LC2(%rip), %xmm0
	movss	%xmm0, 36(%rax)
	.loc 2 188 26
	movq	-32(%rbp), %rax
	pxor	%xmm0, %xmm0
	movss	%xmm0, 40(%rax)
	.loc 2 189 13
	jmp	.L88
.L76:
	.loc 2 192 43
	movss	-12(%rbp), %xmm0
	pxor	%xmm1, %xmm1
	comiss	%xmm1, %xmm0
	jb	.L157
	.loc 2 192 43 is_stmt 0 discriminator 1
	movss	-12(%rbp), %xmm0
	jmp	.L112
.L157:
	.loc 2 192 43 discriminator 2
	movss	.LC2(%rip), %xmm0
.L112:
	.loc 2 192 25 is_stmt 1 discriminator 3
	movq	-32(%rbp), %rax
	movss	%xmm0, 12(%rax)
	.loc 2 193 26
	movq	-32(%rbp), %rax
	movss	.LC2(%rip), %xmm0
	movss	%xmm0, 36(%rax)
	.loc 2 194 32
	movq	-48(%rbp), %rax
	movss	12(%rax), %xmm0
	.loc 2 194 26
	movq	-32(%rbp), %rax
	movss	%xmm0, 40(%rax)
	.loc 2 195 35
	movss	-4(%rbp), %xmm1
	movss	.LC55(%rip), %xmm0
	mulss	%xmm1, %xmm0
	.loc 2 195 26
	movq	-32(%rbp), %rax
	movss	%xmm0, 24(%rax)
	.loc 2 196 35
	movss	-4(%rbp), %xmm1
	movss	.LC55(%rip), %xmm0
	mulss	%xmm1, %xmm0
	.loc 2 196 26
	movq	-32(%rbp), %rax
	movss	%xmm0, 28(%rax)
	.loc 2 197 30
	movq	-32(%rbp), %rax
	pxor	%xmm0, %xmm0
	movss	%xmm0, 32(%rax)
	.loc 2 198 13
	jmp	.L88
.L75:
	.loc 2 201 43
	movss	-12(%rbp), %xmm0
	pxor	%xmm1, %xmm1
	comiss	%xmm1, %xmm0
	jb	.L158
	.loc 2 201 43 is_stmt 0 discriminator 1
	movss	-12(%rbp), %xmm0
	jmp	.L115
.L158:
	.loc 2 201 43 discriminator 2
	movss	.LC56(%rip), %xmm0
.L115:
	.loc 2 201 25 is_stmt 1 discriminator 3
	movq	-32(%rbp), %rax
	movss	%xmm0, 12(%rax)
	.loc 2 202 26
	movq	-32(%rbp), %rax
	movss	.LC2(%rip), %xmm0
	movss	%xmm0, 36(%rax)
	.loc 2 203 26
	movq	-32(%rbp), %rax
	pxor	%xmm0, %xmm0
	movss	%xmm0, 40(%rax)
	.loc 2 204 26
	movq	-32(%rbp), %rax
	pxor	%xmm0, %xmm0
	movss	%xmm0, 52(%rax)
	.loc 2 205 26
	movq	-32(%rbp), %rax
	movl	$0, 56(%rax)
	.loc 2 206 30
	movq	-32(%rbp), %rax
	movss	.LC57(%rip), %xmm0
	movss	%xmm0, 32(%rax)
	.loc 2 207 13
	jmp	.L88
.L74:
	.loc 2 210 43
	movss	-12(%rbp), %xmm0
	pxor	%xmm1, %xmm1
	comiss	%xmm1, %xmm0
	jb	.L159
	.loc 2 210 43 is_stmt 0 discriminator 1
	movss	-12(%rbp), %xmm0
	jmp	.L118
.L159:
	.loc 2 210 43 discriminator 2
	movss	.LC57(%rip), %xmm0
.L118:
	.loc 2 210 25 is_stmt 1 discriminator 3
	movq	-32(%rbp), %rax
	movss	%xmm0, 12(%rax)
	.loc 2 211 36
	movss	-4(%rbp), %xmm1
	movss	.LC58(%rip), %xmm0
	mulss	%xmm1, %xmm0
	.loc 2 211 26
	movq	-32(%rbp), %rax
	movss	%xmm0, 24(%rax)
	.loc 2 212 36
	movss	-4(%rbp), %xmm1
	movss	.LC58(%rip), %xmm0
	mulss	%xmm1, %xmm0
	.loc 2 212 26
	movq	-32(%rbp), %rax
	movss	%xmm0, 28(%rax)
	.loc 2 213 30
	movq	-32(%rbp), %rax
	pxor	%xmm0, %xmm0
	movss	%xmm0, 32(%rax)
	.loc 2 214 26
	movq	-32(%rbp), %rax
	movss	.LC29(%rip), %xmm0
	movss	%xmm0, 40(%rax)
	.loc 2 215 26
	movq	-32(%rbp), %rax
	movss	.LC24(%rip), %xmm0
	movss	%xmm0, 36(%rax)
	.loc 2 216 13
	jmp	.L88
.L73:
	.loc 2 219 43
	movss	-12(%rbp), %xmm0
	pxor	%xmm1, %xmm1
	comiss	%xmm1, %xmm0
	jb	.L160
	.loc 2 219 43 is_stmt 0 discriminator 1
	movss	-12(%rbp), %xmm0
	jmp	.L121
.L160:
	.loc 2 219 43 discriminator 2
	movss	.LC59(%rip), %xmm0
.L121:
	.loc 2 219 25 is_stmt 1 discriminator 3
	movq	-32(%rbp), %rax
	movss	%xmm0, 12(%rax)
	.loc 2 220 35
	movss	-4(%rbp), %xmm1
	movss	.LC60(%rip), %xmm0
	mulss	%xmm1, %xmm0
	.loc 2 220 26
	movq	-32(%rbp), %rax
	movss	%xmm0, 24(%rax)
	.loc 2 221 35
	movss	-4(%rbp), %xmm1
	movss	.LC60(%rip), %xmm0
	mulss	%xmm1, %xmm0
	.loc 2 221 26
	movq	-32(%rbp), %rax
	movss	%xmm0, 28(%rax)
	.loc 2 222 30
	movq	-32(%rbp), %rax
	pxor	%xmm0, %xmm0
	movss	%xmm0, 32(%rax)
	.loc 2 223 26
	movq	-32(%rbp), %rax
	movss	.LC2(%rip), %xmm0
	movss	%xmm0, 40(%rax)
	.loc 2 224 26
	movq	-32(%rbp), %rax
	pxor	%xmm0, %xmm0
	movss	%xmm0, 36(%rax)
	.loc 2 225 35
	movss	-4(%rbp), %xmm1
	movss	.LC61(%rip), %xmm0
	mulss	%xmm1, %xmm0
	.loc 2 225 26
	movq	-32(%rbp), %rax
	movss	%xmm0, 60(%rax)
	.loc 2 226 13
	jmp	.L88
.L72:
	.loc 2 229 43
	movss	-12(%rbp), %xmm0
	pxor	%xmm1, %xmm1
	comiss	%xmm1, %xmm0
	jb	.L161
	.loc 2 229 43 is_stmt 0 discriminator 1
	movss	-12(%rbp), %xmm0
	jmp	.L124
.L161:
	.loc 2 229 43 discriminator 2
	movss	.LC62(%rip), %xmm0
.L124:
	.loc 2 229 25 is_stmt 1 discriminator 3
	movq	-32(%rbp), %rax
	movss	%xmm0, 12(%rax)
	.loc 2 230 26
	movq	-32(%rbp), %rax
	movss	.LC2(%rip), %xmm0
	movss	%xmm0, 36(%rax)
	.loc 2 231 26
	movq	-32(%rbp), %rax
	pxor	%xmm0, %xmm0
	movss	%xmm0, 40(%rax)
	.loc 2 232 15
	movq	-32(%rbp), %rax
	movss	4(%rax), %xmm1
	.loc 2 232 24
	movss	.LC28(%rip), %xmm0
	mulss	%xmm1, %xmm0
	movq	-32(%rbp), %rax
	movss	%xmm0, 4(%rax)
	.loc 2 233 13
	jmp	.L88
.L71:
	.loc 2 236 43
	movss	-12(%rbp), %xmm0
	pxor	%xmm1, %xmm1
	comiss	%xmm1, %xmm0
	jb	.L162
	.loc 2 236 43 is_stmt 0 discriminator 1
	movss	-12(%rbp), %xmm0
	jmp	.L127
.L162:
	.loc 2 236 43 discriminator 2
	movss	.LC56(%rip), %xmm0
.L127:
	.loc 2 236 25 is_stmt 1 discriminator 3
	movq	-32(%rbp), %rax
	movss	%xmm0, 12(%rax)
	.loc 2 237 35
	movss	-4(%rbp), %xmm1
	movss	.LC63(%rip), %xmm0
	mulss	%xmm1, %xmm0
	.loc 2 237 26
	movq	-32(%rbp), %rax
	movss	%xmm0, 24(%rax)
	.loc 2 238 35
	movss	-4(%rbp), %xmm1
	movss	.LC64(%rip), %xmm0
	mulss	%xmm1, %xmm0
	.loc 2 238 26
	movq	-32(%rbp), %rax
	movss	%xmm0, 28(%rax)
	.loc 2 239 30
	movq	-32(%rbp), %rax
	movss	.LC53(%rip), %xmm0
	movss	%xmm0, 32(%rax)
	.loc 2 240 26
	movq	-32(%rbp), %rax
	movss	.LC2(%rip), %xmm0
	movss	%xmm0, 40(%rax)
	.loc 2 241 26
	movq	-32(%rbp), %rax
	movss	.LC30(%rip), %xmm0
	movss	%xmm0, 36(%rax)
	.loc 2 242 13
	jmp	.L88
.L69:
	.loc 2 245 43
	movss	-12(%rbp), %xmm0
	pxor	%xmm1, %xmm1
	comiss	%xmm1, %xmm0
	jb	.L163
	.loc 2 245 43 is_stmt 0 discriminator 1
	movss	-12(%rbp), %xmm0
	jmp	.L130
.L163:
	.loc 2 245 43 discriminator 2
	movss	.LC65(%rip), %xmm0
.L130:
	.loc 2 245 25 is_stmt 1 discriminator 3
	movq	-32(%rbp), %rax
	movss	%xmm0, 12(%rax)
	.loc 2 246 35
	movss	-4(%rbp), %xmm1
	movss	.LC66(%rip), %xmm0
	mulss	%xmm1, %xmm0
	.loc 2 246 26
	movq	-32(%rbp), %rax
	movss	%xmm0, 24(%rax)
	.loc 2 247 35
	movss	-4(%rbp), %xmm1
	movss	.LC48(%rip), %xmm0
	mulss	%xmm1, %xmm0
	.loc 2 247 26
	movq	-32(%rbp), %rax
	movss	%xmm0, 28(%rax)
	.loc 2 248 30
	movq	-32(%rbp), %rax
	movss	.LC41(%rip), %xmm0
	movss	%xmm0, 32(%rax)
	.loc 2 249 26
	movq	-32(%rbp), %rax
	movss	.LC2(%rip), %xmm0
	movss	%xmm0, 40(%rax)
	.loc 2 250 26
	movq	-32(%rbp), %rax
	movss	.LC30(%rip), %xmm0
	movss	%xmm0, 36(%rax)
	.loc 2 251 13
	jmp	.L88
.L164:
	.loc 2 254 13
	nop
.L88:
	.loc 2 256 1
	nop
	popq	%rbp
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE1977:
	.size	_ZN9opensynth7DrumKit14configureVoiceERNS_9DrumVoiceENS_8DrumTypeERKNS_15DrumSoundConfigEfi, .-_ZN9opensynth7DrumKit14configureVoiceERNS_9DrumVoiceENS_8DrumTypeERKNS_15DrumSoundConfigEfi
	.align 2
	.globl	_ZN9opensynth7DrumKit6noteOnEif
	.hidden	_ZN9opensynth7DrumKit6noteOnEif
	.type	_ZN9opensynth7DrumKit6noteOnEif, @function
_ZN9opensynth7DrumKit6noteOnEif:
.LFB1978:
	.loc 2 260 52
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$48, %rsp
	movq	%rdi, -40(%rbp)
	movl	%esi, -44(%rbp)
	movss	%xmm0, -48(%rbp)
	.loc 2 261 36
	movl	-44(%rbp), %eax
	movl	%eax, %edi
	call	_ZN9opensynth17gm2NoteToDrumTypeEi@PLT
	.loc 2 261 36 is_stmt 0 discriminator 1
	movl	%eax, -16(%rbp)
	.loc 2 262 5 is_stmt 1
	cmpl	$0, -16(%rbp)
	js	.L172
	.loc 2 264 14
	movl	-16(%rbp), %eax
	movb	%al, -21(%rbp)
.LBB10:
	.loc 2 266 5
	cmpb	$2, -21(%rbp)
	jne	.L168
.LBB11:
.LBB12:
	.loc 2 267 18
	movl	$0, -20(%rbp)
	.loc 2 267 9
	jmp	.L169
.L171:
	.loc 2 268 28
	movq	-40(%rbp), %rdx
	movl	-20(%rbp), %eax
	cltq
	imulq	$148, %rax, %rax
	addq	%rdx, %rax
	addq	$1, %rax
	movzbl	(%rax), %eax
	.loc 2 268 13
	testb	%al, %al
	je	.L170
	.loc 2 268 49 discriminator 1
	movq	-40(%rbp), %rdx
	movl	-20(%rbp), %eax
	cltq
	imulq	$148, %rax, %rax
	addq	%rdx, %rax
	movzbl	(%rax), %eax
	.loc 2 268 35 discriminator 1
	cmpb	$3, %al
	jne	.L170
	.loc 2 269 39
	movq	-40(%rbp), %rdx
	movl	-20(%rbp), %eax
	cltq
	imulq	$148, %rax, %rax
	addq	%rdx, %rax
	addq	$80, %rax
	pxor	%xmm0, %xmm0
	movss	%xmm0, (%rax)
.L170:
	.loc 2 267 9 discriminator 1
	addl	$1, -20(%rbp)
.L169:
	.loc 2 267 27 discriminator 2
	cmpl	$31, -20(%rbp)
	jle	.L171
.L168:
.LBE12:
.LBE11:
.LBE10:
	.loc 2 274 28
	movq	-40(%rbp), %rax
	movq	%rax, %rdi
	call	_ZN9opensynth7DrumKit13findFreeVoiceEv
	movl	%eax, -12(%rbp)
	.loc 2 275 40
	movq	-40(%rbp), %rax
	movl	9504(%rax), %eax
	.loc 2 275 28
	movl	-16(%rbp), %edx
	movslq	%edx, %rdx
	salq	$4, %rdx
	cltq
	imulq	$264, %rax, %rax
	addq	%rdx, %rax
	leaq	4752(%rax), %rdx
	movq	-40(%rbp), %rax
	addq	%rdx, %rax
	addq	$8, %rax
	movq	%rax, -8(%rbp)
	.loc 2 276 31
	movl	-12(%rbp), %eax
	cltq
	imulq	$148, %rax, %rdx
	movq	-40(%rbp), %rax
	leaq	(%rdx,%rax), %rdi
	.loc 2 276 19
	movl	-44(%rbp), %r8d
	movl	-48(%rbp), %esi
	movq	-8(%rbp), %rcx
	movzbl	-21(%rbp), %edx
	movq	-40(%rbp), %rax
	movd	%esi, %xmm0
	movq	%rdi, %rsi
	movq	%rax, %rdi
	call	_ZN9opensynth7DrumKit14configureVoiceERNS_9DrumVoiceENS_8DrumTypeERKNS_15DrumSoundConfigEfi
	jmp	.L165
.L172:
	.loc 2 262 22 discriminator 1
	nop
.L165:
	.loc 2 277 1
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE1978:
	.size	_ZN9opensynth7DrumKit6noteOnEif, .-_ZN9opensynth7DrumKit6noteOnEif
	.align 2
	.globl	_ZN9opensynth7DrumKit7noteOffEi
	.hidden	_ZN9opensynth7DrumKit7noteOffEi
	.type	_ZN9opensynth7DrumKit7noteOffEi, @function
_ZN9opensynth7DrumKit7noteOffEi:
.LFB1979:
	.loc 2 279 37
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$32, %rsp
	movq	%rdi, -24(%rbp)
	movl	%esi, -28(%rbp)
	.loc 2 280 36
	movl	-28(%rbp), %eax
	movl	%eax, %edi
	call	_ZN9opensynth17gm2NoteToDrumTypeEi@PLT
	.loc 2 280 36 is_stmt 0 discriminator 1
	movl	%eax, -4(%rbp)
	.loc 2 281 5 is_stmt 1
	cmpl	$0, -4(%rbp)
	js	.L180
	.loc 2 282 14
	movl	-4(%rbp), %eax
	movb	%al, -9(%rbp)
.LBB13:
	.loc 2 284 14
	movl	$0, -8(%rbp)
	.loc 2 284 5
	jmp	.L176
.L179:
	.loc 2 285 24
	movq	-24(%rbp), %rdx
	movl	-8(%rbp), %eax
	cltq
	imulq	$148, %rax, %rax
	addq	%rdx, %rax
	addq	$1, %rax
	movzbl	(%rax), %eax
	.loc 2 285 9
	testb	%al, %al
	je	.L177
	.loc 2 286 13
	cmpb	$2, -9(%rbp)
	jne	.L178
	.loc 2 286 59 discriminator 1
	movq	-24(%rbp), %rdx
	movl	-8(%rbp), %eax
	cltq
	imulq	$148, %rax, %rax
	addq	%rdx, %rax
	movzbl	(%rax), %eax
	.loc 2 286 45 discriminator 1
	cmpb	$3, %al
	jne	.L178
	.loc 2 287 39
	movq	-24(%rbp), %rdx
	movl	-8(%rbp), %eax
	cltq
	imulq	$148, %rax, %rax
	addq	%rdx, %rax
	addq	$80, %rax
	pxor	%xmm0, %xmm0
	movss	%xmm0, (%rax)
.L178:
	.loc 2 289 28
	movq	-24(%rbp), %rdx
	movl	-8(%rbp), %eax
	cltq
	imulq	$148, %rax, %rax
	addq	%rdx, %rax
	movzbl	(%rax), %eax
	.loc 2 289 13
	cmpb	%al, -9(%rbp)
	jne	.L177
	.loc 2 289 41 discriminator 1
	cmpb	$3, -9(%rbp)
	jne	.L177
	.loc 2 290 39
	movq	-24(%rbp), %rdx
	movl	-8(%rbp), %eax
	cltq
	imulq	$148, %rax, %rax
	addq	%rdx, %rax
	addq	$80, %rax
	pxor	%xmm0, %xmm0
	movss	%xmm0, (%rax)
.L177:
	.loc 2 284 5 discriminator 1
	addl	$1, -8(%rbp)
.L176:
	.loc 2 284 23 discriminator 2
	cmpl	$31, -8(%rbp)
	jle	.L179
	jmp	.L173
.L180:
.LBE13:
	.loc 2 281 22 discriminator 1
	nop
.L173:
	.loc 2 294 1
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE1979:
	.size	_ZN9opensynth7DrumKit7noteOffEi, .-_ZN9opensynth7DrumKit7noteOffEi
	.section	.rodata
.LC67:
	.string	"!(__hi < __lo)"
	.align 8
.LC68:
	.string	"constexpr const _Tp& std::clamp(const _Tp&, const _Tp&, const _Tp&) [with _Tp = float]"
	.align 8
.LC69:
	.string	"/usr/include/c++/16.1.1/bits/stl_algo.h"
	.section	.text._ZSt5clampIfERKT_S2_S2_S2_,"axG",@progbits,_ZSt5clampIfERKT_S2_S2_S2_,comdat
	.weak	_ZSt5clampIfERKT_S2_S2_S2_
	.hidden	_ZSt5clampIfERKT_S2_S2_S2_
	.type	_ZSt5clampIfERKT_S2_S2_S2_, @function
_ZSt5clampIfERKT_S2_S2_S2_:
.LFB1981:
	.file 4 "/usr/include/c++/16.1.1/bits/stl_algo.h"
	.loc 4 3614 5
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$32, %rsp
	movq	%rdi, -8(%rbp)
	movq	%rsi, -16(%rbp)
	movq	%rdx, -24(%rbp)
	.loc 4 3616 7
	movq	-24(%rbp), %rax
	movss	(%rax), %xmm1
	movq	-16(%rbp), %rax
	movss	(%rax), %xmm0
	comiss	%xmm1, %xmm0
	seta	%al
	movzbl	%al, %eax
	.loc 4 3616 7 is_stmt 0 discriminator 1
	testq	%rax, %rax
	je	.L182
	.loc 4 3616 7 discriminator 2
	leaq	.LC67(%rip), %rcx
	leaq	.LC68(%rip), %rdx
	leaq	.LC69(%rip), %rax
	movl	$3616, %esi
	movq	%rax, %rdi
	call	_ZSt21__glibcxx_assert_failPKciS0_S0_@PLT
.L182:
	.loc 4 3617 22 is_stmt 1
	movq	-16(%rbp), %rdx
	movq	-8(%rbp), %rax
	movq	%rdx, %rsi
	movq	%rax, %rdi
	call	_ZSt3maxIfERKT_S2_S2_
	movq	%rax, %rdx
	.loc 4 3617 22 is_stmt 0 discriminator 1
	movq	-24(%rbp), %rax
	movq	%rax, %rsi
	movq	%rdx, %rdi
	call	_ZSt3minIfERKT_S2_S2_
	.loc 4 3618 5 is_stmt 1
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE1981:
	.size	_ZSt5clampIfERKT_S2_S2_S2_, .-_ZSt5clampIfERKT_S2_S2_S2_
	.section	.text._ZSt3maxIfERKT_S2_S2_,"axG",@progbits,_ZSt3maxIfERKT_S2_S2_,comdat
	.weak	_ZSt3maxIfERKT_S2_S2_
	.hidden	_ZSt3maxIfERKT_S2_S2_
	.type	_ZSt3maxIfERKT_S2_S2