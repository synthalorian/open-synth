	.file	"drum_kit_mapping.cpp"
	.text
.Ltext0:
	.file 0 "/home/synth/projects/05-active-dev/open-synth/build" "/home/synth/projects/05-active-dev/open-synth/dsp/drum_kit_mapping.cpp"
	.globl	_ZN9opensynth17gm2NoteToDrumTypeEi
	.hidden	_ZN9opensynth17gm2NoteToDrumTypeEi
	.type	_ZN9opensynth17gm2NoteToDrumTypeEi, @function
_ZN9opensynth17gm2NoteToDrumTypeEi:
.LFB1274:
	.file 1 "/home/synth/projects/05-active-dev/open-synth/dsp/drum_kit_mapping.cpp"
	.loc 1 8 37
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	movl	%edi, -4(%rbp)
	.loc 1 9 5
	cmpl	$70, -4(%rbp)
	je	.L2
	cmpl	$70, -4(%rbp)
	jg	.L3
	cmpl	$64, -4(%rbp)
	je	.L4
	cmpl	$64, -4(%rbp)
	jg	.L3
	cmpl	$62, -4(%rbp)
	je	.L5
	cmpl	$62, -4(%rbp)
	jg	.L3
	cmpl	$59, -4(%rbp)
	je	.L6
	cmpl	$59, -4(%rbp)
	jg	.L3
	cmpl	$57, -4(%rbp)
	je	.L7
	cmpl	$57, -4(%rbp)
	jg	.L3
	cmpl	$56, -4(%rbp)
	je	.L8
	cmpl	$56, -4(%rbp)
	jg	.L3
	cmpl	$55, -4(%rbp)
	je	.L7
	cmpl	$55, -4(%rbp)
	jg	.L3
	cmpl	$54, -4(%rbp)
	je	.L2
	cmpl	$54, -4(%rbp)
	jg	.L3
	cmpl	$53, -4(%rbp)
	je	.L6
	cmpl	$53, -4(%rbp)
	jg	.L3
	cmpl	$52, -4(%rbp)
	je	.L7
	cmpl	$52, -4(%rbp)
	jg	.L3
	cmpl	$51, -4(%rbp)
	je	.L6
	cmpl	$51, -4(%rbp)
	jg	.L3
	cmpl	$49, -4(%rbp)
	je	.L7
	cmpl	$49, -4(%rbp)
	jg	.L3
	cmpl	$48, -4(%rbp)
	je	.L9
	cmpl	$48, -4(%rbp)
	jg	.L3
	cmpl	$46, -4(%rbp)
	je	.L10
	cmpl	$46, -4(%rbp)
	jg	.L3
	cmpl	$45, -4(%rbp)
	je	.L11
	cmpl	$45, -4(%rbp)
	jg	.L3
	cmpl	$44, -4(%rbp)
	je	.L12
	cmpl	$44, -4(%rbp)
	jg	.L3
	cmpl	$42, -4(%rbp)
	je	.L12
	cmpl	$42, -4(%rbp)
	jg	.L3
	cmpl	$41, -4(%rbp)
	je	.L13
	cmpl	$41, -4(%rbp)
	jg	.L3
	cmpl	$40, -4(%rbp)
	je	.L14
	cmpl	$40, -4(%rbp)
	jg	.L3
	cmpl	$39, -4(%rbp)
	je	.L15
	cmpl	$39, -4(%rbp)
	jg	.L3
	cmpl	$38, -4(%rbp)
	je	.L14
	cmpl	$38, -4(%rbp)
	jg	.L3
	cmpl	$36, -4(%rbp)
	jg	.L16
	cmpl	$35, -4(%rbp)
	jge	.L17
	jmp	.L3
.L16:
	cmpl	$37, -4(%rbp)
	je	.L18
	jmp	.L3
.L17:
	.loc 1 13 51
	movl	$0, %eax
	jmp	.L19
.L18:
	.loc 1 17 54
	movl	$10, %eax
	jmp	.L19
.L14:
	.loc 1 22 52
	movl	$1, %eax
	jmp	.L19
.L15:
	.loc 1 26 51
	movl	$9, %eax
	jmp	.L19
.L13:
	.loc 1 30 54
	movl	$6, %eax
	jmp	.L19
.L12:
	.loc 1 35 56
	movl	$2, %eax
	jmp	.L19
.L11:
	.loc 1 39 54
	movl	$5, %eax
	jmp	.L19
.L10:
	.loc 1 43 54
	movl	$3, %eax
	jmp	.L19
.L9:
	.loc 1 47 55
	movl	$4, %eax
	jmp	.L19
.L7:
	.loc 1 54 52
	movl	$7, %eax
	jmp	.L19
.L6:
	.loc 1 60 51
	movl	$8, %eax
	jmp	.L19
.L8:
	.loc 1 64 54
	movl	$11, %eax
	jmp	.L19
.L2:
	.loc 1 69 53
	movl	$12, %eax
	jmp	.L19
.L5:
	.loc 1 73 57
	movl	$13, %eax
	jmp	.L19
.L4:
	.loc 1 77 56
	movl	$14, %eax
	jmp	.L19
.L3:
	.loc 1 80 21
	movl	$-1, %eax
.L19:
	.loc 1 82 1
	popq	%rbp
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE1274:
	.size	_ZN9opensynth17gm2NoteToDrumTypeEi, .-_ZN9opensynth17gm2NoteToDrumTypeEi
	.section	.rodata
.LC0:
	.string	"Unknown"
.LC1:
	.string	"Kick"
.LC2:
	.string	"Snare"
.LC3:
	.string	"Closed HH"
.LC4:
	.string	"Open HH"
.LC5:
	.string	"Tom High"
.LC6:
	.string	"Tom Mid"
.LC7:
	.string	"Tom Low"
.LC8:
	.string	"Crash"
.LC9:
	.string	"Ride"
.LC10:
	.string	"Clap"
.LC11:
	.string	"Rimshot"
.LC12:
	.string	"Cowbell"
.LC13:
	.string	"Shaker"
.LC14:
	.string	"Conga High"
.LC15:
	.string	"Conga Low"
	.text
	.globl	_ZN9opensynth12drumTypeNameEi
	.hidden	_ZN9opensynth12drumTypeNameEi
	.type	_ZN9opensynth12drumTypeNameEi, @function
_ZN9opensynth12drumTypeNameEi:
.LFB1275:
	.loc 1 84 36
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	movl	%edi, -4(%rbp)
	.loc 1 85 5
	cmpl	$0, -4(%rbp)
	js	.L21
	.loc 1 85 18 discriminator 1
	cmpl	$14, -4(%rbp)
	jle	.L22
.L21:
	.loc 1 85 71 discriminator 2
	leaq	.LC0(%rip), %rax
	jmp	.L23
.L22:
	.loc 1 86 13
	movl	-4(%rbp), %eax
	.loc 1 86 5
	cmpb	$14, %al
	je	.L24
	cmpb	$14, %al
	ja	.L25
	cmpb	$13, %al
	je	.L26
	cmpb	$13, %al
	ja	.L25
	cmpb	$12, %al
	je	.L27
	cmpb	$12, %al
	ja	.L25
	cmpb	$11, %al
	je	.L28
	cmpb	$11, %al
	ja	.L25
	cmpb	$10, %al
	je	.L29
	cmpb	$10, %al
	ja	.L25
	cmpb	$9, %al
	je	.L30
	cmpb	$9, %al
	ja	.L25
	cmpb	$8, %al
	je	.L31
	cmpb	$8, %al
	ja	.L25
	cmpb	$7, %al
	je	.L32
	cmpb	$7, %al
	ja	.L25
	cmpb	$6, %al
	je	.L33
	cmpb	$6, %al
	ja	.L25
	cmpb	$5, %al
	je	.L34
	cmpb	$5, %al
	ja	.L25
	cmpb	$4, %al
	je	.L35
	cmpb	$4, %al
	ja	.L25
	cmpb	$3, %al
	je	.L36
	cmpb	$3, %al
	ja	.L25
	cmpb	$2, %al
	je	.L37
	cmpb	$2, %al
	ja	.L25
	testb	%al, %al
	je	.L38
	cmpb	$1, %al
	je	.L39
	jmp	.L25
.L38:
	.loc 1 87 43
	leaq	.LC1(%rip), %rax
	jmp	.L23
.L39:
	.loc 1 88 43
	leaq	.LC2(%rip), %rax
	jmp	.L23
.L37:
	.loc 1 89 43
	leaq	.LC3(%rip), %rax
	jmp	.L23
.L36:
	.loc 1 90 43
	leaq	.LC4(%rip), %rax
	jmp	.L23
.L35:
	.loc 1 91 43
	leaq	.LC5(%rip), %rax
	jmp	.L23
.L34:
	.loc 1 92 43
	leaq	.LC6(%rip), %rax
	jmp	.L23
.L33:
	.loc 1 93 43
	leaq	.LC7(%rip), %rax
	jmp	.L23
.L32:
	.loc 1 94 43
	leaq	.LC8(%rip), %rax
	jmp	.L23
.L31:
	.loc 1 95 43
	leaq	.LC9(%rip), %rax
	jmp	.L23
.L30:
	.loc 1 96 43
	leaq	.LC10(%rip), %rax
	jmp	.L23
.L29:
	.loc 1 97 43
	leaq	.LC11(%rip), %rax
	jmp	.L23
.L28:
	.loc 1 98 43
	leaq	.LC12(%rip), %rax
	jmp	.L23
.L27:
	.loc 1 99 43
	leaq	.LC13(%rip), %rax
	jmp	.L23
.L26:
	.loc 1 100 43
	leaq	.LC14(%rip), %rax
	jmp	.L23
.L24:
	.loc 1 101 43
	leaq	.LC15(%rip), %rax
	jmp	.L23
.L25:
	.loc 1 102 43
	leaq	.LC0(%rip), %rax
.L23:
	.loc 1 104 1
	popq	%rbp
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE1275:
	.size	_ZN9opensynth12drumTypeNameEi, .-_ZN9opensynth12drumTypeNameEi
	.type	_ZN9opensynthL5mkCfgEffff, @function
_ZN9opensynthL5mkCfgEffff:
.LFB1276:
	.loc 1 109 85
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$48, %rsp
	movss	%xmm0, -36(%rbp)
	movss	%xmm1, -40(%rbp)
	movss	%xmm2, -44(%rbp)
	movss	%xmm3, -48(%rbp)
	.loc 1 109 85
	movq	%fs:40, %rax
	movq	%rax, -8(%rbp)
	xorl	%eax, %eax
	.loc 1 110 21
	movss	.LC16(%rip), %xmm0
	movss	%xmm0, -32(%rbp)
	movss	.LC16(%rip), %xmm0
	movss	%xmm0, -28(%rbp)
	movss	.LC17(%rip), %xmm0
	movss	%xmm0, -24(%rbp)
	movss	.LC18(%rip), %xmm0
	movss	%xmm0, -20(%rbp)
	.loc 1 111 15
	movss	-36(%rbp), %xmm0
	movss	%xmm0, -32(%rbp)
	.loc 1 112 15
	movss	-40(%rbp), %xmm0
	movss	%xmm0, -28(%rbp)
	.loc 1 113 15
	movss	-44(%rbp), %xmm0
	movss	%xmm0, -24(%rbp)
	.loc 1 114 15
	movss	-48(%rbp), %xmm0
	movss	%xmm0, -20(%rbp)
	.loc 1 115 12
	movq	-32(%rbp), %rax
	movq	-24(%rbp), %rdx
	.loc 1 115 12 is_stmt 0 discriminator 1
	movq	%rax, %rcx
	movq	%rdx, %xmm1
	.loc 1 116 1 is_stmt 1
	movq	-8(%rbp), %rax
	subq	%fs:40, %rax
	je	.L42
	call	__stack_chk_fail@PLT
.L42:
	movq	%rcx, %xmm0
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE1276:
	.size	_ZN9opensynthL5mkCfgEffff, .-_ZN9opensynthL5mkCfgEffff
	.local	_ZN9opensynthL6stdCfgE
	.comm	_ZN9opensynthL6stdCfgE,256,32
	.local	_ZN9opensynthL7roomCfgE
	.comm	_ZN9opensynthL7roomCfgE,256,32
	.local	_ZN9opensynthL8powerCfgE
	.comm	_ZN9opensynthL8powerCfgE,256,32
	.local	_ZN9opensynthL8tr808CfgE
	.comm	_ZN9opensynthL8tr808CfgE,256,32
	.local	_ZN9opensynthL8tr909CfgE
	.comm	_ZN9opensynthL8tr909CfgE,256,32
	.local	_ZN9opensynthL13electronicCfgE
	.comm	_ZN9opensynthL13electronicCfgE,256,32
	.local	_ZN9opensynthL7jazzCfgE
	.comm	_ZN9opensynthL7jazzCfgE,256,32
	.local	_ZN9opensynthL8brushCfgE
	.comm	_ZN9opensynthL8brushCfgE,256,32
	.local	_ZN9opensynthL12orchestraCfgE
	.comm	_ZN9opensynthL12orchestraCfgE,256,32
	.local	_ZN9opensynthL6sfxCfgE
	.comm	_ZN9opensynthL6sfxCfgE,256,32
	.local	_ZN9opensynthL8latinCfgE
	.comm	_ZN9opensynthL8latinCfgE,256,32
	.local	_ZN9opensynthL8metalCfgE
	.comm	_ZN9opensynthL8metalCfgE,256,32
	.local	_ZN9opensynthL10vintageCfgE
	.comm	_ZN9opensynthL10vintageCfgE,256,32
	.local	_ZN9opensynthL8danceCfgE
	.comm	_ZN9opensynthL8danceCfgE,256,32
	.local	_ZN9opensynthL11acousticCfgE
	.comm	_ZN9opensynthL11acousticCfgE,256,32
	.local	_ZN9opensynthL9hiphopCfgE
	.comm	_ZN9opensynthL9hiphopCfgE,256,32
	.local	_ZN9opensynthL13percussionCfgE
	.comm	_ZN9opensynthL13percussionCfgE,256,32
	.local	_ZN9opensynthL12cinematicCfgE
	.comm	_ZN9opensynthL12cinematicCfgE,256,32
	.section	.data.rel.local,"aw"
	.align 32
	.type	_ZN9opensynthL14kitPresetTableE, @object
	.size	_ZN9opensynthL14kitPresetTableE, 144
_ZN9opensynthL14kitPresetTableE:
	.quad	_ZN9opensynthL6stdCfgE
	.quad	_ZN9opensynthL7roomCfgE
	.quad	_ZN9opensynthL8powerCfgE
	.quad	_ZN9opensynthL8tr808CfgE
	.quad	_ZN9opensynthL8tr909CfgE
	.quad	_ZN9opensynthL13electronicCfgE
	.quad	_ZN9opensynthL7jazzCfgE
	.quad	_ZN9opensynthL8brushCfgE
	.quad	_ZN9opensynthL12orchestraCfgE
	.quad	_ZN9opensynthL6sfxCfgE
	.quad	_ZN9opensynthL8latinCfgE
	.quad	_ZN9opensynthL8metalCfgE
	.quad	_ZN9opensynthL10vintageCfgE
	.quad	_ZN9opensynthL8danceCfgE
	.quad	_ZN9opensynthL11acousticCfgE
	.quad	_ZN9opensynthL9hiphopCfgE
	.quad	_ZN9opensynthL13percussionCfgE
	.quad	_ZN9opensynthL12cinematicCfgE
	.section	.rodata
.LC19:
	.string	"Standard"
.LC20:
	.string	"Room"
.LC21:
	.string	"Power"
.LC22:
	.string	"TR-808"
.LC23:
	.string	"TR-909"
.LC24:
	.string	"Electronic"
.LC25:
	.string	"Jazz"
.LC26:
	.string	"Brush"
.LC27:
	.string	"Orchestra"
.LC28:
	.string	"SFX"
.LC29:
	.string	"Latin"
.LC30:
	.string	"Metal"
.LC31:
	.string	"Vintage"
.LC32:
	.string	"Dance"
.LC33:
	.string	"Acoustic"
.LC34:
	.string	"Hip Hop"
.LC35:
	.string	"Percussion"
.LC36:
	.string	"Cinematic"
	.section	.data.rel.local
	.align 32
	.type	_ZN9opensynthL14kitPresetNamesE, @object
	.size	_ZN9opensynthL14kitPresetNamesE, 144
_ZN9opensynthL14kitPresetNamesE:
	.quad	.LC19
	.quad	.LC20
	.quad	.LC21
	.quad	.LC22
	.quad	.LC23
	.quad	.LC24
	.quad	.LC25
	.quad	.LC26
	.quad	.LC27
	.quad	.LC28
	.quad	.LC29
	.quad	.LC30
	.quad	.LC31
	.quad	.LC32
	.quad	.LC33
	.quad	.LC34
	.quad	.LC35
	.quad	.LC36
	.text
	.globl	_ZN9opensynth18initDrumKitPresetsEPNS_13DrumKitPresetE
	.hidden	_ZN9opensynth18initDrumKitPresetsEPNS_13DrumKitPresetE
	.type	_ZN9opensynth18initDrumKitPresetsEPNS_13DrumKitPresetE, @function
_ZN9opensynth18initDrumKitPresetsEPNS_13DrumKitPresetE:
.LFB1280:
	.loc 1 550 49
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	movq	%rdi, -24(%rbp)
.LBB2:
	.loc 1 551 14
	movl	$0, -8(%rbp)
	.loc 1 551 5
	jmp	.L44
.L47:
.LBB3:
	.loc 1 552 14
	movl	-8(%rbp), %eax
	cltq
	.loc 1 552 15
	imulq	$264, %rax, %rdx
	movq	-24(%rbp), %rax
	addq	%rax, %rdx
	.loc 1 552 40
	movl	-8(%rbp), %eax
	cltq
	leaq	0(,%rax,8), %rcx
	leaq	_ZN9opensynthL14kitPresetNamesE(%rip), %rax
	movq	(%rcx,%rax), %rax
	.loc 1 552 22
	movq	%rax, (%rdx)
.LBB4:
	.loc 1 553 18
	movl	$0, -4(%rbp)
	.loc 1 553 9
	jmp	.L45
.L46:
	.loc 1 554 49
	movl	-8(%rbp), %eax
	cltq
	leaq	0(,%rax,8), %rdx
	leaq	_ZN9opensynthL14kitPresetTableE(%rip), %rax
	movq	(%rdx,%rax), %rax
	.loc 1 554 51
	movl	-4(%rbp), %edx
	movslq	%edx, %rdx
	.loc 1 554 52
	salq	$4, %rdx
	addq	%rdx, %rax
	.loc 1 554 18
	movl	-8(%rbp), %edx
	movslq	%edx, %rdx
	.loc 1 554 19
	imulq	$264, %rdx, %rcx
	movq	-24(%rbp), %rdx
	addq	%rdx, %rcx
	.loc 1 554 31
	movl	-4(%rbp), %edx
	movslq	%edx, %rdx
	salq	$4, %rdx
	addq	%rdx, %rcx
	movq	8(%rax), %rdx
	movq	(%rax), %rax
	movq	%rax, 8(%rcx)
	movq	%rdx, 16(%rcx)
	.loc 1 553 9 discriminator 1
	addl	$1, -4(%rbp)
.L45:
	.loc 1 553 27 discriminator 2
	cmpl	$15, -4(%rbp)
	jle	.L46
.LBE4:
.LBE3:
	.loc 1 551 5 discriminator 1
	addl	$1, -8(%rbp)
.L44:
	.loc 1 551 23 discriminator 2
	cmpl	$17, -8(%rbp)
	jle	.L47
.LBE2:
	.loc 1 557 1
	nop
	nop
	popq	%rbp
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE1280:
	.size	_ZN9opensynth18initDrumKitPresetsEPNS_13DrumKitPresetE, .-_ZN9opensynth18initDrumKitPresetsEPNS_13DrumKitPresetE
	.type	_Z41__static_initialization_and_destruction_0v, @function
_Z41__static_initialization_and_destruction_0v:
.LFB1436:
	.loc 1 559 1
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	pushq	%rbx
	subq	$8, %rsp
	.cfi_offset 3, -24
	.loc 1 155 1
	leaq	_ZN9opensynthL6stdCfgE(%rip), %rbx
	.loc 1 124 10
	pxor	%xmm3, %xmm3
	movss	.LC17(%rip), %xmm2
	movss	.LC16(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 155 1 discriminator 1
	addq	$16, %rbx
	.loc 1 126 10
	movss	.LC18(%rip), %xmm3
	movss	.LC17(%rip), %xmm2
	movss	.LC16(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 155 1 discriminator 2
	addq	$16, %rbx
	.loc 1 128 10
	pxor	%xmm3, %xmm3
	movss	.LC17(%rip), %xmm2
	movss	.LC38(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 155 1 discriminator 3
	addq	$16, %rbx
	.loc 1 130 10
	pxor	%xmm3, %xmm3
	movss	.LC17(%rip), %xmm2
	movss	.LC39(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 155 1 discriminator 4
	addq	$16, %rbx
	.loc 1 132 10
	pxor	%xmm3, %xmm3
	movss	.LC17(%rip), %xmm2
	movss	.LC40(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 155 1 discriminator 5
	addq	$16, %rbx
	.loc 1 134 10
	pxor	%xmm3, %xmm3
	movss	.LC17(%rip), %xmm2
	movss	.LC40(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 155 1 discriminator 6
	addq	$16, %rbx
	.loc 1 136 10
	pxor	%xmm3, %xmm3
	movss	.LC17(%rip), %xmm2
	movss	.LC16(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 155 1 discriminator 7
	addq	$16, %rbx
	.loc 1 138 10
	pxor	%xmm3, %xmm3
	movss	.LC17(%rip), %xmm2
	movss	.LC39(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 155 1 discriminator 8
	addq	$16, %rbx
	.loc 1 140 10
	movss	.LC41(%rip), %xmm3
	movss	.LC17(%rip), %xmm2
	movss	.LC42(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 155 1 discriminator 9
	addq	$16, %rbx
	.loc 1 142 10
	pxor	%xmm3, %xmm3
	movss	.LC17(%rip), %xmm2
	movss	.LC38(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 155 1 discriminator 10
	addq	$16, %rbx
	.loc 1 144 10
	pxor	%xmm3, %xmm3
	movss	.LC17(%rip), %xmm2
	movss	.LC43(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 155 1 discriminator 11
	addq	$16, %rbx
	.loc 1 146 10
	pxor	%xmm3, %xmm3
	movss	.LC17(%rip), %xmm2
	movss	.LC39(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 155 1 discriminator 12
	addq	$16, %rbx
	.loc 1 148 10
	pxor	%xmm3, %xmm3
	movss	.LC17(%rip), %xmm2
	movss	.LC44(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 155 1 discriminator 13
	addq	$16, %rbx
	.loc 1 150 10
	pxor	%xmm3, %xmm3
	movss	.LC17(%rip), %xmm2
	movss	.LC38(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 155 1 discriminator 14
	addq	$16, %rbx
	.loc 1 152 10
	pxor	%xmm3, %xmm3
	movss	.LC17(%rip), %xmm2
	movss	.LC45(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 155 1 discriminator 15
	addq	$16, %rbx
	.loc 1 154 10
	pxor	%xmm3, %xmm3
	pxor	%xmm2, %xmm2
	pxor	%xmm1, %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 175 1
	leaq	_ZN9opensynthL7roomCfgE(%rip), %rbx
	.loc 1 159 10
	pxor	%xmm3, %xmm3
	movss	.LC44(%rip), %xmm2
	movss	.LC16(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 175 1 discriminator 1
	addq	$16, %rbx
	.loc 1 160 10
	movss	.LC46(%rip), %xmm3
	movss	.LC18(%rip), %xmm2
	movss	.LC16(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 175 1 discriminator 2
	addq	$16, %rbx
	.loc 1 161 10
	pxor	%xmm3, %xmm3
	movss	.LC47(%rip), %xmm2
	movss	.LC39(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 175 1 discriminator 3
	addq	$16, %rbx
	.loc 1 162 10
	pxor	%xmm3, %xmm3
	movss	.LC18(%rip), %xmm2
	movss	.LC42(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 175 1 discriminator 4
	addq	$16, %rbx
	.loc 1 163 10
	pxor	%xmm3, %xmm3
	movss	.LC48(%rip), %xmm2
	movss	.LC40(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 175 1 discriminator 5
	addq	$16, %rbx
	.loc 1 164 10
	pxor	%xmm3, %xmm3
	movss	.LC48(%rip), %xmm2
	movss	.LC40(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 175 1 discriminator 6
	addq	$16, %rbx
	.loc 1 165 10
	pxor	%xmm3, %xmm3
	movss	.LC46(%rip), %xmm2
	movss	.LC16(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 175 1 discriminator 7
	addq	$16, %rbx
	.loc 1 166 10
	pxor	%xmm3, %xmm3
	movss	.LC49(%rip), %xmm2
	movss	.LC39(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 175 1 discriminator 8
	addq	$16, %rbx
	.loc 1 167 10
	movss	.LC48(%rip), %xmm3
	movss	.LC50(%rip), %xmm2
	movss	.LC42(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 175 1 discriminator 9
	addq	$16, %rbx
	.loc 1 168 10
	pxor	%xmm3, %xmm3
	movss	.LC41(%rip), %xmm2
	movss	.LC38(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 175 1 discriminator 10
	addq	$16, %rbx
	.loc 1 169 10
	pxor	%xmm3, %xmm3
	movss	.LC51(%rip), %xmm2
	movss	.LC39(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 175 1 discriminator 11
	addq	$16, %rbx
	.loc 1 170 10
	pxor	%xmm3, %xmm3
	movss	.LC52(%rip), %xmm2
	movss	.LC39(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 175 1 discriminator 12
	addq	$16, %rbx
	.loc 1 171 10
	pxor	%xmm3, %xmm3
	movss	.LC53(%rip), %xmm2
	movss	.LC18(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 175 1 discriminator 13
	addq	$16, %rbx
	.loc 1 172 10
	pxor	%xmm3, %xmm3
	movss	.LC41(%rip), %xmm2
	movss	.LC38(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 175 1 discriminator 14
	addq	$16, %rbx
	.loc 1 173 10
	pxor	%xmm3, %xmm3
	movss	.LC41(%rip), %xmm2
	movss	.LC45(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 175 1 discriminator 15
	addq	$16, %rbx
	.loc 1 174 10
	pxor	%xmm3, %xmm3
	pxor	%xmm2, %xmm2
	pxor	%xmm1, %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 195 1
	leaq	_ZN9opensynthL8powerCfgE(%rip), %rbx
	.loc 1 179 10
	pxor	%xmm3, %xmm3
	movss	.LC52(%rip), %xmm2
	movss	.LC16(%rip), %xmm1
	movl	.LC54(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 195 1 discriminator 1
	addq	$16, %rbx
	.loc 1 180 10
	movss	.LC44(%rip), %xmm3
	movss	.LC52(%rip), %xmm2
	movss	.LC16(%rip), %xmm1
	movl	.LC55(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 195 1 discriminator 2
	addq	$16, %rbx
	.loc 1 181 10
	pxor	%xmm3, %xmm3
	movss	.LC56(%rip), %xmm2
	movss	.LC40(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 195 1 discriminator 3
	addq	$16, %rbx
	.loc 1 182 10
	pxor	%xmm3, %xmm3
	movss	.LC52(%rip), %xmm2
	movss	.LC38(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 195 1 discriminator 4
	addq	$16, %rbx
	.loc 1 183 10
	pxor	%xmm3, %xmm3
	movss	.LC57(%rip), %xmm2
	movss	.LC16(%rip), %xmm1
	movl	.LC55(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 195 1 discriminator 5
	addq	$16, %rbx
	.loc 1 184 10
	pxor	%xmm3, %xmm3
	movss	.LC57(%rip), %xmm2
	movss	.LC16(%rip), %xmm1
	movl	.LC58(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 195 1 discriminator 6
	addq	$16, %rbx
	.loc 1 185 10
	pxor	%xmm3, %xmm3
	movss	.LC59(%rip), %xmm2
	movss	.LC16(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 195 1 discriminator 7
	addq	$16, %rbx
	.loc 1 186 10
	pxor	%xmm3, %xmm3
	movss	.LC60(%rip), %xmm2
	movss	.LC38(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 195 1 discriminator 8
	addq	$16, %rbx
	.loc 1 187 10
	movss	.LC41(%rip), %xmm3
	movss	.LC39(%rip), %xmm2
	movss	.LC43(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 195 1 discriminator 9
	addq	$16, %rbx
	.loc 1 188 10
	pxor	%xmm3, %xmm3
	movss	.LC59(%rip), %xmm2
	movss	.LC40(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 195 1 discriminator 10
	addq	$16, %rbx
	.loc 1 189 10
	pxor	%xmm3, %xmm3
	movss	.LC61(%rip), %xmm2
	movss	.LC45(%rip), %xmm1
	movl	.LC55(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 195 1 discriminator 11
	addq	$16, %rbx
	.loc 1 190 10
	pxor	%xmm3, %xmm3
	movss	.LC53(%rip), %xmm2
	movss	.LC38(%rip), %xmm1
	movl	.LC55(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 195 1 discriminator 12
	addq	$16, %rbx
	.loc 1 191 10
	pxor	%xmm3, %xmm3
	movss	.LC47(%rip), %xmm2
	movss	.LC39(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 195 1 discriminator 13
	addq	$16, %rbx
	.loc 1 192 10
	pxor	%xmm3, %xmm3
	movss	.LC57(%rip), %xmm2
	movss	.LC40(%rip), %xmm1
	movl	.LC58(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 195 1 discriminator 14
	addq	$16, %rbx
	.loc 1 193 10
	pxor	%xmm3, %xmm3
	movss	.LC59(%rip), %xmm2
	movss	.LC62(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 195 1 discriminator 15
	addq	$16, %rbx
	.loc 1 194 10
	pxor	%xmm3, %xmm3
	pxor	%xmm2, %xmm2
	pxor	%xmm1, %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 215 1
	leaq	_ZN9opensynthL8tr808CfgE(%rip), %rbx
	.loc 1 199 10
	pxor	%xmm3, %xmm3
	movss	.LC48(%rip), %xmm2
	movss	.LC16(%rip), %xmm1
	movl	.LC40(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 215 1 discriminator 1
	addq	$16, %rbx
	.loc 1 200 10
	movss	.LC46(%rip), %xmm3
	movss	.LC63(%rip), %xmm2
	movss	.LC16(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 215 1 discriminator 2
	addq	$16, %rbx
	.loc 1 201 10
	pxor	%xmm3, %xmm3
	movss	.LC56(%rip), %xmm2
	movss	.LC43(%rip), %xmm1
	movl	.LC64(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 215 1 discriminator 3
	addq	$16, %rbx
	.loc 1 202 10
	pxor	%xmm3, %xmm3
	movss	.LC57(%rip), %xmm2
	movss	.LC42(%rip), %xmm1
	movl	.LC65(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 215 1 discriminator 4
	addq	$16, %rbx
	.loc 1 203 10
	pxor	%xmm3, %xmm3
	movss	.LC57(%rip), %xmm2
	movss	.LC45(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 215 1 discriminator 5
	addq	$16, %rbx
	.loc 1 204 10
	pxor	%xmm3, %xmm3
	movss	.LC57(%rip), %xmm2
	movss	.LC45(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 215 1 discriminator 6
	addq	$16, %rbx
	.loc 1 205 10
	pxor	%xmm3, %xmm3
	movss	.LC59(%rip), %xmm2
	movss	.LC40(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 215 1 discriminator 7
	addq	$16, %rbx
	.loc 1 206 10
	pxor	%xmm3, %xmm3
	movss	.LC16(%rip), %xmm2
	movss	.LC44(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 215 1 discriminator 8
	addq	$16, %rbx
	.loc 1 207 10
	movss	.LC52(%rip), %xmm3
	movss	.LC44(%rip), %xmm2
	movss	.LC44(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 215 1 discriminator 9
	addq	$16, %rbx
	.loc 1 208 10
	pxor	%xmm3, %xmm3
	movss	.LC57(%rip), %xmm2
	movss	.LC43(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 215 1 discriminator 10
	addq	$16, %rbx
	.loc 1 209 10
	pxor	%xmm3, %xmm3
	movss	.LC66(%rip), %xmm2
	movss	.LC39(%rip), %xmm1
	movl	.LC50(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 215 1 discriminator 11
	addq	$16, %rbx
	.loc 1 210 10
	pxor	%xmm3, %xmm3
	movss	.LC67(%rip), %xmm2
	movss	.LC38(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 215 1 discriminator 12
	addq	$16, %rbx
	.loc 1 211 10
	pxor	%xmm3, %xmm3
	movss	.LC68(%rip), %xmm2
	movss	.LC69(%rip), %xmm1
	movl	.LC64(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 215 1 discriminator 13
	addq	$16, %rbx
	.loc 1 212 10
	pxor	%xmm3, %xmm3
	movss	.LC53(%rip), %xmm2
	movss	.LC39(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 215 1 discriminator 14
	addq	$16, %rbx
	.loc 1 213 10
	pxor	%xmm3, %xmm3
	movss	.LC57(%rip), %xmm2
	movss	.LC38(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 215 1 discriminator 15
	addq	$16, %rbx
	.loc 1 214 10
	pxor	%xmm3, %xmm3
	pxor	%xmm2, %xmm2
	pxor	%xmm1, %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 235 1
	leaq	_ZN9opensynthL8tr909CfgE(%rip), %rbx
	.loc 1 219 10
	pxor	%xmm3, %xmm3
	movss	.LC41(%rip), %xmm2
	movss	.LC16(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 235 1 discriminator 1
	addq	$16, %rbx
	.loc 1 220 10
	movss	.LC18(%rip), %xmm3
	movss	.LC52(%rip), %xmm2
	movss	.LC16(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 235 1 discriminator 2
	addq	$16, %rbx
	.loc 1 221 10
	pxor	%xmm3, %xmm3
	movss	.LC70(%rip), %xmm2
	movss	.LC38(%rip), %xmm1
	movl	.LC65(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 235 1 discriminator 3
	addq	$16, %rbx
	.loc 1 222 10
	pxor	%xmm3, %xmm3
	movss	.LC52(%rip), %xmm2
	movss	.LC39(%rip), %xmm1
	movl	.LC55(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 235 1 discriminator 4
	addq	$16, %rbx
	.loc 1 223 10
	pxor	%xmm3, %xmm3
	movss	.LC59(%rip), %xmm2
	movss	.LC40(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 235 1 discriminator 5
	addq	$16, %rbx
	.loc 1 224 10
	pxor	%xmm3, %xmm3
	movss	.LC59(%rip), %xmm2
	movss	.LC40(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 235 1 discriminator 6
	addq	$16, %rbx
	.loc 1 225 10
	pxor	%xmm3, %xmm3
	movss	.LC63(%rip), %xmm2
	movss	.LC62(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 235 1 discriminator 7
	addq	$16, %rbx
	.loc 1 226 10
	pxor	%xmm3, %xmm3
	movss	.LC64(%rip), %xmm2
	movss	.LC39(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 235 1 discriminator 8
	addq	$16, %rbx
	.loc 1 227 10
	movss	.LC41(%rip), %xmm3
	movss	.LC39(%rip), %xmm2
	movss	.LC42(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 235 1 discriminator 9
	addq	$16, %rbx
	.loc 1 228 10
	pxor	%xmm3, %xmm3
	movss	.LC59(%rip), %xmm2
	movss	.LC38(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 235 1 discriminator 10
	addq	$16, %rbx
	.loc 1 229 10
	pxor	%xmm3, %xmm3
	movss	.LC61(%rip), %xmm2
	movss	.LC43(%rip), %xmm1
	movl	.LC55(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 235 1 discriminator 11
	addq	$16, %rbx
	.loc 1 230 10
	pxor	%xmm3, %xmm3
	movss	.LC53(%rip), %xmm2
	movss	.LC43(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 235 1 discriminator 12
	addq	$16, %rbx
	.loc 1 231 10
	pxor	%xmm3, %xmm3
	movss	.LC71(%rip), %xmm2
	movss	.LC44(%rip), %xmm1
	movl	.LC50(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 235 1 discriminator 13
	addq	$16, %rbx
	.loc 1 232 10
	pxor	%xmm3, %xmm3
	movss	.LC57(%rip), %xmm2
	movss	.LC43(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 235 1 discriminator 14
	addq	$16, %rbx
	.loc 1 233 10
	pxor	%xmm3, %xmm3
	movss	.LC59(%rip), %xmm2
	movss	.LC38(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 235 1 discriminator 15
	addq	$16, %rbx
	.loc 1 234 10
	pxor	%xmm3, %xmm3
	pxor	%xmm2, %xmm2
	pxor	%xmm1, %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 255 1
	leaq	_ZN9opensynthL13electronicCfgE(%rip), %rbx
	.loc 1 239 10
	pxor	%xmm3, %xmm3
	movss	.LC72(%rip), %xmm2
	movss	.LC16(%rip), %xmm1
	movl	.LC55(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 255 1 discriminator 1
	addq	$16, %rbx
	.loc 1 240 10
	movss	.LC48(%rip), %xmm3
	movss	.LC63(%rip), %xmm2
	movss	.LC16(%rip), %xmm1
	movl	.LC55(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 255 1 discriminator 2
	addq	$16, %rbx
	.loc 1 241 10
	pxor	%xmm3, %xmm3
	movss	.LC73(%rip), %xmm2
	movss	.LC45(%rip), %xmm1
	movl	.LC74(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 255 1 discriminator 3
	addq	$16, %rbx
	.loc 1 242 10
	pxor	%xmm3, %xmm3
	movss	.LC63(%rip), %xmm2
	movss	.LC43(%rip), %xmm1
	movl	.LC50(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 255 1 discriminator 4
	addq	$16, %rbx
	.loc 1 243 10
	pxor	%xmm3, %xmm3
	movss	.LC53(%rip), %xmm2
	movss	.LC40(%rip), %xmm1
	movl	.LC58(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 255 1 discriminator 5
	addq	$16, %rbx
	.loc 1 244 10
	pxor	%xmm3, %xmm3
	movss	.LC75(%rip), %xmm2
	movss	.LC40(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 255 1 discriminator 6
	addq	$16, %rbx
	.loc 1 245 10
	pxor	%xmm3, %xmm3
	movss	.LC76(%rip), %xmm2
	movss	.LC62(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 255 1 discriminator 7
	addq	$16, %rbx
	.loc 1 246 10
	pxor	%xmm3, %xmm3
	movss	.LC64(%rip), %xmm2
	movss	.LC43(%rip), %xmm1
	movl	.LC55(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 255 1 discriminator 8
	addq	$16, %rbx
	.loc 1 247 10
	movss	.LC48(%rip), %xmm3
	movss	.LC44(%rip), %xmm2
	movss	.LC39(%rip), %xmm1
	movl	.LC58(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 255 1 discriminator 9
	addq	$16, %rbx
	.loc 1 248 10
	pxor	%xmm3, %xmm3
	movss	.LC57(%rip), %xmm2
	movss	.LC45(%rip), %xmm1
	movl	.LC55(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 255 1 discriminator 10
	addq	$16, %rbx
	.loc 1 249 10
	pxor	%xmm3, %xmm3
	movss	.LC77(%rip), %xmm2
	movss	.LC38(%rip), %xmm1
	movl	.LC65(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 255 1 discriminator 11
	addq	$16, %rbx
	.loc 1 250 10
	pxor	%xmm3, %xmm3
	movss	.LC67(%rip), %xmm2
	movss	.LC39(%rip), %xmm1
	movl	.LC55(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 255 1 discriminator 12
	addq	$16, %rbx
	.loc 1 251 10
	pxor	%xmm3, %xmm3
	movss	.LC47(%rip), %xmm2
	movss	.LC42(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 255 1 discriminator 13
	addq	$16, %rbx
	.loc 1 252 10
	pxor	%xmm3, %xmm3
	movss	.LC76(%rip), %xmm2
	movss	.LC38(%rip), %xmm1
	movl	.LC55(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 255 1 discriminator 14
	addq	$16, %rbx
	.loc 1 253 10
	pxor	%xmm3, %xmm3
	movss	.LC59(%rip), %xmm2
	movss	.LC45(%rip), %xmm1
	movl	.LC58(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 255 1 discriminator 15
	addq	$16, %rbx
	.loc 1 254 10
	pxor	%xmm3, %xmm3
	pxor	%xmm2, %xmm2
	pxor	%xmm1, %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 275 1
	leaq	_ZN9opensynthL7jazzCfgE(%rip), %rbx
	.loc 1 259 10
	pxor	%xmm3, %xmm3
	movss	.LC46(%rip), %xmm2
	movss	.LC38(%rip), %xmm1
	movl	.LC62(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 275 1 discriminator 1
	addq	$16, %rbx
	.loc 1 260 10
	movss	.LC63(%rip), %xmm3
	movss	.LC57(%rip), %xmm2
	movss	.LC69(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 275 1 discriminator 2
	addq	$16, %rbx
	.loc 1 261 10
	pxor	%xmm3, %xmm3
	movss	.LC51(%rip), %xmm2
	movss	.LC78(%rip), %xmm1
	movl	.LC55(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 275 1 discriminator 3
	addq	$16, %rbx
	.loc 1 262 10
	pxor	%xmm3, %xmm3
	movss	.LC48(%rip), %xmm2
	movss	.LC46(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 275 1 discriminator 4
	addq	$16, %rbx
	.loc 1 263 10
	pxor	%xmm3, %xmm3
	movss	.LC52(%rip), %xmm2
	movss	.LC39(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 275 1 discriminator 5
	addq	$16, %rbx
	.loc 1 264 10
	pxor	%xmm3, %xmm3
	movss	.LC52(%rip), %xmm2
	movss	.LC39(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 275 1 discriminator 6
	addq	$16, %rbx
	.loc 1 265 10
	pxor	%xmm3, %xmm3
	movss	.LC79(%rip), %xmm2
	movss	.LC43(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 275 1 discriminator 7
	addq	$16, %rbx
	.loc 1 266 10
	pxor	%xmm3, %xmm3
	movss	.LC80(%rip), %xmm2
	movss	.LC78(%rip), %xmm1
	movl	.LC62(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 275 1 discriminator 8
	addq	$16, %rbx
	.loc 1 267 10
	movss	.LC63(%rip), %xmm3
	movss	.LC16(%rip), %xmm2
	movss	.LC46(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 275 1 discriminator 9
	addq	$16, %rbx
	.loc 1 268 10
	pxor	%xmm3, %xmm3
	movss	.LC59(%rip), %xmm2
	movss	.LC18(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 275 1 discriminator 10
	addq	$16, %rbx
	.loc 1 269 10
	pxor	%xmm3, %xmm3
	movss	.LC56(%rip), %xmm2
	movss	.LC46(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 275 1 discriminator 11
	addq	$16, %rbx
	.loc 1 270 10
	pxor	%xmm3, %xmm3
	movss	.LC59(%rip), %xmm2
	movss	.LC18(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 275 1 discriminator 12
	addq	$16, %rbx
	.loc 1 271 10
	pxor	%xmm3, %xmm3
	movss	.LC47(%rip), %xmm2
	movss	.LC52(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 275 1 discriminator 13
	addq	$16, %rbx
	.loc 1 272 10
	pxor	%xmm3, %xmm3
	movss	.LC72(%rip), %xmm2
	movss	.LC44(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 275 1 discriminator 14
	addq	$16, %rbx
	.loc 1 273 10
	pxor	%xmm3, %xmm3
	movss	.LC52(%rip), %xmm2
	movss	.LC42(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 275 1 discriminator 15
	addq	$16, %rbx
	.loc 1 274 10
	pxor	%xmm3, %xmm3
	pxor	%xmm2, %xmm2
	pxor	%xmm1, %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 295 1
	leaq	_ZN9opensynthL8brushCfgE(%rip), %rbx
	.loc 1 279 10
	pxor	%xmm3, %xmm3
	movss	.LC18(%rip), %xmm2
	movss	.LC39(%rip), %xmm1
	movl	.LC40(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 295 1 discriminator 1
	addq	$16, %rbx
	.loc 1 280 10
	movss	.LC67(%rip), %xmm3
	movss	.LC18(%rip), %xmm2
	movss	.LC48(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 295 1 discriminator 2
	addq	$16, %rbx
	.loc 1 281 10
	pxor	%xmm3, %xmm3
	movss	.LC81(%rip), %xmm2
	movss	.LC48(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 295 1 discriminator 3
	addq	$16, %rbx
	.loc 1 282 10
	pxor	%xmm3, %xmm3
	movss	.LC46(%rip), %xmm2
	movss	.LC41(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 295 1 discriminator 4
	addq	$16, %rbx
	.loc 1 283 10
	pxor	%xmm3, %xmm3
	movss	.LC41(%rip), %xmm2
	movss	.LC44(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 295 1 discriminator 5
	addq	$16, %rbx
	.loc 1 284 10
	pxor	%xmm3, %xmm3
	movss	.LC41(%rip), %xmm2
	movss	.LC44(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 295 1 discriminator 6
	addq	$16, %rbx
	.loc 1 285 10
	pxor	%xmm3, %xmm3
	movss	.LC48(%rip), %xmm2
	movss	.LC42(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 295 1 discriminator 7
	addq	$16, %rbx
	.loc 1 286 10
	pxor	%xmm3, %xmm3
	movss	.LC49(%rip), %xmm2
	movss	.LC46(%rip), %xmm1
	movl	.LC40(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 295 1 discriminator 8
	addq	$16, %rbx
	.loc 1 287 10
	movss	.LC57(%rip), %xmm3
	movss	.LC16(%rip), %xmm2
	movss	.LC48(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 295 1 discriminator 9
	addq	$16, %rbx
	.loc 1 288 10
	pxor	%xmm3, %xmm3
	movss	.LC52(%rip), %xmm2
	movss	.LC46(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 295 1 discriminator 10
	addq	$16, %rbx
	.loc 1 289 10
	pxor	%xmm3, %xmm3
	movss	.LC73(%rip), %xmm2
	movss	.LC48(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 295 1 discriminator 11
	addq	$16, %rbx
	.loc 1 290 10
	pxor	%xmm3, %xmm3
	movss	.LC63(%rip), %xmm2
	movss	.LC46(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 295 1 discriminator 12
	addq	$16, %rbx
	.loc 1 291 10
	pxor	%xmm3, %xmm3
	movss	.LC67(%rip), %xmm2
	movss	.LC57(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 295 1 discriminator 13
	addq	$16, %rbx
	.loc 1 292 10
	pxor	%xmm3, %xmm3
	movss	.LC79(%rip), %xmm2
	movss	.LC18(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 295 1 discriminator 14
	addq	$16, %rbx
	.loc 1 293 10
	pxor	%xmm3, %xmm3
	movss	.LC41(%rip), %xmm2
	movss	.LC69(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 295 1 discriminator 15
	addq	$16, %rbx
	.loc 1 294 10
	pxor	%xmm3, %xmm3
	pxor	%xmm2, %xmm2
	pxor	%xmm1, %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 315 1
	leaq	_ZN9opensynthL12orchestraCfgE(%rip), %rbx
	.loc 1 299 10
	pxor	%xmm3, %xmm3
	movss	.LC42(%rip), %xmm2
	movss	.LC16(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 315 1 discriminator 1
	addq	$16, %rbx
	.loc 1 300 10
	movss	.LC78(%rip), %xmm3
	movss	.LC18(%rip), %xmm2
	movss	.LC40(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 315 1 discriminator 2
	addq	$16, %rbx
	.loc 1 301 10
	pxor	%xmm3, %xmm3
	movss	.LC81(%rip), %xmm2
	movss	.LC44(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 315 1 discriminator 3
	addq	$16, %rbx
	.loc 1 302 10
	pxor	%xmm3, %xmm3
	movss	.LC44(%rip), %xmm2
	movss	.LC69(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 315 1 discriminator 4
	addq	$16, %rbx
	.loc 1 303 10
	pxor	%xmm3, %xmm3
	movss	.LC48(%rip), %xmm2
	movss	.LC45(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 315 1 discriminator 5
	addq	$16, %rbx
	.loc 1 304 10
	pxor	%xmm3, %xmm3
	movss	.LC48(%rip), %xmm2
	movss	.LC45(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 315 1 discriminator 6
	addq	$16, %rbx
	.loc 1 305 10
	pxor	%xmm3, %xmm3
	movss	.LC46(%rip), %xmm2
	movss	.LC40(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 315 1 discriminator 7
	addq	$16, %rbx
	.loc 1 306 10
	pxor	%xmm3, %xmm3
	movss	.LC82(%rip), %xmm2
	movss	.LC39(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 315 1 discriminator 8
	addq	$16, %rbx
	.loc 1 307 10
	movss	.LC46(%rip), %xmm3
	movss	.LC64(%rip), %xmm2
	movss	.LC42(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 315 1 discriminator 9
	addq	$16, %rbx
	.loc 1 308 10
	pxor	%xmm3, %xmm3
	movss	.LC48(%rip), %xmm2
	movss	.LC44(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 315 1 discriminator 10
	addq	$16, %rbx
	.loc 1 309 10
	pxor	%xmm3, %xmm3
	movss	.LC51(%rip), %xmm2
	movss	.LC69(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 315 1 discriminator 11
	addq	$16, %rbx
	.loc 1 310 10
	pxor	%xmm3, %xmm3
	movss	.LC41(%rip), %xmm2
	movss	.LC44(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 315 1 discriminator 12
	addq	$16, %rbx
	.loc 1 311 10
	pxor	%xmm3, %xmm3
	movss	.LC57(%rip), %xmm2
	movss	.LC48(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 315 1 discriminator 13
	addq	$16, %rbx
	.loc 1 312 10
	pxor	%xmm3, %xmm3
	movss	.LC48(%rip), %xmm2
	movss	.LC43(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 315 1 discriminator 14
	addq	$16, %rbx
	.loc 1 313 10
	pxor	%xmm3, %xmm3
	movss	.LC46(%rip), %xmm2
	movss	.LC38(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 315 1 discriminator 15
	addq	$16, %rbx
	.loc 1 314 10
	pxor	%xmm3, %xmm3
	pxor	%xmm2, %xmm2
	pxor	%xmm1, %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 335 1
	leaq	_ZN9opensynthL6sfxCfgE(%rip), %rbx
	.loc 1 319 10
	pxor	%xmm3, %xmm3
	movss	.LC44(%rip), %xmm2
	movss	.LC16(%rip), %xmm1
	movl	.LC46(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 335 1 discriminator 1
	addq	$16, %rbx
	.loc 1 320 10
	movss	.LC39(%rip), %xmm3
	movss	.LC67(%rip), %xmm2
	movss	.LC16(%rip), %xmm1
	movl	.LC83(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 335 1 discriminator 2
	addq	$16, %rbx
	.loc 1 321 10
	pxor	%xmm3, %xmm3
	movss	.LC68(%rip), %xmm2
	movss	.LC38(%rip), %xmm1
	movl	.LC41(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 335 1 discriminator 3
	addq	$16, %rbx
	.loc 1 322 10
	pxor	%xmm3, %xmm3
	movss	.LC44(%rip), %xmm2
	movss	.LC39(%rip), %xmm1
	movl	.LC18(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 335 1 discriminator 4
	addq	$16, %rbx
	.loc 1 323 10
	pxor	%xmm3, %xmm3
	movss	.LC67(%rip), %xmm2
	movss	.LC40(%rip), %xmm1
	movl	.LC60(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 335 1 discriminator 5
	addq	$16, %rbx
	.loc 1 324 10
	pxor	%xmm3, %xmm3
	movss	.LC52(%rip), %xmm2
	movss	.LC40(%rip), %xmm1
	movl	.LC39(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 335 1 discriminator 6
	addq	$16, %rbx
	.loc 1 325 10
	pxor	%xmm3, %xmm3
	movss	.LC48(%rip), %xmm2
	movss	.LC16(%rip), %xmm1
	movl	.LC18(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 335 1 discriminator 7
	addq	$16, %rbx
	.loc 1 326 10
	pxor	%xmm3, %xmm3
	movss	.LC84(%rip), %xmm2
	movss	.LC38(%rip), %xmm1
	movl	.LC64(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 335 1 discriminator 8
	addq	$16, %rbx
	.loc 1 327 10
	movss	.LC18(%rip), %xmm3
	movss	.LC64(%rip), %xmm2
	movss	.LC39(%rip), %xmm1
	movl	.LC44(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 335 1 discriminator 9
	addq	$16, %rbx
	.loc 1 328 10
	pxor	%xmm3, %xmm3
	movss	.LC53(%rip), %xmm2
	movss	.LC40(%rip), %xmm1
	movl	.LC83(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 335 1 discriminator 10
	addq	$16, %rbx
	.loc 1 329 10
	pxor	%xmm3, %xmm3
	movss	.LC77(%rip), %xmm2
	movss	.LC45(%rip), %xmm1
	movl	.LC49(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 335 1 discriminator 11
	addq	$16, %rbx
	.loc 1 330 10
	pxor	%xmm3, %xmm3
	movss	.LC81(%rip), %xmm2
	movss	.LC38(%rip), %xmm1
	movl	.LC83(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 335 1 discriminator 12
	addq	$16, %rbx
	.loc 1 331 10
	pxor	%xmm3, %xmm3
	movss	.LC63(%rip), %xmm2
	movss	.LC44(%rip), %xmm1
	movl	.LC41(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 335 1 discriminator 13
	addq	$16, %rbx
	.loc 1 332 10
	pxor	%xmm3, %xmm3
	movss	.LC52(%rip), %xmm2
	movss	.LC38(%rip), %xmm1
	movl	.LC44(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 335 1 discriminator 14
	addq	$16, %rbx
	.loc 1 333 10
	pxor	%xmm3, %xmm3
	movss	.LC48(%rip), %xmm2
	movss	.LC40(%rip), %xmm1
	movl	.LC46(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 335 1 discriminator 15
	addq	$16, %rbx
	.loc 1 334 10
	pxor	%xmm3, %xmm3
	pxor	%xmm2, %xmm2
	pxor	%xmm1, %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 355 1
	leaq	_ZN9opensynthL8latinCfgE(%rip), %rbx
	.loc 1 339 10
	pxor	%xmm3, %xmm3
	movss	.LC48(%rip), %xmm2
	movss	.LC40(%rip), %xmm1
	movl	.LC62(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 355 1 discriminator 1
	addq	$16, %rbx
	.loc 1 340 10
	movss	.LC48(%rip), %xmm3
	movss	.LC52(%rip), %xmm2
	movss	.LC38(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 355 1 discriminator 2
	addq	$16, %rbx
	.loc 1 341 10
	pxor	%xmm3, %xmm3
	movss	.LC51(%rip), %xmm2
	movss	.LC44(%rip), %xmm1
	movl	.LC50(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 355 1 discriminator 3
	addq	$16, %rbx
	.loc 1 342 10
	pxor	%xmm3, %xmm3
	movss	.LC46(%rip), %xmm2
	movss	.LC69(%rip), %xmm1
	movl	.LC55(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 355 1 discriminator 4
	addq	$16, %rbx
	.loc 1 343 10
	pxor	%xmm3, %xmm3
	movss	.LC63(%rip), %xmm2
	movss	.LC45(%rip), %xmm1
	movl	.LC54(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 355 1 discriminator 5
	addq	$16, %rbx
	.loc 1 344 10
	pxor	%xmm3, %xmm3
	movss	.LC63(%rip), %xmm2
	movss	.LC45(%rip), %xmm1
	movl	.LC55(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 355 1 discriminator 6
	addq	$16, %rbx
	.loc 1 345 10
	pxor	%xmm3, %xmm3
	movss	.LC72(%rip), %xmm2
	movss	.LC40(%rip), %xmm1
	movl	.LC58(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 355 1 discriminator 7
	addq	$16, %rbx
	.loc 1 346 10
	pxor	%xmm3, %xmm3
	movss	.LC83(%rip), %xmm2
	movss	.LC42(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 355 1 discriminator 8
	addq	$16, %rbx
	.loc 1 347 10
	movss	.LC41(%rip), %xmm3
	movss	.LC38(%rip), %xmm2
	movss	.LC44(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 355 1 discriminator 9
	addq	$16, %rbx
	.loc 1 348 10
	pxor	%xmm3, %xmm3
	movss	.LC63(%rip), %xmm2
	movss	.LC43(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 355 1 discriminator 10
	addq	$16, %rbx
	.loc 1 349 10
	pxor	%xmm3, %xmm3
	movss	.LC73(%rip), %xmm2
	movss	.LC39(%rip), %xmm1
	movl	.LC55(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 355 1 discriminator 11
	addq	$16, %rbx
	.loc 1 350 10
	pxor	%xmm3, %xmm3
	movss	.LC59(%rip), %xmm2
	movss	.LC43(%rip), %xmm1
	movl	.LC50(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 355 1 discriminator 12
	addq	$16, %rbx
	.loc 1 351 10
	pxor	%xmm3, %xmm3
	movss	.LC81(%rip), %xmm2
	movss	.LC69(%rip), %xmm1
	movl	.LC55(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 355 1 discriminator 13
	addq	$16, %rbx
	.loc 1 352 10
	pxor	%xmm3, %xmm3
	movss	.LC59(%rip), %xmm2
	movss	.LC45(%rip), %xmm1
	movl	.LC54(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 355 1 discriminator 14
	addq	$16, %rbx
	.loc 1 353 10
	pxor	%xmm3, %xmm3
	movss	.LC63(%rip), %xmm2
	movss	.LC40(%rip), %xmm1
	movl	.LC55(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 355 1 discriminator 15
	addq	$16, %rbx
	.loc 1 354 10
	pxor	%xmm3, %xmm3
	pxor	%xmm2, %xmm2
	pxor	%xmm1, %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 375 1
	leaq	_ZN9opensynthL8metalCfgE(%rip), %rbx
	.loc 1 359 10
	pxor	%xmm3, %xmm3
	movss	.LC69(%rip), %xmm2
	movss	.LC16(%rip), %xmm1
	movl	.LC50(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 375 1 discriminator 1
	addq	$16, %rbx
	.loc 1 360 10
	movss	.LC69(%rip), %xmm3
	movss	.LC48(%rip), %xmm2
	movss	.LC16(%rip), %xmm1
	movl	.LC54(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 375 1 discriminator 2
	addq	$16, %rbx
	.loc 1 361 10
	pxor	%xmm3, %xmm3
	movss	.LC68(%rip), %xmm2
	movss	.LC45(%rip), %xmm1
	movl	.LC65(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 375 1 discriminator 3
	addq	$16, %rbx
	.loc 1 362 10
	pxor	%xmm3, %xmm3
	movss	.LC18(%rip), %xmm2
	movss	.LC43(%rip), %xmm1
	movl	.LC50(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 375 1 discriminator 4
	addq	$16, %rbx
	.loc 1 363 10
	pxor	%xmm3, %xmm3
	movss	.LC72(%rip), %xmm2
	movss	.LC62(%rip), %xmm1
	movl	.LC50(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 375 1 discriminator 5
	addq	$16, %rbx
	.loc 1 364 10
	pxor	%xmm3, %xmm3
	movss	.LC72(%rip), %xmm2
	movss	.LC62(%rip), %xmm1
	movl	.LC54(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 375 1 discriminator 6
	addq	$16, %rbx
	.loc 1 365 10
	pxor	%xmm3, %xmm3
	movss	.LC52(%rip), %xmm2
	movss	.LC16(%rip), %xmm1
	movl	.LC55(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 375 1 discriminator 7
	addq	$16, %rbx
	.loc 1 366 10
	pxor	%xmm3, %xmm3
	movss	.LC82(%rip), %xmm2
	movss	.LC38(%rip), %xmm1
	movl	.LC55(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 375 1 discriminator 8
	addq	$16, %rbx
	.loc 1 367 10
	movss	.LC46(%rip), %xmm3
	movss	.LC50(%rip), %xmm2
	movss	.LC43(%rip), %xmm1
	movl	.LC58(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 375 1 discriminator 9
	addq	$16, %rbx
	.loc 1 368 10
	pxor	%xmm3, %xmm3
	movss	.LC72(%rip), %xmm2
	movss	.LC40(%rip), %xmm1
	movl	.LC55(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 375 1 discriminator 10
	addq	$16, %rbx
	.loc 1 369 10
	pxor	%xmm3, %xmm3
	movss	.LC56(%rip), %xmm2
	movss	.LC45(%rip), %xmm1
	movl	.LC50(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 375 1 discriminator 11
	addq	$16, %rbx
	.loc 1 370 10
	pxor	%xmm3, %xmm3
	movss	.LC57(%rip), %xmm2
	movss	.LC38(%rip), %xmm1
	movl	.LC50(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 375 1 discriminator 12
	addq	$16, %rbx
	.loc 1 371 10
	pxor	%xmm3, %xmm3
	movss	.LC81(%rip), %xmm2
	movss	.LC42(%rip), %xmm1
	movl	.LC55(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 375 1 discriminator 13
	addq	$16, %rbx
	.loc 1 372 10
	pxor	%xmm3, %xmm3
	movss	.LC63(%rip), %xmm2
	movss	.LC40(%rip), %xmm1
	movl	.LC54(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 375 1 discriminator 14
	addq	$16, %rbx
	.loc 1 373 10
	pxor	%xmm3, %xmm3
	movss	.LC72(%rip), %xmm2
	movss	.LC62(%rip), %xmm1
	movl	.LC55(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 375 1 discriminator 15
	addq	$16, %rbx
	.loc 1 374 10
	pxor	%xmm3, %xmm3
	pxor	%xmm2, %xmm2
	pxor	%xmm1, %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 395 1
	leaq	_ZN9opensynthL10vintageCfgE(%rip), %rbx
	.loc 1 379 10
	pxor	%xmm3, %xmm3
	movss	.LC46(%rip), %xmm2
	movss	.LC40(%rip), %xmm1
	movl	.LC45(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 395 1 discriminator 1
	addq	$16, %rbx
	.loc 1 380 10
	movss	.LC52(%rip), %xmm3
	movss	.LC59(%rip), %xmm2
	movss	.LC43(%rip), %xmm1
	movl	.LC62(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 395 1 discriminator 2
	addq	$16, %rbx
	.loc 1 381 10
	pxor	%xmm3, %xmm3
	movss	.LC85(%rip), %xmm2
	movss	.LC69(%rip), %xmm1
	movl	.LC55(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 395 1 discriminator 3
	addq	$16, %rbx
	.loc 1 382 10
	pxor	%xmm3, %xmm3
	movss	.LC48(%rip), %xmm2
	movss	.LC18(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 395 1 discriminator 4
	addq	$16, %rbx
	.loc 1 383 10
	pxor	%xmm3, %xmm3
	movss	.LC59(%rip), %xmm2
	movss	.LC43(%rip), %xmm1
	movl	.LC58(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 395 1 discriminator 5
	addq	$16, %rbx
	.loc 1 384 10
	pxor	%xmm3, %xmm3
	movss	.LC59(%rip), %xmm2
	movss	.LC43(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 395 1 discriminator 6
	addq	$16, %rbx
	.loc 1 385 10
	pxor	%xmm3, %xmm3
	movss	.LC63(%rip), %xmm2
	movss	.LC38(%rip), %xmm1
	movl	.LC62(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 395 1 discriminator 7
	addq	$16, %rbx
	.loc 1 386 10
	pxor	%xmm3, %xmm3
	movss	.LC80(%rip), %xmm2
	movss	.LC18(%rip), %xmm1
	movl	.LC40(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 395 1 discriminator 8
	addq	$16, %rbx
	.loc 1 387 10
	movss	.LC63(%rip), %xmm3
	movss	.LC38(%rip), %xmm2
	movss	.LC78(%rip), %xmm1
	movl	.LC62(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 395 1 discriminator 9
	addq	$16, %rbx
	.loc 1 388 10
	pxor	%xmm3, %xmm3
	movss	.LC63(%rip), %xmm2
	movss	.LC42(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 395 1 discriminator 10
	addq	$16, %rbx
	.loc 1 389 10
	pxor	%xmm3, %xmm3
	movss	.LC56(%rip), %xmm2
	movss	.LC44(%rip), %xmm1
	movl	.LC55(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 395 1 discriminator 11
	addq	$16, %rbx
	.loc 1 390 10
	pxor	%xmm3, %xmm3
	movss	.LC75(%rip), %xmm2
	movss	.LC69(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 395 1 discriminator 12
	addq	$16, %rbx
	.loc 1 391 10
	pxor	%xmm3, %xmm3
	movss	.LC71(%rip), %xmm2
	movss	.LC48(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 395 1 discriminator 13
	addq	$16, %rbx
	.loc 1 392 10
	pxor	%xmm3, %xmm3
	movss	.LC59(%rip), %xmm2
	movss	.LC39(%rip), %xmm1
	movl	.LC58(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 395 1 discriminator 14
	addq	$16, %rbx
	.loc 1 393 10
	pxor	%xmm3, %xmm3
	movss	.LC63(%rip), %xmm2
	movss	.LC43(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 395 1 discriminator 15
	addq	$16, %rbx
	.loc 1 394 10
	pxor	%xmm3, %xmm3
	pxor	%xmm2, %xmm2
	pxor	%xmm1, %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 415 1
	leaq	_ZN9opensynthL8danceCfgE(%rip), %rbx
	.loc 1 399 10
	pxor	%xmm3, %xmm3
	movss	.LC59(%rip), %xmm2
	movss	.LC16(%rip), %xmm1
	movl	.LC54(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 415 1 discriminator 1
	addq	$16, %rbx
	.loc 1 400 10
	movss	.LC46(%rip), %xmm3
	movss	.LC76(%rip), %xmm2
	movss	.LC16(%rip), %xmm1
	movl	.LC55(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 415 1 discriminator 2
	addq	$16, %rbx
	.loc 1 401 10
	pxor	%xmm3, %xmm3
	movss	.LC56(%rip), %xmm2
	movss	.LC40(%rip), %xmm1
	movl	.LC64(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 415 1 discriminator 3
	addq	$16, %rbx
	.loc 1 402 10
	pxor	%xmm3, %xmm3
	movss	.LC59(%rip), %xmm2
	movss	.LC38(%rip), %xmm1
	movl	.LC65(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 415 1 discriminator 4
	addq	$16, %rbx
	.loc 1 403 10
	pxor	%xmm3, %xmm3
	movss	.LC67(%rip), %xmm2
	movss	.LC62(%rip), %xmm1
	movl	.LC55(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 415 1 discriminator 5
	addq	$16, %rbx
	.loc 1 404 10
	pxor	%xmm3, %xmm3
	movss	.LC53(%rip), %xmm2
	movss	.LC62(%rip), %xmm1
	movl	.LC58(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 415 1 discriminator 6
	addq	$16, %rbx
	.loc 1 405 10
	pxor	%xmm3, %xmm3
	movss	.LC75(%rip), %xmm2
	movss	.LC16(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 415 1 discriminator 7
	addq	$16, %rbx
	.loc 1 406 10
	pxor	%xmm3, %xmm3
	movss	.LC50(%rip), %xmm2
	movss	.LC38(%rip), %xmm1
	movl	.LC55(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 415 1 discriminator 8
	addq	$16, %rbx
	.loc 1 407 10
	movss	.LC48(%rip), %xmm3
	movss	.LC18(%rip), %xmm2
	movss	.LC43(%rip), %xmm1
	movl	.LC58(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 415 1 discriminator 9
	addq	$16, %rbx
	.loc 1 408 10
	pxor	%xmm3, %xmm3
	movss	.LC75(%rip), %xmm2
	movss	.LC40(%rip), %xmm1
	movl	.LC55(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 415 1 discriminator 10
	addq	$16, %rbx
	.loc 1 409 10
	pxor	%xmm3, %xmm3
	movss	.LC77(%rip), %xmm2
	movss	.LC45(%rip), %xmm1
	movl	.LC65(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 415 1 discriminator 11
	addq	$16, %rbx
	.loc 1 410 10
	pxor	%xmm3, %xmm3
	movss	.LC67(%rip), %xmm2
	movss	.LC43(%rip), %xmm1
	movl	.LC55(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 415 1 discriminator 12
	addq	$16, %rbx
	.loc 1 411 10
	pxor	%xmm3, %xmm3
	movss	.LC68(%rip), %xmm2
	movss	.LC39(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 415 1 discriminator 13
	addq	$16, %rbx
	.loc 1 412 10
	pxor	%xmm3, %xmm3
	movss	.LC75(%rip), %xmm2
	movss	.LC45(%rip), %xmm1
	movl	.LC55(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 415 1 discriminator 14
	addq	$16, %rbx
	.loc 1 413 10
	pxor	%xmm3, %xmm3
	movss	.LC76(%rip), %xmm2
	movss	.LC40(%rip), %xmm1
	movl	.LC58(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 415 1 discriminator 15
	addq	$16, %rbx
	.loc 1 414 10
	pxor	%xmm3, %xmm3
	pxor	%xmm2, %xmm2
	pxor	%xmm1, %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 435 1
	leaq	_ZN9opensynthL11acousticCfgE(%rip), %rbx
	.loc 1 419 10
	pxor	%xmm3, %xmm3
	movss	.LC18(%rip), %xmm2
	movss	.LC16(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 435 1 discriminator 1
	addq	$16, %rbx
	.loc 1 420 10
	movss	.LC46(%rip), %xmm3
	movss	.LC41(%rip), %xmm2
	movss	.LC40(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 435 1 discriminator 2
	addq	$16, %rbx
	.loc 1 421 10
	pxor	%xmm3, %xmm3
	movss	.LC47(%rip), %xmm2
	movss	.LC43(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 435 1 discriminator 3
	addq	$16, %rbx
	.loc 1 422 10
	pxor	%xmm3, %xmm3
	movss	.LC69(%rip), %xmm2
	movss	.LC39(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 435 1 discriminator 4
	addq	$16, %rbx
	.loc 1 423 10
	pxor	%xmm3, %xmm3
	movss	.LC41(%rip), %xmm2
	movss	.LC40(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 435 1 discriminator 5
	addq	$16, %rbx
	.loc 1 424 10
	pxor	%xmm3, %xmm3
	movss	.LC41(%rip), %xmm2
	movss	.LC40(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 435 1 discriminator 6
	addq	$16, %rbx
	.loc 1 425 10
	pxor	%xmm3, %xmm3
	movss	.LC86(%rip), %xmm2
	movss	.LC62(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 435 1 discriminator 7
	addq	$16, %rbx
	.loc 1 426 10
	pxor	%xmm3, %xmm3
	movss	.LC87(%rip), %xmm2
	movss	.LC43(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 435 1 discriminator 8
	addq	$16, %rbx
	.loc 1 427 10
	movss	.LC48(%rip), %xmm3
	movss	.LC50(%rip), %xmm2
	movss	.LC39(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 435 1 discriminator 9
	addq	$16, %rbx
	.loc 1 428 10
	pxor	%xmm3, %xmm3
	movss	.LC79(%rip), %xmm2
	movss	.LC45(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 435 1 discriminator 10
	addq	$16, %rbx
	.loc 1 429 10
	pxor	%xmm3, %xmm3
	movss	.LC51(%rip), %xmm2
	movss	.LC43(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 435 1 discriminator 11
	addq	$16, %rbx
	.loc 1 430 10
	pxor	%xmm3, %xmm3
	movss	.LC52(%rip), %xmm2
	movss	.LC43(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 435 1 discriminator 12
	addq	$16, %rbx
	.loc 1 431 10
	pxor	%xmm3, %xmm3
	movss	.LC53(%rip), %xmm2
	movss	.LC18(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 435 1 discriminator 13
	addq	$16, %rbx
	.loc 1 432 10
	pxor	%xmm3, %xmm3
	movss	.LC79(%rip), %xmm2
	movss	.LC45(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 435 1 discriminator 14
	addq	$16, %rbx
	.loc 1 433 10
	pxor	%xmm3, %xmm3
	movss	.LC41(%rip), %xmm2
	movss	.LC40(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 435 1 discriminator 15
	addq	$16, %rbx
	.loc 1 434 10
	pxor	%xmm3, %xmm3
	pxor	%xmm2, %xmm2
	pxor	%xmm1, %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 455 1
	leaq	_ZN9opensynthL9hiphopCfgE(%rip), %rbx
	.loc 1 439 10
	pxor	%xmm3, %xmm3
	movss	.LC69(%rip), %xmm2
	movss	.LC16(%rip), %xmm1
	movl	.LC40(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 455 1 discriminator 1
	addq	$16, %rbx
	.loc 1 440 10
	movss	.LC78(%rip), %xmm3
	movss	.LC79(%rip), %xmm2
	movss	.LC16(%rip), %xmm1
	movl	.LC58(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 455 1 discriminator 2
	addq	$16, %rbx
	.loc 1 441 10
	pxor	%xmm3, %xmm3
	movss	.LC70(%rip), %xmm2
	movss	.LC38(%rip), %xmm1
	movl	.LC65(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 455 1 discriminator 3
	addq	$16, %rbx
	.loc 1 442 10
	pxor	%xmm3, %xmm3
	movss	.LC78(%rip), %xmm2
	movss	.LC39(%rip), %xmm1
	movl	.LC55(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 455 1 discriminator 4
	addq	$16, %rbx
	.loc 1 443 10
	pxor	%xmm3, %xmm3
	movss	.LC72(%rip), %xmm2
	movss	.LC40(%rip), %xmm1
	movl	.LC58(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 455 1 discriminator 5
	addq	$16, %rbx
	.loc 1 444 10
	pxor	%xmm3, %xmm3
	movss	.LC88(%rip), %xmm2
	movss	.LC40(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 455 1 discriminator 6
	addq	$16, %rbx
	.loc 1 445 10
	pxor	%xmm3, %xmm3
	movss	.LC79(%rip), %xmm2
	movss	.LC62(%rip), %xmm1
	movl	.LC62(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 455 1 discriminator 7
	addq	$16, %rbx
	.loc 1 446 10
	pxor	%xmm3, %xmm3
	movss	.LC83(%rip), %xmm2
	movss	.LC39(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 455 1 discriminator 8
	addq	$16, %rbx
	.loc 1 447 10
	movss	.LC41(%rip), %xmm3
	movss	.LC38(%rip), %xmm2
	movss	.LC42(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 455 1 discriminator 9
	addq	$16, %rbx
	.loc 1 448 10
	pxor	%xmm3, %xmm3
	movss	.LC72(%rip), %xmm2
	movss	.LC45(%rip), %xmm1
	movl	.LC58(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 455 1 discriminator 10
	addq	$16, %rbx
	.loc 1 449 10
	pxor	%xmm3, %xmm3
	movss	.LC61(%rip), %xmm2
	movss	.LC38(%rip), %xmm1
	movl	.LC50(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 455 1 discriminator 11
	addq	$16, %rbx
	.loc 1 450 10
	pxor	%xmm3, %xmm3
	movss	.LC75(%rip), %xmm2
	movss	.LC43(%rip), %xmm1
	movl	.LC58(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 455 1 discriminator 12
	addq	$16, %rbx
	.loc 1 451 10
	pxor	%xmm3, %xmm3
	movss	.LC71(%rip), %xmm2
	movss	.LC44(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 455 1 discriminator 13
	addq	$16, %rbx
	.loc 1 452 10
	pxor	%xmm3, %xmm3
	movss	.LC72(%rip), %xmm2
	movss	.LC45(%rip), %xmm1
	movl	.LC58(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 455 1 discriminator 14
	addq	$16, %rbx
	.loc 1 453 10
	pxor	%xmm3, %xmm3
	movss	.LC52(%rip), %xmm2
	movss	.LC40(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 455 1 discriminator 15
	addq	$16, %rbx
	.loc 1 454 10
	pxor	%xmm3, %xmm3
	pxor	%xmm2, %xmm2
	pxor	%xmm1, %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 475 1
	leaq	_ZN9opensynthL13percussionCfgE(%rip), %rbx
	.loc 1 459 10
	pxor	%xmm3, %xmm3
	movss	.LC41(%rip), %xmm2
	movss	.LC45(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 475 1 discriminator 1
	addq	$16, %rbx
	.loc 1 460 10
	movss	.LC63(%rip), %xmm3
	movss	.LC53(%rip), %xmm2
	movss	.LC44(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 475 1 discriminator 2
	addq	$16, %rbx
	.loc 1 461 10
	pxor	%xmm3, %xmm3
	movss	.LC68(%rip), %xmm2
	movss	.LC39(%rip), %xmm1
	movl	.LC65(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 475 1 discriminator 3
	addq	$16, %rbx
	.loc 1 462 10
	pxor	%xmm3, %xmm3
	movss	.LC48(%rip), %xmm2
	movss	.LC42(%rip), %xmm1
	movl	.LC50(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 475 1 discriminator 4
	addq	$16, %rbx
	.loc 1 463 10
	pxor	%xmm3, %xmm3
	movss	.LC57(%rip), %xmm2
	movss	.LC38(%rip), %xmm1
	movl	.LC50(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 475 1 discriminator 5
	addq	$16, %rbx
	.loc 1 464 10
	pxor	%xmm3, %xmm3
	movss	.LC57(%rip), %xmm2
	movss	.LC38(%rip), %xmm1
	movl	.LC54(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 475 1 discriminator 6
	addq	$16, %rbx
	.loc 1 465 10
	pxor	%xmm3, %xmm3
	movss	.LC59(%rip), %xmm2
	movss	.LC45(%rip), %xmm1
	movl	.LC55(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 475 1 discriminator 7
	addq	$16, %rbx
	.loc 1 466 10
	pxor	%xmm3, %xmm3
	movss	.LC80(%rip), %xmm2
	movss	.LC39(%rip), %xmm1
	movl	.LC55(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 475 1 discriminator 8
	addq	$16, %rbx
	.loc 1 467 10
	movss	.LC52(%rip), %xmm3
	movss	.LC40(%rip), %xmm2
	movss	.LC42(%rip), %xmm1
	movl	.LC58(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 475 1 discriminator 9
	addq	$16, %rbx
	.loc 1 468 10
	pxor	%xmm3, %xmm3
	movss	.LC57(%rip), %xmm2
	movss	.LC38(%rip), %xmm1
	movl	.LC55(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 475 1 discriminator 10
	addq	$16, %rbx
	.loc 1 469 10
	pxor	%xmm3, %xmm3
	movss	.LC56(%rip), %xmm2
	movss	.LC43(%rip), %xmm1
	movl	.LC89(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 475 1 discriminator 11
	addq	$16, %rbx
	.loc 1 470 10
	pxor	%xmm3, %xmm3
	movss	.LC63(%rip), %xmm2
	movss	.LC45(%rip), %xmm1
	movl	.LC65(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 475 1 discriminator 12
	addq	$16, %rbx
	.loc 1 471 10
	pxor	%xmm3, %xmm3
	movss	.LC67(%rip), %xmm2
	movss	.LC39(%rip), %xmm1
	movl	.LC50(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 475 1 discriminator 13
	addq	$16, %rbx
	.loc 1 472 10
	pxor	%xmm3, %xmm3
	movss	.LC76(%rip), %xmm2
	movss	.LC40(%rip), %xmm1
	movl	.LC54(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 475 1 discriminator 14
	addq	$16, %rbx
	.loc 1 473 10
	pxor	%xmm3, %xmm3
	movss	.LC59(%rip), %xmm2
	movss	.LC40(%rip), %xmm1
	movl	.LC55(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 475 1 discriminator 15
	addq	$16, %rbx
	.loc 1 474 10
	pxor	%xmm3, %xmm3
	pxor	%xmm2, %xmm2
	pxor	%xmm1, %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 495 1
	leaq	_ZN9opensynthL12cinematicCfgE(%rip), %rbx
	.loc 1 479 10
	pxor	%xmm3, %xmm3
	movss	.LC43(%rip), %xmm2
	movss	.LC16(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 495 1 discriminator 1
	addq	$16, %rbx
	.loc 1 480 10
	movss	.LC18(%rip), %xmm3
	movss	.LC78(%rip), %xmm2
	movss	.LC62(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 495 1 discriminator 2
	addq	$16, %rbx
	.loc 1 481 10
	pxor	%xmm3, %xmm3
	movss	.LC67(%rip), %xmm2
	movss	.LC39(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 495 1 discriminator 3
	addq	$16, %rbx
	.loc 1 482 10
	pxor	%xmm3, %xmm3
	movss	.LC39(%rip), %xmm2
	movss	.LC42(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 495 1 discriminator 4
	addq	$16, %rbx
	.loc 1 483 10
	pxor	%xmm3, %xmm3
	movss	.LC46(%rip), %xmm2
	movss	.LC40(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 495 1 discriminator 5
	addq	$16, %rbx
	.loc 1 484 10
	pxor	%xmm3, %xmm3
	movss	.LC46(%rip), %xmm2
	movss	.LC40(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 495 1 discriminator 6
	addq	$16, %rbx
	.loc 1 485 10
	pxor	%xmm3, %xmm3
	movss	.LC90(%rip), %xmm2
	movss	.LC62(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 495 1 discriminator 7
	addq	$16, %rbx
	.loc 1 486 10
	pxor	%xmm3, %xmm3
	movss	.LC84(%rip), %xmm2
	movss	.LC38(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 495 1 discriminator 8
	addq	$16, %rbx
	.loc 1 487 10
	movss	.LC78(%rip), %xmm3
	movss	.LC60(%rip), %xmm2
	movss	.LC43(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 495 1 discriminator 9
	addq	$16, %rbx
	.loc 1 488 10
	pxor	%xmm3, %xmm3
	movss	.LC48(%rip), %xmm2
	movss	.LC45(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 495 1 discriminator 10
	addq	$16, %rbx
	.loc 1 489 10
	pxor	%xmm3, %xmm3
	movss	.LC68(%rip), %xmm2
	movss	.LC39(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 495 1 discriminator 11
	addq	$16, %rbx
	.loc 1 490 10
	pxor	%xmm3, %xmm3
	movss	.LC41(%rip), %xmm2
	movss	.LC43(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 495 1 discriminator 12
	addq	$16, %rbx
	.loc 1 491 10
	pxor	%xmm3, %xmm3
	movss	.LC59(%rip), %xmm2
	movss	.LC78(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 495 1 discriminator 13
	addq	$16, %rbx
	.loc 1 492 10
	pxor	%xmm3, %xmm3
	movss	.LC48(%rip), %xmm2
	movss	.LC40(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 495 1 discriminator 14
	addq	$16, %rbx
	.loc 1 493 10
	pxor	%xmm3, %xmm3
	movss	.LC46(%rip), %xmm2
	movss	.LC62(%rip), %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 495 1 discriminator 15
	addq	$16, %rbx
	.loc 1 494 10
	pxor	%xmm3, %xmm3
	pxor	%xmm2, %xmm2
	pxor	%xmm1, %xmm1
	movl	.LC16(%rip), %eax
	movd	%eax, %xmm0
	call	_ZN9opensynthL5mkCfgEffff
	movq	%xmm0, %rax
	movdqa	%xmm1, %xmm0
	movq	%rax, (%rbx)
	movq	%xmm0, 8(%rbx)
	.loc 1 559 1
	nop
	movq	-8(%rbp), %rbx
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE1436:
	.size	_Z41__static_initialization_and_destruction_0v, .-_Z41__static_initialization_and_destruction_0v
	.type	_GLOBAL__sub_I_drum_kit_mapping.cpp, @function
_GLOBAL__sub_I_drum_kit_mapping.cpp:
.LFB1437:
	.loc 1 559 1
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	.loc 1 559 1
	call	_Z41__static_initialization_and_destruction_0v
	popq	%rbp
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE1437:
	.size	_GLOBAL__sub_I_drum_kit_mapping.cpp, .-_GLOBAL__sub_I_drum_kit_mapping.cpp
	.section	.init_array,"aw"
	.align 8
	.quad	_GLOBAL__sub_I_drum_kit_mapping.cpp
	.section	.rodata
	.align 4
.LC16:
	.long	1065353216
	.align 4
.LC17:
	.long	-1082130432
	.align 4
.LC18:
	.long	1056964608
	.align 4
.LC38:
	.long	1061997773
	.align 4
.LC39:
	.long	1060320051
	.align 4
.LC40:
	.long	1063675494
	.align 4
.LC41:
	.long	1050253722
	.align 4
.LC42:
	.long	1059481190
	.align 4
.LC43:
	.long	1061158912
	.align 4
.LC44:
	.long	1058642330
	.align 4
.LC45:
	.long	1062836634
	.align 4
.LC46:
	.long	1053609165
	.align 4
.LC47:
	.long	1031127695
	.align 4
.LC48:
	.long	1051931443
	.align 4
.LC49:
	.long	1077936128
	.align 4
.LC50:
	.long	1067030938
	.align 4
.LC51:
	.long	1025758986
	.align 4
.LC52:
	.long	1048576000
	.align 4
.LC53:
	.long	1039516303
	.align 4
.LC54:
	.long	1066611507
	.align 4
.LC55:
	.long	1066192077
	.align 4
.LC56:
	.long	1017370378
	.align 4
.LC57:
	.long	1041865114
	.align 4
.LC58:
	.long	1065772646
	.align 4
.LC59:
	.long	1043878380
	.align 4
.LC60:
	.long	1072064102
	.align 4
.LC61:
	.long	1014350479
	.align 4
.LC62:
	.long	1064514355
	.align 4
.LC63:
	.long	1045220557
	.align 4
.LC64:
	.long	1069547520
	.align 4
.LC65:
	.long	1067869798
	.align 4
.LC66:
	.long	1011129254
	.align 4
.LC67:
	.long	1036831949
	.align 4
.LC68:
	.long	1028443341
	.align 4
.LC69:
	.long	1057803469
	.align 4
.LC70:
	.long	1022739087
	.align 4
.LC71:
	.long	1032805417
	.align 4
.LC72:
	.long	1046562734
	.align 4
.LC73:
	.long	1020054733
	.align 4
.LC74:
	.long	1068708659
	.align 4
.LC75:
	.long	1041194025
	.align 4
.LC76:
	.long	1042536202
	.align 4
.LC77:
	.long	1008981770
	.align 4
.LC78:
	.long	1055286886
	.align 4
.LC79:
	.long	1049582633
	.align 4
.LC80:
	.long	1075838976
	.align 4
.LC81:
	.long	1034147594
	.align 4
.LC82:
	.long	1082130432
	.align 4
.LC83:
	.long	1073741824
	.align 4
.LC84:
	.long	1084227584
	.align 4
.LC85:
	.long	1024416809
	.align 4
.LC86:
	.long	1050924810
	.align 4
.LC87:
	.long	1080033280
	.align 4
.LC88:
	.long	1047904911
	.align 4
.LC89:
	.long	1067450368
	.align 4
.LC90:
	.long	1054280253
	.text
.Letext0:
	.file 2 "/usr/include/bits/types.h"
	.file 3 "/usr/include/bits/stdint-intn.h"
	.file 4 "/usr/include/bits/stdint-uintn.h"
	.file 5 "/usr/include/bits/stdint-least.h"
	.file 6 "/usr/include/stdint.h"
	.file 7 "/usr/include/c++/16.1.1/cstdint"
	.file 8 "/usr/include/c++/16.1.1/type_traits"
	.file 9 "/usr/include/c++/16.1.1/cmath"
	.file 10 "/usr/include/c++/16.1.1/concepts"
	.file 11 "/usr/include/c++/16.1.1/bits/iterator_concepts.h"
	.file 12 "/usr/include/c++/16.1.1/compare"
	.file 13 "/usr/include/c++/16.1.1/debug/debug.h"
	.file 14 "/usr/include/c++/16.1.1/x86_64-pc-linux-gnu/bits/c++config.h"
	.file 15 "/usr/include/math.h"
	.file 16 "/usr/include/c++/16.1.1/bits/utility.h"
	.file 17 "/usr/include/c++/16.1.1/bits/ptr_traits.h"
	.file 18 "/home/synth/projects/05-active-dev/open-synth/include/drum_kit_mapping.h"
	.file 19 "/home/synth/projects/05-active-dev/open-synth/include/drum_synth.h"
	.section	.debug_info,"",@progbits
.Ldebug_info0:
	.long	0x97b
	.value	0x5
	.byte	0x1
	.byte	0x8
	.long	.Ldebug_abbrev0
	.uleb128 0x17
	.long	.LASF141
	.byte	0x21
	.byte	0x4
	.long	0x31512
	.long	.LASF0
	.long	.LASF1
	.quad	.Ltext0
	.quad	.Letext0-.Ltext0
	.long	.Ldebug_line0
	.uleb128 0x3
	.byte	0x1
	.byte	0x8
	.long	.LASF2
	.uleb128 0x3
	.byte	0x2
	.byte	0x7
	.long	.LASF3
	.uleb128 0x3
	.byte	0x4
	.byte	0x7
	.long	.LASF4
	.uleb128 0x3
	.byte	0x8
	.byte	0x7
	.long	.LASF5
	.uleb128 0x1
	.long	.LASF7
	.byte	0x2
	.byte	0x25
	.byte	0x15
	.long	0x5b
	.uleb128 0x3
	.byte	0x1
	.byte	0x6
	.long	.LASF6
	.uleb128 0x1
	.long	.LASF8
	.byte	0x2
	.byte	0x26
	.byte	0x17
	.long	0x33
	.uleb128 0x1
	.long	.LASF9
	.byte	0x2
	.byte	0x27
	.byte	0x1a
	.long	0x7a
	.uleb128 0x3
	.byte	0x2
	.byte	0x5
	.long	.LASF10
	.uleb128 0x1
	.long	.LASF11
	.byte	0x2
	.byte	0x28
	.byte	0x1c
	.long	0x3a
	.uleb128 0x1
	.long	.LASF12
	.byte	0x2
	.byte	0x29
	.byte	0x14
	.long	0x99
	.uleb128 0x18
	.byte	0x4
	.byte	0x5
	.string	"int"
	.uleb128 0x1
	.long	.LASF13
	.byte	0x2
	.byte	0x2a
	.byte	0x16
	.long	0x41
	.uleb128 0x1
	.long	.LASF14
	.byte	0x2
	.byte	0x2c
	.byte	0x19
	.long	0xb8
	.uleb128 0x3
	.byte	0x8
	.byte	0x5
	.long	.LASF15
	.uleb128 0x1
	.long	.LASF16
	.byte	0x2
	.byte	0x2d
	.byte	0x1b
	.long	0x48
	.uleb128 0x1
	.long	.LASF17
	.byte	0x2
	.byte	0x34
	.byte	0x12
	.long	0x4f
	.uleb128 0x1
	.long	.LASF18
	.byte	0x2
	.byte	0x35
	.byte	0x13
	.long	0x62
	.uleb128 0x1
	.long	.LASF19
	.byte	0x2
	.byte	0x36
	.byte	0x13
	.long	0x6e
	.uleb128 0x1
	.long	.LASF20
	.byte	0x2
	.byte	0x37
	.byte	0x14
	.long	0x81
	.uleb128 0x1
	.long	.LASF21
	.byte	0x2
	.byte	0x38
	.byte	0x13
	.long	0x8d
	.uleb128 0x1
	.long	.LASF22
	.byte	0x2
	.byte	0x39
	.byte	0x14
	.long	0xa0
	.uleb128 0x1
	.long	.LASF23
	.byte	0x2
	.byte	0x3a
	.byte	0x13
	.long	0xac
	.uleb128 0x1
	.long	.LASF24
	.byte	0x2
	.byte	0x3b
	.byte	0x14
	.long	0xbf
	.uleb128 0x1
	.long	.LASF25
	.byte	0x2
	.byte	0x48
	.byte	0x12
	.long	0xb8
	.uleb128 0x1
	.long	.LASF26
	.byte	0x2
	.byte	0x49
	.byte	0x1b
	.long	0x48
	.uleb128 0x3
	.byte	0x1
	.byte	0x6
	.long	.LASF27
	.uleb128 0x10
	.long	0x143
	.uleb128 0x1
	.long	.LASF28
	.byte	0x3
	.byte	0x18
	.byte	0x12
	.long	0x4f
	.uleb128 0x1
	.long	.LASF29
	.byte	0x3
	.byte	0x19
	.byte	0x13
	.long	0x6e
	.uleb128 0x1
	.long	.LASF30
	.byte	0x3
	.byte	0x1a
	.byte	0x13
	.long	0x8d
	.uleb128 0x1
	.long	.LASF31
	.byte	0x3
	.byte	0x1b
	.byte	0x13
	.long	0xac
	.uleb128 0x1
	.long	.LASF32
	.byte	0x4
	.byte	0x18
	.byte	0x13
	.long	0x62
	.uleb128 0x1
	.long	.LASF33
	.byte	0x4
	.byte	0x19
	.byte	0x14
	.long	0x81
	.uleb128 0x1
	.long	.LASF34
	.byte	0x4
	.byte	0x1a
	.byte	0x14
	.long	0xa0
	.uleb128 0x1
	.long	.LASF35
	.byte	0x4
	.byte	0x1b
	.byte	0x14
	.long	0xbf
	.uleb128 0x1
	.long	.LASF36
	.byte	0x5
	.byte	0x19
	.byte	0x18
	.long	0xcb
	.uleb128 0x1
	.long	.LASF37
	.byte	0x5
	.byte	0x1a
	.byte	0x19
	.long	0xe3
	.uleb128 0x1
	.long	.LASF38
	.byte	0x5
	.byte	0x1b
	.byte	0x19
	.long	0xfb
	.uleb128 0x1
	.long	.LASF39
	.byte	0x5
	.byte	0x1c
	.byte	0x19
	.long	0x113
	.uleb128 0x1
	.long	.LASF40
	.byte	0x5
	.byte	0x1f
	.byte	0x19
	.long	0xd7
	.uleb128 0x1
	.long	.LASF41
	.byte	0x5
	.byte	0x20
	.byte	0x1a
	.long	0xef
	.uleb128 0x1
	.long	.LASF42
	.byte	0x5
	.byte	0x21
	.byte	0x1a
	.long	0x107
	.uleb128 0x1
	.long	.LASF43
	.byte	0x5
	.byte	0x22
	.byte	0x1a
	.long	0x11f
	.uleb128 0x1
	.long	.LASF44
	.byte	0x6
	.byte	0x33
	.byte	0x16
	.long	0x5b
	.uleb128 0x1
	.long	.LASF45
	.byte	0x6
	.byte	0x35
	.byte	0x13
	.long	0xb8
	.uleb128 0x1
	.long	.LASF46
	.byte	0x6
	.byte	0x36
	.byte	0x13
	.long	0xb8
	.uleb128 0x1
	.long	.LASF47
	.byte	0x6
	.byte	0x37
	.byte	0x13
	.long	0xb8
	.uleb128 0x1
	.long	.LASF48
	.byte	0x6
	.byte	0x40
	.byte	0x18
	.long	0x33
	.uleb128 0x1
	.long	.LASF49
	.byte	0x6
	.byte	0x42
	.byte	0x1b
	.long	0x48
	.uleb128 0x1
	.long	.LASF50
	.byte	0x6
	.byte	0x43
	.byte	0x1b
	.long	0x48
	.uleb128 0x1
	.long	.LASF51
	.byte	0x6
	.byte	0x44
	.byte	0x1b
	.long	0x48
	.uleb128 0x1
	.long	.LASF52
	.byte	0x6
	.byte	0x50
	.byte	0x13
	.long	0xb8
	.uleb128 0x1
	.long	.LASF53
	.byte	0x6
	.byte	0x53
	.byte	0x1b
	.long	0x48
	.uleb128 0x1
	.long	.LASF54
	.byte	0x6
	.byte	0x5e
	.byte	0x15
	.long	0x12b
	.uleb128 0x1
	.long	.LASF55
	.byte	0x6
	.byte	0x5f
	.byte	0x16
	.long	0x137
	.uleb128 0x19
	.string	"std"
	.byte	0xe
	.value	0x156
	.byte	0xb
	.long	0x3ce
	.uleb128 0x2
	.byte	0x35
	.long	0x14f
	.uleb128 0x2
	.byte	0x36
	.long	0x15b
	.uleb128 0x2
	.byte	0x37
	.long	0x167
	.uleb128 0x2
	.byte	0x38
	.long	0x173
	.uleb128 0x2
	.byte	0x3a
	.long	0x20f
	.uleb128 0x2
	.byte	0x3b
	.long	0x21b
	.uleb128 0x2
	.byte	0x3c
	.long	0x227
	.uleb128 0x2
	.byte	0x3d
	.long	0x233
	.uleb128 0x2
	.byte	0x3f
	.long	0x1af
	.uleb128 0x2
	.byte	0x40
	.long	0x1bb
	.uleb128 0x2
	.byte	0x41
	.long	0x1c7
	.uleb128 0x2
	.byte	0x42
	.long	0x1d3
	.uleb128 0x2
	.byte	0x44
	.long	0x287
	.uleb128 0x2
	.byte	0x45
	.long	0x26f
	.uleb128 0x2
	.byte	0x47
	.long	0x17f
	.uleb128 0x2
	.byte	0x48
	.long	0x18b
	.uleb128 0x2
	.byte	0x49
	.long	0x197
	.uleb128 0x2
	.byte	0x4a
	.long	0x1a3
	.uleb128 0x2
	.byte	0x4c
	.long	0x23f
	.uleb128 0x2
	.byte	0x4d
	.long	0x24b
	.uleb128 0x2
	.byte	0x4e
	.long	0x257
	.uleb128 0x2
	.byte	0x4f
	.long	0x263
	.uleb128 0x2
	.byte	0x51
	.long	0x1df
	.uleb128 0x2
	.byte	0x52
	.long	0x1eb
	.uleb128 0x2
	.byte	0x53
	.long	0x1f7
	.uleb128 0x2
	.byte	0x54
	.long	0x203
	.uleb128 0x2
	.byte	0x56
	.long	0x293
	.uleb128 0x2
	.byte	0x57
	.long	0x27b
	.uleb128 0xb
	.long	.LASF56
	.byte	0x8
	.value	0xbff
	.byte	0xd
	.uleb128 0xb
	.long	.LASF57
	.byte	0x8
	.value	0xc54
	.byte	0xd
	.uleb128 0x11
	.value	0x82c
	.long	0x437
	.uleb128 0x11
	.value	0x82d
	.long	0x42b
	.uleb128 0x1a
	.long	.LASF58
	.byte	0x10
	.value	0x298
	.byte	0xd
	.long	0x3a3
	.uleb128 0xc
	.long	.LASF59
	.byte	0xa
	.byte	0xbf
	.byte	0xf
	.uleb128 0x1b
	.long	.LASF65
	.byte	0xa
	.byte	0xfc
	.byte	0x16
	.uleb128 0xc
	.long	.LASF60
	.byte	0xb
	.byte	0x68
	.byte	0xf
	.uleb128 0xb
	.long	.LASF61
	.byte	0xb
	.value	0x356
	.byte	0xd
	.byte	0
	.uleb128 0xc
	.long	.LASF62
	.byte	0xc
	.byte	0x36
	.byte	0xd
	.uleb128 0xc
	.long	.LASF63
	.byte	0x8
	.byte	0xaf
	.byte	0xd
	.uleb128 0xb
	.long	.LASF64
	.byte	0xc
	.value	0x258
	.byte	0xd
	.uleb128 0x1c
	.long	.LASF65
	.byte	0xc
	.value	0x4ae
	.byte	0x14
	.uleb128 0xc
	.long	.LASF66
	.byte	0xd
	.byte	0x32
	.byte	0xd
	.byte	0
	.uleb128 0x3
	.byte	0x1
	.byte	0x2
	.long	.LASF67
	.uleb128 0x3
	.byte	0x8
	.byte	0x7
	.long	.LASF68
	.uleb128 0x3
	.byte	0x10
	.byte	0x7
	.long	.LASF69
	.uleb128 0x3
	.byte	0x8
	.byte	0x5
	.long	.LASF70
	.uleb128 0x3
	.byte	0x10
	.byte	0x5
	.long	.LASF71
	.uleb128 0x3
	.byte	0x4
	.byte	0x5
	.long	.LASF72
	.uleb128 0x3
	.byte	0x1
	.byte	0x10
	.long	.LASF73
	.uleb128 0x3
	.byte	0x2
	.byte	0x10
	.long	.LASF74
	.uleb128 0x3
	.byte	0x4
	.byte	0x10
	.long	.LASF75
	.uleb128 0xb
	.long	.LASF76
	.byte	0xe
	.value	0x17b
	.byte	0xb
	.uleb128 0x3
	.byte	0x10
	.byte	0x4
	.long	.LASF77
	.uleb128 0x3
	.byte	0x8
	.byte	0x4
	.long	.LASF78
	.uleb128 0x3
	.byte	0x4
	.byte	0x4
	.long	.LASF79
	.uleb128 0x1
	.long	.LASF80
	.byte	0xf
	.byte	0xaa
	.byte	0xf
	.long	0x424
	.uleb128 0x1
	.long	.LASF81
	.byte	0xf
	.byte	0xab
	.byte	0x10
	.long	0x41d
	.uleb128 0x3
	.byte	0x4
	.byte	0x4
	.long	.LASF82
	.uleb128 0x3
	.byte	0x8
	.byte	0x4
	.long	.LASF83
	.uleb128 0x3
	.byte	0x10
	.byte	0x4
	.long	.LASF84
	.uleb128 0x3
	.byte	0x8
	.byte	0x4
	.long	.LASF85
	.uleb128 0x3
	.byte	0x10
	.byte	0x4
	.long	.LASF86
	.uleb128 0xf
	.long	0x14a
	.uleb128 0x12
	.long	.LASF87
	.byte	0x11
	.byte	0x27
	.long	0x47f
	.uleb128 0x1d
	.byte	0xd
	.byte	0x3a
	.byte	0x18
	.long	0x3c5
	.byte	0
	.uleb128 0x3
	.byte	0x10
	.byte	0x4
	.long	.LASF88
	.uleb128 0x12
	.long	.LASF89
	.byte	0x12
	.byte	0x5
	.long	0x6bf
	.uleb128 0x1e
	.long	.LASF142
	.byte	0x7
	.byte	0x1
	.long	0x17f
	.byte	0x13
	.byte	0x9
	.byte	0xc
	.long	0x504
	.uleb128 0x5
	.long	.LASF90
	.byte	0
	.uleb128 0x5
	.long	.LASF91
	.byte	0x1
	.uleb128 0x5
	.long	.LASF92
	.byte	0x2
	.uleb128 0x5
	.long	.LASF93
	.byte	0x3
	.uleb128 0x5
	.long	.LASF94
	.byte	0x4
	.uleb128 0x5
	.long	.LASF95
	.byte	0x5
	.uleb128 0x5
	.long	.LASF96
	.byte	0x6
	.uleb128 0x5
	.long	.LASF97
	.byte	0x7
	.uleb128 0x5
	.long	.LASF98
	.byte	0x8
	.uleb128 0x5
	.long	.LASF99
	.byte	0x9
	.uleb128 0x5
	.long	.LASF100
	.byte	0xa
	.uleb128 0x5
	.long	.LASF101
	.byte	0xb
	.uleb128 0x5
	.long	.LASF102
	.byte	0xc
	.uleb128 0x5
	.long	.LASF103
	.byte	0xd
	.uleb128 0x5
	.long	.LASF104
	.byte	0xe
	.uleb128 0x5
	.long	.LASF105
	.byte	0xf
	.byte	0
	.uleb128 0x1f
	.long	.LASF110
	.byte	0x10
	.byte	0x13
	.byte	0x44
	.byte	0x8
	.long	0x542
	.uleb128 0x8
	.long	.LASF106
	.byte	0x45
	.byte	0xb
	.long	0x424
	.byte	0
	.uleb128 0x8
	.long	.LASF107
	.byte	0x46
	.byte	0xb
	.long	0x424
	.byte	0x4
	.uleb128 0x8
	.long	.LASF108
	.byte	0x47
	.byte	0xb
	.long	0x424
	.byte	0x8
	.uleb128 0x8
	.long	.LASF109
	.byte	0x48
	.byte	0xb
	.long	0x424
	.byte	0xc
	.byte	0
	.uleb128 0x10
	.long	0x504
	.uleb128 0x20
	.long	.LASF111
	.value	0x108
	.byte	0x13
	.byte	0x4d
	.byte	0x8
	.long	0x56e
	.uleb128 0x8
	.long	.LASF112
	.byte	0x4e
	.byte	0x11
	.long	0x466
	.byte	0
	.uleb128 0x8
	.long	.LASF113
	.byte	0x4f
	.byte	0x15
	.long	0x6bf
	.byte	0x8
	.byte	0
	.uleb128 0x9
	.long	.LASF114
	.byte	0x7a
	.long	0x6cf
	.uleb128 0x9
	.long	.LASF115
	.byte	0x9e
	.long	0x6cf
	.uleb128 0x9
	.long	.LASF116
	.byte	0xb2
	.long	0x6cf
	.uleb128 0x9
	.long	.LASF117
	.byte	0xc6
	.long	0x6cf
	.uleb128 0x9
	.long	.LASF118
	.byte	0xda
	.long	0x6cf
	.uleb128 0x9
	.long	.LASF119
	.byte	0xee
	.long	0x6cf
	.uleb128 0x6
	.long	.LASF120
	.value	0x102
	.byte	0x1e
	.long	0x6cf
	.uleb128 0x6
	.long	.LASF121
	.value	0x116
	.byte	0x1e
	.long	0x6cf
	.uleb128 0x6
	.long	.LASF122
	.value	0x12a
	.byte	0x1e
	.long	0x6cf
	.uleb128 0x6
	.long	.LASF123
	.value	0x13e
	.byte	0x1e
	.long	0x6cf
	.uleb128 0x6
	.long	.LASF124
	.value	0x152
	.byte	0x1e
	.long	0x6cf
	.uleb128 0x6
	.long	.LASF125
	.value	0x166
	.byte	0x1e
	.long	0x6cf
	.uleb128 0x6
	.long	.LASF126
	.value	0x17a
	.byte	0x1e
	.long	0x6cf
	.uleb128 0x6
	.long	.LASF127
	.value	0x18e
	.byte	0x1e
	.long	0x6cf
	.uleb128 0x6
	.long	.LASF128
	.value	0x1a2
	.byte	0x1e
	.long	0x6cf
	.uleb128 0x6
	.long	.LASF129
	.value	0x1b6
	.byte	0x1e
	.long	0x6cf
	.uleb128 0x6
	.long	.LASF130
	.value	0x1ca
	.byte	0x1e
	.long	0x6cf
	.uleb128 0x6
	.long	.LASF131
	.value	0x1de
	.byte	0x1e
	.long	0x6cf
	.uleb128 0x6
	.long	.LASF132
	.value	0x1f3
	.byte	0x1f
	.long	0x7ed
	.uleb128 0x6
	.long	.LASF133
	.value	0x208
	.byte	0x14
	.long	0x811
	.uleb128 0x21
	.long	.LASF134
	.byte	0x1
	.value	0x226
	.byte	0x6
	.long	.LASF143
	.long	0x669
	.uleb128 0x7
	.long	0x85e
	.byte	0
	.uleb128 0x22
	.long	.LASF144
	.byte	0x1
	.byte	0x6d
	.byte	0x18
	.long	0x504
	.long	0x68e
	.uleb128 0x7
	.long	0x424
	.uleb128 0x7
	.long	0x424
	.uleb128 0x7
	.long	0x424
	.uleb128 0x7
	.long	0x424
	.byte	0
	.uleb128 0x23
	.long	.LASF145
	.byte	0x1
	.byte	0x54
	.byte	0xd
	.long	.LASF146
	.long	0x466
	.long	0x6a8
	.uleb128 0x7
	.long	0x99
	.byte	0
	.uleb128 0x24
	.long	.LASF135
	.byte	0x1
	.byte	0x8
	.byte	0x5
	.long	.LASF147
	.long	0x99
	.uleb128 0x7
	.long	0x99
	.byte	0
	.byte	0
	.uleb128 0xd
	.long	0x504
	.long	0x6cf
	.uleb128 0xe
	.long	0x48
	.byte	0xf
	.byte	0
	.uleb128 0xd
	.long	0x542
	.long	0x6df
	.uleb128 0xe
	.long	0x48
	.byte	0xf
	.byte	0
	.uleb128 0x4
	.long	0x56e
	.uleb128 0x9
	.byte	0x3
	.quad	_ZN9opensynthL6stdCfgE
	.uleb128 0x4
	.long	0x578
	.uleb128 0x9
	.byte	0x3
	.quad	_ZN9opensynthL7roomCfgE
	.uleb128 0x4
	.long	0x582
	.uleb128 0x9
	.byte	0x3
	.quad	_ZN9opensynthL8powerCfgE
	.uleb128 0x4
	.long	0x58c
	.uleb128 0x9
	.byte	0x3
	.quad	_ZN9opensynthL8tr808CfgE
	.uleb128 0x4
	.long	0x596
	.uleb128 0x9
	.byte	0x3
	.quad	_ZN9opensynthL8tr909CfgE
	.uleb128 0x4
	.long	0x5a0
	.uleb128 0x9
	.byte	0x3
	.quad	_ZN9opensynthL13electronicCfgE
	.uleb128 0x4
	.long	0x5aa
	.uleb128 0x9
	.byte	0x3
	.quad	_ZN9opensynthL7jazzCfgE
	.uleb128 0x4
	.long	0x5b6
	.uleb128 0x9
	.byte	0x3
	.quad	_ZN9opensynthL8brushCfgE
	.uleb128 0x4
	.long	0x5c2
	.uleb128 0x9
	.byte	0x3
	.quad	_ZN9opensynthL12orchestraCfgE
	.uleb128 0x4
	.long	0x5ce
	.uleb128 0x9
	.byte	0x3
	.quad	_ZN9opensynthL6sfxCfgE
	.uleb128 0x4
	.long	0x5da
	.uleb128 0x9
	.byte	0x3
	.quad	_ZN9opensynthL8latinCfgE
	.uleb128 0x4
	.long	0x5e6
	.uleb128 0x9
	.byte	0x3
	.quad	_ZN9opensynthL8metalCfgE
	.uleb128 0x4
	.long	0x5f2
	.uleb128 0x9
	.byte	0x3
	.quad	_ZN9opensynthL10vintageCfgE
	.uleb128 0x4
	.long	0x5fe
	.uleb128 0x9
	.byte	0x3
	.quad	_ZN9opensynthL8danceCfgE
	.uleb128 0x4
	.long	0x60a
	.uleb128 0x9
	.byte	0x3
	.quad	_ZN9opensynthL11acousticCfgE
	.uleb128 0x4
	.long	0x616
	.uleb128 0x9
	.byte	0x3
	.quad	_ZN9opensynthL9hiphopCfgE
	.uleb128 0x4
	.long	0x622
	.uleb128 0x9
	.byte	0x3
	.quad	_ZN9opensynthL13percussionCfgE
	.uleb128 0x4
	.long	0x62e
	.uleb128 0x9
	.byte	0x3
	.quad	_ZN9opensynthL12cinematicCfgE
	.uleb128 0xd
	.long	0x7fd
	.long	0x7fd
	.uleb128 0xe
	.long	0x48
	.byte	0x11
	.byte	0
	.uleb128 0xf
	.long	0x542
	.uleb128 0x4
	.long	0x63a
	.uleb128 0x9
	.byte	0x3
	.quad	_ZN9opensynthL14kitPresetTableE
	.uleb128 0xd
	.long	0x466
	.long	0x821
	.uleb128 0xe
	.long	0x48
	.byte	0x11
	.byte	0
	.uleb128 0x4
	.long	0x646
	.uleb128 0x9
	.byte	0x3
	.quad	_ZN9opensynthL14kitPresetNamesE
	.uleb128 0x13
	.long	.LASF136
	.quad	.LFB1437
	.quad	.LFE1437-.LFB1437
	.uleb128 0x1
	.byte	0x9c
	.uleb128 0x13
	.long	.LASF137
	.quad	.LFB1436
	.quad	.LFE1436-.LFB1436
	.uleb128 0x1
	.byte	0x9c
	.uleb128 0xf
	.long	0x547
	.uleb128 0x14
	.long	0x652
	.quad	.LFB1280
	.quad	.LFE1280-.LFB1280
	.uleb128 0x1
	.byte	0x9c
	.long	0x8cd
	.uleb128 0x25
	.long	.LASF138
	.byte	0x1
	.value	0x226
	.byte	0x27
	.long	0x85e
	.uleb128 0x2
	.byte	0x91
	.sleb128 -40
	.uleb128 0x15
	.quad	.LBB2
	.quad	.LBE2-.LBB2
	.uleb128 0x16
	.string	"k"
	.value	0x227
	.byte	0xe
	.long	0x99
	.uleb128 0x2
	.byte	0x91
	.sleb128 -24
	.uleb128 0x15
	.quad	.LBB4
	.quad	.LBE4-.LBB4
	.uleb128 0x16
	.string	"i"
	.value	0x229
	.byte	0x12
	.long	0x99
	.uleb128 0x2
	.byte	0x91
	.sleb128 -20
	.byte	0
	.byte	0
	.byte	0
	.uleb128 0x26
	.long	0x669
	.quad	.LFB1276
	.quad	.LFE1276-.LFB1276
	.uleb128 0x1
	.byte	0x9c
	.long	0x92e
	.uleb128 0xa
	.long	.LASF106
	.byte	0x6d
	.byte	0x24
	.long	0x424
	.uleb128 0x2
	.byte	0x91
	.sleb128 -52
	.uleb128 0xa
	.long	.LASF107
	.byte	0x6d
	.byte	0x32
	.long	0x424
	.uleb128 0x2
	.byte	0x91
	.sleb128 -56
	.uleb128 0xa
	.long	.LASF108
	.byte	0x6d
	.byte	0x3f
	.long	0x424
	.uleb128 0x2
	.byte	0x91
	.sleb128 -60
	.uleb128 0xa
	.long	.LASF109
	.byte	0x6d
	.byte	0x4c
	.long	0x424
	.uleb128 0x2
	.byte	0x91
	.sleb128 -64
	.uleb128 0x27
	.string	"c"
	.byte	0x1
	.byte	0x6e
	.byte	0x15
	.long	0x504
	.uleb128 0x2
	.byte	0x91
	.sleb128 -48
	.byte	0
	.uleb128 0x14
	.long	0x68e
	.quad	.LFB1275
	.quad	.LFE1275-.LFB1275
	.uleb128 0x1
	.byte	0x9c
	.long	0x958
	.uleb128 0xa
	.long	.LASF139
	.byte	0x54
	.byte	0x1e
	.long	0x99
	.uleb128 0x2
	.byte	0x91
	.sleb128 -20
	.byte	0
	.uleb128 0x28
	.long	0x6a8
	.quad	.LFB1274
	.quad	.LFE1274-.LFB1274
	.uleb128 0x1
	.byte	0x9c
	.uleb128 0xa
	.long	.LASF140
	.byte	0x8
	.byte	0x1b
	.long	0x99
	.uleb128 0x2
	.byte	0x91
	.sleb128 -20
	.byte	0
	.byte	0
	.section	.debug_abbrev,"",@progbits
.Ldebug_abbrev0:
	.uleb128 0x1
	.uleb128 0x16
	.byte	0
	.uleb128 0x3
	.uleb128 0xe
	.uleb128 0x3a
	.uleb128 0xb
	.uleb128 0x3b
	.uleb128 0xb
	.uleb128 0x39
	.uleb128 0xb
	.uleb128 0x49
	.uleb128 0x13
	.byte	0
	.byte	0
	.uleb128 0x2
	.uleb128 0x8
	.byte	0
	.uleb128 0x3a
	.uleb128 0x21
	.sleb128 7
	.uleb128 0x3b
	.uleb128 0xb
	.uleb128 0x39
	.uleb128 0x21
	.sleb128 11
	.uleb128 0x18
	.uleb128 0x13
	.byte	0
	.byte	0
	.uleb128 0x3
	.uleb128 0x24
	.byte	0
	.uleb128 0xb
	.uleb128 0xb
	.uleb128 0x3e
	.uleb128 0xb
	.uleb128 0x3
	.uleb128 0xe
	.byte	0
	.byte	0
	.uleb128 0x4
	.uleb128 0x34
	.byte	0
	.uleb128 0x47
	.uleb128 0x13
	.uleb128 0x2
	.uleb128 0x18
	.byte	0
	.byte	0
	.uleb128 0x5
	.uleb128 0x28
	.byte	0
	.uleb128 0x3
	.uleb128 0xe
	.uleb128 0x1c
	.uleb128 0xb
	.byte	0
	.byte	0
	.uleb128 0x6
	.uleb128 0x34
	.byte	0
	.uleb128 0x3
	.uleb128 0xe
	.uleb128 0x3a
	.uleb128 0x21
	.sleb128 1
	.uleb128 0x3b
	.uleb128 0x5
	.uleb128 0x39
	.uleb128 0xb
	.uleb128 0x49
	.uleb128 0x13
	.uleb128 0x3c
	.uleb128 0x19
	.byte	0
	.byte	0
	.uleb128 0x7
	.uleb128 0x5
	.byte	0
	.uleb128 0x49
	.uleb128 0x13
	.byte	0
	.byte	0
	.uleb128 0x8
	.uleb128 0xd
	.byte	0
	.uleb128 0x3
	.uleb128 0xe
	.uleb128 0x3a
	.uleb128 0x21
	.sleb128 19
	.uleb128 0x3b
	.uleb128 0xb
	.uleb128 0x39
	.uleb128 0xb
	.uleb128 0x49
	.uleb128 0x13
	.uleb128 0x38
	.uleb128 0xb
	.byte	0
	.byte	0
	.uleb128 0x9
	.uleb128 0x34
	.byte	0
	.uleb128 0x3
	.uleb128 0xe
	.uleb128 0x3a
	.uleb128 0x21
	.sleb128 1
	.uleb128 0x3b
	.uleb128 0xb
	.uleb128 0x39
	.uleb128 0x21
	.sleb128 30
	.uleb128 0x49
	.uleb128 0x13
	.uleb128 0x3c
	.uleb128 0x19
	.byte	0
	.byte	0
	.uleb128 0xa
	.uleb128 0x5
	.byte	0
	.uleb128 0x3
	.uleb128 0xe
	.uleb128 0x3a
	.uleb128 0x21
	.sleb128 1
	.uleb128 0x3b
	.uleb128 0xb
	.uleb128 0x39
	.uleb128 0xb
	.uleb128 0x49
	.uleb128 0x13
	.uleb128 0x2
	.uleb128 0x18
	.byte	0
	.byte	0
	.uleb128 0xb
	.uleb128 0x39
	.byte	0
	.uleb128 0x3
	.uleb128 0xe
	.uleb128 0x3a
	.uleb128 0xb
	.uleb128 0x3b
	.uleb128 0x5
	.uleb128 0x39
	.uleb128 0xb
	.byte	0
	.byte	0
	.uleb128 0xc
	.uleb128 0x39
	.byte	0
	.uleb128 0x3
	.uleb128 0xe
	.uleb128 0x3a
	.uleb128 0xb
	.uleb128 0x3b
	.uleb128 0xb
	.uleb128 0x39
	.uleb128 0xb
	.byte	0
	.byte	0
	.uleb128 0xd
	.uleb128 0x1
	.byte	0x1
	.uleb128 0x49
	.uleb128 0x13
	.uleb128 0x1
	.uleb128 0x13
	.byte	0
	.byte	0
	.uleb128 0xe
	.uleb128 0x21
	.byte	0
	.uleb128 0x49
	.uleb128 0x13
	.uleb128 0x2f
	.uleb128 0xb
	.byte	0
	.byte	0
	.uleb128 0xf
	.uleb128 0xf
	.byte	0
	.uleb128 0xb
	.uleb128 0x21
	.sleb128 8
	.uleb128 0x49
	.uleb128 0x13
	.byte	0
	.byte	0
	.uleb128 0x10
	.uleb128 0x26
	.byte	0
	.uleb128 0x49
	.uleb128 0x13
	.byte	0
	.byte	0
	.uleb128 0x11
	.uleb128 0x8
	.byte	0
	.uleb128 0x3a
	.uleb128 0x21
	.sleb128 9
	.uleb128 0x3b
	.uleb128 0x5
	.uleb128 0x39
	.uleb128 0x21
	.sleb128 11
	.uleb128 0x18
	.uleb128 0x13
	.byte	0
	.byte	0
	.uleb128 0x12
	.uleb128 0x39
	.byte	0x1
	.uleb128 0x3
	.uleb128 0xe
	.uleb128 0x3a
	.uleb128 0xb
	.uleb128 0x3b
	.uleb128 0xb
	.uleb128 0x39
	.uleb128 0x21
	.sleb128 11
	.uleb128 0x1
	.uleb128 0x13
	.byte	0
	.byte	0
	.uleb128 0x13
	.uleb128 0x2e
	.byte	0
	.uleb128 0x3
	.uleb128 0xe
	.uleb128 0x34
	.uleb128 0x19
	.uleb128 0x11
	.uleb128 0x1
	.uleb128 0x12
	.uleb128 0x7
	.uleb128 0x40
	.uleb128 0x18
	.uleb128 0x7c
	.uleb128 0x19
	.byte	0
	.byte	0
	.uleb128 0x14
	.uleb128 0x2e
	.byte	0x1
	.uleb128 0x47
	.uleb128 0x13
	.uleb128 0x11
	.uleb128 0x1
	.uleb128 0x12
	.uleb128 0x7
	.uleb128 0x40
	.uleb128 0x18
	.uleb128 0x7a
	.uleb128 0x19
	.uleb128 0x1
	.uleb128 0x13
	.byte	0
	.byte	0
	.uleb128 0x15
	.uleb128 0xb
	.byte	0x1
	.uleb128 0x11
	.uleb128 0x1
	.uleb128 0x12
	.uleb128 0x7
	.byte	0
	.byte	0
	.uleb128 0x16
	.uleb128 0x34
	.byte	0
	.uleb128 0x3
	.uleb128 0x8
	.uleb128 0x3a
	.uleb128 0x21
	.sleb128 1
	.uleb128 0x3b
	.uleb128 0x5
	.uleb128 0x39
	.uleb128 0xb
	.uleb128 0x49
	.uleb128 0x13
	.uleb128 0x2
	.uleb128 0x18
	.byte	0
	.byte	0
	.uleb128 0x17
	.uleb128 0x11
	.byte	0x1
	.uleb128 0x25
	.uleb128 0xe
	.uleb128 0x13
	.uleb128 0xb
	.uleb128 0x90
	.uleb128 0xb
	.uleb128 0x91
	.uleb128 0x6
	.uleb128 0x3
	.uleb128 0x1f
	.uleb128 0x1b
	.uleb128 0x1f
	.uleb128 0x11
	.uleb128 0x1
	.uleb128 0x12
	.uleb128 0x7
	.uleb128 0x10
	.uleb128 0x17
	.byte	0
	.byte	0
	.uleb128 0x18
	.uleb128 0x24
	.byte	0
	.uleb128 0xb
	.uleb128 0xb
	.uleb128 0x3e
	.uleb128 0xb
	.uleb128 0x3
	.uleb128 0x8
	.byte	0
	.byte	0
	.uleb128 0x19
	.uleb128 0x39
	.byte	0x1
	.uleb128 0x3
	.uleb128 0x8
	.uleb128 0x3a
	.uleb128 0xb
	.uleb128 0x3b
	.uleb128 0x5
	.uleb128 0x39
	.uleb128 0xb
	.uleb128 0x1
	.uleb128 0x13
	.byte	0
	.byte	0
	.uleb128 0x1a
	.uleb128 0x39
	.byte	0x1
	.uleb128 0x3
	.uleb128 0xe
	.uleb128 0x3a
	.uleb128 0xb
	.uleb128 0x3b
	.uleb128 0x5
	.uleb128 0x39
	.uleb128 0xb
	.uleb128 0x1
	.uleb128 0x13
	.byte	0
	.byte	0
	.uleb128 0x1b
	.uleb128 0x39
	.byte	0
	.uleb128 0x3
	.uleb128 0xe
	.uleb128 0x3a
	.uleb128 0xb
	.uleb128 0x3b
	.uleb128 0xb
	.uleb128 0x39
	.uleb128 0xb
	.uleb128 0x89
	.uleb128 0x19
	.byte	0
	.byte	0
	.uleb128 0x1c
	.uleb128 0x39
	.byte	0
	.uleb128 0x3
	.uleb128 0xe
	.uleb128 0x3a
	.uleb128 0xb
	.uleb128 0x3b
	.uleb128 0x5
	.uleb128 0x39
	.uleb128 0xb
	.uleb128 0x89
	.uleb128 0x19
	.byte	0
	.byte	0
	.uleb128 0x1d
	.uleb128 0x3a
	.byte	0
	.uleb128 0x3a
	.uleb128 0xb
	.uleb128 0x3b
	.uleb128 0xb
	.uleb128 0x39
	.uleb128 0xb
	.uleb128 0x18
	.uleb128 0x13
	.byte	0
	.byte	0
	.uleb128 0x1e
	.uleb128 0x4
	.byte	0x1
	.uleb128 0x3
	.uleb128 0xe
	.uleb128 0x6d
	.uleb128 0x19
	.uleb128 0x3e
	.uleb128 0xb
	.uleb128 0xb
	.uleb128 0xb
	.uleb128 0x49
	.uleb128 0x13
	.uleb128 0x3a
	.uleb128 0xb
	.uleb128 0x3b
	.uleb128 0xb
	.uleb128 0x39
	.uleb128 0xb
	.uleb128 0x1
	.uleb128 0x13
	.byte	0
	.byte	0
	.uleb128 0x1f
	.uleb128 0x13
	.byte	0x1
	.uleb128 0x3
	.uleb128 0xe
	.uleb128 0xb
	.uleb128 0xb
	.uleb128 0x3a
	.uleb128 0xb
	.uleb128 0x3b
	.uleb128 0xb
	.uleb128 0x39
	.uleb128 0xb
	.uleb128 0x1
	.uleb128 0x13
	.byte	0
	.byte	0
	.uleb128 0x20
	.uleb128 0x13
	.byte	0x1
	.uleb128 0x3
	.uleb128 0xe
	.uleb128 0xb
	.uleb128 0x5
	.uleb128 0x3a
	.uleb128 0xb
	.uleb128 0x3b
	.uleb128 0xb
	.uleb128 0x39
	.uleb128 0xb
	.uleb128 0x1
	.uleb128 0x13
	.byte	0
	.byte	0
	.uleb128 0x21
	.uleb128 0x2e
	.byte	0x1
	.uleb128 0x3f
	.uleb128 0x19
	.uleb128 0x3
	.uleb128 0xe
	.uleb128 0x3a
	.uleb128 0xb
	.uleb128 0x3b
	.uleb128 0x5
	.uleb128 0x39
	.uleb128 0xb
	.uleb128 0x6e
	.uleb128 0xe
	.uleb128 0x3c
	.uleb128 0x19
	.uleb128 0x1
	.uleb128 0x13
	.byte	0
	.byte	0
	.uleb128 0x22
	.uleb128 0x2e
	.byte	0x1
	.uleb128 0x3
	.uleb128 0xe
	.uleb128 0x3a
	.uleb128 0xb
	.uleb128 0x3b
	.uleb128 0xb
	.uleb128 0x39
	.uleb128 0xb
	.uleb128 0x49
	.uleb128 0x13
	.uleb128 0x3c
	.uleb128 0x19
	.uleb128 0x1
	.uleb128 0x13
	.byte	0
	.byte	0
	.uleb128 0x23
	.uleb128 0x2e
	.byte	0x1
	.uleb128 0x3f
	.uleb128 0x19
	.uleb128 0x3
	.uleb128 0xe
	.uleb128 0x3a
	.uleb128 0xb
	.uleb128 0x3b
	.uleb128 0xb
	.uleb128 0x39
	.uleb128 0xb
	.uleb128 0x6e
	.uleb128 0xe
	.uleb128 0x49
	.uleb128 0x13
	.uleb128 0x3c
	.uleb128 0x19
	.uleb128 0x1
	.uleb128 0x13
	.byte	0
	.byte	0
	.uleb128 0x24
	.uleb128 0x2e
	.byte	0x1
	.uleb128 0x3f
	.uleb128 0x19
	.uleb128 0x3
	.uleb128 0xe
	.uleb128 0x3a
	.uleb128 0xb
	.uleb128 0x3b
	.uleb128 0xb
	.uleb128 0x39
	.uleb128 0xb
	.uleb128 0x6e
	.uleb128 0xe
	.uleb128 0x49
	.uleb128 0x13
	.uleb128 0x3c
	.uleb128 0x19
	.byte	0
	.byte	0
	.uleb128 0x25
	.uleb128 0x5
	.byte	0
	.uleb128 0x3
	.uleb128 0xe
	.uleb128 0x3a
	.uleb128 0xb
	.uleb128 0x3b
	.uleb128 0x5
	.uleb128 0x39
	.uleb128 0xb
	.uleb128 0x49
	.uleb128 0x13
	.uleb128 0x2
	.uleb128 0x18
	.byte	0
	.byte	0
	.uleb128 0x26
	.uleb128 0x2e
	.byte	0x1
	.uleb128 0x47
	.uleb128 0x13
	.uleb128 0x11
	.uleb128 0x1
	.uleb128 0x12
	.uleb128 0x7
	.uleb128 0x40
	.uleb128 0x18
	.uleb128 0x7c
	.uleb128 0x19
	.uleb128 0x1
	.uleb128 0x13
	.byte	0
	.byte	0
	.uleb128 0x27
	.uleb128 0x34
	.byte	0
	.uleb128 0x3
	.uleb128 0x8
	.uleb128 0x3a
	.uleb128 0xb
	.uleb128 0x3b
	.uleb128 0xb
	.uleb128 0x39
	.uleb128 0xb
	.uleb128 0x49
	.uleb128 0x13
	.uleb128 0x2
	.uleb128 0x18
	.byte	0
	.byte	0
	.uleb128 0x28
	.uleb128 0x2e
	.byte	0x1
	.uleb128 0x47
	.uleb128 0x13
	.uleb128 0x11
	.uleb128 0x1
	.uleb128 0x12
	.uleb128 0x7
	.uleb128 0x40
	.uleb128 0x18
	.uleb128 0x7a
	.uleb128 0x19
	.byte	0
	.byte	0
	.byte	0
	.section	.debug_aranges,"",@progbits
	.long	0x2c
	.value	0x2
	.long	.Ldebug_info0
	.byte	0x8
	.byte	0
	.value	0
	.value	0
	.quad	.Ltext0
	.quad	.Letext0-.Ltext0
	.quad	0
	.quad	0
	.section	.debug_line,"",@progbits
.Ldebug_line0:
	.section	.debug_str,"MS",@progbits,1
.LASF136:
	.string	"_GLOBAL__sub_I_drum_kit_mapping.cpp"
.LASF81:
	.string	"double_t"
.LASF45:
	.string	"int_fast16_t"
.LASF133:
	.string	"kitPresetNames"
.LASF130:
	.string	"percussionCfg"
.LASF53:
	.string	"uintptr_t"
.LASF35:
	.string	"uint64_t"
.LASF143:
	.string	"_ZN9opensynth18initDrumKitPresetsEPNS_13DrumKitPresetE"
.LASF8:
	.string	"__uint8_t"
.LASF99:
	.string	"CLAP"
.LASF137:
	.string	"__static_initialization_and_destruction_0"
.LASF139:
	.string	"type"
.LASF68:
	.string	"long long unsigned int"
.LASF92:
	.string	"CLOSED_HH"
.LASF57:
	.string	"__swappable_with_details"
.LASF14:
	.string	"__int64_t"
.LASF50:
	.string	"uint_fast32_t"
.LASF23:
	.string	"__int_least64_t"
.LASF131:
	.string	"cinematicCfg"
.LASF110:
	.string	"DrumSoundConfig"
.LASF63:
	.string	"__detail"
.LASF142:
	.string	"DrumType"
.LASF52:
	.string	"intptr_t"
.LASF145:
	.string	"drumTypeName"
.LASF29:
	.string	"int16_t"
.LASF70:
	.string	"long long int"
.LASF6:
	.string	"signed char"
.LASF120:
	.string	"jazzCfg"
.LASF55:
	.string	"uintmax_t"
.LASF84:
	.string	"_Float128"
.LASF7:
	.string	"__int8_t"
.LASF100:
	.string	"RIMSHOT"
.LASF18:
	.string	"__uint_least8_t"
.LASF15:
	.string	"long int"
.LASF91:
	.string	"SNARE"
.LASF104:
	.string	"CONGA_LOW"
.LASF138:
	.string	"kits"
.LASF74:
	.string	"char16_t"
.LASF38:
	.string	"int_least32_t"
.LASF88:
	.string	"__float128"
.LASF44:
	.string	"int_fast8_t"
.LASF33:
	.string	"uint16_t"
.LASF103:
	.string	"CONGA_HIGH"
.LASF106:
	.string	"tuning"
.LASF140:
	.string	"midiNote"
.LASF73:
	.string	"char8_t"
.LASF82:
	.string	"_Float32"
.LASF59:
	.string	"__swap"
.LASF13:
	.string	"__uint32_t"
.LASF108:
	.string	"decay"
.LASF9:
	.string	"__int16_t"
.LASF42:
	.string	"uint_least32_t"
.LASF141:
	.string	"GNU C++20 16.1.1 20260430 -mtune=generic -march=x86-64 -g -std=gnu++20 -fPIC -fvisibility=hidden -fvisibility-inlines-hidden"
.LASF19:
	.string	"__int_least16_t"
.LASF113:
	.string	"sounds"
.LASF22:
	.string	"__uint_least32_t"
.LASF98:
	.string	"RIDE"
.LASF121:
	.string	"brushCfg"
.LASF62:
	.string	"__cmp_cat"
.LASF71:
	.string	"__int128"
.LASF5:
	.string	"long unsigned int"
.LASF112:
	.string	"name"
.LASF107:
	.string	"level"
.LASF102:
	.string	"SHAKER"
.LASF3:
	.string	"short unsigned int"
.LASF126:
	.string	"vintageCfg"
.LASF25:
	.string	"__intmax_t"
.LASF123:
	.string	"sfxCfg"
.LASF114:
	.string	"stdCfg"
.LASF80:
	.string	"float_t"
.LASF111:
	.string	"DrumKitPreset"
.LASF51:
	.string	"uint_fast64_t"
.LASF72:
	.string	"wchar_t"
.LASF125:
	.string	"metalCfg"
.LASF67:
	.string	"bool"
.LASF12:
	.string	"__int32_t"
.LASF117:
	.string	"tr808Cfg"
.LASF118:
	.string	"tr909Cfg"
.LASF87:
	.string	"__gnu_debug"
.LASF127:
	.string	"danceCfg"
.LASF36:
	.string	"int_least8_t"
.LASF95:
	.string	"TOM_MID"
.LASF96:
	.string	"TOM_LOW"
.LASF93:
	.string	"OPEN_HH"
.LASF46:
	.string	"int_fast32_t"
.LASF39:
	.string	"int_least64_t"
.LASF54:
	.string	"intmax_t"
.LASF94:
	.string	"TOM_HIGH"
.LASF16:
	.string	"__uint64_t"
.LASF79:
	.string	"float"
.LASF43:
	.string	"uint_least64_t"
.LASF49:
	.string	"uint_fast16_t"
.LASF58:
	.string	"ranges"
.LASF69:
	.string	"__int128 unsigned"
.LASF24:
	.string	"__uint_least64_t"
.LASF147:
	.string	"_ZN9opensynth17gm2NoteToDrumTypeEi"
.LASF30:
	.string	"int32_t"
.LASF2:
	.string	"unsigned char"
.LASF86:
	.string	"_Float64x"
.LASF56:
	.string	"__swappable_details"
.LASF83:
	.string	"_Float64"
.LASF10:
	.string	"short int"
.LASF132:
	.string	"kitPresetTable"
.LASF48:
	.string	"uint_fast8_t"
.LASF144:
	.string	"mkCfg"
.LASF64:
	.string	"__compare"
.LASF135:
	.string	"gm2NoteToDrumType"
.LASF75:
	.string	"char32_t"
.LASF37:
	.string	"int_least16_t"
.LASF116:
	.string	"powerCfg"
.LASF78:
	.string	"double"
.LASF34:
	.string	"uint32_t"
.LASF128:
	.string	"acousticCfg"
.LASF109:
	.string	"toneMix"
.LASF77:
	.string	"long double"
.LASF27:
	.string	"char"
.LASF119:
	.string	"electronicCfg"
.LASF4:
	.string	"unsigned int"
.LASF11:
	.string	"__uint16_t"
.LASF101:
	.string	"COWBELL"
.LASF40:
	.string	"uint_least8_t"
.LASF66:
	.string	"__debug"
.LASF41:
	.string	"uint_least16_t"
.LASF26:
	.string	"__uintmax_t"
.LASF21:
	.string	"__int_least32_t"
.LASF20:
	.string	"__uint_least16_t"
.LASF47:
	.string	"int_fast64_t"
.LASF60:
	.string	"__imove"
.LASF97:
	.string	"CRASH"
.LASF124:
	.string	"latinCfg"
.LASF28:
	.string	"int8_t"
.LASF65:
	.string	"_Cpo"
.LASF122:
	.string	"orchestraCfg"
.LASF17:
	.string	"__int_least8_t"
.LASF32:
	.string	"uint8_t"
.LASF105:
	.string	"COUNT"
.LASF85:
	.string	"_Float32x"
.LASF134:
	.string	"initDrumKitPresets"
.LASF31:
	.string	"int64_t"
.LASF129:
	.string	"hiphopCfg"
.LASF146:
	.string	"_ZN9opensynth12drumTypeNameEi"
.LASF89:
	.string	"opensynth"
.LASF90:
	.string	"KICK"
.LASF61:
	.string	"__iswap"
.LASF76:
	.string	"__gnu_cxx"
.LASF115:
	.string	"roomCfg"
	.section	.debug_line_str,"MS",@progbits,1
.LASF1:
	.string	"/home/synth/projects/05-active-dev/open-synth/build"
.LASF0:
	.string	"/home/synth/projects/05-active-dev/open-synth/dsp/drum_kit_mapping.cpp"
	.ident	"GCC: (GNU) 16.1.1 20260430"
	.section	.note.GNU-stack,"",@progbits
