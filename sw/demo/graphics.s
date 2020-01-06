; -*- mode: mr32asm; tab-width: 4; indent-tabs-mode: nil; -*-
; -------------------------------------------------------------------------------------------------
; This is a small graphics test.
; -------------------------------------------------------------------------------------------------

; Memory mapped I/O registers for controlling the GPU.
MMIO_GPU_BASE     = 0x00000100  ; Base address of the GPU MMIO registers.
MMIO_GPU_ADDR     = 0x00        ; Start of the framebuffer memory area.
MMIO_GPU_WIDTH    = 0x04        ; Width of the framebuffer (in pixels).
MMIO_GPU_HEIGHT   = 0x08        ; Height of the framebuffer (in pixels).
MMIO_GPU_DEPTH    = 0x0c        ; Number of bits per pixel.
MMIO_GPU_FRAME_NO = 0x20        ; Current frame number.

; Video configuration.
VID_MEM    = 0x00010000
VID_WIDTH  = 256
VID_HEIGHT = 256
VID_DEPTH  = 32

; -------------------------------------------------------------------------------------------------
; Main program.
; -------------------------------------------------------------------------------------------------

    .text
    .globl  main
    .p2align 2

main:
    ; Set up the graphics mode.
    ldi     s10, #MMIO_GPU_BASE
    ldi     s11, #VID_MEM
    stw     s11, s10, #MMIO_GPU_ADDR
    ldi     s11, #VID_WIDTH
    stw     s11, s10, #MMIO_GPU_WIDTH
    ldi     s11, #VID_HEIGHT
    stw     s11, s10, #MMIO_GPU_HEIGHT
    ldi     s11, #VID_DEPTH
    stw     s11, s10, #MMIO_GPU_DEPTH

    cpuid   s13, z, z
    mov     vl, s13
    lsl     s14, s13, #2    ; s14 = memory stride per vector operation

    add     s1, s13, #-1
    ldea    v4, s1, #-1     ; v4 is a ramp from vl-1 downto 0

    add     s21, pc, #sine1024@pc  ; s21 = start of 1024-entry sine table
    ldi     s12, #0         ; s12 = last frame number

begin_new_frame:
    ldi     s6, #VID_MEM    ; s6 = video frame buffer

    ldi     s8, #VID_HEIGHT ; s8 = y counter
loop_y:
    add     s8, s8, #-1     ; Decrement the y counter

    ldi     s7, #VID_WIDTH  ; s7 = x counter
loop_x:
    min     vl, s13, s7
    sub     s7, s7, vl      ; Decrement the x counter

    ; Some funky kind of test pattern...
    add     v7, v4, s7

    lsl     s20, s12, #1
    add     s20, s7, s20
    add     v9, v4, s20
    and     v8, v9, #1023
    lsl     v8, v8, #1
    ldh     v8, s21, v8
    mulq.h  v7, v7, v8

    add     s9, s8, s12
    add     v1, v7, s9
    shuf    v1, v7, v1

    shuf    v8, v9, #0b0000000001010
    adds.b  v1, v1, v8

    stw     v1, s6, #4
    add     s6, s6, s14     ; Increment the memory pointer

    bgt     s7, #loop_x
    bgt     s8, #loop_y

wait_vblank:
    ldw     s11, s10, #MMIO_GPU_FRAME_NO
    sne     s1, s11, s12
    bns     s1, #wait_vblank
    mov     s12, s11

    b       #begin_new_frame


    .data

sine1024:
    ; This is a 1024-entry LUT of sin(x), in Q15 format.
    .half   0, 201, 402, 603, 804, 1005, 1206, 1407, 1608, 1809, 2009, 2210, 2410, 2611, 2811
    .half   3012, 3212, 3412, 3612, 3811, 4011, 4210, 4410, 4609, 4808, 5007, 5205, 5404, 5602
    .half   5800, 5998, 6195, 6393, 6590, 6786, 6983, 7179, 7375, 7571, 7767, 7962, 8157, 8351
    .half   8545, 8739, 8933, 9126, 9319, 9512, 9704, 9896, 10087, 10278, 10469, 10659, 10849
    .half   11039, 11228, 11417, 11605, 11793, 11980, 12167, 12353, 12539, 12725, 12910, 13094
    .half   13279, 13462, 13645, 13828, 14010, 14191, 14372, 14553, 14732, 14912, 15090, 15269
    .half   15446, 15623, 15800, 15976, 16151, 16325, 16499, 16673, 16846, 17018, 17189, 17360
    .half   17530, 17700, 17869, 18037, 18204, 18371, 18537, 18703, 18868, 19032, 19195, 19357
    .half   19519, 19680, 19841, 20000, 20159, 20317, 20475, 20631, 20787, 20942, 21096, 21250
    .half   21403, 21554, 21705, 21856, 22005, 22154, 22301, 22448, 22594, 22739, 22884, 23027
    .half   23170, 23311, 23452, 23592, 23731, 23870, 24007, 24143, 24279, 24413, 24547, 24680
    .half   24811, 24942, 25072, 25201, 25329, 25456, 25582, 25708, 25832, 25955, 26077, 26198
    .half   26319, 26438, 26556, 26674, 26790, 26905, 27019, 27133, 27245, 27356, 27466, 27575
    .half   27683, 27790, 27896, 28001, 28105, 28208, 28310, 28411, 28510, 28609, 28706, 28803
    .half   28898, 28992, 29085, 29177, 29268, 29358, 29447, 29534, 29621, 29706, 29791, 29874
    .half   29956, 30037, 30117, 30195, 30273, 30349, 30424, 30498, 30571, 30643, 30714, 30783
    .half   30852, 30919, 30985, 31050, 31113, 31176, 31237, 31297, 31356, 31414, 31470, 31526
    .half   31580, 31633, 31685, 31736, 31785, 31833, 31880, 31926, 31971, 32014, 32057, 32098
    .half   32137, 32176, 32213, 32250, 32285, 32318, 32351, 32382, 32412, 32441, 32469, 32495
    .half   32521, 32545, 32567, 32589, 32609, 32628, 32646, 32663, 32678, 32692, 32705, 32717
    .half   32728, 32737, 32745, 32752, 32757, 32761, 32765, 32766, 32767, 32766, 32765, 32761
    .half   32757, 32752, 32745, 32737, 32728, 32717, 32705, 32692, 32678, 32663, 32646, 32628
    .half   32609, 32589, 32567, 32545, 32521, 32495, 32469, 32441, 32412, 32382, 32351, 32318
    .half   32285, 32250, 32213, 32176, 32137, 32098, 32057, 32014, 31971, 31926, 31880, 31833
    .half   31785, 31736, 31685, 31633, 31580, 31526, 31470, 31414, 31356, 31297, 31237, 31176
    .half   31113, 31050, 30985, 30919, 30852, 30783, 30714, 30643, 30571, 30498, 30424, 30349
    .half   30273, 30195, 30117, 30037, 29956, 29874, 29791, 29706, 29621, 29534, 29447, 29358
    .half   29268, 29177, 29085, 28992, 28898, 28803, 28706, 28609, 28510, 28411, 28310, 28208
    .half   28105, 28001, 27896, 27790, 27683, 27575, 27466, 27356, 27245, 27133, 27019, 26905
    .half   26790, 26674, 26556, 26438, 26319, 26198, 26077, 25955, 25832, 25708, 25582, 25456
    .half   25329, 25201, 25072, 24942, 24811, 24680, 24547, 24413, 24279, 24143, 24007, 23870
    .half   23731, 23592, 23452, 23311, 23170, 23027, 22884, 22739, 22594, 22448, 22301, 22154
    .half   22005, 21856, 21705, 21554, 21403, 21250, 21096, 20942, 20787, 20631, 20475, 20317
    .half   20159, 20000, 19841, 19680, 19519, 19357, 19195, 19032, 18868, 18703, 18537, 18371
    .half   18204, 18037, 17869, 17700, 17530, 17360, 17189, 17018, 16846, 16673, 16499, 16325
    .half   16151, 15976, 15800, 15623, 15446, 15269, 15090, 14912, 14732, 14553, 14372, 14191
    .half   14010, 13828, 13645, 13462, 13279, 13094, 12910, 12725, 12539, 12353, 12167, 11980
    .half   11793, 11605, 11417, 11228, 11039, 10849, 10659, 10469, 10278, 10087, 9896, 9704
    .half   9512, 9319, 9126, 8933, 8739, 8545, 8351, 8157, 7962, 7767, 7571, 7375, 7179, 6983
    .half   6786, 6590, 6393, 6195, 5998, 5800, 5602, 5404, 5205, 5007, 4808, 4609, 4410, 4210
    .half   4011, 3811, 3612, 3412, 3212, 3012, 2811, 2611, 2410, 2210, 2009, 1809, 1608, 1407
    .half   1206, 1005, 804, 603, 402, 201, 0, -201, -402, -603, -804, -1005, -1206, -1407
    .half   -1608, -1809, -2009, -2210, -2410, -2611, -2811, -3012, -3212, -3412, -3612, -3811
    .half   -4011, -4210, -4410, -4609, -4808, -5007, -5205, -5404, -5602, -5800, -5998, -6195
    .half   -6393, -6590, -6786, -6983, -7179, -7375, -7571, -7767, -7962, -8157, -8351, -8545
    .half   -8739, -8933, -9126, -9319, -9512, -9704, -9896, -10087, -10278, -10469, -10659
    .half   -10849, -11039, -11228, -11417, -11605, -11793, -11980, -12167, -12353, -12539
    .half   -12725, -12910, -13094, -13279, -13462, -13645, -13828, -14010, -14191, -14372
    .half   -14553, -14732, -14912, -15090, -15269, -15446, -15623, -15800, -15976, -16151
    .half   -16325, -16499, -16673, -16846, -17018, -17189, -17360, -17530, -17700, -17869
    .half   -18037, -18204, -18371, -18537, -18703, -18868, -19032, -19195, -19357, -19519
    .half   -19680, -19841, -20000, -20159, -20317, -20475, -20631, -20787, -20942, -21096
    .half   -21250, -21403, -21554, -21705, -21856, -22005, -22154, -22301, -22448, -22594
    .half   -22739, -22884, -23027, -23170, -23311, -23452, -23592, -23731, -23870, -24007
    .half   -24143, -24279, -24413, -24547, -24680, -24811, -24942, -25072, -25201, -25329
    .half   -25456, -25582, -25708, -25832, -25955, -26077, -26198, -26319, -26438, -26556
    .half   -26674, -26790, -26905, -27019, -27133, -27245, -27356, -27466, -27575, -27683
    .half   -27790, -27896, -28001, -28105, -28208, -28310, -28411, -28510, -28609, -28706
    .half   -28803, -28898, -28992, -29085, -29177, -29268, -29358, -29447, -29534, -29621
    .half   -29706, -29791, -29874, -29956, -30037, -30117, -30195, -30273, -30349, -30424
    .half   -30498, -30571, -30643, -30714, -30783, -30852, -30919, -30985, -31050, -31113
    .half   -31176, -31237, -31297, -31356, -31414, -31470, -31526, -31580, -31633, -31685
    .half   -31736, -31785, -31833, -31880, -31926, -31971, -32014, -32057, -32098, -32137
    .half   -32176, -32213, -32250, -32285, -32318, -32351, -32382, -32412, -32441, -32469
    .half   -32495, -32521, -32545, -32567, -32589, -32609, -32628, -32646, -32663, -32678
    .half   -32692, -32705, -32717, -32728, -32737, -32745, -32752, -32757, -32761, -32765
    .half   -32766, -32767, -32766, -32765, -32761, -32757, -32752, -32745, -32737, -32728
    .half   -32717, -32705, -32692, -32678, -32663, -32646, -32628, -32609, -32589, -32567
    .half   -32545, -32521, -32495, -32469, -32441, -32412, -32382, -32351, -32318, -32285
    .half   -32250, -32213, -32176, -32137, -32098, -32057, -32014, -31971, -31926, -31880
    .half   -31833, -31785, -31736, -31685, -31633, -31580, -31526, -31470, -31414, -31356
    .half   -31297, -31237, -31176, -31113, -31050, -30985, -30919, -30852, -30783, -30714
    .half   -30643, -30571, -30498, -30424, -30349, -30273, -30195, -30117, -30037, -29956
    .half   -29874, -29791, -29706, -29621, -29534, -29447, -29358, -29268, -29177, -29085
    .half   -28992, -28898, -28803, -28706, -28609, -28510, -28411, -28310, -28208, -28105
    .half   -28001, -27896, -27790, -27683, -27575, -27466, -27356, -27245, -27133, -27019
    .half   -26905, -26790, -26674, -26556, -26438, -26319, -26198, -26077, -25955, -25832
    .half   -25708, -25582, -25456, -25329, -25201, -25072, -24942, -24811, -24680, -24547
    .half   -24413, -24279, -24143, -24007, -23870, -23731, -23592, -23452, -23311, -23170
    .half   -23027, -22884, -22739, -22594, -22448, -22301, -22154, -22005, -21856, -21705
    .half   -21554, -21403, -21250, -21096, -20942, -20787, -20631, -20475, -20317, -20159
    .half   -20000, -19841, -19680, -19519, -19357, -19195, -19032, -18868, -18703, -18537
    .half   -18371, -18204, -18037, -17869, -17700, -17530, -17360, -17189, -17018, -16846
    .half   -16673, -16499, -16325, -16151, -15976, -15800, -15623, -15446, -15269, -15090
    .half   -14912, -14732, -14553, -14372, -14191, -14010, -13828, -13645, -13462, -13279
    .half   -13094, -12910, -12725, -12539, -12353, -12167, -11980, -11793, -11605, -11417
    .half   -11228, -11039, -10849, -10659, -10469, -10278, -10087, -9896, -9704, -9512, -9319
    .half   -9126, -8933, -8739, -8545, -8351, -8157, -7962, -7767, -7571, -7375, -7179, -6983
    .half   -6786, -6590, -6393, -6195, -5998, -5800, -5602, -5404, -5205, -5007, -4808, -4609
    .half   -4410, -4210, -4011, -3811, -3612, -3412, -3212, -3012, -2811, -2611, -2410, -2210
    .half   -2009, -1809, -1608, -1407, -1206, -1005, -804, -603, -402, -201
