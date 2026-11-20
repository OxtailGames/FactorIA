{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "5f457c7d0bc8edbcdea422ba00c093c613745eefd8db6d8c8f93fc5e235db1e8",
  "slang": "metal_macos",
  "params": [
    "dark"
  ],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float3 fa_lm [[user(locn5)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _131);\n    float3 _270 = _160.world_pos;\n    fa_world_pos = _270;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = _131.fa_view_proj * float4(_270, 1.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _131 [[buffer(0)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5, _131, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.gl_Position);\n    out.fa_lm = float3(0.0);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n#pragma clang diagnostic ignored \"-Wmissing-braces\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\ntemplate<typename T, size_t Num>\nstruct spvUnsafeArray\n{\n    T elements[Num ? Num : 1];\n    \n    thread T& operator [] (size_t pos) thread\n    {\n        return elements[pos];\n    }\n    constexpr const thread T& operator [] (size_t pos) const thread\n    {\n        return elements[pos];\n    }\n    \n    device T& operator [] (size_t pos) device\n    {\n        return elements[pos];\n    }\n    constexpr const device T& operator [] (size_t pos) const device\n    {\n        return elements[pos];\n    }\n    \n    constexpr const constant T& operator [] (size_t pos) const constant\n    {\n        return elements[pos];\n    }\n    \n    threadgroup T& operator [] (size_t pos) threadgroup\n    {\n        return elements[pos];\n    }\n    constexpr const threadgroup T& operator [] (size_t pos) const threadgroup\n    {\n        return elements[pos];\n    }\n};\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n    float4 fa_shadow_lcfg;\n};\n\nstruct fa_material\n{\n    float dark;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float3 fa_lm [[user(locn5)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_cluster_texel(thread const float3& world_pos, constant fa_mesh_fs_params& _378, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    bool _1306 = _378.fa_cl_info.x < 0.0;\n    bool _1313;\n    if (!_1306)\n    {\n        _1313 = _378.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _1313 = _1306;\n    }\n    bool _1321;\n    if (!_1313)\n    {\n        _1321 = _378.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _1321 = _1313;\n    }\n    bool _1328;\n    if (!_1321)\n    {\n        _1328 = _378.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _1328 = _1321;\n    }\n    bool _1335;\n    if (!_1328)\n    {\n        _1335 = _378.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _1335 = _1328;\n    }\n    if (_1335)\n    {\n        return float4(0.0);\n    }\n    float4 _1345 = float4(world_pos, 1.0);\n    float _1351 = dot(_378.fa_cl_vpw, _1345);\n    if (!(_1351 > 9.9999999747524270787835121154785e-07))\n    {\n        return float4(0.0);\n    }\n    float2 _1373 = float2(dot(_378.fa_cl_vpx, _1345), dot(_378.fa_cl_vpy, _1345)) / float2(_1351);\n    int _1377 = int(_378.fa_cl_grid.x);\n    int _1381 = int(_378.fa_cl_grid.y);\n    int param = (int(_378.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_378.fa_cl_fwd.xyz, world_pos) + _378.fa_cl_fwd.w, _378.fa_cl_grid.w) / _378.fa_cl_grid.w) * _378.fa_cl_grid.z)), 0, int(_378.fa_cl_info.y) - 1) * _1381) + clamp(int(floor(((_1373.y * 0.5) + 0.5) * _378.fa_cl_grid.y)), 0, _1381 - 1)) * _1377)) + clamp(int(floor(((_1373.x * 0.5) + 0.5) * _378.fa_cl_grid.x)), 0, _1377 - 1);\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, constant fa_mesh_fs_params& _378, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    float3 param = world_pos;\n    float4 _1457 = fa_cluster_texel(param, _378, fa_light_tex, fa_shadow_smp);\n    return int2(int(_1457.x), int(_1457.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, constant fa_mesh_fs_params& _378, texture2d<float> fa_light_tex, sampler fa_shadow_smp, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_378.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _3235 = fa_cluster_lookup(param, _378, fa_light_tex, fa_shadow_smp);\n    fa_cl_slot = _3235.x;\n    fa_cl_local = _3235.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _3417 = fa_linear_to_srgb(param);\n        c = _3417;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _3425 = fa_srgb_to_linear(param_1);\n            c = _3425;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _261;\n    if (bool(i.front_facing))\n    {\n        _261 = i.world_normal;\n    }\n    else\n    {\n        _261 = -i.world_normal;\n    }\n    float3 _285 = fast::normalize(i.world_tangent.xyz - (_261 * dot(_261, i.world_tangent.xyz)));\n    float3 _312 = fast::normalize(((_285 * m.x) + ((cross(_261, _285) * i.world_tangent.w) * m.y)) + (_261 * m.z));\n    float3 _315;\n    if (bool(i.front_facing))\n    {\n        _315 = _312;\n    }\n    else\n    {\n        _315 = -_312;\n    }\n    return _315;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _378, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _378.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _3456 = fa_tex_fix(param_2, param_3);\n    float4 _4479 = base_t;\n    _4479.x = _3456.x;\n    _4479.y = _3456.y;\n    _4479.z = _3456.z;\n    base_t = _4479;\n    float4 _3470 = (_4479 * _378.fa_base_color) * i.vertex_color;\n    float3 _4344 = i.world_normal;\n    if (_378.fa_maps.z > 0.5)\n    {\n        float param_4 = _378.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _3502 = fa_tex_fix(param_6, param_7);\n        float3 _3505 = (_3502 * 2.0) - float3(1.0);\n        float2 _3510 = _3505.xy * _378.fa_maps.x;\n        float3 _4487 = _3505;\n        _4487.x = _3510.x;\n        _4487.y = _3510.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _4487;\n        _4344 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _378.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _3538 = fa_tex_fix(param_12, param_13);\n    float4 _4490 = mrt;\n    _4490.x = _3538.x;\n    _4490.y = _3538.y;\n    _4490.z = _3538.z;\n    mrt = _4490;\n    float4 _3566 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _378.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _3566.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _3577 = fa_tex_fix(param_16, param_17);\n    float param_18 = _378.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _3607 = fa_tex_fix(param_20, param_21);\n    float _4349 = _378.fa_layers_a.x;\n    float _4350 = _378.fa_layers_a.y;\n    float _4353 = _378.fa_layers_a.z;\n    float _4352 = _378.fa_layers_b.w;\n    float _4355 = _378.fa_layers_c.x;\n    if (_378.fa_layers_c.z > 0.5)\n    {\n        if (mod(_378.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _4349 *= _3577.y;\n            _4350 *= _3577.z;\n            _4352 *= _3566.w;\n        }\n        if (_378.fa_layers_c.z > 1.5)\n        {\n            _4353 *= mrt.x;\n            _4355 *= mrt.w;\n        }\n    }\n    return Surface{ _3470.xyz, _3470.w, _4344, fast::clamp(_378.fa_pbr.x * _3538.z, 0.0, 1.0), fast::clamp(_378.fa_pbr.y * _3538.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_378.fa_maps.y * (_3577.x - 1.0)), _378.fa_emissive.xyz + (_378.fa_model_emissive.xyz * _3607), _4349, _4350, _378.fa_layers_b.xyz, _4352, _4353, _378.fa_layers_a.w, _4355, _378.fa_layers_c.y, _378.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_decal_tile(thread const float4& rect, thread const float2& uv, thread const float2& atlas, thread const float2& ddx, thread const float2& ddy, sampler fa_env_smp, texture2d<float> fa_decal_tex)\n{\n    float2 _1537 = rect.zw - rect.xy;\n    float2 _1541 = _1537 * atlas;\n    float2 _1545 = ddx * _1541;\n    float2 _1549 = ddy * _1541;\n    return fa_decal_tex.sample(fa_env_smp, (rect.xy + (fast::clamp(uv, float2(0.0), float2(1.0)) * _1537)), level(fast::clamp(0.5 * log2(fast::max(fast::max(dot(_1545, _1545), dot(_1549, _1549)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_apply_decals(thread const float3& world_pos, thread const float3& geo_normal, thread float3& albedo, thread float3& normal, constant fa_mesh_fs_params& _378, texture2d<float> fa_light_tex, sampler fa_shadow_smp, sampler fa_env_smp, texture2d<float> fa_decal_tex)\n{\n    bool _1582 = _378.fa_counts.y < 0.5;\n    bool _1589;\n    if (!_1582)\n    {\n        _1589 = _378.fa_counts.w < 0.5;\n    }\n    else\n    {\n        _1589 = _1582;\n    }\n    if (_1589)\n    {\n        return;\n    }\n    float3 _1595 = dfdx(world_pos);\n    float3 _1598 = dfdy(world_pos);\n    float3 param = world_pos;\n    float4 _1602 = fa_cluster_texel(param, _378, fa_light_tex, fa_shadow_smp);\n    int _1606 = int(_1602.w);\n    if (_1606 < 1)\n    {\n        return;\n    }\n    int _1616 = int(_378.fa_counts.y + 0.5);\n    int param_1 = _1616;\n    float4 _1620 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float2 _1623 = _1620.yz;\n    int _1627 = int(_1620.w);\n    int param_2 = _1616 + 1;\n    float4 _1632 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float _1633 = _1632.x;\n    int _1639 = int(_378.fa_counts.w + 0.5) - 1;\n    int _1643 = int(_1602.z);\n    float3 _1908;\n    for (int k = 0; k < _1606; k++)\n    {\n        int _1656 = _1643 + k;\n        int param_3 = _1627 + (_1656 >> 2);\n        int _1673 = (_1616 + 2) + (int(fa_light_texel(param_3, fa_light_tex, fa_shadow_smp)[_1656 & 3]) * 7);\n        int param_4 = _1673 + 6;\n        float4 _1678 = fa_light_texel(param_4, fa_light_tex, fa_shadow_smp);\n        if (((int(_1678.w + 0.5) >> _1639) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1673;\n        float4 _1693 = fa_light_texel(param_5, fa_light_tex, fa_shadow_smp);\n        int param_6 = _1673 + 1;\n        float4 _1698 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n        int param_7 = _1673 + 2;\n        float4 _1703 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n        float3 _1706 = _1693.xyz;\n        float _1711 = dot(_1706, world_pos) + _1693.w;\n        float3 _1713 = _1698.xyz;\n        float _1718 = dot(_1713, world_pos) + _1698.w;\n        float3 _1720 = _1703.xyz;\n        float _1725 = dot(_1720, world_pos) + _1703.w;\n        bool _1730 = abs(_1711) > 0.5;\n        bool _1738;\n        if (!_1730)\n        {\n            _1738 = abs(_1718) > 0.5;\n        }\n        else\n        {\n            _1738 = _1730;\n        }\n        bool _1746;\n        if (!_1738)\n        {\n            _1746 = abs(_1725) > 0.5;\n        }\n        else\n        {\n            _1746 = _1738;\n        }\n        if (_1746)\n        {\n            continue;\n        }\n        float _1761 = fast::clamp(dot(geo_normal, fast::normalize(_1720)) * _1678.z, 0.0, 1.0);\n        if (_1761 <= 0.0)\n        {\n            continue;\n        }\n        float _1781 = (fast::clamp((0.5 - abs(_1725)) * 10.0, 0.0, 1.0) * _1761) * _1678.x;\n        float2 _1789 = float2(_1711 + 0.5, 0.5 - _1718);\n        float2 _1799 = float2(dot(_1706, _1595), dot(_1713, _1595));\n        float2 _1809 = float2(dot(_1706, _1598), dot(_1713, _1598));\n        int param_8 = _1673 + 5;\n        float4 _1814 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n        int param_9 = _1673 + 3;\n        float4 _1819 = fa_light_texel(param_9, fa_light_tex, fa_shadow_smp);\n        int param_10 = _1673 + 4;\n        float4 _1824 = fa_light_texel(param_10, fa_light_tex, fa_shadow_smp);\n        float tex_a = 1.0;\n        float3 col = _1814.xyz;\n        bool _1834 = _1819.z > _1819.x;\n        if (_1834)\n        {\n            float4 param_11 = _1819;\n            float2 param_12 = _1789;\n            float2 param_13 = _1623;\n            float2 param_14 = _1799;\n            float2 param_15 = _1809;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15, fa_env_smp, fa_decal_tex);\n            if ((_1633 > 0.5) && (_1633 < 1.5))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1860 = fa_dc_to_linear(param_16);\n                float4 _4424 = tx;\n                _4424.x = _1860.x;\n                _4424.y = _1860.y;\n                _4424.z = _1860.z;\n                tx = _4424;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, float3(fast::clamp((_1781 * tex_a) * _1814.w, 0.0, 1.0)));\n        if (_1824.z > _1824.x)\n        {\n            float4 param_17 = _1824;\n            float2 param_18 = _1789;\n            float2 param_19 = _1623;\n            float2 param_20 = _1799;\n            float2 param_21 = _1809;\n            float4 _1904 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21, fa_env_smp, fa_decal_tex);\n            if (_1633 > 1.5)\n            {\n                float3 param_22 = _1904.xyz;\n                float3 _1914 = fa_dc_to_srgb(param_22);\n                _1908 = _1914;\n            }\n            else\n            {\n                _1908 = _1904.xyz;\n            }\n            float3 _1923 = (_1908 * 2.0) - float3(1.0);\n            float2 _1928 = _1923.xy * _1678.y;\n            float3 _1950 = (fast::normalize(_1706) * _1928.x) + (fast::normalize(_1713) * _1928.y);\n            float3 _1953 = fast::normalize(normal);\n            normal = fast::normalize(mix(_1953, fast::normalize((_1953 * fast::max(_1923.z, 0.0500000007450580596923828125)) + (_1950 - (_1953 * dot(_1953, _1950)))), float3(fast::clamp(_1781 * (_1834 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_sh_coef(thread const int& k, constant fa_mesh_fs_params& _378, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float3 v = fa_env_tex.sample(fa_env_smp, float3(1.0, 1.0 - (float((2 * (k >> 2)) + 1) * 0.25), 1.0 - (float((2 * (k & 3)) + 1) * 0.25)), level(5.0)).xyz;\n    if (_378.fa_env_sky.w > 1.5)\n    {\n        v = (v - float3(0.5)) * 8.0;\n    }\n    return v;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sh_eval(thread const spvUnsafeArray<float3, 9>& c, thread const float3& n)\n{\n    float3 _3148 = fast::max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), float3(0.0));\n    return _3148;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _378, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    if (_378.fa_env_sky.w > 0.5)\n    {\n        spvUnsafeArray<float3, 9> c;\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param, _378, fa_env_smp, fa_env_tex);\n        }\n        spvUnsafeArray<float3, 9> param_1 = c;\n        float3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return _378.fa_ambient.xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_indirect_diffuse(thread const float3& n, constant fa_mesh_fs_params& _378, sampler fa_env_smp, texturecube<float> fa_env_tex, thread float3& fa_lm, texture2d<float> fa_lightmap)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return fa_lightmap.sample(fa_env_smp, fa_lm.xy, level(0.0)).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param, _378, fa_env_smp, fa_env_tex);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, constant fa_mesh_fs_params& _378, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (int(_378.fa_cl_info.x) + int(_378.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, constant fa_mesh_fs_params& _378, texture2d<float> fa_light_tex, sampler fa_shadow_smp, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, _378, fa_light_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_light_base(thread const int& li, constant fa_mesh_fs_params& _378)\n{\n    return li * ((_378.fa_ambient.w > 4.5) ? 8 : 4);\n}\n\nstatic inline __attribute__((always_inline))\nbool fa_light_baked(thread const int& li, constant fa_mesh_fs_params& _378, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li;\n    int param_1 = fa_light_base(param, _378) + 3;\n    return fa_light_texel(param_1, fa_light_tex, fa_shadow_smp).w > 0.5;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_light_type(thread const int& li, constant fa_mesh_fs_params& _378, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li;\n    int param_1 = fa_light_base(param, _378) + 1;\n    return fa_light_texel(param_1, fa_light_tex, fa_shadow_smp).w;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_atlas_fetch(thread const float2& texel, texture2d<float> fa_light_atlas, sampler fa_env_smp)\n{\n    return fa_light_atlas.sample(fa_env_smp, (texel / float2(int2(fa_light_atlas.get_width(), fa_light_atlas.get_height()))), level(0.0));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_cookie_sample(thread const float2& tile_origin, thread const float2& uv, texture2d<float> fa_light_atlas, sampler fa_env_smp)\n{\n    float2 param = (tile_origin + float2(1.0)) + (fast::clamp(uv, float2(0.0), float2(1.0)) * 254.0);\n    return fa_atlas_fetch(param, fa_light_atlas, fa_env_smp).xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_area_point(thread const float3& c, thread const float3& axis, thread const float3& ru, thread const float3& uu, thread const float& hx, thread const float& hy, thread const float& shape, thread const float3& p, thread const float3& r)\n{\n    bool _556 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        float3 _569 = (c - (ru * hx)) - p;\n        float3 _575 = ru * (2.0 * hx);\n        float _581 = fast::max(dot(_575, _575), 9.9999999392252902907785028219223e-09);\n        float _585 = dot(_569, _575);\n        float t = fast::clamp((-_585) / _581, 0.0, 1.0);\n        if (_556)\n        {\n            float _600 = dot(r, _575);\n            float _606 = _581 - (_600 * _600);\n            if (abs(_606) > (9.9999997473787516355514526367188e-06 * _581))\n            {\n                t = fast::clamp(((dot(r, _569) * _600) - _585) / _606, 0.0, 1.0);\n            }\n        }\n        return (p + _569) + (_575 * t);\n    }\n    float3 q = p;\n    float _638 = dot(r, axis);\n    bool _646;\n    if (_556)\n    {\n        _646 = abs(_638) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _646 = _556;\n    }\n    if (_646)\n    {\n        float _656 = dot(c - p, axis) / _638;\n        if (_656 > 0.0)\n        {\n            q = p + (r * _656);\n        }\n    }\n    float3 _669 = q - c;\n    float2 xy = float2(dot(_669, ru), dot(_669, uu));\n    if (shape > 0.5)\n    {\n        float _684 = length(xy);\n        if (_684 > hx)\n        {\n            xy *= (hx / _684);\n        }\n    }\n    else\n    {\n        xy = fast::clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cube_face(thread const float3& d)\n{\n    float3 _327 = abs(d);\n    float _329 = _327.x;\n    float _331 = _327.y;\n    bool _332 = _329 >= _331;\n    bool _340;\n    if (_332)\n    {\n        _340 = _329 >= _327.z;\n    }\n    else\n    {\n        _340 = _332;\n    }\n    int _341;\n    if (_340)\n    {\n        _341 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _356;\n        if (_331 >= _327.z)\n        {\n            _356 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _356 = (d.z > 0.0) ? 4 : 5;\n        }\n        _341 = _356;\n    }\n    return _341;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cube_face_basis(thread const int& f, thread float3& fwd, thread float3& up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0, 0.0, 0.0);\n        up = float3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0, 0.0, 0.0);\n            up = float3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0, 1.0, 0.0);\n                up = float3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0, -1.0, 0.0);\n                    up = float3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0, 0.0, 1.0);\n                        up = float3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0, 0.0, -1.0);\n                        up = float3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_ies_sample(thread const float2& tile_origin, thread const float3& d, thread const float3& axis, thread const float3& right, thread const float3& up, texture2d<float> fa_light_atlas, sampler fa_env_smp)\n{\n    float _476 = dot(d, right);\n    float _480 = dot(d, up);\n    float _491;\n    if (((_476 * _476) + (_480 * _480)) > 1.0000000133514319600180897396058e-10)\n    {\n        _491 = precise::atan2(_480, _476) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _491 = 0.0;\n    }\n    float2 param = tile_origin + float2(1.0 + ((_491 - floor(_491)) * 64.0), 1.0 + (acos(fast::clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param, fa_light_atlas, fa_env_smp).x;\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample_n(thread const int& li, thread const float3& world_pos, thread const float3& n, constant fa_mesh_fs_params& _378, texture2d<float> fa_light_tex, sampler fa_shadow_smp, texture2d<float> fa_light_atlas, sampler fa_env_smp, thread float3& fa_light_tint, thread bool& fa_light_is_area)\n{\n    int param = li;\n    int _722 = fa_light_base(param, _378);\n    bool _726 = _378.fa_ambient.w > 4.5;\n    int param_1 = _722;\n    float4 _730 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    int param_2 = _722 + 1;\n    float4 _735 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float _738 = _735.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = float3(1.0);\n    bool _750 = _726 && (_738 > 2.5);\n    fa_light_is_area = _750;\n    bool _752 = _738 < 0.5;\n    float3 l;\n    if (_752)\n    {\n        l = fast::normalize(_730.xyz);\n        if (_726)\n        {\n            int param_3 = _722 + 6;\n            float4 _766 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            if (_766.z > 0.5)\n            {\n                int param_4 = _722 + 4;\n                float4 _776 = fa_light_texel(param_4, fa_light_tex, fa_shadow_smp);\n                int param_5 = _722 + 5;\n                float4 _781 = fa_light_texel(param_5, fa_light_tex, fa_shadow_smp);\n                float2 param_6 = _766.xy;\n                float2 param_7 = fract(float2(dot(world_pos, _776.xyz) * _776.w, (-dot(world_pos, _781.xyz)) * _781.w) + float2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7, fa_light_atlas, fa_env_smp);\n            }\n        }\n    }\n    else\n    {\n        float3 _811 = _730.xyz;\n        float3 _813 = _811 - world_pos;\n        float3 to_light = _813;\n        float _816 = length(_813);\n        float reach = _816;\n        bool front = true;\n        if (_750)\n        {\n            int param_8 = _722 + 7;\n            reach = fast::max(_816 - fa_light_texel(param_8, fa_light_tex, fa_shadow_smp).w, 0.0);\n            int param_9 = _722 + 4;\n            float4 _840 = fa_light_texel(param_9, fa_light_tex, fa_shadow_smp);\n            int param_10 = _722 + 5;\n            float4 _845 = fa_light_texel(param_10, fa_light_tex, fa_shadow_smp);\n            int param_11 = _722 + 6;\n            float4 _850 = fa_light_texel(param_11, fa_light_tex, fa_shadow_smp);\n            float _851 = _850.w;\n            int param_12 = _722 + 2;\n            float3 _858 = fast::normalize(fa_light_texel(param_12, fa_light_tex, fa_shadow_smp).xyz);\n            bool _860 = _851 > 1.5;\n            bool _868;\n            if (!_860)\n            {\n                _868 = dot(_858, to_light) < 0.0;\n            }\n            else\n            {\n                _868 = _860;\n            }\n            front = _868;\n            float3 r = float3(0.0);\n            float3 _877 = _378.fa_camera_pos.xyz - world_pos;\n            bool _881 = dot(n, n) > 0.5;\n            bool _889;\n            if (_881)\n            {\n                _889 = dot(_877, _877) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _889 = _881;\n            }\n            if (_889)\n            {\n                r = reflect(-fast::normalize(_877), fast::normalize(n));\n            }\n            float3 param_13 = _811;\n            float3 param_14 = _858;\n            float3 param_15 = _840.xyz;\n            float3 param_16 = _845.xyz;\n            float param_17 = _840.w;\n            float param_18 = _845.w;\n            float param_19 = _851;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _925 = length(to_light);\n        dist = _925;\n        l = to_light / float3(fast::max(_925, 9.9999997473787516355514526367188e-05));\n        float _939 = reach / fast::max(_730.w, 0.001000000047497451305389404296875);\n        float _945 = fast::clamp(1.0 - (_939 * _939), 0.0, 1.0);\n        float _947;\n        if (front)\n        {\n            _947 = _945 * _945;\n        }\n        else\n        {\n            _947 = 0.0;\n        }\n        atten = _947;\n        bool _958 = _738 < 2.5;\n        if ((_738 > 1.5) && _958)\n        {\n            int param_22 = _722 + 2;\n            float4 _966 = fa_light_texel(param_22, fa_light_tex, fa_shadow_smp);\n            float _976 = _966.w;\n            int param_23 = _722 + 3;\n            float4 _981 = fa_light_texel(param_23, fa_light_tex, fa_shadow_smp);\n            float _982 = _981.x;\n            float cos_inner = _982;\n            if (_982 > 1.5)\n            {\n                cos_inner = mix(_976, 1.0, 0.25);\n            }\n            atten *= smoothstep(_976, cos_inner, dot(-l, fast::normalize(_966.xyz)));\n        }\n        if (_726 && (_738 < 1.5))\n        {\n            int param_24 = _722 + 6;\n            float4 _1006 = fa_light_texel(param_24, fa_light_tex, fa_shadow_smp);\n            if (_1006.z > 0.5)\n            {\n                float3 _1014 = -to_light;\n                int param_25 = _722 + 4;\n                int param_26 = _722 + 5;\n                float3 _1028 = fa_light_texel(param_25, fa_light_tex, fa_shadow_smp).xyz;\n                float3 _1032 = fa_light_texel(param_26, fa_light_tex, fa_shadow_smp).xyz;\n                float3 _1041 = float3(dot(_1014, _1028), dot(_1014, _1032), dot(_1014, cross(_1028, _1032)));\n                float3 param_27 = _1041;\n                int _1045 = fa_cube_face(param_27);\n                int param_28 = _1045;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1072 = float2(dot(_1041, cross(param_29, param_30)), dot(_1041, param_30)) / float2(fast::max(dot(_1041, param_29), 9.9999997473787516355514526367188e-05));\n                int _1076 = _1045 / 3;\n                float2 param_31 = _1006.xy + (float2(float(_1045 - (_1076 * 3)), float(_1076)) * 256.0);\n                float2 param_32 = float2(0.5 + (0.5 * _1072.x), 0.5 - (0.5 * _1072.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32, fa_light_atlas, fa_env_smp);\n            }\n            int param_33 = _722 + 7;\n            float4 _1106 = fa_light_texel(param_33, fa_light_tex, fa_shadow_smp);\n            if (_1106.z > 0.5)\n            {\n                int param_34 = _722 + 2;\n                int param_35 = _722 + 4;\n                int param_36 = _722 + 5;\n                float2 param_37 = _1106.xy;\n                float3 param_38 = -l;\n                float3 param_39 = fast::normalize(fa_light_texel(param_34, fa_light_tex, fa_shadow_smp).xyz);\n                float3 param_40 = fa_light_texel(param_35, fa_light_tex, fa_shadow_smp).xyz;\n                float3 param_41 = fa_light_texel(param_36, fa_light_tex, fa_shadow_smp).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41, fa_light_atlas, fa_env_smp);\n            }\n        }\n        else\n        {\n            if (_726 && _958)\n            {\n                int param_42 = _722 + 6;\n                float4 _1153 = fa_light_texel(param_42, fa_light_tex, fa_shadow_smp);\n                int param_43 = _722 + 7;\n                float4 _1158 = fa_light_texel(param_43, fa_light_tex, fa_shadow_smp);\n                bool _1161 = _1153.z > 0.5;\n                bool _1168;\n                if (!_1161)\n                {\n                    _1168 = _1158.z > 0.5;\n                }\n                else\n                {\n                    _1168 = _1161;\n                }\n                if (_1168)\n                {\n                    int param_44 = _722 + 2;\n                    float4 _1175 = fa_light_texel(param_44, fa_light_tex, fa_shadow_smp);\n                    float3 _1179 = fast::normalize(_1175.xyz);\n                    int param_45 = _722 + 4;\n                    float4 _1184 = fa_light_texel(param_45, fa_light_tex, fa_shadow_smp);\n                    int param_46 = _722 + 5;\n                    float4 _1189 = fa_light_texel(param_46, fa_light_tex, fa_shadow_smp);\n                    if (_1161)\n                    {\n                        float3 _1197 = -to_light;\n                        float _1204 = _1175.w;\n                        float _1220 = 0.5 / fast::max(dot(_1197, _1179) * (sqrt(fast::max(1.0 - (_1204 * _1204), 0.0)) / fast::max(_1204, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        float2 param_47 = _1153.xy;\n                        float2 param_48 = float2(0.5 + (dot(_1197, _1184.xyz) * _1220), 0.5 - (dot(_1197, _1189.xyz) * _1220));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48, fa_light_atlas, fa_env_smp);\n                    }\n                    if (_1158.z > 0.5)\n                    {\n                        float2 param_49 = _1158.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1179;\n                        float3 param_52 = _1184.xyz;\n                        float3 param_53 = _1189.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53, fa_light_atlas, fa_env_smp);\n                    }\n                }\n            }\n        }\n    }\n    float3 _4298 = _735.xyz * atten;\n    if (_726)\n    {\n        _4298 *= fa_light_tint;\n    }\n    int _1288;\n    if (_752)\n    {\n        _1288 = 0;\n    }\n    else\n    {\n        _1288 = ((_738 > 1.5) && (_738 < 2.5)) ? 2 : 1;\n    }\n    return LightSample{ l, _4298, atten, 1.0, dist, _1288 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _2035)\n{\n    float _2025;\n    if (i == 0)\n    {\n        _2025 = _2035.fa_shadow_split.x;\n    }\n    else\n    {\n        float _2041;\n        if (i == 1)\n        {\n            _2041 = _2035.fa_shadow_split.y;\n        }\n        else\n        {\n            float _2049;\n            if (i == 2)\n            {\n                _2049 = _2035.fa_shadow_split.z;\n            }\n            else\n            {\n                _2049 = _2035.fa_shadow_split.w;\n            }\n            _2041 = _2049;\n        }\n        _2025 = _2041;\n    }\n    return _2025;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_fetch(thread const float2& uv, thread const float4& rect, thread const float3& conv, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2082 = fa_shadow_depth(param, param_1, fa_shadow_smp, fa_shadow_tex);\n    float _2086;\n    if (conv.x < 0.5)\n    {\n        _2086 = _2082;\n    }\n    else\n    {\n        _2086 = (conv.y * conv.z) / (conv.z - (_2082 * (conv.z - conv.y)));\n    }\n    return _2086;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _2013 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_2013), sin(_2013)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_filter(thread const float2& uv, thread const float4& rect, thread const float& zr, thread const float& texel_m, thread const float& unit, thread const float& reach, thread const float& plane, thread const float3& conv, thread const int& mode, thread const float& k, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2035, texture2d<float> fa_shadow_tex)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2, fa_shadow_smp, fa_shadow_tex));\n    }\n    float _2132 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2141;\n        if (k < 0.0)\n        {\n            _2141 = (-k) / fast::max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2141 = k;\n        }\n        float _2161 = fast::clamp((_2141 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2132;\n            float2 _2180 = fa_shadow_vogel(param_3, param_4, param_5) * _2161;\n            float2 param_6 = uv + (_2180 * _2035.fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _2192 = fa_shadow_fetch(param_6, param_7, param_8, fa_shadow_smp, fa_shadow_tex);\n            if (_2192 < (zr - (length(_2180) * plane)))\n            {\n                sum += _2192;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2218 = sum / cnt;\n        float _2228;\n        if (k < 0.0)\n        {\n            _2228 = (-k) / fast::max(_2218, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2228 = k;\n        }\n        radius = fast::clamp(((fast::max(zr - _2218, 0.0) * unit) * _2228) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _2250 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2250; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2250;\n        float param_11 = _2132;\n        float2 _2269 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_2269 * _2035.fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_2269) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14, fa_shadow_smp, fa_shadow_tex));\n    }\n    return lit / float(_2250);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2035, texture2d<float> fa_shadow_tex)\n{\n    float _2311 = fast::max(_2035.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _2316 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _2322 = sqrt(1.0 - (_2316 * _2316));\n    float _2329 = fast::min(_2322 / fast::max(_2316, 0.20000000298023223876953125), 4.0);\n    float _2334;\n    if (_2035.fa_shadow_bias.y > 0.0)\n    {\n        _2334 = _2035.fa_shadow_bias.y;\n    }\n    else\n    {\n        _2334 = 1.5 * _2035.fa_shadow_info[ci].x;\n    }\n    float4 _2359 = _2035.fa_shadow_mat[ci] * float4(world + (n * (_2334 * _2322)), 1.0);\n    float _2366 = _2359.x;\n    bool _2369 = _2366 < _2035.fa_shadow_rect[ci].x;\n    bool _2378;\n    if (!_2369)\n    {\n        _2378 = _2366 > _2035.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2378 = _2369;\n    }\n    bool _2387;\n    if (!_2378)\n    {\n        _2387 = _2359.y < _2035.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2387 = _2378;\n    }\n    bool _2396;\n    if (!_2387)\n    {\n        _2396 = _2359.y > _2035.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2396 = _2387;\n    }\n    bool _2403;\n    if (!_2396)\n    {\n        _2403 = _2359.z > 1.0;\n    }\n    else\n    {\n        _2403 = _2396;\n    }\n    if (_2403)\n    {\n        return -1.0;\n    }\n    float _2411;\n    if (_2035.fa_shadow_bias.x > 0.0)\n    {\n        _2411 = _2035.fa_shadow_bias.x;\n    }\n    else\n    {\n        _2411 = 1.5 * _2035.fa_shadow_info[ci].x;\n    }\n    float2 param = _2359.xy;\n    float4 param_1 = _2035.fa_shadow_rect[ci];\n    float param_2 = _2359.z - ((_2411 * (1.0 + (0.5 * _2329))) / _2311);\n    float param_3 = _2035.fa_shadow_info[ci].x;\n    float param_4 = _2311;\n    float param_5 = _2311 * 0.25;\n    float param_6 = ((_2035.fa_shadow_info[ci].x * fast::min(_2329, 3.0)) * 0.5) / _2311;\n    float3 param_7 = float3(0.0);\n    int param_8 = int(_2035.fa_shadow_cfg.z + 0.5);\n    float param_9 = _2035.fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9, fa_shadow_smp, gl_FragCoord, _2035, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _378, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2035, texture2d<float> fa_shadow_tex)\n{\n    if (_378.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2789 = int(_2035.fa_shadow_cfg.x + 0.5);\n    if (_2789 < 1)\n    {\n        return 1.0;\n    }\n    float _2804 = dot(world - _2035.fa_shadow_eye.xyz, _2035.fa_shadow_fwd.xyz);\n    int param = _2789 - 1;\n    if (_2804 > fa_shadow_split_at(param, _2035))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2816 = _2789 > 1;\n    bool _2823;\n    if (_2816)\n    {\n        _2823 = _2804 > _2035.fa_shadow_split.x;\n    }\n    else\n    {\n        _2823 = _2816;\n    }\n    if (_2823)\n    {\n        ci = 1;\n    }\n    bool _2827 = _2789 > 2;\n    bool _2834;\n    if (_2827)\n    {\n        _2834 = _2804 > _2035.fa_shadow_split.y;\n    }\n    else\n    {\n        _2834 = _2827;\n    }\n    if (_2834)\n    {\n        ci = 2;\n    }\n    bool _2838 = _2789 > 3;\n    bool _2845;\n    if (_2838)\n    {\n        _2845 = _2804 > _2035.fa_shadow_split.z;\n    }\n    else\n    {\n        _2845 = _2838;\n    }\n    if (_2845)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2789)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2871 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_shadow_smp, gl_FragCoord, _2035, fa_shadow_tex);\n        s = _2871;\n        if (_2871 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_2035.fa_shadow_cfg.y > 0.0)\n    {\n        float _2896;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2896 = fa_shadow_split_at(param_5, _2035);\n        }\n        else\n        {\n            _2896 = _2035.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _2915 = _2035.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _2035) - _2896, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2926 = fast::clamp((_2804 - (fa_shadow_split_at(param_7, _2035) - _2915)) / _2915, 0.0, 1.0);\n        if (_2926 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2789)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _2947 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_shadow_smp, gl_FragCoord, _2035, fa_shadow_tex);\n                s2 = _2947;\n                if (_2947 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2926);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _378, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2035, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, _378, fa_shadow_smp, gl_FragCoord, _2035, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_local(thread const int& li, thread const float3& lpos, thread const float3& world, thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _378, texture2d<float> fa_light_tex, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2035, texture2d<float> fa_shadow_tex)\n{\n    bool _2469 = _378.fa_pbr.z < 0.5;\n    bool _2476;\n    if (!_2469)\n    {\n        _2476 = _2035.fa_shadow_lcfg.x < 0.5;\n    }\n    else\n    {\n        _2476 = _2469;\n    }\n    if (_2476)\n    {\n        return 1.0;\n    }\n    int param = (int(_2035.fa_shadow_lcfg.x + 0.5) - 1) + li;\n    float4 _2489 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    float _2490 = _2489.x;\n    if (_2490 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2499 = int(_2490 + 0.5);\n    int param_1 = _2499;\n    float4 _2503 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    int param_2 = _2499 + 1;\n    float4 _2508 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float fade = 1.0;\n    float _2511 = _2503.y;\n    if (_2511 > 0.0)\n    {\n        float _2528 = 1.0 - smoothstep(0.75 * _2511, _2511, length(world - _2035.fa_shadow_eye.xyz));\n        fade = _2528;\n        if (_2528 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2503.x > 1.5)\n    {\n        float3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2552 = (_2499 + 2) + (face * 6);\n    int param_4 = _2552;\n    int param_5 = _2552 + 1;\n    int param_6 = _2552 + 3;\n    float4 _2566 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n    int param_7 = _2552 + 4;\n    float4 _2571 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n    int param_8 = _2552 + 5;\n    float4 _2576 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n    float _2588 = _2576.x * fast::max(dot(_2566, float4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2593 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _2616 = fast::clamp(dot(n, _2566.xyz), -1.0, 1.0);\n    float _2635 = fast::min(sqrt(1.0 - (_2616 * _2616)) / fast::max(abs(dot(n, world - lpos)) / fast::max(dot(_2566, float4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2638 = _2508.y;\n    float _2640;\n    if (_2638 > 0.0)\n    {\n        _2640 = _2638;\n    }\n    else\n    {\n        _2640 = 1.5 * _2588;\n    }\n    float4 _2660 = float4(world + (n * (_2640 * sqrt(1.0 - (_2593 * _2593)))), 1.0);\n    float _2664 = dot(_2566, _2660);\n    float _2667 = _2576.y;\n    if (_2664 < _2667)\n    {\n        return 1.0;\n    }\n    float2 _2682 = float2(dot(fa_light_texel(param_4, fa_light_tex, fa_shadow_smp), _2660), dot(fa_light_texel(param_5, fa_light_tex, fa_shadow_smp), _2660)) / float2(_2664);\n    float _2684 = _2682.x;\n    bool _2687 = _2684 < _2571.x;\n    bool _2696;\n    if (!_2687)\n    {\n        _2696 = _2684 > _2571.z;\n    }\n    else\n    {\n        _2696 = _2687;\n    }\n    bool _2705;\n    if (!_2696)\n    {\n        _2705 = _2682.y < _2571.y;\n    }\n    else\n    {\n        _2705 = _2696;\n    }\n    bool _2714;\n    if (!_2705)\n    {\n        _2714 = _2682.y > _2571.w;\n    }\n    else\n    {\n        _2714 = _2705;\n    }\n    if (_2714)\n    {\n        return 1.0;\n    }\n    float _2720 = _2508.x;\n    float _2722;\n    if (_2720 > 0.0)\n    {\n        _2722 = _2720;\n    }\n    else\n    {\n        _2722 = 1.5 * _2588;\n    }\n    float2 param_9 = _2682;\n    float4 param_10 = _2571;\n    float param_11 = _2664 - (_2722 * (1.0 + (0.5 * _2635)));\n    float param_12 = _2588;\n    float param_13 = 1.0;\n    float param_14 = _2576.z * 0.25;\n    float param_15 = (_2588 * fast::min(_2635, 3.0)) * 0.5;\n    float3 param_16 = float3(1.0, _2667, _2576.z);\n    int param_17 = int(_2503.z + 0.5);\n    float param_18 = _2503.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, fa_shadow_smp, gl_FragCoord, _2035, fa_shadow_tex), fade);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, constant fa_mesh_fs_params& _378, texture2d<float> fa_light_tex, sampler fa_shadow_smp, texture2d<float> fa_light_atlas, sampler fa_env_smp, thread float3& fa_light_tint, thread bool& fa_light_is_area, thread float4& gl_FragCoord, constant fa_shadows& _2035, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos, thread float3& fa_lm)\n{\n    bool _3262 = fa_lm.z > 0.5;\n    bool _3268;\n    if (_3262)\n    {\n        int param = li;\n        _3268 = fa_light_baked(param, _378, fa_light_tex, fa_shadow_smp);\n    }\n    else\n    {\n        _3268 = _3262;\n    }\n    if (_3268)\n    {\n        int param_1 = li;\n        return LightSample{ float3(0.0, 1.0, 0.0), float3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1, _378, fa_light_tex, fa_shadow_smp) + 0.5) };\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _3292 = fa_light_sample_n(param_2, param_3, param_4, _378, fa_light_tex, fa_shadow_smp, fa_light_atlas, fa_env_smp, fa_light_tint, fa_light_is_area);\n    float3 _4324 = _3292.color;\n    float _4326 = _3292.shadow;\n    if ((_3292.type == 0) && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _3292.direction;\n        float _3306 = fa_shadow_factor(param_5, param_6, _378, fa_shadow_smp, gl_FragCoord, _2035, fa_shadow_tex, fa_world_pos);\n        _4326 = _3306;\n        _4324 *= _3306;\n    }\n    else\n    {\n        bool _3317 = _3292.type != 0;\n        bool _3323;\n        if (_3317)\n        {\n            _3323 = _3292.attenuation > 0.0;\n        }\n        else\n        {\n            _3323 = _3317;\n        }\n        if (_3323)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7, _378);\n            int param_9 = li;\n            float3 param_10 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp).xyz;\n            float3 param_11 = world_pos;\n            float3 param_12 = gn;\n            float3 param_13 = _3292.direction;\n            float _3342 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13, _378, fa_light_tex, fa_shadow_smp, gl_FragCoord, _2035, fa_shadow_tex);\n            _4326 = _3342;\n            _4324 *= _3342;\n        }\n    }\n    return LightSample{ _3292.direction, _4324, _3292.attenuation, _4326, _3292._distance, _3292.type };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 light(thread const SurfaceInput& i, thread const Surface& s, thread const LightSample& l, constant fa_material& _3368)\n{\n    float _3362;\n    if (dot(s.normal, l.direction) > 0.5)\n    {\n        _3362 = 1.0;\n    }\n    else\n    {\n        _3362 = _3368.dark;\n    }\n    return (s.albedo * l.color) * _3362;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _2035)\n{\n    if (_2035.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _2971 = int(_2035.fa_shadow_cfg.x + 0.5);\n    float _2981 = dot(world - _2035.fa_shadow_eye.xyz, _2035.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _2986 = _2971 > 0;\n    bool _2995;\n    if (_2986)\n    {\n        int param = _2971 - 1;\n        _2995 = _2981 <= fa_shadow_split_at(param, _2035);\n    }\n    else\n    {\n        _2995 = _2986;\n    }\n    if (_2995)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3001 = _2971 > 1;\n        bool _3008;\n        if (_3001)\n        {\n            _3008 = _2981 > _2035.fa_shadow_split.x;\n        }\n        else\n        {\n            _3008 = _3001;\n        }\n        if (_3008)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3014 = _2971 > 2;\n        bool _3021;\n        if (_3014)\n        {\n            _3021 = _2981 > _2035.fa_shadow_split.y;\n        }\n        else\n        {\n            _3021 = _3014;\n        }\n        if (_3021)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3027 = _2971 > 3;\n        bool _3034;\n        if (_3027)\n        {\n            _3034 = _2981 > _2035.fa_shadow_split.z;\n        }\n        else\n        {\n            _3034 = _3027;\n        }\n        if (_3034)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _378 [[buffer(1)]], constant fa_material& _3368 [[buffer(5)]], constant fa_shadows& _2035 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_env_tex [[texture(6)]], texture2d<float> fa_light_tex [[texture(7)]], texture2d<float> fa_light_atlas [[texture(8)]], texture2d<float> fa_lightmap [[texture(9)]], texture2d<float> fa_decal_tex [[texture(10)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _4165 = fast::normalize(in.fa_world_normal);\n    float3 fa_light_tint;\n    bool fa_light_is_area;\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _4165 = -_4165;\n    }\n    float3 _3750 = fast::normalize(_378.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, _378, fa_light_tex, fa_shadow_smp, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _4165, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _3750, short(gl_FrontFacing) };\n    Surface _3758 = fa_standard_surface(param_1, _378, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _4196 = _3758.albedo;\n    float _4197 = _3758.alpha;\n    float3 _4198 = _3758.normal;\n    float _4199 = _3758.metallic;\n    float _4200 = _3758.roughness;\n    float _4201 = _3758.occlusion;\n    float3 _4202 = _3758.emission;\n    float _4203 = _3758.clearcoat;\n    float _4204 = _3758.clearcoat_roughness;\n    float3 _4205 = _3758.sheen_color;\n    float _4206 = _3758.sheen_roughness;\n    float _4207 = _3758.anisotropy;\n    float _4208 = _3758.anisotropy_rotation;\n    float _4209 = _3758.specular;\n    float _4210 = _3758.ior;\n    float3 _4211 = _3758.specular_color;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _4165, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _3750, short(gl_FrontFacing) };\n    Surface param_3 = _3758;\n    surface(param_2, param_3);\n    _4196 = param_3.albedo;\n    _4197 = param_3.alpha;\n    _4198 = param_3.normal;\n    _4199 = param_3.metallic;\n    _4200 = param_3.roughness;\n    _4201 = param_3.occlusion;\n    _4202 = param_3.emission;\n    _4203 = param_3.clearcoat;\n    _4204 = param_3.clearcoat_roughness;\n    _4205 = param_3.sheen_color;\n    _4206 = param_3.sheen_roughness;\n    _4207 = param_3.anisotropy;\n    _4208 = param_3.anisotropy_rotation;\n    _4209 = param_3.specular;\n    _4210 = param_3.ior;\n    _4211 = param_3.specular_color;\n    float3 param_4 = in.fa_world_pos;\n    float3 param_5 = _4165;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7, _378, fa_light_tex, fa_shadow_smp, fa_env_smp, fa_decal_tex);\n    _4196 = param_6;\n    _4198 = param_7;\n    float3 result;\n    if (_378.fa_emissive.w > 0.5)\n    {\n        result = _4196;\n    }\n    else\n    {\n        float3 _3796 = _4198;\n        float3 _3797 = fast::normalize(_3796);\n        _4198 = _3797;\n        float3 param_8 = _3797;\n        float3 lit = (fa_indirect_diffuse(param_8, _378, fa_env_smp, fa_env_tex, in.fa_lm, fa_lightmap) * _4196) * _4201;\n        int _3816 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _3816; ln++)\n        {\n            int param_9 = ln;\n            int _3829 = fa_cl_light(param_9, _378, fa_light_tex, fa_shadow_smp, fa_cl_ndir, fa_cl_slot);\n            bool _3832 = in.fa_lm.z > 0.5;\n            bool _3838;\n            if (_3832)\n            {\n                int param_10 = _3829;\n                _3838 = fa_light_baked(param_10, _378, fa_light_tex, fa_shadow_smp);\n            }\n            else\n            {\n                _3838 = _3832;\n            }\n            if (_3838)\n            {\n                continue;\n            }\n            int param_11 = _3829;\n            float3 param_12 = in.fa_world_pos;\n            float3 param_13 = _4165;\n            LightSample _3850 = fa_light_shadowed(param_11, param_12, param_13, _378, fa_light_tex, fa_shadow_smp, fa_light_atlas, fa_env_smp, fa_light_tint, fa_light_is_area, gl_FragCoord, _2035, fa_shadow_tex, in.fa_world_pos, in.fa_lm);\n            SurfaceInput param_14 = SurfaceInput{ in.fa_world_pos, _4165, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _3750, short(gl_FrontFacing) };\n            Surface param_15 = Surface{ _4196, _4197, _4198, _4199, _4200, _4201, _4202, _4203, _4204, _4205, _4206, _4207, _4208, _4209, _4210, _4211 };\n            LightSample param_16 = _3850;\n            lit += light(param_14, param_15, param_16, _3368);\n        }\n        result = lit;\n    }\n    float3 _3865 = result;\n    float3 _3866 = _3865 + _4202;\n    result = _3866;\n    float3 param_17 = _3866;\n    float3 param_18 = in.fa_world_pos;\n    result = fa_shadow_debug(param_17, param_18, _2035);\n    bool _3875 = _378.fa_fog.w > 0.0;\n    bool _3882;\n    if (!_3875)\n    {\n        _3882 = _378.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _3882 = _3875;\n    }\n    if (_3882)\n    {\n        float3 _3891 = in.fa_world_pos - _378.fa_camera_pos.xyz;\n        float _3897 = dot(_3891, _378.fa_fog_c.xyz);\n        bool _3901 = _378.fa_fog_c.w > 0.5;\n        float _3902;\n        if (_3901)\n        {\n            _3902 = _3897;\n        }\n        else\n        {\n            _3902 = length(_3891);\n        }\n        float _3914 = _3902 - _378.fa_fog_b.x;\n        if (_3914 > 0.0)\n        {\n            float _3923 = _378.fa_fog.w * _3914;\n            float tau = _3923 * _3923;\n            if (_378.fa_fog_b.y > 0.0)\n            {\n                float _3939;\n                if (_3901)\n                {\n                    _3939 = in.fa_world_pos.y - (_378.fa_fog_c.y * _3897);\n                }\n                else\n                {\n                    _3939 = _378.fa_camera_pos.y;\n                }\n                float _3960 = mix(_3939, in.fa_world_pos.y, fast::clamp(_378.fa_fog_b.x / _3902, 0.0, 1.0));\n                float _3964 = in.fa_world_pos.y - _3960;\n                float _3969 = _3960 - _378.fa_fog_b.z;\n                float _3974 = in.fa_world_pos.y - _378.fa_fog_b.z;\n                bool _3977 = _3969 <= 0.0;\n                bool _3978 = !_3977;\n                bool _3984;\n                if (_3978)\n                {\n                    _3984 = _378.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3984 = _3977;\n                }\n                float _3985;\n                if (_3984)\n                {\n                    _3985 = _378.fa_fog_b.y;\n                }\n                else\n                {\n                    _3985 = _378.fa_fog_b.y * exp(-fast::min(_378.fa_fog_b.w * _3969, 80.0));\n                }\n                bool _4012;\n                if (_3978)\n                {\n                    _4012 = _378.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4012 = _3977;\n                }\n                float _4013;\n                if (_4012)\n                {\n                    _4013 = _378.fa_fog_b.y * _3969;\n                }\n                else\n                {\n                    _4013 = (_378.fa_fog_b.y * (1.0 - exp(-fast::min(_378.fa_fog_b.w * _3969, 80.0)))) / _378.fa_fog_b.w;\n                }\n                bool _4038 = _3974 <= 0.0;\n                bool _4045;\n                if (!_4038)\n                {\n                    _4045 = _378.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4045 = _4038;\n                }\n                float _4046;\n                if (_4045)\n                {\n                    _4046 = _378.fa_fog_b.y * _3974;\n                }\n                else\n                {\n                    _4046 = (_378.fa_fog_b.y * (1.0 - exp(-fast::min(_378.fa_fog_b.w * _3974, 80.0)))) / _378.fa_fog_b.w;\n                }\n                float _4073;\n                if (abs(_3964) < 0.001000000047497451305389404296875)\n                {\n                    _4073 = _3985;\n                }\n                else\n                {\n                    _4073 = (_4046 - _4013) / _3964;\n                }\n                tau += (_3914 * fast::max(_4073, 0.0));\n            }\n            result = mix(result, _378.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _4197);\n    return out;\n}\n\n",
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
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_378",
            "msl_buffer_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2035",
            "msl_buffer_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_3368",
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
            "name": "fa_env_tex_fa_env_smp",
            "view_name": "fa_env_tex",
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
          }
        ]
      }
    },
    "mesh_skin": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float3 fa_lm [[user(locn5)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n    float4 fa_joints [[attribute(9)]];\n    float4 fa_weights [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _183)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_183.fa_joint_rows[_174] * weights[i]);\n        r1 += (_183.fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183.fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _136);\n    float3 _391 = _273.world_pos;\n    fa_world_pos = _391;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = _136.fa_view_proj * float4(_391, 1.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _136 [[buffer(0)]], constant fa_skin& _183 [[buffer(3)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float4x4 param_2 = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _183);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7, _136, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.gl_Position);\n    out.fa_lm = float3(0.0);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n#pragma clang diagnostic ignored \"-Wmissing-braces\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\ntemplate<typename T, size_t Num>\nstruct spvUnsafeArray\n{\n    T elements[Num ? Num : 1];\n    \n    thread T& operator [] (size_t pos) thread\n    {\n        return elements[pos];\n    }\n    constexpr const thread T& operator [] (size_t pos) const thread\n    {\n        return elements[pos];\n    }\n    \n    device T& operator [] (size_t pos) device\n    {\n        return elements[pos];\n    }\n    constexpr const device T& operator [] (size_t pos) const device\n    {\n        return elements[pos];\n    }\n    \n    constexpr const constant T& operator [] (size_t pos) const constant\n    {\n        return elements[pos];\n    }\n    \n    threadgroup T& operator [] (size_t pos) threadgroup\n    {\n        return elements[pos];\n    }\n    constexpr const threadgroup T& operator [] (size_t pos) const threadgroup\n    {\n        return elements[pos];\n    }\n};\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n    float4 fa_shadow_lcfg;\n};\n\nstruct fa_material\n{\n    float dark;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float3 fa_lm [[user(locn5)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_cluster_texel(thread const float3& world_pos, constant fa_mesh_fs_params& _378, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    bool _1306 = _378.fa_cl_info.x < 0.0;\n    bool _1313;\n    if (!_1306)\n    {\n        _1313 = _378.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _1313 = _1306;\n    }\n    bool _1321;\n    if (!_1313)\n    {\n        _1321 = _378.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _1321 = _1313;\n    }\n    bool _1328;\n    if (!_1321)\n    {\n        _1328 = _378.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _1328 = _1321;\n    }\n    bool _1335;\n    if (!_1328)\n    {\n        _1335 = _378.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _1335 = _1328;\n    }\n    if (_1335)\n    {\n        return float4(0.0);\n    }\n    float4 _1345 = float4(world_pos, 1.0);\n    float _1351 = dot(_378.fa_cl_vpw, _1345);\n    if (!(_1351 > 9.9999999747524270787835121154785e-07))\n    {\n        return float4(0.0);\n    }\n    float2 _1373 = float2(dot(_378.fa_cl_vpx, _1345), dot(_378.fa_cl_vpy, _1345)) / float2(_1351);\n    int _1377 = int(_378.fa_cl_grid.x);\n    int _1381 = int(_378.fa_cl_grid.y);\n    int param = (int(_378.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_378.fa_cl_fwd.xyz, world_pos) + _378.fa_cl_fwd.w, _378.fa_cl_grid.w) / _378.fa_cl_grid.w) * _378.fa_cl_grid.z)), 0, int(_378.fa_cl_info.y) - 1) * _1381) + clamp(int(floor(((_1373.y * 0.5) + 0.5) * _378.fa_cl_grid.y)), 0, _1381 - 1)) * _1377)) + clamp(int(floor(((_1373.x * 0.5) + 0.5) * _378.fa_cl_grid.x)), 0, _1377 - 1);\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, constant fa_mesh_fs_params& _378, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    float3 param = world_pos;\n    float4 _1457 = fa_cluster_texel(param, _378, fa_light_tex, fa_shadow_smp);\n    return int2(int(_1457.x), int(_1457.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, constant fa_mesh_fs_params& _378, texture2d<float> fa_light_tex, sampler fa_shadow_smp, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_378.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _3235 = fa_cluster_lookup(param, _378, fa_light_tex, fa_shadow_smp);\n    fa_cl_slot = _3235.x;\n    fa_cl_local = _3235.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _3417 = fa_linear_to_srgb(param);\n        c = _3417;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _3425 = fa_srgb_to_linear(param_1);\n            c = _3425;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _261;\n    if (bool(i.front_facing))\n    {\n        _261 = i.world_normal;\n    }\n    else\n    {\n        _261 = -i.world_normal;\n    }\n    float3 _285 = fast::normalize(i.world_tangent.xyz - (_261 * dot(_261, i.world_tangent.xyz)));\n    float3 _312 = fast::normalize(((_285 * m.x) + ((cross(_261, _285) * i.world_tangent.w) * m.y)) + (_261 * m.z));\n    float3 _315;\n    if (bool(i.front_facing))\n    {\n        _315 = _312;\n    }\n    else\n    {\n        _315 = -_312;\n    }\n    return _315;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _378, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _378.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _3456 = fa_tex_fix(param_2, param_3);\n    float4 _4479 = base_t;\n    _4479.x = _3456.x;\n    _4479.y = _3456.y;\n    _4479.z = _3456.z;\n    base_t = _4479;\n    float4 _3470 = (_4479 * _378.fa_base_color) * i.vertex_color;\n    float3 _4344 = i.world_normal;\n    if (_378.fa_maps.z > 0.5)\n    {\n        float param_4 = _378.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _3502 = fa_tex_fix(param_6, param_7);\n        float3 _3505 = (_3502 * 2.0) - float3(1.0);\n        float2 _3510 = _3505.xy * _378.fa_maps.x;\n        float3 _4487 = _3505;\n        _4487.x = _3510.x;\n        _4487.y = _3510.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _4487;\n        _4344 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _378.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _3538 = fa_tex_fix(param_12, param_13);\n    float4 _4490 = mrt;\n    _4490.x = _3538.x;\n    _4490.y = _3538.y;\n    _4490.z = _3538.z;\n    mrt = _4490;\n    float4 _3566 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _378.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _3566.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _3577 = fa_tex_fix(param_16, param_17);\n    float param_18 = _378.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _3607 = fa_tex_fix(param_20, param_21);\n    float _4349 = _378.fa_layers_a.x;\n    float _4350 = _378.fa_layers_a.y;\n    float _4353 = _378.fa_layers_a.z;\n    float _4352 = _378.fa_layers_b.w;\n    float _4355 = _378.fa_layers_c.x;\n    if (_378.fa_layers_c.z > 0.5)\n    {\n        if (mod(_378.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _4349 *= _3577.y;\n            _4350 *= _3577.z;\n            _4352 *= _3566.w;\n        }\n        if (_378.fa_layers_c.z > 1.5)\n        {\n            _4353 *= mrt.x;\n            _4355 *= mrt.w;\n        }\n    }\n    return Surface{ _3470.xyz, _3470.w, _4344, fast::clamp(_378.fa_pbr.x * _3538.z, 0.0, 1.0), fast::clamp(_378.fa_pbr.y * _3538.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_378.fa_maps.y * (_3577.x - 1.0)), _378.fa_emissive.xyz + (_378.fa_model_emissive.xyz * _3607), _4349, _4350, _378.fa_layers_b.xyz, _4352, _4353, _378.fa_layers_a.w, _4355, _378.fa_layers_c.y, _378.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_decal_tile(thread const float4& rect, thread const float2& uv, thread const float2& atlas, thread const float2& ddx, thread const float2& ddy, sampler fa_env_smp, texture2d<float> fa_decal_tex)\n{\n    float2 _1537 = rect.zw - rect.xy;\n    float2 _1541 = _1537 * atlas;\n    float2 _1545 = ddx * _1541;\n    float2 _1549 = ddy * _1541;\n    return fa_decal_tex.sample(fa_env_smp, (rect.xy + (fast::clamp(uv, float2(0.0), float2(1.0)) * _1537)), level(fast::clamp(0.5 * log2(fast::max(fast::max(dot(_1545, _1545), dot(_1549, _1549)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_apply_decals(thread const float3& world_pos, thread const float3& geo_normal, thread float3& albedo, thread float3& normal, constant fa_mesh_fs_params& _378, texture2d<float> fa_light_tex, sampler fa_shadow_smp, sampler fa_env_smp, texture2d<float> fa_decal_tex)\n{\n    bool _1582 = _378.fa_counts.y < 0.5;\n    bool _1589;\n    if (!_1582)\n    {\n        _1589 = _378.fa_counts.w < 0.5;\n    }\n    else\n    {\n        _1589 = _1582;\n    }\n    if (_1589)\n    {\n        return;\n    }\n    float3 _1595 = dfdx(world_pos);\n    float3 _1598 = dfdy(world_pos);\n    float3 param = world_pos;\n    float4 _1602 = fa_cluster_texel(param, _378, fa_light_tex, fa_shadow_smp);\n    int _1606 = int(_1602.w);\n    if (_1606 < 1)\n    {\n        return;\n    }\n    int _1616 = int(_378.fa_counts.y + 0.5);\n    int param_1 = _1616;\n    float4 _1620 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float2 _1623 = _1620.yz;\n    int _1627 = int(_1620.w);\n    int param_2 = _1616 + 1;\n    float4 _1632 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float _1633 = _1632.x;\n    int _1639 = int(_378.fa_counts.w + 0.5) - 1;\n    int _1643 = int(_1602.z);\n    float3 _1908;\n    for (int k = 0; k < _1606; k++)\n    {\n        int _1656 = _1643 + k;\n        int param_3 = _1627 + (_1656 >> 2);\n        int _1673 = (_1616 + 2) + (int(fa_light_texel(param_3, fa_light_tex, fa_shadow_smp)[_1656 & 3]) * 7);\n        int param_4 = _1673 + 6;\n        float4 _1678 = fa_light_texel(param_4, fa_light_tex, fa_shadow_smp);\n        if (((int(_1678.w + 0.5) >> _1639) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1673;\n        float4 _1693 = fa_light_texel(param_5, fa_light_tex, fa_shadow_smp);\n        int param_6 = _1673 + 1;\n        float4 _1698 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n        int param_7 = _1673 + 2;\n        float4 _1703 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n        float3 _1706 = _1693.xyz;\n        float _1711 = dot(_1706, world_pos) + _1693.w;\n        float3 _1713 = _1698.xyz;\n        float _1718 = dot(_1713, world_pos) + _1698.w;\n        float3 _1720 = _1703.xyz;\n        float _1725 = dot(_1720, world_pos) + _1703.w;\n        bool _1730 = abs(_1711) > 0.5;\n        bool _1738;\n        if (!_1730)\n        {\n            _1738 = abs(_1718) > 0.5;\n        }\n        else\n        {\n            _1738 = _1730;\n        }\n        bool _1746;\n        if (!_1738)\n        {\n            _1746 = abs(_1725) > 0.5;\n        }\n        else\n        {\n            _1746 = _1738;\n        }\n        if (_1746)\n        {\n            continue;\n        }\n        float _1761 = fast::clamp(dot(geo_normal, fast::normalize(_1720)) * _1678.z, 0.0, 1.0);\n        if (_1761 <= 0.0)\n        {\n            continue;\n        }\n        float _1781 = (fast::clamp((0.5 - abs(_1725)) * 10.0, 0.0, 1.0) * _1761) * _1678.x;\n        float2 _1789 = float2(_1711 + 0.5, 0.5 - _1718);\n        float2 _1799 = float2(dot(_1706, _1595), dot(_1713, _1595));\n        float2 _1809 = float2(dot(_1706, _1598), dot(_1713, _1598));\n        int param_8 = _1673 + 5;\n        float4 _1814 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n        int param_9 = _1673 + 3;\n        float4 _1819 = fa_light_texel(param_9, fa_light_tex, fa_shadow_smp);\n        int param_10 = _1673 + 4;\n        float4 _1824 = fa_light_texel(param_10, fa_light_tex, fa_shadow_smp);\n        float tex_a = 1.0;\n        float3 col = _1814.xyz;\n        bool _1834 = _1819.z > _1819.x;\n        if (_1834)\n        {\n            float4 param_11 = _1819;\n            float2 param_12 = _1789;\n            float2 param_13 = _1623;\n            float2 param_14 = _1799;\n            float2 param_15 = _1809;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15, fa_env_smp, fa_decal_tex);\n            if ((_1633 > 0.5) && (_1633 < 1.5))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1860 = fa_dc_to_linear(param_16);\n                float4 _4424 = tx;\n                _4424.x = _1860.x;\n                _4424.y = _1860.y;\n                _4424.z = _1860.z;\n                tx = _4424;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, float3(fast::clamp((_1781 * tex_a) * _1814.w, 0.0, 1.0)));\n        if (_1824.z > _1824.x)\n        {\n            float4 param_17 = _1824;\n            float2 param_18 = _1789;\n            float2 param_19 = _1623;\n            float2 param_20 = _1799;\n            float2 param_21 = _1809;\n            float4 _1904 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21, fa_env_smp, fa_decal_tex);\n            if (_1633 > 1.5)\n            {\n                float3 param_22 = _1904.xyz;\n                float3 _1914 = fa_dc_to_srgb(param_22);\n                _1908 = _1914;\n            }\n            else\n            {\n                _1908 = _1904.xyz;\n            }\n            float3 _1923 = (_1908 * 2.0) - float3(1.0);\n            float2 _1928 = _1923.xy * _1678.y;\n            float3 _1950 = (fast::normalize(_1706) * _1928.x) + (fast::normalize(_1713) * _1928.y);\n            float3 _1953 = fast::normalize(normal);\n            normal = fast::normalize(mix(_1953, fast::normalize((_1953 * fast::max(_1923.z, 0.0500000007450580596923828125)) + (_1950 - (_1953 * dot(_1953, _1950)))), float3(fast::clamp(_1781 * (_1834 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_sh_coef(thread const int& k, constant fa_mesh_fs_params& _378, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float3 v = fa_env_tex.sample(fa_env_smp, float3(1.0, 1.0 - (float((2 * (k >> 2)) + 1) * 0.25), 1.0 - (float((2 * (k & 3)) + 1) * 0.25)), level(5.0)).xyz;\n    if (_378.fa_env_sky.w > 1.5)\n    {\n        v = (v - float3(0.5)) * 8.0;\n    }\n    return v;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sh_eval(thread const spvUnsafeArray<float3, 9>& c, thread const float3& n)\n{\n    float3 _3148 = fast::max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), float3(0.0));\n    return _3148;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _378, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    if (_378.fa_env_sky.w > 0.5)\n    {\n        spvUnsafeArray<float3, 9> c;\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param, _378, fa_env_smp, fa_env_tex);\n        }\n        spvUnsafeArray<float3, 9> param_1 = c;\n        float3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return _378.fa_ambient.xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_indirect_diffuse(thread const float3& n, constant fa_mesh_fs_params& _378, sampler fa_env_smp, texturecube<float> fa_env_tex, thread float3& fa_lm, texture2d<float> fa_lightmap)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return fa_lightmap.sample(fa_env_smp, fa_lm.xy, level(0.0)).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param, _378, fa_env_smp, fa_env_tex);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, constant fa_mesh_fs_params& _378, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (int(_378.fa_cl_info.x) + int(_378.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, constant fa_mesh_fs_params& _378, texture2d<float> fa_light_tex, sampler fa_shadow_smp, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, _378, fa_light_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_light_base(thread const int& li, constant fa_mesh_fs_params& _378)\n{\n    return li * ((_378.fa_ambient.w > 4.5) ? 8 : 4);\n}\n\nstatic inline __attribute__((always_inline))\nbool fa_light_baked(thread const int& li, constant fa_mesh_fs_params& _378, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li;\n    int param_1 = fa_light_base(param, _378) + 3;\n    return fa_light_texel(param_1, fa_light_tex, fa_shadow_smp).w > 0.5;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_light_type(thread const int& li, constant fa_mesh_fs_params& _378, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li;\n    int param_1 = fa_light_base(param, _378) + 1;\n    return fa_light_texel(param_1, fa_light_tex, fa_shadow_smp).w;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_atlas_fetch(thread const float2& texel, texture2d<float> fa_light_atlas, sampler fa_env_smp)\n{\n    return fa_light_atlas.sample(fa_env_smp, (texel / float2(int2(fa_light_atlas.get_width(), fa_light_atlas.get_height()))), level(0.0));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_cookie_sample(thread const float2& tile_origin, thread const float2& uv, texture2d<float> fa_light_atlas, sampler fa_env_smp)\n{\n    float2 param = (tile_origin + float2(1.0)) + (fast::clamp(uv, float2(0.0), float2(1.0)) * 254.0);\n    return fa_atlas_fetch(param, fa_light_atlas, fa_env_smp).xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_area_point(thread const float3& c, thread const float3& axis, thread const float3& ru, thread const float3& uu, thread const float& hx, thread const float& hy, thread const float& shape, thread const float3& p, thread const float3& r)\n{\n    bool _556 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        float3 _569 = (c - (ru * hx)) - p;\n        float3 _575 = ru * (2.0 * hx);\n        float _581 = fast::max(dot(_575, _575), 9.9999999392252902907785028219223e-09);\n        float _585 = dot(_569, _575);\n        float t = fast::clamp((-_585) / _581, 0.0, 1.0);\n        if (_556)\n        {\n            float _600 = dot(r, _575);\n            float _606 = _581 - (_600 * _600);\n            if (abs(_606) > (9.9999997473787516355514526367188e-06 * _581))\n            {\n                t = fast::clamp(((dot(r, _569) * _600) - _585) / _606, 0.0, 1.0);\n            }\n        }\n        return (p + _569) + (_575 * t);\n    }\n    float3 q = p;\n    float _638 = dot(r, axis);\n    bool _646;\n    if (_556)\n    {\n        _646 = abs(_638) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _646 = _556;\n    }\n    if (_646)\n    {\n        float _656 = dot(c - p, axis) / _638;\n        if (_656 > 0.0)\n        {\n            q = p + (r * _656);\n        }\n    }\n    float3 _669 = q - c;\n    float2 xy = float2(dot(_669, ru), dot(_669, uu));\n    if (shape > 0.5)\n    {\n        float _684 = length(xy);\n        if (_684 > hx)\n        {\n            xy *= (hx / _684);\n        }\n    }\n    else\n    {\n        xy = fast::clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cube_face(thread const float3& d)\n{\n    float3 _327 = abs(d);\n    float _329 = _327.x;\n    float _331 = _327.y;\n    bool _332 = _329 >= _331;\n    bool _340;\n    if (_332)\n    {\n        _340 = _329 >= _327.z;\n    }\n    else\n    {\n        _340 = _332;\n    }\n    int _341;\n    if (_340)\n    {\n        _341 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _356;\n        if (_331 >= _327.z)\n        {\n            _356 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _356 = (d.z > 0.0) ? 4 : 5;\n        }\n        _341 = _356;\n    }\n    return _341;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cube_face_basis(thread const int& f, thread float3& fwd, thread float3& up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0, 0.0, 0.0);\n        up = float3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0, 0.0, 0.0);\n            up = float3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0, 1.0, 0.0);\n                up = float3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0, -1.0, 0.0);\n                    up = float3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0, 0.0, 1.0);\n                        up = float3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0, 0.0, -1.0);\n                        up = float3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_ies_sample(thread const float2& tile_origin, thread const float3& d, thread const float3& axis, thread const float3& right, thread const float3& up, texture2d<float> fa_light_atlas, sampler fa_env_smp)\n{\n    float _476 = dot(d, right);\n    float _480 = dot(d, up);\n    float _491;\n    if (((_476 * _476) + (_480 * _480)) > 1.0000000133514319600180897396058e-10)\n    {\n        _491 = precise::atan2(_480, _476) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _491 = 0.0;\n    }\n    float2 param = tile_origin + float2(1.0 + ((_491 - floor(_491)) * 64.0), 1.0 + (acos(fast::clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param, fa_light_atlas, fa_env_smp).x;\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample_n(thread const int& li, thread const float3& world_pos, thread const float3& n, constant fa_mesh_fs_params& _378, texture2d<float> fa_light_tex, sampler fa_shadow_smp, texture2d<float> fa_light_atlas, sampler fa_env_smp, thread float3& fa_light_tint, thread bool& fa_light_is_area)\n{\n    int param = li;\n    int _722 = fa_light_base(param, _378);\n    bool _726 = _378.fa_ambient.w > 4.5;\n    int param_1 = _722;\n    float4 _730 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    int param_2 = _722 + 1;\n    float4 _735 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float _738 = _735.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = float3(1.0);\n    bool _750 = _726 && (_738 > 2.5);\n    fa_light_is_area = _750;\n    bool _752 = _738 < 0.5;\n    float3 l;\n    if (_752)\n    {\n        l = fast::normalize(_730.xyz);\n        if (_726)\n        {\n            int param_3 = _722 + 6;\n            float4 _766 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            if (_766.z > 0.5)\n            {\n                int param_4 = _722 + 4;\n                float4 _776 = fa_light_texel(param_4, fa_light_tex, fa_shadow_smp);\n                int param_5 = _722 + 5;\n                float4 _781 = fa_light_texel(param_5, fa_light_tex, fa_shadow_smp);\n                float2 param_6 = _766.xy;\n                float2 param_7 = fract(float2(dot(world_pos, _776.xyz) * _776.w, (-dot(world_pos, _781.xyz)) * _781.w) + float2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7, fa_light_atlas, fa_env_smp);\n            }\n        }\n    }\n    else\n    {\n        float3 _811 = _730.xyz;\n        float3 _813 = _811 - world_pos;\n        float3 to_light = _813;\n        float _816 = length(_813);\n        float reach = _816;\n        bool front = true;\n        if (_750)\n        {\n            int param_8 = _722 + 7;\n            reach = fast::max(_816 - fa_light_texel(param_8, fa_light_tex, fa_shadow_smp).w, 0.0);\n            int param_9 = _722 + 4;\n            float4 _840 = fa_light_texel(param_9, fa_light_tex, fa_shadow_smp);\n            int param_10 = _722 + 5;\n            float4 _845 = fa_light_texel(param_10, fa_light_tex, fa_shadow_smp);\n            int param_11 = _722 + 6;\n            float4 _850 = fa_light_texel(param_11, fa_light_tex, fa_shadow_smp);\n            float _851 = _850.w;\n            int param_12 = _722 + 2;\n            float3 _858 = fast::normalize(fa_light_texel(param_12, fa_light_tex, fa_shadow_smp).xyz);\n            bool _860 = _851 > 1.5;\n            bool _868;\n            if (!_860)\n            {\n                _868 = dot(_858, to_light) < 0.0;\n            }\n            else\n            {\n                _868 = _860;\n            }\n            front = _868;\n            float3 r = float3(0.0);\n            float3 _877 = _378.fa_camera_pos.xyz - world_pos;\n            bool _881 = dot(n, n) > 0.5;\n            bool _889;\n            if (_881)\n            {\n                _889 = dot(_877, _877) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _889 = _881;\n            }\n            if (_889)\n            {\n                r = reflect(-fast::normalize(_877), fast::normalize(n));\n            }\n            float3 param_13 = _811;\n            float3 param_14 = _858;\n            float3 param_15 = _840.xyz;\n            float3 param_16 = _845.xyz;\n            float param_17 = _840.w;\n            float param_18 = _845.w;\n            float param_19 = _851;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _925 = length(to_light);\n        dist = _925;\n        l = to_light / float3(fast::max(_925, 9.9999997473787516355514526367188e-05));\n        float _939 = reach / fast::max(_730.w, 0.001000000047497451305389404296875);\n        float _945 = fast::clamp(1.0 - (_939 * _939), 0.0, 1.0);\n        float _947;\n        if (front)\n        {\n            _947 = _945 * _945;\n        }\n        else\n        {\n            _947 = 0.0;\n        }\n        atten = _947;\n        bool _958 = _738 < 2.5;\n        if ((_738 > 1.5) && _958)\n        {\n            int param_22 = _722 + 2;\n            float4 _966 = fa_light_texel(param_22, fa_light_tex, fa_shadow_smp);\n            float _976 = _966.w;\n            int param_23 = _722 + 3;\n            float4 _981 = fa_light_texel(param_23, fa_light_tex, fa_shadow_smp);\n            float _982 = _981.x;\n            float cos_inner = _982;\n            if (_982 > 1.5)\n            {\n                cos_inner = mix(_976, 1.0, 0.25);\n            }\n            atten *= smoothstep(_976, cos_inner, dot(-l, fast::normalize(_966.xyz)));\n        }\n        if (_726 && (_738 < 1.5))\n        {\n            int param_24 = _722 + 6;\n            float4 _1006 = fa_light_texel(param_24, fa_light_tex, fa_shadow_smp);\n            if (_1006.z > 0.5)\n            {\n                float3 _1014 = -to_light;\n                int param_25 = _722 + 4;\n                int param_26 = _722 + 5;\n                float3 _1028 = fa_light_texel(param_25, fa_light_tex, fa_shadow_smp).xyz;\n                float3 _1032 = fa_light_texel(param_26, fa_light_tex, fa_shadow_smp).xyz;\n                float3 _1041 = float3(dot(_1014, _1028), dot(_1014, _1032), dot(_1014, cross(_1028, _1032)));\n                float3 param_27 = _1041;\n                int _1045 = fa_cube_face(param_27);\n                int param_28 = _1045;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1072 = float2(dot(_1041, cross(param_29, param_30)), dot(_1041, param_30)) / float2(fast::max(dot(_1041, param_29), 9.9999997473787516355514526367188e-05));\n                int _1076 = _1045 / 3;\n                float2 param_31 = _1006.xy + (float2(float(_1045 - (_1076 * 3)), float(_1076)) * 256.0);\n                float2 param_32 = float2(0.5 + (0.5 * _1072.x), 0.5 - (0.5 * _1072.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32, fa_light_atlas, fa_env_smp);\n            }\n            int param_33 = _722 + 7;\n            float4 _1106 = fa_light_texel(param_33, fa_light_tex, fa_shadow_smp);\n            if (_1106.z > 0.5)\n            {\n                int param_34 = _722 + 2;\n                int param_35 = _722 + 4;\n                int param_36 = _722 + 5;\n                float2 param_37 = _1106.xy;\n                float3 param_38 = -l;\n                float3 param_39 = fast::normalize(fa_light_texel(param_34, fa_light_tex, fa_shadow_smp).xyz);\n                float3 param_40 = fa_light_texel(param_35, fa_light_tex, fa_shadow_smp).xyz;\n                float3 param_41 = fa_light_texel(param_36, fa_light_tex, fa_shadow_smp).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41, fa_light_atlas, fa_env_smp);\n            }\n        }\n        else\n        {\n            if (_726 && _958)\n            {\n                int param_42 = _722 + 6;\n                float4 _1153 = fa_light_texel(param_42, fa_light_tex, fa_shadow_smp);\n                int param_43 = _722 + 7;\n                float4 _1158 = fa_light_texel(param_43, fa_light_tex, fa_shadow_smp);\n                bool _1161 = _1153.z > 0.5;\n                bool _1168;\n                if (!_1161)\n                {\n                    _1168 = _1158.z > 0.5;\n                }\n                else\n                {\n                    _1168 = _1161;\n                }\n                if (_1168)\n                {\n                    int param_44 = _722 + 2;\n                    float4 _1175 = fa_light_texel(param_44, fa_light_tex, fa_shadow_smp);\n                    float3 _1179 = fast::normalize(_1175.xyz);\n                    int param_45 = _722 + 4;\n                    float4 _1184 = fa_light_texel(param_45, fa_light_tex, fa_shadow_smp);\n                    int param_46 = _722 + 5;\n                    float4 _1189 = fa_light_texel(param_46, fa_light_tex, fa_shadow_smp);\n                    if (_1161)\n                    {\n                        float3 _1197 = -to_light;\n                        float _1204 = _1175.w;\n                        float _1220 = 0.5 / fast::max(dot(_1197, _1179) * (sqrt(fast::max(1.0 - (_1204 * _1204), 0.0)) / fast::max(_1204, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        float2 param_47 = _1153.xy;\n                        float2 param_48 = float2(0.5 + (dot(_1197, _1184.xyz) * _1220), 0.5 - (dot(_1197, _1189.xyz) * _1220));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48, fa_light_atlas, fa_env_smp);\n                    }\n                    if (_1158.z > 0.5)\n                    {\n                        float2 param_49 = _1158.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1179;\n                        float3 param_52 = _1184.xyz;\n                        float3 param_53 = _1189.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53, fa_light_atlas, fa_env_smp);\n                    }\n                }\n            }\n        }\n    }\n    float3 _4298 = _735.xyz * atten;\n    if (_726)\n    {\n        _4298 *= fa_light_tint;\n    }\n    int _1288;\n    if (_752)\n    {\n        _1288 = 0;\n    }\n    else\n    {\n        _1288 = ((_738 > 1.5) && (_738 < 2.5)) ? 2 : 1;\n    }\n    return LightSample{ l, _4298, atten, 1.0, dist, _1288 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _2035)\n{\n    float _2025;\n    if (i == 0)\n    {\n        _2025 = _2035.fa_shadow_split.x;\n    }\n    else\n    {\n        float _2041;\n        if (i == 1)\n        {\n            _2041 = _2035.fa_shadow_split.y;\n        }\n        else\n        {\n            float _2049;\n            if (i == 2)\n            {\n                _2049 = _2035.fa_shadow_split.z;\n            }\n            else\n            {\n                _2049 = _2035.fa_shadow_split.w;\n            }\n            _2041 = _2049;\n        }\n        _2025 = _2041;\n    }\n    return _2025;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_fetch(thread const float2& uv, thread const float4& rect, thread const float3& conv, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2082 = fa_shadow_depth(param, param_1, fa_shadow_smp, fa_shadow_tex);\n    float _2086;\n    if (conv.x < 0.5)\n    {\n        _2086 = _2082;\n    }\n    else\n    {\n        _2086 = (conv.y * conv.z) / (conv.z - (_2082 * (conv.z - conv.y)));\n    }\n    return _2086;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _2013 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_2013), sin(_2013)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_filter(thread const float2& uv, thread const float4& rect, thread const float& zr, thread const float& texel_m, thread const float& unit, thread const float& reach, thread const float& plane, thread const float3& conv, thread const int& mode, thread const float& k, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2035, texture2d<float> fa_shadow_tex)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2, fa_shadow_smp, fa_shadow_tex));\n    }\n    float _2132 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2141;\n        if (k < 0.0)\n        {\n            _2141 = (-k) / fast::max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2141 = k;\n        }\n        float _2161 = fast::clamp((_2141 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2132;\n            float2 _2180 = fa_shadow_vogel(param_3, param_4, param_5) * _2161;\n            float2 param_6 = uv + (_2180 * _2035.fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _2192 = fa_shadow_fetch(param_6, param_7, param_8, fa_shadow_smp, fa_shadow_tex);\n            if (_2192 < (zr - (length(_2180) * plane)))\n            {\n                sum += _2192;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2218 = sum / cnt;\n        float _2228;\n        if (k < 0.0)\n        {\n            _2228 = (-k) / fast::max(_2218, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2228 = k;\n        }\n        radius = fast::clamp(((fast::max(zr - _2218, 0.0) * unit) * _2228) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _2250 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2250; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2250;\n        float param_11 = _2132;\n        float2 _2269 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_2269 * _2035.fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_2269) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14, fa_shadow_smp, fa_shadow_tex));\n    }\n    return lit / float(_2250);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2035, texture2d<float> fa_shadow_tex)\n{\n    float _2311 = fast::max(_2035.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _2316 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _2322 = sqrt(1.0 - (_2316 * _2316));\n    float _2329 = fast::min(_2322 / fast::max(_2316, 0.20000000298023223876953125), 4.0);\n    float _2334;\n    if (_2035.fa_shadow_bias.y > 0.0)\n    {\n        _2334 = _2035.fa_shadow_bias.y;\n    }\n    else\n    {\n        _2334 = 1.5 * _2035.fa_shadow_info[ci].x;\n    }\n    float4 _2359 = _2035.fa_shadow_mat[ci] * float4(world + (n * (_2334 * _2322)), 1.0);\n    float _2366 = _2359.x;\n    bool _2369 = _2366 < _2035.fa_shadow_rect[ci].x;\n    bool _2378;\n    if (!_2369)\n    {\n        _2378 = _2366 > _2035.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2378 = _2369;\n    }\n    bool _2387;\n    if (!_2378)\n    {\n        _2387 = _2359.y < _2035.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2387 = _2378;\n    }\n    bool _2396;\n    if (!_2387)\n    {\n        _2396 = _2359.y > _2035.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2396 = _2387;\n    }\n    bool _2403;\n    if (!_2396)\n    {\n        _2403 = _2359.z > 1.0;\n    }\n    else\n    {\n        _2403 = _2396;\n    }\n    if (_2403)\n    {\n        return -1.0;\n    }\n    float _2411;\n    if (_2035.fa_shadow_bias.x > 0.0)\n    {\n        _2411 = _2035.fa_shadow_bias.x;\n    }\n    else\n    {\n        _2411 = 1.5 * _2035.fa_shadow_info[ci].x;\n    }\n    float2 param = _2359.xy;\n    float4 param_1 = _2035.fa_shadow_rect[ci];\n    float param_2 = _2359.z - ((_2411 * (1.0 + (0.5 * _2329))) / _2311);\n    float param_3 = _2035.fa_shadow_info[ci].x;\n    float param_4 = _2311;\n    float param_5 = _2311 * 0.25;\n    float param_6 = ((_2035.fa_shadow_info[ci].x * fast::min(_2329, 3.0)) * 0.5) / _2311;\n    float3 param_7 = float3(0.0);\n    int param_8 = int(_2035.fa_shadow_cfg.z + 0.5);\n    float param_9 = _2035.fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9, fa_shadow_smp, gl_FragCoord, _2035, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _378, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2035, texture2d<float> fa_shadow_tex)\n{\n    if (_378.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2789 = int(_2035.fa_shadow_cfg.x + 0.5);\n    if (_2789 < 1)\n    {\n        return 1.0;\n    }\n    float _2804 = dot(world - _2035.fa_shadow_eye.xyz, _2035.fa_shadow_fwd.xyz);\n    int param = _2789 - 1;\n    if (_2804 > fa_shadow_split_at(param, _2035))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2816 = _2789 > 1;\n    bool _2823;\n    if (_2816)\n    {\n        _2823 = _2804 > _2035.fa_shadow_split.x;\n    }\n    else\n    {\n        _2823 = _2816;\n    }\n    if (_2823)\n    {\n        ci = 1;\n    }\n    bool _2827 = _2789 > 2;\n    bool _2834;\n    if (_2827)\n    {\n        _2834 = _2804 > _2035.fa_shadow_split.y;\n    }\n    else\n    {\n        _2834 = _2827;\n    }\n    if (_2834)\n    {\n        ci = 2;\n    }\n    bool _2838 = _2789 > 3;\n    bool _2845;\n    if (_2838)\n    {\n        _2845 = _2804 > _2035.fa_shadow_split.z;\n    }\n    else\n    {\n        _2845 = _2838;\n    }\n    if (_2845)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2789)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2871 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_shadow_smp, gl_FragCoord, _2035, fa_shadow_tex);\n        s = _2871;\n        if (_2871 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_2035.fa_shadow_cfg.y > 0.0)\n    {\n        float _2896;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2896 = fa_shadow_split_at(param_5, _2035);\n        }\n        else\n        {\n            _2896 = _2035.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _2915 = _2035.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _2035) - _2896, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2926 = fast::clamp((_2804 - (fa_shadow_split_at(param_7, _2035) - _2915)) / _2915, 0.0, 1.0);\n        if (_2926 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2789)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _2947 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_shadow_smp, gl_FragCoord, _2035, fa_shadow_tex);\n                s2 = _2947;\n                if (_2947 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2926);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _378, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2035, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, _378, fa_shadow_smp, gl_FragCoord, _2035, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_local(thread const int& li, thread const float3& lpos, thread const float3& world, thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _378, texture2d<float> fa_light_tex, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2035, texture2d<float> fa_shadow_tex)\n{\n    bool _2469 = _378.fa_pbr.z < 0.5;\n    bool _2476;\n    if (!_2469)\n    {\n        _2476 = _2035.fa_shadow_lcfg.x < 0.5;\n    }\n    else\n    {\n        _2476 = _2469;\n    }\n    if (_2476)\n    {\n        return 1.0;\n    }\n    int param = (int(_2035.fa_shadow_lcfg.x + 0.5) - 1) + li;\n    float4 _2489 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    float _2490 = _2489.x;\n    if (_2490 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2499 = int(_2490 + 0.5);\n    int param_1 = _2499;\n    float4 _2503 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    int param_2 = _2499 + 1;\n    float4 _2508 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float fade = 1.0;\n    float _2511 = _2503.y;\n    if (_2511 > 0.0)\n    {\n        float _2528 = 1.0 - smoothstep(0.75 * _2511, _2511, length(world - _2035.fa_shadow_eye.xyz));\n        fade = _2528;\n        if (_2528 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2503.x > 1.5)\n    {\n        float3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2552 = (_2499 + 2) + (face * 6);\n    int param_4 = _2552;\n    int param_5 = _2552 + 1;\n    int param_6 = _2552 + 3;\n    float4 _2566 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n    int param_7 = _2552 + 4;\n    float4 _2571 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n    int param_8 = _2552 + 5;\n    float4 _2576 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n    float _2588 = _2576.x * fast::max(dot(_2566, float4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2593 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _2616 = fast::clamp(dot(n, _2566.xyz), -1.0, 1.0);\n    float _2635 = fast::min(sqrt(1.0 - (_2616 * _2616)) / fast::max(abs(dot(n, world - lpos)) / fast::max(dot(_2566, float4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2638 = _2508.y;\n    float _2640;\n    if (_2638 > 0.0)\n    {\n        _2640 = _2638;\n    }\n    else\n    {\n        _2640 = 1.5 * _2588;\n    }\n    float4 _2660 = float4(world + (n * (_2640 * sqrt(1.0 - (_2593 * _2593)))), 1.0);\n    float _2664 = dot(_2566, _2660);\n    float _2667 = _2576.y;\n    if (_2664 < _2667)\n    {\n        return 1.0;\n    }\n    float2 _2682 = float2(dot(fa_light_texel(param_4, fa_light_tex, fa_shadow_smp), _2660), dot(fa_light_texel(param_5, fa_light_tex, fa_shadow_smp), _2660)) / float2(_2664);\n    float _2684 = _2682.x;\n    bool _2687 = _2684 < _2571.x;\n    bool _2696;\n    if (!_2687)\n    {\n        _2696 = _2684 > _2571.z;\n    }\n    else\n    {\n        _2696 = _2687;\n    }\n    bool _2705;\n    if (!_2696)\n    {\n        _2705 = _2682.y < _2571.y;\n    }\n    else\n    {\n        _2705 = _2696;\n    }\n    bool _2714;\n    if (!_2705)\n    {\n        _2714 = _2682.y > _2571.w;\n    }\n    else\n    {\n        _2714 = _2705;\n    }\n    if (_2714)\n    {\n        return 1.0;\n    }\n    float _2720 = _2508.x;\n    float _2722;\n    if (_2720 > 0.0)\n    {\n        _2722 = _2720;\n    }\n    else\n    {\n        _2722 = 1.5 * _2588;\n    }\n    float2 param_9 = _2682;\n    float4 param_10 = _2571;\n    float param_11 = _2664 - (_2722 * (1.0 + (0.5 * _2635)));\n    float param_12 = _2588;\n    float param_13 = 1.0;\n    float param_14 = _2576.z * 0.25;\n    float param_15 = (_2588 * fast::min(_2635, 3.0)) * 0.5;\n    float3 param_16 = float3(1.0, _2667, _2576.z);\n    int param_17 = int(_2503.z + 0.5);\n    float param_18 = _2503.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, fa_shadow_smp, gl_FragCoord, _2035, fa_shadow_tex), fade);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, constant fa_mesh_fs_params& _378, texture2d<float> fa_light_tex, sampler fa_shadow_smp, texture2d<float> fa_light_atlas, sampler fa_env_smp, thread float3& fa_light_tint, thread bool& fa_light_is_area, thread float4& gl_FragCoord, constant fa_shadows& _2035, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos, thread float3& fa_lm)\n{\n    bool _3262 = fa_lm.z > 0.5;\n    bool _3268;\n    if (_3262)\n    {\n        int param = li;\n        _3268 = fa_light_baked(param, _378, fa_light_tex, fa_shadow_smp);\n    }\n    else\n    {\n        _3268 = _3262;\n    }\n    if (_3268)\n    {\n        int param_1 = li;\n        return LightSample{ float3(0.0, 1.0, 0.0), float3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1, _378, fa_light_tex, fa_shadow_smp) + 0.5) };\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _3292 = fa_light_sample_n(param_2, param_3, param_4, _378, fa_light_tex, fa_shadow_smp, fa_light_atlas, fa_env_smp, fa_light_tint, fa_light_is_area);\n    float3 _4324 = _3292.color;\n    float _4326 = _3292.shadow;\n    if ((_3292.type == 0) && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _3292.direction;\n        float _3306 = fa_shadow_factor(param_5, param_6, _378, fa_shadow_smp, gl_FragCoord, _2035, fa_shadow_tex, fa_world_pos);\n        _4326 = _3306;\n        _4324 *= _3306;\n    }\n    else\n    {\n        bool _3317 = _3292.type != 0;\n        bool _3323;\n        if (_3317)\n        {\n            _3323 = _3292.attenuation > 0.0;\n        }\n        else\n        {\n            _3323 = _3317;\n        }\n        if (_3323)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7, _378);\n            int param_9 = li;\n            float3 param_10 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp).xyz;\n            float3 param_11 = world_pos;\n            float3 param_12 = gn;\n            float3 param_13 = _3292.direction;\n            float _3342 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13, _378, fa_light_tex, fa_shadow_smp, gl_FragCoord, _2035, fa_shadow_tex);\n            _4326 = _3342;\n            _4324 *= _3342;\n        }\n    }\n    return LightSample{ _3292.direction, _4324, _3292.attenuation, _4326, _3292._distance, _3292.type };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 light(thread const SurfaceInput& i, thread const Surface& s, thread const LightSample& l, constant fa_material& _3368)\n{\n    float _3362;\n    if (dot(s.normal, l.direction) > 0.5)\n    {\n        _3362 = 1.0;\n    }\n    else\n    {\n        _3362 = _3368.dark;\n    }\n    return (s.albedo * l.color) * _3362;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _2035)\n{\n    if (_2035.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _2971 = int(_2035.fa_shadow_cfg.x + 0.5);\n    float _2981 = dot(world - _2035.fa_shadow_eye.xyz, _2035.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _2986 = _2971 > 0;\n    bool _2995;\n    if (_2986)\n    {\n        int param = _2971 - 1;\n        _2995 = _2981 <= fa_shadow_split_at(param, _2035);\n    }\n    else\n    {\n        _2995 = _2986;\n    }\n    if (_2995)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3001 = _2971 > 1;\n        bool _3008;\n        if (_3001)\n        {\n            _3008 = _2981 > _2035.fa_shadow_split.x;\n        }\n        else\n        {\n            _3008 = _3001;\n        }\n        if (_3008)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3014 = _2971 > 2;\n        bool _3021;\n        if (_3014)\n        {\n            _3021 = _2981 > _2035.fa_shadow_split.y;\n        }\n        else\n        {\n            _3021 = _3014;\n        }\n        if (_3021)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3027 = _2971 > 3;\n        bool _3034;\n        if (_3027)\n        {\n            _3034 = _2981 > _2035.fa_shadow_split.z;\n        }\n        else\n        {\n            _3034 = _3027;\n        }\n        if (_3034)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _378 [[buffer(1)]], constant fa_material& _3368 [[buffer(5)]], constant fa_shadows& _2035 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_env_tex [[texture(6)]], texture2d<float> fa_light_tex [[texture(7)]], texture2d<float> fa_light_atlas [[texture(8)]], texture2d<float> fa_lightmap [[texture(9)]], texture2d<float> fa_decal_tex [[texture(10)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _4165 = fast::normalize(in.fa_world_normal);\n    float3 fa_light_tint;\n    bool fa_light_is_area;\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _4165 = -_4165;\n    }\n    float3 _3750 = fast::normalize(_378.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, _378, fa_light_tex, fa_shadow_smp, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _4165, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _3750, short(gl_FrontFacing) };\n    Surface _3758 = fa_standard_surface(param_1, _378, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _4196 = _3758.albedo;\n    float _4197 = _3758.alpha;\n    float3 _4198 = _3758.normal;\n    float _4199 = _3758.metallic;\n    float _4200 = _3758.roughness;\n    float _4201 = _3758.occlusion;\n    float3 _4202 = _3758.emission;\n    float _4203 = _3758.clearcoat;\n    float _4204 = _3758.clearcoat_roughness;\n    float3 _4205 = _3758.sheen_color;\n    float _4206 = _3758.sheen_roughness;\n    float _4207 = _3758.anisotropy;\n    float _4208 = _3758.anisotropy_rotation;\n    float _4209 = _3758.specular;\n    float _4210 = _3758.ior;\n    float3 _4211 = _3758.specular_color;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _4165, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _3750, short(gl_FrontFacing) };\n    Surface param_3 = _3758;\n    surface(param_2, param_3);\n    _4196 = param_3.albedo;\n    _4197 = param_3.alpha;\n    _4198 = param_3.normal;\n    _4199 = param_3.metallic;\n    _4200 = param_3.roughness;\n    _4201 = param_3.occlusion;\n    _4202 = param_3.emission;\n    _4203 = param_3.clearcoat;\n    _4204 = param_3.clearcoat_roughness;\n    _4205 = param_3.sheen_color;\n    _4206 = param_3.sheen_roughness;\n    _4207 = param_3.anisotropy;\n    _4208 = param_3.anisotropy_rotation;\n    _4209 = param_3.specular;\n    _4210 = param_3.ior;\n    _4211 = param_3.specular_color;\n    float3 param_4 = in.fa_world_pos;\n    float3 param_5 = _4165;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7, _378, fa_light_tex, fa_shadow_smp, fa_env_smp, fa_decal_tex);\n    _4196 = param_6;\n    _4198 = param_7;\n    float3 result;\n    if (_378.fa_emissive.w > 0.5)\n    {\n        result = _4196;\n    }\n    else\n    {\n        float3 _3796 = _4198;\n        float3 _3797 = fast::normalize(_3796);\n        _4198 = _3797;\n        float3 param_8 = _3797;\n        float3 lit = (fa_indirect_diffuse(param_8, _378, fa_env_smp, fa_env_tex, in.fa_lm, fa_lightmap) * _4196) * _4201;\n        int _3816 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _3816; ln++)\n        {\n            int param_9 = ln;\n            int _3829 = fa_cl_light(param_9, _378, fa_light_tex, fa_shadow_smp, fa_cl_ndir, fa_cl_slot);\n            bool _3832 = in.fa_lm.z > 0.5;\n            bool _3838;\n            if (_3832)\n            {\n                int param_10 = _3829;\n                _3838 = fa_light_baked(param_10, _378, fa_light_tex, fa_shadow_smp);\n            }\n            else\n            {\n                _3838 = _3832;\n            }\n            if (_3838)\n            {\n                continue;\n            }\n            int param_11 = _3829;\n            float3 param_12 = in.fa_world_pos;\n            float3 param_13 = _4165;\n            LightSample _3850 = fa_light_shadowed(param_11, param_12, param_13, _378, fa_light_tex, fa_shadow_smp, fa_light_atlas, fa_env_smp, fa_light_tint, fa_light_is_area, gl_FragCoord, _2035, fa_shadow_tex, in.fa_world_pos, in.fa_lm);\n            SurfaceInput param_14 = SurfaceInput{ in.fa_world_pos, _4165, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _3750, short(gl_FrontFacing) };\n            Surface param_15 = Surface{ _4196, _4197, _4198, _4199, _4200, _4201, _4202, _4203, _4204, _4205, _4206, _4207, _4208, _4209, _4210, _4211 };\n            LightSample param_16 = _3850;\n            lit += light(param_14, param_15, param_16, _3368);\n        }\n        result = lit;\n    }\n    float3 _3865 = result;\n    float3 _3866 = _3865 + _4202;\n    result = _3866;\n    float3 param_17 = _3866;\n    float3 param_18 = in.fa_world_pos;\n    result = fa_shadow_debug(param_17, param_18, _2035);\n    bool _3875 = _378.fa_fog.w > 0.0;\n    bool _3882;\n    if (!_3875)\n    {\n        _3882 = _378.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _3882 = _3875;\n    }\n    if (_3882)\n    {\n        float3 _3891 = in.fa_world_pos - _378.fa_camera_pos.xyz;\n        float _3897 = dot(_3891, _378.fa_fog_c.xyz);\n        bool _3901 = _378.fa_fog_c.w > 0.5;\n        float _3902;\n        if (_3901)\n        {\n            _3902 = _3897;\n        }\n        else\n        {\n            _3902 = length(_3891);\n        }\n        float _3914 = _3902 - _378.fa_fog_b.x;\n        if (_3914 > 0.0)\n        {\n            float _3923 = _378.fa_fog.w * _3914;\n            float tau = _3923 * _3923;\n            if (_378.fa_fog_b.y > 0.0)\n            {\n                float _3939;\n                if (_3901)\n                {\n                    _3939 = in.fa_world_pos.y - (_378.fa_fog_c.y * _3897);\n                }\n                else\n                {\n                    _3939 = _378.fa_camera_pos.y;\n                }\n                float _3960 = mix(_3939, in.fa_world_pos.y, fast::clamp(_378.fa_fog_b.x / _3902, 0.0, 1.0));\n                float _3964 = in.fa_world_pos.y - _3960;\n                float _3969 = _3960 - _378.fa_fog_b.z;\n                float _3974 = in.fa_world_pos.y - _378.fa_fog_b.z;\n                bool _3977 = _3969 <= 0.0;\n                bool _3978 = !_3977;\n                bool _3984;\n                if (_3978)\n                {\n                    _3984 = _378.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3984 = _3977;\n                }\n                float _3985;\n                if (_3984)\n                {\n                    _3985 = _378.fa_fog_b.y;\n                }\n                else\n                {\n                    _3985 = _378.fa_fog_b.y * exp(-fast::min(_378.fa_fog_b.w * _3969, 80.0));\n                }\n                bool _4012;\n                if (_3978)\n                {\n                    _4012 = _378.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4012 = _3977;\n                }\n                float _4013;\n                if (_4012)\n                {\n                    _4013 = _378.fa_fog_b.y * _3969;\n                }\n                else\n                {\n                    _4013 = (_378.fa_fog_b.y * (1.0 - exp(-fast::min(_378.fa_fog_b.w * _3969, 80.0)))) / _378.fa_fog_b.w;\n                }\n                bool _4038 = _3974 <= 0.0;\n                bool _4045;\n                if (!_4038)\n                {\n                    _4045 = _378.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4045 = _4038;\n                }\n                float _4046;\n                if (_4045)\n                {\n                    _4046 = _378.fa_fog_b.y * _3974;\n                }\n                else\n                {\n                    _4046 = (_378.fa_fog_b.y * (1.0 - exp(-fast::min(_378.fa_fog_b.w * _3974, 80.0)))) / _378.fa_fog_b.w;\n                }\n                float _4073;\n                if (abs(_3964) < 0.001000000047497451305389404296875)\n                {\n                    _4073 = _3985;\n                }\n                else\n                {\n                    _4073 = (_4046 - _4013) / _3964;\n                }\n                tau += (_3914 * fast::max(_4073, 0.0));\n            }\n            result = mix(result, _378.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _4197);\n    return out;\n}\n\n",
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
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_378",
            "msl_buffer_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2035",
            "msl_buffer_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_3368",
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
            "name": "fa_env_tex_fa_env_smp",
            "view_name": "fa_env_tex",
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
          }
        ]
      }
    },
    "prepass": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_prepass_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float& fa_pre_depth, thread float3& fa_pre_r0, thread float3& fa_pre_r1, thread float3& fa_pre_r2, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _131);\n    float3 _302 = _160.world_pos;\n    float4 _171 = float4(_302, 1.0);\n    fa_world_pos = _302;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -(_131.fa_light_vp * _171).z;\n    fa_pre_r0 = float3(_131.fa_light_vp[0].x, _131.fa_light_vp[1].x, _131.fa_light_vp[2].x);\n    fa_pre_r1 = float3(_131.fa_light_vp[0].y, _131.fa_light_vp[1].y, _131.fa_light_vp[2].y);\n    fa_pre_r2 = float3(_131.fa_light_vp[0].z, _131.fa_light_vp[1].z, _131.fa_light_vp[2].z);\n    gl_Position = _131.fa_view_proj * _171;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _131 [[buffer(0)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5, _131, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_pre_depth, out.fa_pre_r0, out.fa_pre_r1, out.fa_pre_r2, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _56;\n    if (bool(i.front_facing))\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = fast::normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = fast::normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (bool(i.front_facing))\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _213, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _213.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _787 = base_t;\n    _787.x = _225.x;\n    _787.y = _225.y;\n    _787.z = _225.z;\n    base_t = _787;\n    float4 _241 = (_787 * _213.fa_base_color) * i.vertex_color;\n    float3 _750 = i.world_normal;\n    if (_213.fa_maps.z > 0.5)\n    {\n        float param_4 = _213.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0) - float3(1.0);\n        float2 _284 = _279.xy * _213.fa_maps.x;\n        float3 _795 = _279;\n        _795.x = _284.x;\n        _795.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _795;\n        _750 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _213.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _798 = mrt;\n    _798.x = _313.x;\n    _798.y = _313.y;\n    _798.z = _313.z;\n    mrt = _798;\n    float4 _343 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _213.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _385 = fa_tex_fix(param_20, param_21);\n    float _755 = _213.fa_layers_a.x;\n    float _756 = _213.fa_layers_a.y;\n    float _759 = _213.fa_layers_a.z;\n    float _758 = _213.fa_layers_b.w;\n    float _761 = _213.fa_layers_c.x;\n    if (_213.fa_layers_c.z > 0.5)\n    {\n        if (mod(_213.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _755 *= _355.y;\n            _756 *= _355.z;\n            _758 *= _343.w;\n        }\n        if (_213.fa_layers_c.z > 1.5)\n        {\n            _759 *= mrt.x;\n            _761 *= mrt.w;\n        }\n    }\n    return Surface{ _241.xyz, _241.w, _750, fast::clamp(_213.fa_pbr.x * _313.z, 0.0, 1.0), fast::clamp(_213.fa_pbr.y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_213.fa_maps.y * (_355.x - 1.0)), _213.fa_emissive.xyz + (_213.fa_model_emissive.xyz * _385), _755, _756, _213.fa_layers_b.xyz, _758, _759, _213.fa_layers_a.w, _761, _213.fa_layers_c.y, _213.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _213 [[buffer(1)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], sampler fa_smp [[sampler(0)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _661 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _661 = -_661;\n    }\n    float3 _519 = fast::normalize(_213.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _661, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _519, short(gl_FrontFacing) };\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _661, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _519, short(gl_FrontFacing) };\n    Surface param_2 = fa_standard_surface(param, fa_tex, fa_smp, _213, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    surface(param_1, param_2);\n    float3 _534 = fast::normalize(param_2.normal);\n    float3 _549 = fast::normalize(float3(dot(in.fa_pre_r0, _534), dot(in.fa_pre_r1, _534), dot(in.fa_pre_r2, _534)));\n    float _561 = _549.z;\n    float2 e = _549.xy / float2((abs(_549.x) + abs(_549.y)) + abs(_561));\n    if (_561 < 0.0)\n    {\n        e = (float2(1.0) - abs(e.yx)) * float2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    out.fa_frag_color = float4(fast::min(in.fa_pre_depth, 60000.0), e, 1.0);\n    return out;\n}\n\n",
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
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_213",
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n    float4 fa_joints [[attribute(9)]];\n    float4 fa_weights [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _183)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_183.fa_joint_rows[_174] * weights[i]);\n        r1 += (_183.fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183.fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_prepass_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float& fa_pre_depth, thread float3& fa_pre_r0, thread float3& fa_pre_r1, thread float3& fa_pre_r2, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _136);\n    float3 _423 = _273.world_pos;\n    float4 _284 = float4(_423, 1.0);\n    fa_world_pos = _423;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    fa_pre_depth = -(_136.fa_light_vp * _284).z;\n    fa_pre_r0 = float3(_136.fa_light_vp[0].x, _136.fa_light_vp[1].x, _136.fa_light_vp[2].x);\n    fa_pre_r1 = float3(_136.fa_light_vp[0].y, _136.fa_light_vp[1].y, _136.fa_light_vp[2].y);\n    fa_pre_r2 = float3(_136.fa_light_vp[0].z, _136.fa_light_vp[1].z, _136.fa_light_vp[2].z);\n    gl_Position = _136.fa_view_proj * _284;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _136 [[buffer(0)]], constant fa_skin& _183 [[buffer(3)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float4x4 param_2 = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _183);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7, _136, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_pre_depth, out.fa_pre_r0, out.fa_pre_r1, out.fa_pre_r2, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _56;\n    if (bool(i.front_facing))\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = fast::normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = fast::normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (bool(i.front_facing))\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _213, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _213.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _787 = base_t;\n    _787.x = _225.x;\n    _787.y = _225.y;\n    _787.z = _225.z;\n    base_t = _787;\n    float4 _241 = (_787 * _213.fa_base_color) * i.vertex_color;\n    float3 _750 = i.world_normal;\n    if (_213.fa_maps.z > 0.5)\n    {\n        float param_4 = _213.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0) - float3(1.0);\n        float2 _284 = _279.xy * _213.fa_maps.x;\n        float3 _795 = _279;\n        _795.x = _284.x;\n        _795.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _795;\n        _750 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _213.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _798 = mrt;\n    _798.x = _313.x;\n    _798.y = _313.y;\n    _798.z = _313.z;\n    mrt = _798;\n    float4 _343 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _213.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _385 = fa_tex_fix(param_20, param_21);\n    float _755 = _213.fa_layers_a.x;\n    float _756 = _213.fa_layers_a.y;\n    float _759 = _213.fa_layers_a.z;\n    float _758 = _213.fa_layers_b.w;\n    float _761 = _213.fa_layers_c.x;\n    if (_213.fa_layers_c.z > 0.5)\n    {\n        if (mod(_213.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _755 *= _355.y;\n            _756 *= _355.z;\n            _758 *= _343.w;\n        }\n        if (_213.fa_layers_c.z > 1.5)\n        {\n            _759 *= mrt.x;\n            _761 *= mrt.w;\n        }\n    }\n    return Surface{ _241.xyz, _241.w, _750, fast::clamp(_213.fa_pbr.x * _313.z, 0.0, 1.0), fast::clamp(_213.fa_pbr.y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_213.fa_maps.y * (_355.x - 1.0)), _213.fa_emissive.xyz + (_213.fa_model_emissive.xyz * _385), _755, _756, _213.fa_layers_b.xyz, _758, _759, _213.fa_layers_a.w, _761, _213.fa_layers_c.y, _213.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _213 [[buffer(1)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], sampler fa_smp [[sampler(0)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _661 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _661 = -_661;\n    }\n    float3 _519 = fast::normalize(_213.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _661, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _519, short(gl_FrontFacing) };\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _661, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _519, short(gl_FrontFacing) };\n    Surface param_2 = fa_standard_surface(param, fa_tex, fa_smp, _213, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    surface(param_1, param_2);\n    float3 _534 = fast::normalize(param_2.normal);\n    float3 _549 = fast::normalize(float3(dot(in.fa_pre_r0, _534), dot(in.fa_pre_r1, _534), dot(in.fa_pre_r2, _534)));\n    float _561 = _549.z;\n    float2 e = _549.xy / float2((abs(_549.x) + abs(_549.y)) + abs(_561));\n    if (_561 < 0.0)\n    {\n        e = (float2(1.0) - abs(e.yx)) * float2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    out.fa_frag_color = float4(fast::min(in.fa_pre_depth, 60000.0), e, 1.0);\n    return out;\n}\n\n",
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
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_213",
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
