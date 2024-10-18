  .section .data
MEM_FD:          .asciz "/dev/mem"      @ Caminho para o arquivo /dev/mem
FPGA_BRIDGE:     .word 0xff200 @ tem que verificar se esse valor tá correto pro tamanho do mapeamento que eu tô usando

  .section .rodata
msg_mmap_error:      .asciz "Deu erro no mapeamento pit\n"
msg_mmap_sucess:     .asciz "funfou\n"
mmsg_mmap_error2:    .asciz "erro no mmap\n"

  .section .text
  .global _start

  @ Definições de endereços para os displays de 7 segmentos
ALT_LWFPGASLVS_OFST:   .word 0xFF200000  @ Offset do barramento Lightweight HPS-to-FPGA
HW_REGS_SPAN:          .word 0x100       @ tamanho do mapeamento de memória (256 kb) 

HEX5_BASE: .word 0x10  @ Endereço do display HEX5 
HEX4_BASE: .word 0x20  @ Endereço do display HEX4 
HEX3_BASE: .word 0x30  @ Endereço do display HEX3 
HEX2_BASE: .word 0x40  @ Endereço do display HEX2 
HEX1_BASE: .word 0x50  @ Endereço do display HEX1
HEX0_BASE: .word 0x60  @ Endereço do display HEX0

_start:
  @abre o arquivo /dev/mem
  MOV r7, #5          @ syscall open
  LDR r0, =MEM_FD     @ caminho do arquivo
  MOV r1, #2          @ para leitura e escrita 
  MOV r2, #0          @ sem flags
  SWI 0               @ chama o sistema para executar
 
  MOV r4, r0          @ guarda o resultado em R4

  @ verificar se o arquivo foi aberto corretamente
  CMP r0,#0
  BLT _error @se r4 < 0 é erro
  
  BL sucess

  @bl _exit

  @ configurar o mmap
  mov r7, #192        @ syscall do mmap2
  mov r0, #0          @ para deixar o kernel decidir o enderço virtual
  ldr r1, =HW_REGS_SPAN @ tamanho da pagina
  mov r2, #3          @ leitura/escrita
  mov r3, #1          @ compartilhado com outros processos
  ldr r5, =FPGA_BRIDGE @carrega o endereço base da FPGA 
  ldr r5, [r5]        @ carrega o valor real do enderço da FPGA
  svc 0               @ kernel é chamado para executar a syscall

  @verificar falha no mmap
  cmp r0, #-1
  beq _errorMMAP

  @bl _exit
 
  mov r11, r0         @ endereço virtual retornado

  @escrever HELP nos displays
  ldr r1, =HEX5_BASE
  ldr r2, [r1]
  mov r3, #0x09 @ valor do led
  strb r3, [r11, r2] @tecnicamente é pra escrever no digito 5   
                @ou coloca r2 aqui no #HEX5_BASE se der erro
  ldr r1, =HEX4_BASE
  ldr r2, [r1]
  mov r3, #0x06 @ valor do led
  strb r3, [r11, r2] @tecnicamente é pra escrever no digito 5 

  ldr r1, =HEX3_BASE
  ldr r2, [r1]
  mov r3, #0x47 @ valor do led
  strb r3, [r11, r2] @tecnicamente é pra escrever no digito 5   

  ldr r1, =HEX2_BASE
  ldr r2, [r1]
  mov r3, #0xc @ valor do led
  strb r3, [r11, r2] @tecnicamente é pra escrever no digito 5 

  ldr r1, =HEX1_BASE
  ldr r2, [r1]
  mov r3, #0x7F @ valor do led
  strb r3, [r11, r2] @tecnicamente é pra escrever no digito 5 

  ldr r1, =HEX0_BASE
  ldr r2, [r1]
  mov r3, #0x7F @ valor do led
  strb r3, [r11, r2] @tecnicamente é pra escrever no digito 5 

  @fechar o arquivo /dev/mem
  mov r7, #6
  mov r0, r4
  svc 0

  bl _exit

_error:
  mov r0, #1
  ldr r1, =msg_mmap_error
  mov r2, #28
  mov r7, #4
  svc 0
  bx lr

_errorMMAP:
  mov r0, #1
  ldr r1, =mmsg_mmap_error2
  mov r2, #15
  mov r7, #4
  svc 0
  bx lr

sucess:
  mov r0, #1
  ldr r1, =msg_mmap_sucess
  mov r2, #8
  mov r7, #4
  svc 0
  bx lr
 
_exit: @ funcao de sair, não aguento mais digitar sabomba
  mov r0, #0
  mov r7, #1
  svc 0
  bx lr
