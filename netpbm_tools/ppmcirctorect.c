/*  ppmcirctorect.c

    Map a portable pixmap from a circular to rectangular projection
    and back.

    You can use this, for example, to "unwrap" circular slide rules
    or gauge faces, or create such from linear scales.

    Designed and implemented by John Walker (http://www.fourmilab.ch/)
    in June 2005.

*/

#include <math.h>
#include "ppm.h"

#define PI      3.141592653589793238
#define TWO_PI  (PI * 2.0)

int
main( argc, argv )
    int argc;
    char* argv[];
    {
    FILE* ifp;
    pixel **ipixels, **opixels;
    int cols, rows, ocols, orows;
    pixval maxval;
    int argn;
    int i, j, ix, iy;

    int radius = 0, ctrx = 0, ctry = 0;
    int recttocirc = FALSE;
    const char *backgroundName = "rgb:00/00/00";
    pixel background;
    const char * usage =
        " [-background color] [-circle] [-radius n] [-xctr n] [-yctr n]  ppmfile";

    ppm_init( &argc, argv );

    argn = 1;

    while ( argn < argc && argv[argn][0] == '-' && argv[argn][1] != '\0' ) {
        if (pm_keymatch(argv[argn], "-background", 2)) {
            backgroundName =  argv[++argn];
         } else if (pm_keymatch(argv[argn], "-circle", 2)) {
            recttocirc = TRUE;
        } else if (pm_keymatch(argv[argn], "-radius", 2)) {
            if ((argn >= argc) || (sscanf(argv[++argn], "%d", &radius) != 1))
                pm_usage(usage);

        } else if (pm_keymatch(argv[argn], "-xctr", 2)) {
            if ((argn >= argc) || (sscanf(argv[++argn], "%d", &ctrx) != 1))
                pm_usage(usage);

        } else if (pm_keymatch(argv[argn], "-yctr", 2)) {
            if ((argn >= argc) || (sscanf(argv[++argn], "%d", &ctry) != 1))
                pm_usage(usage);

        } else {
            pm_usage( usage );
        }
        ++argn;
   }

    if ( argn != argc ) {
        ifp = pm_openr( argv[argn] );
        ++argn;
    } else {
        ifp = stdin;
    }

    if ( argn != argc ) {
        pm_usage( usage );
    }

    ipixels = ppm_readppm( ifp, &cols, &rows, &maxval );
    pm_close( ifp );

    background = ppm_parsecolor(backgroundName, maxval);

    if (recttocirc) {

        /*  Mapping a rectangular image to a circle.  No geometry options
            affect the result, as we assume the mapping is to be
            the inverse of that performed by this program when run
            without the -circle option.  If the input pixmap has some
            other mapping, no harm will be done but the output, while
            amusing, is unlikely to be useful.  */

        ocols = orows = rows;

        opixels = ppm_allocarray(ocols, orows);

        if ((PPM_GETR(background) != 0) ||
            (PPM_GETG(background) != 0) ||
            (PPM_GETB(background) != 0)) {
            for (i = 0; i < ocols; i++) {
                for (j = 0; j < orows; j++) {
                    opixels[j][i] = background;
                }
            }
        }

#ifdef OLDWAY
        for (i = 0; i < cols; i++) {
            double angle = TWO_PI * ((double) i) / cols;

            for (j = 0; j < rows; j++) {
                double rj = ((rows - 1) - j) / 2.0;
                ix = MIN(ocols - 1, MAX(0, (ocols / 2) + ((int) (cos(angle) * rj))));
                iy = MIN(orows - 1, MAX(0, (orows / 2) + ((int) (sin(angle) * rj))));
                opixels[iy][ix] = ipixels[j][i];
            }
        }
#else
        /* Reduce loops to ocols/2, orows/2, use symmetry to set pixels. */
        for (i = 0; i < ocols; i++) {
            int dx = (ocols / 2) - i;
            for (j = 0; j < orows; j++) {
                int dy = (orows / 2) - j,
                    ir = (dx * dx) + (dy * dy);
                if (ir < ((orows * orows) / 4)) {
                    double r = sqrt((double) ir) * 2,
                           theta = atan2((double) dy, (double) dx) + M_PI;

                    ix = MIN(cols - 1, MAX(0, ((int) ((cols - 1) * theta) / (2 * M_PI))));
                    iy = MIN(rows - 1, MAX(0, ((int) r)));
                    opixels[j][i] = ipixels[(rows - 1) - iy][ix];
                }

            }
        }
#endif

    } else {

        /*  Mapping a circular image to a rectangle.  Set centre
            and radius of the circle to default values if not
            specified.  */

        if (radius == 0) {
            radius = cols / 2;
        }
        if (ctrx == 0) {
            ctrx = radius;
        }
        if (ctry == 0) {
            ctry = radius;
        }

        orows = radius;
        ocols = (int) (TWO_PI * radius);
        opixels = ppm_allocarray(ocols, orows);

        for (i = 0; i < ocols; i++) {
            double angle = ((double) i) / radius;

            for (j = 0; j < orows; j++) {

                ix = MIN(cols, MAX(0, ctrx + ((int) (cos(angle) * j))));
                iy = MIN(rows, MAX(0, ctry + ((int) (sin(angle) * j))));

                opixels[(orows - 1) - j][i] = ipixels[iy][ix];
            }
        }
    }

    ppm_writeppm(stdout, opixels, ocols, orows, maxval, 0);
    pm_close(stdout);
    exit(0);
}
