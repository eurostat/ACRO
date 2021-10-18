# ACRO
## Automatic checking of research outputs

ACRO (Automatic Checking of Research Outputs), is a proof of concept tool designed and developed to reduce the manual workload of statistical disclosure control (SDC) checking of research outputs. 
The Authors are particularly keen for more users to provide ideas and feedback. Users wanting to try the software beforehand can clone the current repository containing the code, manuals and test data, as well as watch the demonstration video at [link].

### License
This software is released under the EUPL v.1.2 (please refer to the LICENSE file). 
Authors: F.Ritchie, J.Smith and E.Green, University of West England, Bristol (UK).
Copyright (c) European Union, 2021.


### Features

- Implementation of automatic checks on disclosure risks deriving from:
 -- Tabulation
 -- Common estimators
 -- Medians
 -- Maxima/Minima
- Automatic primary suppression
- Possibility for the researcher to requests exceptions
- Preparation of a report for the Output checker specialist

### Techs

ACRO is implemented in the form of STATA(R) code. The user needs an installation of STATA v.16 or earlier. 

### Installation

Clone the present repository or download as zip archive, then follow the installation instructions contained in the ACRO_manager_guide pdf. For instance on Linux, make sure that your $S_ADO environment variable is set, then:

```sh
git clone https://github.com/eurostat/ACRO.git ACRO
cp -r ACRO $S_ADO/ACRO
```

### Development

Would you like to contribute? Great! We really appreciate the effort of our community to find and correct bugs, or to implement additional features! Please find out how to get in contact with us below.

### Links
 [ACRO GitHub repository]
 
### Get in touch
In order to get in touch with us, please write an email at ESTAT-CONFIDENTIALITY@ec.europa.eu specifying your contact details, including information about your Research Entity.



   [ACRO GitHub repository]: <https://github.com/eurostat/ACRO>

