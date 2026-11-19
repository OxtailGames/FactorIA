{
  "format": "factoria.shader/1",
  "engine": "0.31.0",
  "template": "60177e0de1a42674d2e25fce0459f055d4bbaa0faf939ebaf036f3e7d4d67c34",
  "slang": "metal_macos",
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
      "cs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\ntemplate <typename ImageT>\nvoid spvImageFence(ImageT img) { img.fence(); }\n\nstruct ComputeInput\n{\n    uint3 global_id;\n    uint3 local_id;\n    uint3 group_id;\n    uint local_index;\n};\n\nconstant uint3 gl_WorkGroupSize [[maybe_unused]] = uint3(8u, 8u, 1u);\n\nstatic inline __attribute__((always_inline))\nvoid compute(thread const ComputeInput& i, texture2d<float, access::read_write> acc)\n{\n    int2 _24 = int2(i.global_id.xy);\n    int2 _31 = int2(acc.get_width(), acc.get_height());\n    bool _39 = _24.x >= _31.x;\n    bool _49;\n    if (!_39)\n    {\n        _49 = _24.y >= _31.y;\n    }\n    else\n    {\n        _49 = _39;\n    }\n    if (_49)\n    {\n        return;\n    }\n    spvImageFence(acc);\n    acc.write(acc.read(uint2(_24)) + float4(0.5, 1.0, 2.0, 3.0), uint2(_24));\n}\n\nkernel void main0(texture2d<float, access::read_write> acc [[texture(0)]], uint3 gl_GlobalInvocationID [[thread_position_in_grid]], uint3 gl_LocalInvocationID [[thread_position_in_threadgroup]], uint3 gl_WorkGroupID [[threadgroup_position_in_grid]], uint gl_LocalInvocationIndex [[thread_index_in_threadgroup]])\n{\n    ComputeInput param = ComputeInput{ gl_GlobalInvocationID, gl_LocalInvocationID, gl_WorkGroupID, gl_LocalInvocationIndex };\n    compute(param, acc);\n}\n\n",
      "reflection": {
        "compute_func": {
          "entry_point": "main0"
        },
        "mtl_threads_per_threadgroup": {
          "x": 8,
          "y": 8,
          "z": 1
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
              "msl_texture_n": 0
            }
          }
        ]
      }
    }
  }
}
