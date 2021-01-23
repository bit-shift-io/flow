#include "globals.h"
#include "register_types.h"
#include "core/variant/variant.h"
#include "core/object/reference.h"
#include "core/config/engine.h"

static Vector<Variant> singletons;

template<class T>
void instance_singleton(const char* p_singleton_name = NULL) {
    ClassDB::register_class<T>();

    Ref<T> ref;
    ref.instance();
    singletons.push_back(ref);

    if (p_singleton_name) {
        Engine::get_singleton()->add_singleton(Engine::Singleton(p_singleton_name, ref.ptr()));
    }
}

void free_singletons() {
    singletons.clear();
}

void register_bitshift_types() {
    //ClassDB::register_class<BIRC>();
    //instance_singleton<BUtil>("BUtil");
}

void unregister_bitshift_types() {
    free_singletons();
}
