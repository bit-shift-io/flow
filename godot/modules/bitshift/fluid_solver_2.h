#ifndef FLUID_SOLVER_2_H
#define FLUID_SOLVER_2_H

#include "scene/3d/node_3d.h"

class FluidSolver2 : public Node3D {

	GDCLASS(FluidSolver2, Node3D)
       
protected:

	static void _bind_methods();
           
public:

	//void dump_image(Ref<PackedFloat32Array> x);

	void density_step(int N, const Variant& x, PackedFloat32Array x0, PackedFloat32Array u, PackedFloat32Array v, float diff, float dt);
	void velocity_step(int N, PackedFloat32Array u, PackedFloat32Array v, PackedFloat32Array u0, PackedFloat32Array v0, float visc, float dt);

	FluidSolver2();
	~FluidSolver2();            
};

#endif // FLUID_SOLVER_2_H
