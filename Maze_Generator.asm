.data
screen: .word 0x10040000
wall:	.word 0x00000000
path:	.word 0xFFFFFFFF
view:	.word 0xFFFF0000
width:	.word 64
edge:	.word 41
height:	.word 63
max:	.word -1
start:	.word -1
finish:	.word -1

	.text
init:
	# calculate max bitmap address
	lw $s0, width
	lw $s1, height
	lw $s2, edge
	lw $s6, screen
	addi $s1, $s1, -1
	mul $s0, $s0, $s1
	add $s0, $s0, $s2
	sll $s0, $s0, 2
	addi $s0, $s0, -4
	add $s0, $s0, $s6
	sw $s0, max
	
	# clear the screen
	addi $t1, $0, 4
	lw $t9, wall
	move $t8, $s6
	clearloop:
		sw $t9, ($t8)
		add $t8, $t8, $t1
		ble $t8, $s0, clearloop
	
	#Generate Random Number
	li $v0, 42
	xor $a0, $a0, $a0
	lw $a1, edge
	srl $a1, $a1, 1
	syscall			# Random number 0 - (width-1)
	sll $s0, $a0, 1
	syscall			# Second random number
	sll $s1, $a0, 1
	
	#format the numbers and word allign them
	addi $s0, $s0, 1
	sll $s0, $s0, 2
	addi $s1, $s1, 1
	sll $s1, $s1, 2

	# set start
	lw $s7, path
	add $t0, $s0, $s6
	sw $s7, ($t0)
	sw $t0, start

	# set finish
	lw $s5, max
	sub $t1, $s5, $s1
	sw $s7, ($t1)
	sw $t1, finish

#init generation
gen_init:
	lw $s0, screen		# min value
	lw $s7, max		# max value
	move $s6, $sp		# stack address
	lw $s5, width
	sll $s5, $s5, 2
	lw $s1, path
	lw $s3, start
	add $s3, $s3, $s5
	addi $sp, $sp, -4
	sw $s3, ($sp)
	lw $s4, view


# generation loop
# $s3 = current cell
# $s1 = color
# $s6 = starting stack value
generate:
	#COMMENT THESE 2 LINES OUT TO REMOVE RANDOM COLORS
	#jal random_color
	#move $s1, $a0
	sw $s1, ($s3)		  # color the current cell
	beq $sp, $s6, exit 	  # stack == empty, exit
	lw $s3, ($sp)		  # peek from the stack
	sw $s4, ($s3)		  # turn the current cell red (ONLY FOR DEMO)
	move $a0, $s3		  # current cell == param1
	jal get_move		  # find valid moves
	bne $v0, $0, found_move	  # if move found, jump
		addi $sp, $sp, 4  # else, pop stack
		j generate	  # recurse
	found_move:
		move $t3, $v0	  # $t3 = found move
		sw $s1, ($v1)	  # color the intermediate cell
		addi $sp, $sp, -4 # prep stack for push
		sw $t3, ($sp)	  # push new cell to stack
		j generate	  # recurse

#exit
exit:
	li $v0, 10
	syscall

# $a0 = current position
# $v0 => new position
# $v1 => intermediate position
# if no path is found, $v0 = 0
get_move:
	addi $sp, $sp, -32
	add $t0, $0, $0
	sub $t4, $a0, $s0
	div $t4, $s5
	mfhi $t3
	lw $t9, edge
	sll $t9, $t9, 2
	#find valid moves		
		addi $t6, $t3, 8
		bge $t6, $t9, skip1
		addi $t7, $a0, 8 # right
		lw $t5, ($t7)
		bne $t5, $0, skip1 # Visited
		addi $t0, $0, 1
		sw $t7, 4($sp)
		addi $t7, $t7, -4
		sw $t7, ($sp)
	skip1:
		addi $t6, $t3, -8
		ble $t6, $0, skip2
		addi $t7, $a0, -8 # left
		lw $t5, ($t7)
		bne $t5, $0, skip2 # Visited
		sll $t1, $t0, 3 # mul by 8
		add $t1, $t1, $sp
		sw $t7, 4($t1)
		addi $t7, $t7, 4
		sw $t7, ($t1)
		addi $t0, $t0, 1
	skip2:
		add $t7, $a0, $s5 # down
		add $t7, $t7, $s5 # down
		bgt $t7, $s7, skip3 # OB
		lw $t5, ($t7)
		bne $t5, $0, skip3 # Visited
		sll $t1, $t0, 3 # mul by 8
		add $t1, $t1, $sp
		sw $t7, 4($t1)
		sub $t7, $t7, $s5
		sw $t7, ($t1)
		addi $t0, $t0, 1
	skip3:
		sub $t7, $a0, $s5 # up
		sub $t7, $t7, $s5 # up
		blt $t7, $s0, skip4 # OB
		lw $t5, ($t7)
		bne $t5, $0, skip4 # Visited
		sll $t1, $t0, 3 # mul by 8
		add $t1, $t1, $sp
		sw $t7, 4($t1)
		add $t7, $t7, $s5
		sw $t7, ($t1)
		addi $t0, $t0, 1
	skip4:
	bne $t0, $0, found
	# return 0
	move $v0, $0
	addi $sp, $sp, 32
	jr $ra
	found:
	# pick a random move
	li $v0, 42
	move $a0, $0
	move $a1, $t0
	syscall
	sll $a0, $a0, 3
	add $t1, $a0, $sp
	lw $v1, ($t1)
	lw $v0, 4($t1)
	addi $sp, $sp, 32
	jr $ra
	
	# $a0 => random color
random_color:
	li $v0, 41         
	xor $a0, $a0, $a0  
	syscall            
	jr $ra
