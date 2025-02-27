.global _start


.macro push rx
	addi sp ,sp ,-4
	stw \rx ,0(sp)
.endm

.macro pop rx
	ldw \rx ,0(sp)
	addi sp ,sp ,4
.endm


# define loop delay in msec (vary speed of the digits)
.equ N, 200
.equ SWITCHES, 0x8850
.equ HEXCONTROL, 0X88B0
.equ HEX, 0X88A0
.equ PUSHBUTTONS, 0x8860
.equ HEXCONTROL,0x88B0 
.equ DECADE, 0x8870
.equ DECADECONTROL, 0x88E0
.equ REDLEDS, 0x8880


#.EQU    HEX8,      0x88A0
#.EQU    LEDS,      0x8880
#.EQU    GREEN,     0x8890
#.EQU    HEX8CTL,   0x88B0
#.EQU    BUTTONS,   0x8860
#.EQU    SWITCHES,  0x8850
#.EQU    TIMER,     0x8870
#.EQU    TIMERCTL,  0x88E0
#.EQU    IRDA,      0x88D0
#.EQU    IOPORT,    0x8930
	
.org 0x0100	
_start:
	call init		# perform initialization

top:	
	ori  r3, r0, N		# wait here for N msec
	call delay

	call buttons		# check buttons now
	beq  r5, r0, four	# done if all digits stopped

	ori  r22, r0, code	# point to first digit
	ori  r4, r0, 0x01 	# select digit 0 mask
	and  r3, r4, r5		# check if digit is enabled
	beq  r3, r0, a0		# skip increment if not enabled
	call incx
a0: 
	addi r22, r22, 1 	# go to next digit 
	ori r4, r0, 0x02 	# select digit 1 mask
	and r3, r4, r5 		# check if digit is enabled
	beq r3, r0, a1 		# skip increment if not enabled
	call incx 		# increment next digit
a1:
	addi r22, r22, 1 	# go to next digit 
	ori r4, r0, 0x04	# select digit 2 mask
	and r3, r4, r5 		# check if digit is enabled
	beq r3, r0, a2 		# skip increment if not enabled
	call incx 		# increment next digit
a2:
	addi r22, r22, 1 	# go to next digit 
	ori r4, r0, 0x08	# select digit 3 mask
	and r3, r4, r5 		# check if digit is enabled
	beq r3, r0, a3 		# skip increment if not enabled
	call incx 		# increment next digit
a3:
	call show4		# update the display
    	br top              	# start over

four:	
    	call check4		# fireworks if match found
	call switch0		# wait here for edge on SW0

	ori  r5,r0,0x0F     	# re-enable count on all digits
	call reset4	    	# reset display digit values

	br top		    	# start over

#============================================================
init:
    ori sp, r0, stacktop      # initalize stack pointer

    push r3
    push r4

    ori r3, r0, HEXCONTROL    
    ori r4, r0, 0x155            
    stwio r4, (r3)            # display ON, HEX 0-3 ON.    
    
    ori r3, r0, DECADECONTROL
    ori r4, r0, 0
    stwio r4, (r3)            # start decade timer
    
    ori r5, r0, 0xF           # no buttons pressed

    pop r4
    pop r3

    ret
#============================================================
# delay for N msec where N is supplied in r3
delay: 
    push r3
    push r4
    push r5
    
    ori r4, r0, 10000            	# 10 seconds = 10 000 msec
    bge r3, r4, maxvalue
    br max_skip
    
    maxvalue:
        ori r3, r0, 10000        	# reset to 10 sec delay
        
    max_skip:
        ori r5,r0,DECADE
        
    falling_edge:
        ldwio r4, (r5)
        andi r4, r4, 4        		# isolate 1 ms 
        beq r4, r0, falling_edge	# wait for rising_edge
        
        addi r3, r3, -1        # decrement time value
        beq r3, r0, done_delay
    
    rising_edge:
        ldwio r4,(r5)
        andi r4,r4,4        # isolate 1 ms
        bne r4,r0,rising_edge    # wait for falling_edge
        br falling_edge    
    
    done_delay:
        
    
    pop r5
    pop r4
    pop r3

    ret
#============================================================    
# wait for a rising edge on SW0
switch0:
    push r3
    push r4

    ori r3,r0,SWITCHES

    down:
        ldwio r4, (r3)
        andi r4, r4, 1    # isolate sw0
        beq r4, r0, down

    waitlow:
        ldwio r4, (r3)
        andi r4, r4, 1    # isolate sw0
        bne r4, r0, waitlow

    pop r4
    pop r3

    ret

#============================================================
# check buttons, if exactly one button is pressed, zero that bit in r5
buttons:
    push r3
    push r4
    push r6

    ori r3, r0, PUSHBUTTONS
    ldwio r6, (r3)       # r6 = buttons
    andi  r6, r6, 0xF    # r6 = 4 buttons

    # accept only if a single button is pressed
    ori   r3, r0, 0b0111 # button 3 alone?
    beq   r3, r6, valid
    ori   r3, r0, 0b1011 # button 2 alone?
    beq   r3, r6, valid
    ori   r3, r0, 0b1101 # button 1 alone?
    beq   r3, r6, valid
    ori   r3, r0, 0b1110 # button 0 alone?
    beq   r3, r6, valid
    br    nothing      	 # reject all others

valid:
    and  r5, r5, r6      # update r5 wrt buttons pressed

nothing:
    pop r6
    pop r4
    pop r3

    ret
#============================================================
# increment the byte @ addr in r22, byte goes up 0 to 9 and rolls back to 0    
incx:
    push r3
    push r4
    
    ldbu r3, (r22)  	# r3 = one digit
    addi r3, r3, 1   	# increment    
    andi r3, r3, 0xF 	# limit to 4 bits
    ori  r4, r0, 10  	# r4 = 20
    blt  r3, r4, dd  	# if digit < 10 ok
    ori  r3, r0, 0   	# else back to 0 
    dd: stb r3, (r22)  	# update digit

    pop r4
    pop r3

    ret
#============================================================
# set 4 digits @ code to some default values
reset4:
    push r3
    push r4

    ori r3, r0, code
    movia r4, 0x04030201
    stwio r4, (r3)         # reset code digits to 1234.

    pop r4
    pop r3

    ret
#============================================================
# send 4 digits @ code to the hex display 
show4:
    push r3
    push r4
    
    ori r3, r0, code
    ldwio r3, (r3)        # r3 = all 4 digits     

    ori r4, r0, HEX
    stwio r3, (r4)        # send r3 to hex display    

    pop r4
    pop r3

    ret
#============================================================
# looks for 4 of a kind, calls fireworks if all 4 digits match
check4:
    push ra
    push r4
    push r5
    push r6    

    ori  r4, r0, code    	# r4 = addr of digits
    
    ldbu r5, 0(r4)    		# r5 = digit 3

    ldbu r6, 1(r4)    		# r6 = digit 2
    bne  r6, r5, not_equal

    ldbu r6, 2(r4)    		# r6 = digit 1
    bne  r6, r5,not_equal

    ldbu r6, 3(r4)    		# r6 = digit 0
    bne  r6, r5, not_equal

    call fireworks

    not_equal:

    pop r6
    pop r5
    pop r4
    pop ra

    ret
#============================================================
# send 16-bits in r3 to the hex diaply
outhex:
    push r3
    push r4
    
    ori r4, r0, HEX
    andi r3, r3, 0xFFFF
    stwio r3, (r4) 

    pop r4
    pop r3

    ret
#============================================================
# send 16-bits in r3 to the red leds
outled:
    push r3
    push r4

    ori r4, r0, REDLEDS
    andi r3, r3, 0xFFFF
    stwio r3, (r4)

    pop r4
    pop r3
    
    ret
#============================================================
# fun fun fun 
fireworks:
    push ra
    push r3
    push r4
    push r5
    push r6
    
    ori r4, r0, 200
    ori r3, r0, 50    	# 50 ms delay
    movia r5, 0x55555555
    ori r6, r0, REDLEDS

    fire_loop:
        
    stwio r5, (r6)
    call delay
    addi r4, r4, -1
    roli r5, r5, 1
    bne r4, r0, fire_loop

    stwio r0, (r6) 	# turn leds off

    pop r6
    pop r5
    pop r4
    pop r3
    pop ra
    
    ret
#============================================================
#-------------------------------------------------------------------
code: .byte 3,2,0,1 # store the four display digits here
#-------------------------------------------------------------------
.skip 200 # stack = 200 bytes = 50 words
stacktop: # end of stack space allocation
#-------------------------------------------------------------------
.end
