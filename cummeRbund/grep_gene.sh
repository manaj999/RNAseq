FILENAME=$1
cat $FILENAME | while read LINE
do
	echo "$LINE";
	grep $LINE $2 >> "$1_out.txt";
done

