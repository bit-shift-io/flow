#ifndef FLUID_SOLVER_H
#define FLUID_SOLVER_H

#include "scene/3d/node_3d.h"

class FluidSolver : public Node3D {

	GDCLASS(FluidSolver, Node3D)
       
protected:

	static void _bind_methods();
	/*
	void _notification(int p_what);
	void _validate_property(PropertyInfo &property) const;
	*/
           
public:

	void set_bnd(int b, Ref<Image> x);
	void lin_solve(int b, Ref<Image> x, Ref<Image> x0, float a, float c);

	void add_source(Ref<Image> x, const Ref<Image>& s, float dt);
	void diffuse(int b, Ref<Image> x, Ref<Image> x0, float diff, float dt);
	void advect(int b, Ref<Image> d, Ref<Image> d0, Ref<Image> u, Ref<Image> v, float dt);
	void project(Ref<Image> u, Ref<Image> v, Ref<Image> p, Ref<Image> div);

	void density_step(Ref<Image> x, Ref<Image> x0, Ref<Image> u, Ref<Image> v, float diff, float dt);
	void velocity_step(Ref<Image> u, Ref<Image> v, Ref<Image> u0, Ref<Image> v0, float visc, float dt);

	/*
	void set_clutter_map(const Ref<Texture>& clutter_map);
    Ref<Texture> get_clutter_map() const;
      */

	FluidSolver();
	~FluidSolver();            
};

#endif // FLUID_SOLVER_H
