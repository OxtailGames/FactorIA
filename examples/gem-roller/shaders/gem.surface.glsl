// Pulsing emission: fa_time.x is the game time in seconds (the same on every machine, so replays match).
void surface(in SurfaceInput i, inout Surface s) {
    float pulse = 0.5 + 0.5 * sin(fa_time.x * speed);
    s.emission += glow.rgb * glow.a * (0.3 + 0.7 * pulse);
}
