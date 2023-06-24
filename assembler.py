# Template by Bruce A. Maxwell, 2015
#
# implements a simple assembler for the following assembly language
# 
# - One instruction or label per line.
#
# - Blank lines are ignored.
#
# - Comments start with a # as the first character and all subsequent
# - characters on the line are ignored.
#
# - Spaces delimit instruction elements.
#
# - A label ends with a colon and must be a single symbol on its own line.
#
# - A label can be any single continuous sequence of printable
# - characters; a colon or space terminates the symbol.
#
# - All immediate and address values are given in decimal.
#
# - Address values must be positive
#
# - Negative immediate values must have a preceeding '-' with no space
# - between it and the number.
#

# Language definition:
#
# LOAD D A   - load from address A to destination D
# LOADA D A  - load using the address register from address A + RE to destination D
# STORE S A  - store value in S to address A
# STOREA S A - store using the address register the value in S to address A + RE
# BRA L      - branch to label A
# BRAZ L     - branch to label A if the CR zero flag is set
# BRAN L     - branch to label L if the CR negative flag is set
# BRAO L     - branch to label L if the CR overflow flag is set
# BRAC L     - branch to label L if the CR carry flag is set
# CALL L     - call the routine at label L
# RETURN     - return from a routine
# HALT       - execute the halt/exit instruction
# PUSH S     - push source value S to the stack
# POP D      - pop form the stack and put in destination D
# OPORT S    - output to the global port from source S
# IPORT D    - input from the global port to destination D
# ADD A B C  - execute C <= A + B
# SUB A B C  - execute C <= A - B
# AND A B C  - execute C <= A and B  bitwise
# OR  A B C  - execute C <= A or B   bitwise
# XOR A B C  - execute C <= A xor B  bitwise
# SHIFTL A C - execute C <= A shift left by 1
# SHIFTR A C - execute C <= A shift right by 1
# ROTL A C   - execute C <= A rotate left by 1
# ROTR A C   - execute C <= A rotate right by 1
# MOVE A C   - execute C <= A where A is a source register
# MOVEI V C  - execute C <= value V
#

# 2-pass assembler
# pass 1: read through the instructions and put numbers on each instruction location
#         calculate the label values
#
# pass 2: read through the instructions and build the machine instructions
#

import sys

# converts d to an 8-bit 2-s complement binary value
def dec2comp8( d, linenum ):
    try:
        if d > 0:
            l = d.bit_length()
            v = "00000000"
            v = v[0:8-l] + format( d, 'b')
        elif d < 0:
            dt = 128 + d
            l = dt.bit_length()
            v = "10000000"
            v = v[0:8-l] + format( dt, 'b')[:]
        else:
            v = "00000000"
    except:
        print ('Invalid decimal number on line %d') % (linenum)
        exit()

    return v

# converts d to an 8-bit unsigned binary value
def dec2bin8( d, linenum ):
    if d > 0:
        l = d.bit_length()
        v = "00000000"
        v = v[0:8-l] + format( d, 'b' )
    elif d == 0:
        v = "00000000"
    else:
        print ('Invalid address on line %d: value is negative') % (linenum)
        exit()

    return v


# Tokenizes the input data, discarding white space and comments
# returns the tokens as a list of lists, one list for each line.
#
# The tokenizer also converts each character to lower case.
def tokenize( fp ):
    tokens = []

    # start of the file
    fp.seek(0)

    lines = fp.readlines()

    # strip white space and comments from each line
    for line in lines:
        ls = line.strip()
        uls = ''
        for c in ls:
            if c != '#':
                uls = uls + c
            else:
                break

        # skip blank lines
        if len(uls) == 0:
            continue

        # split on white space
        words = uls.split()

        newwords = []
        for word in words:
            newwords.append( word.lower() )

        tokens.append( newwords )

    return tokens


# reads through the file and returns a dictionary of all location
# labels with their line numbers
labels = {}
instructions = []
def pass1( tokens ):
    #create a dictionary [label:line number]
    counter = 0
    for line in tokens:
        if line[0][-1] == ":":
            labels[line[0][:-1]] = counter
        else:
            instructions.append(line)
            counter = counter +1  
    return labels, instructions



def pass2( instructions, labels ):
    instr = ""
    reg = ""
    reg2 = ""
    reg3 = ""
    num = ""
    label = ""
    full_instr = ""
    newLabel = ""
    #CPU tables
    tableB = {"ra":"000", "rb":"001", "rc":"010", "rd":"011","re":"100","sp":"101"}
    tableC = {"ra":"000", "rb":"001", "rc":"010", "rd":"011","re":"100","sp":"101", "pc":"110","cr":"111"}
    tableD = {"ra":"000", "rb":"001", "rc":"010", "rd":"011","re":"100","sp":"101", "pc":"110","ir":"111"}
    tableE = {"ra":"000", "rb":"001", "rc":"010", "rd":"011","re":"100","sp":"101", "zero":"000000000000000","one":"111111111111111"}
    list = []
    for line in instructions:
        #building the opcodes mostly
        if len(line) > 4:
             full_instr = "ERROR: an instruction is too long, CHECK: unneeded arguments"
        elif line[0] == "load":
            instr = "00000"
            reg = tableB[line[1]]
            num = bin(int(line[2]))[2:]
            while len(num) != 8:
                num = "0" + num
            full_instr = instr + reg + num
        elif line[0] == "loada":
            instr = "00001"
            reg = tableB[line[1]]
            num = bin(int(line[2]))[2:]
            while len(num) != 8:
                num = "0" + num
            full_instr = instr + reg + num
        elif line [0] == "store":
            instr = "00010"
            reg = tableB[line[1]]
            num = bin(int(line[2]))[2:]
            while len(num) != 8:
                num = "0" + num
            full_instr = instr + reg + num
        elif line[0] == "storea":
            instr = "00011"
            reg = tableB[line[1]]
            num = bin(int(line[2]))[2:]
            while len(num) != 8:
                num = "0" + num
            full_instr = instr + reg + num
        elif line[0] == "bra":
            instr = "0010"
            label = labels[line[1]]
            num = bin(label)[2:]
            while len(num) != 8:
                num = "0" + num
            full_instr = instr + "0000" + num
        elif line[0] == "braz":
            instr = "00110000"
            label = labels[line[1]]
            num = bin(label)[2:]
            while len(num) != 8:
                num = "0" + num
            full_instr = instr + num
        elif line[0] == "bran":
            instr = "00110010"
            label = labels[line[1]]
            num = bin(label)[2:]
            while len(num) != 8:
                num = "0" + num
            full_instr = instr + num
        elif line[0] == "brao":
            instr = "00110001"
            label = labels[line[1]]
            num = bin(label)[2:]
            print(num)
            while len(num) != 8:
                num = "0" + num
            full_instr = instr + num
        elif line[0] == "brac":
            instr = "00110011"
            label = labels[line[1]]
            num = bin(label)[2:]
            while len(num) != 8:
                num = "0" + num
            full_instr = instr + num
        elif line[0] == "call":
            instr = "001101"
            label = labels[line[1]]
            num = bin(int(label))[2:]
            while len(num) != 8:
                num = "0" + num
            full_instr = instr + "00" + num
            print(full_instr)
        elif line[0] == "return":
            print("return")
            full_instr = "0011100000000000"
        elif line[0] == "halt":
            full_instr = "0011110000000000"
        elif line[0] == "push":
            instr = "0100"
        elif line[0] == "pop":
            instr = "0101"
        elif line[0] == "oport":
            instr = "0110"
            reg = tableD[line[1]]
            full_instr = instr + reg + "000000000"
        elif line[0] == "iport":
            instr = "0111"
            reg = tableB[line[1]]
            full_instr = instr + reg + "000000000"
        elif line[0] == "add":
            instr = "1000"
            reg = tableE[line[1]]
            reg2 = tableE[line[2]]
            reg3 = tableB[line[3]]
            full_instr = instr + reg + reg2 + "000" + reg3
        elif line[0] == "sub":
            instr = "1001"
            reg = tableE[line[1]]
            reg2 = tableE[line[2]]
            reg3 = tableB[line[3]]
            full_instr = instr + reg + reg2 + "000" + reg3
        elif line[0] == "and":
            instr = "1010"
            reg = tableE[line[1]]
            reg2 = tableE[line[2]]
            reg3 = tableB[line[3]]
            full_instr = instr + reg + reg2 + "000" + reg3
        elif line[0] == "or":
            instr = "1011"
            reg = tableE[line[1]]
            reg2 = tableE[line[2]]
            reg3 = tableB[line[3]]
            full_instr = instr + reg + reg2 + "000" + reg3
        elif line[0] == "xor":
            instr = "1100"
            reg = tableE[line[1]]
            reg2 = tableE[line[2]]
            reg3 = tableB[line[3]]
            full_instr = instr + reg + reg2 + "000" + reg3
        elif line[0] == "shiftl":
            instr = "11010"
            reg = tableE[line[1]]
            reg2 = tableB[line[2]]
            full_instr = instr + reg + "00000" + reg2
        elif line[0] == "shiftr":
            instr = "11011"
            reg = tableE[line[1]]
            reg2 = tableB[line[2]]
            full_instr = instr + reg + "00000" + reg2
        elif line[0] == "rotl":
            instr = "11100"
            reg = tableE[line[1]]
            reg2 = tableB[line[2]]
            full_instr = instr + reg + "00000" + reg2
        elif line[0] == "rotr":
            instr = "11101"
            reg = tableE[line[1]]
            reg2 = tableB[line[2]]
            full_instr = instr + reg + "00000" + reg2
        elif line[0] == "move":
            instr = "11110"
            reg = tableD[line[1]]
            reg2 = tableB[line[2]]
            full_instr = instr + reg + "00000" + reg2
        elif line[0] == "movei":
            instr = "11111"
            num = bin(int(line[1]))[2:]
            while len(num) != 8:
                num = "0" + num
            reg2 = tableB[line[2]]
            full_instr = instr + num + reg2
        else:
            full_instr = "ERROR: an instruction is not found, CHECK: spelling and spacing"
        list.append(full_instr)

    print("-- program memory file for text.a \nDEPTH = 256;\nWIDTH = 16;\nADDRESS_RADIX = HEX;\nDATA_RADIX = BIN;\nCONTENT\nBEGIN")
    for line, single_instr in enumerate(list):
        if single_instr != list[-1]:
            print("%02X : %s;" % (line, single_instr))
        elif single_instr == list[-1]:
            print("[%02X...FF] : %s;" % (line, single_instr))


def main( argv ):
    if len(argv) < 2:
        print('Usage: python %s <filename>') % (argv[0])
        exit()

    fp = open( argv[1], 'r' )
   
    tokens = tokenize( fp )
    pass1(tokens)
    pass2(instructions, labels)
    fp.close()

if __name__ == "__main__":
    main(sys.argv)
    
