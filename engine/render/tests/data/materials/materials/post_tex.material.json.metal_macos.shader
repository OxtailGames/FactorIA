{
  "format": "factoria.shader/1",
  "engine": "0.31.0",
  "template": "d03c1c7f934d4bdc20c513c6cb4bc09d11d7167b51a10ca9dcb59b504997591f",
  "slang": "metal_macos",
  "params": [
    "amount"
  ],
  "textures": [
    "mask"
  ],
  "kind": "post",
  "programs": {
    "post": {
      "vs": "#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct fa_post_vs_params\n{\n    float4 fa_flip;\n};\n\nstruct main0_out\n{\n    float2 fa_uv [[user(locn0)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float2 pos [[attribute(0)]];\n};\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_post_vs_params& _51 [[buffer(0)]])\n{\n    main0_out out = {};\n    out.gl_Position = float4(in.pos, 0.0, 1.0);\n    float _33 = in.pos.y * 0.5;\n    out.fa_uv = float2((in.pos.x * 0.5) + 0.5, mix(0.5 - _33, 0.5 + _33, _51.fa_flip.x));\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct PostInput\n{\n    float2 uv;\n    float2 texel;\n    float2 size;\n    float time;\n};\n\nstruct PostSurface\n{\n    float4 color;\n};\n\nstruct fa_post_params\n{\n    float4 fa_a;\n    float4 fa_rc;\n    float4 fa_size;\n    float4 fa_time;\n};\n\nstruct fa_material\n{\n    float amount;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float2 fa_uv [[user(locn0)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_flip_uv(thread const float2& s, constant fa_post_params& _45)\n{\n    return float2(s.x, mix(s.y, 1.0 - s.y, _45.fa_a.x));\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_scene_color(thread const float2& uv, constant fa_post_params& _45, texture2d<float> fa_scene, sampler fa_scene_smp)\n{\n    float2 param = (fast::clamp(uv, float2(0.0), float2(1.0)) * _45.fa_rc.zw) + _45.fa_rc.xy;\n    return fa_scene.sample(fa_scene_smp, fa_flip_uv(param, _45), level(0.0));\n}\n\nstatic inline __attribute__((always_inline))\nvoid post(thread const PostInput& i, thread PostSurface& s, constant fa_post_params& _45, texture2d<float> fa_scene, sampler fa_scene_smp, texture2d<float> mask, sampler mask_smp, constant fa_material& _123)\n{\n    float2 param = i.uv;\n    float3 _127 = mix(fa_scene_color(param, _45, fa_scene, fa_scene_smp).xyz, mask.sample(mask_smp, float2(0.0500000007450580596923828125)).xyz, float3(_123.amount));\n    s.color.x = _127.x;\n    s.color.y = _127.y;\n    s.color.z = _127.z;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_sane(thread const float& x)\n{\n    if (((as_type<uint>(x) >> 23u) & 255u) == 255u)\n    {\n        return 0.0;\n    }\n    return fast::clamp(x, 0.0, 65504.0);\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_post_params& _45 [[buffer(1)]], constant fa_material& _123 [[buffer(5)]], texture2d<float> fa_scene [[texture(0)]], texture2d<float> mask [[texture(1)]], sampler fa_scene_smp [[sampler(0)]], sampler mask_smp [[sampler(2)]])\n{\n    main0_out out = {};\n    float2 param = in.fa_uv;\n    float2 _140 = fa_flip_uv(param, _45);\n    float2 param_1 = _140;\n    float4 _160 = fa_scene_color(param_1, _45, fa_scene, fa_scene_smp);\n    float4 _212 = _160;\n    PostInput param_2 = PostInput{ _140, _45.fa_size.zw, _45.fa_size.xy, _45.fa_time.x };\n    PostSurface param_3 = PostSurface{ _160 };\n    post(param_2, param_3, _45, fa_scene, fa_scene_smp, mask, mask_smp, _123);\n    _212 = param_3.color;\n    float _177;\n    if (((as_type<uint>(param_3.color.w) >> 23u) & 255u) == 255u)\n    {\n        _177 = 1.0;\n    }\n    else\n    {\n        _177 = fast::clamp(_212.w, 0.0, 1.0);\n    }\n    float param_4 = _212.x;\n    float param_5 = _212.y;\n    float param_6 = _212.z;\n    out.fa_frag_color = float4(fa_sane(param_4), fa_sane(param_5), fa_sane(param_6), _177);\n    return out;\n}\n\n",
      "reflection": {
        "vertex_func": {
          "entry_point": "main0"
        },
        "fragment_func": {
          "entry_point": "main0"
        },
        "attrs": [
          {
            "slot": 0,
            "type": "vec2",
            "base_type": "Float"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 16,
            "struct_name": "fa_post_vs_params",
            "inst_name": "_51",
            "msl_buffer_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 64,
            "struct_name": "fa_post_params",
            "inst_name": "_45",
            "msl_buffer_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_123",
            "msl_buffer_n": 5
          }
        ],
        "views": [
          {
            "texture": {
              "slot": 0,
              "stage": "fragment",
              "name": "fa_scene",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 0
            }
          },
          {
            "texture": {
              "slot": 2,
              "stage": "fragment",
              "name": "mask",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 1
            }
          }
        ],
        "samplers": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_scene_smp",
            "sampler_type": "filtering",
            "msl_sampler_n": 0
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "mask_smp",
            "sampler_type": "filtering",
            "msl_sampler_n": 2
          }
        ],
        "texture_sampler_pairs": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_scene_fa_scene_smp",
            "view_name": "fa_scene",
            "sampler_name": "fa_scene_smp",
            "view_slot": 0,
            "sampler_slot": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "mask_mask_smp",
            "view_name": "mask",
            "sampler_name": "mask_smp",
            "view_slot": 2,
            "sampler_slot": 2
          }
        ]
      }
    }
  }
}
