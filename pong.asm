stack segment para stack
    db 64 dup (' ')
stack ends

data segment para 'data'
    window_width dw 140h
    window_height dw 0c8h
    window_bounds dw 6
    time_aux db 0
    game_active db 1
    exiting_game db 0
    winner_index db 0
    current_scene db 0
    
    text_player_one_points db '0','$'
    text_player_two_points db '0','$'
    text_game_over_title db 'game over','$'
    text_game_over_winner db 'player 0 won','$'
    text_game_over_play_again db 'press r to play again','$'
    text_game_over_main_menu db 'press e to exit to main menu','$'
    text_main_menu_title db 'main menu','$'
    text_main_menu_singleplayer db 'singleplayer - s key','$'
    text_main_menu_multiplayer db 'multiplayer - m key','$'
    text_main_menu_exit db 'exit game - e key','$'
    
    ball_original_x dw 0a0h
    ball_original_y dw 64h
    ball_x dw 0a0h
    ball_y dw 64h
    ball_size dw 06h
    ball_velocity_x dw 05h
    ball_velocity_y dw 02h
    
    paddle_left_x dw 0ah
    paddle_left_y dw 55h
    player_one_points db 0
    
    paddle_right_x dw 130h
    paddle_right_y dw 55h
    player_two_points db 0
    
    paddle_width dw 06h
    paddle_height dw 25h
    paddle_velocity dw 0fh

data ends

code segment para 'code'

    main proc far
    assume cs:code,ds:data,ss:stack
    push ds
    sub ax,ax
    push ax
    mov ax,data
    mov ds,ax
    pop ax
    pop ax
    
    call clear_screen

    check_time:
        cmp exiting_game,01h
        je start_exit_process

        cmp current_scene,00h
        je show_main_menu

        cmp game_active,00h
        je show_game_over

        mov ah,2ch
        int 21h

        cmp dl,time_aux
        je check_time

        mov time_aux,dl

        call clear_screen

        call move_ball
        call draw_ball

        call move_paddles
        call draw_paddles

        call draw_ui

        jmp check_time

    show_game_over:
        call draw_game_over_menu
        jmp check_time

    show_main_menu:
        call draw_main_menu
        jmp check_time

    start_exit_process:
        call conclude_exit_game

    ret
    main endp

    move_ball proc near
        mov ax,ball_velocity_x
        add ball_x,ax

        mov ax,window_bounds
        cmp ball_x,ax
        jl give_point_to_player_two

        mov ax,window_width
        sub ax,ball_size
        sub ax,window_bounds
        cmp ball_x,ax
        jg give_point_to_player_one
        jmp move_ball_vertically

    give_point_to_player_one:
        inc player_one_points
        call reset_ball_position

        call update_text_player_one_points

        cmp player_one_points,05h
        jge game_over
        ret

    give_point_to_player_two:
        inc player_two_points
        call reset_ball_position

        call update_text_player_two_points

        cmp player_two_points,05h
        jge game_over
        ret

    game_over:
        cmp player_one_points,05h
        jnl winner_is_player_one
        jmp winner_is_player_two

    winner_is_player_one:
        mov winner_index,01h
        jmp continue_game_over
    winner_is_player_two:
        mov winner_index,02h
        jmp continue_game_over

    continue_game_over:
        mov player_one_points,00h
        mov player_two_points,00h
        call update_text_player_one_points
        call update_text_player_two_points
        mov game_active,00h
        ret

    move_ball_vertically:
        mov ax,ball_velocity_y
        add ball_y,ax

        mov ax,window_bounds
        cmp ball_y,ax
        jl neg_velocity_y

        mov ax,window_height
        sub ax,ball_size
        sub ax,window_bounds
        cmp ball_y,ax
        jg neg_velocity_y

        mov ax,ball_x
        add ax,ball_size
        cmp ax,paddle_right_x
        jng check_collision_with_left_paddle

        mov ax,paddle_right_x
        add ax,paddle_width
        cmp ball_x,ax
        jnl check_collision_with_left_paddle

        mov ax,ball_y
        add ax,ball_size
        cmp ax,paddle_right_y
        jng check_collision_with_left_paddle

        mov ax,paddle_right_y
        add ax,paddle_height
        cmp ball_y,ax
        jnl check_collision_with_left_paddle

        jmp neg_velocity_x

    check_collision_with_left_paddle:
        mov ax,ball_x
        add ax,ball_size
        cmp ax,paddle_left_x
        jng exit_collision_check

        mov ax,paddle_left_x
        add ax,paddle_width
        cmp ball_x,ax
        jnl exit_collision_check

        mov ax,ball_y
        add ax,ball_size
        cmp ax,paddle_left_y
        jng exit_collision_check

        mov ax,paddle_left_y
        add ax,paddle_height
        cmp ball_y,ax
        jnl exit_collision_check

        jmp neg_velocity_x

    neg_velocity_y:
        neg ball_velocity_y
        ret
    neg_velocity_x:
        neg ball_velocity_x
        ret

    exit_collision_check:
        ret
    move_ball endp

    move_paddles proc near
        mov ah,01h
        int 16h
        jz check_right_paddle_movement

        mov ah,00h
        int 16h

        cmp al,77h
        je move_left_paddle_up
        cmp al,57h
        je move_left_paddle_up

        cmp al,73h
        je move_left_paddle_down
        cmp al,53h
        je move_left_paddle_down
        jmp check_right_paddle_movement

    move_left_paddle_up:
        mov ax,paddle_velocity
        sub paddle_left_y,ax

        mov ax,window_bounds
        cmp paddle_left_y,ax
        jl fix_paddle_left_top_position
        jmp check_right_paddle_movement

    fix_paddle_left_top_position:
        mov paddle_left_y,ax
        jmp check_right_paddle_movement

    move_left_paddle_down:
        mov ax,paddle_velocity
        add paddle_left_y,ax
        mov ax,window_height
        sub ax,window_bounds
        sub ax,paddle_height
        cmp paddle_left_y,ax
        jg fix_paddle_left_bottom_position
        jmp check_right_paddle_movement

    fix_paddle_left_bottom_position:
        mov paddle_left_y,ax
        jmp check_right_paddle_movement

    check_right_paddle_movement:
        cmp al,6fh
        je move_right_paddle_up
        cmp al,4fh
        je move_right_paddle_up

        cmp al,6ch
        je move_right_paddle_down
        cmp al,4ch
        je move_right_paddle_down
        jmp exit_paddle_movement

    move_right_paddle_up:
        mov ax,paddle_velocity
        sub paddle_right_y,ax

        mov ax,window_bounds
        cmp paddle_right_y,ax
        jl fix_paddle_right_top_position
        jmp exit_paddle_movement

    fix_paddle_right_top_position:
        mov paddle_right_y,ax
        jmp exit_paddle_movement

    move_right_paddle_down:
        mov ax,paddle_velocity
        add paddle_right_y,ax
        mov ax,window_height
        sub ax,window_bounds
        sub ax,paddle_height
        cmp paddle_right_y,ax
        jg fix_paddle_right_bottom_position
        jmp exit_paddle_movement

    fix_paddle_right_bottom_position:
        mov paddle_right_y,ax
        jmp exit_paddle_movement

    exit_paddle_movement:
        ret

    move_paddles endp

    reset_ball_position proc near
        mov ax,ball_original_x
        mov ball_x,ax

        mov ax,ball_original_y
        mov ball_y,ax

        neg ball_velocity_x
        neg ball_velocity_y

        ret
    reset_ball_position endp

    draw_ball proc near
        mov cx,ball_x
        mov dx,ball_y

    draw_ball_horizontal:
        mov ah,0ch
        mov al,0fh
        mov bh,00h
        int 10h

        inc cx
        mov ax,cx
        sub ax,ball_x
        cmp ax,ball_size
        jng draw_ball_horizontal

        mov cx,ball_x
        inc dx

        mov ax,dx
        sub ax,ball_y
        cmp ax,ball_size
        jng draw_ball_horizontal

        ret
    draw_ball endp

    draw_paddles proc near
        ; omitted since it's not relevant to cleanup
        ret
    draw_paddles endp

    draw_game_over_menu proc near
        ; omitted since it's not relevant to cleanup
        ret
    draw_game_over_menu endp

    draw_main_menu proc near
        ; omitted since it's not relevant to cleanup
        ret
    draw_main_menu endp

    update_winner_text proc near
        mov al,winner_index
        add al,30h
        mov [text_game_over_winner+7],al
        ret
    update_winner_text endp

    clear_screen proc near            
        mov ah,00h
        mov al,13h
        int 10h
        mov ah,0bh
        mov bh,00h
        mov bl,00h
        int 10h
        ret
    clear_screen endp

    conclude_exit_game proc near         
        mov ah,00h
        mov al,02h
        int 10h
        mov ah,4ch
        int 21h
    conclude_exit_game endp

code ends
end
