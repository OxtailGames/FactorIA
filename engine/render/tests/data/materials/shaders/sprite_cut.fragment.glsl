void fragment(in QuadInput i, inout QuadSurface s) {
    if (i.screen_uv.x < cut || i.screen_uv.y < cutY) discard;
}
