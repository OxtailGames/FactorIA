{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "5803d023b1c011299e7caeb3dafe645d0b88230997a6bd7a8ad8bad27e396a28",
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
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n};\n\nstruct fa_material\n{\n    float4 base;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 v_pos [[user(locn0)]];\n    float3 v_normal [[user(locn1)]];\n    float4 v_shadow [[user(locn2)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nint fa_light_count(constant fa_mesh_fs_params& _216)\n{\n    return min(int(_216.fa_counts.x), 32);\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_full_light_tex, sampler fa_full_shadow_smp)\n{\n    return fa_full_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, texture2d<float> fa_full_light_tex, sampler fa_full_shadow_smp)\n{\n    int param = li * 4;\n    float4 _81 = fa_light_texel(param, fa_full_light_tex, fa_full_shadow_smp);\n    int param_1 = (li * 4) + 1;\n    float4 _88 = fa_light_texel(param_1, fa_full_light_tex, fa_full_shadow_smp);\n    float _94 = _88.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _102 = _94 < 0.5;\n    float3 l;\n    if (_102)\n    {\n        l = fast::normalize(_81.xyz);\n    }\n    else\n    {\n        float3 _114 = _81.xyz - world_pos;\n        float _116 = length(_114);\n        dist = _116;\n        l = _114 / float3(fast::max(_116, 9.9999997473787516355514526367188e-05));\n        float _131 = _116 / fast::max(_81.w, 0.001000000047497451305389404296875);\n        float _137 = fast::clamp(1.0 - (_131 * _131), 0.0, 1.0);\n        atten = _137 * _137;\n        if (_94 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _152 = fa_light_texel(param_2, fa_full_light_tex, fa_full_shadow_smp);\n            float _162 = _152.w;\n            int param_3 = (li * 4) + 3;\n            float4 _169 = fa_light_texel(param_3, fa_full_light_tex, fa_full_shadow_smp);\n            float _171 = _169.x;\n            float cos_inner = _171;\n            if (_171 > 1.5)\n            {\n                cos_inner = mix(_162, 1.0, 0.25);\n            }\n            atten *= smoothstep(_162, cos_inner, dot(-l, fast::normalize(_152.xyz)));\n        }\n    }\n    int _202;\n    if (_102)\n    {\n        _202 = 0;\n    }\n    else\n    {\n        _202 = (_94 > 1.5) ? 2 : 1;\n    }\n    return LightSample{ l, _88.xyz * atten, atten, 1.0, dist, _202 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_pcf(thread const float4& coord, thread const float3& n, thread const float3& l, sampler fa_full_shadow_smp, constant fa_mesh_fs_params& _216, texture2d<float> fa_full_shadow_tex)\n{\n    if (_216.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    float3 _231 = coord.xyz / float3(coord.w);\n    float3 p = _231;\n    float2 suv = (_231.xy * 0.5) + float2(0.5);\n    if (_216.fa_counts.z > 0.5)\n    {\n        float3 _760 = p;\n        _760.z = (_760.z * 0.5) + 0.5;\n        p = _760;\n    }\n    else\n    {\n        float2 _763 = suv;\n        _763.y = 1.0 - _763.y;\n        suv = _763;\n    }\n    bool _261 = suv.x < 0.0;\n    bool _268;\n    if (!_261)\n    {\n        _268 = suv.x > 1.0;\n    }\n    else\n    {\n        _268 = _261;\n    }\n    bool _275;\n    if (!_268)\n    {\n        _275 = suv.y < 0.0;\n    }\n    else\n    {\n        _275 = _268;\n    }\n    bool _282;\n    if (!_275)\n    {\n        _282 = suv.y > 1.0;\n    }\n    else\n    {\n        _282 = _275;\n    }\n    bool _289;\n    if (!_282)\n    {\n        _289 = p.z > 1.0;\n    }\n    else\n    {\n        _289 = _282;\n    }\n    if (_289)\n    {\n        return 1.0;\n    }\n    float _304 = _216.fa_pbr.w * (1.0 + (2.0 * (1.0 - fast::clamp(dot(n, l), 0.0, 1.0))));\n    float lit = 0.0;\n    for (int ix = -1; ix <= 1; ix++)\n    {\n        for (int iy = -1; iy <= 1; iy++)\n        {\n            lit += float((p.z - _304) <= fa_full_shadow_tex.sample(fa_full_shadow_smp, (suv + (float2(float(ix), float(iy)) * _216.fa_counts.y)), level(0.0)).x);\n        }\n    }\n    return lit * 0.111111111938953399658203125;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow(thread const float4& coord, thread const float3& n, thread const float3& l, sampler fa_full_shadow_smp, constant fa_mesh_fs_params& _216, texture2d<float> fa_full_shadow_tex)\n{\n    float4 param = coord;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_pcf(param, param_1, param_2, fa_full_shadow_smp, _216, fa_full_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light(thread const int& li, thread const float3& world_pos, thread const float3& gn, thread const float4& coord, texture2d<float> fa_full_light_tex, sampler fa_full_shadow_smp, constant fa_mesh_fs_params& _216, texture2d<float> fa_full_shadow_tex)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _381 = fa_light_sample(param, param_1, fa_full_light_tex, fa_full_shadow_smp);\n    float3 _738 = _381.direction;\n    float3 _733 = _381.color;\n    float _735 = _381.shadow;\n    int _743 = _381.type;\n    if ((_743 == 0) && (li == 0))\n    {\n        float4 param_2 = coord;\n        float3 param_3 = gn;\n        float3 param_4 = _738;\n        float _397 = fa_shadow(param_2, param_3, param_4, fa_full_shadow_smp, _216, fa_full_shadow_tex);\n        _735 = _397;\n        _733 *= _397;\n    }\n    return LightSample{ _738, _733, _381.attenuation, _735, _381._distance, _743 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_apply_fog(thread float3& result, thread const float3& world_pos, constant fa_mesh_fs_params& _216)\n{\n    bool _411 = _216.fa_fog.w > 0.0;\n    bool _419;\n    if (!_411)\n    {\n        _419 = _216.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _419 = _411;\n    }\n    if (_419)\n    {\n        float3 _428 = world_pos - _216.fa_camera_pos.xyz;\n        float _435 = dot(_428, _216.fa_fog_c.xyz);\n        bool _439 = _216.fa_fog_c.w > 0.5;\n        float _440;\n        if (_439)\n        {\n            _440 = _435;\n        }\n        else\n        {\n            _440 = length(_428);\n        }\n        float _452 = _440 - _216.fa_fog_b.x;\n        if (_452 > 0.0)\n        {\n            float _461 = _216.fa_fog.w * _452;\n            float tau = _461 * _461;\n            if (_216.fa_fog_b.y > 0.0)\n            {\n                float _477;\n                if (_439)\n                {\n                    _477 = world_pos.y - (_216.fa_fog_c.y * _435);\n                }\n                else\n                {\n                    _477 = _216.fa_camera_pos.y;\n                }\n                float _498 = mix(_477, world_pos.y, fast::clamp(_216.fa_fog_b.x / _440, 0.0, 1.0));\n                float _502 = world_pos.y - _498;\n                float _507 = _498 - _216.fa_fog_b.z;\n                float _512 = world_pos.y - _216.fa_fog_b.z;\n                bool _515 = _507 <= 0.0;\n                bool _516 = !_515;\n                bool _522;\n                if (_516)\n                {\n                    _522 = _216.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _522 = _515;\n                }\n                float _523;\n                if (_522)\n                {\n                    _523 = _216.fa_fog_b.y;\n                }\n                else\n                {\n                    _523 = _216.fa_fog_b.y * exp(-fast::min(_216.fa_fog_b.w * _507, 80.0));\n                }\n                bool _550;\n                if (_516)\n                {\n                    _550 = _216.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _550 = _515;\n                }\n                float _551;\n                if (_550)\n                {\n                    _551 = _216.fa_fog_b.y * _507;\n                }\n                else\n                {\n                    _551 = (_216.fa_fog_b.y * (1.0 - exp(-fast::min(_216.fa_fog_b.w * _507, 80.0)))) / _216.fa_fog_b.w;\n                }\n                bool _576 = _512 <= 0.0;\n                bool _583;\n                if (!_576)\n                {\n                    _583 = _216.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _583 = _576;\n                }\n                float _584;\n                if (_583)\n                {\n                    _584 = _216.fa_fog_b.y * _512;\n                }\n                else\n                {\n                    _584 = (_216.fa_fog_b.y * (1.0 - exp(-fast::min(_216.fa_fog_b.w * _512, 80.0)))) / _216.fa_fog_b.w;\n                }\n                float _611;\n                if (abs(_502) < 0.001000000047497451305389404296875)\n                {\n                    _611 = _523;\n                }\n                else\n                {\n                    _611 = (_584 - _551) / _502;\n                }\n                tau += (_452 * fast::max(_611, 0.0));\n            }\n            result = mix(result, _216.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_user_main(texture2d<float> fa_full_light_tex, sampler fa_full_shadow_smp, constant fa_mesh_fs_params& _216, texture2d<float> fa_full_shadow_tex, thread float3& v_normal, constant fa_material& _656, thread float3& v_pos, thread float4& v_shadow, thread float4& fa_frag_color)\n{\n    float3 _649 = fast::normalize(v_normal);\n    float3 lit = _216.fa_ambient.xyz * _656.base.xyz;\n    for (int i = 0; i < fa_light_count(_216); i++)\n    {\n        int param = i;\n        float3 param_1 = v_pos;\n        float3 param_2 = _649;\n        float4 param_3 = v_shadow;\n        LightSample _682 = fa_light(param, param_1, param_2, param_3, fa_full_light_tex, fa_full_shadow_smp, _216, fa_full_shadow_tex);\n        lit += ((_656.base.xyz * _682.color) * fast::max(dot(_649, _682.direction), 0.0));\n    }\n    float3 param_4 = lit;\n    float3 param_5 = v_pos;\n    float3 _705 = fa_apply_fog(param_4, param_5, _216);\n    fa_frag_color = float4(_705, 1.0);\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _216 [[buffer(1)]], constant fa_material& _656 [[buffer(5)]], texture2d<float> fa_full_shadow_tex [[texture(0)]], texture2d<float> fa_full_light_tex [[texture(1)]], sampler fa_full_shadow_smp [[sampler(1)]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    fa_user_main(fa_full_light_tex, fa_full_shadow_smp, _216, fa_full_shadow_tex, in.v_normal, _656, in.v_pos, in.v_shadow, out.fa_frag_color);\n    return out;\n}\n\n",
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
            "size": 320,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_216",
            "msl_buffer_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_656",
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
          },
          {
            "texture": {
              "slot": 24,
              "stage": "fragment",
              "name": "fa_full_light_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float",
              "msl_texture_n": 1
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
            "name": "fa_full_light_tex_fa_full_shadow_smp",
            "view_name": "fa_full_light_tex",
            "sampler_name": "fa_full_shadow_smp",
            "view_slot": 24,
            "sampler_slot": 1
          },
          {
            "slot": 1,
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
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n};\n\nstruct fa_material\n{\n    float4 base;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 v_pos [[user(locn0)]];\n    float3 v_normal [[user(locn1)]];\n    float4 v_shadow [[user(locn2)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nint fa_light_count(constant fa_mesh_fs_params& _216)\n{\n    return min(int(_216.fa_counts.x), 32);\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_full_light_tex, sampler fa_full_shadow_smp)\n{\n    return fa_full_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, texture2d<float> fa_full_light_tex, sampler fa_full_shadow_smp)\n{\n    int param = li * 4;\n    float4 _81 = fa_light_texel(param, fa_full_light_tex, fa_full_shadow_smp);\n    int param_1 = (li * 4) + 1;\n    float4 _88 = fa_light_texel(param_1, fa_full_light_tex, fa_full_shadow_smp);\n    float _94 = _88.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _102 = _94 < 0.5;\n    float3 l;\n    if (_102)\n    {\n        l = fast::normalize(_81.xyz);\n    }\n    else\n    {\n        float3 _114 = _81.xyz - world_pos;\n        float _116 = length(_114);\n        dist = _116;\n        l = _114 / float3(fast::max(_116, 9.9999997473787516355514526367188e-05));\n        float _131 = _116 / fast::max(_81.w, 0.001000000047497451305389404296875);\n        float _137 = fast::clamp(1.0 - (_131 * _131), 0.0, 1.0);\n        atten = _137 * _137;\n        if (_94 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _152 = fa_light_texel(param_2, fa_full_light_tex, fa_full_shadow_smp);\n            float _162 = _152.w;\n            int param_3 = (li * 4) + 3;\n            float4 _169 = fa_light_texel(param_3, fa_full_light_tex, fa_full_shadow_smp);\n            float _171 = _169.x;\n            float cos_inner = _171;\n            if (_171 > 1.5)\n            {\n                cos_inner = mix(_162, 1.0, 0.25);\n            }\n            atten *= smoothstep(_162, cos_inner, dot(-l, fast::normalize(_152.xyz)));\n        }\n    }\n    int _202;\n    if (_102)\n    {\n        _202 = 0;\n    }\n    else\n    {\n        _202 = (_94 > 1.5) ? 2 : 1;\n    }\n    return LightSample{ l, _88.xyz * atten, atten, 1.0, dist, _202 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_pcf(thread const float4& coord, thread const float3& n, thread const float3& l, sampler fa_full_shadow_smp, constant fa_mesh_fs_params& _216, texture2d<float> fa_full_shadow_tex)\n{\n    if (_216.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    float3 _231 = coord.xyz / float3(coord.w);\n    float3 p = _231;\n    float2 suv = (_231.xy * 0.5) + float2(0.5);\n    if (_216.fa_counts.z > 0.5)\n    {\n        float3 _760 = p;\n        _760.z = (_760.z * 0.5) + 0.5;\n        p = _760;\n    }\n    else\n    {\n        float2 _763 = suv;\n        _763.y = 1.0 - _763.y;\n        suv = _763;\n    }\n    bool _261 = suv.x < 0.0;\n    bool _268;\n    if (!_261)\n    {\n        _268 = suv.x > 1.0;\n    }\n    else\n    {\n        _268 = _261;\n    }\n    bool _275;\n    if (!_268)\n    {\n        _275 = suv.y < 0.0;\n    }\n    else\n    {\n        _275 = _268;\n    }\n    bool _282;\n    if (!_275)\n    {\n        _282 = suv.y > 1.0;\n    }\n    else\n    {\n        _282 = _275;\n    }\n    bool _289;\n    if (!_282)\n    {\n        _289 = p.z > 1.0;\n    }\n    else\n    {\n        _289 = _282;\n    }\n    if (_289)\n    {\n        return 1.0;\n    }\n    float _304 = _216.fa_pbr.w * (1.0 + (2.0 * (1.0 - fast::clamp(dot(n, l), 0.0, 1.0))));\n    float lit = 0.0;\n    for (int ix = -1; ix <= 1; ix++)\n    {\n        for (int iy = -1; iy <= 1; iy++)\n        {\n            lit += float((p.z - _304) <= fa_full_shadow_tex.sample(fa_full_shadow_smp, (suv + (float2(float(ix), float(iy)) * _216.fa_counts.y)), level(0.0)).x);\n        }\n    }\n    return lit * 0.111111111938953399658203125;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow(thread const float4& coord, thread const float3& n, thread const float3& l, sampler fa_full_shadow_smp, constant fa_mesh_fs_params& _216, texture2d<float> fa_full_shadow_tex)\n{\n    float4 param = coord;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_pcf(param, param_1, param_2, fa_full_shadow_smp, _216, fa_full_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light(thread const int& li, thread const float3& world_pos, thread const float3& gn, thread const float4& coord, texture2d<float> fa_full_light_tex, sampler fa_full_shadow_smp, constant fa_mesh_fs_params& _216, texture2d<float> fa_full_shadow_tex)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _381 = fa_light_sample(param, param_1, fa_full_light_tex, fa_full_shadow_smp);\n    float3 _738 = _381.direction;\n    float3 _733 = _381.color;\n    float _735 = _381.shadow;\n    int _743 = _381.type;\n    if ((_743 == 0) && (li == 0))\n    {\n        float4 param_2 = coord;\n        float3 param_3 = gn;\n        float3 param_4 = _738;\n        float _397 = fa_shadow(param_2, param_3, param_4, fa_full_shadow_smp, _216, fa_full_shadow_tex);\n        _735 = _397;\n        _733 *= _397;\n    }\n    return LightSample{ _738, _733, _381.attenuation, _735, _381._distance, _743 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_apply_fog(thread float3& result, thread const float3& world_pos, constant fa_mesh_fs_params& _216)\n{\n    bool _411 = _216.fa_fog.w > 0.0;\n    bool _419;\n    if (!_411)\n    {\n        _419 = _216.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _419 = _411;\n    }\n    if (_419)\n    {\n        float3 _428 = world_pos - _216.fa_camera_pos.xyz;\n        float _435 = dot(_428, _216.fa_fog_c.xyz);\n        bool _439 = _216.fa_fog_c.w > 0.5;\n        float _440;\n        if (_439)\n        {\n            _440 = _435;\n        }\n        else\n        {\n            _440 = length(_428);\n        }\n        float _452 = _440 - _216.fa_fog_b.x;\n        if (_452 > 0.0)\n        {\n            float _461 = _216.fa_fog.w * _452;\n            float tau = _461 * _461;\n            if (_216.fa_fog_b.y > 0.0)\n            {\n                float _477;\n                if (_439)\n                {\n                    _477 = world_pos.y - (_216.fa_fog_c.y * _435);\n                }\n                else\n                {\n                    _477 = _216.fa_camera_pos.y;\n                }\n                float _498 = mix(_477, world_pos.y, fast::clamp(_216.fa_fog_b.x / _440, 0.0, 1.0));\n                float _502 = world_pos.y - _498;\n                float _507 = _498 - _216.fa_fog_b.z;\n                float _512 = world_pos.y - _216.fa_fog_b.z;\n                bool _515 = _507 <= 0.0;\n                bool _516 = !_515;\n                bool _522;\n                if (_516)\n                {\n                    _522 = _216.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _522 = _515;\n                }\n                float _523;\n                if (_522)\n                {\n                    _523 = _216.fa_fog_b.y;\n                }\n                else\n                {\n                    _523 = _216.fa_fog_b.y * exp(-fast::min(_216.fa_fog_b.w * _507, 80.0));\n                }\n                bool _550;\n                if (_516)\n                {\n                    _550 = _216.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _550 = _515;\n                }\n                float _551;\n                if (_550)\n                {\n                    _551 = _216.fa_fog_b.y * _507;\n                }\n                else\n                {\n                    _551 = (_216.fa_fog_b.y * (1.0 - exp(-fast::min(_216.fa_fog_b.w * _507, 80.0)))) / _216.fa_fog_b.w;\n                }\n                bool _576 = _512 <= 0.0;\n                bool _583;\n                if (!_576)\n                {\n                    _583 = _216.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _583 = _576;\n                }\n                float _584;\n                if (_583)\n                {\n                    _584 = _216.fa_fog_b.y * _512;\n                }\n                else\n                {\n                    _584 = (_216.fa_fog_b.y * (1.0 - exp(-fast::min(_216.fa_fog_b.w * _512, 80.0)))) / _216.fa_fog_b.w;\n                }\n                float _611;\n                if (abs(_502) < 0.001000000047497451305389404296875)\n                {\n                    _611 = _523;\n                }\n                else\n                {\n                    _611 = (_584 - _551) / _502;\n                }\n                tau += (_452 * fast::max(_611, 0.0));\n            }\n            result = mix(result, _216.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_user_main(texture2d<float> fa_full_light_tex, sampler fa_full_shadow_smp, constant fa_mesh_fs_params& _216, texture2d<float> fa_full_shadow_tex, thread float3& v_normal, constant fa_material& _656, thread float3& v_pos, thread float4& v_shadow, thread float4& fa_frag_color)\n{\n    float3 _649 = fast::normalize(v_normal);\n    float3 lit = _216.fa_ambient.xyz * _656.base.xyz;\n    for (int i = 0; i < fa_light_count(_216); i++)\n    {\n        int param = i;\n        float3 param_1 = v_pos;\n        float3 param_2 = _649;\n        float4 param_3 = v_shadow;\n        LightSample _682 = fa_light(param, param_1, param_2, param_3, fa_full_light_tex, fa_full_shadow_smp, _216, fa_full_shadow_tex);\n        lit += ((_656.base.xyz * _682.color) * fast::max(dot(_649, _682.direction), 0.0));\n    }\n    float3 param_4 = lit;\n    float3 param_5 = v_pos;\n    float3 _705 = fa_apply_fog(param_4, param_5, _216);\n    fa_frag_color = float4(_705, 1.0);\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _216 [[buffer(1)]], constant fa_material& _656 [[buffer(5)]], texture2d<float> fa_full_shadow_tex [[texture(0)]], texture2d<float> fa_full_light_tex [[texture(1)]], sampler fa_full_shadow_smp [[sampler(1)]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    fa_user_main(fa_full_light_tex, fa_full_shadow_smp, _216, fa_full_shadow_tex, in.v_normal, _656, in.v_pos, in.v_shadow, out.fa_frag_color);\n    return out;\n}\n\n",
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
            "size": 320,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_216",
            "msl_buffer_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_656",
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
          },
          {
            "texture": {
              "slot": 24,
              "stage": "fragment",
              "name": "fa_full_light_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float",
              "msl_texture_n": 1
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
            "name": "fa_full_light_tex_fa_full_shadow_smp",
            "view_name": "fa_full_light_tex",
            "sampler_name": "fa_full_shadow_smp",
            "view_slot": 24,
            "sampler_slot": 1
          },
          {
            "slot": 1,
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
