// World::index_bound: the size of a table indexed by Entity::index.
#include <doctest.h>

#include <vector>

#include "fa/scene/world.h"

using namespace fa;

TEST_CASE("World::index_bound counts the highest index ever allocated, freed ones included") {
    World w;
    CHECK(w.index_bound() == 0);
    std::vector<Entity> es;
    for (int i = 0; i < 5; ++i) es.push_back(w.create("e"));
    CHECK(w.index_bound() == 5);
    w.destroy_immediate(es[1]);
    w.destroy_immediate(es[4]);
    CHECK(w.index_bound() == 5);
    for (int i = 0; i < 2; ++i) w.create("again");  // reuse the freed indices
    CHECK(w.index_bound() == 5);
    w.create("past the old maximum");
    CHECK(w.index_bound() == 6);
}
