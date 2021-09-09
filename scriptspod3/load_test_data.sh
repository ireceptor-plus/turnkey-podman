#!/bin/bash
scriptspod/load_metadata.sh ireceptor test_data/PRJNA330606_Wang_1_sample_metadata.csv
sleep 2
scriptspod/load_rearrangements.sh mixcr test_data/SRR4084215_aa_mixcr_annotation_1000_lines.txt
echo done
