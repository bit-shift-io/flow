#include "ut.h"

Ut *Ut::singleton=NULL;

Ut::Ut() {
    singleton = this;
}

Ut::~Ut() {
    singleton = NULL;
}

void Ut::_bind_methods() {
    
}
