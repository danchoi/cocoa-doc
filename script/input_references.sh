find 4_2 -iname 'reference.html' |  grep -v Guide |
while read path
do
  echo $path
  bin/parse $path
done

