{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "70ec7addbf81ecb38af52c4a5f6d5b8f2213a6d2ef6305cbd78b3ce14189ad63",
  "slang": "metal_macos",
  "params": [
    "dark"
  ],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float3 fa_lm [[user(locn5)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _131);\n    float3 _270 = _160.world_pos;\n    fa_world_pos = _270;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = _131.fa_view_proj * float4(_270, 1.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _131 [[buffer(0)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5, _131, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.gl_Position);\n    out.fa_lm = float3(0.0);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n#pragma clang diagnostic ignored \"-Wmissing-braces\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\ntemplate<typename T, size_t Num>\nstruct spvUnsafeArray\n{\n    T elements[Num ? Num : 1];\n    \n    thread T& operator [] (size_t pos) thread\n    {\n        return elements[pos];\n    }\n    constexpr const thread T& operator [] (size_t pos) const thread\n    {\n        return elements[pos];\n    }\n    \n    device T& operator [] (size_t pos) device\n    {\n        return elements[pos];\n    }\n    constexpr const device T& operator [] (size_t pos) const device\n    {\n        return elements[pos];\n    }\n    \n    constexpr const constant T& operator [] (size_t pos) const constant\n    {\n        return elements[pos];\n    }\n    \n    threadgroup T& operator [] (size_t pos) threadgroup\n    {\n        return elements[pos];\n    }\n    constexpr const threadgroup T& operator [] (size_t pos) const threadgroup\n    {\n        return elements[pos];\n    }\n};\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n    float4 fa_ct_a;\n    float4 fa_ct_b;\n    float4 fa_ct_vpx;\n    float4 fa_ct_vpy;\n    float4 fa_ct_vpw;\n    float4 fa_ct_fwd;\n    float4 fa_tr_a;\n    float4 fa_tr_b;\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n    float4 fa_shadow_lcfg;\n};\n\nstruct fa_material\n{\n    float dark;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float3 fa_lm [[user(locn5)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_cluster_texel(thread const float3& world_pos, constant fa_mesh_fs_params& _386, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    bool _1314 = _386.fa_cl_info.x < 0.0;\n    bool _1321;\n    if (!_1314)\n    {\n        _1321 = _386.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _1321 = _1314;\n    }\n    bool _1329;\n    if (!_1321)\n    {\n        _1329 = _386.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _1329 = _1321;\n    }\n    bool _1336;\n    if (!_1329)\n    {\n        _1336 = _386.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _1336 = _1329;\n    }\n    bool _1343;\n    if (!_1336)\n    {\n        _1343 = _386.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _1343 = _1336;\n    }\n    if (_1343)\n    {\n        return float4(0.0);\n    }\n    float4 _1353 = float4(world_pos, 1.0);\n    float _1359 = dot(_386.fa_cl_vpw, _1353);\n    if (!(_1359 > 9.9999999747524270787835121154785e-07))\n    {\n        return float4(0.0);\n    }\n    float2 _1381 = float2(dot(_386.fa_cl_vpx, _1353), dot(_386.fa_cl_vpy, _1353)) / float2(_1359);\n    int _1385 = int(_386.fa_cl_grid.x);\n    int _1389 = int(_386.fa_cl_grid.y);\n    int param = (int(_386.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_386.fa_cl_fwd.xyz, world_pos) + _386.fa_cl_fwd.w, _386.fa_cl_grid.w) / _386.fa_cl_grid.w) * _386.fa_cl_grid.z)), 0, int(_386.fa_cl_info.y) - 1) * _1389) + clamp(int(floor(((_1381.y * 0.5) + 0.5) * _386.fa_cl_grid.y)), 0, _1389 - 1)) * _1385)) + clamp(int(floor(((_1381.x * 0.5) + 0.5) * _386.fa_cl_grid.x)), 0, _1385 - 1);\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, constant fa_mesh_fs_params& _386, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    float3 param = world_pos;\n    float4 _1465 = fa_cluster_texel(param, _386, fa_light_tex, fa_shadow_smp);\n    return int2(int(_1465.x), int(_1465.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, constant fa_mesh_fs_params& _386, texture2d<float> fa_light_tex, sampler fa_shadow_smp, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_386.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _3496 = fa_cluster_lookup(param, _386, fa_light_tex, fa_shadow_smp);\n    fa_cl_slot = _3496.x;\n    fa_cl_local = _3496.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _3722 = fa_linear_to_srgb(param);\n        c = _3722;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _3730 = fa_srgb_to_linear(param_1);\n            c = _3730;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _269;\n    if (bool(i.front_facing))\n    {\n        _269 = i.world_normal;\n    }\n    else\n    {\n        _269 = -i.world_normal;\n    }\n    float3 _293 = fast::normalize(i.world_tangent.xyz - (_269 * dot(_269, i.world_tangent.xyz)));\n    float3 _320 = fast::normalize(((_293 * m.x) + ((cross(_269, _293) * i.world_tangent.w) * m.y)) + (_269 * m.z));\n    float3 _323;\n    if (bool(i.front_facing))\n    {\n        _323 = _320;\n    }\n    else\n    {\n        _323 = -_320;\n    }\n    return _323;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _386, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _386.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _3761 = fa_tex_fix(param_2, param_3);\n    float4 _4854 = base_t;\n    _4854.x = _3761.x;\n    _4854.y = _3761.y;\n    _4854.z = _3761.z;\n    base_t = _4854;\n    float4 _3775 = (_4854 * _386.fa_base_color) * i.vertex_color;\n    float3 _4698 = i.world_normal;\n    if (_386.fa_maps.z > 0.5)\n    {\n        float param_4 = _386.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _3807 = fa_tex_fix(param_6, param_7);\n        float3 _3810 = (_3807 * 2.0) - float3(1.0);\n        float2 _3815 = _3810.xy * _386.fa_maps.x;\n        float3 _4862 = _3810;\n        _4862.x = _3815.x;\n        _4862.y = _3815.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _4862;\n        _4698 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _386.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _3843 = fa_tex_fix(param_12, param_13);\n    float4 _4865 = mrt;\n    _4865.x = _3843.x;\n    _4865.y = _3843.y;\n    _4865.z = _3843.z;\n    mrt = _4865;\n    float4 _3871 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _386.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _3871.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _3882 = fa_tex_fix(param_16, param_17);\n    float param_18 = _386.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _3912 = fa_tex_fix(param_20, param_21);\n    float _4703 = _386.fa_layers_a.x;\n    float _4704 = _386.fa_layers_a.y;\n    float _4707 = _386.fa_layers_a.z;\n    float _4706 = _386.fa_layers_b.w;\n    float _4709 = _386.fa_layers_c.x;\n    if (_386.fa_layers_c.z > 0.5)\n    {\n        if (mod(_386.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _4703 *= _3882.y;\n            _4704 *= _3882.z;\n            _4706 *= _3871.w;\n        }\n        if (_386.fa_layers_c.z > 1.5)\n        {\n            _4707 *= mrt.x;\n            _4709 *= mrt.w;\n        }\n    }\n    return Surface{ _3775.xyz, _3775.w, _4698, fast::clamp(_386.fa_pbr.x * _3843.z, 0.0, 1.0), fast::clamp(_386.fa_pbr.y * _3843.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_386.fa_maps.y * (_3882.x - 1.0)), _386.fa_emissive.xyz + (_386.fa_model_emissive.xyz * _3912), _4703, _4704, _386.fa_layers_b.xyz, _4706, _4707, _386.fa_layers_a.w, _4709, _386.fa_layers_c.y, _386.fa_layers_d.xyz, _386.fa_tr_a.x, _386.fa_tr_a.y, _386.fa_tr_b.xyz, _386.fa_tr_a.z };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_decal_tile(thread const float4& rect, thread const float2& uv, thread const float2& atlas, thread const float2& ddx, thread const float2& ddy, sampler fa_env_smp, texture2d<float> fa_decal_tex)\n{\n    float2 _1545 = rect.zw - rect.xy;\n    float2 _1549 = _1545 * atlas;\n    float2 _1553 = ddx * _1549;\n    float2 _1557 = ddy * _1549;\n    return fa_decal_tex.sample(fa_env_smp, (rect.xy + (fast::clamp(uv, float2(0.0), float2(1.0)) * _1545)), level(fast::clamp(0.5 * log2(fast::max(fast::max(dot(_1553, _1553), dot(_1557, _1557)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_apply_decals(thread const float3& world_pos, thread const float3& geo_normal, thread float3& albedo, thread float3& normal, constant fa_mesh_fs_params& _386, texture2d<float> fa_light_tex, sampler fa_shadow_smp, sampler fa_env_smp, texture2d<float> fa_decal_tex)\n{\n    bool _1590 = _386.fa_counts.y < 0.5;\n    bool _1597;\n    if (!_1590)\n    {\n        _1597 = _386.fa_counts.w < 0.5;\n    }\n    else\n    {\n        _1597 = _1590;\n    }\n    if (_1597)\n    {\n        return;\n    }\n    float3 _1603 = dfdx(world_pos);\n    float3 _1606 = dfdy(world_pos);\n    float3 param = world_pos;\n    float4 _1610 = fa_cluster_texel(param, _386, fa_light_tex, fa_shadow_smp);\n    int _1614 = int(_1610.w);\n    if (_1614 < 1)\n    {\n        return;\n    }\n    int _1624 = int(_386.fa_counts.y + 0.5);\n    int param_1 = _1624;\n    float4 _1628 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float2 _1631 = _1628.yz;\n    int _1635 = int(_1628.w);\n    int param_2 = _1624 + 1;\n    float4 _1640 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float _1641 = _1640.x;\n    int _1647 = int(_386.fa_counts.w + 0.5) - 1;\n    int _1651 = int(_1610.z);\n    float3 _1916;\n    for (int k = 0; k < _1614; k++)\n    {\n        int _1664 = _1651 + k;\n        int param_3 = _1635 + (_1664 >> 2);\n        int _1681 = (_1624 + 2) + (int(fa_light_texel(param_3, fa_light_tex, fa_shadow_smp)[_1664 & 3]) * 7);\n        int param_4 = _1681 + 6;\n        float4 _1686 = fa_light_texel(param_4, fa_light_tex, fa_shadow_smp);\n        if (((int(_1686.w + 0.5) >> _1647) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1681;\n        float4 _1701 = fa_light_texel(param_5, fa_light_tex, fa_shadow_smp);\n        int param_6 = _1681 + 1;\n        float4 _1706 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n        int param_7 = _1681 + 2;\n        float4 _1711 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n        float3 _1714 = _1701.xyz;\n        float _1719 = dot(_1714, world_pos) + _1701.w;\n        float3 _1721 = _1706.xyz;\n        float _1726 = dot(_1721, world_pos) + _1706.w;\n        float3 _1728 = _1711.xyz;\n        float _1733 = dot(_1728, world_pos) + _1711.w;\n        bool _1738 = abs(_1719) > 0.5;\n        bool _1746;\n        if (!_1738)\n        {\n            _1746 = abs(_1726) > 0.5;\n        }\n        else\n        {\n            _1746 = _1738;\n        }\n        bool _1754;\n        if (!_1746)\n        {\n            _1754 = abs(_1733) > 0.5;\n        }\n        else\n        {\n            _1754 = _1746;\n        }\n        if (_1754)\n        {\n            continue;\n        }\n        float _1769 = fast::clamp(dot(geo_normal, fast::normalize(_1728)) * _1686.z, 0.0, 1.0);\n        if (_1769 <= 0.0)\n        {\n            continue;\n        }\n        float _1789 = (fast::clamp((0.5 - abs(_1733)) * 10.0, 0.0, 1.0) * _1769) * _1686.x;\n        float2 _1797 = float2(_1719 + 0.5, 0.5 - _1726);\n        float2 _1807 = float2(dot(_1714, _1603), dot(_1721, _1603));\n        float2 _1817 = float2(dot(_1714, _1606), dot(_1721, _1606));\n        int param_8 = _1681 + 5;\n        float4 _1822 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n        int param_9 = _1681 + 3;\n        float4 _1827 = fa_light_texel(param_9, fa_light_tex, fa_shadow_smp);\n        int param_10 = _1681 + 4;\n        float4 _1832 = fa_light_texel(param_10, fa_light_tex, fa_shadow_smp);\n        float tex_a = 1.0;\n        float3 col = _1822.xyz;\n        bool _1842 = _1827.z > _1827.x;\n        if (_1842)\n        {\n            float4 param_11 = _1827;\n            float2 param_12 = _1797;\n            float2 param_13 = _1631;\n            float2 param_14 = _1807;\n            float2 param_15 = _1817;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15, fa_env_smp, fa_decal_tex);\n            if ((_1641 > 0.5) && (_1641 < 1.5))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1868 = fa_dc_to_linear(param_16);\n                float4 _4786 = tx;\n                _4786.x = _1868.x;\n                _4786.y = _1868.y;\n                _4786.z = _1868.z;\n                tx = _4786;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, float3(fast::clamp((_1789 * tex_a) * _1822.w, 0.0, 1.0)));\n        if (_1832.z > _1832.x)\n        {\n            float4 param_17 = _1832;\n            float2 param_18 = _1797;\n            float2 param_19 = _1631;\n            float2 param_20 = _1807;\n            float2 param_21 = _1817;\n            float4 _1912 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21, fa_env_smp, fa_decal_tex);\n            if (_1641 > 1.5)\n            {\n                float3 param_22 = _1912.xyz;\n                float3 _1922 = fa_dc_to_srgb(param_22);\n                _1916 = _1922;\n            }\n            else\n            {\n                _1916 = _1912.xyz;\n            }\n            float3 _1931 = (_1916 * 2.0) - float3(1.0);\n            float2 _1936 = _1931.xy * _1686.y;\n            float3 _1958 = (fast::normalize(_1714) * _1936.x) + (fast::normalize(_1721) * _1936.y);\n            float3 _1961 = fast::normalize(normal);\n            normal = fast::normalize(mix(_1961, fast::normalize((_1961 * fast::max(_1931.z, 0.0500000007450580596923828125)) + (_1958 - (_1961 * dot(_1961, _1958)))), float3(fast::clamp(_1789 * (_1842 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_sh_coef(thread const int& k, constant fa_mesh_fs_params& _386, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float3 v = fa_env_tex.sample(fa_env_smp, float3(1.0, 1.0 - (float((2 * (k >> 2)) + 1) * 0.25), 1.0 - (float((2 * (k & 3)) + 1) * 0.25)), level(5.0)).xyz;\n    if (_386.fa_env_sky.w > 1.5)\n    {\n        v = (v - float3(0.5)) * 8.0;\n    }\n    return v;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sh_eval(thread const spvUnsafeArray<float3, 9>& c, thread const float3& n)\n{\n    float3 _3156 = fast::max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), float3(0.0));\n    return _3156;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _386, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    if (_386.fa_env_sky.w > 0.5)\n    {\n        spvUnsafeArray<float3, 9> c;\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param, _386, fa_env_smp, fa_env_tex);\n        }\n        spvUnsafeArray<float3, 9> param_1 = c;\n        float3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return _386.fa_ambient.xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_indirect_diffuse(thread const float3& n, constant fa_mesh_fs_params& _386, sampler fa_env_smp, texturecube<float> fa_env_tex, thread float3& fa_lm, texture2d<float> fa_lightmap)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return fa_lightmap.sample(fa_env_smp, fa_lm.xy, level(0.0)).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param, _386, fa_env_smp, fa_env_tex);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, constant fa_mesh_fs_params& _386, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (int(_386.fa_cl_info.x) + int(_386.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, constant fa_mesh_fs_params& _386, texture2d<float> fa_light_tex, sampler fa_shadow_smp, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, _386, fa_light_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_light_base(thread const int& li, constant fa_mesh_fs_params& _386)\n{\n    return li * ((_386.fa_ambient.w > 4.5) ? 8 : 4);\n}\n\nstatic inline __attribute__((always_inline))\nbool fa_light_baked(thread const int& li, constant fa_mesh_fs_params& _386, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li;\n    int param_1 = fa_light_base(param, _386) + 3;\n    return fa_light_texel(param_1, fa_light_tex, fa_shadow_smp).w > 0.5;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_light_type(thread const int& li, constant fa_mesh_fs_params& _386, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li;\n    int param_1 = fa_light_base(param, _386) + 1;\n    return fa_light_texel(param_1, fa_light_tex, fa_shadow_smp).w;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_area_point(thread const float3& c, thread const float3& axis, thread const float3& ru, thread const float3& uu, thread const float& hx, thread const float& hy, thread const float& shape, thread const float3& p, thread const float3& r)\n{\n    bool _564 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        float3 _577 = (c - (ru * hx)) - p;\n        float3 _583 = ru * (2.0 * hx);\n        float _589 = fast::max(dot(_583, _583), 9.9999999392252902907785028219223e-09);\n        float _593 = dot(_577, _583);\n        float t = fast::clamp((-_593) / _589, 0.0, 1.0);\n        if (_564)\n        {\n            float _608 = dot(r, _583);\n            float _614 = _589 - (_608 * _608);\n            if (abs(_614) > (9.9999997473787516355514526367188e-06 * _589))\n            {\n                t = fast::clamp(((dot(r, _577) * _608) - _593) / _614, 0.0, 1.0);\n            }\n        }\n        return (p + _577) + (_583 * t);\n    }\n    float3 q = p;\n    float _646 = dot(r, axis);\n    bool _654;\n    if (_564)\n    {\n        _654 = abs(_646) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _654 = _564;\n    }\n    if (_654)\n    {\n        float _664 = dot(c - p, axis) / _646;\n        if (_664 > 0.0)\n        {\n            q = p + (r * _664);\n        }\n    }\n    float3 _677 = q - c;\n    float2 xy = float2(dot(_677, ru), dot(_677, uu));\n    if (shape > 0.5)\n    {\n        float _692 = length(xy);\n        if (_692 > hx)\n        {\n            xy *= (hx / _692);\n        }\n    }\n    else\n    {\n        xy = fast::clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_atlas_fetch(thread const float2& texel, texture2d<float> fa_light_atlas, sampler fa_env_smp)\n{\n    return fa_light_atlas.sample(fa_env_smp, (texel / float2(int2(fa_light_atlas.get_width(), fa_light_atlas.get_height()))), level(0.0));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_cookie_sample(thread const float2& tile_origin, thread const float2& uv, texture2d<float> fa_light_atlas, sampler fa_env_smp)\n{\n    float2 param = (tile_origin + float2(1.0)) + (fast::clamp(uv, float2(0.0), float2(1.0)) * 254.0);\n    return fa_atlas_fetch(param, fa_light_atlas, fa_env_smp).xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_ies_sample(thread const float2& tile_origin, thread const float3& d, thread const float3& axis, thread const float3& right, thread const float3& up, texture2d<float> fa_light_atlas, sampler fa_env_smp)\n{\n    float _484 = dot(d, right);\n    float _488 = dot(d, up);\n    float _499;\n    if (((_484 * _484) + (_488 * _488)) > 1.0000000133514319600180897396058e-10)\n    {\n        _499 = precise::atan2(_488, _484) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _499 = 0.0;\n    }\n    float2 param = tile_origin + float2(1.0 + ((_499 - floor(_499)) * 64.0), 1.0 + (acos(fast::clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param, fa_light_atlas, fa_env_smp).x;\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cube_face(thread const float3& d)\n{\n    float3 _335 = abs(d);\n    float _337 = _335.x;\n    float _339 = _335.y;\n    bool _340 = _337 >= _339;\n    bool _348;\n    if (_340)\n    {\n        _348 = _337 >= _335.z;\n    }\n    else\n    {\n        _348 = _340;\n    }\n    int _349;\n    if (_348)\n    {\n        _349 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _364;\n        if (_339 >= _335.z)\n        {\n            _364 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _364 = (d.z > 0.0) ? 4 : 5;\n        }\n        _349 = _364;\n    }\n    return _349;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cube_face_basis(thread const int& f, thread float3& fwd, thread float3& up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0, 0.0, 0.0);\n        up = float3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0, 0.0, 0.0);\n            up = float3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0, 1.0, 0.0);\n                up = float3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0, -1.0, 0.0);\n                    up = float3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0, 0.0, 1.0);\n                        up = float3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0, 0.0, -1.0);\n                        up = float3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample_n(thread const int& li, thread const float3& world_pos, thread const float3& n, constant fa_mesh_fs_params& _386, texture2d<float> fa_light_tex, sampler fa_shadow_smp, texture2d<float> fa_light_atlas, sampler fa_env_smp, thread float3& fa_light_tint, thread bool& fa_light_is_area)\n{\n    int param = li;\n    int _730 = fa_light_base(param, _386);\n    bool _734 = _386.fa_ambient.w > 4.5;\n    int param_1 = _730;\n    float4 _738 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    int param_2 = _730 + 1;\n    float4 _743 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float _746 = _743.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = float3(1.0);\n    bool _758 = _734 && (_746 > 2.5);\n    fa_light_is_area = _758;\n    bool _760 = _746 < 0.5;\n    float3 l;\n    if (_760)\n    {\n        l = fast::normalize(_738.xyz);\n        if (_734)\n        {\n            int param_3 = _730 + 6;\n            float4 _774 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            if (_774.z > 0.5)\n            {\n                int param_4 = _730 + 4;\n                float4 _784 = fa_light_texel(param_4, fa_light_tex, fa_shadow_smp);\n                int param_5 = _730 + 5;\n                float4 _789 = fa_light_texel(param_5, fa_light_tex, fa_shadow_smp);\n                float2 param_6 = _774.xy;\n                float2 param_7 = fract(float2(dot(world_pos, _784.xyz) * _784.w, (-dot(world_pos, _789.xyz)) * _789.w) + float2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7, fa_light_atlas, fa_env_smp);\n            }\n        }\n    }\n    else\n    {\n        float3 _819 = _738.xyz;\n        float3 _821 = _819 - world_pos;\n        float3 to_light = _821;\n        float _824 = length(_821);\n        float reach = _824;\n        bool front = true;\n        if (_758)\n        {\n            int param_8 = _730 + 7;\n            reach = fast::max(_824 - fa_light_texel(param_8, fa_light_tex, fa_shadow_smp).w, 0.0);\n            int param_9 = _730 + 4;\n            float4 _848 = fa_light_texel(param_9, fa_light_tex, fa_shadow_smp);\n            int param_10 = _730 + 5;\n            float4 _853 = fa_light_texel(param_10, fa_light_tex, fa_shadow_smp);\n            int param_11 = _730 + 6;\n            float4 _858 = fa_light_texel(param_11, fa_light_tex, fa_shadow_smp);\n            float _859 = _858.w;\n            int param_12 = _730 + 2;\n            float3 _866 = fast::normalize(fa_light_texel(param_12, fa_light_tex, fa_shadow_smp).xyz);\n            bool _868 = _859 > 1.5;\n            bool _876;\n            if (!_868)\n            {\n                _876 = dot(_866, to_light) < 0.0;\n            }\n            else\n            {\n                _876 = _868;\n            }\n            front = _876;\n            float3 r = float3(0.0);\n            float3 _885 = _386.fa_camera_pos.xyz - world_pos;\n            bool _889 = dot(n, n) > 0.5;\n            bool _897;\n            if (_889)\n            {\n                _897 = dot(_885, _885) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _897 = _889;\n            }\n            if (_897)\n            {\n                r = reflect(-fast::normalize(_885), fast::normalize(n));\n            }\n            float3 param_13 = _819;\n            float3 param_14 = _866;\n            float3 param_15 = _848.xyz;\n            float3 param_16 = _853.xyz;\n            float param_17 = _848.w;\n            float param_18 = _853.w;\n            float param_19 = _859;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _933 = length(to_light);\n        dist = _933;\n        l = to_light / float3(fast::max(_933, 9.9999997473787516355514526367188e-05));\n        float _947 = reach / fast::max(_738.w, 0.001000000047497451305389404296875);\n        float _953 = fast::clamp(1.0 - (_947 * _947), 0.0, 1.0);\n        float _955;\n        if (front)\n        {\n            _955 = _953 * _953;\n        }\n        else\n        {\n            _955 = 0.0;\n        }\n        atten = _955;\n        bool _966 = _746 < 2.5;\n        if ((_746 > 1.5) && _966)\n        {\n            int param_22 = _730 + 2;\n            float4 _974 = fa_light_texel(param_22, fa_light_tex, fa_shadow_smp);\n            float _984 = _974.w;\n            int param_23 = _730 + 3;\n            float4 _989 = fa_light_texel(param_23, fa_light_tex, fa_shadow_smp);\n            float _990 = _989.x;\n            float cos_inner = _990;\n            if (_990 > 1.5)\n            {\n                cos_inner = mix(_984, 1.0, 0.25);\n            }\n            atten *= smoothstep(_984, cos_inner, dot(-l, fast::normalize(_974.xyz)));\n        }\n        if (_734 && (_746 < 1.5))\n        {\n            int param_24 = _730 + 6;\n            float4 _1014 = fa_light_texel(param_24, fa_light_tex, fa_shadow_smp);\n            if (_1014.z > 0.5)\n            {\n                float3 _1022 = -to_light;\n                int param_25 = _730 + 4;\n                int param_26 = _730 + 5;\n                float3 _1036 = fa_light_texel(param_25, fa_light_tex, fa_shadow_smp).xyz;\n                float3 _1040 = fa_light_texel(param_26, fa_light_tex, fa_shadow_smp).xyz;\n                float3 _1049 = float3(dot(_1022, _1036), dot(_1022, _1040), dot(_1022, cross(_1036, _1040)));\n                float3 param_27 = _1049;\n                int _1053 = fa_cube_face(param_27);\n                int param_28 = _1053;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1080 = float2(dot(_1049, cross(param_29, param_30)), dot(_1049, param_30)) / float2(fast::max(dot(_1049, param_29), 9.9999997473787516355514526367188e-05));\n                int _1084 = _1053 / 3;\n                float2 param_31 = _1014.xy + (float2(float(_1053 - (_1084 * 3)), float(_1084)) * 256.0);\n                float2 param_32 = float2(0.5 + (0.5 * _1080.x), 0.5 - (0.5 * _1080.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32, fa_light_atlas, fa_env_smp);\n            }\n            int param_33 = _730 + 7;\n            float4 _1114 = fa_light_texel(param_33, fa_light_tex, fa_shadow_smp);\n            if (_1114.z > 0.5)\n            {\n                int param_34 = _730 + 2;\n                int param_35 = _730 + 4;\n                int param_36 = _730 + 5;\n                float2 param_37 = _1114.xy;\n                float3 param_38 = -l;\n                float3 param_39 = fast::normalize(fa_light_texel(param_34, fa_light_tex, fa_shadow_smp).xyz);\n                float3 param_40 = fa_light_texel(param_35, fa_light_tex, fa_shadow_smp).xyz;\n                float3 param_41 = fa_light_texel(param_36, fa_light_tex, fa_shadow_smp).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41, fa_light_atlas, fa_env_smp);\n            }\n        }\n        else\n        {\n            if (_734 && _966)\n            {\n                int param_42 = _730 + 6;\n                float4 _1161 = fa_light_texel(param_42, fa_light_tex, fa_shadow_smp);\n                int param_43 = _730 + 7;\n                float4 _1166 = fa_light_texel(param_43, fa_light_tex, fa_shadow_smp);\n                bool _1169 = _1161.z > 0.5;\n                bool _1176;\n                if (!_1169)\n                {\n                    _1176 = _1166.z > 0.5;\n                }\n                else\n                {\n                    _1176 = _1169;\n                }\n                if (_1176)\n                {\n                    int param_44 = _730 + 2;\n                    float4 _1183 = fa_light_texel(param_44, fa_light_tex, fa_shadow_smp);\n                    float3 _1187 = fast::normalize(_1183.xyz);\n                    int param_45 = _730 + 4;\n                    float4 _1192 = fa_light_texel(param_45, fa_light_tex, fa_shadow_smp);\n                    int param_46 = _730 + 5;\n                    float4 _1197 = fa_light_texel(param_46, fa_light_tex, fa_shadow_smp);\n                    if (_1169)\n                    {\n                        float3 _1205 = -to_light;\n                        float _1212 = _1183.w;\n                        float _1228 = 0.5 / fast::max(dot(_1205, _1187) * (sqrt(fast::max(1.0 - (_1212 * _1212), 0.0)) / fast::max(_1212, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        float2 param_47 = _1161.xy;\n                        float2 param_48 = float2(0.5 + (dot(_1205, _1192.xyz) * _1228), 0.5 - (dot(_1205, _1197.xyz) * _1228));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48, fa_light_atlas, fa_env_smp);\n                    }\n                    if (_1166.z > 0.5)\n                    {\n                        float2 param_49 = _1166.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1187;\n                        float3 param_52 = _1192.xyz;\n                        float3 param_53 = _1197.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53, fa_light_atlas, fa_env_smp);\n                    }\n                }\n            }\n        }\n    }\n    float3 _4652 = _743.xyz * atten;\n    if (_734)\n    {\n        _4652 *= fa_light_tint;\n    }\n    int _1296;\n    if (_760)\n    {\n        _1296 = 0;\n    }\n    else\n    {\n        _1296 = ((_746 > 1.5) && (_746 < 2.5)) ? 2 : 1;\n    }\n    return LightSample{ l, _4652, atten, 1.0, dist, _1296 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_fetch(thread const float2& uv, thread const float4& rect, thread const float3& conv, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2090 = fa_shadow_depth(param, param_1, fa_shadow_smp, fa_shadow_tex);\n    float _2094;\n    if (conv.x < 0.5)\n    {\n        _2094 = _2090;\n    }\n    else\n    {\n        _2094 = (conv.y * conv.z) / (conv.z - (_2090 * (conv.z - conv.y)));\n    }\n    return _2094;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _2021 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_2021), sin(_2021)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_filter(thread const float2& uv, thread const float4& rect, thread const float& zr, thread const float& texel_m, thread const float& unit, thread const float& reach, thread const float& plane, thread const float3& conv, thread const int& mode, thread const float& k, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2043, texture2d<float> fa_shadow_tex)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2, fa_shadow_smp, fa_shadow_tex));\n    }\n    float _2140 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2149;\n        if (k < 0.0)\n        {\n            _2149 = (-k) / fast::max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2149 = k;\n        }\n        float _2169 = fast::clamp((_2149 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2140;\n            float2 _2188 = fa_shadow_vogel(param_3, param_4, param_5) * _2169;\n            float2 param_6 = uv + (_2188 * _2043.fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _2200 = fa_shadow_fetch(param_6, param_7, param_8, fa_shadow_smp, fa_shadow_tex);\n            if (_2200 < (zr - (length(_2188) * plane)))\n            {\n                sum += _2200;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2226 = sum / cnt;\n        float _2236;\n        if (k < 0.0)\n        {\n            _2236 = (-k) / fast::max(_2226, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2236 = k;\n        }\n        radius = fast::clamp(((fast::max(zr - _2226, 0.0) * unit) * _2236) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _2258 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2258; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2258;\n        float param_11 = _2140;\n        float2 _2277 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_2277 * _2043.fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_2277) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14, fa_shadow_smp, fa_shadow_tex));\n    }\n    return lit / float(_2258);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_local(thread const int& li, thread const float3& lpos, thread const float3& world, thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _386, texture2d<float> fa_light_tex, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2043, texture2d<float> fa_shadow_tex)\n{\n    bool _2477 = _386.fa_pbr.z < 0.5;\n    bool _2484;\n    if (!_2477)\n    {\n        _2484 = _2043.fa_shadow_lcfg.x < 0.5;\n    }\n    else\n    {\n        _2484 = _2477;\n    }\n    if (_2484)\n    {\n        return 1.0;\n    }\n    int param = (int(_2043.fa_shadow_lcfg.x + 0.5) - 1) + li;\n    float4 _2497 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    float _2498 = _2497.x;\n    if (_2498 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2507 = int(_2498 + 0.5);\n    int param_1 = _2507;\n    float4 _2511 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    int param_2 = _2507 + 1;\n    float4 _2516 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float fade = 1.0;\n    float _2519 = _2511.y;\n    if (_2519 > 0.0)\n    {\n        float _2536 = 1.0 - smoothstep(0.75 * _2519, _2519, length(world - _2043.fa_shadow_eye.xyz));\n        fade = _2536;\n        if (_2536 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2511.x > 1.5)\n    {\n        float3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2560 = (_2507 + 2) + (face * 6);\n    int param_4 = _2560;\n    int param_5 = _2560 + 1;\n    int param_6 = _2560 + 3;\n    float4 _2574 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n    int param_7 = _2560 + 4;\n    float4 _2579 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n    int param_8 = _2560 + 5;\n    float4 _2584 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n    float _2596 = _2584.x * fast::max(dot(_2574, float4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2601 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _2624 = fast::clamp(dot(n, _2574.xyz), -1.0, 1.0);\n    float _2643 = fast::min(sqrt(1.0 - (_2624 * _2624)) / fast::max(abs(dot(n, world - lpos)) / fast::max(dot(_2574, float4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2646 = _2516.y;\n    float _2648;\n    if (_2646 > 0.0)\n    {\n        _2648 = _2646;\n    }\n    else\n    {\n        _2648 = 1.5 * _2596;\n    }\n    float4 _2668 = float4(world + (n * (_2648 * sqrt(1.0 - (_2601 * _2601)))), 1.0);\n    float _2672 = dot(_2574, _2668);\n    float _2675 = _2584.y;\n    if (_2672 < _2675)\n    {\n        return 1.0;\n    }\n    float2 _2690 = float2(dot(fa_light_texel(param_4, fa_light_tex, fa_shadow_smp), _2668), dot(fa_light_texel(param_5, fa_light_tex, fa_shadow_smp), _2668)) / float2(_2672);\n    float _2692 = _2690.x;\n    bool _2695 = _2692 < _2579.x;\n    bool _2704;\n    if (!_2695)\n    {\n        _2704 = _2692 > _2579.z;\n    }\n    else\n    {\n        _2704 = _2695;\n    }\n    bool _2713;\n    if (!_2704)\n    {\n        _2713 = _2690.y < _2579.y;\n    }\n    else\n    {\n        _2713 = _2704;\n    }\n    bool _2722;\n    if (!_2713)\n    {\n        _2722 = _2690.y > _2579.w;\n    }\n    else\n    {\n        _2722 = _2713;\n    }\n    if (_2722)\n    {\n        return 1.0;\n    }\n    float _2728 = _2516.x;\n    float _2730;\n    if (_2728 > 0.0)\n    {\n        _2730 = _2728;\n    }\n    else\n    {\n        _2730 = 1.5 * _2596;\n    }\n    float2 param_9 = _2690;\n    float4 param_10 = _2579;\n    float param_11 = _2672 - (_2730 * (1.0 + (0.5 * _2643)));\n    float param_12 = _2596;\n    float param_13 = 1.0;\n    float param_14 = _2584.z * 0.25;\n    float param_15 = (_2596 * fast::min(_2643, 3.0)) * 0.5;\n    float3 param_16 = float3(1.0, _2675, _2584.z);\n    int param_17 = int(_2511.z + 0.5);\n    float param_18 = _2511.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, fa_shadow_smp, gl_FragCoord, _2043, fa_shadow_tex), fade);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _2043)\n{\n    float _2033;\n    if (i == 0)\n    {\n        _2033 = _2043.fa_shadow_split.x;\n    }\n    else\n    {\n        float _2049;\n        if (i == 1)\n        {\n            _2049 = _2043.fa_shadow_split.y;\n        }\n        else\n        {\n            float _2057;\n            if (i == 2)\n            {\n                _2057 = _2043.fa_shadow_split.z;\n            }\n            else\n            {\n                _2057 = _2043.fa_shadow_split.w;\n            }\n            _2049 = _2057;\n        }\n        _2033 = _2049;\n    }\n    return _2033;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2043, texture2d<float> fa_shadow_tex)\n{\n    float _2319 = fast::max(_2043.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _2324 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _2330 = sqrt(1.0 - (_2324 * _2324));\n    float _2337 = fast::min(_2330 / fast::max(_2324, 0.20000000298023223876953125), 4.0);\n    float _2342;\n    if (_2043.fa_shadow_bias.y > 0.0)\n    {\n        _2342 = _2043.fa_shadow_bias.y;\n    }\n    else\n    {\n        _2342 = 1.5 * _2043.fa_shadow_info[ci].x;\n    }\n    float4 _2367 = _2043.fa_shadow_mat[ci] * float4(world + (n * (_2342 * _2330)), 1.0);\n    float _2374 = _2367.x;\n    bool _2377 = _2374 < _2043.fa_shadow_rect[ci].x;\n    bool _2386;\n    if (!_2377)\n    {\n        _2386 = _2374 > _2043.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2386 = _2377;\n    }\n    bool _2395;\n    if (!_2386)\n    {\n        _2395 = _2367.y < _2043.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2395 = _2386;\n    }\n    bool _2404;\n    if (!_2395)\n    {\n        _2404 = _2367.y > _2043.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2404 = _2395;\n    }\n    bool _2411;\n    if (!_2404)\n    {\n        _2411 = _2367.z > 1.0;\n    }\n    else\n    {\n        _2411 = _2404;\n    }\n    if (_2411)\n    {\n        return -1.0;\n    }\n    float _2419;\n    if (_2043.fa_shadow_bias.x > 0.0)\n    {\n        _2419 = _2043.fa_shadow_bias.x;\n    }\n    else\n    {\n        _2419 = 1.5 * _2043.fa_shadow_info[ci].x;\n    }\n    float2 param = _2367.xy;\n    float4 param_1 = _2043.fa_shadow_rect[ci];\n    float param_2 = _2367.z - ((_2419 * (1.0 + (0.5 * _2337))) / _2319);\n    float param_3 = _2043.fa_shadow_info[ci].x;\n    float param_4 = _2319;\n    float param_5 = _2319 * 0.25;\n    float param_6 = ((_2043.fa_shadow_info[ci].x * fast::min(_2337, 3.0)) * 0.5) / _2319;\n    float3 param_7 = float3(0.0);\n    int param_8 = int(_2043.fa_shadow_cfg.z + 0.5);\n    float param_9 = _2043.fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9, fa_shadow_smp, gl_FragCoord, _2043, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _386, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2043, texture2d<float> fa_shadow_tex)\n{\n    if (_386.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2797 = int(_2043.fa_shadow_cfg.x + 0.5);\n    if (_2797 < 1)\n    {\n        return 1.0;\n    }\n    float _2812 = dot(world - _2043.fa_shadow_eye.xyz, _2043.fa_shadow_fwd.xyz);\n    int param = _2797 - 1;\n    if (_2812 > fa_shadow_split_at(param, _2043))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2824 = _2797 > 1;\n    bool _2831;\n    if (_2824)\n    {\n        _2831 = _2812 > _2043.fa_shadow_split.x;\n    }\n    else\n    {\n        _2831 = _2824;\n    }\n    if (_2831)\n    {\n        ci = 1;\n    }\n    bool _2835 = _2797 > 2;\n    bool _2842;\n    if (_2835)\n    {\n        _2842 = _2812 > _2043.fa_shadow_split.y;\n    }\n    else\n    {\n        _2842 = _2835;\n    }\n    if (_2842)\n    {\n        ci = 2;\n    }\n    bool _2846 = _2797 > 3;\n    bool _2853;\n    if (_2846)\n    {\n        _2853 = _2812 > _2043.fa_shadow_split.z;\n    }\n    else\n    {\n        _2853 = _2846;\n    }\n    if (_2853)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2797)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2879 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_shadow_smp, gl_FragCoord, _2043, fa_shadow_tex);\n        s = _2879;\n        if (_2879 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_2043.fa_shadow_cfg.y > 0.0)\n    {\n        float _2904;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2904 = fa_shadow_split_at(param_5, _2043);\n        }\n        else\n        {\n            _2904 = _2043.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _2923 = _2043.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _2043) - _2904, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2934 = fast::clamp((_2812 - (fa_shadow_split_at(param_7, _2043) - _2923)) / _2923, 0.0, 1.0);\n        if (_2934 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2797)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _2955 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_shadow_smp, gl_FragCoord, _2043, fa_shadow_tex);\n                s2 = _2955;\n                if (_2955 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2934);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _386, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2043, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, _386, fa_shadow_smp, gl_FragCoord, _2043, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_contact_shadow(thread const int& li, thread const float3& world, thread const float3& gn, thread const float3& l, thread const float& dist, constant fa_mesh_fs_params& _386, texture2d<float> fa_light_tex, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2043, texture2d<float> fa_screen_tex)\n{\n    bool _3236 = _386.fa_ct_a.x < 0.5;\n    bool _3243;\n    if (!_3236)\n    {\n        _3243 = _2043.fa_shadow_lcfg.x < 0.5;\n    }\n    else\n    {\n        _3243 = _3236;\n    }\n    if (_3243)\n    {\n        return 1.0;\n    }\n    int param = (int(_2043.fa_shadow_lcfg.x + 0.5) - 1) + li;\n    float4 _3256 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    float _3257 = _3256.y;\n    float len = _3257;\n    if (_3257 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3269 = length(world - _386.fa_camera_pos.xyz);\n    float _3279 = 1.0 - smoothstep(0.5 * _386.fa_ct_b.x, _386.fa_ct_b.x, _3269);\n    if (_3279 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3285 = len;\n    float _3288 = fast::min(_3285, 0.89999997615814208984375 * dist);\n    len = _3288;\n    float _3294 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _3269);\n    float _3299 = _3294 + (0.5 * _3288);\n    float3 _3305 = world + (gn * _3294);\n    float _3307 = fa_shadow_noise(gl_FragCoord);\n    float occ = 0.0;\n    float _3372;\n    for (int k = 0; k < 12; k++)\n    {\n        float _3323 = (float(k) + _3307) * 0.083333335816860198974609375;\n        float3 _3331 = _3305 + (l * (_3323 * len));\n        float4 _3337 = float4(_3331, 1.0);\n        float _3343 = dot(_386.fa_ct_vpw, _3337);\n        if (_3343 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        float2 _3363 = float2(dot(_386.fa_ct_vpx, _3337), dot(_386.fa_ct_vpy, _3337)) / float2(_3343);\n        float _3367 = _3363.x * 0.5;\n        float _3368 = _3367 + 0.5;\n        if (_386.fa_ct_a.y > 0.5)\n        {\n            _3372 = (_3363.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _3372 = 0.5 - (_3363.y * 0.5);\n        }\n        bool _3388 = _3368 < 0.0;\n        bool _3395;\n        if (!_3388)\n        {\n            _3395 = _3368 >= 1.0;\n        }\n        else\n        {\n            _3395 = _3388;\n        }\n        bool _3402;\n        if (!_3395)\n        {\n            _3402 = _3372 < 0.0;\n        }\n        else\n        {\n            _3402 = _3395;\n        }\n        bool _3409;\n        if (!_3402)\n        {\n            _3409 = _3372 >= 1.0;\n        }\n        else\n        {\n            _3409 = _3402;\n        }\n        if (_3409)\n        {\n            break;\n        }\n        float4 _3428 = fa_screen_tex.read(uint2(int2(float2(_3368, _3372) * _386.fa_ct_a.zw)), 0);\n        if (_3428.w < 0.5)\n        {\n            continue;\n        }\n        float _3447 = (dot(_386.fa_ct_fwd.xyz, _3331) + _386.fa_ct_fwd.w) - _3428.x;\n        if ((_3447 > _3294) && (_3447 < _3299))\n        {\n            occ = fast::max(occ, (1.0 - (_3323 * _3323)) * smoothstep(0.0, 0.0500000007450580596923828125, fast::min(fast::min(_3368, 0.5 - _3367), fast::min(_3372, 1.0 - _3372))));\n        }\n    }\n    return 1.0 - (occ * _3279);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, constant fa_mesh_fs_params& _386, texture2d<float> fa_light_tex, sampler fa_shadow_smp, texture2d<float> fa_light_atlas, sampler fa_env_smp, thread float3& fa_light_tint, thread bool& fa_light_is_area, thread float4& gl_FragCoord, constant fa_shadows& _2043, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos, texture2d<float> fa_screen_tex, thread float3& fa_lm)\n{\n    bool _3523 = fa_lm.z > 0.5;\n    bool _3529;\n    if (_3523)\n    {\n        int param = li;\n        _3529 = fa_light_baked(param, _386, fa_light_tex, fa_shadow_smp);\n    }\n    else\n    {\n        _3529 = _3523;\n    }\n    if (_3529)\n    {\n        int param_1 = li;\n        return LightSample{ float3(0.0, 1.0, 0.0), float3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1, _386, fa_light_tex, fa_shadow_smp) + 0.5) };\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _3553 = fa_light_sample_n(param_2, param_3, param_4, _386, fa_light_tex, fa_shadow_smp, fa_light_atlas, fa_env_smp, fa_light_tint, fa_light_is_area);\n    float3 _4678 = _3553.color;\n    float _4680 = _3553.shadow;\n    bool _3556 = _3553.type == 0;\n    if (_3556 && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _3553.direction;\n        float _3567 = fa_shadow_factor(param_5, param_6, _386, fa_shadow_smp, gl_FragCoord, _2043, fa_shadow_tex, fa_world_pos);\n        _4680 = _3567;\n        _4678 *= _3567;\n    }\n    else\n    {\n        bool _3578 = _3553.type != 0;\n        bool _3584;\n        if (_3578)\n        {\n            _3584 = _3553.attenuation > 0.0;\n        }\n        else\n        {\n            _3584 = _3578;\n        }\n        if (_3584)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7, _386);\n            int param_9 = li;\n            float3 param_10 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp).xyz;\n            float3 param_11 = world_pos;\n            float3 param_12 = gn;\n            float3 param_13 = _3553.direction;\n            float _3603 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13, _386, fa_light_tex, fa_shadow_smp, gl_FragCoord, _2043, fa_shadow_tex);\n            _4680 = _3603;\n            _4678 *= _3603;\n        }\n    }\n    bool _3613 = _386.fa_ct_a.x > 0.5;\n    bool _3619;\n    if (_3613)\n    {\n        _3619 = _3553.attenuation > 0.0;\n    }\n    else\n    {\n        _3619 = _3613;\n    }\n    if (_3619)\n    {\n        float _3626;\n        if (_3556)\n        {\n            _3626 = 1000000000.0;\n        }\n        else\n        {\n            _3626 = _3553._distance;\n        }\n        int param_14 = li;\n        float3 param_15 = world_pos;\n        float3 param_16 = gn;\n        float3 param_17 = _3553.direction;\n        float param_18 = _3626;\n        float _3644 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18, _386, fa_light_tex, fa_shadow_smp, gl_FragCoord, _2043, fa_screen_tex);\n        _4680 *= _3644;\n        _4678 *= _3644;\n    }\n    return LightSample{ _3553.direction, _4678, _3553.attenuation, _4680, _3553._distance, _3553.type };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 light(thread const SurfaceInput& i, thread const Surface& s, thread const LightSample& l, constant fa_material& _3673)\n{\n    float _3667;\n    if (dot(s.normal, l.direction) > 0.5)\n    {\n        _3667 = 1.0;\n    }\n    else\n    {\n        _3667 = _3673.dark;\n    }\n    return (s.albedo * l.color) * _3667;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _2043)\n{\n    if (_2043.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _2979 = int(_2043.fa_shadow_cfg.x + 0.5);\n    float _2989 = dot(world - _2043.fa_shadow_eye.xyz, _2043.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _2994 = _2979 > 0;\n    bool _3003;\n    if (_2994)\n    {\n        int param = _2979 - 1;\n        _3003 = _2989 <= fa_shadow_split_at(param, _2043);\n    }\n    else\n    {\n        _3003 = _2994;\n    }\n    if (_3003)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3009 = _2979 > 1;\n        bool _3016;\n        if (_3009)\n        {\n            _3016 = _2989 > _2043.fa_shadow_split.x;\n        }\n        else\n        {\n            _3016 = _3009;\n        }\n        if (_3016)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3022 = _2979 > 2;\n        bool _3029;\n        if (_3022)\n        {\n            _3029 = _2989 > _2043.fa_shadow_split.y;\n        }\n        else\n        {\n            _3029 = _3022;\n        }\n        if (_3029)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3035 = _2979 > 3;\n        bool _3042;\n        if (_3035)\n        {\n            _3042 = _2989 > _2043.fa_shadow_split.z;\n        }\n        else\n        {\n            _3042 = _3035;\n        }\n        if (_3042)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _386 [[buffer(1)]], constant fa_material& _3673 [[buffer(5)]], constant fa_shadows& _2043 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_env_tex [[texture(6)]], texture2d<float> fa_light_tex [[texture(7)]], texture2d<float> fa_light_atlas [[texture(8)]], texture2d<float> fa_lightmap [[texture(9)]], texture2d<float> fa_decal_tex [[texture(10)]], texture2d<float> fa_screen_tex [[texture(11)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _4499 = fast::normalize(in.fa_world_normal);\n    float3 fa_light_tint;\n    bool fa_light_is_area;\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _4499 = -_4499;\n    }\n    float3 _4069 = fast::normalize(_386.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, _386, fa_light_tex, fa_shadow_smp, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _4499, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _4069, short(gl_FrontFacing) };\n    Surface _4077 = fa_standard_surface(param_1, _386, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _4530 = _4077.albedo;\n    float _4531 = _4077.alpha;\n    float3 _4532 = _4077.normal;\n    float _4533 = _4077.metallic;\n    float _4534 = _4077.roughness;\n    float _4535 = _4077.occlusion;\n    float3 _4536 = _4077.emission;\n    float _4537 = _4077.clearcoat;\n    float _4538 = _4077.clearcoat_roughness;\n    float3 _4539 = _4077.sheen_color;\n    float _4540 = _4077.sheen_roughness;\n    float _4541 = _4077.anisotropy;\n    float _4542 = _4077.anisotropy_rotation;\n    float _4543 = _4077.specular;\n    float _4544 = _4077.ior;\n    float3 _4545 = _4077.specular_color;\n    float _4546 = _4077.transmission;\n    float _4547 = _4077.thickness;\n    float3 _4548 = _4077.attenuation_color;\n    float _4549 = _4077.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _4499, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _4069, short(gl_FrontFacing) };\n    Surface param_3 = _4077;\n    surface(param_2, param_3);\n    _4530 = param_3.albedo;\n    _4531 = param_3.alpha;\n    _4532 = param_3.normal;\n    _4533 = param_3.metallic;\n    _4534 = param_3.roughness;\n    _4535 = param_3.occlusion;\n    _4536 = param_3.emission;\n    _4537 = param_3.clearcoat;\n    _4538 = param_3.clearcoat_roughness;\n    _4539 = param_3.sheen_color;\n    _4540 = param_3.sheen_roughness;\n    _4541 = param_3.anisotropy;\n    _4542 = param_3.anisotropy_rotation;\n    _4543 = param_3.specular;\n    _4544 = param_3.ior;\n    _4545 = param_3.specular_color;\n    _4546 = param_3.transmission;\n    _4547 = param_3.thickness;\n    _4548 = param_3.attenuation_color;\n    _4549 = param_3.attenuation_distance;\n    float3 param_4 = in.fa_world_pos;\n    float3 param_5 = _4499;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7, _386, fa_light_tex, fa_shadow_smp, fa_env_smp, fa_decal_tex);\n    _4530 = param_6;\n    _4532 = param_7;\n    float3 result;\n    if (_386.fa_emissive.w > 0.5)\n    {\n        result = _4530;\n    }\n    else\n    {\n        float3 _4116 = _4532;\n        float3 _4117 = fast::normalize(_4116);\n        _4532 = _4117;\n        float3 param_8 = _4117;\n        float3 lit = (fa_indirect_diffuse(param_8, _386, fa_env_smp, fa_env_tex, in.fa_lm, fa_lightmap) * _4530) * _4535;\n        int _4136 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _4136; ln++)\n        {\n            int param_9 = ln;\n            int _4149 = fa_cl_light(param_9, _386, fa_light_tex, fa_shadow_smp, fa_cl_ndir, fa_cl_slot);\n            bool _4152 = in.fa_lm.z > 0.5;\n            bool _4158;\n            if (_4152)\n            {\n                int param_10 = _4149;\n                _4158 = fa_light_baked(param_10, _386, fa_light_tex, fa_shadow_smp);\n            }\n            else\n            {\n                _4158 = _4152;\n            }\n            if (_4158)\n            {\n                continue;\n            }\n            int param_11 = _4149;\n            float3 param_12 = in.fa_world_pos;\n            float3 param_13 = _4499;\n            LightSample _4170 = fa_light_shadowed(param_11, param_12, param_13, _386, fa_light_tex, fa_shadow_smp, fa_light_atlas, fa_env_smp, fa_light_tint, fa_light_is_area, gl_FragCoord, _2043, fa_shadow_tex, in.fa_world_pos, fa_screen_tex, in.fa_lm);\n            SurfaceInput param_14 = SurfaceInput{ in.fa_world_pos, _4499, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _4069, short(gl_FrontFacing) };\n            Surface param_15 = Surface{ _4530, _4531, _4532, _4533, _4534, _4535, _4536, _4537, _4538, _4539, _4540, _4541, _4542, _4543, _4544, _4545, _4546, _4547, _4548, _4549 };\n            LightSample param_16 = _4170;\n            lit += light(param_14, param_15, param_16, _3673);\n        }\n        result = lit;\n    }\n    float3 _4185 = result;\n    float3 _4186 = _4185 + _4536;\n    result = _4186;\n    float3 param_17 = _4186;\n    float3 param_18 = in.fa_world_pos;\n    result = fa_shadow_debug(param_17, param_18, _2043);\n    bool _4195 = _386.fa_fog.w > 0.0;\n    bool _4202;\n    if (!_4195)\n    {\n        _4202 = _386.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _4202 = _4195;\n    }\n    if (_4202)\n    {\n        float3 _4211 = in.fa_world_pos - _386.fa_camera_pos.xyz;\n        float _4217 = dot(_4211, _386.fa_fog_c.xyz);\n        bool _4221 = _386.fa_fog_c.w > 0.5;\n        float _4222;\n        if (_4221)\n        {\n            _4222 = _4217;\n        }\n        else\n        {\n            _4222 = length(_4211);\n        }\n        float _4234 = _4222 - _386.fa_fog_b.x;\n        if (_4234 > 0.0)\n        {\n            float _4243 = _386.fa_fog.w * _4234;\n            float tau = _4243 * _4243;\n            if (_386.fa_fog_b.y > 0.0)\n            {\n                float _4259;\n                if (_4221)\n                {\n                    _4259 = in.fa_world_pos.y - (_386.fa_fog_c.y * _4217);\n                }\n                else\n                {\n                    _4259 = _386.fa_camera_pos.y;\n                }\n                float _4280 = mix(_4259, in.fa_world_pos.y, fast::clamp(_386.fa_fog_b.x / _4222, 0.0, 1.0));\n                float _4284 = in.fa_world_pos.y - _4280;\n                float _4289 = _4280 - _386.fa_fog_b.z;\n                float _4294 = in.fa_world_pos.y - _386.fa_fog_b.z;\n                bool _4297 = _4289 <= 0.0;\n                bool _4298 = !_4297;\n                bool _4304;\n                if (_4298)\n                {\n                    _4304 = _386.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4304 = _4297;\n                }\n                float _4305;\n                if (_4304)\n                {\n                    _4305 = _386.fa_fog_b.y;\n                }\n                else\n                {\n                    _4305 = _386.fa_fog_b.y * exp(-fast::min(_386.fa_fog_b.w * _4289, 80.0));\n                }\n                bool _4332;\n                if (_4298)\n                {\n                    _4332 = _386.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4332 = _4297;\n                }\n                float _4333;\n                if (_4332)\n                {\n                    _4333 = _386.fa_fog_b.y * _4289;\n                }\n                else\n                {\n                    _4333 = (_386.fa_fog_b.y * (1.0 - exp(-fast::min(_386.fa_fog_b.w * _4289, 80.0)))) / _386.fa_fog_b.w;\n                }\n                bool _4358 = _4294 <= 0.0;\n                bool _4365;\n                if (!_4358)\n                {\n                    _4365 = _386.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4365 = _4358;\n                }\n                float _4366;\n                if (_4365)\n                {\n                    _4366 = _386.fa_fog_b.y * _4294;\n                }\n                else\n                {\n                    _4366 = (_386.fa_fog_b.y * (1.0 - exp(-fast::min(_386.fa_fog_b.w * _4294, 80.0)))) / _386.fa_fog_b.w;\n                }\n                float _4393;\n                if (abs(_4284) < 0.001000000047497451305389404296875)\n                {\n                    _4393 = _4305;\n                }\n                else\n                {\n                    _4393 = (_4366 - _4333) / _4284;\n                }\n                tau += (_4234 * fast::max(_4393, 0.0));\n            }\n            result = mix(result, _386.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _4531);\n    return out;\n}\n\n",
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
            "size": 512,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_386",
            "msl_buffer_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2043",
            "msl_buffer_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_3673",
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float3 fa_lm [[user(locn5)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n    float4 fa_joints [[attribute(9)]];\n    float4 fa_weights [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _183)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_183.fa_joint_rows[_174] * weights[i]);\n        r1 += (_183.fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183.fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _136);\n    float3 _391 = _273.world_pos;\n    fa_world_pos = _391;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = _136.fa_view_proj * float4(_391, 1.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _136 [[buffer(0)]], constant fa_skin& _183 [[buffer(3)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float4x4 param_2 = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _183);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7, _136, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.gl_Position);\n    out.fa_lm = float3(0.0);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n#pragma clang diagnostic ignored \"-Wmissing-braces\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\ntemplate<typename T, size_t Num>\nstruct spvUnsafeArray\n{\n    T elements[Num ? Num : 1];\n    \n    thread T& operator [] (size_t pos) thread\n    {\n        return elements[pos];\n    }\n    constexpr const thread T& operator [] (size_t pos) const thread\n    {\n        return elements[pos];\n    }\n    \n    device T& operator [] (size_t pos) device\n    {\n        return elements[pos];\n    }\n    constexpr const device T& operator [] (size_t pos) const device\n    {\n        return elements[pos];\n    }\n    \n    constexpr const constant T& operator [] (size_t pos) const constant\n    {\n        return elements[pos];\n    }\n    \n    threadgroup T& operator [] (size_t pos) threadgroup\n    {\n        return elements[pos];\n    }\n    constexpr const threadgroup T& operator [] (size_t pos) const threadgroup\n    {\n        return elements[pos];\n    }\n};\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n    float4 fa_ct_a;\n    float4 fa_ct_b;\n    float4 fa_ct_vpx;\n    float4 fa_ct_vpy;\n    float4 fa_ct_vpw;\n    float4 fa_ct_fwd;\n    float4 fa_tr_a;\n    float4 fa_tr_b;\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n    float4 fa_shadow_lcfg;\n};\n\nstruct fa_material\n{\n    float dark;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float3 fa_lm [[user(locn5)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_cluster_texel(thread const float3& world_pos, constant fa_mesh_fs_params& _386, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    bool _1314 = _386.fa_cl_info.x < 0.0;\n    bool _1321;\n    if (!_1314)\n    {\n        _1321 = _386.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _1321 = _1314;\n    }\n    bool _1329;\n    if (!_1321)\n    {\n        _1329 = _386.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _1329 = _1321;\n    }\n    bool _1336;\n    if (!_1329)\n    {\n        _1336 = _386.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _1336 = _1329;\n    }\n    bool _1343;\n    if (!_1336)\n    {\n        _1343 = _386.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _1343 = _1336;\n    }\n    if (_1343)\n    {\n        return float4(0.0);\n    }\n    float4 _1353 = float4(world_pos, 1.0);\n    float _1359 = dot(_386.fa_cl_vpw, _1353);\n    if (!(_1359 > 9.9999999747524270787835121154785e-07))\n    {\n        return float4(0.0);\n    }\n    float2 _1381 = float2(dot(_386.fa_cl_vpx, _1353), dot(_386.fa_cl_vpy, _1353)) / float2(_1359);\n    int _1385 = int(_386.fa_cl_grid.x);\n    int _1389 = int(_386.fa_cl_grid.y);\n    int param = (int(_386.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_386.fa_cl_fwd.xyz, world_pos) + _386.fa_cl_fwd.w, _386.fa_cl_grid.w) / _386.fa_cl_grid.w) * _386.fa_cl_grid.z)), 0, int(_386.fa_cl_info.y) - 1) * _1389) + clamp(int(floor(((_1381.y * 0.5) + 0.5) * _386.fa_cl_grid.y)), 0, _1389 - 1)) * _1385)) + clamp(int(floor(((_1381.x * 0.5) + 0.5) * _386.fa_cl_grid.x)), 0, _1385 - 1);\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, constant fa_mesh_fs_params& _386, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    float3 param = world_pos;\n    float4 _1465 = fa_cluster_texel(param, _386, fa_light_tex, fa_shadow_smp);\n    return int2(int(_1465.x), int(_1465.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, constant fa_mesh_fs_params& _386, texture2d<float> fa_light_tex, sampler fa_shadow_smp, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_386.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _3496 = fa_cluster_lookup(param, _386, fa_light_tex, fa_shadow_smp);\n    fa_cl_slot = _3496.x;\n    fa_cl_local = _3496.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _3722 = fa_linear_to_srgb(param);\n        c = _3722;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _3730 = fa_srgb_to_linear(param_1);\n            c = _3730;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _269;\n    if (bool(i.front_facing))\n    {\n        _269 = i.world_normal;\n    }\n    else\n    {\n        _269 = -i.world_normal;\n    }\n    float3 _293 = fast::normalize(i.world_tangent.xyz - (_269 * dot(_269, i.world_tangent.xyz)));\n    float3 _320 = fast::normalize(((_293 * m.x) + ((cross(_269, _293) * i.world_tangent.w) * m.y)) + (_269 * m.z));\n    float3 _323;\n    if (bool(i.front_facing))\n    {\n        _323 = _320;\n    }\n    else\n    {\n        _323 = -_320;\n    }\n    return _323;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _386, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _386.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _3761 = fa_tex_fix(param_2, param_3);\n    float4 _4854 = base_t;\n    _4854.x = _3761.x;\n    _4854.y = _3761.y;\n    _4854.z = _3761.z;\n    base_t = _4854;\n    float4 _3775 = (_4854 * _386.fa_base_color) * i.vertex_color;\n    float3 _4698 = i.world_normal;\n    if (_386.fa_maps.z > 0.5)\n    {\n        float param_4 = _386.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _3807 = fa_tex_fix(param_6, param_7);\n        float3 _3810 = (_3807 * 2.0) - float3(1.0);\n        float2 _3815 = _3810.xy * _386.fa_maps.x;\n        float3 _4862 = _3810;\n        _4862.x = _3815.x;\n        _4862.y = _3815.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _4862;\n        _4698 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _386.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _3843 = fa_tex_fix(param_12, param_13);\n    float4 _4865 = mrt;\n    _4865.x = _3843.x;\n    _4865.y = _3843.y;\n    _4865.z = _3843.z;\n    mrt = _4865;\n    float4 _3871 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _386.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _3871.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _3882 = fa_tex_fix(param_16, param_17);\n    float param_18 = _386.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _3912 = fa_tex_fix(param_20, param_21);\n    float _4703 = _386.fa_layers_a.x;\n    float _4704 = _386.fa_layers_a.y;\n    float _4707 = _386.fa_layers_a.z;\n    float _4706 = _386.fa_layers_b.w;\n    float _4709 = _386.fa_layers_c.x;\n    if (_386.fa_layers_c.z > 0.5)\n    {\n        if (mod(_386.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _4703 *= _3882.y;\n            _4704 *= _3882.z;\n            _4706 *= _3871.w;\n        }\n        if (_386.fa_layers_c.z > 1.5)\n        {\n            _4707 *= mrt.x;\n            _4709 *= mrt.w;\n        }\n    }\n    return Surface{ _3775.xyz, _3775.w, _4698, fast::clamp(_386.fa_pbr.x * _3843.z, 0.0, 1.0), fast::clamp(_386.fa_pbr.y * _3843.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_386.fa_maps.y * (_3882.x - 1.0)), _386.fa_emissive.xyz + (_386.fa_model_emissive.xyz * _3912), _4703, _4704, _386.fa_layers_b.xyz, _4706, _4707, _386.fa_layers_a.w, _4709, _386.fa_layers_c.y, _386.fa_layers_d.xyz, _386.fa_tr_a.x, _386.fa_tr_a.y, _386.fa_tr_b.xyz, _386.fa_tr_a.z };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_decal_tile(thread const float4& rect, thread const float2& uv, thread const float2& atlas, thread const float2& ddx, thread const float2& ddy, sampler fa_env_smp, texture2d<float> fa_decal_tex)\n{\n    float2 _1545 = rect.zw - rect.xy;\n    float2 _1549 = _1545 * atlas;\n    float2 _1553 = ddx * _1549;\n    float2 _1557 = ddy * _1549;\n    return fa_decal_tex.sample(fa_env_smp, (rect.xy + (fast::clamp(uv, float2(0.0), float2(1.0)) * _1545)), level(fast::clamp(0.5 * log2(fast::max(fast::max(dot(_1553, _1553), dot(_1557, _1557)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_apply_decals(thread const float3& world_pos, thread const float3& geo_normal, thread float3& albedo, thread float3& normal, constant fa_mesh_fs_params& _386, texture2d<float> fa_light_tex, sampler fa_shadow_smp, sampler fa_env_smp, texture2d<float> fa_decal_tex)\n{\n    bool _1590 = _386.fa_counts.y < 0.5;\n    bool _1597;\n    if (!_1590)\n    {\n        _1597 = _386.fa_counts.w < 0.5;\n    }\n    else\n    {\n        _1597 = _1590;\n    }\n    if (_1597)\n    {\n        return;\n    }\n    float3 _1603 = dfdx(world_pos);\n    float3 _1606 = dfdy(world_pos);\n    float3 param = world_pos;\n    float4 _1610 = fa_cluster_texel(param, _386, fa_light_tex, fa_shadow_smp);\n    int _1614 = int(_1610.w);\n    if (_1614 < 1)\n    {\n        return;\n    }\n    int _1624 = int(_386.fa_counts.y + 0.5);\n    int param_1 = _1624;\n    float4 _1628 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float2 _1631 = _1628.yz;\n    int _1635 = int(_1628.w);\n    int param_2 = _1624 + 1;\n    float4 _1640 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float _1641 = _1640.x;\n    int _1647 = int(_386.fa_counts.w + 0.5) - 1;\n    int _1651 = int(_1610.z);\n    float3 _1916;\n    for (int k = 0; k < _1614; k++)\n    {\n        int _1664 = _1651 + k;\n        int param_3 = _1635 + (_1664 >> 2);\n        int _1681 = (_1624 + 2) + (int(fa_light_texel(param_3, fa_light_tex, fa_shadow_smp)[_1664 & 3]) * 7);\n        int param_4 = _1681 + 6;\n        float4 _1686 = fa_light_texel(param_4, fa_light_tex, fa_shadow_smp);\n        if (((int(_1686.w + 0.5) >> _1647) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1681;\n        float4 _1701 = fa_light_texel(param_5, fa_light_tex, fa_shadow_smp);\n        int param_6 = _1681 + 1;\n        float4 _1706 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n        int param_7 = _1681 + 2;\n        float4 _1711 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n        float3 _1714 = _1701.xyz;\n        float _1719 = dot(_1714, world_pos) + _1701.w;\n        float3 _1721 = _1706.xyz;\n        float _1726 = dot(_1721, world_pos) + _1706.w;\n        float3 _1728 = _1711.xyz;\n        float _1733 = dot(_1728, world_pos) + _1711.w;\n        bool _1738 = abs(_1719) > 0.5;\n        bool _1746;\n        if (!_1738)\n        {\n            _1746 = abs(_1726) > 0.5;\n        }\n        else\n        {\n            _1746 = _1738;\n        }\n        bool _1754;\n        if (!_1746)\n        {\n            _1754 = abs(_1733) > 0.5;\n        }\n        else\n        {\n            _1754 = _1746;\n        }\n        if (_1754)\n        {\n            continue;\n        }\n        float _1769 = fast::clamp(dot(geo_normal, fast::normalize(_1728)) * _1686.z, 0.0, 1.0);\n        if (_1769 <= 0.0)\n        {\n            continue;\n        }\n        float _1789 = (fast::clamp((0.5 - abs(_1733)) * 10.0, 0.0, 1.0) * _1769) * _1686.x;\n        float2 _1797 = float2(_1719 + 0.5, 0.5 - _1726);\n        float2 _1807 = float2(dot(_1714, _1603), dot(_1721, _1603));\n        float2 _1817 = float2(dot(_1714, _1606), dot(_1721, _1606));\n        int param_8 = _1681 + 5;\n        float4 _1822 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n        int param_9 = _1681 + 3;\n        float4 _1827 = fa_light_texel(param_9, fa_light_tex, fa_shadow_smp);\n        int param_10 = _1681 + 4;\n        float4 _1832 = fa_light_texel(param_10, fa_light_tex, fa_shadow_smp);\n        float tex_a = 1.0;\n        float3 col = _1822.xyz;\n        bool _1842 = _1827.z > _1827.x;\n        if (_1842)\n        {\n            float4 param_11 = _1827;\n            float2 param_12 = _1797;\n            float2 param_13 = _1631;\n            float2 param_14 = _1807;\n            float2 param_15 = _1817;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15, fa_env_smp, fa_decal_tex);\n            if ((_1641 > 0.5) && (_1641 < 1.5))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1868 = fa_dc_to_linear(param_16);\n                float4 _4786 = tx;\n                _4786.x = _1868.x;\n                _4786.y = _1868.y;\n                _4786.z = _1868.z;\n                tx = _4786;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, float3(fast::clamp((_1789 * tex_a) * _1822.w, 0.0, 1.0)));\n        if (_1832.z > _1832.x)\n        {\n            float4 param_17 = _1832;\n            float2 param_18 = _1797;\n            float2 param_19 = _1631;\n            float2 param_20 = _1807;\n            float2 param_21 = _1817;\n            float4 _1912 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21, fa_env_smp, fa_decal_tex);\n            if (_1641 > 1.5)\n            {\n                float3 param_22 = _1912.xyz;\n                float3 _1922 = fa_dc_to_srgb(param_22);\n                _1916 = _1922;\n            }\n            else\n            {\n                _1916 = _1912.xyz;\n            }\n            float3 _1931 = (_1916 * 2.0) - float3(1.0);\n            float2 _1936 = _1931.xy * _1686.y;\n            float3 _1958 = (fast::normalize(_1714) * _1936.x) + (fast::normalize(_1721) * _1936.y);\n            float3 _1961 = fast::normalize(normal);\n            normal = fast::normalize(mix(_1961, fast::normalize((_1961 * fast::max(_1931.z, 0.0500000007450580596923828125)) + (_1958 - (_1961 * dot(_1961, _1958)))), float3(fast::clamp(_1789 * (_1842 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_sh_coef(thread const int& k, constant fa_mesh_fs_params& _386, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float3 v = fa_env_tex.sample(fa_env_smp, float3(1.0, 1.0 - (float((2 * (k >> 2)) + 1) * 0.25), 1.0 - (float((2 * (k & 3)) + 1) * 0.25)), level(5.0)).xyz;\n    if (_386.fa_env_sky.w > 1.5)\n    {\n        v = (v - float3(0.5)) * 8.0;\n    }\n    return v;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sh_eval(thread const spvUnsafeArray<float3, 9>& c, thread const float3& n)\n{\n    float3 _3156 = fast::max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), float3(0.0));\n    return _3156;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _386, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    if (_386.fa_env_sky.w > 0.5)\n    {\n        spvUnsafeArray<float3, 9> c;\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param, _386, fa_env_smp, fa_env_tex);\n        }\n        spvUnsafeArray<float3, 9> param_1 = c;\n        float3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return _386.fa_ambient.xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_indirect_diffuse(thread const float3& n, constant fa_mesh_fs_params& _386, sampler fa_env_smp, texturecube<float> fa_env_tex, thread float3& fa_lm, texture2d<float> fa_lightmap)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return fa_lightmap.sample(fa_env_smp, fa_lm.xy, level(0.0)).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param, _386, fa_env_smp, fa_env_tex);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, constant fa_mesh_fs_params& _386, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (int(_386.fa_cl_info.x) + int(_386.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, constant fa_mesh_fs_params& _386, texture2d<float> fa_light_tex, sampler fa_shadow_smp, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, _386, fa_light_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_light_base(thread const int& li, constant fa_mesh_fs_params& _386)\n{\n    return li * ((_386.fa_ambient.w > 4.5) ? 8 : 4);\n}\n\nstatic inline __attribute__((always_inline))\nbool fa_light_baked(thread const int& li, constant fa_mesh_fs_params& _386, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li;\n    int param_1 = fa_light_base(param, _386) + 3;\n    return fa_light_texel(param_1, fa_light_tex, fa_shadow_smp).w > 0.5;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_light_type(thread const int& li, constant fa_mesh_fs_params& _386, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li;\n    int param_1 = fa_light_base(param, _386) + 1;\n    return fa_light_texel(param_1, fa_light_tex, fa_shadow_smp).w;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_area_point(thread const float3& c, thread const float3& axis, thread const float3& ru, thread const float3& uu, thread const float& hx, thread const float& hy, thread const float& shape, thread const float3& p, thread const float3& r)\n{\n    bool _564 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        float3 _577 = (c - (ru * hx)) - p;\n        float3 _583 = ru * (2.0 * hx);\n        float _589 = fast::max(dot(_583, _583), 9.9999999392252902907785028219223e-09);\n        float _593 = dot(_577, _583);\n        float t = fast::clamp((-_593) / _589, 0.0, 1.0);\n        if (_564)\n        {\n            float _608 = dot(r, _583);\n            float _614 = _589 - (_608 * _608);\n            if (abs(_614) > (9.9999997473787516355514526367188e-06 * _589))\n            {\n                t = fast::clamp(((dot(r, _577) * _608) - _593) / _614, 0.0, 1.0);\n            }\n        }\n        return (p + _577) + (_583 * t);\n    }\n    float3 q = p;\n    float _646 = dot(r, axis);\n    bool _654;\n    if (_564)\n    {\n        _654 = abs(_646) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _654 = _564;\n    }\n    if (_654)\n    {\n        float _664 = dot(c - p, axis) / _646;\n        if (_664 > 0.0)\n        {\n            q = p + (r * _664);\n        }\n    }\n    float3 _677 = q - c;\n    float2 xy = float2(dot(_677, ru), dot(_677, uu));\n    if (shape > 0.5)\n    {\n        float _692 = length(xy);\n        if (_692 > hx)\n        {\n            xy *= (hx / _692);\n        }\n    }\n    else\n    {\n        xy = fast::clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_atlas_fetch(thread const float2& texel, texture2d<float> fa_light_atlas, sampler fa_env_smp)\n{\n    return fa_light_atlas.sample(fa_env_smp, (texel / float2(int2(fa_light_atlas.get_width(), fa_light_atlas.get_height()))), level(0.0));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_cookie_sample(thread const float2& tile_origin, thread const float2& uv, texture2d<float> fa_light_atlas, sampler fa_env_smp)\n{\n    float2 param = (tile_origin + float2(1.0)) + (fast::clamp(uv, float2(0.0), float2(1.0)) * 254.0);\n    return fa_atlas_fetch(param, fa_light_atlas, fa_env_smp).xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_ies_sample(thread const float2& tile_origin, thread const float3& d, thread const float3& axis, thread const float3& right, thread const float3& up, texture2d<float> fa_light_atlas, sampler fa_env_smp)\n{\n    float _484 = dot(d, right);\n    float _488 = dot(d, up);\n    float _499;\n    if (((_484 * _484) + (_488 * _488)) > 1.0000000133514319600180897396058e-10)\n    {\n        _499 = precise::atan2(_488, _484) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _499 = 0.0;\n    }\n    float2 param = tile_origin + float2(1.0 + ((_499 - floor(_499)) * 64.0), 1.0 + (acos(fast::clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param, fa_light_atlas, fa_env_smp).x;\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cube_face(thread const float3& d)\n{\n    float3 _335 = abs(d);\n    float _337 = _335.x;\n    float _339 = _335.y;\n    bool _340 = _337 >= _339;\n    bool _348;\n    if (_340)\n    {\n        _348 = _337 >= _335.z;\n    }\n    else\n    {\n        _348 = _340;\n    }\n    int _349;\n    if (_348)\n    {\n        _349 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _364;\n        if (_339 >= _335.z)\n        {\n            _364 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _364 = (d.z > 0.0) ? 4 : 5;\n        }\n        _349 = _364;\n    }\n    return _349;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cube_face_basis(thread const int& f, thread float3& fwd, thread float3& up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0, 0.0, 0.0);\n        up = float3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0, 0.0, 0.0);\n            up = float3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0, 1.0, 0.0);\n                up = float3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0, -1.0, 0.0);\n                    up = float3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0, 0.0, 1.0);\n                        up = float3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0, 0.0, -1.0);\n                        up = float3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample_n(thread const int& li, thread const float3& world_pos, thread const float3& n, constant fa_mesh_fs_params& _386, texture2d<float> fa_light_tex, sampler fa_shadow_smp, texture2d<float> fa_light_atlas, sampler fa_env_smp, thread float3& fa_light_tint, thread bool& fa_light_is_area)\n{\n    int param = li;\n    int _730 = fa_light_base(param, _386);\n    bool _734 = _386.fa_ambient.w > 4.5;\n    int param_1 = _730;\n    float4 _738 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    int param_2 = _730 + 1;\n    float4 _743 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float _746 = _743.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = float3(1.0);\n    bool _758 = _734 && (_746 > 2.5);\n    fa_light_is_area = _758;\n    bool _760 = _746 < 0.5;\n    float3 l;\n    if (_760)\n    {\n        l = fast::normalize(_738.xyz);\n        if (_734)\n        {\n            int param_3 = _730 + 6;\n            float4 _774 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            if (_774.z > 0.5)\n            {\n                int param_4 = _730 + 4;\n                float4 _784 = fa_light_texel(param_4, fa_light_tex, fa_shadow_smp);\n                int param_5 = _730 + 5;\n                float4 _789 = fa_light_texel(param_5, fa_light_tex, fa_shadow_smp);\n                float2 param_6 = _774.xy;\n                float2 param_7 = fract(float2(dot(world_pos, _784.xyz) * _784.w, (-dot(world_pos, _789.xyz)) * _789.w) + float2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7, fa_light_atlas, fa_env_smp);\n            }\n        }\n    }\n    else\n    {\n        float3 _819 = _738.xyz;\n        float3 _821 = _819 - world_pos;\n        float3 to_light = _821;\n        float _824 = length(_821);\n        float reach = _824;\n        bool front = true;\n        if (_758)\n        {\n            int param_8 = _730 + 7;\n            reach = fast::max(_824 - fa_light_texel(param_8, fa_light_tex, fa_shadow_smp).w, 0.0);\n            int param_9 = _730 + 4;\n            float4 _848 = fa_light_texel(param_9, fa_light_tex, fa_shadow_smp);\n            int param_10 = _730 + 5;\n            float4 _853 = fa_light_texel(param_10, fa_light_tex, fa_shadow_smp);\n            int param_11 = _730 + 6;\n            float4 _858 = fa_light_texel(param_11, fa_light_tex, fa_shadow_smp);\n            float _859 = _858.w;\n            int param_12 = _730 + 2;\n            float3 _866 = fast::normalize(fa_light_texel(param_12, fa_light_tex, fa_shadow_smp).xyz);\n            bool _868 = _859 > 1.5;\n            bool _876;\n            if (!_868)\n            {\n                _876 = dot(_866, to_light) < 0.0;\n            }\n            else\n            {\n                _876 = _868;\n            }\n            front = _876;\n            float3 r = float3(0.0);\n            float3 _885 = _386.fa_camera_pos.xyz - world_pos;\n            bool _889 = dot(n, n) > 0.5;\n            bool _897;\n            if (_889)\n            {\n                _897 = dot(_885, _885) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _897 = _889;\n            }\n            if (_897)\n            {\n                r = reflect(-fast::normalize(_885), fast::normalize(n));\n            }\n            float3 param_13 = _819;\n            float3 param_14 = _866;\n            float3 param_15 = _848.xyz;\n            float3 param_16 = _853.xyz;\n            float param_17 = _848.w;\n            float param_18 = _853.w;\n            float param_19 = _859;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _933 = length(to_light);\n        dist = _933;\n        l = to_light / float3(fast::max(_933, 9.9999997473787516355514526367188e-05));\n        float _947 = reach / fast::max(_738.w, 0.001000000047497451305389404296875);\n        float _953 = fast::clamp(1.0 - (_947 * _947), 0.0, 1.0);\n        float _955;\n        if (front)\n        {\n            _955 = _953 * _953;\n        }\n        else\n        {\n            _955 = 0.0;\n        }\n        atten = _955;\n        bool _966 = _746 < 2.5;\n        if ((_746 > 1.5) && _966)\n        {\n            int param_22 = _730 + 2;\n            float4 _974 = fa_light_texel(param_22, fa_light_tex, fa_shadow_smp);\n            float _984 = _974.w;\n            int param_23 = _730 + 3;\n            float4 _989 = fa_light_texel(param_23, fa_light_tex, fa_shadow_smp);\n            float _990 = _989.x;\n            float cos_inner = _990;\n            if (_990 > 1.5)\n            {\n                cos_inner = mix(_984, 1.0, 0.25);\n            }\n            atten *= smoothstep(_984, cos_inner, dot(-l, fast::normalize(_974.xyz)));\n        }\n        if (_734 && (_746 < 1.5))\n        {\n            int param_24 = _730 + 6;\n            float4 _1014 = fa_light_texel(param_24, fa_light_tex, fa_shadow_smp);\n            if (_1014.z > 0.5)\n            {\n                float3 _1022 = -to_light;\n                int param_25 = _730 + 4;\n                int param_26 = _730 + 5;\n                float3 _1036 = fa_light_texel(param_25, fa_light_tex, fa_shadow_smp).xyz;\n                float3 _1040 = fa_light_texel(param_26, fa_light_tex, fa_shadow_smp).xyz;\n                float3 _1049 = float3(dot(_1022, _1036), dot(_1022, _1040), dot(_1022, cross(_1036, _1040)));\n                float3 param_27 = _1049;\n                int _1053 = fa_cube_face(param_27);\n                int param_28 = _1053;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1080 = float2(dot(_1049, cross(param_29, param_30)), dot(_1049, param_30)) / float2(fast::max(dot(_1049, param_29), 9.9999997473787516355514526367188e-05));\n                int _1084 = _1053 / 3;\n                float2 param_31 = _1014.xy + (float2(float(_1053 - (_1084 * 3)), float(_1084)) * 256.0);\n                float2 param_32 = float2(0.5 + (0.5 * _1080.x), 0.5 - (0.5 * _1080.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32, fa_light_atlas, fa_env_smp);\n            }\n            int param_33 = _730 + 7;\n            float4 _1114 = fa_light_texel(param_33, fa_light_tex, fa_shadow_smp);\n            if (_1114.z > 0.5)\n            {\n                int param_34 = _730 + 2;\n                int param_35 = _730 + 4;\n                int param_36 = _730 + 5;\n                float2 param_37 = _1114.xy;\n                float3 param_38 = -l;\n                float3 param_39 = fast::normalize(fa_light_texel(param_34, fa_light_tex, fa_shadow_smp).xyz);\n                float3 param_40 = fa_light_texel(param_35, fa_light_tex, fa_shadow_smp).xyz;\n                float3 param_41 = fa_light_texel(param_36, fa_light_tex, fa_shadow_smp).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41, fa_light_atlas, fa_env_smp);\n            }\n        }\n        else\n        {\n            if (_734 && _966)\n            {\n                int param_42 = _730 + 6;\n                float4 _1161 = fa_light_texel(param_42, fa_light_tex, fa_shadow_smp);\n                int param_43 = _730 + 7;\n                float4 _1166 = fa_light_texel(param_43, fa_light_tex, fa_shadow_smp);\n                bool _1169 = _1161.z > 0.5;\n                bool _1176;\n                if (!_1169)\n                {\n                    _1176 = _1166.z > 0.5;\n                }\n                else\n                {\n                    _1176 = _1169;\n                }\n                if (_1176)\n                {\n                    int param_44 = _730 + 2;\n                    float4 _1183 = fa_light_texel(param_44, fa_light_tex, fa_shadow_smp);\n                    float3 _1187 = fast::normalize(_1183.xyz);\n                    int param_45 = _730 + 4;\n                    float4 _1192 = fa_light_texel(param_45, fa_light_tex, fa_shadow_smp);\n                    int param_46 = _730 + 5;\n                    float4 _1197 = fa_light_texel(param_46, fa_light_tex, fa_shadow_smp);\n                    if (_1169)\n                    {\n                        float3 _1205 = -to_light;\n                        float _1212 = _1183.w;\n                        float _1228 = 0.5 / fast::max(dot(_1205, _1187) * (sqrt(fast::max(1.0 - (_1212 * _1212), 0.0)) / fast::max(_1212, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        float2 param_47 = _1161.xy;\n                        float2 param_48 = float2(0.5 + (dot(_1205, _1192.xyz) * _1228), 0.5 - (dot(_1205, _1197.xyz) * _1228));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48, fa_light_atlas, fa_env_smp);\n                    }\n                    if (_1166.z > 0.5)\n                    {\n                        float2 param_49 = _1166.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1187;\n                        float3 param_52 = _1192.xyz;\n                        float3 param_53 = _1197.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53, fa_light_atlas, fa_env_smp);\n                    }\n                }\n            }\n        }\n    }\n    float3 _4652 = _743.xyz * atten;\n    if (_734)\n    {\n        _4652 *= fa_light_tint;\n    }\n    int _1296;\n    if (_760)\n    {\n        _1296 = 0;\n    }\n    else\n    {\n        _1296 = ((_746 > 1.5) && (_746 < 2.5)) ? 2 : 1;\n    }\n    return LightSample{ l, _4652, atten, 1.0, dist, _1296 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_fetch(thread const float2& uv, thread const float4& rect, thread const float3& conv, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2090 = fa_shadow_depth(param, param_1, fa_shadow_smp, fa_shadow_tex);\n    float _2094;\n    if (conv.x < 0.5)\n    {\n        _2094 = _2090;\n    }\n    else\n    {\n        _2094 = (conv.y * conv.z) / (conv.z - (_2090 * (conv.z - conv.y)));\n    }\n    return _2094;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _2021 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_2021), sin(_2021)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_filter(thread const float2& uv, thread const float4& rect, thread const float& zr, thread const float& texel_m, thread const float& unit, thread const float& reach, thread const float& plane, thread const float3& conv, thread const int& mode, thread const float& k, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2043, texture2d<float> fa_shadow_tex)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2, fa_shadow_smp, fa_shadow_tex));\n    }\n    float _2140 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2149;\n        if (k < 0.0)\n        {\n            _2149 = (-k) / fast::max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2149 = k;\n        }\n        float _2169 = fast::clamp((_2149 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2140;\n            float2 _2188 = fa_shadow_vogel(param_3, param_4, param_5) * _2169;\n            float2 param_6 = uv + (_2188 * _2043.fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _2200 = fa_shadow_fetch(param_6, param_7, param_8, fa_shadow_smp, fa_shadow_tex);\n            if (_2200 < (zr - (length(_2188) * plane)))\n            {\n                sum += _2200;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2226 = sum / cnt;\n        float _2236;\n        if (k < 0.0)\n        {\n            _2236 = (-k) / fast::max(_2226, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2236 = k;\n        }\n        radius = fast::clamp(((fast::max(zr - _2226, 0.0) * unit) * _2236) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _2258 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2258; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2258;\n        float param_11 = _2140;\n        float2 _2277 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_2277 * _2043.fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_2277) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14, fa_shadow_smp, fa_shadow_tex));\n    }\n    return lit / float(_2258);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_local(thread const int& li, thread const float3& lpos, thread const float3& world, thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _386, texture2d<float> fa_light_tex, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2043, texture2d<float> fa_shadow_tex)\n{\n    bool _2477 = _386.fa_pbr.z < 0.5;\n    bool _2484;\n    if (!_2477)\n    {\n        _2484 = _2043.fa_shadow_lcfg.x < 0.5;\n    }\n    else\n    {\n        _2484 = _2477;\n    }\n    if (_2484)\n    {\n        return 1.0;\n    }\n    int param = (int(_2043.fa_shadow_lcfg.x + 0.5) - 1) + li;\n    float4 _2497 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    float _2498 = _2497.x;\n    if (_2498 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2507 = int(_2498 + 0.5);\n    int param_1 = _2507;\n    float4 _2511 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    int param_2 = _2507 + 1;\n    float4 _2516 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float fade = 1.0;\n    float _2519 = _2511.y;\n    if (_2519 > 0.0)\n    {\n        float _2536 = 1.0 - smoothstep(0.75 * _2519, _2519, length(world - _2043.fa_shadow_eye.xyz));\n        fade = _2536;\n        if (_2536 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2511.x > 1.5)\n    {\n        float3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2560 = (_2507 + 2) + (face * 6);\n    int param_4 = _2560;\n    int param_5 = _2560 + 1;\n    int param_6 = _2560 + 3;\n    float4 _2574 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n    int param_7 = _2560 + 4;\n    float4 _2579 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n    int param_8 = _2560 + 5;\n    float4 _2584 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n    float _2596 = _2584.x * fast::max(dot(_2574, float4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2601 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _2624 = fast::clamp(dot(n, _2574.xyz), -1.0, 1.0);\n    float _2643 = fast::min(sqrt(1.0 - (_2624 * _2624)) / fast::max(abs(dot(n, world - lpos)) / fast::max(dot(_2574, float4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2646 = _2516.y;\n    float _2648;\n    if (_2646 > 0.0)\n    {\n        _2648 = _2646;\n    }\n    else\n    {\n        _2648 = 1.5 * _2596;\n    }\n    float4 _2668 = float4(world + (n * (_2648 * sqrt(1.0 - (_2601 * _2601)))), 1.0);\n    float _2672 = dot(_2574, _2668);\n    float _2675 = _2584.y;\n    if (_2672 < _2675)\n    {\n        return 1.0;\n    }\n    float2 _2690 = float2(dot(fa_light_texel(param_4, fa_light_tex, fa_shadow_smp), _2668), dot(fa_light_texel(param_5, fa_light_tex, fa_shadow_smp), _2668)) / float2(_2672);\n    float _2692 = _2690.x;\n    bool _2695 = _2692 < _2579.x;\n    bool _2704;\n    if (!_2695)\n    {\n        _2704 = _2692 > _2579.z;\n    }\n    else\n    {\n        _2704 = _2695;\n    }\n    bool _2713;\n    if (!_2704)\n    {\n        _2713 = _2690.y < _2579.y;\n    }\n    else\n    {\n        _2713 = _2704;\n    }\n    bool _2722;\n    if (!_2713)\n    {\n        _2722 = _2690.y > _2579.w;\n    }\n    else\n    {\n        _2722 = _2713;\n    }\n    if (_2722)\n    {\n        return 1.0;\n    }\n    float _2728 = _2516.x;\n    float _2730;\n    if (_2728 > 0.0)\n    {\n        _2730 = _2728;\n    }\n    else\n    {\n        _2730 = 1.5 * _2596;\n    }\n    float2 param_9 = _2690;\n    float4 param_10 = _2579;\n    float param_11 = _2672 - (_2730 * (1.0 + (0.5 * _2643)));\n    float param_12 = _2596;\n    float param_13 = 1.0;\n    float param_14 = _2584.z * 0.25;\n    float param_15 = (_2596 * fast::min(_2643, 3.0)) * 0.5;\n    float3 param_16 = float3(1.0, _2675, _2584.z);\n    int param_17 = int(_2511.z + 0.5);\n    float param_18 = _2511.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, fa_shadow_smp, gl_FragCoord, _2043, fa_shadow_tex), fade);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _2043)\n{\n    float _2033;\n    if (i == 0)\n    {\n        _2033 = _2043.fa_shadow_split.x;\n    }\n    else\n    {\n        float _2049;\n        if (i == 1)\n        {\n            _2049 = _2043.fa_shadow_split.y;\n        }\n        else\n        {\n            float _2057;\n            if (i == 2)\n            {\n                _2057 = _2043.fa_shadow_split.z;\n            }\n            else\n            {\n                _2057 = _2043.fa_shadow_split.w;\n            }\n            _2049 = _2057;\n        }\n        _2033 = _2049;\n    }\n    return _2033;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2043, texture2d<float> fa_shadow_tex)\n{\n    float _2319 = fast::max(_2043.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _2324 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _2330 = sqrt(1.0 - (_2324 * _2324));\n    float _2337 = fast::min(_2330 / fast::max(_2324, 0.20000000298023223876953125), 4.0);\n    float _2342;\n    if (_2043.fa_shadow_bias.y > 0.0)\n    {\n        _2342 = _2043.fa_shadow_bias.y;\n    }\n    else\n    {\n        _2342 = 1.5 * _2043.fa_shadow_info[ci].x;\n    }\n    float4 _2367 = _2043.fa_shadow_mat[ci] * float4(world + (n * (_2342 * _2330)), 1.0);\n    float _2374 = _2367.x;\n    bool _2377 = _2374 < _2043.fa_shadow_rect[ci].x;\n    bool _2386;\n    if (!_2377)\n    {\n        _2386 = _2374 > _2043.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2386 = _2377;\n    }\n    bool _2395;\n    if (!_2386)\n    {\n        _2395 = _2367.y < _2043.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2395 = _2386;\n    }\n    bool _2404;\n    if (!_2395)\n    {\n        _2404 = _2367.y > _2043.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2404 = _2395;\n    }\n    bool _2411;\n    if (!_2404)\n    {\n        _2411 = _2367.z > 1.0;\n    }\n    else\n    {\n        _2411 = _2404;\n    }\n    if (_2411)\n    {\n        return -1.0;\n    }\n    float _2419;\n    if (_2043.fa_shadow_bias.x > 0.0)\n    {\n        _2419 = _2043.fa_shadow_bias.x;\n    }\n    else\n    {\n        _2419 = 1.5 * _2043.fa_shadow_info[ci].x;\n    }\n    float2 param = _2367.xy;\n    float4 param_1 = _2043.fa_shadow_rect[ci];\n    float param_2 = _2367.z - ((_2419 * (1.0 + (0.5 * _2337))) / _2319);\n    float param_3 = _2043.fa_shadow_info[ci].x;\n    float param_4 = _2319;\n    float param_5 = _2319 * 0.25;\n    float param_6 = ((_2043.fa_shadow_info[ci].x * fast::min(_2337, 3.0)) * 0.5) / _2319;\n    float3 param_7 = float3(0.0);\n    int param_8 = int(_2043.fa_shadow_cfg.z + 0.5);\n    float param_9 = _2043.fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9, fa_shadow_smp, gl_FragCoord, _2043, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _386, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2043, texture2d<float> fa_shadow_tex)\n{\n    if (_386.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2797 = int(_2043.fa_shadow_cfg.x + 0.5);\n    if (_2797 < 1)\n    {\n        return 1.0;\n    }\n    float _2812 = dot(world - _2043.fa_shadow_eye.xyz, _2043.fa_shadow_fwd.xyz);\n    int param = _2797 - 1;\n    if (_2812 > fa_shadow_split_at(param, _2043))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2824 = _2797 > 1;\n    bool _2831;\n    if (_2824)\n    {\n        _2831 = _2812 > _2043.fa_shadow_split.x;\n    }\n    else\n    {\n        _2831 = _2824;\n    }\n    if (_2831)\n    {\n        ci = 1;\n    }\n    bool _2835 = _2797 > 2;\n    bool _2842;\n    if (_2835)\n    {\n        _2842 = _2812 > _2043.fa_shadow_split.y;\n    }\n    else\n    {\n        _2842 = _2835;\n    }\n    if (_2842)\n    {\n        ci = 2;\n    }\n    bool _2846 = _2797 > 3;\n    bool _2853;\n    if (_2846)\n    {\n        _2853 = _2812 > _2043.fa_shadow_split.z;\n    }\n    else\n    {\n        _2853 = _2846;\n    }\n    if (_2853)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2797)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2879 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_shadow_smp, gl_FragCoord, _2043, fa_shadow_tex);\n        s = _2879;\n        if (_2879 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_2043.fa_shadow_cfg.y > 0.0)\n    {\n        float _2904;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2904 = fa_shadow_split_at(param_5, _2043);\n        }\n        else\n        {\n            _2904 = _2043.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _2923 = _2043.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _2043) - _2904, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2934 = fast::clamp((_2812 - (fa_shadow_split_at(param_7, _2043) - _2923)) / _2923, 0.0, 1.0);\n        if (_2934 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2797)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _2955 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_shadow_smp, gl_FragCoord, _2043, fa_shadow_tex);\n                s2 = _2955;\n                if (_2955 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2934);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _386, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2043, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, _386, fa_shadow_smp, gl_FragCoord, _2043, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_contact_shadow(thread const int& li, thread const float3& world, thread const float3& gn, thread const float3& l, thread const float& dist, constant fa_mesh_fs_params& _386, texture2d<float> fa_light_tex, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2043, texture2d<float> fa_screen_tex)\n{\n    bool _3236 = _386.fa_ct_a.x < 0.5;\n    bool _3243;\n    if (!_3236)\n    {\n        _3243 = _2043.fa_shadow_lcfg.x < 0.5;\n    }\n    else\n    {\n        _3243 = _3236;\n    }\n    if (_3243)\n    {\n        return 1.0;\n    }\n    int param = (int(_2043.fa_shadow_lcfg.x + 0.5) - 1) + li;\n    float4 _3256 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    float _3257 = _3256.y;\n    float len = _3257;\n    if (_3257 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3269 = length(world - _386.fa_camera_pos.xyz);\n    float _3279 = 1.0 - smoothstep(0.5 * _386.fa_ct_b.x, _386.fa_ct_b.x, _3269);\n    if (_3279 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3285 = len;\n    float _3288 = fast::min(_3285, 0.89999997615814208984375 * dist);\n    len = _3288;\n    float _3294 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _3269);\n    float _3299 = _3294 + (0.5 * _3288);\n    float3 _3305 = world + (gn * _3294);\n    float _3307 = fa_shadow_noise(gl_FragCoord);\n    float occ = 0.0;\n    float _3372;\n    for (int k = 0; k < 12; k++)\n    {\n        float _3323 = (float(k) + _3307) * 0.083333335816860198974609375;\n        float3 _3331 = _3305 + (l * (_3323 * len));\n        float4 _3337 = float4(_3331, 1.0);\n        float _3343 = dot(_386.fa_ct_vpw, _3337);\n        if (_3343 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        float2 _3363 = float2(dot(_386.fa_ct_vpx, _3337), dot(_386.fa_ct_vpy, _3337)) / float2(_3343);\n        float _3367 = _3363.x * 0.5;\n        float _3368 = _3367 + 0.5;\n        if (_386.fa_ct_a.y > 0.5)\n        {\n            _3372 = (_3363.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _3372 = 0.5 - (_3363.y * 0.5);\n        }\n        bool _3388 = _3368 < 0.0;\n        bool _3395;\n        if (!_3388)\n        {\n            _3395 = _3368 >= 1.0;\n        }\n        else\n        {\n            _3395 = _3388;\n        }\n        bool _3402;\n        if (!_3395)\n        {\n            _3402 = _3372 < 0.0;\n        }\n        else\n        {\n            _3402 = _3395;\n        }\n        bool _3409;\n        if (!_3402)\n        {\n            _3409 = _3372 >= 1.0;\n        }\n        else\n        {\n            _3409 = _3402;\n        }\n        if (_3409)\n        {\n            break;\n        }\n        float4 _3428 = fa_screen_tex.read(uint2(int2(float2(_3368, _3372) * _386.fa_ct_a.zw)), 0);\n        if (_3428.w < 0.5)\n        {\n            continue;\n        }\n        float _3447 = (dot(_386.fa_ct_fwd.xyz, _3331) + _386.fa_ct_fwd.w) - _3428.x;\n        if ((_3447 > _3294) && (_3447 < _3299))\n        {\n            occ = fast::max(occ, (1.0 - (_3323 * _3323)) * smoothstep(0.0, 0.0500000007450580596923828125, fast::min(fast::min(_3368, 0.5 - _3367), fast::min(_3372, 1.0 - _3372))));\n        }\n    }\n    return 1.0 - (occ * _3279);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, constant fa_mesh_fs_params& _386, texture2d<float> fa_light_tex, sampler fa_shadow_smp, texture2d<float> fa_light_atlas, sampler fa_env_smp, thread float3& fa_light_tint, thread bool& fa_light_is_area, thread float4& gl_FragCoord, constant fa_shadows& _2043, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos, texture2d<float> fa_screen_tex, thread float3& fa_lm)\n{\n    bool _3523 = fa_lm.z > 0.5;\n    bool _3529;\n    if (_3523)\n    {\n        int param = li;\n        _3529 = fa_light_baked(param, _386, fa_light_tex, fa_shadow_smp);\n    }\n    else\n    {\n        _3529 = _3523;\n    }\n    if (_3529)\n    {\n        int param_1 = li;\n        return LightSample{ float3(0.0, 1.0, 0.0), float3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1, _386, fa_light_tex, fa_shadow_smp) + 0.5) };\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _3553 = fa_light_sample_n(param_2, param_3, param_4, _386, fa_light_tex, fa_shadow_smp, fa_light_atlas, fa_env_smp, fa_light_tint, fa_light_is_area);\n    float3 _4678 = _3553.color;\n    float _4680 = _3553.shadow;\n    bool _3556 = _3553.type == 0;\n    if (_3556 && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _3553.direction;\n        float _3567 = fa_shadow_factor(param_5, param_6, _386, fa_shadow_smp, gl_FragCoord, _2043, fa_shadow_tex, fa_world_pos);\n        _4680 = _3567;\n        _4678 *= _3567;\n    }\n    else\n    {\n        bool _3578 = _3553.type != 0;\n        bool _3584;\n        if (_3578)\n        {\n            _3584 = _3553.attenuation > 0.0;\n        }\n        else\n        {\n            _3584 = _3578;\n        }\n        if (_3584)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7, _386);\n            int param_9 = li;\n            float3 param_10 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp).xyz;\n            float3 param_11 = world_pos;\n            float3 param_12 = gn;\n            float3 param_13 = _3553.direction;\n            float _3603 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13, _386, fa_light_tex, fa_shadow_smp, gl_FragCoord, _2043, fa_shadow_tex);\n            _4680 = _3603;\n            _4678 *= _3603;\n        }\n    }\n    bool _3613 = _386.fa_ct_a.x > 0.5;\n    bool _3619;\n    if (_3613)\n    {\n        _3619 = _3553.attenuation > 0.0;\n    }\n    else\n    {\n        _3619 = _3613;\n    }\n    if (_3619)\n    {\n        float _3626;\n        if (_3556)\n        {\n            _3626 = 1000000000.0;\n        }\n        else\n        {\n            _3626 = _3553._distance;\n        }\n        int param_14 = li;\n        float3 param_15 = world_pos;\n        float3 param_16 = gn;\n        float3 param_17 = _3553.direction;\n        float param_18 = _3626;\n        float _3644 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18, _386, fa_light_tex, fa_shadow_smp, gl_FragCoord, _2043, fa_screen_tex);\n        _4680 *= _3644;\n        _4678 *= _3644;\n    }\n    return LightSample{ _3553.direction, _4678, _3553.attenuation, _4680, _3553._distance, _3553.type };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 light(thread const SurfaceInput& i, thread const Surface& s, thread const LightSample& l, constant fa_material& _3673)\n{\n    float _3667;\n    if (dot(s.normal, l.direction) > 0.5)\n    {\n        _3667 = 1.0;\n    }\n    else\n    {\n        _3667 = _3673.dark;\n    }\n    return (s.albedo * l.color) * _3667;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _2043)\n{\n    if (_2043.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _2979 = int(_2043.fa_shadow_cfg.x + 0.5);\n    float _2989 = dot(world - _2043.fa_shadow_eye.xyz, _2043.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _2994 = _2979 > 0;\n    bool _3003;\n    if (_2994)\n    {\n        int param = _2979 - 1;\n        _3003 = _2989 <= fa_shadow_split_at(param, _2043);\n    }\n    else\n    {\n        _3003 = _2994;\n    }\n    if (_3003)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3009 = _2979 > 1;\n        bool _3016;\n        if (_3009)\n        {\n            _3016 = _2989 > _2043.fa_shadow_split.x;\n        }\n        else\n        {\n            _3016 = _3009;\n        }\n        if (_3016)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3022 = _2979 > 2;\n        bool _3029;\n        if (_3022)\n        {\n            _3029 = _2989 > _2043.fa_shadow_split.y;\n        }\n        else\n        {\n            _3029 = _3022;\n        }\n        if (_3029)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3035 = _2979 > 3;\n        bool _3042;\n        if (_3035)\n        {\n            _3042 = _2989 > _2043.fa_shadow_split.z;\n        }\n        else\n        {\n            _3042 = _3035;\n        }\n        if (_3042)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _386 [[buffer(1)]], constant fa_material& _3673 [[buffer(5)]], constant fa_shadows& _2043 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_env_tex [[texture(6)]], texture2d<float> fa_light_tex [[texture(7)]], texture2d<float> fa_light_atlas [[texture(8)]], texture2d<float> fa_lightmap [[texture(9)]], texture2d<float> fa_decal_tex [[texture(10)]], texture2d<float> fa_screen_tex [[texture(11)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _4499 = fast::normalize(in.fa_world_normal);\n    float3 fa_light_tint;\n    bool fa_light_is_area;\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _4499 = -_4499;\n    }\n    float3 _4069 = fast::normalize(_386.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, _386, fa_light_tex, fa_shadow_smp, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _4499, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _4069, short(gl_FrontFacing) };\n    Surface _4077 = fa_standard_surface(param_1, _386, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _4530 = _4077.albedo;\n    float _4531 = _4077.alpha;\n    float3 _4532 = _4077.normal;\n    float _4533 = _4077.metallic;\n    float _4534 = _4077.roughness;\n    float _4535 = _4077.occlusion;\n    float3 _4536 = _4077.emission;\n    float _4537 = _4077.clearcoat;\n    float _4538 = _4077.clearcoat_roughness;\n    float3 _4539 = _4077.sheen_color;\n    float _4540 = _4077.sheen_roughness;\n    float _4541 = _4077.anisotropy;\n    float _4542 = _4077.anisotropy_rotation;\n    float _4543 = _4077.specular;\n    float _4544 = _4077.ior;\n    float3 _4545 = _4077.specular_color;\n    float _4546 = _4077.transmission;\n    float _4547 = _4077.thickness;\n    float3 _4548 = _4077.attenuation_color;\n    float _4549 = _4077.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _4499, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _4069, short(gl_FrontFacing) };\n    Surface param_3 = _4077;\n    surface(param_2, param_3);\n    _4530 = param_3.albedo;\n    _4531 = param_3.alpha;\n    _4532 = param_3.normal;\n    _4533 = param_3.metallic;\n    _4534 = param_3.roughness;\n    _4535 = param_3.occlusion;\n    _4536 = param_3.emission;\n    _4537 = param_3.clearcoat;\n    _4538 = param_3.clearcoat_roughness;\n    _4539 = param_3.sheen_color;\n    _4540 = param_3.sheen_roughness;\n    _4541 = param_3.anisotropy;\n    _4542 = param_3.anisotropy_rotation;\n    _4543 = param_3.specular;\n    _4544 = param_3.ior;\n    _4545 = param_3.specular_color;\n    _4546 = param_3.transmission;\n    _4547 = param_3.thickness;\n    _4548 = param_3.attenuation_color;\n    _4549 = param_3.attenuation_distance;\n    float3 param_4 = in.fa_world_pos;\n    float3 param_5 = _4499;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7, _386, fa_light_tex, fa_shadow_smp, fa_env_smp, fa_decal_tex);\n    _4530 = param_6;\n    _4532 = param_7;\n    float3 result;\n    if (_386.fa_emissive.w > 0.5)\n    {\n        result = _4530;\n    }\n    else\n    {\n        float3 _4116 = _4532;\n        float3 _4117 = fast::normalize(_4116);\n        _4532 = _4117;\n        float3 param_8 = _4117;\n        float3 lit = (fa_indirect_diffuse(param_8, _386, fa_env_smp, fa_env_tex, in.fa_lm, fa_lightmap) * _4530) * _4535;\n        int _4136 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _4136; ln++)\n        {\n            int param_9 = ln;\n            int _4149 = fa_cl_light(param_9, _386, fa_light_tex, fa_shadow_smp, fa_cl_ndir, fa_cl_slot);\n            bool _4152 = in.fa_lm.z > 0.5;\n            bool _4158;\n            if (_4152)\n            {\n                int param_10 = _4149;\n                _4158 = fa_light_baked(param_10, _386, fa_light_tex, fa_shadow_smp);\n            }\n            else\n            {\n                _4158 = _4152;\n            }\n            if (_4158)\n            {\n                continue;\n            }\n            int param_11 = _4149;\n            float3 param_12 = in.fa_world_pos;\n            float3 param_13 = _4499;\n            LightSample _4170 = fa_light_shadowed(param_11, param_12, param_13, _386, fa_light_tex, fa_shadow_smp, fa_light_atlas, fa_env_smp, fa_light_tint, fa_light_is_area, gl_FragCoord, _2043, fa_shadow_tex, in.fa_world_pos, fa_screen_tex, in.fa_lm);\n            SurfaceInput param_14 = SurfaceInput{ in.fa_world_pos, _4499, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _4069, short(gl_FrontFacing) };\n            Surface param_15 = Surface{ _4530, _4531, _4532, _4533, _4534, _4535, _4536, _4537, _4538, _4539, _4540, _4541, _4542, _4543, _4544, _4545, _4546, _4547, _4548, _4549 };\n            LightSample param_16 = _4170;\n            lit += light(param_14, param_15, param_16, _3673);\n        }\n        result = lit;\n    }\n    float3 _4185 = result;\n    float3 _4186 = _4185 + _4536;\n    result = _4186;\n    float3 param_17 = _4186;\n    float3 param_18 = in.fa_world_pos;\n    result = fa_shadow_debug(param_17, param_18, _2043);\n    bool _4195 = _386.fa_fog.w > 0.0;\n    bool _4202;\n    if (!_4195)\n    {\n        _4202 = _386.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _4202 = _4195;\n    }\n    if (_4202)\n    {\n        float3 _4211 = in.fa_world_pos - _386.fa_camera_pos.xyz;\n        float _4217 = dot(_4211, _386.fa_fog_c.xyz);\n        bool _4221 = _386.fa_fog_c.w > 0.5;\n        float _4222;\n        if (_4221)\n        {\n            _4222 = _4217;\n        }\n        else\n        {\n            _4222 = length(_4211);\n        }\n        float _4234 = _4222 - _386.fa_fog_b.x;\n        if (_4234 > 0.0)\n        {\n            float _4243 = _386.fa_fog.w * _4234;\n            float tau = _4243 * _4243;\n            if (_386.fa_fog_b.y > 0.0)\n            {\n                float _4259;\n                if (_4221)\n                {\n                    _4259 = in.fa_world_pos.y - (_386.fa_fog_c.y * _4217);\n                }\n                else\n                {\n                    _4259 = _386.fa_camera_pos.y;\n                }\n                float _4280 = mix(_4259, in.fa_world_pos.y, fast::clamp(_386.fa_fog_b.x / _4222, 0.0, 1.0));\n                float _4284 = in.fa_world_pos.y - _4280;\n                float _4289 = _4280 - _386.fa_fog_b.z;\n                float _4294 = in.fa_world_pos.y - _386.fa_fog_b.z;\n                bool _4297 = _4289 <= 0.0;\n                bool _4298 = !_4297;\n                bool _4304;\n                if (_4298)\n                {\n                    _4304 = _386.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4304 = _4297;\n                }\n                float _4305;\n                if (_4304)\n                {\n                    _4305 = _386.fa_fog_b.y;\n                }\n                else\n                {\n                    _4305 = _386.fa_fog_b.y * exp(-fast::min(_386.fa_fog_b.w * _4289, 80.0));\n                }\n                bool _4332;\n                if (_4298)\n                {\n                    _4332 = _386.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4332 = _4297;\n                }\n                float _4333;\n                if (_4332)\n                {\n                    _4333 = _386.fa_fog_b.y * _4289;\n                }\n                else\n                {\n                    _4333 = (_386.fa_fog_b.y * (1.0 - exp(-fast::min(_386.fa_fog_b.w * _4289, 80.0)))) / _386.fa_fog_b.w;\n                }\n                bool _4358 = _4294 <= 0.0;\n                bool _4365;\n                if (!_4358)\n                {\n                    _4365 = _386.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4365 = _4358;\n                }\n                float _4366;\n                if (_4365)\n                {\n                    _4366 = _386.fa_fog_b.y * _4294;\n                }\n                else\n                {\n                    _4366 = (_386.fa_fog_b.y * (1.0 - exp(-fast::min(_386.fa_fog_b.w * _4294, 80.0)))) / _386.fa_fog_b.w;\n                }\n                float _4393;\n                if (abs(_4284) < 0.001000000047497451305389404296875)\n                {\n                    _4393 = _4305;\n                }\n                else\n                {\n                    _4393 = (_4366 - _4333) / _4284;\n                }\n                tau += (_4234 * fast::max(_4393, 0.0));\n            }\n            result = mix(result, _386.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _4531);\n    return out;\n}\n\n",
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
            "size": 512,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_386",
            "msl_buffer_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2043",
            "msl_buffer_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_3673",
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_prepass_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float& fa_pre_depth, thread float3& fa_pre_r0, thread float3& fa_pre_r1, thread float3& fa_pre_r2, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _131);\n    float3 _302 = _160.world_pos;\n    float4 _171 = float4(_302, 1.0);\n    fa_world_pos = _302;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -(_131.fa_light_vp * _171).z;\n    fa_pre_r0 = float3(_131.fa_light_vp[0].x, _131.fa_light_vp[1].x, _131.fa_light_vp[2].x);\n    fa_pre_r1 = float3(_131.fa_light_vp[0].y, _131.fa_light_vp[1].y, _131.fa_light_vp[2].y);\n    fa_pre_r2 = float3(_131.fa_light_vp[0].z, _131.fa_light_vp[1].z, _131.fa_light_vp[2].z);\n    gl_Position = _131.fa_view_proj * _171;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _131 [[buffer(0)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5, _131, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_pre_depth, out.fa_pre_r0, out.fa_pre_r1, out.fa_pre_r2, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n    float4 fa_ct_a;\n    float4 fa_ct_b;\n    float4 fa_ct_vpx;\n    float4 fa_ct_vpy;\n    float4 fa_ct_vpw;\n    float4 fa_ct_fwd;\n    float4 fa_tr_a;\n    float4 fa_tr_b;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _56;\n    if (bool(i.front_facing))\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = fast::normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = fast::normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (bool(i.front_facing))\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _213, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _213.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _831 = base_t;\n    _831.x = _225.x;\n    _831.y = _225.y;\n    _831.z = _225.z;\n    base_t = _831;\n    float4 _241 = (_831 * _213.fa_base_color) * i.vertex_color;\n    float3 _786 = i.world_normal;\n    if (_213.fa_maps.z > 0.5)\n    {\n        float param_4 = _213.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0) - float3(1.0);\n        float2 _284 = _279.xy * _213.fa_maps.x;\n        float3 _839 = _279;\n        _839.x = _284.x;\n        _839.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _839;\n        _786 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _213.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _842 = mrt;\n    _842.x = _313.x;\n    _842.y = _313.y;\n    _842.z = _313.z;\n    mrt = _842;\n    float4 _343 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _213.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _385 = fa_tex_fix(param_20, param_21);\n    float _791 = _213.fa_layers_a.x;\n    float _792 = _213.fa_layers_a.y;\n    float _795 = _213.fa_layers_a.z;\n    float _794 = _213.fa_layers_b.w;\n    float _797 = _213.fa_layers_c.x;\n    if (_213.fa_layers_c.z > 0.5)\n    {\n        if (mod(_213.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _791 *= _355.y;\n            _792 *= _355.z;\n            _794 *= _343.w;\n        }\n        if (_213.fa_layers_c.z > 1.5)\n        {\n            _795 *= mrt.x;\n            _797 *= mrt.w;\n        }\n    }\n    return Surface{ _241.xyz, _241.w, _786, fast::clamp(_213.fa_pbr.x * _313.z, 0.0, 1.0), fast::clamp(_213.fa_pbr.y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_213.fa_maps.y * (_355.x - 1.0)), _213.fa_emissive.xyz + (_213.fa_model_emissive.xyz * _385), _791, _792, _213.fa_layers_b.xyz, _794, _795, _213.fa_layers_a.w, _797, _213.fa_layers_c.y, _213.fa_layers_d.xyz, _213.fa_tr_a.x, _213.fa_tr_a.y, _213.fa_tr_b.xyz, _213.fa_tr_a.z };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _213 [[buffer(1)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], sampler fa_smp [[sampler(0)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _681 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _681 = -_681;\n    }\n    float3 _538 = fast::normalize(_213.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _681, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _538, short(gl_FrontFacing) };\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _681, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _538, short(gl_FrontFacing) };\n    Surface param_2 = fa_standard_surface(param, fa_tex, fa_smp, _213, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    surface(param_1, param_2);\n    float3 _553 = fast::normalize(param_2.normal);\n    float3 _568 = fast::normalize(float3(dot(in.fa_pre_r0, _553), dot(in.fa_pre_r1, _553), dot(in.fa_pre_r2, _553)));\n    float _580 = _568.z;\n    float2 e = _568.xy / float2((abs(_568.x) + abs(_568.y)) + abs(_580));\n    if (_580 < 0.0)\n    {\n        e = (float2(1.0) - abs(e.yx)) * float2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    out.fa_frag_color = float4(fast::min(in.fa_pre_depth, 60000.0), e, 1.0);\n    return out;\n}\n\n",
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
            "size": 512,
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
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n    float4 fa_ct_a;\n    float4 fa_ct_b;\n    float4 fa_ct_vpx;\n    float4 fa_ct_vpy;\n    float4 fa_ct_vpw;\n    float4 fa_ct_fwd;\n    float4 fa_tr_a;\n    float4 fa_tr_b;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _56;\n    if (bool(i.front_facing))\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = fast::normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = fast::normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (bool(i.front_facing))\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _213, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _213.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _831 = base_t;\n    _831.x = _225.x;\n    _831.y = _225.y;\n    _831.z = _225.z;\n    base_t = _831;\n    float4 _241 = (_831 * _213.fa_base_color) * i.vertex_color;\n    float3 _786 = i.world_normal;\n    if (_213.fa_maps.z > 0.5)\n    {\n        float param_4 = _213.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0) - float3(1.0);\n        float2 _284 = _279.xy * _213.fa_maps.x;\n        float3 _839 = _279;\n        _839.x = _284.x;\n        _839.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _839;\n        _786 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _213.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _842 = mrt;\n    _842.x = _313.x;\n    _842.y = _313.y;\n    _842.z = _313.z;\n    mrt = _842;\n    float4 _343 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _213.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _385 = fa_tex_fix(param_20, param_21);\n    float _791 = _213.fa_layers_a.x;\n    float _792 = _213.fa_layers_a.y;\n    float _795 = _213.fa_layers_a.z;\n    float _794 = _213.fa_layers_b.w;\n    float _797 = _213.fa_layers_c.x;\n    if (_213.fa_layers_c.z > 0.5)\n    {\n        if (mod(_213.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _791 *= _355.y;\n            _792 *= _355.z;\n            _794 *= _343.w;\n        }\n        if (_213.fa_layers_c.z > 1.5)\n        {\n            _795 *= mrt.x;\n            _797 *= mrt.w;\n        }\n    }\n    return Surface{ _241.xyz, _241.w, _786, fast::clamp(_213.fa_pbr.x * _313.z, 0.0, 1.0), fast::clamp(_213.fa_pbr.y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_213.fa_maps.y * (_355.x - 1.0)), _213.fa_emissive.xyz + (_213.fa_model_emissive.xyz * _385), _791, _792, _213.fa_layers_b.xyz, _794, _795, _213.fa_layers_a.w, _797, _213.fa_layers_c.y, _213.fa_layers_d.xyz, _213.fa_tr_a.x, _213.fa_tr_a.y, _213.fa_tr_b.xyz, _213.fa_tr_a.z };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _213 [[buffer(1)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], sampler fa_smp [[sampler(0)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _681 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _681 = -_681;\n    }\n    float3 _538 = fast::normalize(_213.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _681, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _538, short(gl_FrontFacing) };\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _681, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _538, short(gl_FrontFacing) };\n    Surface param_2 = fa_standard_surface(param, fa_tex, fa_smp, _213, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    surface(param_1, param_2);\n    float3 _553 = fast::normalize(param_2.normal);\n    float3 _568 = fast::normalize(float3(dot(in.fa_pre_r0, _553), dot(in.fa_pre_r1, _553), dot(in.fa_pre_r2, _553)));\n    float _580 = _568.z;\n    float2 e = _568.xy / float2((abs(_568.x) + abs(_568.y)) + abs(_580));\n    if (_580 < 0.0)\n    {\n        e = (float2(1.0) - abs(e.yx)) * float2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    out.fa_frag_color = float4(fast::min(in.fa_pre_depth, 60000.0), e, 1.0);\n    return out;\n}\n\n",
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
            "size": 512,
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
