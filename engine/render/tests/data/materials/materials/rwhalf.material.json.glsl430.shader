{
  "format": "factoria.shader/1",
  "engine": "0.31.0",
  "template": "60177e0de1a42674d2e25fce0459f055d4bbaa0faf939ebaf036f3e7d4d67c34",
  "slang": "glsl430",
  "params": [],
  "textures": [],
  "kind": "compute",
  "workgroupSize": [
    8,
    8,
    1
  ],
  "buffers": [],
  "images": [
    {
      "name": "acc",
      "binding": 0,
      "format": "rgba16f",
      "access": "readWrite",
      "width": 8,
      "height": 8
    }
  ],
  "programs": {
    "compute": {
      "cs": "#version 430\nlayout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;\n\nstruct ComputeInput\n{\n    uvec3 global_id;\n    uvec3 local_id;\n    uvec3 group_id;\n    uint local_index;\n};\n\nlayout(binding = 0, rgba16f) uniform image2D acc;\n\nvoid compute(ComputeInput i)\n{\n    ivec2 _24 = ivec2(i.global_id.xy);\n    ivec2 _31 = imageSize(acc);\n    bool _39 = _24.x >= _31.x;\n    bool _49;\n    if (!_39)\n    {\n        _49 = _24.y >= _31.y;\n    }\n    else\n    {\n        _49 = _39;\n    }\n    if (_49)\n    {\n        return;\n    }\n    imageStore(acc, _24, imageLoad(acc, _24) + vec4(0.5, 1.0, 2.0, 3.0));\n}\n\nvoid main()\n{\n    ComputeInput param = ComputeInput(gl_GlobalInvocationID, gl_LocalInvocationID, gl_WorkGroupID, gl_LocalInvocationIndex);\n    compute(param);\n}\n\n",
      "reflection": {
        "compute_func": {
          "entry_point": "main"
        },
        "views": [
          {
            "storage_image": {
              "slot": 0,
              "stage": "compute",
              "name": "acc",
              "type": "2d",
              "access_format": "RGBA16F",
              "writeonly": false,
              "glsl_binding_n": 0
            }
          }
        ]
      }
    }
  }
}
