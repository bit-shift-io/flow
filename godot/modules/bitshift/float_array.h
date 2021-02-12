#ifndef FLOAT_ARRAY_H
#define FLOAT_ARRAY_H

#include "core/object/reference.h"

//
// This class exists simply to allow us to pass a PackedFloat32Array around
// after being able to new it.
//
class FloatArray : public Reference {

	GDCLASS(FloatArray, Reference)
       
protected:

    PackedFloat32Array array;

	static void _bind_methods();
           
public:

    Error resize(int p_size);
    float get_value(int index);
    void set_value(int index, float value);

    void set_all(float value);

    float *ptrw();

	FloatArray();
	~FloatArray();            
};

#endif // FLOAT_ARRAY_H
