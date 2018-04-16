#!/bin/bash
cd /usr/share/perl5/VTP/
for file in `find . -name "*.pm"`; do
   filetype=`file $file | grep Perl`
   if [ -z "$filetype" ]; then
       filetype=`echo $file | grep -E "\.pm$"`
   fi
   if [ ! -z "$filetype" ]; then
        file1=${file:2:-3}
        echo use VTP::${file1//\//::}\;
   fi
done
