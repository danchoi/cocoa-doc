#!/bin/bash

# This needs to be changed because some doc files aren't named Reference.html.
# Some are named after their class. Functions and Constants are in files called
# reference.html with an underscore.

mkdir -p data
find /Developer/Platforms/iPhoneOS.platform/Developer/Documentation/DocSets/com.apple.adc.documentation.AppleiOS4_2.iOSLibrary.docset -regex '.*/Reference.html'  |
while read path
do
  # echo $path
  pre_outfile=${path%/Reference/Reference.html}
  outfile=data/${pre_outfile##/*/}.yml
  if [[ ! -e $outfile ]]
  then
    echo Making $outfile
    ruby lib/adc-doc-parser.rb < $path > $outfile
  fi  
done

