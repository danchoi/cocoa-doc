find 4_2 -iname 'reference.html' |  grep -v Guide |
while read path
do
  echo $path
  bin/parse $path
done

find 4_2 -name '*.html' | grep Reference | grep '/\(NS\|UI\)[A-Z][^\/]*.html$'  | 
while read path
do
  echo $path
  bin/parse $path
done

