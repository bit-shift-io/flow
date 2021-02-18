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


class BUt : public Reference {
	GDCLASS(BUt, Reference)

	//static Ut *singleton;

protected:

	static void _bind_methods();
           
public:

    BUt();
    ~BUt();

    //static Ut *get_singleton() { return singleton; }
};



#endif // UT_H
