{
  "format": "factoria.shader/1",
  "engine": "0.1.6",
  "template": "a75dcd870d51444499f61f3cb2010a1b06d96d8916439ce459176478546f3cd8",
  "slang": "metal_macos",
  "params": [],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float4 fa_shadow_pos [[user(locn5)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n};\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _129)\n{\n    float3 _67 = cross(model[1].xyz, model[2].xyz);\n    float _73 = (dot(model[0].xyz, _67) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_67 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _73, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _73), texcoord0 * _129.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _129, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& fa_shadow_pos, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _158 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _129);\n    float3 _267 = _158.world_pos;\n    float4 _165 = float4(_267, 1.0);\n    fa_world_pos = _267;\n    fa_world_normal = _158.world_normal;\n    fa_world_tangent = _158.world_tangent;\n    fa_uv = _158.uv;\n    fa_vertex_color = _158.color;\n    fa_shadow_pos = _129.fa_light_vp * _165;\n    gl_Position = _129.fa_view_proj * _165;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _129 [[buffer(0)]])\n{\n    main0_out out = {};\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5, _129, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_shadow_pos, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n};\n\nstruct fa_lights\n{\n    float4 fa_light_pos[32];\n    float4 fa_light_color[32];\n    float4 fa_light_dir[32];\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float4 fa_shadow_pos [[user(locn5)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _52;\n    if (bool(i.front_facing))\n    {\n        _52 = i.world_normal;\n    }\n    else\n    {\n        _52 = -i.world_normal;\n    }\n    float3 _77 = fast::normalize(i.world_tangent.xyz - (_52 * dot(_52, i.world_tangent.xyz)));\n    float3 _105 = fast::normalize(((_77 * m.x) + ((cross(_52, _77) * i.world_tangent.w) * m.y)) + (_52 * m.z));\n    float3 _108;\n    if (bool(i.front_facing))\n    {\n        _108 = _105;\n    }\n    else\n    {\n        _108 = -_105;\n    }\n    return _108;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _121, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 _157 = fa_tex.sample(fa_smp, i.uv);\n    float4 _165 = (_157 * _121.fa_base_color) * i.vertex_color;\n    float3 _968 = i.world_normal;\n    if (_121.fa_maps.z > 0.5)\n    {\n        float3 _195 = (fa_normal_tex.sample(fa_smp, i.uv).xyz * 2.0) - float3(1.0);\n        float2 _200 = _195.xy * _121.fa_maps.x;\n        float3 _985 = _195;\n        _985.x = _200.x;\n        _985.y = _200.y;\n        SurfaceInput param = i;\n        float3 param_1 = _985;\n        _968 = fa_tangent_normal(param, param_1);\n    }\n    float4 _218 = fa_mr_tex.sample(fa_smp, i.uv);\n    return Surface{ _165.xyz, _165.w, _968, fast::clamp(_121.fa_pbr.x * _218.z, 0.0, 1.0), fast::clamp(_121.fa_pbr.y * _218.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_121.fa_maps.y * (fa_occlusion_tex.sample(fa_smp, i.uv).x - 1.0)), _121.fa_emissive.xyz + (_121.fa_model_emissive.xyz * fa_emissive_tex.sample(fa_smp, i.uv).xyz) };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread Surface& s, constant fa_mesh_fs_params& _121)\n{\n    s.emission += float3(0.5 + (0.5 * sin(_121.fa_time.x * 3.0)), 0.25 * fract(_121.fa_time.x), 0.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _121, thread float4& fa_shadow_pos, texture2d<float> fa_shadow_tex, sampler fa_shadow_smp)\n{\n    if (_121.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    float3 _284 = fa_shadow_pos.xyz / float3(fa_shadow_pos.w);\n    float3 p = _284;\n    float2 suv = (_284.xy * 0.5) + float2(0.5);\n    if (_121.fa_counts.z > 0.5)\n    {\n        float3 _990 = p;\n        _990.z = (_990.z * 0.5) + 0.5;\n        p = _990;\n    }\n    else\n    {\n        float2 _993 = suv;\n        _993.y = 1.0 - _993.y;\n        suv = _993;\n    }\n    bool _311 = suv.x < 0.0;\n    bool _318;\n    if (!_311)\n    {\n        _318 = suv.x > 1.0;\n    }\n    else\n    {\n        _318 = _311;\n    }\n    bool _325;\n    if (!_318)\n    {\n        _325 = suv.y < 0.0;\n    }\n    else\n    {\n        _325 = _318;\n    }\n    bool _332;\n    if (!_325)\n    {\n        _332 = suv.y > 1.0;\n    }\n    else\n    {\n        _332 = _325;\n    }\n    bool _339;\n    if (!_332)\n    {\n        _339 = p.z > 1.0;\n    }\n    else\n    {\n        _339 = _332;\n    }\n    if (_339)\n    {\n        return 1.0;\n    }\n    float _353 = _121.fa_pbr.w * (1.0 + (2.0 * (1.0 - fast::clamp(dot(n, l), 0.0, 1.0))));\n    float lit = 0.0;\n    for (int ix = -1; ix <= 1; ix++)\n    {\n        for (int iy = -1; iy <= 1; iy++)\n        {\n            lit += float((p.z - _353) <= fa_shadow_tex.sample(fa_shadow_smp, (suv + (float2(float(ix), float(iy)) * _121.fa_counts.y)), level(0.0)).x);\n        }\n    }\n    return lit * 0.111111111938953399658203125;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_env_brdf(thread const float& rough, thread const float& ndv)\n{\n    float4 _494 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _497 = _494.x;\n    return (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_497 * _497, exp2((-9.27999973297119140625) * ndv)) * _497) + _494.y)) + _494.zw;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_environment(thread const float3& d, thread const float& rough, constant fa_mesh_fs_params& _121)\n{\n    float _414 = rough * rough;\n    float _447 = 0.60000002384185791015625 * _414;\n    return mix(mix(_121.fa_env_horizon.xyz * 0.550000011920928955078125, mix(_121.fa_env_horizon.xyz, _121.fa_env_sky.xyz, float3(powr(fast::clamp(d.y * (1.0 - (0.699999988079071044921875 * _414)), 0.0, 1.0), 0.550000011920928955078125))), float3(smoothstep((-0.0500000007450580596923828125) - _447, 0.0500000007450580596923828125 + _447, d.y))), ((_121.fa_env_sky.xyz + _121.fa_env_horizon.xyz) * 0.5) * 0.800000011920928955078125, float3(_414 * 0.60000002384185791015625));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _121 [[buffer(1)]], constant fa_lights& _660 [[buffer(2)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    float3 _915 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _915 = -_915;\n    }\n    float3 _557 = _121.fa_camera_pos.xyz - in.fa_world_pos;\n    float3 _558 = fast::normalize(_557);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _915, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _558, short(gl_FrontFacing) };\n    Surface _563 = fa_standard_surface(param, _121, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _937 = _563.albedo;\n    float _938 = _563.alpha;\n    float3 _939 = _563.normal;\n    float _940 = _563.metallic;\n    float _941 = _563.roughness;\n    float _942 = _563.occlusion;\n    float3 _943 = _563.emission;\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _915, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _558, short(gl_FrontFacing) };\n    Surface param_2 = _563;\n    surface(param_1, param_2, _121);\n    _937 = param_2.albedo;\n    _938 = param_2.alpha;\n    _939 = param_2.normal;\n    _940 = param_2.metallic;\n    _941 = param_2.roughness;\n    _942 = param_2.occlusion;\n    _943 = param_2.emission;\n    float3 result;\n    if (_121.fa_emissive.w > 0.5)\n    {\n        result = _937;\n    }\n    else\n    {\n        float3 _585 = fast::normalize(_939);\n        float _592 = fast::clamp(_940, 0.0, 1.0);\n        float _596 = fast::clamp(_941, 0.0500000007450580596923828125, 1.0);\n        float _600 = _596 * _596;\n        float _604 = _600 * _600;\n        float _610 = fast::max(dot(_585, _558), 9.9999997473787516355514526367188e-05);\n        float3 _616 = _937 * (1.0 - _592);\n        float3 _624 = mix(float3(0.039999999105930328369140625), _937, float3(_592));\n        float3 lit = (_121.fa_ambient.xyz * _616) * _942;\n        int _637 = int(_121.fa_counts.x);\n        float3 l;\n        for (int li = 0; li < 32; li++)\n        {\n            if (li >= _637)\n            {\n                break;\n            }\n            float atten = 1.0;\n            bool _666 = _660.fa_light_color[li].w < 0.5;\n            if (_666)\n            {\n                l = fast::normalize(_660.fa_light_pos[li].xyz);\n            }\n            else\n            {\n                float3 _683 = _660.fa_light_pos[li].xyz - in.fa_world_pos;\n                float _686 = length(_683);\n                l = _683 / float3(fast::max(_686, 9.9999997473787516355514526367188e-05));\n                float _701 = _686 / fast::max(_660.fa_light_pos[li].w, 0.001000000047497451305389404296875);\n                float _707 = fast::clamp(1.0 - (_701 * _701), 0.0, 1.0);\n                atten = _707 * _707;\n                if (_660.fa_light_color[li].w > 1.5)\n                {\n                    atten *= smoothstep(_660.fa_light_dir[li].w, mix(_660.fa_light_dir[li].w, 1.0, 0.25), dot(-l, fast::normalize(_660.fa_light_dir[li].xyz)));\n                }\n            }\n            float _740 = fast::max(dot(_585, l), 0.0);\n            if (_666 && (li == 0))\n            {\n                float3 param_3 = _915;\n                float3 param_4 = l;\n                atten *= fa_shadow_factor(param_3, param_4, _121, in.fa_shadow_pos, fa_shadow_tex, fa_shadow_smp);\n            }\n            float3 _759 = fast::normalize(l + _558);\n            float _764 = fast::max(dot(_585, _759), 0.0);\n            float _777 = ((_764 * _764) * (_604 - 1.0)) + 1.0;\n            lit += (((_616 + (((_624 + ((float3(1.0) - _624) * powr(1.0 - fast::max(dot(_558, _759), 0.0), 5.0))) * (((_604 / ((3.1415927410125732421875 * _777) * _777)) * (0.5 / fast::max(mix((2.0 * _740) * _610, _740 + _610, _600), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _740))) * _660.fa_light_color[li].xyz) * (_740 * atten));\n        }\n        float param_5 = _596;\n        float param_6 = _610;\n        float2 _845 = fa_env_brdf(param_5, param_6);\n        float3 param_7 = reflect(-_558, _585);\n        float param_8 = _596;\n        float3 _863 = lit;\n        float3 _864 = _863 + ((fa_environment(param_7, param_8, _121) * ((_624 * _845.x) + float3(_845.y))) * _942);\n        lit = _864;\n        result = _864;\n    }\n    result += _943;\n    if (_121.fa_fog.w > 0.0)\n    {\n        float _888 = _121.fa_fog.w * length(_557);\n        result = mix(result, _121.fa_fog.xyz, float3(fast::clamp(1.0 - exp((-_888) * _888), 0.0, 1.0)));\n    }\n    out.fa_frag_color = float4(result, _938);\n    return out;\n}\n\n",
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
            "inst_name": "_129",
            "msl_buffer_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 192,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_121",
            "msl_buffer_n": 1
          },
          {
            "slot": 2,
            "stage": "fragment",
            "size": 1536,
            "struct_name": "fa_lights",
            "inst_name": "_660",
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float4 fa_shadow_pos [[user(locn5)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n    float4 fa_joints [[attribute(9)]];\n    float4 fa_weights [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _181)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _172 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_181.fa_joint_rows[_172] * weights[i]);\n        r1 += (_181.fa_joint_rows[_172 + 1] * weights[i]);\n        r2 += (_181.fa_joint_rows[_172 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _134)\n{\n    float3 _72 = cross(model[1].xyz, model[2].xyz);\n    float _78 = (dot(model[0].xyz, _72) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_72 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _78, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _78), texcoord0 * _134.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _134, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& fa_shadow_pos, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _271 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _134);\n    float3 _388 = _271.world_pos;\n    float4 _278 = float4(_388, 1.0);\n    fa_world_pos = _388;\n    fa_world_normal = _271.world_normal;\n    fa_world_tangent = _271.world_tangent;\n    fa_uv = _271.uv;\n    fa_vertex_color = _271.color;\n    fa_shadow_pos = _134.fa_light_vp * _278;\n    gl_Position = _134.fa_view_proj * _278;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _134 [[buffer(0)]], constant fa_skin& _181 [[buffer(3)]])\n{\n    main0_out out = {};\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float4x4 param_2 = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _181);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7, _134, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_shadow_pos, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n};\n\nstruct fa_lights\n{\n    float4 fa_light_pos[32];\n    float4 fa_light_color[32];\n    float4 fa_light_dir[32];\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float4 fa_shadow_pos [[user(locn5)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _52;\n    if (bool(i.front_facing))\n    {\n        _52 = i.world_normal;\n    }\n    else\n    {\n        _52 = -i.world_normal;\n    }\n    float3 _77 = fast::normalize(i.world_tangent.xyz - (_52 * dot(_52, i.world_tangent.xyz)));\n    float3 _105 = fast::normalize(((_77 * m.x) + ((cross(_52, _77) * i.world_tangent.w) * m.y)) + (_52 * m.z));\n    float3 _108;\n    if (bool(i.front_facing))\n    {\n        _108 = _105;\n    }\n    else\n    {\n        _108 = -_105;\n    }\n    return _108;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _121, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 _157 = fa_tex.sample(fa_smp, i.uv);\n    float4 _165 = (_157 * _121.fa_base_color) * i.vertex_color;\n    float3 _968 = i.world_normal;\n    if (_121.fa_maps.z > 0.5)\n    {\n        float3 _195 = (fa_normal_tex.sample(fa_smp, i.uv).xyz * 2.0) - float3(1.0);\n        float2 _200 = _195.xy * _121.fa_maps.x;\n        float3 _985 = _195;\n        _985.x = _200.x;\n        _985.y = _200.y;\n        SurfaceInput param = i;\n        float3 param_1 = _985;\n        _968 = fa_tangent_normal(param, param_1);\n    }\n    float4 _218 = fa_mr_tex.sample(fa_smp, i.uv);\n    return Surface{ _165.xyz, _165.w, _968, fast::clamp(_121.fa_pbr.x * _218.z, 0.0, 1.0), fast::clamp(_121.fa_pbr.y * _218.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_121.fa_maps.y * (fa_occlusion_tex.sample(fa_smp, i.uv).x - 1.0)), _121.fa_emissive.xyz + (_121.fa_model_emissive.xyz * fa_emissive_tex.sample(fa_smp, i.uv).xyz) };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread Surface& s, constant fa_mesh_fs_params& _121)\n{\n    s.emission += float3(0.5 + (0.5 * sin(_121.fa_time.x * 3.0)), 0.25 * fract(_121.fa_time.x), 0.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _121, thread float4& fa_shadow_pos, texture2d<float> fa_shadow_tex, sampler fa_shadow_smp)\n{\n    if (_121.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    float3 _284 = fa_shadow_pos.xyz / float3(fa_shadow_pos.w);\n    float3 p = _284;\n    float2 suv = (_284.xy * 0.5) + float2(0.5);\n    if (_121.fa_counts.z > 0.5)\n    {\n        float3 _990 = p;\n        _990.z = (_990.z * 0.5) + 0.5;\n        p = _990;\n    }\n    else\n    {\n        float2 _993 = suv;\n        _993.y = 1.0 - _993.y;\n        suv = _993;\n    }\n    bool _311 = suv.x < 0.0;\n    bool _318;\n    if (!_311)\n    {\n        _318 = suv.x > 1.0;\n    }\n    else\n    {\n        _318 = _311;\n    }\n    bool _325;\n    if (!_318)\n    {\n        _325 = suv.y < 0.0;\n    }\n    else\n    {\n        _325 = _318;\n    }\n    bool _332;\n    if (!_325)\n    {\n        _332 = suv.y > 1.0;\n    }\n    else\n    {\n        _332 = _325;\n    }\n    bool _339;\n    if (!_332)\n    {\n        _339 = p.z > 1.0;\n    }\n    else\n    {\n        _339 = _332;\n    }\n    if (_339)\n    {\n        return 1.0;\n    }\n    float _353 = _121.fa_pbr.w * (1.0 + (2.0 * (1.0 - fast::clamp(dot(n, l), 0.0, 1.0))));\n    float lit = 0.0;\n    for (int ix = -1; ix <= 1; ix++)\n    {\n        for (int iy = -1; iy <= 1; iy++)\n        {\n            lit += float((p.z - _353) <= fa_shadow_tex.sample(fa_shadow_smp, (suv + (float2(float(ix), float(iy)) * _121.fa_counts.y)), level(0.0)).x);\n        }\n    }\n    return lit * 0.111111111938953399658203125;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_env_brdf(thread const float& rough, thread const float& ndv)\n{\n    float4 _494 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _497 = _494.x;\n    return (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_497 * _497, exp2((-9.27999973297119140625) * ndv)) * _497) + _494.y)) + _494.zw;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_environment(thread const float3& d, thread const float& rough, constant fa_mesh_fs_params& _121)\n{\n    float _414 = rough * rough;\n    float _447 = 0.60000002384185791015625 * _414;\n    return mix(mix(_121.fa_env_horizon.xyz * 0.550000011920928955078125, mix(_121.fa_env_horizon.xyz, _121.fa_env_sky.xyz, float3(powr(fast::clamp(d.y * (1.0 - (0.699999988079071044921875 * _414)), 0.0, 1.0), 0.550000011920928955078125))), float3(smoothstep((-0.0500000007450580596923828125) - _447, 0.0500000007450580596923828125 + _447, d.y))), ((_121.fa_env_sky.xyz + _121.fa_env_horizon.xyz) * 0.5) * 0.800000011920928955078125, float3(_414 * 0.60000002384185791015625));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _121 [[buffer(1)]], constant fa_lights& _660 [[buffer(2)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    float3 _915 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _915 = -_915;\n    }\n    float3 _557 = _121.fa_camera_pos.xyz - in.fa_world_pos;\n    float3 _558 = fast::normalize(_557);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _915, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _558, short(gl_FrontFacing) };\n    Surface _563 = fa_standard_surface(param, _121, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _937 = _563.albedo;\n    float _938 = _563.alpha;\n    float3 _939 = _563.normal;\n    float _940 = _563.metallic;\n    float _941 = _563.roughness;\n    float _942 = _563.occlusion;\n    float3 _943 = _563.emission;\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _915, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _558, short(gl_FrontFacing) };\n    Surface param_2 = _563;\n    surface(param_1, param_2, _121);\n    _937 = param_2.albedo;\n    _938 = param_2.alpha;\n    _939 = param_2.normal;\n    _940 = param_2.metallic;\n    _941 = param_2.roughness;\n    _942 = param_2.occlusion;\n    _943 = param_2.emission;\n    float3 result;\n    if (_121.fa_emissive.w > 0.5)\n    {\n        result = _937;\n    }\n    else\n    {\n        float3 _585 = fast::normalize(_939);\n        float _592 = fast::clamp(_940, 0.0, 1.0);\n        float _596 = fast::clamp(_941, 0.0500000007450580596923828125, 1.0);\n        float _600 = _596 * _596;\n        float _604 = _600 * _600;\n        float _610 = fast::max(dot(_585, _558), 9.9999997473787516355514526367188e-05);\n        float3 _616 = _937 * (1.0 - _592);\n        float3 _624 = mix(float3(0.039999999105930328369140625), _937, float3(_592));\n        float3 lit = (_121.fa_ambient.xyz * _616) * _942;\n        int _637 = int(_121.fa_counts.x);\n        float3 l;\n        for (int li = 0; li < 32; li++)\n        {\n            if (li >= _637)\n            {\n                break;\n            }\n            float atten = 1.0;\n            bool _666 = _660.fa_light_color[li].w < 0.5;\n            if (_666)\n            {\n                l = fast::normalize(_660.fa_light_pos[li].xyz);\n            }\n            else\n            {\n                float3 _683 = _660.fa_light_pos[li].xyz - in.fa_world_pos;\n                float _686 = length(_683);\n                l = _683 / float3(fast::max(_686, 9.9999997473787516355514526367188e-05));\n                float _701 = _686 / fast::max(_660.fa_light_pos[li].w, 0.001000000047497451305389404296875);\n                float _707 = fast::clamp(1.0 - (_701 * _701), 0.0, 1.0);\n                atten = _707 * _707;\n                if (_660.fa_light_color[li].w > 1.5)\n                {\n                    atten *= smoothstep(_660.fa_light_dir[li].w, mix(_660.fa_light_dir[li].w, 1.0, 0.25), dot(-l, fast::normalize(_660.fa_light_dir[li].xyz)));\n                }\n            }\n            float _740 = fast::max(dot(_585, l), 0.0);\n            if (_666 && (li == 0))\n            {\n                float3 param_3 = _915;\n                float3 param_4 = l;\n                atten *= fa_shadow_factor(param_3, param_4, _121, in.fa_shadow_pos, fa_shadow_tex, fa_shadow_smp);\n            }\n            float3 _759 = fast::normalize(l + _558);\n            float _764 = fast::max(dot(_585, _759), 0.0);\n            float _777 = ((_764 * _764) * (_604 - 1.0)) + 1.0;\n            lit += (((_616 + (((_624 + ((float3(1.0) - _624) * powr(1.0 - fast::max(dot(_558, _759), 0.0), 5.0))) * (((_604 / ((3.1415927410125732421875 * _777) * _777)) * (0.5 / fast::max(mix((2.0 * _740) * _610, _740 + _610, _600), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _740))) * _660.fa_light_color[li].xyz) * (_740 * atten));\n        }\n        float param_5 = _596;\n        float param_6 = _610;\n        float2 _845 = fa_env_brdf(param_5, param_6);\n        float3 param_7 = reflect(-_558, _585);\n        float param_8 = _596;\n        float3 _863 = lit;\n        float3 _864 = _863 + ((fa_environment(param_7, param_8, _121) * ((_624 * _845.x) + float3(_845.y))) * _942);\n        lit = _864;\n        result = _864;\n    }\n    result += _943;\n    if (_121.fa_fog.w > 0.0)\n    {\n        float _888 = _121.fa_fog.w * length(_557);\n        result = mix(result, _121.fa_fog.xyz, float3(fast::clamp(1.0 - exp((-_888) * _888), 0.0, 1.0)));\n    }\n    out.fa_frag_color = float4(result, _938);\n    return out;\n}\n\n",
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
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_134",
            "msl_buffer_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_181",
            "msl_buffer_n": 3
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 192,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_121",
            "msl_buffer_n": 1
          },
          {
            "slot": 2,
            "stage": "fragment",
            "size": 1536,
            "struct_name": "fa_lights",
            "inst_name": "_660",
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
