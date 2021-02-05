#ifndef UT_H
#define UT_H

#include "scene/main/node.h"
#include "core/os/dir_access.h"

class FuncRef;
class BTerrain;
class BWater;
class ArrayMesh;
class CanvasItem;
class Node3D;
class TextureButton;
class BBoundaryMap;
class Timer;
class SceneTree;
class RichTextLabel;
class Camera3D;
class MeshInstance3D;


class Ut : public Reference {
	GDCLASS(Ut,Reference)

	static Ut *singleton;

protected:

	static void _bind_methods();
           
public:

    Ut();
    ~Ut();

    static Ut *get_singleton() { return singleton; }

    // temporary work around for this issue: https://github.com/godotengine/godot/issues/44812#issuecomment-770315447
    float packed_array_get(const PackedFloat32Array& u, float index);
};



#endif // UT_H
