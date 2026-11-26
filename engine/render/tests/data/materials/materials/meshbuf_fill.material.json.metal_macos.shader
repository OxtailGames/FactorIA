{
  "format": "factoria.shader/1",
  "engine": "0.38.0",
  "template": "60177e0de1a42674d2e25fce0459f055d4bbaa0faf939ebaf036f3e7d4d67c34",
  "slang": "metal_macos",
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
      "cs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct ComputeInput\n{\n    uint3 global_id;\n    uint3 local_id;\n    uint3 group_id;\n    uint local_index;\n};\n\nstruct fa_material\n{\n    float count;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n    float hide;\n    float fa_pad3;\n    float fa_pad4;\n    float fa_pad5;\n    float spacing;\n    float fa_pad6;\n    float fa_pad7;\n    float fa_pad8;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nstruct fa_points_buf\n{\n    points_item data[1];\n};\n\nconstant uint3 gl_WorkGroupSize [[maybe_unused]] = uint3(64u, 1u, 1u);\n\nstatic inline __attribute__((always_inline))\nvoid compute(thread const ComputeInput& i, constant fa_material& _26, device fa_points_buf& points)\n{\n    float _23 = float(i.global_id.x);\n    if (_23 >= _26.count)\n    {\n        return;\n    }\n    points.data[i.global_id.x].pos = float4((_23 - 2.0) * _26.spacing, 0.0, 0.0, (_23 == _26.hide) ? 0.0 : 1.0);\n    points.data[i.global_id.x].tint = float4(1.0, 0.0, 0.0, 1.0);\n}\n\nkernel void main0(constant fa_material& _26 [[buffer(0)]], device fa_points_buf& points [[buffer(8)]], uint3 gl_GlobalInvocationID [[thread_position_in_grid]], uint3 gl_LocalInvocationID [[thread_position_in_threadgroup]], uint3 gl_WorkGroupID [[threadgroup_position_in_grid]], uint gl_LocalInvocationIndex [[thread_index_in_threadgroup]])\n{\n    ComputeInput param = ComputeInput{ gl_GlobalInvocationID, gl_LocalInvocationID, gl_WorkGroupID, gl_LocalInvocationIndex };\n    compute(param, _26, points);\n}\n\n",
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
            "size": 48,
            "struct_name": "fa_material",
            "inst_name": "_26",
            "msl_buffer_n": 0
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
              "msl_buffer_n": 8
            }
          }
        ]
      }
    }
  }
}
