/********************************************************\
* A small utility to query games installed through Steam *
* Sam Stuewe (C) 2014 Licensed under the terms of        *
* the GNU Public License version 2                       *
\********************************************************/

#include <stdint.h> // int32_t
#include <stdlib.h> // getenv()
#include <string.h> // strlen(), strncpy(), strncat(), strerror()
#include <errno.h>  // errno
#include <unistd.h> // chdir()
#include <stdio.h>  // fprintf(), fopen(), fscanf(), printf(), fclose()
#include <glob.h>   // glob_t, glob(), gl_pathc, gl_pathv

int32_t
main (void) { // Add argp support

    const char * home = getenv("HOME");
    if ( home ) {
        size_t n = strlen(home) + 31;
        char steamdir [n + 1];
        strncpy(steamdir, home, n);
        strncat(steamdir, "/.local/share/Steam/steamapps/", n - strlen(steamdir));

        errno = 0;
        int32_t r = chdir(steamdir);
        int32_t errsv = errno;
        if ( r ) {
            fprintf(stderr, "Something went horribly wrong!: %s\n", strerror(errsv));
            return 1;
        }

        glob_t glb;
        r = glob("./*.acf", 0, NULL, &glb);
        if ( r ) {
            fprintf(stderr, "Something went horribly wrong (with the globbing)!\n");
        }

        FILE * f;
        uint32_t appid;
        char appname [128]; // longest game title I can find is 78-ish chars
        for ( size_t i = 0; i < glb.gl_pathc; i ++ ) {
            f = fopen(glb.gl_pathv[i], "r");
            fscanf(f, "%*[^d]d\"%*[^\"]\"%u%*[^m]me\"%*[^\"]\"%[^\"]", &appid, appname);
            printf("%u: %s\n", appid, appname);
            fclose(f);
        }
    } return 0;
}

// vim: set ts=4 sw=4 et:
