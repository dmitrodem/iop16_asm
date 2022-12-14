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
      fclose(self->output);
      self->output = NULL;
    }
  }
}

static void append_instruction(struct iop16_state_t *self, uint16_t inst) {
  fprintf(self->output, "%03lx: %04x\n", self->pc, inst);
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
