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

dataA: .word 0x80
dataB: .word 0x70
WRREG: .word 0xc0

_start:
  @abre o arquivo /dev/mem
  MOV r7, #5          @ syscall open
  LDR r0, =MEM_FD     @ caminho do arquivo
  MOV r1, #2          
  MOV r2, #0          @ sem flags
  SWI 0               @ chama o sistema para executar
 
  @ verificar se o arquivo foi aberto corretamente
  CMP r0,#0
  BLT _error @se r4 < 0 é erro
  
  BL sucess

  @bl _exit

  @ configurar o mmap
  mov r7, #192        @ syscall do mmap2
  mov r0, #0          @ para deixar o kernel decidir o enderço virtual
  ldr r1, = HW_REGS_SPAN @ tamanho da pagina
  mov r2, #3          @ leitura/escrita
  mov r3, #1          @ compartilhado com outros processos
  ldr r5, =FPGA_BRIDGE @carrega o endereço base da FPGA 
  ldr r5, [r5]        @ carrega o valor do FPGA_BRIDGE (é basicamente um ponteiro)
  svc 0               @ kernel é chamado para executar a syscall

  @verificar falha no mmap
  cmp r0, #-1
  beq _errorMMAP

  @bl _exit
 
  mov r11, r0         @ endereço virtual retornado
  
  @adiciona um valor logico baixo ao start
  mov r5, #0
  strb r5, [r11, #0xc0] @escreve no lugar do endereco de memoria

  @os valores do dataA para executar a instrução WSM (se não me engano)
  ldr r1, =dataA @ só recebe o opcode e o endereco
  @ldr r1, [r1] @ ver se isso aqui funciona tbm
  mov r2, #0b0010 @opcode
  mov r3, #0b0 @ endereco
  lsl r3, r3, #4 @ arrasta 4 bits para a esquerda
  add r3, r3, r2 @ soma os valores em r3, para ficar em um só binário
  str r3, [r11, [dataA]] @se não funfar, coloca o endereco direto
  
  @valores de dataB para o WSM (realmente não lembro se era essa instrução)
  mov r4, #0b111 @RGB
  lsl r4, r4, #6
  add r4, r4, #0b111
  str r4, [r11, #0x70] @carrega a cor em binario no endereco de dataB
 
  mov r5, #1 
  str r5, [r11, #0xc0]

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
