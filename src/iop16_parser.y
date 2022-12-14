%{
#include <stdio.h>
#include <string.h>
#include "iop16_state.h"

extern char *yytext;
extern int yylex();
extern int yyparse();
extern void yyrestart(FILE* fd);
extern FILE* yyin;

void yyerror(const char* s);
%}

%token T_COLON T_COMMA T_LPAREN T_RPAREN T_SHARP
%token T_BTARGET T_IMM T_REG
%token T_SLL T_SLR T_SAL T_SAR T_RRL T_RRR
%token T_RTS
%token T_LRI T_CMP
%token T_IOW T_IOR
%token T_XRI T_ORI T_ARI T_ADI
%token T_JSR T_JMP T_BEZ T_BNZ

%start program_body

%%
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
                                          (((uint16_t) state.imm) & 0xff));
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
                                          (((uint16_t) state.imm) & 0xff));
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
                                          (((uint16_t) state.imm) & 0xff));
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
                                          (((uint16_t) state.imm) & 0xff));
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
                                          (((uint16_t) state.imm) & 0xff));
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
                                          (((uint16_t) state.imm) & 0xff));
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
                                          (((uint16_t) state.imm) & 0xff));
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
                                          (((uint16_t) state.imm) & 0xff));
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
                }
        ;
imm:            T_SHARP T_IMM
                {
                    $$ = state.imm;
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
                    }
                }
        ;
%%

void yyerror(const char *s) {
        fflush(stdout);
        printf("\n%s\n", s);
        printf("\n%*s\n%*s\n",
               state.column,
               "^",
               state.column,
               s);
}
