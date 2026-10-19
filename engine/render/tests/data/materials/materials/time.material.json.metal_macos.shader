{
  "format": "factoria.shader/1",
  "engine": "0.1.6",
  "template": "c92b9f1a26adc9a735edf9d88d24268eb2cae4ffeaa00748a36617e70a4776c1",
  "slang": "metal_macos",
  "params": [],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_shadow_pos [[user(locn4)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_inst_m0 [[attribute(4)]];\n    float4 fa_inst_m1 [[attribute(5)]];\n    float4 fa_inst_m2 [[attribute(6)]];\n    float4 fa_inst_m3 [[attribute(7)]];\n};\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, constant fa_mesh_vs_params& _127)\n{\n    float3 _65 = cross(model[1].xyz, model[2].xyz);\n    float _71 = (dot(model[0].xyz, _65) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_65 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _71, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _71), texcoord0 * _127.fa_uv_scale.xy, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, constant fa_mesh_vs_params& _127, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_shadow_pos, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    VertexData _151 = fa_vertex_data(param, param_1, param_2, param_3, param_4, _127);\n    float3 _251 = _151.world_pos;\n    float4 _158 = float4(_251, 1.0);\n    fa_world_pos = _251;\n    fa_world_normal = _151.world_normal;\n    fa_world_tangent = _151.world_tangent;\n    fa_uv = _151.uv;\n    fa_shadow_pos = _127.fa_light_vp * _158;\n    gl_Position = _127.fa_view_proj * _158;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _127 [[buffer(0)]])\n{\n    main0_out out = {};\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, _127, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_shadow_pos, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n};\n\nstruct fa_lights\n{\n    float4 fa_light_pos[32];\n    float4 fa_light_color[32];\n    float4 fa_light_dir[32];\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_shadow_pos [[user(locn4)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _52;\n    if (bool(i.front_facing))\n    {\n        _52 = i.world_normal;\n    }\n    else\n    {\n        _52 = -i.world_normal;\n    }\n    float3 _77 = fast::normalize(i.world_tangent.xyz - (_52 * dot(_52, i.world_tangent.xyz)));\n    float3 _105 = fast::normalize(((_77 * m.x) + ((cross(_52, _77) * i.world_tangent.w) * m.y)) + (_52 * m.z));\n    float3 _108;\n    if (bool(i.front_facing))\n    {\n        _108 = _105;\n    }\n    else\n    {\n        _108 = -_105;\n    }\n    return _108;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _122, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 _158 = fa_tex.sample(fa_smp, i.uv);\n    float4 _162 = _158 * _122.fa_base_color;\n    float3 _959 = i.world_normal;\n    if (_122.fa_maps.z > 0.5)\n    {\n        float3 _192 = (fa_normal_tex.sample(fa_smp, i.uv).xyz * 2.0) - float3(1.0);\n        float2 _197 = _192.xy * _122.fa_maps.x;\n        float3 _976 = _192;\n        _976.x = _197.x;\n        _976.y = _197.y;\n        SurfaceInput param = i;\n        float3 param_1 = _976;\n        _959 = fa_tangent_normal(param, param_1);\n    }\n    float4 _215 = fa_mr_tex.sample(fa_smp, i.uv);\n    return Surface{ _162.xyz, _162.w, _959, fast::clamp(_122.fa_pbr.x * _215.z, 0.0, 1.0), fast::clamp(_122.fa_pbr.y * _215.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_122.fa_maps.y * (fa_occlusion_tex.sample(fa_smp, i.uv).x - 1.0)), _122.fa_emissive.xyz + (_122.fa_model_emissive.xyz * fa_emissive_tex.sample(fa_smp, i.uv).xyz) };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread Surface& s, constant fa_mesh_fs_params& _122)\n{\n    s.emission += float3(0.5 + (0.5 * sin(_122.fa_time.x * 3.0)), 0.25 * fract(_122.fa_time.x), 0.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _122, thread float4& fa_shadow_pos, texture2d<float> fa_shadow_tex, sampler fa_shadow_smp)\n{\n    if (_122.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    float3 _281 = fa_shadow_pos.xyz / float3(fa_shadow_pos.w);\n    float3 p = _281;\n    float2 suv = (_281.xy * 0.5) + float2(0.5);\n    if (_122.fa_counts.z > 0.5)\n    {\n        float3 _981 = p;\n        _981.z = (_981.z * 0.5) + 0.5;\n        p = _981;\n    }\n    else\n    {\n        float2 _984 = suv;\n        _984.y = 1.0 - _984.y;\n        suv = _984;\n    }\n    bool _308 = suv.x < 0.0;\n    bool _315;\n    if (!_308)\n    {\n        _315 = suv.x > 1.0;\n    }\n    else\n    {\n        _315 = _308;\n    }\n    bool _322;\n    if (!_315)\n    {\n        _322 = suv.y < 0.0;\n    }\n    else\n    {\n        _322 = _315;\n    }\n    bool _329;\n    if (!_322)\n    {\n        _329 = suv.y > 1.0;\n    }\n    else\n    {\n        _329 = _322;\n    }\n    bool _336;\n    if (!_329)\n    {\n        _336 = p.z > 1.0;\n    }\n    else\n    {\n        _336 = _329;\n    }\n    if (_336)\n    {\n        return 1.0;\n    }\n    float _350 = _122.fa_pbr.w * (1.0 + (2.0 * (1.0 - fast::clamp(dot(n, l), 0.0, 1.0))));\n    float lit = 0.0;\n    for (int ix = -1; ix <= 1; ix++)\n    {\n        for (int iy = -1; iy <= 1; iy++)\n        {\n            lit += float((p.z - _350) <= fa_shadow_tex.sample(fa_shadow_smp, (suv + (float2(float(ix), float(iy)) * _122.fa_counts.y)), level(0.0)).x);\n        }\n    }\n    return lit * 0.111111111938953399658203125;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_env_brdf(thread const float& rough, thread const float& ndv)\n{\n    float4 _491 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _494 = _491.x;\n    return (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_494 * _494, exp2((-9.27999973297119140625) * ndv)) * _494) + _491.y)) + _491.zw;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_environment(thread const float3& d, thread const float& rough, constant fa_mesh_fs_params& _122)\n{\n    float _411 = rough * rough;\n    float _444 = 0.60000002384185791015625 * _411;\n    return mix(mix(_122.fa_env_horizon.xyz * 0.550000011920928955078125, mix(_122.fa_env_horizon.xyz, _122.fa_env_sky.xyz, float3(powr(fast::clamp(d.y * (1.0 - (0.699999988079071044921875 * _411)), 0.0, 1.0), 0.550000011920928955078125))), float3(smoothstep((-0.0500000007450580596923828125) - _444, 0.0500000007450580596923828125 + _444, d.y))), ((_122.fa_env_sky.xyz + _122.fa_env_horizon.xyz) * 0.5) * 0.800000011920928955078125, float3(_411 * 0.60000002384185791015625));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _122 [[buffer(1)]], constant fa_lights& _654 [[buffer(2)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    float3 _909 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _909 = -_909;\n    }\n    float3 _551 = _122.fa_camera_pos.xyz - in.fa_world_pos;\n    float3 _552 = fast::normalize(_551);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _909, in.fa_world_tangent, in.fa_uv, _552, short(gl_FrontFacing) };\n    Surface _557 = fa_standard_surface(param, _122, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _928 = _557.albedo;\n    float _929 = _557.alpha;\n    float3 _930 = _557.normal;\n    float _931 = _557.metallic;\n    float _932 = _557.roughness;\n    float _933 = _557.occlusion;\n    float3 _934 = _557.emission;\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _909, in.fa_world_tangent, in.fa_uv, _552, short(gl_FrontFacing) };\n    Surface param_2 = _557;\n    surface(param_1, param_2, _122);\n    _928 = param_2.albedo;\n    _929 = param_2.alpha;\n    _930 = param_2.normal;\n    _931 = param_2.metallic;\n    _932 = param_2.roughness;\n    _933 = param_2.occlusion;\n    _934 = param_2.emission;\n    float3 result;\n    if (_122.fa_emissive.w > 0.5)\n    {\n        result = _928;\n    }\n    else\n    {\n        float3 _579 = fast::normalize(_930);\n        float _586 = fast::clamp(_931, 0.0, 1.0);\n        float _590 = fast::clamp(_932, 0.0500000007450580596923828125, 1.0);\n        float _594 = _590 * _590;\n        float _598 = _594 * _594;\n        float _604 = fast::max(dot(_579, _552), 9.9999997473787516355514526367188e-05);\n        float3 _610 = _928 * (1.0 - _586);\n        float3 _618 = mix(float3(0.039999999105930328369140625), _928, float3(_586));\n        float3 lit = (_122.fa_ambient.xyz * _610) * _933;\n        int _631 = int(_122.fa_counts.x);\n        float3 l;\n        for (int li = 0; li < 32; li++)\n        {\n            if (li >= _631)\n            {\n                break;\n            }\n            float atten = 1.0;\n            bool _660 = _654.fa_light_color[li].w < 0.5;\n            if (_660)\n            {\n                l = fast::normalize(_654.fa_light_pos[li].xyz);\n            }\n            else\n            {\n                float3 _677 = _654.fa_light_pos[li].xyz - in.fa_world_pos;\n                float _680 = length(_677);\n                l = _677 / float3(fast::max(_680, 9.9999997473787516355514526367188e-05));\n                float _695 = _680 / fast::max(_654.fa_light_pos[li].w, 0.001000000047497451305389404296875);\n                float _701 = fast::clamp(1.0 - (_695 * _695), 0.0, 1.0);\n                atten = _701 * _701;\n                if (_654.fa_light_color[li].w > 1.5)\n                {\n                    atten *= smoothstep(_654.fa_light_dir[li].w, mix(_654.fa_light_dir[li].w, 1.0, 0.25), dot(-l, fast::normalize(_654.fa_light_dir[li].xyz)));\n                }\n            }\n            float _734 = fast::max(dot(_579, l), 0.0);\n            if (_660 && (li == 0))\n            {\n                float3 param_3 = _909;\n                float3 param_4 = l;\n                atten *= fa_shadow_factor(param_3, param_4, _122, in.fa_shadow_pos, fa_shadow_tex, fa_shadow_smp);\n            }\n            float3 _753 = fast::normalize(l + _552);\n            float _758 = fast::max(dot(_579, _753), 0.0);\n            float _771 = ((_758 * _758) * (_598 - 1.0)) + 1.0;\n            lit += (((_610 + (((_618 + ((float3(1.0) - _618) * powr(1.0 - fast::max(dot(_552, _753), 0.0), 5.0))) * (((_598 / ((3.1415927410125732421875 * _771) * _771)) * (0.5 / fast::max(mix((2.0 * _734) * _604, _734 + _604, _594), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _734))) * _654.fa_light_color[li].xyz) * (_734 * atten));\n        }\n        float param_5 = _590;\n        float param_6 = _604;\n        float2 _839 = fa_env_brdf(param_5, param_6);\n        float3 param_7 = reflect(-_552, _579);\n        float param_8 = _590;\n        float3 _857 = lit;\n        float3 _858 = _857 + ((fa_environment(param_7, param_8, _122) * ((_618 * _839.x) + float3(_839.y))) * _933);\n        lit = _858;\n        result = _858;\n    }\n    result += _934;\n    if (_122.fa_fog.w > 0.0)\n    {\n        float _882 = _122.fa_fog.w * length(_551);\n        result = mix(result, _122.fa_fog.xyz, float3(fast::clamp(1.0 - exp((-_882) * _882), 0.0, 1.0)));\n    }\n    out.fa_frag_color = float4(result, _929);\n    return out;\n}\n\n",
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
            "type": "vec3",
            "base_type": "Float"
          },
          {
            "slot": 1,
            "type": "vec3",
            "base_type": "Float"
          },
          {
            "slot": 2,
            "type": "vec2",
            "base_type": "Float"
          },
          {
            "slot": 3,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 4,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 5,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 6,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 7,
            "type": "vec4",
            "base_type": "Float"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_127",
            "msl_buffer_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 192,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_122",
            "msl_buffer_n": 1
          },
          {
            "slot": 2,
            "stage": "fragment",
            "size": 1536,
            "struct_name": "fa_lights",
            "inst_name": "_654",
            "msl_buffer_n": 2
          }
        ],
        "views": [
          {
            "texture": {
              "slot": 0,
              "stage": "fragment",
              "name": "fa_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 0
            }
          },
          {
            "texture": {
              "slot": 1,
              "stage": "fragment",
              "name": "fa_shadow_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float",
              "msl_texture_n": 1
            }
          },
          {
            "texture": {
              "slot": 2,
              "stage": "fragment",
              "name": "fa_normal_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 2
            }
          },
          {
            "texture": {
              "slot": 3,
              "stage": "fragment",
              "name": "fa_mr_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 3
            }
          },
          {
            "texture": {
              "slot": 4,
              "stage": "fragment",
              "name": "fa_occlusion_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 4
            }
          },
          {
            "texture": {
              "slot": 5,
              "stage": "fragment",
              "name": "fa_emissive_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 5
            }
          }
        ],
        "samplers": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_smp",
            "sampler_type": "filtering",
            "msl_sampler_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_shadow_smp",
            "sampler_type": "nonfiltering",
            "msl_sampler_n": 1
          }
        ],
        "texture_sampler_pairs": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_tex_fa_smp",
            "view_name": "fa_tex",
            "sampler_name": "fa_smp",
            "view_slot": 0,
            "sampler_slot": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_normal_tex_fa_smp",
            "view_name": "fa_normal_tex",
            "sampler_name": "fa_smp",
            "view_slot": 2,
            "sampler_slot": 0
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "fa_mr_tex_fa_smp",
            "view_name": "fa_mr_tex",
            "sampler_name": "fa_smp",
            "view_slot": 3,
            "sampler_slot": 0
          },
          {
            "slot": 3,
            "stage": "fragment",
            "name": "fa_occlusion_tex_fa_smp",
            "view_name": "fa_occlusion_tex",
            "sampler_name": "fa_smp",
            "view_slot": 4,
            "sampler_slot": 0
          },
          {
            "slot": 4,
            "stage": "fragment",
            "name": "fa_emissive_tex_fa_smp",
            "view_name": "fa_emissive_tex",
            "sampler_name": "fa_smp",
            "view_slot": 5,
            "sampler_slot": 0
          },
          {
            "slot": 5,
            "stage": "fragment",
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1
          }
        ]
      }
    },
    "mesh_skin": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_shadow_pos [[user(locn4)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_inst_m0 [[attribute(4)]];\n    float4 fa_inst_m1 [[attribute(5)]];\n    float4 fa_inst_m2 [[attribute(6)]];\n    float4 fa_inst_m3 [[attribute(7)]];\n    float4 fa_joints [[attribute(8)]];\n    float4 fa_weights [[attribute(9)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _176)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _167 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_176.fa_joint_rows[_167] * weights[i]);\n        r1 += (_176.fa_joint_rows[_167 + 1] * weights[i]);\n        r2 += (_176.fa_joint_rows[_167 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, constant fa_mesh_vs_params& _132)\n{\n    float3 _70 = cross(model[1].xyz, model[2].xyz);\n    float _76 = (dot(model[0].xyz, _70) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_70 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _76, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _76), texcoord0 * _132.fa_uv_scale.xy, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, constant fa_mesh_vs_params& _132, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_shadow_pos, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    VertexData _264 = fa_vertex_data(param, param_1, param_2, param_3, param_4, _132);\n    float3 _372 = _264.world_pos;\n    float4 _271 = float4(_372, 1.0);\n    fa_world_pos = _372;\n    fa_world_normal = _264.world_normal;\n    fa_world_tangent = _264.world_tangent;\n    fa_uv = _264.uv;\n    fa_shadow_pos = _132.fa_light_vp * _271;\n    gl_Position = _132.fa_view_proj * _271;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _132 [[buffer(0)]], constant fa_skin& _176 [[buffer(3)]])\n{\n    main0_out out = {};\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float4x4 param_2 = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _176);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, _132, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_shadow_pos, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n};\n\nstruct fa_lights\n{\n    float4 fa_light_pos[32];\n    float4 fa_light_color[32];\n    float4 fa_light_dir[32];\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_shadow_pos [[user(locn4)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _52;\n    if (bool(i.front_facing))\n    {\n        _52 = i.world_normal;\n    }\n    else\n    {\n        _52 = -i.world_normal;\n    }\n    float3 _77 = fast::normalize(i.world_tangent.xyz - (_52 * dot(_52, i.world_tangent.xyz)));\n    float3 _105 = fast::normalize(((_77 * m.x) + ((cross(_52, _77) * i.world_tangent.w) * m.y)) + (_52 * m.z));\n    float3 _108;\n    if (bool(i.front_facing))\n    {\n        _108 = _105;\n    }\n    else\n    {\n        _108 = -_105;\n    }\n    return _108;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _122, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 _158 = fa_tex.sample(fa_smp, i.uv);\n    float4 _162 = _158 * _122.fa_base_color;\n    float3 _959 = i.world_normal;\n    if (_122.fa_maps.z > 0.5)\n    {\n        float3 _192 = (fa_normal_tex.sample(fa_smp, i.uv).xyz * 2.0) - float3(1.0);\n        float2 _197 = _192.xy * _122.fa_maps.x;\n        float3 _976 = _192;\n        _976.x = _197.x;\n        _976.y = _197.y;\n        SurfaceInput param = i;\n        float3 param_1 = _976;\n        _959 = fa_tangent_normal(param, param_1);\n    }\n    float4 _215 = fa_mr_tex.sample(fa_smp, i.uv);\n    return Surface{ _162.xyz, _162.w, _959, fast::clamp(_122.fa_pbr.x * _215.z, 0.0, 1.0), fast::clamp(_122.fa_pbr.y * _215.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_122.fa_maps.y * (fa_occlusion_tex.sample(fa_smp, i.uv).x - 1.0)), _122.fa_emissive.xyz + (_122.fa_model_emissive.xyz * fa_emissive_tex.sample(fa_smp, i.uv).xyz) };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread Surface& s, constant fa_mesh_fs_params& _122)\n{\n    s.emission += float3(0.5 + (0.5 * sin(_122.fa_time.x * 3.0)), 0.25 * fract(_122.fa_time.x), 0.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _122, thread float4& fa_shadow_pos, texture2d<float> fa_shadow_tex, sampler fa_shadow_smp)\n{\n    if (_122.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    float3 _281 = fa_shadow_pos.xyz / float3(fa_shadow_pos.w);\n    float3 p = _281;\n    float2 suv = (_281.xy * 0.5) + float2(0.5);\n    if (_122.fa_counts.z > 0.5)\n    {\n        float3 _981 = p;\n        _981.z = (_981.z * 0.5) + 0.5;\n        p = _981;\n    }\n    else\n    {\n        float2 _984 = suv;\n        _984.y = 1.0 - _984.y;\n        suv = _984;\n    }\n    bool _308 = suv.x < 0.0;\n    bool _315;\n    if (!_308)\n    {\n        _315 = suv.x > 1.0;\n    }\n    else\n    {\n        _315 = _308;\n    }\n    bool _322;\n    if (!_315)\n    {\n        _322 = suv.y < 0.0;\n    }\n    else\n    {\n        _322 = _315;\n    }\n    bool _329;\n    if (!_322)\n    {\n        _329 = suv.y > 1.0;\n    }\n    else\n    {\n        _329 = _322;\n    }\n    bool _336;\n    if (!_329)\n    {\n        _336 = p.z > 1.0;\n    }\n    else\n    {\n        _336 = _329;\n    }\n    if (_336)\n    {\n        return 1.0;\n    }\n    float _350 = _122.fa_pbr.w * (1.0 + (2.0 * (1.0 - fast::clamp(dot(n, l), 0.0, 1.0))));\n    float lit = 0.0;\n    for (int ix = -1; ix <= 1; ix++)\n    {\n        for (int iy = -1; iy <= 1; iy++)\n        {\n            lit += float((p.z - _350) <= fa_shadow_tex.sample(fa_shadow_smp, (suv + (float2(float(ix), float(iy)) * _122.fa_counts.y)), level(0.0)).x);\n        }\n    }\n    return lit * 0.111111111938953399658203125;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_env_brdf(thread const float& rough, thread const float& ndv)\n{\n    float4 _491 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _494 = _491.x;\n    return (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_494 * _494, exp2((-9.27999973297119140625) * ndv)) * _494) + _491.y)) + _491.zw;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_environment(thread const float3& d, thread const float& rough, constant fa_mesh_fs_params& _122)\n{\n    float _411 = rough * rough;\n    float _444 = 0.60000002384185791015625 * _411;\n    return mix(mix(_122.fa_env_horizon.xyz * 0.550000011920928955078125, mix(_122.fa_env_horizon.xyz, _122.fa_env_sky.xyz, float3(powr(fast::clamp(d.y * (1.0 - (0.699999988079071044921875 * _411)), 0.0, 1.0), 0.550000011920928955078125))), float3(smoothstep((-0.0500000007450580596923828125) - _444, 0.0500000007450580596923828125 + _444, d.y))), ((_122.fa_env_sky.xyz + _122.fa_env_horizon.xyz) * 0.5) * 0.800000011920928955078125, float3(_411 * 0.60000002384185791015625));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _122 [[buffer(1)]], constant fa_lights& _654 [[buffer(2)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    float3 _909 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _909 = -_909;\n    }\n    float3 _551 = _122.fa_camera_pos.xyz - in.fa_world_pos;\n    float3 _552 = fast::normalize(_551);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _909, in.fa_world_tangent, in.fa_uv, _552, short(gl_FrontFacing) };\n    Surface _557 = fa_standard_surface(param, _122, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _928 = _557.albedo;\n    float _929 = _557.alpha;\n    float3 _930 = _557.normal;\n    float _931 = _557.metallic;\n    float _932 = _557.roughness;\n    float _933 = _557.occlusion;\n    float3 _934 = _557.emission;\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _909, in.fa_world_tangent, in.fa_uv, _552, short(gl_FrontFacing) };\n    Surface param_2 = _557;\n    surface(param_1, param_2, _122);\n    _928 = param_2.albedo;\n    _929 = param_2.alpha;\n    _930 = param_2.normal;\n    _931 = param_2.metallic;\n    _932 = param_2.roughness;\n    _933 = param_2.occlusion;\n    _934 = param_2.emission;\n    float3 result;\n    if (_122.fa_emissive.w > 0.5)\n    {\n        result = _928;\n    }\n    else\n    {\n        float3 _579 = fast::normalize(_930);\n        float _586 = fast::clamp(_931, 0.0, 1.0);\n        float _590 = fast::clamp(_932, 0.0500000007450580596923828125, 1.0);\n        float _594 = _590 * _590;\n        float _598 = _594 * _594;\n        float _604 = fast::max(dot(_579, _552), 9.9999997473787516355514526367188e-05);\n        float3 _610 = _928 * (1.0 - _586);\n        float3 _618 = mix(float3(0.039999999105930328369140625), _928, float3(_586));\n        float3 lit = (_122.fa_ambient.xyz * _610) * _933;\n        int _631 = int(_122.fa_counts.x);\n        float3 l;\n        for (int li = 0; li < 32; li++)\n        {\n            if (li >= _631)\n            {\n                break;\n            }\n            float atten = 1.0;\n            bool _660 = _654.fa_light_color[li].w < 0.5;\n            if (_660)\n            {\n                l = fast::normalize(_654.fa_light_pos[li].xyz);\n            }\n            else\n            {\n                float3 _677 = _654.fa_light_pos[li].xyz - in.fa_world_pos;\n                float _680 = length(_677);\n                l = _677 / float3(fast::max(_680, 9.9999997473787516355514526367188e-05));\n                float _695 = _680 / fast::max(_654.fa_light_pos[li].w, 0.001000000047497451305389404296875);\n                float _701 = fast::clamp(1.0 - (_695 * _695), 0.0, 1.0);\n                atten = _701 * _701;\n                if (_654.fa_light_color[li].w > 1.5)\n                {\n                    atten *= smoothstep(_654.fa_light_dir[li].w, mix(_654.fa_light_dir[li].w, 1.0, 0.25), dot(-l, fast::normalize(_654.fa_light_dir[li].xyz)));\n                }\n            }\n            float _734 = fast::max(dot(_579, l), 0.0);\n            if (_660 && (li == 0))\n            {\n                float3 param_3 = _909;\n                float3 param_4 = l;\n                atten *= fa_shadow_factor(param_3, param_4, _122, in.fa_shadow_pos, fa_shadow_tex, fa_shadow_smp);\n            }\n            float3 _753 = fast::normalize(l + _552);\n            float _758 = fast::max(dot(_579, _753), 0.0);\n            float _771 = ((_758 * _758) * (_598 - 1.0)) + 1.0;\n            lit += (((_610 + (((_618 + ((float3(1.0) - _618) * powr(1.0 - fast::max(dot(_552, _753), 0.0), 5.0))) * (((_598 / ((3.1415927410125732421875 * _771) * _771)) * (0.5 / fast::max(mix((2.0 * _734) * _604, _734 + _604, _594), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _734))) * _654.fa_light_color[li].xyz) * (_734 * atten));\n        }\n        float param_5 = _590;\n        float param_6 = _604;\n        float2 _839 = fa_env_brdf(param_5, param_6);\n        float3 param_7 = reflect(-_552, _579);\n        float param_8 = _590;\n        float3 _857 = lit;\n        float3 _858 = _857 + ((fa_environment(param_7, param_8, _122) * ((_618 * _839.x) + float3(_839.y))) * _933);\n        lit = _858;\n        result = _858;\n    }\n    result += _934;\n    if (_122.fa_fog.w > 0.0)\n    {\n        float _882 = _122.fa_fog.w * length(_551);\n        result = mix(result, _122.fa_fog.xyz, float3(fast::clamp(1.0 - exp((-_882) * _882), 0.0, 1.0)));\n    }\n    out.fa_frag_color = float4(result, _929);\n    return out;\n}\n\n",
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
            "type": "vec3",
            "base_type": "Float"
          },
          {
            "slot": 1,
            "type": "vec3",
            "base_type": "Float"
          },
          {
            "slot": 2,
            "type": "vec2",
            "base_type": "Float"
          },
          {
            "slot": 3,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 4,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 5,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 6,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 7,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 8,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 9,
            "type": "vec4",
            "base_type": "Float"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_132",
            "msl_buffer_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_176",
            "msl_buffer_n": 3
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 192,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_122",
            "msl_buffer_n": 1
          },
          {
            "slot": 2,
            "stage": "fragment",
            "size": 1536,
            "struct_name": "fa_lights",
            "inst_name": "_654",
            "msl_buffer_n": 2
          }
        ],
        "views": [
          {
            "texture": {
              "slot": 0,
              "stage": "fragment",
              "name": "fa_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 0
            }
          },
          {
            "texture": {
              "slot": 1,
              "stage": "fragment",
              "name": "fa_shadow_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float",
              "msl_texture_n": 1
            }
          },
          {
            "texture": {
              "slot": 2,
              "stage": "fragment",
              "name": "fa_normal_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 2
            }
          },
          {
            "texture": {
              "slot": 3,
              "stage": "fragment",
              "name": "fa_mr_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 3
            }
          },
          {
            "texture": {
              "slot": 4,
              "stage": "fragment",
              "name": "fa_occlusion_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 4
            }
          },
          {
            "texture": {
              "slot": 5,
              "stage": "fragment",
              "name": "fa_emissive_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 5
            }
          }
        ],
        "samplers": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_smp",
            "sampler_type": "filtering",
            "msl_sampler_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_shadow_smp",
            "sampler_type": "nonfiltering",
            "msl_sampler_n": 1
          }
        ],
        "texture_sampler_pairs": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_tex_fa_smp",
            "view_name": "fa_tex",
            "sampler_name": "fa_smp",
            "view_slot": 0,
            "sampler_slot": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_normal_tex_fa_smp",
            "view_name": "fa_normal_tex",
            "sampler_name": "fa_smp",
            "view_slot": 2,
            "sampler_slot": 0
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "fa_mr_tex_fa_smp",
            "view_name": "fa_mr_tex",
            "sampler_name": "fa_smp",
            "view_slot": 3,
            "sampler_slot": 0
          },
          {
            "slot": 3,
            "stage": "fragment",
            "name": "fa_occlusion_tex_fa_smp",
            "view_name": "fa_occlusion_tex",
            "sampler_name": "fa_smp",
            "view_slot": 4,
            "sampler_slot": 0
          },
          {
            "slot": 4,
            "stage": "fragment",
            "name": "fa_emissive_tex_fa_smp",
            "view_name": "fa_emissive_tex",
            "sampler_name": "fa_smp",
            "view_slot": 5,
            "sampler_slot": 0
          },
          {
            "slot": 5,
            "stage": "fragment",
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1
          }
        ]
      }
    }
  }
}
