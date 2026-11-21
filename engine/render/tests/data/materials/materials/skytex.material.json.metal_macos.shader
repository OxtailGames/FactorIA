{
  "format": "factoria.shader/1",
  "engine": "0.33.0",
  "template": "3e2ab04520b9dfea7aed47b5f8c67dace661b6200fc615b2b53570e4e4b3c03a",
  "slang": "metal_macos",
  "params": [],
  "textures": [
    "map"
  ],
  "kind": "sky",
  "programs": {
    "sky": {
      "vs": "#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct sky_vs_params\n{\n    float4x4 inv_view_proj;\n    float4 cam_pos;\n};\n\nstruct main0_out\n{\n    float3 ray_dir [[user(locn0)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float2 pos [[attribute(0)]];\n};\n\nvertex main0_out main0(main0_in in [[stage_in]], constant sky_vs_params& _31 [[buffer(0)]])\n{\n    main0_out out = {};\n    float4 _23 = float4(in.pos, 1.0, 1.0);\n    out.gl_Position = _23;\n    float4 _39 = _31.inv_view_proj * _23;\n    out.ray_dir = (_39.xyz / float3(_39.w)) - _31.cam_pos.xyz;\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct SkyInput\n{\n    float3 dir;\n    float3 sun_dir;\n    float time;\n};\n\nstruct SkySurface\n{\n    float3 color;\n};\n\nstruct sky_fs_params\n{\n    float4 sky_color;\n    float4 horizon_color;\n    float4 fa_sun;\n    float4 fa_time;\n    float4 fa_cspace;\n};\n\nstruct main0_out\n{\n    float4 frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 ray_dir [[user(locn0)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid sky(thread const SkyInput& i, thread SkySurface& s, texture2d<float> map, sampler map_smp)\n{\n    s.color = map.sample(map_smp, ((i.dir.xz * 0.5) + float2(0.5))).xyz;\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant sky_fs_params& _66 [[buffer(1)]], texture2d<float> map [[texture(0)]], sampler map_smp [[sampler(0)]])\n{\n    main0_out out = {};\n    float3 _46 = fast::normalize(in.ray_dir);\n    SkyInput param = SkyInput{ _46, _66.fa_sun.xyz, _66.fa_time.x };\n    SkySurface param_1 = SkySurface{ mix(_66.horizon_color.xyz, _66.sky_color.xyz, float3(powr(fast::clamp(_46.y, 0.0, 1.0), 0.550000011920928955078125))) };\n    sky(param, param_1, map, map_smp);\n    out.frag_color = float4(param_1.color, 1.0);\n    return out;\n}\n\n",
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
            "size": 80,
            "struct_name": "sky_vs_params",
            "inst_name": "_31",
            "msl_buffer_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 80,
            "struct_name": "sky_fs_params",
            "inst_name": "_66",
            "msl_buffer_n": 1
          }
        ],
        "views": [
          {
            "texture": {
              "slot": 0,
              "stage": "fragment",
              "name": "map",
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
            "name": "map_smp",
            "sampler_type": "filtering",
            "msl_sampler_n": 0
          }
        ],
        "texture_sampler_pairs": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "map_map_smp",
            "view_name": "map",
            "sampler_name": "map_smp",
            "view_slot": 0,
            "sampler_slot": 0
          }
        ]
      }
    }
  }
}
