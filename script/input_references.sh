find 4_2 -iname 'reference.html' | 
while read path
do
  echo $path
  bin/parse $path
done

