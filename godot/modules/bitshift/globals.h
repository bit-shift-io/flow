#ifndef BGLOBALS_H
#define BGLOBALS_H

#include "core/math/quat.h"

#ifdef DEBUG_ENABLED
    #define DEBUG_PRINT(_x_) print_line( _x_ );
#else
    #define DEBUG_PRINT(_x_)
#endif

typedef Quat Vector4;

#endif // BGLOBALS_H
