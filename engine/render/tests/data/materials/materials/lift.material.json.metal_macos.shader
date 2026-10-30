{
  "format": "factoria.shader/1",
  "engine": "0.1.6",
  "template": "a75dcd870d51444499f61f3cb2010a1b06d96d8916439ce459176478546f3cd8",
  "slang": "metal_macos",
  "params": [
    "offset"
  ],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_material_vs\n{\n    packed_float3 offset;\n    float fa_pad0;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float4 fa_shadow_pos [[user(locn5)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n};\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _143)\n{\n    float3 _81 = cross(model[1].xyz, model[2].xyz);\n    float _87 = (dot(model[0].xyz, _81) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_81 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _87, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _87), texcoord0 * _143.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread VertexData& v, constant fa_material_vs& _43)\n{\n    v.world_pos += float3(_43.offset);\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_material_vs& _43, constant fa_mesh_vs_params& _143, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& fa_shadow_pos, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _143);\n    vertex0(param_6, _43);\n    float4 _183 = float4(param_6.world_pos, 1.0);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_shadow_pos = _143.fa_light_vp * _183;\n    gl_Position = _143.fa_view_proj * _183;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _143 [[buffer(0)]], constant fa_material_vs& _43 [[buffer(4)]])\n{\n    main0_out out = {};\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5, _43, _143, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_shadow_pos, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n};\n\nstruct fa_lights\n{\n    float4 fa_light_pos[32];\n    float4 fa_light_color[32];\n    float4 fa_light_dir[32];\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float4 fa_shadow_pos [[user(locn5)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _52;\n    if (bool(i.front_facing))\n    {\n        _52 = i.world_normal;\n    }\n    else\n    {\n        _52 = -i.world_normal;\n    }\n    float3 _77 = fast::normalize(i.world_tangent.xyz - (_52 * dot(_52, i.world_tangent.xyz)));\n    float3 _105 = fast::normalize(((_77 * m.x) + ((cross(_52, _77) * i.world_tangent.w) * m.y)) + (_52 * m.z));\n    float3 _108;\n    if (bool(i.front_facing))\n    {\n        _108 = _105;\n    }\n    else\n    {\n        _108 = -_105;\n    }\n    return _108;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _136, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 _133 = fa_tex.sample(fa_smp, i.uv);\n    float4 _144 = (_133 * _136.fa_base_color) * i.vertex_color;\n    float3 _954 = i.world_normal;\n    if (_136.fa_maps.z > 0.5)\n    {\n        float3 _176 = (fa_normal_tex.sample(fa_smp, i.uv).xyz * 2.0) - float3(1.0);\n        float2 _181 = _176.xy * _136.fa_maps.x;\n        float3 _971 = _176;\n        _971.x = _181.x;\n        _971.y = _181.y;\n        SurfaceInput param = i;\n        float3 param_1 = _971;\n        _954 = fa_tangent_normal(param, param_1);\n    }\n    float4 _199 = fa_mr_tex.sample(fa_smp, i.uv);\n    return Surface{ _144.xyz, _144.w, _954, fast::clamp(_136.fa_pbr.x * _199.z, 0.0, 1.0), fast::clamp(_136.fa_pbr.y * _199.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_136.fa_maps.y * (fa_occlusion_tex.sample(fa_smp, i.uv).x - 1.0)), _136.fa_emissive.xyz + (_136.fa_model_emissive.xyz * fa_emissive_tex.sample(fa_smp, i.uv).xyz) };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _136, thread float4& fa_shadow_pos, texture2d<float> fa_shadow_tex, sampler fa_shadow_smp)\n{\n    if (_136.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    float3 _266 = fa_shadow_pos.xyz / float3(fa_shadow_pos.w);\n    float3 p = _266;\n    float2 suv = (_266.xy * 0.5) + float2(0.5);\n    if (_136.fa_counts.z > 0.5)\n    {\n        float3 _976 = p;\n        _976.z = (_976.z * 0.5) + 0.5;\n        p = _976;\n    }\n    else\n    {\n        float2 _979 = suv;\n        _979.y = 1.0 - _979.y;\n        suv = _979;\n    }\n    bool _293 = suv.x < 0.0;\n    bool _300;\n    if (!_293)\n    {\n        _300 = suv.x > 1.0;\n    }\n    else\n    {\n        _300 = _293;\n    }\n    bool _307;\n    if (!_300)\n    {\n        _307 = suv.y < 0.0;\n    }\n    else\n    {\n        _307 = _300;\n    }\n    bool _314;\n    if (!_307)\n    {\n        _314 = suv.y > 1.0;\n    }\n    else\n    {\n        _314 = _307;\n    }\n    bool _321;\n    if (!_314)\n    {\n        _321 = p.z > 1.0;\n    }\n    else\n    {\n        _321 = _314;\n    }\n    if (_321)\n    {\n        return 1.0;\n    }\n    float _335 = _136.fa_pbr.w * (1.0 + (2.0 * (1.0 - fast::clamp(dot(n, l), 0.0, 1.0))));\n    float lit = 0.0;\n    for (int ix = -1; ix <= 1; ix++)\n    {\n        for (int iy = -1; iy <= 1; iy++)\n        {\n            lit += float((p.z - _335) <= fa_shadow_tex.sample(fa_shadow_smp, (suv + (float2(float(ix), float(iy)) * _136.fa_counts.y)), level(0.0)).x);\n        }\n    }\n    return lit * 0.111111111938953399658203125;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_env_brdf(thread const float& rough, thread const float& ndv)\n{\n    float4 _476 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _479 = _476.x;\n    return (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_479 * _479, exp2((-9.27999973297119140625) * ndv)) * _479) + _476.y)) + _476.zw;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_environment(thread const float3& d, thread const float& rough, constant fa_mesh_fs_params& _136)\n{\n    float _396 = rough * rough;\n    float _429 = 0.60000002384185791015625 * _396;\n    return mix(mix(_136.fa_env_horizon.xyz * 0.550000011920928955078125, mix(_136.fa_env_horizon.xyz, _136.fa_env_sky.xyz, float3(powr(fast::clamp(d.y * (1.0 - (0.699999988079071044921875 * _396)), 0.0, 1.0), 0.550000011920928955078125))), float3(smoothstep((-0.0500000007450580596923828125) - _429, 0.0500000007450580596923828125 + _429, d.y))), ((_136.fa_env_sky.xyz + _136.fa_env_horizon.xyz) * 0.5) * 0.800000011920928955078125, float3(_396 * 0.60000002384185791015625));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _136 [[buffer(1)]], constant fa_lights& _642 [[buffer(2)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    float3 _901 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _901 = -_901;\n    }\n    float3 _539 = _136.fa_camera_pos.xyz - in.fa_world_pos;\n    float3 _540 = fast::normalize(_539);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _901, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _540, short(gl_FrontFacing) };\n    Surface _545 = fa_standard_surface(param, fa_tex, fa_smp, _136, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _923 = _545.albedo;\n    float _924 = _545.alpha;\n    float3 _925 = _545.normal;\n    float _926 = _545.metallic;\n    float _927 = _545.roughness;\n    float _928 = _545.occlusion;\n    float3 _929 = _545.emission;\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _901, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _540, short(gl_FrontFacing) };\n    Surface param_2 = _545;\n    surface(param_1, param_2);\n    _923 = param_2.albedo;\n    _924 = param_2.alpha;\n    _925 = param_2.normal;\n    _926 = param_2.metallic;\n    _927 = param_2.roughness;\n    _928 = param_2.occlusion;\n    _929 = param_2.emission;\n    float3 result;\n    if (_136.fa_emissive.w > 0.5)\n    {\n        result = _923;\n    }\n    else\n    {\n        float3 _567 = fast::normalize(_925);\n        float _574 = fast::clamp(_926, 0.0, 1.0);\n        float _578 = fast::clamp(_927, 0.0500000007450580596923828125, 1.0);\n        float _582 = _578 * _578;\n        float _586 = _582 * _582;\n        float _592 = fast::max(dot(_567, _540), 9.9999997473787516355514526367188e-05);\n        float3 _598 = _923 * (1.0 - _574);\n        float3 _606 = mix(float3(0.039999999105930328369140625), _923, float3(_574));\n        float3 lit = (_136.fa_ambient.xyz * _598) * _928;\n        int _619 = int(_136.fa_counts.x);\n        float3 l;\n        for (int li = 0; li < 32; li++)\n        {\n            if (li >= _619)\n            {\n                break;\n            }\n            float atten = 1.0;\n            bool _648 = _642.fa_light_color[li].w < 0.5;\n            if (_648)\n            {\n                l = fast::normalize(_642.fa_light_pos[li].xyz);\n            }\n            else\n            {\n                float3 _665 = _642.fa_light_pos[li].xyz - in.fa_world_pos;\n                float _668 = length(_665);\n                l = _665 / float3(fast::max(_668, 9.9999997473787516355514526367188e-05));\n                float _683 = _668 / fast::max(_642.fa_light_pos[li].w, 0.001000000047497451305389404296875);\n                float _689 = fast::clamp(1.0 - (_683 * _683), 0.0, 1.0);\n                atten = _689 * _689;\n                if (_642.fa_light_color[li].w > 1.5)\n                {\n                    atten *= smoothstep(_642.fa_light_dir[li].w, mix(_642.fa_light_dir[li].w, 1.0, 0.25), dot(-l, fast::normalize(_642.fa_light_dir[li].xyz)));\n                }\n            }\n            float _723 = fast::max(dot(_567, l), 0.0);\n            if (_648 && (li == 0))\n            {\n                float3 param_3 = _901;\n                float3 param_4 = l;\n                atten *= fa_shadow_factor(param_3, param_4, _136, in.fa_shadow_pos, fa_shadow_tex, fa_shadow_smp);\n            }\n            float3 _742 = fast::normalize(l + _540);\n            float _747 = fast::max(dot(_567, _742), 0.0);\n            float _760 = ((_747 * _747) * (_586 - 1.0)) + 1.0;\n            lit += (((_598 + (((_606 + ((float3(1.0) - _606) * powr(1.0 - fast::max(dot(_540, _742), 0.0), 5.0))) * (((_586 / ((3.1415927410125732421875 * _760) * _760)) * (0.5 / fast::max(mix((2.0 * _723) * _592, _723 + _592, _582), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _723))) * _642.fa_light_color[li].xyz) * (_723 * atten));\n        }\n        float param_5 = _578;\n        float param_6 = _592;\n        float2 _828 = fa_env_brdf(param_5, param_6);\n        float3 param_7 = reflect(-_540, _567);\n        float param_8 = _578;\n        float3 _846 = lit;\n        float3 _847 = _846 + ((fa_environment(param_7, param_8, _136) * ((_606 * _828.x) + float3(_828.y))) * _928);\n        lit = _847;\n        result = _847;\n    }\n    result += _929;\n    if (_136.fa_fog.w > 0.0)\n    {\n        float _871 = _136.fa_fog.w * length(_539);\n        result = mix(result, _136.fa_fog.xyz, float3(fast::clamp(1.0 - exp((-_871) * _871), 0.0, 1.0)));\n    }\n    out.fa_frag_color = float4(result, _924);\n    return out;\n}\n\n",
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
            "slot": 4,
            "stage": "vertex",
            "size": 16,
            "struct_name": "fa_material_vs",
            "inst_name": "_43",
            "msl_buffer_n": 4
          },
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_143",
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
            "inst_name": "_642",
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_material_vs\n{\n    packed_float3 offset;\n    float fa_pad0;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float4 fa_shadow_pos [[user(locn5)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n    float4 fa_joints [[attribute(9)]];\n    float4 fa_weights [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _195)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _186 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_195.fa_joint_rows[_186] * weights[i]);\n        r1 += (_195.fa_joint_rows[_186 + 1] * weights[i]);\n        r2 += (_195.fa_joint_rows[_186 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _148)\n{\n    float3 _86 = cross(model[1].xyz, model[2].xyz);\n    float _92 = (dot(model[0].xyz, _86) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_86 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _92, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _92), texcoord0 * _148.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread VertexData& v, constant fa_material_vs& _48)\n{\n    v.world_pos += float3(_48.offset);\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_material_vs& _48, constant fa_mesh_vs_params& _148, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& fa_shadow_pos, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _148);\n    vertex0(param_6, _48);\n    float4 _296 = float4(param_6.world_pos, 1.0);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_shadow_pos = _148.fa_light_vp * _296;\n    gl_Position = _148.fa_view_proj * _296;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _148 [[buffer(0)]], constant fa_skin& _195 [[buffer(3)]], constant fa_material_vs& _48 [[buffer(4)]])\n{\n    main0_out out = {};\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float4x4 param_2 = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _195);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7, _48, _148, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_shadow_pos, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n};\n\nstruct fa_lights\n{\n    float4 fa_light_pos[32];\n    float4 fa_light_color[32];\n    float4 fa_light_dir[32];\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float4 fa_shadow_pos [[user(locn5)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _52;\n    if (bool(i.front_facing))\n    {\n        _52 = i.world_normal;\n    }\n    else\n    {\n        _52 = -i.world_normal;\n    }\n    float3 _77 = fast::normalize(i.world_tangent.xyz - (_52 * dot(_52, i.world_tangent.xyz)));\n    float3 _105 = fast::normalize(((_77 * m.x) + ((cross(_52, _77) * i.world_tangent.w) * m.y)) + (_52 * m.z));\n    float3 _108;\n    if (bool(i.front_facing))\n    {\n        _108 = _105;\n    }\n    else\n    {\n        _108 = -_105;\n    }\n    return _108;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _136, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 _133 = fa_tex.sample(fa_smp, i.uv);\n    float4 _144 = (_133 * _136.fa_base_color) * i.vertex_color;\n    float3 _954 = i.world_normal;\n    if (_136.fa_maps.z > 0.5)\n    {\n        float3 _176 = (fa_normal_tex.sample(fa_smp, i.uv).xyz * 2.0) - float3(1.0);\n        float2 _181 = _176.xy * _136.fa_maps.x;\n        float3 _971 = _176;\n        _971.x = _181.x;\n        _971.y = _181.y;\n        SurfaceInput param = i;\n        float3 param_1 = _971;\n        _954 = fa_tangent_normal(param, param_1);\n    }\n    float4 _199 = fa_mr_tex.sample(fa_smp, i.uv);\n    return Surface{ _144.xyz, _144.w, _954, fast::clamp(_136.fa_pbr.x * _199.z, 0.0, 1.0), fast::clamp(_136.fa_pbr.y * _199.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_136.fa_maps.y * (fa_occlusion_tex.sample(fa_smp, i.uv).x - 1.0)), _136.fa_emissive.xyz + (_136.fa_model_emissive.xyz * fa_emissive_tex.sample(fa_smp, i.uv).xyz) };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _136, thread float4& fa_shadow_pos, texture2d<float> fa_shadow_tex, sampler fa_shadow_smp)\n{\n    if (_136.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    float3 _266 = fa_shadow_pos.xyz / float3(fa_shadow_pos.w);\n    float3 p = _266;\n    float2 suv = (_266.xy * 0.5) + float2(0.5);\n    if (_136.fa_counts.z > 0.5)\n    {\n        float3 _976 = p;\n        _976.z = (_976.z * 0.5) + 0.5;\n        p = _976;\n    }\n    else\n    {\n        float2 _979 = suv;\n        _979.y = 1.0 - _979.y;\n        suv = _979;\n    }\n    bool _293 = suv.x < 0.0;\n    bool _300;\n    if (!_293)\n    {\n        _300 = suv.x > 1.0;\n    }\n    else\n    {\n        _300 = _293;\n    }\n    bool _307;\n    if (!_300)\n    {\n        _307 = suv.y < 0.0;\n    }\n    else\n    {\n        _307 = _300;\n    }\n    bool _314;\n    if (!_307)\n    {\n        _314 = suv.y > 1.0;\n    }\n    else\n    {\n        _314 = _307;\n    }\n    bool _321;\n    if (!_314)\n    {\n        _321 = p.z > 1.0;\n    }\n    else\n    {\n        _321 = _314;\n    }\n    if (_321)\n    {\n        return 1.0;\n    }\n    float _335 = _136.fa_pbr.w * (1.0 + (2.0 * (1.0 - fast::clamp(dot(n, l), 0.0, 1.0))));\n    float lit = 0.0;\n    for (int ix = -1; ix <= 1; ix++)\n    {\n        for (int iy = -1; iy <= 1; iy++)\n        {\n            lit += float((p.z - _335) <= fa_shadow_tex.sample(fa_shadow_smp, (suv + (float2(float(ix), float(iy)) * _136.fa_counts.y)), level(0.0)).x);\n        }\n    }\n    return lit * 0.111111111938953399658203125;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_env_brdf(thread const float& rough, thread const float& ndv)\n{\n    float4 _476 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _479 = _476.x;\n    return (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_479 * _479, exp2((-9.27999973297119140625) * ndv)) * _479) + _476.y)) + _476.zw;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_environment(thread const float3& d, thread const float& rough, constant fa_mesh_fs_params& _136)\n{\n    float _396 = rough * rough;\n    float _429 = 0.60000002384185791015625 * _396;\n    return mix(mix(_136.fa_env_horizon.xyz * 0.550000011920928955078125, mix(_136.fa_env_horizon.xyz, _136.fa_env_sky.xyz, float3(powr(fast::clamp(d.y * (1.0 - (0.699999988079071044921875 * _396)), 0.0, 1.0), 0.550000011920928955078125))), float3(smoothstep((-0.0500000007450580596923828125) - _429, 0.0500000007450580596923828125 + _429, d.y))), ((_136.fa_env_sky.xyz + _136.fa_env_horizon.xyz) * 0.5) * 0.800000011920928955078125, float3(_396 * 0.60000002384185791015625));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _136 [[buffer(1)]], constant fa_lights& _642 [[buffer(2)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    float3 _901 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _901 = -_901;\n    }\n    float3 _539 = _136.fa_camera_pos.xyz - in.fa_world_pos;\n    float3 _540 = fast::normalize(_539);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _901, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _540, short(gl_FrontFacing) };\n    Surface _545 = fa_standard_surface(param, fa_tex, fa_smp, _136, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _923 = _545.albedo;\n    float _924 = _545.alpha;\n    float3 _925 = _545.normal;\n    float _926 = _545.metallic;\n    float _927 = _545.roughness;\n    float _928 = _545.occlusion;\n    float3 _929 = _545.emission;\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _901, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _540, short(gl_FrontFacing) };\n    Surface param_2 = _545;\n    surface(param_1, param_2);\n    _923 = param_2.albedo;\n    _924 = param_2.alpha;\n    _925 = param_2.normal;\n    _926 = param_2.metallic;\n    _927 = param_2.roughness;\n    _928 = param_2.occlusion;\n    _929 = param_2.emission;\n    float3 result;\n    if (_136.fa_emissive.w > 0.5)\n    {\n        result = _923;\n    }\n    else\n    {\n        float3 _567 = fast::normalize(_925);\n        float _574 = fast::clamp(_926, 0.0, 1.0);\n        float _578 = fast::clamp(_927, 0.0500000007450580596923828125, 1.0);\n        float _582 = _578 * _578;\n        float _586 = _582 * _582;\n        float _592 = fast::max(dot(_567, _540), 9.9999997473787516355514526367188e-05);\n        float3 _598 = _923 * (1.0 - _574);\n        float3 _606 = mix(float3(0.039999999105930328369140625), _923, float3(_574));\n        float3 lit = (_136.fa_ambient.xyz * _598) * _928;\n        int _619 = int(_136.fa_counts.x);\n        float3 l;\n        for (int li = 0; li < 32; li++)\n        {\n            if (li >= _619)\n            {\n                break;\n            }\n            float atten = 1.0;\n            bool _648 = _642.fa_light_color[li].w < 0.5;\n            if (_648)\n            {\n                l = fast::normalize(_642.fa_light_pos[li].xyz);\n            }\n            else\n            {\n                float3 _665 = _642.fa_light_pos[li].xyz - in.fa_world_pos;\n                float _668 = length(_665);\n                l = _665 / float3(fast::max(_668, 9.9999997473787516355514526367188e-05));\n                float _683 = _668 / fast::max(_642.fa_light_pos[li].w, 0.001000000047497451305389404296875);\n                float _689 = fast::clamp(1.0 - (_683 * _683), 0.0, 1.0);\n                atten = _689 * _689;\n                if (_642.fa_light_color[li].w > 1.5)\n                {\n                    atten *= smoothstep(_642.fa_light_dir[li].w, mix(_642.fa_light_dir[li].w, 1.0, 0.25), dot(-l, fast::normalize(_642.fa_light_dir[li].xyz)));\n                }\n            }\n            float _723 = fast::max(dot(_567, l), 0.0);\n            if (_648 && (li == 0))\n            {\n                float3 param_3 = _901;\n                float3 param_4 = l;\n                atten *= fa_shadow_factor(param_3, param_4, _136, in.fa_shadow_pos, fa_shadow_tex, fa_shadow_smp);\n            }\n            float3 _742 = fast::normalize(l + _540);\n            float _747 = fast::max(dot(_567, _742), 0.0);\n            float _760 = ((_747 * _747) * (_586 - 1.0)) + 1.0;\n            lit += (((_598 + (((_606 + ((float3(1.0) - _606) * powr(1.0 - fast::max(dot(_540, _742), 0.0), 5.0))) * (((_586 / ((3.1415927410125732421875 * _760) * _760)) * (0.5 / fast::max(mix((2.0 * _723) * _592, _723 + _592, _582), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _723))) * _642.fa_light_color[li].xyz) * (_723 * atten));\n        }\n        float param_5 = _578;\n        float param_6 = _592;\n        float2 _828 = fa_env_brdf(param_5, param_6);\n        float3 param_7 = reflect(-_540, _567);\n        float param_8 = _578;\n        float3 _846 = lit;\n        float3 _847 = _846 + ((fa_environment(param_7, param_8, _136) * ((_606 * _828.x) + float3(_828.y))) * _928);\n        lit = _847;\n        result = _847;\n    }\n    result += _929;\n    if (_136.fa_fog.w > 0.0)\n    {\n        float _871 = _136.fa_fog.w * length(_539);\n        result = mix(result, _136.fa_fog.xyz, float3(fast::clamp(1.0 - exp((-_871) * _871), 0.0, 1.0)));\n    }\n    out.fa_frag_color = float4(result, _924);\n    return out;\n}\n\n",
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
            "slot": 4,
            "stage": "vertex",
            "size": 16,
            "struct_name": "fa_material_vs",
            "inst_name": "_48",
            "msl_buffer_n": 4
          },
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_148",
            "msl_buffer_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_195",
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
            "inst_name": "_642",
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_material_vs\n{\n    packed_float3 offset;\n    float fa_pad0;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float4 fa_inst_m0 [[attribute(1)]];\n    float4 fa_inst_m1 [[attribute(2)]];\n    float4 fa_inst_m2 [[attribute(3)]];\n    float4 fa_inst_m3 [[attribute(4)]];\n    float3 fa_normal [[attribute(5)]];\n    float2 fa_texcoord0 [[attribute(6)]];\n    float4 fa_tangent [[attribute(7)]];\n    float4 fa_color [[attribute(8)]];\n};\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _134)\n{\n    float3 _72 = cross(model[1].xyz, model[2].xyz);\n    float _78 = (dot(model[0].xyz, _72) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_72 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _78, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _78), texcoord0 * _134.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread VertexData& v, constant fa_material_vs& _34)\n{\n    v.world_pos += float3(_34.offset);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _134 [[buffer(0)]], constant fa_material_vs& _34 [[buffer(4)]])\n{\n    main0_out out = {};\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _134);\n    vertex0(param_6, _34);\n    out.gl_Position = _134.fa_light_vp * float4(param_6.world_pos, 1.0);\n    return out;\n}\n\n",
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
          },
          {
            "slot": 8,
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
            "inst_name": "_34",
            "msl_buffer_n": 4
          },
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_134",
            "msl_buffer_n": 0
          }
        ]
      }
    },
    "shadow_skin": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_material_vs\n{\n    packed_float3 offset;\n    float fa_pad0;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct main0_out\n{\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float4 fa_inst_m0 [[attribute(1)]];\n    float4 fa_inst_m1 [[attribute(2)]];\n    float4 fa_inst_m2 [[attribute(3)]];\n    float4 fa_inst_m3 [[attribute(4)]];\n    float4 fa_joints [[attribute(5)]];\n    float4 fa_weights [[attribute(6)]];\n    float3 fa_normal [[attribute(7)]];\n    float2 fa_texcoord0 [[attribute(8)]];\n    float4 fa_tangent [[attribute(9)]];\n    float4 fa_color [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _186)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _177 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_186.fa_joint_rows[_177] * weights[i]);\n        r1 += (_186.fa_joint_rows[_177 + 1] * weights[i]);\n        r2 += (_186.fa_joint_rows[_177 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _139)\n{\n    float3 _77 = cross(model[1].xyz, model[2].xyz);\n    float _83 = (dot(model[0].xyz, _77) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_77 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _83, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _83), texcoord0 * _139.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread VertexData& v, constant fa_material_vs& _39)\n{\n    v.world_pos += float3(_39.offset);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _139 [[buffer(0)]], constant fa_skin& _186 [[buffer(3)]], constant fa_material_vs& _39 [[buffer(4)]])\n{\n    main0_out out = {};\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float4x4 param_2 = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _186);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    VertexData param_8 = fa_vertex_data(param_2, param_3, param_4, param_5, param_6, param_7, _139);\n    vertex0(param_8, _39);\n    out.gl_Position = _139.fa_light_vp * float4(param_8.world_pos, 1.0);\n    return out;\n}\n\n",
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
          },
          {
            "slot": 10,
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
            "inst_name": "_39",
            "msl_buffer_n": 4
          },
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_139",
            "msl_buffer_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_186",
            "msl_buffer_n": 3
          }
        ]
      }
    }
  }
}
