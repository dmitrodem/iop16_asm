#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include "iop16_state.h"
#include "die.h"

extern int yydebug;
extern int yyparse();
extern void yyrestart(FILE* fd);
extern FILE* yyin;
void yyerror(const char* s);

static char *progname;

struct help_entry_t {
  const char *option;
  const char *description;
};

static const struct help_entry_t help_entries[] = {
  {"-h",         "Display this help"},
  {"-o OUTFILE", "Output file name"},
  {"-l LABELS",  "Generate list of labels"},
  {NULL, NULL}
};

void help() {
  fprintf(stdout, "Usage: %s [OPTIONS] INFILE\n", progname);
  for (const struct help_entry_t *e = help_entries; e->option; e++) {
    fprintf(stdout, "%-20s %s\n",
            e->option, e->description);
  }
}

int main(int argc, char **argv) {

  progname = malloc(strlen(argv[0])+1);
  if (progname == NULL) {
    die("Failed to allocate memory");
  }
  strcpy(progname, argv[0]);

  char *infile = NULL;
  char *outfile = NULL;
  char *labelsfile = NULL;
  int opt;
  while((opt = getopt(argc, argv, "ho:l:")) != -1) {
    switch (opt) {
    case 'h':
      help();
      exit(EXIT_SUCCESS);
      break;
    case 'o':
      outfile = optarg;
      break;
    case 'l':
      labelsfile = optarg;
      break;
    case '?':
    default:
      help();
      exit(EXIT_FAILURE);
      break;
    }
  }

  size_t ninputs = 0;
  for (int i = optind; i < argc; i++) {
    infile = argv[i];
    ninputs += 1;
  }

  if (ninputs != 1) {
    die("Invalid number of input files: %ld", ninputs);
  }

  yydebug = 0;

  if ((state.input = fopen(infile, "r")) == NULL) {
    die("Failed to open input file: %s", infile);
  }
  if (outfile) {
    if ((state.output = fopen(outfile, "w")) == NULL) {
      die("Failed to open output file: %s", outfile);
    }
  } else {
    state.output = stdout;
  }

  yyin = state.input;

  /* Pass 1 -- map labels to addresses */
  state.init(&state, PASS1);
  if (yyparse() != 0) {
    die("Failed to parse input file");
  }
  printf("number of instructions = %ld\n", state.pc);
  if (labelsfile) {
    FILE* labelsfd = fopen(labelsfile, "w");
    if (labelsfd == NULL) {
      fprintf(stderr, "Failed to write labels to file %s\n", labelsfile);
    } else {
      for (struct label_entry_t *e = state.labels; e; e = e->next) {
        fprintf(labelsfd, "0x%03lx : %s\n", e->address, e->label);
      }
      fclose(labelsfd);
    }
  }

  /* Pass 2 -- generate machine codes */
  state.init(&state, PASS2);
  rewind(yyin);
  yyrestart(yyin);
  if (yyparse() != 0) {
    die("Failed to parse input file");
  }

  /* Finish -- close files, free labels table */
  state.init(&state, FINISH);
  free(progname);

  return EXIT_SUCCESS;
}
