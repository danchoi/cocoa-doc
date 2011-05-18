#!/bin/bash

mkdir -p data
find /Developer/Platforms/iPhoneOS.platform/Developer/Documentation/DocSets/com.apple.adc.documentation.AppleiOS4_2.iOSLibrary.docset -regex '.*/Reference.html'  |
while read path
do
  # echo $path
  pre_outfile=${path%/Reference/Reference.html}
  outfile=data/${pre_outfile##/*/}.yml
  echo Making $outfile
  ruby lib/adc-doc-parser.rb < $path > $outfile
done

