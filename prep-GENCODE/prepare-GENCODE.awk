BEGIN{}

FNR==NR{
	if ($3 !~ "gene") print $0
	next
}


