{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "8e17f8fe8414cc09b116dbec8674b3a6cd067e2a7d4dad7f7f8631e46f7f82bd",
  "slang": "metal_macos",
  "params": [
    "base"
  ],
  "textures": [],
  "full": true,
  "shadow": "none",
  "prepass": false,
  "passes": [
    {
      "name": "main",
      "cull": "back",
      "depthTest": true,
      "depthWrite": true,
      "blend": "none",
      "program": "mesh",
      "programSkin": "mesh_skin"
    }
  ],
  "programs": {
    "mesh": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float3 v_pos [[user(locn0)]];\n    float3 v_normal [[user(locn1)]];\n    float4 v_shadow [[user(locn2)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_world_position(thread const float3& p, thread float4x4& fa_model)\n{\n    return (fa_model * float4(p, 1.0)).xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_world_direction(thread const float3& n, thread float4x4& fa_model)\n{\n    float3 _61 = cross(fa_model[1].xyz, fa_model[2].xyz);\n    return fast::normalize((((_61 * n.x) + (cross(fa_model[2].xyz, fa_model[0].xyz) * n.y)) + (cross(fa_model[0].xyz, fa_model[1].xyz) * n.z)) * ((dot(fa_model[0].xyz, _61) < 0.0) ? (-1.0) : 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_shadow_coord(thread const float3& world, constant fa_mesh_vs_params& _99)\n{\n    return _99.fa_light_vp * float4(world, 1.0);\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_user_main(thread float4x4& fa_model, constant fa_mesh_vs_params& _99, thread float3& fa_position, thread float3& v_pos, thread float3& v_normal, thread float3& fa_normal, thread float4& v_shadow, thread float4& gl_Position)\n{\n    float3 param = fa_position;\n    float3 _116 = fa_world_position(param, fa_model);\n    v_pos = _116;\n    float3 param_1 = fa_normal;\n    v_normal = fa_world_direction(param_1, fa_model);\n    float3 param_2 = _116;\n    v_shadow = fa_shadow_coord(param_2, _99);\n    gl_Position = _99.fa_view_proj * float4(_116, 1.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _99 [[buffer(0)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4x4 fa_model = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    fa_user_main(fa_model, _99, in.fa_position, out.v_pos, out.v_normal, in.fa_normal, out.v_shadow, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct fa_lights\n{\n    float4 fa_light_pos[32];\n    float4 fa_light_color[32];\n    float4 fa_light_dir[32];\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct fa_material\n{\n    float4 base;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 v_pos [[user(locn0)]];\n    float3 v_normal [[user(locn1)]];\n    float4 v_shadow [[user(locn2)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nint fa_light_count(constant fa_mesh_fs_params& _180)\n{\n    return min(int(_180.fa_counts.x), 32);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, constant fa_lights& _58)\n{\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _72 = _58.fa_light_color[li].w < 0.5;\n    float3 l;\n    if (_72)\n    {\n        l = fast::normalize(_58.fa_light_pos[li].xyz);\n    }\n    else\n    {\n        float3 _90 = _58.fa_light_pos[li].xyz - world_pos;\n        float _92 = length(_90);\n        dist = _92;\n        l = _90 / float3(fast::max(_92, 9.9999997473787516355514526367188e-05));\n        float _108 = _92 / fast::max(_58.fa_light_pos[li].w, 0.001000000047497451305389404296875);\n        float _114 = fast::clamp(1.0 - (_108 * _108), 0.0, 1.0);\n        atten = _114 * _114;\n        if (_58.fa_light_color[li].w > 1.5)\n        {\n            atten *= smoothstep(_58.fa_light_dir[li].w, mix(_58.fa_light_dir[li].w, 1.0, 0.25), dot(-l, fast::normalize(_58.fa_light_dir[li].xyz)));\n        }\n    }\n    int _166;\n    if (_72)\n    {\n        _166 = 0;\n    }\n    else\n    {\n        _166 = (_58.fa_light_color[li].w > 1.5) ? 2 : 1;\n    }\n    return LightSample{ l, _58.fa_light_color[li].xyz * atten, atten, 1.0, dist, _166 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_pcf(thread const float4& coord, thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _180, texture2d<float> fa_full_shadow_tex, sampler fa_full_shadow_smp)\n{\n    if (_180.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    float3 _194 = coord.xyz / float3(coord.w);\n    float3 p = _194;\n    float2 suv = (_194.xy * 0.5) + float2(0.5);\n    if (_180.fa_counts.z > 0.5)\n    {\n        float3 _732 = p;\n        _732.z = (_732.z * 0.5) + 0.5;\n        p = _732;\n    }\n    else\n    {\n        float2 _735 = suv;\n        _735.y = 1.0 - _735.y;\n        suv = _735;\n    }\n    bool _226 = suv.x < 0.0;\n    bool _233;\n    if (!_226)\n    {\n        _233 = suv.x > 1.0;\n    }\n    else\n    {\n        _233 = _226;\n    }\n    bool _240;\n    if (!_233)\n    {\n        _240 = suv.y < 0.0;\n    }\n    else\n    {\n        _240 = _233;\n    }\n    bool _247;\n    if (!_240)\n    {\n        _247 = suv.y > 1.0;\n    }\n    else\n    {\n        _247 = _240;\n    }\n    bool _254;\n    if (!_247)\n    {\n        _254 = p.z > 1.0;\n    }\n    else\n    {\n        _254 = _247;\n    }\n    if (_254)\n    {\n        return 1.0;\n    }\n    float _269 = _180.fa_pbr.w * (1.0 + (2.0 * (1.0 - fast::clamp(dot(n, l), 0.0, 1.0))));\n    float lit = 0.0;\n    for (int ix = -1; ix <= 1; ix++)\n    {\n        for (int iy = -1; iy <= 1; iy++)\n        {\n            lit += float((p.z - _269) <= fa_full_shadow_tex.sample(fa_full_shadow_smp, (suv + (float2(float(ix), float(iy)) * _180.fa_counts.y)), level(0.0)).x);\n        }\n    }\n    return lit * 0.111111111938953399658203125;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow(thread const float4& coord, thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _180, texture2d<float> fa_full_shadow_tex, sampler fa_full_shadow_smp)\n{\n    float4 param = coord;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_pcf(param, param_1, param_2, _180, fa_full_shadow_tex, fa_full_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light(thread const int& li, thread const float3& world_pos, thread const float3& gn, thread const float4& coord, constant fa_lights& _58, constant fa_mesh_fs_params& _180, texture2d<float> fa_full_shadow_tex, sampler fa_full_shadow_smp)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _352 = fa_light_sample(param, param_1, _58);\n    float3 _713 = _352.direction;\n    float3 _708 = _352.color;\n    float _715 = _352.attenuation;\n    float _710 = _352.shadow;\n    int _718 = _352.type;\n    if ((_718 == 0) && (li == 0))\n    {\n        float4 param_2 = coord;\n        float3 param_3 = gn;\n        float3 param_4 = _713;\n        float _368 = fa_shadow(param_2, param_3, param_4, _180, fa_full_shadow_tex, fa_full_shadow_smp);\n        _710 = _368;\n        _708 = _58.fa_light_color[li].xyz * (_715 * _368);\n    }\n    return LightSample{ _713, _708, _715, _710, _352._distance, _718 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_apply_fog(thread float3& result, thread const float3& world_pos, constant fa_mesh_fs_params& _180)\n{\n    bool _387 = _180.fa_fog.w > 0.0;\n    bool _395;\n    if (!_387)\n    {\n        _395 = _180.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _395 = _387;\n    }\n    if (_395)\n    {\n        float3 _403 = world_pos - _180.fa_camera_pos.xyz;\n        float _410 = dot(_403, _180.fa_fog_c.xyz);\n        bool _414 = _180.fa_fog_c.w > 0.5;\n        float _415;\n        if (_414)\n        {\n            _415 = _410;\n        }\n        else\n        {\n            _415 = length(_403);\n        }\n        float _427 = _415 - _180.fa_fog_b.x;\n        if (_427 > 0.0)\n        {\n            float _436 = _180.fa_fog.w * _427;\n            float tau = _436 * _436;\n            if (_180.fa_fog_b.y > 0.0)\n            {\n                float _452;\n                if (_414)\n                {\n                    _452 = world_pos.y - (_180.fa_fog_c.y * _410);\n                }\n                else\n                {\n                    _452 = _180.fa_camera_pos.y;\n                }\n                float _473 = mix(_452, world_pos.y, fast::clamp(_180.fa_fog_b.x / _415, 0.0, 1.0));\n                float _477 = world_pos.y - _473;\n                float _482 = _473 - _180.fa_fog_b.z;\n                float _487 = world_pos.y - _180.fa_fog_b.z;\n                bool _490 = _482 <= 0.0;\n                bool _491 = !_490;\n                bool _497;\n                if (_491)\n                {\n                    _497 = _180.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _497 = _490;\n                }\n                float _498;\n                if (_497)\n                {\n                    _498 = _180.fa_fog_b.y;\n                }\n                else\n                {\n                    _498 = _180.fa_fog_b.y * exp(-fast::min(_180.fa_fog_b.w * _482, 80.0));\n                }\n                bool _525;\n                if (_491)\n                {\n                    _525 = _180.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _525 = _490;\n                }\n                float _526;\n                if (_525)\n                {\n                    _526 = _180.fa_fog_b.y * _482;\n                }\n                else\n                {\n                    _526 = (_180.fa_fog_b.y * (1.0 - exp(-fast::min(_180.fa_fog_b.w * _482, 80.0)))) / _180.fa_fog_b.w;\n                }\n                bool _551 = _487 <= 0.0;\n                bool _558;\n                if (!_551)\n                {\n                    _558 = _180.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _558 = _551;\n                }\n                float _559;\n                if (_558)\n                {\n                    _559 = _180.fa_fog_b.y * _487;\n                }\n                else\n                {\n                    _559 = (_180.fa_fog_b.y * (1.0 - exp(-fast::min(_180.fa_fog_b.w * _487, 80.0)))) / _180.fa_fog_b.w;\n                }\n                float _586;\n                if (abs(_477) < 0.001000000047497451305389404296875)\n                {\n                    _586 = _498;\n                }\n                else\n                {\n                    _586 = (_559 - _526) / _477;\n                }\n                tau += (_427 * fast::max(_586, 0.0));\n            }\n            result = mix(result, _180.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_user_main(constant fa_lights& _58, constant fa_mesh_fs_params& _180, texture2d<float> fa_full_shadow_tex, sampler fa_full_shadow_smp, thread float3& v_normal, constant fa_material& _631, thread float3& v_pos, thread float4& v_shadow, thread float4& fa_frag_color)\n{\n    float3 _624 = fast::normalize(v_normal);\n    float3 lit = _180.fa_ambient.xyz * _631.base.xyz;\n    for (int i = 0; i < fa_light_count(_180); i++)\n    {\n        int param = i;\n        float3 param_1 = v_pos;\n        float3 param_2 = _624;\n        float4 param_3 = v_shadow;\n        LightSample _657 = fa_light(param, param_1, param_2, param_3, _58, _180, fa_full_shadow_tex, fa_full_shadow_smp);\n        lit += ((_631.base.xyz * _657.color) * fast::max(dot(_624, _657.direction), 0.0));\n    }\n    float3 param_4 = lit;\n    float3 param_5 = v_pos;\n    float3 _680 = fa_apply_fog(param_4, param_5, _180);\n    fa_frag_color = float4(_680, 1.0);\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _180 [[buffer(1)]], constant fa_lights& _58 [[buffer(2)]], constant fa_material& _631 [[buffer(5)]], texture2d<float> fa_full_shadow_tex [[texture(0)]], sampler fa_full_shadow_smp [[sampler(1)]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    fa_user_main(_58, _180, fa_full_shadow_tex, fa_full_shadow_smp, in.v_normal, _631, in.v_pos, in.v_shadow, out.fa_frag_color);\n    return out;\n}\n\n",
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
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_99",
            "msl_buffer_n": 0
          },
          {
            "slot": 2,
            "stage": "fragment",
            "size": 1536,
            "struct_name": "fa_lights",
            "inst_name": "_58",
            "msl_buffer_n": 2
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 288,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_180",
            "msl_buffer_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_631",
            "msl_buffer_n": 5
          }
        ],
        "views": [
          {
            "texture": {
              "slot": 1,
              "stage": "fragment",
              "name": "fa_full_shadow_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float",
              "msl_texture_n": 0
            }
          }
        ],
        "samplers": [
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_full_shadow_smp",
            "sampler_type": "nonfiltering",
            "msl_sampler_n": 1
          }
        ],
        "texture_sampler_pairs": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_full_shadow_tex_fa_full_shadow_smp",
            "view_name": "fa_full_shadow_tex",
            "sampler_name": "fa_full_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1
          }
        ]
      }
    },
    "mesh_skin": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float3 v_pos [[user(locn0)]];\n    float3 v_normal [[user(locn1)]];\n    float4 v_shadow [[user(locn2)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n    float4 fa_joints [[attribute(9)]];\n    float4 fa_weights [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _71)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _61 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_71.fa_joint_rows[_61] * weights[i]);\n        r1 += (_71.fa_joint_rows[_61 + 1] * weights[i]);\n        r2 += (_71.fa_joint_rows[_61 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_world_position(thread const float3& p, thread float4x4& fa_model)\n{\n    return (fa_model * float4(p, 1.0)).xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_world_direction(thread const float3& n, thread float4x4& fa_model)\n{\n    float3 _185 = cross(fa_model[1].xyz, fa_model[2].xyz);\n    return fast::normalize((((_185 * n.x) + (cross(fa_model[2].xyz, fa_model[0].xyz) * n.y)) + (cross(fa_model[0].xyz, fa_model[1].xyz) * n.z)) * ((dot(fa_model[0].xyz, _185) < 0.0) ? (-1.0) : 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_shadow_coord(thread const float3& world, constant fa_mesh_vs_params& _217)\n{\n    return _217.fa_light_vp * float4(world, 1.0);\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_user_main(thread float4x4& fa_model, constant fa_mesh_vs_params& _217, thread float3& fa_position, thread float3& v_pos, thread float3& v_normal, thread float3& fa_normal, thread float4& v_shadow, thread float4& gl_Position)\n{\n    float3 param = fa_position;\n    float3 _234 = fa_world_position(param, fa_model);\n    v_pos = _234;\n    float3 param_1 = fa_normal;\n    v_normal = fa_world_direction(param_1, fa_model);\n    float3 param_2 = _234;\n    v_shadow = fa_shadow_coord(param_2, _217);\n    gl_Position = _217.fa_view_proj * float4(_234, 1.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _217 [[buffer(0)]], constant fa_skin& _71 [[buffer(3)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float4x4 fa_model = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _71);\n    fa_user_main(fa_model, _217, in.fa_position, out.v_pos, out.v_normal, in.fa_normal, out.v_shadow, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct fa_lights\n{\n    float4 fa_light_pos[32];\n    float4 fa_light_color[32];\n    float4 fa_light_dir[32];\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct fa_material\n{\n    float4 base;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 v_pos [[user(locn0)]];\n    float3 v_normal [[user(locn1)]];\n    float4 v_shadow [[user(locn2)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nint fa_light_count(constant fa_mesh_fs_params& _180)\n{\n    return min(int(_180.fa_counts.x), 32);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, constant fa_lights& _58)\n{\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _72 = _58.fa_light_color[li].w < 0.5;\n    float3 l;\n    if (_72)\n    {\n        l = fast::normalize(_58.fa_light_pos[li].xyz);\n    }\n    else\n    {\n        float3 _90 = _58.fa_light_pos[li].xyz - world_pos;\n        float _92 = length(_90);\n        dist = _92;\n        l = _90 / float3(fast::max(_92, 9.9999997473787516355514526367188e-05));\n        float _108 = _92 / fast::max(_58.fa_light_pos[li].w, 0.001000000047497451305389404296875);\n        float _114 = fast::clamp(1.0 - (_108 * _108), 0.0, 1.0);\n        atten = _114 * _114;\n        if (_58.fa_light_color[li].w > 1.5)\n        {\n            atten *= smoothstep(_58.fa_light_dir[li].w, mix(_58.fa_light_dir[li].w, 1.0, 0.25), dot(-l, fast::normalize(_58.fa_light_dir[li].xyz)));\n        }\n    }\n    int _166;\n    if (_72)\n    {\n        _166 = 0;\n    }\n    else\n    {\n        _166 = (_58.fa_light_color[li].w > 1.5) ? 2 : 1;\n    }\n    return LightSample{ l, _58.fa_light_color[li].xyz * atten, atten, 1.0, dist, _166 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_pcf(thread const float4& coord, thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _180, texture2d<float> fa_full_shadow_tex, sampler fa_full_shadow_smp)\n{\n    if (_180.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    float3 _194 = coord.xyz / float3(coord.w);\n    float3 p = _194;\n    float2 suv = (_194.xy * 0.5) + float2(0.5);\n    if (_180.fa_counts.z > 0.5)\n    {\n        float3 _732 = p;\n        _732.z = (_732.z * 0.5) + 0.5;\n        p = _732;\n    }\n    else\n    {\n        float2 _735 = suv;\n        _735.y = 1.0 - _735.y;\n        suv = _735;\n    }\n    bool _226 = suv.x < 0.0;\n    bool _233;\n    if (!_226)\n    {\n        _233 = suv.x > 1.0;\n    }\n    else\n    {\n        _233 = _226;\n    }\n    bool _240;\n    if (!_233)\n    {\n        _240 = suv.y < 0.0;\n    }\n    else\n    {\n        _240 = _233;\n    }\n    bool _247;\n    if (!_240)\n    {\n        _247 = suv.y > 1.0;\n    }\n    else\n    {\n        _247 = _240;\n    }\n    bool _254;\n    if (!_247)\n    {\n        _254 = p.z > 1.0;\n    }\n    else\n    {\n        _254 = _247;\n    }\n    if (_254)\n    {\n        return 1.0;\n    }\n    float _269 = _180.fa_pbr.w * (1.0 + (2.0 * (1.0 - fast::clamp(dot(n, l), 0.0, 1.0))));\n    float lit = 0.0;\n    for (int ix = -1; ix <= 1; ix++)\n    {\n        for (int iy = -1; iy <= 1; iy++)\n        {\n            lit += float((p.z - _269) <= fa_full_shadow_tex.sample(fa_full_shadow_smp, (suv + (float2(float(ix), float(iy)) * _180.fa_counts.y)), level(0.0)).x);\n        }\n    }\n    return lit * 0.111111111938953399658203125;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow(thread const float4& coord, thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _180, texture2d<float> fa_full_shadow_tex, sampler fa_full_shadow_smp)\n{\n    float4 param = coord;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_pcf(param, param_1, param_2, _180, fa_full_shadow_tex, fa_full_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light(thread const int& li, thread const float3& world_pos, thread const float3& gn, thread const float4& coord, constant fa_lights& _58, constant fa_mesh_fs_params& _180, texture2d<float> fa_full_shadow_tex, sampler fa_full_shadow_smp)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _352 = fa_light_sample(param, param_1, _58);\n    float3 _713 = _352.direction;\n    float3 _708 = _352.color;\n    float _715 = _352.attenuation;\n    float _710 = _352.shadow;\n    int _718 = _352.type;\n    if ((_718 == 0) && (li == 0))\n    {\n        float4 param_2 = coord;\n        float3 param_3 = gn;\n        float3 param_4 = _713;\n        float _368 = fa_shadow(param_2, param_3, param_4, _180, fa_full_shadow_tex, fa_full_shadow_smp);\n        _710 = _368;\n        _708 = _58.fa_light_color[li].xyz * (_715 * _368);\n    }\n    return LightSample{ _713, _708, _715, _710, _352._distance, _718 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_apply_fog(thread float3& result, thread const float3& world_pos, constant fa_mesh_fs_params& _180)\n{\n    bool _387 = _180.fa_fog.w > 0.0;\n    bool _395;\n    if (!_387)\n    {\n        _395 = _180.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _395 = _387;\n    }\n    if (_395)\n    {\n        float3 _403 = world_pos - _180.fa_camera_pos.xyz;\n        float _410 = dot(_403, _180.fa_fog_c.xyz);\n        bool _414 = _180.fa_fog_c.w > 0.5;\n        float _415;\n        if (_414)\n        {\n            _415 = _410;\n        }\n        else\n        {\n            _415 = length(_403);\n        }\n        float _427 = _415 - _180.fa_fog_b.x;\n        if (_427 > 0.0)\n        {\n            float _436 = _180.fa_fog.w * _427;\n            float tau = _436 * _436;\n            if (_180.fa_fog_b.y > 0.0)\n            {\n                float _452;\n                if (_414)\n                {\n                    _452 = world_pos.y - (_180.fa_fog_c.y * _410);\n                }\n                else\n                {\n                    _452 = _180.fa_camera_pos.y;\n                }\n                float _473 = mix(_452, world_pos.y, fast::clamp(_180.fa_fog_b.x / _415, 0.0, 1.0));\n                float _477 = world_pos.y - _473;\n                float _482 = _473 - _180.fa_fog_b.z;\n                float _487 = world_pos.y - _180.fa_fog_b.z;\n                bool _490 = _482 <= 0.0;\n                bool _491 = !_490;\n                bool _497;\n                if (_491)\n                {\n                    _497 = _180.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _497 = _490;\n                }\n                float _498;\n                if (_497)\n                {\n                    _498 = _180.fa_fog_b.y;\n                }\n                else\n                {\n                    _498 = _180.fa_fog_b.y * exp(-fast::min(_180.fa_fog_b.w * _482, 80.0));\n                }\n                bool _525;\n                if (_491)\n                {\n                    _525 = _180.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _525 = _490;\n                }\n                float _526;\n                if (_525)\n                {\n                    _526 = _180.fa_fog_b.y * _482;\n                }\n                else\n                {\n                    _526 = (_180.fa_fog_b.y * (1.0 - exp(-fast::min(_180.fa_fog_b.w * _482, 80.0)))) / _180.fa_fog_b.w;\n                }\n                bool _551 = _487 <= 0.0;\n                bool _558;\n                if (!_551)\n                {\n                    _558 = _180.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _558 = _551;\n                }\n                float _559;\n                if (_558)\n                {\n                    _559 = _180.fa_fog_b.y * _487;\n                }\n                else\n                {\n                    _559 = (_180.fa_fog_b.y * (1.0 - exp(-fast::min(_180.fa_fog_b.w * _487, 80.0)))) / _180.fa_fog_b.w;\n                }\n                float _586;\n                if (abs(_477) < 0.001000000047497451305389404296875)\n                {\n                    _586 = _498;\n                }\n                else\n                {\n                    _586 = (_559 - _526) / _477;\n                }\n                tau += (_427 * fast::max(_586, 0.0));\n            }\n            result = mix(result, _180.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_user_main(constant fa_lights& _58, constant fa_mesh_fs_params& _180, texture2d<float> fa_full_shadow_tex, sampler fa_full_shadow_smp, thread float3& v_normal, constant fa_material& _631, thread float3& v_pos, thread float4& v_shadow, thread float4& fa_frag_color)\n{\n    float3 _624 = fast::normalize(v_normal);\n    float3 lit = _180.fa_ambient.xyz * _631.base.xyz;\n    for (int i = 0; i < fa_light_count(_180); i++)\n    {\n        int param = i;\n        float3 param_1 = v_pos;\n        float3 param_2 = _624;\n        float4 param_3 = v_shadow;\n        LightSample _657 = fa_light(param, param_1, param_2, param_3, _58, _180, fa_full_shadow_tex, fa_full_shadow_smp);\n        lit += ((_631.base.xyz * _657.color) * fast::max(dot(_624, _657.direction), 0.0));\n    }\n    float3 param_4 = lit;\n    float3 param_5 = v_pos;\n    float3 _680 = fa_apply_fog(param_4, param_5, _180);\n    fa_frag_color = float4(_680, 1.0);\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _180 [[buffer(1)]], constant fa_lights& _58 [[buffer(2)]], constant fa_material& _631 [[buffer(5)]], texture2d<float> fa_full_shadow_tex [[texture(0)]], sampler fa_full_shadow_smp [[sampler(1)]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    fa_user_main(_58, _180, fa_full_shadow_tex, fa_full_shadow_smp, in.v_normal, _631, in.v_pos, in.v_shadow, out.fa_frag_color);\n    return out;\n}\n\n",
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
          },
          {
            "slot": 10,
            "type": "vec4",
            "base_type": "Float"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_71",
            "msl_buffer_n": 3
          },
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_217",
            "msl_buffer_n": 0
          },
          {
            "slot": 2,
            "stage": "fragment",
            "size": 1536,
            "struct_name": "fa_lights",
            "inst_name": "_58",
            "msl_buffer_n": 2
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 288,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_180",
            "msl_buffer_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_631",
            "msl_buffer_n": 5
          }
        ],
        "views": [
          {
            "texture": {
              "slot": 1,
              "stage": "fragment",
              "name": "fa_full_shadow_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float",
              "msl_texture_n": 0
            }
          }
        ],
        "samplers": [
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_full_shadow_smp",
            "sampler_type": "nonfiltering",
            "msl_sampler_n": 1
          }
        ],
        "texture_sampler_pairs": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_full_shadow_tex_fa_full_shadow_smp",
            "view_name": "fa_full_shadow_tex",
            "sampler_name": "fa_full_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1
          }
        ]
      }
    }
  }
}
