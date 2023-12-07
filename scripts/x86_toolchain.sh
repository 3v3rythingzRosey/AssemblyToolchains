#! /bin/bash

# Created by Lubos Kuzma,
# ISS Program, SADT, SAIT
# August 2022

# This script that compiles and links an assembly file into an executable, that can be run in QEMU or GDB.

# Checks if at least one argument is provided.
if [ $# -lt 1 ]; then
  # If not, display an error message and exit the program.
	echo "Usage:"  
	echo ""
	echo "x86_toolchain.sh [ options ] <assembly filename> [-o | --output <output filename>]"
	echo ""
	echo "-v | --verbose                Show some information about steps performed."
	echo "-g | --gdb                    Run gdb command on executable."
	echo "-b | --break <break point>    Add breakpoint after running gdb. Default is _start."
	echo "-r | --run                    Run program in gdb automatically. Same as run command inside gdb env."
	echo "-q | --qemu                   Run executable in QEMU emulator. This will execute the program."
	echo "-64| --x86-64                 Compile for 64bit (x86-64) system."
	echo "-o | --output <filename>      Output filename."

	exit 1
fi

# Initialize variables and set default values for options.
POSITIONAL_ARGS=()
GDB=False
OUTPUT_FILE=""
VERBOSE=False
BITS=False
QEMU=False
BREAK="_start"
RUN=False

# command-line options.
while [[ $# -gt 0 ]]; do ##while loop
	case $1 in
		-g|--gdb)  # Set the GDB option to True.
			GDB=True
			shift # Shifts argument to the next one.
			;;
		-o|--output)  # Sets the OUTPUT_FILE variable to the value of the next argument.
			OUTPUT_FILE="$2"
			shift # Shift argument to the next one.
			shift # Shift argument to the next one.
			;;
		-v|--verbose)
			VERBOSE=True # Sets the VERBOSE option to True.
			shift # Shift argument to the next one.
			;;
		-64|--x84-64)
			BITS=True # Sets the BITS option to True.
			shift # Shift argument to the next one.
			;;
		-q|--qemu)
			QEMU=True # Sets the QEMU option to True.
			shift # Shift argument to the next one.
			;;
		-r|--run)
			RUN=True # Sets the RUN option to True.
			shift # Shift argument to the next one.
			;;
		-b|--break) # Sets the BREAK variable to the value of the next argument.
			BREAK="$2"
			shift # Shift argument to the next one.
			shift # Shift argument to the next one.
			;;
		-*|--*)
			echo "Unknown option $1" # error message if an unknown option is selected
			exit 1 
			;;
		*)
			POSITIONAL_ARGS+=("$1") # Add the argument to the POSITIONAL_ARGS array.
			shift # Shifts argument to the next one
			;;
	esac
done

set -- "${POSITIONAL_ARGS[@]}" # Restore positional parameters from the POSITIONAL_ARGS array.

if [[ ! -f $1 ]]; then
	echo "Specified file does not exist"
	exit 1 
	#checks for specific assembly file and displays error message it if DNE
fi

if [ "$OUTPUT_FILE" == "" ]; then
	OUTPUT_FILE=${1%.*}
	# Sets the output file name  as the input file name if not specified.
fi

# This displays the arguments being set when the VERBOSE option is True.
if [ "$VERBOSE" == "True" ]; then
	echo "Arguments being set:"
	echo "	GDB = ${GDB}"
	echo "	RUN = ${RUN}"
	echo "	BREAK = ${BREAK}"
	echo "	QEMU = ${QEMU}"
	echo "	Input File = $1"
	echo "	Output File = $OUTPUT_FILE"
	echo "	Verbose = $VERBOSE"
	echo "	64 bit mode = $BITS" 
	echo ""

	echo "NASM started..."

fi

# Here the assembly file is compiled in 64-bit mode if the BITS option is True.
if [ "$BITS" == "True" ]; then

	nasm -f elf64 $1 -o $OUTPUT_FILE.o && echo ""

	# Otherwise, its compiled in 32-bit mode.
elif [ "$BITS" == "False" ]; then

	nasm -f elf $1 -o $OUTPUT_FILE.o && echo ""
		#Assembles input assembly file into 32-bit mode
fi

if [ "$VERBOSE" == "True" ]; then

	echo "NASM finished"
	echo "Linking ..."
	
fi

# Display a popup message indicating compilation is done
if [ "$VERBOSE" == "True" ]; then

	echo "NASM finished"
	echo "Linking ..."
fi

# Link the object file into an executable in 64-bit since BITS was true.
if [ "$BITS" == "True" ]; then

	ld -m elf_x86_64 $OUTPUT_FILE.o -o $OUTPUT_FILE && echo ""

# Otherwise it links the object file into a 32-bit executable.
elif [ "$BITS" == "False" ]; then

	ld -m elf_i386 $OUTPUT_FILE.o -o $OUTPUT_FILE && echo ""

fi

# Display a popup message indicating compilation is done
if [ "$VERBOSE" == "True" ]; then

	echo "Linking finished"

fi

# Runs the executable in QEMU if the QEMU option is True.
if [ "$QEMU" == "True" ]; then

	echo "Starting QEMU ..."
	echo ""

  # Executes the program in QEMU 64-bit mode if the BITS option is True.
	if [ "$BITS" == "True" ]; then
	
		qemu-x86_64 $OUTPUT_FILE && echo ""
  
  # Otherwise it runs the executable in QEMU 32-bit mode.
	elif [ "$BITS" == "False" ]; then

		qemu-i386 $OUTPUT_FILE && echo ""
		#runs the executeable in QEMU in 64-bit mode.
	fi
  # The script is terminated after executing the prgoam in QEMU
	exit 0
	
fi

# The executeable gets run in GDB if the GDB option was set to true
if [ "$GDB" == "True" ]; then

	gdb_params=()
	gdb_params+=(-ex "b ${BREAK}")

  # if RUN option is enabled, an additional breakpoint command will be included after lauching
	if [ "$RUN" == "True" ]; then

		gdb_params+=(-ex "r")

	fi
	
  # GDB will be launched with the specified parameters in the gbd_params array.
	gdb "${gdb_params[@]}" $OUTPUT_FILE

fi
