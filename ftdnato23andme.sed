#!/usr/bin/sed -n -f

# Convert FTDNA format to 23andme
# usage: ./ftdnato23andme.sed < ftdna.csv > 23andme.txt

1a\
    # rsid	chromosome	position	genotype

y/-,/m	/; s/"//g

2,$p