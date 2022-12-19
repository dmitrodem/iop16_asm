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
"/*"		{ comment_multiline(); }
"//"            { comment_single();    }
"#"             { comment_single();    }
";;"            { comment_single();    }
"!"             { comment_single();    }
{ws}+		;
","		{ c(); return T_COMMA; }
{reg}{hdigit}   { c(); state.reg = strtol(yytext + 1, NULL, 16); return(T_REG); }
"("             { c(); return(T_LPAREN); }
")"             { c(); return(T_RPAREN); }
":"		{ c(); return(T_COLON); }

[1-9][0-9]*     { c(); yylval = conv_integer(yytext    , 10); return(T_NUMBER);}
0b[0-1]+        { c(); yylval = conv_integer(yytext + 2,  2); return(T_NUMBER);}
0[0-7]+         { c(); yylval = conv_integer(yytext + 1,  8); return(T_NUMBER);}
0x[0-9a-fA-F]+  { c(); yylval = conv_integer(yytext + 2, 16); return(T_NUMBER);}
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

static void comment_multiline() {
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

static void comment_single() {
  for (char ch = input();
       (ch != '\0') && (ch != '\n');
       ch = input());
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

#if 0
int main() {
    for (int r = yylex(); r != YYEOF; r = yylex()) {
        fprintf(stderr, "r = %i %s\n", r, yytext);
    }
    return 0;
}
#endif
