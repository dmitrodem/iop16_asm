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
static void chkimm(unsigned int v);
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
%token T_SLL T_SLR T_SAL T_SAR T_RRL T_RRR
%token T_RTS
%token T_LRI T_CMP
%token T_IOW T_IOR
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

instr:          sll_instruction |
                slr_instruction |
                sal_instruction |
                sar_instruction |
                rrl_instruction |
                rrr_instruction |
                rts_instruction |
                lri_instruction |
                cmp_instruction |
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
sll_instruction:
                T_SLL reg
                {
                    if (state.pass == PASS2) {
                        state.append_inst(&state,
                                          (OP_OP3 << 12) |
                                          ((((uint16_t) state.reg) & 0x0f) << 8) |
                                          (0x01));
                    }
                }
        ;
slr_instruction:
                T_SLR reg
                {
                    if (state.pass == PASS2) {
                        state.append_inst(&state,
                                          (OP_OP3 << 12) |
                                          ((((uint16_t) state.reg) & 0x0f) << 8) |
                                          (0x81));
                    }
                }
        ;
sal_instruction:
                T_SAL reg
                {
                    if (state.pass == PASS2) {
                        state.append_inst(&state,
                                          (OP_OP3 << 12) |
                                          ((((uint16_t) state.reg) & 0x0f) << 8) |
                                          (0x21));
                    }
                }
        ;
sar_instruction:
                T_SAR reg
                {
                    if (state.pass == PASS2) {
                        state.append_inst(&state,
                                          (OP_OP3 << 12) |
                                          ((((uint16_t) state.reg) & 0x0f) << 8) |
                                          (0xa1));
                    }
                }
        ;
rrl_instruction:
                T_RRL reg
                {
                    if (state.pass == PASS2) {
                        state.append_inst(&state,
                                          (OP_OP3 << 12) |
                                          ((((uint16_t) state.reg) & 0x0f) << 8) |
                                          (0x41));
                    }
                }
        ;
rrr_instruction:
                T_RRR reg
                {
                    if (state.pass == PASS2) {
                        state.append_inst(&state,
                                          (OP_OP3 << 12) |
                                          ((((uint16_t) state.reg) & 0x0f) << 8) |
                                          (0xc1));
                    }
                }
        ;
rts_instruction:
                T_RTS
                {
                    if (state.pass == PASS2) {
                        state.append_inst(&state,
                                          (OP_OP3 << 12) |
                                          (0x008));
                    }
                }

        ;
lri_instruction:
                T_LRI reg T_COMMA imm
                {
                    if (state.pass == PASS2) {
                        state.append_inst(&state,
                                          (OP_LRI << 12) |
                                          ((((uint16_t) state.reg) & 0x0f) << 8) |
                                          (((uint16_t) ($4)) & 0xff));
                    }
                }
        ;
cmp_instruction:
                T_CMP reg T_COMMA imm
                {
                    if (state.pass == PASS2) {
                        state.append_inst(&state,
                                          (OP_CMP << 12) |
                                          ((((uint16_t) state.reg) & 0x0f) << 8) |
                                          (((uint16_t) ($4)) & 0xff));
                    }
                }
        ;
iow_instruction:
                T_IOW reg T_COMMA imm
                {
                    if (state.pass == PASS2) {
                        state.append_inst(&state,
                                          (OP_IOW << 12) |
                                          ((((uint16_t) state.reg) & 0x0f) << 8) |
                                          (((uint16_t) ($4)) & 0xff));
                    }
                }
        ;
ior_instruction:
                T_IOR reg T_COMMA imm
                {
                    if (state.pass == PASS2) {
                        state.append_inst(&state,
                                          (OP_IOR << 12) |
                                          ((((uint16_t) state.reg) & 0x0f) << 8) |
                                          (((uint16_t) ($4)) & 0xff));
                    }
                }
        ;
xri_instruction:
                T_XRI reg T_COMMA imm
                {
                    if (state.pass == PASS2) {
                        state.append_inst(&state,
                                          (OP_XRI << 12) |
                                          ((((uint16_t) state.reg) & 0x0f) << 8) |
                                          (((uint16_t) ($4)) & 0xff));
                    }
                }

        ;
ori_instruction:
                T_ORI reg T_COMMA imm
                {
                    if (state.pass == PASS2) {
                        state.append_inst(&state,
                                          (OP_ORI << 12) |
                                          ((((uint16_t) state.reg) & 0x0f) << 8) |
                                          (((uint16_t) ($4)) & 0xff));
                    }
                }
        ;
ari_instruction:
                T_ARI reg T_COMMA imm
                {
                    if (state.pass == PASS2) {
                        state.append_inst(&state,
                                          (OP_ARI << 12) |
                                          ((((uint16_t) state.reg) & 0x0f) << 8) |
                                          (((uint16_t) ($4)) & 0xff));
                    }
                }
        ;
adi_instruction:
                T_ADI reg T_COMMA imm
                {
                    if (state.pass == PASS2) {
                        state.append_inst(&state,
                                          (OP_ADI << 12) |
                                          ((((uint16_t) state.reg) & 0x0f) << 8) |
                                          (((uint16_t) ($4)) & 0xff));
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
imm:            expression
                {
                    $$ = $1;
                    chkimm($$);
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

static void chkimm(unsigned int v) {
    if ((v >> 8) != 0) {
        die("Immediate does not fit 8 bits");
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
