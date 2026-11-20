{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "5f457c7d0bc8edbcdea422ba00c093c613745eefd8db6d8c8f93fc5e235db1e8",
  "slang": "metal_macos",
  "params": [],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float3 fa_lm [[user(locn5)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _131);\n    float3 _267 = _160.world_pos;\n    fa_world_pos = _267;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = _131.fa_view_proj * float4(_267, 1.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _131 [[buffer(0)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5, _131, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.gl_Position);\n    out.fa_lm = float3(0.0);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n#pragma clang diagnostic ignored \"-Wmissing-braces\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\ntemplate<typename T, size_t Num>\nstruct spvUnsafeArray\n{\n    T elements[Num ? Num : 1];\n    \n    thread T& operator [] (size_t pos) thread\n    {\n        return elements[pos];\n    }\n    constexpr const thread T& operator [] (size_t pos) const thread\n    {\n        return elements[pos];\n    }\n    \n    device T& operator [] (size_t pos) device\n    {\n        return elements[pos];\n    }\n    constexpr const device T& operator [] (size_t pos) const device\n    {\n        return elements[pos];\n    }\n    \n    constexpr const constant T& operator [] (size_t pos) const constant\n    {\n        return elements[pos];\n    }\n    \n    threadgroup T& operator [] (size_t pos) threadgroup\n    {\n        return elements[pos];\n    }\n    constexpr const threadgroup T& operator [] (size_t pos) const threadgroup\n    {\n        return elements[pos];\n    }\n};\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n    float4 fa_shadow_lcfg;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float3 fa_lm [[user(locn5)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_cluster_texel(thread const float3& world_pos, constant fa_mesh_fs_params& _384, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    bool _1312 = _384.fa_cl_info.x < 0.0;\n    bool _1319;\n    if (!_1312)\n    {\n        _1319 = _384.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _1319 = _1312;\n    }\n    bool _1327;\n    if (!_1319)\n    {\n        _1327 = _384.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _1327 = _1319;\n    }\n    bool _1334;\n    if (!_1327)\n    {\n        _1334 = _384.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _1334 = _1327;\n    }\n    bool _1341;\n    if (!_1334)\n    {\n        _1341 = _384.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _1341 = _1334;\n    }\n    if (_1341)\n    {\n        return float4(0.0);\n    }\n    float4 _1351 = float4(world_pos, 1.0);\n    float _1357 = dot(_384.fa_cl_vpw, _1351);\n    if (!(_1357 > 9.9999999747524270787835121154785e-07))\n    {\n        return float4(0.0);\n    }\n    float2 _1379 = float2(dot(_384.fa_cl_vpx, _1351), dot(_384.fa_cl_vpy, _1351)) / float2(_1357);\n    int _1383 = int(_384.fa_cl_grid.x);\n    int _1387 = int(_384.fa_cl_grid.y);\n    int param = (int(_384.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_384.fa_cl_fwd.xyz, world_pos) + _384.fa_cl_fwd.w, _384.fa_cl_grid.w) / _384.fa_cl_grid.w) * _384.fa_cl_grid.z)), 0, int(_384.fa_cl_info.y) - 1) * _1387) + clamp(int(floor(((_1379.y * 0.5) + 0.5) * _384.fa_cl_grid.y)), 0, _1387 - 1)) * _1383)) + clamp(int(floor(((_1379.x * 0.5) + 0.5) * _384.fa_cl_grid.x)), 0, _1383 - 1);\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, constant fa_mesh_fs_params& _384, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    float3 param = world_pos;\n    float4 _1463 = fa_cluster_texel(param, _384, fa_light_tex, fa_shadow_smp);\n    return int2(int(_1463.x), int(_1463.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, constant fa_mesh_fs_params& _384, texture2d<float> fa_light_tex, sampler fa_shadow_smp, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_384.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _3241 = fa_cluster_lookup(param, _384, fa_light_tex, fa_shadow_smp);\n    fa_cl_slot = _3241.x;\n    fa_cl_local = _3241.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _3400 = fa_linear_to_srgb(param);\n        c = _3400;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _3408 = fa_srgb_to_linear(param_1);\n            c = _3408;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _267;\n    if (bool(i.front_facing))\n    {\n        _267 = i.world_normal;\n    }\n    else\n    {\n        _267 = -i.world_normal;\n    }\n    float3 _291 = fast::normalize(i.world_tangent.xyz - (_267 * dot(_267, i.world_tangent.xyz)));\n    float3 _318 = fast::normalize(((_291 * m.x) + ((cross(_267, _291) * i.world_tangent.w) * m.y)) + (_267 * m.z));\n    float3 _321;\n    if (bool(i.front_facing))\n    {\n        _321 = _318;\n    }\n    else\n    {\n        _321 = -_318;\n    }\n    return _321;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _384, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _384.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _3439 = fa_tex_fix(param_2, param_3);\n    float4 _4487 = base_t;\n    _4487.x = _3439.x;\n    _4487.y = _3439.y;\n    _4487.z = _3439.z;\n    base_t = _4487;\n    float4 _3453 = (_4487 * _384.fa_base_color) * i.vertex_color;\n    float3 _4352 = i.world_normal;\n    if (_384.fa_maps.z > 0.5)\n    {\n        float param_4 = _384.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _3485 = fa_tex_fix(param_6, param_7);\n        float3 _3488 = (_3485 * 2.0) - float3(1.0);\n        float2 _3493 = _3488.xy * _384.fa_maps.x;\n        float3 _4495 = _3488;\n        _4495.x = _3493.x;\n        _4495.y = _3493.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _4495;\n        _4352 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _384.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _3521 = fa_tex_fix(param_12, param_13);\n    float4 _4498 = mrt;\n    _4498.x = _3521.x;\n    _4498.y = _3521.y;\n    _4498.z = _3521.z;\n    mrt = _4498;\n    float4 _3549 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _384.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _3549.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _3560 = fa_tex_fix(param_16, param_17);\n    float param_18 = _384.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _3590 = fa_tex_fix(param_20, param_21);\n    float _4357 = _384.fa_layers_a.x;\n    float _4358 = _384.fa_layers_a.y;\n    float _4361 = _384.fa_layers_a.z;\n    float _4360 = _384.fa_layers_b.w;\n    float _4363 = _384.fa_layers_c.x;\n    if (_384.fa_layers_c.z > 0.5)\n    {\n        if (mod(_384.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _4357 *= _3560.y;\n            _4358 *= _3560.z;\n            _4360 *= _3549.w;\n        }\n        if (_384.fa_layers_c.z > 1.5)\n        {\n            _4361 *= mrt.x;\n            _4363 *= mrt.w;\n        }\n    }\n    return Surface{ _3453.xyz, _3453.w, _4352, fast::clamp(_384.fa_pbr.x * _3521.z, 0.0, 1.0), fast::clamp(_384.fa_pbr.y * _3521.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_384.fa_maps.y * (_3560.x - 1.0)), _384.fa_emissive.xyz + (_384.fa_model_emissive.xyz * _3590), _4357, _4358, _384.fa_layers_b.xyz, _4360, _4361, _384.fa_layers_a.w, _4363, _384.fa_layers_c.y, _384.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_decal_tile(thread const float4& rect, thread const float2& uv, thread const float2& atlas, thread const float2& ddx, thread const float2& ddy, sampler fa_env_smp, texture2d<float> fa_decal_tex)\n{\n    float2 _1543 = rect.zw - rect.xy;\n    float2 _1547 = _1543 * atlas;\n    float2 _1551 = ddx * _1547;\n    float2 _1555 = ddy * _1547;\n    return fa_decal_tex.sample(fa_env_smp, (rect.xy + (fast::clamp(uv, float2(0.0), float2(1.0)) * _1543)), level(fast::clamp(0.5 * log2(fast::max(fast::max(dot(_1551, _1551), dot(_1555, _1555)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_apply_decals(thread const float3& world_pos, thread const float3& geo_normal, thread float3& albedo, thread float3& normal, constant fa_mesh_fs_params& _384, texture2d<float> fa_light_tex, sampler fa_shadow_smp, sampler fa_env_smp, texture2d<float> fa_decal_tex)\n{\n    bool _1588 = _384.fa_counts.y < 0.5;\n    bool _1595;\n    if (!_1588)\n    {\n        _1595 = _384.fa_counts.w < 0.5;\n    }\n    else\n    {\n        _1595 = _1588;\n    }\n    if (_1595)\n    {\n        return;\n    }\n    float3 _1601 = dfdx(world_pos);\n    float3 _1604 = dfdy(world_pos);\n    float3 param = world_pos;\n    float4 _1608 = fa_cluster_texel(param, _384, fa_light_tex, fa_shadow_smp);\n    int _1612 = int(_1608.w);\n    if (_1612 < 1)\n    {\n        return;\n    }\n    int _1622 = int(_384.fa_counts.y + 0.5);\n    int param_1 = _1622;\n    float4 _1626 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float2 _1629 = _1626.yz;\n    int _1633 = int(_1626.w);\n    int param_2 = _1622 + 1;\n    float4 _1638 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float _1639 = _1638.x;\n    int _1645 = int(_384.fa_counts.w + 0.5) - 1;\n    int _1649 = int(_1608.z);\n    float3 _1914;\n    for (int k = 0; k < _1612; k++)\n    {\n        int _1662 = _1649 + k;\n        int param_3 = _1633 + (_1662 >> 2);\n        int _1679 = (_1622 + 2) + (int(fa_light_texel(param_3, fa_light_tex, fa_shadow_smp)[_1662 & 3]) * 7);\n        int param_4 = _1679 + 6;\n        float4 _1684 = fa_light_texel(param_4, fa_light_tex, fa_shadow_smp);\n        if (((int(_1684.w + 0.5) >> _1645) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1679;\n        float4 _1699 = fa_light_texel(param_5, fa_light_tex, fa_shadow_smp);\n        int param_6 = _1679 + 1;\n        float4 _1704 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n        int param_7 = _1679 + 2;\n        float4 _1709 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n        float3 _1712 = _1699.xyz;\n        float _1717 = dot(_1712, world_pos) + _1699.w;\n        float3 _1719 = _1704.xyz;\n        float _1724 = dot(_1719, world_pos) + _1704.w;\n        float3 _1726 = _1709.xyz;\n        float _1731 = dot(_1726, world_pos) + _1709.w;\n        bool _1736 = abs(_1717) > 0.5;\n        bool _1744;\n        if (!_1736)\n        {\n            _1744 = abs(_1724) > 0.5;\n        }\n        else\n        {\n            _1744 = _1736;\n        }\n        bool _1752;\n        if (!_1744)\n        {\n            _1752 = abs(_1731) > 0.5;\n        }\n        else\n        {\n            _1752 = _1744;\n        }\n        if (_1752)\n        {\n            continue;\n        }\n        float _1767 = fast::clamp(dot(geo_normal, fast::normalize(_1726)) * _1684.z, 0.0, 1.0);\n        if (_1767 <= 0.0)\n        {\n            continue;\n        }\n        float _1787 = (fast::clamp((0.5 - abs(_1731)) * 10.0, 0.0, 1.0) * _1767) * _1684.x;\n        float2 _1795 = float2(_1717 + 0.5, 0.5 - _1724);\n        float2 _1805 = float2(dot(_1712, _1601), dot(_1719, _1601));\n        float2 _1815 = float2(dot(_1712, _1604), dot(_1719, _1604));\n        int param_8 = _1679 + 5;\n        float4 _1820 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n        int param_9 = _1679 + 3;\n        float4 _1825 = fa_light_texel(param_9, fa_light_tex, fa_shadow_smp);\n        int param_10 = _1679 + 4;\n        float4 _1830 = fa_light_texel(param_10, fa_light_tex, fa_shadow_smp);\n        float tex_a = 1.0;\n        float3 col = _1820.xyz;\n        bool _1840 = _1825.z > _1825.x;\n        if (_1840)\n        {\n            float4 param_11 = _1825;\n            float2 param_12 = _1795;\n            float2 param_13 = _1629;\n            float2 param_14 = _1805;\n            float2 param_15 = _1815;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15, fa_env_smp, fa_decal_tex);\n            if ((_1639 > 0.5) && (_1639 < 1.5))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1866 = fa_dc_to_linear(param_16);\n                float4 _4432 = tx;\n                _4432.x = _1866.x;\n                _4432.y = _1866.y;\n                _4432.z = _1866.z;\n                tx = _4432;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, float3(fast::clamp((_1787 * tex_a) * _1820.w, 0.0, 1.0)));\n        if (_1830.z > _1830.x)\n        {\n            float4 param_17 = _1830;\n            float2 param_18 = _1795;\n            float2 param_19 = _1629;\n            float2 param_20 = _1805;\n            float2 param_21 = _1815;\n            float4 _1910 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21, fa_env_smp, fa_decal_tex);\n            if (_1639 > 1.5)\n            {\n                float3 param_22 = _1910.xyz;\n                float3 _1920 = fa_dc_to_srgb(param_22);\n                _1914 = _1920;\n            }\n            else\n            {\n                _1914 = _1910.xyz;\n            }\n            float3 _1929 = (_1914 * 2.0) - float3(1.0);\n            float2 _1934 = _1929.xy * _1684.y;\n            float3 _1956 = (fast::normalize(_1712) * _1934.x) + (fast::normalize(_1719) * _1934.y);\n            float3 _1959 = fast::normalize(normal);\n            normal = fast::normalize(mix(_1959, fast::normalize((_1959 * fast::max(_1929.z, 0.0500000007450580596923828125)) + (_1956 - (_1959 * dot(_1959, _1956)))), float3(fast::clamp(_1787 * (_1840 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_sh_coef(thread const int& k, constant fa_mesh_fs_params& _384, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float3 v = fa_env_tex.sample(fa_env_smp, float3(1.0, 1.0 - (float((2 * (k >> 2)) + 1) * 0.25), 1.0 - (float((2 * (k & 3)) + 1) * 0.25)), level(5.0)).xyz;\n    if (_384.fa_env_sky.w > 1.5)\n    {\n        v = (v - float3(0.5)) * 8.0;\n    }\n    return v;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sh_eval(thread const spvUnsafeArray<float3, 9>& c, thread const float3& n)\n{\n    float3 _3154 = fast::max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), float3(0.0));\n    return _3154;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _384, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    if (_384.fa_env_sky.w > 0.5)\n    {\n        spvUnsafeArray<float3, 9> c;\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param, _384, fa_env_smp, fa_env_tex);\n        }\n        spvUnsafeArray<float3, 9> param_1 = c;\n        float3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return _384.fa_ambient.xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_indirect_diffuse(thread const float3& n, constant fa_mesh_fs_params& _384, sampler fa_env_smp, texturecube<float> fa_env_tex, thread float3& fa_lm, texture2d<float> fa_lightmap)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return fa_lightmap.sample(fa_env_smp, fa_lm.xy, level(0.0)).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param, _384, fa_env_smp, fa_env_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 ambient(thread const SurfaceInput& i, thread const Surface& s, thread const float3& ambientColor)\n{\n    return ambientColor;\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, constant fa_mesh_fs_params& _384, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (int(_384.fa_cl_info.x) + int(_384.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, constant fa_mesh_fs_params& _384, texture2d<float> fa_light_tex, sampler fa_shadow_smp, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, _384, fa_light_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_light_base(thread const int& li, constant fa_mesh_fs_params& _384)\n{\n    return li * ((_384.fa_ambient.w > 4.5) ? 8 : 4);\n}\n\nstatic inline __attribute__((always_inline))\nbool fa_light_baked(thread const int& li, constant fa_mesh_fs_params& _384, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li;\n    int param_1 = fa_light_base(param, _384) + 3;\n    return fa_light_texel(param_1, fa_light_tex, fa_shadow_smp).w > 0.5;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_light_type(thread const int& li, constant fa_mesh_fs_params& _384, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li;\n    int param_1 = fa_light_base(param, _384) + 1;\n    return fa_light_texel(param_1, fa_light_tex, fa_shadow_smp).w;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_atlas_fetch(thread const float2& texel, texture2d<float> fa_light_atlas, sampler fa_env_smp)\n{\n    return fa_light_atlas.sample(fa_env_smp, (texel / float2(int2(fa_light_atlas.get_width(), fa_light_atlas.get_height()))), level(0.0));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_cookie_sample(thread const float2& tile_origin, thread const float2& uv, texture2d<float> fa_light_atlas, sampler fa_env_smp)\n{\n    float2 param = (tile_origin + float2(1.0)) + (fast::clamp(uv, float2(0.0), float2(1.0)) * 254.0);\n    return fa_atlas_fetch(param, fa_light_atlas, fa_env_smp).xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_area_point(thread const float3& c, thread const float3& axis, thread const float3& ru, thread const float3& uu, thread const float& hx, thread const float& hy, thread const float& shape, thread const float3& p, thread const float3& r)\n{\n    bool _562 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        float3 _575 = (c - (ru * hx)) - p;\n        float3 _581 = ru * (2.0 * hx);\n        float _587 = fast::max(dot(_581, _581), 9.9999999392252902907785028219223e-09);\n        float _591 = dot(_575, _581);\n        float t = fast::clamp((-_591) / _587, 0.0, 1.0);\n        if (_562)\n        {\n            float _606 = dot(r, _581);\n            float _612 = _587 - (_606 * _606);\n            if (abs(_612) > (9.9999997473787516355514526367188e-06 * _587))\n            {\n                t = fast::clamp(((dot(r, _575) * _606) - _591) / _612, 0.0, 1.0);\n            }\n        }\n        return (p + _575) + (_581 * t);\n    }\n    float3 q = p;\n    float _644 = dot(r, axis);\n    bool _652;\n    if (_562)\n    {\n        _652 = abs(_644) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _652 = _562;\n    }\n    if (_652)\n    {\n        float _662 = dot(c - p, axis) / _644;\n        if (_662 > 0.0)\n        {\n            q = p + (r * _662);\n        }\n    }\n    float3 _675 = q - c;\n    float2 xy = float2(dot(_675, ru), dot(_675, uu));\n    if (shape > 0.5)\n    {\n        float _690 = length(xy);\n        if (_690 > hx)\n        {\n            xy *= (hx / _690);\n        }\n    }\n    else\n    {\n        xy = fast::clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cube_face(thread const float3& d)\n{\n    float3 _333 = abs(d);\n    float _335 = _333.x;\n    float _337 = _333.y;\n    bool _338 = _335 >= _337;\n    bool _346;\n    if (_338)\n    {\n        _346 = _335 >= _333.z;\n    }\n    else\n    {\n        _346 = _338;\n    }\n    int _347;\n    if (_346)\n    {\n        _347 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _362;\n        if (_337 >= _333.z)\n        {\n            _362 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _362 = (d.z > 0.0) ? 4 : 5;\n        }\n        _347 = _362;\n    }\n    return _347;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cube_face_basis(thread const int& f, thread float3& fwd, thread float3& up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0, 0.0, 0.0);\n        up = float3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0, 0.0, 0.0);\n            up = float3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0, 1.0, 0.0);\n                up = float3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0, -1.0, 0.0);\n                    up = float3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0, 0.0, 1.0);\n                        up = float3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0, 0.0, -1.0);\n                        up = float3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_ies_sample(thread const float2& tile_origin, thread const float3& d, thread const float3& axis, thread const float3& right, thread const float3& up, texture2d<float> fa_light_atlas, sampler fa_env_smp)\n{\n    float _482 = dot(d, right);\n    float _486 = dot(d, up);\n    float _497;\n    if (((_482 * _482) + (_486 * _486)) > 1.0000000133514319600180897396058e-10)\n    {\n        _497 = precise::atan2(_486, _482) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _497 = 0.0;\n    }\n    float2 param = tile_origin + float2(1.0 + ((_497 - floor(_497)) * 64.0), 1.0 + (acos(fast::clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param, fa_light_atlas, fa_env_smp).x;\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample_n(thread const int& li, thread const float3& world_pos, thread const float3& n, constant fa_mesh_fs_params& _384, texture2d<float> fa_light_tex, sampler fa_shadow_smp, texture2d<float> fa_light_atlas, sampler fa_env_smp, thread float3& fa_light_tint, thread bool& fa_light_is_area)\n{\n    int param = li;\n    int _728 = fa_light_base(param, _384);\n    bool _732 = _384.fa_ambient.w > 4.5;\n    int param_1 = _728;\n    float4 _736 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    int param_2 = _728 + 1;\n    float4 _741 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float _744 = _741.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = float3(1.0);\n    bool _756 = _732 && (_744 > 2.5);\n    fa_light_is_area = _756;\n    bool _758 = _744 < 0.5;\n    float3 l;\n    if (_758)\n    {\n        l = fast::normalize(_736.xyz);\n        if (_732)\n        {\n            int param_3 = _728 + 6;\n            float4 _772 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            if (_772.z > 0.5)\n            {\n                int param_4 = _728 + 4;\n                float4 _782 = fa_light_texel(param_4, fa_light_tex, fa_shadow_smp);\n                int param_5 = _728 + 5;\n                float4 _787 = fa_light_texel(param_5, fa_light_tex, fa_shadow_smp);\n                float2 param_6 = _772.xy;\n                float2 param_7 = fract(float2(dot(world_pos, _782.xyz) * _782.w, (-dot(world_pos, _787.xyz)) * _787.w) + float2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7, fa_light_atlas, fa_env_smp);\n            }\n        }\n    }\n    else\n    {\n        float3 _817 = _736.xyz;\n        float3 _819 = _817 - world_pos;\n        float3 to_light = _819;\n        float _822 = length(_819);\n        float reach = _822;\n        bool front = true;\n        if (_756)\n        {\n            int param_8 = _728 + 7;\n            reach = fast::max(_822 - fa_light_texel(param_8, fa_light_tex, fa_shadow_smp).w, 0.0);\n            int param_9 = _728 + 4;\n            float4 _846 = fa_light_texel(param_9, fa_light_tex, fa_shadow_smp);\n            int param_10 = _728 + 5;\n            float4 _851 = fa_light_texel(param_10, fa_light_tex, fa_shadow_smp);\n            int param_11 = _728 + 6;\n            float4 _856 = fa_light_texel(param_11, fa_light_tex, fa_shadow_smp);\n            float _857 = _856.w;\n            int param_12 = _728 + 2;\n            float3 _864 = fast::normalize(fa_light_texel(param_12, fa_light_tex, fa_shadow_smp).xyz);\n            bool _866 = _857 > 1.5;\n            bool _874;\n            if (!_866)\n            {\n                _874 = dot(_864, to_light) < 0.0;\n            }\n            else\n            {\n                _874 = _866;\n            }\n            front = _874;\n            float3 r = float3(0.0);\n            float3 _883 = _384.fa_camera_pos.xyz - world_pos;\n            bool _887 = dot(n, n) > 0.5;\n            bool _895;\n            if (_887)\n            {\n                _895 = dot(_883, _883) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _895 = _887;\n            }\n            if (_895)\n            {\n                r = reflect(-fast::normalize(_883), fast::normalize(n));\n            }\n            float3 param_13 = _817;\n            float3 param_14 = _864;\n            float3 param_15 = _846.xyz;\n            float3 param_16 = _851.xyz;\n            float param_17 = _846.w;\n            float param_18 = _851.w;\n            float param_19 = _857;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _931 = length(to_light);\n        dist = _931;\n        l = to_light / float3(fast::max(_931, 9.9999997473787516355514526367188e-05));\n        float _945 = reach / fast::max(_736.w, 0.001000000047497451305389404296875);\n        float _951 = fast::clamp(1.0 - (_945 * _945), 0.0, 1.0);\n        float _953;\n        if (front)\n        {\n            _953 = _951 * _951;\n        }\n        else\n        {\n            _953 = 0.0;\n        }\n        atten = _953;\n        bool _964 = _744 < 2.5;\n        if ((_744 > 1.5) && _964)\n        {\n            int param_22 = _728 + 2;\n            float4 _972 = fa_light_texel(param_22, fa_light_tex, fa_shadow_smp);\n            float _982 = _972.w;\n            int param_23 = _728 + 3;\n            float4 _987 = fa_light_texel(param_23, fa_light_tex, fa_shadow_smp);\n            float _988 = _987.x;\n            float cos_inner = _988;\n            if (_988 > 1.5)\n            {\n                cos_inner = mix(_982, 1.0, 0.25);\n            }\n            atten *= smoothstep(_982, cos_inner, dot(-l, fast::normalize(_972.xyz)));\n        }\n        if (_732 && (_744 < 1.5))\n        {\n            int param_24 = _728 + 6;\n            float4 _1012 = fa_light_texel(param_24, fa_light_tex, fa_shadow_smp);\n            if (_1012.z > 0.5)\n            {\n                float3 _1020 = -to_light;\n                int param_25 = _728 + 4;\n                int param_26 = _728 + 5;\n                float3 _1034 = fa_light_texel(param_25, fa_light_tex, fa_shadow_smp).xyz;\n                float3 _1038 = fa_light_texel(param_26, fa_light_tex, fa_shadow_smp).xyz;\n                float3 _1047 = float3(dot(_1020, _1034), dot(_1020, _1038), dot(_1020, cross(_1034, _1038)));\n                float3 param_27 = _1047;\n                int _1051 = fa_cube_face(param_27);\n                int param_28 = _1051;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1078 = float2(dot(_1047, cross(param_29, param_30)), dot(_1047, param_30)) / float2(fast::max(dot(_1047, param_29), 9.9999997473787516355514526367188e-05));\n                int _1082 = _1051 / 3;\n                float2 param_31 = _1012.xy + (float2(float(_1051 - (_1082 * 3)), float(_1082)) * 256.0);\n                float2 param_32 = float2(0.5 + (0.5 * _1078.x), 0.5 - (0.5 * _1078.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32, fa_light_atlas, fa_env_smp);\n            }\n            int param_33 = _728 + 7;\n            float4 _1112 = fa_light_texel(param_33, fa_light_tex, fa_shadow_smp);\n            if (_1112.z > 0.5)\n            {\n                int param_34 = _728 + 2;\n                int param_35 = _728 + 4;\n                int param_36 = _728 + 5;\n                float2 param_37 = _1112.xy;\n                float3 param_38 = -l;\n                float3 param_39 = fast::normalize(fa_light_texel(param_34, fa_light_tex, fa_shadow_smp).xyz);\n                float3 param_40 = fa_light_texel(param_35, fa_light_tex, fa_shadow_smp).xyz;\n                float3 param_41 = fa_light_texel(param_36, fa_light_tex, fa_shadow_smp).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41, fa_light_atlas, fa_env_smp);\n            }\n        }\n        else\n        {\n            if (_732 && _964)\n            {\n                int param_42 = _728 + 6;\n                float4 _1159 = fa_light_texel(param_42, fa_light_tex, fa_shadow_smp);\n                int param_43 = _728 + 7;\n                float4 _1164 = fa_light_texel(param_43, fa_light_tex, fa_shadow_smp);\n                bool _1167 = _1159.z > 0.5;\n                bool _1174;\n                if (!_1167)\n                {\n                    _1174 = _1164.z > 0.5;\n                }\n                else\n                {\n                    _1174 = _1167;\n                }\n                if (_1174)\n                {\n                    int param_44 = _728 + 2;\n                    float4 _1181 = fa_light_texel(param_44, fa_light_tex, fa_shadow_smp);\n                    float3 _1185 = fast::normalize(_1181.xyz);\n                    int param_45 = _728 + 4;\n                    float4 _1190 = fa_light_texel(param_45, fa_light_tex, fa_shadow_smp);\n                    int param_46 = _728 + 5;\n                    float4 _1195 = fa_light_texel(param_46, fa_light_tex, fa_shadow_smp);\n                    if (_1167)\n                    {\n                        float3 _1203 = -to_light;\n                        float _1210 = _1181.w;\n                        float _1226 = 0.5 / fast::max(dot(_1203, _1185) * (sqrt(fast::max(1.0 - (_1210 * _1210), 0.0)) / fast::max(_1210, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        float2 param_47 = _1159.xy;\n                        float2 param_48 = float2(0.5 + (dot(_1203, _1190.xyz) * _1226), 0.5 - (dot(_1203, _1195.xyz) * _1226));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48, fa_light_atlas, fa_env_smp);\n                    }\n                    if (_1164.z > 0.5)\n                    {\n                        float2 param_49 = _1164.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1185;\n                        float3 param_52 = _1190.xyz;\n                        float3 param_53 = _1195.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53, fa_light_atlas, fa_env_smp);\n                    }\n                }\n            }\n        }\n    }\n    float3 _4306 = _741.xyz * atten;\n    if (_732)\n    {\n        _4306 *= fa_light_tint;\n    }\n    int _1294;\n    if (_758)\n    {\n        _1294 = 0;\n    }\n    else\n    {\n        _1294 = ((_744 > 1.5) && (_744 < 2.5)) ? 2 : 1;\n    }\n    return LightSample{ l, _4306, atten, 1.0, dist, _1294 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _2041)\n{\n    float _2031;\n    if (i == 0)\n    {\n        _2031 = _2041.fa_shadow_split.x;\n    }\n    else\n    {\n        float _2047;\n        if (i == 1)\n        {\n            _2047 = _2041.fa_shadow_split.y;\n        }\n        else\n        {\n            float _2055;\n            if (i == 2)\n            {\n                _2055 = _2041.fa_shadow_split.z;\n            }\n            else\n            {\n                _2055 = _2041.fa_shadow_split.w;\n            }\n            _2047 = _2055;\n        }\n        _2031 = _2047;\n    }\n    return _2031;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_fetch(thread const float2& uv, thread const float4& rect, thread const float3& conv, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2088 = fa_shadow_depth(param, param_1, fa_shadow_smp, fa_shadow_tex);\n    float _2092;\n    if (conv.x < 0.5)\n    {\n        _2092 = _2088;\n    }\n    else\n    {\n        _2092 = (conv.y * conv.z) / (conv.z - (_2088 * (conv.z - conv.y)));\n    }\n    return _2092;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _2019 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_2019), sin(_2019)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_filter(thread const float2& uv, thread const float4& rect, thread const float& zr, thread const float& texel_m, thread const float& unit, thread const float& reach, thread const float& plane, thread const float3& conv, thread const int& mode, thread const float& k, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2041, texture2d<float> fa_shadow_tex)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2, fa_shadow_smp, fa_shadow_tex));\n    }\n    float _2138 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2147;\n        if (k < 0.0)\n        {\n            _2147 = (-k) / fast::max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2147 = k;\n        }\n        float _2167 = fast::clamp((_2147 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2138;\n            float2 _2186 = fa_shadow_vogel(param_3, param_4, param_5) * _2167;\n            float2 param_6 = uv + (_2186 * _2041.fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _2198 = fa_shadow_fetch(param_6, param_7, param_8, fa_shadow_smp, fa_shadow_tex);\n            if (_2198 < (zr - (length(_2186) * plane)))\n            {\n                sum += _2198;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2224 = sum / cnt;\n        float _2234;\n        if (k < 0.0)\n        {\n            _2234 = (-k) / fast::max(_2224, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2234 = k;\n        }\n        radius = fast::clamp(((fast::max(zr - _2224, 0.0) * unit) * _2234) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _2256 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2256; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2256;\n        float param_11 = _2138;\n        float2 _2275 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_2275 * _2041.fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_2275) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14, fa_shadow_smp, fa_shadow_tex));\n    }\n    return lit / float(_2256);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2041, texture2d<float> fa_shadow_tex)\n{\n    float _2317 = fast::max(_2041.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _2322 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _2328 = sqrt(1.0 - (_2322 * _2322));\n    float _2335 = fast::min(_2328 / fast::max(_2322, 0.20000000298023223876953125), 4.0);\n    float _2340;\n    if (_2041.fa_shadow_bias.y > 0.0)\n    {\n        _2340 = _2041.fa_shadow_bias.y;\n    }\n    else\n    {\n        _2340 = 1.5 * _2041.fa_shadow_info[ci].x;\n    }\n    float4 _2365 = _2041.fa_shadow_mat[ci] * float4(world + (n * (_2340 * _2328)), 1.0);\n    float _2372 = _2365.x;\n    bool _2375 = _2372 < _2041.fa_shadow_rect[ci].x;\n    bool _2384;\n    if (!_2375)\n    {\n        _2384 = _2372 > _2041.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2384 = _2375;\n    }\n    bool _2393;\n    if (!_2384)\n    {\n        _2393 = _2365.y < _2041.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2393 = _2384;\n    }\n    bool _2402;\n    if (!_2393)\n    {\n        _2402 = _2365.y > _2041.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2402 = _2393;\n    }\n    bool _2409;\n    if (!_2402)\n    {\n        _2409 = _2365.z > 1.0;\n    }\n    else\n    {\n        _2409 = _2402;\n    }\n    if (_2409)\n    {\n        return -1.0;\n    }\n    float _2417;\n    if (_2041.fa_shadow_bias.x > 0.0)\n    {\n        _2417 = _2041.fa_shadow_bias.x;\n    }\n    else\n    {\n        _2417 = 1.5 * _2041.fa_shadow_info[ci].x;\n    }\n    float2 param = _2365.xy;\n    float4 param_1 = _2041.fa_shadow_rect[ci];\n    float param_2 = _2365.z - ((_2417 * (1.0 + (0.5 * _2335))) / _2317);\n    float param_3 = _2041.fa_shadow_info[ci].x;\n    float param_4 = _2317;\n    float param_5 = _2317 * 0.25;\n    float param_6 = ((_2041.fa_shadow_info[ci].x * fast::min(_2335, 3.0)) * 0.5) / _2317;\n    float3 param_7 = float3(0.0);\n    int param_8 = int(_2041.fa_shadow_cfg.z + 0.5);\n    float param_9 = _2041.fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9, fa_shadow_smp, gl_FragCoord, _2041, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _384, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2041, texture2d<float> fa_shadow_tex)\n{\n    if (_384.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2795 = int(_2041.fa_shadow_cfg.x + 0.5);\n    if (_2795 < 1)\n    {\n        return 1.0;\n    }\n    float _2810 = dot(world - _2041.fa_shadow_eye.xyz, _2041.fa_shadow_fwd.xyz);\n    int param = _2795 - 1;\n    if (_2810 > fa_shadow_split_at(param, _2041))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2822 = _2795 > 1;\n    bool _2829;\n    if (_2822)\n    {\n        _2829 = _2810 > _2041.fa_shadow_split.x;\n    }\n    else\n    {\n        _2829 = _2822;\n    }\n    if (_2829)\n    {\n        ci = 1;\n    }\n    bool _2833 = _2795 > 2;\n    bool _2840;\n    if (_2833)\n    {\n        _2840 = _2810 > _2041.fa_shadow_split.y;\n    }\n    else\n    {\n        _2840 = _2833;\n    }\n    if (_2840)\n    {\n        ci = 2;\n    }\n    bool _2844 = _2795 > 3;\n    bool _2851;\n    if (_2844)\n    {\n        _2851 = _2810 > _2041.fa_shadow_split.z;\n    }\n    else\n    {\n        _2851 = _2844;\n    }\n    if (_2851)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2795)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2877 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_shadow_smp, gl_FragCoord, _2041, fa_shadow_tex);\n        s = _2877;\n        if (_2877 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_2041.fa_shadow_cfg.y > 0.0)\n    {\n        float _2902;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2902 = fa_shadow_split_at(param_5, _2041);\n        }\n        else\n        {\n            _2902 = _2041.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _2921 = _2041.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _2041) - _2902, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2932 = fast::clamp((_2810 - (fa_shadow_split_at(param_7, _2041) - _2921)) / _2921, 0.0, 1.0);\n        if (_2932 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2795)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _2953 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_shadow_smp, gl_FragCoord, _2041, fa_shadow_tex);\n                s2 = _2953;\n                if (_2953 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2932);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _384, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2041, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, _384, fa_shadow_smp, gl_FragCoord, _2041, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_local(thread const int& li, thread const float3& lpos, thread const float3& world, thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _384, texture2d<float> fa_light_tex, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2041, texture2d<float> fa_shadow_tex)\n{\n    bool _2475 = _384.fa_pbr.z < 0.5;\n    bool _2482;\n    if (!_2475)\n    {\n        _2482 = _2041.fa_shadow_lcfg.x < 0.5;\n    }\n    else\n    {\n        _2482 = _2475;\n    }\n    if (_2482)\n    {\n        return 1.0;\n    }\n    int param = (int(_2041.fa_shadow_lcfg.x + 0.5) - 1) + li;\n    float4 _2495 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    float _2496 = _2495.x;\n    if (_2496 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2505 = int(_2496 + 0.5);\n    int param_1 = _2505;\n    float4 _2509 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    int param_2 = _2505 + 1;\n    float4 _2514 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float fade = 1.0;\n    float _2517 = _2509.y;\n    if (_2517 > 0.0)\n    {\n        float _2534 = 1.0 - smoothstep(0.75 * _2517, _2517, length(world - _2041.fa_shadow_eye.xyz));\n        fade = _2534;\n        if (_2534 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2509.x > 1.5)\n    {\n        float3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2558 = (_2505 + 2) + (face * 6);\n    int param_4 = _2558;\n    int param_5 = _2558 + 1;\n    int param_6 = _2558 + 3;\n    float4 _2572 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n    int param_7 = _2558 + 4;\n    float4 _2577 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n    int param_8 = _2558 + 5;\n    float4 _2582 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n    float _2594 = _2582.x * fast::max(dot(_2572, float4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2599 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _2622 = fast::clamp(dot(n, _2572.xyz), -1.0, 1.0);\n    float _2641 = fast::min(sqrt(1.0 - (_2622 * _2622)) / fast::max(abs(dot(n, world - lpos)) / fast::max(dot(_2572, float4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2644 = _2514.y;\n    float _2646;\n    if (_2644 > 0.0)\n    {\n        _2646 = _2644;\n    }\n    else\n    {\n        _2646 = 1.5 * _2594;\n    }\n    float4 _2666 = float4(world + (n * (_2646 * sqrt(1.0 - (_2599 * _2599)))), 1.0);\n    float _2670 = dot(_2572, _2666);\n    float _2673 = _2582.y;\n    if (_2670 < _2673)\n    {\n        return 1.0;\n    }\n    float2 _2688 = float2(dot(fa_light_texel(param_4, fa_light_tex, fa_shadow_smp), _2666), dot(fa_light_texel(param_5, fa_light_tex, fa_shadow_smp), _2666)) / float2(_2670);\n    float _2690 = _2688.x;\n    bool _2693 = _2690 < _2577.x;\n    bool _2702;\n    if (!_2693)\n    {\n        _2702 = _2690 > _2577.z;\n    }\n    else\n    {\n        _2702 = _2693;\n    }\n    bool _2711;\n    if (!_2702)\n    {\n        _2711 = _2688.y < _2577.y;\n    }\n    else\n    {\n        _2711 = _2702;\n    }\n    bool _2720;\n    if (!_2711)\n    {\n        _2720 = _2688.y > _2577.w;\n    }\n    else\n    {\n        _2720 = _2711;\n    }\n    if (_2720)\n    {\n        return 1.0;\n    }\n    float _2726 = _2514.x;\n    float _2728;\n    if (_2726 > 0.0)\n    {\n        _2728 = _2726;\n    }\n    else\n    {\n        _2728 = 1.5 * _2594;\n    }\n    float2 param_9 = _2688;\n    float4 param_10 = _2577;\n    float param_11 = _2670 - (_2728 * (1.0 + (0.5 * _2641)));\n    float param_12 = _2594;\n    float param_13 = 1.0;\n    float param_14 = _2582.z * 0.25;\n    float param_15 = (_2594 * fast::min(_2641, 3.0)) * 0.5;\n    float3 param_16 = float3(1.0, _2673, _2582.z);\n    int param_17 = int(_2509.z + 0.5);\n    float param_18 = _2509.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, fa_shadow_smp, gl_FragCoord, _2041, fa_shadow_tex), fade);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, constant fa_mesh_fs_params& _384, texture2d<float> fa_light_tex, sampler fa_shadow_smp, texture2d<float> fa_light_atlas, sampler fa_env_smp, thread float3& fa_light_tint, thread bool& fa_light_is_area, thread float4& gl_FragCoord, constant fa_shadows& _2041, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos, thread float3& fa_lm)\n{\n    bool _3268 = fa_lm.z > 0.5;\n    bool _3274;\n    if (_3268)\n    {\n        int param = li;\n        _3274 = fa_light_baked(param, _384, fa_light_tex, fa_shadow_smp);\n    }\n    else\n    {\n        _3274 = _3268;\n    }\n    if (_3274)\n    {\n        int param_1 = li;\n        return LightSample{ float3(0.0, 1.0, 0.0), float3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1, _384, fa_light_tex, fa_shadow_smp) + 0.5) };\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _3298 = fa_light_sample_n(param_2, param_3, param_4, _384, fa_light_tex, fa_shadow_smp, fa_light_atlas, fa_env_smp, fa_light_tint, fa_light_is_area);\n    float3 _4332 = _3298.color;\n    float _4334 = _3298.shadow;\n    if ((_3298.type == 0) && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _3298.direction;\n        float _3312 = fa_shadow_factor(param_5, param_6, _384, fa_shadow_smp, gl_FragCoord, _2041, fa_shadow_tex, fa_world_pos);\n        _4334 = _3312;\n        _4332 *= _3312;\n    }\n    else\n    {\n        bool _3323 = _3298.type != 0;\n        bool _3329;\n        if (_3323)\n        {\n            _3329 = _3298.attenuation > 0.0;\n        }\n        else\n        {\n            _3329 = _3323;\n        }\n        if (_3329)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7, _384);\n            int param_9 = li;\n            float3 param_10 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp).xyz;\n            float3 param_11 = world_pos;\n            float3 param_12 = gn;\n            float3 param_13 = _3298.direction;\n            float _3348 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13, _384, fa_light_tex, fa_shadow_smp, gl_FragCoord, _2041, fa_shadow_tex);\n            _4334 = _3348;\n            _4332 *= _3348;\n        }\n    }\n    return LightSample{ _3298.direction, _4332, _3298.attenuation, _4334, _3298._distance, _3298.type };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 light(thread const SurfaceInput& i, thread const Surface& s, thread const LightSample& l)\n{\n    return float3(0.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _2041)\n{\n    if (_2041.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _2977 = int(_2041.fa_shadow_cfg.x + 0.5);\n    float _2987 = dot(world - _2041.fa_shadow_eye.xyz, _2041.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _2992 = _2977 > 0;\n    bool _3001;\n    if (_2992)\n    {\n        int param = _2977 - 1;\n        _3001 = _2987 <= fa_shadow_split_at(param, _2041);\n    }\n    else\n    {\n        _3001 = _2992;\n    }\n    if (_3001)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3007 = _2977 > 1;\n        bool _3014;\n        if (_3007)\n        {\n            _3014 = _2987 > _2041.fa_shadow_split.x;\n        }\n        else\n        {\n            _3014 = _3007;\n        }\n        if (_3014)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3020 = _2977 > 2;\n        bool _3027;\n        if (_3020)\n        {\n            _3027 = _2987 > _2041.fa_shadow_split.y;\n        }\n        else\n        {\n            _3027 = _3020;\n        }\n        if (_3027)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3033 = _2977 > 3;\n        bool _3040;\n        if (_3033)\n        {\n            _3040 = _2987 > _2041.fa_shadow_split.z;\n        }\n        else\n        {\n            _3040 = _3033;\n        }\n        if (_3040)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _384 [[buffer(1)]], constant fa_shadows& _2041 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_env_tex [[texture(6)]], texture2d<float> fa_light_tex [[texture(7)]], texture2d<float> fa_light_atlas [[texture(8)]], texture2d<float> fa_lightmap [[texture(9)]], texture2d<float> fa_decal_tex [[texture(10)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _4148 = fast::normalize(in.fa_world_normal);\n    float3 fa_light_tint;\n    bool fa_light_is_area;\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _4148 = -_4148;\n    }\n    float3 _3733 = fast::normalize(_384.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, _384, fa_light_tex, fa_shadow_smp, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _4148, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _3733, short(gl_FrontFacing) };\n    Surface _3741 = fa_standard_surface(param_1, _384, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _4187 = _3741.albedo;\n    float _4188 = _3741.alpha;\n    float3 _4189 = _3741.normal;\n    float _4190 = _3741.metallic;\n    float _4191 = _3741.roughness;\n    float _4192 = _3741.occlusion;\n    float3 _4193 = _3741.emission;\n    float _4194 = _3741.clearcoat;\n    float _4195 = _3741.clearcoat_roughness;\n    float3 _4196 = _3741.sheen_color;\n    float _4197 = _3741.sheen_roughness;\n    float _4198 = _3741.anisotropy;\n    float _4199 = _3741.anisotropy_rotation;\n    float _4200 = _3741.specular;\n    float _4201 = _3741.ior;\n    float3 _4202 = _3741.specular_color;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _4148, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _3733, short(gl_FrontFacing) };\n    Surface param_3 = _3741;\n    surface(param_2, param_3);\n    _4187 = param_3.albedo;\n    _4188 = param_3.alpha;\n    _4189 = param_3.normal;\n    _4190 = param_3.metallic;\n    _4191 = param_3.roughness;\n    _4192 = param_3.occlusion;\n    _4193 = param_3.emission;\n    _4194 = param_3.clearcoat;\n    _4195 = param_3.clearcoat_roughness;\n    _4196 = param_3.sheen_color;\n    _4197 = param_3.sheen_roughness;\n    _4198 = param_3.anisotropy;\n    _4199 = param_3.anisotropy_rotation;\n    _4200 = param_3.specular;\n    _4201 = param_3.ior;\n    _4202 = param_3.specular_color;\n    float3 param_4 = in.fa_world_pos;\n    float3 param_5 = _4148;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7, _384, fa_light_tex, fa_shadow_smp, fa_env_smp, fa_decal_tex);\n    _4187 = param_6;\n    _4189 = param_7;\n    float3 result;\n    if (_384.fa_emissive.w > 0.5)\n    {\n        result = _4187;\n    }\n    else\n    {\n        float3 _3779 = _4189;\n        float3 _3780 = fast::normalize(_3779);\n        _4189 = _3780;\n        float3 param_8 = _3780;\n        SurfaceInput param_9 = SurfaceInput{ in.fa_world_pos, _4148, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _3733, short(gl_FrontFacing) };\n        Surface param_10 = Surface{ _4187, _4188, _4189, _4190, _4191, _4192, _4193, _4194, _4195, _4196, _4197, _4198, _4199, _4200, _4201, _4202 };\n        float3 param_11 = fa_indirect_diffuse(param_8, _384, fa_env_smp, fa_env_tex, in.fa_lm, fa_lightmap);\n        float3 lit = ambient(param_9, param_10, param_11);\n        int _3799 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _3799; ln++)\n        {\n            int param_12 = ln;\n            int _3812 = fa_cl_light(param_12, _384, fa_light_tex, fa_shadow_smp, fa_cl_ndir, fa_cl_slot);\n            bool _3815 = in.fa_lm.z > 0.5;\n            bool _3821;\n            if (_3815)\n            {\n                int param_13 = _3812;\n                _3821 = fa_light_baked(param_13, _384, fa_light_tex, fa_shadow_smp);\n            }\n            else\n            {\n                _3821 = _3815;\n            }\n            if (_3821)\n            {\n                continue;\n            }\n            int param_14 = _3812;\n            float3 param_15 = in.fa_world_pos;\n            float3 param_16 = _4148;\n            LightSample _3833 = fa_light_shadowed(param_14, param_15, param_16, _384, fa_light_tex, fa_shadow_smp, fa_light_atlas, fa_env_smp, fa_light_tint, fa_light_is_area, gl_FragCoord, _2041, fa_shadow_tex, in.fa_world_pos, in.fa_lm);\n            SurfaceInput param_17 = SurfaceInput{ in.fa_world_pos, _4148, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _3733, short(gl_FrontFacing) };\n            Surface param_18 = Surface{ _4187, _4188, _4189, _4190, _4191, _4192, _4193, _4194, _4195, _4196, _4197, _4198, _4199, _4200, _4201, _4202 };\n            LightSample param_19 = _3833;\n            lit += light(param_17, param_18, param_19);\n        }\n        result = lit;\n    }\n    float3 _3848 = result;\n    float3 _3849 = _3848 + _4193;\n    result = _3849;\n    float3 param_20 = _3849;\n    float3 param_21 = in.fa_world_pos;\n    result = fa_shadow_debug(param_20, param_21, _2041);\n    bool _3858 = _384.fa_fog.w > 0.0;\n    bool _3865;\n    if (!_3858)\n    {\n        _3865 = _384.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _3865 = _3858;\n    }\n    if (_3865)\n    {\n        float3 _3874 = in.fa_world_pos - _384.fa_camera_pos.xyz;\n        float _3880 = dot(_3874, _384.fa_fog_c.xyz);\n        bool _3884 = _384.fa_fog_c.w > 0.5;\n        float _3885;\n        if (_3884)\n        {\n            _3885 = _3880;\n        }\n        else\n        {\n            _3885 = length(_3874);\n        }\n        float _3897 = _3885 - _384.fa_fog_b.x;\n        if (_3897 > 0.0)\n        {\n            float _3906 = _384.fa_fog.w * _3897;\n            float tau = _3906 * _3906;\n            if (_384.fa_fog_b.y > 0.0)\n            {\n                float _3922;\n                if (_3884)\n                {\n                    _3922 = in.fa_world_pos.y - (_384.fa_fog_c.y * _3880);\n                }\n                else\n                {\n                    _3922 = _384.fa_camera_pos.y;\n                }\n                float _3943 = mix(_3922, in.fa_world_pos.y, fast::clamp(_384.fa_fog_b.x / _3885, 0.0, 1.0));\n                float _3947 = in.fa_world_pos.y - _3943;\n                float _3952 = _3943 - _384.fa_fog_b.z;\n                float _3957 = in.fa_world_pos.y - _384.fa_fog_b.z;\n                bool _3960 = _3952 <= 0.0;\n                bool _3961 = !_3960;\n                bool _3967;\n                if (_3961)\n                {\n                    _3967 = _384.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3967 = _3960;\n                }\n                float _3968;\n                if (_3967)\n                {\n                    _3968 = _384.fa_fog_b.y;\n                }\n                else\n                {\n                    _3968 = _384.fa_fog_b.y * exp(-fast::min(_384.fa_fog_b.w * _3952, 80.0));\n                }\n                bool _3995;\n                if (_3961)\n                {\n                    _3995 = _384.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3995 = _3960;\n                }\n                float _3996;\n                if (_3995)\n                {\n                    _3996 = _384.fa_fog_b.y * _3952;\n                }\n                else\n                {\n                    _3996 = (_384.fa_fog_b.y * (1.0 - exp(-fast::min(_384.fa_fog_b.w * _3952, 80.0)))) / _384.fa_fog_b.w;\n                }\n                bool _4021 = _3957 <= 0.0;\n                bool _4028;\n                if (!_4021)\n                {\n                    _4028 = _384.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4028 = _4021;\n                }\n                float _4029;\n                if (_4028)\n                {\n                    _4029 = _384.fa_fog_b.y * _3957;\n                }\n                else\n                {\n                    _4029 = (_384.fa_fog_b.y * (1.0 - exp(-fast::min(_384.fa_fog_b.w * _3957, 80.0)))) / _384.fa_fog_b.w;\n                }\n                float _4056;\n                if (abs(_3947) < 0.001000000047497451305389404296875)\n                {\n                    _4056 = _3968;\n                }\n                else\n                {\n                    _4056 = (_4029 - _3996) / _3947;\n                }\n                tau += (_3897 * fast::max(_4056, 0.0));\n            }\n            result = mix(result, _384.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _4188);\n    return out;\n}\n\n",
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
            "inst_name": "_384",
            "msl_buffer_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2041",
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float3 fa_lm [[user(locn5)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n    float4 fa_joints [[attribute(9)]];\n    float4 fa_weights [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _183)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_183.fa_joint_rows[_174] * weights[i]);\n        r1 += (_183.fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183.fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _136);\n    float3 _388 = _273.world_pos;\n    fa_world_pos = _388;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = _136.fa_view_proj * float4(_388, 1.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _136 [[buffer(0)]], constant fa_skin& _183 [[buffer(3)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float4x4 param_2 = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _183);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7, _136, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.gl_Position);\n    out.fa_lm = float3(0.0);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n#pragma clang diagnostic ignored \"-Wmissing-braces\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\ntemplate<typename T, size_t Num>\nstruct spvUnsafeArray\n{\n    T elements[Num ? Num : 1];\n    \n    thread T& operator [] (size_t pos) thread\n    {\n        return elements[pos];\n    }\n    constexpr const thread T& operator [] (size_t pos) const thread\n    {\n        return elements[pos];\n    }\n    \n    device T& operator [] (size_t pos) device\n    {\n        return elements[pos];\n    }\n    constexpr const device T& operator [] (size_t pos) const device\n    {\n        return elements[pos];\n    }\n    \n    constexpr const constant T& operator [] (size_t pos) const constant\n    {\n        return elements[pos];\n    }\n    \n    threadgroup T& operator [] (size_t pos) threadgroup\n    {\n        return elements[pos];\n    }\n    constexpr const threadgroup T& operator [] (size_t pos) const threadgroup\n    {\n        return elements[pos];\n    }\n};\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n    float4 fa_shadow_lcfg;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float3 fa_lm [[user(locn5)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_cluster_texel(thread const float3& world_pos, constant fa_mesh_fs_params& _384, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    bool _1312 = _384.fa_cl_info.x < 0.0;\n    bool _1319;\n    if (!_1312)\n    {\n        _1319 = _384.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _1319 = _1312;\n    }\n    bool _1327;\n    if (!_1319)\n    {\n        _1327 = _384.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _1327 = _1319;\n    }\n    bool _1334;\n    if (!_1327)\n    {\n        _1334 = _384.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _1334 = _1327;\n    }\n    bool _1341;\n    if (!_1334)\n    {\n        _1341 = _384.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _1341 = _1334;\n    }\n    if (_1341)\n    {\n        return float4(0.0);\n    }\n    float4 _1351 = float4(world_pos, 1.0);\n    float _1357 = dot(_384.fa_cl_vpw, _1351);\n    if (!(_1357 > 9.9999999747524270787835121154785e-07))\n    {\n        return float4(0.0);\n    }\n    float2 _1379 = float2(dot(_384.fa_cl_vpx, _1351), dot(_384.fa_cl_vpy, _1351)) / float2(_1357);\n    int _1383 = int(_384.fa_cl_grid.x);\n    int _1387 = int(_384.fa_cl_grid.y);\n    int param = (int(_384.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_384.fa_cl_fwd.xyz, world_pos) + _384.fa_cl_fwd.w, _384.fa_cl_grid.w) / _384.fa_cl_grid.w) * _384.fa_cl_grid.z)), 0, int(_384.fa_cl_info.y) - 1) * _1387) + clamp(int(floor(((_1379.y * 0.5) + 0.5) * _384.fa_cl_grid.y)), 0, _1387 - 1)) * _1383)) + clamp(int(floor(((_1379.x * 0.5) + 0.5) * _384.fa_cl_grid.x)), 0, _1383 - 1);\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, constant fa_mesh_fs_params& _384, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    float3 param = world_pos;\n    float4 _1463 = fa_cluster_texel(param, _384, fa_light_tex, fa_shadow_smp);\n    return int2(int(_1463.x), int(_1463.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, constant fa_mesh_fs_params& _384, texture2d<float> fa_light_tex, sampler fa_shadow_smp, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_384.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _3241 = fa_cluster_lookup(param, _384, fa_light_tex, fa_shadow_smp);\n    fa_cl_slot = _3241.x;\n    fa_cl_local = _3241.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _3400 = fa_linear_to_srgb(param);\n        c = _3400;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _3408 = fa_srgb_to_linear(param_1);\n            c = _3408;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _267;\n    if (bool(i.front_facing))\n    {\n        _267 = i.world_normal;\n    }\n    else\n    {\n        _267 = -i.world_normal;\n    }\n    float3 _291 = fast::normalize(i.world_tangent.xyz - (_267 * dot(_267, i.world_tangent.xyz)));\n    float3 _318 = fast::normalize(((_291 * m.x) + ((cross(_267, _291) * i.world_tangent.w) * m.y)) + (_267 * m.z));\n    float3 _321;\n    if (bool(i.front_facing))\n    {\n        _321 = _318;\n    }\n    else\n    {\n        _321 = -_318;\n    }\n    return _321;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _384, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _384.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _3439 = fa_tex_fix(param_2, param_3);\n    float4 _4487 = base_t;\n    _4487.x = _3439.x;\n    _4487.y = _3439.y;\n    _4487.z = _3439.z;\n    base_t = _4487;\n    float4 _3453 = (_4487 * _384.fa_base_color) * i.vertex_color;\n    float3 _4352 = i.world_normal;\n    if (_384.fa_maps.z > 0.5)\n    {\n        float param_4 = _384.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _3485 = fa_tex_fix(param_6, param_7);\n        float3 _3488 = (_3485 * 2.0) - float3(1.0);\n        float2 _3493 = _3488.xy * _384.fa_maps.x;\n        float3 _4495 = _3488;\n        _4495.x = _3493.x;\n        _4495.y = _3493.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _4495;\n        _4352 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _384.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _3521 = fa_tex_fix(param_12, param_13);\n    float4 _4498 = mrt;\n    _4498.x = _3521.x;\n    _4498.y = _3521.y;\n    _4498.z = _3521.z;\n    mrt = _4498;\n    float4 _3549 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _384.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _3549.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _3560 = fa_tex_fix(param_16, param_17);\n    float param_18 = _384.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _3590 = fa_tex_fix(param_20, param_21);\n    float _4357 = _384.fa_layers_a.x;\n    float _4358 = _384.fa_layers_a.y;\n    float _4361 = _384.fa_layers_a.z;\n    float _4360 = _384.fa_layers_b.w;\n    float _4363 = _384.fa_layers_c.x;\n    if (_384.fa_layers_c.z > 0.5)\n    {\n        if (mod(_384.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _4357 *= _3560.y;\n            _4358 *= _3560.z;\n            _4360 *= _3549.w;\n        }\n        if (_384.fa_layers_c.z > 1.5)\n        {\n            _4361 *= mrt.x;\n            _4363 *= mrt.w;\n        }\n    }\n    return Surface{ _3453.xyz, _3453.w, _4352, fast::clamp(_384.fa_pbr.x * _3521.z, 0.0, 1.0), fast::clamp(_384.fa_pbr.y * _3521.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_384.fa_maps.y * (_3560.x - 1.0)), _384.fa_emissive.xyz + (_384.fa_model_emissive.xyz * _3590), _4357, _4358, _384.fa_layers_b.xyz, _4360, _4361, _384.fa_layers_a.w, _4363, _384.fa_layers_c.y, _384.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_decal_tile(thread const float4& rect, thread const float2& uv, thread const float2& atlas, thread const float2& ddx, thread const float2& ddy, sampler fa_env_smp, texture2d<float> fa_decal_tex)\n{\n    float2 _1543 = rect.zw - rect.xy;\n    float2 _1547 = _1543 * atlas;\n    float2 _1551 = ddx * _1547;\n    float2 _1555 = ddy * _1547;\n    return fa_decal_tex.sample(fa_env_smp, (rect.xy + (fast::clamp(uv, float2(0.0), float2(1.0)) * _1543)), level(fast::clamp(0.5 * log2(fast::max(fast::max(dot(_1551, _1551), dot(_1555, _1555)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_apply_decals(thread const float3& world_pos, thread const float3& geo_normal, thread float3& albedo, thread float3& normal, constant fa_mesh_fs_params& _384, texture2d<float> fa_light_tex, sampler fa_shadow_smp, sampler fa_env_smp, texture2d<float> fa_decal_tex)\n{\n    bool _1588 = _384.fa_counts.y < 0.5;\n    bool _1595;\n    if (!_1588)\n    {\n        _1595 = _384.fa_counts.w < 0.5;\n    }\n    else\n    {\n        _1595 = _1588;\n    }\n    if (_1595)\n    {\n        return;\n    }\n    float3 _1601 = dfdx(world_pos);\n    float3 _1604 = dfdy(world_pos);\n    float3 param = world_pos;\n    float4 _1608 = fa_cluster_texel(param, _384, fa_light_tex, fa_shadow_smp);\n    int _1612 = int(_1608.w);\n    if (_1612 < 1)\n    {\n        return;\n    }\n    int _1622 = int(_384.fa_counts.y + 0.5);\n    int param_1 = _1622;\n    float4 _1626 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float2 _1629 = _1626.yz;\n    int _1633 = int(_1626.w);\n    int param_2 = _1622 + 1;\n    float4 _1638 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float _1639 = _1638.x;\n    int _1645 = int(_384.fa_counts.w + 0.5) - 1;\n    int _1649 = int(_1608.z);\n    float3 _1914;\n    for (int k = 0; k < _1612; k++)\n    {\n        int _1662 = _1649 + k;\n        int param_3 = _1633 + (_1662 >> 2);\n        int _1679 = (_1622 + 2) + (int(fa_light_texel(param_3, fa_light_tex, fa_shadow_smp)[_1662 & 3]) * 7);\n        int param_4 = _1679 + 6;\n        float4 _1684 = fa_light_texel(param_4, fa_light_tex, fa_shadow_smp);\n        if (((int(_1684.w + 0.5) >> _1645) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1679;\n        float4 _1699 = fa_light_texel(param_5, fa_light_tex, fa_shadow_smp);\n        int param_6 = _1679 + 1;\n        float4 _1704 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n        int param_7 = _1679 + 2;\n        float4 _1709 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n        float3 _1712 = _1699.xyz;\n        float _1717 = dot(_1712, world_pos) + _1699.w;\n        float3 _1719 = _1704.xyz;\n        float _1724 = dot(_1719, world_pos) + _1704.w;\n        float3 _1726 = _1709.xyz;\n        float _1731 = dot(_1726, world_pos) + _1709.w;\n        bool _1736 = abs(_1717) > 0.5;\n        bool _1744;\n        if (!_1736)\n        {\n            _1744 = abs(_1724) > 0.5;\n        }\n        else\n        {\n            _1744 = _1736;\n        }\n        bool _1752;\n        if (!_1744)\n        {\n            _1752 = abs(_1731) > 0.5;\n        }\n        else\n        {\n            _1752 = _1744;\n        }\n        if (_1752)\n        {\n            continue;\n        }\n        float _1767 = fast::clamp(dot(geo_normal, fast::normalize(_1726)) * _1684.z, 0.0, 1.0);\n        if (_1767 <= 0.0)\n        {\n            continue;\n        }\n        float _1787 = (fast::clamp((0.5 - abs(_1731)) * 10.0, 0.0, 1.0) * _1767) * _1684.x;\n        float2 _1795 = float2(_1717 + 0.5, 0.5 - _1724);\n        float2 _1805 = float2(dot(_1712, _1601), dot(_1719, _1601));\n        float2 _1815 = float2(dot(_1712, _1604), dot(_1719, _1604));\n        int param_8 = _1679 + 5;\n        float4 _1820 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n        int param_9 = _1679 + 3;\n        float4 _1825 = fa_light_texel(param_9, fa_light_tex, fa_shadow_smp);\n        int param_10 = _1679 + 4;\n        float4 _1830 = fa_light_texel(param_10, fa_light_tex, fa_shadow_smp);\n        float tex_a = 1.0;\n        float3 col = _1820.xyz;\n        bool _1840 = _1825.z > _1825.x;\n        if (_1840)\n        {\n            float4 param_11 = _1825;\n            float2 param_12 = _1795;\n            float2 param_13 = _1629;\n            float2 param_14 = _1805;\n            float2 param_15 = _1815;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15, fa_env_smp, fa_decal_tex);\n            if ((_1639 > 0.5) && (_1639 < 1.5))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1866 = fa_dc_to_linear(param_16);\n                float4 _4432 = tx;\n                _4432.x = _1866.x;\n                _4432.y = _1866.y;\n                _4432.z = _1866.z;\n                tx = _4432;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, float3(fast::clamp((_1787 * tex_a) * _1820.w, 0.0, 1.0)));\n        if (_1830.z > _1830.x)\n        {\n            float4 param_17 = _1830;\n            float2 param_18 = _1795;\n            float2 param_19 = _1629;\n            float2 param_20 = _1805;\n            float2 param_21 = _1815;\n            float4 _1910 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21, fa_env_smp, fa_decal_tex);\n            if (_1639 > 1.5)\n            {\n                float3 param_22 = _1910.xyz;\n                float3 _1920 = fa_dc_to_srgb(param_22);\n                _1914 = _1920;\n            }\n            else\n            {\n                _1914 = _1910.xyz;\n            }\n            float3 _1929 = (_1914 * 2.0) - float3(1.0);\n            float2 _1934 = _1929.xy * _1684.y;\n            float3 _1956 = (fast::normalize(_1712) * _1934.x) + (fast::normalize(_1719) * _1934.y);\n            float3 _1959 = fast::normalize(normal);\n            normal = fast::normalize(mix(_1959, fast::normalize((_1959 * fast::max(_1929.z, 0.0500000007450580596923828125)) + (_1956 - (_1959 * dot(_1959, _1956)))), float3(fast::clamp(_1787 * (_1840 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_sh_coef(thread const int& k, constant fa_mesh_fs_params& _384, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float3 v = fa_env_tex.sample(fa_env_smp, float3(1.0, 1.0 - (float((2 * (k >> 2)) + 1) * 0.25), 1.0 - (float((2 * (k & 3)) + 1) * 0.25)), level(5.0)).xyz;\n    if (_384.fa_env_sky.w > 1.5)\n    {\n        v = (v - float3(0.5)) * 8.0;\n    }\n    return v;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sh_eval(thread const spvUnsafeArray<float3, 9>& c, thread const float3& n)\n{\n    float3 _3154 = fast::max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), float3(0.0));\n    return _3154;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _384, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    if (_384.fa_env_sky.w > 0.5)\n    {\n        spvUnsafeArray<float3, 9> c;\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param, _384, fa_env_smp, fa_env_tex);\n        }\n        spvUnsafeArray<float3, 9> param_1 = c;\n        float3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return _384.fa_ambient.xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_indirect_diffuse(thread const float3& n, constant fa_mesh_fs_params& _384, sampler fa_env_smp, texturecube<float> fa_env_tex, thread float3& fa_lm, texture2d<float> fa_lightmap)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return fa_lightmap.sample(fa_env_smp, fa_lm.xy, level(0.0)).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param, _384, fa_env_smp, fa_env_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 ambient(thread const SurfaceInput& i, thread const Surface& s, thread const float3& ambientColor)\n{\n    return ambientColor;\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, constant fa_mesh_fs_params& _384, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (int(_384.fa_cl_info.x) + int(_384.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, constant fa_mesh_fs_params& _384, texture2d<float> fa_light_tex, sampler fa_shadow_smp, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, _384, fa_light_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_light_base(thread const int& li, constant fa_mesh_fs_params& _384)\n{\n    return li * ((_384.fa_ambient.w > 4.5) ? 8 : 4);\n}\n\nstatic inline __attribute__((always_inline))\nbool fa_light_baked(thread const int& li, constant fa_mesh_fs_params& _384, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li;\n    int param_1 = fa_light_base(param, _384) + 3;\n    return fa_light_texel(param_1, fa_light_tex, fa_shadow_smp).w > 0.5;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_light_type(thread const int& li, constant fa_mesh_fs_params& _384, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li;\n    int param_1 = fa_light_base(param, _384) + 1;\n    return fa_light_texel(param_1, fa_light_tex, fa_shadow_smp).w;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_atlas_fetch(thread const float2& texel, texture2d<float> fa_light_atlas, sampler fa_env_smp)\n{\n    return fa_light_atlas.sample(fa_env_smp, (texel / float2(int2(fa_light_atlas.get_width(), fa_light_atlas.get_height()))), level(0.0));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_cookie_sample(thread const float2& tile_origin, thread const float2& uv, texture2d<float> fa_light_atlas, sampler fa_env_smp)\n{\n    float2 param = (tile_origin + float2(1.0)) + (fast::clamp(uv, float2(0.0), float2(1.0)) * 254.0);\n    return fa_atlas_fetch(param, fa_light_atlas, fa_env_smp).xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_area_point(thread const float3& c, thread const float3& axis, thread const float3& ru, thread const float3& uu, thread const float& hx, thread const float& hy, thread const float& shape, thread const float3& p, thread const float3& r)\n{\n    bool _562 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        float3 _575 = (c - (ru * hx)) - p;\n        float3 _581 = ru * (2.0 * hx);\n        float _587 = fast::max(dot(_581, _581), 9.9999999392252902907785028219223e-09);\n        float _591 = dot(_575, _581);\n        float t = fast::clamp((-_591) / _587, 0.0, 1.0);\n        if (_562)\n        {\n            float _606 = dot(r, _581);\n            float _612 = _587 - (_606 * _606);\n            if (abs(_612) > (9.9999997473787516355514526367188e-06 * _587))\n            {\n                t = fast::clamp(((dot(r, _575) * _606) - _591) / _612, 0.0, 1.0);\n            }\n        }\n        return (p + _575) + (_581 * t);\n    }\n    float3 q = p;\n    float _644 = dot(r, axis);\n    bool _652;\n    if (_562)\n    {\n        _652 = abs(_644) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _652 = _562;\n    }\n    if (_652)\n    {\n        float _662 = dot(c - p, axis) / _644;\n        if (_662 > 0.0)\n        {\n            q = p + (r * _662);\n        }\n    }\n    float3 _675 = q - c;\n    float2 xy = float2(dot(_675, ru), dot(_675, uu));\n    if (shape > 0.5)\n    {\n        float _690 = length(xy);\n        if (_690 > hx)\n        {\n            xy *= (hx / _690);\n        }\n    }\n    else\n    {\n        xy = fast::clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cube_face(thread const float3& d)\n{\n    float3 _333 = abs(d);\n    float _335 = _333.x;\n    float _337 = _333.y;\n    bool _338 = _335 >= _337;\n    bool _346;\n    if (_338)\n    {\n        _346 = _335 >= _333.z;\n    }\n    else\n    {\n        _346 = _338;\n    }\n    int _347;\n    if (_346)\n    {\n        _347 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _362;\n        if (_337 >= _333.z)\n        {\n            _362 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _362 = (d.z > 0.0) ? 4 : 5;\n        }\n        _347 = _362;\n    }\n    return _347;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cube_face_basis(thread const int& f, thread float3& fwd, thread float3& up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0, 0.0, 0.0);\n        up = float3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0, 0.0, 0.0);\n            up = float3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0, 1.0, 0.0);\n                up = float3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0, -1.0, 0.0);\n                    up = float3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0, 0.0, 1.0);\n                        up = float3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0, 0.0, -1.0);\n                        up = float3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_ies_sample(thread const float2& tile_origin, thread const float3& d, thread const float3& axis, thread const float3& right, thread const float3& up, texture2d<float> fa_light_atlas, sampler fa_env_smp)\n{\n    float _482 = dot(d, right);\n    float _486 = dot(d, up);\n    float _497;\n    if (((_482 * _482) + (_486 * _486)) > 1.0000000133514319600180897396058e-10)\n    {\n        _497 = precise::atan2(_486, _482) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _497 = 0.0;\n    }\n    float2 param = tile_origin + float2(1.0 + ((_497 - floor(_497)) * 64.0), 1.0 + (acos(fast::clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param, fa_light_atlas, fa_env_smp).x;\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample_n(thread const int& li, thread const float3& world_pos, thread const float3& n, constant fa_mesh_fs_params& _384, texture2d<float> fa_light_tex, sampler fa_shadow_smp, texture2d<float> fa_light_atlas, sampler fa_env_smp, thread float3& fa_light_tint, thread bool& fa_light_is_area)\n{\n    int param = li;\n    int _728 = fa_light_base(param, _384);\n    bool _732 = _384.fa_ambient.w > 4.5;\n    int param_1 = _728;\n    float4 _736 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    int param_2 = _728 + 1;\n    float4 _741 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float _744 = _741.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = float3(1.0);\n    bool _756 = _732 && (_744 > 2.5);\n    fa_light_is_area = _756;\n    bool _758 = _744 < 0.5;\n    float3 l;\n    if (_758)\n    {\n        l = fast::normalize(_736.xyz);\n        if (_732)\n        {\n            int param_3 = _728 + 6;\n            float4 _772 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            if (_772.z > 0.5)\n            {\n                int param_4 = _728 + 4;\n                float4 _782 = fa_light_texel(param_4, fa_light_tex, fa_shadow_smp);\n                int param_5 = _728 + 5;\n                float4 _787 = fa_light_texel(param_5, fa_light_tex, fa_shadow_smp);\n                float2 param_6 = _772.xy;\n                float2 param_7 = fract(float2(dot(world_pos, _782.xyz) * _782.w, (-dot(world_pos, _787.xyz)) * _787.w) + float2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7, fa_light_atlas, fa_env_smp);\n            }\n        }\n    }\n    else\n    {\n        float3 _817 = _736.xyz;\n        float3 _819 = _817 - world_pos;\n        float3 to_light = _819;\n        float _822 = length(_819);\n        float reach = _822;\n        bool front = true;\n        if (_756)\n        {\n            int param_8 = _728 + 7;\n            reach = fast::max(_822 - fa_light_texel(param_8, fa_light_tex, fa_shadow_smp).w, 0.0);\n            int param_9 = _728 + 4;\n            float4 _846 = fa_light_texel(param_9, fa_light_tex, fa_shadow_smp);\n            int param_10 = _728 + 5;\n            float4 _851 = fa_light_texel(param_10, fa_light_tex, fa_shadow_smp);\n            int param_11 = _728 + 6;\n            float4 _856 = fa_light_texel(param_11, fa_light_tex, fa_shadow_smp);\n            float _857 = _856.w;\n            int param_12 = _728 + 2;\n            float3 _864 = fast::normalize(fa_light_texel(param_12, fa_light_tex, fa_shadow_smp).xyz);\n            bool _866 = _857 > 1.5;\n            bool _874;\n            if (!_866)\n            {\n                _874 = dot(_864, to_light) < 0.0;\n            }\n            else\n            {\n                _874 = _866;\n            }\n            front = _874;\n            float3 r = float3(0.0);\n            float3 _883 = _384.fa_camera_pos.xyz - world_pos;\n            bool _887 = dot(n, n) > 0.5;\n            bool _895;\n            if (_887)\n            {\n                _895 = dot(_883, _883) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _895 = _887;\n            }\n            if (_895)\n            {\n                r = reflect(-fast::normalize(_883), fast::normalize(n));\n            }\n            float3 param_13 = _817;\n            float3 param_14 = _864;\n            float3 param_15 = _846.xyz;\n            float3 param_16 = _851.xyz;\n            float param_17 = _846.w;\n            float param_18 = _851.w;\n            float param_19 = _857;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _931 = length(to_light);\n        dist = _931;\n        l = to_light / float3(fast::max(_931, 9.9999997473787516355514526367188e-05));\n        float _945 = reach / fast::max(_736.w, 0.001000000047497451305389404296875);\n        float _951 = fast::clamp(1.0 - (_945 * _945), 0.0, 1.0);\n        float _953;\n        if (front)\n        {\n            _953 = _951 * _951;\n        }\n        else\n        {\n            _953 = 0.0;\n        }\n        atten = _953;\n        bool _964 = _744 < 2.5;\n        if ((_744 > 1.5) && _964)\n        {\n            int param_22 = _728 + 2;\n            float4 _972 = fa_light_texel(param_22, fa_light_tex, fa_shadow_smp);\n            float _982 = _972.w;\n            int param_23 = _728 + 3;\n            float4 _987 = fa_light_texel(param_23, fa_light_tex, fa_shadow_smp);\n            float _988 = _987.x;\n            float cos_inner = _988;\n            if (_988 > 1.5)\n            {\n                cos_inner = mix(_982, 1.0, 0.25);\n            }\n            atten *= smoothstep(_982, cos_inner, dot(-l, fast::normalize(_972.xyz)));\n        }\n        if (_732 && (_744 < 1.5))\n        {\n            int param_24 = _728 + 6;\n            float4 _1012 = fa_light_texel(param_24, fa_light_tex, fa_shadow_smp);\n            if (_1012.z > 0.5)\n            {\n                float3 _1020 = -to_light;\n                int param_25 = _728 + 4;\n                int param_26 = _728 + 5;\n                float3 _1034 = fa_light_texel(param_25, fa_light_tex, fa_shadow_smp).xyz;\n                float3 _1038 = fa_light_texel(param_26, fa_light_tex, fa_shadow_smp).xyz;\n                float3 _1047 = float3(dot(_1020, _1034), dot(_1020, _1038), dot(_1020, cross(_1034, _1038)));\n                float3 param_27 = _1047;\n                int _1051 = fa_cube_face(param_27);\n                int param_28 = _1051;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1078 = float2(dot(_1047, cross(param_29, param_30)), dot(_1047, param_30)) / float2(fast::max(dot(_1047, param_29), 9.9999997473787516355514526367188e-05));\n                int _1082 = _1051 / 3;\n                float2 param_31 = _1012.xy + (float2(float(_1051 - (_1082 * 3)), float(_1082)) * 256.0);\n                float2 param_32 = float2(0.5 + (0.5 * _1078.x), 0.5 - (0.5 * _1078.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32, fa_light_atlas, fa_env_smp);\n            }\n            int param_33 = _728 + 7;\n            float4 _1112 = fa_light_texel(param_33, fa_light_tex, fa_shadow_smp);\n            if (_1112.z > 0.5)\n            {\n                int param_34 = _728 + 2;\n                int param_35 = _728 + 4;\n                int param_36 = _728 + 5;\n                float2 param_37 = _1112.xy;\n                float3 param_38 = -l;\n                float3 param_39 = fast::normalize(fa_light_texel(param_34, fa_light_tex, fa_shadow_smp).xyz);\n                float3 param_40 = fa_light_texel(param_35, fa_light_tex, fa_shadow_smp).xyz;\n                float3 param_41 = fa_light_texel(param_36, fa_light_tex, fa_shadow_smp).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41, fa_light_atlas, fa_env_smp);\n            }\n        }\n        else\n        {\n            if (_732 && _964)\n            {\n                int param_42 = _728 + 6;\n                float4 _1159 = fa_light_texel(param_42, fa_light_tex, fa_shadow_smp);\n                int param_43 = _728 + 7;\n                float4 _1164 = fa_light_texel(param_43, fa_light_tex, fa_shadow_smp);\n                bool _1167 = _1159.z > 0.5;\n                bool _1174;\n                if (!_1167)\n                {\n                    _1174 = _1164.z > 0.5;\n                }\n                else\n                {\n                    _1174 = _1167;\n                }\n                if (_1174)\n                {\n                    int param_44 = _728 + 2;\n                    float4 _1181 = fa_light_texel(param_44, fa_light_tex, fa_shadow_smp);\n                    float3 _1185 = fast::normalize(_1181.xyz);\n                    int param_45 = _728 + 4;\n                    float4 _1190 = fa_light_texel(param_45, fa_light_tex, fa_shadow_smp);\n                    int param_46 = _728 + 5;\n                    float4 _1195 = fa_light_texel(param_46, fa_light_tex, fa_shadow_smp);\n                    if (_1167)\n                    {\n                        float3 _1203 = -to_light;\n                        float _1210 = _1181.w;\n                        float _1226 = 0.5 / fast::max(dot(_1203, _1185) * (sqrt(fast::max(1.0 - (_1210 * _1210), 0.0)) / fast::max(_1210, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        float2 param_47 = _1159.xy;\n                        float2 param_48 = float2(0.5 + (dot(_1203, _1190.xyz) * _1226), 0.5 - (dot(_1203, _1195.xyz) * _1226));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48, fa_light_atlas, fa_env_smp);\n                    }\n                    if (_1164.z > 0.5)\n                    {\n                        float2 param_49 = _1164.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1185;\n                        float3 param_52 = _1190.xyz;\n                        float3 param_53 = _1195.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53, fa_light_atlas, fa_env_smp);\n                    }\n                }\n            }\n        }\n    }\n    float3 _4306 = _741.xyz * atten;\n    if (_732)\n    {\n        _4306 *= fa_light_tint;\n    }\n    int _1294;\n    if (_758)\n    {\n        _1294 = 0;\n    }\n    else\n    {\n        _1294 = ((_744 > 1.5) && (_744 < 2.5)) ? 2 : 1;\n    }\n    return LightSample{ l, _4306, atten, 1.0, dist, _1294 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _2041)\n{\n    float _2031;\n    if (i == 0)\n    {\n        _2031 = _2041.fa_shadow_split.x;\n    }\n    else\n    {\n        float _2047;\n        if (i == 1)\n        {\n            _2047 = _2041.fa_shadow_split.y;\n        }\n        else\n        {\n            float _2055;\n            if (i == 2)\n            {\n                _2055 = _2041.fa_shadow_split.z;\n            }\n            else\n            {\n                _2055 = _2041.fa_shadow_split.w;\n            }\n            _2047 = _2055;\n        }\n        _2031 = _2047;\n    }\n    return _2031;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_fetch(thread const float2& uv, thread const float4& rect, thread const float3& conv, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2088 = fa_shadow_depth(param, param_1, fa_shadow_smp, fa_shadow_tex);\n    float _2092;\n    if (conv.x < 0.5)\n    {\n        _2092 = _2088;\n    }\n    else\n    {\n        _2092 = (conv.y * conv.z) / (conv.z - (_2088 * (conv.z - conv.y)));\n    }\n    return _2092;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _2019 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_2019), sin(_2019)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_filter(thread const float2& uv, thread const float4& rect, thread const float& zr, thread const float& texel_m, thread const float& unit, thread const float& reach, thread const float& plane, thread const float3& conv, thread const int& mode, thread const float& k, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2041, texture2d<float> fa_shadow_tex)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2, fa_shadow_smp, fa_shadow_tex));\n    }\n    float _2138 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2147;\n        if (k < 0.0)\n        {\n            _2147 = (-k) / fast::max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2147 = k;\n        }\n        float _2167 = fast::clamp((_2147 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2138;\n            float2 _2186 = fa_shadow_vogel(param_3, param_4, param_5) * _2167;\n            float2 param_6 = uv + (_2186 * _2041.fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _2198 = fa_shadow_fetch(param_6, param_7, param_8, fa_shadow_smp, fa_shadow_tex);\n            if (_2198 < (zr - (length(_2186) * plane)))\n            {\n                sum += _2198;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2224 = sum / cnt;\n        float _2234;\n        if (k < 0.0)\n        {\n            _2234 = (-k) / fast::max(_2224, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2234 = k;\n        }\n        radius = fast::clamp(((fast::max(zr - _2224, 0.0) * unit) * _2234) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _2256 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2256; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2256;\n        float param_11 = _2138;\n        float2 _2275 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_2275 * _2041.fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_2275) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14, fa_shadow_smp, fa_shadow_tex));\n    }\n    return lit / float(_2256);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2041, texture2d<float> fa_shadow_tex)\n{\n    float _2317 = fast::max(_2041.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _2322 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _2328 = sqrt(1.0 - (_2322 * _2322));\n    float _2335 = fast::min(_2328 / fast::max(_2322, 0.20000000298023223876953125), 4.0);\n    float _2340;\n    if (_2041.fa_shadow_bias.y > 0.0)\n    {\n        _2340 = _2041.fa_shadow_bias.y;\n    }\n    else\n    {\n        _2340 = 1.5 * _2041.fa_shadow_info[ci].x;\n    }\n    float4 _2365 = _2041.fa_shadow_mat[ci] * float4(world + (n * (_2340 * _2328)), 1.0);\n    float _2372 = _2365.x;\n    bool _2375 = _2372 < _2041.fa_shadow_rect[ci].x;\n    bool _2384;\n    if (!_2375)\n    {\n        _2384 = _2372 > _2041.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2384 = _2375;\n    }\n    bool _2393;\n    if (!_2384)\n    {\n        _2393 = _2365.y < _2041.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2393 = _2384;\n    }\n    bool _2402;\n    if (!_2393)\n    {\n        _2402 = _2365.y > _2041.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2402 = _2393;\n    }\n    bool _2409;\n    if (!_2402)\n    {\n        _2409 = _2365.z > 1.0;\n    }\n    else\n    {\n        _2409 = _2402;\n    }\n    if (_2409)\n    {\n        return -1.0;\n    }\n    float _2417;\n    if (_2041.fa_shadow_bias.x > 0.0)\n    {\n        _2417 = _2041.fa_shadow_bias.x;\n    }\n    else\n    {\n        _2417 = 1.5 * _2041.fa_shadow_info[ci].x;\n    }\n    float2 param = _2365.xy;\n    float4 param_1 = _2041.fa_shadow_rect[ci];\n    float param_2 = _2365.z - ((_2417 * (1.0 + (0.5 * _2335))) / _2317);\n    float param_3 = _2041.fa_shadow_info[ci].x;\n    float param_4 = _2317;\n    float param_5 = _2317 * 0.25;\n    float param_6 = ((_2041.fa_shadow_info[ci].x * fast::min(_2335, 3.0)) * 0.5) / _2317;\n    float3 param_7 = float3(0.0);\n    int param_8 = int(_2041.fa_shadow_cfg.z + 0.5);\n    float param_9 = _2041.fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9, fa_shadow_smp, gl_FragCoord, _2041, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _384, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2041, texture2d<float> fa_shadow_tex)\n{\n    if (_384.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2795 = int(_2041.fa_shadow_cfg.x + 0.5);\n    if (_2795 < 1)\n    {\n        return 1.0;\n    }\n    float _2810 = dot(world - _2041.fa_shadow_eye.xyz, _2041.fa_shadow_fwd.xyz);\n    int param = _2795 - 1;\n    if (_2810 > fa_shadow_split_at(param, _2041))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2822 = _2795 > 1;\n    bool _2829;\n    if (_2822)\n    {\n        _2829 = _2810 > _2041.fa_shadow_split.x;\n    }\n    else\n    {\n        _2829 = _2822;\n    }\n    if (_2829)\n    {\n        ci = 1;\n    }\n    bool _2833 = _2795 > 2;\n    bool _2840;\n    if (_2833)\n    {\n        _2840 = _2810 > _2041.fa_shadow_split.y;\n    }\n    else\n    {\n        _2840 = _2833;\n    }\n    if (_2840)\n    {\n        ci = 2;\n    }\n    bool _2844 = _2795 > 3;\n    bool _2851;\n    if (_2844)\n    {\n        _2851 = _2810 > _2041.fa_shadow_split.z;\n    }\n    else\n    {\n        _2851 = _2844;\n    }\n    if (_2851)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2795)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2877 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_shadow_smp, gl_FragCoord, _2041, fa_shadow_tex);\n        s = _2877;\n        if (_2877 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_2041.fa_shadow_cfg.y > 0.0)\n    {\n        float _2902;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2902 = fa_shadow_split_at(param_5, _2041);\n        }\n        else\n        {\n            _2902 = _2041.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _2921 = _2041.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _2041) - _2902, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2932 = fast::clamp((_2810 - (fa_shadow_split_at(param_7, _2041) - _2921)) / _2921, 0.0, 1.0);\n        if (_2932 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2795)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _2953 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_shadow_smp, gl_FragCoord, _2041, fa_shadow_tex);\n                s2 = _2953;\n                if (_2953 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2932);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _384, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2041, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, _384, fa_shadow_smp, gl_FragCoord, _2041, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_local(thread const int& li, thread const float3& lpos, thread const float3& world, thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _384, texture2d<float> fa_light_tex, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2041, texture2d<float> fa_shadow_tex)\n{\n    bool _2475 = _384.fa_pbr.z < 0.5;\n    bool _2482;\n    if (!_2475)\n    {\n        _2482 = _2041.fa_shadow_lcfg.x < 0.5;\n    }\n    else\n    {\n        _2482 = _2475;\n    }\n    if (_2482)\n    {\n        return 1.0;\n    }\n    int param = (int(_2041.fa_shadow_lcfg.x + 0.5) - 1) + li;\n    float4 _2495 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    float _2496 = _2495.x;\n    if (_2496 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2505 = int(_2496 + 0.5);\n    int param_1 = _2505;\n    float4 _2509 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    int param_2 = _2505 + 1;\n    float4 _2514 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float fade = 1.0;\n    float _2517 = _2509.y;\n    if (_2517 > 0.0)\n    {\n        float _2534 = 1.0 - smoothstep(0.75 * _2517, _2517, length(world - _2041.fa_shadow_eye.xyz));\n        fade = _2534;\n        if (_2534 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2509.x > 1.5)\n    {\n        float3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2558 = (_2505 + 2) + (face * 6);\n    int param_4 = _2558;\n    int param_5 = _2558 + 1;\n    int param_6 = _2558 + 3;\n    float4 _2572 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n    int param_7 = _2558 + 4;\n    float4 _2577 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n    int param_8 = _2558 + 5;\n    float4 _2582 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n    float _2594 = _2582.x * fast::max(dot(_2572, float4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2599 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _2622 = fast::clamp(dot(n, _2572.xyz), -1.0, 1.0);\n    float _2641 = fast::min(sqrt(1.0 - (_2622 * _2622)) / fast::max(abs(dot(n, world - lpos)) / fast::max(dot(_2572, float4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2644 = _2514.y;\n    float _2646;\n    if (_2644 > 0.0)\n    {\n        _2646 = _2644;\n    }\n    else\n    {\n        _2646 = 1.5 * _2594;\n    }\n    float4 _2666 = float4(world + (n * (_2646 * sqrt(1.0 - (_2599 * _2599)))), 1.0);\n    float _2670 = dot(_2572, _2666);\n    float _2673 = _2582.y;\n    if (_2670 < _2673)\n    {\n        return 1.0;\n    }\n    float2 _2688 = float2(dot(fa_light_texel(param_4, fa_light_tex, fa_shadow_smp), _2666), dot(fa_light_texel(param_5, fa_light_tex, fa_shadow_smp), _2666)) / float2(_2670);\n    float _2690 = _2688.x;\n    bool _2693 = _2690 < _2577.x;\n    bool _2702;\n    if (!_2693)\n    {\n        _2702 = _2690 > _2577.z;\n    }\n    else\n    {\n        _2702 = _2693;\n    }\n    bool _2711;\n    if (!_2702)\n    {\n        _2711 = _2688.y < _2577.y;\n    }\n    else\n    {\n        _2711 = _2702;\n    }\n    bool _2720;\n    if (!_2711)\n    {\n        _2720 = _2688.y > _2577.w;\n    }\n    else\n    {\n        _2720 = _2711;\n    }\n    if (_2720)\n    {\n        return 1.0;\n    }\n    float _2726 = _2514.x;\n    float _2728;\n    if (_2726 > 0.0)\n    {\n        _2728 = _2726;\n    }\n    else\n    {\n        _2728 = 1.5 * _2594;\n    }\n    float2 param_9 = _2688;\n    float4 param_10 = _2577;\n    float param_11 = _2670 - (_2728 * (1.0 + (0.5 * _2641)));\n    float param_12 = _2594;\n    float param_13 = 1.0;\n    float param_14 = _2582.z * 0.25;\n    float param_15 = (_2594 * fast::min(_2641, 3.0)) * 0.5;\n    float3 param_16 = float3(1.0, _2673, _2582.z);\n    int param_17 = int(_2509.z + 0.5);\n    float param_18 = _2509.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, fa_shadow_smp, gl_FragCoord, _2041, fa_shadow_tex), fade);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, constant fa_mesh_fs_params& _384, texture2d<float> fa_light_tex, sampler fa_shadow_smp, texture2d<float> fa_light_atlas, sampler fa_env_smp, thread float3& fa_light_tint, thread bool& fa_light_is_area, thread float4& gl_FragCoord, constant fa_shadows& _2041, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos, thread float3& fa_lm)\n{\n    bool _3268 = fa_lm.z > 0.5;\n    bool _3274;\n    if (_3268)\n    {\n        int param = li;\n        _3274 = fa_light_baked(param, _384, fa_light_tex, fa_shadow_smp);\n    }\n    else\n    {\n        _3274 = _3268;\n    }\n    if (_3274)\n    {\n        int param_1 = li;\n        return LightSample{ float3(0.0, 1.0, 0.0), float3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1, _384, fa_light_tex, fa_shadow_smp) + 0.5) };\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _3298 = fa_light_sample_n(param_2, param_3, param_4, _384, fa_light_tex, fa_shadow_smp, fa_light_atlas, fa_env_smp, fa_light_tint, fa_light_is_area);\n    float3 _4332 = _3298.color;\n    float _4334 = _3298.shadow;\n    if ((_3298.type == 0) && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _3298.direction;\n        float _3312 = fa_shadow_factor(param_5, param_6, _384, fa_shadow_smp, gl_FragCoord, _2041, fa_shadow_tex, fa_world_pos);\n        _4334 = _3312;\n        _4332 *= _3312;\n    }\n    else\n    {\n        bool _3323 = _3298.type != 0;\n        bool _3329;\n        if (_3323)\n        {\n            _3329 = _3298.attenuation > 0.0;\n        }\n        else\n        {\n            _3329 = _3323;\n        }\n        if (_3329)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7, _384);\n            int param_9 = li;\n            float3 param_10 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp).xyz;\n            float3 param_11 = world_pos;\n            float3 param_12 = gn;\n            float3 param_13 = _3298.direction;\n            float _3348 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13, _384, fa_light_tex, fa_shadow_smp, gl_FragCoord, _2041, fa_shadow_tex);\n            _4334 = _3348;\n            _4332 *= _3348;\n        }\n    }\n    return LightSample{ _3298.direction, _4332, _3298.attenuation, _4334, _3298._distance, _3298.type };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 light(thread const SurfaceInput& i, thread const Surface& s, thread const LightSample& l)\n{\n    return float3(0.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _2041)\n{\n    if (_2041.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _2977 = int(_2041.fa_shadow_cfg.x + 0.5);\n    float _2987 = dot(world - _2041.fa_shadow_eye.xyz, _2041.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _2992 = _2977 > 0;\n    bool _3001;\n    if (_2992)\n    {\n        int param = _2977 - 1;\n        _3001 = _2987 <= fa_shadow_split_at(param, _2041);\n    }\n    else\n    {\n        _3001 = _2992;\n    }\n    if (_3001)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3007 = _2977 > 1;\n        bool _3014;\n        if (_3007)\n        {\n            _3014 = _2987 > _2041.fa_shadow_split.x;\n        }\n        else\n        {\n            _3014 = _3007;\n        }\n        if (_3014)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3020 = _2977 > 2;\n        bool _3027;\n        if (_3020)\n        {\n            _3027 = _2987 > _2041.fa_shadow_split.y;\n        }\n        else\n        {\n            _3027 = _3020;\n        }\n        if (_3027)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3033 = _2977 > 3;\n        bool _3040;\n        if (_3033)\n        {\n            _3040 = _2987 > _2041.fa_shadow_split.z;\n        }\n        else\n        {\n            _3040 = _3033;\n        }\n        if (_3040)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _384 [[buffer(1)]], constant fa_shadows& _2041 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_env_tex [[texture(6)]], texture2d<float> fa_light_tex [[texture(7)]], texture2d<float> fa_light_atlas [[texture(8)]], texture2d<float> fa_lightmap [[texture(9)]], texture2d<float> fa_decal_tex [[texture(10)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _4148 = fast::normalize(in.fa_world_normal);\n    float3 fa_light_tint;\n    bool fa_light_is_area;\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _4148 = -_4148;\n    }\n    float3 _3733 = fast::normalize(_384.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, _384, fa_light_tex, fa_shadow_smp, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _4148, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _3733, short(gl_FrontFacing) };\n    Surface _3741 = fa_standard_surface(param_1, _384, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _4187 = _3741.albedo;\n    float _4188 = _3741.alpha;\n    float3 _4189 = _3741.normal;\n    float _4190 = _3741.metallic;\n    float _4191 = _3741.roughness;\n    float _4192 = _3741.occlusion;\n    float3 _4193 = _3741.emission;\n    float _4194 = _3741.clearcoat;\n    float _4195 = _3741.clearcoat_roughness;\n    float3 _4196 = _3741.sheen_color;\n    float _4197 = _3741.sheen_roughness;\n    float _4198 = _3741.anisotropy;\n    float _4199 = _3741.anisotropy_rotation;\n    float _4200 = _3741.specular;\n    float _4201 = _3741.ior;\n    float3 _4202 = _3741.specular_color;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _4148, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _3733, short(gl_FrontFacing) };\n    Surface param_3 = _3741;\n    surface(param_2, param_3);\n    _4187 = param_3.albedo;\n    _4188 = param_3.alpha;\n    _4189 = param_3.normal;\n    _4190 = param_3.metallic;\n    _4191 = param_3.roughness;\n    _4192 = param_3.occlusion;\n    _4193 = param_3.emission;\n    _4194 = param_3.clearcoat;\n    _4195 = param_3.clearcoat_roughness;\n    _4196 = param_3.sheen_color;\n    _4197 = param_3.sheen_roughness;\n    _4198 = param_3.anisotropy;\n    _4199 = param_3.anisotropy_rotation;\n    _4200 = param_3.specular;\n    _4201 = param_3.ior;\n    _4202 = param_3.specular_color;\n    float3 param_4 = in.fa_world_pos;\n    float3 param_5 = _4148;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7, _384, fa_light_tex, fa_shadow_smp, fa_env_smp, fa_decal_tex);\n    _4187 = param_6;\n    _4189 = param_7;\n    float3 result;\n    if (_384.fa_emissive.w > 0.5)\n    {\n        result = _4187;\n    }\n    else\n    {\n        float3 _3779 = _4189;\n        float3 _3780 = fast::normalize(_3779);\n        _4189 = _3780;\n        float3 param_8 = _3780;\n        SurfaceInput param_9 = SurfaceInput{ in.fa_world_pos, _4148, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _3733, short(gl_FrontFacing) };\n        Surface param_10 = Surface{ _4187, _4188, _4189, _4190, _4191, _4192, _4193, _4194, _4195, _4196, _4197, _4198, _4199, _4200, _4201, _4202 };\n        float3 param_11 = fa_indirect_diffuse(param_8, _384, fa_env_smp, fa_env_tex, in.fa_lm, fa_lightmap);\n        float3 lit = ambient(param_9, param_10, param_11);\n        int _3799 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _3799; ln++)\n        {\n            int param_12 = ln;\n            int _3812 = fa_cl_light(param_12, _384, fa_light_tex, fa_shadow_smp, fa_cl_ndir, fa_cl_slot);\n            bool _3815 = in.fa_lm.z > 0.5;\n            bool _3821;\n            if (_3815)\n            {\n                int param_13 = _3812;\n                _3821 = fa_light_baked(param_13, _384, fa_light_tex, fa_shadow_smp);\n            }\n            else\n            {\n                _3821 = _3815;\n            }\n            if (_3821)\n            {\n                continue;\n            }\n            int param_14 = _3812;\n            float3 param_15 = in.fa_world_pos;\n            float3 param_16 = _4148;\n            LightSample _3833 = fa_light_shadowed(param_14, param_15, param_16, _384, fa_light_tex, fa_shadow_smp, fa_light_atlas, fa_env_smp, fa_light_tint, fa_light_is_area, gl_FragCoord, _2041, fa_shadow_tex, in.fa_world_pos, in.fa_lm);\n            SurfaceInput param_17 = SurfaceInput{ in.fa_world_pos, _4148, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _3733, short(gl_FrontFacing) };\n            Surface param_18 = Surface{ _4187, _4188, _4189, _4190, _4191, _4192, _4193, _4194, _4195, _4196, _4197, _4198, _4199, _4200, _4201, _4202 };\n            LightSample param_19 = _3833;\n            lit += light(param_17, param_18, param_19);\n        }\n        result = lit;\n    }\n    float3 _3848 = result;\n    float3 _3849 = _3848 + _4193;\n    result = _3849;\n    float3 param_20 = _3849;\n    float3 param_21 = in.fa_world_pos;\n    result = fa_shadow_debug(param_20, param_21, _2041);\n    bool _3858 = _384.fa_fog.w > 0.0;\n    bool _3865;\n    if (!_3858)\n    {\n        _3865 = _384.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _3865 = _3858;\n    }\n    if (_3865)\n    {\n        float3 _3874 = in.fa_world_pos - _384.fa_camera_pos.xyz;\n        float _3880 = dot(_3874, _384.fa_fog_c.xyz);\n        bool _3884 = _384.fa_fog_c.w > 0.5;\n        float _3885;\n        if (_3884)\n        {\n            _3885 = _3880;\n        }\n        else\n        {\n            _3885 = length(_3874);\n        }\n        float _3897 = _3885 - _384.fa_fog_b.x;\n        if (_3897 > 0.0)\n        {\n            float _3906 = _384.fa_fog.w * _3897;\n            float tau = _3906 * _3906;\n            if (_384.fa_fog_b.y > 0.0)\n            {\n                float _3922;\n                if (_3884)\n                {\n                    _3922 = in.fa_world_pos.y - (_384.fa_fog_c.y * _3880);\n                }\n                else\n                {\n                    _3922 = _384.fa_camera_pos.y;\n                }\n                float _3943 = mix(_3922, in.fa_world_pos.y, fast::clamp(_384.fa_fog_b.x / _3885, 0.0, 1.0));\n                float _3947 = in.fa_world_pos.y - _3943;\n                float _3952 = _3943 - _384.fa_fog_b.z;\n                float _3957 = in.fa_world_pos.y - _384.fa_fog_b.z;\n                bool _3960 = _3952 <= 0.0;\n                bool _3961 = !_3960;\n                bool _3967;\n                if (_3961)\n                {\n                    _3967 = _384.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3967 = _3960;\n                }\n                float _3968;\n                if (_3967)\n                {\n                    _3968 = _384.fa_fog_b.y;\n                }\n                else\n                {\n                    _3968 = _384.fa_fog_b.y * exp(-fast::min(_384.fa_fog_b.w * _3952, 80.0));\n                }\n                bool _3995;\n                if (_3961)\n                {\n                    _3995 = _384.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3995 = _3960;\n                }\n                float _3996;\n                if (_3995)\n                {\n                    _3996 = _384.fa_fog_b.y * _3952;\n                }\n                else\n                {\n                    _3996 = (_384.fa_fog_b.y * (1.0 - exp(-fast::min(_384.fa_fog_b.w * _3952, 80.0)))) / _384.fa_fog_b.w;\n                }\n                bool _4021 = _3957 <= 0.0;\n                bool _4028;\n                if (!_4021)\n                {\n                    _4028 = _384.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4028 = _4021;\n                }\n                float _4029;\n                if (_4028)\n                {\n                    _4029 = _384.fa_fog_b.y * _3957;\n                }\n                else\n                {\n                    _4029 = (_384.fa_fog_b.y * (1.0 - exp(-fast::min(_384.fa_fog_b.w * _3957, 80.0)))) / _384.fa_fog_b.w;\n                }\n                float _4056;\n                if (abs(_3947) < 0.001000000047497451305389404296875)\n                {\n                    _4056 = _3968;\n                }\n                else\n                {\n                    _4056 = (_4029 - _3996) / _3947;\n                }\n                tau += (_3897 * fast::max(_4056, 0.0));\n            }\n            result = mix(result, _384.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _4188);\n    return out;\n}\n\n",
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
            "inst_name": "_384",
            "msl_buffer_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2041",
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_prepass_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float& fa_pre_depth, thread float3& fa_pre_r0, thread float3& fa_pre_r1, thread float3& fa_pre_r2, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _131);\n    float3 _299 = _160.world_pos;\n    float4 _171 = float4(_299, 1.0);\n    fa_world_pos = _299;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -(_131.fa_light_vp * _171).z;\n    fa_pre_r0 = float3(_131.fa_light_vp[0].x, _131.fa_light_vp[1].x, _131.fa_light_vp[2].x);\n    fa_pre_r1 = float3(_131.fa_light_vp[0].y, _131.fa_light_vp[1].y, _131.fa_light_vp[2].y);\n    fa_pre_r2 = float3(_131.fa_light_vp[0].z, _131.fa_light_vp[1].z, _131.fa_light_vp[2].z);\n    gl_Position = _131.fa_view_proj * _171;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _131 [[buffer(0)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5, _131, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_pre_depth, out.fa_pre_r0, out.fa_pre_r1, out.fa_pre_r2, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _56;\n    if (bool(i.front_facing))\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = fast::normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = fast::normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (bool(i.front_facing))\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _213, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _213.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _784 = base_t;\n    _784.x = _225.x;\n    _784.y = _225.y;\n    _784.z = _225.z;\n    base_t = _784;\n    float4 _241 = (_784 * _213.fa_base_color) * i.vertex_color;\n    float3 _747 = i.world_normal;\n    if (_213.fa_maps.z > 0.5)\n    {\n        float param_4 = _213.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0) - float3(1.0);\n        float2 _284 = _279.xy * _213.fa_maps.x;\n        float3 _792 = _279;\n        _792.x = _284.x;\n        _792.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _792;\n        _747 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _213.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _795 = mrt;\n    _795.x = _313.x;\n    _795.y = _313.y;\n    _795.z = _313.z;\n    mrt = _795;\n    float4 _343 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _213.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _385 = fa_tex_fix(param_20, param_21);\n    float _752 = _213.fa_layers_a.x;\n    float _753 = _213.fa_layers_a.y;\n    float _756 = _213.fa_layers_a.z;\n    float _755 = _213.fa_layers_b.w;\n    float _758 = _213.fa_layers_c.x;\n    if (_213.fa_layers_c.z > 0.5)\n    {\n        if (mod(_213.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _752 *= _355.y;\n            _753 *= _355.z;\n            _755 *= _343.w;\n        }\n        if (_213.fa_layers_c.z > 1.5)\n        {\n            _756 *= mrt.x;\n            _758 *= mrt.w;\n        }\n    }\n    return Surface{ _241.xyz, _241.w, _747, fast::clamp(_213.fa_pbr.x * _313.z, 0.0, 1.0), fast::clamp(_213.fa_pbr.y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_213.fa_maps.y * (_355.x - 1.0)), _213.fa_emissive.xyz + (_213.fa_model_emissive.xyz * _385), _752, _753, _213.fa_layers_b.xyz, _755, _756, _213.fa_layers_a.w, _758, _213.fa_layers_c.y, _213.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _213 [[buffer(1)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], sampler fa_smp [[sampler(0)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _658 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _658 = -_658;\n    }\n    float3 _519 = fast::normalize(_213.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _658, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _519, short(gl_FrontFacing) };\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _658, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _519, short(gl_FrontFacing) };\n    Surface param_2 = fa_standard_surface(param, fa_tex, fa_smp, _213, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    surface(param_1, param_2);\n    float3 _534 = fast::normalize(param_2.normal);\n    float3 _549 = fast::normalize(float3(dot(in.fa_pre_r0, _534), dot(in.fa_pre_r1, _534), dot(in.fa_pre_r2, _534)));\n    float _561 = _549.z;\n    float2 e = _549.xy / float2((abs(_549.x) + abs(_549.y)) + abs(_561));\n    if (_561 < 0.0)\n    {\n        e = (float2(1.0) - abs(e.yx)) * float2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    out.fa_frag_color = float4(fast::min(in.fa_pre_depth, 60000.0), e, 1.0);\n    return out;\n}\n\n",
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n    float4 fa_joints [[attribute(9)]];\n    float4 fa_weights [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _183)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_183.fa_joint_rows[_174] * weights[i]);\n        r1 += (_183.fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183.fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_prepass_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float& fa_pre_depth, thread float3& fa_pre_r0, thread float3& fa_pre_r1, thread float3& fa_pre_r2, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _136);\n    float3 _420 = _273.world_pos;\n    float4 _284 = float4(_420, 1.0);\n    fa_world_pos = _420;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    fa_pre_depth = -(_136.fa_light_vp * _284).z;\n    fa_pre_r0 = float3(_136.fa_light_vp[0].x, _136.fa_light_vp[1].x, _136.fa_light_vp[2].x);\n    fa_pre_r1 = float3(_136.fa_light_vp[0].y, _136.fa_light_vp[1].y, _136.fa_light_vp[2].y);\n    fa_pre_r2 = float3(_136.fa_light_vp[0].z, _136.fa_light_vp[1].z, _136.fa_light_vp[2].z);\n    gl_Position = _136.fa_view_proj * _284;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _136 [[buffer(0)]], constant fa_skin& _183 [[buffer(3)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float4x4 param_2 = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _183);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7, _136, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_pre_depth, out.fa_pre_r0, out.fa_pre_r1, out.fa_pre_r2, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _56;\n    if (bool(i.front_facing))\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = fast::normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = fast::normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (bool(i.front_facing))\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _213, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _213.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _784 = base_t;\n    _784.x = _225.x;\n    _784.y = _225.y;\n    _784.z = _225.z;\n    base_t = _784;\n    float4 _241 = (_784 * _213.fa_base_color) * i.vertex_color;\n    float3 _747 = i.world_normal;\n    if (_213.fa_maps.z > 0.5)\n    {\n        float param_4 = _213.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0) - float3(1.0);\n        float2 _284 = _279.xy * _213.fa_maps.x;\n        float3 _792 = _279;\n        _792.x = _284.x;\n        _792.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _792;\n        _747 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _213.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _795 = mrt;\n    _795.x = _313.x;\n    _795.y = _313.y;\n    _795.z = _313.z;\n    mrt = _795;\n    float4 _343 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _213.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _385 = fa_tex_fix(param_20, param_21);\n    float _752 = _213.fa_layers_a.x;\n    float _753 = _213.fa_layers_a.y;\n    float _756 = _213.fa_layers_a.z;\n    float _755 = _213.fa_layers_b.w;\n    float _758 = _213.fa_layers_c.x;\n    if (_213.fa_layers_c.z > 0.5)\n    {\n        if (mod(_213.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _752 *= _355.y;\n            _753 *= _355.z;\n            _755 *= _343.w;\n        }\n        if (_213.fa_layers_c.z > 1.5)\n        {\n            _756 *= mrt.x;\n            _758 *= mrt.w;\n        }\n    }\n    return Surface{ _241.xyz, _241.w, _747, fast::clamp(_213.fa_pbr.x * _313.z, 0.0, 1.0), fast::clamp(_213.fa_pbr.y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_213.fa_maps.y * (_355.x - 1.0)), _213.fa_emissive.xyz + (_213.fa_model_emissive.xyz * _385), _752, _753, _213.fa_layers_b.xyz, _755, _756, _213.fa_layers_a.w, _758, _213.fa_layers_c.y, _213.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _213 [[buffer(1)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], sampler fa_smp [[sampler(0)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _658 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _658 = -_658;\n    }\n    float3 _519 = fast::normalize(_213.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _658, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _519, short(gl_FrontFacing) };\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _658, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _519, short(gl_FrontFacing) };\n    Surface param_2 = fa_standard_surface(param, fa_tex, fa_smp, _213, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    surface(param_1, param_2);\n    float3 _534 = fast::normalize(param_2.normal);\n    float3 _549 = fast::normalize(float3(dot(in.fa_pre_r0, _534), dot(in.fa_pre_r1, _534), dot(in.fa_pre_r2, _534)));\n    float _561 = _549.z;\n    float2 e = _549.xy / float2((abs(_549.x) + abs(_549.y)) + abs(_561));\n    if (_561 < 0.0)\n    {\n        e = (float2(1.0) - abs(e.yx)) * float2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    out.fa_frag_color = float4(fast::min(in.fa_pre_depth, 60000.0), e, 1.0);\n    return out;\n}\n\n",
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
