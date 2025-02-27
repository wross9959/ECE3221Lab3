.global _start
# ECE3221 LAB#3 - SUBROUTINES                       
# ----------------------------------------------- 
# DATE: Feb 2025		  NAME:  Will Ross 3734692
# DATE: Feb 2025		  NAME:  Alex Cameron 3680202
# ----------------------------------------------- 
# A Slot Machine
# - rapidly display four counting digits
# - each digits stops when its button is pressed
# - when all stops, four cherries wins
#   (any four digits, all the same)
# -----------------------------------------------
#  THIS STARTING CODE ONLY WORKS ON ONE DIGIT
# -----------------------------------------------


.macro push rx
	addi sp ,sp ,-4
	stw \rx ,0(sp)
.endm

.macro pop rx
	ldw \rx ,0(sp)
	addi sp ,sp ,4
.endm

# Timer N 
.equ N, 200


# ==============================
# IN-LAB NIOS DE-115
# ==============================
.EQU    HEX,      0x88A0
.EQU    REDLEDS,      0x8880
.EQU    GREEN,     0x8890
.EQU    HEXCONTROL,   0x88B0
.EQU    PUSHBUTTONS,   0x8860
.EQU    SWITCHES,  0x8850
.EQU    DECADE,     0x8870
.EQU    DECADECONTROL,  0x88E0
# ==============================



# ==============================
# ONLINE SIM VAR
# ==============================
#.EQU    HEX,      		0x10000020
#.EQU    REDLEDS,      	0x10000000
#.EQU    GREEN,     		0x10000010
#.EQU    HEXCONTROL,   N/A
#.EQU    PUSHBUTTONS,   	0x10000050
#.EQU    SWITCHES,  		0x10000040
#.EQU    DECADE,     	0x10002000
#.EQU    DECADECONTROL, N/A
# ==============================



.org 0x0100
_start:
    call init			    # Perform initialization

top:

	ori r3, r0, N		    # wait here for N msec
	call delay

	call buttons 		    # check buttons now
	beq r5, r0, four 	    # done if all digits stopped

	ori r4, r0, 0x08 	    # select digit 0 mask
	and r3, r4, r5 		    # check if digit is enabled
	beq r3, r0, a1 		    # skip increment if not enabled
	call incx

a1:
    call show4              # update display 
    br top

four:
	call check4 		    # fireworks if match found
	call switch0 		    # wait here for edge on SW0

	ori r5, r0, 0x0F 		# re-enable count on all digits
	call reset4 		    # reset display digit values
	br top 				    # start over

#
# ----------------------------------------------- 
# DATE: Feb 2025		  NAME:  Will Ross #3734692
# ----------------------------------------------- 
# init procedure
# -----------------------------------------------
#
init:

	movia sp, stacktop		# Get the stack

	push r3
	push r4


	# OFF FOR ONLINE SIM
	movia r3, HEXCONTROL 	# Use the hex control for enabling the hex displays
	movia r4, 0x155			# HEX display's to turn on HEX3-HEX0
	stwio r4, (r3)			# Turn on display

	movia r3, DECADECONTROL	# Use the timer control
	movia r4, 0				# time the timer will start at 
	stwio r4, (r3)			# Turn on the timer

	movia r5, 0xF			# when no button is pressed

	pop r4
	pop r3

	ret


#                     
# ----------------------------------------------- 
# DATE: Feb 2025		  NAME:  Will Ross #3734692
# ----------------------------------------------- 
# delay procedure
# -----------------------------------------------
delay:

	push r3
	push r4
	push r5

	ori r4, r0, 10000		    # Get the max time 10 seconds as per lab req

	bge r3, r4, max_delay	    # If( r3 >= r4 ) then maxdelay is called
	br delay_loop			    # loop on delay loop

	max_delay:

		ori r3, r0, 10000	    # reset the delay to 10 seconds
	
	delay_loop:
		
		ori r5, r0, DECADE      # r5 = Decade address


	fall_edge:

		ldwio r4, (r5)			# load the value
		andi r4, r4, 4			# r4 = mask 4
		beq  r4, r0, fall_edge	# If( r4 == 0 ) then loop (wait for the edge)

		addi r3, r3, -1			# time value - 1
		beq r3, r0, done_delay	# if( r3 == 0 ) then the delay is done

	rise_edge:

		ldwio r4, (r5)		    # load the value
		andi r4, r4, 4		    # mask 4 
		bne r4, r0, rise_edge	# if(r4==0) wait for fall
		br fall_edge

	done_delay:
		
		pop r5
		pop r4
		pop r3

		ret
                  
# ----------------------------------------------- 
# DATE: Feb 2025		  NAME:  Will Ross #3734692
# ----------------------------------------------- 
# switch0 procedure
# -----------------------------------------------
switch0:

	push r3
	push r4


	ori r3, r0, SWITCHES		# Get switches address

	switch_down:
		ldwio r4, (r3)			# load switch value
		andi r4, r4, 1			# get sw0
		bne r4, r0, switch_down		# if(r4 == 0) wait till switch goes up

	switch_low:
		ldwio r4, (r3)			# load switch value
		andi r4, r4, 1			# get sw0
		bne r4, r0, switch_low 	# if( r4 == 0 ) wait till switch goes down

	pop r4
	pop r3

	ret

                    
# ----------------------------------------------- 
# DATE: Feb 2025		  NAME:  Will Ross #3734692
# ----------------------------------------------- 
# buttons procedure
# -----------------------------------------------
buttons:
	
	push r3
	push r4
	push r6

	ori r3, r0, PUSHBUTTONS		# Get pushbutton address

	ldwio r6, (r3)				# load the button
	andi r6, r6, 0xF			# get all four buttons

 
	ori   r3, r0, 0b0111		# Get button 3
    beq   r3, r6, button_valid	# If(btn3 == r6) get valid 

    ori   r3, r0, 0b1011 		# Get button 2
    beq   r3, r6, button_valid  # If(btn2 == r6) get valid 
    
	ori   r3, r0, 0b1101 		# Get button 1
    beq   r3, r6, button_valid  # If(btn1 == r6) get valid 
    
	ori   r3, r0, 0b1110 		# Get button 0
    beq   r3, r6, button_valid	# If(btn0 == r6) get valid 
    
	br    button_done      		# Then check if done

	button_valid:
		and  r5, r5, r6      # update r5 wrt buttons pressed


	button_done:
		pop r6
		pop r4
		pop r3

		ret


                    
# ----------------------------------------------- 
# DATE: Feb 2025		  NAME:  Will Ross #3734692
# ----------------------------------------------- 
# incx procedure
# -----------------------------------------------
incx:
	push r3
	push r4

	ldbu r3, (r22)  	# r3 = one digit
    addi r3, r3, 1   	# r3 += 1    

    andi r3, r3, 0xF 	# have only 4 bits

    ori  r4, r0, 10  	# n = 10
    blt  r3, r4, dd  	# if (r3 < n) { send the signal }
    ori  r3, r0, 0   	# else { go back }

    dd: 
		stb r3, (r22)  	# send the data to update

	pop r4
	pop r3

	ret


                
# ----------------------------------------------- 
# DATE: Feb 2025		  NAME:  Will Ross #3734692
# ----------------------------------------------- 
# reset4 procedure
# -----------------------------------------------
reset4:
	push r3
    push r4

    ori r3, r0, code		# Load code to r3
    movia r4, 0x04030201	# Value of 1234 for the hex
    stwio r4, (r3)         	# Resets all digits to different numbers so they cant get a jackpot

    pop r4
    pop r3

    ret

                 
# ----------------------------------------------- 
# DATE: Feb 2025		  NAME:  Alex Cameron #3680202
# ----------------------------------------------- 
# show4 procedure
# -----------------------------------------------
show4:

	push r3
	push r4

	ori r3, r0, code		# Load code to r3
    ldwio r3, (r3)        	# Load the code    

	

    ori r4, r0, HEX			# Get hex address 
    stwio r3, (r4)        	# send r3 to hex address 

	pop r4
	pop r3

	ret 

#                   
# ----------------------------------------------- 
# DATE: Feb 2025		  NAME:  Alex Cameron #3680202
# ----------------------------------------------- 
# check4 procedure
# -----------------------------------------------
check4:
	push ra
    push r4
    push r5
    push r6    

    ori  r4, r0, code    	# r4 = address of code
    
    ldbu r5, 0(r4)    		# r5 = HEX 0 digit
							
    ldbu r6, 1(r4)    		# r6 = HEX 1 digit
    bne  r6, r5, not_equal	# If( r6 != HEX0 val) then its not equal

    ldbu r6, 2(r4)    		# r6 = HEX 2 digit
    bne  r6, r5,not_equal	# If( r6 != HEX0 val) then its not equal

    ldbu r6, 3(r4)    		# r6 = Hex 3 digit
    bne  r6, r5, not_equal	# If( r6 != HEX0 val) then its not equal

    call fireworks			# If it didnt get called to not equal its a jackpot

    not_equal:
        pop r6
        pop r5
        pop r4
        pop ra

        ret

                    
# ---------------------------------------------- 
# DATE: Feb 2025		  NAME:  Alex Cameron #3680202
# ----------------------------------------------- 
# outhex procedure
# -----------------------------------------------
outhex:
	push r3
    push r4
    
    ori r4, r0, HEX			    # Get hex address
    andi r3, r3, 0xFFFF		    # r3 = 1111 1111 1111 1111
    stwio r3, (r4) 			    # send ffff to hex

    pop r4
    pop r3

    ret

#                 
# ----------------------------------------------- 
# DATE: Feb 2025		  NAME:  Alex Cameron #3680202
# ----------------------------------------------- 
# outled procedure
# -----------------------------------------------
outled:
	push r3
    push r4

    ori r4, r0, REDLEDS			# Address of the LEDS	
    andi r3, r3, 0xFFFF			# Get all 
    stwio r3, (r4)				# send signal

    pop r4
    pop r3
    
    ret

                   
# ----------------------------------------------- 
# DATE: Feb 2025		  NAME:  Alex Cameron #3680202
# ----------------------------------------------- 
# fireworks procedure
# -----------------------------------------------
fireworks:

	push ra
    push r3
    push r4
    push r5
    push r6
    
    ori r4, r0, 200         # 200 ms delay
    ori r3, r0, 50    	    # r3 = 50 ms delay
    movia r5, 0x55555555    # r5 = 0101 0101 0101 0101
    ori r6, r0, REDLEDS     # Get adress of leds

    fire_loop:
        
    stwio r5, (r6)          # Send the signal
    call delay              # Call the delay
    addi r4, r4, -1         # r4 = r4 - 1
    roli r5, r5, 1          # r5 = r5 << 1
    bne r4, r0, fire_loop   # if(r4 !=) fire loop

    stwio r0, (r6) 	        # turn leds off

    pop r6
    pop r5
    pop r4
    pop r3
    pop ra
    
    ret
	

# Important stuff

code: .byte 3,2,1,0

.skip 200
stacktop:

.end
