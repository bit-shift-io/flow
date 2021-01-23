extends Node

func set_bnd(N, b, x):
	"""We assume that the fluid is contained in a box with solid walls.

	No flow should exit the walls. This simply means that the horizontal
	component of the velocity should be zero on the vertical walls, while the
	vertical component of the velocity should be zero on the horizontal walls.
	For the density and other fields considered in the code we simply assume
	continuity. The following code implements these conditions.
	"""

	for i in range(1, N + 1):
		if b == 1:
			x[0][i] = -x[1][i]
		else:
			x[0][i] = x[1][i]
			
		if b == 1:
			x[N + 1][i] = -x[N][i]
		else:
			x[N + 1][i] = x[N][i]
			
		if b == 2:
			x[i][0] = -x[i][1]
		else:
			x[i][0] = x[i][1]
			
		if b == 2:
			x[i][N + 1] = -x[i][N]
		else:
			x[i][N + 1] = x[i][N]

	x[0][0] = 0.5 * (x[1][0] + x[0][1])
	x[0][N + 1] = 0.5 * (x[1][N + 1] + x[0][N])
	x[N + 1][0] = 0.5 * (x[N][0] + x[N + 1][1])
	x[N + 1][N + 1] = 0.5 * (x[N][N + 1] + x[N + 1][N])


func lin_solve(N, b, x, x0, a, c):
	"""lin_solve."""

	for k in range(0, 20):
		for i in range(1, N + 1):
			for j in range(1, N + 1):
				x[i][j] = (x0[i][j] + a * (x[i-1][j] + x[i+1][j] + x[i][j-1] + x[i][j+1])) / c;
				
				#x[IX(i,j)] = (x0[IX(i,j)] + a*(x[IX(i-1,j)]+x[IX(i+1,j)]+x[IX(i,j-1)]+x[IX(i,j+1)]))/c;
				#x[1:N + 1, 1:N + 1] = (x0[1:N + 1, 1:N + 1] + a *
				#			   (x[0:N, 1:N + 1] +
				#				x[2:N + 2, 1:N + 1] +
				#				x[1:N + 1, 0:N] +
				#				x[1:N + 1, 2:N + 2])) / c
				
		set_bnd(N, b, x)


func add_source(N, x, s, dt):
	"""Addition of forces: the density increases due to sources."""
	
	for i in range(0, N + 2):
		for j in range(0, N + 2):
			x[i][j] += dt * s[i][j];



func diffuse(N, b, x, x0, diff, dt):
	"""Diffusion: the density diffuses at a certain rate.

	The basic idea behind our method is to find the densities which when
	diffused backward in time yield the densities we started with. The simplest
	iterative solver which works well in practice is Gauss-Seidel relaxation.
	"""

	var a = dt * diff * N * N
	lin_solve(N, b, x, x0, a, 1 + 4 * a)


func advect(N, b, d, d0, u, v, dt):
	"""Advection: the density follows the velocity field.

	The basic idea behind the advection step. Instead of moving the cell
	centers forward in time through the velocity field, we look for the
	particles which end up exactly at the cell centers by tracing backwards in
	time from the cell centers.
	"""

	var dt0 = dt * N
	for i in range(1, N + 1):
		for j in range(1, N + 1):
			var x = i - dt0 * u[i][j]
			var y = j - dt0 * v[i][j]
			if x < 0.5:
				x = 0.5
			if x > N + 0.5:
				x = N + 0.5
			var i0 = int(x)
			var i1 = i0 + 1
			
			if y < 0.5:
				y = 0.5
			if y > N + 0.5:
				y = N + 0.5
			var j0 = int(y)
			var j1 = j0 + 1
			
			var s1 = x - i0
			var s0 = 1 - s1
			var t1 = y - j0
			var t0 = 1 - t1
			d[i][j] = s0 * (t0 * d0[i0][j0] + t1 * d0[i0][j1]) + s1 * (t0 * d0[i1][j0] + t1 * d0[i1][j1])
	
	set_bnd(N, b, d)


func project(N, u, v, p, div):
	"""project."""

	var h = 1.0 / N
	
	for i in range(1, N + 1):
		for j in range(1, N + 1):
			div[i][j] = -0.5 * h * (u[i+1][j] - u[i-1][j] + v[i][j+1] - v[i][j-1])
			p[i][j] = 0;
			
	set_bnd(N, 0, div)
	set_bnd(N, 0, p)
	lin_solve(N, 0, p, div, 1, 4)
	
	for i in range(1, N + 1):
		for j in range(1, N + 1):
			u[i][j] -= 0.5 * N * p[i+1][j] - p[i-1][j];
			v[i][j] -= 0.5 * N * p[i][j+1] - p[i][j-1];

	set_bnd(N, 1, u)
	set_bnd(N, 2, v)


func dens_step(N, x, x0, u, v, diff, dt):
	"""Evolving density.

	It implies advection, diffusion, addition of sources.
	"""

	# Add (x0 * dt) to x
	# x0 is the previous density
	add_source(N, x, x0, dt)
	
	# swap - is this swapping contents or what x and x0 point to?
	var tmp = x;
	x = x0;
	x0 = tmp;
	
	diffuse(N, 0, x, x0, diff, dt)	
	
	# swap
	tmp = x;
	x = x0;
	x0 = tmp;
	
	advect(N, 0, x, x0, u, v, dt)

func check_if_velocity_increasing(N, u, v, u0, v0, velocityAllowedToIncrease):
	if (velocityAllowedToIncrease):
		return;
		
	var epsilon = 0.00001;
	for i in range(1, N + 1):
		for j in range(1, N + 1):
			var uval = abs(u[i][j]);
			var u0val = abs(u0[i][j]);
			if ((uval - epsilon) > u0val):
				print("unstable! force is increasing!");
				
			var vval = abs(v[i][j]);
			var v0val = abs(v0[i][j]);
			if ((vval - epsilon) > v0val):
				print("unstable! force is increasing!");
	
	
func vel_step(N, u, v, u0, v0, visc, dt, velocityAllowedToIncrease):
	"""Evolving velocity.

	It implies self-advection, viscous diffusion, addition of forces.
	"""

	# Add the previous velocity (u0,v0) to the current velocity (u,v)
	add_source(N, u, u0, dt)
	add_source(N, v, v0, dt)
	
	# swap
	var tmp = u;
	u = u0;
	u0 = tmp;
	
	# swap
	tmp = v;
	v = v0;
	v0 = tmp;
	
	# Diffuse the velocity
	diffuse(N, 1, u, u0, visc, dt)
	diffuse(N, 2, v, v0, visc, dt)
	
	
	# what does this do?
	project(N, u, v, u0, v0)
	
	
	#check_if_velocity_increasing(N, u, v, u0, v0, velocityAllowedToIncrease);
	#return;
	
	# swap
	tmp = u;
	u = u0;
	u0 = tmp;
	
	tmp = v;
	v = v0;
	v0 = tmp;
	
	# move the velocity along the velocity field?
	advect(N, 1, u, u0, u0, v0, dt)
	advect(N, 2, v, v0, u0, v0, dt)
	
	
	# what does this do?
	project(N, u, v, u0, v0)
