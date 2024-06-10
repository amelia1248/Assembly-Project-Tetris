################ CSC258H1F Winter 2024 Assembly Final Project ##################
# This file contains our implementation of Tetris.
#
# Student 1: Amelia Wu, 1009613599
# Student 2: Jodhvir Bassi, 1009279451
######################## Bitmap Display Configuration ########################
# - Unit width in pixels:       8
# - Unit height in pixels:      8
# - Display width in pixels:    256
# - Display height in pixels:   256
# - Base Address for Display:   0x10008000 ($gp)
##############################################################################

    .data
##############################################################################
# Immutable Data
##############################################################################
# The address of the bitmap display. Don't forget to connect it!
ADDR_DSPL:
    .word 0x10008000
# The address of the keyboard. Don't forget to connect it!
ADDR_KBRD:
    .word 0xffff0000

PAUSE_DSPL:
    .word 0x10008050
##############################################################################
# Mutable Data
##############################################################################
black:   .word   0x1b1b1b
grey:   .word   0x454545
green:  .word   0x9ACD32
white:  .word   0xFFFFFF
red:  .word   0xFF0000
back_address:   .word   0x10008F88
second_last_row:    .word   0x10008F00      # storing the address of the 2nd last row
last_bitmap_pixel:      .word   0x10008FC8          # storing the last pixel of the bitmap
##############################################################################
# Code
##############################################################################
	.text
	.globl main

	# Run the Tetris game.
main:
    # Initialize the game
    
    # li $t1, 0x1b1b1b        # grid colour 1: dark grey
    # li $t2, 0x454545        # grid colour 2: light grey
    # li $t3, 0x9ACD32        # wall colour: green

    li $s0, 0       # setting game loop # boolean
    lw $t4, ADDR_DSPL        # setting $t4 to the base address
    # li $s1, 0x10008F00          # storing the 2nd last row address
    # li $s2, 0x10008FC8          # storing the last pixel of the bitmap
    li $s3, 0x10008F08          # storing last pixel of grid
    li $k0, 0                   # Stores level number
    
    # sw $t2, 0($s4)            # for testing pixel placement
    
    # DRAWING THE GRID #######################################################
draw_all:
    li $t4, 0x10008000          # loading $t4 loop variable as display start
    li $t5, 0x10008080          # loading $t5 loop variable as end of row
    li $t6, 0x10008100
    
    
    final_grid_top:
        jal grid_black_top
        addiu $t5, $t5, 256
        jal grid_grey_top
        addiu $t6, $t6, 256
        
        
        beq $t4, 0x10009000, final_grid_end
        j final_grid_top
    final_grid_end:
    j ult_wall_top
    
    grid_black_top:
        lw $t1, black
        sw $t1, 0($t4)          # paint current pixel black
        lw $t2, grey
        sw $t2, 4($t4)          # paint next pixel grey
        addiu $t4, $t4, 8           # increment $t4 by 8(2 pixels)
        beq $t4, $t5, grid_black_end
        j grid_black_top
    grid_black_end:
    jr $ra          # jump back to code
    
    grid_grey_top:
        lw $t2, grey
        sw $t2, 0($t4)          # paint current pixel grey
        lw $t1, black
        sw $t1, 4($t4)          # paint next pixel black
        addiu $t4, $t4, 8           # increment $t4 by 8(2 pixels)
        beq $t4, $t6, grid_grey_end
        j grid_grey_top
    grid_grey_end:
    jr $ra          # jump back to code
    
    
    
   # DRAWING THE WALLS #######################################################
   ult_wall_top:
   li $t4, 0x10008000        # setting $t4 to the base address
   wall_top:
        
        lw $t3, green
        sw $t3, 0($t4)          # paint the first two pixels on row green
        sw $t3, 4($t4)
        sw $t3, 64($t4)        # paint the last two pixels on row green
        sw $t3, 68($t4)
        addiu $t4, $t4, 128        # increment $t4 by 128
        # CHANGED HERE... s1 to t3
        lw $t1, second_last_row
        beq $t4, $t1, wall_end
        # CHANGE END
        j wall_top        # jump to top of outer loop
    wall_end:
    floor_top:
        floor_row_1:
            sw $t3, ($t4)          # paint current pixel green
            addiu $t4, $t4, 4           # increment $t4 by 4(1 pixel)
            beq $t4, 0x10008F48, floor_row_1_end
            j floor_row_1
        floor_row_1_end:
        
            addiu $t4, $t4, 56
        
        floor_row_2:
            sw $t3, ($t4)          # paint current pixel green
            addiu $t4, $t4, 4           # increment $t4 by 4(1 pixel)
            beq $t4, 0x10008FC8, floor_end
            j floor_row_2
        floor_row_2_end:
    floor_end:
    ult_wall_end:
    
    
draw_all_end:


        # COPYING background from memory
    copy_background_top:
        li $s3, 0           # keeps track of when the pixels accross the background end
        li $t3, 0x10008008
        li $t2, 0x10009000      # setting $t2 to a memory address past the grid
        
        
            copy_background_row:
                lw $t1, 0($t3)      # setting $t1 to first pixel in grid
                sw $t1, 0($t2)      # placing value of pixel at $t1 into $t2 memory spot
                addi $t3, $t3, 4
                addiu $t2, $t2, 4
                addiu $s3, $s3, 4
                beq $s3, 56, copy_background_row_end        # ends at right side 
                j copy_background_row
            copy_background_row_end:
            addi $t3, $t3, 72       # add to $t3 so it starts at next row of background
            li $s3, 0
            beq $t3, 0x10008F08, copy_background_end
            j copy_background_row
            
    copy_background_end:       # now entire background is stored in memory
        
        # DRAWING background from memory
        
        li $s3, 0           # keeps track of when the pixels accross the background end
        li $t3, 0x10008008      # setting $t3 to the first pixel in background, $t3 stores current bitmap pixel
        li $t2, 0x10009000      # setting $t2 to the address of the first pixel in memory
        # $t3 stores the current bitmap pixel

        draw_background_row_top:
        
        lw $t1, 0($t2)      # $t1 now stores VALUE at $t2 memory address
        lw $s7, black       # store BLACK in $s7
        
        
        # If $t1(VALUE) at memory address is black or grey, do NOT draw and move to next pixel
        beq $t1, $s7, increment_no_draw_1
        lw $s7, grey        # store GREY in $s7
        
        beq $t1, $s7, increment_no_draw_1
        
        sw $t1, 0($t3)      # sw VALUE, memory location/address, this is where we actually DRAW
        
        increment_no_draw_1:
        
        
        addi $t3, $t3, 4
        addi $t2, $t2, 4
        addi $s3, $s3, 4
        beq $s3, 56, draw_background_row_end
        j draw_background_row_top
        draw_background_row_end:
        addi $t3, $t3, 72       # add to $t3 so it starts at next row of background
        li $s3, 0
        beq $t3, 0x10008F08, end_draw_background
        j draw_background_row_top
            
        end_draw_background:       # now entire background is DONE being drawn

beq $a0, 750, continue_s
beq $a0, 500, continue_s
beq $a0, 0x64, continue_d
beq $a0, 0x61, continue_a
beq $a0, 0x73, continue_s
beq $a0, 0x77, continue_w
    
    
    # DRAWING THE I-TETROMINOE ####################################################
    
    
    draw_i_tetrominoe_top:
        li $t7, 0x10008024        # store x&y coordinate of middle of first row
        li $s4, 0x100080A4         # store second pixel address
        li $s5, 0x10008124          # store third pixel address
        li $s6, 0x100081A4          # store fourth pixel address
        
        li $t3, 0xebeb49
        li $s1, 0xebeb49            # LOADING COLOUR: YELLOW
        sw $t3, 0($t7)              # draw first pixel
        sw $t3, 128($t7)            # draw second pixel
        sw $t3, 256($t7)            # draw third pixel
        sw $t3, 384($t7)            # draw fourth pixel
        li, $t9, 0                  # t9 keeps track of the orientation
        # LOAD TYPE OF TETROMINOE HERE!!!!!
        li $s2, 1           # Indicating this tetrominoe is type 1 = i
    draw_i_tetrominoe_end:
    
    # KEYBOARD INPUT FOR MILESTONE 2 ####################################################
       .data
ADDR_KBRD:
    .word 0xffff0000

    .text
	.globl main1
	

main1:

	li 		$v0, 32
	li 		$a0, 1
	syscall
                                    
    lw $t0, ADDR_KBRD               # $t0 = base address for keyboard
    lw $t8, 0($t0)                  # Load first word from keyboard
    beq $t8, 1, keyboard_input      # If first word 1, key is pressed
    
bge $k0, 3, increase_speed
         
    li 		$v0, 32
	li 		$a0, 750
	syscall
    j respond_to_S
    
    j main1_end

increase_speed:
li  $v0, 32
li	 $a0, 500
syscall
j respond_to_S
j main1_end
    
    bottom_reached:                 # The current tetrominoe has reached the bottom
            # Copy + draw current background
            j copy_background_top_2
        bottom_continued:
                li $s0, 1       # set boolean value to 1. Now when we draw_all, we will NOT copy background until we get to the next bottom collision.
        
                
        
                # CHECKING FOR FULL ROWS LOOP HERE!!!!!
                ##########################################################################################################################################################################
                        check_full_background:
                            li $t3, 0x10008008      # first pixel in first row of background... CORRECT NUMBER!
                            lw $t1, black
                            li $t2, 0           # tracks when to STOP going through a ROW
                            lw $s3, 0($t3)      # storing current pixel's COLOUR at s3
                            li $s4, 0           # tracks row #/WHICH ROW is full
                            li $s5, 0           # is boolean value for if a row is full
                            
                            check_bottom_outer_loop:
                                check_full_row_loop:
                                    # Early return... if any block is equal to gray or black, SKIP over the shift function
                                    lw $s3, 0($t3)      # storing COLOUR at 3
                                    lw $t1, black
                                    beq $s3, $t1, load_row_bool     # If current pixel is equal to BLACK... load bool = 1
                                    lw $t1, grey
                                    beq $s3, $t1, load_row_bool      # If current pixel is equal to GREY... load bool = 1
                                    
                                    # SO FAR PIXELS ARE ALL FULL IN ROW...
                                    beq $t2, 56, check_full_row_loop_end      # hex value is the LAST PIXEL of the bottom row of background... CORRECT NUMBER!
                                    addi $t3, $t3, 4
                                    addi $t2, $t2, 4
                                    j check_full_row_loop
                                    
                                    # THERE IS A BLACK/GREY PIXEL IN ROW, ROW IS NOT FULL.
                                    load_row_bool:
                                        li $s5, 1
                                    beq $t2, 56, check_full_row_loop_end      # hex value is the LAST PIXEL of the bottom row of background... CORRECT NUMBER!
                                    addi $t3, $t3, 4
                                    addi $t2, $t2, 4
                                    j check_full_row_loop
                                check_full_row_loop_end:
                                addi $s4, $s4, 1        # row number has GONE UP BY 1
                                beq $s5, 0, go_to_shift_function        # if row is FULL... IMMEDIATELY go to shift function
                                # otherwise continue onto next row...
                                li $s5, 0           # CURCIAL: RESET $s5 boolean!!!
                                addi $t3, $t3, 72
                                li $t2, 0
                                beq $t3, 0x10008F08, check_bottom_outer_loop_end
                                j check_full_row_loop
                            check_bottom_outer_loop_end:
                            
                            # None of the rows in background are full... KEEP PLAYING/generate next tetrominoe.
                            continue_to_play:
                            j next_tetrominoe
                            
                            
                                go_to_shift_function:
                                
                                addi $k0, $k0, 1   #increase speed of gracity after 3 rows complete
                                
                                j shifted_draw
                                
                    
                            
                            ###################################################################
                            shifted_draw:
                            # REDRAW GRID HERE!!!!
                                shift_new_draw_all:
                                        shift_ndraw_all:
                                            li $t4, 0x10008000          # loading $t4 loop variable as display start
                                            li $t5, 0x10008080          # loading $t5 loop variable as end of row
                                            li $t6, 0x10008100
                                            
                                            
                                            shift_nfinal_grid_top:
                                                jal shift_ngrid_black_top
                                                addiu $t5, $t5, 256
                                                jal shift_ngrid_grey_top
                                                addiu $t6, $t6, 256
                                                
                                                
                                                beq $t4, 0x10009000, shift_nfinal_grid_end
                                                j shift_nfinal_grid_top
                                            shift_nfinal_grid_end:
                                            j shift_nult_wall_top
                                            
                                            shift_ngrid_black_top:
                                                lw $t1, black
                                                sw $t1, 0($t4)          # paint current pixel black
                                                lw $t2, grey
                                                sw $t2, 4($t4)          # paint next pixel grey
                                                addiu $t4, $t4, 8           # increment $t4 by 8(2 pixels)
                                                beq $t4, $t5, shift_ngrid_black_end
                                                j shift_ngrid_black_top
                                            shift_ngrid_black_end:
                                            jr $ra          # jump back to code
                                            
                                            shift_ngrid_grey_top:
                                                lw $t2, grey
                                                sw $t2, 0($t4)          # paint current pixel grey
                                                lw $t1, black
                                                sw $t1, 4($t4)          # paint next pixel black
                                                addiu $t4, $t4, 8           # increment $t4 by 8(2 pixels)
                                                beq $t4, $t6, shift_ngrid_grey_end
                                                j shift_ngrid_grey_top
                                            shift_ngrid_grey_end:
                                            
                                            li $v0, 31 
                                            la $a0, 70 
                                            la $a1, 500
                                            la $a2, 82
                                            la $a3, 50
                                            syscall
                                            
                                            jr $ra          # jump back to code
                                            
                                            
                                            
                                           # DRAWING THE WALLS #######################################################
                                           shift_nult_wall_top:
                                           li $t4, 0x10008000        # setting $t4 to the base address
                                           shift_nwall_top:
                                                
                                                lw $t3, green
                                                sw $t3, 0($t4)          # paint the first two pixels on row green
                                                sw $t3, 4($t4)
                                                sw $t3, 64($t4)        # paint the last two pixels on row green
                                                sw $t3, 68($t4)
                                                addiu $t4, $t4, 128        # increment $t4 by 128
                                                # CHANGE HERE... s1 to t1
                                                lw $t1, second_last_row
                                                beq $t4, $t1, shift_nwall_end
                                                # CHANGE END
                                                j shift_nwall_top        # jump to top of outer loop
                                            shift_nwall_end:
                                            shift_nfloor_top:
                                                shift_nfloor_row_1:
                                                    sw $t3, ($t4)          # paint current pixel green
                                                    addiu $t4, $t4, 4           # increment $t4 by 4(1 pixel)
                                                    beq $t4, 0x10008F48, shift_nfloor_row_1_end
                                                    j shift_nfloor_row_1
                                                shift_nfloor_row_1_end:
                                                
                                                    addiu $t4, $t4, 56
                                                
                                                shift_nfloor_row_2:
                                                    sw $t3, ($t4)          # paint current pixel green
                                                    addiu $t4, $t4, 4           # increment $t4 by 4(1 pixel)
                                                    beq $t4, 0x10008FC8, shift_nfloor_end
                                                    j shift_nfloor_row_2
                                                shift_nfloor_row_2_end:
                                            shift_nfloor_end:
                                            shift_nult_wall_end:
                                            
                                            
                                        shift_new_draw_all_end:
                            
                            
                            
                            
                            
                            
                            
                            
                            
                            
                                # Drawing background shifted DOWN by 1 row
                                    li $s3, 0           # keeps track of when the pixels accross the background end
                                    li $t3, 0x10008008      # setting $t3 to the first pixel in background, $t3 stores current bitmap pixel
                                    li $t2, 0x10009000      # setting $t2 to the address of the first pixel in memory
                                    # #s3: just tracks when we are done a row
                                    # $t3: stores the current bitmap pixel we iterate thru
                                    # $t2: first address in memory
                                    # $s4: stores the ROW that is full
                                    # $s5: stores the CURRENT row we are on
                                    # $t1: will store COLOUR at memory address
                                    # $s7: will store BLACK/GREY
                                    li $s5, 0       # $s5 starts out on first row
                                    subi $s4, $s4, 1
                                    ULT_shift_background:
                                        # bne $s5, $s4, next_row      # keep iterating through rows until we get to $s4 - 1, the one that we NEED TO SHIFT!!!
                                    # Start at VERY FIRST ROW OF BACKGROUND. 
                                    # KEEP SHIFTING UNTIL WE GET TO CORRECT ROW!!!!
                                    draw_background_row_top_SHIFT:
                                        lw $t1, 0($t2)      # $t1 now stores VALUE at $t2 memory address
                                        lw $s7, black       # store BLACK in $s7
                                        # If $t1(VALUE) at memory address is black or grey, do NOT draw and move to next pixel
                                        beq $t1, $s7, increment_no_draw_SHIFT
                                        lw $s7, grey        # store GREY in $s7
                                        beq $t1, $s7, increment_no_draw_SHIFT
                                        
                                        
                                        sw $t1, 128($t3)      # sw VALUE, memory location/address, this is where we actually DRAW
                                        increment_no_draw_SHIFT:
                                    
                                        addi $t3, $t3, 4        # going to next pixel
                                        addi $t2, $t2, 4        # going to next memory address
                                        addi $s3, $s3, 4        # adding 4 to tracker variable
                                        beq $s3, 56, draw_background_row_end_SHIFT      # once we get to end of row, we go to outer loop
                                        j draw_background_row_top_SHIFT
                                    draw_background_row_end_SHIFT:
                                    addi $t3, $t3, 72       # add to $t3 so it starts at next row of background
                                    li $s3, 0               # resetting tracker variable
                                    addi $s5, $s5, 1        # row number tracker increases
                                    beq $s5, $s4, skip_a_row_shift      # if next row is equal to the row that is FULL... SKIP over the row and keep drawing until background is done
                                    
                                    beq $t3, 0x10008F08, shifted_draw_end
                                    j draw_background_row_top_SHIFT
                                    
                                    skip_a_row_shift:
                                    # addi $t3, $t3, 72
                                    addi $t2, $t2, 56
                                    beq $t3, 0x10008F08, shifted_draw_end
                                    j draw_background_row_top_SHIFT
                                
                                    
                                    
                                        
                                ULT_shift_background_end:       # now entire background is DONE being drawn
                            shifted_draw_end:
                            
                            ###################################################################################################
                            # copy background into memory after it's been shifted? 
                            
                            copy_background_top_shift:
                                    li $s3, 0           # keeps track of when the pixels accross the background end
                                    li $t3, 0x10008008
                                    li $t2, 0x10009000      # setting $t2 to a memory address past the grid
                                    
                                    
                                        copy_background_row_shift:
                                            lw $t1, 0($t3)      # setting $t1 to first pixel in grid
                                            sw $t1, 0($t2)      # placing value of pixel at $t1 into $t2 memory spot
                                            addi $t3, $t3, 4
                                            addiu $t2, $t2, 4
                                            addiu $s3, $s3, 4
                                            beq $s3, 56, copy_background_row_end_shift        # ends at right side 
                                            j copy_background_row_shift
                                        copy_background_row_end_shift:
                                        addi $t3, $t3, 72       # add to $t3 so it starts at next row of background
                                        li $s3, 0
                                        beq $t3, 0x10008F08, copy_background_end_shift
                                        j copy_background_row_shift
                                        
                                copy_background_end_shift:
                            
                            j check_full_background
        
        
                
                ##########################################################################################################################################################################
                next_tetrominoe:
                # ONLY DRAW NEW TETROMINOE *AFTER* WE'VE COPIED + DRAWN BACKGROUND... SEPARATELY from draw_all 
                
                # NEW: ONLY DRAW NEXT TETROMINOE IF SPACE AND GAME WILL NOT END
   
                li $t3, 0x1000800C      # first pixel in the first row of background... CORRECT NUMBER!
                lw $t4, black
                lw $t2, grey
                lw $s3, 0($t3)      # storing COLOUR at 3
                            
                            check_bottom_loop1:
                                # Early return... if any block is equal to gray or black, SKIP over the shift function
                                # li $t0, 0           # boolean value for if we find any colour at current pixel
                                lw $s3, 0($t3)      # storing COLOUR at 3
                                beq $s3, $t4, continue_checking     # If current pixel is equal to black, keep checking
                                # add_to_boolean:
                                    # addi $t0, $t0, 1
                                check_top_pixel_grey:
                                beq $s3, $t2, continue_checking     # If current pixel is equal to grey, keep checking
                                # add_to_boolean_again:
                                    # addi $t0, $t0, 1
                                    
                                
                                j end_sound     # If current pixel is NOT equal to black OR grey
                               
                                continue_checking:
                                beq $t3, 0x1000803C, next1      # hex value is the LAST PIXEL of the bottom row of background... CORRECT NUMBER!
                                addi $t3, $t3, 4
                                j check_bottom_loop1
                next1:
                # DRAW NEW TETROMINOE HERE
                    # li $t7, 0x10008024        # store x&y coordinate of middle of first row
                    # li $s4, 0x100080A4         # store second pixel address
                    # li $s5, 0x10008124          # store third pixel address
                    # li $s6, 0x100081A4          # store fourth pixel address
                    
                    # lw $t3, green
                    # sw $t3, 0($t7)              # draw first pixel
                    # sw $t3, 128($t7)            # draw second pixel
                    # sw $t3, 256($t7)            # draw third pixel
                    # sw $t3, 384($t7)            # draw fourth pixel
                    # li, $t9, 0                  # t9 keeps track of the orientation
                # GENERATE RANDOM NUMBER 0-6
                    choose_colour:
                        li $v0, 42 
                        la $a0, 0 
                        la $a1, 7
                        syscall
                # JUMPING TO CORRESPONDING DRAW TETROMINOE FXN
                    beq $a0, 0, draw_o_tetrominoe_top
                    beq $a0, 1, draw_i_tetrominoe_top
                    beq $a0, 2, draw_s_tetrominoe_top
                    beq $a0, 3, draw_z_tetrominoe_top
                    beq $a0, 4, draw_l_tetrominoe_top
                    beq $a0, 5, draw_j_tetrominoe_top
                    beq $a0, 6, draw_t_tetrominoe_top
    
    
    main1_end:
    b main1

keyboard_input:                     # A key is pressed
    lw $a0, 4($t0)                  # Load second word from keyboard
    beq $a0, 0x71, respond_to_Q     # Check if the key q was pressed
    beq $a0, 0x64, respond_to_D
    beq $a0, 0x73, respond_to_S
    beq $a0, 0x61, respond_to_A
    beq $a0, 0x77, respond_to_W
    beq $a0, 0x70, respond_to_P
    beq $a0, 0x72, respond_to_R

    li $v0, 1                       # ask system to print $a0
    syscall

    b main1
    
draw_in_place:
    # lw $t3, green
    sw $s1, 0($t7)
    sw $s1, 0($s4)
    sw $s1, 0($s5)
    sw $s1, 0($s6)
    j main1




hit_bottom_stop:
    # Need to redraw the piece but stop responding to keyboard inputs...
    # lw $t3, green
    sw $s1, 0($t7)
    sw $s1, 0($s4)
    sw $s1, 0($s5)
    sw $s1, 0($s6)
    
    li $v0, 31 
    la $a0, 60 
    la $a1, 500
    la $a2, 118
    la $a3, 100
    syscall 
    
    j bottom_reached
    
respond_to_R:
    j main

respond_to_P:
    li 		$v0, 32
	li 		$a0, 1
	syscall
                                    # store x&y coordinate
    lw $t0, ADDR_KBRD               # $t0 = base address for keyboard
    lw $t8, 0($t0)                  # Load first word from keyboard
    
    
    lw $t1, white
    lw $t4, PAUSE_DSPL
    sw $t1, ($t4)       # paint current pixel white
    sw $t1, 4($t4)

    sw $t1, 128($t4)
    sw $t1, 136($t4)
    sw $t1, 256($t4)
    sw $t1, 260($t4)
    sw $t1, 384($t4)
    
    sw $t1, 16($t4)
    sw $t1, 20($t4)
    sw $t1, 24($t4)
    sw $t1, 144($t4)
    sw $t1, 152($t4)
    sw $t1, 272($t4)
    sw $t1, 276($t4)
    sw $t1, 280($t4)
    sw $t1, 400($t4)
    sw $t1, 408($t4)
    
     sw $t1, 32($t4)
     sw $t1, 40($t4)
     sw $t1, 160($t4)
     sw $t1, 168($t4)
     sw $t1, 288($t4)
     sw $t1, 296($t4)
     sw $t1, 416($t4)
     sw $t1, 420($t4)
     sw $t1, 424($t4)
     
     sw $t1, 768($t4)
     sw $t1, 772($t4)
     sw $t1, 776($t4)
     sw $t1, 896($t4)
     sw $t1, 1024($t4)
     sw $t1, 1028($t4)
     sw $t1, 1032($t4)
     sw $t1, 1160($t4)
     sw $t1, 1032($t4)
     sw $t1, 1288($t4)
     sw $t1, 1284($t4)
     sw $t1, 1280($t4)
     
     sw $t1, 784($t4)
     sw $t1, 788($t4)
     sw $t1, 792($t4)
     sw $t1, 912($t4)
     sw $t1, 1040($t4)
     sw $t1, 1044($t4)
     sw $t1, 1048($t4)
     sw $t1, 1168($t4)
     sw $t1, 1296($t4)
     sw $t1, 1300($t4)
     sw $t1, 1304($t4)
     
     sw $t1, 800($t4)
     sw $t1, 804($t4)
     sw $t1, 928($t4)
     sw $t1, 936($t4)
     sw $t1, 1056($t4)
     sw $t1, 1064($t4)
     sw $t1, 1184($t4)
     sw $t1, 1192($t4)
     sw $t1, 1312($t4)
     sw $t1, 1316($t4)
     
    beq $t8, 1, keyboard_input1      # If first word 1, key is pressed

    b respond_to_P

keyboard_input1:


    lw $a0, 4($t0)
     beq $a0, 0x70, main1
     b respond_to_P

respond_to_Q:
	li $v0, 10                      # Quit gracefully
	syscall

respond_to_D:

    beq $s0, 1, new_draw_all
    j draw_all
    # j draw_preexisting_background
continue_d:

# Checking for right collision
# check_px_1
lw $t1, black
lw $t2, grey
lw $s7, 4($t7)
li $t3, 0
beq $s7, $t1, check_right_px_2
beq $s7, $t2, check_right_px_2

beq $t3, 0, draw_in_place

check_right_px_2:
lw $t1, black
lw $t2, grey
lw $s7, 4($s4)
beq $s7, $t1, check_right_px_3
beq $s7, $t2, check_right_px_3
beq $t3, 0, draw_in_place

check_right_px_3:
lw $t1, black
lw $t2, grey
lw $s7, 4($s5)
beq $s7, $t1, check_right_px_4
beq $s7, $t2, check_right_px_4
beq $t3, 0, draw_in_place

check_right_px_4:
lw $t1, black
lw $t2, grey
lw $s7, 4($s6)
li $t3, 0
beq $s7, $t1, load_right_d        # if next pixel to right is black, load 1
beq $s7, $t2, load_right_d       # if next pixel to right is grey, load 1
beq $t3, 0, draw_in_place
j check_col_right       # if next pixel to right is FULL(with wall or tetronimoe, jump to check), $t3 remains as 0
load_right_d:
li $t3, 1
check_col_right:
    bne $t3, 1, draw_in_place       # if the next pixel to the right is FULL, draw in place

# Drawing tetrominoe to right

 addiu $t7, $t7, 4               # increment $t7 by 4
 addiu $s4, $s4, 4
 addiu $s5, $s5, 4
 addiu $s6, $s6, 4
 
    # lw $t3, green
    sw $s1, 0($t7)
    sw $s1, 0($s4)
    sw $s1, 0($s5)
    sw $s1, 0($s6)
    b main1
    
respond_to_A:
    beq $s0, 1, new_draw_all
    j draw_all
    # j draw_preexisting_background
continue_a:

# Checking for left collision
# check_left_px_1
lw $t1, black
lw $t2, grey
lw $s7, -4($t7)
li $t3, 0
beq $s7, $t1, check_left_px_2
beq $s7, $t2, check_left_px_2
beq $t3, 0, draw_in_place

check_left_px_2:
lw $s7, -4($s4)
beq $s7, $t1, check_left_px_3
beq $s7, $t2, check_left_px_3
beq $t3, 0, draw_in_place

check_left_px_3:
lw $s7, -4($s5)
beq $s7, $t1, check_left_px_4
beq $s7, $t2, check_left_px_4
beq $t3, 0, draw_in_place

check_left_px_4:
lw $s7, -4($s6)
li $t3, 0
beq $s7, $t1, load_left_d        # if next pixel to right is black, load 1
beq $s7, $t2, load_left_d       # if next pixel to right is grey, load 1
beq $t3, 0, draw_in_place
load_left_d:
li $t3, 1
check_col_right:
    bne $t3, 1, draw_in_place       # if the next pixel to the right is FULL, draw in place



 subi $t7, $t7, 4               # increment $t7 by -4
 subi $s4, $s4, 4
 subi $s5, $s5, 4
 subi $s6, $s6, 4
    # lw $t3, green
    sw $s1, 0($t7)
    sw $s1, 0($s4)
    sw $s1, 0($s5)
    sw $s1, 0($s6)
    b main1

respond_to_S:
    beq $s0, 1, new_draw_all
    j draw_all
    # j draw_preexisting_background
continue_s:

# Checking for bottom collision
    # check_bottom_px_1
    lw $t1, black
    lw $t2, grey
    lw $s7, 128($t7)
    li $t3, 0
    beq $s7, $t1, check_bottom_px_2
    beq $s7, $t2, check_bottom_px_2
    beq $t3, 0, hit_bottom_stop
    
    check_bottom_px_2:
    lw $s7, 128($s4)
    beq $s7, $t1, check_bottom_px_3
    beq $s7, $t2, check_bottom_px_3
    beq $t3, 0, hit_bottom_stop
    
    check_bottom_px_3:
    lw $s7, 128($s5)
    beq $s7, $t1, check_bottom_px_4
    beq $s7, $t2, check_bottom_px_4
    beq $t3, 0, hit_bottom_stop
    
    check_bottom_px_4:
    lw $s7, 128($s6)
    li $t3, 0
    beq $s7, $t1, load_bottom_d        # if next pixel to right is black, load 1
    beq $s7, $t2, load_bottom_d       # if next pixel to right is grey, load 1
    beq $t3, 0, hit_bottom_stop
    load_bottom_d:
    li $t3, 1
    check_col_bottom:
        bne $t3, 1, hit_bottom_stop       # if the next pixel to the right is FULL, draw in place
        


     addi $t7, $t7, 128               # increment $t7 by 128
     addiu $s4, $s4, 128
     addiu $s5, $s5, 128
     addiu $s6, $s6, 128
        # lw $t3, green
        sw $s1, 0($t7)
        sw $s1, 0($s4)
        sw $s1, 0($s5)
        sw $s1, 0($s6)
        b main1

respond_to_W:
    beq $s0, 1, new_draw_all
    j draw_all
    # j draw_preexisting_background
continue_w:
    beq $s2, 0, rotate_o
    beq $s2, 1, rotate_i
    beq $s2, 2, rotate_s
    beq $s2, 3, rotate_z
    beq $s2, 4, rotate_l
    beq $s2, 5, rotate_j
    beq $s2, 6, rotate_t
        rotate_o:
            beq $t9, 0, respond_to_90_o
            beq $t9, 1, respond_to_180_o
            beq $t9, 2, respond_to_270_o
            beq $t9, 3, respond_to_360_o
        rotate_i:
            beq $t9, 0, respond_to_90_i
            beq $t9, 1, respond_to_180_i
            beq $t9, 2, respond_to_270_i
            beq $t9, 3, respond_to_360_i
        rotate_s:
            beq $t9, 0, respond_to_90_s
            beq $t9, 1, respond_to_180_s
            beq $t9, 2, respond_to_270_s
            beq $t9, 3, respond_to_360_s
        rotate_z:
            beq $t9, 0, respond_to_90_z
            beq $t9, 1, respond_to_180_z
            beq $t9, 2, respond_to_270_z
            beq $t9, 3, respond_to_360_z
        rotate_l:
            beq $t9, 0, respond_to_90_l
            beq $t9, 1, respond_to_180_l
            beq $t9, 2, respond_to_270_l
            beq $t9, 3, respond_to_360_l
        rotate_j:
            beq $t9, 0, respond_to_90_j
            beq $t9, 1, respond_to_180_j
            beq $t9, 2, respond_to_270_j
            beq $t9, 3, respond_to_360_j
        rotate_t:
            beq $t9, 0, respond_to_90_t
            beq $t9, 1, respond_to_180_t
            beq $t9, 2, respond_to_270_t
            beq $t9, 3, respond_to_360_t

 respond_to_90:  
 
 # Checking for 90 rotation collision    
    lw $t1, black
    lw $t2, grey
    li $t3, 0
    check_90_px_2:
    lw $s7, -132($s4)
    beq $s7, $t1, check_90_px_3
    beq $s7, $t2, check_90_px_3
    beq $t3, 0, draw_in_place
    
    check_90_px_3:
    lw $s7, -264($s5)
    beq $s7, $t1, check_90_px_4
    beq $s7, $t2, check_90_px_4
    beq $t3, 0, draw_in_place
    
    check_90_px_4:
    lw $s7, -396($s6)
    li $t3, 0
    beq $s7, $t1, load_90_d        # if next pixel to right is black, load 1
    beq $s7, $t2, load_90_d       # if next pixel to right is grey, load 1
    beq $t3, 0, draw_in_place
    load_90_d:
    li $t3, 1
    check_col_90:
        bne $t3, 1, draw_in_place       # if the next pixel to the right is FULL, draw in place
 
    lw $t3, green
    subi, $s4, $s4, 132
    subi, $s5, $s5, 264
    subi, $s6, $s6, 396
    sw $t3, 0($t7)
    sw $t3, 0($s4)
    sw $t3, 0($s5)
    sw $t3, 0($s6)
    
    li $v0, 31 
    la $a0, 60 
    la $a1, 500
    la $a2, 82
    la $a3, 100
    syscall
    
    li, $t9, 1
    b main1
    
respond_to_180:
     # Checking for 180 rotation collision    
    lw $t1, black
    lw $t2, grey
    li $t3, 0
    check_180_px_2:
    lw $s7, -124($s4)
    beq $s7, $t1, check_180_px_3
    beq $s7, $t2, check_180_px_3
    beq $t3, 0, draw_in_place
    
    check_180_px_3:
    lw $s7, -248($s5)
    beq $s7, $t1, check_180_px_4
    beq $s7, $t2, check_180_px_4
    beq $t3, 0, draw_in_place
    
    check_180_px_4:
    lw $s7, -372($s6)
    li $t3, 0
    beq $s7, $t1, load_180_d        # if next pixel to right is black, load 1
    beq $s7, $t2, load_180_d       # if next pixel to right is grey, load 1
    beq $t3, 0, draw_in_place
    load_180_d:
    li $t3, 1
    check_col_180:
        bne $t3, 1, draw_in_place       # if the next pixel to the right is FULL, draw in place


    lw $t3, green
    subi, $s4, $s4, 124
    subi, $s5, $s5, 248
    subi, $s6, $s6, 372
    sw $t3, 0($t7)
    sw $t3, 0($s4)
    sw $t3, 0($s5)
    sw $t3, 0($s6)
    
    li $v0, 31 
    la $a0, 60 
    la $a1, 500
    la $a2, 82
    la $a3, 100
    syscall
    
    li, $t9, 2
    b main1
    
respond_to_270:
     # Checking for 270 rotation collision
  
    lw $t1, black
    lw $t2, grey
    li $t3, 0
    check_270_px_2:
    lw $s7, 132($s4)
    beq $s7, $t1, check_270_px_3
    beq $s7, $t2, check_270_px_3
    beq $t3, 0, draw_in_place
    
    check_270_px_3:
    lw $s7, 264($s5)
    beq $s7, $t1, check_270_px_4
    beq $s7, $t2, check_270_px_4
    beq $t3, 0, draw_in_place
    
    check_270_px_4:
    lw $s7, 396($s6)
    li $t3, 0
    beq $s7, $t1, load_270_d        # if next pixel to right is black, load 1
    beq $s7, $t2, load_270_d       # if next pixel to right is grey, load 1
    beq $t3, 0, draw_in_place
    load_270_d:
    li $t3, 1
    check_col_270:
        bne $t3, 1, draw_in_place       # if the next pixel to the right is FULL, draw in place
    
    
    addiu $s4, $s4, 132
    addiu $s5, $s5, 264
    addiu $s6, $s6, 396
    
    lw $t3, green
    sw $t3, 0($t7)
    sw $t3, 4($t7)
    sw $t3, 8($t7)
    sw $t3, 12($t7)
    
    li $v0, 31 
    la $a0, 60 
    la $a1, 500
    la $a2, 82
    la $a3, 100
    syscall
    
    li, $t9, 3
    b main1
    
    
respond_to_360:  

 # Checking for 360 rotation collision
 
    lw $t1, black
    lw $t2, grey
    li $t3, 0
    check_360_px_2:
    lw $s7, 124($s4)
    beq $s7, $t1, check_360_px_3
    beq $s7, $t2, check_360_px_3
    beq $t3, 0, draw_in_place
    
    check_360_px_3:
    lw $s7, 248($s5)
    beq $s7, $t1, check_360_px_4
    beq $s7, $t2, check_360_px_4
    beq $t3, 0, draw_in_place
    
    check_360_px_4:
    lw $s7, 372($s6)
    li $t3, 0
    beq $s7, $t1, load_360_d        # if next pixel to right is black, load 1
    beq $s7, $t2, load_360_d       # if next pixel to right is grey, load 1
    beq $t3, 0, draw_in_place
    load_360_d:
    li $t3, 1
    check_col_360:
        bne $t3, 1, draw_in_place       # if the next pixel to the right is FULL, draw in place

    addiu, $s4, $s4, 124
    addiu, $s5, $s5, 248
    addiu, $s6, $s6, 372
    
    lw $t3, green
    sw $t3, 0($t7)
    sw $t3, 0($s4)
    sw $t3, 0($s5)
    sw $t3, 0($s6)
    
    li $v0, 31 
    la $a0, 60 
    la $a1, 500
    la $a2, 82
    la $a3, 100
    syscall
    
    li, $t9, 0
    b main1

# NEW DRAW ALL FUNCTION... DRAWS WITHOUT COPYING#####################################################################################################
new_draw_all:
ndraw_all:
    li $t4, 0x10008000          # loading $t4 loop variable as display start
    li $t5, 0x10008080          # loading $t5 loop variable as end of row
    li $t6, 0x10008100
    
    
    nfinal_grid_top:
        jal ngrid_black_top
        addiu $t5, $t5, 256
        jal ngrid_grey_top
        addiu $t6, $t6, 256
        
        
        beq $t4, 0x10009000, nfinal_grid_end
        j nfinal_grid_top
    nfinal_grid_end:
    j nult_wall_top
    
    ngrid_black_top:
        lw $t1, black
        sw $t1, 0($t4)          # paint current pixel black
        lw $t2, grey
        sw $t2, 4($t4)          # paint next pixel grey
        addiu $t4, $t4, 8           # increment $t4 by 8(2 pixels)
        beq $t4, $t5, ngrid_black_end
        j ngrid_black_top
    ngrid_black_end:
    jr $ra          # jump back to code
    
    ngrid_grey_top:
        lw $t2, grey
        sw $t2, 0($t4)          # paint current pixel grey
        lw $t1, black
        sw $t1, 4($t4)          # paint next pixel black
        addiu $t4, $t4, 8           # increment $t4 by 8(2 pixels)
        beq $t4, $t6, ngrid_grey_end
        j ngrid_grey_top
    ngrid_grey_end:
    jr $ra          # jump back to code
    
    
    
   # DRAWING THE WALLS #######################################################
   nult_wall_top:
   li $t4, 0x10008000        # setting $t4 to the base address
   nwall_top:
        
        lw $t3, green
        sw $t3, 0($t4)          # paint the first two pixels on row green
        sw $t3, 4($t4)
        sw $t3, 64($t4)        # paint the last two pixels on row green
        sw $t3, 68($t4)
        addiu $t4, $t4, 128        # increment $t4 by 128
        # CHANGE STARTS HERE... s1 to t3####
        lw $t1, second_last_row
        beq $t4, $t1, nwall_end
        # CHANGE ENDS HERE
        j nwall_top        # jump to top of outer loop
    nwall_end:
    nfloor_top:
        nfloor_row_1:
            sw $t3, ($t4)          # paint current pixel green
            addiu $t4, $t4, 4           # increment $t4 by 4(1 pixel)
            beq $t4, 0x10008F48, nfloor_row_1_end
            j nfloor_row_1
        nfloor_row_1_end:
        
            addiu $t4, $t4, 56
        
        nfloor_row_2:
            sw $t3, ($t4)          # paint current pixel green
            addiu $t4, $t4, 4           # increment $t4 by 4(1 pixel)
            beq $t4, 0x10008FC8, nfloor_end
            j nfloor_row_2
        nfloor_row_2_end:
    nfloor_end:
    nult_wall_end:
    
    
new_draw_all_end:

        # DRAWING background from memory
        
        li $s3, 0           # keeps track of when the pixels accross the background end
        li $t3, 0x10008008      # setting $t3 to the first pixel in background, $t3 stores current bitmap pixel
        li $t2, 0x10009000      # setting $t2 to the address of the first pixel in memory
        # $t3 stores the current bitmap pixel

    new_draw_background_row_top:
        lw $t1, 0($t2)      # $t1 now stores VALUE at $t2 memory address
        lw $s7, black       # store BLACK in $s7
        
        
        # If $t1(VALUE) at memory address is black or grey, do NOT draw and move to next pixel
        beq $t1, $s7, increment_no_draw
        lw $s7, grey        # store GREY in $s7
        
        beq $t1, $s7, increment_no_draw
        
        
        sw $t1, 0($t3)      # sw VALUE, memory location/address, this is where we actually DRAW
        increment_no_draw:
        addi $t3, $t3, 4
        addi $t2, $t2, 4
        addi $s3, $s3, 4
        beq $s3, 56, draw_background_row_end
        j new_draw_background_row_top
    draw_background_row_end:
        addi $t3, $t3, 72       # add to $t3 so it starts at next row of background
        li $s3, 0
        beq $t3, 0x10008F08, end_draw_background
        j new_draw_background_row_top
            
        new_end_draw_background:       # now entire background is DONE being drawn

beq $a0, 0x64, continue_d
beq $a0, 0x61, continue_a
beq $a0, 0x73, continue_s
beq $a0, 0x77, continue_w


    
####################################################################################################################################
# HIT BOTTOM CASE ONLY!!!

copy_background_top_2:
        li $s3, 0           # keeps track of when the pixels accross the background end
        li $t3, 0x10008008
        li $t2, 0x10009000      # setting $t2 to a memory address past the grid
        
        
            copy_background_row_2:
                lw $t1, 0($t3)      # setting $t1 to first pixel in grid
                sw $t1, 0($t2)      # placing value of pixel at $t1 into $t2 memory spot
                addi $t3, $t3, 4
                addiu $t2, $t2, 4
                addiu $s3, $s3, 4
                beq $s3, 56, copy_background_row_end_2        # ends at right side 
                j copy_background_row_2
            copy_background_row_end_2:
            addi $t3, $t3, 72       # add to $t3 so it starts at next row of background
            li $s3, 0
            beq $t3, 0x10008F08, copy_background_end_2
            j copy_background_row_2
            
    copy_background_end_2:
        
# DRAW BACKGROUND
        li $s3, 0           # keeps track of when the pixels accross the background end
        li $t3, 0x10008008      # setting $t3 to the first pixel in background, $t3 stores current bitmap pixel
        li $t2, 0x10009000      # setting $t2 to the address of the first pixel in memory
        # $t3 stores the current bitmap pixel

        draw_background_row_top_2:
        lw $t1, 0($t2)      # $t1 now stores VALUE at $t2 memory address

        lw $s7, black       # store BLACK in $s7
        # If $t1(VALUE) at memory address is black or grey, do NOT draw and move to next pixel
        beq $t1, $s7, increment_no_draw_2
        lw $s7, grey        # store GREY in $s7
        beq $t1, $s7, increment_no_draw_2
        
        
        sw $t1, 0($t3)      # sw VALUE, memory location/address, this is where we actually DRAW
        increment_no_draw_2:
        
        addi $t3, $t3, 4
        addi $t2, $t2, 4
        addi $s3, $s3, 4
        beq $s3, 56, draw_background_row_end_2
        j draw_background_row_top_2
        draw_background_row_end_2:
        addi $t3, $t3, 72       # add to $t3 so it starts at next row of background
        li $s3, 0
        beq $t3, 0x10008F08, end_draw_background_2
        j draw_background_row_top_2
            
        end_draw_background_2:       # now entire background is DONE being drawn
   
   j bottom_continued
   
   end_sound:
   li $v0, 31 
    la $a0, 63 
    la $a1, 1000
    la $a2, 82
    la $a3, 100
    syscall
    j end_game
   
   end_game:
    
    li 		$v0, 32
	li 		$a0, 1
	syscall
                                    # store x&y coordinate
    lw $t0, ADDR_KBRD               # $t0 = base address for keyboard
    
    lw $t0, ADDR_KBRD               # $t0 = base address for keyboard
    lw $t8, 0($t0)                  # Load first word from keyboard
    
    
    
    lw $t1, red
    lw $t4, PAUSE_DSPL
    sw $t1, ($t4)       # paint current pixel white
    sw $t1, 4($t4)
    sw $t1, 8($t4)
    

    sw $t1, 128($t4)
    sw $t1, 256($t4)
    sw $t1, 264($t4)
    sw $t1, 384($t4)
    sw $t1, 388($t4)
    sw $t1, 392($t4)
    
    
sw $t1, 768($t4)
sw $t1, 772($t4)
sw $t1, 776($t4)
sw $t1, 896($t4)
sw $t1, 904($t4)
sw $t1, 1024($t4)
sw $t1, 1028($t4)
sw $t1, 1032($t4)
sw $t1, 1152($t4)
sw $t1, 1160($t4)
    
sw $t1, 1536($t4)
sw $t1, 1544($t4)
sw $t1, 1664($t4)
sw $t1, 1668($t4)
sw $t1, 1672($t4)
sw $t1, 1792($t4)
sw $t1, 1800($t4)
sw $t1, 1920($t4)
sw $t1, 1928($t4)

sw $t1, 2304($t4)
sw $t1, 2308($t4)
sw $t1, 2312($t4)
sw $t1, 2432($t4)
sw $t1, 2560($t4)
sw $t1, 2564($t4)
sw $t1, 2568($t4)
sw $t1, 2688($t4)
sw $t1, 2568($t4)
sw $t1, 2824($t4)
sw $t1, 2820($t4)
sw $t1, 2816($t4)
     
sw $t1, 24($t4)       #O
sw $t1, 28($t4)
sw $t1, 32($t4)

sw $t1, 152($t4)
sw $t1, 160($t4)
sw $t1, 280($t4)
sw $t1, 288($t4)
sw $t1, 408($t4)
sw $t1, 412($t4)
sw $t1, 416($t4)


sw $t1, 792($t4)
sw $t1, 800($t4)
sw $t1, 920($t4)
sw $t1, 928($t4)
sw $t1, 1048($t4)
sw $t1, 1056($t4)
sw $t1, 1180($t4)

sw $t1, 1560($t4)
sw $t1, 1564($t4)
sw $t1, 1568($t4)
sw $t1, 1688($t4)
sw $t1, 1816($t4)
sw $t1, 1820($t4)
sw $t1, 1824($t4)
sw $t1, 1944($t4)
sw $t1, 1824($t4)
sw $t1, 2080($t4)
sw $t1, 2076($t4)
sw $t1, 2072($t4)

sw $t1, 2328($t4)
sw $t1, 2332($t4)
sw $t1, 2336($t4)
sw $t1, 2456($t4)
sw $t1, 2584($t4)
sw $t1, 2712($t4)
sw $t1, 2840($t4)

   
    
    beq $t8, 1, keyboard_input2      # If first word 1, key is pressed

    b end_game

keyboard_input2:

     lw $a0, 4($t0)
     beq $a0, 0x72, main
     b end_game
     
     
#################################################################################################################################################################################
# INITIALIZING ALL TYPES OF TETROMINOES!!!!
#################################################################################################################################################################################
    # Drawing O tetrominoe
    draw_o_tetrominoe_top:
        li $t7, 0x10008024        # store x&y coordinate of middle of first row
        li $s4, 0x10008020         # store second pixel address
        li $s5, 0x100080A0          # store third pixel address
        li $s6, 0x100080A4          # store fourth pixel address
        
        li $t3, 0xf05d5d            # LOADING COLOUR: RED
        li $s1, 0xf05d5d            # LOADING COLOUR: RED
        sw $t3, 0($t7)              # draw first pixel
        sw $t3, -4($t7)            # draw second pixel
        sw $t3, 124($t7)            # draw third pixel
        sw $t3, 128($t7)            # draw fourth pixel
        li $t9, 0                  # t9 keeps track of the orientation
        # Set TYPE of tetrominoe
        li $s2, 0               # s2 keeps track of the TYPE of tetrominoe
    draw_o_tetrominoe_end:
        b main1
    
    # Drawing I tetrominoe
    draw_i_tetrominoe_top:
        li $t7, 0x10008024        # store x&y coordinate of middle of first row
        li $s4, 0x100080A4         # store second pixel address
        li $s5, 0x10008124          # store third pixel address
        li $s6, 0x100081A4          # store fourth pixel address
        
        li $t3, 0xebeb49            # LOADING COLOUR: YELLOW
        li $s1, 0xebeb49            # LOADING COLOUR: YELLOW
        sw $t3, 0($t7)              # draw first pixel
        sw $t3, 128($t7)            # draw second pixel
        sw $t3, 256($t7)            # draw third pixel
        sw $t3, 384($t7)            # draw fourth pixel
        li $t9, 0                  # t9 keeps track of the orientation
        # Set TYPE of tetrominoe
        li $s2, 1               # s2 keeps track of the TYPE of tetrominoe
    draw_i_tetrominoe_end:
        b main1

    
    # Drawing S tetrominoe
    draw_s_tetrominoe_top:
        li $t7, 0x10008024        # store x&y coordinate of middle of first row
        li $s4, 0x10008028         # store second pixel address
        li $s5, 0x100080A4          # store third pixel address
        li $s6, 0x100080A0          # store fourth pixel address
        
        li $t3, 0x4af24a            # LOADING COLOUR: GREEN
        li $s1, 0x4af24a            # LOADING COLOUR: GREEN
        sw $t3, 0($t7)              # draw first pixel
        sw $t3, 4($t7)            # draw second pixel
        sw $t3, 128($t7)            # draw third pixel
        sw $t3, 124($t7)            # draw fourth pixel
        li $t9, 0                  # t9 keeps track of the orientation
        # Set TYPE of tetrominoe
        li $s2, 2               # s2 keeps track of the TYPE of tetrominoe
    draw_s_tetrominoe_end:
        b main1
    
    # Drawing Z tetrominoe
    draw_z_tetrominoe_top:
        li $t7, 0x10008024        # store x&y coordinate of middle of first row
        li $s4, 0x10008020         # store second pixel address
        li $s5, 0x100080A4          # store third pixel address
        li $s6, 0x100080A8          # store fourth pixel address
        
        li $t3, 0x75ebd9            # LOADING COLOUR: BLUE
        li $s1, 0x75ebd9            # LOADING COLOUR: BLUE
        sw $t3, 0($t7)              # draw first pixel
        sw $t3, -4($t7)            # draw second pixel
        sw $t3, 128($t7)            # draw third pixel
        sw $t3, 132($t7)            # draw fourth pixel
        li $t9, 0                  # t9 keeps track of the orientation
        # Set TYPE of tetrominoe
        li $s2, 3               # s2 keeps track of the TYPE of tetrominoe
    draw_z_tetrominoe_end:
        b main1
    
    
    # Drawing L tetrominoe
    draw_l_tetrominoe_top:
        li $t7, 0x10008024        # store x&y coordinate of middle of first row
        li $s4, 0x100080A4         # store second pixel address
        li $s5, 0x10008124          # store third pixel address
        li $s6, 0x10008128          # store fourth pixel address
        
        li $t3, 0x7676f5            # LOADING COLOUR: INDIGO
        li $s1, 0x7676f5            # LOADING COLOUR: INDIGO
        sw $t3, 0($t7)              # draw first pixel
        sw $t3, 128($t7)            # draw second pixel
        sw $t3, 256($t7)            # draw third pixel
        sw $t3, 260($t7)            # draw fourth pixel
        li $t9, 0                  # t9 keeps track of the orientation
        # Set TYPE of tetrominoe
        li $s2, 4               # s2 keeps track of the TYPE of tetrominoe
    draw_l_tetrominoe_end:
        b main1
    
    
    # Drawing J tetrominoe
    draw_j_tetrominoe_top:
        li $t7, 0x10008024        # store x&y coordinate of middle of first row
        li $s4, 0x100080A4         # store second pixel address
        li $s5, 0x10008124          # store third pixel address
        li $s6, 0x10008120          # store fourth pixel address
        
        li $t3, 0xc184f0            # LOADING COLOUR: PURPLE
        li $s1, 0xc184f0            # LOADING COLOUR: PURPLE
        sw $t3, 0($t7)              # draw first pixel
        sw $t3, 128($t7)            # draw second pixel
        sw $t3, 256($t7)            # draw third pixel
        sw $t3, 252($t7)            # draw fourth pixel
        li $t9, 0                  # t9 keeps track of the orientation
        # Set TYPE of tetrominoe
        li $s2, 5               # s2 keeps track of the TYPE of tetrominoe
    draw_j_tetrominoe_end:
        b main1
    
    
    # Drawing T tetrominoe
    draw_t_tetrominoe_top:
        li $t7, 0x10008024        # store x&y coordinate of middle of first row
        li $s4, 0x10008020         # store second pixel address
        li $s5, 0x10008028          # store third pixel address
        li $s6, 0x100080A4          # store fourth pixel address
        
        li $t3, 0xf76f9a            # LOADING COLOUR: PINK
        li $s1, 0xf76f9a            # LOADING COLOUR: PINK
        sw $t3, 0($t7)              # draw first pixel
        sw $t3, -4($t7)            # draw second pixel
        sw $t3, 4($t7)            # draw third pixel
        sw $t3, 128($t7)            # draw fourth pixel
        li $t9, 0                  # t9 keeps track of the orientation
        # Set TYPE of tetrominoe
        li $s2, 6               # s2 keeps track of the TYPE of tetrominoe
    draw_t_tetrominoe_end:
        b main1

################################################################################################################################################################################
# HAVE U EVER FELT? LIKE A PLASTIC BAG? DRIFTING THROUGH THE WIND?(ROTATION PARTS)
#################################################################################################################################################################################
    # ROTATING O
    respond_to_90_o:
        li $t3, 0xf05d5d
        sw $t3, 0($t7)
        sw $t3, 0($s4)
        sw $t3, 0($s5)
        sw $t3, 0($s6)
        
        li $v0, 31 
        la $a0, 60 
        la $a1, 500
        la $a2, 82
        la $a3, 100
        syscall
        
        li, $t9, 1
        b main1
    
    respond_to_180_o:
        li $t3, 0xf05d5d
        sw $t3, 0($t7)
        sw $t3, 0($s4)
        sw $t3, 0($s5)
        sw $t3, 0($s6)
        
        li $v0, 31 
        la $a0, 60 
        la $a1, 500
        la $a2, 82
        la $a3, 100
        syscall
        
        li, $t9, 2
        b main1
    
    respond_to_270_o:
        li $t3, 0xf05d5d
        sw $t3, 0($t7)
        sw $t3, 0($s4)
        sw $t3, 0($s5)
        sw $t3, 0($s6)
        
        li $v0, 31 
        la $a0, 60 
        la $a1, 500
        la $a2, 82
        la $a3, 100
        syscall
        
        li, $t9, 3
        b main1
    
    respond_to_360_o:
        li $t3, 0xf05d5d
        sw $t3, 0($t7)
        sw $t3, 0($s4)
        sw $t3, 0($s5)
        sw $t3, 0($s6)
        
        li $v0, 31 
        la $a0, 60 
        la $a1, 500
        la $a2, 82
        la $a3, 100
        syscall
        
        li, $t9, 0
        b main1
    
    
#######################################################################################################################
    # ROTATING I
    respond_to_90_i:  
     # Checking for 90 rotation collision    
        lw $t1, black
        lw $t2, grey
        li $t3, 0
        check_90_px_2_i:
        lw $s7, -132($s4)
        beq $s7, $t1, check_90_px_3_i
        beq $s7, $t2, check_90_px_3_i
        beq $t3, 0, draw_in_place
        
        check_90_px_3_i:
        lw $s7, -264($s5)
        beq $s7, $t1, check_90_px_4_i
        beq $s7, $t2, check_90_px_4_i
        beq $t3, 0, draw_in_place
        
        check_90_px_4_i:
        lw $s7, -396($s6)
        li $t3, 0
        beq $s7, $t1, load_90_d_i        # if next pixel to right is black, load 1
        beq $s7, $t2, load_90_d_i       # if next pixel to right is grey, load 1
        beq $t3, 0, draw_in_place
        load_90_d_i:
        li $t3, 1
        check_col_90_i:
            bne $t3, 1, draw_in_place       # if the next pixel to the right is FULL, draw in place
     
        li $t3, 0xebeb49
        subi, $s4, $s4, 132
        subi, $s5, $s5, 264
        subi, $s6, $s6, 396
        sw $t3, 0($t7)
        sw $t3, 0($s4)
        sw $t3, 0($s5)
        sw $t3, 0($s6)
        
        li $v0, 31 
        la $a0, 60 
        la $a1, 500
        la $a2, 82
        la $a3, 100
        syscall
        
        li, $t9, 1
        b main1
        
    respond_to_180_i:
         # Checking for 180 rotation collision    
        lw $t1, black
        lw $t2, grey
        li $t3, 0
        check_180_px_2_i:
        lw $s7, -124($s4)
        beq $s7, $t1, check_180_px_3_i
        beq $s7, $t2, check_180_px_3_i
        beq $t3, 0, draw_in_place
        
        check_180_px_3_i:
        lw $s7, -248($s5)
        beq $s7, $t1, check_180_px_4_i
        beq $s7, $t2, check_180_px_4_i
        beq $t3, 0, draw_in_place
        
        check_180_px_4_i:
        lw $s7, -372($s6)
        li $t3, 0
        beq $s7, $t1, load_180_d_i        # if next pixel to right is black, load 1
        beq $s7, $t2, load_180_d_i       # if next pixel to right is grey, load 1
        beq $t3, 0, draw_in_place
        load_180_d_i:
        li $t3, 1
        check_col_180_i:
            bne $t3, 1, draw_in_place       # if the next pixel to the right is FULL, draw in place
    
    
        li $t3, 0xebeb49
        subi, $s4, $s4, 124
        subi, $s5, $s5, 248
        subi, $s6, $s6, 372
        sw $t3, 0($t7)
        sw $t3, 0($s4)
        sw $t3, 0($s5)
        sw $t3, 0($s6)
        
        li $v0, 31 
        la $a0, 60 
        la $a1, 500
        la $a2, 82
        la $a3, 100
        syscall
        
        li, $t9, 2
        b main1
        
    respond_to_270_i:
         # Checking for 270 rotation collision
      
        lw $t1, black
        lw $t2, grey
        li $t3, 0
        check_270_px_2_i:
        lw $s7, 132($s4)
        beq $s7, $t1, check_270_px_3_i
        beq $s7, $t2, check_270_px_3_i
        beq $t3, 0, draw_in_place
        
        check_270_px_3_i:
        lw $s7, 264($s5)
        beq $s7, $t1, check_270_px_4_i
        beq $s7, $t2, check_270_px_4_i
        beq $t3, 0, draw_in_place
        
        check_270_px_4_i:
        lw $s7, 396($s6)
        li $t3, 0
        beq $s7, $t1, load_270_d_i        # if next pixel to right is black, load 1
        beq $s7, $t2, load_270_d_i       # if next pixel to right is grey, load 1
        beq $t3, 0, draw_in_place
        load_270_d_i:
        li $t3, 1
        check_col_270_i:
            bne $t3, 1, draw_in_place       # if the next pixel to the right is FULL, draw in place
        
        
        addiu $s4, $s4, 132
        addiu $s5, $s5, 264
        addiu $s6, $s6, 396
        
        li $t3, 0xebeb49
        sw $t3, 0($t7)
        sw $t3, 4($t7)
        sw $t3, 8($t7)
        sw $t3, 12($t7)
        
        li $v0, 31 
        la $a0, 60 
        la $a1, 500
        la $a2, 82
        la $a3, 100
        syscall
        
        li, $t9, 3
        b main1
        
        
    respond_to_360_i:  
    
     # Checking for 360 rotation collision
     
        lw $t1, black
        lw $t2, grey
        li $t3, 0
        check_360_px_2_i:
        lw $s7, 124($s4)
        beq $s7, $t1, check_360_px_3_i
        beq $s7, $t2, check_360_px_3_i
        beq $t3, 0, draw_in_place
        
        check_360_px_3_i:
        lw $s7, 248($s5)
        beq $s7, $t1, check_360_px_4_i
        beq $s7, $t2, check_360_px_4_i
        beq $t3, 0, draw_in_place
        
        check_360_px_4_i:
        lw $s7, 372($s6)
        li $t3, 0
        beq $s7, $t1, load_360_d_i        # if next pixel to right is black, load 1
        beq $s7, $t2, load_360_d_i       # if next pixel to right is grey, load 1
        beq $t3, 0, draw_in_place
        load_360_d_i:
        li $t3, 1
        check_col_360_i:
            bne $t3, 1, draw_in_place       # if the next pixel to the right is FULL, draw in place
    
        addiu, $s4, $s4, 124
        addiu, $s5, $s5, 248
        addiu, $s6, $s6, 372
        
        li $t3, 0xebeb49
        sw $t3, 0($t7)
        sw $t3, 0($s4)
        sw $t3, 0($s5)
        sw $t3, 0($s6)
        
        li $v0, 31 
        la $a0, 60 
        la $a1, 500
        la $a2, 82
        la $a3, 100
        syscall
        
        li, $t9, 0
        b main1
    
    
#######################################################################################################################
    # ROTATING S 
    respond_to_90_s:
        # Checking for 90 rotation collision    
        lw $t1, black
        lw $t2, grey
        li $t3, 0
        check_90_px_2_s:
        lw $s7, 124($s4)
        beq $s7, $t1, check_90_px_3_s
        beq $s7, $t2, check_90_px_3_s
        beq $t3, 0, draw_in_place
        
        check_90_px_3_s:
        lw $s7, -132($s5)
        beq $s7, $t1, check_90_px_4_s
        beq $s7, $t2, check_90_px_4_s
        beq $t3, 0, draw_in_place
        
        check_90_px_4_s:
        lw $s7, -256($s6)
        li $t3, 0
        beq $s7, $t1, load_90_d_s        # if next pixel to right is black, load 1
        beq $s7, $t2, load_90_d_s       # if next pixel to right is grey, load 1
        beq $t3, 0, draw_in_place
        load_90_d_s:
        li $t3, 1
        check_col_90_s:
            bne $t3, 1, draw_in_place       # if the next pixel to the right is FULL, draw in place
     
        li $t3, 0x4af24a
        addi, $s4, $s4, 124
        subi, $s5, $s5, 132
        subi, $s6, $s6, 256
        sw $t3, 0($t7)
        sw $t3, 0($s4)
        sw $t3, 0($s5)
        sw $t3, 0($s6)
        
        li $v0, 31 
        la $a0, 60 
        la $a1, 500
        la $a2, 82
        la $a3, 100
        syscall
        
        li, $t9, 1
        b main1
        
    
    respond_to_180_s:
        # Checking for 90 rotation collision    
        lw $t1, black
        lw $t2, grey
        li $t3, 0
        check_180_px_2_s:
        lw $s7, -132($s4)
        beq $s7, $t1, check_180_px_3_s
        beq $s7, $t2, check_180_px_3_s
        beq $t3, 0, draw_in_place
        
        check_180_px_3_s:
        lw $s7, -124($s5)
        beq $s7, $t1, check_180_px_4_s
        beq $s7, $t2, check_180_px_4_s
        beq $t3, 0, draw_in_place
        
        check_180_px_4_s:
        lw $s7, 8($s6)
        li $t3, 0
        beq $s7, $t1, load_180_d_s        # if next pixel to right is black, load 1
        beq $s7, $t2, load_180_d_s       # if next pixel to right is grey, load 1
        beq $t3, 0, draw_in_place
        load_180_d_s:
        li $t3, 1
        check_col_180_s:
            bne $t3, 1, draw_in_place       # if the next pixel to the right is FULL, draw in place
     
        li $t3, 0x4af24a
        subi, $s4, $s4, 132
        subi, $s5, $s5, 124
        addi, $s6, $s6, 8
        sw $t3, 0($t7)
        sw $t3, 0($s4)
        sw $t3, 0($s5)
        sw $t3, 0($s6)
        
        li $v0, 31 
        la $a0, 60 
        la $a1, 500
        la $a2, 82
        la $a3, 100
        syscall
        
        li, $t9, 2
        b main1
        
        
    respond_to_270_s:
        # Checking for 90 rotation collision    
        lw $t1, black
        lw $t2, grey
        li $t3, 0
        check_270_px_2_s:
        lw $s7, -124($s4)
        beq $s7, $t1, check_270_px_3_s
        beq $s7, $t2, check_270_px_3_s
        beq $t3, 0, draw_in_place
        
        check_270_px_3_s:
        lw $s7, 132($s5)
        beq $s7, $t1, check_270_px_4_s
        beq $s7, $t2, check_270_px_4_s
        beq $t3, 0, draw_in_place
        
        check_270_px_4_s:
        lw $s7, 256($s6)
        li $t3, 0
        beq $s7, $t1, load_270_d_s        # if next pixel to right is black, load 1
        beq $s7, $t2, load_270_d_s       # if next pixel to right is grey, load 1
        beq $t3, 0, draw_in_place
        load_270_d_s:
        li $t3, 1
        check_col_270_s:
            bne $t3, 1, draw_in_place       # if the next pixel to the right is FULL, draw in place
     
        li $t3, 0x4af24a
        subi, $s4, $s4, 124
        addi, $s5, $s5, 132
        addi, $s6, $s6, 256
        sw $t3, 0($t7)
        sw $t3, 0($s4)
        sw $t3, 0($s5)
        sw $t3, 0($s6)
        
        li $v0, 31 
        la $a0, 60 
        la $a1, 500
        la $a2, 82
        la $a3, 100
        syscall
        
        li, $t9, 3
        b main1
    
    respond_to_360_s:
        # Checking for 90 rotation collision    
        lw $t1, black
        lw $t2, grey
        li $t3, 0
        check_360_px_2_s:
        lw $s7, 132($s4)
        beq $s7, $t1, check_360_px_3_s
        beq $s7, $t2, check_360_px_3_s
        beq $t3, 0, draw_in_place
        
        check_360_px_3_s:
        lw $s7, 124($s5)
        beq $s7, $t1, check_360_px_4_s
        beq $s7, $t2, check_360_px_4_s
        beq $t3, 0, draw_in_place
        
        check_360_px_4_s:
        lw $s7, -8($s6)
        li $t3, 0
        beq $s7, $t1, load_360_d_s        # if next pixel to right is black, load 1
        beq $s7, $t2, load_360_d_s       # if next pixel to right is grey, load 1
        beq $t3, 0, draw_in_place
        load_360_d_s:
        li $t3, 1
        check_col_360_s:
            bne $t3, 1, draw_in_place       # if the next pixel to the right is FULL, draw in place
     
        li $t3, 0x4af24a
        addi, $s4, $s4, 132
        addi, $s5, $s5, 124
        subi, $s6, $s6, 8
        sw $t3, 0($t7)
        sw $t3, 0($s4)
        sw $t3, 0($s5)
        sw $t3, 0($s6)
        
        li $v0, 31 
        la $a0, 60 
        la $a1, 500
        la $a2, 82
        la $a3, 100
        syscall
        
        li, $t9, 0
        b main1
        
####################################################################################################################
        # ROTATING Z
    respond_to_90_z:
        # Checking for 90 rotation collision    
        lw $t1, black
        lw $t2, grey
        li $t3, 0
        check_90_px_2_z:
        lw $s7, -124($s4)
        beq $s7, $t1, check_90_px_3_z
        beq $s7, $t2, check_90_px_3_z
        beq $t3, 0, draw_in_place
        
        check_90_px_3_z:
        lw $s7, -132($s5)
        beq $s7, $t1, check_90_px_4_z
        beq $s7, $t2, check_90_px_4_z
        beq $t3, 0, draw_in_place
        
        check_90_px_4_z:
        lw $s7, -8($s6)
        li $t3, 0
        beq $s7, $t1, load_90_d_z        # if next pixel to right is black, load 1
        beq $s7, $t2, load_90_d_z       # if next pixel to right is grey, load 1
        beq $t3, 0, draw_in_place
        load_90_d_z:
        li $t3, 1
        check_col_90_z:
            bne $t3, 1, draw_in_place       # if the next pixel to the right is FULL, draw in place
     
        li $t3, 0x75ebd9
        subi, $s4, $s4, 124
        subi, $s5, $s5, 132
        subi, $s6, $s6, 8
        sw $t3, 0($t7)
        sw $t3, 0($s4)
        sw $t3, 0($s5)
        sw $t3, 0($s6)
        
        li $v0, 31 
        la $a0, 60 
        la $a1, 500
        la $a2, 82
        la $a3, 100
        syscall
        
        li, $t9, 1
        b main1
        
    
    respond_to_180_z:
        # Checking for 90 rotation collision    
        lw $t1, black
        lw $t2, grey
        li $t3, 0
        check_180_px_2_z:
        lw $s7, 132($s4)
        beq $s7, $t1, check_180_px_3_z
        beq $s7, $t2, check_180_px_3_z
        beq $t3, 0, draw_in_place
        
        check_180_px_3_z:
        lw $s7, -124($s5)
        beq $s7, $t1, check_180_px_4_z
        beq $s7, $t2, check_180_px_4_z
        beq $t3, 0, draw_in_place
        
        check_180_px_4_z:
        lw $s7, -256($s6)
        li $t3, 0
        beq $s7, $t1, load_180_d_z        # if next pixel to right is black, load 1
        beq $s7, $t2, load_180_d_z       # if next pixel to right is grey, load 1
        beq $t3, 0, draw_in_place
        load_180_d_z:
        li $t3, 1
        check_col_180_z:
            bne $t3, 1, draw_in_place       # if the next pixel to the right is FULL, draw in place
     
        li $t3, 0x75ebd9
        addi, $s4, $s4, 132
        subi, $s5, $s5, 124
        subi, $s6, $s6, 256
        sw $t3, 0($t7)
        sw $t3, 0($s4)
        sw $t3, 0($s5)
        sw $t3, 0($s6)
        
        li $v0, 31 
        la $a0, 60 
        la $a1, 500
        la $a2, 82
        la $a3, 100
        syscall
        
        li, $t9, 2
        b main1
        
        
    respond_to_270_z:
        # Checking for 90 rotation collision    
        lw $t1, black
        lw $t2, grey
        li $t3, 0
        check_270_px_2_z:
        lw $s7, 124($s4)
        beq $s7, $t1, check_270_px_3_z
        beq $s7, $t2, check_270_px_3_z
        beq $t3, 0, draw_in_place
        
        check_270_px_3_z:
        lw $s7, 132($s5)
        beq $s7, $t1, check_270_px_4_z
        beq $s7, $t2, check_270_px_4_z
        beq $t3, 0, draw_in_place
        
        check_270_px_4_z:
        lw $s7, 8($s6)
        li $t3, 0
        beq $s7, $t1, load_270_d_z        # if next pixel to right is black, load 1
        beq $s7, $t2, load_270_d_z       # if next pixel to right is grey, load 1
        beq $t3, 0, draw_in_place
        load_270_d_z:
        li $t3, 1
        check_col_270_z:
            bne $t3, 1, draw_in_place       # if the next pixel to the right is FULL, draw in place
     
        li $t3, 0x75ebd9
        addi, $s4, $s4, 124
        addi, $s5, $s5, 132
        addi, $s6, $s6, 8
        sw $t3, 0($t7)
        sw $t3, 0($s4)
        sw $t3, 0($s5)
        sw $t3, 0($s6)
        
        li $v0, 31 
        la $a0, 60 
        la $a1, 500
        la $a2, 82
        la $a3, 100
        syscall
        
        li, $t9, 3
        b main1
    
    respond_to_360_z:
        # Checking for 90 rotation collision    
        lw $t1, black
        lw $t2, grey
        li $t3, 0
        check_360_px_2_z:
        lw $s7, -132($s4)
        beq $s7, $t1, check_360_px_3_z
        beq $s7, $t2, check_360_px_3_z
        beq $t3, 0, draw_in_place
        
        check_360_px_3_z:
        lw $s7, 124($s5)
        beq $s7, $t1, check_360_px_4_z
        beq $s7, $t2, check_360_px_4_z
        beq $t3, 0, draw_in_place
        
        check_360_px_4_z:
        lw $s7, 256($s6)
        li $t3, 0
        beq $s7, $t1, load_360_d_z        # if next pixel to right is black, load 1
        beq $s7, $t2, load_360_d_z       # if next pixel to right is grey, load 1
        beq $t3, 0, draw_in_place
        load_360_d_z:
        li $t3, 1
        check_col_360_z:
            bne $t3, 1, draw_in_place       # if the next pixel to the right is FULL, draw in place
     
        li $t3, 0x75ebd9
        subi, $s4, $s4, 132
        addi, $s5, $s5, 124
        addi, $s6, $s6, 256
        sw $t3, 0($t7)
        sw $t3, 0($s4)
        sw $t3, 0($s5)
        sw $t3, 0($s6)
        
        li $v0, 31 
        la $a0, 60 
        la $a1, 500
        la $a2, 82
        la $a3, 100
        syscall
        
        li, $t9, 0
        b main1
        
####################################################################################################################
        # ROTATING L
    respond_to_90_l:
        # Checking for 90 rotation collision    
        lw $t1, black
        lw $t2, grey
        li $t3, 0
        check_90_px_2_l:
        lw $s7, -132($s4)
        beq $s7, $t1, check_90_px_3_l
        beq $s7, $t2, check_90_px_3_l
        beq $t3, 0, draw_in_place
        
        check_90_px_3_l:
        lw $s7, -264($s5)
        beq $s7, $t1, check_90_px_4_l
        beq $s7, $t2, check_90_px_4_l
        beq $t3, 0, draw_in_place
        
        check_90_px_4_l:
        lw $s7, -140($s6)
        li $t3, 0
        beq $s7, $t1, load_90_d_l        # if next pixel to right is black, load 1
        beq $s7, $t2, load_90_d_l       # if next pixel to right is grey, load 1
        beq $t3, 0, draw_in_place
        load_90_d_l:
        li $t3, 1
        check_col_90_l:
            bne $t3, 1, draw_in_place       # if the next pixel to the right is FULL, draw in place
     
        li $t3, 0x7676f5
        subi, $s4, $s4, 132
        subi, $s5, $s5, 264
        subi, $s6, $s6, 140
        sw $t3, 0($t7)
        sw $t3, 0($s4)
        sw $t3, 0($s5)
        sw $t3, 0($s6)
        
        li $v0, 31 
        la $a0, 60 
        la $a1, 500
        la $a2, 82
        la $a3, 100
        syscall
        
        li, $t9, 1
        b main1
        
    
    respond_to_180_l:
        # Checking for 90 rotation collision    
        lw $t1, black
        lw $t2, grey
        li $t3, 0
        check_180_px_2_l:
        lw $s7, -124($s4)
        beq $s7, $t1, check_180_px_3_l
        beq $s7, $t2, check_180_px_3_l
        beq $t3, 0, draw_in_place
        
        check_180_px_3_l:
        lw $s7, -248($s5)
        beq $s7, $t1, check_180_px_4_l
        beq $s7, $t2, check_180_px_4_l
        beq $t3, 0, draw_in_place
        
        check_180_px_4_l:
        lw $s7, -380($s6)
        li $t3, 0
        beq $s7, $t1, load_180_d_l        # if next pixel to right is black, load 1
        beq $s7, $t2, load_180_d_l       # if next pixel to right is grey, load 1
        beq $t3, 0, draw_in_place
        load_180_d_l:
        li $t3, 1
        check_col_180_l:
            bne $t3, 1, draw_in_place       # if the next pixel to the right is FULL, draw in place
     
        li $t3, 0x7676f5
        subi, $s4, $s4, 124
        subi, $s5, $s5, 248
        subi, $s6, $s6, 380
        sw $t3, 0($t7)
        sw $t3, 0($s4)
        sw $t3, 0($s5)
        sw $t3, 0($s6)
        
        li $v0, 31 
        la $a0, 60 
        la $a1, 500
        la $a2, 82
        la $a3, 100
        syscall
        
        li, $t9, 2
        b main1
        
        
    respond_to_270_l:
        # Checking for 90 rotation collision    
        lw $t1, black
        lw $t2, grey
        li $t3, 0
        check_270_px_2_l:
        lw $s7, 132($s4)
        beq $s7, $t1, check_270_px_3_l
        beq $s7, $t2, check_270_px_3_l
        beq $t3, 0, draw_in_place
        
        check_270_px_3_l:
        lw $s7, 264($s5)
        beq $s7, $t1, check_270_px_4_l
        beq $s7, $t2, check_270_px_4_l
        beq $t3, 0, draw_in_place
        
        check_270_px_4_l:
        lw $s7, 140($s6)
        li $t3, 0
        beq $s7, $t1, load_270_d_l        # if next pixel to right is black, load 1
        beq $s7, $t2, load_270_d_l       # if next pixel to right is grey, load 1
        beq $t3, 0, draw_in_place
        load_270_d_l:
        li $t3, 1
        check_col_270_l:
            bne $t3, 1, draw_in_place       # if the next pixel to the right is FULL, draw in place
     
        li $t3, 0x7676f5
        addi, $s4, $s4, 132
        addi, $s5, $s5, 264
        addi, $s6, $s6, 140
        sw $t3, 0($t7)
        sw $t3, 0($s4)
        sw $t3, 0($s5)
        sw $t3, 0($s6)
        
        li $v0, 31 
        la $a0, 60 
        la $a1, 500
        la $a2, 82
        la $a3, 100
        syscall
        
        li, $t9, 3
        b main1
    
    respond_to_360_l:
        # Checking for 90 rotation collision    
        lw $t1, black
        lw $t2, grey
        li $t3, 0
        check_360_px_2_l:
        lw $s7, 124($s4)
        beq $s7, $t1, check_360_px_3_l
        beq $s7, $t2, check_360_px_3_l
        beq $t3, 0, draw_in_place
        
        check_360_px_3_l:
        lw $s7, 248($s5)
        beq $s7, $t1, check_360_px_4_l
        beq $s7, $t2, check_360_px_4_l
        beq $t3, 0, draw_in_place
        
        check_360_px_4_l:
        lw $s7, 380($s6)
        li $t3, 0
        beq $s7, $t1, load_360_d_l        # if next pixel to right is black, load 1
        beq $s7, $t2, load_360_d_l       # if next pixel to right is grey, load 1
        beq $t3, 0, draw_in_place
        load_360_d_l:
        li $t3, 1
        check_col_360_l:
            bne $t3, 1, draw_in_place       # if the next pixel to the right is FULL, draw in place
     
        li $t3, 0x7676f5
        addi, $s4, $s4, 124
        addi, $s5, $s5, 248
        addi, $s6, $s6, 380
        sw $t3, 0($t7)
        sw $t3, 0($s4)
        sw $t3, 0($s5)
        sw $t3, 0($s6)
        
        li $v0, 31 
        la $a0, 60 
        la $a1, 500
        la $a2, 82
        la $a3, 100
        syscall
        
        li, $t9, 0
        b main1
    
##################################################################################################################################################
        # ROTATING J
    respond_to_90_j:
        # Checking for 90 rotation collision    
        lw $t1, black
        lw $t2, grey
        li $t3, 0
        check_90_px_2_j:
        lw $s7, -132($s4)
        beq $s7, $t1, check_90_px_3_j
        beq $s7, $t2, check_90_px_3_j
        beq $t3, 0, draw_in_place
        
        check_90_px_3_j:
        lw $s7, -264($s5)
        beq $s7, $t1, check_90_px_4_j
        beq $s7, $t2, check_90_px_4_j
        beq $t3, 0, draw_in_place
        
        check_90_px_4_j:
        lw $s7, -388($s6)
        li $t3, 0
        beq $s7, $t1, load_90_d_j        # if next pixel to right is black, load 1
        beq $s7, $t2, load_90_d_j       # if next pixel to right is grey, load 1
        beq $t3, 0, draw_in_place
        load_90_d_j:
        li $t3, 1
        check_col_90_j:
            bne $t3, 1, draw_in_place       # if the next pixel to the right is FULL, draw in place
     
        li $t3, 0xc184f0
        subi, $s4, $s4, 132
        subi, $s5, $s5, 264
        subi, $s6, $s6, 388
        sw $t3, 0($t7)
        sw $t3, 0($s4)
        sw $t3, 0($s5)
        sw $t3, 0($s6)
        
        li $v0, 31 
        la $a0, 60 
        la $a1, 500
        la $a2, 82
        la $a3, 100
        syscall
        
        li, $t9, 1
        b main1
        
    
    respond_to_180_j:
        # Checking for 90 rotation collision    
        lw $t1, black
        lw $t2, grey
        li $t3, 0
        check_180_px_2_j:
        lw $s7, -124($s4)
        beq $s7, $t1, check_180_px_3_j
        beq $s7, $t2, check_180_px_3_j
        beq $t3, 0, draw_in_place
        
        check_180_px_3_j:
        lw $s7, -248($s5)
        beq $s7, $t1, check_180_px_4_j
        beq $s7, $t2, check_180_px_4_j
        beq $t3, 0, draw_in_place
        
        check_180_px_4_j:
        lw $s7, -116($s6)
        li $t3, 0
        beq $s7, $t1, load_180_d_j        # if next pixel to right is black, load 1
        beq $s7, $t2, load_180_d_j       # if next pixel to right is grey, load 1
        beq $t3, 0, draw_in_place
        load_180_d_j:
        li $t3, 1
        check_col_180_j:
            bne $t3, 1, draw_in_place       # if the next pixel to the right is FULL, draw in place
     
        li $t3, 0xc184f0
        subi, $s4, $s4, 124
        subi, $s5, $s5, 248
        subi, $s6, $s6, 116
        sw $t3, 0($t7)
        sw $t3, 0($s4)
        sw $t3, 0($s5)
        sw $t3, 0($s6)
        
        li $v0, 31 
        la $a0, 60 
        la $a1, 500
        la $a2, 82
        la $a3, 100
        syscall
        
        li, $t9, 2
        b main1
        
        
    respond_to_270_j:
        # Checking for 90 rotation collision    
        lw $t1, black
        lw $t2, grey
        li $t3, 0
        check_270_px_2_j:
        lw $s7, 132($s4)
        beq $s7, $t1, check_270_px_3_j
        beq $s7, $t2, check_270_px_3_j
        beq $t3, 0, draw_in_place
        
        check_270_px_3_j:
        lw $s7, 264($s5)
        beq $s7, $t1, check_270_px_4_j
        beq $s7, $t2, check_270_px_4_j
        beq $t3, 0, draw_in_place
        
        check_270_px_4_j:
        lw $s7, 388($s6)
        li $t3, 0
        beq $s7, $t1, load_270_d_j        # if next pixel to right is black, load 1
        beq $s7, $t2, load_270_d_j       # if next pixel to right is grey, load 1
        beq $t3, 0, draw_in_place
        load_270_d_j:
        li $t3, 1
        check_col_270_j:
            bne $t3, 1, draw_in_place       # if the next pixel to the right is FULL, draw in place
     
        li $t3, 0xc184f0
        addi, $s4, $s4, 132
        addi, $s5, $s5, 264
        addi, $s6, $s6, 388
        sw $t3, 0($t7)
        sw $t3, 0($s4)
        sw $t3, 0($s5)
        sw $t3, 0($s6)
        
        li $v0, 31 
        la $a0, 60 
        la $a1, 500
        la $a2, 82
        la $a3, 100
        syscall
        
        li, $t9, 3
        b main1
    
    respond_to_360_j:
        # Checking for 90 rotation collision    
        lw $t1, black
        lw $t2, grey
        li $t3, 0
        check_360_px_2_j:
        lw $s7, 124($s4)
        beq $s7, $t1, check_360_px_3_j
        beq $s7, $t2, check_360_px_3_j
        beq $t3, 0, draw_in_place
        
        check_360_px_3_j:
        lw $s7, 248($s5)
        beq $s7, $t1, check_360_px_4_j
        beq $s7, $t2, check_360_px_4_j
        beq $t3, 0, draw_in_place
        
        check_360_px_4_j:
        lw $s7, 116($s6)
        li $t3, 0
        beq $s7, $t1, load_360_d_j        # if next pixel to right is black, load 1
        beq $s7, $t2, load_360_d_j       # if next pixel to right is grey, load 1
        beq $t3, 0, draw_in_place
        load_360_d_j:
        li $t3, 1
        check_col_360_j:
            bne $t3, 1, draw_in_place       # if the next pixel to the right is FULL, draw in place
     
        li $t3, 0xc184f0
        addi, $s4, $s4, 124
        addi, $s5, $s5, 248
        addi, $s6, $s6, 116
        sw $t3, 0($t7)
        sw $t3, 0($s4)
        sw $t3, 0($s5)
        sw $t3, 0($s6)
        
        li $v0, 31 
        la $a0, 60 
        la $a1, 500
        la $a2, 82
        la $a3, 100
        syscall
        
        li, $t9, 0
        b main1
        
####################################################################################################################
    # ROTATING T
    respond_to_90_t:
        # Checking for 90 rotation collision    
        lw $t1, black
        lw $t2, grey
        li $t3, 0
        check_90_px_2_t:
        lw $s7, -124($s4)
        beq $s7, $t1, check_90_px_3_t
        beq $s7, $t2, check_90_px_3_t
        beq $t3, 0, draw_in_place
        
        check_90_px_3_t:
        lw $s7, 124($s5)
        beq $s7, $t1, check_90_px_4_t
        beq $s7, $t2, check_90_px_4_t
        beq $t3, 0, draw_in_place
        
        check_90_px_4_t:
        lw $s7, -132($s6)
        li $t3, 0
        beq $s7, $t1, load_90_d_t        # if next pixel to right is black, load 1
        beq $s7, $t2, load_90_d_t       # if next pixel to right is grey, load 1
        beq $t3, 0, draw_in_place
        load_90_d_t:
        li $t3, 1
        check_col_90_t:
            bne $t3, 1, draw_in_place       # if the next pixel to the right is FULL, draw in place
     
        li $t3, 0xf76f9a
        subi, $s4, $s4, 124
        addi, $s5, $s5, 124
        subi, $s6, $s6, 132
        sw $t3, 0($t7)
        sw $t3, 0($s4)
        sw $t3, 0($s5)
        sw $t3, 0($s6)
        
        li $v0, 31 
        la $a0, 60 
        la $a1, 500
        la $a2, 82
        la $a3, 100
        syscall
        
        li, $t9, 1
        b main1
        
    
    respond_to_180_t:
        # Checking for 90 rotation collision    
        lw $t1, black
        lw $t2, grey
        li $t3, 0
        check_180_px_2_t:
        lw $s7, 132($s4)
        beq $s7, $t1, check_180_px_3_t
        beq $s7, $t2, check_180_px_3_t
        beq $t3, 0, draw_in_place
        
        check_180_px_3_t:
        lw $s7, -132($s5)
        beq $s7, $t1, check_180_px_4_t
        beq $s7, $t2, check_180_px_4_t
        beq $t3, 0, draw_in_place
        
        check_180_px_4_t:
        lw $s7, -124($s6)
        li $t3, 0
        beq $s7, $t1, load_180_d_t        # if next pixel to right is black, load 1
        beq $s7, $t2, load_180_d_t       # if next pixel to right is grey, load 1
        beq $t3, 0, draw_in_place
        load_180_d_t:
        li $t3, 1
        check_col_180_t:
            bne $t3, 1, draw_in_place       # if the next pixel to the right is FULL, draw in place
     
        li $t3, 0xf76f9a
        addi, $s4, $s4, 132
        subi, $s5, $s5, 132
        subi, $s6, $s6, 124
        sw $t3, 0($t7)
        sw $t3, 0($s4)
        sw $t3, 0($s5)
        sw $t3, 0($s6)
        
        li $v0, 31 
        la $a0, 60 
        la $a1, 500
        la $a2, 82
        la $a3, 100
        syscall
        
        li, $t9, 2
        b main1
        
        
    respond_to_270_t:
        # Checking for 90 rotation collision    
        lw $t1, black
        lw $t2, grey
        li $t3, 0
        check_270_px_2_t:
        lw $s7, 124($s4)
        beq $s7, $t1, check_270_px_3_t
        beq $s7, $t2, check_270_px_3_t
        beq $t3, 0, draw_in_place
        
        check_270_px_3_t:
        lw $s7, -124($s5)
        beq $s7, $t1, check_270_px_4_t
        beq $s7, $t2, check_270_px_4_t
        beq $t3, 0, draw_in_place
        
        check_270_px_4_t:
        lw $s7, 132($s6)
        li $t3, 0
        beq $s7, $t1, load_270_d_t        # if next pixel to right is black, load 1
        beq $s7, $t2, load_270_d_t       # if next pixel to right is grey, load 1
        beq $t3, 0, draw_in_place
        load_270_d_t:
        li $t3, 1
        check_col_270_t:
            bne $t3, 1, draw_in_place       # if the next pixel to the right is FULL, draw in place
     
        li $t3, 0xf76f9a
        addi, $s4, $s4, 124
        subi, $s5, $s5, 124
        addi, $s6, $s6, 132
        sw $t3, 0($t7)
        sw $t3, 0($s4)
        sw $t3, 0($s5)
        sw $t3, 0($s6)
        
        li $v0, 31 
        la $a0, 60 
        la $a1, 500
        la $a2, 82
        la $a3, 100
        syscall
        
        li, $t9, 3
        b main1
    
    respond_to_360_t:
        # Checking for 90 rotation collision    
        lw $t1, black
        lw $t2, grey
        li $t3, 0
        check_360_px_2_t:
        lw $s7, -132($s4)
        beq $s7, $t1, check_360_px_3_t
        beq $s7, $t2, check_360_px_3_t
        beq $t3, 0, draw_in_place
        
        check_360_px_3_t:
        lw $s7, 132($s5)
        beq $s7, $t1, check_360_px_4_t
        beq $s7, $t2, check_360_px_4_t
        beq $t3, 0, draw_in_place
        
        check_360_px_4_t:
        lw $s7, 124($s6)
        li $t3, 0
        beq $s7, $t1, load_360_d_t        # if next pixel to right is black, load 1
        beq $s7, $t2, load_360_d_t       # if next pixel to right is grey, load 1
        beq $t3, 0, draw_in_place
        load_360_d_t:
        li $t3, 1
        check_col_360_t:
            bne $t3, 1, draw_in_place       # if the next pixel to the right is FULL, draw in place
     
        li $t3, 0xf76f9a
        subi, $s4, $s4, 132
        addi, $s5, $s5, 132
        addi, $s6, $s6, 124
        sw $t3, 0($t7)
        sw $t3, 0($s4)
        sw $t3, 0($s5)
        sw $t3, 0($s6)
        
        li $v0, 31 
        la $a0, 60 
        la $a1, 500
        la $a2, 82
        la $a3, 100
        syscall
        
        li, $t9, 0
        b main1


























####################################################################################################################################################################
# END OF CODE
####################################################################################################################################################################
game_loop:
	# 1a. Check if key has been pressed
    # 1b. Check which key has been pressed
    # 2a. Check for collisions
	# 2b. Update locations (paddle, ball)
	# 3. Draw the screen
	# 4. Sleep

    #5. Go back to 1
    # b game_loop

#  Add code here to "quit elegantly"