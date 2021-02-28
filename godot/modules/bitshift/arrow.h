#ifndef ARROW_H
#define ARROW_H

//
// Draw an arrow in 3d space
//
class Arrow : public Node3D {

	GDCLASS(Arrow, Node3D)
       
protected:

	static void _bind_methods();
           
public:

	Arrow();
	~Arrow();   

    void set_velocity(const Vector3& v);         
};

#endif // ARROW_H
