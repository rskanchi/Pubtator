# Pubtator

R script for generating publication-hit frequency tables based on [Pubtator search](https://www.ncbi.nlm.nih.gov/research/pubtator/) using input search strings/terms. 

# Quick Readme

## **```Files needed```** 

pubtator.R and phantomjs executable file

1. **```pubtator.R```** includes the functions required for getting the pubtator search frequencies.

2. **```phantomjs```** executable file
  * Download the phantomjs executable from [phantomjs download site](https://phantomjs.org/download.html).
  * Add phantomjs to PATH:  sudo ln -s /path/of/phantomjs/executable /usr/local/bin.

## **```Usage```**

```
source("pubtator.R")
getPubtatorFrequencies(datafile = "example_input_file.csv", fileId = "example")
```
The input file is a .csv file with two columns of search terms as shown in example_input_file.csv.

## **```Output```**

Output is an xlsx file with two worksheets:

  - **frequency**: sheet containing the frequency table (no of publication hits for pairs of search terms) sorted by row & col sums
  - **long_form**: frequencies in long format

Checkout the example output file pubtator_output_example_date.xlsx.
