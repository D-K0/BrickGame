################ CSC258H1F Fall 2022 Assembly Final Project ##################
 # This file contains our implementation of Breakout.
 #
 # Student 1: Arsal Khan, 1008295505
 # Student 2: Diana Korotun, 1006868828
 ######################## Bitmap Display Configuration ########################
 # - Unit width in pixels:       1
 # - Unit height in pixels:      1
 # - Display width in pixels:    16
 # - Display height in pixels:   16
 # - Base Address for Display:   0x10008000 ($gp)
 ##############################################################################

     .data
 ##############################################################################
 # Immutable Data
 ##############################################################################

 displayAddress:    .word 0x10008000    # The address of the bitmap display.

 ADDR_KBRD:         .word 0xffff0000    # The address of the keyboard. Don't forget to connect it!
 SLEEP_TIME:        .word 425           # number of millisecond for sleep

                                        # PLANK initial parameters
 PLANK_WIDTH:       .word 3
 PLANK_HEIGHT:      .word 1
 PLANK_COLOUR:      .word 0xa0cacd
 PLANK_X:           .word 7
 PLANK_Y:           .word 15

                                         # BALL initial parameters
 BALL_WIDTH:         .word 1
 BALL_HEIGHT:        .word 1
 BALL_COLOUR:        .word 0xffffff
 BALL_X:             .word 9
 BALL_Y:             .word 13

                                         # BRICK initial parameters
 BRICK_WIDTH:        .word 2
 BRICK_HEIGHT:       .word 1
 BRICK1_COLOR:       .word 0x35a0ff      # bricks' colours by row
 BRICK2_COLOR:       .word 0x8851D0
 BRICK3_COLOR:       .word 0x29CAAB
 BRICK_COL1:         .word 4             # bricks' x location by comumn
 BRICK_COL2:         .word 7
 BRICK_COL3:         .word 10
 BRICK_ROW1:         .word 6              # bricks' y location by comumn
 BRICK_ROW2:         .word 8
 BRICK_ROW3:         .word 10

                                         # WALL initial parameters
 WALL_COLOUR:         .word 0xdadada
                                         # left wall
 WALL_LEFT_WIDTH:     .word 2
 WALL_LEFT_HEIGHT:    .word 16
 WALL_LEFT_X:         .word 0
 WALL_LEFT_Y:         .word 0
                                         # right wall
 WALL_RIGHT_WIDTH:    .word 2
 WALL_RIGHT_HEIGHT:   .word 16
 WALL_RIGHT_X:        .word 14
 WALL_RIGHT_Y:        .word 0
                                         # horizontal wall
 WALL_HORIZ_WIDTH:    .word 16
 WALL_HORIZ_HEIGHT:   .word 1
 WALL_HORIZ_X:        .word 0
 WALL_HORIZ_Y:        .word 3

                                         # COLOURS
 BLACK_COLOUR:         .word 0x000000
 PLANK_DECIMAL_COLOUR: .word 10537677
 WALL_DECIMAL_COLOUR:  .word 14342874

                                         # Home screen colours
 LEVEL_COLOUR:         .word 0x35a0ff
 LINE_COLOUR:          .word 0xa0cacd
 RATE_COLOUR:          .word 0x8851D0
 SCORE_COLOR:          .word 0x29CAAB

 TALLY_COLOUR:         .word 0xA4CDEE
 TALLY_WIDTH:          .word 1
 TALLY_HEIGHT:         .word 1
 TALLY_X:              .word 4
 TALLY_Y:              .word 1



 ##############################################################################
 # Mutable Data
 ##############################################################################

 BALL:
 	                  .space 8	       #reserve space for x and y coords of ball #0(t0) -> x  4(t0) -> y
 	                  .space 8   	   #reserve space for x and y direction of ball
 	                  
 ball_flag:            .word -1        # make it so the ball moves every other loop

 PLANK:
 	                  .space 8	       # reserving space for the x and y coordinate of plank
 	                  .space 4         # reserving space for direction

 CURR_SCORE:           .word 0		   # stores current score, set to 0 in the beginning

 PAST_SCORE:           .space 12    

 ##############################################################################
 # Code
 ##############################################################################
 .text
 .globl main

 	# Run the Brick Breaker game.
 main:
     jal set_history                       
     main_loop:
         jal initialize_var
         jal update_history
         jal short_sleep
         jal draw_black_screen
         jal draw_home_screen # may have problems with initial home_screen being drawn, should move to right before main_loop
         jal keyboard_input              # call keyboard
         beq $v1, 0x71, quit     # Check if the key q was pressed
         #check level
         beq $v1, 0x31, draw_game1     # Check if the key 1 was pressed
         beq $v1, 0x32, draw_game2     # Check if the key 2 was pressed
         b main_loop

     draw_game1: #level 1
         li $t5, 1
         jal draw_black_screen #clear screen
         jal draw_start_game_screen
         j game_loop

     draw_game2: #level 2
         li $t5, 2
         jal draw_black_screen #clear screen
         jal draw_start_game_screen
         j game_loop

     jal quit

 game_loop:
 	# 1a. Check if key has been pressed & Check which key has been pressed
     jal check_kbrd_input
     # 2a. Check for collisions
     jal detect_collision                           
     # *. erase old elements (paddle, ball)
     jal erase_ball
     jal erase_plank
 	# 2b. Update locations (paddle, ball)
 	jal refresh_ball 
 	jal refresh_plank	
 	# 3. Draw the screen
 	jal draw_ball
 	jal draw_plank
 	jal draw_tally
 	# 4. Sleep
     jal sleep
     #5. Go back to 1
     b game_loop

 check_kbrd_input:
     addi $sp, $sp, -4    #allocate one space
     sw $ra, 0($sp)        # put ra to main in the allocate space

     jal keyboard_input              # call keyboard
     bne $v0, 1, exit_key_input

     beq $v1, 0x71, quit     # Check if the key q was pressed
     beq $v1, 0x70, pause     # if pause if p is pressed. unpause if o is pressed
     exit_pause:
     beq $v1, 0x6d, menu    # go to menu if m is pressed
     beq $v1, 0x61, move_plate_left    # if a was pressed
     beq $v1, 0x64, move_plate_right    # if d was pressed

     exit_key_input:

     lw $ra, 0($sp)                    #get ra to main from the stack
     addi $sp, $sp, 4                    # Increment the stack pointer to delocate space for the return address
     jr $ra			            # return to the calling program

 ##########################################################################
 # User actions
 ##########################################################################

 quit:                                
 	li $v0, 10                      # Quit gracefully
 	syscall

 keyboard_input:                     # got from the starting package
     addi $sp, $sp, -4                # allocate one space
     sw $a0, 0($sp)                    # put ra to main in the allocate space

     lw $t0, ADDR_KBRD               # $t0 = base address for keyboard
     lw $v0, 0($t0)                  # Load first word from keyboard
     lw $v1, 4($t0)                  # Load second word from keyboard

     lw $a0, 0($sp)                    #get ra to main from the stack
     addi $sp, $sp, 4                    # Increment the stack pointer to delocate space for the return address
     jr $ra

 menu:    
     jal update_history                
     j main_loop

 pause:
     jal short_sleep   
     jal keyboard_input              # call keyboard
     bne $v0, 1, pause      # check if key has been pressed   
     beq $v1, 0x71, quit    # go to quit if q is pressed 
     beq $v1, 0x6d, menu    # go to menu if m is pressed
     beq $v1, 0x70, exit_pause  
     j pause

 move_plate_right: 
         la $t0, PLANK
         lw $t1, 8($t0)		# get x direction from plank
     	addi $t1, $t1, 1	# update x direction
 	    sw $t1, 8($t0)		# store the updated direction of the ball into memory
         j exit_key_input

 move_plate_left: 
         la $t0, PLANK
         lw $t1, 8($t0)		# get x direction from plank
     	addi $t1, $t1, -1	# update x direction
 	    sw $t1, 8($t0)		# store the updated direction of the ball into memory
         j exit_key_input

 ##########################################################################
 # program actions (often used)
 ##########################################################################

 find_address:
     lw $t0, displayAddress      # Load display base address into $t0
     mul $t2, $a0, 4             # coord_x = a0 * 4
     mul $t3, $a1, 64            # coord_y = a1 * (16*4=64) 
     addu $t4, $t2, $t3          # get then x y address
     addu $v0, $t0, $t4          # assign the new x y coordinates
     jr $ra			             # return to the calling program

 sleep: 
     addi $sp, $sp, -4    # allocate one space
     sw $a0, 0($sp)        # put ra to main in the allocate space
     addi $sp, $sp, -4    # allocate one space
     sw $v0, 0($sp)        # put ra to main in the allocate space

     li $v0, 32                # 32 is the value in the syscall corresponding to sleep
     lw $a0, SLEEP_TIME              # number of milisec. 1000 would change every second. 42 would change every 1/24 second
     syscall

     lw $v0, 0($sp)                    # get ra to main from the stack
     addi $sp, $sp, 4                    # Increment the stack pointer to delocate space for the return address
     lw $a0, 0($sp)                    # get ra to main from the stack
     addi $sp, $sp, 4                    # Increment the stack pointer to delocate space for the return address
     jr $ra			            # return to the calling program

 short_sleep:
     addi $sp, $sp, -4    # allocate one space
     sw $a0, 0($sp)        # put ra to main in the allocate space
     addi $sp, $sp, -4    # allocate one space
     sw $v0, 0($sp)        # put ra to main in the allocate space

     li $v0, 32                # 32 is the value in the syscall corresponding to sleep
     li $a0, 1              # number of milisec. 1000 would change every second. 42 would change every 1/24 second
     syscall

     lw $v0, 0($sp)                    # get ra to main from the stack
     addi $sp, $sp, 4                    # Increment the stack pointer to delocate space for the return address
     lw $a0, 0($sp)                    # get ra to main from the stack
     addi $sp, $sp, 4                    # Increment the stack pointer to delocate space for the return address
     jr $ra

 sleep_2: 
     addi $sp, $sp, -4    # allocate one space
     sw $a0, 0($sp)        # put ra to main in the allocate space
     addi $sp, $sp, -4    # allocate one space
     sw $v0, 0($sp)        # put ra to main in the allocate space


     li $v0, 32                # 32 is the value in the syscall corresponding to sleep
     lw $a0, SLEEP_TIME              # number of milisec. 1000 would change every second. 42 would change every 1/24 second
     lw $a3, SLEEP_TIME # trying out a3 instead, revert back to a0 if doesnt work
     syscall

     lw $v0, 0($sp)                    # get ra to main from the stack
     addi $sp, $sp, 4                    # Increment the stack pointer to delocate space for the return address
     lw $a0, 0($sp)                    # get ra to main from the stack
     addi $sp, $sp, 4                    # Increment the stack pointer to delocate space for the return address
     jr $ra			            # return to the calling program

 draw_rect:                    # got it from the provided in class example (on Piazza we were given explicit permision to use it)
     add $t0, $zero, $a0     # Put drawing location into $t0
     add $t1, $zero, $a2		# Put the height into $t1
     add $t2, $zero, $a1		# Put the width into $t2
     add $t3, $zero, $a3		# Put the colour into $t3

     outer_loop:
     beq $t1, $zero, end_outer_loop	# if the height variable is zero, then jump to the end.

     # draw a line
     inner_loop:
     beq $t2, $zero, end_inner_loop	# if the width variable is zero, jump to the end of the inner loop
     sw $t3, 0($t0)			# draw a pixel at the current location.
     addi $t0, $t0, 4		# move the current drawing location to the right.
     addi $t2, $t2, -1		# decrement the width variable
     j inner_loop			# repeat the inner loop
     end_inner_loop:

     addi $t1, $t1, -1		# decrement the height variable
     add $t2, $zero, $a1		# reset the width variable to $a1
     # reset the current drawing location to the first pixel of the next line.
     addi $t0, $t0, 64		# move $t0 to the next line
     sll $t4, $t2, 2			# convert $t2 into bytes
     sub $t0, $t0, $t4		# move $t0 to the first pixel to draw in this line.
     j outer_loop			# jump to the beginning of the outer loop

     end_outer_loop:			# the end of the rectangle drawing
     jr $ra			# return to the calling program

 ##########################################################################
 # Clear screen
 ##########################################################################

 draw_black_screen:
     # Save return address to draw to the stack
     addi $sp, $sp, -4                    # Decrement the stack pointer to allocate space for the return address
     sw $ra, 0($sp)                    #put ra to main in the allocate space/ # Store the return address to the top of the stack (at offset 0)

     li $a0, 0                  # x0 coordinate
     li $a1, 0                 # y0 coordinate
     jal find_address            # find the (x,y) address
     move $a0, $v0               # move the return value from $v0 to $a0 
     li $a1,  16        # width of screen
     li $a2,  16        # height of screen
     lw $a3,  BLACK_COLOUR  #colour
     jal draw_rect    # Call the draw_rect function			   

      # load return address to draw
     lw $ra, 0($sp)                    # get ra to main from the stack
     addi $sp, $sp, 4                    # Increment the stack pointer to delocate space for the return address
     jr $ra			            # return to the calling program




 ##########################################################################
 # program actions (in game)
 ##########################################################################

  draw_plank:
     # Save return address to draw
     addi $sp, $sp, -4                # allocate one sapce
     sw $ra, 0($sp)                    # put ra to main in the allocate space

     la $t0, PLANK
 	lw $a0, 0($t0)		# get x from plank
 	lw $a1, 4($t0)    # get y from plank
     jal find_address            # find the (x,y) address
     move $a0, $v0               # move the return value from $v0 to $t0 
     lw $a1, PLANK_WIDTH         # width
     lw $a2, PLANK_HEIGHT         # height
     lw $a3, PLANK_COLOUR   # colour
     jal draw_rect    # Call the draw_rect function			   

      # load return address to draw
     lw $ra, 0($sp)                    # get ra to main from the stack
     addi $sp, $sp, 4                    # delocate stpace
     jr $ra			            # return to the calling program


 erase_plank:
     # Save return address to draw
     addi $sp, $sp, -4                # allocate one sapce
     sw $ra, 0($sp)                    # put ra to main in the allocate space

     la $t0, PLANK
 	lw $a0, 0($t0)		# get x from plank
 	lw $a1, 4($t0)    # get y from plank

     #PLANK
     #lw $a0, PLANK_X                   # x0 coordinate
     #lw $a1, PLANK_Y                  # y0 coordinate
     jal find_address            # find the (x,y) address
     move $a0, $v0               # move the return value from $v0 to $t0 
     lw $a1, PLANK_WIDTH         # width
     lw $a2, PLANK_HEIGHT         #height
     li $a3, 0x000000   #colour
     jal draw_rect    # Call the draw_rect function			   

      # load return address to draw
     lw $ra, 0($sp)                    #get ra to main from the stack
     addi $sp, $sp, 4                    #delocate stpace
     jr $ra			            # return to the calling program

 refresh_plank:
     addi $sp, $sp, -4                # allocate one sapce
     sw $ra, 0($sp)                    #put ra to main in the allocate space

 	la $t0, PLANK
 	lw $t1, 0($t0)		# get x from plank
 	lw $t3, 8($t0)		# get x direction from plank

 	add $t1, $t1, $t3	# update coords x cooredinates
 	sw $t1, 0($t0)		# store the updated coords of the ball into memory
 	sw $zero, 8($t0)    # reset the direction of plank      

 	lw $t1, 8($t0)

 	lw $ra, 0($sp)                    #get ra to main from the stack
     addi $sp, $sp, 4                    #delocate stpace
     jr $ra			            # return to the calling program

 draw_ball:
     # Save return address to draw
     addi $sp, $sp, -4                # allocate one sapce
     sw $ra, 0($sp)                    #put ra to main in the allocate space


     la $t0, BALL
 	lw $a0, 0($t0)		# get x from ball
 	lw $a1, 4($t0)

 	#BALL
     # lw $a0, BALL_X                  # x0 coordinate
     # lw $a1, BALL_Y                  # y0 coordinate
     jal find_address            # find the (x,y) address
     move $a0, $v0               # move the return value from $v0 to $t0
     lw $a1, BALL_WIDTH          # width
     lw $a2, BALL_HEIGHT         # height
     lw $a3, BALL_COLOUR   # colour
     jal draw_rect    # Call the draw_rect function		   

      # load return address to draw
     lw $ra, 0($sp)                    # get ra to main from the stack
     addi $sp, $sp, 4                  # delocate stpace
     jr $ra			            # return to the calling program

     #li $v0, 32                # 32 is the value in the syscall corresponding to sleep
     #li $a0, 1              # number of milisec. 1000 would chamge every second. 42 would change every 1/24 second
     #syscall
     #jr $ra 

 erase_ball:
     # Save return address to draw
     addi $sp, $sp, -4                # allocate one sapce
     sw $ra, 0($sp)                    #put ra to main in the allocate space


     la $t0, BALL
 	lw $a0, 0($t0)		# get x from ball
 	lw $a1, 4($t0)

 	#BALL
     # lw $a0, BALL_X                  # x0 coordinate
     # lw $a1, BALL_Y                  # y0 coordinate
     jal find_address            # find the (x,y) address
     move $a0, $v0               # move the return value from $v0 to $t0
     lw $a1, BALL_WIDTH         # width
     lw $a2, BALL_HEIGHT         # height
     li $a3, 0x000000   #colour
     jal draw_rect    # Call the draw_rect function		   

      # load return address to draw
     lw $ra, 0($sp)                    #get ra to main from the stack
     addi $sp, $sp, 4                    # delocate stpace
     jr $ra			            # return to the calling program

     #li $v0, 32                # 32 is the value in the syscall corresponding to sleep
     #li $a0, 1              # number of milisec. 1000 would chamge every second. 42 would change every 1/24 second
     #syscall
     #jr $ra 

 refresh_ball:
     addi $sp, $sp, -4                # allocate one sapce
     sw $ra, 0($sp)                    # put ra to main in the allocate space

 	la $t0, BALL
 	lw $t1, 0($t0)		# get x from ball
 	lw $t2, 4($t0)		# get y from ball
 	lw $t3, 8($t0)		# get x direction from ball
 	lw $t4, 12($t0)		# get y direction from ball

 	add $t1, $t1, $t3	# update coords (x + x direction)
 	add $t2, $t2, $t4	# (y + y direction)
 	sw $t1, 0($t0)		# store the updated coords of the ball into memory
 	sw $t2, 4($t0)

 	lw $ra, 0($sp)                    #get ra to main from the stack
     addi $sp, $sp, 4                    #delocate stpace
     jr $ra			            # return to the calling program

 draw_tally:
     # Save return address to brick
     addi $sp, $sp, -4                # allocate one sapce
     sw $ra, 0($sp)                    #put ra to main in the allocate space

     lw $a0, TALLY_X                  # x0 coordinate
     lw $a1, TALLY_Y                  # y0 coordinate
     jal find_address            # find the (x,y) address
     move $a0, $v0               # move the return value from $v0 to $t0
     lw $a1, CURR_SCORE         # width
     lw $a2, TALLY_HEIGHT         #height
     lw $a3, TALLY_COLOUR   #colour
     jal draw_rect    # Call the draw_rect function		   

      # load return address to brick
     lw $ra, 0($sp)                    # get ra to main from the stack
     addi $sp, $sp, 4                    # delocate stpace
     jr $ra			            # return to the calling program

 ##########################################################################
 # COLLISION HANDELING
 ##########################################################################

 detect_collision:
     # check collision of walls and plank first
     # then check collision of brick

     # Save return address to draw
     addi $sp, $sp, -4                # allocate one space
     sw $ra, 0($sp)                    # put ra to main in the allocate space

 	# $s0 = x coordinate, $s1 = y coordinate, $s2 = x direction, $s3 = y direction
 	la $t0, BALL
 	lw $s0, 0($t0)	# get x value from ball
 	lw $s1, 4($t0)	# get y value from ball
 	lw $s2, 8($t0)	# get x direction of ball
 	lw $s3, 12($t0)	# get y direction of ball

 	add $t0, $s0, $s2 # next x-value of ball
 	add $t1, $s1, $s3 # next y-value of ball

 	move $a0, $s0                 # x0 coordinate
     move $a1, $s1                 # y0 coordinate

     # new line added below
     #jal update_history        
     #beq $a1, 15, quit
     beq $a1, 15, main_loop
     # new line added above

     jal find_address            # find the (x,y) address

     #check top & bottom
 	check_2:
         add $a0, $v0, -64
         lw $t0, ($a0)
     	#sw $t0, 0($a0)
     	beq $t0, 0x000000, check_6
     	    jal change_y_direction
 	        beq $t0, 0x29CAAB, collision # row3
 	        beq $t0, 0x8851D0, collision # row2
 	        beq $t0, 0x35a0ff, collision # row1
 	    j check_6

 	check_6:
 	    add $a0, $v0, 64
 	    lw $t0, ($a0)
     	#sw $t0, 0($a0)
     	beq $t0, 0x000000, check_4
     	    jal change_y_direction
 	        beq $t0, 0x29CAAB, collision # row3
 	        beq $t0, 0x8851D0, collision # row2
 	        beq $t0, 0x35a0ff, collision # row1
 	    j check_4

 	#check left & right
 	check_4:
 	    add $a0, $v0, 4
 	    lw $t0, ($a0)
     	#sw $t0, 0($a0)
     	beq $t0, 0x000000, check_8
     	    jal change_x_direction
 	        beq $t0, 0x29CAAB, collision # row3
 	        beq $t0, 0x8851D0, collision # row2
 	        beq $t0, 0x35a0ff, collision # row1
 	    j check_8

 	check_8:
 		add $a0, $v0, -4
 		lw $t0, ($a0)
     	#sw $t0, 0($a0)
     	beq $t0, 0x000000, end
     	    jal change_x_direction
 	        beq $t0, 0x29CAAB, collision # row3
 	        beq $t0, 0x8851D0, collision # row2
 	        beq $t0, 0x35a0ff, collision # row1

     # load return address to draw
     end:
     lw $ra, 0($sp)                    # get ra to main from the stack
     addi $sp, $sp, 4                    # delocate stpace
     jr $ra			            # return to the calling program
     
     
 exit:
     jr $ra


 collision:
     # Save return address to draw
     addi $sp, $sp, -4                 # allocate one sapce
     sw $ra, 0($sp)                    # put ra to main in the allocate space

     jal update_score    # update current score

     #colour a0 some colour
     li $a1, 1
     li $a2, 1
     # lw $a3, ANIMATION_COLOUR
     li $a3, 16711680 # this is the red decimal colour
     #li $a3, 0
     jal draw_rect

     #added
     #jal sleep -> if uncommented, the registers get messed up and then check_6 doesnt work
     jal sleep_2

     #colour a0+4 some colour
     #add $a0, $a0, 8
     add $a0, $a0, 4
     li $a1, 1
     li $a2, 1
     #li $a3, 16711680 #added colour
     jal draw_rect

     #colour a0-4 some colour
     add $a0, $a0, -8
     li $a1, 1
     li $a2, 1
     #li $a3, 16711680 # added colour
     jal draw_rect

     # jal sleep

     #colour a0-4 black
     li $a1, 1
     li $a2, 1
     li $a3, 0
     # lw $a3, ANIMATION_COLOUR
     jal draw_rect

     #colour a0+4 black
     add $a0, $a0, 8
     li $a1, 1
     li $a2, 1
     # lw $a3, ANIMATION_COLOUR
     jal draw_rect

     # jal sleep
     #colour a0 some black
     add $a0, $a0, -4
     li $a1, 1
     li $a2, 1
     # lw $a3, ANIMATION_COLOUR
     jal draw_rect


     # load return address to draw
     lw $ra, 0($sp)                      # get ra to main from the stack
     addi $sp, $sp, 4                    # delocate stpace
     jr $ra			            # return to the calling program

 change_diagonally:
     # Save return address to draw
     addi $sp, $sp, -4                 # allocate one space
     sw $ra, 0($sp)                    # put ra to main in the allocate space

     jal change_x_direction
     jal change_y_direction

     # load return address to draw
     lw $ra, 0($sp)                    # get ra to main from the stack
     addi $sp, $sp, 4                    # delocate space
     jr $ra			            # return to the calling program

 change_y_direction:
     # Save return address to draw
     addi $sp, $sp, -4                # allocate one sapce
     sw $ra, 0($sp)                    # put ra to main in the allocate space

     # $s0 = x coordinate, $s1 = y coordinate, $s2 = x direction, $s3 = y direction
 	la $t1, BALL
 	lw $s0, 0($t1)	# get x value from ball
 	lw $s1, 4($t1)	# get y value from ball
 	lw $s2, 8($t1)	# get x direction of ball
 	li $t7, -1

 	lw $s3, 12($t1)	# get y direction of ball

 	mul $s3, $s3, $t7 # get inverted
 	sw $s3, 12($t1) # store inverted value back into Ball y direction

     # load return address to draw
     lw $ra, 0($sp)                    # get ra to main from the stack
     addi $sp, $sp, 4                    # delocate space
     jr $ra			            # return to the calling program

 change_x_direction:
     # Save return address to draw
     addi $sp, $sp, -4                 # allocate one sapce
     sw $ra, 0($sp)                    # put ra to main in the allocate space


     # $s0 = x coordinate, $s1 = y coordinate, $s2 = x direction, $s3 = y direction
 	la $t2, BALL
 	lw $s0, 0($t2)	# get x value from ball
 	lw $s1, 4($t2)	# get y value from ball
 	li $t8, -1
 	lw $s2, 8($t2)	# get x direction of ball
 	lw $s3, 12($t2)	# get y direction of ball

 	mul $s2, $s2, $t8 # get inverted
 	sw $s2, 8($t2) # store inverted value back into Ball y direction

     # load return address to draw
     lw $ra, 0($sp)                     # get ra to main from the stack
     addi $sp, $sp, 4                    # delocate stpace
     jr $ra			            # return to the calling program

 ##########################################################################
 # SCORES
 ##########################################################################
 set_history:
     addi $sp, $sp, -4
     sw $a0, 0($sp)

     addi $sp, $sp, -4
     sw $s0, 0($sp)
     la $s0, PAST_SCORE

     sw $zero, 0($s0)    #high score
     sw $zero, 4($s0)    #second scre
     sw $zero, 8($s0)    #third highrs

     lw $s0, 0($sp)
     addi $sp, $sp, 4

     lw $a0, 0($sp)
     addi $sp, $sp, 4
     jr $ra

 update_history:
     addi $sp, $sp, -4
     sw $a0, 0($sp)

    # $s0 -> $s4
     addi $sp, $sp, -4
     sw $s4, 0($sp)
     la $s4, PAST_SCORE

     lw $t0, CURR_SCORE
     lw $t1, 0($s4) #high score
     lw $t2, 4($s4) #second score
     lw $t3, 8($s4) #third score

     bgt $t3, $t0, end_comare    # if curr is less than top 3
     
     beq $t0, $t1, end_comare    # if curr is already recorded
     beq $t0, $t2, end_comare
     beq $t0, $t3, end_comare     
     
     bgt $t0, $t1, move_curr1    # if curr highest
     bgt $t0, $t2, move_curr2    # if curr second highest
     bgt $t0, $t3, move_curr3    # if curr third highest
     move_12:
     sw $t1, 4($s4)
     j move_23
     move_23:
     sw $t2, 8($s4)
     j end_comare

     move_curr1:
     sw $t0, 0($s4)
     j move_12
     move_curr2:
     sw $t0, 4($s4)
     j move_23
     move_curr3:
     sw $t0, 8($s4)
     end_comare:

     sw $zero, CURR_SCORE    # resets curr_score to 0

     lw $s4, 0($sp)
     addi $sp, $sp, 4
     lw $a0, 0($sp)
     addi $sp, $sp, 4
     jr $ra

 update_score:
     addi $sp, $sp, -4
     sw $a0, 0($sp)

    # a0 -> s5
     lw $s5, CURR_SCORE
     addi $s5, $s5, 1 
     sw $s5, CURR_SCORE

     lw $a0, 0($sp)
     addi $sp, $sp, 4
     jr $ra

 ##########################################################################
 # INITIALIZATIONs
 ##########################################################################

 initialize_var: # initalizes ball and plate variables
     addi $sp, $sp, -4    #allocate one space
     sw $ra, 0($sp)        # put ra to main in the allocate space

     # initialize ball with starting position and direction
     la $t0, BALL
     lw $t1, BALL_X
     sw, $t1, 0($t0)
     lw $t1, BALL_Y
     sw $t1, 4($t0)
     addi $t1, $0, -1
     sw, $t1, 8($t0)
     addi $t1, $0, -1
     sw $t1, 12($t0)

     # initialize plank with starting position and direction
     la $t0, PLANK
     lw $t1, PLANK_X
     sw, $t1, 0($t0)
     lw $t1, PLANK_Y
     sw $t1, 4($t0)
     li $t1, 0
     sw $t1, 8($t0)

     lw $ra, 0($sp)                    #get ra to main from the stack
     addi $sp, $sp, 4                    # Increment the stack pointer to delocate space for the return address
     jr $ra			            # return to the calling program

 ##########################################################################
 # Game Screen (excluding the ball and plank)
 ##########################################################################
 draw_start_game_screen:
     # Save return address to main
     addi $sp, $sp, -4                # allocate one sapce
     sw $ra, 0($sp)                    #put ra to main in the allocate space

     jal draw_plank
     jal draw_ball
     jal draw_walls
     jal draw_bricks

     # load return address to main
     lw $ra, 0($sp)                    #get ra to main from the stack
     addi $sp, $sp, 4                    #delocate stpace
     jr $ra			            # return to the calling program


 draw_walls:
         # Save return address to draw
     addi $sp, $sp, -4                # alocate one sapce
     sw $ra, 0($sp)                    #put ra to main in the allocate space

 	jal draw_walls_left
     jal draw_walls_right
     jal draw_walls_horizontal		   

      # load return address to draw
     lw $ra, 0($sp)                    #get ra to main from the stack
     addi $sp, $sp, 4                    #delocate stpace
     jr $ra			            # return to the calling program

 draw_walls_left:
     # Save return address to draw
     addi $sp, $sp, -4                # alocate one sapce
     sw $ra, 0($sp)                    #put ra to main in the allocate space

 	    #LEFT WALL
     lw $a0, WALL_LEFT_X                  # x0 coordinate
     lw $a1, WALL_LEFT_Y                  # y0 coordinate
     jal find_address            # find the (x,y) address
     move $a0, $v0               # move the return value from $v0 to $t0
     lw $a1, WALL_LEFT_WIDTH         # width
     lw $a2, WALL_LEFT_HEIGHT         #height
     lw $a3, WALL_COLOUR   #colour
     jal draw_rect    # Call the draw_rect function		   

      # load return address to main
     lw $ra, 0($sp)                    #get ra to main from the stack
     addi $sp, $sp, 4                    #delocate stpace
     jr $ra			            # return to the calling program

 draw_walls_right:
     # Save return address to draw
     addi $sp, $sp, -4                # alocate one sapce
     sw $ra, 0($sp)                    #put ra to main in the allocate space

 	#RIGHT WALL
     lw $a0, WALL_RIGHT_X                  # x0 coordinate
     lw $a1, WALL_RIGHT_Y                  # y0 coordinate
     jal find_address            # find the (x,y) address
     move $a0, $v0               # move the return value from $v0 to $t0
     lw $a1, WALL_RIGHT_WIDTH         # width
     lw $a2, WALL_RIGHT_HEIGHT         #height
     lw $a3, WALL_COLOUR   #colour
     jal draw_rect    # Call the draw_rect function		   

      # load return address to main
     lw $ra, 0($sp)                    #get ra to main from the stack
     addi $sp, $sp, 4                    #delocate stpace
     jr $ra			            # return to the calling program

 draw_walls_horizontal:
     # Save return address to draw
     addi $sp, $sp, -4                # alocate one sapce
     sw $ra, 0($sp)                    #put ra to main in the allocate space

 	#Horizontal WALL
     lw $a0, WALL_HORIZ_X                  # x0 coordinate
     lw $a1, WALL_HORIZ_Y                  # y0 coordinate
     jal find_address            # find the (x,y) address
     move $a0, $v0               # move the return value from $v0 to $t0
     lw $a1, WALL_HORIZ_WIDTH         # width
     lw $a2, WALL_HORIZ_HEIGHT         #height
     lw $a3, WALL_COLOUR   #colour
     jal draw_rect    # Call the draw_rect function		   

      # load return address to main
     lw $ra, 0($sp)                    #get ra to main from the stack
     addi $sp, $sp, 4                    #delocate stpace
     jr $ra			            # return to the calling program


 draw_bricks:
     # Save return address to draw
     addi $sp, $sp, -4                # alocate one sapce
     sw $ra, 0($sp)                    #put ra to main in the allocate space

     jal draw_brick1
     jal draw_brick3                   
     jal draw_brick5
     jal draw_brick7
     jal draw_brick9
     bne $t5, 2, level1     # Check if level 2 was activates
     #level2
     jal draw_brick2
     jal draw_brick4
     jal draw_brick6
     jal draw_brick8
     level1:                # skip here if its level 1

      # load return address to main
     lw $ra, 0($sp)                    #get ra to main from the stack
     addi $sp, $sp, 4                    #delocate stpace
     jr $ra			            # return to the calling program

 draw_brick1:
     # Save return address to brick
     addi $sp, $sp, -4                # alocate one sapce
     sw $ra, 0($sp)                    #put ra to main in the allocate space

     lw $a0, BRICK_COL1                  # x0 coordinate
     lw $a1, BRICK_ROW1                  # y0 coordinate
     jal find_address            # find the (x,y) address
     move $a0, $v0               # move the return value from $v0 to $t0
     lw $a1, BRICK_WIDTH         # width
     lw $a2, BRICK_HEIGHT         #height
     lw $a3, BRICK1_COLOR   #colour
     jal draw_rect    # Call the draw_rect function		   

      # load return address to brick
     lw $ra, 0($sp)                    #get ra to main from the stack
     addi $sp, $sp, 4                    #delocate stpace
     jr $ra			            # return to the calling program


 draw_brick2:
     # Save return address to brick
     addi $sp, $sp, -4                # alocate one sapce
     sw $ra, 0($sp)                    #put ra to main in the allocate space

     lw $a0, BRICK_COL2                  # x0 coordinate
     lw $a1, BRICK_ROW1                  # y0 coordinate
     jal find_address            # find the (x,y) address
     move $a0, $v0               # move the return value from $v0 to $t0
     lw $a1, BRICK_WIDTH         # width
     lw $a2, BRICK_HEIGHT         #height
     lw $a3, BRICK1_COLOR   #colour
     jal draw_rect    # Call the draw_rect function		   

      # load return address to brick
     lw $ra, 0($sp)                    #get ra to main from the stack
     addi $sp, $sp, 4                    #delocate stpace
     jr $ra			            # return to the calling program


 draw_brick3:
     # Save return address to brick
     addi $sp, $sp, -4                # alocate one sapce
     sw $ra, 0($sp)                    #put ra to main in the allocate space

     lw $a0, BRICK_COL3                  # x0 coordinate
     lw $a1, BRICK_ROW1                  # y0 coordinate
     jal find_address            # find the (x,y) address
     move $a0, $v0               # move the return value from $v0 to $t0
     lw $a1, BRICK_WIDTH         # width
     lw $a2, BRICK_HEIGHT         #height
     lw $a3, BRICK1_COLOR   #colour
     jal draw_rect    # Call the draw_rect function		   

      # load return address to brick
     lw $ra, 0($sp)                    #get ra to main from the stack
     addi $sp, $sp, 4                    #delocate stpace
     jr $ra			            # return to the calling program


 draw_brick4:
     # Save return address to brick
     addi $sp, $sp, -4                # alocate one sapce
     sw $ra, 0($sp)                    #put ra to main in the allocate space

     lw $a0, BRICK_COL1                  # x0 coordinate
     lw $a1, BRICK_ROW2                  # y0 coordinate
     jal find_address            # find the (x,y) address
     move $a0, $v0               # move the return value from $v0 to $t0
     lw $a1, BRICK_WIDTH         # width
     lw $a2, BRICK_HEIGHT         #height
     lw $a3, BRICK2_COLOR   #colour
     jal draw_rect    # Call the draw_rect function		   

      # load return address to brick
     lw $ra, 0($sp)                    #get ra to main from the stack
     addi $sp, $sp, 4                    #delocate stpace
     jr $ra			            # return to the calling program


 draw_brick5:
     # Save return address to brick
     addi $sp, $sp, -4                # alocate one sapce
     sw $ra, 0($sp)                    #put ra to main in the allocate space

     lw $a0, BRICK_COL2                  # x0 coordinate
     lw $a1, BRICK_ROW2                  # y0 coordinate
     jal find_address            # find the (x,y) address
     move $a0, $v0               # move the return value from $v0 to $t0
     lw $a1, BRICK_WIDTH         # width
     lw $a2, BRICK_HEIGHT         #height
     lw $a3, BRICK2_COLOR   #colour
     jal draw_rect    # Call the draw_rect function		   

      # load return address to brick
     lw $ra, 0($sp)                    #get ra to main from the stack
     addi $sp, $sp, 4                    #delocate stpace
     jr $ra			            # return to the calling program


 draw_brick6:
     # Save return address to brick
     addi $sp, $sp, -4                # alocate one sapce
     sw $ra, 0($sp)                    #put ra to main in the allocate space

     lw $a0, BRICK_COL3                  # x0 coordinate
     lw $a1, BRICK_ROW2                  # y0 coordinate
     jal find_address            # find the (x,y) address
     move $a0, $v0               # move the return value from $v0 to $t0
     lw $a1, BRICK_WIDTH         # width
     lw $a2, BRICK_HEIGHT         #height
     lw $a3, BRICK2_COLOR   #colour
     jal draw_rect    # Call the draw_rect function		   

      # load return address to brick
     lw $ra, 0($sp)                    #get ra to main from the stack
     addi $sp, $sp, 4                    #delocate stpace
     jr $ra			            # return to the calling program

 draw_brick7:
     # Save return address to brick
     addi $sp, $sp, -4                # alocate one sapce
     sw $ra, 0($sp)                    #put ra to main in the allocate space

     lw $a0, BRICK_COL1                  # x0 coordinate
     lw $a1, BRICK_ROW3                  # y0 coordinate
     jal find_address            # find the (x,y) address
     move $a0, $v0               # move the return value from $v0 to $t0
     lw $a1, BRICK_WIDTH         # width
     lw $a2, BRICK_HEIGHT         #height
     lw $a3, BRICK3_COLOR   #colour
     jal draw_rect    # Call the draw_rect function		   

      # load return address to brick
     lw $ra, 0($sp)                    #get ra to main from the stack
     addi $sp, $sp, 4                    #delocate stpace
     jr $ra			            # return to the calling program


 draw_brick8:
     # Save return address to brick
     addi $sp, $sp, -4                # alocate one sapce
     sw $ra, 0($sp)                    #put ra to main in the allocate space

     lw $a0, BRICK_COL2                  # x0 coordinate
     lw $a1, BRICK_ROW3                  # y0 coordinate
     jal find_address            # find the (x,y) address
     move $a0, $v0               # move the return value from $v0 to $t0
     lw $a1, BRICK_WIDTH         # width
     lw $a2, BRICK_HEIGHT         #height
     lw $a3, BRICK3_COLOR   #colour
     jal draw_rect    # Call the draw_rect function		   

      # load return address to brick
     lw $ra, 0($sp)                    #get ra to main from the stack
     addi $sp, $sp, 4                    #delocate stpace
     jr $ra			            # return to the calling program


 draw_brick9:
     # Save return address to brick
     addi $sp, $sp, -4                # alocate one sapce
     sw $ra, 0($sp)                    #put ra to main in the allocate space

     lw $a0, BRICK_COL3                  # x0 coordinate
     lw $a1, BRICK_ROW3                  # y0 coordinate
     jal find_address            # find the (x,y) address
     move $a0, $v0               # move the return value from $v0 to $t0
     lw $a1, BRICK_WIDTH         # width
     lw $a2, BRICK_HEIGHT         #height
     lw $a3, BRICK3_COLOR   #colour
     jal draw_rect    # Call the draw_rect function		   

      # load return address to brick
     lw $ra, 0($sp)                    #get ra to main from the stack
     addi $sp, $sp, 4                    #delocate stpace
     jr $ra			            # return to the calling program

    leave:
    jal draw_black_screen #clear screen     #clear screen
     # Terminate the program
     jal quit
 ##########################################################################
 # Home Screen
 ##########################################################################

 draw_home_screen:
     # Save return address to main
     addi $sp, $sp, -4                # allocate one space
     sw $ra, 0($sp)                    #put ra to main in the allocate space

     jal draw_rate1
     jal draw_rate2
     jal draw_rate3
     jal draw_score1
     jal draw_score2
     jal draw_score3
     jal draw_L1
     jal draw_V
     jal draw_L2
     jal draw_colon
     jal draw_bottom_line

     # load return address to main
     lw $ra, 0($sp)                    #get ra to main from the stack
     addi $sp, $sp, 4                    #delocate stpace
     jr $ra			            # return to the calling program

 draw_rate1:
     # Save return address to draw
     addi $sp, $sp, -4                # allocate one sapce
     sw $ra, 0($sp)                    #put ra to main in the allocate space

     li $a0, 3                  # x0 coordinate
     li $a1, 1                 # y0 coordinate
     jal find_address            # find the (x,y) address
     move $a0, $v0               # move the return value from $v0 to $t0 
     li $a1,  1        # width
     li $a2,  1       #height
     lw $a3,  RATE_COLOUR  #colour
     jal draw_rect    # Call the draw_rect function			   

      # load return address to draw
     lw $ra, 0($sp)                    #get ra to main from the stack
     addi $sp, $sp, 4                    #delocate stpace
     jr $ra			            # return to the calling program

 draw_rate2:
     # Save return address to draw
     addi $sp, $sp, -4                # alocate one sapce
     sw $ra, 0($sp)                    #put ra to main in the allocate space

     li $a0, 2                  # x0 coordinate
     li $a1, 3                  # y0 coordinate
     jal find_address            # find the (x,y) address
     move $a0, $v0               # move the return value from $v0 to $t0 
     li $a1, 2       # width
     li $a2, 1        #height
     lw $a3, RATE_COLOUR  #colour
     jal draw_rect    # Call the draw_rect function			   

      # load return address to draw
     lw $ra, 0($sp)                    #get ra to main from the stack
     addi $sp, $sp, 4                    #delocate stpace
     jr $ra			            # return to the calling program

 draw_rate3:
     # Save return address to draw
     addi $sp, $sp, -4                # alocate one sapce
     sw $ra, 0($sp)                    #put ra to main in the allocate space

     #PLANK
     li $a0, 1                  # x0 coordinate
     li $a1, 5                  # y0 coordinate
     jal find_address            # find the (x,y) address
     move $a0, $v0               # move the return value from $v0 to $t0 
     li $a1, 3        # width
     li $a2, 1         #height
     lw $a3, RATE_COLOUR  #colour
     jal draw_rect    # Call the draw_rect function			   

      # load return address to draw
     lw $ra, 0($sp)                    #get ra to main from the stack
     addi $sp, $sp, 4                    #delocate stpace
     jr $ra			            # return to the calling program

 draw_score1:
     # Save return address to draw
     addi $sp, $sp, -4                # alocate one sapce
     sw $ra, 0($sp)                    #put ra to main in the allocate space

     #PLANK
     li $a0, 6                  # x0 coordinate
     li $a1, 1                  # y0 coordinate
     jal find_address            # find the (x,y) address
     move $a0, $v0               # move the return value from $v0 to $t0 

     la $s0, PAST_SCORE
     lw $t1, 0($s0) #high score

     move $a1, $t1         # width   
     li $a2, 1         #height
     lw $a3, SCORE_COLOR   #colour
     jal draw_rect    # Call the draw_rect function			   

      # load return address to draw
     lw $ra, 0($sp)                    #get ra to main from the stack
     addi $sp, $sp, 4                    #delocate stpace
     jr $ra			            # return to the calling program

 draw_score2:
     # Save return address to draw
     addi $sp, $sp, -4                # alocate one sapce
     sw $ra, 0($sp)                    #put ra to main in the allocate space

     #PLANK
     li $a0, 6                  # x0 coordinate
     li $a1, 3                  # y0 coordinate
     jal find_address            # find the (x,y) address
     move $a0, $v0               # move the return value from $v0 to $t0 

     la $s0, PAST_SCORE
     lw $t1, 4($s0) #second score

     move $a1, $t1         # width  
     li $a2, 1         #height
     lw $a3, SCORE_COLOR   #colour
     jal draw_rect    # Call the draw_rect function			   

      # load return address to draw
     lw $ra, 0($sp)                    #get ra to main from the stack
     addi $sp, $sp, 4                    #delocate stpace
     jr $ra			            # return to the calling program

 draw_score3:
     # Save return address to draw
     addi $sp, $sp, -4                # alocate one sapce
     sw $ra, 0($sp)                    #put ra to main in the allocate space

     li $a0, 6                  # x0 coordinate
     li $a1, 5                  # y0 coordinate
     jal find_address            # find the (x,y) address
     move $a0, $v0               # move the return value from $v0 to $t0 

     la $s0, PAST_SCORE
     lw $t1, 8($s0) #third highest score
     move $a1, $t1         # width  
     li $a2, 1        #height
     lw $a3, SCORE_COLOR   #colour
     jal draw_rect    # Call the draw_rect function			   

      # load return address to draw
     lw $ra, 0($sp)                    #get ra to main from the stack
     addi $sp, $sp, 4                    #delocate stpace
     jr $ra			            # return to the calling program

 draw_L1:
     # Save return address to draw
     addi $sp, $sp, -4                # alocate one sapce
     sw $ra, 0($sp)                    #put ra to main in the allocate space

     #vertical line
     li $a0, 2                  # x0 coordinate
     li $a1, 7                  # y0 coordinate
     jal find_address            # find the (x,y) address
     move $a0, $v0               # move the return value from $v0 to $t0 
     li $a1, 1        # width   
     li $a2, 3         #height
     lw $a3, LEVEL_COLOUR   #colour
     jal draw_rect    # Call the draw_rect function	

     #Horizontal line
     li $a0, 2                  # x0 coordinate
     li $a1, 9                  # y0 coordinate
     jal find_address            # find the (x,y) address
     move $a0, $v0               # move the return value from $v0 to $t0 
     li $a1, 3        # width   
     li $a2, 1         #height
     lw $a3, LEVEL_COLOUR   #colour
     jal draw_rect    # Call the draw_rect function	

      # load return address to draw
     lw $ra, 0($sp)                    #get ra to main from the stack
     addi $sp, $sp, 4                    #delocate stpace
     jr $ra			            # return to the calling program

 draw_V:
     # Save return address to draw
     addi $sp, $sp, -4                # alocate one sapce
     sw $ra, 0($sp)                    #put ra to main in the allocate space

     #verticle line
     li $a0, 6                  # x0 coordinate
     li $a1, 7                  # y0 coordinate
     jal find_address            # find the (x,y) address
     move $a0, $v0               # move the return value from $v0 to $t0 
     li $a1, 1         # width   
     li $a2, 3        #height
     lw $a3, LEVEL_COLOUR   #colour
     jal draw_rect    # Call the draw_rect function

     #middle square
     li $a0,  7                 # x0 coordinate
     li $a1,  8                 # y0 coordinate
     jal find_address            # find the (x,y) address
     move $a0, $v0               # move the return value from $v0 to $t0 
     li $a1, 1         # width   
     li $a2, 1         #height
     lw $a3, LEVEL_COLOUR   #colour
     jal draw_rect    # Call the draw_rect function

     #corner square
     li $a0,  8                 # x0 coordinate
     li $a1,  7                 # y0 coordinate
     jal find_address            # find the (x,y) address
     move $a0, $v0               # move the return value from $v0 to $t0 
     li $a1, 1         # width   
     li $a2, 1         #height
     lw $a3, LEVEL_COLOUR   #colour
     jal draw_rect    # Call the draw_rect function

      # load return address to draw
     lw $ra, 0($sp)                    #get ra to main from the stack
     addi $sp, $sp, 4                    #delocate stpace
     jr $ra			            # return to the calling program

 draw_L2:
     # Save return address to draw
     addi $sp, $sp, -4                # alocate one sapce
     sw $ra, 0($sp)                    #put ra to main in the allocate space

     #vertical line
     li $a0, 10                  # x0 coordinate
     li $a1, 7                  # y0 coordinate
     jal find_address            # find the (x,y) address
     move $a0, $v0               # move the return value from $v0 to $t0 
     li $a1, 1        # width   
     li $a2, 3         #height
     lw $a3, LEVEL_COLOUR   #colour
     jal draw_rect    # Call the draw_rect function	

     #Horizontal line
     li $a0, 10                  # x0 coordinate
     li $a1, 9                  # y0 coordinate
     jal find_address            # find the (x,y) address
     move $a0, $v0               # move the return value from $v0 to $t0 
     li $a1, 3        # width   
     li $a2, 1         #height
     lw $a3, LEVEL_COLOUR   #colour
     jal draw_rect    # Call the draw_rect function	

      # load return address to draw
     lw $ra, 0($sp)                    #get ra to main from the stack
     addi $sp, $sp, 4                    #delocate stpace
     jr $ra			            # return to the calling program

 draw_colon:
     # Save return address to draw
     addi $sp, $sp, -4                # alocate one sapce
     sw $ra, 0($sp)                    #put ra to main in the allocate space

     #vertical line
     li $a0, 14                  # x0 coordinate
     li $a1, 7                  # y0 coordinate
     jal find_address            # find the (x,y) address
     move $a0, $v0               # move the return value from $v0 to $t0 
     li $a1, 1        # width   
     li $a2, 1         #height
     lw $a3, LEVEL_COLOUR   #colour
     jal draw_rect    # Call the draw_rect function	

     #Horizontal line
     li $a0, 14                  # x0 coordinate
     li $a1, 9                  # y0 coordinate
     jal find_address            # find the (x,y) address
     move $a0, $v0               # move the return value from $v0 to $t0 
     li $a1, 1        # width   
     li $a2, 1         #height
     lw $a3, LEVEL_COLOUR   #colour
     jal draw_rect    # Call the draw_rect function	

      # load return address to draw
     lw $ra, 0($sp)                    #get ra to main from the stack
     addi $sp, $sp, 4                    #delocate space
     jr $ra			            # return to the calling program


 draw_bottom_line:
     # Save return address to draw
     addi $sp, $sp, -4                # allocate one sapce
     sw $ra, 0($sp)                    #put ra to main in the allocate space

     li $a0, 2                  # x0 coordinate
     li $a1, 13                  # y0 coordinate
     jal find_address            # find the (x,y) address
     move $a0, $v0               # move the return value from $v0 to $t0 
     li $a1,  12        # width   
     li $a2,  1        #height
     lw $a3,  LINE_COLOUR  #colour
     jal draw_rect    # Call the draw_rect function			   

      # load return address to draw
     lw $ra, 0($sp)                    #get ra to main from the stack
     addi $sp, $sp, 4                    #delocate space
     jr $ra			            # return to the calling program