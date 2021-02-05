#include "fluid_solver.h"
#include "globals.h"
#include "core/string/ustring.h"

#define FOR_EACH_CELL for ( i=1 ; i<=N ; i++ ) { for ( j=1 ; j<=N ; j++ ) {
#define END_FOR }}


void FluidSolver::dump_image(const Ref<Image>& x) {
	for (int yi = 0; yi < x->get_height(); ++yi) {
		String s = String::num(yi) + "| ";
		for (int xi = 0; xi < x->get_width(); ++xi) {
			Color c = x->get_pixel(xi, yi);
			s += String::num(c.r, 1) + ",";

			if (c.r > 0.f) {
				int nothing = 0;
				++nothing;
			}
		}
		DEBUG_PRINT(s);
	}
	DEBUG_PRINT("");
}


/*

#define IX(i,j) ((i)+(N+2)*(j))
#define SWAP(x0,x) {float * tmp=x0;x0=x;x=tmp;}
#define FOR_EACH_CELL for ( i=1 ; i<=N ; i++ ) { for ( j=1 ; j<=N ; j++ ) {
#define END_FOR }}

void add_source ( int N, float * x, float * s, float dt )
{
	int i, size=(N+2)*(N+2);
	for ( i=0 ; i<size ; i++ ) x[i] += dt*s[i];
}
*/

void FluidSolver::add_source(Ref<Image> x, const Ref<Image>& s, float dt) {
	//Image *img = const_cast<Image*>(x.ptr());
	for (int yi = 0; yi < x->get_height(); ++yi) {
		for (int xi = 0; xi < x->get_width(); ++xi) {
			Color c = s->get_pixel(xi, yi);
			c.r *= dt;


			if (c.r > 0.f) {
				int nothing = 0;
				++nothing;
			}

			x->set_pixel(xi, yi, c);
		}
	}
}
/*

void set_bnd ( int N, int b, float * x )
{
	int i;

	for ( i=1 ; i<=N ; i++ ) {
		x[IX(0  ,i)] = b==1 ? -x[IX(1,i)] : x[IX(1,i)];
		x[IX(N+1,i)] = b==1 ? -x[IX(N,i)] : x[IX(N,i)];
		x[IX(i,0  )] = b==2 ? -x[IX(i,1)] : x[IX(i,1)];
		x[IX(i,N+1)] = b==2 ? -x[IX(i,N)] : x[IX(i,N)];
	}
	x[IX(0  ,0  )] = 0.5f*(x[IX(1,0  )]+x[IX(0  ,1)]);
	x[IX(0  ,N+1)] = 0.5f*(x[IX(1,N+1)]+x[IX(0  ,N)]);
	x[IX(N+1,0  )] = 0.5f*(x[IX(N,0  )]+x[IX(N+1,1)]);
	x[IX(N+1,N+1)] = 0.5f*(x[IX(N,N+1)]+x[IX(N+1,N)]);
}
*/

void FluidSolver::set_bnd(int b, Ref<Image> x) {
	float N = x->get_width() - 2;

	int i;

	for ( i=1 ; i<=N ; i++ ) {

		x->set_pixel(0,i, b == 1 ? -x->get_pixel(1,i) : x->get_pixel(1,i));
		//x[IX(0  ,i)] = b==1 ? -x[IX(1,i)] : x[IX(1,i)];

		x->set_pixel(N+1,i, b == 1 ? -x->get_pixel(N,i) : x->get_pixel(N,i));
		//x[IX(N+1,i)] = b==1 ? -x[IX(N,i)] : x[IX(N,i)];

		x->set_pixel(i,0, b == 2 ? -x->get_pixel(i,1) : x->get_pixel(i,1));
		//x[IX(i,0  )] = b==2 ? -x[IX(i,1)] : x[IX(i,1)];

		x->set_pixel(i,N+1, b == 2 ? -x->get_pixel(i,N) : x->get_pixel(i,N));
		//x[IX(i,N+1)] = b==2 ? -x[IX(i,N)] : x[IX(i,N)];
	}
	
	Color col = 0.5f*(x->get_pixel(1,N+1)+x->get_pixel(0  ,N));
	x->set_pixel(0, 0, col);
	//x[IX(0  ,0  )] = 0.5f*(x[IX(1,0  )]+x[IX(0  ,1)]);

	col = 0.5f*(x->get_pixel(1,N+1)+x->get_pixel(0  ,N));
	x->set_pixel(0, N+1, col);
	//x[IX(0  ,N+1)] = 0.5f*(x[IX(1,N+1)]+x[IX(0  ,N)]);
	
	col = 0.5f*(x->get_pixel(N,0  )+x->get_pixel(N+1,1));
	x->set_pixel(N+1,0, col);
	//x[IX(N+1,0  )] = 0.5f*(x[IX(N,0  )]+x[IX(N+1,1)]);

	col = 0.5f*(x->get_pixel(N,N+1)+x->get_pixel(N+1,N));
	x->set_pixel(N+1,N+1, col);
	//x[IX(N+1,N+1)] = 0.5f*(x[IX(N,N+1)]+x[IX(N+1,N)]);
}

/*

void lin_solve ( int N, int b, float * x, float * x0, float a, float c )
{
	int i, j, k;

	for ( k=0 ; k<20 ; k++ ) {
		FOR_EACH_CELL
			x[IX(i,j)] = (x0[IX(i,j)] + a*(x[IX(i-1,j)]+x[IX(i+1,j)]+x[IX(i,j-1)]+x[IX(i,j+1)]))/c;
		END_FOR
		set_bnd ( N, b, x );
	}
}
*/

void FluidSolver::lin_solve(int b, Ref<Image> x, Ref<Image> x0, float a, float c) {
	float N = x->get_width() - 2;

	int i, j, k;

	for ( k=0 ; k<20 ; k++ ) {
		FOR_EACH_CELL
			// TODO: HOW CAN THIS write to x while reading to x? no copy?! susms suspect!

			Color prev = x0->get_pixel(i, j);
			Color cur_left = x->get_pixel(i-1,j);
			Color cur_right = x->get_pixel(i+1,j);
			Color cur_up = x->get_pixel(i, j-1);
			Color cur_down = x->get_pixel(i,j+1);
			Color col = (prev + a*(cur_left + cur_right + cur_up + cur_down))/c;
			

			if (prev.r > 0.f) {
				int nothing = 0;
				++nothing;
			}

			if (col.r > 0.f) {
				int nothing = 0;
				++nothing;
			}
			
			x->set_pixel(i, j, col);
			//x[IX(i,j)] = (x0[IX(i,j)] + a*(x[IX(i-1,j)]+x[IX(i+1,j)]+x[IX(i,j-1)]+x[IX(i,j+1)]))/c;
		END_FOR
		set_bnd(b, x);
	}
}

/*

void diffuse ( int N, int b, float * x, float * x0, float diff, float dt )
{
	float a=dt*diff*N*N;
	lin_solve ( N, b, x, x0, a, 1+4*a );
}

*/

void FluidSolver::diffuse(int b, Ref<Image> x, Ref<Image> x0, float diff, float dt) {
	float N = x->get_width() - 2;
	float a=dt*diff*N*N;
	lin_solve(b, x, x0, a, 1+4*a);
}

/*
void advect ( int N, int b, float * d, float * d0, float * u, float * v, float dt )
{
	int i, j, i0, j0, i1, j1;
	float x, y, s0, t0, s1, t1, dt0;

	dt0 = dt*N;
	FOR_EACH_CELL
		x = i-dt0*u[IX(i,j)]; y = j-dt0*v[IX(i,j)];
		if (x<0.5f) x=0.5f; if (x>N+0.5f) x=N+0.5f; i0=(int)x; i1=i0+1;
		if (y<0.5f) y=0.5f; if (y>N+0.5f) y=N+0.5f; j0=(int)y; j1=j0+1;
		s1 = x-i0; s0 = 1-s1; t1 = y-j0; t0 = 1-t1;
		d[IX(i,j)] = s0*(t0*d0[IX(i0,j0)]+t1*d0[IX(i0,j1)])+
					 s1*(t0*d0[IX(i1,j0)]+t1*d0[IX(i1,j1)]);
	END_FOR
	set_bnd ( N, b, d );
}
*/

void FluidSolver::advect(int b, Ref<Image> d, Ref<Image> d0, Ref<Image> u, Ref<Image> v, float dt) {
	float N = d->get_width() - 2;
	int i, j, i0, j0, i1, j1;
	float x, y, s0, t0, s1, t1, dt0;

	dt0 = dt*N;
	FOR_EACH_CELL
		x = i-dt0*u->get_pixel(i, j).r; y = j-dt0*v->get_pixel(i,j).r;
		if (x<0.5f) x=0.5f; if (x>N+0.5f) x=N+0.5f; i0=(int)x; i1=i0+1;
		if (y<0.5f) y=0.5f; if (y>N+0.5f) y=N+0.5f; j0=(int)y; j1=j0+1;
		s1 = x-i0; s0 = 1-s1; t1 = y-j0; t0 = 1-t1;
		Color col = s0*(t0*d0->get_pixel(i0,j0)+t1*d0->get_pixel(i0,j1))+
					 s1*(t0*d0->get_pixel(i1,j0)+t1*d0->get_pixel(i1,j1));
		d->set_pixel(i,j, col);
	END_FOR
	set_bnd(b, d);
}

/*

void project ( int N, float * u, float * v, float * p, float * div )
{
	int i, j;

	FOR_EACH_CELL
		div[IX(i,j)] = -0.5f*(u[IX(i+1,j)]-u[IX(i-1,j)]+v[IX(i,j+1)]-v[IX(i,j-1)])/N;
		p[IX(i,j)] = 0;
	END_FOR	
	set_bnd ( N, 0, div ); set_bnd ( N, 0, p );

	lin_solve ( N, 0, p, div, 1, 4 );

	FOR_EACH_CELL
		u[IX(i,j)] -= 0.5f*N*(p[IX(i+1,j)]-p[IX(i-1,j)]);
		v[IX(i,j)] -= 0.5f*N*(p[IX(i,j+1)]-p[IX(i,j-1)]);
	END_FOR
	set_bnd ( N, 1, u ); set_bnd ( N, 2, v );
}
*/

void FluidSolver::project(Ref<Image> u, Ref<Image> v, Ref<Image> p, Ref<Image> div) {
	int N = u->get_width() - 2;
	int i, j;

	FOR_EACH_CELL
		Color col = -0.5f*(u->get_pixel(i+1,j)-u->get_pixel(i-1,j)+v->get_pixel(i,j+1)-v->get_pixel(i,j-1))/N;
		div->set_pixel(i,j, col);
		//p->set_color(i,j,Color(0,0,0));
	END_FOR	
	p->set_as_black();

	set_bnd (0, div ); set_bnd (0, p );

	lin_solve (0, p, div, 1, 4 );

	FOR_EACH_CELL
		Color col = u->get_pixel(i,j) - 0.5f*N*(p->get_pixel(i+1,j)-p->get_pixel(i-1,j));
		u->set_pixel(i,j,col); //u[IX(i,j)] -= 0.5f*N*(p[IX(i+1,j)]-p[IX(i-1,j)]);

		col = v->get_pixel(i,j) - 0.5f*N*(p->get_pixel(i,j+1)-p->get_pixel(i,j-1));
		v->set_pixel(i,j,col); //v[IX(i,j)] -= 0.5f*N*(p[IX(i,j+1)]-p[IX(i,j-1)]);
	END_FOR
	set_bnd (1, u ); set_bnd (2, v );
}

/*
void dens_step ( int N, float * x, float * x0, float * u, float * v, float diff, float dt )
{
	add_source ( N, x, x0, dt );
	SWAP ( x0, x ); diffuse ( N, 0, x, x0, diff, dt );
	SWAP ( x0, x ); advect ( N, 0, x, x0, u, v, dt );
}

void vel_step ( int N, float * u, float * v, float * u0, float * v0, float visc, float dt )
{
	add_source ( N, u, u0, dt ); add_source ( N, v, v0, dt );
	SWAP ( u0, u ); diffuse ( N, 1, u, u0, visc, dt );
	SWAP ( v0, v ); diffuse ( N, 2, v, v0, visc, dt );
	project ( N, u, v, u0, v0 );
	SWAP ( u0, u ); SWAP ( v0, v );
	advect ( N, 1, u, u0, u0, v0, dt ); advect ( N, 2, v, v0, u0, v0, dt );
	project ( N, u, v, u0, v0 );
}

*/

void FluidSolver::density_step(Ref<Image> x, Ref<Image> x0, Ref<Image> u, Ref<Image> v, float diff, float dt) {
	add_source(x, x0, dt);
	SWAP ( x0, x ); diffuse (0, x, x0, diff, dt );
	SWAP ( x0, x ); advect (0, x, x0, u, v, dt );

	//dump_image(x);
}

void FluidSolver::velocity_step(Ref<Image> u, Ref<Image> v, Ref<Image> u0, Ref<Image> v0, float visc, float dt) {
	add_source(u, u0, dt); add_source(v, v0, dt);
	SWAP ( u0, u ); diffuse (1, u, u0, visc, dt );
	SWAP ( v0, v ); diffuse (2, v, v0, visc, dt );
	project (u, v, u0, v0 );
	SWAP ( u0, u ); SWAP ( v0, v );
	advect (1, u, u0, u0, v0, dt ); advect (2, v, v0, u0, v0, dt );
	project (u, v, u0, v0 );
}

void FluidSolver::_bind_methods() {
	ClassDB::bind_method(D_METHOD("density_step"), &FluidSolver::density_step);
	ClassDB::bind_method(D_METHOD("velocity_step"), &FluidSolver::velocity_step);

	ClassDB::bind_method(D_METHOD("add_source"), &FluidSolver::add_source);
	ClassDB::bind_method(D_METHOD("diffuse"), &FluidSolver::diffuse);
	ClassDB::bind_method(D_METHOD("advect"), &FluidSolver::advect);
	ClassDB::bind_method(D_METHOD("project"), &FluidSolver::project);
}

FluidSolver::FluidSolver() {}
FluidSolver::~FluidSolver() {}