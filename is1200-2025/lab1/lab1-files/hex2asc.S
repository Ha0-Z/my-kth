  # hexmain.S
  # Written 2015-09-04 by F Lundevall
  # Copyright abandonded - this file is in the public domain.

	.text
	.globl hex2asc

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

	
