# timetemplate.S
# Written 2015 by F Lundevall
# Ported 2024/06 by W Szczerek (from MIPS to RISC-V)
# Copyright abandonded - this file is in the public domain.

#############################################################
# Choose the macro syntax for RARS or DTEK-V board.         #
# The syntax for RARS is probably due to its MIPS heritage. #
#############################################################
###################
# Macros for RARS #
###################
.macro	PUSH (%reg)
	addi	sp,sp,-4
	sw	%reg,0(sp) 
.end_macro

.macro	POP (%reg)
	lw	%reg,0(sp)
	addi	sp,sp,4
.end_macro
###################
# Macros for DTEK #
###################
#.macro	PUSH reg
#	addi sp,sp,-4
#	sw \reg,0(sp) 
#.endm

#.macro	POP reg
#	lw	\reg,0(sp)
#	addi	sp,sp,4
#.endm
#############################################################

	.data
	.align 2
mytime:	.word 	0x5957
timstr:	.asciz 	"text more text lots of text\0"
	.text
	.globl timetemplate, tick, time2string

# Function for displaying a string with a newline at the end	
display_string:	
	li a7, 4
	ecall
	li a0, 10
	li a7, 11
	ecall
	jr ra
	
timetemplate:
	la	a0, timstr
	jal     display_string
	
	# wait a little
	li	a0, 2		# ms
	jal	delay
	
	# call tick
	la 	a0, mytime
	jal	tick
	
	# call your function time2string
	la	a0, timstr
	la	t0, mytime
	lw	a1, 0(t0)
	jal	time2string
	
	# go back and do it all again
	j	timetemplate

	
# tick: update time pointed to by $a0
tick:	lw	t0, 0(a0)	# get time
	addi	t0, t0, 1	# increase
	andi	t1, t0, 0xf	# check lowest digit
	sltiu	t2, t1, 0xa	# if digit < a, okay
	bnez	t2, tiend
	addi	t0, t0, 0x6	# adjust lowest digit
	
	andi	t1, t0, 0xf0	# check next digit
	sltiu	t2, t1, 0x60	# if digit < 6, okay
	bnez	t2, tiend
	addi	t0, t0, 0xa0	# adjust digit
	
	li	t3, 0xF
	slli	t3, t3, 0x8
	and	t1, t0, t3	# check minute digit
	addi	t3, x0, 0xA
	slli	t3, t3, 0x8
	slt	t2, t1, t3	# if digit < a, okay
	bnez	t2, tiend
	addi	t0, t0, 0x600	# adjust digit - this one's okay, it's lower than 0x7FF 
	
	li	t3, 0xF
	slli	t3, t3, 0xC
	and	t1, t0, t3	# check last digit
	addi	t3, x0, 0x6
	slli	t3, t3, 0xC
	slt	t2, t1, t3	# if digit < 6, okay
	bnez	t2, tiend
	
	li	t3, 0xA
	slli	t3, t3, 0xC
	add	t0, t0, t3	# adjust last digit
tiend:	sw	t0,0(a0)	# save updated result
	jr	ra		# return

#########################################################
# Place for your functions: time2string, hex2asc, delay.#
#########################################################

hex2asc:
	li	a0, 17		# test number (from 0 to 15)
	
	addi    sp,sp,-4
	sw      ra,0(sp)
	
	jal	hexasc		# call hexasc
	
	li	a7, 11	# write a0 to stdout
	ecall

	lw      ra,0(sp)
	addi    sp,sp,4
	jr      ra	

  # You can write your own code for hexasc here
  #

hexasc:
    # Ignore all bits except the last 4 bits (F = 1111)
    andi a0, a0, 0xF

    # Check if a0 <= 9 (decimal)
    li   t0, 9
    ble  a0, t0, digit_case

    # If > 9, convert to 'A'..'F'
    # a0 = a0 - 10 + 'A' (65)
    li   t1, 10
    sub  a0, a0, t1      # a0 = a0 - 10
    li   t2, 'A'
    add  a0, a0, t2      # a0 = a0 + 'A'
    j    finish

digit_case:
    # Convert 0..9 to '0'..'9'
    li   t2, '0'
    add  a0, a0, t2

finish:
    # Clear all bits except the lowest 7 bits (ASCII code in 7 bits)
    andi a0, a0, 0x7F

    ret
    
    

time2string:
    # Save registers that need to be preserved
    PUSH(ra)
    PUSH(s0)
    PUSH(s1)
    
    mv s0, a0            # s0 = buffer pointer
    mv s1, a1            # s1 = time value

    # Extract and convert minutes tens digit
    srli a0, s1, 12      # shift right 12 bits to get min tens
    andi a0, a0, 0xF     # mask to get only 4 bits
    jal hexasc           # convert to ASCII
    sb a0, 0(s0)         # store at buffer
    addi s0, s0, 1       # increment buffer pointer

    # Extract and convert minutes ones digit
    srli a0, s1, 8       # shift right 8 bits to get min ones
    andi a0, a0, 0xF     # mask to get only 4 bits
    jal hexasc           # convert to ASCII
    sb a0, 0(s0)         # store at buffer
    addi s0, s0, 1       # increment buffer pointer

    # Store colon
    li a0, ':'           # colon character
    sb a0, 0(s0)         # store at buffer
    addi s0, s0, 1       # increment buffer pointer

    # Extract and convert seconds tens digit
    srli a0, s1, 4       # shift right 4 bits to get sec tens
    andi a0, a0, 0xF     # mask to get only 4 bits
    jal hexasc           # convert to ASCII
    sb a0, 0(s0)         # store at buffer
    addi s0, s0, 1       # increment buffer pointer

    # Extract and convert seconds ones digit
    andi a0, s1, 0xF     # mask to get sec ones (lowest 4 bits)
    jal hexasc           # convert to ASCII
    sb a0, 0(s0)         # store at buffer
    addi s0, s0, 1       # increment buffer pointer

    # Store null terminator
    li a0, 0             # null byte
    sb a0, 0(s0)         # store at buffer

    # Restore registers
    POP(s1)
    POP(s0) 
    POP(ra)
    jr ra


delay:
    # Save registers we will use
    PUSH a0           # Save the ms parameter (input)
    PUSH ra           # Save return address
    PUSH t0           # Save t0 (iterator for inner loop)
    PUSH t1           # Save t1 (counter for outer loop)

    # Initialize the times register to 0
    li t1, 0          # t1 = 0 (this will be our 'times' register)

loop_outer:
    # Loop 4711 times (inner loop)
    li t0, 4711       # t0 = 4711 (number of iterations for inner loop)

loop_inner:
    addi t0, t0, -1   # t0 = t0 - 1
    bnez t0, loop_inner # continue inner loop if t0 != 0

    # Increment the times register (t1)
    addi t1, t1, 1     # t1 = t1 + 1

    # Check if times (t1) equals ms (a0), if yes, exit loop
    beq t1, a0, done   # if t1 == ms, exit

    # Otherwise, repeat the outer loop (loop 4711 more times)
    j loop_outer

done:
    # Restore registers before returning
    POP t1            # Restore t1 (times register)
    POP t0            # Restore t0 (iterator for inner loop)
    POP ra            # Restore return address
    POP a0            # Restore the ms parameter

    jr ra             # Return from function
