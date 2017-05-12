# RandPass: A command-line interface for generating random passwords
# Copyright (C) 2017 U8N WXD
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Arguments:
#   -l [Number of Words to Include]
#   -e [Bits of Entropy Required]
#   -b for uppercase
#   -s for lowercase
#   -n for numerals
#   -c for special characters
#   -a [Additional Arbitrary Characters]
#   -h for help

# Note that either -l or -b must be supplied and must be >0

echo "RandPass Copyright (C) U8N WXD"
echo "This program comes with ABSOLUTELY NO WARRANTY"
echo "This is free software, and you are welcome to redistribute it"
echo "under the conditions of the Affero General Public License."
echo "License: <http://www.gnu.org/licenses/>"
echo

# Reset getopts index variable to 1 so it looks at the first argument
OPTIND=1

# Set character lists
uppercase="ABCDEFGHIJKLMNOPQRSTUVWXYZ"
lowercase="abcdefghijklmnopqrstuvwxyz"
numerals="1234567890"
symbols="!@#$%^&*()~<>,./?;:[]{}|=+-_"

# Initialize variables for argument parsing
length=0
bits=0
characters=""
dictLength=0

# Parse arguments
# SOURCE: http://wiki.bash-hackers.org/howto/getopts_tutorial
while getopts ":l:e:bsnca:h" opt; do
  case $opt in
    l)
      length=$OPTARG
      ;;
    e)
      bits=$OPTARG
      ;;
    b)
      characters="$characters$uppercase"
      let dictLength=dictLength+26
      ;;
    s)
      characters="$characters$lowercase"
      let dictLength=dictLength+26
      ;;
    n)
      characters="$characters$numerals"
      let dictLength=dictLength+10
      ;;
    c)
      characters="$characters$symbols"
      let dictLength=dictLength+28
      ;;
    a)
      characters="$characters$OPTARG"
      dictLength=$(($dictLength + ${#OPTARG}))
      ;;
    h)
      echo "RandPass Usage: ./randpass.sh [-e [bits] | -l [words]] -bsnc -a [characters]"
      echo "-b includes uppercase characters"
      echo "-s includes lowercase characters"
      echo "-n includes numerals"
      echo "-c includes special characters"
      echo "-a includes arbitrary additional characters"
      echo "-h displays this help text"
      exit 0
      ;;
    \?)
      echo "Invalid Option: -$OPTARG"
      echo "Run ./dicepass.sh -h for help"
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument"
      echo "Run ./dicepass.sh -h for help"
      exit 1
      ;;
  esac
done

if (( $# < 1 ))
  then {
    echo "Insufficient options provided. -e or -l required"
    echo "Run ./randpass.sh -h for help"
    exit 1
  }
fi

# SOURCE: https://stackoverflow.com/questions/6022384/bash-tool-to-get-nth-line-from-a-file
# SOURCE: http://www.tldp.org/LDP/abs/html/arithexp.html
entropyPerCharacter=$( echo "scale=10; l($dictLength) / l(2)" | bc -l )

# Check that either bits or length specified
if (( $bits + $length <= 0 ))
  then {
    echo "Invalid Options: Either length (-l) or bits (-e) must be supplied > 0"
    exit 1
  }
fi

# Calculate length needed based on bits requiested
# SOURCE: http://www.tldp.org/LDP/abs/html/comparison-ops.html
if (( $bits > 0 ))
  then length=$( echo "scale=0; $bits / $entropyPerCharacter + 1" | bc)
fi

# Calculate bits based on length
bitsActual=$( echo "scale=3; $entropyPerCharacter * $length" | bc )

# Generate and display passphrase
echo -n "Generated Password: "
i=0;
while (( i < $length ))
  do {
    numHex=$( echo "scale=0; l($dictLength) / l(16)" | bc -l )
    if (( $numHex == 0 ))
      then numHex=1
    fi
    index=$dictLength

    while [[ "$index" -ge "$dictLength" ]]
      do {
        rand=$( openssl rand -hex $numHex 2>/dev/null )
        rand=$( echo $rand | tr [a-z] [A-Z] )
        index=$( echo "ibase=16; $rand" | BC_LINE_LENGTH=9999999999999 bc )
        if (( $( echo "$index - $dictLength" | bc ) >= $dictLength ))
          then index=$( echo "$index % $dictLength" | bc )
        fi
      }
    done
    char=${characters:${index}:1}
    echo -n "$char"
    let i=i+1
  }
done

# Report entropy of generated passphrase to user
echo
echo "Bits: $bitsActual"

exit 0
