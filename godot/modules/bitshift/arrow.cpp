#include "arrow.h"

void Arrow3D::_bind_methods() {
    ClassDB::bind_method(D_METHOD("set_node"), &Arrow3D::set_node);
    ClassDB::bind_method(D_METHOD("set_velocity"), &Arrow3D::set_velocity);
}
       
Arrow3D::Arrow3D(): node(nullptr) {}
Arrow3D::~Arrow3D() {}


void Arrow3D::_notification(int p_what) {
	switch (p_what) {
		case NOTIFICATION_READY: {
            if (!node) {
                Variant b = get_child(0);
                set_node(b);
                set_velocity(Vector3(0, 0, 0));
            }
		} break;
	}
}

void Arrow3D::set_node(const Variant &p_node) {
    node = Object::cast_to<Node3D>(p_node);
}

void Arrow3D::set_velocity(const Vector3& v) {
    if (!node) {
        return;
    }

    auto l = v.length();
	if (l <= 0) {
        node->set_visible(false);
		return;
    }
		
    node->set_visible(true);

    auto trans = node->get_transform();
    trans.origin.z = -l * 0.5;

    trans = trans.looking_at(trans.origin + v, Vector3(0, 1, 0));

    // scale z axis
    trans.basis.set_axis(2, trans.basis.get_axis(2) * l);

    node->set_transform(trans);
}