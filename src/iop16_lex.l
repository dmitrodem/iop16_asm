%{
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "iop16_parser.tab.h"
#include "iop16_state.h"

static void comment();
static void c();
%}

ws	[ \t\n]
reg	[\$rR]
digit	[0-9]
hdigit  [0-9a-fA-F]
anum    [a-zA-Z][a-zA-Z0-9_]*
A	[aA]
B	[bB]
C	[cC]
D	[dD]
E	[eE]
F	[fF]
G	[gG]
H	[hH]
I	[iI]
J	[jJ]
K	[kK]
L	[lL]
M	[mM]
N	[nN]
O	[oO]
P	[pP]
Q	[qQ]
R	[rR]
S	[sS]
T	[tT]
U	[uU]
V	[vV]
W	[wW]
X	[xX]
Y	[yY]
Z	[zZ]

%%
"/*"		{ comment(); }
{ws}+		;
","		{ c(); return T_COMMA; }
{reg}{hdigit}+  { c(); state.reg = strtol(yytext + 1, NULL, 16); return(T_REG); }
"("             { c(); return(T_LPAREN); }
")"             { c(); return(T_RPAREN); }
"#"             { c(); return(T_SHARP); }
":"		{ c(); return(T_COLON); }
{hdigit}+       { c(); state.imm = strtol(yytext, NULL, 16); return(T_IMM); }

{S}{L}{L}       { c(); return T_SLL; }
{S}{L}{R}       { c(); return T_SLR; }
{S}{A}{L}       { c(); return T_SAL; }
{S}{A}{R}       { c(); return T_SAR; }
{R}{R}{L}       { c(); return T_RRL; }
{R}{R}{R}       { c(); return T_RRR; }

{R}{T}{S}       { c(); return T_RTS; }

{L}{R}{I}       { c(); return T_LRI; }
{C}{M}{P}       { c(); return T_CMP; }

{I}{O}{W}       { c(); return T_IOW; }
{I}{O}{R}       { c(); return T_IOR; }

{X}{R}{I}       { c(); return T_XRI; }
{O}{R}{I}       { c(); return T_ORI; }
{A}{R}{I}       { c(); return T_ARI; }
{A}{D}{I}       { c(); return T_ADI; }

{J}{S}{R}       { c(); return T_JSR; }
{J}{M}{P}       { c(); return T_JMP; }
{B}{E}{Z}       { c(); return T_BEZ; }
{B}{N}{Z}       { c(); return T_BNZ; }
{anum}		{ c(); return T_BTARGET; }

%%

int yywrap() {
  return 1;
}

static void comment() {
    char ch;
    while (1) {
        ch = input();
        if (ch == '\0') {
            break;
        }
        if (ch == '*') {
            ch = input();
            if (ch == '\0') {
                break;
            }
            if (ch == '/') {
                break;
            }
        }
    }
}

static void c() {
    for (char *ch = yytext; *ch != '\0'; ch++) {
        switch (*ch) {
        case '\n':
            state.column = 0;
            break;
        case '\t':
            state.column += 8 - (state.column % 8);
            break;
        default:
            state.column += 1;
            break;
        }
    }
}

/* int main() { */
/*     for (int r = yylex(); r != YYEOF; r = yylex()) { */
/*         fprintf(stderr, "r = %i %s\n", r, yytext); */
/*     } */
/*     return 0; */
/* } */
