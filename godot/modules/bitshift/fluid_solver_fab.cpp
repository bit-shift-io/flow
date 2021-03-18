#include "fluid_solver_fab.h"
#include "globals.h"
#include "core/os/os.h"

// i = x, j = y
#define IX(i,j) ((i)+(N+2)*(j))
#define SWAP(x0,x) {float * tmp=x0;x0=x;x=tmp;}
#define FOR_EACH_CELL for ( i=1 ; i<=N ; i++ ) { for ( j=1 ; j<=N ; j++ ) {
#define END_FOR }}


static void dump_array(int N, float * x) {
	int i,j;
	for ( i=1 ; i<=N ; i++ ) { 
		String s = String::num(i) + "|| ";
		if (i < 10) {
			s = " " + s;
		}

		for ( j=1 ; j<=N ; j++ ) {

			float v = x[IX(i,j)];
			s += String::num(v, 2) + " | ";
		}
		DEBUG_PRINT(s);
	}
	DEBUG_PRINT("");
}

static void dump_array_2(int N, float * u, float * v) {
	int i,j;
	for ( i=1 ; i<=N ; i++ ) { 
		String s = String::num(i) + "|| ";
		if (i < 10) {
			s = " " + s;
		}

		for ( j=1 ; j<=N ; j++ ) {

			float u_val = u[IX(i,j)];
			float v_val = v[IX(i,j)];
			s += String::num(u_val, 2) + "," + String::num(v_val, 2) + " | ";
		}
		DEBUG_PRINT(s);
	}
	DEBUG_PRINT("");
}

void FluidSolverFab::dump_array(int N, Ref<FloatArray> x) {
	::dump_array(N, x->ptrw());
}

// move a pressure/density (x0) (single float value) through a force field (u, v)
// x serves as a temporary storage
void FluidSolverFab::density_step(int N, Ref<FloatArray> x, Ref<FloatArray> x0, Ref<FloatArray> u, Ref<FloatArray> v, float diff, float dt) {
	uint64_t ticks_from = OS::get_singleton()->get_ticks_usec();

	float *pu = u->ptrw();
	float *pv = v->ptrw();
	float *px = x->ptrw();
	float *px0 = x0->ptrw();

	int i, j;

	// clear the current pressure (which we treat just as a working/temporary buffer)
	FOR_EACH_CELL
		px[IX(i, j)] = 0.f;
	END_FOR

	// use uv (velocity field) to move the pressure through
	FOR_EACH_CELL
		float pres = px0[IX(i, j)]; // pressure or density

		float vel_x = pu[IX(i, j)];// * dt;
		float vel_y = pv[IX(i, j)];// * dt;

		if (pres > 0.f) {
			int nothing = 0;
			++nothing;
		}

		// the target - where the pressure wants to go
		float target_x = i + vel_x;
		float target_y = j + vel_y;

		// round to the nearest cell, floor and ceiling
		int target_x_floor = floor(target_x);
		int target_y_floor = floor(target_y);

		int target_x_ceil = ceil(target_x);
		int target_y_ceil = ceil(target_y);

		bool target_out_of_bounds = false;

		// velocity fell off the map!
		if (target_x_floor < 0 || target_y_floor < 0) {
			target_out_of_bounds = true;
		}

		// velocity fell off the map!
		if (target_x_ceil >= (N+2) || target_x_ceil >= (N+2)) {
			target_out_of_bounds = true;
		}

		if (target_out_of_bounds) {
			continue;
		}

		// compute the delta from the floor
		// which will tell us what percentage needs to do into the ceiling square (delta%)
		// while the (1 - delta)% goes into the floor square
		float x_delta = target_x - target_x_floor;
		float y_delta = target_y - target_y_floor;

		// now we have the 4 cells around where the velocity wants to go
		// so we need to divy up the velocity over these 4 cells

		// cell: (x-floor, y-floor)
		float x_floor_y_floor_pres = pres * (1.0 - x_delta) * (1.0 - y_delta);
		px[IX(target_x_floor, target_y_floor)] += x_floor_y_floor_pres;

		// cell: (x-floor, y-ceil)
		float x_floor_y_ceil_pres = pres * (1.0 - x_delta) * y_delta;
		px[IX(target_x_floor, target_y_ceil)] += x_floor_y_ceil_pres;

		// cell: (x-ceil, y-ceil)
		float x_ceil_y_ceil_pres = pres * x_delta * y_delta;
		px[IX(target_x_ceil, target_y_ceil)] += x_ceil_y_ceil_pres;

		// cell: (x-ceil, y-floor)
		float x_ceil_y_floor_pres = pres * x_delta * (1.0 - y_delta);
		px[IX(target_x_ceil, target_y_floor)] += x_ceil_y_floor_pres;

		/*

		// lets double check
		// yep! pres ~= test_press
		float test_pres = x_floor_y_floor_pres + x_floor_y_ceil_pres + x_ceil_y_ceil_pres + x_ceil_y_floor_pres;
		*/

		int nothing = 0;
		++nothing;
	END_FOR

	// copy (x) back to (x0)
	x0->copy(x);

	uint64_t ticks_elapsed = OS::get_singleton()->get_ticks_usec() - ticks_from;
	print_line("density_step (total " + rtos(ticks_elapsed / 1000.0) + "ms): ");
}

// move a velocity (u0, v0) (2 floats) through a force field (u0, v0)
// (u, v) serves as temporary working space
void FluidSolverFab::velocity_step(int N, Ref<FloatArray> u, Ref<FloatArray> v, Ref<FloatArray> u0, Ref<FloatArray> v0, float visc, float dt) {
	uint64_t ticks_from = OS::get_singleton()->get_ticks_usec();

	float *pu = u->ptrw();
	float *pv = v->ptrw();
	float *pu0 = u0->ptrw();
	float *pv0 = v0->ptrw();

	int i, j;

	// clear the current veloicity (which we treat just as a working/temporary buffer)
	FOR_EACH_CELL
		pu[IX(i, j)] = 0.f;
		pv[IX(i, j)] = 0.f;
	END_FOR	

	// move velocity from old velocity to the new location (advect?)
	FOR_EACH_CELL
		float vel_x = pu0[IX(i, j)];// * dt;
		float vel_y = pv0[IX(i, j)];// * dt;

		if (vel_x > 0.f) {
			int nothing = 0;
			++nothing;
		}

		if (vel_y > 0.f) {
			int nothing = 0;
			++nothing;
		}

		// the target - where the velocity wants to go
		float target_x = i + vel_x;
		float target_y = j + vel_y;

		// round to the nearest cell, floor and ceiling
		int target_x_floor = floor(target_x);
		int target_y_floor = floor(target_y);

		int target_x_ceil = ceil(target_x);
		int target_y_ceil = ceil(target_y);

		bool target_out_of_bounds = false;

		// velocity fell off the map!
		if (target_x_floor < 0 || target_y_floor < 0) {
			target_out_of_bounds = true;
		}

		// velocity fell off the map!
		if (target_x_ceil >= (N+2) || target_x_ceil >= (N+2)) {
			target_out_of_bounds = true;
		}

		if (target_out_of_bounds) {
			continue;
		}

		// compute the delta from the floor
		// which will tell us what percentage needs to do into the ceiling square (delta%)
		// while the (1 - delta)% goes into the floor square
		float x_delta = target_x - target_x_floor;
		float y_delta = target_y - target_y_floor;

		// now we have the 4 cells around where the velocity wants to go
		// so we need to divy up the velocity over these 4 cells

		// cell: (x-floor, y-floor)
		float x_floor_y_floor_vel_x = vel_x * (1.0 - x_delta) * (1.0 - y_delta);
		float x_floor_y_floor_vel_y = vel_y * (1.0 - x_delta) * (1.0 - y_delta);
		pu[IX(target_x_floor, target_y_floor)] += x_floor_y_floor_vel_x;
		pv[IX(target_x_floor, target_y_floor)] += x_floor_y_floor_vel_y;

		// cell: (x-floor, y-ceil)
		float x_floor_y_ceil_vel_x = vel_x * (1.0 - x_delta) * y_delta;
		float x_floor_y_ceil_vel_y = vel_y * (1.0 - x_delta) * y_delta;
		pu[IX(target_x_floor, target_y_ceil)] += x_floor_y_ceil_vel_x;
		pv[IX(target_x_floor, target_y_ceil)] += x_floor_y_ceil_vel_y;

		// cell: (x-ceil, y-ceil)
		float x_ceil_y_ceil_vel_x = vel_x * x_delta * y_delta;
		float x_ceil_y_ceil_vel_y = vel_y * x_delta * y_delta;
		pu[IX(target_x_ceil, target_y_ceil)] += x_ceil_y_ceil_vel_x;
		pv[IX(target_x_ceil, target_y_ceil)] += x_ceil_y_ceil_vel_y;

		// cell: (x-ceil, y-floor)
		float x_ceil_y_floor_vel_x = vel_x * x_delta * (1.0 - y_delta);
		float x_ceil_y_floor_vel_y = vel_y * x_delta * (1.0 - y_delta);
		pu[IX(target_x_ceil, target_y_floor)] += x_ceil_y_floor_vel_x;
		pv[IX(target_x_ceil, target_y_floor)] += x_ceil_y_floor_vel_y;

		/*
		// lets double check
		// yep! vel_x ~= test_x_vel, vel_y ~= test_y_vel
		float test_x_vel = x_floor_y_floor_vel_x + x_floor_y_ceil_vel_x + x_ceil_y_ceil_vel_x + x_ceil_y_floor_vel_x;
		float test_y_vel = x_floor_y_floor_vel_y + x_floor_y_ceil_vel_y + x_ceil_y_ceil_vel_y + x_ceil_y_floor_vel_y;
		*/
		int nothing = 0;
		++nothing;
	END_FOR	

/*
	print_line("-- prev vel ------------");
	dump_array_2(N, pu0, pv0);
	print_line("-- next/cur vel ------------");
	dump_array_2(N, pu, pv);
*/

	// copy (u,v) back to (u0,v0)
	u0->copy(u);
	v0->copy(v);

	uint64_t ticks_elapsed = OS::get_singleton()->get_ticks_usec() - ticks_from;
	print_line("velocity_step (total " + rtos(ticks_elapsed / 1000.0) + "ms): ");
}

void FluidSolverFab::_bind_methods() {
	ClassDB::bind_method(D_METHOD("density_step"), &FluidSolverFab::density_step);
	ClassDB::bind_method(D_METHOD("velocity_step"), &FluidSolverFab::velocity_step);
	ClassDB::bind_method(D_METHOD("dump_array"), &FluidSolverFab::dump_array);
}

FluidSolverFab::FluidSolverFab() {}
FluidSolverFab::~FluidSolverFab() {}