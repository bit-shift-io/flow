#include "float_array.h"

FloatArray::FloatArray() {
}

FloatArray::~FloatArray() {
}

void FloatArray::_bind_methods() {
    ClassDB::bind_method(D_METHOD("resize"), &FloatArray::resize);
    ClassDB::bind_method(D_METHOD("get_value"), &FloatArray::get_value);
    ClassDB::bind_method(D_METHOD("set_value"), &FloatArray::set_value);
    ClassDB::bind_method(D_METHOD("set_all"), &FloatArray::set_all);
}

int FloatArray::size() {
    return array.size();
}

Error FloatArray::resize(int p_size) {
    return array.resize(p_size);
}

float FloatArray::get_value(int index) {
    return array[index];
}

void FloatArray::set_value(int index, float value) {
    array.set(index, value);
}

void FloatArray::set_all(float value) {
    for (auto i = 0; i < array.size(); ++i) {
        array.set(i, value);
    }
}

float *FloatArray::ptrw() {
    return array.ptrw();
}

void FloatArray::copy(Ref<FloatArray> other) {
    if (other->size() != size()) {
        print_line("[FloatArray::copy] size mismatch");
        return;
    }

    for (auto i = 0; i < array.size(); ++i) {
        array.set(i, other->get_value(i));
    }
}