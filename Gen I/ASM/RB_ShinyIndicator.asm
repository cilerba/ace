/* 
	[ RB Shiny Indicator 1.0 ]

	To be executed via OAM DMA Hijack.
	Runs every frame and places an indicator on screen if the loaded Pokémon is shiny.
*/

SECTION "ShinyIndicator", ROM0

DEF BackupMSP		EQU $D431
DEF MSPRedirect  	EQU $DCF0

DEF SHINY_ATK_MASK EQU %0010
DEF SHINY_DEF_DV EQU 10
DEF SHINY_SPD_DV EQU 10
DEF SHINY_SPC_DV EQU 10

start:
	ld hl, $D36F 		; wCurMapScriptPtr
	ld de, BackupMSP	; wDestinationWarpID+1
	
	ld a, [hl]
    and $D0
    cp $D0
	jr z, .installed

	; Back up the map script pointer at $D440
	; This is jumped to in HijackInstallerMSP
.backup
	ld a, [hl-]
	ld [de], a
	dec de
	ld a, [hl]
	ld [de], a

	; 
.hijack
    ld de, MSPRedirect
    ld a, e
    ld [hli], a
    ld [hl], d
    
    ; Fallthrough

.installed
	ld a, [$D057]		; wIsInBattle
	and a
	jr z, .statusCheck	; Skip to status screen check if battle check fails

	; Battle has been confirmed
	; Check wTilemap tile for opponent HUD ('HP' tile)
	ld hl, $C3CA 
	ld a, [hl]
	cp $71				; 'HP'
	ret nz 				; Return if HUD isn't present

	; Check if '!' already exists
	ld hl, $C3B4
	ld a, [hl]
	cp $E7 				; '!'
	ret z 				; Return if true

	ld hl, $CFF1 		; wEnemyMonDVs
	ld bc, $C3B4 		; Store position for '!'
	jr .shinyCheck 		; Skip status screen check, battle is confirmed active
	
.statusCheck
	; Perform two checks to confirm status screen is visible
	; First check for 'ID' then check for 'No.' to the right
	ld hl, $C4AE 		; VRAM Tile for ID
	ld a, [hli]
	cp $73 				; 'ID'
	ret nz 
	ld a, [hl]
	cp $74 				; 'No.'
	ret nz 				; Return if both checks fail, not in the status screen
	
	; Check wTilemap for '!'
	ld hl, $C3E5
	ld a, [hl]
	cp $E7 				; '!'
	ret z 				; Return if '!' already exists

	ld hl, $CFB3 		; wLoadedMonDVs
	ld bc, $C3E5 		; Store position for '!'

.shinyCheck ; Ported from GSC
	; Attack
	ld a, [hl]
	and SHINY_ATK_MASK << 4
	ret z               ; Not shiny

	; Defense
	ld a, [hli]
	and %1111
	cp SHINY_DEF_DV
	ret nz              ; Not shiny

	; Speed
	ld a, [hl]
	and %1111 << 4
	cp SHINY_SPD_DV << 4
	ret nz              ; Not shiny

	; Special
	ld a, [hl]
	and %1111
	cp SHINY_SPC_DV
	ret nz              ; Not shiny

	; Shiny (!)
	ld l, c
	ld h, b
	ld [hl], $E7 ; !
	ret