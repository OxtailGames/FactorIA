{
  "format": "factoria.shader/1",
  "engine": "0.39.0",
  "template": "60177e0de1a42674d2e25fce0459f055d4bbaa0faf939ebaf036f3e7d4d67c34",
  "slang": "glsl430",
  "params": [
    "factor",
    "offset"
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
      "name": "items",
      "binding": 0,
      "stride": 24,
      "access": "readWrite",
      "fields": [
        {
          "name": "value",
          "type": "float",
          "offset": 0
        },
        {
          "name": "pos",
          "type": "vec2",
          "offset": 8
        },
        {
          "name": "id",
          "type": "uint",
          "offset": 16
        },
        {
          "name": "steps",
          "type": "int",
          "offset": 20
        }
      ]
    }
  ],
  "programs": {
    "compute": {
      "cs": "#version 430\nlayout(local_size_x = 64, local_size_y = 1, local_size_z = 1) in;\n\nstruct ComputeInput\n{\n    uvec3 global_id;\n    uvec3 local_id;\n    uvec3 group_id;\n    uint local_index;\n};\n\nstruct items_item\n{\n    float value;\n    vec2 pos;\n    uint id;\n    int steps;\n};\n\nlayout(binding = 0, std430) buffer fa_items_buf\n{\n    items_item data[];\n} items;\n\nuniform vec4 fa_material[2];\nvoid compute(ComputeInput i)\n{\n    items.data[i.global_id.x].value *= fa_material[0].x;\n    items.data[i.global_id.x].pos += fa_material[1].xy;\n    items.data[i.global_id.x].id = i.global_id.x;\n    items.data[i.global_id.x].steps++;\n}\n\nvoid main()\n{\n    ComputeInput param = ComputeInput(gl_GlobalInvocationID, gl_LocalInvocationID, gl_WorkGroupID, gl_LocalInvocationIndex);\n    compute(param);\n}\n\n",
      "reflection": {
        "compute_func": {
          "entry_point": "main"
        },
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "compute",
            "size": 32,
            "struct_name": "fa_material",
            "inst_name": "_35",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 2,
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
              "size": 24,
              "align": 8,
              "struct_name": "fa_items_buf",
              "inst_name": "items",
              "inner_struct_name": "items_item",
              "readonly": false,
              "glsl_binding_n": 0
            }
          }
        ]
      }
    }
  }
}
