#include "fluid_renderer.h"
#include "core/os/os.h"

// i = x, j = y
#define IX(i,j) ((i)+(N+2)*(j))
#define SWAP(x0,x) {float * tmp=x0;x0=x;x=tmp;}
#define FOR_EACH_CELL for ( i=1 ; i<=N ; i++ ) { for ( j=1 ; j<=N ; j++ ) {
#define END_FOR }}

void FluidRenderer::draw_velocity(int N, Variant p_cells, Ref<FloatArray> p_u, Ref<FloatArray> p_v, float velocity_scale) {
    uint64_t ticks_from = OS::get_singleton()->get_ticks_usec();

    float * u = p_u->ptrw();
    float * v = p_v->ptrw();

    Array cells = p_cells;

    Vector3 vel;
    int i, j;
    FOR_EACH_CELL
        vel = Vector3(u[IX(i, j)] * velocity_scale, 0, -v[IX(i, j)] * velocity_scale);
        Array row = cells[j];
        Variant cell = row[i];
        Object *obj = cell;
        obj->call("set_velocity", vel); //(v);
    END_FOR

	uint64_t ticks_elapsed = OS::get_singleton()->get_ticks_usec() - ticks_from;
	print_line("draw_velocity (total " + rtos(ticks_elapsed / 1000.0) + "ms): ");
}

void FluidRenderer::_bind_methods() {
	ClassDB::bind_method(D_METHOD("draw_velocity"), &FluidRenderer::draw_velocity);
}

FluidRenderer::FluidRenderer() {}
FluidRenderer::~FluidRenderer() {}