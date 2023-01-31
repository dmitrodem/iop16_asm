#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include <sys/wait.h>
#include <stdint.h>
#include <stdbool.h>

char *iop16_asm[] = {"./iop16_asm", "-f", "raw"};

int runtest(const char *msg,
             const char *test,
            int (*handle)(int fd, void *userdata),
            void *userdata) {
  /* pipes[0] :: read end of test -> asm (read by asm) */
  /* pipes[1] :: write end of test -> asm (written by test) */
  /* pipes[2] :: read end of asm -> test (read by test) */
  /* pipes[3] :: write end of asm -> test (written by asm) */
  int pipes[4];
  int r;
  printf("Running %-32s ", msg);
  r = pipe(pipes);
  r = pipe(pipes+2);
  r = fork();
  if (r < 0) {
    return EXIT_FAILURE;
  } else if (r == 0) {
    /* child -- asm */
    close(STDIN_FILENO);
    close(STDOUT_FILENO);
    dup2(pipes[0], STDIN_FILENO);
    dup2(pipes[3], STDOUT_FILENO);
    close(pipes[0]);
    close(pipes[1]);
    close(pipes[2]);
    close(pipes[3]);
    execvp(*iop16_asm, iop16_asm);
  } else {
    /* parent -- test */
    close(pipes[0]);
    close(pipes[3]);

    write(pipes[1], test, strlen(test));
    close(pipes[1]);

    int result = (*handle)(pipes[2], userdata);
    close(pipes[2]);
    int wstatus;
    wait(&wstatus);
    if (WIFEXITED(wstatus) &&
        (WEXITSTATUS(wstatus) == EXIT_SUCCESS) &&
        (result == 1)) {
      printf("[OK]\n");
      return EXIT_SUCCESS;
    } else {
      printf("[ERR]\n");
      exit(EXIT_FAILURE);
    }
  }
  return EXIT_SUCCESS;
}

int handle_single_opcode_test(int fd, void *userdata) {
  uint16_t opcode;
  uint16_t *opcodes = (uint16_t *) userdata;
  int ok = 1;
  for (size_t n = 0; read(fd, &opcode, sizeof(opcode)) > 0; n += 1) {
    ok = ok & (opcode == opcodes[n]);
    /* printf("0x%04x\n", opcode); */
  }
  return ok;
}

int main() {
  uint16_t expected;

  expected = 0x2507;
  runtest("BCLR test #1", "bclr 5, 0x07", handle_single_opcode_test, &expected);

  expected = 0x27cd;
  runtest("BCLR test #2", "bclr 7, 0xcd", handle_single_opcode_test, &expected);

  expected = 0x2fcd;
  runtest("BSET test #1", "bset 7, 0xcd", handle_single_opcode_test, &expected);

  expected = 0x2800;
  runtest("BSET test #2", "bset 0, 0x00", handle_single_opcode_test, &expected);

  expected = 0x3854;
  runtest("SLL test #1", "sll r8, r5, 0x4", handle_single_opcode_test, &expected);

  expected = 0x3f07;
  runtest("SLL test #2", "sll rF, r0, 0x7", handle_single_opcode_test, &expected);

  expected = 0x3acf;
  runtest("SLR test #1", "slr rA, rC, 0x7", handle_single_opcode_test, &expected);

  expected = 0x40ab;
  runtest("LRI test #1", "lri r0, 0xab", handle_single_opcode_test, &expected);

  expected = 0x46cd;
  runtest("LRI test #2", "lri r6, 0xcd", handle_single_opcode_test, &expected);

  return EXIT_SUCCESS;
}
