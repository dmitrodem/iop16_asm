#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <strings.h>
#include <unistd.h>
#include <string.h>
#include "iop16_state.h"
#include "die.h"

#define CHUNKSIZE 128

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
  {"-h"             , "Display this help"},
  {"-o OUTFILE"     , "Output file name"},
  {"-l LABELS"      , "Generate list of labels"},
  {"-f [c|rom|hex]" , "Output format"},
  {"-b BASENAME"    , "Base name for C and ROM outputs"},
  {NULL             , NULL}
};

void help() {
  fprintf(stdout, "Usage: %s [OPTIONS] [INFILE]\n", progname);
  for (const struct help_entry_t *e = help_entries; e->option; e++) {
    fprintf(stdout, "%-20s %s\n",
            e->option, e->description);
  }
}

#ifndef TEST_LEXER
#ifndef TEST_PARSER

int main(int argc, char **argv) {

  int r;

  progname = malloc(strlen(argv[0])+1);
  if (progname == NULL) {
    die("Failed to allocate memory");
  }
  strcpy(progname, argv[0]);

  char *infile = NULL;
  char *outfile = NULL;
  char *labelsfile = NULL;
  char *basename = "rom";
  enum output_fmt_t fmt = FMT_UNK;
  int opt;
  while((opt = getopt(argc, argv, "ho:l:f:b:")) != -1) {
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
    case 'f':
      if      (strcasecmp(optarg, "c")   == 0) {fmt = FMT_C;  }
      else if (strcasecmp(optarg, "rom") == 0) {fmt = FMT_ROM;}
      else if (strcasecmp(optarg, "hex") == 0) {fmt = FMT_HEX;}
      break;
    case 'b':
      basename = optarg;
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

  if (ninputs > 1) {
    die("Invalid number of input files: %ld", ninputs);
  }

  yydebug = 0;

  struct {
    int rfd;
    int wfd;
  } p;

  r = pipe((void *)&p);
  if (r != 0) {
    die("Failed to create pipe");
  }

  r = fork();

  if (r < 0) {
    die("Failed to fork child process");
  }

  if (r == 0) {
    /* child process -- set up pipe and excecute C preprocessor */
    if (close(p.rfd) != 0) {
      die("Failed to close read end of pipe");
    }
    if (close(STDOUT_FILENO) != 0) {
      die("Failed to close stdout");
    }
    if (dup2(p.wfd, STDOUT_FILENO) == -1) {
      die("dup2() failed");
    }
    /* non-null infile -- replace STDIN */
    if (infile != NULL) {
      FILE *fp = fopen(infile, "r");
      if (fp == NULL) {
        die("Failed to open file: %s", infile);
      }
      if (close(STDIN_FILENO) != 0) {
        die("Failed to close stdin");
      }
      if (dup2(fileno(fp), STDIN_FILENO) == -1) {
        die("dup2() failed");
      }
    }
    char *const preprocessor[] = {"gcc", "-E", "-C", "-", NULL};
    if (execvp(preprocessor[0], preprocessor) == -1) {
      die("Failed to execute preprocessor");
    }
  }

  /* parent process -- read from pipe */
  char *buf = NULL;
  size_t buflen = 0;

  do {
    if (close(p.wfd) != 0) {
      die("Failed to close write end of pipe");
    }
    FILE *memfp = open_memstream(&buf, &buflen);
    if (memfp == NULL) {
      die("Failed to open_memstream()");
    }
    char tmpbuf[CHUNKSIZE];
    for(;;) {
      ssize_t n = read(p.rfd, tmpbuf, CHUNKSIZE);
      if (n == -1) {
        die("Failed to read from pipe");
      }
      if (n == 0) {
        break;
      }
      fwrite(tmpbuf, 1, n, memfp);
    }
    fclose(memfp);
    close(p.rfd);
  } while (0);

  if ((state.input = fmemopen(buf, buflen, "r")) == NULL) {
    die("Failed to open input file: %s", infile);
  }
  if (outfile) {
    if ((state.output = fopen(outfile, "w")) == NULL) {
      die("Failed to open output file: %s", outfile);
    }
  } else {
    state.output = stdout;
  }

  state.fmt = fmt;
  state.basename = basename;

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
  free(buf);
  free(progname);

  return EXIT_SUCCESS;
}
#endif
#endif
