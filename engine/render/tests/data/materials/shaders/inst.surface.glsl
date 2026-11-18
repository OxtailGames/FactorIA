void vertex(inout VertexData v) {
    v.world_pos.y += raise;
}

void surface(in SurfaceInput i, inout Surface s) {
    s.emission += tint.rgb * tint.a * boost;
}
