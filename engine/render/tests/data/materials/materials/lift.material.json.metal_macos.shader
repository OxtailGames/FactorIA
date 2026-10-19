{
  "format": "factoria.shader/1",
  "engine": "0.1.6",
  "template": "c92b9f1a26adc9a735edf9d88d24268eb2cae4ffeaa00748a36617e70a4776c1",
  "slang": "metal_macos",
  "params": [
    "offset"
  ],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float3 object_pos;\n};\n\nstruct fa_material_vs\n{\n    packed_float3 offset;\n    float fa_pad0;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_shadow_pos [[user(locn4)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_inst_m0 [[attribute(4)]];\n    float4 fa_inst_m1 [[attribute(5)]];\n    float4 fa_inst_m2 [[attribute(6)]];\n    float4 fa_inst_m3 [[attribute(7)]];\n};\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, constant fa_mesh_vs_params& _141)\n{\n    float3 _79 = cross(model[1].xyz, model[2].xyz);\n    float _85 = (dot(model[0].xyz, _79) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_79 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _85, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _85), texcoord0 * _141.fa_uv_scale.xy, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread VertexData& v, constant fa_material_vs& _41)\n{\n    v.world_pos += float3(_41.offset);\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, constant fa_material_vs& _41, constant fa_mesh_vs_params& _141, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_shadow_pos, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    VertexData param_5 = fa_vertex_data(param, param_1, param_2, param_3, param_4, _141);\n    vertex0(param_5, _41);\n    float4 _176 = float4(param_5.world_pos, 1.0);\n    fa_world_pos = param_5.world_pos;\n    fa_world_normal = param_5.world_normal;\n    fa_world_tangent = param_5.world_tangent;\n    fa_uv = param_5.uv;\n    fa_shadow_pos = _141.fa_light_vp * _176;\n    gl_Position = _141.fa_view_proj * _176;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _141 [[buffer(0)]], constant fa_material_vs& _41 [[buffer(4)]])\n{\n    main0_out out = {};\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, _41, _141, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_shadow_pos, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n};\n\nstruct fa_lights\n{\n    float4 fa_light_pos[32];\n    float4 fa_light_color[32];\n    float4 fa_light_dir[32];\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_shadow_pos [[user(locn4)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _52;\n    if (bool(i.front_facing))\n    {\n        _52 = i.world_normal;\n    }\n    else\n    {\n        _52 = -i.world_normal;\n    }\n    float3 _77 = fast::normalize(i.world_tangent.xyz - (_52 * dot(_52, i.world_tangent.xyz)));\n    float3 _105 = fast::normalize(((_77 * m.x) + ((cross(_52, _77) * i.world_tangent.w) * m.y)) + (_52 * m.z));\n    float3 _108;\n    if (bool(i.front_facing))\n    {\n        _108 = _105;\n    }\n    else\n    {\n        _108 = -_105;\n    }\n    return _108;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _136, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 _133 = fa_tex.sample(fa_smp, i.uv);\n    float4 _140 = _133 * _136.fa_base_color;\n    float3 _945 = i.world_normal;\n    if (_136.fa_maps.z > 0.5)\n    {\n        float3 _173 = (fa_normal_tex.sample(fa_smp, i.uv).xyz * 2.0) - float3(1.0);\n        float2 _178 = _173.xy * _136.fa_maps.x;\n        float3 _962 = _173;\n        _962.x = _178.x;\n        _962.y = _178.y;\n        SurfaceInput param = i;\n        float3 param_1 = _962;\n        _945 = fa_tangent_normal(param, param_1);\n    }\n    float4 _196 = fa_mr_tex.sample(fa_smp, i.uv);\n    return Surface{ _140.xyz, _140.w, _945, fast::clamp(_136.fa_pbr.x * _196.z, 0.0, 1.0), fast::clamp(_136.fa_pbr.y * _196.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_136.fa_maps.y * (fa_occlusion_tex.sample(fa_smp, i.uv).x - 1.0)), _136.fa_emissive.xyz + (_136.fa_model_emissive.xyz * fa_emissive_tex.sample(fa_smp, i.uv).xyz) };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _136, thread float4& fa_shadow_pos, texture2d<float> fa_shadow_tex, sampler fa_shadow_smp)\n{\n    if (_136.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    float3 _263 = fa_shadow_pos.xyz / float3(fa_shadow_pos.w);\n    float3 p = _263;\n    float2 suv = (_263.xy * 0.5) + float2(0.5);\n    if (_136.fa_counts.z > 0.5)\n    {\n        float3 _967 = p;\n        _967.z = (_967.z * 0.5) + 0.5;\n        p = _967;\n    }\n    else\n    {\n        float2 _970 = suv;\n        _970.y = 1.0 - _970.y;\n        suv = _970;\n    }\n    bool _290 = suv.x < 0.0;\n    bool _297;\n    if (!_290)\n    {\n        _297 = suv.x > 1.0;\n    }\n    else\n    {\n        _297 = _290;\n    }\n    bool _304;\n    if (!_297)\n    {\n        _304 = suv.y < 0.0;\n    }\n    else\n    {\n        _304 = _297;\n    }\n    bool _311;\n    if (!_304)\n    {\n        _311 = suv.y > 1.0;\n    }\n    else\n    {\n        _311 = _304;\n    }\n    bool _318;\n    if (!_311)\n    {\n        _318 = p.z > 1.0;\n    }\n    else\n    {\n        _318 = _311;\n    }\n    if (_318)\n    {\n        return 1.0;\n    }\n    float _332 = _136.fa_pbr.w * (1.0 + (2.0 * (1.0 - fast::clamp(dot(n, l), 0.0, 1.0))));\n    float lit = 0.0;\n    for (int ix = -1; ix <= 1; ix++)\n    {\n        for (int iy = -1; iy <= 1; iy++)\n        {\n            lit += float((p.z - _332) <= fa_shadow_tex.sample(fa_shadow_smp, (suv + (float2(float(ix), float(iy)) * _136.fa_counts.y)), level(0.0)).x);\n        }\n    }\n    return lit * 0.111111111938953399658203125;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_env_brdf(thread const float& rough, thread const float& ndv)\n{\n    float4 _473 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _476 = _473.x;\n    return (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_476 * _476, exp2((-9.27999973297119140625) * ndv)) * _476) + _473.y)) + _473.zw;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_environment(thread const float3& d, thread const float& rough, constant fa_mesh_fs_params& _136)\n{\n    float _393 = rough * rough;\n    float _426 = 0.60000002384185791015625 * _393;\n    return mix(mix(_136.fa_env_horizon.xyz * 0.550000011920928955078125, mix(_136.fa_env_horizon.xyz, _136.fa_env_sky.xyz, float3(powr(fast::clamp(d.y * (1.0 - (0.699999988079071044921875 * _393)), 0.0, 1.0), 0.550000011920928955078125))), float3(smoothstep((-0.0500000007450580596923828125) - _426, 0.0500000007450580596923828125 + _426, d.y))), ((_136.fa_env_sky.xyz + _136.fa_env_horizon.xyz) * 0.5) * 0.800000011920928955078125, float3(_393 * 0.60000002384185791015625));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _136 [[buffer(1)]], constant fa_lights& _636 [[buffer(2)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    float3 _895 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _895 = -_895;\n    }\n    float3 _533 = _136.fa_camera_pos.xyz - in.fa_world_pos;\n    float3 _534 = fast::normalize(_533);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _895, in.fa_world_tangent, in.fa_uv, _534, short(gl_FrontFacing) };\n    Surface _539 = fa_standard_surface(param, fa_tex, fa_smp, _136, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _914 = _539.albedo;\n    float _915 = _539.alpha;\n    float3 _916 = _539.normal;\n    float _917 = _539.metallic;\n    float _918 = _539.roughness;\n    float _919 = _539.occlusion;\n    float3 _920 = _539.emission;\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _895, in.fa_world_tangent, in.fa_uv, _534, short(gl_FrontFacing) };\n    Surface param_2 = _539;\n    surface(param_1, param_2);\n    _914 = param_2.albedo;\n    _915 = param_2.alpha;\n    _916 = param_2.normal;\n    _917 = param_2.metallic;\n    _918 = param_2.roughness;\n    _919 = param_2.occlusion;\n    _920 = param_2.emission;\n    float3 result;\n    if (_136.fa_emissive.w > 0.5)\n    {\n        result = _914;\n    }\n    else\n    {\n        float3 _561 = fast::normalize(_916);\n        float _568 = fast::clamp(_917, 0.0, 1.0);\n        float _572 = fast::clamp(_918, 0.0500000007450580596923828125, 1.0);\n        float _576 = _572 * _572;\n        float _580 = _576 * _576;\n        float _586 = fast::max(dot(_561, _534), 9.9999997473787516355514526367188e-05);\n        float3 _592 = _914 * (1.0 - _568);\n        float3 _600 = mix(float3(0.039999999105930328369140625), _914, float3(_568));\n        float3 lit = (_136.fa_ambient.xyz * _592) * _919;\n        int _613 = int(_136.fa_counts.x);\n        float3 l;\n        for (int li = 0; li < 32; li++)\n        {\n            if (li >= _613)\n            {\n                break;\n            }\n            float atten = 1.0;\n            bool _642 = _636.fa_light_color[li].w < 0.5;\n            if (_642)\n            {\n                l = fast::normalize(_636.fa_light_pos[li].xyz);\n            }\n            else\n            {\n                float3 _659 = _636.fa_light_pos[li].xyz - in.fa_world_pos;\n                float _662 = length(_659);\n                l = _659 / float3(fast::max(_662, 9.9999997473787516355514526367188e-05));\n                float _677 = _662 / fast::max(_636.fa_light_pos[li].w, 0.001000000047497451305389404296875);\n                float _683 = fast::clamp(1.0 - (_677 * _677), 0.0, 1.0);\n                atten = _683 * _683;\n                if (_636.fa_light_color[li].w > 1.5)\n                {\n                    atten *= smoothstep(_636.fa_light_dir[li].w, mix(_636.fa_light_dir[li].w, 1.0, 0.25), dot(-l, fast::normalize(_636.fa_light_dir[li].xyz)));\n                }\n            }\n            float _717 = fast::max(dot(_561, l), 0.0);\n            if (_642 && (li == 0))\n            {\n                float3 param_3 = _895;\n                float3 param_4 = l;\n                atten *= fa_shadow_factor(param_3, param_4, _136, in.fa_shadow_pos, fa_shadow_tex, fa_shadow_smp);\n            }\n            float3 _736 = fast::normalize(l + _534);\n            float _741 = fast::max(dot(_561, _736), 0.0);\n            float _754 = ((_741 * _741) * (_580 - 1.0)) + 1.0;\n            lit += (((_592 + (((_600 + ((float3(1.0) - _600) * powr(1.0 - fast::max(dot(_534, _736), 0.0), 5.0))) * (((_580 / ((3.1415927410125732421875 * _754) * _754)) * (0.5 / fast::max(mix((2.0 * _717) * _586, _717 + _586, _576), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _717))) * _636.fa_light_color[li].xyz) * (_717 * atten));\n        }\n        float param_5 = _572;\n        float param_6 = _586;\n        float2 _822 = fa_env_brdf(param_5, param_6);\n        float3 param_7 = reflect(-_534, _561);\n        float param_8 = _572;\n        float3 _840 = lit;\n        float3 _841 = _840 + ((fa_environment(param_7, param_8, _136) * ((_600 * _822.x) + float3(_822.y))) * _919);\n        lit = _841;\n        result = _841;\n    }\n    result += _920;\n    if (_136.fa_fog.w > 0.0)\n    {\n        float _865 = _136.fa_fog.w * length(_533);\n        result = mix(result, _136.fa_fog.xyz, float3(fast::clamp(1.0 - exp((-_865) * _865), 0.0, 1.0)));\n    }\n    out.fa_frag_color = float4(result, _915);\n    return out;\n}\n\n",
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
            "slot": 4,
            "stage": "vertex",
            "size": 16,
            "struct_name": "fa_material_vs",
            "inst_name": "_41",
            "msl_buffer_n": 4
          },
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_141",
            "msl_buffer_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 192,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_136",
            "msl_buffer_n": 1
          },
          {
            "slot": 2,
            "stage": "fragment",
            "size": 1536,
            "struct_name": "fa_lights",
            "inst_name": "_636",
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float3 object_pos;\n};\n\nstruct fa_material_vs\n{\n    packed_float3 offset;\n    float fa_pad0;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_shadow_pos [[user(locn4)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_inst_m0 [[attribute(4)]];\n    float4 fa_inst_m1 [[attribute(5)]];\n    float4 fa_inst_m2 [[attribute(6)]];\n    float4 fa_inst_m3 [[attribute(7)]];\n    float4 fa_joints [[attribute(8)]];\n    float4 fa_weights [[attribute(9)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _190)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _181 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_190.fa_joint_rows[_181] * weights[i]);\n        r1 += (_190.fa_joint_rows[_181 + 1] * weights[i]);\n        r2 += (_190.fa_joint_rows[_181 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, constant fa_mesh_vs_params& _146)\n{\n    float3 _84 = cross(model[1].xyz, model[2].xyz);\n    float _90 = (dot(model[0].xyz, _84) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_84 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _90, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _90), texcoord0 * _146.fa_uv_scale.xy, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread VertexData& v, constant fa_material_vs& _46)\n{\n    v.world_pos += float3(_46.offset);\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, constant fa_material_vs& _46, constant fa_mesh_vs_params& _146, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_shadow_pos, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    VertexData param_5 = fa_vertex_data(param, param_1, param_2, param_3, param_4, _146);\n    vertex0(param_5, _46);\n    float4 _289 = float4(param_5.world_pos, 1.0);\n    fa_world_pos = param_5.world_pos;\n    fa_world_normal = param_5.world_normal;\n    fa_world_tangent = param_5.world_tangent;\n    fa_uv = param_5.uv;\n    fa_shadow_pos = _146.fa_light_vp * _289;\n    gl_Position = _146.fa_view_proj * _289;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _146 [[buffer(0)]], constant fa_skin& _190 [[buffer(3)]], constant fa_material_vs& _46 [[buffer(4)]])\n{\n    main0_out out = {};\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float4x4 param_2 = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _190);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, _46, _146, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_shadow_pos, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n};\n\nstruct fa_lights\n{\n    float4 fa_light_pos[32];\n    float4 fa_light_color[32];\n    float4 fa_light_dir[32];\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_shadow_pos [[user(locn4)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _52;\n    if (bool(i.front_facing))\n    {\n        _52 = i.world_normal;\n    }\n    else\n    {\n        _52 = -i.world_normal;\n    }\n    float3 _77 = fast::normalize(i.world_tangent.xyz - (_52 * dot(_52, i.world_tangent.xyz)));\n    float3 _105 = fast::normalize(((_77 * m.x) + ((cross(_52, _77) * i.world_tangent.w) * m.y)) + (_52 * m.z));\n    float3 _108;\n    if (bool(i.front_facing))\n    {\n        _108 = _105;\n    }\n    else\n    {\n        _108 = -_105;\n    }\n    return _108;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _136, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 _133 = fa_tex.sample(fa_smp, i.uv);\n    float4 _140 = _133 * _136.fa_base_color;\n    float3 _945 = i.world_normal;\n    if (_136.fa_maps.z > 0.5)\n    {\n        float3 _173 = (fa_normal_tex.sample(fa_smp, i.uv).xyz * 2.0) - float3(1.0);\n        float2 _178 = _173.xy * _136.fa_maps.x;\n        float3 _962 = _173;\n        _962.x = _178.x;\n        _962.y = _178.y;\n        SurfaceInput param = i;\n        float3 param_1 = _962;\n        _945 = fa_tangent_normal(param, param_1);\n    }\n    float4 _196 = fa_mr_tex.sample(fa_smp, i.uv);\n    return Surface{ _140.xyz, _140.w, _945, fast::clamp(_136.fa_pbr.x * _196.z, 0.0, 1.0), fast::clamp(_136.fa_pbr.y * _196.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_136.fa_maps.y * (fa_occlusion_tex.sample(fa_smp, i.uv).x - 1.0)), _136.fa_emissive.xyz + (_136.fa_model_emissive.xyz * fa_emissive_tex.sample(fa_smp, i.uv).xyz) };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _136, thread float4& fa_shadow_pos, texture2d<float> fa_shadow_tex, sampler fa_shadow_smp)\n{\n    if (_136.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    float3 _263 = fa_shadow_pos.xyz / float3(fa_shadow_pos.w);\n    float3 p = _263;\n    float2 suv = (_263.xy * 0.5) + float2(0.5);\n    if (_136.fa_counts.z > 0.5)\n    {\n        float3 _967 = p;\n        _967.z = (_967.z * 0.5) + 0.5;\n        p = _967;\n    }\n    else\n    {\n        float2 _970 = suv;\n        _970.y = 1.0 - _970.y;\n        suv = _970;\n    }\n    bool _290 = suv.x < 0.0;\n    bool _297;\n    if (!_290)\n    {\n        _297 = suv.x > 1.0;\n    }\n    else\n    {\n        _297 = _290;\n    }\n    bool _304;\n    if (!_297)\n    {\n        _304 = suv.y < 0.0;\n    }\n    else\n    {\n        _304 = _297;\n    }\n    bool _311;\n    if (!_304)\n    {\n        _311 = suv.y > 1.0;\n    }\n    else\n    {\n        _311 = _304;\n    }\n    bool _318;\n    if (!_311)\n    {\n        _318 = p.z > 1.0;\n    }\n    else\n    {\n        _318 = _311;\n    }\n    if (_318)\n    {\n        return 1.0;\n    }\n    float _332 = _136.fa_pbr.w * (1.0 + (2.0 * (1.0 - fast::clamp(dot(n, l), 0.0, 1.0))));\n    float lit = 0.0;\n    for (int ix = -1; ix <= 1; ix++)\n    {\n        for (int iy = -1; iy <= 1; iy++)\n        {\n            lit += float((p.z - _332) <= fa_shadow_tex.sample(fa_shadow_smp, (suv + (float2(float(ix), float(iy)) * _136.fa_counts.y)), level(0.0)).x);\n        }\n    }\n    return lit * 0.111111111938953399658203125;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_env_brdf(thread const float& rough, thread const float& ndv)\n{\n    float4 _473 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _476 = _473.x;\n    return (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_476 * _476, exp2((-9.27999973297119140625) * ndv)) * _476) + _473.y)) + _473.zw;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_environment(thread const float3& d, thread const float& rough, constant fa_mesh_fs_params& _136)\n{\n    float _393 = rough * rough;\n    float _426 = 0.60000002384185791015625 * _393;\n    return mix(mix(_136.fa_env_horizon.xyz * 0.550000011920928955078125, mix(_136.fa_env_horizon.xyz, _136.fa_env_sky.xyz, float3(powr(fast::clamp(d.y * (1.0 - (0.699999988079071044921875 * _393)), 0.0, 1.0), 0.550000011920928955078125))), float3(smoothstep((-0.0500000007450580596923828125) - _426, 0.0500000007450580596923828125 + _426, d.y))), ((_136.fa_env_sky.xyz + _136.fa_env_horizon.xyz) * 0.5) * 0.800000011920928955078125, float3(_393 * 0.60000002384185791015625));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _136 [[buffer(1)]], constant fa_lights& _636 [[buffer(2)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    float3 _895 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _895 = -_895;\n    }\n    float3 _533 = _136.fa_camera_pos.xyz - in.fa_world_pos;\n    float3 _534 = fast::normalize(_533);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _895, in.fa_world_tangent, in.fa_uv, _534, short(gl_FrontFacing) };\n    Surface _539 = fa_standard_surface(param, fa_tex, fa_smp, _136, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _914 = _539.albedo;\n    float _915 = _539.alpha;\n    float3 _916 = _539.normal;\n    float _917 = _539.metallic;\n    float _918 = _539.roughness;\n    float _919 = _539.occlusion;\n    float3 _920 = _539.emission;\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _895, in.fa_world_tangent, in.fa_uv, _534, short(gl_FrontFacing) };\n    Surface param_2 = _539;\n    surface(param_1, param_2);\n    _914 = param_2.albedo;\n    _915 = param_2.alpha;\n    _916 = param_2.normal;\n    _917 = param_2.metallic;\n    _918 = param_2.roughness;\n    _919 = param_2.occlusion;\n    _920 = param_2.emission;\n    float3 result;\n    if (_136.fa_emissive.w > 0.5)\n    {\n        result = _914;\n    }\n    else\n    {\n        float3 _561 = fast::normalize(_916);\n        float _568 = fast::clamp(_917, 0.0, 1.0);\n        float _572 = fast::clamp(_918, 0.0500000007450580596923828125, 1.0);\n        float _576 = _572 * _572;\n        float _580 = _576 * _576;\n        float _586 = fast::max(dot(_561, _534), 9.9999997473787516355514526367188e-05);\n        float3 _592 = _914 * (1.0 - _568);\n        float3 _600 = mix(float3(0.039999999105930328369140625), _914, float3(_568));\n        float3 lit = (_136.fa_ambient.xyz * _592) * _919;\n        int _613 = int(_136.fa_counts.x);\n        float3 l;\n        for (int li = 0; li < 32; li++)\n        {\n            if (li >= _613)\n            {\n                break;\n            }\n            float atten = 1.0;\n            bool _642 = _636.fa_light_color[li].w < 0.5;\n            if (_642)\n            {\n                l = fast::normalize(_636.fa_light_pos[li].xyz);\n            }\n            else\n            {\n                float3 _659 = _636.fa_light_pos[li].xyz - in.fa_world_pos;\n                float _662 = length(_659);\n                l = _659 / float3(fast::max(_662, 9.9999997473787516355514526367188e-05));\n                float _677 = _662 / fast::max(_636.fa_light_pos[li].w, 0.001000000047497451305389404296875);\n                float _683 = fast::clamp(1.0 - (_677 * _677), 0.0, 1.0);\n                atten = _683 * _683;\n                if (_636.fa_light_color[li].w > 1.5)\n                {\n                    atten *= smoothstep(_636.fa_light_dir[li].w, mix(_636.fa_light_dir[li].w, 1.0, 0.25), dot(-l, fast::normalize(_636.fa_light_dir[li].xyz)));\n                }\n            }\n            float _717 = fast::max(dot(_561, l), 0.0);\n            if (_642 && (li == 0))\n            {\n                float3 param_3 = _895;\n                float3 param_4 = l;\n                atten *= fa_shadow_factor(param_3, param_4, _136, in.fa_shadow_pos, fa_shadow_tex, fa_shadow_smp);\n            }\n            float3 _736 = fast::normalize(l + _534);\n            float _741 = fast::max(dot(_561, _736), 0.0);\n            float _754 = ((_741 * _741) * (_580 - 1.0)) + 1.0;\n            lit += (((_592 + (((_600 + ((float3(1.0) - _600) * powr(1.0 - fast::max(dot(_534, _736), 0.0), 5.0))) * (((_580 / ((3.1415927410125732421875 * _754) * _754)) * (0.5 / fast::max(mix((2.0 * _717) * _586, _717 + _586, _576), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _717))) * _636.fa_light_color[li].xyz) * (_717 * atten));\n        }\n        float param_5 = _572;\n        float param_6 = _586;\n        float2 _822 = fa_env_brdf(param_5, param_6);\n        float3 param_7 = reflect(-_534, _561);\n        float param_8 = _572;\n        float3 _840 = lit;\n        float3 _841 = _840 + ((fa_environment(param_7, param_8, _136) * ((_600 * _822.x) + float3(_822.y))) * _919);\n        lit = _841;\n        result = _841;\n    }\n    result += _920;\n    if (_136.fa_fog.w > 0.0)\n    {\n        float _865 = _136.fa_fog.w * length(_533);\n        result = mix(result, _136.fa_fog.xyz, float3(fast::clamp(1.0 - exp((-_865) * _865), 0.0, 1.0)));\n    }\n    out.fa_frag_color = float4(result, _915);\n    return out;\n}\n\n",
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
            "slot": 4,
            "stage": "vertex",
            "size": 16,
            "struct_name": "fa_material_vs",
            "inst_name": "_46",
            "msl_buffer_n": 4
          },
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_146",
            "msl_buffer_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_190",
            "msl_buffer_n": 3
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 192,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_136",
            "msl_buffer_n": 1
          },
          {
            "slot": 2,
            "stage": "fragment",
            "size": 1536,
            "struct_name": "fa_lights",
            "inst_name": "_636",
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
    "shadow": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float3 object_pos;\n};\n\nstruct fa_material_vs\n{\n    packed_float3 offset;\n    float fa_pad0;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float4 fa_inst_m0 [[attribute(1)]];\n    float4 fa_inst_m1 [[attribute(2)]];\n    float4 fa_inst_m2 [[attribute(3)]];\n    float4 fa_inst_m3 [[attribute(4)]];\n    float3 fa_normal [[attribute(5)]];\n    float2 fa_texcoord0 [[attribute(6)]];\n    float4 fa_tangent [[attribute(7)]];\n};\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, constant fa_mesh_vs_params& _133)\n{\n    float3 _71 = cross(model[1].xyz, model[2].xyz);\n    float _77 = (dot(model[0].xyz, _71) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_71 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _77, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _77), texcoord0 * _133.fa_uv_scale.xy, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread VertexData& v, constant fa_material_vs& _33)\n{\n    v.world_pos += float3(_33.offset);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _133 [[buffer(0)]], constant fa_material_vs& _33 [[buffer(4)]])\n{\n    main0_out out = {};\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    VertexData param_5 = fa_vertex_data(param, param_1, param_2, param_3, param_4, _133);\n    vertex0(param_5, _33);\n    out.gl_Position = _133.fa_light_vp * float4(param_5.world_pos, 1.0);\n    return out;\n}\n\n",
      "fs": "#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nfragment main0_out main0(float4 gl_FragCoord [[position]])\n{\n    main0_out out = {};\n    out.fa_frag_color = float4(gl_FragCoord.z, 0.0, 0.0, 1.0);\n    return out;\n}\n\n",
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
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 2,
            "type": "vec4",
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
            "type": "vec3",
            "base_type": "Float"
          },
          {
            "slot": 6,
            "type": "vec2",
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
            "slot": 4,
            "stage": "vertex",
            "size": 16,
            "struct_name": "fa_material_vs",
            "inst_name": "_33",
            "msl_buffer_n": 4
          },
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_133",
            "msl_buffer_n": 0
          }
        ]
      }
    },
    "shadow_skin": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float3 object_pos;\n};\n\nstruct fa_material_vs\n{\n    packed_float3 offset;\n    float fa_pad0;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct main0_out\n{\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float4 fa_inst_m0 [[attribute(1)]];\n    float4 fa_inst_m1 [[attribute(2)]];\n    float4 fa_inst_m2 [[attribute(3)]];\n    float4 fa_inst_m3 [[attribute(4)]];\n    float4 fa_joints [[attribute(5)]];\n    float4 fa_weights [[attribute(6)]];\n    float3 fa_normal [[attribute(7)]];\n    float2 fa_texcoord0 [[attribute(8)]];\n    float4 fa_tangent [[attribute(9)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _182)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _173 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_182.fa_joint_rows[_173] * weights[i]);\n        r1 += (_182.fa_joint_rows[_173 + 1] * weights[i]);\n        r2 += (_182.fa_joint_rows[_173 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, constant fa_mesh_vs_params& _138)\n{\n    float3 _76 = cross(model[1].xyz, model[2].xyz);\n    float _82 = (dot(model[0].xyz, _76) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_76 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _82, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _82), texcoord0 * _138.fa_uv_scale.xy, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread VertexData& v, constant fa_material_vs& _38)\n{\n    v.world_pos += float3(_38.offset);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _138 [[buffer(0)]], constant fa_skin& _182 [[buffer(3)]], constant fa_material_vs& _38 [[buffer(4)]])\n{\n    main0_out out = {};\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float4x4 param_2 = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _182);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    VertexData param_7 = fa_vertex_data(param_2, param_3, param_4, param_5, param_6, _138);\n    vertex0(param_7, _38);\n    out.gl_Position = _138.fa_light_vp * float4(param_7.world_pos, 1.0);\n    return out;\n}\n\n",
      "fs": "#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nfragment main0_out main0(float4 gl_FragCoord [[position]])\n{\n    main0_out out = {};\n    out.fa_frag_color = float4(gl_FragCoord.z, 0.0, 0.0, 1.0);\n    return out;\n}\n\n",
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
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 2,
            "type": "vec4",
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
            "type": "vec3",
            "base_type": "Float"
          },
          {
            "slot": 8,
            "type": "vec2",
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
            "slot": 4,
            "stage": "vertex",
            "size": 16,
            "struct_name": "fa_material_vs",
            "inst_name": "_38",
            "msl_buffer_n": 4
          },
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_138",
            "msl_buffer_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_182",
            "msl_buffer_n": 3
          }
        ]
      }
    }
  }
}
