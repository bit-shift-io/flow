#include "ut.h"

Ut *Ut::singleton=NULL;

Ut::Ut() {
    singleton = this;
}

Ut::~Ut() {
    singleton = NULL;
}

void Ut::_bind_methods() {
    ClassDB::bind_method(D_METHOD("packed_array_get"), &Ut::packed_array_get);    
}

float Ut::packed_array_get(const PackedFloat32Array& arr, float index) {
    return arr[index];
}
