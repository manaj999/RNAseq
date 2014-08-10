BEGIN{}
FNR==NR{
	a[$1]
	next
}



{ if ($5 in a) print $0 }

