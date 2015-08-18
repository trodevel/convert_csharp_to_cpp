#!/bin/bash

# Rough C# to C++ syntax converter.
#
# Copyright (C) 2015 Sergey Kolevatov
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.
#

# $Revision: 2337 $ $Date:: 2015-08-18 #$ $Author: serge $

VER="1.1"

replace_word()
{
local from=$1
local to=$2
local file_in=$3

local mask="s/\b$from\b/$to/g"

local tmp=replace_${RANDOM}

cat $file_in | sed $mask > $tmp
rm $file_in
mv $tmp $file_in
}


cs_file=$1

if [ -z "$cs_file" ]
then
    echo "USAGE: convert_cs_to_cpp.sh <filename>"
    exit
fi

fl=${cs_file%%.*};
fl_cpp=${fl}.h

msk=convert_cs_to_cpp_tmp_${RANDOM}

echo "input  = $cs_file"
echo "output = $fl_cpp"


# add ifndef/define
echo -e "// automatically converted from C# to C++ by convert_cs_to_cpp.sh ver. $VER\n" > ${msk}_01
echo -e "#ifndef _${fl}_h_\n#define _${fl}_h_\n\n" >> ${msk}_01
cat $cs_file >> ${msk}_01
echo -e "\n\n#endif // _${fl}_h_" >> ${msk}_01

#replace private,public,protected
#cat ${msk}_01 | sed "s/[^w]public /public:\n/" | sed "s/[^w]private /private:\n/" | sed "s/[^w]protected /protected:\n/" > ${msk}_02
replace_word "public"    "public:\n" ${msk}_01
replace_word "protected" "protected:\n" ${msk}_01
replace_word "private"   "private:\n" ${msk}_01

#replace override --> virtual
replace_word "override" "virtual" ${msk}_01

#replace internal --> private:
replace_word "internal\s*" "" ${msk}_01

#replace readonly --> const
replace_word "readonly" "const" ${msk}_01

#replace string --> std::string
replace_word "string" "std::string" ${msk}_01

#replace var --> auto
replace_word "var" "auto"  ${msk}_01

#replace periods in 'using' with semicolons
sed -i -e '/using / s/\./::/g' ${msk}_01

#replace periods in 'namespace' with nested namespace
sed -i -e '/namespace / s/\./\n{\nnamespace /g' ${msk}_01

#replace periods in 'case' with semicolon
sed -i -e '/case / s/\./::/g' ${msk}_01

# convert some exception class names
replace_word "ArgumentOutOfRangeException" "std::out_of_range"  ${msk}_01

# convert some container classes
replace_word "List" "std::list"  ${msk}_01

# convert some container classes
replace_word "Dictionary" "std::map"  ${msk}_01

# convert some template classes
replace_word "Func" "std::function"  ${msk}_01

# select last file
last=$( ls ${msk}_* | tail -1 )

cp $last $fl_cpp

rm ${msk}*
