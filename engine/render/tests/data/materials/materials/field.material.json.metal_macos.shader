{
  "format": "factoria.shader/1",
  "engine": "0.39.0",
  "template": "60177e0de1a42674d2e25fce0459f055d4bbaa0faf939ebaf036f3e7d4d67c34",
  "slang": "metal_macos",
  "params": [
    "blue"
  ],
  "textures": [
    "src"
  ],
  "kind": "compute",
  "workgroupSize": [
    8,
    8,
    1
  ],
  "buffers": [],
  "images": [
    {
      "name": "count",
      "binding": 0,
      "format": "r32f",
      "access": "readWrite",
      "width": 16,
      "height": 16
    },
    {
      "name": "field",
      "binding": 1,
      "format": "rgba8",
      "access": "write",
      "width": 16,
      "height": 16
    }
  ],
  "programs": {
    "compute": {
      "cs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\ntemplate <typename ImageT>\nvoid spvImageFence(ImageT img) { img.fence(); }\n\nstruct ComputeInput\n{\n    uint3 global_id;\n    uint3 local_id;\n    uint3 group_id;\n    uint local_index;\n};\n\nstruct fa_material\n{\n    float blue;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n};\n\nconstant uint3 gl_WorkGroupSize [[maybe_unused]] = uint3(8u, 8u, 1u);\n\nstatic inline __attribute__((always_inline))\nvoid compute(thread const ComputeInput& i, texture2d<float, access::write> field, texture2d<float> src, sampler src_smp, constant fa_material& _89, texture2d<float, access::read_write> count)\n{\n    int2 _24 = int2(i.global_id.xy);\n    int2 _31 = int2(field.get_width(), field.get_height());\n    int _36 = _24.x;\n    bool _39 = _36 >= _31.x;\n    bool _49;\n    if (!_39)\n    {\n        _49 = _24.y >= _31.y;\n    }\n    else\n    {\n        _49 = _39;\n    }\n    if (_49)\n    {\n        return;\n    }\n    field.write(float4(float(_36 * 16) * 0.0039215688593685626983642578125, float(_24.y * 16) * 0.0039215688593685626983642578125, _89.blue * src.sample(src_smp, float2(0.5), level(0.0)).w, 1.0), uint2(_24));\n    spvImageFence(count);\n    count.write(float4(count.read(uint2(_24)).x + 1.0, 0.0, 0.0, 0.0), uint2(_24));\n}\n\nkernel void main0(constant fa_material& _89 [[buffer(0)]], texture2d<float, access::read_write> count [[texture(0)]], texture2d<float, access::write> field [[texture(1)]], texture2d<float> src [[texture(2)]], sampler src_smp [[sampler(0)]], uint3 gl_GlobalInvocationID [[thread_position_in_grid]], uint3 gl_LocalInvocationID [[thread_position_in_threadgroup]], uint3 gl_WorkGroupID [[threadgroup_position_in_grid]], uint gl_LocalInvocationIndex [[thread_index_in_threadgroup]])\n{\n    ComputeInput param = ComputeInput{ gl_GlobalInvocationID, gl_LocalInvocationID, gl_WorkGroupID, gl_LocalInvocationIndex };\n    compute(param, field, src, src_smp, _89, count);\n}\n\n",
      "reflection": {
        "compute_func": {
          "entry_point": "main0"
        },
        "mtl_threads_per_threadgroup": {
          "x": 8,
          "y": 8,
          "z": 1
        },
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "compute",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_89",
            "msl_buffer_n": 0
          }
        ],
        "views": [
          {
            "storage_image": {
              "slot": 0,
              "stage": "compute",
              "name": "count",
              "type": "2d",
              "access_format": "R32F",
              "writeonly": false,
              "msl_texture_n": 0
            }
          },
          {
            "storage_image": {
              "slot": 1,
              "stage": "compute",
              "name": "field",
              "type": "2d",
              "access_format": "RGBA8",
              "writeonly": true,
              "msl_texture_n": 1
            }
          },
          {
            "texture": {
              "slot": 2,
              "stage": "compute",
              "name": "src",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 2
            }
          }
        ],
        "samplers": [
          {
            "slot": 0,
            "stage": "compute",
            "name": "src_smp",
            "sampler_type": "filtering",
            "msl_sampler_n": 0
          }
        ],
        "texture_sampler_pairs": [
          {
            "slot": 0,
            "stage": "compute",
            "name": "src_src_smp",
            "view_name": "src",
            "sampler_name": "src_smp",
            "view_slot": 2,
            "sampler_slot": 0
          }
        ]
      }
    }
  }
}
