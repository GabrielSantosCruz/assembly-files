#include <stdio.h>

extern int key();

void main(){
  while(1){
    int key = _start();
    printf("%d", key);
  }
}
