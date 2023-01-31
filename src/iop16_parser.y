%{
#include <stdio.h>
#include <string.h>
#include "die.h"
#include "iop16_state.h"

extern int yylineno;
extern char *yytext;
extern int yylex();
extern int yyparse();
extern void yyrestart(FILE* fd);
extern FILE* yyin;

void yyerror(const char* s);
static void chkreg(unsigned int v);
static void chkimm(unsigned int v, size_t n);
static void chkaddr(unsigned int v);

#ifdef TEST_PARSER
#define dbg(...) {printf(__VA_ARGS__);}
#else
#define dbg(...) {}
#endif

#define YYERROR_VERBOSE 1
%}

%define api.value.type {unsigned int}

%token T_COLON T_COMMA T_LPAREN T_RPAREN
%token T_NUMBER
%token T_LSHIFT T_RSHIFT
%token T_BTARGET T_IMM T_REG
%token T_BCLR T_BSET
%token T_SLL T_SLR
%token T_LRI
%token T_RTS
%token T_IOR T_IOW
%token T_XRI T_ORI T_ARI T_ADI
%token T_JSR T_JMP T_BEZ T_BNZ


%left T_LSHIFT T_RSHIFT
%left '&' '|' '^'
%left '+' '-'
%left '*' '/'
%left '~'
%left T_UMINUS

%start program_body

%%
expression:     T_NUMBER
                {
                    $$ = $1;
                    dbg("T_NUMBER: %i\n", $$);
                } |
                expression '+' expression
                {
                    $$ = $1 + $3;
                    dbg("T_PLUS: %i + %i = %i\n", $1, $3, $$);
                } |
                expression '-' expression
                {
                    $$ = $1 - $3;
                    dbg("T_MINUS: %i - %i = %i\n", $1, $3, $$);
                } |
                expression '*' expression
                {
                    $$ = $1 * $3;
                    dbg("T_MUL: %i * %i = %i\n", $1, $3, $$);
                } |
                expression '/' expression
                {
                    $$ = $1 / $3;
                    dbg("T_DIV: %i / %i = %i\n", $1, $3, $$);
                } |
                expression '|' expression
                {
                    $$ = $1 | $3;
                    dbg("T_OR: %i | %i = %i\n", $1, $3, $$);
                } |
                expression '&' expression
                {
                    $$ = $1 & $3;
                    dbg("T_AND: %i & %i = %i\n", $1, $3, $$);
                } |
                expression '^' expression
                {
                    $$ = $1 ^ $3;
                    dbg("T_XOR: %i ^ %i = %i\n", $1, $3, $$);
                } |
                expression T_LSHIFT expression
                {
                    $$ = $1 << $3;
                    dbg("T_LSHIFT: %i << %i = %i\n", $1, $3, $$);
                } |
                expression T_RSHIFT expression
                {
                    $$ = $1 >> $3;
                    dbg("T_RSHIFT: %i >> %i = %i\n", $1, $3, $$);
                } |
                '~' expression
                {
                    $$ = ~$2;
                    dbg("T_NOT: ~%i = %i\n", $2, $$);
                } |
                '-' expression %prec T_UMINUS
                {
                    $$ = -$2;
                    dbg("T_UMINUS: -%i = %i\n", $2, $$);
                } |
                T_LPAREN expression T_RPAREN
                {
                    $$ = $2;
                    dbg("T_PAREN: (%i) = %i\n", $2, $$);
                }
        ;

program_body:   instr_line |
                program_body instr_line
        ;
instr_line:     blabel T_COLON instr
                {
                    if (state.pass == PASS1) {
                        iop16_append_label();
                    }
                    state.pc += 1;
                } |
                instr {
                    state.pc += 1;
                }
        ;

instr:
                bclr_instruction |
                bset_instruction |
                sll_instruction |
                slr_instruction |
                rts_instruction |
                lri_instruction |
                iow_instruction |
                ior_instruction |
                xri_instruction |
                ori_instruction |
                ari_instruction |
                adi_instruction |
                jsr_instruction |
                jmp_instruction |
                bez_instruction |
                bnz_instruction
        ;
bclr_instruction:
                T_BCLR imm3 T_COMMA imm3
                {
                    if (state.pass = PASS2) {
                        state.append_inst(&state,
                                          (OP_OP2 << 12) |
                                          ((((uint16_t) ($4)) & 0x7) << 8) |
                                          (((uint16_t) ($2)) & 0xff));

                    }
                }
        ;
bset_instruction:
                T_BSET imm3 T_COMMA imm3
                {
                    if (state.pass = PASS2) {
                        state.append_inst(&state,
                                          (OP_OP2 << 12) |
                                          (((((uint16_t) ($4)) & 0x7) | 0x8) << 8) |
                                          (((uint16_t) ($2)) & 0xff));

                    }
                }
        ;
sll_instruction:
                T_SLL reg T_COMMA reg T_COMMA imm3
                {
                    if (state.pass == PASS2) {
                        state.append_inst(&state,
                                          (OP_OP3 << 12) |
                                          (((uint16_t)($2) & 0xf) << 8) |
                                          (((uint16_t)($4) & 0xf) << 4) |
                                          ((uint16_t)($6) & 0x7));
                    }
                }
        ;
slr_instruction:
                T_SLR reg T_COMMA reg T_COMMA imm3
                {
                    if (state.pass == PASS2) {
                        state.append_inst(&state,
                                          (OP_OP3 << 12) |
                                          (((uint16_t)($2) & 0xf) << 8) |
                                          (((uint16_t)($4) & 0xf) << 4) |
                                          (((uint16_t)($6) & 0x7) | 0x8));
                    }
                }
        ;
lri_instruction:
                T_LRI reg T_COMMA imm8
                {
                    if (state.pass == PASS2) {
                        state.append_inst(&state,
                                          (OP_LRI << 12) |
                                          ((((uint16_t) ($2)) & 0x0f) << 8) |
                                          (((uint16_t) ($4)) & 0xff));
                    }
                }
        ;
rts_instruction:
                T_RTS
                {
                    if (state.pass == PASS2) {
                        state.append_inst(&state,
                                          (OP_RTS << 12));
                    }
                }

        ;
ior_instruction:
                T_IOR reg T_COMMA imm8
                {
                    if (state.pass == PASS2) {
                        state.append_inst(&state,
                                          (OP_IOR << 12) |
                                          (((uint16_t)($2) & 0xf) << 8) |
                                          ((uint16_t)($4) & 0xff));
                    }
                }
        ;
iow_instruction:
                T_IOW reg T_COMMA imm8
                {
                    if (state.pass == PASS2) {
                        state.append_inst(&state,
                                          (OP_IOW << 12) |
                                          (((uint16_t)($2) & 0xf) << 8) |
                                          ((uint16_t)($4) & 0xff));
                    }
                }
        ;
xri_instruction:
                T_XRI reg T_COMMA reg T_COMMA reg
                {
                    if (state.pass == PASS2) {
                        state.append_inst(&state,
                                          (OP_XRI << 12) |
                                          ((((uint16_t) ($2)) & 0xf) << 8) |
                                          ((((uint16_t) ($4)) & 0xf) << 4) |
                                          ((((uint16_t) ($6)) & 0xf)));
                    }
                }
        ;
ori_instruction:
                T_ORI reg T_COMMA reg T_COMMA reg
                {
                    if (state.pass == PASS2) {
                        state.append_inst(&state,
                                          (OP_ORI << 12) |
                                          ((((uint16_t) ($2)) & 0xf) << 8) |
                                          ((((uint16_t) ($4)) & 0xf) << 4) |
                                          ((((uint16_t) ($6)) & 0xf)));
                    }
                }
        ;
ari_instruction:
                T_ARI reg T_COMMA reg T_COMMA reg
                {
                    if (state.pass == PASS2) {
                        state.append_inst(&state,
                                          (OP_ARI << 12) |
                                          ((((uint16_t) ($2)) & 0xf) << 8) |
                                          ((((uint16_t) ($4)) & 0xf) << 4) |
                                          ((((uint16_t) ($6)) & 0xf)));
                    }
                }
        ;
adi_instruction:
                T_ADI reg T_COMMA reg T_COMMA reg
                {
                    if (state.pass == PASS2) {
                        state.append_inst(&state,
                                          (OP_ADI << 12) |
                                          ((((uint16_t) ($2)) & 0xf) << 8) |
                                          ((((uint16_t) ($4)) & 0xf) << 4) |
                                          ((((uint16_t) ($6)) & 0xf)));
                    }
                }
        ;
jsr_instruction:
                T_JSR btarget
                {
                    if (state.pass == PASS2) {
                        state.append_inst(&state,
                                          (OP_JSR << 12) |
                                          (((uint16_t) state.target_address) & 0xfff));
                    }
                }
        ;
jmp_instruction:
                T_JMP btarget
                {
                    if (state.pass == PASS2) {
                        state.append_inst(&state,
                                          (OP_JMP << 12) |
                                          (((uint16_t) state.target_address) & 0xfff));
                    }
                }
        ;
bez_instruction:
                T_BEZ btarget
                {
                    if (state.pass == PASS2) {
                        state.append_inst(&state,
                                          (OP_BEZ << 12) |
                                          (((uint16_t) state.target_address) & 0xfff));
                    }
                }
        ;
bnz_instruction:
                T_BNZ btarget
                {
                    if (state.pass == PASS2) {
                        state.append_inst(&state,
                                          (OP_BNZ << 12) |
                                          (((uint16_t) state.target_address) & 0xfff));
                    }
                }
        ;
reg:            T_REG
                {
                    $$ = state.reg;
                    chkreg($$);
                }
        ;
imm3:           expression
                {
                    $$ = $1;
                    chkimm($$, 3);
                }
        ;
imm8:           expression
                {
                    $$ = $1;
                    chkimm($$, 8);
                }
        ;
blabel:         T_BTARGET
                {
                    strncpy(state.label, yytext, MAX_LABEL_LENGTH-1);
                    state.label[MAX_LABEL_LENGTH-1] = '\0';
                }
        ;
btarget:        T_BTARGET
                {
                    if (state.pass == PASS2) {
                        state.target_address = iop16_get_label_address(yytext);
                        chkaddr(state.target_address);
                    }
                }
        ;
%%

void yyerror(const char *s) {
    fprintf(stderr,"error: %s in line %d\n", s, yylineno);

    if (ftell(yyin) != -1) {
        fseek(yyin, 0, SEEK_SET);
        char ch;
        ssize_t lineno = 1;
        char errline[MAX_LINE];
        for (;!feof(yyin);) {
            if (lineno == yylineno) {
                fgets(errline, MAX_LINE, yyin);
                size_t errline_len = strlen(errline);
                if (errline[errline_len-1] == '\n') {
                    errline[errline_len-1] = '\0';
                }
                fputs(errline, stderr);
                fputc('\n', stderr);
                for (size_t i = 0; i < state.column; i++) {
                    fputc(' ', stderr);
                }
                fputs("^\n", stderr);
                break;
            }
            for (ch = fgetc(yyin);
                 !feof(yyin);
                 ch = fgetc(yyin)) {
                if (ch == '\n') {
                    lineno += 1;
                    break;
                }
            }
        }
    }
}

static void chkreg(unsigned int v) {
    if ((v >> 4) != 0) {
        die("Register does not fit 8 bits");
    }
}

static void chkimm(unsigned int v, size_t n) {
    if ((v >> n) != 0) {
        die("Immediate does not fit %i bits", n);
    }
}

static void chkaddr(unsigned int v) {
    if ((v >> 12) != 0) {
        die("Address does not fit 12 bits");
    }
}

#if TEST_PARSER
int main() {
    yyin = stdin;
    yydebug = 0;
    int r = yyparse();
    printf("result = %ld\n", r);
    return r;
}
#endif
