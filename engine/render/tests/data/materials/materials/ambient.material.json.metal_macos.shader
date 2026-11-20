{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "21384afe6cb0557eed79a6c482a811939939d99108959ca6157b877697a348a6",
  "slang": "metal_macos",
  "params": [],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float3 fa_lm [[user(locn5)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _131);\n    float3 _267 = _160.world_pos;\n    fa_world_pos = _267;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = _131.fa_view_proj * float4(_267, 1.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _131 [[buffer(0)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5, _131, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.gl_Position);\n    out.fa_lm = float3(0.0);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n#pragma clang diagnostic ignored \"-Wmissing-braces\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\ntemplate<typename T, size_t Num>\nstruct spvUnsafeArray\n{\n    T elements[Num ? Num : 1];\n    \n    thread T& operator [] (size_t pos) thread\n    {\n        return elements[pos];\n    }\n    constexpr const thread T& operator [] (size_t pos) const thread\n    {\n        return elements[pos];\n    }\n    \n    device T& operator [] (size_t pos) device\n    {\n        return elements[pos];\n    }\n    constexpr const device T& operator [] (size_t pos) const device\n    {\n        return elements[pos];\n    }\n    \n    constexpr const constant T& operator [] (size_t pos) const constant\n    {\n        return elements[pos];\n    }\n    \n    threadgroup T& operator [] (size_t pos) threadgroup\n    {\n        return elements[pos];\n    }\n    constexpr const threadgroup T& operator [] (size_t pos) const threadgroup\n    {\n        return elements[pos];\n    }\n};\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n    float4 fa_ct_a;\n    float4 fa_ct_b;\n    float4 fa_ct_vpx;\n    float4 fa_ct_vpy;\n    float4 fa_ct_vpw;\n    float4 fa_ct_fwd;\n    float4 fa_probe_sh[9];\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n    float4 fa_shadow_lcfg;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float3 fa_lm [[user(locn5)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_cluster_texel(thread const float3& world_pos, constant fa_mesh_fs_params& _396, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    bool _1324 = _396.fa_cl_info.x < 0.0;\n    bool _1331;\n    if (!_1324)\n    {\n        _1331 = _396.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _1331 = _1324;\n    }\n    bool _1339;\n    if (!_1331)\n    {\n        _1339 = _396.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _1339 = _1331;\n    }\n    bool _1346;\n    if (!_1339)\n    {\n        _1346 = _396.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _1346 = _1339;\n    }\n    bool _1353;\n    if (!_1346)\n    {\n        _1353 = _396.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _1353 = _1346;\n    }\n    if (_1353)\n    {\n        return float4(0.0);\n    }\n    float4 _1363 = float4(world_pos, 1.0);\n    float _1369 = dot(_396.fa_cl_vpw, _1363);\n    if (!(_1369 > 9.9999999747524270787835121154785e-07))\n    {\n        return float4(0.0);\n    }\n    float2 _1391 = float2(dot(_396.fa_cl_vpx, _1363), dot(_396.fa_cl_vpy, _1363)) / float2(_1369);\n    int _1395 = int(_396.fa_cl_grid.x);\n    int _1399 = int(_396.fa_cl_grid.y);\n    int param = (int(_396.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_396.fa_cl_fwd.xyz, world_pos) + _396.fa_cl_fwd.w, _396.fa_cl_grid.w) / _396.fa_cl_grid.w) * _396.fa_cl_grid.z)), 0, int(_396.fa_cl_info.y) - 1) * _1399) + clamp(int(floor(((_1391.y * 0.5) + 0.5) * _396.fa_cl_grid.y)), 0, _1399 - 1)) * _1395)) + clamp(int(floor(((_1391.x * 0.5) + 0.5) * _396.fa_cl_grid.x)), 0, _1395 - 1);\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, constant fa_mesh_fs_params& _396, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    float3 param = world_pos;\n    float4 _1475 = fa_cluster_texel(param, _396, fa_light_tex, fa_shadow_smp);\n    return int2(int(_1475.x), int(_1475.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, constant fa_mesh_fs_params& _396, texture2d<float> fa_light_tex, sampler fa_shadow_smp, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_396.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _3534 = fa_cluster_lookup(param, _396, fa_light_tex, fa_shadow_smp);\n    fa_cl_slot = _3534.x;\n    fa_cl_local = _3534.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _3744 = fa_linear_to_srgb(param);\n        c = _3744;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _3752 = fa_srgb_to_linear(param_1);\n            c = _3752;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _278;\n    if (bool(i.front_facing))\n    {\n        _278 = i.world_normal;\n    }\n    else\n    {\n        _278 = -i.world_normal;\n    }\n    float3 _302 = fast::normalize(i.world_tangent.xyz - (_278 * dot(_278, i.world_tangent.xyz)));\n    float3 _329 = fast::normalize(((_302 * m.x) + ((cross(_278, _302) * i.world_tangent.w) * m.y)) + (_278 * m.z));\n    float3 _332;\n    if (bool(i.front_facing))\n    {\n        _332 = _329;\n    }\n    else\n    {\n        _332 = -_329;\n    }\n    return _332;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _396, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _396.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _3783 = fa_tex_fix(param_2, param_3);\n    float4 _4874 = base_t;\n    _4874.x = _3783.x;\n    _4874.y = _3783.y;\n    _4874.z = _3783.z;\n    base_t = _4874;\n    float4 _3797 = (_4874 * _396.fa_base_color) * i.vertex_color;\n    float3 _4726 = i.world_normal;\n    if (_396.fa_maps.z > 0.5)\n    {\n        float param_4 = _396.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _3829 = fa_tex_fix(param_6, param_7);\n        float3 _3832 = (_3829 * 2.0) - float3(1.0);\n        float2 _3837 = _3832.xy * _396.fa_maps.x;\n        float3 _4882 = _3832;\n        _4882.x = _3837.x;\n        _4882.y = _3837.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _4882;\n        _4726 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _396.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _3865 = fa_tex_fix(param_12, param_13);\n    float4 _4885 = mrt;\n    _4885.x = _3865.x;\n    _4885.y = _3865.y;\n    _4885.z = _3865.z;\n    mrt = _4885;\n    float4 _3893 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _396.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _3893.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _3904 = fa_tex_fix(param_16, param_17);\n    float param_18 = _396.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _3934 = fa_tex_fix(param_20, param_21);\n    float _4731 = _396.fa_layers_a.x;\n    float _4732 = _396.fa_layers_a.y;\n    float _4735 = _396.fa_layers_a.z;\n    float _4734 = _396.fa_layers_b.w;\n    float _4737 = _396.fa_layers_c.x;\n    if (_396.fa_layers_c.z > 0.5)\n    {\n        if (mod(_396.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _4731 *= _3904.y;\n            _4732 *= _3904.z;\n            _4734 *= _3893.w;\n        }\n        if (_396.fa_layers_c.z > 1.5)\n        {\n            _4735 *= mrt.x;\n            _4737 *= mrt.w;\n        }\n    }\n    return Surface{ _3797.xyz, _3797.w, _4726, fast::clamp(_396.fa_pbr.x * _3865.z, 0.0, 1.0), fast::clamp(_396.fa_pbr.y * _3865.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_396.fa_maps.y * (_3904.x - 1.0)), _396.fa_emissive.xyz + (_396.fa_model_emissive.xyz * _3934), _4731, _4732, _396.fa_layers_b.xyz, _4734, _4735, _396.fa_layers_a.w, _4737, _396.fa_layers_c.y, _396.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_decal_tile(thread const float4& rect, thread const float2& uv, thread const float2& atlas, thread const float2& ddx, thread const float2& ddy, sampler fa_env_smp, texture2d<float> fa_decal_tex)\n{\n    float2 _1555 = rect.zw - rect.xy;\n    float2 _1559 = _1555 * atlas;\n    float2 _1563 = ddx * _1559;\n    float2 _1567 = ddy * _1559;\n    return fa_decal_tex.sample(fa_env_smp, (rect.xy + (fast::clamp(uv, float2(0.0), float2(1.0)) * _1555)), level(fast::clamp(0.5 * log2(fast::max(fast::max(dot(_1563, _1563), dot(_1567, _1567)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_apply_decals(thread const float3& world_pos, thread const float3& geo_normal, thread float3& albedo, thread float3& normal, constant fa_mesh_fs_params& _396, texture2d<float> fa_light_tex, sampler fa_shadow_smp, sampler fa_env_smp, texture2d<float> fa_decal_tex)\n{\n    bool _1600 = _396.fa_counts.y < 0.5;\n    bool _1607;\n    if (!_1600)\n    {\n        _1607 = _396.fa_counts.w < 0.5;\n    }\n    else\n    {\n        _1607 = _1600;\n    }\n    if (_1607)\n    {\n        return;\n    }\n    float3 _1613 = dfdx(world_pos);\n    float3 _1616 = dfdy(world_pos);\n    float3 param = world_pos;\n    float4 _1620 = fa_cluster_texel(param, _396, fa_light_tex, fa_shadow_smp);\n    int _1624 = int(_1620.w);\n    if (_1624 < 1)\n    {\n        return;\n    }\n    int _1634 = int(_396.fa_counts.y + 0.5);\n    int param_1 = _1634;\n    float4 _1638 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float2 _1641 = _1638.yz;\n    int _1645 = int(_1638.w);\n    int param_2 = _1634 + 1;\n    float4 _1650 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float _1651 = _1650.x;\n    int _1657 = int(_396.fa_counts.w + 0.5) - 1;\n    int _1661 = int(_1620.z);\n    float3 _1926;\n    for (int k = 0; k < _1624; k++)\n    {\n        int _1674 = _1661 + k;\n        int param_3 = _1645 + (_1674 >> 2);\n        int _1691 = (_1634 + 2) + (int(fa_light_texel(param_3, fa_light_tex, fa_shadow_smp)[_1674 & 3]) * 7);\n        int param_4 = _1691 + 6;\n        float4 _1696 = fa_light_texel(param_4, fa_light_tex, fa_shadow_smp);\n        if (((int(_1696.w + 0.5) >> _1657) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1691;\n        float4 _1711 = fa_light_texel(param_5, fa_light_tex, fa_shadow_smp);\n        int param_6 = _1691 + 1;\n        float4 _1716 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n        int param_7 = _1691 + 2;\n        float4 _1721 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n        float3 _1724 = _1711.xyz;\n        float _1729 = dot(_1724, world_pos) + _1711.w;\n        float3 _1731 = _1716.xyz;\n        float _1736 = dot(_1731, world_pos) + _1716.w;\n        float3 _1738 = _1721.xyz;\n        float _1743 = dot(_1738, world_pos) + _1721.w;\n        bool _1748 = abs(_1729) > 0.5;\n        bool _1756;\n        if (!_1748)\n        {\n            _1756 = abs(_1736) > 0.5;\n        }\n        else\n        {\n            _1756 = _1748;\n        }\n        bool _1764;\n        if (!_1756)\n        {\n            _1764 = abs(_1743) > 0.5;\n        }\n        else\n        {\n            _1764 = _1756;\n        }\n        if (_1764)\n        {\n            continue;\n        }\n        float _1779 = fast::clamp(dot(geo_normal, fast::normalize(_1738)) * _1696.z, 0.0, 1.0);\n        if (_1779 <= 0.0)\n        {\n            continue;\n        }\n        float _1799 = (fast::clamp((0.5 - abs(_1743)) * 10.0, 0.0, 1.0) * _1779) * _1696.x;\n        float2 _1807 = float2(_1729 + 0.5, 0.5 - _1736);\n        float2 _1817 = float2(dot(_1724, _1613), dot(_1731, _1613));\n        float2 _1827 = float2(dot(_1724, _1616), dot(_1731, _1616));\n        int param_8 = _1691 + 5;\n        float4 _1832 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n        int param_9 = _1691 + 3;\n        float4 _1837 = fa_light_texel(param_9, fa_light_tex, fa_shadow_smp);\n        int param_10 = _1691 + 4;\n        float4 _1842 = fa_light_texel(param_10, fa_light_tex, fa_shadow_smp);\n        float tex_a = 1.0;\n        float3 col = _1832.xyz;\n        bool _1852 = _1837.z > _1837.x;\n        if (_1852)\n        {\n            float4 param_11 = _1837;\n            float2 param_12 = _1807;\n            float2 param_13 = _1641;\n            float2 param_14 = _1817;\n            float2 param_15 = _1827;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15, fa_env_smp, fa_decal_tex);\n            if ((_1651 > 0.5) && (_1651 < 1.5))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1878 = fa_dc_to_linear(param_16);\n                float4 _4806 = tx;\n                _4806.x = _1878.x;\n                _4806.y = _1878.y;\n                _4806.z = _1878.z;\n                tx = _4806;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, float3(fast::clamp((_1799 * tex_a) * _1832.w, 0.0, 1.0)));\n        if (_1842.z > _1842.x)\n        {\n            float4 param_17 = _1842;\n            float2 param_18 = _1807;\n            float2 param_19 = _1641;\n            float2 param_20 = _1817;\n            float2 param_21 = _1827;\n            float4 _1922 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21, fa_env_smp, fa_decal_tex);\n            if (_1651 > 1.5)\n            {\n                float3 param_22 = _1922.xyz;\n                float3 _1932 = fa_dc_to_srgb(param_22);\n                _1926 = _1932;\n            }\n            else\n            {\n                _1926 = _1922.xyz;\n            }\n            float3 _1941 = (_1926 * 2.0) - float3(1.0);\n            float2 _1946 = _1941.xy * _1696.y;\n            float3 _1968 = (fast::normalize(_1724) * _1946.x) + (fast::normalize(_1731) * _1946.y);\n            float3 _1971 = fast::normalize(normal);\n            normal = fast::normalize(mix(_1971, fast::normalize((_1971 * fast::max(_1941.z, 0.0500000007450580596923828125)) + (_1968 - (_1971 * dot(_1971, _1968)))), float3(fast::clamp(_1799 * (_1852 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_sh_coef(thread const int& k, constant fa_mesh_fs_params& _396, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float3 v = fa_env_tex.sample(fa_env_smp, float3(1.0, 1.0 - (float((2 * (k >> 2)) + 1) * 0.25), 1.0 - (float((2 * (k & 3)) + 1) * 0.25)), level(5.0)).xyz;\n    if (_396.fa_env_sky.w > 1.5)\n    {\n        v = (v - float3(0.5)) * 8.0;\n    }\n    return v;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sh_eval(thread const spvUnsafeArray<float3, 9>& c, thread const float3& n)\n{\n    float3 _3166 = fast::max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), float3(0.0));\n    return _3166;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _396, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    if (_396.fa_env_sky.w > 0.5)\n    {\n        spvUnsafeArray<float3, 9> c;\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param, _396, fa_env_smp, fa_env_tex);\n        }\n        spvUnsafeArray<float3, 9> param_1 = c;\n        float3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return _396.fa_ambient.xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_indirect_diffuse(thread const float3& n, constant fa_mesh_fs_params& _396, sampler fa_env_smp, texturecube<float> fa_env_tex, thread float3& fa_lm, texture2d<float> fa_lightmap)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return fa_lightmap.sample(fa_env_smp, fa_lm.xy, level(0.0)).xyz;\n    }\n    if (_396.fa_probe_sh[0].w > 0.0)\n    {\n        spvUnsafeArray<float3, 9> c;\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = _396.fa_probe_sh[k].xyz;\n        }\n        float3 param = n;\n        spvUnsafeArray<float3, 9> param_1 = c;\n        float3 param_2 = n;\n        return mix(fa_ambient_light(param, _396, fa_env_smp, fa_env_tex), fa_sh_eval(param_1, param_2), float3(fast::clamp(_396.fa_probe_sh[0].w, 0.0, 1.0)));\n    }\n    float3 param_3 = n;\n    return fa_ambient_light(param_3, _396, fa_env_smp, fa_env_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 ambient(thread const SurfaceInput& i, thread const Surface& s, thread const float3& ambientColor)\n{\n    return float3(0.0, ambientColor.y, 0.0);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, constant fa_mesh_fs_params& _396, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (int(_396.fa_cl_info.x) + int(_396.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, constant fa_mesh_fs_params& _396, texture2d<float> fa_light_tex, sampler fa_shadow_smp, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, _396, fa_light_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_light_base(thread const int& li, constant fa_mesh_fs_params& _396)\n{\n    return li * ((_396.fa_ambient.w > 4.5) ? 8 : 4);\n}\n\nstatic inline __attribute__((always_inline))\nbool fa_light_baked(thread const int& li, constant fa_mesh_fs_params& _396, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li;\n    int param_1 = fa_light_base(param, _396) + 3;\n    return fa_light_texel(param_1, fa_light_tex, fa_shadow_smp).w > 0.5;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_baked_keep(thread const int& li, constant fa_mesh_fs_params& _396, texture2d<float> fa_light_tex, sampler fa_shadow_smp, thread float3& fa_lm)\n{\n    float _3504;\n    if (fa_lm.z > 0.5)\n    {\n        _3504 = 0.0;\n    }\n    else\n    {\n        _3504 = 1.0 - fast::clamp(_396.fa_probe_sh[0].w, 0.0, 1.0);\n    }\n    bool _3515 = _3504 < 1.0;\n    bool _3521;\n    if (_3515)\n    {\n        int param = li;\n        _3521 = fa_light_baked(param, _396, fa_light_tex, fa_shadow_smp);\n    }\n    else\n    {\n        _3521 = _3515;\n    }\n    return _3521 ? _3504 : 1.0;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_light_type(thread const int& li, constant fa_mesh_fs_params& _396, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li;\n    int param_1 = fa_light_base(param, _396) + 1;\n    return fa_light_texel(param_1, fa_light_tex, fa_shadow_smp).w;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_atlas_fetch(thread const float2& texel, texture2d<float> fa_light_atlas, sampler fa_env_smp)\n{\n    return fa_light_atlas.sample(fa_env_smp, (texel / float2(int2(fa_light_atlas.get_width(), fa_light_atlas.get_height()))), level(0.0));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_cookie_sample(thread const float2& tile_origin, thread const float2& uv, texture2d<float> fa_light_atlas, sampler fa_env_smp)\n{\n    float2 param = (tile_origin + float2(1.0)) + (fast::clamp(uv, float2(0.0), float2(1.0)) * 254.0);\n    return fa_atlas_fetch(param, fa_light_atlas, fa_env_smp).xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_area_point(thread const float3& c, thread const float3& axis, thread const float3& ru, thread const float3& uu, thread const float& hx, thread const float& hy, thread const float& shape, thread const float3& p, thread const float3& r)\n{\n    bool _574 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        float3 _587 = (c - (ru * hx)) - p;\n        float3 _593 = ru * (2.0 * hx);\n        float _599 = fast::max(dot(_593, _593), 9.9999999392252902907785028219223e-09);\n        float _603 = dot(_587, _593);\n        float t = fast::clamp((-_603) / _599, 0.0, 1.0);\n        if (_574)\n        {\n            float _618 = dot(r, _593);\n            float _624 = _599 - (_618 * _618);\n            if (abs(_624) > (9.9999997473787516355514526367188e-06 * _599))\n            {\n                t = fast::clamp(((dot(r, _587) * _618) - _603) / _624, 0.0, 1.0);\n            }\n        }\n        return (p + _587) + (_593 * t);\n    }\n    float3 q = p;\n    float _656 = dot(r, axis);\n    bool _664;\n    if (_574)\n    {\n        _664 = abs(_656) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _664 = _574;\n    }\n    if (_664)\n    {\n        float _674 = dot(c - p, axis) / _656;\n        if (_674 > 0.0)\n        {\n            q = p + (r * _674);\n        }\n    }\n    float3 _687 = q - c;\n    float2 xy = float2(dot(_687, ru), dot(_687, uu));\n    if (shape > 0.5)\n    {\n        float _702 = length(xy);\n        if (_702 > hx)\n        {\n            xy *= (hx / _702);\n        }\n    }\n    else\n    {\n        xy = fast::clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cube_face(thread const float3& d)\n{\n    float3 _344 = abs(d);\n    float _346 = _344.x;\n    float _348 = _344.y;\n    bool _349 = _346 >= _348;\n    bool _357;\n    if (_349)\n    {\n        _357 = _346 >= _344.z;\n    }\n    else\n    {\n        _357 = _349;\n    }\n    int _358;\n    if (_357)\n    {\n        _358 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _373;\n        if (_348 >= _344.z)\n        {\n            _373 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _373 = (d.z > 0.0) ? 4 : 5;\n        }\n        _358 = _373;\n    }\n    return _358;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cube_face_basis(thread const int& f, thread float3& fwd, thread float3& up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0, 0.0, 0.0);\n        up = float3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0, 0.0, 0.0);\n            up = float3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0, 1.0, 0.0);\n                up = float3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0, -1.0, 0.0);\n                    up = float3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0, 0.0, 1.0);\n                        up = float3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0, 0.0, -1.0);\n                        up = float3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_ies_sample(thread const float2& tile_origin, thread const float3& d, thread const float3& axis, thread const float3& right, thread const float3& up, texture2d<float> fa_light_atlas, sampler fa_env_smp)\n{\n    float _494 = dot(d, right);\n    float _498 = dot(d, up);\n    float _509;\n    if (((_494 * _494) + (_498 * _498)) > 1.0000000133514319600180897396058e-10)\n    {\n        _509 = precise::atan2(_498, _494) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _509 = 0.0;\n    }\n    float2 param = tile_origin + float2(1.0 + ((_509 - floor(_509)) * 64.0), 1.0 + (acos(fast::clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param, fa_light_atlas, fa_env_smp).x;\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample_n(thread const int& li, thread const float3& world_pos, thread const float3& n, constant fa_mesh_fs_params& _396, texture2d<float> fa_light_tex, sampler fa_shadow_smp, texture2d<float> fa_light_atlas, sampler fa_env_smp, thread float3& fa_light_tint, thread bool& fa_light_is_area)\n{\n    int param = li;\n    int _740 = fa_light_base(param, _396);\n    bool _744 = _396.fa_ambient.w > 4.5;\n    int param_1 = _740;\n    float4 _748 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    int param_2 = _740 + 1;\n    float4 _753 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float _756 = _753.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = float3(1.0);\n    bool _768 = _744 && (_756 > 2.5);\n    fa_light_is_area = _768;\n    bool _770 = _756 < 0.5;\n    float3 l;\n    if (_770)\n    {\n        l = fast::normalize(_748.xyz);\n        if (_744)\n        {\n            int param_3 = _740 + 6;\n            float4 _784 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            if (_784.z > 0.5)\n            {\n                int param_4 = _740 + 4;\n                float4 _794 = fa_light_texel(param_4, fa_light_tex, fa_shadow_smp);\n                int param_5 = _740 + 5;\n                float4 _799 = fa_light_texel(param_5, fa_light_tex, fa_shadow_smp);\n                float2 param_6 = _784.xy;\n                float2 param_7 = fract(float2(dot(world_pos, _794.xyz) * _794.w, (-dot(world_pos, _799.xyz)) * _799.w) + float2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7, fa_light_atlas, fa_env_smp);\n            }\n        }\n    }\n    else\n    {\n        float3 _829 = _748.xyz;\n        float3 _831 = _829 - world_pos;\n        float3 to_light = _831;\n        float _834 = length(_831);\n        float reach = _834;\n        bool front = true;\n        if (_768)\n        {\n            int param_8 = _740 + 7;\n            reach = fast::max(_834 - fa_light_texel(param_8, fa_light_tex, fa_shadow_smp).w, 0.0);\n            int param_9 = _740 + 4;\n            float4 _858 = fa_light_texel(param_9, fa_light_tex, fa_shadow_smp);\n            int param_10 = _740 + 5;\n            float4 _863 = fa_light_texel(param_10, fa_light_tex, fa_shadow_smp);\n            int param_11 = _740 + 6;\n            float4 _868 = fa_light_texel(param_11, fa_light_tex, fa_shadow_smp);\n            float _869 = _868.w;\n            int param_12 = _740 + 2;\n            float3 _876 = fast::normalize(fa_light_texel(param_12, fa_light_tex, fa_shadow_smp).xyz);\n            bool _878 = _869 > 1.5;\n            bool _886;\n            if (!_878)\n            {\n                _886 = dot(_876, to_light) < 0.0;\n            }\n            else\n            {\n                _886 = _878;\n            }\n            front = _886;\n            float3 r = float3(0.0);\n            float3 _895 = _396.fa_camera_pos.xyz - world_pos;\n            bool _899 = dot(n, n) > 0.5;\n            bool _907;\n            if (_899)\n            {\n                _907 = dot(_895, _895) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _907 = _899;\n            }\n            if (_907)\n            {\n                r = reflect(-fast::normalize(_895), fast::normalize(n));\n            }\n            float3 param_13 = _829;\n            float3 param_14 = _876;\n            float3 param_15 = _858.xyz;\n            float3 param_16 = _863.xyz;\n            float param_17 = _858.w;\n            float param_18 = _863.w;\n            float param_19 = _869;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _943 = length(to_light);\n        dist = _943;\n        l = to_light / float3(fast::max(_943, 9.9999997473787516355514526367188e-05));\n        float _957 = reach / fast::max(_748.w, 0.001000000047497451305389404296875);\n        float _963 = fast::clamp(1.0 - (_957 * _957), 0.0, 1.0);\n        float _965;\n        if (front)\n        {\n            _965 = _963 * _963;\n        }\n        else\n        {\n            _965 = 0.0;\n        }\n        atten = _965;\n        bool _976 = _756 < 2.5;\n        if ((_756 > 1.5) && _976)\n        {\n            int param_22 = _740 + 2;\n            float4 _984 = fa_light_texel(param_22, fa_light_tex, fa_shadow_smp);\n            float _994 = _984.w;\n            int param_23 = _740 + 3;\n            float4 _999 = fa_light_texel(param_23, fa_light_tex, fa_shadow_smp);\n            float _1000 = _999.x;\n            float cos_inner = _1000;\n            if (_1000 > 1.5)\n            {\n                cos_inner = mix(_994, 1.0, 0.25);\n            }\n            atten *= smoothstep(_994, cos_inner, dot(-l, fast::normalize(_984.xyz)));\n        }\n        if (_744 && (_756 < 1.5))\n        {\n            int param_24 = _740 + 6;\n            float4 _1024 = fa_light_texel(param_24, fa_light_tex, fa_shadow_smp);\n            if (_1024.z > 0.5)\n            {\n                float3 _1032 = -to_light;\n                int param_25 = _740 + 4;\n                int param_26 = _740 + 5;\n                float3 _1046 = fa_light_texel(param_25, fa_light_tex, fa_shadow_smp).xyz;\n                float3 _1050 = fa_light_texel(param_26, fa_light_tex, fa_shadow_smp).xyz;\n                float3 _1059 = float3(dot(_1032, _1046), dot(_1032, _1050), dot(_1032, cross(_1046, _1050)));\n                float3 param_27 = _1059;\n                int _1063 = fa_cube_face(param_27);\n                int param_28 = _1063;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1090 = float2(dot(_1059, cross(param_29, param_30)), dot(_1059, param_30)) / float2(fast::max(dot(_1059, param_29), 9.9999997473787516355514526367188e-05));\n                int _1094 = _1063 / 3;\n                float2 param_31 = _1024.xy + (float2(float(_1063 - (_1094 * 3)), float(_1094)) * 256.0);\n                float2 param_32 = float2(0.5 + (0.5 * _1090.x), 0.5 - (0.5 * _1090.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32, fa_light_atlas, fa_env_smp);\n            }\n            int param_33 = _740 + 7;\n            float4 _1124 = fa_light_texel(param_33, fa_light_tex, fa_shadow_smp);\n            if (_1124.z > 0.5)\n            {\n                int param_34 = _740 + 2;\n                int param_35 = _740 + 4;\n                int param_36 = _740 + 5;\n                float2 param_37 = _1124.xy;\n                float3 param_38 = -l;\n                float3 param_39 = fast::normalize(fa_light_texel(param_34, fa_light_tex, fa_shadow_smp).xyz);\n                float3 param_40 = fa_light_texel(param_35, fa_light_tex, fa_shadow_smp).xyz;\n                float3 param_41 = fa_light_texel(param_36, fa_light_tex, fa_shadow_smp).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41, fa_light_atlas, fa_env_smp);\n            }\n        }\n        else\n        {\n            if (_744 && _976)\n            {\n                int param_42 = _740 + 6;\n                float4 _1171 = fa_light_texel(param_42, fa_light_tex, fa_shadow_smp);\n                int param_43 = _740 + 7;\n                float4 _1176 = fa_light_texel(param_43, fa_light_tex, fa_shadow_smp);\n                bool _1179 = _1171.z > 0.5;\n                bool _1186;\n                if (!_1179)\n                {\n                    _1186 = _1176.z > 0.5;\n                }\n                else\n                {\n                    _1186 = _1179;\n                }\n                if (_1186)\n                {\n                    int param_44 = _740 + 2;\n                    float4 _1193 = fa_light_texel(param_44, fa_light_tex, fa_shadow_smp);\n                    float3 _1197 = fast::normalize(_1193.xyz);\n                    int param_45 = _740 + 4;\n                    float4 _1202 = fa_light_texel(param_45, fa_light_tex, fa_shadow_smp);\n                    int param_46 = _740 + 5;\n                    float4 _1207 = fa_light_texel(param_46, fa_light_tex, fa_shadow_smp);\n                    if (_1179)\n                    {\n                        float3 _1215 = -to_light;\n                        float _1222 = _1193.w;\n                        float _1238 = 0.5 / fast::max(dot(_1215, _1197) * (sqrt(fast::max(1.0 - (_1222 * _1222), 0.0)) / fast::max(_1222, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        float2 param_47 = _1171.xy;\n                        float2 param_48 = float2(0.5 + (dot(_1215, _1202.xyz) * _1238), 0.5 - (dot(_1215, _1207.xyz) * _1238));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48, fa_light_atlas, fa_env_smp);\n                    }\n                    if (_1176.z > 0.5)\n                    {\n                        float2 param_49 = _1176.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1197;\n                        float3 param_52 = _1202.xyz;\n                        float3 param_53 = _1207.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53, fa_light_atlas, fa_env_smp);\n                    }\n                }\n            }\n        }\n    }\n    float3 _4680 = _753.xyz * atten;\n    if (_744)\n    {\n        _4680 *= fa_light_tint;\n    }\n    int _1306;\n    if (_770)\n    {\n        _1306 = 0;\n    }\n    else\n    {\n        _1306 = ((_756 > 1.5) && (_756 < 2.5)) ? 2 : 1;\n    }\n    return LightSample{ l, _4680, atten, 1.0, dist, _1306 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _2053)\n{\n    float _2043;\n    if (i == 0)\n    {\n        _2043 = _2053.fa_shadow_split.x;\n    }\n    else\n    {\n        float _2059;\n        if (i == 1)\n        {\n            _2059 = _2053.fa_shadow_split.y;\n        }\n        else\n        {\n            float _2067;\n            if (i == 2)\n            {\n                _2067 = _2053.fa_shadow_split.z;\n            }\n            else\n            {\n                _2067 = _2053.fa_shadow_split.w;\n            }\n            _2059 = _2067;\n        }\n        _2043 = _2059;\n    }\n    return _2043;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_fetch(thread const float2& uv, thread const float4& rect, thread const float3& conv, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2100 = fa_shadow_depth(param, param_1, fa_shadow_smp, fa_shadow_tex);\n    float _2104;\n    if (conv.x < 0.5)\n    {\n        _2104 = _2100;\n    }\n    else\n    {\n        _2104 = (conv.y * conv.z) / (conv.z - (_2100 * (conv.z - conv.y)));\n    }\n    return _2104;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _2031 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_2031), sin(_2031)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_filter(thread const float2& uv, thread const float4& rect, thread const float& zr, thread const float& texel_m, thread const float& unit, thread const float& reach, thread const float& plane, thread const float3& conv, thread const int& mode, thread const float& k, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2053, texture2d<float> fa_shadow_tex)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2, fa_shadow_smp, fa_shadow_tex));\n    }\n    float _2150 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2159;\n        if (k < 0.0)\n        {\n            _2159 = (-k) / fast::max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2159 = k;\n        }\n        float _2179 = fast::clamp((_2159 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2150;\n            float2 _2198 = fa_shadow_vogel(param_3, param_4, param_5) * _2179;\n            float2 param_6 = uv + (_2198 * _2053.fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _2210 = fa_shadow_fetch(param_6, param_7, param_8, fa_shadow_smp, fa_shadow_tex);\n            if (_2210 < (zr - (length(_2198) * plane)))\n            {\n                sum += _2210;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2236 = sum / cnt;\n        float _2246;\n        if (k < 0.0)\n        {\n            _2246 = (-k) / fast::max(_2236, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2246 = k;\n        }\n        radius = fast::clamp(((fast::max(zr - _2236, 0.0) * unit) * _2246) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _2268 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2268; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2268;\n        float param_11 = _2150;\n        float2 _2287 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_2287 * _2053.fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_2287) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14, fa_shadow_smp, fa_shadow_tex));\n    }\n    return lit / float(_2268);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2053, texture2d<float> fa_shadow_tex)\n{\n    float _2329 = fast::max(_2053.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _2334 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _2340 = sqrt(1.0 - (_2334 * _2334));\n    float _2347 = fast::min(_2340 / fast::max(_2334, 0.20000000298023223876953125), 4.0);\n    float _2352;\n    if (_2053.fa_shadow_bias.y > 0.0)\n    {\n        _2352 = _2053.fa_shadow_bias.y;\n    }\n    else\n    {\n        _2352 = 1.5 * _2053.fa_shadow_info[ci].x;\n    }\n    float4 _2377 = _2053.fa_shadow_mat[ci] * float4(world + (n * (_2352 * _2340)), 1.0);\n    float _2384 = _2377.x;\n    bool _2387 = _2384 < _2053.fa_shadow_rect[ci].x;\n    bool _2396;\n    if (!_2387)\n    {\n        _2396 = _2384 > _2053.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2396 = _2387;\n    }\n    bool _2405;\n    if (!_2396)\n    {\n        _2405 = _2377.y < _2053.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2405 = _2396;\n    }\n    bool _2414;\n    if (!_2405)\n    {\n        _2414 = _2377.y > _2053.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2414 = _2405;\n    }\n    bool _2421;\n    if (!_2414)\n    {\n        _2421 = _2377.z > 1.0;\n    }\n    else\n    {\n        _2421 = _2414;\n    }\n    if (_2421)\n    {\n        return -1.0;\n    }\n    float _2429;\n    if (_2053.fa_shadow_bias.x > 0.0)\n    {\n        _2429 = _2053.fa_shadow_bias.x;\n    }\n    else\n    {\n        _2429 = 1.5 * _2053.fa_shadow_info[ci].x;\n    }\n    float2 param = _2377.xy;\n    float4 param_1 = _2053.fa_shadow_rect[ci];\n    float param_2 = _2377.z - ((_2429 * (1.0 + (0.5 * _2347))) / _2329);\n    float param_3 = _2053.fa_shadow_info[ci].x;\n    float param_4 = _2329;\n    float param_5 = _2329 * 0.25;\n    float param_6 = ((_2053.fa_shadow_info[ci].x * fast::min(_2347, 3.0)) * 0.5) / _2329;\n    float3 param_7 = float3(0.0);\n    int param_8 = int(_2053.fa_shadow_cfg.z + 0.5);\n    float param_9 = _2053.fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9, fa_shadow_smp, gl_FragCoord, _2053, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _396, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2053, texture2d<float> fa_shadow_tex)\n{\n    if (_396.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2807 = int(_2053.fa_shadow_cfg.x + 0.5);\n    if (_2807 < 1)\n    {\n        return 1.0;\n    }\n    float _2822 = dot(world - _2053.fa_shadow_eye.xyz, _2053.fa_shadow_fwd.xyz);\n    int param = _2807 - 1;\n    if (_2822 > fa_shadow_split_at(param, _2053))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2834 = _2807 > 1;\n    bool _2841;\n    if (_2834)\n    {\n        _2841 = _2822 > _2053.fa_shadow_split.x;\n    }\n    else\n    {\n        _2841 = _2834;\n    }\n    if (_2841)\n    {\n        ci = 1;\n    }\n    bool _2845 = _2807 > 2;\n    bool _2852;\n    if (_2845)\n    {\n        _2852 = _2822 > _2053.fa_shadow_split.y;\n    }\n    else\n    {\n        _2852 = _2845;\n    }\n    if (_2852)\n    {\n        ci = 2;\n    }\n    bool _2856 = _2807 > 3;\n    bool _2863;\n    if (_2856)\n    {\n        _2863 = _2822 > _2053.fa_shadow_split.z;\n    }\n    else\n    {\n        _2863 = _2856;\n    }\n    if (_2863)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2807)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2889 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_shadow_smp, gl_FragCoord, _2053, fa_shadow_tex);\n        s = _2889;\n        if (_2889 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_2053.fa_shadow_cfg.y > 0.0)\n    {\n        float _2914;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2914 = fa_shadow_split_at(param_5, _2053);\n        }\n        else\n        {\n            _2914 = _2053.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _2933 = _2053.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _2053) - _2914, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2944 = fast::clamp((_2822 - (fa_shadow_split_at(param_7, _2053) - _2933)) / _2933, 0.0, 1.0);\n        if (_2944 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2807)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _2965 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_shadow_smp, gl_FragCoord, _2053, fa_shadow_tex);\n                s2 = _2965;\n                if (_2965 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2944);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _396, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2053, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, _396, fa_shadow_smp, gl_FragCoord, _2053, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_local(thread const int& li, thread const float3& lpos, thread const float3& world, thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _396, texture2d<float> fa_light_tex, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2053, texture2d<float> fa_shadow_tex)\n{\n    bool _2487 = _396.fa_pbr.z < 0.5;\n    bool _2494;\n    if (!_2487)\n    {\n        _2494 = _2053.fa_shadow_lcfg.x < 0.5;\n    }\n    else\n    {\n        _2494 = _2487;\n    }\n    if (_2494)\n    {\n        return 1.0;\n    }\n    int param = (int(_2053.fa_shadow_lcfg.x + 0.5) - 1) + li;\n    float4 _2507 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    float _2508 = _2507.x;\n    if (_2508 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2517 = int(_2508 + 0.5);\n    int param_1 = _2517;\n    float4 _2521 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    int param_2 = _2517 + 1;\n    float4 _2526 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float fade = 1.0;\n    float _2529 = _2521.y;\n    if (_2529 > 0.0)\n    {\n        float _2546 = 1.0 - smoothstep(0.75 * _2529, _2529, length(world - _2053.fa_shadow_eye.xyz));\n        fade = _2546;\n        if (_2546 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2521.x > 1.5)\n    {\n        float3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2570 = (_2517 + 2) + (face * 6);\n    int param_4 = _2570;\n    int param_5 = _2570 + 1;\n    int param_6 = _2570 + 3;\n    float4 _2584 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n    int param_7 = _2570 + 4;\n    float4 _2589 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n    int param_8 = _2570 + 5;\n    float4 _2594 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n    float _2606 = _2594.x * fast::max(dot(_2584, float4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2611 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _2634 = fast::clamp(dot(n, _2584.xyz), -1.0, 1.0);\n    float _2653 = fast::min(sqrt(1.0 - (_2634 * _2634)) / fast::max(abs(dot(n, world - lpos)) / fast::max(dot(_2584, float4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2656 = _2526.y;\n    float _2658;\n    if (_2656 > 0.0)\n    {\n        _2658 = _2656;\n    }\n    else\n    {\n        _2658 = 1.5 * _2606;\n    }\n    float4 _2678 = float4(world + (n * (_2658 * sqrt(1.0 - (_2611 * _2611)))), 1.0);\n    float _2682 = dot(_2584, _2678);\n    float _2685 = _2594.y;\n    if (_2682 < _2685)\n    {\n        return 1.0;\n    }\n    float2 _2700 = float2(dot(fa_light_texel(param_4, fa_light_tex, fa_shadow_smp), _2678), dot(fa_light_texel(param_5, fa_light_tex, fa_shadow_smp), _2678)) / float2(_2682);\n    float _2702 = _2700.x;\n    bool _2705 = _2702 < _2589.x;\n    bool _2714;\n    if (!_2705)\n    {\n        _2714 = _2702 > _2589.z;\n    }\n    else\n    {\n        _2714 = _2705;\n    }\n    bool _2723;\n    if (!_2714)\n    {\n        _2723 = _2700.y < _2589.y;\n    }\n    else\n    {\n        _2723 = _2714;\n    }\n    bool _2732;\n    if (!_2723)\n    {\n        _2732 = _2700.y > _2589.w;\n    }\n    else\n    {\n        _2732 = _2723;\n    }\n    if (_2732)\n    {\n        return 1.0;\n    }\n    float _2738 = _2526.x;\n    float _2740;\n    if (_2738 > 0.0)\n    {\n        _2740 = _2738;\n    }\n    else\n    {\n        _2740 = 1.5 * _2606;\n    }\n    float2 param_9 = _2700;\n    float4 param_10 = _2589;\n    float param_11 = _2682 - (_2740 * (1.0 + (0.5 * _2653)));\n    float param_12 = _2606;\n    float param_13 = 1.0;\n    float param_14 = _2594.z * 0.25;\n    float param_15 = (_2606 * fast::min(_2653, 3.0)) * 0.5;\n    float3 param_16 = float3(1.0, _2685, _2594.z);\n    int param_17 = int(_2521.z + 0.5);\n    float param_18 = _2521.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, fa_shadow_smp, gl_FragCoord, _2053, fa_shadow_tex), fade);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_contact_shadow(thread const int& li, thread const float3& world, thread const float3& gn, thread const float3& l, thread const float& dist, constant fa_mesh_fs_params& _396, texture2d<float> fa_light_tex, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2053, texture2d<float> fa_screen_tex)\n{\n    bool _3246 = _396.fa_ct_a.x < 0.5;\n    bool _3253;\n    if (!_3246)\n    {\n        _3253 = _2053.fa_shadow_lcfg.x < 0.5;\n    }\n    else\n    {\n        _3253 = _3246;\n    }\n    if (_3253)\n    {\n        return 1.0;\n    }\n    int param = (int(_2053.fa_shadow_lcfg.x + 0.5) - 1) + li;\n    float4 _3266 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    float _3267 = _3266.y;\n    float len = _3267;\n    if (_3267 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3279 = length(world - _396.fa_camera_pos.xyz);\n    float _3289 = 1.0 - smoothstep(0.5 * _396.fa_ct_b.x, _396.fa_ct_b.x, _3279);\n    if (_3289 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3295 = len;\n    float _3298 = fast::min(_3295, 0.89999997615814208984375 * dist);\n    len = _3298;\n    float _3304 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _3279);\n    float _3309 = _3304 + (0.5 * _3298);\n    float3 _3315 = world + (gn * _3304);\n    float _3317 = fa_shadow_noise(gl_FragCoord);\n    float occ = 0.0;\n    float _3382;\n    for (int k = 0; k < 12; k++)\n    {\n        float _3333 = (float(k) + _3317) * 0.083333335816860198974609375;\n        float3 _3341 = _3315 + (l * (_3333 * len));\n        float4 _3347 = float4(_3341, 1.0);\n        float _3353 = dot(_396.fa_ct_vpw, _3347);\n        if (_3353 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        float2 _3373 = float2(dot(_396.fa_ct_vpx, _3347), dot(_396.fa_ct_vpy, _3347)) / float2(_3353);\n        float _3377 = _3373.x * 0.5;\n        float _3378 = _3377 + 0.5;\n        if (_396.fa_ct_a.y > 0.5)\n        {\n            _3382 = (_3373.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _3382 = 0.5 - (_3373.y * 0.5);\n        }\n        bool _3398 = _3378 < 0.0;\n        bool _3405;\n        if (!_3398)\n        {\n            _3405 = _3378 >= 1.0;\n        }\n        else\n        {\n            _3405 = _3398;\n        }\n        bool _3412;\n        if (!_3405)\n        {\n            _3412 = _3382 < 0.0;\n        }\n        else\n        {\n            _3412 = _3405;\n        }\n        bool _3419;\n        if (!_3412)\n        {\n            _3419 = _3382 >= 1.0;\n        }\n        else\n        {\n            _3419 = _3412;\n        }\n        if (_3419)\n        {\n            break;\n        }\n        float4 _3438 = fa_screen_tex.read(uint2(int2(float2(_3378, _3382) * _396.fa_ct_a.zw)), 0);\n        if (_3438.w < 0.5)\n        {\n            continue;\n        }\n        float _3457 = (dot(_396.fa_ct_fwd.xyz, _3341) + _396.fa_ct_fwd.w) - _3438.x;\n        if ((_3457 > _3304) && (_3457 < _3309))\n        {\n            occ = fast::max(occ, (1.0 - (_3333 * _3333)) * smoothstep(0.0, 0.0500000007450580596923828125, fast::min(fast::min(_3378, 0.5 - _3377), fast::min(_3382, 1.0 - _3382))));\n        }\n    }\n    return 1.0 - (occ * _3289);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, constant fa_mesh_fs_params& _396, texture2d<float> fa_light_tex, sampler fa_shadow_smp, texture2d<float> fa_light_atlas, sampler fa_env_smp, thread float3& fa_light_tint, thread bool& fa_light_is_area, thread float4& gl_FragCoord, constant fa_shadows& _2053, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos, texture2d<float> fa_screen_tex, thread float3& fa_lm)\n{\n    int param = li;\n    float _3560 = fa_baked_keep(param, _396, fa_light_tex, fa_shadow_smp, fa_lm);\n    if (_3560 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample{ float3(0.0, 1.0, 0.0), float3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1, _396, fa_light_tex, fa_shadow_smp) + 0.5) };\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _3586 = fa_light_sample_n(param_2, param_3, param_4, _396, fa_light_tex, fa_shadow_smp, fa_light_atlas, fa_env_smp, fa_light_tint, fa_light_is_area);\n    float3 _4706 = _3586.color;\n    float _4707 = _3586.attenuation;\n    float _4708 = _3586.shadow;\n    bool _3589 = _3586.type == 0;\n    if (_3589 && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _3586.direction;\n        float _3600 = fa_shadow_factor(param_5, param_6, _396, fa_shadow_smp, gl_FragCoord, _2053, fa_shadow_tex, fa_world_pos);\n        _4708 = _3600;\n        _4706 *= _3600;\n    }\n    else\n    {\n        bool _3611 = _3586.type != 0;\n        bool _3617;\n        if (_3611)\n        {\n            _3617 = _4707 > 0.0;\n        }\n        else\n        {\n            _3617 = _3611;\n        }\n        if (_3617)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7, _396);\n            int param_9 = li;\n            float3 param_10 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp).xyz;\n            float3 param_11 = world_pos;\n            float3 param_12 = gn;\n            float3 param_13 = _3586.direction;\n            float _3636 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13, _396, fa_light_tex, fa_shadow_smp, gl_FragCoord, _2053, fa_shadow_tex);\n            _4708 = _3636;\n            _4706 *= _3636;\n        }\n    }\n    bool _3646 = _396.fa_ct_a.x > 0.5;\n    bool _3652;\n    if (_3646)\n    {\n        _3652 = _4707 > 0.0;\n    }\n    else\n    {\n        _3652 = _3646;\n    }\n    if (_3652)\n    {\n        float _3659;\n        if (_3589)\n        {\n            _3659 = 1000000000.0;\n        }\n        else\n        {\n            _3659 = _3586._distance;\n        }\n        int param_14 = li;\n        float3 param_15 = world_pos;\n        float3 param_16 = gn;\n        float3 param_17 = _3586.direction;\n        float param_18 = _3659;\n        float _3677 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18, _396, fa_light_tex, fa_shadow_smp, gl_FragCoord, _2053, fa_screen_tex);\n        _4708 *= _3677;\n        _4706 *= _3677;\n    }\n    float _3690 = _4707;\n    float _3691 = _3690 * _3560;\n    _4707 = _3691;\n    float3 _3695 = _4706;\n    float3 _3696 = _3695 * _3560;\n    _4706 = _3696;\n    return LightSample{ _3586.direction, _3696, _3691, _4708, _3586._distance, _3586.type };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 light(thread const SurfaceInput& i, thread const Surface& s, thread const LightSample& l)\n{\n    return float3(0.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _2053)\n{\n    if (_2053.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _2989 = int(_2053.fa_shadow_cfg.x + 0.5);\n    float _2999 = dot(world - _2053.fa_shadow_eye.xyz, _2053.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _3004 = _2989 > 0;\n    bool _3013;\n    if (_3004)\n    {\n        int param = _2989 - 1;\n        _3013 = _2999 <= fa_shadow_split_at(param, _2053);\n    }\n    else\n    {\n        _3013 = _3004;\n    }\n    if (_3013)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3019 = _2989 > 1;\n        bool _3026;\n        if (_3019)\n        {\n            _3026 = _2999 > _2053.fa_shadow_split.x;\n        }\n        else\n        {\n            _3026 = _3019;\n        }\n        if (_3026)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3032 = _2989 > 2;\n        bool _3039;\n        if (_3032)\n        {\n            _3039 = _2999 > _2053.fa_shadow_split.y;\n        }\n        else\n        {\n            _3039 = _3032;\n        }\n        if (_3039)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3045 = _2989 > 3;\n        bool _3052;\n        if (_3045)\n        {\n            _3052 = _2999 > _2053.fa_shadow_split.z;\n        }\n        else\n        {\n            _3052 = _3045;\n        }\n        if (_3052)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _396 [[buffer(1)]], constant fa_shadows& _2053 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_env_tex [[texture(6)]], texture2d<float> fa_light_tex [[texture(7)]], texture2d<float> fa_light_atlas [[texture(8)]], texture2d<float> fa_lightmap [[texture(9)]], texture2d<float> fa_decal_tex [[texture(10)]], texture2d<float> fa_screen_tex [[texture(11)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _4522 = fast::normalize(in.fa_world_normal);\n    float3 fa_light_tint;\n    bool fa_light_is_area;\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _4522 = -_4522;\n    }\n    float3 _4113 = fast::normalize(_396.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, _396, fa_light_tex, fa_shadow_smp, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _4522, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _4113, short(gl_FrontFacing) };\n    Surface _4121 = fa_standard_surface(param_1, _396, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _4561 = _4121.albedo;\n    float _4562 = _4121.alpha;\n    float3 _4563 = _4121.normal;\n    float _4564 = _4121.metallic;\n    float _4565 = _4121.roughness;\n    float _4566 = _4121.occlusion;\n    float3 _4567 = _4121.emission;\n    float _4568 = _4121.clearcoat;\n    float _4569 = _4121.clearcoat_roughness;\n    float3 _4570 = _4121.sheen_color;\n    float _4571 = _4121.sheen_roughness;\n    float _4572 = _4121.anisotropy;\n    float _4573 = _4121.anisotropy_rotation;\n    float _4574 = _4121.specular;\n    float _4575 = _4121.ior;\n    float3 _4576 = _4121.specular_color;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _4522, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _4113, short(gl_FrontFacing) };\n    Surface param_3 = _4121;\n    surface(param_2, param_3);\n    _4561 = param_3.albedo;\n    _4562 = param_3.alpha;\n    _4563 = param_3.normal;\n    _4564 = param_3.metallic;\n    _4565 = param_3.roughness;\n    _4566 = param_3.occlusion;\n    _4567 = param_3.emission;\n    _4568 = param_3.clearcoat;\n    _4569 = param_3.clearcoat_roughness;\n    _4570 = param_3.sheen_color;\n    _4571 = param_3.sheen_roughness;\n    _4572 = param_3.anisotropy;\n    _4573 = param_3.anisotropy_rotation;\n    _4574 = param_3.specular;\n    _4575 = param_3.ior;\n    _4576 = param_3.specular_color;\n    float3 param_4 = in.fa_world_pos;\n    float3 param_5 = _4522;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7, _396, fa_light_tex, fa_shadow_smp, fa_env_smp, fa_decal_tex);\n    _4561 = param_6;\n    _4563 = param_7;\n    float3 result;\n    if (_396.fa_emissive.w > 0.5)\n    {\n        result = _4561;\n    }\n    else\n    {\n        float3 _4159 = _4563;\n        float3 _4160 = fast::normalize(_4159);\n        _4563 = _4160;\n        float3 param_8 = _4160;\n        SurfaceInput param_9 = SurfaceInput{ in.fa_world_pos, _4522, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _4113, short(gl_FrontFacing) };\n        Surface param_10 = Surface{ _4561, _4562, _4563, _4564, _4565, _4566, _4567, _4568, _4569, _4570, _4571, _4572, _4573, _4574, _4575, _4576 };\n        float3 param_11 = fa_indirect_diffuse(param_8, _396, fa_env_smp, fa_env_tex, in.fa_lm, fa_lightmap);\n        float3 lit = ambient(param_9, param_10, param_11);\n        int _4179 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _4179; ln++)\n        {\n            int param_12 = ln;\n            int _4192 = fa_cl_light(param_12, _396, fa_light_tex, fa_shadow_smp, fa_cl_ndir, fa_cl_slot);\n            int param_13 = _4192;\n            if (fa_baked_keep(param_13, _396, fa_light_tex, fa_shadow_smp, in.fa_lm) <= 0.0)\n            {\n                continue;\n            }\n            int param_14 = _4192;\n            float3 param_15 = in.fa_world_pos;\n            float3 param_16 = _4522;\n            LightSample _4208 = fa_light_shadowed(param_14, param_15, param_16, _396, fa_light_tex, fa_shadow_smp, fa_light_atlas, fa_env_smp, fa_light_tint, fa_light_is_area, gl_FragCoord, _2053, fa_shadow_tex, in.fa_world_pos, fa_screen_tex, in.fa_lm);\n            SurfaceInput param_17 = SurfaceInput{ in.fa_world_pos, _4522, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _4113, short(gl_FrontFacing) };\n            Surface param_18 = Surface{ _4561, _4562, _4563, _4564, _4565, _4566, _4567, _4568, _4569, _4570, _4571, _4572, _4573, _4574, _4575, _4576 };\n            LightSample param_19 = _4208;\n            lit += light(param_17, param_18, param_19);\n        }\n        result = lit;\n    }\n    float3 _4223 = result;\n    float3 _4224 = _4223 + _4567;\n    result = _4224;\n    float3 param_20 = _4224;\n    float3 param_21 = in.fa_world_pos;\n    result = fa_shadow_debug(param_20, param_21, _2053);\n    bool _4233 = _396.fa_fog.w > 0.0;\n    bool _4240;\n    if (!_4233)\n    {\n        _4240 = _396.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _4240 = _4233;\n    }\n    if (_4240)\n    {\n        float3 _4249 = in.fa_world_pos - _396.fa_camera_pos.xyz;\n        float _4255 = dot(_4249, _396.fa_fog_c.xyz);\n        bool _4259 = _396.fa_fog_c.w > 0.5;\n        float _4260;\n        if (_4259)\n        {\n            _4260 = _4255;\n        }\n        else\n        {\n            _4260 = length(_4249);\n        }\n        float _4272 = _4260 - _396.fa_fog_b.x;\n        if (_4272 > 0.0)\n        {\n            float _4281 = _396.fa_fog.w * _4272;\n            float tau = _4281 * _4281;\n            if (_396.fa_fog_b.y > 0.0)\n            {\n                float _4297;\n                if (_4259)\n                {\n                    _4297 = in.fa_world_pos.y - (_396.fa_fog_c.y * _4255);\n                }\n                else\n                {\n                    _4297 = _396.fa_camera_pos.y;\n                }\n                float _4318 = mix(_4297, in.fa_world_pos.y, fast::clamp(_396.fa_fog_b.x / _4260, 0.0, 1.0));\n                float _4322 = in.fa_world_pos.y - _4318;\n                float _4327 = _4318 - _396.fa_fog_b.z;\n                float _4332 = in.fa_world_pos.y - _396.fa_fog_b.z;\n                bool _4335 = _4327 <= 0.0;\n                bool _4336 = !_4335;\n                bool _4342;\n                if (_4336)\n                {\n                    _4342 = _396.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4342 = _4335;\n                }\n                float _4343;\n                if (_4342)\n                {\n                    _4343 = _396.fa_fog_b.y;\n                }\n                else\n                {\n                    _4343 = _396.fa_fog_b.y * exp(-fast::min(_396.fa_fog_b.w * _4327, 80.0));\n                }\n                bool _4370;\n                if (_4336)\n                {\n                    _4370 = _396.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4370 = _4335;\n                }\n                float _4371;\n                if (_4370)\n                {\n                    _4371 = _396.fa_fog_b.y * _4327;\n                }\n                else\n                {\n                    _4371 = (_396.fa_fog_b.y * (1.0 - exp(-fast::min(_396.fa_fog_b.w * _4327, 80.0)))) / _396.fa_fog_b.w;\n                }\n                bool _4396 = _4332 <= 0.0;\n                bool _4403;\n                if (!_4396)\n                {\n                    _4403 = _396.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4403 = _4396;\n                }\n                float _4404;\n                if (_4403)\n                {\n                    _4404 = _396.fa_fog_b.y * _4332;\n                }\n                else\n                {\n                    _4404 = (_396.fa_fog_b.y * (1.0 - exp(-fast::min(_396.fa_fog_b.w * _4332, 80.0)))) / _396.fa_fog_b.w;\n                }\n                float _4431;\n                if (abs(_4322) < 0.001000000047497451305389404296875)\n                {\n                    _4431 = _4343;\n                }\n                else\n                {\n                    _4431 = (_4404 - _4371) / _4322;\n                }\n                tau += (_4272 * fast::max(_4431, 0.0));\n            }\n            result = mix(result, _396.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _4562);\n    return out;\n}\n\n",
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
            "size": 624,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_396",
            "msl_buffer_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2053",
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
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n#pragma clang diagnostic ignored \"-Wmissing-braces\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\ntemplate<typename T, size_t Num>\nstruct spvUnsafeArray\n{\n    T elements[Num ? Num : 1];\n    \n    thread T& operator [] (size_t pos) thread\n    {\n        return elements[pos];\n    }\n    constexpr const thread T& operator [] (size_t pos) const thread\n    {\n        return elements[pos];\n    }\n    \n    device T& operator [] (size_t pos) device\n    {\n        return elements[pos];\n    }\n    constexpr const device T& operator [] (size_t pos) const device\n    {\n        return elements[pos];\n    }\n    \n    constexpr const constant T& operator [] (size_t pos) const constant\n    {\n        return elements[pos];\n    }\n    \n    threadgroup T& operator [] (size_t pos) threadgroup\n    {\n        return elements[pos];\n    }\n    constexpr const threadgroup T& operator [] (size_t pos) const threadgroup\n    {\n        return elements[pos];\n    }\n};\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n    float4 fa_ct_a;\n    float4 fa_ct_b;\n    float4 fa_ct_vpx;\n    float4 fa_ct_vpy;\n    float4 fa_ct_vpw;\n    float4 fa_ct_fwd;\n    float4 fa_probe_sh[9];\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n    float4 fa_shadow_lcfg;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float3 fa_lm [[user(locn5)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_cluster_texel(thread const float3& world_pos, constant fa_mesh_fs_params& _396, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    bool _1324 = _396.fa_cl_info.x < 0.0;\n    bool _1331;\n    if (!_1324)\n    {\n        _1331 = _396.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _1331 = _1324;\n    }\n    bool _1339;\n    if (!_1331)\n    {\n        _1339 = _396.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _1339 = _1331;\n    }\n    bool _1346;\n    if (!_1339)\n    {\n        _1346 = _396.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _1346 = _1339;\n    }\n    bool _1353;\n    if (!_1346)\n    {\n        _1353 = _396.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _1353 = _1346;\n    }\n    if (_1353)\n    {\n        return float4(0.0);\n    }\n    float4 _1363 = float4(world_pos, 1.0);\n    float _1369 = dot(_396.fa_cl_vpw, _1363);\n    if (!(_1369 > 9.9999999747524270787835121154785e-07))\n    {\n        return float4(0.0);\n    }\n    float2 _1391 = float2(dot(_396.fa_cl_vpx, _1363), dot(_396.fa_cl_vpy, _1363)) / float2(_1369);\n    int _1395 = int(_396.fa_cl_grid.x);\n    int _1399 = int(_396.fa_cl_grid.y);\n    int param = (int(_396.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_396.fa_cl_fwd.xyz, world_pos) + _396.fa_cl_fwd.w, _396.fa_cl_grid.w) / _396.fa_cl_grid.w) * _396.fa_cl_grid.z)), 0, int(_396.fa_cl_info.y) - 1) * _1399) + clamp(int(floor(((_1391.y * 0.5) + 0.5) * _396.fa_cl_grid.y)), 0, _1399 - 1)) * _1395)) + clamp(int(floor(((_1391.x * 0.5) + 0.5) * _396.fa_cl_grid.x)), 0, _1395 - 1);\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, constant fa_mesh_fs_params& _396, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    float3 param = world_pos;\n    float4 _1475 = fa_cluster_texel(param, _396, fa_light_tex, fa_shadow_smp);\n    return int2(int(_1475.x), int(_1475.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, constant fa_mesh_fs_params& _396, texture2d<float> fa_light_tex, sampler fa_shadow_smp, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_396.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _3534 = fa_cluster_lookup(param, _396, fa_light_tex, fa_shadow_smp);\n    fa_cl_slot = _3534.x;\n    fa_cl_local = _3534.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _3744 = fa_linear_to_srgb(param);\n        c = _3744;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _3752 = fa_srgb_to_linear(param_1);\n            c = _3752;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _278;\n    if (bool(i.front_facing))\n    {\n        _278 = i.world_normal;\n    }\n    else\n    {\n        _278 = -i.world_normal;\n    }\n    float3 _302 = fast::normalize(i.world_tangent.xyz - (_278 * dot(_278, i.world_tangent.xyz)));\n    float3 _329 = fast::normalize(((_302 * m.x) + ((cross(_278, _302) * i.world_tangent.w) * m.y)) + (_278 * m.z));\n    float3 _332;\n    if (bool(i.front_facing))\n    {\n        _332 = _329;\n    }\n    else\n    {\n        _332 = -_329;\n    }\n    return _332;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _396, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _396.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _3783 = fa_tex_fix(param_2, param_3);\n    float4 _4874 = base_t;\n    _4874.x = _3783.x;\n    _4874.y = _3783.y;\n    _4874.z = _3783.z;\n    base_t = _4874;\n    float4 _3797 = (_4874 * _396.fa_base_color) * i.vertex_color;\n    float3 _4726 = i.world_normal;\n    if (_396.fa_maps.z > 0.5)\n    {\n        float param_4 = _396.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _3829 = fa_tex_fix(param_6, param_7);\n        float3 _3832 = (_3829 * 2.0) - float3(1.0);\n        float2 _3837 = _3832.xy * _396.fa_maps.x;\n        float3 _4882 = _3832;\n        _4882.x = _3837.x;\n        _4882.y = _3837.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _4882;\n        _4726 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _396.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _3865 = fa_tex_fix(param_12, param_13);\n    float4 _4885 = mrt;\n    _4885.x = _3865.x;\n    _4885.y = _3865.y;\n    _4885.z = _3865.z;\n    mrt = _4885;\n    float4 _3893 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _396.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _3893.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _3904 = fa_tex_fix(param_16, param_17);\n    float param_18 = _396.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _3934 = fa_tex_fix(param_20, param_21);\n    float _4731 = _396.fa_layers_a.x;\n    float _4732 = _396.fa_layers_a.y;\n    float _4735 = _396.fa_layers_a.z;\n    float _4734 = _396.fa_layers_b.w;\n    float _4737 = _396.fa_layers_c.x;\n    if (_396.fa_layers_c.z > 0.5)\n    {\n        if (mod(_396.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _4731 *= _3904.y;\n            _4732 *= _3904.z;\n            _4734 *= _3893.w;\n        }\n        if (_396.fa_layers_c.z > 1.5)\n        {\n            _4735 *= mrt.x;\n            _4737 *= mrt.w;\n        }\n    }\n    return Surface{ _3797.xyz, _3797.w, _4726, fast::clamp(_396.fa_pbr.x * _3865.z, 0.0, 1.0), fast::clamp(_396.fa_pbr.y * _3865.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_396.fa_maps.y * (_3904.x - 1.0)), _396.fa_emissive.xyz + (_396.fa_model_emissive.xyz * _3934), _4731, _4732, _396.fa_layers_b.xyz, _4734, _4735, _396.fa_layers_a.w, _4737, _396.fa_layers_c.y, _396.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_decal_tile(thread const float4& rect, thread const float2& uv, thread const float2& atlas, thread const float2& ddx, thread const float2& ddy, sampler fa_env_smp, texture2d<float> fa_decal_tex)\n{\n    float2 _1555 = rect.zw - rect.xy;\n    float2 _1559 = _1555 * atlas;\n    float2 _1563 = ddx * _1559;\n    float2 _1567 = ddy * _1559;\n    return fa_decal_tex.sample(fa_env_smp, (rect.xy + (fast::clamp(uv, float2(0.0), float2(1.0)) * _1555)), level(fast::clamp(0.5 * log2(fast::max(fast::max(dot(_1563, _1563), dot(_1567, _1567)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_apply_decals(thread const float3& world_pos, thread const float3& geo_normal, thread float3& albedo, thread float3& normal, constant fa_mesh_fs_params& _396, texture2d<float> fa_light_tex, sampler fa_shadow_smp, sampler fa_env_smp, texture2d<float> fa_decal_tex)\n{\n    bool _1600 = _396.fa_counts.y < 0.5;\n    bool _1607;\n    if (!_1600)\n    {\n        _1607 = _396.fa_counts.w < 0.5;\n    }\n    else\n    {\n        _1607 = _1600;\n    }\n    if (_1607)\n    {\n        return;\n    }\n    float3 _1613 = dfdx(world_pos);\n    float3 _1616 = dfdy(world_pos);\n    float3 param = world_pos;\n    float4 _1620 = fa_cluster_texel(param, _396, fa_light_tex, fa_shadow_smp);\n    int _1624 = int(_1620.w);\n    if (_1624 < 1)\n    {\n        return;\n    }\n    int _1634 = int(_396.fa_counts.y + 0.5);\n    int param_1 = _1634;\n    float4 _1638 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float2 _1641 = _1638.yz;\n    int _1645 = int(_1638.w);\n    int param_2 = _1634 + 1;\n    float4 _1650 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float _1651 = _1650.x;\n    int _1657 = int(_396.fa_counts.w + 0.5) - 1;\n    int _1661 = int(_1620.z);\n    float3 _1926;\n    for (int k = 0; k < _1624; k++)\n    {\n        int _1674 = _1661 + k;\n        int param_3 = _1645 + (_1674 >> 2);\n        int _1691 = (_1634 + 2) + (int(fa_light_texel(param_3, fa_light_tex, fa_shadow_smp)[_1674 & 3]) * 7);\n        int param_4 = _1691 + 6;\n        float4 _1696 = fa_light_texel(param_4, fa_light_tex, fa_shadow_smp);\n        if (((int(_1696.w + 0.5) >> _1657) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1691;\n        float4 _1711 = fa_light_texel(param_5, fa_light_tex, fa_shadow_smp);\n        int param_6 = _1691 + 1;\n        float4 _1716 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n        int param_7 = _1691 + 2;\n        float4 _1721 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n        float3 _1724 = _1711.xyz;\n        float _1729 = dot(_1724, world_pos) + _1711.w;\n        float3 _1731 = _1716.xyz;\n        float _1736 = dot(_1731, world_pos) + _1716.w;\n        float3 _1738 = _1721.xyz;\n        float _1743 = dot(_1738, world_pos) + _1721.w;\n        bool _1748 = abs(_1729) > 0.5;\n        bool _1756;\n        if (!_1748)\n        {\n            _1756 = abs(_1736) > 0.5;\n        }\n        else\n        {\n            _1756 = _1748;\n        }\n        bool _1764;\n        if (!_1756)\n        {\n            _1764 = abs(_1743) > 0.5;\n        }\n        else\n        {\n            _1764 = _1756;\n        }\n        if (_1764)\n        {\n            continue;\n        }\n        float _1779 = fast::clamp(dot(geo_normal, fast::normalize(_1738)) * _1696.z, 0.0, 1.0);\n        if (_1779 <= 0.0)\n        {\n            continue;\n        }\n        float _1799 = (fast::clamp((0.5 - abs(_1743)) * 10.0, 0.0, 1.0) * _1779) * _1696.x;\n        float2 _1807 = float2(_1729 + 0.5, 0.5 - _1736);\n        float2 _1817 = float2(dot(_1724, _1613), dot(_1731, _1613));\n        float2 _1827 = float2(dot(_1724, _1616), dot(_1731, _1616));\n        int param_8 = _1691 + 5;\n        float4 _1832 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n        int param_9 = _1691 + 3;\n        float4 _1837 = fa_light_texel(param_9, fa_light_tex, fa_shadow_smp);\n        int param_10 = _1691 + 4;\n        float4 _1842 = fa_light_texel(param_10, fa_light_tex, fa_shadow_smp);\n        float tex_a = 1.0;\n        float3 col = _1832.xyz;\n        bool _1852 = _1837.z > _1837.x;\n        if (_1852)\n        {\n            float4 param_11 = _1837;\n            float2 param_12 = _1807;\n            float2 param_13 = _1641;\n            float2 param_14 = _1817;\n            float2 param_15 = _1827;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15, fa_env_smp, fa_decal_tex);\n            if ((_1651 > 0.5) && (_1651 < 1.5))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1878 = fa_dc_to_linear(param_16);\n                float4 _4806 = tx;\n                _4806.x = _1878.x;\n                _4806.y = _1878.y;\n                _4806.z = _1878.z;\n                tx = _4806;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, float3(fast::clamp((_1799 * tex_a) * _1832.w, 0.0, 1.0)));\n        if (_1842.z > _1842.x)\n        {\n            float4 param_17 = _1842;\n            float2 param_18 = _1807;\n            float2 param_19 = _1641;\n            float2 param_20 = _1817;\n            float2 param_21 = _1827;\n            float4 _1922 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21, fa_env_smp, fa_decal_tex);\n            if (_1651 > 1.5)\n            {\n                float3 param_22 = _1922.xyz;\n                float3 _1932 = fa_dc_to_srgb(param_22);\n                _1926 = _1932;\n            }\n            else\n            {\n                _1926 = _1922.xyz;\n            }\n            float3 _1941 = (_1926 * 2.0) - float3(1.0);\n            float2 _1946 = _1941.xy * _1696.y;\n            float3 _1968 = (fast::normalize(_1724) * _1946.x) + (fast::normalize(_1731) * _1946.y);\n            float3 _1971 = fast::normalize(normal);\n            normal = fast::normalize(mix(_1971, fast::normalize((_1971 * fast::max(_1941.z, 0.0500000007450580596923828125)) + (_1968 - (_1971 * dot(_1971, _1968)))), float3(fast::clamp(_1799 * (_1852 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_sh_coef(thread const int& k, constant fa_mesh_fs_params& _396, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float3 v = fa_env_tex.sample(fa_env_smp, float3(1.0, 1.0 - (float((2 * (k >> 2)) + 1) * 0.25), 1.0 - (float((2 * (k & 3)) + 1) * 0.25)), level(5.0)).xyz;\n    if (_396.fa_env_sky.w > 1.5)\n    {\n        v = (v - float3(0.5)) * 8.0;\n    }\n    return v;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sh_eval(thread const spvUnsafeArray<float3, 9>& c, thread const float3& n)\n{\n    float3 _3166 = fast::max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), float3(0.0));\n    return _3166;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _396, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    if (_396.fa_env_sky.w > 0.5)\n    {\n        spvUnsafeArray<float3, 9> c;\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param, _396, fa_env_smp, fa_env_tex);\n        }\n        spvUnsafeArray<float3, 9> param_1 = c;\n        float3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return _396.fa_ambient.xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_indirect_diffuse(thread const float3& n, constant fa_mesh_fs_params& _396, sampler fa_env_smp, texturecube<float> fa_env_tex, thread float3& fa_lm, texture2d<float> fa_lightmap)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return fa_lightmap.sample(fa_env_smp, fa_lm.xy, level(0.0)).xyz;\n    }\n    if (_396.fa_probe_sh[0].w > 0.0)\n    {\n        spvUnsafeArray<float3, 9> c;\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = _396.fa_probe_sh[k].xyz;\n        }\n        float3 param = n;\n        spvUnsafeArray<float3, 9> param_1 = c;\n        float3 param_2 = n;\n        return mix(fa_ambient_light(param, _396, fa_env_smp, fa_env_tex), fa_sh_eval(param_1, param_2), float3(fast::clamp(_396.fa_probe_sh[0].w, 0.0, 1.0)));\n    }\n    float3 param_3 = n;\n    return fa_ambient_light(param_3, _396, fa_env_smp, fa_env_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 ambient(thread const SurfaceInput& i, thread const Surface& s, thread const float3& ambientColor)\n{\n    return float3(0.0, ambientColor.y, 0.0);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, constant fa_mesh_fs_params& _396, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (int(_396.fa_cl_info.x) + int(_396.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, constant fa_mesh_fs_params& _396, texture2d<float> fa_light_tex, sampler fa_shadow_smp, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, _396, fa_light_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_light_base(thread const int& li, constant fa_mesh_fs_params& _396)\n{\n    return li * ((_396.fa_ambient.w > 4.5) ? 8 : 4);\n}\n\nstatic inline __attribute__((always_inline))\nbool fa_light_baked(thread const int& li, constant fa_mesh_fs_params& _396, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li;\n    int param_1 = fa_light_base(param, _396) + 3;\n    return fa_light_texel(param_1, fa_light_tex, fa_shadow_smp).w > 0.5;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_baked_keep(thread const int& li, constant fa_mesh_fs_params& _396, texture2d<float> fa_light_tex, sampler fa_shadow_smp, thread float3& fa_lm)\n{\n    float _3504;\n    if (fa_lm.z > 0.5)\n    {\n        _3504 = 0.0;\n    }\n    else\n    {\n        _3504 = 1.0 - fast::clamp(_396.fa_probe_sh[0].w, 0.0, 1.0);\n    }\n    bool _3515 = _3504 < 1.0;\n    bool _3521;\n    if (_3515)\n    {\n        int param = li;\n        _3521 = fa_light_baked(param, _396, fa_light_tex, fa_shadow_smp);\n    }\n    else\n    {\n        _3521 = _3515;\n    }\n    return _3521 ? _3504 : 1.0;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_light_type(thread const int& li, constant fa_mesh_fs_params& _396, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li;\n    int param_1 = fa_light_base(param, _396) + 1;\n    return fa_light_texel(param_1, fa_light_tex, fa_shadow_smp).w;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_atlas_fetch(thread const float2& texel, texture2d<float> fa_light_atlas, sampler fa_env_smp)\n{\n    return fa_light_atlas.sample(fa_env_smp, (texel / float2(int2(fa_light_atlas.get_width(), fa_light_atlas.get_height()))), level(0.0));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_cookie_sample(thread const float2& tile_origin, thread const float2& uv, texture2d<float> fa_light_atlas, sampler fa_env_smp)\n{\n    float2 param = (tile_origin + float2(1.0)) + (fast::clamp(uv, float2(0.0), float2(1.0)) * 254.0);\n    return fa_atlas_fetch(param, fa_light_atlas, fa_env_smp).xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_area_point(thread const float3& c, thread const float3& axis, thread const float3& ru, thread const float3& uu, thread const float& hx, thread const float& hy, thread const float& shape, thread const float3& p, thread const float3& r)\n{\n    bool _574 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        float3 _587 = (c - (ru * hx)) - p;\n        float3 _593 = ru * (2.0 * hx);\n        float _599 = fast::max(dot(_593, _593), 9.9999999392252902907785028219223e-09);\n        float _603 = dot(_587, _593);\n        float t = fast::clamp((-_603) / _599, 0.0, 1.0);\n        if (_574)\n        {\n            float _618 = dot(r, _593);\n            float _624 = _599 - (_618 * _618);\n            if (abs(_624) > (9.9999997473787516355514526367188e-06 * _599))\n            {\n                t = fast::clamp(((dot(r, _587) * _618) - _603) / _624, 0.0, 1.0);\n            }\n        }\n        return (p + _587) + (_593 * t);\n    }\n    float3 q = p;\n    float _656 = dot(r, axis);\n    bool _664;\n    if (_574)\n    {\n        _664 = abs(_656) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _664 = _574;\n    }\n    if (_664)\n    {\n        float _674 = dot(c - p, axis) / _656;\n        if (_674 > 0.0)\n        {\n            q = p + (r * _674);\n        }\n    }\n    float3 _687 = q - c;\n    float2 xy = float2(dot(_687, ru), dot(_687, uu));\n    if (shape > 0.5)\n    {\n        float _702 = length(xy);\n        if (_702 > hx)\n        {\n            xy *= (hx / _702);\n        }\n    }\n    else\n    {\n        xy = fast::clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cube_face(thread const float3& d)\n{\n    float3 _344 = abs(d);\n    float _346 = _344.x;\n    float _348 = _344.y;\n    bool _349 = _346 >= _348;\n    bool _357;\n    if (_349)\n    {\n        _357 = _346 >= _344.z;\n    }\n    else\n    {\n        _357 = _349;\n    }\n    int _358;\n    if (_357)\n    {\n        _358 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _373;\n        if (_348 >= _344.z)\n        {\n            _373 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _373 = (d.z > 0.0) ? 4 : 5;\n        }\n        _358 = _373;\n    }\n    return _358;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cube_face_basis(thread const int& f, thread float3& fwd, thread float3& up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0, 0.0, 0.0);\n        up = float3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0, 0.0, 0.0);\n            up = float3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0, 1.0, 0.0);\n                up = float3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0, -1.0, 0.0);\n                    up = float3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0, 0.0, 1.0);\n                        up = float3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0, 0.0, -1.0);\n                        up = float3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_ies_sample(thread const float2& tile_origin, thread const float3& d, thread const float3& axis, thread const float3& right, thread const float3& up, texture2d<float> fa_light_atlas, sampler fa_env_smp)\n{\n    float _494 = dot(d, right);\n    float _498 = dot(d, up);\n    float _509;\n    if (((_494 * _494) + (_498 * _498)) > 1.0000000133514319600180897396058e-10)\n    {\n        _509 = precise::atan2(_498, _494) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _509 = 0.0;\n    }\n    float2 param = tile_origin + float2(1.0 + ((_509 - floor(_509)) * 64.0), 1.0 + (acos(fast::clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param, fa_light_atlas, fa_env_smp).x;\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample_n(thread const int& li, thread const float3& world_pos, thread const float3& n, constant fa_mesh_fs_params& _396, texture2d<float> fa_light_tex, sampler fa_shadow_smp, texture2d<float> fa_light_atlas, sampler fa_env_smp, thread float3& fa_light_tint, thread bool& fa_light_is_area)\n{\n    int param = li;\n    int _740 = fa_light_base(param, _396);\n    bool _744 = _396.fa_ambient.w > 4.5;\n    int param_1 = _740;\n    float4 _748 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    int param_2 = _740 + 1;\n    float4 _753 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float _756 = _753.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = float3(1.0);\n    bool _768 = _744 && (_756 > 2.5);\n    fa_light_is_area = _768;\n    bool _770 = _756 < 0.5;\n    float3 l;\n    if (_770)\n    {\n        l = fast::normalize(_748.xyz);\n        if (_744)\n        {\n            int param_3 = _740 + 6;\n            float4 _784 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            if (_784.z > 0.5)\n            {\n                int param_4 = _740 + 4;\n                float4 _794 = fa_light_texel(param_4, fa_light_tex, fa_shadow_smp);\n                int param_5 = _740 + 5;\n                float4 _799 = fa_light_texel(param_5, fa_light_tex, fa_shadow_smp);\n                float2 param_6 = _784.xy;\n                float2 param_7 = fract(float2(dot(world_pos, _794.xyz) * _794.w, (-dot(world_pos, _799.xyz)) * _799.w) + float2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7, fa_light_atlas, fa_env_smp);\n            }\n        }\n    }\n    else\n    {\n        float3 _829 = _748.xyz;\n        float3 _831 = _829 - world_pos;\n        float3 to_light = _831;\n        float _834 = length(_831);\n        float reach = _834;\n        bool front = true;\n        if (_768)\n        {\n            int param_8 = _740 + 7;\n            reach = fast::max(_834 - fa_light_texel(param_8, fa_light_tex, fa_shadow_smp).w, 0.0);\n            int param_9 = _740 + 4;\n            float4 _858 = fa_light_texel(param_9, fa_light_tex, fa_shadow_smp);\n            int param_10 = _740 + 5;\n            float4 _863 = fa_light_texel(param_10, fa_light_tex, fa_shadow_smp);\n            int param_11 = _740 + 6;\n            float4 _868 = fa_light_texel(param_11, fa_light_tex, fa_shadow_smp);\n            float _869 = _868.w;\n            int param_12 = _740 + 2;\n            float3 _876 = fast::normalize(fa_light_texel(param_12, fa_light_tex, fa_shadow_smp).xyz);\n            bool _878 = _869 > 1.5;\n            bool _886;\n            if (!_878)\n            {\n                _886 = dot(_876, to_light) < 0.0;\n            }\n            else\n            {\n                _886 = _878;\n            }\n            front = _886;\n            float3 r = float3(0.0);\n            float3 _895 = _396.fa_camera_pos.xyz - world_pos;\n            bool _899 = dot(n, n) > 0.5;\n            bool _907;\n            if (_899)\n            {\n                _907 = dot(_895, _895) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _907 = _899;\n            }\n            if (_907)\n            {\n                r = reflect(-fast::normalize(_895), fast::normalize(n));\n            }\n            float3 param_13 = _829;\n            float3 param_14 = _876;\n            float3 param_15 = _858.xyz;\n            float3 param_16 = _863.xyz;\n            float param_17 = _858.w;\n            float param_18 = _863.w;\n            float param_19 = _869;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _943 = length(to_light);\n        dist = _943;\n        l = to_light / float3(fast::max(_943, 9.9999997473787516355514526367188e-05));\n        float _957 = reach / fast::max(_748.w, 0.001000000047497451305389404296875);\n        float _963 = fast::clamp(1.0 - (_957 * _957), 0.0, 1.0);\n        float _965;\n        if (front)\n        {\n            _965 = _963 * _963;\n        }\n        else\n        {\n            _965 = 0.0;\n        }\n        atten = _965;\n        bool _976 = _756 < 2.5;\n        if ((_756 > 1.5) && _976)\n        {\n            int param_22 = _740 + 2;\n            float4 _984 = fa_light_texel(param_22, fa_light_tex, fa_shadow_smp);\n            float _994 = _984.w;\n            int param_23 = _740 + 3;\n            float4 _999 = fa_light_texel(param_23, fa_light_tex, fa_shadow_smp);\n            float _1000 = _999.x;\n            float cos_inner = _1000;\n            if (_1000 > 1.5)\n            {\n                cos_inner = mix(_994, 1.0, 0.25);\n            }\n            atten *= smoothstep(_994, cos_inner, dot(-l, fast::normalize(_984.xyz)));\n        }\n        if (_744 && (_756 < 1.5))\n        {\n            int param_24 = _740 + 6;\n            float4 _1024 = fa_light_texel(param_24, fa_light_tex, fa_shadow_smp);\n            if (_1024.z > 0.5)\n            {\n                float3 _1032 = -to_light;\n                int param_25 = _740 + 4;\n                int param_26 = _740 + 5;\n                float3 _1046 = fa_light_texel(param_25, fa_light_tex, fa_shadow_smp).xyz;\n                float3 _1050 = fa_light_texel(param_26, fa_light_tex, fa_shadow_smp).xyz;\n                float3 _1059 = float3(dot(_1032, _1046), dot(_1032, _1050), dot(_1032, cross(_1046, _1050)));\n                float3 param_27 = _1059;\n                int _1063 = fa_cube_face(param_27);\n                int param_28 = _1063;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1090 = float2(dot(_1059, cross(param_29, param_30)), dot(_1059, param_30)) / float2(fast::max(dot(_1059, param_29), 9.9999997473787516355514526367188e-05));\n                int _1094 = _1063 / 3;\n                float2 param_31 = _1024.xy + (float2(float(_1063 - (_1094 * 3)), float(_1094)) * 256.0);\n                float2 param_32 = float2(0.5 + (0.5 * _1090.x), 0.5 - (0.5 * _1090.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32, fa_light_atlas, fa_env_smp);\n            }\n            int param_33 = _740 + 7;\n            float4 _1124 = fa_light_texel(param_33, fa_light_tex, fa_shadow_smp);\n            if (_1124.z > 0.5)\n            {\n                int param_34 = _740 + 2;\n                int param_35 = _740 + 4;\n                int param_36 = _740 + 5;\n                float2 param_37 = _1124.xy;\n                float3 param_38 = -l;\n                float3 param_39 = fast::normalize(fa_light_texel(param_34, fa_light_tex, fa_shadow_smp).xyz);\n                float3 param_40 = fa_light_texel(param_35, fa_light_tex, fa_shadow_smp).xyz;\n                float3 param_41 = fa_light_texel(param_36, fa_light_tex, fa_shadow_smp).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41, fa_light_atlas, fa_env_smp);\n            }\n        }\n        else\n        {\n            if (_744 && _976)\n            {\n                int param_42 = _740 + 6;\n                float4 _1171 = fa_light_texel(param_42, fa_light_tex, fa_shadow_smp);\n                int param_43 = _740 + 7;\n                float4 _1176 = fa_light_texel(param_43, fa_light_tex, fa_shadow_smp);\n                bool _1179 = _1171.z > 0.5;\n                bool _1186;\n                if (!_1179)\n                {\n                    _1186 = _1176.z > 0.5;\n                }\n                else\n                {\n                    _1186 = _1179;\n                }\n                if (_1186)\n                {\n                    int param_44 = _740 + 2;\n                    float4 _1193 = fa_light_texel(param_44, fa_light_tex, fa_shadow_smp);\n                    float3 _1197 = fast::normalize(_1193.xyz);\n                    int param_45 = _740 + 4;\n                    float4 _1202 = fa_light_texel(param_45, fa_light_tex, fa_shadow_smp);\n                    int param_46 = _740 + 5;\n                    float4 _1207 = fa_light_texel(param_46, fa_light_tex, fa_shadow_smp);\n                    if (_1179)\n                    {\n                        float3 _1215 = -to_light;\n                        float _1222 = _1193.w;\n                        float _1238 = 0.5 / fast::max(dot(_1215, _1197) * (sqrt(fast::max(1.0 - (_1222 * _1222), 0.0)) / fast::max(_1222, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        float2 param_47 = _1171.xy;\n                        float2 param_48 = float2(0.5 + (dot(_1215, _1202.xyz) * _1238), 0.5 - (dot(_1215, _1207.xyz) * _1238));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48, fa_light_atlas, fa_env_smp);\n                    }\n                    if (_1176.z > 0.5)\n                    {\n                        float2 param_49 = _1176.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1197;\n                        float3 param_52 = _1202.xyz;\n                        float3 param_53 = _1207.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53, fa_light_atlas, fa_env_smp);\n                    }\n                }\n            }\n        }\n    }\n    float3 _4680 = _753.xyz * atten;\n    if (_744)\n    {\n        _4680 *= fa_light_tint;\n    }\n    int _1306;\n    if (_770)\n    {\n        _1306 = 0;\n    }\n    else\n    {\n        _1306 = ((_756 > 1.5) && (_756 < 2.5)) ? 2 : 1;\n    }\n    return LightSample{ l, _4680, atten, 1.0, dist, _1306 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _2053)\n{\n    float _2043;\n    if (i == 0)\n    {\n        _2043 = _2053.fa_shadow_split.x;\n    }\n    else\n    {\n        float _2059;\n        if (i == 1)\n        {\n            _2059 = _2053.fa_shadow_split.y;\n        }\n        else\n        {\n            float _2067;\n            if (i == 2)\n            {\n                _2067 = _2053.fa_shadow_split.z;\n            }\n            else\n            {\n                _2067 = _2053.fa_shadow_split.w;\n            }\n            _2059 = _2067;\n        }\n        _2043 = _2059;\n    }\n    return _2043;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_fetch(thread const float2& uv, thread const float4& rect, thread const float3& conv, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2100 = fa_shadow_depth(param, param_1, fa_shadow_smp, fa_shadow_tex);\n    float _2104;\n    if (conv.x < 0.5)\n    {\n        _2104 = _2100;\n    }\n    else\n    {\n        _2104 = (conv.y * conv.z) / (conv.z - (_2100 * (conv.z - conv.y)));\n    }\n    return _2104;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _2031 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_2031), sin(_2031)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_filter(thread const float2& uv, thread const float4& rect, thread const float& zr, thread const float& texel_m, thread const float& unit, thread const float& reach, thread const float& plane, thread const float3& conv, thread const int& mode, thread const float& k, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2053, texture2d<float> fa_shadow_tex)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2, fa_shadow_smp, fa_shadow_tex));\n    }\n    float _2150 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2159;\n        if (k < 0.0)\n        {\n            _2159 = (-k) / fast::max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2159 = k;\n        }\n        float _2179 = fast::clamp((_2159 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2150;\n            float2 _2198 = fa_shadow_vogel(param_3, param_4, param_5) * _2179;\n            float2 param_6 = uv + (_2198 * _2053.fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _2210 = fa_shadow_fetch(param_6, param_7, param_8, fa_shadow_smp, fa_shadow_tex);\n            if (_2210 < (zr - (length(_2198) * plane)))\n            {\n                sum += _2210;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2236 = sum / cnt;\n        float _2246;\n        if (k < 0.0)\n        {\n            _2246 = (-k) / fast::max(_2236, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2246 = k;\n        }\n        radius = fast::clamp(((fast::max(zr - _2236, 0.0) * unit) * _2246) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _2268 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2268; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2268;\n        float param_11 = _2150;\n        float2 _2287 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_2287 * _2053.fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_2287) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14, fa_shadow_smp, fa_shadow_tex));\n    }\n    return lit / float(_2268);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2053, texture2d<float> fa_shadow_tex)\n{\n    float _2329 = fast::max(_2053.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _2334 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _2340 = sqrt(1.0 - (_2334 * _2334));\n    float _2347 = fast::min(_2340 / fast::max(_2334, 0.20000000298023223876953125), 4.0);\n    float _2352;\n    if (_2053.fa_shadow_bias.y > 0.0)\n    {\n        _2352 = _2053.fa_shadow_bias.y;\n    }\n    else\n    {\n        _2352 = 1.5 * _2053.fa_shadow_info[ci].x;\n    }\n    float4 _2377 = _2053.fa_shadow_mat[ci] * float4(world + (n * (_2352 * _2340)), 1.0);\n    float _2384 = _2377.x;\n    bool _2387 = _2384 < _2053.fa_shadow_rect[ci].x;\n    bool _2396;\n    if (!_2387)\n    {\n        _2396 = _2384 > _2053.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2396 = _2387;\n    }\n    bool _2405;\n    if (!_2396)\n    {\n        _2405 = _2377.y < _2053.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2405 = _2396;\n    }\n    bool _2414;\n    if (!_2405)\n    {\n        _2414 = _2377.y > _2053.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2414 = _2405;\n    }\n    bool _2421;\n    if (!_2414)\n    {\n        _2421 = _2377.z > 1.0;\n    }\n    else\n    {\n        _2421 = _2414;\n    }\n    if (_2421)\n    {\n        return -1.0;\n    }\n    float _2429;\n    if (_2053.fa_shadow_bias.x > 0.0)\n    {\n        _2429 = _2053.fa_shadow_bias.x;\n    }\n    else\n    {\n        _2429 = 1.5 * _2053.fa_shadow_info[ci].x;\n    }\n    float2 param = _2377.xy;\n    float4 param_1 = _2053.fa_shadow_rect[ci];\n    float param_2 = _2377.z - ((_2429 * (1.0 + (0.5 * _2347))) / _2329);\n    float param_3 = _2053.fa_shadow_info[ci].x;\n    float param_4 = _2329;\n    float param_5 = _2329 * 0.25;\n    float param_6 = ((_2053.fa_shadow_info[ci].x * fast::min(_2347, 3.0)) * 0.5) / _2329;\n    float3 param_7 = float3(0.0);\n    int param_8 = int(_2053.fa_shadow_cfg.z + 0.5);\n    float param_9 = _2053.fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9, fa_shadow_smp, gl_FragCoord, _2053, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _396, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2053, texture2d<float> fa_shadow_tex)\n{\n    if (_396.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2807 = int(_2053.fa_shadow_cfg.x + 0.5);\n    if (_2807 < 1)\n    {\n        return 1.0;\n    }\n    float _2822 = dot(world - _2053.fa_shadow_eye.xyz, _2053.fa_shadow_fwd.xyz);\n    int param = _2807 - 1;\n    if (_2822 > fa_shadow_split_at(param, _2053))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2834 = _2807 > 1;\n    bool _2841;\n    if (_2834)\n    {\n        _2841 = _2822 > _2053.fa_shadow_split.x;\n    }\n    else\n    {\n        _2841 = _2834;\n    }\n    if (_2841)\n    {\n        ci = 1;\n    }\n    bool _2845 = _2807 > 2;\n    bool _2852;\n    if (_2845)\n    {\n        _2852 = _2822 > _2053.fa_shadow_split.y;\n    }\n    else\n    {\n        _2852 = _2845;\n    }\n    if (_2852)\n    {\n        ci = 2;\n    }\n    bool _2856 = _2807 > 3;\n    bool _2863;\n    if (_2856)\n    {\n        _2863 = _2822 > _2053.fa_shadow_split.z;\n    }\n    else\n    {\n        _2863 = _2856;\n    }\n    if (_2863)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2807)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2889 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_shadow_smp, gl_FragCoord, _2053, fa_shadow_tex);\n        s = _2889;\n        if (_2889 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_2053.fa_shadow_cfg.y > 0.0)\n    {\n        float _2914;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2914 = fa_shadow_split_at(param_5, _2053);\n        }\n        else\n        {\n            _2914 = _2053.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _2933 = _2053.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _2053) - _2914, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2944 = fast::clamp((_2822 - (fa_shadow_split_at(param_7, _2053) - _2933)) / _2933, 0.0, 1.0);\n        if (_2944 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2807)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _2965 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_shadow_smp, gl_FragCoord, _2053, fa_shadow_tex);\n                s2 = _2965;\n                if (_2965 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2944);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _396, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2053, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, _396, fa_shadow_smp, gl_FragCoord, _2053, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_local(thread const int& li, thread const float3& lpos, thread const float3& world, thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _396, texture2d<float> fa_light_tex, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2053, texture2d<float> fa_shadow_tex)\n{\n    bool _2487 = _396.fa_pbr.z < 0.5;\n    bool _2494;\n    if (!_2487)\n    {\n        _2494 = _2053.fa_shadow_lcfg.x < 0.5;\n    }\n    else\n    {\n        _2494 = _2487;\n    }\n    if (_2494)\n    {\n        return 1.0;\n    }\n    int param = (int(_2053.fa_shadow_lcfg.x + 0.5) - 1) + li;\n    float4 _2507 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    float _2508 = _2507.x;\n    if (_2508 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2517 = int(_2508 + 0.5);\n    int param_1 = _2517;\n    float4 _2521 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    int param_2 = _2517 + 1;\n    float4 _2526 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float fade = 1.0;\n    float _2529 = _2521.y;\n    if (_2529 > 0.0)\n    {\n        float _2546 = 1.0 - smoothstep(0.75 * _2529, _2529, length(world - _2053.fa_shadow_eye.xyz));\n        fade = _2546;\n        if (_2546 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2521.x > 1.5)\n    {\n        float3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2570 = (_2517 + 2) + (face * 6);\n    int param_4 = _2570;\n    int param_5 = _2570 + 1;\n    int param_6 = _2570 + 3;\n    float4 _2584 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n    int param_7 = _2570 + 4;\n    float4 _2589 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n    int param_8 = _2570 + 5;\n    float4 _2594 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n    float _2606 = _2594.x * fast::max(dot(_2584, float4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2611 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _2634 = fast::clamp(dot(n, _2584.xyz), -1.0, 1.0);\n    float _2653 = fast::min(sqrt(1.0 - (_2634 * _2634)) / fast::max(abs(dot(n, world - lpos)) / fast::max(dot(_2584, float4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2656 = _2526.y;\n    float _2658;\n    if (_2656 > 0.0)\n    {\n        _2658 = _2656;\n    }\n    else\n    {\n        _2658 = 1.5 * _2606;\n    }\n    float4 _2678 = float4(world + (n * (_2658 * sqrt(1.0 - (_2611 * _2611)))), 1.0);\n    float _2682 = dot(_2584, _2678);\n    float _2685 = _2594.y;\n    if (_2682 < _2685)\n    {\n        return 1.0;\n    }\n    float2 _2700 = float2(dot(fa_light_texel(param_4, fa_light_tex, fa_shadow_smp), _2678), dot(fa_light_texel(param_5, fa_light_tex, fa_shadow_smp), _2678)) / float2(_2682);\n    float _2702 = _2700.x;\n    bool _2705 = _2702 < _2589.x;\n    bool _2714;\n    if (!_2705)\n    {\n        _2714 = _2702 > _2589.z;\n    }\n    else\n    {\n        _2714 = _2705;\n    }\n    bool _2723;\n    if (!_2714)\n    {\n        _2723 = _2700.y < _2589.y;\n    }\n    else\n    {\n        _2723 = _2714;\n    }\n    bool _2732;\n    if (!_2723)\n    {\n        _2732 = _2700.y > _2589.w;\n    }\n    else\n    {\n        _2732 = _2723;\n    }\n    if (_2732)\n    {\n        return 1.0;\n    }\n    float _2738 = _2526.x;\n    float _2740;\n    if (_2738 > 0.0)\n    {\n        _2740 = _2738;\n    }\n    else\n    {\n        _2740 = 1.5 * _2606;\n    }\n    float2 param_9 = _2700;\n    float4 param_10 = _2589;\n    float param_11 = _2682 - (_2740 * (1.0 + (0.5 * _2653)));\n    float param_12 = _2606;\n    float param_13 = 1.0;\n    float param_14 = _2594.z * 0.25;\n    float param_15 = (_2606 * fast::min(_2653, 3.0)) * 0.5;\n    float3 param_16 = float3(1.0, _2685, _2594.z);\n    int param_17 = int(_2521.z + 0.5);\n    float param_18 = _2521.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, fa_shadow_smp, gl_FragCoord, _2053, fa_shadow_tex), fade);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_contact_shadow(thread const int& li, thread const float3& world, thread const float3& gn, thread const float3& l, thread const float& dist, constant fa_mesh_fs_params& _396, texture2d<float> fa_light_tex, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2053, texture2d<float> fa_screen_tex)\n{\n    bool _3246 = _396.fa_ct_a.x < 0.5;\n    bool _3253;\n    if (!_3246)\n    {\n        _3253 = _2053.fa_shadow_lcfg.x < 0.5;\n    }\n    else\n    {\n        _3253 = _3246;\n    }\n    if (_3253)\n    {\n        return 1.0;\n    }\n    int param = (int(_2053.fa_shadow_lcfg.x + 0.5) - 1) + li;\n    float4 _3266 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    float _3267 = _3266.y;\n    float len = _3267;\n    if (_3267 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3279 = length(world - _396.fa_camera_pos.xyz);\n    float _3289 = 1.0 - smoothstep(0.5 * _396.fa_ct_b.x, _396.fa_ct_b.x, _3279);\n    if (_3289 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3295 = len;\n    float _3298 = fast::min(_3295, 0.89999997615814208984375 * dist);\n    len = _3298;\n    float _3304 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _3279);\n    float _3309 = _3304 + (0.5 * _3298);\n    float3 _3315 = world + (gn * _3304);\n    float _3317 = fa_shadow_noise(gl_FragCoord);\n    float occ = 0.0;\n    float _3382;\n    for (int k = 0; k < 12; k++)\n    {\n        float _3333 = (float(k) + _3317) * 0.083333335816860198974609375;\n        float3 _3341 = _3315 + (l * (_3333 * len));\n        float4 _3347 = float4(_3341, 1.0);\n        float _3353 = dot(_396.fa_ct_vpw, _3347);\n        if (_3353 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        float2 _3373 = float2(dot(_396.fa_ct_vpx, _3347), dot(_396.fa_ct_vpy, _3347)) / float2(_3353);\n        float _3377 = _3373.x * 0.5;\n        float _3378 = _3377 + 0.5;\n        if (_396.fa_ct_a.y > 0.5)\n        {\n            _3382 = (_3373.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _3382 = 0.5 - (_3373.y * 0.5);\n        }\n        bool _3398 = _3378 < 0.0;\n        bool _3405;\n        if (!_3398)\n        {\n            _3405 = _3378 >= 1.0;\n        }\n        else\n        {\n            _3405 = _3398;\n        }\n        bool _3412;\n        if (!_3405)\n        {\n            _3412 = _3382 < 0.0;\n        }\n        else\n        {\n            _3412 = _3405;\n        }\n        bool _3419;\n        if (!_3412)\n        {\n            _3419 = _3382 >= 1.0;\n        }\n        else\n        {\n            _3419 = _3412;\n        }\n        if (_3419)\n        {\n            break;\n        }\n        float4 _3438 = fa_screen_tex.read(uint2(int2(float2(_3378, _3382) * _396.fa_ct_a.zw)), 0);\n        if (_3438.w < 0.5)\n        {\n            continue;\n        }\n        float _3457 = (dot(_396.fa_ct_fwd.xyz, _3341) + _396.fa_ct_fwd.w) - _3438.x;\n        if ((_3457 > _3304) && (_3457 < _3309))\n        {\n            occ = fast::max(occ, (1.0 - (_3333 * _3333)) * smoothstep(0.0, 0.0500000007450580596923828125, fast::min(fast::min(_3378, 0.5 - _3377), fast::min(_3382, 1.0 - _3382))));\n        }\n    }\n    return 1.0 - (occ * _3289);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, constant fa_mesh_fs_params& _396, texture2d<float> fa_light_tex, sampler fa_shadow_smp, texture2d<float> fa_light_atlas, sampler fa_env_smp, thread float3& fa_light_tint, thread bool& fa_light_is_area, thread float4& gl_FragCoord, constant fa_shadows& _2053, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos, texture2d<float> fa_screen_tex, thread float3& fa_lm)\n{\n    int param = li;\n    float _3560 = fa_baked_keep(param, _396, fa_light_tex, fa_shadow_smp, fa_lm);\n    if (_3560 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample{ float3(0.0, 1.0, 0.0), float3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1, _396, fa_light_tex, fa_shadow_smp) + 0.5) };\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _3586 = fa_light_sample_n(param_2, param_3, param_4, _396, fa_light_tex, fa_shadow_smp, fa_light_atlas, fa_env_smp, fa_light_tint, fa_light_is_area);\n    float3 _4706 = _3586.color;\n    float _4707 = _3586.attenuation;\n    float _4708 = _3586.shadow;\n    bool _3589 = _3586.type == 0;\n    if (_3589 && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _3586.direction;\n        float _3600 = fa_shadow_factor(param_5, param_6, _396, fa_shadow_smp, gl_FragCoord, _2053, fa_shadow_tex, fa_world_pos);\n        _4708 = _3600;\n        _4706 *= _3600;\n    }\n    else\n    {\n        bool _3611 = _3586.type != 0;\n        bool _3617;\n        if (_3611)\n        {\n            _3617 = _4707 > 0.0;\n        }\n        else\n        {\n            _3617 = _3611;\n        }\n        if (_3617)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7, _396);\n            int param_9 = li;\n            float3 param_10 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp).xyz;\n            float3 param_11 = world_pos;\n            float3 param_12 = gn;\n            float3 param_13 = _3586.direction;\n            float _3636 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13, _396, fa_light_tex, fa_shadow_smp, gl_FragCoord, _2053, fa_shadow_tex);\n            _4708 = _3636;\n            _4706 *= _3636;\n        }\n    }\n    bool _3646 = _396.fa_ct_a.x > 0.5;\n    bool _3652;\n    if (_3646)\n    {\n        _3652 = _4707 > 0.0;\n    }\n    else\n    {\n        _3652 = _3646;\n    }\n    if (_3652)\n    {\n        float _3659;\n        if (_3589)\n        {\n            _3659 = 1000000000.0;\n        }\n        else\n        {\n            _3659 = _3586._distance;\n        }\n        int param_14 = li;\n        float3 param_15 = world_pos;\n        float3 param_16 = gn;\n        float3 param_17 = _3586.direction;\n        float param_18 = _3659;\n        float _3677 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18, _396, fa_light_tex, fa_shadow_smp, gl_FragCoord, _2053, fa_screen_tex);\n        _4708 *= _3677;\n        _4706 *= _3677;\n    }\n    float _3690 = _4707;\n    float _3691 = _3690 * _3560;\n    _4707 = _3691;\n    float3 _3695 = _4706;\n    float3 _3696 = _3695 * _3560;\n    _4706 = _3696;\n    return LightSample{ _3586.direction, _3696, _3691, _4708, _3586._distance, _3586.type };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 light(thread const SurfaceInput& i, thread const Surface& s, thread const LightSample& l)\n{\n    return float3(0.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _2053)\n{\n    if (_2053.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _2989 = int(_2053.fa_shadow_cfg.x + 0.5);\n    float _2999 = dot(world - _2053.fa_shadow_eye.xyz, _2053.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _3004 = _2989 > 0;\n    bool _3013;\n    if (_3004)\n    {\n        int param = _2989 - 1;\n        _3013 = _2999 <= fa_shadow_split_at(param, _2053);\n    }\n    else\n    {\n        _3013 = _3004;\n    }\n    if (_3013)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3019 = _2989 > 1;\n        bool _3026;\n        if (_3019)\n        {\n            _3026 = _2999 > _2053.fa_shadow_split.x;\n        }\n        else\n        {\n            _3026 = _3019;\n        }\n        if (_3026)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3032 = _2989 > 2;\n        bool _3039;\n        if (_3032)\n        {\n            _3039 = _2999 > _2053.fa_shadow_split.y;\n        }\n        else\n        {\n            _3039 = _3032;\n        }\n        if (_3039)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3045 = _2989 > 3;\n        bool _3052;\n        if (_3045)\n        {\n            _3052 = _2999 > _2053.fa_shadow_split.z;\n        }\n        else\n        {\n            _3052 = _3045;\n        }\n        if (_3052)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _396 [[buffer(1)]], constant fa_shadows& _2053 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_env_tex [[texture(6)]], texture2d<float> fa_light_tex [[texture(7)]], texture2d<float> fa_light_atlas [[texture(8)]], texture2d<float> fa_lightmap [[texture(9)]], texture2d<float> fa_decal_tex [[texture(10)]], texture2d<float> fa_screen_tex [[texture(11)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _4522 = fast::normalize(in.fa_world_normal);\n    float3 fa_light_tint;\n    bool fa_light_is_area;\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _4522 = -_4522;\n    }\n    float3 _4113 = fast::normalize(_396.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, _396, fa_light_tex, fa_shadow_smp, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _4522, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _4113, short(gl_FrontFacing) };\n    Surface _4121 = fa_standard_surface(param_1, _396, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _4561 = _4121.albedo;\n    float _4562 = _4121.alpha;\n    float3 _4563 = _4121.normal;\n    float _4564 = _4121.metallic;\n    float _4565 = _4121.roughness;\n    float _4566 = _4121.occlusion;\n    float3 _4567 = _4121.emission;\n    float _4568 = _4121.clearcoat;\n    float _4569 = _4121.clearcoat_roughness;\n    float3 _4570 = _4121.sheen_color;\n    float _4571 = _4121.sheen_roughness;\n    float _4572 = _4121.anisotropy;\n    float _4573 = _4121.anisotropy_rotation;\n    float _4574 = _4121.specular;\n    float _4575 = _4121.ior;\n    float3 _4576 = _4121.specular_color;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _4522, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _4113, short(gl_FrontFacing) };\n    Surface param_3 = _4121;\n    surface(param_2, param_3);\n    _4561 = param_3.albedo;\n    _4562 = param_3.alpha;\n    _4563 = param_3.normal;\n    _4564 = param_3.metallic;\n    _4565 = param_3.roughness;\n    _4566 = param_3.occlusion;\n    _4567 = param_3.emission;\n    _4568 = param_3.clearcoat;\n    _4569 = param_3.clearcoat_roughness;\n    _4570 = param_3.sheen_color;\n    _4571 = param_3.sheen_roughness;\n    _4572 = param_3.anisotropy;\n    _4573 = param_3.anisotropy_rotation;\n    _4574 = param_3.specular;\n    _4575 = param_3.ior;\n    _4576 = param_3.specular_color;\n    float3 param_4 = in.fa_world_pos;\n    float3 param_5 = _4522;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7, _396, fa_light_tex, fa_shadow_smp, fa_env_smp, fa_decal_tex);\n    _4561 = param_6;\n    _4563 = param_7;\n    float3 result;\n    if (_396.fa_emissive.w > 0.5)\n    {\n        result = _4561;\n    }\n    else\n    {\n        float3 _4159 = _4563;\n        float3 _4160 = fast::normalize(_4159);\n        _4563 = _4160;\n        float3 param_8 = _4160;\n        SurfaceInput param_9 = SurfaceInput{ in.fa_world_pos, _4522, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _4113, short(gl_FrontFacing) };\n        Surface param_10 = Surface{ _4561, _4562, _4563, _4564, _4565, _4566, _4567, _4568, _4569, _4570, _4571, _4572, _4573, _4574, _4575, _4576 };\n        float3 param_11 = fa_indirect_diffuse(param_8, _396, fa_env_smp, fa_env_tex, in.fa_lm, fa_lightmap);\n        float3 lit = ambient(param_9, param_10, param_11);\n        int _4179 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _4179; ln++)\n        {\n            int param_12 = ln;\n            int _4192 = fa_cl_light(param_12, _396, fa_light_tex, fa_shadow_smp, fa_cl_ndir, fa_cl_slot);\n            int param_13 = _4192;\n            if (fa_baked_keep(param_13, _396, fa_light_tex, fa_shadow_smp, in.fa_lm) <= 0.0)\n            {\n                continue;\n            }\n            int param_14 = _4192;\n            float3 param_15 = in.fa_world_pos;\n            float3 param_16 = _4522;\n            LightSample _4208 = fa_light_shadowed(param_14, param_15, param_16, _396, fa_light_tex, fa_shadow_smp, fa_light_atlas, fa_env_smp, fa_light_tint, fa_light_is_area, gl_FragCoord, _2053, fa_shadow_tex, in.fa_world_pos, fa_screen_tex, in.fa_lm);\n            SurfaceInput param_17 = SurfaceInput{ in.fa_world_pos, _4522, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _4113, short(gl_FrontFacing) };\n            Surface param_18 = Surface{ _4561, _4562, _4563, _4564, _4565, _4566, _4567, _4568, _4569, _4570, _4571, _4572, _4573, _4574, _4575, _4576 };\n            LightSample param_19 = _4208;\n            lit += light(param_17, param_18, param_19);\n        }\n        result = lit;\n    }\n    float3 _4223 = result;\n    float3 _4224 = _4223 + _4567;\n    result = _4224;\n    float3 param_20 = _4224;\n    float3 param_21 = in.fa_world_pos;\n    result = fa_shadow_debug(param_20, param_21, _2053);\n    bool _4233 = _396.fa_fog.w > 0.0;\n    bool _4240;\n    if (!_4233)\n    {\n        _4240 = _396.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _4240 = _4233;\n    }\n    if (_4240)\n    {\n        float3 _4249 = in.fa_world_pos - _396.fa_camera_pos.xyz;\n        float _4255 = dot(_4249, _396.fa_fog_c.xyz);\n        bool _4259 = _396.fa_fog_c.w > 0.5;\n        float _4260;\n        if (_4259)\n        {\n            _4260 = _4255;\n        }\n        else\n        {\n            _4260 = length(_4249);\n        }\n        float _4272 = _4260 - _396.fa_fog_b.x;\n        if (_4272 > 0.0)\n        {\n            float _4281 = _396.fa_fog.w * _4272;\n            float tau = _4281 * _4281;\n            if (_396.fa_fog_b.y > 0.0)\n            {\n                float _4297;\n                if (_4259)\n                {\n                    _4297 = in.fa_world_pos.y - (_396.fa_fog_c.y * _4255);\n                }\n                else\n                {\n                    _4297 = _396.fa_camera_pos.y;\n                }\n                float _4318 = mix(_4297, in.fa_world_pos.y, fast::clamp(_396.fa_fog_b.x / _4260, 0.0, 1.0));\n                float _4322 = in.fa_world_pos.y - _4318;\n                float _4327 = _4318 - _396.fa_fog_b.z;\n                float _4332 = in.fa_world_pos.y - _396.fa_fog_b.z;\n                bool _4335 = _4327 <= 0.0;\n                bool _4336 = !_4335;\n                bool _4342;\n                if (_4336)\n                {\n                    _4342 = _396.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4342 = _4335;\n                }\n                float _4343;\n                if (_4342)\n                {\n                    _4343 = _396.fa_fog_b.y;\n                }\n                else\n                {\n                    _4343 = _396.fa_fog_b.y * exp(-fast::min(_396.fa_fog_b.w * _4327, 80.0));\n                }\n                bool _4370;\n                if (_4336)\n                {\n                    _4370 = _396.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4370 = _4335;\n                }\n                float _4371;\n                if (_4370)\n                {\n                    _4371 = _396.fa_fog_b.y * _4327;\n                }\n                else\n                {\n                    _4371 = (_396.fa_fog_b.y * (1.0 - exp(-fast::min(_396.fa_fog_b.w * _4327, 80.0)))) / _396.fa_fog_b.w;\n                }\n                bool _4396 = _4332 <= 0.0;\n                bool _4403;\n                if (!_4396)\n                {\n                    _4403 = _396.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4403 = _4396;\n                }\n                float _4404;\n                if (_4403)\n                {\n                    _4404 = _396.fa_fog_b.y * _4332;\n                }\n                else\n                {\n                    _4404 = (_396.fa_fog_b.y * (1.0 - exp(-fast::min(_396.fa_fog_b.w * _4332, 80.0)))) / _396.fa_fog_b.w;\n                }\n                float _4431;\n                if (abs(_4322) < 0.001000000047497451305389404296875)\n                {\n                    _4431 = _4343;\n                }\n                else\n                {\n                    _4431 = (_4404 - _4371) / _4322;\n                }\n                tau += (_4272 * fast::max(_4431, 0.0));\n            }\n            result = mix(result, _396.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _4562);\n    return out;\n}\n\n",
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
            "size": 624,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_396",
            "msl_buffer_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2053",
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
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n    float4 fa_ct_a;\n    float4 fa_ct_b;\n    float4 fa_ct_vpx;\n    float4 fa_ct_vpy;\n    float4 fa_ct_vpw;\n    float4 fa_ct_fwd;\n    float4 fa_probe_sh[9];\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _56;\n    if (bool(i.front_facing))\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = fast::normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = fast::normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (bool(i.front_facing))\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _215, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _215.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _227 = fa_tex_fix(param_2, param_3);\n    float4 _787 = base_t;\n    _787.x = _227.x;\n    _787.y = _227.y;\n    _787.z = _227.z;\n    base_t = _787;\n    float4 _243 = (_787 * _215.fa_base_color) * i.vertex_color;\n    float3 _750 = i.world_normal;\n    if (_215.fa_maps.z > 0.5)\n    {\n        float param_4 = _215.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _277 = fa_tex_fix(param_6, param_7);\n        float3 _281 = (_277 * 2.0) - float3(1.0);\n        float2 _286 = _281.xy * _215.fa_maps.x;\n        float3 _795 = _281;\n        _795.x = _286.x;\n        _795.y = _286.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _795;\n        _750 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _215.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _315 = fa_tex_fix(param_12, param_13);\n    float4 _798 = mrt;\n    _798.x = _315.x;\n    _798.y = _315.y;\n    _798.z = _315.z;\n    mrt = _798;\n    float4 _345 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _215.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _345.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _357 = fa_tex_fix(param_16, param_17);\n    float param_18 = _215.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _387 = fa_tex_fix(param_20, param_21);\n    float _755 = _215.fa_layers_a.x;\n    float _756 = _215.fa_layers_a.y;\n    float _759 = _215.fa_layers_a.z;\n    float _758 = _215.fa_layers_b.w;\n    float _761 = _215.fa_layers_c.x;\n    if (_215.fa_layers_c.z > 0.5)\n    {\n        if (mod(_215.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _755 *= _357.y;\n            _756 *= _357.z;\n            _758 *= _345.w;\n        }\n        if (_215.fa_layers_c.z > 1.5)\n        {\n            _759 *= mrt.x;\n            _761 *= mrt.w;\n        }\n    }\n    return Surface{ _243.xyz, _243.w, _750, fast::clamp(_215.fa_pbr.x * _315.z, 0.0, 1.0), fast::clamp(_215.fa_pbr.y * _315.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_215.fa_maps.y * (_357.x - 1.0)), _215.fa_emissive.xyz + (_215.fa_model_emissive.xyz * _387), _755, _756, _215.fa_layers_b.xyz, _758, _759, _215.fa_layers_a.w, _761, _215.fa_layers_c.y, _215.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _215 [[buffer(1)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], sampler fa_smp [[sampler(0)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _661 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _661 = -_661;\n    }\n    float3 _521 = fast::normalize(_215.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _661, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _521, short(gl_FrontFacing) };\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _661, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _521, short(gl_FrontFacing) };\n    Surface param_2 = fa_standard_surface(param, fa_tex, fa_smp, _215, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    surface(param_1, param_2);\n    float3 _536 = fast::normalize(param_2.normal);\n    float3 _551 = fast::normalize(float3(dot(in.fa_pre_r0, _536), dot(in.fa_pre_r1, _536), dot(in.fa_pre_r2, _536)));\n    float _563 = _551.z;\n    float2 e = _551.xy / float2((abs(_551.x) + abs(_551.y)) + abs(_563));\n    if (_563 < 0.0)\n    {\n        e = (float2(1.0) - abs(e.yx)) * float2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    out.fa_frag_color = float4(fast::min(in.fa_pre_depth, 60000.0), e, 1.0);\n    return out;\n}\n\n",
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
            "size": 624,
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
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n    float4 fa_ct_a;\n    float4 fa_ct_b;\n    float4 fa_ct_vpx;\n    float4 fa_ct_vpy;\n    float4 fa_ct_vpw;\n    float4 fa_ct_fwd;\n    float4 fa_probe_sh[9];\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _56;\n    if (bool(i.front_facing))\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = fast::normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = fast::normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (bool(i.front_facing))\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _215, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _215.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _227 = fa_tex_fix(param_2, param_3);\n    float4 _787 = base_t;\n    _787.x = _227.x;\n    _787.y = _227.y;\n    _787.z = _227.z;\n    base_t = _787;\n    float4 _243 = (_787 * _215.fa_base_color) * i.vertex_color;\n    float3 _750 = i.world_normal;\n    if (_215.fa_maps.z > 0.5)\n    {\n        float param_4 = _215.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _277 = fa_tex_fix(param_6, param_7);\n        float3 _281 = (_277 * 2.0) - float3(1.0);\n        float2 _286 = _281.xy * _215.fa_maps.x;\n        float3 _795 = _281;\n        _795.x = _286.x;\n        _795.y = _286.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _795;\n        _750 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _215.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _315 = fa_tex_fix(param_12, param_13);\n    float4 _798 = mrt;\n    _798.x = _315.x;\n    _798.y = _315.y;\n    _798.z = _315.z;\n    mrt = _798;\n    float4 _345 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _215.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _345.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _357 = fa_tex_fix(param_16, param_17);\n    float param_18 = _215.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _387 = fa_tex_fix(param_20, param_21);\n    float _755 = _215.fa_layers_a.x;\n    float _756 = _215.fa_layers_a.y;\n    float _759 = _215.fa_layers_a.z;\n    float _758 = _215.fa_layers_b.w;\n    float _761 = _215.fa_layers_c.x;\n    if (_215.fa_layers_c.z > 0.5)\n    {\n        if (mod(_215.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _755 *= _357.y;\n            _756 *= _357.z;\n            _758 *= _345.w;\n        }\n        if (_215.fa_layers_c.z > 1.5)\n        {\n            _759 *= mrt.x;\n            _761 *= mrt.w;\n        }\n    }\n    return Surface{ _243.xyz, _243.w, _750, fast::clamp(_215.fa_pbr.x * _315.z, 0.0, 1.0), fast::clamp(_215.fa_pbr.y * _315.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_215.fa_maps.y * (_357.x - 1.0)), _215.fa_emissive.xyz + (_215.fa_model_emissive.xyz * _387), _755, _756, _215.fa_layers_b.xyz, _758, _759, _215.fa_layers_a.w, _761, _215.fa_layers_c.y, _215.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _215 [[buffer(1)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], sampler fa_smp [[sampler(0)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _661 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _661 = -_661;\n    }\n    float3 _521 = fast::normalize(_215.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _661, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _521, short(gl_FrontFacing) };\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _661, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _521, short(gl_FrontFacing) };\n    Surface param_2 = fa_standard_surface(param, fa_tex, fa_smp, _215, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    surface(param_1, param_2);\n    float3 _536 = fast::normalize(param_2.normal);\n    float3 _551 = fast::normalize(float3(dot(in.fa_pre_r0, _536), dot(in.fa_pre_r1, _536), dot(in.fa_pre_r2, _536)));\n    float _563 = _551.z;\n    float2 e = _551.xy / float2((abs(_551.x) + abs(_551.y)) + abs(_563));\n    if (_563 < 0.0)\n    {\n        e = (float2(1.0) - abs(e.yx)) * float2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    out.fa_frag_color = float4(fast::min(in.fa_pre_depth, 60000.0), e, 1.0);\n    return out;\n}\n\n",
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
            "size": 624,
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
