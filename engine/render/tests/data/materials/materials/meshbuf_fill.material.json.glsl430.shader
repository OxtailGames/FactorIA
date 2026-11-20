{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "60177e0de1a42674d2e25fce0459f055d4bbaa0faf939ebaf036f3e7d4d67c34",
  "slang": "glsl430",
  "params": [
    "count",
    "hide",
    "spacing"
  ],
  "textures": [],
  "kind": "compute",
  "workgroupSize": [
    64,
    1,
    1
  ],
  "buffers": [
    {
      "name": "points",
      "binding": 0,
      "stride": 32,
      "access": "readWrite",
      "fields": [
        {
          "name": "pos",
          "type": "vec4",
          "offset": 0
        },
        {
          "name": "tint",
          "type": "vec4",
          "offset": 16
        }
      ]
    }
  ],
  "programs": {
    "compute": {
      "cs": "#version 430\nlayout(local_size_x = 64, local_size_y = 1, local_size_z = 1) in;\n\nstruct ComputeInput\n{\n    uvec3 global_id;\n    uvec3 local_id;\n    uvec3 group_id;\n    uint local_index;\n};\n\nstruct points_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nuniform vec4 fa_material[3];\nlayout(binding = 0, std430) buffer fa_points_buf\n{\n    points_item data[];\n} points;\n\nvoid compute(ComputeInput i)\n{\n    float _23 = float(i.global_id.x);\n    if (_23 >= fa_material[0].x)\n    {\n        return;\n    }\n    points.data[i.global_id.x].pos = vec4((_23 - 2.0) * fa_material[2].x, 0.0, 0.0, (_23 == fa_material[1].x) ? 0.0 : 1.0);\n    points.data[i.global_id.x].tint = vec4(1.0, 0.0, 0.0, 1.0);\n}\n\nvoid main()\n{\n    ComputeInput param = ComputeInput(gl_GlobalInvocationID, gl_LocalInvocationID, gl_WorkGroupID, gl_LocalInvocationIndex);\n    compute(param);\n}\n\n",
      "reflection": {
        "compute_func": {
          "entry_point": "main"
        },
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "compute",
            "size": 48,
            "struct_name": "fa_material",
            "inst_name": "_26",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 3,
                "offset": 0,
                "glsl_name": "fa_material"
              }
            ]
          }
        ],
        "views": [
          {
            "storage_buffer": {
              "slot": 0,
              "stage": "compute",
              "size": 32,
              "align": 16,
              "struct_name": "fa_points_buf",
              "inst_name": "points",
              "inner_struct_name": "points_item",
              "readonly": false,
              "glsl_binding_n": 0
            }
          }
        ]
      }
    }
  }
}
