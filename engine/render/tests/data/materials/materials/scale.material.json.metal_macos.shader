{
  "format": "factoria.shader/1",
  "engine": "0.33.0",
  "template": "60177e0de1a42674d2e25fce0459f055d4bbaa0faf939ebaf036f3e7d4d67c34",
  "slang": "metal_macos",
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
      "cs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct ComputeInput\n{\n    uint3 global_id;\n    uint3 local_id;\n    uint3 group_id;\n    uint local_index;\n};\n\nstruct items_item\n{\n    float value;\n    float2 pos;\n    uint id;\n    int steps;\n};\n\nstruct fa_items_buf\n{\n    items_item data[1];\n};\n\nstruct fa_material\n{\n    float factor;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n    float2 offset;\n    float fa_pad3;\n    float fa_pad4;\n};\n\nconstant uint3 gl_WorkGroupSize [[maybe_unused]] = uint3(64u, 1u, 1u);\n\nstatic inline __attribute__((always_inline))\nvoid compute(thread const ComputeInput& i, device fa_items_buf& items, constant fa_material& _35)\n{\n    items.data[i.global_id.x].value *= _35.factor;\n    items.data[i.global_id.x].pos += _35.offset;\n    items.data[i.global_id.x].id = i.global_id.x;\n    items.data[i.global_id.x].steps++;\n}\n\nkernel void main0(constant fa_material& _35 [[buffer(0)]], device fa_items_buf& items [[buffer(8)]], uint3 gl_GlobalInvocationID [[thread_position_in_grid]], uint3 gl_LocalInvocationID [[thread_position_in_threadgroup]], uint3 gl_WorkGroupID [[threadgroup_position_in_grid]], uint gl_LocalInvocationIndex [[thread_index_in_threadgroup]])\n{\n    ComputeInput param = ComputeInput{ gl_GlobalInvocationID, gl_LocalInvocationID, gl_WorkGroupID, gl_LocalInvocationIndex };\n    compute(param, items, _35);\n}\n\n",
      "reflection": {
        "compute_func": {
          "entry_point": "main0"
        },
        "mtl_threads_per_threadgroup": {
          "x": 64,
          "y": 1,
          "z": 1
        },
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "compute",
            "size": 32,
            "struct_name": "fa_material",
            "inst_name": "_35",
            "msl_buffer_n": 0
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
              "msl_buffer_n": 8
            }
          }
        ]
      }
    }
  }
}
