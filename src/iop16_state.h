#ifndef __IOP16_STATE__
#define __IOP16_STATE__
#include <stdlib.h>
#include <stdint.h>
#include <stdio.h>

#define MAX_LABEL_LENGTH 32
#define MAX_LINE 1024

#define OP_OP0 0x0
#define OP_OP1 0x1
#define OP_OP2 0x2
#define OP_OP3 0x3
#define OP_LRI 0x4
#define OP_CMP 0x5
#define OP_IOR 0x6
#define OP_IOW 0x7
#define OP_XRI 0x8
#define OP_ORI 0x9
#define OP_ARI 0xa
#define OP_ADI 0xb
#define OP_JSR 0xc
#define OP_JMP 0xd
#define OP_BEZ 0xe
#define OP_BNZ 0xf

struct label_entry_t;
struct label_entry_t {
  size_t address;
  char label[MAX_LABEL_LENGTH];
  struct label_entry_t *next;
};

enum pass_t {
  PASS1 = 0,
  PASS2,
  FINISH
};

enum output_fmt_t {
  FMT_UNK,
  FMT_C,
  FMT_ROM,
  FMT_HEX
};

struct iop16_state_t;
struct iop16_state_t {
  int reg;
  int imm;
  size_t column;
  size_t line;

  enum pass_t pass;
  size_t pc;
  char label[MAX_LABEL_LENGTH];
  struct label_entry_t *labels;
  uint16_t target_address;

  FILE* input;
  FILE* output;

  enum output_fmt_t fmt;
  const char *basename;
  char cur_line[MAX_LINE];
  size_t cur_ptr;
  size_t cur_prev_ptr;
  char last_line[MAX_LINE];

  void (*init)(struct iop16_state_t *self, enum pass_t pass);
  void (*append_inst)(struct iop16_state_t *self, uint16_t inst);
};

extern struct iop16_state_t state;
void iop16_append_label();
uint16_t iop16_get_label_address(const char *label);

#endif /* __IOP16_STATE__ */
