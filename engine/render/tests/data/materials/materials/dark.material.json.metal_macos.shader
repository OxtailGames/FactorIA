{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "57cbd5df71b0000e548dcd5fbfe873bc15510a64a336f6248792368f21adbf33",
  "slang": "metal_macos",
  "params": [],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float3 fa_lm [[user(locn5)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _131);\n    float3 _267 = _160.world_pos;\n    fa_world_pos = _267;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = _131.fa_view_proj * float4(_267, 1.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _131 [[buffer(0)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5, _131, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.gl_Position);\n    out.fa_lm = float3(0.0);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n#pragma clang diagnostic ignored \"-Wmissing-braces\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\ntemplate<typename T, size_t Num>\nstruct spvUnsafeArray\n{\n    T elements[Num ? Num : 1];\n    \n    thread T& operator [] (size_t pos) thread\n    {\n        return elements[pos];\n    }\n    constexpr const thread T& operator [] (size_t pos) const thread\n    {\n        return elements[pos];\n    }\n    \n    device T& operator [] (size_t pos) device\n    {\n        return elements[pos];\n    }\n    constexpr const device T& operator [] (size_t pos) const device\n    {\n        return elements[pos];\n    }\n    \n    constexpr const constant T& operator [] (size_t pos) const constant\n    {\n        return elements[pos];\n    }\n    \n    threadgroup T& operator [] (size_t pos) threadgroup\n    {\n        return elements[pos];\n    }\n    constexpr const threadgroup T& operator [] (size_t pos) const threadgroup\n    {\n        return elements[pos];\n    }\n};\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n    float4 fa_ct_a;\n    float4 fa_ct_b;\n    float4 fa_ct_vpx;\n    float4 fa_ct_vpy;\n    float4 fa_ct_vpw;\n    float4 fa_ct_fwd;\n    float4 fa_probe_sh[9];\n    float4 fa_atlas;\n    float4 fa_rpa_tile;\n    float4 fa_rpa_pos;\n    float4 fa_rpa_bx;\n    float4 fa_rpa_by;\n    float4 fa_rpa_bz;\n    float4 fa_rpb_tile;\n    float4 fa_rpb_pos;\n    float4 fa_rpb_bx;\n    float4 fa_rpb_by;\n    float4 fa_rpb_bz;\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n    float4 fa_shadow_lcfg;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float3 fa_lm [[user(locn5)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_cluster_texel(thread const float3& world_pos, constant fa_mesh_fs_params& _395, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    bool _1323 = _395.fa_cl_info.x < 0.0;\n    bool _1330;\n    if (!_1323)\n    {\n        _1330 = _395.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _1330 = _1323;\n    }\n    bool _1338;\n    if (!_1330)\n    {\n        _1338 = _395.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _1338 = _1330;\n    }\n    bool _1345;\n    if (!_1338)\n    {\n        _1345 = _395.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _1345 = _1338;\n    }\n    bool _1352;\n    if (!_1345)\n    {\n        _1352 = _395.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _1352 = _1345;\n    }\n    if (_1352)\n    {\n        return float4(0.0);\n    }\n    float4 _1362 = float4(world_pos, 1.0);\n    float _1368 = dot(_395.fa_cl_vpw, _1362);\n    if (!(_1368 > 9.9999999747524270787835121154785e-07))\n    {\n        return float4(0.0);\n    }\n    float2 _1390 = float2(dot(_395.fa_cl_vpx, _1362), dot(_395.fa_cl_vpy, _1362)) / float2(_1368);\n    int _1394 = int(_395.fa_cl_grid.x);\n    int _1398 = int(_395.fa_cl_grid.y);\n    int param = (int(_395.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_395.fa_cl_fwd.xyz, world_pos) + _395.fa_cl_fwd.w, _395.fa_cl_grid.w) / _395.fa_cl_grid.w) * _395.fa_cl_grid.z)), 0, int(_395.fa_cl_info.y) - 1) * _1398) + clamp(int(floor(((_1390.y * 0.5) + 0.5) * _395.fa_cl_grid.y)), 0, _1398 - 1)) * _1394)) + clamp(int(floor(((_1390.x * 0.5) + 0.5) * _395.fa_cl_grid.x)), 0, _1394 - 1);\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, constant fa_mesh_fs_params& _395, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    float3 param = world_pos;\n    float4 _1474 = fa_cluster_texel(param, _395, fa_light_tex, fa_shadow_smp);\n    return int2(int(_1474.x), int(_1474.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, constant fa_mesh_fs_params& _395, texture2d<float> fa_light_tex, sampler fa_shadow_smp, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_395.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _3650 = fa_cluster_lookup(param, _395, fa_light_tex, fa_shadow_smp);\n    fa_cl_slot = _3650.x;\n    fa_cl_local = _3650.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _3855 = fa_linear_to_srgb(param);\n        c = _3855;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _3863 = fa_srgb_to_linear(param_1);\n            c = _3863;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _277;\n    if (bool(i.front_facing))\n    {\n        _277 = i.world_normal;\n    }\n    else\n    {\n        _277 = -i.world_normal;\n    }\n    float3 _301 = fast::normalize(i.world_tangent.xyz - (_277 * dot(_277, i.world_tangent.xyz)));\n    float3 _328 = fast::normalize(((_301 * m.x) + ((cross(_277, _301) * i.world_tangent.w) * m.y)) + (_277 * m.z));\n    float3 _331;\n    if (bool(i.front_facing))\n    {\n        _331 = _328;\n    }\n    else\n    {\n        _331 = -_328;\n    }\n    return _331;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _395, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _395.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _3894 = fa_tex_fix(param_2, param_3);\n    float4 _4960 = base_t;\n    _4960.x = _3894.x;\n    _4960.y = _3894.y;\n    _4960.z = _3894.z;\n    base_t = _4960;\n    float4 _3908 = (_4960 * _395.fa_base_color) * i.vertex_color;\n    float3 _4812 = i.world_normal;\n    if (_395.fa_maps.z > 0.5)\n    {\n        float param_4 = _395.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _3940 = fa_tex_fix(param_6, param_7);\n        float3 _3943 = (_3940 * 2.0) - float3(1.0);\n        float2 _3948 = _3943.xy * _395.fa_maps.x;\n        float3 _4968 = _3943;\n        _4968.x = _3948.x;\n        _4968.y = _3948.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _4968;\n        _4812 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _395.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _3976 = fa_tex_fix(param_12, param_13);\n    float4 _4971 = mrt;\n    _4971.x = _3976.x;\n    _4971.y = _3976.y;\n    _4971.z = _3976.z;\n    mrt = _4971;\n    float4 _4004 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _395.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _4004.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _4015 = fa_tex_fix(param_16, param_17);\n    float param_18 = _395.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _4045 = fa_tex_fix(param_20, param_21);\n    float _4817 = _395.fa_layers_a.x;\n    float _4818 = _395.fa_layers_a.y;\n    float _4821 = _395.fa_layers_a.z;\n    float _4820 = _395.fa_layers_b.w;\n    float _4823 = _395.fa_layers_c.x;\n    if (_395.fa_layers_c.z > 0.5)\n    {\n        if (mod(_395.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _4817 *= _4015.y;\n            _4818 *= _4015.z;\n            _4820 *= _4004.w;\n        }\n        if (_395.fa_layers_c.z > 1.5)\n        {\n            _4821 *= mrt.x;\n            _4823 *= mrt.w;\n        }\n    }\n    return Surface{ _3908.xyz, _3908.w, _4812, fast::clamp(_395.fa_pbr.x * _3976.z, 0.0, 1.0), fast::clamp(_395.fa_pbr.y * _3976.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_395.fa_maps.y * (_4015.x - 1.0)), _395.fa_emissive.xyz + (_395.fa_model_emissive.xyz * _4045), _4817, _4818, _395.fa_layers_b.xyz, _4820, _4821, _395.fa_layers_a.w, _4823, _395.fa_layers_c.y, _395.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_decal_tile(thread const float4& rect, thread const float2& uv, thread const float2& atlas, thread const float2& ddx, thread const float2& ddy, sampler fa_env_smp, texture2d<float> fa_decal_tex)\n{\n    float2 _1554 = rect.zw - rect.xy;\n    float2 _1558 = _1554 * atlas;\n    float2 _1562 = ddx * _1558;\n    float2 _1566 = ddy * _1558;\n    return fa_decal_tex.sample(fa_env_smp, (rect.xy + (fast::clamp(uv, float2(0.0), float2(1.0)) * _1554)), level(fast::clamp(0.5 * log2(fast::max(fast::max(dot(_1562, _1562), dot(_1566, _1566)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_apply_decals(thread const float3& world_pos, thread const float3& geo_normal, thread float3& albedo, thread float3& normal, constant fa_mesh_fs_params& _395, texture2d<float> fa_light_tex, sampler fa_shadow_smp, sampler fa_env_smp, texture2d<float> fa_decal_tex)\n{\n    bool _1599 = _395.fa_counts.y < 0.5;\n    bool _1606;\n    if (!_1599)\n    {\n        _1606 = _395.fa_counts.w < 0.5;\n    }\n    else\n    {\n        _1606 = _1599;\n    }\n    if (_1606)\n    {\n        return;\n    }\n    float3 _1612 = dfdx(world_pos);\n    float3 _1615 = dfdy(world_pos);\n    float3 param = world_pos;\n    float4 _1619 = fa_cluster_texel(param, _395, fa_light_tex, fa_shadow_smp);\n    int _1623 = int(_1619.w);\n    if (_1623 < 1)\n    {\n        return;\n    }\n    int _1633 = int(_395.fa_counts.y + 0.5);\n    int param_1 = _1633;\n    float4 _1637 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float2 _1640 = _1637.yz;\n    int _1644 = int(_1637.w);\n    int param_2 = _1633 + 1;\n    float4 _1649 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float _1650 = _1649.x;\n    int _1656 = int(_395.fa_counts.w + 0.5) - 1;\n    int _1660 = int(_1619.z);\n    float3 _1925;\n    for (int k = 0; k < _1623; k++)\n    {\n        int _1673 = _1660 + k;\n        int param_3 = _1644 + (_1673 >> 2);\n        int _1690 = (_1633 + 2) + (int(fa_light_texel(param_3, fa_light_tex, fa_shadow_smp)[_1673 & 3]) * 7);\n        int param_4 = _1690 + 6;\n        float4 _1695 = fa_light_texel(param_4, fa_light_tex, fa_shadow_smp);\n        if (((int(_1695.w + 0.5) >> _1656) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1690;\n        float4 _1710 = fa_light_texel(param_5, fa_light_tex, fa_shadow_smp);\n        int param_6 = _1690 + 1;\n        float4 _1715 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n        int param_7 = _1690 + 2;\n        float4 _1720 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n        float3 _1723 = _1710.xyz;\n        float _1728 = dot(_1723, world_pos) + _1710.w;\n        float3 _1730 = _1715.xyz;\n        float _1735 = dot(_1730, world_pos) + _1715.w;\n        float3 _1737 = _1720.xyz;\n        float _1742 = dot(_1737, world_pos) + _1720.w;\n        bool _1747 = abs(_1728) > 0.5;\n        bool _1755;\n        if (!_1747)\n        {\n            _1755 = abs(_1735) > 0.5;\n        }\n        else\n        {\n            _1755 = _1747;\n        }\n        bool _1763;\n        if (!_1755)\n        {\n            _1763 = abs(_1742) > 0.5;\n        }\n        else\n        {\n            _1763 = _1755;\n        }\n        if (_1763)\n        {\n            continue;\n        }\n        float _1778 = fast::clamp(dot(geo_normal, fast::normalize(_1737)) * _1695.z, 0.0, 1.0);\n        if (_1778 <= 0.0)\n        {\n            continue;\n        }\n        float _1798 = (fast::clamp((0.5 - abs(_1742)) * 10.0, 0.0, 1.0) * _1778) * _1695.x;\n        float2 _1806 = float2(_1728 + 0.5, 0.5 - _1735);\n        float2 _1816 = float2(dot(_1723, _1612), dot(_1730, _1612));\n        float2 _1826 = float2(dot(_1723, _1615), dot(_1730, _1615));\n        int param_8 = _1690 + 5;\n        float4 _1831 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n        int param_9 = _1690 + 3;\n        float4 _1836 = fa_light_texel(param_9, fa_light_tex, fa_shadow_smp);\n        int param_10 = _1690 + 4;\n        float4 _1841 = fa_light_texel(param_10, fa_light_tex, fa_shadow_smp);\n        float tex_a = 1.0;\n        float3 col = _1831.xyz;\n        bool _1851 = _1836.z > _1836.x;\n        if (_1851)\n        {\n            float4 param_11 = _1836;\n            float2 param_12 = _1806;\n            float2 param_13 = _1640;\n            float2 param_14 = _1816;\n            float2 param_15 = _1826;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15, fa_env_smp, fa_decal_tex);\n            if ((_1650 > 0.5) && (_1650 < 1.5))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1877 = fa_dc_to_linear(param_16);\n                float4 _4892 = tx;\n                _4892.x = _1877.x;\n                _4892.y = _1877.y;\n                _4892.z = _1877.z;\n                tx = _4892;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, float3(fast::clamp((_1798 * tex_a) * _1831.w, 0.0, 1.0)));\n        if (_1841.z > _1841.x)\n        {\n            float4 param_17 = _1841;\n            float2 param_18 = _1806;\n            float2 param_19 = _1640;\n            float2 param_20 = _1816;\n            float2 param_21 = _1826;\n            float4 _1921 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21, fa_env_smp, fa_decal_tex);\n            if (_1650 > 1.5)\n            {\n                float3 param_22 = _1921.xyz;\n                float3 _1931 = fa_dc_to_srgb(param_22);\n                _1925 = _1931;\n            }\n            else\n            {\n                _1925 = _1921.xyz;\n            }\n            float3 _1940 = (_1925 * 2.0) - float3(1.0);\n            float2 _1945 = _1940.xy * _1695.y;\n            float3 _1967 = (fast::normalize(_1723) * _1945.x) + (fast::normalize(_1730) * _1945.y);\n            float3 _1970 = fast::normalize(normal);\n            normal = fast::normalize(mix(_1970, fast::normalize((_1970 * fast::max(_1940.z, 0.0500000007450580596923828125)) + (_1967 - (_1970 * dot(_1970, _1967)))), float3(fast::clamp(_1798 * (_1851 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_atlas_size(sampler fa_env_smp, texture2d<float> fa_probe_atlas)\n{\n    return float2(int2(fa_probe_atlas.get_width(), fa_probe_atlas.get_height()));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_probe_sh_coef(thread const float2& origin, thread const float& res, thread const int& k, constant fa_mesh_fs_params& _395, sampler fa_env_smp, texture2d<float> fa_probe_atlas)\n{\n    float3 v = fa_probe_atlas.sample(fa_env_smp, ((origin + float2(float(k) + 0.5, res + 2.5)) / fa_atlas_size(fa_env_smp, fa_probe_atlas)), level(0.0)).xyz;\n    if (_395.fa_atlas.y > 0.5)\n    {\n        v = (v - float3(0.5)) * 8.0;\n    }\n    return v;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sh_eval(thread const spvUnsafeArray<float3, 9>& c, thread const float3& n)\n{\n    float3 _3165 = fast::max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), float3(0.0));\n    return _3165;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _395, sampler fa_env_smp, texture2d<float> fa_probe_atlas)\n{\n    float _3221 = (1.0 - _395.fa_rpa_tile.w) - _395.fa_rpb_tile.w;\n    float3 amb = float3(0.0);\n    bool _3227 = _395.fa_env_sky.w > 0.5;\n    spvUnsafeArray<float3, 9> c;\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = float3(0.0);\n    }\n    if (_3221 > 0.0005000000237487256526947021484375)\n    {\n        if (_3227)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                float2 param = _395.fa_atlas.zw;\n                float param_1 = 128.0;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2, _395, fa_env_smp, fa_probe_atlas) * _3221;\n            }\n        }\n        else\n        {\n            amb = _395.fa_ambient.xyz * _3221;\n        }\n    }\n    bool _3280 = _395.fa_rpa_tile.w > 0.0;\n    if (_3280)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            float2 param_3 = _395.fa_rpa_tile.xy;\n            float param_4 = _395.fa_rpa_tile.z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5, _395, fa_env_smp, fa_probe_atlas) * _395.fa_rpa_tile.w);\n        }\n    }\n    bool _3311 = _395.fa_rpb_tile.w > 0.0;\n    if (_3311)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            float2 param_6 = _395.fa_rpb_tile.xy;\n            float param_7 = _395.fa_rpb_tile.z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8, _395, fa_env_smp, fa_probe_atlas) * _395.fa_rpb_tile.w);\n        }\n    }\n    if ((_3227 || _3280) || _3311)\n    {\n        spvUnsafeArray<float3, 9> param_9 = c;\n        float3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_indirect_diffuse(thread const float3& n, constant fa_mesh_fs_params& _395, sampler fa_env_smp, texture2d<float> fa_probe_atlas, thread float3& fa_lm, texture2d<float> fa_lightmap)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return fa_lightmap.sample(fa_env_smp, fa_lm.xy, level(0.0)).xyz;\n    }\n    if (_395.fa_probe_sh[0].w > 0.0)\n    {\n        spvUnsafeArray<float3, 9> c;\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = _395.fa_probe_sh[k].xyz;\n        }\n        float3 param = n;\n        spvUnsafeArray<float3, 9> param_1 = c;\n        float3 param_2 = n;\n        return mix(fa_ambient_light(param, _395, fa_env_smp, fa_probe_atlas), fa_sh_eval(param_1, param_2), float3(fast::clamp(_395.fa_probe_sh[0].w, 0.0, 1.0)));\n    }\n    float3 param_3 = n;\n    return fa_ambient_light(param_3, _395, fa_env_smp, fa_probe_atlas);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, constant fa_mesh_fs_params& _395, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (int(_395.fa_cl_info.x) + int(_395.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, constant fa_mesh_fs_params& _395, texture2d<float> fa_light_tex, sampler fa_shadow_smp, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, _395, fa_light_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_light_base(thread const int& li, constant fa_mesh_fs_params& _395)\n{\n    return li * ((_395.fa_ambient.w > 4.5) ? 8 : 4);\n}\n\nstatic inline __attribute__((always_inline))\nbool fa_light_baked(thread const int& li, constant fa_mesh_fs_params& _395, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li;\n    int param_1 = fa_light_base(param, _395) + 3;\n    return fa_light_texel(param_1, fa_light_tex, fa_shadow_smp).w > 0.5;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_baked_keep(thread const int& li, constant fa_mesh_fs_params& _395, texture2d<float> fa_light_tex, sampler fa_shadow_smp, thread float3& fa_lm)\n{\n    float _3620;\n    if (fa_lm.z > 0.5)\n    {\n        _3620 = 0.0;\n    }\n    else\n    {\n        _3620 = 1.0 - fast::clamp(_395.fa_probe_sh[0].w, 0.0, 1.0);\n    }\n    bool _3631 = _3620 < 1.0;\n    bool _3637;\n    if (_3631)\n    {\n        int param = li;\n        _3637 = fa_light_baked(param, _395, fa_light_tex, fa_shadow_smp);\n    }\n    else\n    {\n        _3637 = _3631;\n    }\n    return _3637 ? _3620 : 1.0;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_light_type(thread const int& li, constant fa_mesh_fs_params& _395, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li;\n    int param_1 = fa_light_base(param, _395) + 1;\n    return fa_light_texel(param_1, fa_light_tex, fa_shadow_smp).w;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_atlas_fetch(thread const float2& texel, texture2d<float> fa_light_atlas, sampler fa_env_smp)\n{\n    return fa_light_atlas.sample(fa_env_smp, (texel / float2(int2(fa_light_atlas.get_width(), fa_light_atlas.get_height()))), level(0.0));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_cookie_sample(thread const float2& tile_origin, thread const float2& uv, texture2d<float> fa_light_atlas, sampler fa_env_smp)\n{\n    float2 param = (tile_origin + float2(1.0)) + (fast::clamp(uv, float2(0.0), float2(1.0)) * 254.0);\n    return fa_atlas_fetch(param, fa_light_atlas, fa_env_smp).xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_area_point(thread const float3& c, thread const float3& axis, thread const float3& ru, thread const float3& uu, thread const float& hx, thread const float& hy, thread const float& shape, thread const float3& p, thread const float3& r)\n{\n    bool _573 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        float3 _586 = (c - (ru * hx)) - p;\n        float3 _592 = ru * (2.0 * hx);\n        float _598 = fast::max(dot(_592, _592), 9.9999999392252902907785028219223e-09);\n        float _602 = dot(_586, _592);\n        float t = fast::clamp((-_602) / _598, 0.0, 1.0);\n        if (_573)\n        {\n            float _617 = dot(r, _592);\n            float _623 = _598 - (_617 * _617);\n            if (abs(_623) > (9.9999997473787516355514526367188e-06 * _598))\n            {\n                t = fast::clamp(((dot(r, _586) * _617) - _602) / _623, 0.0, 1.0);\n            }\n        }\n        return (p + _586) + (_592 * t);\n    }\n    float3 q = p;\n    float _655 = dot(r, axis);\n    bool _663;\n    if (_573)\n    {\n        _663 = abs(_655) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _663 = _573;\n    }\n    if (_663)\n    {\n        float _673 = dot(c - p, axis) / _655;\n        if (_673 > 0.0)\n        {\n            q = p + (r * _673);\n        }\n    }\n    float3 _686 = q - c;\n    float2 xy = float2(dot(_686, ru), dot(_686, uu));\n    if (shape > 0.5)\n    {\n        float _701 = length(xy);\n        if (_701 > hx)\n        {\n            xy *= (hx / _701);\n        }\n    }\n    else\n    {\n        xy = fast::clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cube_face(thread const float3& d)\n{\n    float3 _343 = abs(d);\n    float _345 = _343.x;\n    float _347 = _343.y;\n    bool _348 = _345 >= _347;\n    bool _356;\n    if (_348)\n    {\n        _356 = _345 >= _343.z;\n    }\n    else\n    {\n        _356 = _348;\n    }\n    int _357;\n    if (_356)\n    {\n        _357 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _372;\n        if (_347 >= _343.z)\n        {\n            _372 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _372 = (d.z > 0.0) ? 4 : 5;\n        }\n        _357 = _372;\n    }\n    return _357;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cube_face_basis(thread const int& f, thread float3& fwd, thread float3& up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0, 0.0, 0.0);\n        up = float3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0, 0.0, 0.0);\n            up = float3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0, 1.0, 0.0);\n                up = float3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0, -1.0, 0.0);\n                    up = float3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0, 0.0, 1.0);\n                        up = float3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0, 0.0, -1.0);\n                        up = float3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_ies_sample(thread const float2& tile_origin, thread const float3& d, thread const float3& axis, thread const float3& right, thread const float3& up, texture2d<float> fa_light_atlas, sampler fa_env_smp)\n{\n    float _493 = dot(d, right);\n    float _497 = dot(d, up);\n    float _508;\n    if (((_493 * _493) + (_497 * _497)) > 1.0000000133514319600180897396058e-10)\n    {\n        _508 = precise::atan2(_497, _493) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _508 = 0.0;\n    }\n    float2 param = tile_origin + float2(1.0 + ((_508 - floor(_508)) * 64.0), 1.0 + (acos(fast::clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param, fa_light_atlas, fa_env_smp).x;\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample_n(thread const int& li, thread const float3& world_pos, thread const float3& n, constant fa_mesh_fs_params& _395, texture2d<float> fa_light_tex, sampler fa_shadow_smp, texture2d<float> fa_light_atlas, sampler fa_env_smp, thread float3& fa_light_tint, thread bool& fa_light_is_area)\n{\n    int param = li;\n    int _739 = fa_light_base(param, _395);\n    bool _743 = _395.fa_ambient.w > 4.5;\n    int param_1 = _739;\n    float4 _747 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    int param_2 = _739 + 1;\n    float4 _752 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float _755 = _752.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = float3(1.0);\n    bool _767 = _743 && (_755 > 2.5);\n    fa_light_is_area = _767;\n    bool _769 = _755 < 0.5;\n    float3 l;\n    if (_769)\n    {\n        l = fast::normalize(_747.xyz);\n        if (_743)\n        {\n            int param_3 = _739 + 6;\n            float4 _783 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            if (_783.z > 0.5)\n            {\n                int param_4 = _739 + 4;\n                float4 _793 = fa_light_texel(param_4, fa_light_tex, fa_shadow_smp);\n                int param_5 = _739 + 5;\n                float4 _798 = fa_light_texel(param_5, fa_light_tex, fa_shadow_smp);\n                float2 param_6 = _783.xy;\n                float2 param_7 = fract(float2(dot(world_pos, _793.xyz) * _793.w, (-dot(world_pos, _798.xyz)) * _798.w) + float2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7, fa_light_atlas, fa_env_smp);\n            }\n        }\n    }\n    else\n    {\n        float3 _828 = _747.xyz;\n        float3 _830 = _828 - world_pos;\n        float3 to_light = _830;\n        float _833 = length(_830);\n        float reach = _833;\n        bool front = true;\n        if (_767)\n        {\n            int param_8 = _739 + 7;\n            reach = fast::max(_833 - fa_light_texel(param_8, fa_light_tex, fa_shadow_smp).w, 0.0);\n            int param_9 = _739 + 4;\n            float4 _857 = fa_light_texel(param_9, fa_light_tex, fa_shadow_smp);\n            int param_10 = _739 + 5;\n            float4 _862 = fa_light_texel(param_10, fa_light_tex, fa_shadow_smp);\n            int param_11 = _739 + 6;\n            float4 _867 = fa_light_texel(param_11, fa_light_tex, fa_shadow_smp);\n            float _868 = _867.w;\n            int param_12 = _739 + 2;\n            float3 _875 = fast::normalize(fa_light_texel(param_12, fa_light_tex, fa_shadow_smp).xyz);\n            bool _877 = _868 > 1.5;\n            bool _885;\n            if (!_877)\n            {\n                _885 = dot(_875, to_light) < 0.0;\n            }\n            else\n            {\n                _885 = _877;\n            }\n            front = _885;\n            float3 r = float3(0.0);\n            float3 _894 = _395.fa_camera_pos.xyz - world_pos;\n            bool _898 = dot(n, n) > 0.5;\n            bool _906;\n            if (_898)\n            {\n                _906 = dot(_894, _894) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _906 = _898;\n            }\n            if (_906)\n            {\n                r = reflect(-fast::normalize(_894), fast::normalize(n));\n            }\n            float3 param_13 = _828;\n            float3 param_14 = _875;\n            float3 param_15 = _857.xyz;\n            float3 param_16 = _862.xyz;\n            float param_17 = _857.w;\n            float param_18 = _862.w;\n            float param_19 = _868;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _942 = length(to_light);\n        dist = _942;\n        l = to_light / float3(fast::max(_942, 9.9999997473787516355514526367188e-05));\n        float _956 = reach / fast::max(_747.w, 0.001000000047497451305389404296875);\n        float _962 = fast::clamp(1.0 - (_956 * _956), 0.0, 1.0);\n        float _964;\n        if (front)\n        {\n            _964 = _962 * _962;\n        }\n        else\n        {\n            _964 = 0.0;\n        }\n        atten = _964;\n        bool _975 = _755 < 2.5;\n        if ((_755 > 1.5) && _975)\n        {\n            int param_22 = _739 + 2;\n            float4 _983 = fa_light_texel(param_22, fa_light_tex, fa_shadow_smp);\n            float _993 = _983.w;\n            int param_23 = _739 + 3;\n            float4 _998 = fa_light_texel(param_23, fa_light_tex, fa_shadow_smp);\n            float _999 = _998.x;\n            float cos_inner = _999;\n            if (_999 > 1.5)\n            {\n                cos_inner = mix(_993, 1.0, 0.25);\n            }\n            atten *= smoothstep(_993, cos_inner, dot(-l, fast::normalize(_983.xyz)));\n        }\n        if (_743 && (_755 < 1.5))\n        {\n            int param_24 = _739 + 6;\n            float4 _1023 = fa_light_texel(param_24, fa_light_tex, fa_shadow_smp);\n            if (_1023.z > 0.5)\n            {\n                float3 _1031 = -to_light;\n                int param_25 = _739 + 4;\n                int param_26 = _739 + 5;\n                float3 _1045 = fa_light_texel(param_25, fa_light_tex, fa_shadow_smp).xyz;\n                float3 _1049 = fa_light_texel(param_26, fa_light_tex, fa_shadow_smp).xyz;\n                float3 _1058 = float3(dot(_1031, _1045), dot(_1031, _1049), dot(_1031, cross(_1045, _1049)));\n                float3 param_27 = _1058;\n                int _1062 = fa_cube_face(param_27);\n                int param_28 = _1062;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1089 = float2(dot(_1058, cross(param_29, param_30)), dot(_1058, param_30)) / float2(fast::max(dot(_1058, param_29), 9.9999997473787516355514526367188e-05));\n                int _1093 = _1062 / 3;\n                float2 param_31 = _1023.xy + (float2(float(_1062 - (_1093 * 3)), float(_1093)) * 256.0);\n                float2 param_32 = float2(0.5 + (0.5 * _1089.x), 0.5 - (0.5 * _1089.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32, fa_light_atlas, fa_env_smp);\n            }\n            int param_33 = _739 + 7;\n            float4 _1123 = fa_light_texel(param_33, fa_light_tex, fa_shadow_smp);\n            if (_1123.z > 0.5)\n            {\n                int param_34 = _739 + 2;\n                int param_35 = _739 + 4;\n                int param_36 = _739 + 5;\n                float2 param_37 = _1123.xy;\n                float3 param_38 = -l;\n                float3 param_39 = fast::normalize(fa_light_texel(param_34, fa_light_tex, fa_shadow_smp).xyz);\n                float3 param_40 = fa_light_texel(param_35, fa_light_tex, fa_shadow_smp).xyz;\n                float3 param_41 = fa_light_texel(param_36, fa_light_tex, fa_shadow_smp).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41, fa_light_atlas, fa_env_smp);\n            }\n        }\n        else\n        {\n            if (_743 && _975)\n            {\n                int param_42 = _739 + 6;\n                float4 _1170 = fa_light_texel(param_42, fa_light_tex, fa_shadow_smp);\n                int param_43 = _739 + 7;\n                float4 _1175 = fa_light_texel(param_43, fa_light_tex, fa_shadow_smp);\n                bool _1178 = _1170.z > 0.5;\n                bool _1185;\n                if (!_1178)\n                {\n                    _1185 = _1175.z > 0.5;\n                }\n                else\n                {\n                    _1185 = _1178;\n                }\n                if (_1185)\n                {\n                    int param_44 = _739 + 2;\n                    float4 _1192 = fa_light_texel(param_44, fa_light_tex, fa_shadow_smp);\n                    float3 _1196 = fast::normalize(_1192.xyz);\n                    int param_45 = _739 + 4;\n                    float4 _1201 = fa_light_texel(param_45, fa_light_tex, fa_shadow_smp);\n                    int param_46 = _739 + 5;\n                    float4 _1206 = fa_light_texel(param_46, fa_light_tex, fa_shadow_smp);\n                    if (_1178)\n                    {\n                        float3 _1214 = -to_light;\n                        float _1221 = _1192.w;\n                        float _1237 = 0.5 / fast::max(dot(_1214, _1196) * (sqrt(fast::max(1.0 - (_1221 * _1221), 0.0)) / fast::max(_1221, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        float2 param_47 = _1170.xy;\n                        float2 param_48 = float2(0.5 + (dot(_1214, _1201.xyz) * _1237), 0.5 - (dot(_1214, _1206.xyz) * _1237));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48, fa_light_atlas, fa_env_smp);\n                    }\n                    if (_1175.z > 0.5)\n                    {\n                        float2 param_49 = _1175.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1196;\n                        float3 param_52 = _1201.xyz;\n                        float3 param_53 = _1206.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53, fa_light_atlas, fa_env_smp);\n                    }\n                }\n            }\n        }\n    }\n    float3 _4766 = _752.xyz * atten;\n    if (_743)\n    {\n        _4766 *= fa_light_tint;\n    }\n    int _1305;\n    if (_769)\n    {\n        _1305 = 0;\n    }\n    else\n    {\n        _1305 = ((_755 > 1.5) && (_755 < 2.5)) ? 2 : 1;\n    }\n    return LightSample{ l, _4766, atten, 1.0, dist, _1305 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _2052)\n{\n    float _2042;\n    if (i == 0)\n    {\n        _2042 = _2052.fa_shadow_split.x;\n    }\n    else\n    {\n        float _2058;\n        if (i == 1)\n        {\n            _2058 = _2052.fa_shadow_split.y;\n        }\n        else\n        {\n            float _2066;\n            if (i == 2)\n            {\n                _2066 = _2052.fa_shadow_split.z;\n            }\n            else\n            {\n                _2066 = _2052.fa_shadow_split.w;\n            }\n            _2058 = _2066;\n        }\n        _2042 = _2058;\n    }\n    return _2042;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_fetch(thread const float2& uv, thread const float4& rect, thread const float3& conv, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2099 = fa_shadow_depth(param, param_1, fa_shadow_smp, fa_shadow_tex);\n    float _2103;\n    if (conv.x < 0.5)\n    {\n        _2103 = _2099;\n    }\n    else\n    {\n        _2103 = (conv.y * conv.z) / (conv.z - (_2099 * (conv.z - conv.y)));\n    }\n    return _2103;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _2030 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_2030), sin(_2030)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_filter(thread const float2& uv, thread const float4& rect, thread const float& zr, thread const float& texel_m, thread const float& unit, thread const float& reach, thread const float& plane, thread const float3& conv, thread const int& mode, thread const float& k, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2052, texture2d<float> fa_shadow_tex)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2, fa_shadow_smp, fa_shadow_tex));\n    }\n    float _2149 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2158;\n        if (k < 0.0)\n        {\n            _2158 = (-k) / fast::max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2158 = k;\n        }\n        float _2178 = fast::clamp((_2158 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2149;\n            float2 _2197 = fa_shadow_vogel(param_3, param_4, param_5) * _2178;\n            float2 param_6 = uv + (_2197 * _2052.fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _2209 = fa_shadow_fetch(param_6, param_7, param_8, fa_shadow_smp, fa_shadow_tex);\n            if (_2209 < (zr - (length(_2197) * plane)))\n            {\n                sum += _2209;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2235 = sum / cnt;\n        float _2245;\n        if (k < 0.0)\n        {\n            _2245 = (-k) / fast::max(_2235, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2245 = k;\n        }\n        radius = fast::clamp(((fast::max(zr - _2235, 0.0) * unit) * _2245) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _2267 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2267; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2267;\n        float param_11 = _2149;\n        float2 _2286 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_2286 * _2052.fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_2286) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14, fa_shadow_smp, fa_shadow_tex));\n    }\n    return lit / float(_2267);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2052, texture2d<float> fa_shadow_tex)\n{\n    float _2328 = fast::max(_2052.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _2333 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _2339 = sqrt(1.0 - (_2333 * _2333));\n    float _2346 = fast::min(_2339 / fast::max(_2333, 0.20000000298023223876953125), 4.0);\n    float _2351;\n    if (_2052.fa_shadow_bias.y > 0.0)\n    {\n        _2351 = _2052.fa_shadow_bias.y;\n    }\n    else\n    {\n        _2351 = 1.5 * _2052.fa_shadow_info[ci].x;\n    }\n    float4 _2376 = _2052.fa_shadow_mat[ci] * float4(world + (n * (_2351 * _2339)), 1.0);\n    float _2383 = _2376.x;\n    bool _2386 = _2383 < _2052.fa_shadow_rect[ci].x;\n    bool _2395;\n    if (!_2386)\n    {\n        _2395 = _2383 > _2052.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2395 = _2386;\n    }\n    bool _2404;\n    if (!_2395)\n    {\n        _2404 = _2376.y < _2052.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2404 = _2395;\n    }\n    bool _2413;\n    if (!_2404)\n    {\n        _2413 = _2376.y > _2052.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2413 = _2404;\n    }\n    bool _2420;\n    if (!_2413)\n    {\n        _2420 = _2376.z > 1.0;\n    }\n    else\n    {\n        _2420 = _2413;\n    }\n    if (_2420)\n    {\n        return -1.0;\n    }\n    float _2428;\n    if (_2052.fa_shadow_bias.x > 0.0)\n    {\n        _2428 = _2052.fa_shadow_bias.x;\n    }\n    else\n    {\n        _2428 = 1.5 * _2052.fa_shadow_info[ci].x;\n    }\n    float2 param = _2376.xy;\n    float4 param_1 = _2052.fa_shadow_rect[ci];\n    float param_2 = _2376.z - ((_2428 * (1.0 + (0.5 * _2346))) / _2328);\n    float param_3 = _2052.fa_shadow_info[ci].x;\n    float param_4 = _2328;\n    float param_5 = _2328 * 0.25;\n    float param_6 = ((_2052.fa_shadow_info[ci].x * fast::min(_2346, 3.0)) * 0.5) / _2328;\n    float3 param_7 = float3(0.0);\n    int param_8 = int(_2052.fa_shadow_cfg.z + 0.5);\n    float param_9 = _2052.fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9, fa_shadow_smp, gl_FragCoord, _2052, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _395, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2052, texture2d<float> fa_shadow_tex)\n{\n    if (_395.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2806 = int(_2052.fa_shadow_cfg.x + 0.5);\n    if (_2806 < 1)\n    {\n        return 1.0;\n    }\n    float _2821 = dot(world - _2052.fa_shadow_eye.xyz, _2052.fa_shadow_fwd.xyz);\n    int param = _2806 - 1;\n    if (_2821 > fa_shadow_split_at(param, _2052))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2833 = _2806 > 1;\n    bool _2840;\n    if (_2833)\n    {\n        _2840 = _2821 > _2052.fa_shadow_split.x;\n    }\n    else\n    {\n        _2840 = _2833;\n    }\n    if (_2840)\n    {\n        ci = 1;\n    }\n    bool _2844 = _2806 > 2;\n    bool _2851;\n    if (_2844)\n    {\n        _2851 = _2821 > _2052.fa_shadow_split.y;\n    }\n    else\n    {\n        _2851 = _2844;\n    }\n    if (_2851)\n    {\n        ci = 2;\n    }\n    bool _2855 = _2806 > 3;\n    bool _2862;\n    if (_2855)\n    {\n        _2862 = _2821 > _2052.fa_shadow_split.z;\n    }\n    else\n    {\n        _2862 = _2855;\n    }\n    if (_2862)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2806)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2888 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_shadow_smp, gl_FragCoord, _2052, fa_shadow_tex);\n        s = _2888;\n        if (_2888 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_2052.fa_shadow_cfg.y > 0.0)\n    {\n        float _2913;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2913 = fa_shadow_split_at(param_5, _2052);\n        }\n        else\n        {\n            _2913 = _2052.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _2932 = _2052.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _2052) - _2913, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2943 = fast::clamp((_2821 - (fa_shadow_split_at(param_7, _2052) - _2932)) / _2932, 0.0, 1.0);\n        if (_2943 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2806)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _2964 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_shadow_smp, gl_FragCoord, _2052, fa_shadow_tex);\n                s2 = _2964;\n                if (_2964 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2943);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _395, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2052, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, _395, fa_shadow_smp, gl_FragCoord, _2052, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_local(thread const int& li, thread const float3& lpos, thread const float3& world, thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _395, texture2d<float> fa_light_tex, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2052, texture2d<float> fa_shadow_tex)\n{\n    bool _2486 = _395.fa_pbr.z < 0.5;\n    bool _2493;\n    if (!_2486)\n    {\n        _2493 = _2052.fa_shadow_lcfg.x < 0.5;\n    }\n    else\n    {\n        _2493 = _2486;\n    }\n    if (_2493)\n    {\n        return 1.0;\n    }\n    int param = (int(_2052.fa_shadow_lcfg.x + 0.5) - 1) + li;\n    float4 _2506 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    float _2507 = _2506.x;\n    if (_2507 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2516 = int(_2507 + 0.5);\n    int param_1 = _2516;\n    float4 _2520 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    int param_2 = _2516 + 1;\n    float4 _2525 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float fade = 1.0;\n    float _2528 = _2520.y;\n    if (_2528 > 0.0)\n    {\n        float _2545 = 1.0 - smoothstep(0.75 * _2528, _2528, length(world - _2052.fa_shadow_eye.xyz));\n        fade = _2545;\n        if (_2545 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2520.x > 1.5)\n    {\n        float3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2569 = (_2516 + 2) + (face * 6);\n    int param_4 = _2569;\n    int param_5 = _2569 + 1;\n    int param_6 = _2569 + 3;\n    float4 _2583 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n    int param_7 = _2569 + 4;\n    float4 _2588 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n    int param_8 = _2569 + 5;\n    float4 _2593 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n    float _2605 = _2593.x * fast::max(dot(_2583, float4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2610 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _2633 = fast::clamp(dot(n, _2583.xyz), -1.0, 1.0);\n    float _2652 = fast::min(sqrt(1.0 - (_2633 * _2633)) / fast::max(abs(dot(n, world - lpos)) / fast::max(dot(_2583, float4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2655 = _2525.y;\n    float _2657;\n    if (_2655 > 0.0)\n    {\n        _2657 = _2655;\n    }\n    else\n    {\n        _2657 = 1.5 * _2605;\n    }\n    float4 _2677 = float4(world + (n * (_2657 * sqrt(1.0 - (_2610 * _2610)))), 1.0);\n    float _2681 = dot(_2583, _2677);\n    float _2684 = _2593.y;\n    if (_2681 < _2684)\n    {\n        return 1.0;\n    }\n    float2 _2699 = float2(dot(fa_light_texel(param_4, fa_light_tex, fa_shadow_smp), _2677), dot(fa_light_texel(param_5, fa_light_tex, fa_shadow_smp), _2677)) / float2(_2681);\n    float _2701 = _2699.x;\n    bool _2704 = _2701 < _2588.x;\n    bool _2713;\n    if (!_2704)\n    {\n        _2713 = _2701 > _2588.z;\n    }\n    else\n    {\n        _2713 = _2704;\n    }\n    bool _2722;\n    if (!_2713)\n    {\n        _2722 = _2699.y < _2588.y;\n    }\n    else\n    {\n        _2722 = _2713;\n    }\n    bool _2731;\n    if (!_2722)\n    {\n        _2731 = _2699.y > _2588.w;\n    }\n    else\n    {\n        _2731 = _2722;\n    }\n    if (_2731)\n    {\n        return 1.0;\n    }\n    float _2737 = _2525.x;\n    float _2739;\n    if (_2737 > 0.0)\n    {\n        _2739 = _2737;\n    }\n    else\n    {\n        _2739 = 1.5 * _2605;\n    }\n    float2 param_9 = _2699;\n    float4 param_10 = _2588;\n    float param_11 = _2681 - (_2739 * (1.0 + (0.5 * _2652)));\n    float param_12 = _2605;\n    float param_13 = 1.0;\n    float param_14 = _2593.z * 0.25;\n    float param_15 = (_2605 * fast::min(_2652, 3.0)) * 0.5;\n    float3 param_16 = float3(1.0, _2684, _2593.z);\n    int param_17 = int(_2520.z + 0.5);\n    float param_18 = _2520.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, fa_shadow_smp, gl_FragCoord, _2052, fa_shadow_tex), fade);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_contact_shadow(thread const int& li, thread const float3& world, thread const float3& gn, thread const float3& l, thread const float& dist, constant fa_mesh_fs_params& _395, texture2d<float> fa_light_tex, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2052, texture2d<float> fa_screen_tex)\n{\n    bool _3362 = _395.fa_ct_a.x < 0.5;\n    bool _3369;\n    if (!_3362)\n    {\n        _3369 = _2052.fa_shadow_lcfg.x < 0.5;\n    }\n    else\n    {\n        _3369 = _3362;\n    }\n    if (_3369)\n    {\n        return 1.0;\n    }\n    int param = (int(_2052.fa_shadow_lcfg.x + 0.5) - 1) + li;\n    float4 _3382 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    float _3383 = _3382.y;\n    float len = _3383;\n    if (_3383 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3395 = length(world - _395.fa_camera_pos.xyz);\n    float _3405 = 1.0 - smoothstep(0.5 * _395.fa_ct_b.x, _395.fa_ct_b.x, _3395);\n    if (_3405 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3411 = len;\n    float _3414 = fast::min(_3411, 0.89999997615814208984375 * dist);\n    len = _3414;\n    float _3420 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _3395);\n    float _3425 = _3420 + (0.5 * _3414);\n    float3 _3431 = world + (gn * _3420);\n    float _3433 = fa_shadow_noise(gl_FragCoord);\n    float occ = 0.0;\n    float _3498;\n    for (int k = 0; k < 12; k++)\n    {\n        float _3449 = (float(k) + _3433) * 0.083333335816860198974609375;\n        float3 _3457 = _3431 + (l * (_3449 * len));\n        float4 _3463 = float4(_3457, 1.0);\n        float _3469 = dot(_395.fa_ct_vpw, _3463);\n        if (_3469 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        float2 _3489 = float2(dot(_395.fa_ct_vpx, _3463), dot(_395.fa_ct_vpy, _3463)) / float2(_3469);\n        float _3493 = _3489.x * 0.5;\n        float _3494 = _3493 + 0.5;\n        if (_395.fa_ct_a.y > 0.5)\n        {\n            _3498 = (_3489.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _3498 = 0.5 - (_3489.y * 0.5);\n        }\n        bool _3514 = _3494 < 0.0;\n        bool _3521;\n        if (!_3514)\n        {\n            _3521 = _3494 >= 1.0;\n        }\n        else\n        {\n            _3521 = _3514;\n        }\n        bool _3528;\n        if (!_3521)\n        {\n            _3528 = _3498 < 0.0;\n        }\n        else\n        {\n            _3528 = _3521;\n        }\n        bool _3535;\n        if (!_3528)\n        {\n            _3535 = _3498 >= 1.0;\n        }\n        else\n        {\n            _3535 = _3528;\n        }\n        if (_3535)\n        {\n            break;\n        }\n        float4 _3554 = fa_screen_tex.read(uint2(int2(float2(_3494, _3498) * _395.fa_ct_a.zw)), 0);\n        if (_3554.w < 0.5)\n        {\n            continue;\n        }\n        float _3573 = (dot(_395.fa_ct_fwd.xyz, _3457) + _395.fa_ct_fwd.w) - _3554.x;\n        if ((_3573 > _3420) && (_3573 < _3425))\n        {\n            occ = fast::max(occ, (1.0 - (_3449 * _3449)) * smoothstep(0.0, 0.0500000007450580596923828125, fast::min(fast::min(_3494, 0.5 - _3493), fast::min(_3498, 1.0 - _3498))));\n        }\n    }\n    return 1.0 - (occ * _3405);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, constant fa_mesh_fs_params& _395, texture2d<float> fa_light_tex, sampler fa_shadow_smp, texture2d<float> fa_light_atlas, sampler fa_env_smp, thread float3& fa_light_tint, thread bool& fa_light_is_area, thread float4& gl_FragCoord, constant fa_shadows& _2052, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos, texture2d<float> fa_screen_tex, thread float3& fa_lm)\n{\n    int param = li;\n    float _3676 = fa_baked_keep(param, _395, fa_light_tex, fa_shadow_smp, fa_lm);\n    if (_3676 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample{ float3(0.0, 1.0, 0.0), float3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1, _395, fa_light_tex, fa_shadow_smp) + 0.5) };\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _3702 = fa_light_sample_n(param_2, param_3, param_4, _395, fa_light_tex, fa_shadow_smp, fa_light_atlas, fa_env_smp, fa_light_tint, fa_light_is_area);\n    float3 _4792 = _3702.color;\n    float _4793 = _3702.attenuation;\n    float _4794 = _3702.shadow;\n    bool _3705 = _3702.type == 0;\n    if (_3705 && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _3702.direction;\n        float _3716 = fa_shadow_factor(param_5, param_6, _395, fa_shadow_smp, gl_FragCoord, _2052, fa_shadow_tex, fa_world_pos);\n        _4794 = _3716;\n        _4792 *= _3716;\n    }\n    else\n    {\n        bool _3727 = _3702.type != 0;\n        bool _3733;\n        if (_3727)\n        {\n            _3733 = _4793 > 0.0;\n        }\n        else\n        {\n            _3733 = _3727;\n        }\n        if (_3733)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7, _395);\n            int param_9 = li;\n            float3 param_10 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp).xyz;\n            float3 param_11 = world_pos;\n            float3 param_12 = gn;\n            float3 param_13 = _3702.direction;\n            float _3752 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13, _395, fa_light_tex, fa_shadow_smp, gl_FragCoord, _2052, fa_shadow_tex);\n            _4794 = _3752;\n            _4792 *= _3752;\n        }\n    }\n    bool _3762 = _395.fa_ct_a.x > 0.5;\n    bool _3768;\n    if (_3762)\n    {\n        _3768 = _4793 > 0.0;\n    }\n    else\n    {\n        _3768 = _3762;\n    }\n    if (_3768)\n    {\n        float _3775;\n        if (_3705)\n        {\n            _3775 = 1000000000.0;\n        }\n        else\n        {\n            _3775 = _3702._distance;\n        }\n        int param_14 = li;\n        float3 param_15 = world_pos;\n        float3 param_16 = gn;\n        float3 param_17 = _3702.direction;\n        float param_18 = _3775;\n        float _3793 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18, _395, fa_light_tex, fa_shadow_smp, gl_FragCoord, _2052, fa_screen_tex);\n        _4794 *= _3793;\n        _4792 *= _3793;\n    }\n    float _3806 = _4793;\n    float _3807 = _3806 * _3676;\n    _4793 = _3807;\n    float3 _3811 = _4792;\n    float3 _3812 = _3811 * _3676;\n    _4792 = _3812;\n    return LightSample{ _3702.direction, _3812, _3807, _4794, _3702._distance, _3702.type };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 light(thread const SurfaceInput& i, thread const Surface& s, thread const LightSample& l)\n{\n    return float3(0.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _2052)\n{\n    if (_2052.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _2988 = int(_2052.fa_shadow_cfg.x + 0.5);\n    float _2998 = dot(world - _2052.fa_shadow_eye.xyz, _2052.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _3003 = _2988 > 0;\n    bool _3012;\n    if (_3003)\n    {\n        int param = _2988 - 1;\n        _3012 = _2998 <= fa_shadow_split_at(param, _2052);\n    }\n    else\n    {\n        _3012 = _3003;\n    }\n    if (_3012)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3018 = _2988 > 1;\n        bool _3025;\n        if (_3018)\n        {\n            _3025 = _2998 > _2052.fa_shadow_split.x;\n        }\n        else\n        {\n            _3025 = _3018;\n        }\n        if (_3025)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3031 = _2988 > 2;\n        bool _3038;\n        if (_3031)\n        {\n            _3038 = _2998 > _2052.fa_shadow_split.y;\n        }\n        else\n        {\n            _3038 = _3031;\n        }\n        if (_3038)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3044 = _2988 > 3;\n        bool _3051;\n        if (_3044)\n        {\n            _3051 = _2998 > _2052.fa_shadow_split.z;\n        }\n        else\n        {\n            _3051 = _3044;\n        }\n        if (_3051)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _395 [[buffer(1)]], constant fa_shadows& _2052 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texture2d<float> fa_probe_atlas [[texture(6)]], texture2d<float> fa_light_tex [[texture(7)]], texture2d<float> fa_light_atlas [[texture(8)]], texture2d<float> fa_lightmap [[texture(9)]], texture2d<float> fa_decal_tex [[texture(10)]], texture2d<float> fa_screen_tex [[texture(11)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _4633 = fast::normalize(in.fa_world_normal);\n    float3 fa_light_tint;\n    bool fa_light_is_area;\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _4633 = -_4633;\n    }\n    float3 _4224 = fast::normalize(_395.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, _395, fa_light_tex, fa_shadow_smp, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _4633, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _4224, short(gl_FrontFacing) };\n    Surface _4232 = fa_standard_surface(param_1, _395, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _4664 = _4232.albedo;\n    float _4665 = _4232.alpha;\n    float3 _4666 = _4232.normal;\n    float _4667 = _4232.metallic;\n    float _4668 = _4232.roughness;\n    float _4669 = _4232.occlusion;\n    float3 _4670 = _4232.emission;\n    float _4671 = _4232.clearcoat;\n    float _4672 = _4232.clearcoat_roughness;\n    float3 _4673 = _4232.sheen_color;\n    float _4674 = _4232.sheen_roughness;\n    float _4675 = _4232.anisotropy;\n    float _4676 = _4232.anisotropy_rotation;\n    float _4677 = _4232.specular;\n    float _4678 = _4232.ior;\n    float3 _4679 = _4232.specular_color;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _4633, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _4224, short(gl_FrontFacing) };\n    Surface param_3 = _4232;\n    surface(param_2, param_3);\n    _4664 = param_3.albedo;\n    _4665 = param_3.alpha;\n    _4666 = param_3.normal;\n    _4667 = param_3.metallic;\n    _4668 = param_3.roughness;\n    _4669 = param_3.occlusion;\n    _4670 = param_3.emission;\n    _4671 = param_3.clearcoat;\n    _4672 = param_3.clearcoat_roughness;\n    _4673 = param_3.sheen_color;\n    _4674 = param_3.sheen_roughness;\n    _4675 = param_3.anisotropy;\n    _4676 = param_3.anisotropy_rotation;\n    _4677 = param_3.specular;\n    _4678 = param_3.ior;\n    _4679 = param_3.specular_color;\n    float3 param_4 = in.fa_world_pos;\n    float3 param_5 = _4633;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7, _395, fa_light_tex, fa_shadow_smp, fa_env_smp, fa_decal_tex);\n    _4664 = param_6;\n    _4666 = param_7;\n    float3 result;\n    if (_395.fa_emissive.w > 0.5)\n    {\n        result = _4664;\n    }\n    else\n    {\n        float3 _4270 = _4666;\n        float3 _4271 = fast::normalize(_4270);\n        _4666 = _4271;\n        float3 param_8 = _4271;\n        float3 lit = (fa_indirect_diffuse(param_8, _395, fa_env_smp, fa_probe_atlas, in.fa_lm, fa_lightmap) * _4664) * _4669;\n        int _4290 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _4290; ln++)\n        {\n            int param_9 = ln;\n            int _4303 = fa_cl_light(param_9, _395, fa_light_tex, fa_shadow_smp, fa_cl_ndir, fa_cl_slot);\n            int param_10 = _4303;\n            if (fa_baked_keep(param_10, _395, fa_light_tex, fa_shadow_smp, in.fa_lm) <= 0.0)\n            {\n                continue;\n            }\n            int param_11 = _4303;\n            float3 param_12 = in.fa_world_pos;\n            float3 param_13 = _4633;\n            LightSample _4319 = fa_light_shadowed(param_11, param_12, param_13, _395, fa_light_tex, fa_shadow_smp, fa_light_atlas, fa_env_smp, fa_light_tint, fa_light_is_area, gl_FragCoord, _2052, fa_shadow_tex, in.fa_world_pos, fa_screen_tex, in.fa_lm);\n            SurfaceInput param_14 = SurfaceInput{ in.fa_world_pos, _4633, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _4224, short(gl_FrontFacing) };\n            Surface param_15 = Surface{ _4664, _4665, _4666, _4667, _4668, _4669, _4670, _4671, _4672, _4673, _4674, _4675, _4676, _4677, _4678, _4679 };\n            LightSample param_16 = _4319;\n            lit += light(param_14, param_15, param_16);\n        }\n        result = lit;\n    }\n    float3 _4334 = result;\n    float3 _4335 = _4334 + _4670;\n    result = _4335;\n    float3 param_17 = _4335;\n    float3 param_18 = in.fa_world_pos;\n    result = fa_shadow_debug(param_17, param_18, _2052);\n    bool _4344 = _395.fa_fog.w > 0.0;\n    bool _4351;\n    if (!_4344)\n    {\n        _4351 = _395.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _4351 = _4344;\n    }\n    if (_4351)\n    {\n        float3 _4360 = in.fa_world_pos - _395.fa_camera_pos.xyz;\n        float _4366 = dot(_4360, _395.fa_fog_c.xyz);\n        bool _4370 = _395.fa_fog_c.w > 0.5;\n        float _4371;\n        if (_4370)\n        {\n            _4371 = _4366;\n        }\n        else\n        {\n            _4371 = length(_4360);\n        }\n        float _4383 = _4371 - _395.fa_fog_b.x;\n        if (_4383 > 0.0)\n        {\n            float _4392 = _395.fa_fog.w * _4383;\n            float tau = _4392 * _4392;\n            if (_395.fa_fog_b.y > 0.0)\n            {\n                float _4408;\n                if (_4370)\n                {\n                    _4408 = in.fa_world_pos.y - (_395.fa_fog_c.y * _4366);\n                }\n                else\n                {\n                    _4408 = _395.fa_camera_pos.y;\n                }\n                float _4429 = mix(_4408, in.fa_world_pos.y, fast::clamp(_395.fa_fog_b.x / _4371, 0.0, 1.0));\n                float _4433 = in.fa_world_pos.y - _4429;\n                float _4438 = _4429 - _395.fa_fog_b.z;\n                float _4443 = in.fa_world_pos.y - _395.fa_fog_b.z;\n                bool _4446 = _4438 <= 0.0;\n                bool _4447 = !_4446;\n                bool _4453;\n                if (_4447)\n                {\n                    _4453 = _395.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4453 = _4446;\n                }\n                float _4454;\n                if (_4453)\n                {\n                    _4454 = _395.fa_fog_b.y;\n                }\n                else\n                {\n                    _4454 = _395.fa_fog_b.y * exp(-fast::min(_395.fa_fog_b.w * _4438, 80.0));\n                }\n                bool _4481;\n                if (_4447)\n                {\n                    _4481 = _395.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4481 = _4446;\n                }\n                float _4482;\n                if (_4481)\n                {\n                    _4482 = _395.fa_fog_b.y * _4438;\n                }\n                else\n                {\n                    _4482 = (_395.fa_fog_b.y * (1.0 - exp(-fast::min(_395.fa_fog_b.w * _4438, 80.0)))) / _395.fa_fog_b.w;\n                }\n                bool _4507 = _4443 <= 0.0;\n                bool _4514;\n                if (!_4507)\n                {\n                    _4514 = _395.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4514 = _4507;\n                }\n                float _4515;\n                if (_4514)\n                {\n                    _4515 = _395.fa_fog_b.y * _4443;\n                }\n                else\n                {\n                    _4515 = (_395.fa_fog_b.y * (1.0 - exp(-fast::min(_395.fa_fog_b.w * _4443, 80.0)))) / _395.fa_fog_b.w;\n                }\n                float _4542;\n                if (abs(_4433) < 0.001000000047497451305389404296875)\n                {\n                    _4542 = _4454;\n                }\n                else\n                {\n                    _4542 = (_4515 - _4482) / _4433;\n                }\n                tau += (_4383 * fast::max(_4542, 0.0));\n            }\n            result = mix(result, _395.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _4665);\n    return out;\n}\n\n",
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
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_131",
            "msl_buffer_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 800,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_395",
            "msl_buffer_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2052",
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
              "name": "fa_probe_atlas",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 6
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
              "msl_texture_n": 7
            }
          },
          {
            "texture": {
              "slot": 25,
              "stage": "fragment",
              "name": "fa_light_atlas",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 8
            }
          },
          {
            "texture": {
              "slot": 26,
              "stage": "fragment",
              "name": "fa_lightmap",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 9
            }
          },
          {
            "texture": {
              "slot": 27,
              "stage": "fragment",
              "name": "fa_decal_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 10
            }
          },
          {
            "texture": {
              "slot": 28,
              "stage": "fragment",
              "name": "fa_screen_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float",
              "msl_texture_n": 11
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
            "name": "fa_decal_tex_fa_env_smp",
            "view_name": "fa_decal_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 27,
            "sampler_slot": 10
          },
          {
            "slot": 7,
            "stage": "fragment",
            "name": "fa_lightmap_fa_env_smp",
            "view_name": "fa_lightmap",
            "sampler_name": "fa_env_smp",
            "view_slot": 26,
            "sampler_slot": 10
          },
          {
            "slot": 8,
            "stage": "fragment",
            "name": "fa_probe_atlas_fa_env_smp",
            "view_name": "fa_probe_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10
          },
          {
            "slot": 9,
            "stage": "fragment",
            "name": "fa_light_atlas_fa_env_smp",
            "view_name": "fa_light_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 25,
            "sampler_slot": 10
          },
          {
            "slot": 10,
            "stage": "fragment",
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1
          },
          {
            "slot": 11,
            "stage": "fragment",
            "name": "fa_screen_tex_fa_shadow_smp",
            "view_name": "fa_screen_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 28,
            "sampler_slot": 1
          }
        ]
      }
    },
    "mesh_skin": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float3 fa_lm [[user(locn5)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n    float4 fa_joints [[attribute(9)]];\n    float4 fa_weights [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _183)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_183.fa_joint_rows[_174] * weights[i]);\n        r1 += (_183.fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183.fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _136);\n    float3 _388 = _273.world_pos;\n    fa_world_pos = _388;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = _136.fa_view_proj * float4(_388, 1.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _136 [[buffer(0)]], constant fa_skin& _183 [[buffer(3)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float4x4 param_2 = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _183);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7, _136, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.gl_Position);\n    out.fa_lm = float3(0.0);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n#pragma clang diagnostic ignored \"-Wmissing-braces\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\ntemplate<typename T, size_t Num>\nstruct spvUnsafeArray\n{\n    T elements[Num ? Num : 1];\n    \n    thread T& operator [] (size_t pos) thread\n    {\n        return elements[pos];\n    }\n    constexpr const thread T& operator [] (size_t pos) const thread\n    {\n        return elements[pos];\n    }\n    \n    device T& operator [] (size_t pos) device\n    {\n        return elements[pos];\n    }\n    constexpr const device T& operator [] (size_t pos) const device\n    {\n        return elements[pos];\n    }\n    \n    constexpr const constant T& operator [] (size_t pos) const constant\n    {\n        return elements[pos];\n    }\n    \n    threadgroup T& operator [] (size_t pos) threadgroup\n    {\n        return elements[pos];\n    }\n    constexpr const threadgroup T& operator [] (size_t pos) const threadgroup\n    {\n        return elements[pos];\n    }\n};\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n    float4 fa_ct_a;\n    float4 fa_ct_b;\n    float4 fa_ct_vpx;\n    float4 fa_ct_vpy;\n    float4 fa_ct_vpw;\n    float4 fa_ct_fwd;\n    float4 fa_probe_sh[9];\n    float4 fa_atlas;\n    float4 fa_rpa_tile;\n    float4 fa_rpa_pos;\n    float4 fa_rpa_bx;\n    float4 fa_rpa_by;\n    float4 fa_rpa_bz;\n    float4 fa_rpb_tile;\n    float4 fa_rpb_pos;\n    float4 fa_rpb_bx;\n    float4 fa_rpb_by;\n    float4 fa_rpb_bz;\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n    float4 fa_shadow_lcfg;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float3 fa_lm [[user(locn5)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_cluster_texel(thread const float3& world_pos, constant fa_mesh_fs_params& _395, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    bool _1323 = _395.fa_cl_info.x < 0.0;\n    bool _1330;\n    if (!_1323)\n    {\n        _1330 = _395.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _1330 = _1323;\n    }\n    bool _1338;\n    if (!_1330)\n    {\n        _1338 = _395.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _1338 = _1330;\n    }\n    bool _1345;\n    if (!_1338)\n    {\n        _1345 = _395.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _1345 = _1338;\n    }\n    bool _1352;\n    if (!_1345)\n    {\n        _1352 = _395.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _1352 = _1345;\n    }\n    if (_1352)\n    {\n        return float4(0.0);\n    }\n    float4 _1362 = float4(world_pos, 1.0);\n    float _1368 = dot(_395.fa_cl_vpw, _1362);\n    if (!(_1368 > 9.9999999747524270787835121154785e-07))\n    {\n        return float4(0.0);\n    }\n    float2 _1390 = float2(dot(_395.fa_cl_vpx, _1362), dot(_395.fa_cl_vpy, _1362)) / float2(_1368);\n    int _1394 = int(_395.fa_cl_grid.x);\n    int _1398 = int(_395.fa_cl_grid.y);\n    int param = (int(_395.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_395.fa_cl_fwd.xyz, world_pos) + _395.fa_cl_fwd.w, _395.fa_cl_grid.w) / _395.fa_cl_grid.w) * _395.fa_cl_grid.z)), 0, int(_395.fa_cl_info.y) - 1) * _1398) + clamp(int(floor(((_1390.y * 0.5) + 0.5) * _395.fa_cl_grid.y)), 0, _1398 - 1)) * _1394)) + clamp(int(floor(((_1390.x * 0.5) + 0.5) * _395.fa_cl_grid.x)), 0, _1394 - 1);\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, constant fa_mesh_fs_params& _395, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    float3 param = world_pos;\n    float4 _1474 = fa_cluster_texel(param, _395, fa_light_tex, fa_shadow_smp);\n    return int2(int(_1474.x), int(_1474.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, constant fa_mesh_fs_params& _395, texture2d<float> fa_light_tex, sampler fa_shadow_smp, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_395.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _3650 = fa_cluster_lookup(param, _395, fa_light_tex, fa_shadow_smp);\n    fa_cl_slot = _3650.x;\n    fa_cl_local = _3650.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _3855 = fa_linear_to_srgb(param);\n        c = _3855;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _3863 = fa_srgb_to_linear(param_1);\n            c = _3863;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _277;\n    if (bool(i.front_facing))\n    {\n        _277 = i.world_normal;\n    }\n    else\n    {\n        _277 = -i.world_normal;\n    }\n    float3 _301 = fast::normalize(i.world_tangent.xyz - (_277 * dot(_277, i.world_tangent.xyz)));\n    float3 _328 = fast::normalize(((_301 * m.x) + ((cross(_277, _301) * i.world_tangent.w) * m.y)) + (_277 * m.z));\n    float3 _331;\n    if (bool(i.front_facing))\n    {\n        _331 = _328;\n    }\n    else\n    {\n        _331 = -_328;\n    }\n    return _331;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _395, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _395.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _3894 = fa_tex_fix(param_2, param_3);\n    float4 _4960 = base_t;\n    _4960.x = _3894.x;\n    _4960.y = _3894.y;\n    _4960.z = _3894.z;\n    base_t = _4960;\n    float4 _3908 = (_4960 * _395.fa_base_color) * i.vertex_color;\n    float3 _4812 = i.world_normal;\n    if (_395.fa_maps.z > 0.5)\n    {\n        float param_4 = _395.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _3940 = fa_tex_fix(param_6, param_7);\n        float3 _3943 = (_3940 * 2.0) - float3(1.0);\n        float2 _3948 = _3943.xy * _395.fa_maps.x;\n        float3 _4968 = _3943;\n        _4968.x = _3948.x;\n        _4968.y = _3948.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _4968;\n        _4812 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _395.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _3976 = fa_tex_fix(param_12, param_13);\n    float4 _4971 = mrt;\n    _4971.x = _3976.x;\n    _4971.y = _3976.y;\n    _4971.z = _3976.z;\n    mrt = _4971;\n    float4 _4004 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _395.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _4004.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _4015 = fa_tex_fix(param_16, param_17);\n    float param_18 = _395.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _4045 = fa_tex_fix(param_20, param_21);\n    float _4817 = _395.fa_layers_a.x;\n    float _4818 = _395.fa_layers_a.y;\n    float _4821 = _395.fa_layers_a.z;\n    float _4820 = _395.fa_layers_b.w;\n    float _4823 = _395.fa_layers_c.x;\n    if (_395.fa_layers_c.z > 0.5)\n    {\n        if (mod(_395.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _4817 *= _4015.y;\n            _4818 *= _4015.z;\n            _4820 *= _4004.w;\n        }\n        if (_395.fa_layers_c.z > 1.5)\n        {\n            _4821 *= mrt.x;\n            _4823 *= mrt.w;\n        }\n    }\n    return Surface{ _3908.xyz, _3908.w, _4812, fast::clamp(_395.fa_pbr.x * _3976.z, 0.0, 1.0), fast::clamp(_395.fa_pbr.y * _3976.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_395.fa_maps.y * (_4015.x - 1.0)), _395.fa_emissive.xyz + (_395.fa_model_emissive.xyz * _4045), _4817, _4818, _395.fa_layers_b.xyz, _4820, _4821, _395.fa_layers_a.w, _4823, _395.fa_layers_c.y, _395.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_decal_tile(thread const float4& rect, thread const float2& uv, thread const float2& atlas, thread const float2& ddx, thread const float2& ddy, sampler fa_env_smp, texture2d<float> fa_decal_tex)\n{\n    float2 _1554 = rect.zw - rect.xy;\n    float2 _1558 = _1554 * atlas;\n    float2 _1562 = ddx * _1558;\n    float2 _1566 = ddy * _1558;\n    return fa_decal_tex.sample(fa_env_smp, (rect.xy + (fast::clamp(uv, float2(0.0), float2(1.0)) * _1554)), level(fast::clamp(0.5 * log2(fast::max(fast::max(dot(_1562, _1562), dot(_1566, _1566)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_apply_decals(thread const float3& world_pos, thread const float3& geo_normal, thread float3& albedo, thread float3& normal, constant fa_mesh_fs_params& _395, texture2d<float> fa_light_tex, sampler fa_shadow_smp, sampler fa_env_smp, texture2d<float> fa_decal_tex)\n{\n    bool _1599 = _395.fa_counts.y < 0.5;\n    bool _1606;\n    if (!_1599)\n    {\n        _1606 = _395.fa_counts.w < 0.5;\n    }\n    else\n    {\n        _1606 = _1599;\n    }\n    if (_1606)\n    {\n        return;\n    }\n    float3 _1612 = dfdx(world_pos);\n    float3 _1615 = dfdy(world_pos);\n    float3 param = world_pos;\n    float4 _1619 = fa_cluster_texel(param, _395, fa_light_tex, fa_shadow_smp);\n    int _1623 = int(_1619.w);\n    if (_1623 < 1)\n    {\n        return;\n    }\n    int _1633 = int(_395.fa_counts.y + 0.5);\n    int param_1 = _1633;\n    float4 _1637 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float2 _1640 = _1637.yz;\n    int _1644 = int(_1637.w);\n    int param_2 = _1633 + 1;\n    float4 _1649 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float _1650 = _1649.x;\n    int _1656 = int(_395.fa_counts.w + 0.5) - 1;\n    int _1660 = int(_1619.z);\n    float3 _1925;\n    for (int k = 0; k < _1623; k++)\n    {\n        int _1673 = _1660 + k;\n        int param_3 = _1644 + (_1673 >> 2);\n        int _1690 = (_1633 + 2) + (int(fa_light_texel(param_3, fa_light_tex, fa_shadow_smp)[_1673 & 3]) * 7);\n        int param_4 = _1690 + 6;\n        float4 _1695 = fa_light_texel(param_4, fa_light_tex, fa_shadow_smp);\n        if (((int(_1695.w + 0.5) >> _1656) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1690;\n        float4 _1710 = fa_light_texel(param_5, fa_light_tex, fa_shadow_smp);\n        int param_6 = _1690 + 1;\n        float4 _1715 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n        int param_7 = _1690 + 2;\n        float4 _1720 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n        float3 _1723 = _1710.xyz;\n        float _1728 = dot(_1723, world_pos) + _1710.w;\n        float3 _1730 = _1715.xyz;\n        float _1735 = dot(_1730, world_pos) + _1715.w;\n        float3 _1737 = _1720.xyz;\n        float _1742 = dot(_1737, world_pos) + _1720.w;\n        bool _1747 = abs(_1728) > 0.5;\n        bool _1755;\n        if (!_1747)\n        {\n            _1755 = abs(_1735) > 0.5;\n        }\n        else\n        {\n            _1755 = _1747;\n        }\n        bool _1763;\n        if (!_1755)\n        {\n            _1763 = abs(_1742) > 0.5;\n        }\n        else\n        {\n            _1763 = _1755;\n        }\n        if (_1763)\n        {\n            continue;\n        }\n        float _1778 = fast::clamp(dot(geo_normal, fast::normalize(_1737)) * _1695.z, 0.0, 1.0);\n        if (_1778 <= 0.0)\n        {\n            continue;\n        }\n        float _1798 = (fast::clamp((0.5 - abs(_1742)) * 10.0, 0.0, 1.0) * _1778) * _1695.x;\n        float2 _1806 = float2(_1728 + 0.5, 0.5 - _1735);\n        float2 _1816 = float2(dot(_1723, _1612), dot(_1730, _1612));\n        float2 _1826 = float2(dot(_1723, _1615), dot(_1730, _1615));\n        int param_8 = _1690 + 5;\n        float4 _1831 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n        int param_9 = _1690 + 3;\n        float4 _1836 = fa_light_texel(param_9, fa_light_tex, fa_shadow_smp);\n        int param_10 = _1690 + 4;\n        float4 _1841 = fa_light_texel(param_10, fa_light_tex, fa_shadow_smp);\n        float tex_a = 1.0;\n        float3 col = _1831.xyz;\n        bool _1851 = _1836.z > _1836.x;\n        if (_1851)\n        {\n            float4 param_11 = _1836;\n            float2 param_12 = _1806;\n            float2 param_13 = _1640;\n            float2 param_14 = _1816;\n            float2 param_15 = _1826;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15, fa_env_smp, fa_decal_tex);\n            if ((_1650 > 0.5) && (_1650 < 1.5))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1877 = fa_dc_to_linear(param_16);\n                float4 _4892 = tx;\n                _4892.x = _1877.x;\n                _4892.y = _1877.y;\n                _4892.z = _1877.z;\n                tx = _4892;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, float3(fast::clamp((_1798 * tex_a) * _1831.w, 0.0, 1.0)));\n        if (_1841.z > _1841.x)\n        {\n            float4 param_17 = _1841;\n            float2 param_18 = _1806;\n            float2 param_19 = _1640;\n            float2 param_20 = _1816;\n            float2 param_21 = _1826;\n            float4 _1921 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21, fa_env_smp, fa_decal_tex);\n            if (_1650 > 1.5)\n            {\n                float3 param_22 = _1921.xyz;\n                float3 _1931 = fa_dc_to_srgb(param_22);\n                _1925 = _1931;\n            }\n            else\n            {\n                _1925 = _1921.xyz;\n            }\n            float3 _1940 = (_1925 * 2.0) - float3(1.0);\n            float2 _1945 = _1940.xy * _1695.y;\n            float3 _1967 = (fast::normalize(_1723) * _1945.x) + (fast::normalize(_1730) * _1945.y);\n            float3 _1970 = fast::normalize(normal);\n            normal = fast::normalize(mix(_1970, fast::normalize((_1970 * fast::max(_1940.z, 0.0500000007450580596923828125)) + (_1967 - (_1970 * dot(_1970, _1967)))), float3(fast::clamp(_1798 * (_1851 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_atlas_size(sampler fa_env_smp, texture2d<float> fa_probe_atlas)\n{\n    return float2(int2(fa_probe_atlas.get_width(), fa_probe_atlas.get_height()));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_probe_sh_coef(thread const float2& origin, thread const float& res, thread const int& k, constant fa_mesh_fs_params& _395, sampler fa_env_smp, texture2d<float> fa_probe_atlas)\n{\n    float3 v = fa_probe_atlas.sample(fa_env_smp, ((origin + float2(float(k) + 0.5, res + 2.5)) / fa_atlas_size(fa_env_smp, fa_probe_atlas)), level(0.0)).xyz;\n    if (_395.fa_atlas.y > 0.5)\n    {\n        v = (v - float3(0.5)) * 8.0;\n    }\n    return v;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sh_eval(thread const spvUnsafeArray<float3, 9>& c, thread const float3& n)\n{\n    float3 _3165 = fast::max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), float3(0.0));\n    return _3165;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _395, sampler fa_env_smp, texture2d<float> fa_probe_atlas)\n{\n    float _3221 = (1.0 - _395.fa_rpa_tile.w) - _395.fa_rpb_tile.w;\n    float3 amb = float3(0.0);\n    bool _3227 = _395.fa_env_sky.w > 0.5;\n    spvUnsafeArray<float3, 9> c;\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = float3(0.0);\n    }\n    if (_3221 > 0.0005000000237487256526947021484375)\n    {\n        if (_3227)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                float2 param = _395.fa_atlas.zw;\n                float param_1 = 128.0;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2, _395, fa_env_smp, fa_probe_atlas) * _3221;\n            }\n        }\n        else\n        {\n            amb = _395.fa_ambient.xyz * _3221;\n        }\n    }\n    bool _3280 = _395.fa_rpa_tile.w > 0.0;\n    if (_3280)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            float2 param_3 = _395.fa_rpa_tile.xy;\n            float param_4 = _395.fa_rpa_tile.z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5, _395, fa_env_smp, fa_probe_atlas) * _395.fa_rpa_tile.w);\n        }\n    }\n    bool _3311 = _395.fa_rpb_tile.w > 0.0;\n    if (_3311)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            float2 param_6 = _395.fa_rpb_tile.xy;\n            float param_7 = _395.fa_rpb_tile.z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8, _395, fa_env_smp, fa_probe_atlas) * _395.fa_rpb_tile.w);\n        }\n    }\n    if ((_3227 || _3280) || _3311)\n    {\n        spvUnsafeArray<float3, 9> param_9 = c;\n        float3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_indirect_diffuse(thread const float3& n, constant fa_mesh_fs_params& _395, sampler fa_env_smp, texture2d<float> fa_probe_atlas, thread float3& fa_lm, texture2d<float> fa_lightmap)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return fa_lightmap.sample(fa_env_smp, fa_lm.xy, level(0.0)).xyz;\n    }\n    if (_395.fa_probe_sh[0].w > 0.0)\n    {\n        spvUnsafeArray<float3, 9> c;\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = _395.fa_probe_sh[k].xyz;\n        }\n        float3 param = n;\n        spvUnsafeArray<float3, 9> param_1 = c;\n        float3 param_2 = n;\n        return mix(fa_ambient_light(param, _395, fa_env_smp, fa_probe_atlas), fa_sh_eval(param_1, param_2), float3(fast::clamp(_395.fa_probe_sh[0].w, 0.0, 1.0)));\n    }\n    float3 param_3 = n;\n    return fa_ambient_light(param_3, _395, fa_env_smp, fa_probe_atlas);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, constant fa_mesh_fs_params& _395, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (int(_395.fa_cl_info.x) + int(_395.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, constant fa_mesh_fs_params& _395, texture2d<float> fa_light_tex, sampler fa_shadow_smp, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, _395, fa_light_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_light_base(thread const int& li, constant fa_mesh_fs_params& _395)\n{\n    return li * ((_395.fa_ambient.w > 4.5) ? 8 : 4);\n}\n\nstatic inline __attribute__((always_inline))\nbool fa_light_baked(thread const int& li, constant fa_mesh_fs_params& _395, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li;\n    int param_1 = fa_light_base(param, _395) + 3;\n    return fa_light_texel(param_1, fa_light_tex, fa_shadow_smp).w > 0.5;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_baked_keep(thread const int& li, constant fa_mesh_fs_params& _395, texture2d<float> fa_light_tex, sampler fa_shadow_smp, thread float3& fa_lm)\n{\n    float _3620;\n    if (fa_lm.z > 0.5)\n    {\n        _3620 = 0.0;\n    }\n    else\n    {\n        _3620 = 1.0 - fast::clamp(_395.fa_probe_sh[0].w, 0.0, 1.0);\n    }\n    bool _3631 = _3620 < 1.0;\n    bool _3637;\n    if (_3631)\n    {\n        int param = li;\n        _3637 = fa_light_baked(param, _395, fa_light_tex, fa_shadow_smp);\n    }\n    else\n    {\n        _3637 = _3631;\n    }\n    return _3637 ? _3620 : 1.0;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_light_type(thread const int& li, constant fa_mesh_fs_params& _395, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li;\n    int param_1 = fa_light_base(param, _395) + 1;\n    return fa_light_texel(param_1, fa_light_tex, fa_shadow_smp).w;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_atlas_fetch(thread const float2& texel, texture2d<float> fa_light_atlas, sampler fa_env_smp)\n{\n    return fa_light_atlas.sample(fa_env_smp, (texel / float2(int2(fa_light_atlas.get_width(), fa_light_atlas.get_height()))), level(0.0));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_cookie_sample(thread const float2& tile_origin, thread const float2& uv, texture2d<float> fa_light_atlas, sampler fa_env_smp)\n{\n    float2 param = (tile_origin + float2(1.0)) + (fast::clamp(uv, float2(0.0), float2(1.0)) * 254.0);\n    return fa_atlas_fetch(param, fa_light_atlas, fa_env_smp).xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_area_point(thread const float3& c, thread const float3& axis, thread const float3& ru, thread const float3& uu, thread const float& hx, thread const float& hy, thread const float& shape, thread const float3& p, thread const float3& r)\n{\n    bool _573 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        float3 _586 = (c - (ru * hx)) - p;\n        float3 _592 = ru * (2.0 * hx);\n        float _598 = fast::max(dot(_592, _592), 9.9999999392252902907785028219223e-09);\n        float _602 = dot(_586, _592);\n        float t = fast::clamp((-_602) / _598, 0.0, 1.0);\n        if (_573)\n        {\n            float _617 = dot(r, _592);\n            float _623 = _598 - (_617 * _617);\n            if (abs(_623) > (9.9999997473787516355514526367188e-06 * _598))\n            {\n                t = fast::clamp(((dot(r, _586) * _617) - _602) / _623, 0.0, 1.0);\n            }\n        }\n        return (p + _586) + (_592 * t);\n    }\n    float3 q = p;\n    float _655 = dot(r, axis);\n    bool _663;\n    if (_573)\n    {\n        _663 = abs(_655) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _663 = _573;\n    }\n    if (_663)\n    {\n        float _673 = dot(c - p, axis) / _655;\n        if (_673 > 0.0)\n        {\n            q = p + (r * _673);\n        }\n    }\n    float3 _686 = q - c;\n    float2 xy = float2(dot(_686, ru), dot(_686, uu));\n    if (shape > 0.5)\n    {\n        float _701 = length(xy);\n        if (_701 > hx)\n        {\n            xy *= (hx / _701);\n        }\n    }\n    else\n    {\n        xy = fast::clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cube_face(thread const float3& d)\n{\n    float3 _343 = abs(d);\n    float _345 = _343.x;\n    float _347 = _343.y;\n    bool _348 = _345 >= _347;\n    bool _356;\n    if (_348)\n    {\n        _356 = _345 >= _343.z;\n    }\n    else\n    {\n        _356 = _348;\n    }\n    int _357;\n    if (_356)\n    {\n        _357 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _372;\n        if (_347 >= _343.z)\n        {\n            _372 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _372 = (d.z > 0.0) ? 4 : 5;\n        }\n        _357 = _372;\n    }\n    return _357;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cube_face_basis(thread const int& f, thread float3& fwd, thread float3& up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0, 0.0, 0.0);\n        up = float3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0, 0.0, 0.0);\n            up = float3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0, 1.0, 0.0);\n                up = float3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0, -1.0, 0.0);\n                    up = float3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0, 0.0, 1.0);\n                        up = float3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0, 0.0, -1.0);\n                        up = float3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_ies_sample(thread const float2& tile_origin, thread const float3& d, thread const float3& axis, thread const float3& right, thread const float3& up, texture2d<float> fa_light_atlas, sampler fa_env_smp)\n{\n    float _493 = dot(d, right);\n    float _497 = dot(d, up);\n    float _508;\n    if (((_493 * _493) + (_497 * _497)) > 1.0000000133514319600180897396058e-10)\n    {\n        _508 = precise::atan2(_497, _493) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _508 = 0.0;\n    }\n    float2 param = tile_origin + float2(1.0 + ((_508 - floor(_508)) * 64.0), 1.0 + (acos(fast::clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param, fa_light_atlas, fa_env_smp).x;\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample_n(thread const int& li, thread const float3& world_pos, thread const float3& n, constant fa_mesh_fs_params& _395, texture2d<float> fa_light_tex, sampler fa_shadow_smp, texture2d<float> fa_light_atlas, sampler fa_env_smp, thread float3& fa_light_tint, thread bool& fa_light_is_area)\n{\n    int param = li;\n    int _739 = fa_light_base(param, _395);\n    bool _743 = _395.fa_ambient.w > 4.5;\n    int param_1 = _739;\n    float4 _747 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    int param_2 = _739 + 1;\n    float4 _752 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float _755 = _752.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = float3(1.0);\n    bool _767 = _743 && (_755 > 2.5);\n    fa_light_is_area = _767;\n    bool _769 = _755 < 0.5;\n    float3 l;\n    if (_769)\n    {\n        l = fast::normalize(_747.xyz);\n        if (_743)\n        {\n            int param_3 = _739 + 6;\n            float4 _783 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            if (_783.z > 0.5)\n            {\n                int param_4 = _739 + 4;\n                float4 _793 = fa_light_texel(param_4, fa_light_tex, fa_shadow_smp);\n                int param_5 = _739 + 5;\n                float4 _798 = fa_light_texel(param_5, fa_light_tex, fa_shadow_smp);\n                float2 param_6 = _783.xy;\n                float2 param_7 = fract(float2(dot(world_pos, _793.xyz) * _793.w, (-dot(world_pos, _798.xyz)) * _798.w) + float2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7, fa_light_atlas, fa_env_smp);\n            }\n        }\n    }\n    else\n    {\n        float3 _828 = _747.xyz;\n        float3 _830 = _828 - world_pos;\n        float3 to_light = _830;\n        float _833 = length(_830);\n        float reach = _833;\n        bool front = true;\n        if (_767)\n        {\n            int param_8 = _739 + 7;\n            reach = fast::max(_833 - fa_light_texel(param_8, fa_light_tex, fa_shadow_smp).w, 0.0);\n            int param_9 = _739 + 4;\n            float4 _857 = fa_light_texel(param_9, fa_light_tex, fa_shadow_smp);\n            int param_10 = _739 + 5;\n            float4 _862 = fa_light_texel(param_10, fa_light_tex, fa_shadow_smp);\n            int param_11 = _739 + 6;\n            float4 _867 = fa_light_texel(param_11, fa_light_tex, fa_shadow_smp);\n            float _868 = _867.w;\n            int param_12 = _739 + 2;\n            float3 _875 = fast::normalize(fa_light_texel(param_12, fa_light_tex, fa_shadow_smp).xyz);\n            bool _877 = _868 > 1.5;\n            bool _885;\n            if (!_877)\n            {\n                _885 = dot(_875, to_light) < 0.0;\n            }\n            else\n            {\n                _885 = _877;\n            }\n            front = _885;\n            float3 r = float3(0.0);\n            float3 _894 = _395.fa_camera_pos.xyz - world_pos;\n            bool _898 = dot(n, n) > 0.5;\n            bool _906;\n            if (_898)\n            {\n                _906 = dot(_894, _894) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _906 = _898;\n            }\n            if (_906)\n            {\n                r = reflect(-fast::normalize(_894), fast::normalize(n));\n            }\n            float3 param_13 = _828;\n            float3 param_14 = _875;\n            float3 param_15 = _857.xyz;\n            float3 param_16 = _862.xyz;\n            float param_17 = _857.w;\n            float param_18 = _862.w;\n            float param_19 = _868;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _942 = length(to_light);\n        dist = _942;\n        l = to_light / float3(fast::max(_942, 9.9999997473787516355514526367188e-05));\n        float _956 = reach / fast::max(_747.w, 0.001000000047497451305389404296875);\n        float _962 = fast::clamp(1.0 - (_956 * _956), 0.0, 1.0);\n        float _964;\n        if (front)\n        {\n            _964 = _962 * _962;\n        }\n        else\n        {\n            _964 = 0.0;\n        }\n        atten = _964;\n        bool _975 = _755 < 2.5;\n        if ((_755 > 1.5) && _975)\n        {\n            int param_22 = _739 + 2;\n            float4 _983 = fa_light_texel(param_22, fa_light_tex, fa_shadow_smp);\n            float _993 = _983.w;\n            int param_23 = _739 + 3;\n            float4 _998 = fa_light_texel(param_23, fa_light_tex, fa_shadow_smp);\n            float _999 = _998.x;\n            float cos_inner = _999;\n            if (_999 > 1.5)\n            {\n                cos_inner = mix(_993, 1.0, 0.25);\n            }\n            atten *= smoothstep(_993, cos_inner, dot(-l, fast::normalize(_983.xyz)));\n        }\n        if (_743 && (_755 < 1.5))\n        {\n            int param_24 = _739 + 6;\n            float4 _1023 = fa_light_texel(param_24, fa_light_tex, fa_shadow_smp);\n            if (_1023.z > 0.5)\n            {\n                float3 _1031 = -to_light;\n                int param_25 = _739 + 4;\n                int param_26 = _739 + 5;\n                float3 _1045 = fa_light_texel(param_25, fa_light_tex, fa_shadow_smp).xyz;\n                float3 _1049 = fa_light_texel(param_26, fa_light_tex, fa_shadow_smp).xyz;\n                float3 _1058 = float3(dot(_1031, _1045), dot(_1031, _1049), dot(_1031, cross(_1045, _1049)));\n                float3 param_27 = _1058;\n                int _1062 = fa_cube_face(param_27);\n                int param_28 = _1062;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1089 = float2(dot(_1058, cross(param_29, param_30)), dot(_1058, param_30)) / float2(fast::max(dot(_1058, param_29), 9.9999997473787516355514526367188e-05));\n                int _1093 = _1062 / 3;\n                float2 param_31 = _1023.xy + (float2(float(_1062 - (_1093 * 3)), float(_1093)) * 256.0);\n                float2 param_32 = float2(0.5 + (0.5 * _1089.x), 0.5 - (0.5 * _1089.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32, fa_light_atlas, fa_env_smp);\n            }\n            int param_33 = _739 + 7;\n            float4 _1123 = fa_light_texel(param_33, fa_light_tex, fa_shadow_smp);\n            if (_1123.z > 0.5)\n            {\n                int param_34 = _739 + 2;\n                int param_35 = _739 + 4;\n                int param_36 = _739 + 5;\n                float2 param_37 = _1123.xy;\n                float3 param_38 = -l;\n                float3 param_39 = fast::normalize(fa_light_texel(param_34, fa_light_tex, fa_shadow_smp).xyz);\n                float3 param_40 = fa_light_texel(param_35, fa_light_tex, fa_shadow_smp).xyz;\n                float3 param_41 = fa_light_texel(param_36, fa_light_tex, fa_shadow_smp).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41, fa_light_atlas, fa_env_smp);\n            }\n        }\n        else\n        {\n            if (_743 && _975)\n            {\n                int param_42 = _739 + 6;\n                float4 _1170 = fa_light_texel(param_42, fa_light_tex, fa_shadow_smp);\n                int param_43 = _739 + 7;\n                float4 _1175 = fa_light_texel(param_43, fa_light_tex, fa_shadow_smp);\n                bool _1178 = _1170.z > 0.5;\n                bool _1185;\n                if (!_1178)\n                {\n                    _1185 = _1175.z > 0.5;\n                }\n                else\n                {\n                    _1185 = _1178;\n                }\n                if (_1185)\n                {\n                    int param_44 = _739 + 2;\n                    float4 _1192 = fa_light_texel(param_44, fa_light_tex, fa_shadow_smp);\n                    float3 _1196 = fast::normalize(_1192.xyz);\n                    int param_45 = _739 + 4;\n                    float4 _1201 = fa_light_texel(param_45, fa_light_tex, fa_shadow_smp);\n                    int param_46 = _739 + 5;\n                    float4 _1206 = fa_light_texel(param_46, fa_light_tex, fa_shadow_smp);\n                    if (_1178)\n                    {\n                        float3 _1214 = -to_light;\n                        float _1221 = _1192.w;\n                        float _1237 = 0.5 / fast::max(dot(_1214, _1196) * (sqrt(fast::max(1.0 - (_1221 * _1221), 0.0)) / fast::max(_1221, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        float2 param_47 = _1170.xy;\n                        float2 param_48 = float2(0.5 + (dot(_1214, _1201.xyz) * _1237), 0.5 - (dot(_1214, _1206.xyz) * _1237));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48, fa_light_atlas, fa_env_smp);\n                    }\n                    if (_1175.z > 0.5)\n                    {\n                        float2 param_49 = _1175.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1196;\n                        float3 param_52 = _1201.xyz;\n                        float3 param_53 = _1206.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53, fa_light_atlas, fa_env_smp);\n                    }\n                }\n            }\n        }\n    }\n    float3 _4766 = _752.xyz * atten;\n    if (_743)\n    {\n        _4766 *= fa_light_tint;\n    }\n    int _1305;\n    if (_769)\n    {\n        _1305 = 0;\n    }\n    else\n    {\n        _1305 = ((_755 > 1.5) && (_755 < 2.5)) ? 2 : 1;\n    }\n    return LightSample{ l, _4766, atten, 1.0, dist, _1305 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _2052)\n{\n    float _2042;\n    if (i == 0)\n    {\n        _2042 = _2052.fa_shadow_split.x;\n    }\n    else\n    {\n        float _2058;\n        if (i == 1)\n        {\n            _2058 = _2052.fa_shadow_split.y;\n        }\n        else\n        {\n            float _2066;\n            if (i == 2)\n            {\n                _2066 = _2052.fa_shadow_split.z;\n            }\n            else\n            {\n                _2066 = _2052.fa_shadow_split.w;\n            }\n            _2058 = _2066;\n        }\n        _2042 = _2058;\n    }\n    return _2042;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_fetch(thread const float2& uv, thread const float4& rect, thread const float3& conv, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2099 = fa_shadow_depth(param, param_1, fa_shadow_smp, fa_shadow_tex);\n    float _2103;\n    if (conv.x < 0.5)\n    {\n        _2103 = _2099;\n    }\n    else\n    {\n        _2103 = (conv.y * conv.z) / (conv.z - (_2099 * (conv.z - conv.y)));\n    }\n    return _2103;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _2030 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_2030), sin(_2030)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_filter(thread const float2& uv, thread const float4& rect, thread const float& zr, thread const float& texel_m, thread const float& unit, thread const float& reach, thread const float& plane, thread const float3& conv, thread const int& mode, thread const float& k, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2052, texture2d<float> fa_shadow_tex)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2, fa_shadow_smp, fa_shadow_tex));\n    }\n    float _2149 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2158;\n        if (k < 0.0)\n        {\n            _2158 = (-k) / fast::max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2158 = k;\n        }\n        float _2178 = fast::clamp((_2158 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2149;\n            float2 _2197 = fa_shadow_vogel(param_3, param_4, param_5) * _2178;\n            float2 param_6 = uv + (_2197 * _2052.fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _2209 = fa_shadow_fetch(param_6, param_7, param_8, fa_shadow_smp, fa_shadow_tex);\n            if (_2209 < (zr - (length(_2197) * plane)))\n            {\n                sum += _2209;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2235 = sum / cnt;\n        float _2245;\n        if (k < 0.0)\n        {\n            _2245 = (-k) / fast::max(_2235, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2245 = k;\n        }\n        radius = fast::clamp(((fast::max(zr - _2235, 0.0) * unit) * _2245) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _2267 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2267; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2267;\n        float param_11 = _2149;\n        float2 _2286 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_2286 * _2052.fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_2286) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14, fa_shadow_smp, fa_shadow_tex));\n    }\n    return lit / float(_2267);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2052, texture2d<float> fa_shadow_tex)\n{\n    float _2328 = fast::max(_2052.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _2333 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _2339 = sqrt(1.0 - (_2333 * _2333));\n    float _2346 = fast::min(_2339 / fast::max(_2333, 0.20000000298023223876953125), 4.0);\n    float _2351;\n    if (_2052.fa_shadow_bias.y > 0.0)\n    {\n        _2351 = _2052.fa_shadow_bias.y;\n    }\n    else\n    {\n        _2351 = 1.5 * _2052.fa_shadow_info[ci].x;\n    }\n    float4 _2376 = _2052.fa_shadow_mat[ci] * float4(world + (n * (_2351 * _2339)), 1.0);\n    float _2383 = _2376.x;\n    bool _2386 = _2383 < _2052.fa_shadow_rect[ci].x;\n    bool _2395;\n    if (!_2386)\n    {\n        _2395 = _2383 > _2052.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2395 = _2386;\n    }\n    bool _2404;\n    if (!_2395)\n    {\n        _2404 = _2376.y < _2052.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2404 = _2395;\n    }\n    bool _2413;\n    if (!_2404)\n    {\n        _2413 = _2376.y > _2052.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2413 = _2404;\n    }\n    bool _2420;\n    if (!_2413)\n    {\n        _2420 = _2376.z > 1.0;\n    }\n    else\n    {\n        _2420 = _2413;\n    }\n    if (_2420)\n    {\n        return -1.0;\n    }\n    float _2428;\n    if (_2052.fa_shadow_bias.x > 0.0)\n    {\n        _2428 = _2052.fa_shadow_bias.x;\n    }\n    else\n    {\n        _2428 = 1.5 * _2052.fa_shadow_info[ci].x;\n    }\n    float2 param = _2376.xy;\n    float4 param_1 = _2052.fa_shadow_rect[ci];\n    float param_2 = _2376.z - ((_2428 * (1.0 + (0.5 * _2346))) / _2328);\n    float param_3 = _2052.fa_shadow_info[ci].x;\n    float param_4 = _2328;\n    float param_5 = _2328 * 0.25;\n    float param_6 = ((_2052.fa_shadow_info[ci].x * fast::min(_2346, 3.0)) * 0.5) / _2328;\n    float3 param_7 = float3(0.0);\n    int param_8 = int(_2052.fa_shadow_cfg.z + 0.5);\n    float param_9 = _2052.fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9, fa_shadow_smp, gl_FragCoord, _2052, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _395, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2052, texture2d<float> fa_shadow_tex)\n{\n    if (_395.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2806 = int(_2052.fa_shadow_cfg.x + 0.5);\n    if (_2806 < 1)\n    {\n        return 1.0;\n    }\n    float _2821 = dot(world - _2052.fa_shadow_eye.xyz, _2052.fa_shadow_fwd.xyz);\n    int param = _2806 - 1;\n    if (_2821 > fa_shadow_split_at(param, _2052))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2833 = _2806 > 1;\n    bool _2840;\n    if (_2833)\n    {\n        _2840 = _2821 > _2052.fa_shadow_split.x;\n    }\n    else\n    {\n        _2840 = _2833;\n    }\n    if (_2840)\n    {\n        ci = 1;\n    }\n    bool _2844 = _2806 > 2;\n    bool _2851;\n    if (_2844)\n    {\n        _2851 = _2821 > _2052.fa_shadow_split.y;\n    }\n    else\n    {\n        _2851 = _2844;\n    }\n    if (_2851)\n    {\n        ci = 2;\n    }\n    bool _2855 = _2806 > 3;\n    bool _2862;\n    if (_2855)\n    {\n        _2862 = _2821 > _2052.fa_shadow_split.z;\n    }\n    else\n    {\n        _2862 = _2855;\n    }\n    if (_2862)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2806)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2888 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_shadow_smp, gl_FragCoord, _2052, fa_shadow_tex);\n        s = _2888;\n        if (_2888 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_2052.fa_shadow_cfg.y > 0.0)\n    {\n        float _2913;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2913 = fa_shadow_split_at(param_5, _2052);\n        }\n        else\n        {\n            _2913 = _2052.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _2932 = _2052.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _2052) - _2913, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2943 = fast::clamp((_2821 - (fa_shadow_split_at(param_7, _2052) - _2932)) / _2932, 0.0, 1.0);\n        if (_2943 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2806)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _2964 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_shadow_smp, gl_FragCoord, _2052, fa_shadow_tex);\n                s2 = _2964;\n                if (_2964 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2943);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _395, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2052, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, _395, fa_shadow_smp, gl_FragCoord, _2052, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_local(thread const int& li, thread const float3& lpos, thread const float3& world, thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _395, texture2d<float> fa_light_tex, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2052, texture2d<float> fa_shadow_tex)\n{\n    bool _2486 = _395.fa_pbr.z < 0.5;\n    bool _2493;\n    if (!_2486)\n    {\n        _2493 = _2052.fa_shadow_lcfg.x < 0.5;\n    }\n    else\n    {\n        _2493 = _2486;\n    }\n    if (_2493)\n    {\n        return 1.0;\n    }\n    int param = (int(_2052.fa_shadow_lcfg.x + 0.5) - 1) + li;\n    float4 _2506 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    float _2507 = _2506.x;\n    if (_2507 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2516 = int(_2507 + 0.5);\n    int param_1 = _2516;\n    float4 _2520 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    int param_2 = _2516 + 1;\n    float4 _2525 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float fade = 1.0;\n    float _2528 = _2520.y;\n    if (_2528 > 0.0)\n    {\n        float _2545 = 1.0 - smoothstep(0.75 * _2528, _2528, length(world - _2052.fa_shadow_eye.xyz));\n        fade = _2545;\n        if (_2545 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2520.x > 1.5)\n    {\n        float3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2569 = (_2516 + 2) + (face * 6);\n    int param_4 = _2569;\n    int param_5 = _2569 + 1;\n    int param_6 = _2569 + 3;\n    float4 _2583 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n    int param_7 = _2569 + 4;\n    float4 _2588 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n    int param_8 = _2569 + 5;\n    float4 _2593 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n    float _2605 = _2593.x * fast::max(dot(_2583, float4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2610 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _2633 = fast::clamp(dot(n, _2583.xyz), -1.0, 1.0);\n    float _2652 = fast::min(sqrt(1.0 - (_2633 * _2633)) / fast::max(abs(dot(n, world - lpos)) / fast::max(dot(_2583, float4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2655 = _2525.y;\n    float _2657;\n    if (_2655 > 0.0)\n    {\n        _2657 = _2655;\n    }\n    else\n    {\n        _2657 = 1.5 * _2605;\n    }\n    float4 _2677 = float4(world + (n * (_2657 * sqrt(1.0 - (_2610 * _2610)))), 1.0);\n    float _2681 = dot(_2583, _2677);\n    float _2684 = _2593.y;\n    if (_2681 < _2684)\n    {\n        return 1.0;\n    }\n    float2 _2699 = float2(dot(fa_light_texel(param_4, fa_light_tex, fa_shadow_smp), _2677), dot(fa_light_texel(param_5, fa_light_tex, fa_shadow_smp), _2677)) / float2(_2681);\n    float _2701 = _2699.x;\n    bool _2704 = _2701 < _2588.x;\n    bool _2713;\n    if (!_2704)\n    {\n        _2713 = _2701 > _2588.z;\n    }\n    else\n    {\n        _2713 = _2704;\n    }\n    bool _2722;\n    if (!_2713)\n    {\n        _2722 = _2699.y < _2588.y;\n    }\n    else\n    {\n        _2722 = _2713;\n    }\n    bool _2731;\n    if (!_2722)\n    {\n        _2731 = _2699.y > _2588.w;\n    }\n    else\n    {\n        _2731 = _2722;\n    }\n    if (_2731)\n    {\n        return 1.0;\n    }\n    float _2737 = _2525.x;\n    float _2739;\n    if (_2737 > 0.0)\n    {\n        _2739 = _2737;\n    }\n    else\n    {\n        _2739 = 1.5 * _2605;\n    }\n    float2 param_9 = _2699;\n    float4 param_10 = _2588;\n    float param_11 = _2681 - (_2739 * (1.0 + (0.5 * _2652)));\n    float param_12 = _2605;\n    float param_13 = 1.0;\n    float param_14 = _2593.z * 0.25;\n    float param_15 = (_2605 * fast::min(_2652, 3.0)) * 0.5;\n    float3 param_16 = float3(1.0, _2684, _2593.z);\n    int param_17 = int(_2520.z + 0.5);\n    float param_18 = _2520.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, fa_shadow_smp, gl_FragCoord, _2052, fa_shadow_tex), fade);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_contact_shadow(thread const int& li, thread const float3& world, thread const float3& gn, thread const float3& l, thread const float& dist, constant fa_mesh_fs_params& _395, texture2d<float> fa_light_tex, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2052, texture2d<float> fa_screen_tex)\n{\n    bool _3362 = _395.fa_ct_a.x < 0.5;\n    bool _3369;\n    if (!_3362)\n    {\n        _3369 = _2052.fa_shadow_lcfg.x < 0.5;\n    }\n    else\n    {\n        _3369 = _3362;\n    }\n    if (_3369)\n    {\n        return 1.0;\n    }\n    int param = (int(_2052.fa_shadow_lcfg.x + 0.5) - 1) + li;\n    float4 _3382 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    float _3383 = _3382.y;\n    float len = _3383;\n    if (_3383 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3395 = length(world - _395.fa_camera_pos.xyz);\n    float _3405 = 1.0 - smoothstep(0.5 * _395.fa_ct_b.x, _395.fa_ct_b.x, _3395);\n    if (_3405 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3411 = len;\n    float _3414 = fast::min(_3411, 0.89999997615814208984375 * dist);\n    len = _3414;\n    float _3420 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _3395);\n    float _3425 = _3420 + (0.5 * _3414);\n    float3 _3431 = world + (gn * _3420);\n    float _3433 = fa_shadow_noise(gl_FragCoord);\n    float occ = 0.0;\n    float _3498;\n    for (int k = 0; k < 12; k++)\n    {\n        float _3449 = (float(k) + _3433) * 0.083333335816860198974609375;\n        float3 _3457 = _3431 + (l * (_3449 * len));\n        float4 _3463 = float4(_3457, 1.0);\n        float _3469 = dot(_395.fa_ct_vpw, _3463);\n        if (_3469 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        float2 _3489 = float2(dot(_395.fa_ct_vpx, _3463), dot(_395.fa_ct_vpy, _3463)) / float2(_3469);\n        float _3493 = _3489.x * 0.5;\n        float _3494 = _3493 + 0.5;\n        if (_395.fa_ct_a.y > 0.5)\n        {\n            _3498 = (_3489.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _3498 = 0.5 - (_3489.y * 0.5);\n        }\n        bool _3514 = _3494 < 0.0;\n        bool _3521;\n        if (!_3514)\n        {\n            _3521 = _3494 >= 1.0;\n        }\n        else\n        {\n            _3521 = _3514;\n        }\n        bool _3528;\n        if (!_3521)\n        {\n            _3528 = _3498 < 0.0;\n        }\n        else\n        {\n            _3528 = _3521;\n        }\n        bool _3535;\n        if (!_3528)\n        {\n            _3535 = _3498 >= 1.0;\n        }\n        else\n        {\n            _3535 = _3528;\n        }\n        if (_3535)\n        {\n            break;\n        }\n        float4 _3554 = fa_screen_tex.read(uint2(int2(float2(_3494, _3498) * _395.fa_ct_a.zw)), 0);\n        if (_3554.w < 0.5)\n        {\n            continue;\n        }\n        float _3573 = (dot(_395.fa_ct_fwd.xyz, _3457) + _395.fa_ct_fwd.w) - _3554.x;\n        if ((_3573 > _3420) && (_3573 < _3425))\n        {\n            occ = fast::max(occ, (1.0 - (_3449 * _3449)) * smoothstep(0.0, 0.0500000007450580596923828125, fast::min(fast::min(_3494, 0.5 - _3493), fast::min(_3498, 1.0 - _3498))));\n        }\n    }\n    return 1.0 - (occ * _3405);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, constant fa_mesh_fs_params& _395, texture2d<float> fa_light_tex, sampler fa_shadow_smp, texture2d<float> fa_light_atlas, sampler fa_env_smp, thread float3& fa_light_tint, thread bool& fa_light_is_area, thread float4& gl_FragCoord, constant fa_shadows& _2052, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos, texture2d<float> fa_screen_tex, thread float3& fa_lm)\n{\n    int param = li;\n    float _3676 = fa_baked_keep(param, _395, fa_light_tex, fa_shadow_smp, fa_lm);\n    if (_3676 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample{ float3(0.0, 1.0, 0.0), float3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1, _395, fa_light_tex, fa_shadow_smp) + 0.5) };\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _3702 = fa_light_sample_n(param_2, param_3, param_4, _395, fa_light_tex, fa_shadow_smp, fa_light_atlas, fa_env_smp, fa_light_tint, fa_light_is_area);\n    float3 _4792 = _3702.color;\n    float _4793 = _3702.attenuation;\n    float _4794 = _3702.shadow;\n    bool _3705 = _3702.type == 0;\n    if (_3705 && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _3702.direction;\n        float _3716 = fa_shadow_factor(param_5, param_6, _395, fa_shadow_smp, gl_FragCoord, _2052, fa_shadow_tex, fa_world_pos);\n        _4794 = _3716;\n        _4792 *= _3716;\n    }\n    else\n    {\n        bool _3727 = _3702.type != 0;\n        bool _3733;\n        if (_3727)\n        {\n            _3733 = _4793 > 0.0;\n        }\n        else\n        {\n            _3733 = _3727;\n        }\n        if (_3733)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7, _395);\n            int param_9 = li;\n            float3 param_10 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp).xyz;\n            float3 param_11 = world_pos;\n            float3 param_12 = gn;\n            float3 param_13 = _3702.direction;\n            float _3752 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13, _395, fa_light_tex, fa_shadow_smp, gl_FragCoord, _2052, fa_shadow_tex);\n            _4794 = _3752;\n            _4792 *= _3752;\n        }\n    }\n    bool _3762 = _395.fa_ct_a.x > 0.5;\n    bool _3768;\n    if (_3762)\n    {\n        _3768 = _4793 > 0.0;\n    }\n    else\n    {\n        _3768 = _3762;\n    }\n    if (_3768)\n    {\n        float _3775;\n        if (_3705)\n        {\n            _3775 = 1000000000.0;\n        }\n        else\n        {\n            _3775 = _3702._distance;\n        }\n        int param_14 = li;\n        float3 param_15 = world_pos;\n        float3 param_16 = gn;\n        float3 param_17 = _3702.direction;\n        float param_18 = _3775;\n        float _3793 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18, _395, fa_light_tex, fa_shadow_smp, gl_FragCoord, _2052, fa_screen_tex);\n        _4794 *= _3793;\n        _4792 *= _3793;\n    }\n    float _3806 = _4793;\n    float _3807 = _3806 * _3676;\n    _4793 = _3807;\n    float3 _3811 = _4792;\n    float3 _3812 = _3811 * _3676;\n    _4792 = _3812;\n    return LightSample{ _3702.direction, _3812, _3807, _4794, _3702._distance, _3702.type };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 light(thread const SurfaceInput& i, thread const Surface& s, thread const LightSample& l)\n{\n    return float3(0.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _2052)\n{\n    if (_2052.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _2988 = int(_2052.fa_shadow_cfg.x + 0.5);\n    float _2998 = dot(world - _2052.fa_shadow_eye.xyz, _2052.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _3003 = _2988 > 0;\n    bool _3012;\n    if (_3003)\n    {\n        int param = _2988 - 1;\n        _3012 = _2998 <= fa_shadow_split_at(param, _2052);\n    }\n    else\n    {\n        _3012 = _3003;\n    }\n    if (_3012)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3018 = _2988 > 1;\n        bool _3025;\n        if (_3018)\n        {\n            _3025 = _2998 > _2052.fa_shadow_split.x;\n        }\n        else\n        {\n            _3025 = _3018;\n        }\n        if (_3025)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3031 = _2988 > 2;\n        bool _3038;\n        if (_3031)\n        {\n            _3038 = _2998 > _2052.fa_shadow_split.y;\n        }\n        else\n        {\n            _3038 = _3031;\n        }\n        if (_3038)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3044 = _2988 > 3;\n        bool _3051;\n        if (_3044)\n        {\n            _3051 = _2998 > _2052.fa_shadow_split.z;\n        }\n        else\n        {\n            _3051 = _3044;\n        }\n        if (_3051)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _395 [[buffer(1)]], constant fa_shadows& _2052 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texture2d<float> fa_probe_atlas [[texture(6)]], texture2d<float> fa_light_tex [[texture(7)]], texture2d<float> fa_light_atlas [[texture(8)]], texture2d<float> fa_lightmap [[texture(9)]], texture2d<float> fa_decal_tex [[texture(10)]], texture2d<float> fa_screen_tex [[texture(11)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _4633 = fast::normalize(in.fa_world_normal);\n    float3 fa_light_tint;\n    bool fa_light_is_area;\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _4633 = -_4633;\n    }\n    float3 _4224 = fast::normalize(_395.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, _395, fa_light_tex, fa_shadow_smp, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _4633, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _4224, short(gl_FrontFacing) };\n    Surface _4232 = fa_standard_surface(param_1, _395, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _4664 = _4232.albedo;\n    float _4665 = _4232.alpha;\n    float3 _4666 = _4232.normal;\n    float _4667 = _4232.metallic;\n    float _4668 = _4232.roughness;\n    float _4669 = _4232.occlusion;\n    float3 _4670 = _4232.emission;\n    float _4671 = _4232.clearcoat;\n    float _4672 = _4232.clearcoat_roughness;\n    float3 _4673 = _4232.sheen_color;\n    float _4674 = _4232.sheen_roughness;\n    float _4675 = _4232.anisotropy;\n    float _4676 = _4232.anisotropy_rotation;\n    float _4677 = _4232.specular;\n    float _4678 = _4232.ior;\n    float3 _4679 = _4232.specular_color;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _4633, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _4224, short(gl_FrontFacing) };\n    Surface param_3 = _4232;\n    surface(param_2, param_3);\n    _4664 = param_3.albedo;\n    _4665 = param_3.alpha;\n    _4666 = param_3.normal;\n    _4667 = param_3.metallic;\n    _4668 = param_3.roughness;\n    _4669 = param_3.occlusion;\n    _4670 = param_3.emission;\n    _4671 = param_3.clearcoat;\n    _4672 = param_3.clearcoat_roughness;\n    _4673 = param_3.sheen_color;\n    _4674 = param_3.sheen_roughness;\n    _4675 = param_3.anisotropy;\n    _4676 = param_3.anisotropy_rotation;\n    _4677 = param_3.specular;\n    _4678 = param_3.ior;\n    _4679 = param_3.specular_color;\n    float3 param_4 = in.fa_world_pos;\n    float3 param_5 = _4633;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7, _395, fa_light_tex, fa_shadow_smp, fa_env_smp, fa_decal_tex);\n    _4664 = param_6;\n    _4666 = param_7;\n    float3 result;\n    if (_395.fa_emissive.w > 0.5)\n    {\n        result = _4664;\n    }\n    else\n    {\n        float3 _4270 = _4666;\n        float3 _4271 = fast::normalize(_4270);\n        _4666 = _4271;\n        float3 param_8 = _4271;\n        float3 lit = (fa_indirect_diffuse(param_8, _395, fa_env_smp, fa_probe_atlas, in.fa_lm, fa_lightmap) * _4664) * _4669;\n        int _4290 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _4290; ln++)\n        {\n            int param_9 = ln;\n            int _4303 = fa_cl_light(param_9, _395, fa_light_tex, fa_shadow_smp, fa_cl_ndir, fa_cl_slot);\n            int param_10 = _4303;\n            if (fa_baked_keep(param_10, _395, fa_light_tex, fa_shadow_smp, in.fa_lm) <= 0.0)\n            {\n                continue;\n            }\n            int param_11 = _4303;\n            float3 param_12 = in.fa_world_pos;\n            float3 param_13 = _4633;\n            LightSample _4319 = fa_light_shadowed(param_11, param_12, param_13, _395, fa_light_tex, fa_shadow_smp, fa_light_atlas, fa_env_smp, fa_light_tint, fa_light_is_area, gl_FragCoord, _2052, fa_shadow_tex, in.fa_world_pos, fa_screen_tex, in.fa_lm);\n            SurfaceInput param_14 = SurfaceInput{ in.fa_world_pos, _4633, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _4224, short(gl_FrontFacing) };\n            Surface param_15 = Surface{ _4664, _4665, _4666, _4667, _4668, _4669, _4670, _4671, _4672, _4673, _4674, _4675, _4676, _4677, _4678, _4679 };\n            LightSample param_16 = _4319;\n            lit += light(param_14, param_15, param_16);\n        }\n        result = lit;\n    }\n    float3 _4334 = result;\n    float3 _4335 = _4334 + _4670;\n    result = _4335;\n    float3 param_17 = _4335;\n    float3 param_18 = in.fa_world_pos;\n    result = fa_shadow_debug(param_17, param_18, _2052);\n    bool _4344 = _395.fa_fog.w > 0.0;\n    bool _4351;\n    if (!_4344)\n    {\n        _4351 = _395.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _4351 = _4344;\n    }\n    if (_4351)\n    {\n        float3 _4360 = in.fa_world_pos - _395.fa_camera_pos.xyz;\n        float _4366 = dot(_4360, _395.fa_fog_c.xyz);\n        bool _4370 = _395.fa_fog_c.w > 0.5;\n        float _4371;\n        if (_4370)\n        {\n            _4371 = _4366;\n        }\n        else\n        {\n            _4371 = length(_4360);\n        }\n        float _4383 = _4371 - _395.fa_fog_b.x;\n        if (_4383 > 0.0)\n        {\n            float _4392 = _395.fa_fog.w * _4383;\n            float tau = _4392 * _4392;\n            if (_395.fa_fog_b.y > 0.0)\n            {\n                float _4408;\n                if (_4370)\n                {\n                    _4408 = in.fa_world_pos.y - (_395.fa_fog_c.y * _4366);\n                }\n                else\n                {\n                    _4408 = _395.fa_camera_pos.y;\n                }\n                float _4429 = mix(_4408, in.fa_world_pos.y, fast::clamp(_395.fa_fog_b.x / _4371, 0.0, 1.0));\n                float _4433 = in.fa_world_pos.y - _4429;\n                float _4438 = _4429 - _395.fa_fog_b.z;\n                float _4443 = in.fa_world_pos.y - _395.fa_fog_b.z;\n                bool _4446 = _4438 <= 0.0;\n                bool _4447 = !_4446;\n                bool _4453;\n                if (_4447)\n                {\n                    _4453 = _395.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4453 = _4446;\n                }\n                float _4454;\n                if (_4453)\n                {\n                    _4454 = _395.fa_fog_b.y;\n                }\n                else\n                {\n                    _4454 = _395.fa_fog_b.y * exp(-fast::min(_395.fa_fog_b.w * _4438, 80.0));\n                }\n                bool _4481;\n                if (_4447)\n                {\n                    _4481 = _395.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4481 = _4446;\n                }\n                float _4482;\n                if (_4481)\n                {\n                    _4482 = _395.fa_fog_b.y * _4438;\n                }\n                else\n                {\n                    _4482 = (_395.fa_fog_b.y * (1.0 - exp(-fast::min(_395.fa_fog_b.w * _4438, 80.0)))) / _395.fa_fog_b.w;\n                }\n                bool _4507 = _4443 <= 0.0;\n                bool _4514;\n                if (!_4507)\n                {\n                    _4514 = _395.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4514 = _4507;\n                }\n                float _4515;\n                if (_4514)\n                {\n                    _4515 = _395.fa_fog_b.y * _4443;\n                }\n                else\n                {\n                    _4515 = (_395.fa_fog_b.y * (1.0 - exp(-fast::min(_395.fa_fog_b.w * _4443, 80.0)))) / _395.fa_fog_b.w;\n                }\n                float _4542;\n                if (abs(_4433) < 0.001000000047497451305389404296875)\n                {\n                    _4542 = _4454;\n                }\n                else\n                {\n                    _4542 = (_4515 - _4482) / _4433;\n                }\n                tau += (_4383 * fast::max(_4542, 0.0));\n            }\n            result = mix(result, _395.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _4665);\n    return out;\n}\n\n",
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
            "size": 176,
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
            "size": 800,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_395",
            "msl_buffer_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2052",
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
              "name": "fa_probe_atlas",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 6
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
              "msl_texture_n": 7
            }
          },
          {
            "texture": {
              "slot": 25,
              "stage": "fragment",
              "name": "fa_light_atlas",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 8
            }
          },
          {
            "texture": {
              "slot": 26,
              "stage": "fragment",
              "name": "fa_lightmap",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 9
            }
          },
          {
            "texture": {
              "slot": 27,
              "stage": "fragment",
              "name": "fa_decal_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 10
            }
          },
          {
            "texture": {
              "slot": 28,
              "stage": "fragment",
              "name": "fa_screen_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float",
              "msl_texture_n": 11
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
            "name": "fa_decal_tex_fa_env_smp",
            "view_name": "fa_decal_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 27,
            "sampler_slot": 10
          },
          {
            "slot": 7,
            "stage": "fragment",
            "name": "fa_lightmap_fa_env_smp",
            "view_name": "fa_lightmap",
            "sampler_name": "fa_env_smp",
            "view_slot": 26,
            "sampler_slot": 10
          },
          {
            "slot": 8,
            "stage": "fragment",
            "name": "fa_probe_atlas_fa_env_smp",
            "view_name": "fa_probe_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10
          },
          {
            "slot": 9,
            "stage": "fragment",
            "name": "fa_light_atlas_fa_env_smp",
            "view_name": "fa_light_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 25,
            "sampler_slot": 10
          },
          {
            "slot": 10,
            "stage": "fragment",
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1
          },
          {
            "slot": 11,
            "stage": "fragment",
            "name": "fa_screen_tex_fa_shadow_smp",
            "view_name": "fa_screen_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 28,
            "sampler_slot": 1
          }
        ]
      }
    },
    "prepass": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_prepass_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float& fa_pre_depth, thread float3& fa_pre_r0, thread float3& fa_pre_r1, thread float3& fa_pre_r2, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _131);\n    float3 _299 = _160.world_pos;\n    float4 _171 = float4(_299, 1.0);\n    fa_world_pos = _299;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -(_131.fa_light_vp * _171).z;\n    fa_pre_r0 = float3(_131.fa_light_vp[0].x, _131.fa_light_vp[1].x, _131.fa_light_vp[2].x);\n    fa_pre_r1 = float3(_131.fa_light_vp[0].y, _131.fa_light_vp[1].y, _131.fa_light_vp[2].y);\n    fa_pre_r2 = float3(_131.fa_light_vp[0].z, _131.fa_light_vp[1].z, _131.fa_light_vp[2].z);\n    gl_Position = _131.fa_view_proj * _171;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _131 [[buffer(0)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5, _131, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_pre_depth, out.fa_pre_r0, out.fa_pre_r1, out.fa_pre_r2, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n    float4 fa_ct_a;\n    float4 fa_ct_b;\n    float4 fa_ct_vpx;\n    float4 fa_ct_vpy;\n    float4 fa_ct_vpw;\n    float4 fa_ct_fwd;\n    float4 fa_probe_sh[9];\n    float4 fa_atlas;\n    float4 fa_rpa_tile;\n    float4 fa_rpa_pos;\n    float4 fa_rpa_bx;\n    float4 fa_rpa_by;\n    float4 fa_rpa_bz;\n    float4 fa_rpb_tile;\n    float4 fa_rpb_pos;\n    float4 fa_rpb_bx;\n    float4 fa_rpb_by;\n    float4 fa_rpb_bz;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _56;\n    if (bool(i.front_facing))\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = fast::normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = fast::normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (bool(i.front_facing))\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _215, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _215.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _227 = fa_tex_fix(param_2, param_3);\n    float4 _785 = base_t;\n    _785.x = _227.x;\n    _785.y = _227.y;\n    _785.z = _227.z;\n    base_t = _785;\n    float4 _243 = (_785 * _215.fa_base_color) * i.vertex_color;\n    float3 _748 = i.world_normal;\n    if (_215.fa_maps.z > 0.5)\n    {\n        float param_4 = _215.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _277 = fa_tex_fix(param_6, param_7);\n        float3 _281 = (_277 * 2.0) - float3(1.0);\n        float2 _286 = _281.xy * _215.fa_maps.x;\n        float3 _793 = _281;\n        _793.x = _286.x;\n        _793.y = _286.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _793;\n        _748 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _215.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _315 = fa_tex_fix(param_12, param_13);\n    float4 _796 = mrt;\n    _796.x = _315.x;\n    _796.y = _315.y;\n    _796.z = _315.z;\n    mrt = _796;\n    float4 _345 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _215.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _345.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _357 = fa_tex_fix(param_16, param_17);\n    float param_18 = _215.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _387 = fa_tex_fix(param_20, param_21);\n    float _753 = _215.fa_layers_a.x;\n    float _754 = _215.fa_layers_a.y;\n    float _757 = _215.fa_layers_a.z;\n    float _756 = _215.fa_layers_b.w;\n    float _759 = _215.fa_layers_c.x;\n    if (_215.fa_layers_c.z > 0.5)\n    {\n        if (mod(_215.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _753 *= _357.y;\n            _754 *= _357.z;\n            _756 *= _345.w;\n        }\n        if (_215.fa_layers_c.z > 1.5)\n        {\n            _757 *= mrt.x;\n            _759 *= mrt.w;\n        }\n    }\n    return Surface{ _243.xyz, _243.w, _748, fast::clamp(_215.fa_pbr.x * _315.z, 0.0, 1.0), fast::clamp(_215.fa_pbr.y * _315.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_215.fa_maps.y * (_357.x - 1.0)), _215.fa_emissive.xyz + (_215.fa_model_emissive.xyz * _387), _753, _754, _215.fa_layers_b.xyz, _756, _757, _215.fa_layers_a.w, _759, _215.fa_layers_c.y, _215.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _215 [[buffer(1)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], sampler fa_smp [[sampler(0)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _659 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _659 = -_659;\n    }\n    float3 _521 = fast::normalize(_215.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _659, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _521, short(gl_FrontFacing) };\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _659, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _521, short(gl_FrontFacing) };\n    Surface param_2 = fa_standard_surface(param, fa_tex, fa_smp, _215, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    surface(param_1, param_2);\n    float3 _536 = fast::normalize(param_2.normal);\n    float3 _551 = fast::normalize(float3(dot(in.fa_pre_r0, _536), dot(in.fa_pre_r1, _536), dot(in.fa_pre_r2, _536)));\n    float _563 = _551.z;\n    float2 e = _551.xy / float2((abs(_551.x) + abs(_551.y)) + abs(_563));\n    if (_563 < 0.0)\n    {\n        e = (float2(1.0) - abs(e.yx)) * float2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    out.fa_frag_color = float4(fast::min(in.fa_pre_depth, 60000.0), e, 1.0);\n    return out;\n}\n\n",
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
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_131",
            "msl_buffer_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 800,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_215",
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n    float4 fa_joints [[attribute(9)]];\n    float4 fa_weights [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _183)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_183.fa_joint_rows[_174] * weights[i]);\n        r1 += (_183.fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183.fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_prepass_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float& fa_pre_depth, thread float3& fa_pre_r0, thread float3& fa_pre_r1, thread float3& fa_pre_r2, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _136);\n    float3 _420 = _273.world_pos;\n    float4 _284 = float4(_420, 1.0);\n    fa_world_pos = _420;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    fa_pre_depth = -(_136.fa_light_vp * _284).z;\n    fa_pre_r0 = float3(_136.fa_light_vp[0].x, _136.fa_light_vp[1].x, _136.fa_light_vp[2].x);\n    fa_pre_r1 = float3(_136.fa_light_vp[0].y, _136.fa_light_vp[1].y, _136.fa_light_vp[2].y);\n    fa_pre_r2 = float3(_136.fa_light_vp[0].z, _136.fa_light_vp[1].z, _136.fa_light_vp[2].z);\n    gl_Position = _136.fa_view_proj * _284;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _136 [[buffer(0)]], constant fa_skin& _183 [[buffer(3)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float4x4 param_2 = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _183);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7, _136, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_pre_depth, out.fa_pre_r0, out.fa_pre_r1, out.fa_pre_r2, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n    float4 fa_ct_a;\n    float4 fa_ct_b;\n    float4 fa_ct_vpx;\n    float4 fa_ct_vpy;\n    float4 fa_ct_vpw;\n    float4 fa_ct_fwd;\n    float4 fa_probe_sh[9];\n    float4 fa_atlas;\n    float4 fa_rpa_tile;\n    float4 fa_rpa_pos;\n    float4 fa_rpa_bx;\n    float4 fa_rpa_by;\n    float4 fa_rpa_bz;\n    float4 fa_rpb_tile;\n    float4 fa_rpb_pos;\n    float4 fa_rpb_bx;\n    float4 fa_rpb_by;\n    float4 fa_rpb_bz;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _56;\n    if (bool(i.front_facing))\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = fast::normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = fast::normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (bool(i.front_facing))\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _215, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _215.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _227 = fa_tex_fix(param_2, param_3);\n    float4 _785 = base_t;\n    _785.x = _227.x;\n    _785.y = _227.y;\n    _785.z = _227.z;\n    base_t = _785;\n    float4 _243 = (_785 * _215.fa_base_color) * i.vertex_color;\n    float3 _748 = i.world_normal;\n    if (_215.fa_maps.z > 0.5)\n    {\n        float param_4 = _215.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _277 = fa_tex_fix(param_6, param_7);\n        float3 _281 = (_277 * 2.0) - float3(1.0);\n        float2 _286 = _281.xy * _215.fa_maps.x;\n        float3 _793 = _281;\n        _793.x = _286.x;\n        _793.y = _286.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _793;\n        _748 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _215.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _315 = fa_tex_fix(param_12, param_13);\n    float4 _796 = mrt;\n    _796.x = _315.x;\n    _796.y = _315.y;\n    _796.z = _315.z;\n    mrt = _796;\n    float4 _345 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _215.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _345.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _357 = fa_tex_fix(param_16, param_17);\n    float param_18 = _215.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _387 = fa_tex_fix(param_20, param_21);\n    float _753 = _215.fa_layers_a.x;\n    float _754 = _215.fa_layers_a.y;\n    float _757 = _215.fa_layers_a.z;\n    float _756 = _215.fa_layers_b.w;\n    float _759 = _215.fa_layers_c.x;\n    if (_215.fa_layers_c.z > 0.5)\n    {\n        if (mod(_215.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _753 *= _357.y;\n            _754 *= _357.z;\n            _756 *= _345.w;\n        }\n        if (_215.fa_layers_c.z > 1.5)\n        {\n            _757 *= mrt.x;\n            _759 *= mrt.w;\n        }\n    }\n    return Surface{ _243.xyz, _243.w, _748, fast::clamp(_215.fa_pbr.x * _315.z, 0.0, 1.0), fast::clamp(_215.fa_pbr.y * _315.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_215.fa_maps.y * (_357.x - 1.0)), _215.fa_emissive.xyz + (_215.fa_model_emissive.xyz * _387), _753, _754, _215.fa_layers_b.xyz, _756, _757, _215.fa_layers_a.w, _759, _215.fa_layers_c.y, _215.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _215 [[buffer(1)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], sampler fa_smp [[sampler(0)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _659 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _659 = -_659;\n    }\n    float3 _521 = fast::normalize(_215.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _659, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _521, short(gl_FrontFacing) };\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _659, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _521, short(gl_FrontFacing) };\n    Surface param_2 = fa_standard_surface(param, fa_tex, fa_smp, _215, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    surface(param_1, param_2);\n    float3 _536 = fast::normalize(param_2.normal);\n    float3 _551 = fast::normalize(float3(dot(in.fa_pre_r0, _536), dot(in.fa_pre_r1, _536), dot(in.fa_pre_r2, _536)));\n    float _563 = _551.z;\n    float2 e = _551.xy / float2((abs(_551.x) + abs(_551.y)) + abs(_563));\n    if (_563 < 0.0)\n    {\n        e = (float2(1.0) - abs(e.yx)) * float2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    out.fa_frag_color = float4(fast::min(in.fa_pre_depth, 60000.0), e, 1.0);\n    return out;\n}\n\n",
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
            "size": 176,
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
            "size": 800,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_215",
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
