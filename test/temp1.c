#include <stdio.h>

int hello_world();

int main() {

    int a;
    int b;
    int c;

    a = 1;
    b = a + 5;
    c = a + b;

    printf("calling sub\n");
    hello_world();

}
