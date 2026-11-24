void vertex(inout VertexData v) {
    v.world_pos.x += fa_time.x * speed;
}

void surface(in SurfaceInput i, inout Surface s) {}
