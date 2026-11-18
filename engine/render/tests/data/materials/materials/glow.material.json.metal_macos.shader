{
  "format": "factoria.shader/1",
  "engine": "0.30.1",
  "template": "616705bcddf9b6a98bc0277c05f4815433dd40e61efe9f55376421e3ba39eecd",
  "slang": "metal_macos",
  "params": [
    "glow"
  ],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float4 fa_shadow_pos [[user(locn5)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n};\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _129)\n{\n    float3 _67 = cross(model[1].xyz, model[2].xyz);\n    float _73 = (dot(model[0].xyz, _67) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_67 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _73, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _73), texcoord0 * _129.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _129, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& fa_shadow_pos, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _158 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _129);\n    float3 _270 = _158.world_pos;\n    float4 _165 = float4(_270, 1.0);\n    fa_world_pos = _270;\n    fa_world_normal = _158.world_normal;\n    fa_world_tangent = _158.world_tangent;\n    fa_uv = _158.uv;\n    fa_vertex_color = _158.color;\n    fa_shadow_pos = _129.fa_light_vp * _165;\n    gl_Position = _129.fa_view_proj * _165;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _129 [[buffer(0)]])\n{\n    main0_out out = {};\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5, _129, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_shadow_pos, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\nstruct fa_material\n{\n    float4 glow;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n};\n\nstruct fa_lights\n{\n    float4 fa_light_pos[32];\n    float4 fa_light_color[32];\n    float4 fa_light_dir[32];\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float4 fa_shadow_pos [[user(locn5)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _200 = fa_linear_to_srgb(param);\n        c = _200;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _209 = fa_srgb_to_linear(param_1);\n            c = _209;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _68;\n    if (bool(i.front_facing))\n    {\n        _68 = i.world_normal;\n    }\n    else\n    {\n        _68 = -i.world_normal;\n    }\n    float3 _93 = fast::normalize(i.world_tangent.xyz - (_68 * dot(_68, i.world_tangent.xyz)));\n    float3 _121 = fast::normalize(((_93 * m.x) + ((cross(_68, _93) * i.world_tangent.w) * m.y)) + (_68 * m.z));\n    float3 _124;\n    if (bool(i.front_facing))\n    {\n        _124 = _121;\n    }\n    else\n    {\n        _124 = -_121;\n    }\n    return _124;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _241, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _241.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _252 = fa_tex_fix(param_2, param_3);\n    float4 _1127 = base_t;\n    _1127.x = _252.x;\n    _1127.y = _252.y;\n    _1127.z = _252.z;\n    base_t = _1127;\n    float4 _267 = (_1127 * _241.fa_base_color) * i.vertex_color;\n    float3 _1112 = i.world_normal;\n    if (_241.fa_maps.z > 0.5)\n    {\n        float param_4 = _241.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _300 = fa_tex_fix(param_6, param_7);\n        float3 _304 = (_300 * 2.0) - float3(1.0);\n        float2 _309 = _304.xy * _241.fa_maps.x;\n        float3 _1135 = _304;\n        _1135.x = _309.x;\n        _1135.y = _309.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _1135;\n        _1112 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _241.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _338 = fa_tex_fix(param_12, param_13);\n    float4 _1138 = mrt;\n    _1138.x = _338.x;\n    _1138.y = _338.y;\n    _1138.z = _338.z;\n    mrt = _1138;\n    float param_14 = _241.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = fa_occlusion_tex.sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _379 = fa_tex_fix(param_16, param_17);\n    float param_18 = _241.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _406 = fa_tex_fix(param_20, param_21);\n    return Surface{ _267.xyz, _267.w, _1112, fast::clamp(_241.fa_pbr.x * _338.z, 0.0, 1.0), fast::clamp(_241.fa_pbr.y * _338.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_241.fa_maps.y * (_379.x - 1.0)), _241.fa_emissive.xyz + (_241.fa_model_emissive.xyz * _406) };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread Surface& s, constant fa_material& _136)\n{\n    s.emission += (_136.glow.xyz * _136.glow.w);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _241, thread float4& fa_shadow_pos, texture2d<float> fa_shadow_tex, sampler fa_shadow_smp)\n{\n    if (_241.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    float3 _428 = fa_shadow_pos.xyz / float3(fa_shadow_pos.w);\n    float3 p = _428;\n    float2 suv = (_428.xy * 0.5) + float2(0.5);\n    if (_241.fa_counts.z > 0.5)\n    {\n        float3 _1146 = p;\n        _1146.z = (_1146.z * 0.5) + 0.5;\n        p = _1146;\n    }\n    else\n    {\n        float2 _1149 = suv;\n        _1149.y = 1.0 - _1149.y;\n        suv = _1149;\n    }\n    bool _455 = suv.x < 0.0;\n    bool _462;\n    if (!_455)\n    {\n        _462 = suv.x > 1.0;\n    }\n    else\n    {\n        _462 = _455;\n    }\n    bool _469;\n    if (!_462)\n    {\n        _469 = suv.y < 0.0;\n    }\n    else\n    {\n        _469 = _462;\n    }\n    bool _476;\n    if (!_469)\n    {\n        _476 = suv.y > 1.0;\n    }\n    else\n    {\n        _476 = _469;\n    }\n    bool _483;\n    if (!_476)\n    {\n        _483 = p.z > 1.0;\n    }\n    else\n    {\n        _483 = _476;\n    }\n    if (_483)\n    {\n        return 1.0;\n    }\n    float _497 = _241.fa_pbr.w * (1.0 + (2.0 * (1.0 - fast::clamp(dot(n, l), 0.0, 1.0))));\n    float lit = 0.0;\n    for (int ix = -1; ix <= 1; ix++)\n    {\n        for (int iy = -1; iy <= 1; iy++)\n        {\n            lit += float((p.z - _497) <= fa_shadow_tex.sample(fa_shadow_smp, (suv + (float2(float(ix), float(iy)) * _241.fa_counts.y)), level(0.0)).x);\n        }\n    }\n    return lit * 0.111111111938953399658203125;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_env_brdf(thread const float& rough, thread const float& ndv)\n{\n    float4 _638 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _641 = _638.x;\n    return (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_641 * _641, exp2((-9.27999973297119140625) * ndv)) * _641) + _638.y)) + _638.zw;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_environment(thread const float3& d, thread const float& rough, constant fa_mesh_fs_params& _241)\n{\n    float _558 = rough * rough;\n    float _591 = 0.60000002384185791015625 * _558;\n    return mix(mix(_241.fa_env_horizon.xyz * 0.550000011920928955078125, mix(_241.fa_env_horizon.xyz, _241.fa_env_sky.xyz, float3(powr(fast::clamp(d.y * (1.0 - (0.699999988079071044921875 * _558)), 0.0, 1.0), 0.550000011920928955078125))), float3(smoothstep((-0.0500000007450580596923828125) - _591, 0.0500000007450580596923828125 + _591, d.y))), ((_241.fa_env_sky.xyz + _241.fa_env_horizon.xyz) * 0.5) * 0.800000011920928955078125, float3(_558 * 0.60000002384185791015625));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _241 [[buffer(1)]], constant fa_lights& _804 [[buffer(2)]], constant fa_material& _136 [[buffer(5)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    float3 _1059 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _1059 = -_1059;\n    }\n    float3 _701 = _241.fa_camera_pos.xyz - in.fa_world_pos;\n    float3 _702 = fast::normalize(_701);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _1059, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _702, short(gl_FrontFacing) };\n    Surface _707 = fa_standard_surface(param, fa_tex, fa_smp, _241, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _1081 = _707.albedo;\n    float _1082 = _707.alpha;\n    float3 _1083 = _707.normal;\n    float _1084 = _707.metallic;\n    float _1085 = _707.roughness;\n    float _1086 = _707.occlusion;\n    float3 _1087 = _707.emission;\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _1059, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _702, short(gl_FrontFacing) };\n    Surface param_2 = _707;\n    surface(param_1, param_2, _136);\n    _1081 = param_2.albedo;\n    _1082 = param_2.alpha;\n    _1083 = param_2.normal;\n    _1084 = param_2.metallic;\n    _1085 = param_2.roughness;\n    _1086 = param_2.occlusion;\n    _1087 = param_2.emission;\n    float3 result;\n    if (_241.fa_emissive.w > 0.5)\n    {\n        result = _1081;\n    }\n    else\n    {\n        float3 _729 = fast::normalize(_1083);\n        float _736 = fast::clamp(_1084, 0.0, 1.0);\n        float _740 = fast::clamp(_1085, 0.0500000007450580596923828125, 1.0);\n        float _744 = _740 * _740;\n        float _748 = _744 * _744;\n        float _754 = fast::max(dot(_729, _702), 9.9999997473787516355514526367188e-05);\n        float3 _760 = _1081 * (1.0 - _736);\n        float3 _768 = mix(float3(0.039999999105930328369140625), _1081, float3(_736));\n        float3 lit = (_241.fa_ambient.xyz * _760) * _1086;\n        int _781 = int(_241.fa_counts.x);\n        float3 l;\n        for (int li = 0; li < 32; li++)\n        {\n            if (li >= _781)\n            {\n                break;\n            }\n            float atten = 1.0;\n            bool _810 = _804.fa_light_color[li].w < 0.5;\n            if (_810)\n            {\n                l = fast::normalize(_804.fa_light_pos[li].xyz);\n            }\n            else\n            {\n                float3 _827 = _804.fa_light_pos[li].xyz - in.fa_world_pos;\n                float _830 = length(_827);\n                l = _827 / float3(fast::max(_830, 9.9999997473787516355514526367188e-05));\n                float _845 = _830 / fast::max(_804.fa_light_pos[li].w, 0.001000000047497451305389404296875);\n                float _851 = fast::clamp(1.0 - (_845 * _845), 0.0, 1.0);\n                atten = _851 * _851;\n                if (_804.fa_light_color[li].w > 1.5)\n                {\n                    atten *= smoothstep(_804.fa_light_dir[li].w, mix(_804.fa_light_dir[li].w, 1.0, 0.25), dot(-l, fast::normalize(_804.fa_light_dir[li].xyz)));\n                }\n            }\n            float _884 = fast::max(dot(_729, l), 0.0);\n            if (_810 && (li == 0))\n            {\n                float3 param_3 = _1059;\n                float3 param_4 = l;\n                atten *= fa_shadow_factor(param_3, param_4, _241, in.fa_shadow_pos, fa_shadow_tex, fa_shadow_smp);\n            }\n            float3 _903 = fast::normalize(l + _702);\n            float _908 = fast::max(dot(_729, _903), 0.0);\n            float _921 = ((_908 * _908) * (_748 - 1.0)) + 1.0;\n            lit += (((_760 + (((_768 + ((float3(1.0) - _768) * powr(1.0 - fast::max(dot(_702, _903), 0.0), 5.0))) * (((_748 / ((3.1415927410125732421875 * _921) * _921)) * (0.5 / fast::max(mix((2.0 * _884) * _754, _884 + _754, _744), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _884))) * _804.fa_light_color[li].xyz) * (_884 * atten));\n        }\n        float param_5 = _740;\n        float param_6 = _754;\n        float2 _989 = fa_env_brdf(param_5, param_6);\n        float3 param_7 = reflect(-_702, _729);\n        float param_8 = _740;\n        float3 _1007 = lit;\n        float3 _1008 = _1007 + ((fa_environment(param_7, param_8, _241) * ((_768 * _989.x) + float3(_989.y))) * _1086);\n        lit = _1008;\n        result = _1008;\n    }\n    result += _1087;\n    if (_241.fa_fog.w > 0.0)\n    {\n        float _1032 = _241.fa_fog.w * length(_701);\n        result = mix(result, _241.fa_fog.xyz, float3(fast::clamp(1.0 - exp((-_1032) * _1032), 0.0, 1.0)));\n    }\n    out.fa_frag_color = float4(result, _1082);\n    return out;\n}\n\n",
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
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_136",
            "msl_buffer_n": 5
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 192,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_241",
            "msl_buffer_n": 1
          },
          {
            "slot": 2,
            "stage": "fragment",
            "size": 1536,
            "struct_name": "fa_lights",
            "inst_name": "_804",
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float4 fa_shadow_pos [[user(locn5)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n    float4 fa_joints [[attribute(9)]];\n    float4 fa_weights [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _181)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _172 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_181.fa_joint_rows[_172] * weights[i]);\n        r1 += (_181.fa_joint_rows[_172 + 1] * weights[i]);\n        r2 += (_181.fa_joint_rows[_172 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _134)\n{\n    float3 _72 = cross(model[1].xyz, model[2].xyz);\n    float _78 = (dot(model[0].xyz, _72) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_72 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _78, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _78), texcoord0 * _134.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _134, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& fa_shadow_pos, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _271 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _134);\n    float3 _391 = _271.world_pos;\n    float4 _278 = float4(_391, 1.0);\n    fa_world_pos = _391;\n    fa_world_normal = _271.world_normal;\n    fa_world_tangent = _271.world_tangent;\n    fa_uv = _271.uv;\n    fa_vertex_color = _271.color;\n    fa_shadow_pos = _134.fa_light_vp * _278;\n    gl_Position = _134.fa_view_proj * _278;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _134 [[buffer(0)]], constant fa_skin& _181 [[buffer(3)]])\n{\n    main0_out out = {};\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float4x4 param_2 = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _181);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7, _134, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_shadow_pos, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\nstruct fa_material\n{\n    float4 glow;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n};\n\nstruct fa_lights\n{\n    float4 fa_light_pos[32];\n    float4 fa_light_color[32];\n    float4 fa_light_dir[32];\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float4 fa_shadow_pos [[user(locn5)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _200 = fa_linear_to_srgb(param);\n        c = _200;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _209 = fa_srgb_to_linear(param_1);\n            c = _209;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _68;\n    if (bool(i.front_facing))\n    {\n        _68 = i.world_normal;\n    }\n    else\n    {\n        _68 = -i.world_normal;\n    }\n    float3 _93 = fast::normalize(i.world_tangent.xyz - (_68 * dot(_68, i.world_tangent.xyz)));\n    float3 _121 = fast::normalize(((_93 * m.x) + ((cross(_68, _93) * i.world_tangent.w) * m.y)) + (_68 * m.z));\n    float3 _124;\n    if (bool(i.front_facing))\n    {\n        _124 = _121;\n    }\n    else\n    {\n        _124 = -_121;\n    }\n    return _124;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _241, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _241.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _252 = fa_tex_fix(param_2, param_3);\n    float4 _1127 = base_t;\n    _1127.x = _252.x;\n    _1127.y = _252.y;\n    _1127.z = _252.z;\n    base_t = _1127;\n    float4 _267 = (_1127 * _241.fa_base_color) * i.vertex_color;\n    float3 _1112 = i.world_normal;\n    if (_241.fa_maps.z > 0.5)\n    {\n        float param_4 = _241.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _300 = fa_tex_fix(param_6, param_7);\n        float3 _304 = (_300 * 2.0) - float3(1.0);\n        float2 _309 = _304.xy * _241.fa_maps.x;\n        float3 _1135 = _304;\n        _1135.x = _309.x;\n        _1135.y = _309.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _1135;\n        _1112 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _241.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _338 = fa_tex_fix(param_12, param_13);\n    float4 _1138 = mrt;\n    _1138.x = _338.x;\n    _1138.y = _338.y;\n    _1138.z = _338.z;\n    mrt = _1138;\n    float param_14 = _241.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = fa_occlusion_tex.sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _379 = fa_tex_fix(param_16, param_17);\n    float param_18 = _241.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _406 = fa_tex_fix(param_20, param_21);\n    return Surface{ _267.xyz, _267.w, _1112, fast::clamp(_241.fa_pbr.x * _338.z, 0.0, 1.0), fast::clamp(_241.fa_pbr.y * _338.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_241.fa_maps.y * (_379.x - 1.0)), _241.fa_emissive.xyz + (_241.fa_model_emissive.xyz * _406) };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread Surface& s, constant fa_material& _136)\n{\n    s.emission += (_136.glow.xyz * _136.glow.w);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _241, thread float4& fa_shadow_pos, texture2d<float> fa_shadow_tex, sampler fa_shadow_smp)\n{\n    if (_241.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    float3 _428 = fa_shadow_pos.xyz / float3(fa_shadow_pos.w);\n    float3 p = _428;\n    float2 suv = (_428.xy * 0.5) + float2(0.5);\n    if (_241.fa_counts.z > 0.5)\n    {\n        float3 _1146 = p;\n        _1146.z = (_1146.z * 0.5) + 0.5;\n        p = _1146;\n    }\n    else\n    {\n        float2 _1149 = suv;\n        _1149.y = 1.0 - _1149.y;\n        suv = _1149;\n    }\n    bool _455 = suv.x < 0.0;\n    bool _462;\n    if (!_455)\n    {\n        _462 = suv.x > 1.0;\n    }\n    else\n    {\n        _462 = _455;\n    }\n    bool _469;\n    if (!_462)\n    {\n        _469 = suv.y < 0.0;\n    }\n    else\n    {\n        _469 = _462;\n    }\n    bool _476;\n    if (!_469)\n    {\n        _476 = suv.y > 1.0;\n    }\n    else\n    {\n        _476 = _469;\n    }\n    bool _483;\n    if (!_476)\n    {\n        _483 = p.z > 1.0;\n    }\n    else\n    {\n        _483 = _476;\n    }\n    if (_483)\n    {\n        return 1.0;\n    }\n    float _497 = _241.fa_pbr.w * (1.0 + (2.0 * (1.0 - fast::clamp(dot(n, l), 0.0, 1.0))));\n    float lit = 0.0;\n    for (int ix = -1; ix <= 1; ix++)\n    {\n        for (int iy = -1; iy <= 1; iy++)\n        {\n            lit += float((p.z - _497) <= fa_shadow_tex.sample(fa_shadow_smp, (suv + (float2(float(ix), float(iy)) * _241.fa_counts.y)), level(0.0)).x);\n        }\n    }\n    return lit * 0.111111111938953399658203125;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_env_brdf(thread const float& rough, thread const float& ndv)\n{\n    float4 _638 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _641 = _638.x;\n    return (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_641 * _641, exp2((-9.27999973297119140625) * ndv)) * _641) + _638.y)) + _638.zw;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_environment(thread const float3& d, thread const float& rough, constant fa_mesh_fs_params& _241)\n{\n    float _558 = rough * rough;\n    float _591 = 0.60000002384185791015625 * _558;\n    return mix(mix(_241.fa_env_horizon.xyz * 0.550000011920928955078125, mix(_241.fa_env_horizon.xyz, _241.fa_env_sky.xyz, float3(powr(fast::clamp(d.y * (1.0 - (0.699999988079071044921875 * _558)), 0.0, 1.0), 0.550000011920928955078125))), float3(smoothstep((-0.0500000007450580596923828125) - _591, 0.0500000007450580596923828125 + _591, d.y))), ((_241.fa_env_sky.xyz + _241.fa_env_horizon.xyz) * 0.5) * 0.800000011920928955078125, float3(_558 * 0.60000002384185791015625));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _241 [[buffer(1)]], constant fa_lights& _804 [[buffer(2)]], constant fa_material& _136 [[buffer(5)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    float3 _1059 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _1059 = -_1059;\n    }\n    float3 _701 = _241.fa_camera_pos.xyz - in.fa_world_pos;\n    float3 _702 = fast::normalize(_701);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _1059, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _702, short(gl_FrontFacing) };\n    Surface _707 = fa_standard_surface(param, fa_tex, fa_smp, _241, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _1081 = _707.albedo;\n    float _1082 = _707.alpha;\n    float3 _1083 = _707.normal;\n    float _1084 = _707.metallic;\n    float _1085 = _707.roughness;\n    float _1086 = _707.occlusion;\n    float3 _1087 = _707.emission;\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _1059, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _702, short(gl_FrontFacing) };\n    Surface param_2 = _707;\n    surface(param_1, param_2, _136);\n    _1081 = param_2.albedo;\n    _1082 = param_2.alpha;\n    _1083 = param_2.normal;\n    _1084 = param_2.metallic;\n    _1085 = param_2.roughness;\n    _1086 = param_2.occlusion;\n    _1087 = param_2.emission;\n    float3 result;\n    if (_241.fa_emissive.w > 0.5)\n    {\n        result = _1081;\n    }\n    else\n    {\n        float3 _729 = fast::normalize(_1083);\n        float _736 = fast::clamp(_1084, 0.0, 1.0);\n        float _740 = fast::clamp(_1085, 0.0500000007450580596923828125, 1.0);\n        float _744 = _740 * _740;\n        float _748 = _744 * _744;\n        float _754 = fast::max(dot(_729, _702), 9.9999997473787516355514526367188e-05);\n        float3 _760 = _1081 * (1.0 - _736);\n        float3 _768 = mix(float3(0.039999999105930328369140625), _1081, float3(_736));\n        float3 lit = (_241.fa_ambient.xyz * _760) * _1086;\n        int _781 = int(_241.fa_counts.x);\n        float3 l;\n        for (int li = 0; li < 32; li++)\n        {\n            if (li >= _781)\n            {\n                break;\n            }\n            float atten = 1.0;\n            bool _810 = _804.fa_light_color[li].w < 0.5;\n            if (_810)\n            {\n                l = fast::normalize(_804.fa_light_pos[li].xyz);\n            }\n            else\n            {\n                float3 _827 = _804.fa_light_pos[li].xyz - in.fa_world_pos;\n                float _830 = length(_827);\n                l = _827 / float3(fast::max(_830, 9.9999997473787516355514526367188e-05));\n                float _845 = _830 / fast::max(_804.fa_light_pos[li].w, 0.001000000047497451305389404296875);\n                float _851 = fast::clamp(1.0 - (_845 * _845), 0.0, 1.0);\n                atten = _851 * _851;\n                if (_804.fa_light_color[li].w > 1.5)\n                {\n                    atten *= smoothstep(_804.fa_light_dir[li].w, mix(_804.fa_light_dir[li].w, 1.0, 0.25), dot(-l, fast::normalize(_804.fa_light_dir[li].xyz)));\n                }\n            }\n            float _884 = fast::max(dot(_729, l), 0.0);\n            if (_810 && (li == 0))\n            {\n                float3 param_3 = _1059;\n                float3 param_4 = l;\n                atten *= fa_shadow_factor(param_3, param_4, _241, in.fa_shadow_pos, fa_shadow_tex, fa_shadow_smp);\n            }\n            float3 _903 = fast::normalize(l + _702);\n            float _908 = fast::max(dot(_729, _903), 0.0);\n            float _921 = ((_908 * _908) * (_748 - 1.0)) + 1.0;\n            lit += (((_760 + (((_768 + ((float3(1.0) - _768) * powr(1.0 - fast::max(dot(_702, _903), 0.0), 5.0))) * (((_748 / ((3.1415927410125732421875 * _921) * _921)) * (0.5 / fast::max(mix((2.0 * _884) * _754, _884 + _754, _744), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _884))) * _804.fa_light_color[li].xyz) * (_884 * atten));\n        }\n        float param_5 = _740;\n        float param_6 = _754;\n        float2 _989 = fa_env_brdf(param_5, param_6);\n        float3 param_7 = reflect(-_702, _729);\n        float param_8 = _740;\n        float3 _1007 = lit;\n        float3 _1008 = _1007 + ((fa_environment(param_7, param_8, _241) * ((_768 * _989.x) + float3(_989.y))) * _1086);\n        lit = _1008;\n        result = _1008;\n    }\n    result += _1087;\n    if (_241.fa_fog.w > 0.0)\n    {\n        float _1032 = _241.fa_fog.w * length(_701);\n        result = mix(result, _241.fa_fog.xyz, float3(fast::clamp(1.0 - exp((-_1032) * _1032), 0.0, 1.0)));\n    }\n    out.fa_frag_color = float4(result, _1082);\n    return out;\n}\n\n",
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
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_136",
            "msl_buffer_n": 5
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 192,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_241",
            "msl_buffer_n": 1
          },
          {
            "slot": 2,
            "stage": "fragment",
            "size": 1536,
            "struct_name": "fa_lights",
            "inst_name": "_804",
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
