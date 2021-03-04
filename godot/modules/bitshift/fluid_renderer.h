#ifndef FLUID_RENDERER_H
#define FLUID_RENDERER_H

#include "core/object/reference.h"
#include "float_array.h"

//
// Class to help draw fluids
//
class FluidRenderer : public Reference {

	GDCLASS(FluidRenderer, Reference)
       
protected:

	static void _bind_methods();
           
public:

    void draw_velocity(int N, Variant cells, Ref<FloatArray> u, Ref<FloatArray> v, float velocity_scale);

	FluidRenderer();
	~FluidRenderer();            
};

#endif // FLUID_RENDERER_H
