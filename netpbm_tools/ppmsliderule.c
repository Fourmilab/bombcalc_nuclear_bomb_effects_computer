/*  ppmsliderule.c

    Assemble a slide rule image from a background and overlay
    images with transparency, each (circular) shifted by a
    specified amount.  Note that the options and file names may
    be intermixed, and a different shift and transparent colour
    may be specified for each overlay image.

    The base and all overlays must have the same size and
    maxval.  This restriction could be lifted with appropriate
    assumptions and twiddling, but in most cases such
    discrepancies indicate you're doing something dumb, so
    enforcing the requirement is likely to catch errors.

    Designed and implemented by John Walker (http://www.fourmilab.ch/)
    in June 2005.

*/

#include "ppm.h"
#include <string.h>

int main(argc, argv)
    int argc;
    char* argv[];
{
    FILE* ifp;
    pixel **ipixels, **apixels, **opixels  = NULL;
    int cols, rows, acols, arows, ocols, orows;
    pixval maxval, amaxval;
    int argn;
    int i, j;
    static const char compext[] = ".gz";                    /* Extension for compressed files */

    const char *transcolourName = "rgb:ff/00/ff";
    pixel transcolour;
    int shift = 0;

    const char *usage =
        " [-transparent color] [-shift n]  ppmfile ...";

    ppm_init(&argc, argv);

    argn = 1;

    while (argn < argc) {

        /*  Process options beginning with a hyphen.  */

        if (argv[argn][0] == '-') {
            if (pm_keymatch(argv[argn], "-shift", 2)) {
                if ((argn >= argc) || (sscanf(argv[++argn], "%d", &shift) != 1)) {
                    pm_usage(usage);
                }
            } else if (pm_keymatch(argv[argn], "-transparent", 2)) {
                transcolourName = argv[++argn];         /* Save transparent colour name (don't know maxval yet) */
            } else {
                pm_usage(usage);
            }
        } else {

            /*  This is the first file name.  Copy it, shifted as requested, to the output
                pixel array.  We do not apply transparency to the first image.  */

            if (opixels == NULL) {
                int piped = FALSE;


                if (strstr(argv[argn], compext) != NULL) {
                    char s[132];


                    piped = TRUE;
                    strcpy(s, "zcat ");
                    strcat(s, argv[argn]);
                    ifp = popen(s, "r");
                    if (ifp == NULL) {
                        pm_error("Cannot open pipe to uncompress %s", argv[argn]);
                    }
                } else {
                    ifp = pm_openr(argv[argn]);
                }

                ipixels = ppm_readppm(ifp, &cols, &rows, &maxval);

                if (piped) {
                    pclose(ifp);
                } else {
                    pm_close(ifp);
                }

                ocols = cols;
                orows = rows;

                while (shift < 0) {
                    shift += cols;
                }
                if (shift >= cols) {
                    shift %= cols;
                }
                pm_message("Loading base %s %d by %d at %d shifted %d.", argv[argn], cols, rows, maxval, shift);

                opixels = ppm_allocarray(ocols, orows);
                for (i = 0; i < cols; i++) {
                    int si = (i + shift) % cols;

                    for (j = 0; j < rows; j++) {
                        opixels[j][i] = ipixels[j][si];
                    }
                }
                ppm_freearray(ipixels, rows);
            } else {
                int piped = FALSE;

                /*  This is an overlay image.  Determine the transparent colour and copy
                    non-transparent pixels, shifted as requested, atop the current composite
                    image.  */

                if (strstr(argv[argn], compext) != NULL) {
                    char s[132];


                    piped = TRUE;
                    strcpy(s, "zcat ");
                    strcat(s, argv[argn]);
                    ifp = popen(s, "r");
                    if (ifp == NULL) {
                        pm_error("Cannot open pipe to uncompress %s", argv[argn]);
                    }
                } else {
                    ifp = pm_openr(argv[argn]);
                }
                apixels = ppm_readppm(ifp, &acols, &arows, &amaxval);
                if (piped) {
                    pclose(ifp);
                } else {
                    pm_close(ifp);
                }

                if ((cols != acols) || (rows != arows)) {
                    pm_error("Base image (%d x %d) and overlay (%d x %d) are different sizes",
                        cols, rows, acols, arows);
                }

                if (maxval != amaxval) {
                    pm_error("Base image (%d) and overlay (%d) have different maxval settings", maxval, amaxval);
                }

                while (shift < 0) {
                    shift += cols;
                }
                if (shift >= cols) {
                    shift %= cols;
                }
                pm_message("Merging overlay %s %d by %d at %d shifted %d.", argv[argn], acols, arows, amaxval, shift);

                transcolour = ppm_parsecolor(transcolourName, amaxval);

                for (i = 0; i < cols; i++) {
                    int si2 = (i + shift) % cols;;

                    for (j = 0; j < rows; j++) {

                        /* It's a win making a special case for completely transparent
                           pixels since we get to skip all the alpha blending logic for
                           every one, and there are a lot of them in typical images.  */

                        if (!PPM_EQUAL(apixels[j][si2], transcolour)) {
                            pixval r, g, b;
                            r = PPM_GETR(apixels[j][si2]);
                            g = PPM_GETG(apixels[j][si2]);
                            b = PPM_GETB(apixels[j][si2]);

                            if ((g == 0) && (r == b)) {
                                PPM_ASSIGN(opixels[j][i],
                                    (PPM_GETR(opixels[j][i]) * r) / maxval,
                                    (PPM_GETG(opixels[j][i]) * r) / maxval,
                                    (PPM_GETB(opixels[j][i]) * r) / maxval);
                            } else {
                                opixels[j][i] = apixels[j][si2];
                            }
                        }
                    }
                }
                ppm_freearray(apixels, rows);
            }
        }
        ++argn;
   }

    pm_message("Writing output %d by %d at %d.", ocols, orows, maxval);
    ppm_writeppm(stdout, opixels, ocols, orows, maxval, 0);
    pm_close(stdout);
    exit(0);
}
