#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include "iop16_state.h"
#include "die.h"

static void init(struct iop16_state_t *self, enum pass_t pass);
static void append_instruction(struct iop16_state_t *self, uint16_t inst);

struct iop16_state_t state = {
  .input = NULL,
  .output = NULL,
  .init = init,
  .append_inst = append_instruction
};

static void init(struct iop16_state_t *self, enum pass_t pass) {
  self->reg = 0;
  self->imm = 0;
  self->column = 0;
  self->pass = pass;
  self->pc = 0;
  self->label[0] = '\0';
  if (pass == PASS1) {
    self->labels = NULL;
  } else if (pass == FINISH) {
    struct label_entry_t *e = self->labels;
    while (e) {
      struct label_entry_t *f = e;
      e = e->next;
      free(f);
    }
  }
  self->target_address = 0;
  if (pass == FINISH) {
    if (self->input) {
      fclose(self->input);
      self->input = NULL;
    }
    if (self->output) {
      switch (self->fmt) {
      case FMT_C:
        fprintf(self->output, "};\n");
        fprintf(self->output, "const size_t %s_rom_len = sizeof(%s_rom)/sizeof(%s_rom[0]);\n",
                state.basename, state.basename, state.basename);
        break;
      case FMT_HEX:
        break;
      case FMT_ROM:
        fprintf(self->output, "x\"0000\";\n");
        break;
      default:
        break;
      }
      fclose(self->output);
      self->output = NULL;
    }
  }
}

static void append_instruction(struct iop16_state_t *self, uint16_t inst) {
  switch (self->fmt) {
  case FMT_C:
    if (self->pc == 0) {
      fprintf(self->output, "#include <stdint.h>\n");
      fprintf(self->output, "#include <stddef.h>\n");
      if (self->width == WIDTH_16) {
        fprintf(self->output, "const uint16_t %s_rom[] = {\n",
                state.basename);
      } else if (self->width == WIDTH_8) {
        fprintf(self->output, "const uint8_t %s_rom[] = {\n",
                state.basename);
      }
    }
    if (self->width == WIDTH_16) {
      fprintf(self->output, "/* 0x%03lx */ 0x%04x,\n",
              self->pc, inst);
    } else if (self->width == WIDTH_8) {
      fprintf(self->output, "/* 0x%03lx */ 0x%02x, 0x%02x,\n",
              self->pc,
              (inst >> 8) & 0xff,
              (inst >> 0) & 0xff);
    }
    break;
  case FMT_HEX:
    fprintf(self->output, "%03lx: %04x\n", self->pc, inst);
    break;
  case FMT_ROM:
    if (self->pc == 0) {
      fprintf(self->output, "%s_rom <= \n", state.basename);
    }
    fprintf(self->output, "x\"%04x\" when address = x\"%03lx\" else\n", inst, self->pc);
  default:
    break;
  }
}

void iop16_append_label() {
  struct label_entry_t *e = malloc(sizeof(struct label_entry_t));
  if (e == NULL) {
    die("Failed to allocate memory");
  }
  e->address = state.pc;
  strncpy(e->label, state.label, MAX_LABEL_LENGTH-1);
  e->label[MAX_LABEL_LENGTH-1] = '\0';
  e->next = NULL;
  if (state.labels == NULL) {
    state.labels = e;
  } else {
    struct label_entry_t *last;
    for (struct label_entry_t *x = state.labels;
         x;
         x = x->next) {
      if (strcmp(state.label, x->label) == 0) {
        die("Duplicate label found: %s", state.label);
      }
      if (x->next == NULL) {
        last = x;
      }
    }
    last->next = e;
  }
}

uint16_t iop16_get_label_address(const char *label) {
  bool found = false;
  uint16_t address = 0;
  for (struct label_entry_t *e = state.labels;
       e;
       e = e->next) {
    if (strcmp(e->label, label) == 0) {
      found = true;
      address = (uint16_t) (e->address);
      break;
    }
  }
  if (!found) {
    die("Failed to find label %s", label);
  }
  return address;
}
