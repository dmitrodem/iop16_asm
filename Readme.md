# IOP16 Assembler #
Assembler for [IOP16](https://github.com/douggilliland/IOP16) CPU. Written using Flex/Bison, inspired by a simple assembler [rasm](https://sourceforge.net/projects/rasm)

<table border=1>
    <tr>
        <td rowspan="2">Instruction mnemonic</td>
        <td colspan="4">Opcode</td>
        <td colspan="4">Regnum</td>
        <td colspan="8">Value</td>
        <td rowspan="2">Description</td>
    </tr>
    <tr>
        <td>D15</td>
        <td>D14</td>
        <td>D13</td>
        <td>D12</td>
        <td>D11</td>
        <td>D10</td>
        <td>D9</td>
        <td>D8</td>
        <td>D7</td>
        <td>D6</td>
        <td>D5</td>
        <td>D4</td>
        <td>D3</td>
        <td>D2</td>
        <td>D1</td>
        <td>D0</td>
    </tr>
    <tr>
        <td>rs0</td>
        <td>0</td><td>0</td><td>0</td><td>0</td>
        <td></td><td></td><td></td><td></td>
        <td></td><td></td><td></td><td></td><td></td><td></td><td></td><td></td>
        <td>Reserved OP-0</td>
    </tr>
    <tr>
        <td>rs1</td>
        <td>0</td><td>0</td><td>0</td><td>1</td>
        <td></td><td></td><td></td><td></td>
        <td></td><td></td><td></td><td></td><td></td><td></td><td></td><td></td>
        <td>Reserved OP-1</td>
    </tr>
    <tr>
        <td>rs2</td>
        <td>0</td><td>0</td><td>1</td><td>0</td>
        <td></td><td></td><td></td><td></td>
        <td></td><td></td><td></td><td></td><td></td><td></td><td></td><td></td>
        <td>Reserved OP-2</td>
    </tr>
    <tr>
        <td>SLL</td>
        <td>0</td><td>0</td><td>1</td><td>1</td>
        <td colspan="4">REG_NUM</td>
        <td>0</td><td>0</td><td>0</td><td>0</td>
        <td>0</td><td colspan="3">001</td>
        <td>Shift Logical Left</td>
    </tr>
    <tr>
        <td>SLR</td>
        <td>0</td><td>0</td><td>1</td><td>1</td>
        <td colspan="4">REG_NUM</td>
        <td>1</td><td>0</td><td>0</td><td>0</td>
        <td>0</td><td colspan="3">001</td>
        <td>Shift Logical Right</td>
    </tr>
    <tr>
        <td>SAL</td>
        <td>0</td><td>0</td><td>1</td><td>1</td>
        <td colspan="4">REG_NUM</td>
        <td>0</td><td>0</td><td>1</td><td>0</td>
        <td>0</td><td colspan="3">001</td>
        <td>Shift Arithmetic Left</td>
    </tr>
    <tr>
        <td>SAR</td>
        <td>0</td><td>0</td><td>1</td><td>1</td>
        <td colspan="4">REG_NUM</td>
        <td>1</td><td>0</td><td>1</td><td>0</td>
        <td>0</td><td colspan="3">001</td>
        <td>Shift Arithmetic Right</td>
    </tr>
    <tr>
        <td>RRL</td>
        <td>0</td><td>0</td><td>1</td><td>1</td>
        <td colspan="4">REG_NUM</td>
        <td>0</td><td>1</td><td>x</td><td>0</td>
        <td>0</td><td colspan="3">001</td>
        <td>Rotate Register Left</td>
    </tr>
    <tr>
        <td>RRR</td>
        <td>0</td><td>0</td><td>1</td><td>1</td>
        <td colspan="4">REG_NUM</td>
        <td>1</td><td>1</td><td>x</td><td>0</td>
        <td>0</td><td colspan="3">001</td>
        <td>Rotate Register Right</td>
    </tr>
    <tr>
        <td>RTS</td>
        <td>0</td><td>0</td><td>1</td><td>1</td>
        <td colspan="4">xxx</td>
        <td>x</td><td>x</td><td>x</td><td>0</td>
        <td>1</td><td>x</td><td>x</td><td>x</td>
        <td>Return From Subroutine</td>
    </tr>
    <tr>
        <td>rs3</td>
        <td>0</td><td>0</td><td>1</td><td>1</td>
        <td colspan="4">xxx</td>
        <td>x</td><td>x</td><td>x</td><td>1</td>
        <td>0</td><td>x</td><td>x</td><td>x</td>
        <td>Reserved OP-3 (Subset)</td>
    </tr>
    <tr>
        <td>LRI</td>
        <td>0</td><td>1</td><td>0</td><td>0</td>
        <td colspan="4">REG_NUM</td>
        <td colspan="8">IMMED_VALUE</td>
        <td>Load Reg with IMMED Value</td>
    </tr>
    <tr>
        <td>CMP</td>
        <td>0</td><td>1</td><td>0</td><td>1</td>
        <td colspan="4">REG_NUM</td>
        <td colspan="8">IMMED_VALUE</td>
        <td>Compare Reg with IMMED Value</td>
    </tr>
    <tr>
        <td>IOR</td>
        <td>0</td><td>1</td><td>1</td><td>0</td>
        <td colspan="4">REG_NUM</td>
        <td colspan="8">IO_ADDR</td>
        <td>I/O Read to Register</td>
    </tr>
    <tr>
        <td>IOW</td>
        <td>0</td><td>1</td><td>1</td><td>1</td>
        <td colspan="4">REG_NUM</td>
        <td colspan="8">IO_ADDR</td>
        <td>I/O Write from Register</td>
    </tr>
    <tr>
        <td>XRI</td>
        <td>1</td><td>0</td><td>0</td><td>0</td>
        <td colspan="4">REG_NUM</td>
        <td colspan="8">IMMED_VALUE</td>
        <td>XOR Reg with IMMED Value</td>
    </tr>
    <tr>
        <td>ORI</td>
        <td>1</td><td>0</td><td>0</td><td>1</td>
        <td colspan="4">REG_NUM</td>
        <td colspan="8">IMMED_VALUE</td>
        <td>OR Reg with IMMED Value</td>
    </tr>
    <tr>
        <td>ARI</td>
        <td>1</td><td>0</td><td>1</td><td>0</td>
        <td colspan="4">REG_NUM</td>
        <td colspan="8">IMMED_VALUE</td>
        <td>AND Reg with IMMED Value</td>
    </tr>
    <tr>
        <td>ADI</td>
        <td>1</td><td>0</td><td>1</td><td>1</td>
        <td colspan="4">REG_NUM</td>
        <td colspan="8">IMMED_VALUE</td>
        <td>ADD Reg with IMMED Value</td>
    </tr>
    <tr>
        <td>JSR</td>
        <td>1</td><td>1</td><td>0</td><td>0</td>
        <td colspan="12">PC_ADDRESS</td>
        <td>Jump to Subroutine</td>
    </tr>
    <tr>
        <td>JMP</td>
        <td>1</td><td>1</td><td>0</td><td>1</td>
        <td colspan="12">PC_ADDRESS</td>
        <td>Jump to Address</td>
    </tr>
    <tr>
        <td>BEZ</td>
        <td>1</td><td>1</td><td>1</td><td>0</td>
        <td colspan="12">PC_ADDRESS</td>
        <td>Branch if Zero</td>
    </tr>
    <tr>
        <td>BEQ</td>
        <td>1</td><td>1</td><td>1</td><td>0</td>
        <td colspan="12">PC_ADDRESS</td>
        <td>Branch if Equal</td>
    </tr>
    <tr>
        <td>BNZ</td>
        <td>1</td><td>1</td><td>1</td><td>1</td>
        <td colspan="12">PC_ADDRESS</td>
        <td>Branch if Not Zero</td>
    </tr>
    <tr>
        <td>BNE</td>
        <td>1</td><td>1</td><td>1</td><td>1</td>
        <td colspan="12">PC_ADDRESS</td>
        <td>Branch if Not Equal</td>
    </tr>
</table>
