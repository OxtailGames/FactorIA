void vertex(inout VertexData v) {
    v.color = vertex_color1;
    v.uv = vertex_uv1;
}

void surface(in SurfaceInput i, inout Surface s) {
    s.emission += i.vertex_color.rgb * (i.uv.x * 2.0);
}
