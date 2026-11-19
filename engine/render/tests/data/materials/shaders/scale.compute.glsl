// Test fixture of the compute material kind: one thread per element of the `items` buffer.
void compute(in ComputeInput i) {
    uint k = i.global_id.x;
    items.data[k].value = items.data[k].value * factor;
    items.data[k].pos = items.data[k].pos + offset;
    items.data[k].id = k;
    items.data[k].steps = items.data[k].steps + 1;
}
