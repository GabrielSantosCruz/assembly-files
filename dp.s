  .section .data
MEM_FD:          .asciz "/dev/mem"      @ Caminho para o arquivo /dev/mem
FPGA_BRIDGE:     .word 0xff200 @ endereco da ponte
dataA: .word 0x80
dataB: .word 0x70

  .section .rodata
msg_mmap_error:      .asciz "Mapping error\n"
msg_mmap_sucess:     .asciz "Successful mapping\n"
mmsg_mmap_error2:    .asciz "Mmap error\n"

  .section .text
  .global _start

  @ Definições de endereços para os displays de 7 segmentos
HW_REGS_SPAN:          .word 0x100       @ tamanho da pagina do mapeamento (256 kb) 

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

  @tentar desenhar um triangulo no monitor
  @ zera o sinal de start
  mov r0, #0
  strd r0, [r11, #0xc0]
 
  @dataA
  mov r0, #0b0011 @opcode
  mov r1, #0b0000 @ endereco
  lsl r1, r1, #4
  add r1, r1, r0
  str r2, [dataA]
  str r1, [r11, [dataA]] @ se der erro, coloca r2
    
  @dataB
  mov r0, #1 @ forma de um triangulo
  lsl r0, r0, #31 @ se der erro, pode ser que isso aqui seja 32 k
  mov r1, #0b011100111 @tecnicamente é pra isso ser laranaja
  lsl r1, r1, #21
  add r0, r0, r1
  mov r2, #0b1111 @tamanho, que e pra ser 160x160
  lsl r2, r2, #17
  add r0, r0, r2
  @ como eu quero que fique com x=0 e y=0, tecnicamente eu não preciso adicionar esses valore
  str r3, [dataB]
  str r0, [r11, r3]

  mov r5, #1
  str r5, [r11, #0xc0]

  @fechar o arquivo /dev/mem
  mov r7, #6
  mov r0, r4
  svc 0

  bl _exit

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
