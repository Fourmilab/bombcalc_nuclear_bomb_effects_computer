/* pgmmidtone.c - read a portable graymap and force midtones to a uniform value

*/

#include <stdio.h>
#include "ppm.h"

int
main( argc, argv )
    int argc;
    char* argv[];
{
    FILE *ifp;
    pixval maxval;
    pixel** gin;
    pixel** gout;
    int argn, rows, cols, row, col;
    const char* const usage = "[ppmfile]";
    int lowmid = 128, highmid = 255;
    pixval repr = 130, repg = 180, repb = 155;

    ppm_init( &argc, argv );

    argn = 1;

    if ( argn < argc )
        {
        ifp = pm_openr( argv[argn] );
        ++argn;
        }
    else
        ifp = stdin;

    if ( argn != argc )
        pm_usage( usage );

    gin = ppm_readppm( ifp, &cols, &rows, &maxval );
    pm_close( ifp );
    gout = ppm_allocarray( cols, rows );

    for ( row = 0; row < rows; ++row ) {
        for ( col = 0; col < cols; ++col ) {
            pixval r = PPM_GETR(gin[row][col]),
                   g = PPM_GETG(gin[row][col]),
                   b = PPM_GETB(gin[row][col]);

            if ((r == g) && (r == b) && (g >= lowmid) && (g <= highmid)) {
                PPM_ASSIGN(gout[row][col], repr, repg, repb);
            } else {
                gout[row][col] = gin[row][col];
            }
        }
    }

    ppm_writeppm( stdout, gout, cols, rows, maxval, 0 );
    pm_close( stdout );
    ppm_freearray( gout, rows );

    exit( 0 );
    }
