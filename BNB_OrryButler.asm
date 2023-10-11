// Basements and Byters
#GP0	led
#GP1	led
#GP2	led
#GP5 	led

#GP4	switch
#GP3	switch

// Constants
$w 	0
$f	1
$RESULT_W	0
$RESULT_F	1
//variables
@lfsr 0x0A
@mode 0x0B
@buffer_ptr 0x0E
@buffer_start 0x10
@buffer_end 0x1F

:origin
	// Setup GP0,GP1,GP2,GP5 as output, GP3,GP4 as input
	movlw	00011000b
	tris	6
	//move literal into lfsr for 8-bit shift register
	movlw 0x78
	movwf lfsr
//Check GP4 for mode choice clear go choice_clear
//set go choice_set
:mode_choice
   	btfss GPIO, GP4
    	goto choice_clear
	goto choice_set
@dice_one 0x0C
//set mode equal to 1 for set
:choice_set
	movlw 1
	movwf mode
	goto check_start
//set mode equal to even working register for clear
:choice_clear
	movwf mode
//check if GP3 set if clear start roll if not don't
:check_start
	btfss GPIO, GP3
	goto loop
	goto check_start
//Check if GP3 is set if clear continue loop if not
//Go to bit_masking for mode choice
:continue
	btfss GPIO, GP3
	goto loop
	movf mode, w
	andlw 0001b
	btfss STATUS,Z
	goto bit_masking_set
	goto bit_masking_clear
//code used from Dr. Posnett on canvas 8-bit linear feedback shift register(Posnett)
//https://canvas.ucdavis.edu/courses/765142/assignments/1012635?module_item_id=1484419 
:loop
	call lfsr_galois
	goto continue
:lfsr_galois

// First clear the carry so that we know that it is zero. Now, shift the lfsr right
// putting the LSB in carry and copying the lfsr into the working register for more
// processing

	bcf STATUS,C
	rrf lfsr, RESULT_W

// If the carry (LSB) is set we want to
// xor the lfsr with our xor taps 8,6,5,4 (0,2,3,4)
//
	btfsc STATUS, C
	xorlw 10111000b
    //fun dispaly during the roll
	movwf GPIO
	movwf lfsr // save the new lfsr
	retlw 1
//bit masking for 2 die rolls 
:bit_masking_clear
    //mask the first roll
	movf lfsr, w
	andlw 111b
	movwf dice_one
    //mask the second roll
	movf lfsr, w
	andlw 00111000b
	movwf lfsr
	rrf lfsr, f
	rrf lfsr, f
	rrf lfsr, f
	movf lfsr, w
	andlw 111b
    //add up the two rolls
	addwf dice_one, w
	movwf lfsr
	goto display_number
//bit masking for the set mode choice
:bit_masking_set
    //set lsfr to the first 4 bits of original random number
	movf lfsr, w
	andlw 1111b
	movwf lfsr
:display_number
    //display first 3 bits
   	movwf GPIO
    //display the fourth bit
	andlw 1000b
	btfss STATUS, Z
	bsf GPIO, GP5
//referenced microntrollerjs.com while writing this segment Indirect memory addressing(Whiteley)
//http://microcontrollerjs.com/sim/microcontroller.html?file=stack.asm
:put_buffer
    //store in each ptr location in the buffer
	movlw buffer_start
	addwf buffer_ptr, w
	movwf FSR
	movf lfsr, w
	movwf INDF
    //check the size if 15 reset the buffer ptr if not increment 
    //the buffer_ptr by 1
	movf buffer_ptr, w
	xorlw 1111b
	btfsc STATUS,Z
	movwf buffer_ptr
	btfss STATUS, Z
	incf buffer_ptr, f
	goto check_start