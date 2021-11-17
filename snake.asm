;  set game state memory location
.equ    HEAD_X,         0x1000  ; Snake head's position on x
.equ    HEAD_Y,         0x1004  ; Snake head's position on y
.equ    TAIL_X,         0x1008  ; Snake tail's position on x
.equ    TAIL_Y,         0x100C  ; Snake tail's position on Y
.equ    SCORE,          0x1010  ; Score address
.equ    GSA,            0x1014  ; Game state array address

.equ    CP_VALID,       0x1200  ; Whether the checkpoint is valid.
.equ    CP_HEAD_X,      0x1204  ; Snake head's X coordinate. (Checkpoint)
.equ    CP_HEAD_Y,      0x1208  ; Snake head's Y coordinate. (Checkpoint)
.equ    CP_TAIL_X,      0x120C  ; Snake tail's X coordinate. (Checkpoint)
.equ    CP_TAIL_Y,      0x1210  ; Snake tail's Y coordinate. (Checkpoint)
.equ    CP_SCORE,       0x1214  ; Score. (Checkpoint)
.equ    CP_GSA,         0x1218  ; GSA. (Checkpoint)

.equ    LEDS,           0x2000  ; LED address
.equ    SEVEN_SEGS,     0x1198  ; 7-segment display addresses
.equ    RANDOM_NUM,     0x2010  ; Random number generator address
.equ    BUTTONS,        0x2030  ; Buttons addresses

; initialize stack pointer
addi    sp, zero, LEDS

; main
; arguments
;     none
;
; return values
;     This procedure should never return.
main:
    ; TODO: Finish this procedure.

    ret


; BEGIN: clear_leds
clear_leds:
	addi t1, r0, 8
	addi t2, t1, 8
  stw r0, LEDS(r0)
  stw r0, LEDS(t1)
  stw r0, LEDS(t2)
  
  ret
; END: clear_leds


; BEGIN: set_pixel
set_pixel:
  add $t1, LEDS, $a0
  ldb $t0, 0($t1)
  
  sll $t2, 1, $a1
  or $t0, $t0, $t2

  stb $t0, 0($t1)
  
  jr $ra
; END: set_pixel


; BEGIN: display_score
display_score:

; END: display_score


; BEGIN: init_game
init_game:

; END: init_game


; BEGIN: create_food
create_food:
  loop_until_valid_number:
    lb $t0, 0(RANDOM_NUM)
  
    bge $t0, 96, gsa_overflow
    ble  $t0, -1, gsa_underflow
    j valid_number
    
    gsa_overflow:
    gsa_underflow:
    j loop_until_valid_number
  
  valid_number:
    ;//create food in the GSA
    ;//multiply the number by 4
    sll $t0, $t0, 2
    add $t0, $t0, 0(GSA)
    sw $t0, 5
  jr $ra
; END: create_food


; BEGIN: hit_test
hit_test:

; END: hit_test


; BEGIN: get_input
get_input:
  lw $t0, 4(BUTTONS)
  sw $zero, 4(BUTTONS)
  
  add $v0, $zero, $zero
  add $t1, $zero, 1
  
  loop_over_buttons:
    beq $t1, 6, return
    and $t2, $t0, 1
    
    beq $t2, 0, not_pressed 
    add $v0, $zero, $t1
    add $t6, $zero, $t1
    
    not_pressed:
    
      srl $t0, $t0, 1
      add $t1, $t1, 1
      j loop_over_buttons
  return:
    beq $t6, 0, no_button_selected
    beq $t6, 5, checkpoint_selected
    
    lw $t4, 0(HEAD_X)
    lw $t3, 0(HEAD_Y)
  
    //je fais x * 8 + y et il sagit de l addresse dans GSA
    multu $t4, 8
    mflo $t4
    addu $t4, $t4, $t3 
  
    addu $t4, $t4, GSA
  
    lw $t5, 0($t4) //t5 contient la valeur de la tete du serpent
    addu $t5, $t5, $t6 //t6 contient la valeur du bouton appuyé
    
    beq $t5, 5, no_change_of_direction
      sw $t6, 0($t4)
    
    no_change_of_direction:
    no_button_selected:
    checkpoint_selected:
    jr $ra
  
; END: get_input

; BEGIN: draw_array
draw_array:
  add $t0, $zero, $zero ;//x
  add $t1, $zero, $zero ;//y
  loop_over_x:
    beq $t0, 12, end_of_loop
    loop_over_y:
      beq $t1, 8, end_of_y_loop
      
      ;//if GSA contains value different than 0 then call set_pixel
      ;//je fais x * 8 + y et il sagit de l addresse dans GSA
      multu $t0, 8
      mflo $t2
      addu $t2, $t2, $t1 
      addu $t2, $t2, GSA
      lw $t3, 0($t2) //t3 contient la valeur de la case du GSA
      
     ; //CALL set_pixel IF T3 IS EQUAL TO 0, I.E. IT IS NOT A SNAKE OR APPLE
      beq $t3, $zero, led_is_off
      
     ; //led must be turned on so we give it t0 and t1 as parameters
      add $a0, $t0, $zero
      add $a1, $t1, $zero
      
      ;//call set_pixel, but first save the registers that it uses
      addi $sp, $sp, -16
      sw $t0, 12($sp)
      sw $t1, 8($sp)
      sw $t2, 4($sp)
      sw $ra, 0($sp)
      
      jal set_pixel
      
      ;//get back the registers
      lw $t0, 12($sp)
      lw $t1, 8($sp)
      lw $t2, 4($sp)
      lw $ra, 0($sp)
      addi $sp, $sp, 16
      
      led_is_off:
      
      add $t1, $t1, 1
      
      j loop_over_y
    end_of_y_loop:
    add $t1, $zero, $zero 
    add $t0, $t0, 1
    
    j loop_over_x
  end_of_loop:
  jr $ra
; END: draw_array


; BEGIN: move_snake
move_snake:
  lw $t1, 0(HEAD_X)
  lw $t0, 0(HEAD_Y)
  
  //je fais x * 8 + y et il sagit de l addresse dans GSA
  multu $t1, 8
  mflo $t3
  addu $t2, $t0, $t3
  addu $t2, $t2, GSA
  //t2 contient l addresse de la tete

  lw $t3, 0($t2) //t3 contient la direction de la tete, entre 1 et 4
  
  //what happens in the case where new x or new y is negative
  bne $t3, 1, direction_is_not_left
    sub $t1, $t1, 1
  direction_is_not_left:
  
  bne $t3, 2, direction_is_not_up
    sub $t0, $t0, 1
  direction_is_not_up
  
  bne $t3, 3, direction_is_not_down
    add $t0, $t0, 1
  direction_is_not_down:
  
  bne $t3, 4, direction_is_not_right
    add $t1, $t1, 1
  direction_is_not_right:
  
  //je calcule l addresse de la nouvelle tete avec t0 et t1 qui contiennent
  //les nouvelles coordonnées de la tete
  //je fais x * 8 + y et il sagit de l addresse dans GSA
  multu $t1, 8
  mflo $t4
  addu $t2, $t0, $t4
  addu $t2, $t2, GSA
  //t2 contient l addresse de la nouvelle tete
  //on met la valeur de la tete precedente dans la nouvelle tete
  
  sw $t3, 0($t2)
  sw $t1, 0(HEAD_X)
  sw $t0, 0(HEAD_Y)
  
  //MAINTENANT ON S OCCUPE DE LA QUEUE
  
  lw $t1, 0(TAIL_X)
  lw $t0, 0(TAIL_Y)
  
  //je fais x * 8 + y et il sagit de l addresse dans GSA
  multu $t1, 8
  mflo $t3
  addu $t2, $t0, $t3
  addu $t2, $t2, GSA
  //t2 contient l addresse de la queue
  
  lw $t3, 0($t2) //t3 contient la direction de la queue, entre 1 et 4
  sw $zero, 0($t2) //l ancienne queue disparait
  
  //what happens in the case where new x or new y is negative
  bne $t3, 1, direction_is_not_left
    sub $t1, $t1, 1
  direction_is_not_left:
  
  bne $t3, 2, direction_is_not_up
    sub $t0, $t0, 1
  direction_is_not_up
  
  bne $t3, 3, direction_is_not_down
    add $t0, $t0, 1
  direction_is_not_down:
  
  bne $t3, 4, direction_is_not_right
    add $t1, $t1, 1
  direction_is_not_right:
  
  sw $t1, 0(TAIL_X)
  sw $t0, 0(TAIL_Y)
  
  jr $ra
; END: move_snake


; BEGIN: save_checkpoint
save_checkpoint:

; END: save_checkpoint


; BEGIN: restore_checkpoint
restore_checkpoint:

; END: restore_checkpoint


; BEGIN: blink_score
blink_score:

; END: blink_score