#ifndef FLUID_SOLVER_H
#define FLUID_SOLVER_H

#include "core/object/reference.h"
#include "float_array.h"

class FluidSolver : public Reference {

	GDCLASS(FluidSolver, Reference)
       
protected:

	static void _bind_methods();
           
public:

	void dump_array(int N, Ref<FloatArray> x);

	void density_step(int N, Ref<FloatArray> x, Ref<FloatArray> x0, Ref<FloatArray> u, Ref<FloatArray> v, float diff, float dt);
	void velocity_step(int N, Ref<FloatArray> u, Ref<FloatArray> v, Ref<FloatArray> u0, Ref<FloatArray> v0, float visc, float dt);

	FluidSolver();
	~FluidSolver();            
};

#endif // FLUID_SOLVER_H
