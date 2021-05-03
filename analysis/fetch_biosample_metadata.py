#!/usr/bin/env python3

import Bio
from Bio import Entrez

Entrez.email = "Your.Name.Here@example.org"

# from Bio import Entrez

# Entrez.email = "Your.Name.Here@example.org"

# handle = Entrez.efetch(db="nucleotide", id="AY851612", rettype="gb", retmode="text")

# print(handle.readline().strip())
# # LOCUS       AY851612                 892 bp    DNA     linear   PLN 10-APR-2007

# handle.close()

# handle = Entrez.efetch(db="biosample", accession="SAMEA7090897", rettype="xml", retmode="text")


# => TODO: Use an API key, and a real email
# https://www.ncbi.nlm.nih.gov/account/settings/?smsg=create_apikey_success\

# WOrks
# handle = Entrez.esearch(db="biosample", retmax=10, term="SAMEA7090897", idtype="acc")
# record = Entrez.read(handle)
# handle.close()

# 18747675
handle = Entrez.efetch(db="biosample", id="18747675", rettype="xml")
x = handle.read()
handle.close()

import xml.etree.ElementTree as ET

bs = ET.fromstring(x)

list([[r.attrib['attribute_name'],r.text] for r in bs.iter('Attribute')])
#=> Need to use harmonized name where possible

list([[r.attrib['taxonomy_id'],r.attrib['taxonomy_name']] for r in bs.iter('Organism')])

import IPython; IPython.embed()
# print(handle.readline().strip())
# # LOCUS       AY851612                 892 bp    DNA     linear   PLN 10-APR-2007

# handle.close()