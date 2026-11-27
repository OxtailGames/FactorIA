{
  "format": "factoria.shader/1",
  "engine": "0.39.0",
  "template": "1e9e617cc134cb3e70426cfbd8094c431d927c55e7a97a62ce35324a67af73d5",
  "slang": "metal_macos",
  "params": [],
  "textures": [],
  "kind": "post",
  "programs": {
    "post": {
      "vs": "#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct fa_post_vs_params\n{\n    float4 fa_flip;\n};\n\nstruct main0_out\n{\n    float2 fa_uv [[user(locn0)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float2 pos [[attribute(0)]];\n};\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_post_vs_params& _51 [[buffer(0)]])\n{\n    main0_out out = {};\n    out.gl_Position = float4(in.pos, 0.0, 1.0);\n    float _33 = in.pos.y * 0.5;\n    out.fa_uv = float2((in.pos.x * 0.5) + 0.5, mix(0.5 - _33, 0.5 + _33, _51.fa_flip.x));\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct PostInput\n{\n    float2 uv;\n    float2 texel;\n    float2 size;\n    float time;\n};\n\nstruct PostSurface\n{\n    float4 color;\n};\n\nstruct fa_post_params\n{\n    float4 fa_a;\n    float4 fa_rc;\n    float4 fa_size;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float2 fa_uv [[user(locn0)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_flip_uv(thread const float2& s, constant fa_post_params& _45)\n{\n    return float2(s.x, mix(s.y, 1.0 - s.y, _45.fa_a.x));\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_scene_color(thread const float2& uv, constant fa_post_params& _45, texture2d<float> fa_scene, sampler fa_scene_smp)\n{\n    float2 _62 = _45.fa_size.zw * 0.5;\n    float2 param = (fast::clamp(uv, _62, float2(1.0) - _62) * _45.fa_rc.zw) + _45.fa_rc.xy;\n    return fa_scene.sample(fa_scene_smp, fa_flip_uv(param, _45), level(0.0));\n}\n\nstatic inline __attribute__((always_inline))\nvoid post(thread const PostInput& i, thread PostSurface& s)\n{\n    s.color.x = i.uv.x;\n    s.color.y = i.uv.y;\n    s.color.z = fast::clamp(i.time * 0.25, 0.0, 1.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_sane(thread const float& x)\n{\n    if (((as_type<uint>(x) >> 23u) & 255u) == 255u)\n    {\n        return 0.0;\n    }\n    return fast::clamp(x, 0.0, 65504.0);\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_post_params& _45 [[buffer(1)]], texture2d<float> fa_scene [[texture(0)]], sampler fa_scene_smp [[sampler(0)]])\n{\n    main0_out out = {};\n    float2 param = in.fa_uv;\n    float2 _136 = fa_flip_uv(param, _45);\n    float2 param_1 = _136;\n    float4 _154 = fa_scene_color(param_1, _45, fa_scene, fa_scene_smp);\n    float4 _207 = _154;\n    PostInput param_2 = PostInput{ _136, _45.fa_size.zw, _45.fa_size.xy, _45.fa_time.x };\n    PostSurface param_3 = PostSurface{ _154 };\n    post(param_2, param_3);\n    _207 = param_3.color;\n    float _171;\n    if (((as_type<uint>(param_3.color.w) >> 23u) & 255u) == 255u)\n    {\n        _171 = 1.0;\n    }\n    else\n    {\n        _171 = fast::clamp(_207.w, 0.0, 1.0);\n    }\n    float param_4 = _207.x;\n    float param_5 = _207.y;\n    float param_6 = _207.z;\n    out.fa_frag_color = float4(fa_sane(param_4), fa_sane(param_5), fa_sane(param_6), _171);\n    return out;\n}\n\n",
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
          }
        ],
        "samplers": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_scene_smp",
            "sampler_type": "filtering",
            "msl_sampler_n": 0
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
          }
        ]
      }
    }
  }
}
