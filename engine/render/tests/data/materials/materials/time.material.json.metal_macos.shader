{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "b9137a7fd5249b4222bedebb6ca5e740fb7c4a348474dd42da5706fae9a2d4c0",
  "slang": "metal_macos",
  "params": [],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _131);\n    float3 _265 = _160.world_pos;\n    fa_world_pos = _265;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = _131.fa_view_proj * float4(_265, 1.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _131 [[buffer(0)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5, _131, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n#pragma clang diagnostic ignored \"-Wmissing-braces\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\ntemplate<typename T, size_t Num>\nstruct spvUnsafeArray\n{\n    T elements[Num ? Num : 1];\n    \n    thread T& operator [] (size_t pos) thread\n    {\n        return elements[pos];\n    }\n    constexpr const thread T& operator [] (size_t pos) const thread\n    {\n        return elements[pos];\n    }\n    \n    device T& operator [] (size_t pos) device\n    {\n        return elements[pos];\n    }\n    constexpr const device T& operator [] (size_t pos) const device\n    {\n        return elements[pos];\n    }\n    \n    constexpr const constant T& operator [] (size_t pos) const constant\n    {\n        return elements[pos];\n    }\n    \n    threadgroup T& operator [] (size_t pos) threadgroup\n    {\n        return elements[pos];\n    }\n    constexpr const threadgroup T& operator [] (size_t pos) const threadgroup\n    {\n        return elements[pos];\n    }\n};\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    short on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    short sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n};\n\nconstant spvUnsafeArray<float, 63> _1589 = spvUnsafeArray<float, 63>({ 1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875 });\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _459)\n{\n    bool _464 = _459.fa_cl_info.x < 0.0;\n    bool _471;\n    if (!_464)\n    {\n        _471 = _459.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _471 = _464;\n    }\n    bool _479;\n    if (!_471)\n    {\n        _479 = _459.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _479 = _471;\n    }\n    bool _486;\n    if (!_479)\n    {\n        _486 = _459.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _486 = _479;\n    }\n    bool _493;\n    if (!_486)\n    {\n        _493 = _459.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _493 = _486;\n    }\n    if (_493)\n    {\n        return int2(0);\n    }\n    float4 _503 = float4(world_pos, 1.0);\n    float _510 = dot(_459.fa_cl_vpw, _503);\n    if (!(_510 > 9.9999999747524270787835121154785e-07))\n    {\n        return int2(0);\n    }\n    float2 _532 = float2(dot(_459.fa_cl_vpx, _503), dot(_459.fa_cl_vpy, _503)) / float2(_510);\n    int _536 = int(_459.fa_cl_grid.x);\n    int _540 = int(_459.fa_cl_grid.y);\n    int param = (int(_459.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_459.fa_cl_fwd.xyz, world_pos) + _459.fa_cl_fwd.w, _459.fa_cl_grid.w) / _459.fa_cl_grid.w) * _459.fa_cl_grid.z)), 0, int(_459.fa_cl_info.y) - 1) * _540) + clamp(int(floor(((_532.y * 0.5) + 0.5) * _459.fa_cl_grid.y)), 0, _540 - 1)) * _536)) + clamp(int(floor(((_532.x * 0.5) + 0.5) * _459.fa_cl_grid.x)), 0, _536 - 1);\n    float4 _611 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int2(int(_611.x), int(_611.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _459, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_459.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _2408 = fa_cluster_lookup(param, fa_light_tex, fa_shadow_smp, _459);\n    fa_cl_slot = _2408.x;\n    fa_cl_local = _2408.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _2523 = fa_linear_to_srgb(param);\n        c = _2523;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _2531 = fa_srgb_to_linear(param_1);\n            c = _2531;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _231;\n    if (bool(i.front_facing))\n    {\n        _231 = i.world_normal;\n    }\n    else\n    {\n        _231 = -i.world_normal;\n    }\n    float3 _255 = fast::normalize(i.world_tangent.xyz - (_231 * dot(_231, i.world_tangent.xyz)));\n    float3 _283 = fast::normalize(((_255 * m.x) + ((cross(_231, _255) * i.world_tangent.w) * m.y)) + (_231 * m.z));\n    float3 _286;\n    if (bool(i.front_facing))\n    {\n        _286 = _283;\n    }\n    else\n    {\n        _286 = -_283;\n    }\n    return _286;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _459, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _459.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _2562 = fa_tex_fix(param_2, param_3);\n    float4 _3733 = base_t;\n    _3733.x = _2562.x;\n    _3733.y = _2562.y;\n    _3733.z = _2562.z;\n    base_t = _3733;\n    float4 _2576 = (_3733 * _459.fa_base_color) * i.vertex_color;\n    float3 _3667 = i.world_normal;\n    if (_459.fa_maps.z > 0.5)\n    {\n        float param_4 = _459.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _2608 = fa_tex_fix(param_6, param_7);\n        float3 _2611 = (_2608 * 2.0) - float3(1.0);\n        float2 _2616 = _2611.xy * _459.fa_maps.x;\n        float3 _3741 = _2611;\n        _3741.x = _2616.x;\n        _3741.y = _2616.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _3741;\n        _3667 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _459.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _2645 = fa_tex_fix(param_12, param_13);\n    float4 _3744 = mrt;\n    _3744.x = _2645.x;\n    _3744.y = _2645.y;\n    _3744.z = _2645.z;\n    mrt = _3744;\n    float4 _2673 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _459.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _2673.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _2685 = fa_tex_fix(param_16, param_17);\n    float param_18 = _459.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _2715 = fa_tex_fix(param_20, param_21);\n    float _3672 = _459.fa_layers_a.x;\n    float _3673 = _459.fa_layers_a.y;\n    float _3676 = _459.fa_layers_a.z;\n    float _3675 = _459.fa_layers_b.w;\n    float _3678 = _459.fa_layers_c.x;\n    if (_459.fa_layers_c.z > 0.5)\n    {\n        if (mod(_459.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _3672 *= _2685.y;\n            _3673 *= _2685.z;\n            _3675 *= _2673.w;\n        }\n        if (_459.fa_layers_c.z > 1.5)\n        {\n            _3676 *= mrt.x;\n            _3678 *= mrt.w;\n        }\n    }\n    return Surface{ _2576.xyz, _2576.w, _3667, fast::clamp(_459.fa_pbr.x * _2645.z, 0.0, 1.0), fast::clamp(_459.fa_pbr.y * _2645.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_459.fa_maps.y * (_2685.x - 1.0)), _459.fa_emissive.xyz + (_459.fa_model_emissive.xyz * _2715), _3672, _3673, _459.fa_layers_b.xyz, _3675, _3676, _459.fa_layers_a.w, _3678, _459.fa_layers_c.y, _459.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread Surface& s, constant fa_mesh_fs_params& _459)\n{\n    s.emission += float3(0.5 + (0.5 * sin(_459.fa_time.x * 3.0)), 0.25 * fract(_459.fa_time.x), 0.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_sheen_albedo(thread const float& ndv, thread const float& rough)\n{\n    float _1514 = fast::min(sqrt(fast::max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _1522 = fast::min(sqrt(fast::clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _1525 = int(_1514);\n    int _1528 = int(_1522);\n    float _1538 = _1522 - float(_1528);\n    int _1594 = (_1525 * 9) + _1528;\n    int _1614 = ((_1525 + 1) * 9) + _1528;\n    return mix(mix(_1589[_1594], _1589[_1594 + 1], _1538), mix(_1589[_1614], _1589[_1614 + 1], _1538), _1514 - float(_1525));\n}\n\nstatic inline __attribute__((always_inline))\nFaLayers fa_layers_setup(thread const SurfaceInput& i, thread const Surface& s, thread const float3& n, thread const float3& v, thread const float& metallic, thread const float& roughness, thread float3& f0)\n{\n    bool _3603 = false;\n    float _3604 = 1.0;\n    float _3605 = 1.0;\n    float _3606 = 1.0;\n    float _3607 = 0.0;\n    float _3608 = 0.0;\n    float _3609 = 0.0;\n    float _3610 = 0.0;\n    float _3612 = 1.0;\n    bool _3613 = false;\n    float3 _3614 = float3(0.0);\n    float _3615 = 1.0;\n    float _3616 = 1.0;\n    float _3617 = 1.0;\n    float _3618 = 0.0;\n    float _3619 = 0.0;\n    float3 _3620 = float3(1.0, 0.0, 0.0);\n    float3 _3621 = float3(0.0, 0.0, 1.0);\n    float _3622 = 1.0;\n    float _3623 = 1.0;\n    float _1669 = fast::clamp(s.specular, 0.0, 1.0);\n    float _1673 = fast::clamp(s.ior, 1.0, 3.0);\n    bool _1678 = (_1669 != 1.0) || (_1673 != 1.5);\n    bool _1688;\n    if (!_1678)\n    {\n        _1688 = any(s.specular_color != float3(1.0));\n    }\n    else\n    {\n        _1688 = _1678;\n    }\n    if (_1688)\n    {\n        float _1696 = (_1673 - 1.0) / (_1673 + 1.0);\n        f0 = mix(fast::min(float3(_1696 * _1696) * fast::max(s.specular_color, float3(0.0)), float3(1.0)) * _1669, s.albedo, float3(metallic));\n        _3604 = mix(_1669, 1.0, metallic);\n        _3603 = true;\n    }\n    float _1724 = fast::clamp(s.clearcoat, 0.0, 1.0);\n    if (_1724 > 0.0)\n    {\n        float _1732 = fast::clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _3607 = _1724;\n        _3608 = _1732;\n        float _1739 = _1732 * _1732;\n        _3609 = _1739;\n        _3610 = _1739 * _1739;\n        float _1751 = fast::max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _3612 = _1751;\n        _3605 = 1.0 - (_1724 * (0.039999999105930328369140625 + (0.959999978542327880859375 * powr(fast::clamp(1.0 - _1751, 0.0, 1.0), 5.0))));\n        _3603 = true;\n    }\n    float3 _1771 = fast::max(s.sheen_color, float3(0.0));\n    float _1780 = fast::max(_1771.x, fast::max(_1771.y, _1771.z));\n    if (_1780 > 0.0)\n    {\n        float _1788 = fast::clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _3613 = true;\n        _3614 = _1771;\n        _3615 = _1788;\n        _3616 = _1788 * _1788;\n        float param = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _1788;\n        float _1805 = fa_sheen_albedo(param, param_1);\n        _3618 = _1805;\n        _3617 = 1.0 - fast::min(_1780 * _1805, 1.0);\n        _3603 = true;\n    }\n    _3606 = _3605 * _3617;\n    float _1824 = fast::clamp(s.anisotropy, -1.0, 1.0);\n    if (_1824 != 0.0)\n    {\n        float3 _1839 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _1839;\n        if (dot(_1839, _1839) < 9.9999999392252902907785028219223e-09)\n        {\n            t = cross(select(float3(1.0, 0.0, 0.0), float3(0.0, 1.0, 0.0), bool3(abs(n.y) < 0.9900000095367431640625)), n);\n        }\n        float3 _1857 = t;\n        float3 _1858 = fast::normalize(_1857);\n        t = _1858;\n        float3 _1883 = fast::normalize((_1858 * cos(s.anisotropy_rotation)) + ((cross(n, _1858) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _3620 = _1883;\n        _3621 = cross(n, _1883);\n        float _1893 = roughness * roughness;\n        float _1899 = mix(_1893, 1.0, _1824 * _1824);\n        bool _1901 = _1824 > 0.0;\n        _3622 = _1901 ? _1899 : _1893;\n        _3623 = _1901 ? _1893 : _1899;\n        _3619 = _1824;\n        _3603 = true;\n    }\n    return FaLayers{ short(_3603), _3604, _3605, _3606, _3607, _3608, _3609, _3610, i.world_normal, _3612, short(_3613), _3614, _3615, _3616, _3617, _3618, _3619, _3620, _3621, _3622, _3623 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _459, sampler fa_env_smp, texturecube<float> fa_irr_tex)\n{\n    if (_459.fa_env_sky.w > 0.5)\n    {\n        return fa_irr_tex.sample(fa_env_smp, n, level(0.0)).xyz;\n    }\n    return _459.fa_ambient.xyz;\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _459)\n{\n    int param = (int(_459.fa_cl_info.x) + int(_459.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _459, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, fa_light_tex, fa_shadow_smp, _459);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li * 4;\n    float4 _331 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    int param_1 = (li * 4) + 1;\n    float4 _337 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float _340 = _337.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _347 = _340 < 0.5;\n    float3 l;\n    if (_347)\n    {\n        l = fast::normalize(_331.xyz);\n    }\n    else\n    {\n        float3 _359 = _331.xyz - world_pos;\n        float _361 = length(_359);\n        dist = _361;\n        l = _359 / float3(fast::max(_361, 9.9999997473787516355514526367188e-05));\n        float _376 = _361 / fast::max(_331.w, 0.001000000047497451305389404296875);\n        float _382 = fast::clamp(1.0 - (_376 * _376), 0.0, 1.0);\n        atten = _382 * _382;\n        if (_340 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _396 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n            float _406 = _396.w;\n            int param_3 = (li * 4) + 3;\n            float4 _413 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            float _414 = _413.x;\n            float cos_inner = _414;\n            if (_414 > 1.5)\n            {\n                cos_inner = mix(_406, 1.0, 0.25);\n            }\n            atten *= smoothstep(_406, cos_inner, dot(-l, fast::normalize(_396.xyz)));\n        }\n    }\n    int _445;\n    if (_347)\n    {\n        _445 = 0;\n    }\n    else\n    {\n        _445 = (_340 > 1.5) ? 2 : 1;\n    }\n    return LightSample{ l, _337.xyz * atten, atten, 1.0, dist, _445 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _695)\n{\n    float _685;\n    if (i == 0)\n    {\n        _685 = _695.fa_shadow_split.x;\n    }\n    else\n    {\n        float _701;\n        if (i == 1)\n        {\n            _701 = _695.fa_shadow_split.y;\n        }\n        else\n        {\n            float _709;\n            if (i == 2)\n            {\n                _709 = _695.fa_shadow_split.z;\n            }\n            else\n            {\n                _709 = _695.fa_shadow_split.w;\n            }\n            _701 = _709;\n        }\n        _685 = _701;\n    }\n    return _685;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _673 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_673), sin(_673)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _695, texture2d<float> fa_shadow_tex)\n{\n    float _747 = fast::max(_695.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _752 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _758 = sqrt(1.0 - (_752 * _752));\n    float _766 = fast::min(_758 / fast::max(_752, 0.20000000298023223876953125), 4.0);\n    float _771;\n    if (_695.fa_shadow_bias.y > 0.0)\n    {\n        _771 = _695.fa_shadow_bias.y;\n    }\n    else\n    {\n        _771 = 1.5 * _695.fa_shadow_info[ci].x;\n    }\n    float4 _796 = _695.fa_shadow_mat[ci] * float4(world + (n * (_771 * _758)), 1.0);\n    float _803 = _796.x;\n    bool _806 = _803 < _695.fa_shadow_rect[ci].x;\n    bool _815;\n    if (!_806)\n    {\n        _815 = _803 > _695.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _815 = _806;\n    }\n    bool _824;\n    if (!_815)\n    {\n        _824 = _796.y < _695.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _824 = _815;\n    }\n    bool _833;\n    if (!_824)\n    {\n        _833 = _796.y > _695.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _833 = _824;\n    }\n    bool _840;\n    if (!_833)\n    {\n        _840 = _796.z > 1.0;\n    }\n    else\n    {\n        _840 = _833;\n    }\n    if (_840)\n    {\n        return -1.0;\n    }\n    float _849;\n    if (_695.fa_shadow_bias.x > 0.0)\n    {\n        _849 = _695.fa_shadow_bias.x;\n    }\n    else\n    {\n        _849 = 1.5 * _695.fa_shadow_info[ci].x;\n    }\n    float _868 = _796.z - ((_849 * (1.0 + (0.5 * _766))) / _747);\n    float _877 = ((_695.fa_shadow_info[ci].x * fast::min(_766, 3.0)) * 0.5) / _747;\n    int _886 = int(_695.fa_shadow_cfg.z + 0.5);\n    if (_886 == 1)\n    {\n        float2 param = _796.xy;\n        float4 param_1 = _695.fa_shadow_rect[ci];\n        float _897 = fa_shadow_depth(param, param_1, fa_shadow_smp, fa_shadow_tex);\n        return float(_868 <= _897);\n    }\n    float _904 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    bool _907 = _886 == 2;\n    if (_907)\n    {\n        float _921 = fast::clamp(((_695.fa_shadow_cfg.w * _747) * 0.25) / _695.fa_shadow_info[ci].x, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _904;\n            float2 _940 = fa_shadow_vogel(param_2, param_3, param_4) * _921;\n            float2 param_5 = _796.xy + (_940 * _695.fa_shadow_bias.zw);\n            float4 param_6 = _695.fa_shadow_rect[ci];\n            float _951 = fa_shadow_depth(param_5, param_6, fa_shadow_smp, fa_shadow_tex);\n            if (_951 < (_868 - (length(_940) * _877)))\n            {\n                sum += _951;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = fast::clamp(((fast::max(_868 - (sum / cnt), 0.0) * _747) * _695.fa_shadow_cfg.w) / _695.fa_shadow_info[ci].x, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _995 = _907 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _995; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _995;\n        float param_9 = _904;\n        float2 _1014 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        float2 param_10 = _796.xy + (_1014 * _695.fa_shadow_bias.zw);\n        float4 param_11 = _695.fa_shadow_rect[ci];\n        float _1025 = fa_shadow_depth(param_10, param_11, fa_shadow_smp, fa_shadow_tex);\n        lit += float((_868 - (length(_1014) * _877)) <= _1025);\n    }\n    return lit / float(_995);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _459, thread float4& gl_FragCoord, constant fa_shadows& _695, texture2d<float> fa_shadow_tex)\n{\n    if (_459.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1055 = int(_695.fa_shadow_cfg.x + 0.5);\n    if (_1055 < 1)\n    {\n        return 1.0;\n    }\n    float _1071 = dot(world - _695.fa_shadow_eye.xyz, _695.fa_shadow_fwd.xyz);\n    int param = _1055 - 1;\n    if (_1071 > fa_shadow_split_at(param, _695))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1083 = _1055 > 1;\n    bool _1090;\n    if (_1083)\n    {\n        _1090 = _1071 > _695.fa_shadow_split.x;\n    }\n    else\n    {\n        _1090 = _1083;\n    }\n    if (_1090)\n    {\n        ci = 1;\n    }\n    bool _1094 = _1055 > 2;\n    bool _1101;\n    if (_1094)\n    {\n        _1101 = _1071 > _695.fa_shadow_split.y;\n    }\n    else\n    {\n        _1101 = _1094;\n    }\n    if (_1101)\n    {\n        ci = 2;\n    }\n    bool _1105 = _1055 > 3;\n    bool _1112;\n    if (_1105)\n    {\n        _1112 = _1071 > _695.fa_shadow_split.z;\n    }\n    else\n    {\n        _1112 = _1105;\n    }\n    if (_1112)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1055)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1138 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_shadow_smp, gl_FragCoord, _695, fa_shadow_tex);\n        s = _1138;\n        if (_1138 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_695.fa_shadow_cfg.y > 0.0)\n    {\n        float _1163;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1163 = fa_shadow_split_at(param_5, _695);\n        }\n        else\n        {\n            _1163 = _695.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1182 = _695.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _695) - _1163, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1193 = fast::clamp((_1071 - (fa_shadow_split_at(param_7, _695) - _1182)) / _1182, 0.0, 1.0);\n        if (_1193 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1055)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1214 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_shadow_smp, gl_FragCoord, _695, fa_shadow_tex);\n                s2 = _1214;\n                if (_1214 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1193);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _459, thread float4& gl_FragCoord, constant fa_shadows& _695, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, fa_shadow_smp, _459, gl_FragCoord, _695, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _459, thread float4& gl_FragCoord, constant fa_shadows& _695, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _2436 = fa_light_sample(param, param_1, fa_light_tex, fa_shadow_smp);\n    float3 _3652 = _2436.direction;\n    float3 _3647 = _2436.color;\n    float _3649 = _2436.shadow;\n    int _3657 = _2436.type;\n    if ((_3657 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _3652;\n        float _2450 = fa_shadow_factor(param_2, param_3, fa_shadow_smp, _459, gl_FragCoord, _695, fa_shadow_tex, fa_world_pos);\n        _3649 = _2450;\n        _3647 *= _2450;\n    }\n    return LightSample{ _3652, _3647, _2436.attenuation, _3649, _2436._distance, _3657 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_d_ggx_aniso(thread const float& ndh, thread const float& tdh, thread const float& bdh, thread const float& at, thread const float& ab)\n{\n    float _2051 = tdh / at;\n    float _2055 = bdh / ab;\n    float _2067 = ((_2051 * _2051) + (_2055 * _2055)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _2067) * _2067);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_lambda_ggx_aniso(thread const float& n, thread const float& t, thread const float& b, thread const float& at, thread const float& ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / fast::max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_v_ggx_aniso(thread const float& ndl, thread const float& ndv, thread const float& tdv, thread const float& bdv, thread const float& tdl, thread const float& bdl, thread const float& at, thread const float& ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return fast::clamp(1.0 / ((4.0 * fast::max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_d_charlie(thread const float& alpha, thread const float& ndh)\n{\n    float _2148 = 1.0 / alpha;\n    return ((2.0 + _2148) * powr(sqrt(fast::max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _2148)) * 0.15915493667125701904296875;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_v_ashikhmin(thread const float& ndl, thread const float& ndv)\n{\n    return fast::clamp(0.25 / fast::max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_layers_light(thread const FaLayers& L, thread const float3& diffuse_color, thread const float3& f0, thread const float3& n, thread const float3& v, thread const float3& l, thread const float3& h, thread const float& ndl, thread const float& ndv, thread const float& ndh, thread const float& vdh, thread const float& alpha, thread const float& a2)\n{\n    float _2181 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _2260 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _2260) * _2260);\n        vis = 0.5 / fast::max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    float3 base = diffuse_color + (((f0 + ((float3(L.f90) - f0) * powr(fast::clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _2181);\n    if (bool(L.sheen_on))\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _2181));\n    }\n    float3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        float _2333 = fast::max(dot(L.nc, l), 0.0);\n        float _2339 = fast::max(dot(L.nc, h), 0.0);\n        float _2348 = ((_2339 * _2339) * (L.coat_a2 - 1.0)) + 1.0;\n        result += float3((((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * powr(fast::clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _2348) * _2348)) * (0.5 / fast::max(mix((2.0 * _2333) * L.coat_ndv, _2333 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _2333)) * _2333);\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_light_rgb(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_env_brdf(thread const float& rough, thread const float& ndv)\n{\n    float4 _1446 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _1449 = _1446.x;\n    return (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_1449 * _1449, exp2((-9.27999973297119140625) * ndv)) * _1449) + _1446.y)) + _1446.zw;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_environment(thread const float3& d, thread const float& rough, constant fa_mesh_fs_params& _459, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    if (_459.fa_env_sky.w > 0.5)\n    {\n        return fa_env_tex.sample(fa_env_smp, d, level(fast::clamp(rough, 0.0, 1.0) * _459.fa_env_horizon.w)).xyz;\n    }\n    float _1351 = rough * rough;\n    float _1381 = 0.60000002384185791015625 * _1351;\n    return mix(mix(_459.fa_env_horizon.xyz * 0.550000011920928955078125, mix(_459.fa_env_horizon.xyz, _459.fa_env_sky.xyz, float3(powr(fast::clamp(d.y * (1.0 - (0.699999988079071044921875 * _1351)), 0.0, 1.0), 0.550000011920928955078125))), float3(smoothstep((-0.0500000007450580596923828125) - _1381, 0.0500000007450580596923828125 + _1381, d.y))), ((_459.fa_env_sky.xyz + _459.fa_env_horizon.xyz) * 0.5) * 0.800000011920928955078125, float3(_1351 * 0.60000002384185791015625));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_layers_ibl(thread const FaLayers& L, thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _459, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        float3 _1934;\n        if (L.aniso >= 0.0)\n        {\n            _1934 = L.b;\n        }\n        else\n        {\n            _1934 = L.t;\n        }\n        rn = fast::normalize(mix(n, cross(cross(_1934, v), _1934), float3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _1967 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3, _459, fa_env_tex, fa_env_smp) * ((f0 * _1967.x) + (float3(L.f90) * _1967.y))) * L.base_scale;\n    if (bool(L.sheen_on))\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5, _459, fa_env_tex, fa_env_smp));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _2022 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9, _459, fa_env_tex, fa_env_smp) * (L.coat * ((0.039999999105930328369140625 * _2022.x) + _2022.y)));\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_reflection(thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _459, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _1488 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3, _459, fa_env_tex, fa_env_smp) * ((f0 * _1488.x) + float3(_1488.y));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _695)\n{\n    if (_695.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _1238 = int(_695.fa_shadow_cfg.x + 0.5);\n    float _1248 = dot(world - _695.fa_shadow_eye.xyz, _695.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _1253 = _1238 > 0;\n    bool _1262;\n    if (_1253)\n    {\n        int param = _1238 - 1;\n        _1262 = _1248 <= fa_shadow_split_at(param, _695);\n    }\n    else\n    {\n        _1262 = _1253;\n    }\n    if (_1262)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1269 = _1238 > 1;\n        bool _1276;\n        if (_1269)\n        {\n            _1276 = _1248 > _695.fa_shadow_split.x;\n        }\n        else\n        {\n            _1276 = _1269;\n        }\n        if (_1276)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1282 = _1238 > 2;\n        bool _1289;\n        if (_1282)\n        {\n            _1289 = _1248 > _695.fa_shadow_split.y;\n        }\n        else\n        {\n            _1289 = _1282;\n        }\n        if (_1289)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1295 = _1238 > 3;\n        bool _1302;\n        if (_1295)\n        {\n            _1302 = _1248 > _695.fa_shadow_split.z;\n        }\n        else\n        {\n            _1302 = _1295;\n        }\n        if (_1302)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _459 [[buffer(1)]], constant fa_shadows& _695 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_env_tex [[texture(6)]], texturecube<float> fa_irr_tex [[texture(7)]], texture2d<float> fa_light_tex [[texture(8)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _3382 = fast::normalize(in.fa_world_normal);\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _3382 = -_3382;\n    }\n    float3 _2836 = fast::normalize(_459.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, fa_light_tex, fa_shadow_smp, _459, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _3382, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2836, short(gl_FrontFacing) };\n    Surface _2844 = fa_standard_surface(param_1, _459, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _3413 = _2844.albedo;\n    float _3414 = _2844.alpha;\n    float3 _3415 = _2844.normal;\n    float _3416 = _2844.metallic;\n    float _3417 = _2844.roughness;\n    float _3418 = _2844.occlusion;\n    float3 _3419 = _2844.emission;\n    float _3420 = _2844.clearcoat;\n    float _3421 = _2844.clearcoat_roughness;\n    float3 _3422 = _2844.sheen_color;\n    float _3423 = _2844.sheen_roughness;\n    float _3424 = _2844.anisotropy;\n    float _3425 = _2844.anisotropy_rotation;\n    float _3426 = _2844.specular;\n    float _3427 = _2844.ior;\n    float3 _3428 = _2844.specular_color;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _3382, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2836, short(gl_FrontFacing) };\n    Surface param_3 = _2844;\n    surface(param_2, param_3, _459);\n    _3413 = param_3.albedo;\n    _3414 = param_3.alpha;\n    _3415 = param_3.normal;\n    _3416 = param_3.metallic;\n    _3417 = param_3.roughness;\n    _3418 = param_3.occlusion;\n    _3419 = param_3.emission;\n    _3420 = param_3.clearcoat;\n    _3421 = param_3.clearcoat_roughness;\n    _3422 = param_3.sheen_color;\n    _3423 = param_3.sheen_roughness;\n    _3424 = param_3.anisotropy;\n    _3425 = param_3.anisotropy_rotation;\n    _3426 = param_3.specular;\n    _3427 = param_3.ior;\n    _3428 = param_3.specular_color;\n    float3 result;\n    if (_459.fa_emissive.w > 0.5)\n    {\n        result = _3413;\n    }\n    else\n    {\n        float3 _2866 = fast::normalize(_3415);\n        float _2873 = fast::clamp(_3416, 0.0, 1.0);\n        float _2877 = fast::clamp(_3417, 0.0500000007450580596923828125, 1.0);\n        float _2881 = _2877 * _2877;\n        float _2885 = _2881 * _2881;\n        float _2890 = fast::max(dot(_2866, _2836), 9.9999997473787516355514526367188e-05);\n        float3 _2896 = _3413 * (1.0 - _2873);\n        float3 _2903 = mix(float3(0.039999999105930328369140625), _3413, float3(_2873));\n        float3 f0 = _2903;\n        SurfaceInput param_4 = SurfaceInput{ in.fa_world_pos, _3382, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2836, short(gl_FrontFacing) };\n        Surface param_5 = Surface{ _3413, _3414, _3415, _3416, _3417, _3418, _3419, _3420, _3421, _3422, _3423, _3424, _3425, _3426, _3427, _3428 };\n        float3 param_6 = _2866;\n        float3 param_7 = _2836;\n        float param_8 = _2873;\n        float param_9 = _2877;\n        float3 param_10 = _2903;\n        FaLayers _2919 = fa_layers_setup(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        f0 = param_10;\n        float3 param_11 = _2866;\n        float3 lit = (fa_ambient_light(param_11, _459, fa_env_smp, fa_irr_tex) * _2896) * _3418;\n        if (_2919.on)\n        {\n            lit *= _2919.base_scale;\n        }\n        int _2941 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _2941; ln++)\n        {\n            int param_12 = ln;\n            int _2954 = fa_cl_light(param_12, fa_light_tex, fa_shadow_smp, _459, fa_cl_ndir, fa_cl_slot);\n            int param_13 = _2954;\n            float3 param_14 = in.fa_world_pos;\n            float3 param_15 = _3382;\n            LightSample _2963 = fa_light_shadowed(param_13, param_14, param_15, fa_light_tex, fa_shadow_smp, _459, gl_FragCoord, _695, fa_shadow_tex, in.fa_world_pos);\n            float3 _3587 = _2963.direction;\n            float _2971 = fast::max(dot(_2866, _3587), 0.0);\n            float _2977 = _2963.attenuation * _2963.shadow;\n            float3 _2982 = fast::normalize(_3587 + _2836);\n            float _2987 = fast::max(dot(_2866, _2982), 0.0);\n            float _2992 = fast::max(dot(_2836, _2982), 0.0);\n            if (_2919.on)\n            {\n                FaLayers param_16 = _2919;\n                float3 param_17 = _2896;\n                float3 param_18 = f0;\n                float3 param_19 = _2866;\n                float3 param_20 = _2836;\n                float3 param_21 = _3587;\n                float3 param_22 = _2982;\n                float param_23 = _2971;\n                float param_24 = _2890;\n                float param_25 = _2987;\n                float param_26 = _2992;\n                float param_27 = _2881;\n                float param_28 = _2885;\n                int param_29 = _2954;\n                lit += (fa_layers_light(param_16, param_17, param_18, param_19, param_20, param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28) * (fa_light_rgb(param_29, fa_light_tex, fa_shadow_smp) * _2977));\n            }\n            else\n            {\n                float _3040 = ((_2987 * _2987) * (_2885 - 1.0)) + 1.0;\n                int param_30 = _2954;\n                lit += (((_2896 + (((f0 + ((float3(1.0) - f0) * powr(1.0 - _2992, 5.0))) * (((_2885 / ((3.1415927410125732421875 * _3040) * _3040)) * (0.5 / fast::max(mix((2.0 * _2971) * _2890, _2971 + _2890, _2881), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _2971))) * fa_light_rgb(param_30, fa_light_tex, fa_shadow_smp)) * (_2971 * _2977));\n            }\n        }\n        if (_2919.on)\n        {\n            FaLayers param_31 = _2919;\n            float3 param_32 = _2866;\n            float3 param_33 = _2836;\n            float3 param_34 = f0;\n            float param_35 = _2877;\n            lit += (fa_layers_ibl(param_31, param_32, param_33, param_34, param_35, _459, fa_env_tex, fa_env_smp) * _3418);\n        }\n        else\n        {\n            float3 param_36 = _2866;\n            float3 param_37 = _2836;\n            float3 param_38 = f0;\n            float param_39 = _2877;\n            lit += (fa_sky_reflection(param_36, param_37, param_38, param_39, _459, fa_env_tex, fa_env_smp) * _3418);\n        }\n        result = lit;\n    }\n    float3 _3133 = result;\n    float3 _3134 = _3133 + _3419;\n    result = _3134;\n    float3 param_40 = _3134;\n    float3 param_41 = in.fa_world_pos;\n    result = fa_shadow_debug(param_40, param_41, _695);\n    bool _3143 = _459.fa_fog.w > 0.0;\n    bool _3150;\n    if (!_3143)\n    {\n        _3150 = _459.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _3150 = _3143;\n    }\n    if (_3150)\n    {\n        float3 _3159 = in.fa_world_pos - _459.fa_camera_pos.xyz;\n        float _3165 = dot(_3159, _459.fa_fog_c.xyz);\n        bool _3169 = _459.fa_fog_c.w > 0.5;\n        float _3170;\n        if (_3169)\n        {\n            _3170 = _3165;\n        }\n        else\n        {\n            _3170 = length(_3159);\n        }\n        float _3182 = _3170 - _459.fa_fog_b.x;\n        if (_3182 > 0.0)\n        {\n            float _3191 = _459.fa_fog.w * _3182;\n            float tau = _3191 * _3191;\n            if (_459.fa_fog_b.y > 0.0)\n            {\n                float _3207;\n                if (_3169)\n                {\n                    _3207 = in.fa_world_pos.y - (_459.fa_fog_c.y * _3165);\n                }\n                else\n                {\n                    _3207 = _459.fa_camera_pos.y;\n                }\n                float _3228 = mix(_3207, in.fa_world_pos.y, fast::clamp(_459.fa_fog_b.x / _3170, 0.0, 1.0));\n                float _3232 = in.fa_world_pos.y - _3228;\n                float _3237 = _3228 - _459.fa_fog_b.z;\n                float _3242 = in.fa_world_pos.y - _459.fa_fog_b.z;\n                bool _3245 = _3237 <= 0.0;\n                bool _3246 = !_3245;\n                bool _3252;\n                if (_3246)\n                {\n                    _3252 = _459.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3252 = _3245;\n                }\n                float _3253;\n                if (_3252)\n                {\n                    _3253 = _459.fa_fog_b.y;\n                }\n                else\n                {\n                    _3253 = _459.fa_fog_b.y * exp(-fast::min(_459.fa_fog_b.w * _3237, 80.0));\n                }\n                bool _3280;\n                if (_3246)\n                {\n                    _3280 = _459.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3280 = _3245;\n                }\n                float _3281;\n                if (_3280)\n                {\n                    _3281 = _459.fa_fog_b.y * _3237;\n                }\n                else\n                {\n                    _3281 = (_459.fa_fog_b.y * (1.0 - exp(-fast::min(_459.fa_fog_b.w * _3237, 80.0)))) / _459.fa_fog_b.w;\n                }\n                bool _3306 = _3242 <= 0.0;\n                bool _3313;\n                if (!_3306)\n                {\n                    _3313 = _459.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3313 = _3306;\n                }\n                float _3314;\n                if (_3313)\n                {\n                    _3314 = _459.fa_fog_b.y * _3242;\n                }\n                else\n                {\n                    _3314 = (_459.fa_fog_b.y * (1.0 - exp(-fast::min(_459.fa_fog_b.w * _3242, 80.0)))) / _459.fa_fog_b.w;\n                }\n                float _3341;\n                if (abs(_3232) < 0.001000000047497451305389404296875)\n                {\n                    _3341 = _3253;\n                }\n                else\n                {\n                    _3341 = (_3314 - _3281) / _3232;\n                }\n                tau += (_3182 * fast::max(_3341, 0.0));\n            }\n            result = mix(result, _459.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _3414);\n    return out;\n}\n\n",
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
            "inst_name": "_131",
            "msl_buffer_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_459",
            "msl_buffer_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_695",
            "msl_buffer_n": 7
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
              "slot": 14,
              "stage": "fragment",
              "name": "fa_env_tex",
              "multisampled": false,
              "type": "cube",
              "sample_type": "float",
              "msl_texture_n": 6
            }
          },
          {
            "texture": {
              "slot": 15,
              "stage": "fragment",
              "name": "fa_irr_tex",
              "multisampled": false,
              "type": "cube",
              "sample_type": "float",
              "msl_texture_n": 7
            }
          },
          {
            "texture": {
              "slot": 24,
              "stage": "fragment",
              "name": "fa_light_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float",
              "msl_texture_n": 8
            }
          }
        ],
        "samplers": [
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_shadow_smp",
            "sampler_type": "nonfiltering",
            "msl_sampler_n": 1
          },
          {
            "slot": 10,
            "stage": "fragment",
            "name": "fa_env_smp",
            "sampler_type": "filtering",
            "msl_sampler_n": 10
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
            "name": "fa_light_tex_fa_shadow_smp",
            "view_name": "fa_light_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 24,
            "sampler_slot": 1
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_tex_fa_smp",
            "view_name": "fa_tex",
            "sampler_name": "fa_smp",
            "view_slot": 0,
            "sampler_slot": 0
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "fa_normal_tex_fa_smp",
            "view_name": "fa_normal_tex",
            "sampler_name": "fa_smp",
            "view_slot": 2,
            "sampler_slot": 0
          },
          {
            "slot": 3,
            "stage": "fragment",
            "name": "fa_mr_tex_fa_smp",
            "view_name": "fa_mr_tex",
            "sampler_name": "fa_smp",
            "view_slot": 3,
            "sampler_slot": 0
          },
          {
            "slot": 4,
            "stage": "fragment",
            "name": "fa_occlusion_tex_fa_smp",
            "view_name": "fa_occlusion_tex",
            "sampler_name": "fa_smp",
            "view_slot": 4,
            "sampler_slot": 0
          },
          {
            "slot": 5,
            "stage": "fragment",
            "name": "fa_emissive_tex_fa_smp",
            "view_name": "fa_emissive_tex",
            "sampler_name": "fa_smp",
            "view_slot": 5,
            "sampler_slot": 0
          },
          {
            "slot": 6,
            "stage": "fragment",
            "name": "fa_irr_tex_fa_env_smp",
            "view_name": "fa_irr_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 15,
            "sampler_slot": 10
          },
          {
            "slot": 7,
            "stage": "fragment",
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1
          },
          {
            "slot": 8,
            "stage": "fragment",
            "name": "fa_env_tex_fa_env_smp",
            "view_name": "fa_env_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10
          }
        ]
      }
    },
    "mesh_skin": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n    float4 fa_joints [[attribute(9)]];\n    float4 fa_weights [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _183)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_183.fa_joint_rows[_174] * weights[i]);\n        r1 += (_183.fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183.fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _136);\n    float3 _386 = _273.world_pos;\n    fa_world_pos = _386;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = _136.fa_view_proj * float4(_386, 1.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _136 [[buffer(0)]], constant fa_skin& _183 [[buffer(3)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float4x4 param_2 = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _183);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7, _136, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n#pragma clang diagnostic ignored \"-Wmissing-braces\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\ntemplate<typename T, size_t Num>\nstruct spvUnsafeArray\n{\n    T elements[Num ? Num : 1];\n    \n    thread T& operator [] (size_t pos) thread\n    {\n        return elements[pos];\n    }\n    constexpr const thread T& operator [] (size_t pos) const thread\n    {\n        return elements[pos];\n    }\n    \n    device T& operator [] (size_t pos) device\n    {\n        return elements[pos];\n    }\n    constexpr const device T& operator [] (size_t pos) const device\n    {\n        return elements[pos];\n    }\n    \n    constexpr const constant T& operator [] (size_t pos) const constant\n    {\n        return elements[pos];\n    }\n    \n    threadgroup T& operator [] (size_t pos) threadgroup\n    {\n        return elements[pos];\n    }\n    constexpr const threadgroup T& operator [] (size_t pos) const threadgroup\n    {\n        return elements[pos];\n    }\n};\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    short on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    short sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n};\n\nconstant spvUnsafeArray<float, 63> _1589 = spvUnsafeArray<float, 63>({ 1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875 });\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _459)\n{\n    bool _464 = _459.fa_cl_info.x < 0.0;\n    bool _471;\n    if (!_464)\n    {\n        _471 = _459.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _471 = _464;\n    }\n    bool _479;\n    if (!_471)\n    {\n        _479 = _459.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _479 = _471;\n    }\n    bool _486;\n    if (!_479)\n    {\n        _486 = _459.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _486 = _479;\n    }\n    bool _493;\n    if (!_486)\n    {\n        _493 = _459.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _493 = _486;\n    }\n    if (_493)\n    {\n        return int2(0);\n    }\n    float4 _503 = float4(world_pos, 1.0);\n    float _510 = dot(_459.fa_cl_vpw, _503);\n    if (!(_510 > 9.9999999747524270787835121154785e-07))\n    {\n        return int2(0);\n    }\n    float2 _532 = float2(dot(_459.fa_cl_vpx, _503), dot(_459.fa_cl_vpy, _503)) / float2(_510);\n    int _536 = int(_459.fa_cl_grid.x);\n    int _540 = int(_459.fa_cl_grid.y);\n    int param = (int(_459.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_459.fa_cl_fwd.xyz, world_pos) + _459.fa_cl_fwd.w, _459.fa_cl_grid.w) / _459.fa_cl_grid.w) * _459.fa_cl_grid.z)), 0, int(_459.fa_cl_info.y) - 1) * _540) + clamp(int(floor(((_532.y * 0.5) + 0.5) * _459.fa_cl_grid.y)), 0, _540 - 1)) * _536)) + clamp(int(floor(((_532.x * 0.5) + 0.5) * _459.fa_cl_grid.x)), 0, _536 - 1);\n    float4 _611 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int2(int(_611.x), int(_611.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _459, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_459.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _2408 = fa_cluster_lookup(param, fa_light_tex, fa_shadow_smp, _459);\n    fa_cl_slot = _2408.x;\n    fa_cl_local = _2408.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _2523 = fa_linear_to_srgb(param);\n        c = _2523;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _2531 = fa_srgb_to_linear(param_1);\n            c = _2531;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _231;\n    if (bool(i.front_facing))\n    {\n        _231 = i.world_normal;\n    }\n    else\n    {\n        _231 = -i.world_normal;\n    }\n    float3 _255 = fast::normalize(i.world_tangent.xyz - (_231 * dot(_231, i.world_tangent.xyz)));\n    float3 _283 = fast::normalize(((_255 * m.x) + ((cross(_231, _255) * i.world_tangent.w) * m.y)) + (_231 * m.z));\n    float3 _286;\n    if (bool(i.front_facing))\n    {\n        _286 = _283;\n    }\n    else\n    {\n        _286 = -_283;\n    }\n    return _286;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _459, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _459.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _2562 = fa_tex_fix(param_2, param_3);\n    float4 _3733 = base_t;\n    _3733.x = _2562.x;\n    _3733.y = _2562.y;\n    _3733.z = _2562.z;\n    base_t = _3733;\n    float4 _2576 = (_3733 * _459.fa_base_color) * i.vertex_color;\n    float3 _3667 = i.world_normal;\n    if (_459.fa_maps.z > 0.5)\n    {\n        float param_4 = _459.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _2608 = fa_tex_fix(param_6, param_7);\n        float3 _2611 = (_2608 * 2.0) - float3(1.0);\n        float2 _2616 = _2611.xy * _459.fa_maps.x;\n        float3 _3741 = _2611;\n        _3741.x = _2616.x;\n        _3741.y = _2616.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _3741;\n        _3667 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _459.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _2645 = fa_tex_fix(param_12, param_13);\n    float4 _3744 = mrt;\n    _3744.x = _2645.x;\n    _3744.y = _2645.y;\n    _3744.z = _2645.z;\n    mrt = _3744;\n    float4 _2673 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _459.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _2673.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _2685 = fa_tex_fix(param_16, param_17);\n    float param_18 = _459.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _2715 = fa_tex_fix(param_20, param_21);\n    float _3672 = _459.fa_layers_a.x;\n    float _3673 = _459.fa_layers_a.y;\n    float _3676 = _459.fa_layers_a.z;\n    float _3675 = _459.fa_layers_b.w;\n    float _3678 = _459.fa_layers_c.x;\n    if (_459.fa_layers_c.z > 0.5)\n    {\n        if (mod(_459.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _3672 *= _2685.y;\n            _3673 *= _2685.z;\n            _3675 *= _2673.w;\n        }\n        if (_459.fa_layers_c.z > 1.5)\n        {\n            _3676 *= mrt.x;\n            _3678 *= mrt.w;\n        }\n    }\n    return Surface{ _2576.xyz, _2576.w, _3667, fast::clamp(_459.fa_pbr.x * _2645.z, 0.0, 1.0), fast::clamp(_459.fa_pbr.y * _2645.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_459.fa_maps.y * (_2685.x - 1.0)), _459.fa_emissive.xyz + (_459.fa_model_emissive.xyz * _2715), _3672, _3673, _459.fa_layers_b.xyz, _3675, _3676, _459.fa_layers_a.w, _3678, _459.fa_layers_c.y, _459.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread Surface& s, constant fa_mesh_fs_params& _459)\n{\n    s.emission += float3(0.5 + (0.5 * sin(_459.fa_time.x * 3.0)), 0.25 * fract(_459.fa_time.x), 0.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_sheen_albedo(thread const float& ndv, thread const float& rough)\n{\n    float _1514 = fast::min(sqrt(fast::max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _1522 = fast::min(sqrt(fast::clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _1525 = int(_1514);\n    int _1528 = int(_1522);\n    float _1538 = _1522 - float(_1528);\n    int _1594 = (_1525 * 9) + _1528;\n    int _1614 = ((_1525 + 1) * 9) + _1528;\n    return mix(mix(_1589[_1594], _1589[_1594 + 1], _1538), mix(_1589[_1614], _1589[_1614 + 1], _1538), _1514 - float(_1525));\n}\n\nstatic inline __attribute__((always_inline))\nFaLayers fa_layers_setup(thread const SurfaceInput& i, thread const Surface& s, thread const float3& n, thread const float3& v, thread const float& metallic, thread const float& roughness, thread float3& f0)\n{\n    bool _3603 = false;\n    float _3604 = 1.0;\n    float _3605 = 1.0;\n    float _3606 = 1.0;\n    float _3607 = 0.0;\n    float _3608 = 0.0;\n    float _3609 = 0.0;\n    float _3610 = 0.0;\n    float _3612 = 1.0;\n    bool _3613 = false;\n    float3 _3614 = float3(0.0);\n    float _3615 = 1.0;\n    float _3616 = 1.0;\n    float _3617 = 1.0;\n    float _3618 = 0.0;\n    float _3619 = 0.0;\n    float3 _3620 = float3(1.0, 0.0, 0.0);\n    float3 _3621 = float3(0.0, 0.0, 1.0);\n    float _3622 = 1.0;\n    float _3623 = 1.0;\n    float _1669 = fast::clamp(s.specular, 0.0, 1.0);\n    float _1673 = fast::clamp(s.ior, 1.0, 3.0);\n    bool _1678 = (_1669 != 1.0) || (_1673 != 1.5);\n    bool _1688;\n    if (!_1678)\n    {\n        _1688 = any(s.specular_color != float3(1.0));\n    }\n    else\n    {\n        _1688 = _1678;\n    }\n    if (_1688)\n    {\n        float _1696 = (_1673 - 1.0) / (_1673 + 1.0);\n        f0 = mix(fast::min(float3(_1696 * _1696) * fast::max(s.specular_color, float3(0.0)), float3(1.0)) * _1669, s.albedo, float3(metallic));\n        _3604 = mix(_1669, 1.0, metallic);\n        _3603 = true;\n    }\n    float _1724 = fast::clamp(s.clearcoat, 0.0, 1.0);\n    if (_1724 > 0.0)\n    {\n        float _1732 = fast::clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _3607 = _1724;\n        _3608 = _1732;\n        float _1739 = _1732 * _1732;\n        _3609 = _1739;\n        _3610 = _1739 * _1739;\n        float _1751 = fast::max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _3612 = _1751;\n        _3605 = 1.0 - (_1724 * (0.039999999105930328369140625 + (0.959999978542327880859375 * powr(fast::clamp(1.0 - _1751, 0.0, 1.0), 5.0))));\n        _3603 = true;\n    }\n    float3 _1771 = fast::max(s.sheen_color, float3(0.0));\n    float _1780 = fast::max(_1771.x, fast::max(_1771.y, _1771.z));\n    if (_1780 > 0.0)\n    {\n        float _1788 = fast::clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _3613 = true;\n        _3614 = _1771;\n        _3615 = _1788;\n        _3616 = _1788 * _1788;\n        float param = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _1788;\n        float _1805 = fa_sheen_albedo(param, param_1);\n        _3618 = _1805;\n        _3617 = 1.0 - fast::min(_1780 * _1805, 1.0);\n        _3603 = true;\n    }\n    _3606 = _3605 * _3617;\n    float _1824 = fast::clamp(s.anisotropy, -1.0, 1.0);\n    if (_1824 != 0.0)\n    {\n        float3 _1839 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _1839;\n        if (dot(_1839, _1839) < 9.9999999392252902907785028219223e-09)\n        {\n            t = cross(select(float3(1.0, 0.0, 0.0), float3(0.0, 1.0, 0.0), bool3(abs(n.y) < 0.9900000095367431640625)), n);\n        }\n        float3 _1857 = t;\n        float3 _1858 = fast::normalize(_1857);\n        t = _1858;\n        float3 _1883 = fast::normalize((_1858 * cos(s.anisotropy_rotation)) + ((cross(n, _1858) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _3620 = _1883;\n        _3621 = cross(n, _1883);\n        float _1893 = roughness * roughness;\n        float _1899 = mix(_1893, 1.0, _1824 * _1824);\n        bool _1901 = _1824 > 0.0;\n        _3622 = _1901 ? _1899 : _1893;\n        _3623 = _1901 ? _1893 : _1899;\n        _3619 = _1824;\n        _3603 = true;\n    }\n    return FaLayers{ short(_3603), _3604, _3605, _3606, _3607, _3608, _3609, _3610, i.world_normal, _3612, short(_3613), _3614, _3615, _3616, _3617, _3618, _3619, _3620, _3621, _3622, _3623 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _459, sampler fa_env_smp, texturecube<float> fa_irr_tex)\n{\n    if (_459.fa_env_sky.w > 0.5)\n    {\n        return fa_irr_tex.sample(fa_env_smp, n, level(0.0)).xyz;\n    }\n    return _459.fa_ambient.xyz;\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _459)\n{\n    int param = (int(_459.fa_cl_info.x) + int(_459.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _459, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, fa_light_tex, fa_shadow_smp, _459);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample(thread const int& li, thread const float3& world_pos, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li * 4;\n    float4 _331 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    int param_1 = (li * 4) + 1;\n    float4 _337 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float _340 = _337.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _347 = _340 < 0.5;\n    float3 l;\n    if (_347)\n    {\n        l = fast::normalize(_331.xyz);\n    }\n    else\n    {\n        float3 _359 = _331.xyz - world_pos;\n        float _361 = length(_359);\n        dist = _361;\n        l = _359 / float3(fast::max(_361, 9.9999997473787516355514526367188e-05));\n        float _376 = _361 / fast::max(_331.w, 0.001000000047497451305389404296875);\n        float _382 = fast::clamp(1.0 - (_376 * _376), 0.0, 1.0);\n        atten = _382 * _382;\n        if (_340 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            float4 _396 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n            float _406 = _396.w;\n            int param_3 = (li * 4) + 3;\n            float4 _413 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            float _414 = _413.x;\n            float cos_inner = _414;\n            if (_414 > 1.5)\n            {\n                cos_inner = mix(_406, 1.0, 0.25);\n            }\n            atten *= smoothstep(_406, cos_inner, dot(-l, fast::normalize(_396.xyz)));\n        }\n    }\n    int _445;\n    if (_347)\n    {\n        _445 = 0;\n    }\n    else\n    {\n        _445 = (_340 > 1.5) ? 2 : 1;\n    }\n    return LightSample{ l, _337.xyz * atten, atten, 1.0, dist, _445 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _695)\n{\n    float _685;\n    if (i == 0)\n    {\n        _685 = _695.fa_shadow_split.x;\n    }\n    else\n    {\n        float _701;\n        if (i == 1)\n        {\n            _701 = _695.fa_shadow_split.y;\n        }\n        else\n        {\n            float _709;\n            if (i == 2)\n            {\n                _709 = _695.fa_shadow_split.z;\n            }\n            else\n            {\n                _709 = _695.fa_shadow_split.w;\n            }\n            _701 = _709;\n        }\n        _685 = _701;\n    }\n    return _685;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _673 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_673), sin(_673)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _695, texture2d<float> fa_shadow_tex)\n{\n    float _747 = fast::max(_695.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _752 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _758 = sqrt(1.0 - (_752 * _752));\n    float _766 = fast::min(_758 / fast::max(_752, 0.20000000298023223876953125), 4.0);\n    float _771;\n    if (_695.fa_shadow_bias.y > 0.0)\n    {\n        _771 = _695.fa_shadow_bias.y;\n    }\n    else\n    {\n        _771 = 1.5 * _695.fa_shadow_info[ci].x;\n    }\n    float4 _796 = _695.fa_shadow_mat[ci] * float4(world + (n * (_771 * _758)), 1.0);\n    float _803 = _796.x;\n    bool _806 = _803 < _695.fa_shadow_rect[ci].x;\n    bool _815;\n    if (!_806)\n    {\n        _815 = _803 > _695.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _815 = _806;\n    }\n    bool _824;\n    if (!_815)\n    {\n        _824 = _796.y < _695.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _824 = _815;\n    }\n    bool _833;\n    if (!_824)\n    {\n        _833 = _796.y > _695.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _833 = _824;\n    }\n    bool _840;\n    if (!_833)\n    {\n        _840 = _796.z > 1.0;\n    }\n    else\n    {\n        _840 = _833;\n    }\n    if (_840)\n    {\n        return -1.0;\n    }\n    float _849;\n    if (_695.fa_shadow_bias.x > 0.0)\n    {\n        _849 = _695.fa_shadow_bias.x;\n    }\n    else\n    {\n        _849 = 1.5 * _695.fa_shadow_info[ci].x;\n    }\n    float _868 = _796.z - ((_849 * (1.0 + (0.5 * _766))) / _747);\n    float _877 = ((_695.fa_shadow_info[ci].x * fast::min(_766, 3.0)) * 0.5) / _747;\n    int _886 = int(_695.fa_shadow_cfg.z + 0.5);\n    if (_886 == 1)\n    {\n        float2 param = _796.xy;\n        float4 param_1 = _695.fa_shadow_rect[ci];\n        float _897 = fa_shadow_depth(param, param_1, fa_shadow_smp, fa_shadow_tex);\n        return float(_868 <= _897);\n    }\n    float _904 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    bool _907 = _886 == 2;\n    if (_907)\n    {\n        float _921 = fast::clamp(((_695.fa_shadow_cfg.w * _747) * 0.25) / _695.fa_shadow_info[ci].x, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _904;\n            float2 _940 = fa_shadow_vogel(param_2, param_3, param_4) * _921;\n            float2 param_5 = _796.xy + (_940 * _695.fa_shadow_bias.zw);\n            float4 param_6 = _695.fa_shadow_rect[ci];\n            float _951 = fa_shadow_depth(param_5, param_6, fa_shadow_smp, fa_shadow_tex);\n            if (_951 < (_868 - (length(_940) * _877)))\n            {\n                sum += _951;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = fast::clamp(((fast::max(_868 - (sum / cnt), 0.0) * _747) * _695.fa_shadow_cfg.w) / _695.fa_shadow_info[ci].x, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _995 = _907 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _995; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _995;\n        float param_9 = _904;\n        float2 _1014 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        float2 param_10 = _796.xy + (_1014 * _695.fa_shadow_bias.zw);\n        float4 param_11 = _695.fa_shadow_rect[ci];\n        float _1025 = fa_shadow_depth(param_10, param_11, fa_shadow_smp, fa_shadow_tex);\n        lit += float((_868 - (length(_1014) * _877)) <= _1025);\n    }\n    return lit / float(_995);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _459, thread float4& gl_FragCoord, constant fa_shadows& _695, texture2d<float> fa_shadow_tex)\n{\n    if (_459.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1055 = int(_695.fa_shadow_cfg.x + 0.5);\n    if (_1055 < 1)\n    {\n        return 1.0;\n    }\n    float _1071 = dot(world - _695.fa_shadow_eye.xyz, _695.fa_shadow_fwd.xyz);\n    int param = _1055 - 1;\n    if (_1071 > fa_shadow_split_at(param, _695))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1083 = _1055 > 1;\n    bool _1090;\n    if (_1083)\n    {\n        _1090 = _1071 > _695.fa_shadow_split.x;\n    }\n    else\n    {\n        _1090 = _1083;\n    }\n    if (_1090)\n    {\n        ci = 1;\n    }\n    bool _1094 = _1055 > 2;\n    bool _1101;\n    if (_1094)\n    {\n        _1101 = _1071 > _695.fa_shadow_split.y;\n    }\n    else\n    {\n        _1101 = _1094;\n    }\n    if (_1101)\n    {\n        ci = 2;\n    }\n    bool _1105 = _1055 > 3;\n    bool _1112;\n    if (_1105)\n    {\n        _1112 = _1071 > _695.fa_shadow_split.z;\n    }\n    else\n    {\n        _1112 = _1105;\n    }\n    if (_1112)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1055)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _1138 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_shadow_smp, gl_FragCoord, _695, fa_shadow_tex);\n        s = _1138;\n        if (_1138 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_695.fa_shadow_cfg.y > 0.0)\n    {\n        float _1163;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1163 = fa_shadow_split_at(param_5, _695);\n        }\n        else\n        {\n            _1163 = _695.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _1182 = _695.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _695) - _1163, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1193 = fast::clamp((_1071 - (fa_shadow_split_at(param_7, _695) - _1182)) / _1182, 0.0, 1.0);\n        if (_1193 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1055)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _1214 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_shadow_smp, gl_FragCoord, _695, fa_shadow_tex);\n                s2 = _1214;\n                if (_1214 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1193);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, sampler fa_shadow_smp, constant fa_mesh_fs_params& _459, thread float4& gl_FragCoord, constant fa_shadows& _695, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, fa_shadow_smp, _459, gl_FragCoord, _695, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, texture2d<float> fa_light_tex, sampler fa_shadow_smp, constant fa_mesh_fs_params& _459, thread float4& gl_FragCoord, constant fa_shadows& _695, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _2436 = fa_light_sample(param, param_1, fa_light_tex, fa_shadow_smp);\n    float3 _3652 = _2436.direction;\n    float3 _3647 = _2436.color;\n    float _3649 = _2436.shadow;\n    int _3657 = _2436.type;\n    if ((_3657 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _3652;\n        float _2450 = fa_shadow_factor(param_2, param_3, fa_shadow_smp, _459, gl_FragCoord, _695, fa_shadow_tex, fa_world_pos);\n        _3649 = _2450;\n        _3647 *= _2450;\n    }\n    return LightSample{ _3652, _3647, _2436.attenuation, _3649, _2436._distance, _3657 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_d_ggx_aniso(thread const float& ndh, thread const float& tdh, thread const float& bdh, thread const float& at, thread const float& ab)\n{\n    float _2051 = tdh / at;\n    float _2055 = bdh / ab;\n    float _2067 = ((_2051 * _2051) + (_2055 * _2055)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _2067) * _2067);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_lambda_ggx_aniso(thread const float& n, thread const float& t, thread const float& b, thread const float& at, thread const float& ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / fast::max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_v_ggx_aniso(thread const float& ndl, thread const float& ndv, thread const float& tdv, thread const float& bdv, thread const float& tdl, thread const float& bdl, thread const float& at, thread const float& ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return fast::clamp(1.0 / ((4.0 * fast::max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_d_charlie(thread const float& alpha, thread const float& ndh)\n{\n    float _2148 = 1.0 / alpha;\n    return ((2.0 + _2148) * powr(sqrt(fast::max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _2148)) * 0.15915493667125701904296875;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_v_ashikhmin(thread const float& ndl, thread const float& ndv)\n{\n    return fast::clamp(0.25 / fast::max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_layers_light(thread const FaLayers& L, thread const float3& diffuse_color, thread const float3& f0, thread const float3& n, thread const float3& v, thread const float3& l, thread const float3& h, thread const float& ndl, thread const float& ndv, thread const float& ndh, thread const float& vdh, thread const float& alpha, thread const float& a2)\n{\n    float _2181 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _2260 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _2260) * _2260);\n        vis = 0.5 / fast::max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    float3 base = diffuse_color + (((f0 + ((float3(L.f90) - f0) * powr(fast::clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _2181);\n    if (bool(L.sheen_on))\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _2181));\n    }\n    float3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        float _2333 = fast::max(dot(L.nc, l), 0.0);\n        float _2339 = fast::max(dot(L.nc, h), 0.0);\n        float _2348 = ((_2339 * _2339) * (L.coat_a2 - 1.0)) + 1.0;\n        result += float3((((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * powr(fast::clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _2348) * _2348)) * (0.5 / fast::max(mix((2.0 * _2333) * L.coat_ndv, _2333 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _2333)) * _2333);\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_light_rgb(thread const int& li, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp).xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_env_brdf(thread const float& rough, thread const float& ndv)\n{\n    float4 _1446 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _1449 = _1446.x;\n    return (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_1449 * _1449, exp2((-9.27999973297119140625) * ndv)) * _1449) + _1446.y)) + _1446.zw;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_environment(thread const float3& d, thread const float& rough, constant fa_mesh_fs_params& _459, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    if (_459.fa_env_sky.w > 0.5)\n    {\n        return fa_env_tex.sample(fa_env_smp, d, level(fast::clamp(rough, 0.0, 1.0) * _459.fa_env_horizon.w)).xyz;\n    }\n    float _1351 = rough * rough;\n    float _1381 = 0.60000002384185791015625 * _1351;\n    return mix(mix(_459.fa_env_horizon.xyz * 0.550000011920928955078125, mix(_459.fa_env_horizon.xyz, _459.fa_env_sky.xyz, float3(powr(fast::clamp(d.y * (1.0 - (0.699999988079071044921875 * _1351)), 0.0, 1.0), 0.550000011920928955078125))), float3(smoothstep((-0.0500000007450580596923828125) - _1381, 0.0500000007450580596923828125 + _1381, d.y))), ((_459.fa_env_sky.xyz + _459.fa_env_horizon.xyz) * 0.5) * 0.800000011920928955078125, float3(_1351 * 0.60000002384185791015625));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_layers_ibl(thread const FaLayers& L, thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _459, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        float3 _1934;\n        if (L.aniso >= 0.0)\n        {\n            _1934 = L.b;\n        }\n        else\n        {\n            _1934 = L.t;\n        }\n        rn = fast::normalize(mix(n, cross(cross(_1934, v), _1934), float3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _1967 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3, _459, fa_env_tex, fa_env_smp) * ((f0 * _1967.x) + (float3(L.f90) * _1967.y))) * L.base_scale;\n    if (bool(L.sheen_on))\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5, _459, fa_env_tex, fa_env_smp));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _2022 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9, _459, fa_env_tex, fa_env_smp) * (L.coat * ((0.039999999105930328369140625 * _2022.x) + _2022.y)));\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_reflection(thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _459, texturecube<float> fa_env_tex, sampler fa_env_smp)\n{\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _1488 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3, _459, fa_env_tex, fa_env_smp) * ((f0 * _1488.x) + float3(_1488.y));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _695)\n{\n    if (_695.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _1238 = int(_695.fa_shadow_cfg.x + 0.5);\n    float _1248 = dot(world - _695.fa_shadow_eye.xyz, _695.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _1253 = _1238 > 0;\n    bool _1262;\n    if (_1253)\n    {\n        int param = _1238 - 1;\n        _1262 = _1248 <= fa_shadow_split_at(param, _695);\n    }\n    else\n    {\n        _1262 = _1253;\n    }\n    if (_1262)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1269 = _1238 > 1;\n        bool _1276;\n        if (_1269)\n        {\n            _1276 = _1248 > _695.fa_shadow_split.x;\n        }\n        else\n        {\n            _1276 = _1269;\n        }\n        if (_1276)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1282 = _1238 > 2;\n        bool _1289;\n        if (_1282)\n        {\n            _1289 = _1248 > _695.fa_shadow_split.y;\n        }\n        else\n        {\n            _1289 = _1282;\n        }\n        if (_1289)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1295 = _1238 > 3;\n        bool _1302;\n        if (_1295)\n        {\n            _1302 = _1248 > _695.fa_shadow_split.z;\n        }\n        else\n        {\n            _1302 = _1295;\n        }\n        if (_1302)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _459 [[buffer(1)]], constant fa_shadows& _695 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_env_tex [[texture(6)]], texturecube<float> fa_irr_tex [[texture(7)]], texture2d<float> fa_light_tex [[texture(8)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _3382 = fast::normalize(in.fa_world_normal);\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _3382 = -_3382;\n    }\n    float3 _2836 = fast::normalize(_459.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, fa_light_tex, fa_shadow_smp, _459, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _3382, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2836, short(gl_FrontFacing) };\n    Surface _2844 = fa_standard_surface(param_1, _459, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _3413 = _2844.albedo;\n    float _3414 = _2844.alpha;\n    float3 _3415 = _2844.normal;\n    float _3416 = _2844.metallic;\n    float _3417 = _2844.roughness;\n    float _3418 = _2844.occlusion;\n    float3 _3419 = _2844.emission;\n    float _3420 = _2844.clearcoat;\n    float _3421 = _2844.clearcoat_roughness;\n    float3 _3422 = _2844.sheen_color;\n    float _3423 = _2844.sheen_roughness;\n    float _3424 = _2844.anisotropy;\n    float _3425 = _2844.anisotropy_rotation;\n    float _3426 = _2844.specular;\n    float _3427 = _2844.ior;\n    float3 _3428 = _2844.specular_color;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _3382, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2836, short(gl_FrontFacing) };\n    Surface param_3 = _2844;\n    surface(param_2, param_3, _459);\n    _3413 = param_3.albedo;\n    _3414 = param_3.alpha;\n    _3415 = param_3.normal;\n    _3416 = param_3.metallic;\n    _3417 = param_3.roughness;\n    _3418 = param_3.occlusion;\n    _3419 = param_3.emission;\n    _3420 = param_3.clearcoat;\n    _3421 = param_3.clearcoat_roughness;\n    _3422 = param_3.sheen_color;\n    _3423 = param_3.sheen_roughness;\n    _3424 = param_3.anisotropy;\n    _3425 = param_3.anisotropy_rotation;\n    _3426 = param_3.specular;\n    _3427 = param_3.ior;\n    _3428 = param_3.specular_color;\n    float3 result;\n    if (_459.fa_emissive.w > 0.5)\n    {\n        result = _3413;\n    }\n    else\n    {\n        float3 _2866 = fast::normalize(_3415);\n        float _2873 = fast::clamp(_3416, 0.0, 1.0);\n        float _2877 = fast::clamp(_3417, 0.0500000007450580596923828125, 1.0);\n        float _2881 = _2877 * _2877;\n        float _2885 = _2881 * _2881;\n        float _2890 = fast::max(dot(_2866, _2836), 9.9999997473787516355514526367188e-05);\n        float3 _2896 = _3413 * (1.0 - _2873);\n        float3 _2903 = mix(float3(0.039999999105930328369140625), _3413, float3(_2873));\n        float3 f0 = _2903;\n        SurfaceInput param_4 = SurfaceInput{ in.fa_world_pos, _3382, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _2836, short(gl_FrontFacing) };\n        Surface param_5 = Surface{ _3413, _3414, _3415, _3416, _3417, _3418, _3419, _3420, _3421, _3422, _3423, _3424, _3425, _3426, _3427, _3428 };\n        float3 param_6 = _2866;\n        float3 param_7 = _2836;\n        float param_8 = _2873;\n        float param_9 = _2877;\n        float3 param_10 = _2903;\n        FaLayers _2919 = fa_layers_setup(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        f0 = param_10;\n        float3 param_11 = _2866;\n        float3 lit = (fa_ambient_light(param_11, _459, fa_env_smp, fa_irr_tex) * _2896) * _3418;\n        if (_2919.on)\n        {\n            lit *= _2919.base_scale;\n        }\n        int _2941 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _2941; ln++)\n        {\n            int param_12 = ln;\n            int _2954 = fa_cl_light(param_12, fa_light_tex, fa_shadow_smp, _459, fa_cl_ndir, fa_cl_slot);\n            int param_13 = _2954;\n            float3 param_14 = in.fa_world_pos;\n            float3 param_15 = _3382;\n            LightSample _2963 = fa_light_shadowed(param_13, param_14, param_15, fa_light_tex, fa_shadow_smp, _459, gl_FragCoord, _695, fa_shadow_tex, in.fa_world_pos);\n            float3 _3587 = _2963.direction;\n            float _2971 = fast::max(dot(_2866, _3587), 0.0);\n            float _2977 = _2963.attenuation * _2963.shadow;\n            float3 _2982 = fast::normalize(_3587 + _2836);\n            float _2987 = fast::max(dot(_2866, _2982), 0.0);\n            float _2992 = fast::max(dot(_2836, _2982), 0.0);\n            if (_2919.on)\n            {\n                FaLayers param_16 = _2919;\n                float3 param_17 = _2896;\n                float3 param_18 = f0;\n                float3 param_19 = _2866;\n                float3 param_20 = _2836;\n                float3 param_21 = _3587;\n                float3 param_22 = _2982;\n                float param_23 = _2971;\n                float param_24 = _2890;\n                float param_25 = _2987;\n                float param_26 = _2992;\n                float param_27 = _2881;\n                float param_28 = _2885;\n                int param_29 = _2954;\n                lit += (fa_layers_light(param_16, param_17, param_18, param_19, param_20, param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28) * (fa_light_rgb(param_29, fa_light_tex, fa_shadow_smp) * _2977));\n            }\n            else\n            {\n                float _3040 = ((_2987 * _2987) * (_2885 - 1.0)) + 1.0;\n                int param_30 = _2954;\n                lit += (((_2896 + (((f0 + ((float3(1.0) - f0) * powr(1.0 - _2992, 5.0))) * (((_2885 / ((3.1415927410125732421875 * _3040) * _3040)) * (0.5 / fast::max(mix((2.0 * _2971) * _2890, _2971 + _2890, _2881), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _2971))) * fa_light_rgb(param_30, fa_light_tex, fa_shadow_smp)) * (_2971 * _2977));\n            }\n        }\n        if (_2919.on)\n        {\n            FaLayers param_31 = _2919;\n            float3 param_32 = _2866;\n            float3 param_33 = _2836;\n            float3 param_34 = f0;\n            float param_35 = _2877;\n            lit += (fa_layers_ibl(param_31, param_32, param_33, param_34, param_35, _459, fa_env_tex, fa_env_smp) * _3418);\n        }\n        else\n        {\n            float3 param_36 = _2866;\n            float3 param_37 = _2836;\n            float3 param_38 = f0;\n            float param_39 = _2877;\n            lit += (fa_sky_reflection(param_36, param_37, param_38, param_39, _459, fa_env_tex, fa_env_smp) * _3418);\n        }\n        result = lit;\n    }\n    float3 _3133 = result;\n    float3 _3134 = _3133 + _3419;\n    result = _3134;\n    float3 param_40 = _3134;\n    float3 param_41 = in.fa_world_pos;\n    result = fa_shadow_debug(param_40, param_41, _695);\n    bool _3143 = _459.fa_fog.w > 0.0;\n    bool _3150;\n    if (!_3143)\n    {\n        _3150 = _459.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _3150 = _3143;\n    }\n    if (_3150)\n    {\n        float3 _3159 = in.fa_world_pos - _459.fa_camera_pos.xyz;\n        float _3165 = dot(_3159, _459.fa_fog_c.xyz);\n        bool _3169 = _459.fa_fog_c.w > 0.5;\n        float _3170;\n        if (_3169)\n        {\n            _3170 = _3165;\n        }\n        else\n        {\n            _3170 = length(_3159);\n        }\n        float _3182 = _3170 - _459.fa_fog_b.x;\n        if (_3182 > 0.0)\n        {\n            float _3191 = _459.fa_fog.w * _3182;\n            float tau = _3191 * _3191;\n            if (_459.fa_fog_b.y > 0.0)\n            {\n                float _3207;\n                if (_3169)\n                {\n                    _3207 = in.fa_world_pos.y - (_459.fa_fog_c.y * _3165);\n                }\n                else\n                {\n                    _3207 = _459.fa_camera_pos.y;\n                }\n                float _3228 = mix(_3207, in.fa_world_pos.y, fast::clamp(_459.fa_fog_b.x / _3170, 0.0, 1.0));\n                float _3232 = in.fa_world_pos.y - _3228;\n                float _3237 = _3228 - _459.fa_fog_b.z;\n                float _3242 = in.fa_world_pos.y - _459.fa_fog_b.z;\n                bool _3245 = _3237 <= 0.0;\n                bool _3246 = !_3245;\n                bool _3252;\n                if (_3246)\n                {\n                    _3252 = _459.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3252 = _3245;\n                }\n                float _3253;\n                if (_3252)\n                {\n                    _3253 = _459.fa_fog_b.y;\n                }\n                else\n                {\n                    _3253 = _459.fa_fog_b.y * exp(-fast::min(_459.fa_fog_b.w * _3237, 80.0));\n                }\n                bool _3280;\n                if (_3246)\n                {\n                    _3280 = _459.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3280 = _3245;\n                }\n                float _3281;\n                if (_3280)\n                {\n                    _3281 = _459.fa_fog_b.y * _3237;\n                }\n                else\n                {\n                    _3281 = (_459.fa_fog_b.y * (1.0 - exp(-fast::min(_459.fa_fog_b.w * _3237, 80.0)))) / _459.fa_fog_b.w;\n                }\n                bool _3306 = _3242 <= 0.0;\n                bool _3313;\n                if (!_3306)\n                {\n                    _3313 = _459.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3313 = _3306;\n                }\n                float _3314;\n                if (_3313)\n                {\n                    _3314 = _459.fa_fog_b.y * _3242;\n                }\n                else\n                {\n                    _3314 = (_459.fa_fog_b.y * (1.0 - exp(-fast::min(_459.fa_fog_b.w * _3242, 80.0)))) / _459.fa_fog_b.w;\n                }\n                float _3341;\n                if (abs(_3232) < 0.001000000047497451305389404296875)\n                {\n                    _3341 = _3253;\n                }\n                else\n                {\n                    _3341 = (_3314 - _3281) / _3232;\n                }\n                tau += (_3182 * fast::max(_3341, 0.0));\n            }\n            result = mix(result, _459.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _3414);\n    return out;\n}\n\n",
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
            "inst_name": "_136",
            "msl_buffer_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_183",
            "msl_buffer_n": 3
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_459",
            "msl_buffer_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_695",
            "msl_buffer_n": 7
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
              "slot": 14,
              "stage": "fragment",
              "name": "fa_env_tex",
              "multisampled": false,
              "type": "cube",
              "sample_type": "float",
              "msl_texture_n": 6
            }
          },
          {
            "texture": {
              "slot": 15,
              "stage": "fragment",
              "name": "fa_irr_tex",
              "multisampled": false,
              "type": "cube",
              "sample_type": "float",
              "msl_texture_n": 7
            }
          },
          {
            "texture": {
              "slot": 24,
              "stage": "fragment",
              "name": "fa_light_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float",
              "msl_texture_n": 8
            }
          }
        ],
        "samplers": [
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_shadow_smp",
            "sampler_type": "nonfiltering",
            "msl_sampler_n": 1
          },
          {
            "slot": 10,
            "stage": "fragment",
            "name": "fa_env_smp",
            "sampler_type": "filtering",
            "msl_sampler_n": 10
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
            "name": "fa_light_tex_fa_shadow_smp",
            "view_name": "fa_light_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 24,
            "sampler_slot": 1
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_tex_fa_smp",
            "view_name": "fa_tex",
            "sampler_name": "fa_smp",
            "view_slot": 0,
            "sampler_slot": 0
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "fa_normal_tex_fa_smp",
            "view_name": "fa_normal_tex",
            "sampler_name": "fa_smp",
            "view_slot": 2,
            "sampler_slot": 0
          },
          {
            "slot": 3,
            "stage": "fragment",
            "name": "fa_mr_tex_fa_smp",
            "view_name": "fa_mr_tex",
            "sampler_name": "fa_smp",
            "view_slot": 3,
            "sampler_slot": 0
          },
          {
            "slot": 4,
            "stage": "fragment",
            "name": "fa_occlusion_tex_fa_smp",
            "view_name": "fa_occlusion_tex",
            "sampler_name": "fa_smp",
            "view_slot": 4,
            "sampler_slot": 0
          },
          {
            "slot": 5,
            "stage": "fragment",
            "name": "fa_emissive_tex_fa_smp",
            "view_name": "fa_emissive_tex",
            "sampler_name": "fa_smp",
            "view_slot": 5,
            "sampler_slot": 0
          },
          {
            "slot": 6,
            "stage": "fragment",
            "name": "fa_irr_tex_fa_env_smp",
            "view_name": "fa_irr_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 15,
            "sampler_slot": 10
          },
          {
            "slot": 7,
            "stage": "fragment",
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1
          },
          {
            "slot": 8,
            "stage": "fragment",
            "name": "fa_env_tex_fa_env_smp",
            "view_name": "fa_env_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10
          }
        ]
      }
    },
    "prepass": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_prepass_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float& fa_pre_depth, thread float3& fa_pre_r0, thread float3& fa_pre_r1, thread float3& fa_pre_r2, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _131);\n    float3 _299 = _160.world_pos;\n    float4 _171 = float4(_299, 1.0);\n    fa_world_pos = _299;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -(_131.fa_light_vp * _171).z;\n    fa_pre_r0 = float3(_131.fa_light_vp[0].x, _131.fa_light_vp[1].x, _131.fa_light_vp[2].x);\n    fa_pre_r1 = float3(_131.fa_light_vp[0].y, _131.fa_light_vp[1].y, _131.fa_light_vp[2].y);\n    fa_pre_r2 = float3(_131.fa_light_vp[0].z, _131.fa_light_vp[1].z, _131.fa_light_vp[2].z);\n    gl_Position = _131.fa_view_proj * _171;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _131 [[buffer(0)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5, _131, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_pre_depth, out.fa_pre_r0, out.fa_pre_r1, out.fa_pre_r2, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _195 = fa_linear_to_srgb(param);\n        c = _195;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _203 = fa_srgb_to_linear(param_1);\n            c = _203;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _56;\n    if (bool(i.front_facing))\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = fast::normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = fast::normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (bool(i.front_facing))\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _125, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _125.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _243 = fa_tex_fix(param_2, param_3);\n    float4 _750 = base_t;\n    _750.x = _243.x;\n    _750.y = _243.y;\n    _750.z = _243.z;\n    base_t = _750;\n    float4 _259 = (_750 * _125.fa_base_color) * i.vertex_color;\n    float3 _713 = i.world_normal;\n    if (_125.fa_maps.z > 0.5)\n    {\n        float param_4 = _125.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _293 = fa_tex_fix(param_6, param_7);\n        float3 _297 = (_293 * 2.0) - float3(1.0);\n        float2 _302 = _297.xy * _125.fa_maps.x;\n        float3 _758 = _297;\n        _758.x = _302.x;\n        _758.y = _302.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _758;\n        _713 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _125.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _331 = fa_tex_fix(param_12, param_13);\n    float4 _761 = mrt;\n    _761.x = _331.x;\n    _761.y = _331.y;\n    _761.z = _331.z;\n    mrt = _761;\n    float4 _361 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _125.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _361.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _373 = fa_tex_fix(param_16, param_17);\n    float param_18 = _125.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _403 = fa_tex_fix(param_20, param_21);\n    float _718 = _125.fa_layers_a.x;\n    float _719 = _125.fa_layers_a.y;\n    float _722 = _125.fa_layers_a.z;\n    float _721 = _125.fa_layers_b.w;\n    float _724 = _125.fa_layers_c.x;\n    if (_125.fa_layers_c.z > 0.5)\n    {\n        if (mod(_125.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _718 *= _373.y;\n            _719 *= _373.z;\n            _721 *= _361.w;\n        }\n        if (_125.fa_layers_c.z > 1.5)\n        {\n            _722 *= mrt.x;\n            _724 *= mrt.w;\n        }\n    }\n    return Surface{ _259.xyz, _259.w, _713, fast::clamp(_125.fa_pbr.x * _331.z, 0.0, 1.0), fast::clamp(_125.fa_pbr.y * _331.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_125.fa_maps.y * (_373.x - 1.0)), _125.fa_emissive.xyz + (_125.fa_model_emissive.xyz * _403), _718, _719, _125.fa_layers_b.xyz, _721, _722, _125.fa_layers_a.w, _724, _125.fa_layers_c.y, _125.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread Surface& s, constant fa_mesh_fs_params& _125)\n{\n    s.emission += float3(0.5 + (0.5 * sin(_125.fa_time.x * 3.0)), 0.25 * fract(_125.fa_time.x), 0.0);\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _125 [[buffer(1)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], sampler fa_smp [[sampler(0)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _624 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _624 = -_624;\n    }\n    float3 _536 = fast::normalize(_125.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _624, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _536, short(gl_FrontFacing) };\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _624, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _536, short(gl_FrontFacing) };\n    Surface param_2 = fa_standard_surface(param, _125, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    surface(param_1, param_2, _125);\n    float3 _551 = fast::normalize(param_2.normal);\n    float3 _566 = fast::normalize(float3(dot(in.fa_pre_r0, _551), dot(in.fa_pre_r1, _551), dot(in.fa_pre_r2, _551)));\n    float _578 = _566.z;\n    float2 e = _566.xy / float2((abs(_566.x) + abs(_566.y)) + abs(_578));\n    if (_578 < 0.0)\n    {\n        e = (float2(1.0) - abs(e.yx)) * float2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    out.fa_frag_color = float4(fast::min(in.fa_pre_depth, 60000.0), e, 1.0);\n    return out;\n}\n\n",
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
            "inst_name": "_131",
            "msl_buffer_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_125",
            "msl_buffer_n": 1
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
          }
        ],
        "samplers": [
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
          }
        ]
      }
    },
    "prepass_skin": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n    float4 fa_joints [[attribute(9)]];\n    float4 fa_weights [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _183)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_183.fa_joint_rows[_174] * weights[i]);\n        r1 += (_183.fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183.fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_prepass_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float& fa_pre_depth, thread float3& fa_pre_r0, thread float3& fa_pre_r1, thread float3& fa_pre_r2, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _136);\n    float3 _420 = _273.world_pos;\n    float4 _284 = float4(_420, 1.0);\n    fa_world_pos = _420;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    fa_pre_depth = -(_136.fa_light_vp * _284).z;\n    fa_pre_r0 = float3(_136.fa_light_vp[0].x, _136.fa_light_vp[1].x, _136.fa_light_vp[2].x);\n    fa_pre_r1 = float3(_136.fa_light_vp[0].y, _136.fa_light_vp[1].y, _136.fa_light_vp[2].y);\n    fa_pre_r2 = float3(_136.fa_light_vp[0].z, _136.fa_light_vp[1].z, _136.fa_light_vp[2].z);\n    gl_Position = _136.fa_view_proj * _284;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _136 [[buffer(0)]], constant fa_skin& _183 [[buffer(3)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float4x4 param_2 = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _183);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7, _136, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_pre_depth, out.fa_pre_r0, out.fa_pre_r1, out.fa_pre_r2, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _195 = fa_linear_to_srgb(param);\n        c = _195;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _203 = fa_srgb_to_linear(param_1);\n            c = _203;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _56;\n    if (bool(i.front_facing))\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = fast::normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = fast::normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (bool(i.front_facing))\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _125, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _125.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _243 = fa_tex_fix(param_2, param_3);\n    float4 _750 = base_t;\n    _750.x = _243.x;\n    _750.y = _243.y;\n    _750.z = _243.z;\n    base_t = _750;\n    float4 _259 = (_750 * _125.fa_base_color) * i.vertex_color;\n    float3 _713 = i.world_normal;\n    if (_125.fa_maps.z > 0.5)\n    {\n        float param_4 = _125.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _293 = fa_tex_fix(param_6, param_7);\n        float3 _297 = (_293 * 2.0) - float3(1.0);\n        float2 _302 = _297.xy * _125.fa_maps.x;\n        float3 _758 = _297;\n        _758.x = _302.x;\n        _758.y = _302.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _758;\n        _713 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _125.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _331 = fa_tex_fix(param_12, param_13);\n    float4 _761 = mrt;\n    _761.x = _331.x;\n    _761.y = _331.y;\n    _761.z = _331.z;\n    mrt = _761;\n    float4 _361 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _125.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _361.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _373 = fa_tex_fix(param_16, param_17);\n    float param_18 = _125.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _403 = fa_tex_fix(param_20, param_21);\n    float _718 = _125.fa_layers_a.x;\n    float _719 = _125.fa_layers_a.y;\n    float _722 = _125.fa_layers_a.z;\n    float _721 = _125.fa_layers_b.w;\n    float _724 = _125.fa_layers_c.x;\n    if (_125.fa_layers_c.z > 0.5)\n    {\n        if (mod(_125.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _718 *= _373.y;\n            _719 *= _373.z;\n            _721 *= _361.w;\n        }\n        if (_125.fa_layers_c.z > 1.5)\n        {\n            _722 *= mrt.x;\n            _724 *= mrt.w;\n        }\n    }\n    return Surface{ _259.xyz, _259.w, _713, fast::clamp(_125.fa_pbr.x * _331.z, 0.0, 1.0), fast::clamp(_125.fa_pbr.y * _331.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_125.fa_maps.y * (_373.x - 1.0)), _125.fa_emissive.xyz + (_125.fa_model_emissive.xyz * _403), _718, _719, _125.fa_layers_b.xyz, _721, _722, _125.fa_layers_a.w, _724, _125.fa_layers_c.y, _125.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread Surface& s, constant fa_mesh_fs_params& _125)\n{\n    s.emission += float3(0.5 + (0.5 * sin(_125.fa_time.x * 3.0)), 0.25 * fract(_125.fa_time.x), 0.0);\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _125 [[buffer(1)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], sampler fa_smp [[sampler(0)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _624 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _624 = -_624;\n    }\n    float3 _536 = fast::normalize(_125.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _624, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _536, short(gl_FrontFacing) };\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _624, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _536, short(gl_FrontFacing) };\n    Surface param_2 = fa_standard_surface(param, _125, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    surface(param_1, param_2, _125);\n    float3 _551 = fast::normalize(param_2.normal);\n    float3 _566 = fast::normalize(float3(dot(in.fa_pre_r0, _551), dot(in.fa_pre_r1, _551), dot(in.fa_pre_r2, _551)));\n    float _578 = _566.z;\n    float2 e = _566.xy / float2((abs(_566.x) + abs(_566.y)) + abs(_578));\n    if (_578 < 0.0)\n    {\n        e = (float2(1.0) - abs(e.yx)) * float2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    out.fa_frag_color = float4(fast::min(in.fa_pre_depth, 60000.0), e, 1.0);\n    return out;\n}\n\n",
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
            "inst_name": "_136",
            "msl_buffer_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_183",
            "msl_buffer_n": 3
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_125",
            "msl_buffer_n": 1
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
          }
        ],
        "samplers": [
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
          }
        ]
      }
    }
  }
}
