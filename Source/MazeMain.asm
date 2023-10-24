; Tile types
kTl_Plr EQU '@'
kTl_Ext EQU 'X'
kTl_Wal EQU 219
kTl_Flr EQU ' '

; Actor types
kAc_Non EQU 0
kAc_Plr EQU 1
kAc_Ext EQU 2

; Config
kPlayer_MaxHealth EQU 4

; Inputs
kInput_Quit EQU 27
kInput_Up	EQU 'w'
kInput_Down EQU 's'
kInput_Left	EQU 'a'
kInput_Rght EQU 'd'

.data
LevelItem struct
	itemType	DWORD	kAc_Non	; 4
	xPos		DWORD	0			; 4
	yPos		DWORD	0			; 4
LevelItem ends
SizeOf_LevelItem EQU 12

PlayerActor struct
	levelItemIndex	DWORD -1
	health			DWORD kPlayer_MaxHealth
PlayerActor ends

player PlayerActor {}

levelData		QWORD 0 ; Pointer to the level data (tiles)
levelDataWidth	DWORD 0	; Level width
levelDataHeight DWORD 0 ; Level height
levelDataSize	DWORD 0 ; Total size of the level data array

levelItems		LevelItem 20 dup(<>) ; We can have up to 20 level items
levelItemCount	DWORD 0	; How many elements of the array are valid
actorIcons		BYTE 4 dup( 32, '@', 88, 153 ) ; Array of chars to use for actor icons

.code
GetTileIndexFromActor MACRO actorPtr
	mov eax, [actorPtr].LevelItem.yPos
	mul [levelDataWidth]
	add eax, [actorPtr].LevelItem.xPos
ENDM

ConvertLevelData proc ; void ConvertLevelData(char* dataBuffer [rcx], int32_t width [rdx], int32_t height [r8])
	push rbp

	mov [levelData],rcx ; Store the level data for later
	mov [levelDataWidth],edx
	mov [levelDataHeight],r8d

	mov r9, rcx	; Use r9 as the loop counter, initialise to the base pointer (rcx)
	mov r10, r9	; Use r10 as the upper bound. Initialise to the base.
	mov r11d, 0	; r11 is actor count

	mov eax, edx	; Move width into eax
	mul r8d			; Multiply by height
	
	mov [levelDataSize],eax ; Store the data size in our variable
	
	add r10, rax	; Add the dimensions to the upper bound pointer

	; Initial loop check
	cmp r9, r10
	jge BufferLoopEnd

	lea r12, levelItems	; Store a pointer to the level items

	jmp BufferLoopStart ; Jump to the loop start

UpdateActorCount:
	mov [r12].LevelItem.itemType, r8d ; Write the actor type ID into the actor array
	
	; Calculate the x and y values from the index
	mov rax, r9
	sub rax, rcx
	xor edx,edx ; Need to clear edx for the div
	div [levelDataWidth]

	mov [r12].LevelItem.xPos, edx
	mov [r12].LevelItem.yPos, eax
	
	mov byte ptr [r9], kTl_Flr	; Write the updated tile value back to the array
	inc r11d					; Increment the actor count
	add r12, SizeOf_LevelItem	; Move the pointer to the next level item
	jmp BufferLoopInc

	; Iterate through screen buffer
BufferLoopStart:
	TestForActor macro TileType, ActorType
		mov r8w, ActorType
		cmp byte ptr [r9], TileType
		je UpdateActorCount
	endm

	; Special Player processing
	mov r8w, kAc_Plr
	cmp byte ptr [r9], kTl_Plr
	jne BufferLoop_NonPlayerActors

	mov player.levelItemIndex, r11d
	jmp UpdateActorCount
	
BufferLoop_NonPlayerActors:
	; Continue processing the remaining level actors
	TestForActor kTl_Ext, kAc_Ext

BufferLoopInc:
	inc r9 ; Increment pointer
	cmp r9, r10 ; Check upper bounds
	jl BufferLoopStart ; Loop if less

BufferLoopEnd:
	mov [levelItemCount], r11d ; Store the actor count

	pop rbp
	ret
ConvertLevelData endp

Update proc ; int Update(int32_t lastInput)
	LOCAL oldPlayerX:DWORD, oldPlayerY:DWORD

	push rbx

	;;;;;;;;;;;;;;;;;
	; Process input ;
	;;;;;;;;;;;;;;;;;
	
	; Store values needed for conditional moves into registers
	mov r9d, -1 
	mov r10d, 1
	
	; Load the address of the player actor
	lea r11, levelItems	
	mov eax, SizeOf_LevelItem
	mul player.levelItemIndex
	add r11, rax

	; Store the original x and y values
	mov eax, [r11].LevelItem.xPos
	mov oldPlayerX, eax

	mov eax, [r11].LevelItem.yPos
	mov oldPlayerY, eax

	; Check for quit
	cmp rcx, kInput_Quit
	mov r8, 1
	cmove rax, r8 ; Set the return value to 1
	je EndUpdate

	; Up
	mov r8d, 0
	cmp rcx, kInput_Up
	cmove r8d, r9d
	add [r11].LevelItem.yPos, r8d

	; Down
	mov r8d, 0
	cmp rcx, kInput_Down
	cmove r8d, r10d
	add [r11].LevelItem.yPos, r8d

	; Left
	mov r8d, 0
	cmp rcx, kInput_Left
	cmove r8d, r9d
	add [r11].LevelItem.xPos, r8d

	; Right
	mov r8d, 0
	cmp rcx, kInput_Rght
	cmove r8d, r10d
	add [r11].LevelItem.xPos, r8d

	GetTileIndexFromActor r11	; Stores index in eax

	; Fetch the tile type from the index
	mov rcx, [levelData]
	add rcx, rax
	mov al, byte ptr [rcx]

	cmp eax, kTl_Flr
	je CheckPositionForActors

	mov eax, oldPlayerX
	mov [r11].LevelItem.xPos, eax

	mov eax, oldPlayerY
	mov [r11].LevelItem.yPos, eax

CheckPositionForActors:
	; Use r9 as the loop counter
	lea r9, levelItems
	
	; Store the upper bound in r10
	mov r10, r9
	mov rax, SizeOf_LevelItem
	mul [levelItemCount]
	add r10, rax

	; Store the actor tile index into r12d (r11 still contains a pointer to the player)
	GetTileIndexFromActor r11
	mov r12d, eax

CheckPositionForActors_LoopStart:
	GetTileIndexFromActor r9
	cmp eax, r12d
	jne CheckPositionForActors_Inc

	cmp [r9].LevelItem.itemType, kAc_Ext
	mov ecx, 2
	cmove eax, ecx
	je EndUpdate
		
CheckPositionForActors_Inc:
	add r9, SizeOf_LevelItem
	cmp r9, r10
	jl CheckPositionForActors_LoopStart

	; Clear the return value if we have not jumped to the end
	xor eax, eax

EndUpdate:
	pop rbx
	ret
Update endp

Draw proc ; void Draw(char* screenBuffer [RCX], int width [RDX], int height [R8])
	push rbx
	
	mov r9, rcx	; Use r9 as the loop counter, initialise to the base pointer (rcx)
	mov r10, r9	; Use r10 as the upper bound. Initialise to the base.
	mov r11, [levelData]

	mov eax, edx	; Move width into eax
	mul r8d			; Multiply by height
	add r10, rax	; Add the dimensions to the upper bound pointer

	; Initial loop check
	cmp r9, r10
	jge ScreenLoopEnd

	; Iterate through screen buffer
ScreenLoopStart:
	mov al, byte ptr [r11]
	mov byte ptr [r9], al
	inc r11
	inc r9 ; Increment pointer
	cmp r9, r10 ; Check upper bounds
	jl ScreenLoopStart ; Loop if less

ScreenLoopEnd:	
	; If there are no actors then jump straight to the end
	cmp [levelItemCount], 0
	je ActorLoopEnd

	; Process the level actors
	lea r9, levelItems
	mov r10, r9
	mov eax, SizeOf_LevelItem
	mul [levelItemCount]
	add r10, rax ; Store the upper bound

ActorLoopStart:
	; Fetch the item icon from the array
	lea r12, actorIcons
	mov r8d, [r9].LevelItem.itemType ; Load the type into a register so that we can make the sizes match for the pointer addition
	add r12, r8
	mov r12b, byte ptr[r12]

	; Store the item icon into the screen buffer array
	GetTileIndexFromActor r9 ; Stores index into rax
	mov byte ptr [rcx + rax], r12b
	
ActorLoopIncrement:
	add r9, SizeOf_LevelItem
	cmp r9, r10
	jl ActorLoopStart

ActorLoopEnd:
	xor eax,eax
	pop rbx
	ret

Draw endp

end