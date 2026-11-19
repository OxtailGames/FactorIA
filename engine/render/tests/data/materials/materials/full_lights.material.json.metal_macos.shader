{
  "format": "factoria.shader/1",
  "engine": "0.31.0",
  "template": "aa84dbdf1d3b8c964f7f7697fbc81e97aa2bc291506ba0e18f7b52c5766c89d3",
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
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n};\n\nstruct fa_lights\n{\n    float4 fa_light_pos[32];\n    float4 fa_light_color[32];\n    float4 fa_light_dir[32];\n};\n\nstruct fa_material\n{\n    float4 base;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 v_pos [[user(locn0)]];\n    float3 v_normal [[user(locn1)]];\n    float4 v_shadow [[user(locn2)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nint fa_light_count(constant fa_mesh_fs_params& _41)\n{\n    return min(int(_41.fa_counts.x), 32);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow(thread const float4& coord, thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _41, texture2d<float> fa_full_shadow_tex, sampler fa_full_shadow_smp)\n{\n    if (_41.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    float3 _63 = coord.xyz / float3(coord.w);\n    float3 p = _63;\n    float2 suv = (_63.xy * 0.5) + float2(0.5);\n    if (_41.fa_counts.z > 0.5)\n    {\n        float3 _675 = p;\n        _675.z = (_675.z * 0.5) + 0.5;\n        p = _675;\n    }\n    else\n    {\n        float2 _678 = suv;\n        _678.y = 1.0 - _678.y;\n        suv = _678;\n    }\n    bool _96 = suv.x < 0.0;\n    bool _103;\n    if (!_96)\n    {\n        _103 = suv.x > 1.0;\n    }\n    else\n    {\n        _103 = _96;\n    }\n    bool _110;\n    if (!_103)\n    {\n        _110 = suv.y < 0.0;\n    }\n    else\n    {\n        _110 = _103;\n    }\n    bool _117;\n    if (!_110)\n    {\n        _117 = suv.y > 1.0;\n    }\n    else\n    {\n        _117 = _110;\n    }\n    bool _124;\n    if (!_117)\n    {\n        _124 = p.z > 1.0;\n    }\n    else\n    {\n        _124 = _117;\n    }\n    if (_124)\n    {\n        return 1.0;\n    }\n    float _139 = _41.fa_pbr.w * (1.0 + (2.0 * (1.0 - fast::clamp(dot(n, l), 0.0, 1.0))));\n    float lit = 0.0;\n    for (int ix = -1; ix <= 1; ix++)\n    {\n        for (int iy = -1; iy <= 1; iy++)\n        {\n            lit += float((p.z - _139) <= fa_full_shadow_tex.sample(fa_full_shadow_smp, (suv + (float2(float(ix), float(iy)) * _41.fa_counts.y)), level(0.0)).x);\n        }\n    }\n    return lit * 0.111111111938953399658203125;\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light(thread const int& li, thread const float3& world_pos, thread const float3& gn, thread const float4& coord, constant fa_mesh_fs_params& _41, texture2d<float> fa_full_shadow_tex, sampler fa_full_shadow_smp, constant fa_lights& _216)\n{\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _223 = _216.fa_light_color[li].w < 0.5;\n    float3 l;\n    if (_223)\n    {\n        l = fast::normalize(_216.fa_light_pos[li].xyz);\n    }\n    else\n    {\n        float3 _241 = _216.fa_light_pos[li].xyz - world_pos;\n        float _243 = length(_241);\n        dist = _243;\n        l = _241 / float3(fast::max(_243, 9.9999997473787516355514526367188e-05));\n        float _259 = _243 / fast::max(_216.fa_light_pos[li].w, 0.001000000047497451305389404296875);\n        float _265 = fast::clamp(1.0 - (_259 * _259), 0.0, 1.0);\n        atten = _265 * _265;\n        if (_216.fa_light_color[li].w > 1.5)\n        {\n            atten *= smoothstep(_216.fa_light_dir[li].w, mix(_216.fa_light_dir[li].w, 1.0, 0.25), dot(-l, fast::normalize(_216.fa_light_dir[li].xyz)));\n        }\n    }\n    float shadow = 1.0;\n    if (_223 && (li == 0))\n    {\n        float4 param = coord;\n        float3 param_1 = gn;\n        float3 param_2 = l;\n        shadow = fa_shadow(param, param_1, param_2, _41, fa_full_shadow_tex, fa_full_shadow_smp);\n    }\n    int _334;\n    if (_223)\n    {\n        _334 = 0;\n    }\n    else\n    {\n        _334 = (_216.fa_light_color[li].w > 1.5) ? 2 : 1;\n    }\n    return LightSample{ l, _216.fa_light_color[li].xyz * (atten * shadow), atten, shadow, dist, _334 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_apply_fog(thread float3& result, thread const float3& world_pos, constant fa_mesh_fs_params& _41)\n{\n    bool _349 = _41.fa_fog.w > 0.0;\n    bool _357;\n    if (!_349)\n    {\n        _357 = _41.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _357 = _349;\n    }\n    if (_357)\n    {\n        float3 _365 = world_pos - _41.fa_camera_pos.xyz;\n        float _372 = dot(_365, _41.fa_fog_c.xyz);\n        bool _376 = _41.fa_fog_c.w > 0.5;\n        float _377;\n        if (_376)\n        {\n            _377 = _372;\n        }\n        else\n        {\n            _377 = length(_365);\n        }\n        float _389 = _377 - _41.fa_fog_b.x;\n        if (_389 > 0.0)\n        {\n            float _398 = _41.fa_fog.w * _389;\n            float tau = _398 * _398;\n            if (_41.fa_fog_b.y > 0.0)\n            {\n                float _414;\n                if (_376)\n                {\n                    _414 = world_pos.y - (_41.fa_fog_c.y * _372);\n                }\n                else\n                {\n                    _414 = _41.fa_camera_pos.y;\n                }\n                float _435 = mix(_414, world_pos.y, fast::clamp(_41.fa_fog_b.x / _377, 0.0, 1.0));\n                float _439 = world_pos.y - _435;\n                float _444 = _435 - _41.fa_fog_b.z;\n                float _449 = world_pos.y - _41.fa_fog_b.z;\n                bool _452 = _444 <= 0.0;\n                bool _453 = !_452;\n                bool _459;\n                if (_453)\n                {\n                    _459 = _41.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _459 = _452;\n                }\n                float _460;\n                if (_459)\n                {\n                    _460 = _41.fa_fog_b.y;\n                }\n                else\n                {\n                    _460 = _41.fa_fog_b.y * exp(-fast::min(_41.fa_fog_b.w * _444, 80.0));\n                }\n                bool _487;\n                if (_453)\n                {\n                    _487 = _41.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _487 = _452;\n                }\n                float _488;\n                if (_487)\n                {\n                    _488 = _41.fa_fog_b.y * _444;\n                }\n                else\n                {\n                    _488 = (_41.fa_fog_b.y * (1.0 - exp(-fast::min(_41.fa_fog_b.w * _444, 80.0)))) / _41.fa_fog_b.w;\n                }\n                bool _513 = _449 <= 0.0;\n                bool _520;\n                if (!_513)\n                {\n                    _520 = _41.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _520 = _513;\n                }\n                float _521;\n                if (_520)\n                {\n                    _521 = _41.fa_fog_b.y * _449;\n                }\n                else\n                {\n                    _521 = (_41.fa_fog_b.y * (1.0 - exp(-fast::min(_41.fa_fog_b.w * _449, 80.0)))) / _41.fa_fog_b.w;\n                }\n                float _548;\n                if (abs(_439) < 0.001000000047497451305389404296875)\n                {\n                    _548 = _460;\n                }\n                else\n                {\n                    _548 = (_521 - _488) / _439;\n                }\n                tau += (_389 * fast::max(_548, 0.0));\n            }\n            result = mix(result, _41.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_user_main(constant fa_mesh_fs_params& _41, texture2d<float> fa_full_shadow_tex, sampler fa_full_shadow_smp, constant fa_lights& _216, thread float3& v_normal, constant fa_material& _593, thread float3& v_pos, thread float4& v_shadow, thread float4& fa_frag_color)\n{\n    float3 _586 = fast::normalize(v_normal);\n    float3 lit = _41.fa_ambient.xyz * _593.base.xyz;\n    for (int i = 0; i < fa_light_count(_41); i++)\n    {\n        int param = i;\n        float3 param_1 = v_pos;\n        float3 param_2 = _586;\n        float4 param_3 = v_shadow;\n        LightSample _619 = fa_light(param, param_1, param_2, param_3, _41, fa_full_shadow_tex, fa_full_shadow_smp, _216);\n        lit += ((_593.base.xyz * _619.color) * fast::max(dot(_586, _619.direction), 0.0));\n    }\n    float3 param_4 = lit;\n    float3 param_5 = v_pos;\n    float3 _642 = fa_apply_fog(param_4, param_5, _41);\n    fa_frag_color = float4(_642, 1.0);\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _41 [[buffer(1)]], constant fa_lights& _216 [[buffer(2)]], constant fa_material& _593 [[buffer(5)]], texture2d<float> fa_full_shadow_tex [[texture(0)]], sampler fa_full_shadow_smp [[sampler(1)]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    fa_user_main(_41, fa_full_shadow_tex, fa_full_shadow_smp, _216, in.v_normal, _593, in.v_pos, in.v_shadow, out.fa_frag_color);\n    return out;\n}\n\n",
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
            "slot": 1,
            "stage": "fragment",
            "size": 224,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_41",
            "msl_buffer_n": 1
          },
          {
            "slot": 2,
            "stage": "fragment",
            "size": 1536,
            "struct_name": "fa_lights",
            "inst_name": "_216",
            "msl_buffer_n": 2
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_593",
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
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n};\n\nstruct fa_lights\n{\n    float4 fa_light_pos[32];\n    float4 fa_light_color[32];\n    float4 fa_light_dir[32];\n};\n\nstruct fa_material\n{\n    float4 base;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 v_pos [[user(locn0)]];\n    float3 v_normal [[user(locn1)]];\n    float4 v_shadow [[user(locn2)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nint fa_light_count(constant fa_mesh_fs_params& _41)\n{\n    return min(int(_41.fa_counts.x), 32);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow(thread const float4& coord, thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _41, texture2d<float> fa_full_shadow_tex, sampler fa_full_shadow_smp)\n{\n    if (_41.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    float3 _63 = coord.xyz / float3(coord.w);\n    float3 p = _63;\n    float2 suv = (_63.xy * 0.5) + float2(0.5);\n    if (_41.fa_counts.z > 0.5)\n    {\n        float3 _675 = p;\n        _675.z = (_675.z * 0.5) + 0.5;\n        p = _675;\n    }\n    else\n    {\n        float2 _678 = suv;\n        _678.y = 1.0 - _678.y;\n        suv = _678;\n    }\n    bool _96 = suv.x < 0.0;\n    bool _103;\n    if (!_96)\n    {\n        _103 = suv.x > 1.0;\n    }\n    else\n    {\n        _103 = _96;\n    }\n    bool _110;\n    if (!_103)\n    {\n        _110 = suv.y < 0.0;\n    }\n    else\n    {\n        _110 = _103;\n    }\n    bool _117;\n    if (!_110)\n    {\n        _117 = suv.y > 1.0;\n    }\n    else\n    {\n        _117 = _110;\n    }\n    bool _124;\n    if (!_117)\n    {\n        _124 = p.z > 1.0;\n    }\n    else\n    {\n        _124 = _117;\n    }\n    if (_124)\n    {\n        return 1.0;\n    }\n    float _139 = _41.fa_pbr.w * (1.0 + (2.0 * (1.0 - fast::clamp(dot(n, l), 0.0, 1.0))));\n    float lit = 0.0;\n    for (int ix = -1; ix <= 1; ix++)\n    {\n        for (int iy = -1; iy <= 1; iy++)\n        {\n            lit += float((p.z - _139) <= fa_full_shadow_tex.sample(fa_full_shadow_smp, (suv + (float2(float(ix), float(iy)) * _41.fa_counts.y)), level(0.0)).x);\n        }\n    }\n    return lit * 0.111111111938953399658203125;\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light(thread const int& li, thread const float3& world_pos, thread const float3& gn, thread const float4& coord, constant fa_mesh_fs_params& _41, texture2d<float> fa_full_shadow_tex, sampler fa_full_shadow_smp, constant fa_lights& _216)\n{\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _223 = _216.fa_light_color[li].w < 0.5;\n    float3 l;\n    if (_223)\n    {\n        l = fast::normalize(_216.fa_light_pos[li].xyz);\n    }\n    else\n    {\n        float3 _241 = _216.fa_light_pos[li].xyz - world_pos;\n        float _243 = length(_241);\n        dist = _243;\n        l = _241 / float3(fast::max(_243, 9.9999997473787516355514526367188e-05));\n        float _259 = _243 / fast::max(_216.fa_light_pos[li].w, 0.001000000047497451305389404296875);\n        float _265 = fast::clamp(1.0 - (_259 * _259), 0.0, 1.0);\n        atten = _265 * _265;\n        if (_216.fa_light_color[li].w > 1.5)\n        {\n            atten *= smoothstep(_216.fa_light_dir[li].w, mix(_216.fa_light_dir[li].w, 1.0, 0.25), dot(-l, fast::normalize(_216.fa_light_dir[li].xyz)));\n        }\n    }\n    float shadow = 1.0;\n    if (_223 && (li == 0))\n    {\n        float4 param = coord;\n        float3 param_1 = gn;\n        float3 param_2 = l;\n        shadow = fa_shadow(param, param_1, param_2, _41, fa_full_shadow_tex, fa_full_shadow_smp);\n    }\n    int _334;\n    if (_223)\n    {\n        _334 = 0;\n    }\n    else\n    {\n        _334 = (_216.fa_light_color[li].w > 1.5) ? 2 : 1;\n    }\n    return LightSample{ l, _216.fa_light_color[li].xyz * (atten * shadow), atten, shadow, dist, _334 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_apply_fog(thread float3& result, thread const float3& world_pos, constant fa_mesh_fs_params& _41)\n{\n    bool _349 = _41.fa_fog.w > 0.0;\n    bool _357;\n    if (!_349)\n    {\n        _357 = _41.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _357 = _349;\n    }\n    if (_357)\n    {\n        float3 _365 = world_pos - _41.fa_camera_pos.xyz;\n        float _372 = dot(_365, _41.fa_fog_c.xyz);\n        bool _376 = _41.fa_fog_c.w > 0.5;\n        float _377;\n        if (_376)\n        {\n            _377 = _372;\n        }\n        else\n        {\n            _377 = length(_365);\n        }\n        float _389 = _377 - _41.fa_fog_b.x;\n        if (_389 > 0.0)\n        {\n            float _398 = _41.fa_fog.w * _389;\n            float tau = _398 * _398;\n            if (_41.fa_fog_b.y > 0.0)\n            {\n                float _414;\n                if (_376)\n                {\n                    _414 = world_pos.y - (_41.fa_fog_c.y * _372);\n                }\n                else\n                {\n                    _414 = _41.fa_camera_pos.y;\n                }\n                float _435 = mix(_414, world_pos.y, fast::clamp(_41.fa_fog_b.x / _377, 0.0, 1.0));\n                float _439 = world_pos.y - _435;\n                float _444 = _435 - _41.fa_fog_b.z;\n                float _449 = world_pos.y - _41.fa_fog_b.z;\n                bool _452 = _444 <= 0.0;\n                bool _453 = !_452;\n                bool _459;\n                if (_453)\n                {\n                    _459 = _41.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _459 = _452;\n                }\n                float _460;\n                if (_459)\n                {\n                    _460 = _41.fa_fog_b.y;\n                }\n                else\n                {\n                    _460 = _41.fa_fog_b.y * exp(-fast::min(_41.fa_fog_b.w * _444, 80.0));\n                }\n                bool _487;\n                if (_453)\n                {\n                    _487 = _41.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _487 = _452;\n                }\n                float _488;\n                if (_487)\n                {\n                    _488 = _41.fa_fog_b.y * _444;\n                }\n                else\n                {\n                    _488 = (_41.fa_fog_b.y * (1.0 - exp(-fast::min(_41.fa_fog_b.w * _444, 80.0)))) / _41.fa_fog_b.w;\n                }\n                bool _513 = _449 <= 0.0;\n                bool _520;\n                if (!_513)\n                {\n                    _520 = _41.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _520 = _513;\n                }\n                float _521;\n                if (_520)\n                {\n                    _521 = _41.fa_fog_b.y * _449;\n                }\n                else\n                {\n                    _521 = (_41.fa_fog_b.y * (1.0 - exp(-fast::min(_41.fa_fog_b.w * _449, 80.0)))) / _41.fa_fog_b.w;\n                }\n                float _548;\n                if (abs(_439) < 0.001000000047497451305389404296875)\n                {\n                    _548 = _460;\n                }\n                else\n                {\n                    _548 = (_521 - _488) / _439;\n                }\n                tau += (_389 * fast::max(_548, 0.0));\n            }\n            result = mix(result, _41.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_user_main(constant fa_mesh_fs_params& _41, texture2d<float> fa_full_shadow_tex, sampler fa_full_shadow_smp, constant fa_lights& _216, thread float3& v_normal, constant fa_material& _593, thread float3& v_pos, thread float4& v_shadow, thread float4& fa_frag_color)\n{\n    float3 _586 = fast::normalize(v_normal);\n    float3 lit = _41.fa_ambient.xyz * _593.base.xyz;\n    for (int i = 0; i < fa_light_count(_41); i++)\n    {\n        int param = i;\n        float3 param_1 = v_pos;\n        float3 param_2 = _586;\n        float4 param_3 = v_shadow;\n        LightSample _619 = fa_light(param, param_1, param_2, param_3, _41, fa_full_shadow_tex, fa_full_shadow_smp, _216);\n        lit += ((_593.base.xyz * _619.color) * fast::max(dot(_586, _619.direction), 0.0));\n    }\n    float3 param_4 = lit;\n    float3 param_5 = v_pos;\n    float3 _642 = fa_apply_fog(param_4, param_5, _41);\n    fa_frag_color = float4(_642, 1.0);\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _41 [[buffer(1)]], constant fa_lights& _216 [[buffer(2)]], constant fa_material& _593 [[buffer(5)]], texture2d<float> fa_full_shadow_tex [[texture(0)]], sampler fa_full_shadow_smp [[sampler(1)]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    fa_user_main(_41, fa_full_shadow_tex, fa_full_shadow_smp, _216, in.v_normal, _593, in.v_pos, in.v_shadow, out.fa_frag_color);\n    return out;\n}\n\n",
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
            "slot": 1,
            "stage": "fragment",
            "size": 224,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_41",
            "msl_buffer_n": 1
          },
          {
            "slot": 2,
            "stage": "fragment",
            "size": 1536,
            "struct_name": "fa_lights",
            "inst_name": "_216",
            "msl_buffer_n": 2
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_593",
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
