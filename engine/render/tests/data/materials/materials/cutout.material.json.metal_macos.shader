{
  "format": "factoria.shader/1",
  "engine": "0.31.0",
  "template": "5dd0da916b10a9a6f999383491342fc1c21819329ed9afcc0f9d0e7d6522a261",
  "slang": "metal_macos",
  "params": [
    "alphaCutoff"
  ],
  "textures": [
    "mask"
  ],
  "programs": {
    "mesh": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float4 fa_shadow_pos [[user(locn5)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n};\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _129)\n{\n    float3 _67 = cross(model[1].xyz, model[2].xyz);\n    float _73 = (dot(model[0].xyz, _67) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_67 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _73, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _73), texcoord0 * _129.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _129, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& fa_shadow_pos, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _158 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _129);\n    float3 _276 = _158.world_pos;\n    float4 _165 = float4(_276, 1.0);\n    fa_world_pos = _276;\n    fa_world_normal = _158.world_normal;\n    fa_world_tangent = _158.world_tangent;\n    fa_uv = _158.uv;\n    fa_vertex_color = _158.color;\n    fa_shadow_pos = _129.fa_light_vp * _165;\n    gl_Position = _129.fa_view_proj * _165;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _129 [[buffer(0)]])\n{\n    main0_out out = {};\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5, _129, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_shadow_pos, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n};\n\nstruct fa_material\n{\n    float alphaCutoff;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n};\n\nstruct fa_lights\n{\n    float4 fa_light_pos[32];\n    float4 fa_light_color[32];\n    float4 fa_light_dir[32];\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float4 fa_shadow_pos [[user(locn5)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _203 = fa_linear_to_srgb(param);\n        c = _203;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _212 = fa_srgb_to_linear(param_1);\n            c = _212;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _68;\n    if (bool(i.front_facing))\n    {\n        _68 = i.world_normal;\n    }\n    else\n    {\n        _68 = -i.world_normal;\n    }\n    float3 _93 = fast::normalize(i.world_tangent.xyz - (_68 * dot(_68, i.world_tangent.xyz)));\n    float3 _121 = fast::normalize(((_93 * m.x) + ((cross(_68, _93) * i.world_tangent.w) * m.y)) + (_68 * m.z));\n    float3 _124;\n    if (bool(i.front_facing))\n    {\n        _124 = _121;\n    }\n    else\n    {\n        _124 = -_121;\n    }\n    return _124;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _237, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _237.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _249 = fa_tex_fix(param_2, param_3);\n    float4 _1339 = base_t;\n    _1339.x = _249.x;\n    _1339.y = _249.y;\n    _1339.z = _249.z;\n    base_t = _1339;\n    float4 _265 = (_1339 * _237.fa_base_color) * i.vertex_color;\n    float3 _1323 = i.world_normal;\n    if (_237.fa_maps.z > 0.5)\n    {\n        float param_4 = _237.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _299 = fa_tex_fix(param_6, param_7);\n        float3 _302 = (_299 * 2.0) - float3(1.0);\n        float2 _307 = _302.xy * _237.fa_maps.x;\n        float3 _1347 = _302;\n        _1347.x = _307.x;\n        _1347.y = _307.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _1347;\n        _1323 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _237.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _336 = fa_tex_fix(param_12, param_13);\n    float4 _1350 = mrt;\n    _1350.x = _336.x;\n    _1350.y = _336.y;\n    _1350.z = _336.z;\n    mrt = _1350;\n    float param_14 = _237.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = fa_occlusion_tex.sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _377 = fa_tex_fix(param_16, param_17);\n    float param_18 = _237.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _404 = fa_tex_fix(param_20, param_21);\n    return Surface{ _265.xyz, _265.w, _1323, fast::clamp(_237.fa_pbr.x * _336.z, 0.0, 1.0), fast::clamp(_237.fa_pbr.y * _336.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_237.fa_maps.y * (_377.x - 1.0)), _237.fa_emissive.xyz + (_237.fa_model_emissive.xyz * _404) };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread Surface& s, texture2d<float> mask, sampler mask_smp)\n{\n    s.alpha = mask.sample(mask_smp, (i.uv * 2.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _237, thread float4& fa_shadow_pos, texture2d<float> fa_shadow_tex, sampler fa_shadow_smp)\n{\n    if (_237.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    float3 _426 = fa_shadow_pos.xyz / float3(fa_shadow_pos.w);\n    float3 p = _426;\n    float2 suv = (_426.xy * 0.5) + float2(0.5);\n    if (_237.fa_counts.z > 0.5)\n    {\n        float3 _1358 = p;\n        _1358.z = (_1358.z * 0.5) + 0.5;\n        p = _1358;\n    }\n    else\n    {\n        float2 _1361 = suv;\n        _1361.y = 1.0 - _1361.y;\n        suv = _1361;\n    }\n    bool _453 = suv.x < 0.0;\n    bool _460;\n    if (!_453)\n    {\n        _460 = suv.x > 1.0;\n    }\n    else\n    {\n        _460 = _453;\n    }\n    bool _467;\n    if (!_460)\n    {\n        _467 = suv.y < 0.0;\n    }\n    else\n    {\n        _467 = _460;\n    }\n    bool _474;\n    if (!_467)\n    {\n        _474 = suv.y > 1.0;\n    }\n    else\n    {\n        _474 = _467;\n    }\n    bool _481;\n    if (!_474)\n    {\n        _481 = p.z > 1.0;\n    }\n    else\n    {\n        _481 = _474;\n    }\n    if (_481)\n    {\n        return 1.0;\n    }\n    float _495 = _237.fa_pbr.w * (1.0 + (2.0 * (1.0 - fast::clamp(dot(n, l), 0.0, 1.0))));\n    float lit = 0.0;\n    for (int ix = -1; ix <= 1; ix++)\n    {\n        for (int iy = -1; iy <= 1; iy++)\n        {\n            lit += float((p.z - _495) <= fa_shadow_tex.sample(fa_shadow_smp, (suv + (float2(float(ix), float(iy)) * _237.fa_counts.y)), level(0.0)).x);\n        }\n    }\n    return lit * 0.111111111938953399658203125;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_env_brdf(thread const float& rough, thread const float& ndv)\n{\n    float4 _636 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _639 = _636.x;\n    return (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_639 * _639, exp2((-9.27999973297119140625) * ndv)) * _639) + _636.y)) + _636.zw;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_environment(thread const float3& d, thread const float& rough, constant fa_mesh_fs_params& _237)\n{\n    float _556 = rough * rough;\n    float _589 = 0.60000002384185791015625 * _556;\n    return mix(mix(_237.fa_env_horizon.xyz * 0.550000011920928955078125, mix(_237.fa_env_horizon.xyz, _237.fa_env_sky.xyz, float3(powr(fast::clamp(d.y * (1.0 - (0.699999988079071044921875 * _556)), 0.0, 1.0), 0.550000011920928955078125))), float3(smoothstep((-0.0500000007450580596923828125) - _589, 0.0500000007450580596923828125 + _589, d.y))), ((_237.fa_env_sky.xyz + _237.fa_env_horizon.xyz) * 0.5) * 0.800000011920928955078125, float3(_556 * 0.60000002384185791015625));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _237 [[buffer(1)]], constant fa_lights& _813 [[buffer(2)]], constant fa_material& _716 [[buffer(5)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texture2d<float> mask [[texture(6)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler mask_smp [[sampler(2)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    float3 _1269 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _1269 = -_1269;\n    }\n    float3 _700 = fast::normalize(_237.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _1269, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _700, short(gl_FrontFacing) };\n    Surface _705 = fa_standard_surface(param, fa_tex, fa_smp, _237, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _1292 = _705.albedo;\n    float _1293 = _705.alpha;\n    float3 _1294 = _705.normal;\n    float _1295 = _705.metallic;\n    float _1296 = _705.roughness;\n    float _1297 = _705.occlusion;\n    float3 _1298 = _705.emission;\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _1269, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _700, short(gl_FrontFacing) };\n    Surface param_2 = _705;\n    surface(param_1, param_2, mask, mask_smp);\n    _1292 = param_2.albedo;\n    _1293 = param_2.alpha;\n    _1294 = param_2.normal;\n    _1295 = param_2.metallic;\n    _1296 = param_2.roughness;\n    _1297 = param_2.occlusion;\n    _1298 = param_2.emission;\n    if (param_2.alpha < _716.alphaCutoff)\n    {\n        discard_fragment();\n    }\n    float3 result;\n    if (_237.fa_emissive.w > 0.5)\n    {\n        result = _1292;\n    }\n    else\n    {\n        float3 _738 = fast::normalize(_1294);\n        float _745 = fast::clamp(_1295, 0.0, 1.0);\n        float _749 = fast::clamp(_1296, 0.0500000007450580596923828125, 1.0);\n        float _753 = _749 * _749;\n        float _757 = _753 * _753;\n        float _763 = fast::max(dot(_738, _700), 9.9999997473787516355514526367188e-05);\n        float3 _769 = _1292 * (1.0 - _745);\n        float3 _777 = mix(float3(0.039999999105930328369140625), _1292, float3(_745));\n        float3 lit = (_237.fa_ambient.xyz * _769) * _1297;\n        int _790 = int(_237.fa_counts.x);\n        float3 l;\n        for (int li = 0; li < 32; li++)\n        {\n            if (li >= _790)\n            {\n                break;\n            }\n            float atten = 1.0;\n            bool _820 = _813.fa_light_color[li].w < 0.5;\n            if (_820)\n            {\n                l = fast::normalize(_813.fa_light_pos[li].xyz);\n            }\n            else\n            {\n                float3 _837 = _813.fa_light_pos[li].xyz - in.fa_world_pos;\n                float _839 = length(_837);\n                l = _837 / float3(fast::max(_839, 9.9999997473787516355514526367188e-05));\n                float _854 = _839 / fast::max(_813.fa_light_pos[li].w, 0.001000000047497451305389404296875);\n                float _860 = fast::clamp(1.0 - (_854 * _854), 0.0, 1.0);\n                atten = _860 * _860;\n                if (_813.fa_light_color[li].w > 1.5)\n                {\n                    atten *= smoothstep(_813.fa_light_dir[li].w, mix(_813.fa_light_dir[li].w, 1.0, 0.25), dot(-l, fast::normalize(_813.fa_light_dir[li].xyz)));\n                }\n            }\n            float shadow = 1.0;\n            if (_820 && (li == 0))\n            {\n                float3 param_3 = _1269;\n                float3 param_4 = l;\n                shadow = fa_shadow_factor(param_3, param_4, _237, in.fa_shadow_pos, fa_shadow_tex, fa_shadow_smp);\n            }\n            float _906 = fast::max(dot(_738, l), 0.0);\n            float _908 = atten;\n            float _909 = _908 * shadow;\n            atten = _909;\n            float3 _914 = fast::normalize(l + _700);\n            float _919 = fast::max(dot(_738, _914), 0.0);\n            float _932 = ((_919 * _919) * (_757 - 1.0)) + 1.0;\n            lit += (((_769 + (((_777 + ((float3(1.0) - _777) * powr(1.0 - fast::max(dot(_700, _914), 0.0), 5.0))) * (((_757 / ((3.1415927410125732421875 * _932) * _932)) * (0.5 / fast::max(mix((2.0 * _906) * _763, _906 + _763, _753), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _906))) * _813.fa_light_color[li].xyz) * (_906 * _909));\n        }\n        float param_5 = _749;\n        float param_6 = _763;\n        float2 _1000 = fa_env_brdf(param_5, param_6);\n        float3 param_7 = reflect(-_700, _738);\n        float param_8 = _749;\n        float3 _1018 = lit;\n        float3 _1019 = _1018 + ((fa_environment(param_7, param_8, _237) * ((_777 * _1000.x) + float3(_1000.y))) * _1297);\n        lit = _1019;\n        result = _1019;\n    }\n    result += _1298;\n    bool _1028 = _237.fa_fog.w > 0.0;\n    bool _1036;\n    if (!_1028)\n    {\n        _1036 = _237.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _1036 = _1028;\n    }\n    if (_1036)\n    {\n        float3 _1045 = in.fa_world_pos - _237.fa_camera_pos.xyz;\n        float _1052 = dot(_1045, _237.fa_fog_c.xyz);\n        bool _1056 = _237.fa_fog_c.w > 0.5;\n        float _1057;\n        if (_1056)\n        {\n            _1057 = _1052;\n        }\n        else\n        {\n            _1057 = length(_1045);\n        }\n        float _1069 = _1057 - _237.fa_fog_b.x;\n        if (_1069 > 0.0)\n        {\n            float _1078 = _237.fa_fog.w * _1069;\n            float tau = _1078 * _1078;\n            if (_237.fa_fog_b.y > 0.0)\n            {\n                float _1094;\n                if (_1056)\n                {\n                    _1094 = in.fa_world_pos.y - (_237.fa_fog_c.y * _1052);\n                }\n                else\n                {\n                    _1094 = _237.fa_camera_pos.y;\n                }\n                float _1115 = mix(_1094, in.fa_world_pos.y, fast::clamp(_237.fa_fog_b.x / _1057, 0.0, 1.0));\n                float _1119 = in.fa_world_pos.y - _1115;\n                float _1124 = _1115 - _237.fa_fog_b.z;\n                float _1129 = in.fa_world_pos.y - _237.fa_fog_b.z;\n                bool _1132 = _1124 <= 0.0;\n                bool _1133 = !_1132;\n                bool _1139;\n                if (_1133)\n                {\n                    _1139 = _237.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1139 = _1132;\n                }\n                float _1140;\n                if (_1139)\n                {\n                    _1140 = _237.fa_fog_b.y;\n                }\n                else\n                {\n                    _1140 = _237.fa_fog_b.y * exp(-fast::min(_237.fa_fog_b.w * _1124, 80.0));\n                }\n                bool _1167;\n                if (_1133)\n                {\n                    _1167 = _237.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1167 = _1132;\n                }\n                float _1168;\n                if (_1167)\n                {\n                    _1168 = _237.fa_fog_b.y * _1124;\n                }\n                else\n                {\n                    _1168 = (_237.fa_fog_b.y * (1.0 - exp(-fast::min(_237.fa_fog_b.w * _1124, 80.0)))) / _237.fa_fog_b.w;\n                }\n                bool _1193 = _1129 <= 0.0;\n                bool _1200;\n                if (!_1193)\n                {\n                    _1200 = _237.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1200 = _1193;\n                }\n                float _1201;\n                if (_1200)\n                {\n                    _1201 = _237.fa_fog_b.y * _1129;\n                }\n                else\n                {\n                    _1201 = (_237.fa_fog_b.y * (1.0 - exp(-fast::min(_237.fa_fog_b.w * _1129, 80.0)))) / _237.fa_fog_b.w;\n                }\n                float _1228;\n                if (abs(_1119) < 0.001000000047497451305389404296875)\n                {\n                    _1228 = _1140;\n                }\n                else\n                {\n                    _1228 = (_1201 - _1168) / _1119;\n                }\n                tau += (_1069 * fast::max(_1228, 0.0));\n            }\n            result = mix(result, _237.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _1293);\n    return out;\n}\n\n",
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
            "size": 224,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_237",
            "msl_buffer_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_716",
            "msl_buffer_n": 5
          },
          {
            "slot": 2,
            "stage": "fragment",
            "size": 1536,
            "struct_name": "fa_lights",
            "inst_name": "_813",
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
          },
          {
            "texture": {
              "slot": 6,
              "stage": "fragment",
              "name": "mask",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 6
            }
          }
        ],
        "samplers": [
          {
            "slot": 2,
            "stage": "fragment",
            "name": "mask_smp",
            "sampler_type": "filtering",
            "msl_sampler_n": 2
          },
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
            "name": "mask_mask_smp",
            "view_name": "mask",
            "sampler_name": "mask_smp",
            "view_slot": 6,
            "sampler_slot": 2
          },
          {
            "slot": 6,
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float4 fa_shadow_pos [[user(locn5)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n    float4 fa_joints [[attribute(9)]];\n    float4 fa_weights [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _181)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _172 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_181.fa_joint_rows[_172] * weights[i]);\n        r1 += (_181.fa_joint_rows[_172 + 1] * weights[i]);\n        r2 += (_181.fa_joint_rows[_172 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _134)\n{\n    float3 _72 = cross(model[1].xyz, model[2].xyz);\n    float _78 = (dot(model[0].xyz, _72) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_72 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _78, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _78), texcoord0 * _134.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _134, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& fa_shadow_pos, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _271 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _134);\n    float3 _397 = _271.world_pos;\n    float4 _278 = float4(_397, 1.0);\n    fa_world_pos = _397;\n    fa_world_normal = _271.world_normal;\n    fa_world_tangent = _271.world_tangent;\n    fa_uv = _271.uv;\n    fa_vertex_color = _271.color;\n    fa_shadow_pos = _134.fa_light_vp * _278;\n    gl_Position = _134.fa_view_proj * _278;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _134 [[buffer(0)]], constant fa_skin& _181 [[buffer(3)]])\n{\n    main0_out out = {};\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float4x4 param_2 = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _181);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7, _134, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_shadow_pos, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n};\n\nstruct fa_material\n{\n    float alphaCutoff;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n};\n\nstruct fa_lights\n{\n    float4 fa_light_pos[32];\n    float4 fa_light_color[32];\n    float4 fa_light_dir[32];\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float4 fa_shadow_pos [[user(locn5)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _203 = fa_linear_to_srgb(param);\n        c = _203;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _212 = fa_srgb_to_linear(param_1);\n            c = _212;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _68;\n    if (bool(i.front_facing))\n    {\n        _68 = i.world_normal;\n    }\n    else\n    {\n        _68 = -i.world_normal;\n    }\n    float3 _93 = fast::normalize(i.world_tangent.xyz - (_68 * dot(_68, i.world_tangent.xyz)));\n    float3 _121 = fast::normalize(((_93 * m.x) + ((cross(_68, _93) * i.world_tangent.w) * m.y)) + (_68 * m.z));\n    float3 _124;\n    if (bool(i.front_facing))\n    {\n        _124 = _121;\n    }\n    else\n    {\n        _124 = -_121;\n    }\n    return _124;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _237, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _237.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _249 = fa_tex_fix(param_2, param_3);\n    float4 _1339 = base_t;\n    _1339.x = _249.x;\n    _1339.y = _249.y;\n    _1339.z = _249.z;\n    base_t = _1339;\n    float4 _265 = (_1339 * _237.fa_base_color) * i.vertex_color;\n    float3 _1323 = i.world_normal;\n    if (_237.fa_maps.z > 0.5)\n    {\n        float param_4 = _237.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _299 = fa_tex_fix(param_6, param_7);\n        float3 _302 = (_299 * 2.0) - float3(1.0);\n        float2 _307 = _302.xy * _237.fa_maps.x;\n        float3 _1347 = _302;\n        _1347.x = _307.x;\n        _1347.y = _307.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _1347;\n        _1323 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _237.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _336 = fa_tex_fix(param_12, param_13);\n    float4 _1350 = mrt;\n    _1350.x = _336.x;\n    _1350.y = _336.y;\n    _1350.z = _336.z;\n    mrt = _1350;\n    float param_14 = _237.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = fa_occlusion_tex.sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _377 = fa_tex_fix(param_16, param_17);\n    float param_18 = _237.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _404 = fa_tex_fix(param_20, param_21);\n    return Surface{ _265.xyz, _265.w, _1323, fast::clamp(_237.fa_pbr.x * _336.z, 0.0, 1.0), fast::clamp(_237.fa_pbr.y * _336.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_237.fa_maps.y * (_377.x - 1.0)), _237.fa_emissive.xyz + (_237.fa_model_emissive.xyz * _404) };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread Surface& s, texture2d<float> mask, sampler mask_smp)\n{\n    s.alpha = mask.sample(mask_smp, (i.uv * 2.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _237, thread float4& fa_shadow_pos, texture2d<float> fa_shadow_tex, sampler fa_shadow_smp)\n{\n    if (_237.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    float3 _426 = fa_shadow_pos.xyz / float3(fa_shadow_pos.w);\n    float3 p = _426;\n    float2 suv = (_426.xy * 0.5) + float2(0.5);\n    if (_237.fa_counts.z > 0.5)\n    {\n        float3 _1358 = p;\n        _1358.z = (_1358.z * 0.5) + 0.5;\n        p = _1358;\n    }\n    else\n    {\n        float2 _1361 = suv;\n        _1361.y = 1.0 - _1361.y;\n        suv = _1361;\n    }\n    bool _453 = suv.x < 0.0;\n    bool _460;\n    if (!_453)\n    {\n        _460 = suv.x > 1.0;\n    }\n    else\n    {\n        _460 = _453;\n    }\n    bool _467;\n    if (!_460)\n    {\n        _467 = suv.y < 0.0;\n    }\n    else\n    {\n        _467 = _460;\n    }\n    bool _474;\n    if (!_467)\n    {\n        _474 = suv.y > 1.0;\n    }\n    else\n    {\n        _474 = _467;\n    }\n    bool _481;\n    if (!_474)\n    {\n        _481 = p.z > 1.0;\n    }\n    else\n    {\n        _481 = _474;\n    }\n    if (_481)\n    {\n        return 1.0;\n    }\n    float _495 = _237.fa_pbr.w * (1.0 + (2.0 * (1.0 - fast::clamp(dot(n, l), 0.0, 1.0))));\n    float lit = 0.0;\n    for (int ix = -1; ix <= 1; ix++)\n    {\n        for (int iy = -1; iy <= 1; iy++)\n        {\n            lit += float((p.z - _495) <= fa_shadow_tex.sample(fa_shadow_smp, (suv + (float2(float(ix), float(iy)) * _237.fa_counts.y)), level(0.0)).x);\n        }\n    }\n    return lit * 0.111111111938953399658203125;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_env_brdf(thread const float& rough, thread const float& ndv)\n{\n    float4 _636 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _639 = _636.x;\n    return (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_639 * _639, exp2((-9.27999973297119140625) * ndv)) * _639) + _636.y)) + _636.zw;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_environment(thread const float3& d, thread const float& rough, constant fa_mesh_fs_params& _237)\n{\n    float _556 = rough * rough;\n    float _589 = 0.60000002384185791015625 * _556;\n    return mix(mix(_237.fa_env_horizon.xyz * 0.550000011920928955078125, mix(_237.fa_env_horizon.xyz, _237.fa_env_sky.xyz, float3(powr(fast::clamp(d.y * (1.0 - (0.699999988079071044921875 * _556)), 0.0, 1.0), 0.550000011920928955078125))), float3(smoothstep((-0.0500000007450580596923828125) - _589, 0.0500000007450580596923828125 + _589, d.y))), ((_237.fa_env_sky.xyz + _237.fa_env_horizon.xyz) * 0.5) * 0.800000011920928955078125, float3(_556 * 0.60000002384185791015625));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _237 [[buffer(1)]], constant fa_lights& _813 [[buffer(2)]], constant fa_material& _716 [[buffer(5)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texture2d<float> mask [[texture(6)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler mask_smp [[sampler(2)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    float3 _1269 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _1269 = -_1269;\n    }\n    float3 _700 = fast::normalize(_237.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _1269, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _700, short(gl_FrontFacing) };\n    Surface _705 = fa_standard_surface(param, fa_tex, fa_smp, _237, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _1292 = _705.albedo;\n    float _1293 = _705.alpha;\n    float3 _1294 = _705.normal;\n    float _1295 = _705.metallic;\n    float _1296 = _705.roughness;\n    float _1297 = _705.occlusion;\n    float3 _1298 = _705.emission;\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _1269, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _700, short(gl_FrontFacing) };\n    Surface param_2 = _705;\n    surface(param_1, param_2, mask, mask_smp);\n    _1292 = param_2.albedo;\n    _1293 = param_2.alpha;\n    _1294 = param_2.normal;\n    _1295 = param_2.metallic;\n    _1296 = param_2.roughness;\n    _1297 = param_2.occlusion;\n    _1298 = param_2.emission;\n    if (param_2.alpha < _716.alphaCutoff)\n    {\n        discard_fragment();\n    }\n    float3 result;\n    if (_237.fa_emissive.w > 0.5)\n    {\n        result = _1292;\n    }\n    else\n    {\n        float3 _738 = fast::normalize(_1294);\n        float _745 = fast::clamp(_1295, 0.0, 1.0);\n        float _749 = fast::clamp(_1296, 0.0500000007450580596923828125, 1.0);\n        float _753 = _749 * _749;\n        float _757 = _753 * _753;\n        float _763 = fast::max(dot(_738, _700), 9.9999997473787516355514526367188e-05);\n        float3 _769 = _1292 * (1.0 - _745);\n        float3 _777 = mix(float3(0.039999999105930328369140625), _1292, float3(_745));\n        float3 lit = (_237.fa_ambient.xyz * _769) * _1297;\n        int _790 = int(_237.fa_counts.x);\n        float3 l;\n        for (int li = 0; li < 32; li++)\n        {\n            if (li >= _790)\n            {\n                break;\n            }\n            float atten = 1.0;\n            bool _820 = _813.fa_light_color[li].w < 0.5;\n            if (_820)\n            {\n                l = fast::normalize(_813.fa_light_pos[li].xyz);\n            }\n            else\n            {\n                float3 _837 = _813.fa_light_pos[li].xyz - in.fa_world_pos;\n                float _839 = length(_837);\n                l = _837 / float3(fast::max(_839, 9.9999997473787516355514526367188e-05));\n                float _854 = _839 / fast::max(_813.fa_light_pos[li].w, 0.001000000047497451305389404296875);\n                float _860 = fast::clamp(1.0 - (_854 * _854), 0.0, 1.0);\n                atten = _860 * _860;\n                if (_813.fa_light_color[li].w > 1.5)\n                {\n                    atten *= smoothstep(_813.fa_light_dir[li].w, mix(_813.fa_light_dir[li].w, 1.0, 0.25), dot(-l, fast::normalize(_813.fa_light_dir[li].xyz)));\n                }\n            }\n            float shadow = 1.0;\n            if (_820 && (li == 0))\n            {\n                float3 param_3 = _1269;\n                float3 param_4 = l;\n                shadow = fa_shadow_factor(param_3, param_4, _237, in.fa_shadow_pos, fa_shadow_tex, fa_shadow_smp);\n            }\n            float _906 = fast::max(dot(_738, l), 0.0);\n            float _908 = atten;\n            float _909 = _908 * shadow;\n            atten = _909;\n            float3 _914 = fast::normalize(l + _700);\n            float _919 = fast::max(dot(_738, _914), 0.0);\n            float _932 = ((_919 * _919) * (_757 - 1.0)) + 1.0;\n            lit += (((_769 + (((_777 + ((float3(1.0) - _777) * powr(1.0 - fast::max(dot(_700, _914), 0.0), 5.0))) * (((_757 / ((3.1415927410125732421875 * _932) * _932)) * (0.5 / fast::max(mix((2.0 * _906) * _763, _906 + _763, _753), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _906))) * _813.fa_light_color[li].xyz) * (_906 * _909));\n        }\n        float param_5 = _749;\n        float param_6 = _763;\n        float2 _1000 = fa_env_brdf(param_5, param_6);\n        float3 param_7 = reflect(-_700, _738);\n        float param_8 = _749;\n        float3 _1018 = lit;\n        float3 _1019 = _1018 + ((fa_environment(param_7, param_8, _237) * ((_777 * _1000.x) + float3(_1000.y))) * _1297);\n        lit = _1019;\n        result = _1019;\n    }\n    result += _1298;\n    bool _1028 = _237.fa_fog.w > 0.0;\n    bool _1036;\n    if (!_1028)\n    {\n        _1036 = _237.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _1036 = _1028;\n    }\n    if (_1036)\n    {\n        float3 _1045 = in.fa_world_pos - _237.fa_camera_pos.xyz;\n        float _1052 = dot(_1045, _237.fa_fog_c.xyz);\n        bool _1056 = _237.fa_fog_c.w > 0.5;\n        float _1057;\n        if (_1056)\n        {\n            _1057 = _1052;\n        }\n        else\n        {\n            _1057 = length(_1045);\n        }\n        float _1069 = _1057 - _237.fa_fog_b.x;\n        if (_1069 > 0.0)\n        {\n            float _1078 = _237.fa_fog.w * _1069;\n            float tau = _1078 * _1078;\n            if (_237.fa_fog_b.y > 0.0)\n            {\n                float _1094;\n                if (_1056)\n                {\n                    _1094 = in.fa_world_pos.y - (_237.fa_fog_c.y * _1052);\n                }\n                else\n                {\n                    _1094 = _237.fa_camera_pos.y;\n                }\n                float _1115 = mix(_1094, in.fa_world_pos.y, fast::clamp(_237.fa_fog_b.x / _1057, 0.0, 1.0));\n                float _1119 = in.fa_world_pos.y - _1115;\n                float _1124 = _1115 - _237.fa_fog_b.z;\n                float _1129 = in.fa_world_pos.y - _237.fa_fog_b.z;\n                bool _1132 = _1124 <= 0.0;\n                bool _1133 = !_1132;\n                bool _1139;\n                if (_1133)\n                {\n                    _1139 = _237.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1139 = _1132;\n                }\n                float _1140;\n                if (_1139)\n                {\n                    _1140 = _237.fa_fog_b.y;\n                }\n                else\n                {\n                    _1140 = _237.fa_fog_b.y * exp(-fast::min(_237.fa_fog_b.w * _1124, 80.0));\n                }\n                bool _1167;\n                if (_1133)\n                {\n                    _1167 = _237.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1167 = _1132;\n                }\n                float _1168;\n                if (_1167)\n                {\n                    _1168 = _237.fa_fog_b.y * _1124;\n                }\n                else\n                {\n                    _1168 = (_237.fa_fog_b.y * (1.0 - exp(-fast::min(_237.fa_fog_b.w * _1124, 80.0)))) / _237.fa_fog_b.w;\n                }\n                bool _1193 = _1129 <= 0.0;\n                bool _1200;\n                if (!_1193)\n                {\n                    _1200 = _237.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1200 = _1193;\n                }\n                float _1201;\n                if (_1200)\n                {\n                    _1201 = _237.fa_fog_b.y * _1129;\n                }\n                else\n                {\n                    _1201 = (_237.fa_fog_b.y * (1.0 - exp(-fast::min(_237.fa_fog_b.w * _1129, 80.0)))) / _237.fa_fog_b.w;\n                }\n                float _1228;\n                if (abs(_1119) < 0.001000000047497451305389404296875)\n                {\n                    _1228 = _1140;\n                }\n                else\n                {\n                    _1228 = (_1201 - _1168) / _1119;\n                }\n                tau += (_1069 * fast::max(_1228, 0.0));\n            }\n            result = mix(result, _237.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _1293);\n    return out;\n}\n\n",
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
            "size": 224,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_237",
            "msl_buffer_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_716",
            "msl_buffer_n": 5
          },
          {
            "slot": 2,
            "stage": "fragment",
            "size": 1536,
            "struct_name": "fa_lights",
            "inst_name": "_813",
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
          },
          {
            "texture": {
              "slot": 6,
              "stage": "fragment",
              "name": "mask",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 6
            }
          }
        ],
        "samplers": [
          {
            "slot": 2,
            "stage": "fragment",
            "name": "mask_smp",
            "sampler_type": "filtering",
            "msl_sampler_n": 2
          },
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
            "name": "mask_mask_smp",
            "view_name": "mask",
            "sampler_name": "mask_smp",
            "view_slot": 6,
            "sampler_slot": 2
          },
          {
            "slot": 6,
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
    "prepass": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n};\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _129)\n{\n    float3 _67 = cross(model[1].xyz, model[2].xyz);\n    float _73 = (dot(model[0].xyz, _67) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_67 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _73, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _73), texcoord0 * _129.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_prepass_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _129, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float& fa_pre_depth, thread float3& fa_pre_r0, thread float3& fa_pre_r1, thread float3& fa_pre_r2, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _158 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _129);\n    float3 _305 = _158.world_pos;\n    float4 _169 = float4(_305, 1.0);\n    fa_world_pos = _305;\n    fa_world_normal = _158.world_normal;\n    fa_world_tangent = _158.world_tangent;\n    fa_uv = _158.uv;\n    fa_vertex_color = _158.color;\n    fa_pre_depth = -(_129.fa_light_vp * _169).z;\n    fa_pre_r0 = float3(_129.fa_light_vp[0].x, _129.fa_light_vp[1].x, _129.fa_light_vp[2].x);\n    fa_pre_r1 = float3(_129.fa_light_vp[0].y, _129.fa_light_vp[1].y, _129.fa_light_vp[2].y);\n    fa_pre_r2 = float3(_129.fa_light_vp[0].z, _129.fa_light_vp[1].z, _129.fa_light_vp[2].z);\n    gl_Position = _129.fa_view_proj * _169;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _129 [[buffer(0)]])\n{\n    main0_out out = {};\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5, _129, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_pre_depth, out.fa_pre_r0, out.fa_pre_r1, out.fa_pre_r2, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n};\n\nstruct fa_material\n{\n    float alphaCutoff;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _189 = fa_linear_to_srgb(param);\n        c = _189;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _198 = fa_srgb_to_linear(param_1);\n            c = _198;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _54;\n    if (bool(i.front_facing))\n    {\n        _54 = i.world_normal;\n    }\n    else\n    {\n        _54 = -i.world_normal;\n    }\n    float3 _79 = fast::normalize(i.world_tangent.xyz - (_54 * dot(_54, i.world_tangent.xyz)));\n    float3 _107 = fast::normalize(((_79 * m.x) + ((cross(_54, _79) * i.world_tangent.w) * m.y)) + (_54 * m.z));\n    float3 _110;\n    if (bool(i.front_facing))\n    {\n        _110 = _107;\n    }\n    else\n    {\n        _110 = -_107;\n    }\n    return _110;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _223, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _223.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _235 = fa_tex_fix(param_2, param_3);\n    float4 _600 = base_t;\n    _600.x = _235.x;\n    _600.y = _235.y;\n    _600.z = _235.z;\n    base_t = _600;\n    float4 _251 = (_600 * _223.fa_base_color) * i.vertex_color;\n    float3 _581 = i.world_normal;\n    if (_223.fa_maps.z > 0.5)\n    {\n        float param_4 = _223.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _285 = fa_tex_fix(param_6, param_7);\n        float3 _288 = (_285 * 2.0) - float3(1.0);\n        float2 _293 = _288.xy * _223.fa_maps.x;\n        float3 _608 = _288;\n        _608.x = _293.x;\n        _608.y = _293.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _608;\n        _581 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _223.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _322 = fa_tex_fix(param_12, param_13);\n    float4 _611 = mrt;\n    _611.x = _322.x;\n    _611.y = _322.y;\n    _611.z = _322.z;\n    mrt = _611;\n    float param_14 = _223.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = fa_occlusion_tex.sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _363 = fa_tex_fix(param_16, param_17);\n    float param_18 = _223.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _390 = fa_tex_fix(param_20, param_21);\n    return Surface{ _251.xyz, _251.w, _581, fast::clamp(_223.fa_pbr.x * _322.z, 0.0, 1.0), fast::clamp(_223.fa_pbr.y * _322.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_223.fa_maps.y * (_363.x - 1.0)), _223.fa_emissive.xyz + (_223.fa_model_emissive.xyz * _390) };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread Surface& s, texture2d<float> mask, sampler mask_smp)\n{\n    s.alpha = mask.sample(mask_smp, (i.uv * 2.0)).x;\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _223 [[buffer(1)]], constant fa_material& _451 [[buffer(5)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], texture2d<float> mask [[texture(5)]], sampler fa_smp [[sampler(0)]], sampler mask_smp [[sampler(2)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    float3 _528 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _528 = -_528;\n    }\n    float3 _435 = fast::normalize(_223.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _528, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _435, short(gl_FrontFacing) };\n    Surface _440 = fa_standard_surface(param, fa_tex, fa_smp, _223, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _552 = _440.normal;\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _528, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _435, short(gl_FrontFacing) };\n    Surface param_2 = _440;\n    surface(param_1, param_2, mask, mask_smp);\n    _552 = param_2.normal;\n    if (param_2.alpha < _451.alphaCutoff)\n    {\n        discard_fragment();\n    }\n    float3 _461 = fast::normalize(_552);\n    float3 _476 = fast::normalize(float3(dot(in.fa_pre_r0, _461), dot(in.fa_pre_r1, _461), dot(in.fa_pre_r2, _461)));\n    float _488 = _476.z;\n    float2 e = _476.xy / float2((abs(_476.x) + abs(_476.y)) + abs(_488));\n    if (_488 < 0.0)\n    {\n        e = (float2(1.0) - abs(e.yx)) * float2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    out.fa_frag_color = float4(fast::min(in.fa_pre_depth, 60000.0), e, 1.0);\n    return out;\n}\n\n",
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
            "size": 224,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_223",
            "msl_buffer_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_451",
            "msl_buffer_n": 5
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
              "slot": 2,
              "stage": "fragment",
              "name": "fa_normal_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 1
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
              "msl_texture_n": 2
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
              "msl_texture_n": 3
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
              "msl_texture_n": 4
            }
          },
          {
            "texture": {
              "slot": 6,
              "stage": "fragment",
              "name": "mask",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 5
            }
          }
        ],
        "samplers": [
          {
            "slot": 2,
            "stage": "fragment",
            "name": "mask_smp",
            "sampler_type": "filtering",
            "msl_sampler_n": 2
          },
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_smp",
            "sampler_type": "filtering",
            "msl_sampler_n": 0
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
            "name": "mask_mask_smp",
            "view_name": "mask",
            "sampler_name": "mask_smp",
            "view_slot": 6,
            "sampler_slot": 2
          }
        ]
      }
    },
    "prepass_skin": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n    float4 fa_joints [[attribute(9)]];\n    float4 fa_weights [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _181)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _172 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_181.fa_joint_rows[_172] * weights[i]);\n        r1 += (_181.fa_joint_rows[_172 + 1] * weights[i]);\n        r2 += (_181.fa_joint_rows[_172 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _134)\n{\n    float3 _72 = cross(model[1].xyz, model[2].xyz);\n    float _78 = (dot(model[0].xyz, _72) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_72 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _78, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _78), texcoord0 * _134.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_prepass_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _134, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float& fa_pre_depth, thread float3& fa_pre_r0, thread float3& fa_pre_r1, thread float3& fa_pre_r2, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _271 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _134);\n    float3 _426 = _271.world_pos;\n    float4 _282 = float4(_426, 1.0);\n    fa_world_pos = _426;\n    fa_world_normal = _271.world_normal;\n    fa_world_tangent = _271.world_tangent;\n    fa_uv = _271.uv;\n    fa_vertex_color = _271.color;\n    fa_pre_depth = -(_134.fa_light_vp * _282).z;\n    fa_pre_r0 = float3(_134.fa_light_vp[0].x, _134.fa_light_vp[1].x, _134.fa_light_vp[2].x);\n    fa_pre_r1 = float3(_134.fa_light_vp[0].y, _134.fa_light_vp[1].y, _134.fa_light_vp[2].y);\n    fa_pre_r2 = float3(_134.fa_light_vp[0].z, _134.fa_light_vp[1].z, _134.fa_light_vp[2].z);\n    gl_Position = _134.fa_view_proj * _282;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _134 [[buffer(0)]], constant fa_skin& _181 [[buffer(3)]])\n{\n    main0_out out = {};\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float4x4 param_2 = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _181);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7, _134, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_pre_depth, out.fa_pre_r0, out.fa_pre_r1, out.fa_pre_r2, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n};\n\nstruct fa_material\n{\n    float alphaCutoff;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _189 = fa_linear_to_srgb(param);\n        c = _189;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _198 = fa_srgb_to_linear(param_1);\n            c = _198;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _54;\n    if (bool(i.front_facing))\n    {\n        _54 = i.world_normal;\n    }\n    else\n    {\n        _54 = -i.world_normal;\n    }\n    float3 _79 = fast::normalize(i.world_tangent.xyz - (_54 * dot(_54, i.world_tangent.xyz)));\n    float3 _107 = fast::normalize(((_79 * m.x) + ((cross(_54, _79) * i.world_tangent.w) * m.y)) + (_54 * m.z));\n    float3 _110;\n    if (bool(i.front_facing))\n    {\n        _110 = _107;\n    }\n    else\n    {\n        _110 = -_107;\n    }\n    return _110;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _223, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _223.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _235 = fa_tex_fix(param_2, param_3);\n    float4 _600 = base_t;\n    _600.x = _235.x;\n    _600.y = _235.y;\n    _600.z = _235.z;\n    base_t = _600;\n    float4 _251 = (_600 * _223.fa_base_color) * i.vertex_color;\n    float3 _581 = i.world_normal;\n    if (_223.fa_maps.z > 0.5)\n    {\n        float param_4 = _223.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _285 = fa_tex_fix(param_6, param_7);\n        float3 _288 = (_285 * 2.0) - float3(1.0);\n        float2 _293 = _288.xy * _223.fa_maps.x;\n        float3 _608 = _288;\n        _608.x = _293.x;\n        _608.y = _293.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _608;\n        _581 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _223.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _322 = fa_tex_fix(param_12, param_13);\n    float4 _611 = mrt;\n    _611.x = _322.x;\n    _611.y = _322.y;\n    _611.z = _322.z;\n    mrt = _611;\n    float param_14 = _223.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = fa_occlusion_tex.sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _363 = fa_tex_fix(param_16, param_17);\n    float param_18 = _223.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _390 = fa_tex_fix(param_20, param_21);\n    return Surface{ _251.xyz, _251.w, _581, fast::clamp(_223.fa_pbr.x * _322.z, 0.0, 1.0), fast::clamp(_223.fa_pbr.y * _322.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_223.fa_maps.y * (_363.x - 1.0)), _223.fa_emissive.xyz + (_223.fa_model_emissive.xyz * _390) };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread Surface& s, texture2d<float> mask, sampler mask_smp)\n{\n    s.alpha = mask.sample(mask_smp, (i.uv * 2.0)).x;\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _223 [[buffer(1)]], constant fa_material& _451 [[buffer(5)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], texture2d<float> mask [[texture(5)]], sampler fa_smp [[sampler(0)]], sampler mask_smp [[sampler(2)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    float3 _528 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _528 = -_528;\n    }\n    float3 _435 = fast::normalize(_223.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _528, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _435, short(gl_FrontFacing) };\n    Surface _440 = fa_standard_surface(param, fa_tex, fa_smp, _223, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _552 = _440.normal;\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _528, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _435, short(gl_FrontFacing) };\n    Surface param_2 = _440;\n    surface(param_1, param_2, mask, mask_smp);\n    _552 = param_2.normal;\n    if (param_2.alpha < _451.alphaCutoff)\n    {\n        discard_fragment();\n    }\n    float3 _461 = fast::normalize(_552);\n    float3 _476 = fast::normalize(float3(dot(in.fa_pre_r0, _461), dot(in.fa_pre_r1, _461), dot(in.fa_pre_r2, _461)));\n    float _488 = _476.z;\n    float2 e = _476.xy / float2((abs(_476.x) + abs(_476.y)) + abs(_488));\n    if (_488 < 0.0)\n    {\n        e = (float2(1.0) - abs(e.yx)) * float2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    out.fa_frag_color = float4(fast::min(in.fa_pre_depth, 60000.0), e, 1.0);\n    return out;\n}\n\n",
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
            "size": 224,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_223",
            "msl_buffer_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_451",
            "msl_buffer_n": 5
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
              "slot": 2,
              "stage": "fragment",
              "name": "fa_normal_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 1
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
              "msl_texture_n": 2
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
              "msl_texture_n": 3
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
              "msl_texture_n": 4
            }
          },
          {
            "texture": {
              "slot": 6,
              "stage": "fragment",
              "name": "mask",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 5
            }
          }
        ],
        "samplers": [
          {
            "slot": 2,
            "stage": "fragment",
            "name": "mask_smp",
            "sampler_type": "filtering",
            "msl_sampler_n": 2
          },
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_smp",
            "sampler_type": "filtering",
            "msl_sampler_n": 0
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
            "name": "mask_mask_smp",
            "view_name": "mask",
            "sampler_name": "mask_smp",
            "view_slot": 6,
            "sampler_slot": 2
          }
        ]
      }
    },
    "shadow": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float4 fa_inst_m0 [[attribute(1)]];\n    float4 fa_inst_m1 [[attribute(2)]];\n    float4 fa_inst_m2 [[attribute(3)]];\n    float4 fa_inst_m3 [[attribute(4)]];\n    float3 fa_normal [[attribute(5)]];\n    float2 fa_texcoord0 [[attribute(6)]];\n    float4 fa_tangent [[attribute(7)]];\n    float4 fa_color [[attribute(8)]];\n};\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _120)\n{\n    float3 _58 = cross(model[1].xyz, model[2].xyz);\n    float _64 = (dot(model[0].xyz, _58) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_58 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _64, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _64), texcoord0 * _120.fa_uv_scale.xy, color, position };\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _120 [[buffer(0)]])\n{\n    main0_out out = {};\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    VertexData _187 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _120);\n    float3 _236 = _187.world_pos;\n    out.fa_world_pos = _236;\n    out.fa_world_normal = _187.world_normal;\n    out.fa_world_tangent = _187.world_tangent;\n    out.fa_uv = _187.uv;\n    out.fa_vertex_color = _187.color;\n    out.gl_Position = _120.fa_light_vp * float4(_236, 1.0);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n};\n\nstruct fa_material\n{\n    float alphaCutoff;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _189 = fa_linear_to_srgb(param);\n        c = _189;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _198 = fa_srgb_to_linear(param_1);\n            c = _198;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _54;\n    if (bool(i.front_facing))\n    {\n        _54 = i.world_normal;\n    }\n    else\n    {\n        _54 = -i.world_normal;\n    }\n    float3 _79 = fast::normalize(i.world_tangent.xyz - (_54 * dot(_54, i.world_tangent.xyz)));\n    float3 _107 = fast::normalize(((_79 * m.x) + ((cross(_54, _79) * i.world_tangent.w) * m.y)) + (_54 * m.z));\n    float3 _110;\n    if (bool(i.front_facing))\n    {\n        _110 = _107;\n    }\n    else\n    {\n        _110 = -_107;\n    }\n    return _110;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _223, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _223.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _235 = fa_tex_fix(param_2, param_3);\n    float4 _534 = base_t;\n    _534.x = _235.x;\n    _534.y = _235.y;\n    _534.z = _235.z;\n    base_t = _534;\n    float4 _251 = (_534 * _223.fa_base_color) * i.vertex_color;\n    float3 _521 = i.world_normal;\n    if (_223.fa_maps.z > 0.5)\n    {\n        float param_4 = _223.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _285 = fa_tex_fix(param_6, param_7);\n        float3 _288 = (_285 * 2.0) - float3(1.0);\n        float2 _293 = _288.xy * _223.fa_maps.x;\n        float3 _542 = _288;\n        _542.x = _293.x;\n        _542.y = _293.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _542;\n        _521 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _223.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _322 = fa_tex_fix(param_12, param_13);\n    float4 _545 = mrt;\n    _545.x = _322.x;\n    _545.y = _322.y;\n    _545.z = _322.z;\n    mrt = _545;\n    float param_14 = _223.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = fa_occlusion_tex.sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _363 = fa_tex_fix(param_16, param_17);\n    float param_18 = _223.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _390 = fa_tex_fix(param_20, param_21);\n    return Surface{ _251.xyz, _251.w, _521, fast::clamp(_223.fa_pbr.x * _322.z, 0.0, 1.0), fast::clamp(_223.fa_pbr.y * _322.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_223.fa_maps.y * (_363.x - 1.0)), _223.fa_emissive.xyz + (_223.fa_model_emissive.xyz * _390) };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread Surface& s, texture2d<float> mask, sampler mask_smp)\n{\n    s.alpha = mask.sample(mask_smp, (i.uv * 2.0)).x;\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _223 [[buffer(1)]], constant fa_material& _451 [[buffer(5)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], texture2d<float> mask [[texture(5)]], sampler fa_smp [[sampler(0)]], sampler mask_smp [[sampler(2)]], bool gl_FrontFacing [[front_facing]], float4 gl_FragCoord [[position]])\n{\n    main0_out out = {};\n    float3 _468 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _468 = -_468;\n    }\n    float3 _435 = fast::normalize(_223.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _468, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _435, short(gl_FrontFacing) };\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _468, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _435, short(gl_FrontFacing) };\n    Surface param_2 = fa_standard_surface(param, fa_tex, fa_smp, _223, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    surface(param_1, param_2, mask, mask_smp);\n    if (param_2.alpha < _451.alphaCutoff)\n    {\n        discard_fragment();\n    }\n    out.fa_frag_color = float4(gl_FragCoord.z, 0.0, 0.0, 1.0);\n    return out;\n}\n\n",
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
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_120",
            "msl_buffer_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 224,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_223",
            "msl_buffer_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_451",
            "msl_buffer_n": 5
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
              "slot": 2,
              "stage": "fragment",
              "name": "fa_normal_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 1
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
              "msl_texture_n": 2
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
              "msl_texture_n": 3
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
              "msl_texture_n": 4
            }
          },
          {
            "texture": {
              "slot": 6,
              "stage": "fragment",
              "name": "mask",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 5
            }
          }
        ],
        "samplers": [
          {
            "slot": 2,
            "stage": "fragment",
            "name": "mask_smp",
            "sampler_type": "filtering",
            "msl_sampler_n": 2
          },
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_smp",
            "sampler_type": "filtering",
            "msl_sampler_n": 0
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
            "name": "mask_mask_smp",
            "view_name": "mask",
            "sampler_name": "mask_smp",
            "view_slot": 6,
            "sampler_slot": 2
          }
        ]
      }
    },
    "shadow_skin": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float4 fa_inst_m0 [[attribute(1)]];\n    float4 fa_inst_m1 [[attribute(2)]];\n    float4 fa_inst_m2 [[attribute(3)]];\n    float4 fa_inst_m3 [[attribute(4)]];\n    float4 fa_joints [[attribute(5)]];\n    float4 fa_weights [[attribute(6)]];\n    float3 fa_normal [[attribute(7)]];\n    float2 fa_texcoord0 [[attribute(8)]];\n    float4 fa_tangent [[attribute(9)]];\n    float4 fa_color [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _172)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _163 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_172.fa_joint_rows[_163] * weights[i]);\n        r1 += (_172.fa_joint_rows[_163 + 1] * weights[i]);\n        r2 += (_172.fa_joint_rows[_163 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _125)\n{\n    float3 _63 = cross(model[1].xyz, model[2].xyz);\n    float _69 = (dot(model[0].xyz, _63) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_63 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _69, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _69), texcoord0 * _125.fa_uv_scale.xy, color, position };\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _125 [[buffer(0)]], constant fa_skin& _172 [[buffer(3)]])\n{\n    main0_out out = {};\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float4x4 param_2 = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _172);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    VertexData _308 = fa_vertex_data(param_2, param_3, param_4, param_5, param_6, param_7, _125);\n    float3 _357 = _308.world_pos;\n    out.fa_world_pos = _357;\n    out.fa_world_normal = _308.world_normal;\n    out.fa_world_tangent = _308.world_tangent;\n    out.fa_uv = _308.uv;\n    out.fa_vertex_color = _308.color;\n    out.gl_Position = _125.fa_light_vp * float4(_357, 1.0);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n};\n\nstruct fa_material\n{\n    float alphaCutoff;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _189 = fa_linear_to_srgb(param);\n        c = _189;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _198 = fa_srgb_to_linear(param_1);\n            c = _198;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _54;\n    if (bool(i.front_facing))\n    {\n        _54 = i.world_normal;\n    }\n    else\n    {\n        _54 = -i.world_normal;\n    }\n    float3 _79 = fast::normalize(i.world_tangent.xyz - (_54 * dot(_54, i.world_tangent.xyz)));\n    float3 _107 = fast::normalize(((_79 * m.x) + ((cross(_54, _79) * i.world_tangent.w) * m.y)) + (_54 * m.z));\n    float3 _110;\n    if (bool(i.front_facing))\n    {\n        _110 = _107;\n    }\n    else\n    {\n        _110 = -_107;\n    }\n    return _110;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _223, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _223.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _235 = fa_tex_fix(param_2, param_3);\n    float4 _534 = base_t;\n    _534.x = _235.x;\n    _534.y = _235.y;\n    _534.z = _235.z;\n    base_t = _534;\n    float4 _251 = (_534 * _223.fa_base_color) * i.vertex_color;\n    float3 _521 = i.world_normal;\n    if (_223.fa_maps.z > 0.5)\n    {\n        float param_4 = _223.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _285 = fa_tex_fix(param_6, param_7);\n        float3 _288 = (_285 * 2.0) - float3(1.0);\n        float2 _293 = _288.xy * _223.fa_maps.x;\n        float3 _542 = _288;\n        _542.x = _293.x;\n        _542.y = _293.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _542;\n        _521 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _223.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _322 = fa_tex_fix(param_12, param_13);\n    float4 _545 = mrt;\n    _545.x = _322.x;\n    _545.y = _322.y;\n    _545.z = _322.z;\n    mrt = _545;\n    float param_14 = _223.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = fa_occlusion_tex.sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _363 = fa_tex_fix(param_16, param_17);\n    float param_18 = _223.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _390 = fa_tex_fix(param_20, param_21);\n    return Surface{ _251.xyz, _251.w, _521, fast::clamp(_223.fa_pbr.x * _322.z, 0.0, 1.0), fast::clamp(_223.fa_pbr.y * _322.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_223.fa_maps.y * (_363.x - 1.0)), _223.fa_emissive.xyz + (_223.fa_model_emissive.xyz * _390) };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread Surface& s, texture2d<float> mask, sampler mask_smp)\n{\n    s.alpha = mask.sample(mask_smp, (i.uv * 2.0)).x;\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _223 [[buffer(1)]], constant fa_material& _451 [[buffer(5)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], texture2d<float> mask [[texture(5)]], sampler fa_smp [[sampler(0)]], sampler mask_smp [[sampler(2)]], bool gl_FrontFacing [[front_facing]], float4 gl_FragCoord [[position]])\n{\n    main0_out out = {};\n    float3 _468 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _468 = -_468;\n    }\n    float3 _435 = fast::normalize(_223.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _468, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _435, short(gl_FrontFacing) };\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _468, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _435, short(gl_FrontFacing) };\n    Surface param_2 = fa_standard_surface(param, fa_tex, fa_smp, _223, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    surface(param_1, param_2, mask, mask_smp);\n    if (param_2.alpha < _451.alphaCutoff)\n    {\n        discard_fragment();\n    }\n    out.fa_frag_color = float4(gl_FragCoord.z, 0.0, 0.0, 1.0);\n    return out;\n}\n\n",
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
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_125",
            "msl_buffer_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_172",
            "msl_buffer_n": 3
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 224,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_223",
            "msl_buffer_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_451",
            "msl_buffer_n": 5
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
              "slot": 2,
              "stage": "fragment",
              "name": "fa_normal_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 1
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
              "msl_texture_n": 2
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
              "msl_texture_n": 3
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
              "msl_texture_n": 4
            }
          },
          {
            "texture": {
              "slot": 6,
              "stage": "fragment",
              "name": "mask",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 5
            }
          }
        ],
        "samplers": [
          {
            "slot": 2,
            "stage": "fragment",
            "name": "mask_smp",
            "sampler_type": "filtering",
            "msl_sampler_n": 2
          },
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_smp",
            "sampler_type": "filtering",
            "msl_sampler_n": 0
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
            "name": "mask_mask_smp",
            "view_name": "mask",
            "sampler_name": "mask_smp",
            "view_slot": 6,
            "sampler_slot": 2
          }
        ]
      }
    }
  }
}
