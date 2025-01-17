/* 
	[ Hijack Installer MSP 1.0 ]

	Installs the OAM DMA hijack that executes code at $D440 every frame
*/

SECTION "MSPHijackInstaller", ROM0


DEF BackupMSP		EQU $D430
DEF Payload			EQU $D440

start:
	; Check to see if OAM DMA Hijack is active
	ldh a, [$FF87]		; hDMARoutine.wait
	cp $18
	jr z, .installed

	ld hl, $FF87		; hDMARoutine.wait
	ld a, $18
	ld [hli], a
	ld a, $66
	ld [hl], a

	ld hl, $FFEF		; hSpriteMapXCoord
	ld a, $20
	ld [hli], a
	ld a, $95
	ld [hli], a
	ld a, $18
	ld [hli], a
	ld a, $07
	ld [hl], a
	
	ld hl, $FFFA		; hDisableJoypadPolling+1 (unused)
	ld a, $C3
	ld [hli], a
	ld a, LOW(Payload)
	ld [hli], a
	ld a, HIGH(Payload)
	ld [hl], a
	
	; Fallthrough

	; The Hijack has been installed
	; Jump to the backup MSP to execute the current map script
.installed
	ld hl, $D430
	ld a, [hli]
	ld h, [hl]
	ld l, a
	jp hl