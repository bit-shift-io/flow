#ifndef ARROW_H
#define ARROW_H

#include "scene/3d/node_3d.h"
#include "modules/csg/csg_shape.h"

class CSGBox3D;

//
// Draw an arrow in 3d space
//
class Arrow3D : public Node3D {

	GDCLASS(Arrow3D, Node3D)
       
protected:

	static void _bind_methods();
           
	Node3D *node;

public:

	Arrow3D();
	~Arrow3D();  

	void _notification(int p_what); 

    void set_velocity(const Vector3& v);  
	void set_node(const Variant &p_box);       
};

#endif // ARROW_H
