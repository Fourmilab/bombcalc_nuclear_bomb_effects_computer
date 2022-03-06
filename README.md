# Bombcalc — Nuclear Bomb Effects Computer

![Nuclear bomb effects computer](webtree/figures/enwcalc.jpg)

This repository is the development directory and archive for
Fourmilab's Web resource, “[*Strangelove Slide Rule*:
Nuclear Bomb Effects Computer](https://www.fourmilab.ch/bombcalc/)”,
which provides an interactive computer emulation of the circular
slide rule weapons effect computer optionally available with the
1962 edition of the U.S. government publication
[*The Effects of Nuclear Weapons*](https://www.fourmilab.ch/etexts/www/effects/).
In addition to the interactive calculator, downloadable file and
instructions are included to allow printing and constructing a
physical replica of the original plastic slide rule in the
interest of authenticity or for use in a post-apocalyptic world where
Internet access may be spotty.

## Structure of the repository

This repository is organised into the following directories.

* **webtree**: Replica of the Web tree from the Fourmilab site
containing all of the HTML documents, images, and downloads.  These
pages contain relative references to style sheets, icons, and other
resources on the Fourmilab Web site and will not work without
modification in other environments.

* **cgi**: Programs and supporting data files for the Common Gateway
Interface (CGI) services used to generate the updated slide rule
image for requests made either from the Web pages or from earlier
queries.  These programs will have to be modified to run in the CGI
environment of the server on which they are installed.

* **netpbm_tools**: Source code for three additions to the
[Netpbm](http://netpbm.sourceforge.net/) image manipulation toolkit,
which are used by the programs in the **cgi** directory to generate
the graphical results from queries.  You must integrate these programs
in a current version of Netpbm (which may require some work: the
versions that appear here were developed and tested with Netpbm
version 10.25 dating from 2005), then install them where the CGI
programs can run them.

* **tools**: An Excel worksheet, `pixparam.xls`, used to develop the
mapping between pixel position and numerical parameters for processing
queries.

* **diy**: Images used to make a printable replica of the original
bumb effects calculator.

## Web resources

* [*Strangelove Slide Rule*:
Nuclear Bomb Effects Computer](https://www.fourmilab.ch/bombcalc/)
    - [Bomb Effects Computer Instructions](https://www.fourmilab.ch/bombcalc/instructions.html)
    - [Production Notes](https://www.fourmilab.ch/bombcalc/production.html)
    - [Build Your Own Bomb Effects Computer Slide Rule](https://www.fourmilab.ch/bombcalc/brico.html)
* [*The Effects of Nuclear Weapons*](https://www.fourmilab.ch/etexts/www/effects/)

