extends Node


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


#
# This program is used to compute neumann boundary conditions for solving
# poisson problems.  The neumann boundary condition for the poisson equation
# says that partial(u)/partial(n) = 0, where n is the normal direction of the
# inside of the boundary.  This simply means that the value of the field
# does not change across the boundary in the normal direction.
# 
# In the case of our simple grid, this simply means that the value of the 
# field at the boundary should equal the value just inside the boundary.
#
# We allow the user to specify the direction of "just inside the boundary" 
# by using texture coordinate 1.
#
# Thus, to use this program on the left boundary, TEX1 = (1, 0):
#
# LEFT:   TEX1=( 1,  0)
# RIGHT:  TEX1=(-1,  0)
# BOTTOM: TEX1=( 0,  1)
# TOP:    TEX1=( 0, -1)
# 

#func boundary(half2       coords : WPOS, 
#			  half2       offset : TEX1,
#		  out half4       bv     : COLOR,
#	  uniform half        scale, 
#	  uniform samplerRECT x)
#{
#  bv = scale * h4texRECT(x, coords + offset); 
#} 

# TODO: here working on this, where is offset coming from?
func boundary(output_texture, coords, scale, offset, x_texture):
	var bv = scale * x_texture.get(coords + offset);
	output_texture.set(coords, bv);
