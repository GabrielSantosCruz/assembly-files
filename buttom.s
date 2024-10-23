
  .section .data
MEM_FD:          .asciz "/dev/mem"      @ Caminho para o arquivo /dev/mem
FPGA_BRIDGE:     .word 0xff200 @ endereco da ponte
KEY_BASE:        .word 0x0
  
  .section .rodata
msg_mmap_error:      .asciz "Mapping error\n"
msg_mmap_sucess:     .asciz "Successful mapping\n"
mmsg_mmap_error2:    .asciz "Mmap error\n"

  .section .text
  .global _start
  .type key, %function

  @ Definições de endereços para os displays de 7 segmentos
HW_REGS_SPAN:          .word 0x100       @ tamanho da pagina do mapeamento (256 kb) 

key:
  @abre o arquivo /dev/mem
  MOV r7, #5          @ syscall open
  LDR r0, =MEM_FD     @ caminho do arquivo
  MOV r1, #2          @ para leitura e escrita 
  MOV r2, #0          @ sem flags
  SWI 0               @ chama o sistema para executar
 
  MOV r4, r0          @ guarda o resultado em R4

  @ verificar se o arquivo foi aberto corretamente
  CMP r0,#0
  BLT _error @se r0 < 0 é erro
  
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
  
  @ escreve as parada aqui 
  ldr r1, =KEY_BASE
  ldr r1, [r1]
  ldr r2, [r11, r1]

  @fechar o arquivo /dev/mem
  mov r7, #6
  mov r0, r4
  svc 0

  ldr r0, r2

  bx lr

_error:
  mov r0, #1
  ldr r1, =msg_mmap_error @strin
  mov r2, #15 @tamanho da string
  mov r7, #4 @syscall para escrita
  svc 0
  bx lr

_errorMMAP:
  mov r0, #1
  ldr r1, =mmsg_mmap_error2
  mov r2, #12
  mov r7, #4
  svc 0
  bx lr

sucess:
  mov r0, #1
  ldr r1, =msg_mmap_sucess
  mov r2, #20
  mov r7, #4
  svc 0
  bx lr
 
_exit: @ funcao de sair, não aguento mais digitar sabomba
  mov r0, #0
  mov r7, #1
  svc 0
  bx lr
