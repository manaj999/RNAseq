# intended for creating pairwise correlation plots and correlation coefficients
## Please see README.txt for more info on usage

BEGIN{}
FNR==NR{
	a[$1]
	next
}



{ if ($5 in a) print $0 }

