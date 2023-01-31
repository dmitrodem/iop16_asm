%{
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "iop16_parser.tab.h"
#include "iop16_state.h"
#include "die.h"

static void comment_multiline();
static void comment_single();
static void c();
static YYSTYPE conv_integer();
%}
%option noyywrap nounput yylineno

ws	[ \t\n]
reg	[\$rR]
digit	[0-9]

int10   [1-9][0-9]*
int2    0b[0-1]+
int8    0[0-7]+
int16   0x[0-9a-fA-F]+

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
"/*"		{ c(); comment_multiline(); }
"//"            { c(); comment_single();    }
"#"             { c(); comment_single();    }
";;"            { c(); comment_single();    }
"!"             { c(); comment_single();    }
[ \t]+		{ c(); }
","		{ c(); return T_COMMA; }
{reg}{hdigit}   { c(); state.reg = strtol(yytext + 1, NULL, 16); return(T_REG); }
"("             { c(); return(T_LPAREN); }
")"             { c(); return(T_RPAREN); }
":"		{ c(); return(T_COLON); }

[1-9][0-9]*     { c(); yylval = conv_integer(yytext    , 10); return(T_NUMBER);}
0b[0-1]+        { c(); yylval = conv_integer(yytext + 2,  2); return(T_NUMBER);}
0[0-7]+         { c(); yylval = conv_integer(yytext + 1,  8); return(T_NUMBER);}
0x[0-9a-fA-F]+  { c(); yylval = conv_integer(yytext + 2, 16); return(T_NUMBER);}
0               { c(); yylval = 0;                            return(T_NUMBER);}
"+"             { c(); return '+';}
"-"             { c(); return '-';}
"*"             { c(); return '*';}
"/"             { c(); return '/';}
"|"             { c(); return '|';}
"&"             { c(); return '&';}
"^"             { c(); return '^';}
"~"             { c(); return '~';}
"<<"            { c(); return T_LSHIFT;}
">>"            { c(); return T_RSHIFT;}

(?i:bclr)       { c(); return T_BCLR; }
(?i:bset)       { c(); return T_BSET; }

(?i:sll)        { c(); return T_SLL; }
(?i:slr)        { c(); return T_SLR; }

(?i:lri)        { c(); return T_LRI; }
(?i:rts)        { c(); return T_RTS; }

(?i:ior)        { c(); return T_IOR; }
(?i:iow)        { c(); return T_IOW; }

(?i:xri)        { c(); return T_XRI; }
(?i:ori)        { c(); return T_ORI; }
(?i:ari)        { c(); return T_ARI; }
(?i:adi)        { c(); return T_ADI; }

(?i:(jsr)|(call)) { c(); return T_JSR; }
(?i:(jmp))        { c(); return T_JMP; }
(?i:(bez)|(beq))  { c(); return T_BEZ; }
(?i:(bnz)|(bne))  { c(); return T_BNZ; }

{anum}		  { c(); return T_BTARGET; }

\n                { c(); }
.                 { c(); }
%%

static void update_position(char ch) {
    if (ch == '\n') {
        state.cur_line[state.cur_ptr] = '\0';
        strcpy(state.last_line, state.cur_line);
        state.cur_ptr = 0;

        state.column = 0;
        state.line += 1;
    } else {
        if (state.cur_ptr < MAX_LINE-1) {
            state.cur_line[state.cur_ptr] = ch;
            state.cur_ptr += 1;
        }
        state.column += 1;
    }
}

static void comment_multiline() {
    enum {IDLE, STAR} fsm = IDLE;
    for (int ch = input();
         (ch != EOF) && (ch != 0);
         ch = input()) {
        int finish = 0;

        /* update position */
        update_position((char)ch);

        /* find end of comment */
        switch (fsm) {
        case IDLE:
            if (ch == '*') {
                fsm = STAR;
            }
            break;
        case STAR:
            if (ch == '/') {
                finish = 1;
            }
            break;
        default:
            break;
        }
        if (finish == 1) {
            break;
        }
    }
}

static void comment_single() {
  for (int ch = input();
       (ch != EOF) && (ch != 0);
       ch = input()) {
      update_position((char)ch);
      if (ch == '\n') {
          break;
      }
  }
}

static void c() {
    for (char *ch = yytext; *ch != '\0'; ch++) {
        update_position(*ch);
    }
}

static YYSTYPE conv_integer(const char* s, int base) {
  long r = strtol(s, NULL, base);
  if (errno == EINVAL) {
    die("Failed to parse integer string: %s", yytext);
  } else if (errno == ERANGE) {
    die("Out of integer range: %s", yytext);
  }
  if (r < 0) {
    die("Somehow lexer encountered a negative value: %ld", r);
  }
  return (YYSTYPE)r;
}

#ifdef TEST_LEXER
int main() {
    memset(state.cur_line, 0, MAX_LINE);
    memset(state.last_line, 0, MAX_LINE);
    state.line = 0; state.column = 0; state.cur_ptr = 0;
    for (int r = yylex(); r != YYEOF; r = yylex()) {
        fprintf(stderr, "r = %i %s\n", r, yytext);
    }

    state.cur_line[state.cur_ptr] = '\0';
    printf("line = %ld, column = %ld, cur_ptr = %ld\n",
           state.line, state.column, state.cur_ptr);
    printf("last_line = \"%s\"\n", state.last_line);
    printf("cur_line = \"%s\"\n", state.cur_line);
    return 0;
}
#endif
