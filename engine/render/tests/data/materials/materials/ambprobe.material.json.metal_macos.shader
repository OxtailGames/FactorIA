{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "70ec7addbf81ecb38af52c4a5f6d5b8f2213a6d2ef6305cbd78b3ce14189ad63",
  "slang": "metal_macos",
  "params": [],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float3 fa_lm [[user(locn5)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _131);\n    float3 _267 = _160.world_pos;\n    fa_world_pos = _267;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = _131.fa_view_proj * float4(_267, 1.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _131 [[buffer(0)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5, _131, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.gl_Position);\n    out.fa_lm = float3(0.0);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n#pragma clang diagnostic ignored \"-Wmissing-braces\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\ntemplate<typename T, size_t Num>\nstruct spvUnsafeArray\n{\n    T elements[Num ? Num : 1];\n    \n    thread T& operator [] (size_t pos) thread\n    {\n        return elements[pos];\n    }\n    constexpr const thread T& operator [] (size_t pos) const thread\n    {\n        return elements[pos];\n    }\n    \n    device T& operator [] (size_t pos) device\n    {\n        return elements[pos];\n    }\n    constexpr const device T& operator [] (size_t pos) const device\n    {\n        return elements[pos];\n    }\n    \n    constexpr const constant T& operator [] (size_t pos) const constant\n    {\n        return elements[pos];\n    }\n    \n    threadgroup T& operator [] (size_t pos) threadgroup\n    {\n        return elements[pos];\n    }\n    constexpr const threadgroup T& operator [] (size_t pos) const threadgroup\n    {\n        return elements[pos];\n    }\n};\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n    float4 fa_ct_a;\n    float4 fa_ct_b;\n    float4 fa_ct_vpx;\n    float4 fa_ct_vpy;\n    float4 fa_ct_vpw;\n    float4 fa_ct_fwd;\n    float4 fa_tr_a;\n    float4 fa_tr_b;\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n    float4 fa_shadow_lcfg;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float3 fa_lm [[user(locn5)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_cluster_texel(thread const float3& world_pos, constant fa_mesh_fs_params& _392, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    bool _1320 = _392.fa_cl_info.x < 0.0;\n    bool _1327;\n    if (!_1320)\n    {\n        _1327 = _392.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _1327 = _1320;\n    }\n    bool _1335;\n    if (!_1327)\n    {\n        _1335 = _392.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _1335 = _1327;\n    }\n    bool _1342;\n    if (!_1335)\n    {\n        _1342 = _392.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _1342 = _1335;\n    }\n    bool _1349;\n    if (!_1342)\n    {\n        _1349 = _392.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _1349 = _1342;\n    }\n    if (_1349)\n    {\n        return float4(0.0);\n    }\n    float4 _1359 = float4(world_pos, 1.0);\n    float _1365 = dot(_392.fa_cl_vpw, _1359);\n    if (!(_1365 > 9.9999999747524270787835121154785e-07))\n    {\n        return float4(0.0);\n    }\n    float2 _1387 = float2(dot(_392.fa_cl_vpx, _1359), dot(_392.fa_cl_vpy, _1359)) / float2(_1365);\n    int _1391 = int(_392.fa_cl_grid.x);\n    int _1395 = int(_392.fa_cl_grid.y);\n    int param = (int(_392.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_392.fa_cl_fwd.xyz, world_pos) + _392.fa_cl_fwd.w, _392.fa_cl_grid.w) / _392.fa_cl_grid.w) * _392.fa_cl_grid.z)), 0, int(_392.fa_cl_info.y) - 1) * _1395) + clamp(int(floor(((_1387.y * 0.5) + 0.5) * _392.fa_cl_grid.y)), 0, _1395 - 1)) * _1391)) + clamp(int(floor(((_1387.x * 0.5) + 0.5) * _392.fa_cl_grid.x)), 0, _1391 - 1);\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, constant fa_mesh_fs_params& _392, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    float3 param = world_pos;\n    float4 _1471 = fa_cluster_texel(param, _392, fa_light_tex, fa_shadow_smp);\n    return int2(int(_1471.x), int(_1471.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, constant fa_mesh_fs_params& _392, texture2d<float> fa_light_tex, sampler fa_shadow_smp, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_392.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _3502 = fa_cluster_lookup(param, _392, fa_light_tex, fa_shadow_smp);\n    fa_cl_slot = _3502.x;\n    fa_cl_local = _3502.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _3705 = fa_linear_to_srgb(param);\n        c = _3705;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _3713 = fa_srgb_to_linear(param_1);\n            c = _3713;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _275;\n    if (bool(i.front_facing))\n    {\n        _275 = i.world_normal;\n    }\n    else\n    {\n        _275 = -i.world_normal;\n    }\n    float3 _299 = fast::normalize(i.world_tangent.xyz - (_275 * dot(_275, i.world_tangent.xyz)));\n    float3 _326 = fast::normalize(((_299 * m.x) + ((cross(_275, _299) * i.world_tangent.w) * m.y)) + (_275 * m.z));\n    float3 _329;\n    if (bool(i.front_facing))\n    {\n        _329 = _326;\n    }\n    else\n    {\n        _329 = -_326;\n    }\n    return _329;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _392, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _392.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _3744 = fa_tex_fix(param_2, param_3);\n    float4 _4866 = base_t;\n    _4866.x = _3744.x;\n    _4866.y = _3744.y;\n    _4866.z = _3744.z;\n    base_t = _4866;\n    float4 _3758 = (_4866 * _392.fa_base_color) * i.vertex_color;\n    float3 _4710 = i.world_normal;\n    if (_392.fa_maps.z > 0.5)\n    {\n        float param_4 = _392.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _3790 = fa_tex_fix(param_6, param_7);\n        float3 _3793 = (_3790 * 2.0) - float3(1.0);\n        float2 _3798 = _3793.xy * _392.fa_maps.x;\n        float3 _4874 = _3793;\n        _4874.x = _3798.x;\n        _4874.y = _3798.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _4874;\n        _4710 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _392.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _3826 = fa_tex_fix(param_12, param_13);\n    float4 _4877 = mrt;\n    _4877.x = _3826.x;\n    _4877.y = _3826.y;\n    _4877.z = _3826.z;\n    mrt = _4877;\n    float4 _3854 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _392.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _3854.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _3865 = fa_tex_fix(param_16, param_17);\n    float param_18 = _392.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _3895 = fa_tex_fix(param_20, param_21);\n    float _4715 = _392.fa_layers_a.x;\n    float _4716 = _392.fa_layers_a.y;\n    float _4719 = _392.fa_layers_a.z;\n    float _4718 = _392.fa_layers_b.w;\n    float _4721 = _392.fa_layers_c.x;\n    if (_392.fa_layers_c.z > 0.5)\n    {\n        if (mod(_392.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _4715 *= _3865.y;\n            _4716 *= _3865.z;\n            _4718 *= _3854.w;\n        }\n        if (_392.fa_layers_c.z > 1.5)\n        {\n            _4719 *= mrt.x;\n            _4721 *= mrt.w;\n        }\n    }\n    return Surface{ _3758.xyz, _3758.w, _4710, fast::clamp(_392.fa_pbr.x * _3826.z, 0.0, 1.0), fast::clamp(_392.fa_pbr.y * _3826.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_392.fa_maps.y * (_3865.x - 1.0)), _392.fa_emissive.xyz + (_392.fa_model_emissive.xyz * _3895), _4715, _4716, _392.fa_layers_b.xyz, _4718, _4719, _392.fa_layers_a.w, _4721, _392.fa_layers_c.y, _392.fa_layers_d.xyz, _392.fa_tr_a.x, _392.fa_tr_a.y, _392.fa_tr_b.xyz, _392.fa_tr_a.z };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_decal_tile(thread const float4& rect, thread const float2& uv, thread const float2& atlas, thread const float2& ddx, thread const float2& ddy, sampler fa_env_smp, texture2d<float> fa_decal_tex)\n{\n    float2 _1551 = rect.zw - rect.xy;\n    float2 _1555 = _1551 * atlas;\n    float2 _1559 = ddx * _1555;\n    float2 _1563 = ddy * _1555;\n    return fa_decal_tex.sample(fa_env_smp, (rect.xy + (fast::clamp(uv, float2(0.0), float2(1.0)) * _1551)), level(fast::clamp(0.5 * log2(fast::max(fast::max(dot(_1559, _1559), dot(_1563, _1563)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_apply_decals(thread const float3& world_pos, thread const float3& geo_normal, thread float3& albedo, thread float3& normal, constant fa_mesh_fs_params& _392, texture2d<float> fa_light_tex, sampler fa_shadow_smp, sampler fa_env_smp, texture2d<float> fa_decal_tex)\n{\n    bool _1596 = _392.fa_counts.y < 0.5;\n    bool _1603;\n    if (!_1596)\n    {\n        _1603 = _392.fa_counts.w < 0.5;\n    }\n    else\n    {\n        _1603 = _1596;\n    }\n    if (_1603)\n    {\n        return;\n    }\n    float3 _1609 = dfdx(world_pos);\n    float3 _1612 = dfdy(world_pos);\n    float3 param = world_pos;\n    float4 _1616 = fa_cluster_texel(param, _392, fa_light_tex, fa_shadow_smp);\n    int _1620 = int(_1616.w);\n    if (_1620 < 1)\n    {\n        return;\n    }\n    int _1630 = int(_392.fa_counts.y + 0.5);\n    int param_1 = _1630;\n    float4 _1634 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float2 _1637 = _1634.yz;\n    int _1641 = int(_1634.w);\n    int param_2 = _1630 + 1;\n    float4 _1646 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float _1647 = _1646.x;\n    int _1653 = int(_392.fa_counts.w + 0.5) - 1;\n    int _1657 = int(_1616.z);\n    float3 _1922;\n    for (int k = 0; k < _1620; k++)\n    {\n        int _1670 = _1657 + k;\n        int param_3 = _1641 + (_1670 >> 2);\n        int _1687 = (_1630 + 2) + (int(fa_light_texel(param_3, fa_light_tex, fa_shadow_smp)[_1670 & 3]) * 7);\n        int param_4 = _1687 + 6;\n        float4 _1692 = fa_light_texel(param_4, fa_light_tex, fa_shadow_smp);\n        if (((int(_1692.w + 0.5) >> _1653) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1687;\n        float4 _1707 = fa_light_texel(param_5, fa_light_tex, fa_shadow_smp);\n        int param_6 = _1687 + 1;\n        float4 _1712 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n        int param_7 = _1687 + 2;\n        float4 _1717 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n        float3 _1720 = _1707.xyz;\n        float _1725 = dot(_1720, world_pos) + _1707.w;\n        float3 _1727 = _1712.xyz;\n        float _1732 = dot(_1727, world_pos) + _1712.w;\n        float3 _1734 = _1717.xyz;\n        float _1739 = dot(_1734, world_pos) + _1717.w;\n        bool _1744 = abs(_1725) > 0.5;\n        bool _1752;\n        if (!_1744)\n        {\n            _1752 = abs(_1732) > 0.5;\n        }\n        else\n        {\n            _1752 = _1744;\n        }\n        bool _1760;\n        if (!_1752)\n        {\n            _1760 = abs(_1739) > 0.5;\n        }\n        else\n        {\n            _1760 = _1752;\n        }\n        if (_1760)\n        {\n            continue;\n        }\n        float _1775 = fast::clamp(dot(geo_normal, fast::normalize(_1734)) * _1692.z, 0.0, 1.0);\n        if (_1775 <= 0.0)\n        {\n            continue;\n        }\n        float _1795 = (fast::clamp((0.5 - abs(_1739)) * 10.0, 0.0, 1.0) * _1775) * _1692.x;\n        float2 _1803 = float2(_1725 + 0.5, 0.5 - _1732);\n        float2 _1813 = float2(dot(_1720, _1609), dot(_1727, _1609));\n        float2 _1823 = float2(dot(_1720, _1612), dot(_1727, _1612));\n        int param_8 = _1687 + 5;\n        float4 _1828 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n        int param_9 = _1687 + 3;\n        float4 _1833 = fa_light_texel(param_9, fa_light_tex, fa_shadow_smp);\n        int param_10 = _1687 + 4;\n        float4 _1838 = fa_light_texel(param_10, fa_light_tex, fa_shadow_smp);\n        float tex_a = 1.0;\n        float3 col = _1828.xyz;\n        bool _1848 = _1833.z > _1833.x;\n        if (_1848)\n        {\n            float4 param_11 = _1833;\n            float2 param_12 = _1803;\n            float2 param_13 = _1637;\n            float2 param_14 = _1813;\n            float2 param_15 = _1823;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15, fa_env_smp, fa_decal_tex);\n            if ((_1647 > 0.5) && (_1647 < 1.5))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1874 = fa_dc_to_linear(param_16);\n                float4 _4798 = tx;\n                _4798.x = _1874.x;\n                _4798.y = _1874.y;\n                _4798.z = _1874.z;\n                tx = _4798;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, float3(fast::clamp((_1795 * tex_a) * _1828.w, 0.0, 1.0)));\n        if (_1838.z > _1838.x)\n        {\n            float4 param_17 = _1838;\n            float2 param_18 = _1803;\n            float2 param_19 = _1637;\n            float2 param_20 = _1813;\n            float2 param_21 = _1823;\n            float4 _1918 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21, fa_env_smp, fa_decal_tex);\n            if (_1647 > 1.5)\n            {\n                float3 param_22 = _1918.xyz;\n                float3 _1928 = fa_dc_to_srgb(param_22);\n                _1922 = _1928;\n            }\n            else\n            {\n                _1922 = _1918.xyz;\n            }\n            float3 _1937 = (_1922 * 2.0) - float3(1.0);\n            float2 _1942 = _1937.xy * _1692.y;\n            float3 _1964 = (fast::normalize(_1720) * _1942.x) + (fast::normalize(_1727) * _1942.y);\n            float3 _1967 = fast::normalize(normal);\n            normal = fast::normalize(mix(_1967, fast::normalize((_1967 * fast::max(_1937.z, 0.0500000007450580596923828125)) + (_1964 - (_1967 * dot(_1967, _1964)))), float3(fast::clamp(_1795 * (_1848 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_sh_coef(thread const int& k, constant fa_mesh_fs_params& _392, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float3 v = fa_env_tex.sample(fa_env_smp, float3(1.0, 1.0 - (float((2 * (k >> 2)) + 1) * 0.25), 1.0 - (float((2 * (k & 3)) + 1) * 0.25)), level(5.0)).xyz;\n    if (_392.fa_env_sky.w > 1.5)\n    {\n        v = (v - float3(0.5)) * 8.0;\n    }\n    return v;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sh_eval(thread const spvUnsafeArray<float3, 9>& c, thread const float3& n)\n{\n    float3 _3162 = fast::max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), float3(0.0));\n    return _3162;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _392, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    if (_392.fa_env_sky.w > 0.5)\n    {\n        spvUnsafeArray<float3, 9> c;\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param, _392, fa_env_smp, fa_env_tex);\n        }\n        spvUnsafeArray<float3, 9> param_1 = c;\n        float3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return _392.fa_ambient.xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_indirect_diffuse(thread const float3& n, constant fa_mesh_fs_params& _392, sampler fa_env_smp, texturecube<float> fa_env_tex, thread float3& fa_lm, texture2d<float> fa_lightmap)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return fa_lightmap.sample(fa_env_smp, fa_lm.xy, level(0.0)).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param, _392, fa_env_smp, fa_env_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 ambient(thread const SurfaceInput& i, thread const Surface& s, thread const float3& ambientColor)\n{\n    return ambientColor;\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, constant fa_mesh_fs_params& _392, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (int(_392.fa_cl_info.x) + int(_392.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, constant fa_mesh_fs_params& _392, texture2d<float> fa_light_tex, sampler fa_shadow_smp, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, _392, fa_light_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_light_base(thread const int& li, constant fa_mesh_fs_params& _392)\n{\n    return li * ((_392.fa_ambient.w > 4.5) ? 8 : 4);\n}\n\nstatic inline __attribute__((always_inline))\nbool fa_light_baked(thread const int& li, constant fa_mesh_fs_params& _392, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li;\n    int param_1 = fa_light_base(param, _392) + 3;\n    return fa_light_texel(param_1, fa_light_tex, fa_shadow_smp).w > 0.5;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_light_type(thread const int& li, constant fa_mesh_fs_params& _392, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li;\n    int param_1 = fa_light_base(param, _392) + 1;\n    return fa_light_texel(param_1, fa_light_tex, fa_shadow_smp).w;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_area_point(thread const float3& c, thread const float3& axis, thread const float3& ru, thread const float3& uu, thread const float& hx, thread const float& hy, thread const float& shape, thread const float3& p, thread const float3& r)\n{\n    bool _570 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        float3 _583 = (c - (ru * hx)) - p;\n        float3 _589 = ru * (2.0 * hx);\n        float _595 = fast::max(dot(_589, _589), 9.9999999392252902907785028219223e-09);\n        float _599 = dot(_583, _589);\n        float t = fast::clamp((-_599) / _595, 0.0, 1.0);\n        if (_570)\n        {\n            float _614 = dot(r, _589);\n            float _620 = _595 - (_614 * _614);\n            if (abs(_620) > (9.9999997473787516355514526367188e-06 * _595))\n            {\n                t = fast::clamp(((dot(r, _583) * _614) - _599) / _620, 0.0, 1.0);\n            }\n        }\n        return (p + _583) + (_589 * t);\n    }\n    float3 q = p;\n    float _652 = dot(r, axis);\n    bool _660;\n    if (_570)\n    {\n        _660 = abs(_652) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _660 = _570;\n    }\n    if (_660)\n    {\n        float _670 = dot(c - p, axis) / _652;\n        if (_670 > 0.0)\n        {\n            q = p + (r * _670);\n        }\n    }\n    float3 _683 = q - c;\n    float2 xy = float2(dot(_683, ru), dot(_683, uu));\n    if (shape > 0.5)\n    {\n        float _698 = length(xy);\n        if (_698 > hx)\n        {\n            xy *= (hx / _698);\n        }\n    }\n    else\n    {\n        xy = fast::clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_atlas_fetch(thread const float2& texel, texture2d<float> fa_light_atlas, sampler fa_env_smp)\n{\n    return fa_light_atlas.sample(fa_env_smp, (texel / float2(int2(fa_light_atlas.get_width(), fa_light_atlas.get_height()))), level(0.0));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_cookie_sample(thread const float2& tile_origin, thread const float2& uv, texture2d<float> fa_light_atlas, sampler fa_env_smp)\n{\n    float2 param = (tile_origin + float2(1.0)) + (fast::clamp(uv, float2(0.0), float2(1.0)) * 254.0);\n    return fa_atlas_fetch(param, fa_light_atlas, fa_env_smp).xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_ies_sample(thread const float2& tile_origin, thread const float3& d, thread const float3& axis, thread const float3& right, thread const float3& up, texture2d<float> fa_light_atlas, sampler fa_env_smp)\n{\n    float _490 = dot(d, right);\n    float _494 = dot(d, up);\n    float _505;\n    if (((_490 * _490) + (_494 * _494)) > 1.0000000133514319600180897396058e-10)\n    {\n        _505 = precise::atan2(_494, _490) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _505 = 0.0;\n    }\n    float2 param = tile_origin + float2(1.0 + ((_505 - floor(_505)) * 64.0), 1.0 + (acos(fast::clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param, fa_light_atlas, fa_env_smp).x;\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cube_face(thread const float3& d)\n{\n    float3 _341 = abs(d);\n    float _343 = _341.x;\n    float _345 = _341.y;\n    bool _346 = _343 >= _345;\n    bool _354;\n    if (_346)\n    {\n        _354 = _343 >= _341.z;\n    }\n    else\n    {\n        _354 = _346;\n    }\n    int _355;\n    if (_354)\n    {\n        _355 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _370;\n        if (_345 >= _341.z)\n        {\n            _370 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _370 = (d.z > 0.0) ? 4 : 5;\n        }\n        _355 = _370;\n    }\n    return _355;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cube_face_basis(thread const int& f, thread float3& fwd, thread float3& up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0, 0.0, 0.0);\n        up = float3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0, 0.0, 0.0);\n            up = float3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0, 1.0, 0.0);\n                up = float3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0, -1.0, 0.0);\n                    up = float3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0, 0.0, 1.0);\n                        up = float3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0, 0.0, -1.0);\n                        up = float3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample_n(thread const int& li, thread const float3& world_pos, thread const float3& n, constant fa_mesh_fs_params& _392, texture2d<float> fa_light_tex, sampler fa_shadow_smp, texture2d<float> fa_light_atlas, sampler fa_env_smp, thread float3& fa_light_tint, thread bool& fa_light_is_area)\n{\n    int param = li;\n    int _736 = fa_light_base(param, _392);\n    bool _740 = _392.fa_ambient.w > 4.5;\n    int param_1 = _736;\n    float4 _744 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    int param_2 = _736 + 1;\n    float4 _749 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float _752 = _749.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = float3(1.0);\n    bool _764 = _740 && (_752 > 2.5);\n    fa_light_is_area = _764;\n    bool _766 = _752 < 0.5;\n    float3 l;\n    if (_766)\n    {\n        l = fast::normalize(_744.xyz);\n        if (_740)\n        {\n            int param_3 = _736 + 6;\n            float4 _780 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            if (_780.z > 0.5)\n            {\n                int param_4 = _736 + 4;\n                float4 _790 = fa_light_texel(param_4, fa_light_tex, fa_shadow_smp);\n                int param_5 = _736 + 5;\n                float4 _795 = fa_light_texel(param_5, fa_light_tex, fa_shadow_smp);\n                float2 param_6 = _780.xy;\n                float2 param_7 = fract(float2(dot(world_pos, _790.xyz) * _790.w, (-dot(world_pos, _795.xyz)) * _795.w) + float2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7, fa_light_atlas, fa_env_smp);\n            }\n        }\n    }\n    else\n    {\n        float3 _825 = _744.xyz;\n        float3 _827 = _825 - world_pos;\n        float3 to_light = _827;\n        float _830 = length(_827);\n        float reach = _830;\n        bool front = true;\n        if (_764)\n        {\n            int param_8 = _736 + 7;\n            reach = fast::max(_830 - fa_light_texel(param_8, fa_light_tex, fa_shadow_smp).w, 0.0);\n            int param_9 = _736 + 4;\n            float4 _854 = fa_light_texel(param_9, fa_light_tex, fa_shadow_smp);\n            int param_10 = _736 + 5;\n            float4 _859 = fa_light_texel(param_10, fa_light_tex, fa_shadow_smp);\n            int param_11 = _736 + 6;\n            float4 _864 = fa_light_texel(param_11, fa_light_tex, fa_shadow_smp);\n            float _865 = _864.w;\n            int param_12 = _736 + 2;\n            float3 _872 = fast::normalize(fa_light_texel(param_12, fa_light_tex, fa_shadow_smp).xyz);\n            bool _874 = _865 > 1.5;\n            bool _882;\n            if (!_874)\n            {\n                _882 = dot(_872, to_light) < 0.0;\n            }\n            else\n            {\n                _882 = _874;\n            }\n            front = _882;\n            float3 r = float3(0.0);\n            float3 _891 = _392.fa_camera_pos.xyz - world_pos;\n            bool _895 = dot(n, n) > 0.5;\n            bool _903;\n            if (_895)\n            {\n                _903 = dot(_891, _891) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _903 = _895;\n            }\n            if (_903)\n            {\n                r = reflect(-fast::normalize(_891), fast::normalize(n));\n            }\n            float3 param_13 = _825;\n            float3 param_14 = _872;\n            float3 param_15 = _854.xyz;\n            float3 param_16 = _859.xyz;\n            float param_17 = _854.w;\n            float param_18 = _859.w;\n            float param_19 = _865;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _939 = length(to_light);\n        dist = _939;\n        l = to_light / float3(fast::max(_939, 9.9999997473787516355514526367188e-05));\n        float _953 = reach / fast::max(_744.w, 0.001000000047497451305389404296875);\n        float _959 = fast::clamp(1.0 - (_953 * _953), 0.0, 1.0);\n        float _961;\n        if (front)\n        {\n            _961 = _959 * _959;\n        }\n        else\n        {\n            _961 = 0.0;\n        }\n        atten = _961;\n        bool _972 = _752 < 2.5;\n        if ((_752 > 1.5) && _972)\n        {\n            int param_22 = _736 + 2;\n            float4 _980 = fa_light_texel(param_22, fa_light_tex, fa_shadow_smp);\n            float _990 = _980.w;\n            int param_23 = _736 + 3;\n            float4 _995 = fa_light_texel(param_23, fa_light_tex, fa_shadow_smp);\n            float _996 = _995.x;\n            float cos_inner = _996;\n            if (_996 > 1.5)\n            {\n                cos_inner = mix(_990, 1.0, 0.25);\n            }\n            atten *= smoothstep(_990, cos_inner, dot(-l, fast::normalize(_980.xyz)));\n        }\n        if (_740 && (_752 < 1.5))\n        {\n            int param_24 = _736 + 6;\n            float4 _1020 = fa_light_texel(param_24, fa_light_tex, fa_shadow_smp);\n            if (_1020.z > 0.5)\n            {\n                float3 _1028 = -to_light;\n                int param_25 = _736 + 4;\n                int param_26 = _736 + 5;\n                float3 _1042 = fa_light_texel(param_25, fa_light_tex, fa_shadow_smp).xyz;\n                float3 _1046 = fa_light_texel(param_26, fa_light_tex, fa_shadow_smp).xyz;\n                float3 _1055 = float3(dot(_1028, _1042), dot(_1028, _1046), dot(_1028, cross(_1042, _1046)));\n                float3 param_27 = _1055;\n                int _1059 = fa_cube_face(param_27);\n                int param_28 = _1059;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1086 = float2(dot(_1055, cross(param_29, param_30)), dot(_1055, param_30)) / float2(fast::max(dot(_1055, param_29), 9.9999997473787516355514526367188e-05));\n                int _1090 = _1059 / 3;\n                float2 param_31 = _1020.xy + (float2(float(_1059 - (_1090 * 3)), float(_1090)) * 256.0);\n                float2 param_32 = float2(0.5 + (0.5 * _1086.x), 0.5 - (0.5 * _1086.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32, fa_light_atlas, fa_env_smp);\n            }\n            int param_33 = _736 + 7;\n            float4 _1120 = fa_light_texel(param_33, fa_light_tex, fa_shadow_smp);\n            if (_1120.z > 0.5)\n            {\n                int param_34 = _736 + 2;\n                int param_35 = _736 + 4;\n                int param_36 = _736 + 5;\n                float2 param_37 = _1120.xy;\n                float3 param_38 = -l;\n                float3 param_39 = fast::normalize(fa_light_texel(param_34, fa_light_tex, fa_shadow_smp).xyz);\n                float3 param_40 = fa_light_texel(param_35, fa_light_tex, fa_shadow_smp).xyz;\n                float3 param_41 = fa_light_texel(param_36, fa_light_tex, fa_shadow_smp).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41, fa_light_atlas, fa_env_smp);\n            }\n        }\n        else\n        {\n            if (_740 && _972)\n            {\n                int param_42 = _736 + 6;\n                float4 _1167 = fa_light_texel(param_42, fa_light_tex, fa_shadow_smp);\n                int param_43 = _736 + 7;\n                float4 _1172 = fa_light_texel(param_43, fa_light_tex, fa_shadow_smp);\n                bool _1175 = _1167.z > 0.5;\n                bool _1182;\n                if (!_1175)\n                {\n                    _1182 = _1172.z > 0.5;\n                }\n                else\n                {\n                    _1182 = _1175;\n                }\n                if (_1182)\n                {\n                    int param_44 = _736 + 2;\n                    float4 _1189 = fa_light_texel(param_44, fa_light_tex, fa_shadow_smp);\n                    float3 _1193 = fast::normalize(_1189.xyz);\n                    int param_45 = _736 + 4;\n                    float4 _1198 = fa_light_texel(param_45, fa_light_tex, fa_shadow_smp);\n                    int param_46 = _736 + 5;\n                    float4 _1203 = fa_light_texel(param_46, fa_light_tex, fa_shadow_smp);\n                    if (_1175)\n                    {\n                        float3 _1211 = -to_light;\n                        float _1218 = _1189.w;\n                        float _1234 = 0.5 / fast::max(dot(_1211, _1193) * (sqrt(fast::max(1.0 - (_1218 * _1218), 0.0)) / fast::max(_1218, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        float2 param_47 = _1167.xy;\n                        float2 param_48 = float2(0.5 + (dot(_1211, _1198.xyz) * _1234), 0.5 - (dot(_1211, _1203.xyz) * _1234));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48, fa_light_atlas, fa_env_smp);\n                    }\n                    if (_1172.z > 0.5)\n                    {\n                        float2 param_49 = _1172.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1193;\n                        float3 param_52 = _1198.xyz;\n                        float3 param_53 = _1203.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53, fa_light_atlas, fa_env_smp);\n                    }\n                }\n            }\n        }\n    }\n    float3 _4664 = _749.xyz * atten;\n    if (_740)\n    {\n        _4664 *= fa_light_tint;\n    }\n    int _1302;\n    if (_766)\n    {\n        _1302 = 0;\n    }\n    else\n    {\n        _1302 = ((_752 > 1.5) && (_752 < 2.5)) ? 2 : 1;\n    }\n    return LightSample{ l, _4664, atten, 1.0, dist, _1302 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_fetch(thread const float2& uv, thread const float4& rect, thread const float3& conv, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2096 = fa_shadow_depth(param, param_1, fa_shadow_smp, fa_shadow_tex);\n    float _2100;\n    if (conv.x < 0.5)\n    {\n        _2100 = _2096;\n    }\n    else\n    {\n        _2100 = (conv.y * conv.z) / (conv.z - (_2096 * (conv.z - conv.y)));\n    }\n    return _2100;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _2027 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_2027), sin(_2027)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_filter(thread const float2& uv, thread const float4& rect, thread const float& zr, thread const float& texel_m, thread const float& unit, thread const float& reach, thread const float& plane, thread const float3& conv, thread const int& mode, thread const float& k, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2049, texture2d<float> fa_shadow_tex)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2, fa_shadow_smp, fa_shadow_tex));\n    }\n    float _2146 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2155;\n        if (k < 0.0)\n        {\n            _2155 = (-k) / fast::max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2155 = k;\n        }\n        float _2175 = fast::clamp((_2155 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2146;\n            float2 _2194 = fa_shadow_vogel(param_3, param_4, param_5) * _2175;\n            float2 param_6 = uv + (_2194 * _2049.fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _2206 = fa_shadow_fetch(param_6, param_7, param_8, fa_shadow_smp, fa_shadow_tex);\n            if (_2206 < (zr - (length(_2194) * plane)))\n            {\n                sum += _2206;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2232 = sum / cnt;\n        float _2242;\n        if (k < 0.0)\n        {\n            _2242 = (-k) / fast::max(_2232, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2242 = k;\n        }\n        radius = fast::clamp(((fast::max(zr - _2232, 0.0) * unit) * _2242) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _2264 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2264; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2264;\n        float param_11 = _2146;\n        float2 _2283 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_2283 * _2049.fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_2283) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14, fa_shadow_smp, fa_shadow_tex));\n    }\n    return lit / float(_2264);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_local(thread const int& li, thread const float3& lpos, thread const float3& world, thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _392, texture2d<float> fa_light_tex, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2049, texture2d<float> fa_shadow_tex)\n{\n    bool _2483 = _392.fa_pbr.z < 0.5;\n    bool _2490;\n    if (!_2483)\n    {\n        _2490 = _2049.fa_shadow_lcfg.x < 0.5;\n    }\n    else\n    {\n        _2490 = _2483;\n    }\n    if (_2490)\n    {\n        return 1.0;\n    }\n    int param = (int(_2049.fa_shadow_lcfg.x + 0.5) - 1) + li;\n    float4 _2503 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    float _2504 = _2503.x;\n    if (_2504 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2513 = int(_2504 + 0.5);\n    int param_1 = _2513;\n    float4 _2517 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    int param_2 = _2513 + 1;\n    float4 _2522 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float fade = 1.0;\n    float _2525 = _2517.y;\n    if (_2525 > 0.0)\n    {\n        float _2542 = 1.0 - smoothstep(0.75 * _2525, _2525, length(world - _2049.fa_shadow_eye.xyz));\n        fade = _2542;\n        if (_2542 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2517.x > 1.5)\n    {\n        float3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2566 = (_2513 + 2) + (face * 6);\n    int param_4 = _2566;\n    int param_5 = _2566 + 1;\n    int param_6 = _2566 + 3;\n    float4 _2580 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n    int param_7 = _2566 + 4;\n    float4 _2585 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n    int param_8 = _2566 + 5;\n    float4 _2590 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n    float _2602 = _2590.x * fast::max(dot(_2580, float4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2607 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _2630 = fast::clamp(dot(n, _2580.xyz), -1.0, 1.0);\n    float _2649 = fast::min(sqrt(1.0 - (_2630 * _2630)) / fast::max(abs(dot(n, world - lpos)) / fast::max(dot(_2580, float4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2652 = _2522.y;\n    float _2654;\n    if (_2652 > 0.0)\n    {\n        _2654 = _2652;\n    }\n    else\n    {\n        _2654 = 1.5 * _2602;\n    }\n    float4 _2674 = float4(world + (n * (_2654 * sqrt(1.0 - (_2607 * _2607)))), 1.0);\n    float _2678 = dot(_2580, _2674);\n    float _2681 = _2590.y;\n    if (_2678 < _2681)\n    {\n        return 1.0;\n    }\n    float2 _2696 = float2(dot(fa_light_texel(param_4, fa_light_tex, fa_shadow_smp), _2674), dot(fa_light_texel(param_5, fa_light_tex, fa_shadow_smp), _2674)) / float2(_2678);\n    float _2698 = _2696.x;\n    bool _2701 = _2698 < _2585.x;\n    bool _2710;\n    if (!_2701)\n    {\n        _2710 = _2698 > _2585.z;\n    }\n    else\n    {\n        _2710 = _2701;\n    }\n    bool _2719;\n    if (!_2710)\n    {\n        _2719 = _2696.y < _2585.y;\n    }\n    else\n    {\n        _2719 = _2710;\n    }\n    bool _2728;\n    if (!_2719)\n    {\n        _2728 = _2696.y > _2585.w;\n    }\n    else\n    {\n        _2728 = _2719;\n    }\n    if (_2728)\n    {\n        return 1.0;\n    }\n    float _2734 = _2522.x;\n    float _2736;\n    if (_2734 > 0.0)\n    {\n        _2736 = _2734;\n    }\n    else\n    {\n        _2736 = 1.5 * _2602;\n    }\n    float2 param_9 = _2696;\n    float4 param_10 = _2585;\n    float param_11 = _2678 - (_2736 * (1.0 + (0.5 * _2649)));\n    float param_12 = _2602;\n    float param_13 = 1.0;\n    float param_14 = _2590.z * 0.25;\n    float param_15 = (_2602 * fast::min(_2649, 3.0)) * 0.5;\n    float3 param_16 = float3(1.0, _2681, _2590.z);\n    int param_17 = int(_2517.z + 0.5);\n    float param_18 = _2517.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, fa_shadow_smp, gl_FragCoord, _2049, fa_shadow_tex), fade);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _2049)\n{\n    float _2039;\n    if (i == 0)\n    {\n        _2039 = _2049.fa_shadow_split.x;\n    }\n    else\n    {\n        float _2055;\n        if (i == 1)\n        {\n            _2055 = _2049.fa_shadow_split.y;\n        }\n        else\n        {\n            float _2063;\n            if (i == 2)\n            {\n                _2063 = _2049.fa_shadow_split.z;\n            }\n            else\n            {\n                _2063 = _2049.fa_shadow_split.w;\n            }\n            _2055 = _2063;\n        }\n        _2039 = _2055;\n    }\n    return _2039;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2049, texture2d<float> fa_shadow_tex)\n{\n    float _2325 = fast::max(_2049.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _2330 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _2336 = sqrt(1.0 - (_2330 * _2330));\n    float _2343 = fast::min(_2336 / fast::max(_2330, 0.20000000298023223876953125), 4.0);\n    float _2348;\n    if (_2049.fa_shadow_bias.y > 0.0)\n    {\n        _2348 = _2049.fa_shadow_bias.y;\n    }\n    else\n    {\n        _2348 = 1.5 * _2049.fa_shadow_info[ci].x;\n    }\n    float4 _2373 = _2049.fa_shadow_mat[ci] * float4(world + (n * (_2348 * _2336)), 1.0);\n    float _2380 = _2373.x;\n    bool _2383 = _2380 < _2049.fa_shadow_rect[ci].x;\n    bool _2392;\n    if (!_2383)\n    {\n        _2392 = _2380 > _2049.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2392 = _2383;\n    }\n    bool _2401;\n    if (!_2392)\n    {\n        _2401 = _2373.y < _2049.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2401 = _2392;\n    }\n    bool _2410;\n    if (!_2401)\n    {\n        _2410 = _2373.y > _2049.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2410 = _2401;\n    }\n    bool _2417;\n    if (!_2410)\n    {\n        _2417 = _2373.z > 1.0;\n    }\n    else\n    {\n        _2417 = _2410;\n    }\n    if (_2417)\n    {\n        return -1.0;\n    }\n    float _2425;\n    if (_2049.fa_shadow_bias.x > 0.0)\n    {\n        _2425 = _2049.fa_shadow_bias.x;\n    }\n    else\n    {\n        _2425 = 1.5 * _2049.fa_shadow_info[ci].x;\n    }\n    float2 param = _2373.xy;\n    float4 param_1 = _2049.fa_shadow_rect[ci];\n    float param_2 = _2373.z - ((_2425 * (1.0 + (0.5 * _2343))) / _2325);\n    float param_3 = _2049.fa_shadow_info[ci].x;\n    float param_4 = _2325;\n    float param_5 = _2325 * 0.25;\n    float param_6 = ((_2049.fa_shadow_info[ci].x * fast::min(_2343, 3.0)) * 0.5) / _2325;\n    float3 param_7 = float3(0.0);\n    int param_8 = int(_2049.fa_shadow_cfg.z + 0.5);\n    float param_9 = _2049.fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9, fa_shadow_smp, gl_FragCoord, _2049, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _392, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2049, texture2d<float> fa_shadow_tex)\n{\n    if (_392.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2803 = int(_2049.fa_shadow_cfg.x + 0.5);\n    if (_2803 < 1)\n    {\n        return 1.0;\n    }\n    float _2818 = dot(world - _2049.fa_shadow_eye.xyz, _2049.fa_shadow_fwd.xyz);\n    int param = _2803 - 1;\n    if (_2818 > fa_shadow_split_at(param, _2049))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2830 = _2803 > 1;\n    bool _2837;\n    if (_2830)\n    {\n        _2837 = _2818 > _2049.fa_shadow_split.x;\n    }\n    else\n    {\n        _2837 = _2830;\n    }\n    if (_2837)\n    {\n        ci = 1;\n    }\n    bool _2841 = _2803 > 2;\n    bool _2848;\n    if (_2841)\n    {\n        _2848 = _2818 > _2049.fa_shadow_split.y;\n    }\n    else\n    {\n        _2848 = _2841;\n    }\n    if (_2848)\n    {\n        ci = 2;\n    }\n    bool _2852 = _2803 > 3;\n    bool _2859;\n    if (_2852)\n    {\n        _2859 = _2818 > _2049.fa_shadow_split.z;\n    }\n    else\n    {\n        _2859 = _2852;\n    }\n    if (_2859)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2803)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2885 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_shadow_smp, gl_FragCoord, _2049, fa_shadow_tex);\n        s = _2885;\n        if (_2885 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_2049.fa_shadow_cfg.y > 0.0)\n    {\n        float _2910;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2910 = fa_shadow_split_at(param_5, _2049);\n        }\n        else\n        {\n            _2910 = _2049.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _2929 = _2049.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _2049) - _2910, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2940 = fast::clamp((_2818 - (fa_shadow_split_at(param_7, _2049) - _2929)) / _2929, 0.0, 1.0);\n        if (_2940 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2803)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _2961 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_shadow_smp, gl_FragCoord, _2049, fa_shadow_tex);\n                s2 = _2961;\n                if (_2961 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2940);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _392, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2049, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, _392, fa_shadow_smp, gl_FragCoord, _2049, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_contact_shadow(thread const int& li, thread const float3& world, thread const float3& gn, thread const float3& l, thread const float& dist, constant fa_mesh_fs_params& _392, texture2d<float> fa_light_tex, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2049, texture2d<float> fa_screen_tex)\n{\n    bool _3242 = _392.fa_ct_a.x < 0.5;\n    bool _3249;\n    if (!_3242)\n    {\n        _3249 = _2049.fa_shadow_lcfg.x < 0.5;\n    }\n    else\n    {\n        _3249 = _3242;\n    }\n    if (_3249)\n    {\n        return 1.0;\n    }\n    int param = (int(_2049.fa_shadow_lcfg.x + 0.5) - 1) + li;\n    float4 _3262 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    float _3263 = _3262.y;\n    float len = _3263;\n    if (_3263 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3275 = length(world - _392.fa_camera_pos.xyz);\n    float _3285 = 1.0 - smoothstep(0.5 * _392.fa_ct_b.x, _392.fa_ct_b.x, _3275);\n    if (_3285 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3291 = len;\n    float _3294 = fast::min(_3291, 0.89999997615814208984375 * dist);\n    len = _3294;\n    float _3300 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _3275);\n    float _3305 = _3300 + (0.5 * _3294);\n    float3 _3311 = world + (gn * _3300);\n    float _3313 = fa_shadow_noise(gl_FragCoord);\n    float occ = 0.0;\n    float _3378;\n    for (int k = 0; k < 12; k++)\n    {\n        float _3329 = (float(k) + _3313) * 0.083333335816860198974609375;\n        float3 _3337 = _3311 + (l * (_3329 * len));\n        float4 _3343 = float4(_3337, 1.0);\n        float _3349 = dot(_392.fa_ct_vpw, _3343);\n        if (_3349 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        float2 _3369 = float2(dot(_392.fa_ct_vpx, _3343), dot(_392.fa_ct_vpy, _3343)) / float2(_3349);\n        float _3373 = _3369.x * 0.5;\n        float _3374 = _3373 + 0.5;\n        if (_392.fa_ct_a.y > 0.5)\n        {\n            _3378 = (_3369.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _3378 = 0.5 - (_3369.y * 0.5);\n        }\n        bool _3394 = _3374 < 0.0;\n        bool _3401;\n        if (!_3394)\n        {\n            _3401 = _3374 >= 1.0;\n        }\n        else\n        {\n            _3401 = _3394;\n        }\n        bool _3408;\n        if (!_3401)\n        {\n            _3408 = _3378 < 0.0;\n        }\n        else\n        {\n            _3408 = _3401;\n        }\n        bool _3415;\n        if (!_3408)\n        {\n            _3415 = _3378 >= 1.0;\n        }\n        else\n        {\n            _3415 = _3408;\n        }\n        if (_3415)\n        {\n            break;\n        }\n        float4 _3434 = fa_screen_tex.read(uint2(int2(float2(_3374, _3378) * _392.fa_ct_a.zw)), 0);\n        if (_3434.w < 0.5)\n        {\n            continue;\n        }\n        float _3453 = (dot(_392.fa_ct_fwd.xyz, _3337) + _392.fa_ct_fwd.w) - _3434.x;\n        if ((_3453 > _3300) && (_3453 < _3305))\n        {\n            occ = fast::max(occ, (1.0 - (_3329 * _3329)) * smoothstep(0.0, 0.0500000007450580596923828125, fast::min(fast::min(_3374, 0.5 - _3373), fast::min(_3378, 1.0 - _3378))));\n        }\n    }\n    return 1.0 - (occ * _3285);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, constant fa_mesh_fs_params& _392, texture2d<float> fa_light_tex, sampler fa_shadow_smp, texture2d<float> fa_light_atlas, sampler fa_env_smp, thread float3& fa_light_tint, thread bool& fa_light_is_area, thread float4& gl_FragCoord, constant fa_shadows& _2049, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos, texture2d<float> fa_screen_tex, thread float3& fa_lm)\n{\n    bool _3529 = fa_lm.z > 0.5;\n    bool _3535;\n    if (_3529)\n    {\n        int param = li;\n        _3535 = fa_light_baked(param, _392, fa_light_tex, fa_shadow_smp);\n    }\n    else\n    {\n        _3535 = _3529;\n    }\n    if (_3535)\n    {\n        int param_1 = li;\n        return LightSample{ float3(0.0, 1.0, 0.0), float3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1, _392, fa_light_tex, fa_shadow_smp) + 0.5) };\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _3559 = fa_light_sample_n(param_2, param_3, param_4, _392, fa_light_tex, fa_shadow_smp, fa_light_atlas, fa_env_smp, fa_light_tint, fa_light_is_area);\n    float3 _4690 = _3559.color;\n    float _4692 = _3559.shadow;\n    bool _3562 = _3559.type == 0;\n    if (_3562 && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _3559.direction;\n        float _3573 = fa_shadow_factor(param_5, param_6, _392, fa_shadow_smp, gl_FragCoord, _2049, fa_shadow_tex, fa_world_pos);\n        _4692 = _3573;\n        _4690 *= _3573;\n    }\n    else\n    {\n        bool _3584 = _3559.type != 0;\n        bool _3590;\n        if (_3584)\n        {\n            _3590 = _3559.attenuation > 0.0;\n        }\n        else\n        {\n            _3590 = _3584;\n        }\n        if (_3590)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7, _392);\n            int param_9 = li;\n            float3 param_10 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp).xyz;\n            float3 param_11 = world_pos;\n            float3 param_12 = gn;\n            float3 param_13 = _3559.direction;\n            float _3609 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13, _392, fa_light_tex, fa_shadow_smp, gl_FragCoord, _2049, fa_shadow_tex);\n            _4692 = _3609;\n            _4690 *= _3609;\n        }\n    }\n    bool _3619 = _392.fa_ct_a.x > 0.5;\n    bool _3625;\n    if (_3619)\n    {\n        _3625 = _3559.attenuation > 0.0;\n    }\n    else\n    {\n        _3625 = _3619;\n    }\n    if (_3625)\n    {\n        float _3632;\n        if (_3562)\n        {\n            _3632 = 1000000000.0;\n        }\n        else\n        {\n            _3632 = _3559._distance;\n        }\n        int param_14 = li;\n        float3 param_15 = world_pos;\n        float3 param_16 = gn;\n        float3 param_17 = _3559.direction;\n        float param_18 = _3632;\n        float _3650 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18, _392, fa_light_tex, fa_shadow_smp, gl_FragCoord, _2049, fa_screen_tex);\n        _4692 *= _3650;\n        _4690 *= _3650;\n    }\n    return LightSample{ _3559.direction, _4690, _3559.attenuation, _4692, _3559._distance, _3559.type };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 light(thread const SurfaceInput& i, thread const Surface& s, thread const LightSample& l)\n{\n    return float3(0.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _2049)\n{\n    if (_2049.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _2985 = int(_2049.fa_shadow_cfg.x + 0.5);\n    float _2995 = dot(world - _2049.fa_shadow_eye.xyz, _2049.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _3000 = _2985 > 0;\n    bool _3009;\n    if (_3000)\n    {\n        int param = _2985 - 1;\n        _3009 = _2995 <= fa_shadow_split_at(param, _2049);\n    }\n    else\n    {\n        _3009 = _3000;\n    }\n    if (_3009)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3015 = _2985 > 1;\n        bool _3022;\n        if (_3015)\n        {\n            _3022 = _2995 > _2049.fa_shadow_split.x;\n        }\n        else\n        {\n            _3022 = _3015;\n        }\n        if (_3022)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3028 = _2985 > 2;\n        bool _3035;\n        if (_3028)\n        {\n            _3035 = _2995 > _2049.fa_shadow_split.y;\n        }\n        else\n        {\n            _3035 = _3028;\n        }\n        if (_3035)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3041 = _2985 > 3;\n        bool _3048;\n        if (_3041)\n        {\n            _3048 = _2995 > _2049.fa_shadow_split.z;\n        }\n        else\n        {\n            _3048 = _3041;\n        }\n        if (_3048)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _392 [[buffer(1)]], constant fa_shadows& _2049 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_env_tex [[texture(6)]], texture2d<float> fa_light_tex [[texture(7)]], texture2d<float> fa_light_atlas [[texture(8)]], texture2d<float> fa_lightmap [[texture(9)]], texture2d<float> fa_decal_tex [[texture(10)]], texture2d<float> fa_screen_tex [[texture(11)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _4482 = fast::normalize(in.fa_world_normal);\n    float3 fa_light_tint;\n    bool fa_light_is_area;\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _4482 = -_4482;\n    }\n    float3 _4052 = fast::normalize(_392.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, _392, fa_light_tex, fa_shadow_smp, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _4482, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _4052, short(gl_FrontFacing) };\n    Surface _4060 = fa_standard_surface(param_1, _392, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _4521 = _4060.albedo;\n    float _4522 = _4060.alpha;\n    float3 _4523 = _4060.normal;\n    float _4524 = _4060.metallic;\n    float _4525 = _4060.roughness;\n    float _4526 = _4060.occlusion;\n    float3 _4527 = _4060.emission;\n    float _4528 = _4060.clearcoat;\n    float _4529 = _4060.clearcoat_roughness;\n    float3 _4530 = _4060.sheen_color;\n    float _4531 = _4060.sheen_roughness;\n    float _4532 = _4060.anisotropy;\n    float _4533 = _4060.anisotropy_rotation;\n    float _4534 = _4060.specular;\n    float _4535 = _4060.ior;\n    float3 _4536 = _4060.specular_color;\n    float _4537 = _4060.transmission;\n    float _4538 = _4060.thickness;\n    float3 _4539 = _4060.attenuation_color;\n    float _4540 = _4060.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _4482, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _4052, short(gl_FrontFacing) };\n    Surface param_3 = _4060;\n    surface(param_2, param_3);\n    _4521 = param_3.albedo;\n    _4522 = param_3.alpha;\n    _4523 = param_3.normal;\n    _4524 = param_3.metallic;\n    _4525 = param_3.roughness;\n    _4526 = param_3.occlusion;\n    _4527 = param_3.emission;\n    _4528 = param_3.clearcoat;\n    _4529 = param_3.clearcoat_roughness;\n    _4530 = param_3.sheen_color;\n    _4531 = param_3.sheen_roughness;\n    _4532 = param_3.anisotropy;\n    _4533 = param_3.anisotropy_rotation;\n    _4534 = param_3.specular;\n    _4535 = param_3.ior;\n    _4536 = param_3.specular_color;\n    _4537 = param_3.transmission;\n    _4538 = param_3.thickness;\n    _4539 = param_3.attenuation_color;\n    _4540 = param_3.attenuation_distance;\n    float3 param_4 = in.fa_world_pos;\n    float3 param_5 = _4482;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7, _392, fa_light_tex, fa_shadow_smp, fa_env_smp, fa_decal_tex);\n    _4521 = param_6;\n    _4523 = param_7;\n    float3 result;\n    if (_392.fa_emissive.w > 0.5)\n    {\n        result = _4521;\n    }\n    else\n    {\n        float3 _4099 = _4523;\n        float3 _4100 = fast::normalize(_4099);\n        _4523 = _4100;\n        float3 param_8 = _4100;\n        SurfaceInput param_9 = SurfaceInput{ in.fa_world_pos, _4482, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _4052, short(gl_FrontFacing) };\n        Surface param_10 = Surface{ _4521, _4522, _4523, _4524, _4525, _4526, _4527, _4528, _4529, _4530, _4531, _4532, _4533, _4534, _4535, _4536, _4537, _4538, _4539, _4540 };\n        float3 param_11 = fa_indirect_diffuse(param_8, _392, fa_env_smp, fa_env_tex, in.fa_lm, fa_lightmap);\n        float3 lit = ambient(param_9, param_10, param_11);\n        int _4119 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _4119; ln++)\n        {\n            int param_12 = ln;\n            int _4132 = fa_cl_light(param_12, _392, fa_light_tex, fa_shadow_smp, fa_cl_ndir, fa_cl_slot);\n            bool _4135 = in.fa_lm.z > 0.5;\n            bool _4141;\n            if (_4135)\n            {\n                int param_13 = _4132;\n                _4141 = fa_light_baked(param_13, _392, fa_light_tex, fa_shadow_smp);\n            }\n            else\n            {\n                _4141 = _4135;\n            }\n            if (_4141)\n            {\n                continue;\n            }\n            int param_14 = _4132;\n            float3 param_15 = in.fa_world_pos;\n            float3 param_16 = _4482;\n            LightSample _4153 = fa_light_shadowed(param_14, param_15, param_16, _392, fa_light_tex, fa_shadow_smp, fa_light_atlas, fa_env_smp, fa_light_tint, fa_light_is_area, gl_FragCoord, _2049, fa_shadow_tex, in.fa_world_pos, fa_screen_tex, in.fa_lm);\n            SurfaceInput param_17 = SurfaceInput{ in.fa_world_pos, _4482, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _4052, short(gl_FrontFacing) };\n            Surface param_18 = Surface{ _4521, _4522, _4523, _4524, _4525, _4526, _4527, _4528, _4529, _4530, _4531, _4532, _4533, _4534, _4535, _4536, _4537, _4538, _4539, _4540 };\n            LightSample param_19 = _4153;\n            lit += light(param_17, param_18, param_19);\n        }\n        result = lit;\n    }\n    float3 _4168 = result;\n    float3 _4169 = _4168 + _4527;\n    result = _4169;\n    float3 param_20 = _4169;\n    float3 param_21 = in.fa_world_pos;\n    result = fa_shadow_debug(param_20, param_21, _2049);\n    bool _4178 = _392.fa_fog.w > 0.0;\n    bool _4185;\n    if (!_4178)\n    {\n        _4185 = _392.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _4185 = _4178;\n    }\n    if (_4185)\n    {\n        float3 _4194 = in.fa_world_pos - _392.fa_camera_pos.xyz;\n        float _4200 = dot(_4194, _392.fa_fog_c.xyz);\n        bool _4204 = _392.fa_fog_c.w > 0.5;\n        float _4205;\n        if (_4204)\n        {\n            _4205 = _4200;\n        }\n        else\n        {\n            _4205 = length(_4194);\n        }\n        float _4217 = _4205 - _392.fa_fog_b.x;\n        if (_4217 > 0.0)\n        {\n            float _4226 = _392.fa_fog.w * _4217;\n            float tau = _4226 * _4226;\n            if (_392.fa_fog_b.y > 0.0)\n            {\n                float _4242;\n                if (_4204)\n                {\n                    _4242 = in.fa_world_pos.y - (_392.fa_fog_c.y * _4200);\n                }\n                else\n                {\n                    _4242 = _392.fa_camera_pos.y;\n                }\n                float _4263 = mix(_4242, in.fa_world_pos.y, fast::clamp(_392.fa_fog_b.x / _4205, 0.0, 1.0));\n                float _4267 = in.fa_world_pos.y - _4263;\n                float _4272 = _4263 - _392.fa_fog_b.z;\n                float _4277 = in.fa_world_pos.y - _392.fa_fog_b.z;\n                bool _4280 = _4272 <= 0.0;\n                bool _4281 = !_4280;\n                bool _4287;\n                if (_4281)\n                {\n                    _4287 = _392.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4287 = _4280;\n                }\n                float _4288;\n                if (_4287)\n                {\n                    _4288 = _392.fa_fog_b.y;\n                }\n                else\n                {\n                    _4288 = _392.fa_fog_b.y * exp(-fast::min(_392.fa_fog_b.w * _4272, 80.0));\n                }\n                bool _4315;\n                if (_4281)\n                {\n                    _4315 = _392.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4315 = _4280;\n                }\n                float _4316;\n                if (_4315)\n                {\n                    _4316 = _392.fa_fog_b.y * _4272;\n                }\n                else\n                {\n                    _4316 = (_392.fa_fog_b.y * (1.0 - exp(-fast::min(_392.fa_fog_b.w * _4272, 80.0)))) / _392.fa_fog_b.w;\n                }\n                bool _4341 = _4277 <= 0.0;\n                bool _4348;\n                if (!_4341)\n                {\n                    _4348 = _392.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4348 = _4341;\n                }\n                float _4349;\n                if (_4348)\n                {\n                    _4349 = _392.fa_fog_b.y * _4277;\n                }\n                else\n                {\n                    _4349 = (_392.fa_fog_b.y * (1.0 - exp(-fast::min(_392.fa_fog_b.w * _4277, 80.0)))) / _392.fa_fog_b.w;\n                }\n                float _4376;\n                if (abs(_4267) < 0.001000000047497451305389404296875)\n                {\n                    _4376 = _4288;\n                }\n                else\n                {\n                    _4376 = (_4349 - _4316) / _4267;\n                }\n                tau += (_4217 * fast::max(_4376, 0.0));\n            }\n            result = mix(result, _392.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _4522);\n    return out;\n}\n\n",
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
            "inst_name": "_392",
            "msl_buffer_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2049",
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
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n#pragma clang diagnostic ignored \"-Wmissing-braces\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\ntemplate<typename T, size_t Num>\nstruct spvUnsafeArray\n{\n    T elements[Num ? Num : 1];\n    \n    thread T& operator [] (size_t pos) thread\n    {\n        return elements[pos];\n    }\n    constexpr const thread T& operator [] (size_t pos) const thread\n    {\n        return elements[pos];\n    }\n    \n    device T& operator [] (size_t pos) device\n    {\n        return elements[pos];\n    }\n    constexpr const device T& operator [] (size_t pos) const device\n    {\n        return elements[pos];\n    }\n    \n    constexpr const constant T& operator [] (size_t pos) const constant\n    {\n        return elements[pos];\n    }\n    \n    threadgroup T& operator [] (size_t pos) threadgroup\n    {\n        return elements[pos];\n    }\n    constexpr const threadgroup T& operator [] (size_t pos) const threadgroup\n    {\n        return elements[pos];\n    }\n};\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n    float4 fa_ct_a;\n    float4 fa_ct_b;\n    float4 fa_ct_vpx;\n    float4 fa_ct_vpy;\n    float4 fa_ct_vpw;\n    float4 fa_ct_fwd;\n    float4 fa_tr_a;\n    float4 fa_tr_b;\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n    float4 fa_shadow_lcfg;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float3 fa_lm [[user(locn5)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_cluster_texel(thread const float3& world_pos, constant fa_mesh_fs_params& _392, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    bool _1320 = _392.fa_cl_info.x < 0.0;\n    bool _1327;\n    if (!_1320)\n    {\n        _1327 = _392.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _1327 = _1320;\n    }\n    bool _1335;\n    if (!_1327)\n    {\n        _1335 = _392.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _1335 = _1327;\n    }\n    bool _1342;\n    if (!_1335)\n    {\n        _1342 = _392.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _1342 = _1335;\n    }\n    bool _1349;\n    if (!_1342)\n    {\n        _1349 = _392.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _1349 = _1342;\n    }\n    if (_1349)\n    {\n        return float4(0.0);\n    }\n    float4 _1359 = float4(world_pos, 1.0);\n    float _1365 = dot(_392.fa_cl_vpw, _1359);\n    if (!(_1365 > 9.9999999747524270787835121154785e-07))\n    {\n        return float4(0.0);\n    }\n    float2 _1387 = float2(dot(_392.fa_cl_vpx, _1359), dot(_392.fa_cl_vpy, _1359)) / float2(_1365);\n    int _1391 = int(_392.fa_cl_grid.x);\n    int _1395 = int(_392.fa_cl_grid.y);\n    int param = (int(_392.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_392.fa_cl_fwd.xyz, world_pos) + _392.fa_cl_fwd.w, _392.fa_cl_grid.w) / _392.fa_cl_grid.w) * _392.fa_cl_grid.z)), 0, int(_392.fa_cl_info.y) - 1) * _1395) + clamp(int(floor(((_1387.y * 0.5) + 0.5) * _392.fa_cl_grid.y)), 0, _1395 - 1)) * _1391)) + clamp(int(floor(((_1387.x * 0.5) + 0.5) * _392.fa_cl_grid.x)), 0, _1391 - 1);\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, constant fa_mesh_fs_params& _392, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    float3 param = world_pos;\n    float4 _1471 = fa_cluster_texel(param, _392, fa_light_tex, fa_shadow_smp);\n    return int2(int(_1471.x), int(_1471.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, constant fa_mesh_fs_params& _392, texture2d<float> fa_light_tex, sampler fa_shadow_smp, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_392.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _3502 = fa_cluster_lookup(param, _392, fa_light_tex, fa_shadow_smp);\n    fa_cl_slot = _3502.x;\n    fa_cl_local = _3502.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _3705 = fa_linear_to_srgb(param);\n        c = _3705;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _3713 = fa_srgb_to_linear(param_1);\n            c = _3713;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _275;\n    if (bool(i.front_facing))\n    {\n        _275 = i.world_normal;\n    }\n    else\n    {\n        _275 = -i.world_normal;\n    }\n    float3 _299 = fast::normalize(i.world_tangent.xyz - (_275 * dot(_275, i.world_tangent.xyz)));\n    float3 _326 = fast::normalize(((_299 * m.x) + ((cross(_275, _299) * i.world_tangent.w) * m.y)) + (_275 * m.z));\n    float3 _329;\n    if (bool(i.front_facing))\n    {\n        _329 = _326;\n    }\n    else\n    {\n        _329 = -_326;\n    }\n    return _329;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _392, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _392.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _3744 = fa_tex_fix(param_2, param_3);\n    float4 _4866 = base_t;\n    _4866.x = _3744.x;\n    _4866.y = _3744.y;\n    _4866.z = _3744.z;\n    base_t = _4866;\n    float4 _3758 = (_4866 * _392.fa_base_color) * i.vertex_color;\n    float3 _4710 = i.world_normal;\n    if (_392.fa_maps.z > 0.5)\n    {\n        float param_4 = _392.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _3790 = fa_tex_fix(param_6, param_7);\n        float3 _3793 = (_3790 * 2.0) - float3(1.0);\n        float2 _3798 = _3793.xy * _392.fa_maps.x;\n        float3 _4874 = _3793;\n        _4874.x = _3798.x;\n        _4874.y = _3798.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _4874;\n        _4710 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _392.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _3826 = fa_tex_fix(param_12, param_13);\n    float4 _4877 = mrt;\n    _4877.x = _3826.x;\n    _4877.y = _3826.y;\n    _4877.z = _3826.z;\n    mrt = _4877;\n    float4 _3854 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _392.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _3854.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _3865 = fa_tex_fix(param_16, param_17);\n    float param_18 = _392.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _3895 = fa_tex_fix(param_20, param_21);\n    float _4715 = _392.fa_layers_a.x;\n    float _4716 = _392.fa_layers_a.y;\n    float _4719 = _392.fa_layers_a.z;\n    float _4718 = _392.fa_layers_b.w;\n    float _4721 = _392.fa_layers_c.x;\n    if (_392.fa_layers_c.z > 0.5)\n    {\n        if (mod(_392.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _4715 *= _3865.y;\n            _4716 *= _3865.z;\n            _4718 *= _3854.w;\n        }\n        if (_392.fa_layers_c.z > 1.5)\n        {\n            _4719 *= mrt.x;\n            _4721 *= mrt.w;\n        }\n    }\n    return Surface{ _3758.xyz, _3758.w, _4710, fast::clamp(_392.fa_pbr.x * _3826.z, 0.0, 1.0), fast::clamp(_392.fa_pbr.y * _3826.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_392.fa_maps.y * (_3865.x - 1.0)), _392.fa_emissive.xyz + (_392.fa_model_emissive.xyz * _3895), _4715, _4716, _392.fa_layers_b.xyz, _4718, _4719, _392.fa_layers_a.w, _4721, _392.fa_layers_c.y, _392.fa_layers_d.xyz, _392.fa_tr_a.x, _392.fa_tr_a.y, _392.fa_tr_b.xyz, _392.fa_tr_a.z };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_decal_tile(thread const float4& rect, thread const float2& uv, thread const float2& atlas, thread const float2& ddx, thread const float2& ddy, sampler fa_env_smp, texture2d<float> fa_decal_tex)\n{\n    float2 _1551 = rect.zw - rect.xy;\n    float2 _1555 = _1551 * atlas;\n    float2 _1559 = ddx * _1555;\n    float2 _1563 = ddy * _1555;\n    return fa_decal_tex.sample(fa_env_smp, (rect.xy + (fast::clamp(uv, float2(0.0), float2(1.0)) * _1551)), level(fast::clamp(0.5 * log2(fast::max(fast::max(dot(_1559, _1559), dot(_1563, _1563)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_apply_decals(thread const float3& world_pos, thread const float3& geo_normal, thread float3& albedo, thread float3& normal, constant fa_mesh_fs_params& _392, texture2d<float> fa_light_tex, sampler fa_shadow_smp, sampler fa_env_smp, texture2d<float> fa_decal_tex)\n{\n    bool _1596 = _392.fa_counts.y < 0.5;\n    bool _1603;\n    if (!_1596)\n    {\n        _1603 = _392.fa_counts.w < 0.5;\n    }\n    else\n    {\n        _1603 = _1596;\n    }\n    if (_1603)\n    {\n        return;\n    }\n    float3 _1609 = dfdx(world_pos);\n    float3 _1612 = dfdy(world_pos);\n    float3 param = world_pos;\n    float4 _1616 = fa_cluster_texel(param, _392, fa_light_tex, fa_shadow_smp);\n    int _1620 = int(_1616.w);\n    if (_1620 < 1)\n    {\n        return;\n    }\n    int _1630 = int(_392.fa_counts.y + 0.5);\n    int param_1 = _1630;\n    float4 _1634 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float2 _1637 = _1634.yz;\n    int _1641 = int(_1634.w);\n    int param_2 = _1630 + 1;\n    float4 _1646 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float _1647 = _1646.x;\n    int _1653 = int(_392.fa_counts.w + 0.5) - 1;\n    int _1657 = int(_1616.z);\n    float3 _1922;\n    for (int k = 0; k < _1620; k++)\n    {\n        int _1670 = _1657 + k;\n        int param_3 = _1641 + (_1670 >> 2);\n        int _1687 = (_1630 + 2) + (int(fa_light_texel(param_3, fa_light_tex, fa_shadow_smp)[_1670 & 3]) * 7);\n        int param_4 = _1687 + 6;\n        float4 _1692 = fa_light_texel(param_4, fa_light_tex, fa_shadow_smp);\n        if (((int(_1692.w + 0.5) >> _1653) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1687;\n        float4 _1707 = fa_light_texel(param_5, fa_light_tex, fa_shadow_smp);\n        int param_6 = _1687 + 1;\n        float4 _1712 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n        int param_7 = _1687 + 2;\n        float4 _1717 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n        float3 _1720 = _1707.xyz;\n        float _1725 = dot(_1720, world_pos) + _1707.w;\n        float3 _1727 = _1712.xyz;\n        float _1732 = dot(_1727, world_pos) + _1712.w;\n        float3 _1734 = _1717.xyz;\n        float _1739 = dot(_1734, world_pos) + _1717.w;\n        bool _1744 = abs(_1725) > 0.5;\n        bool _1752;\n        if (!_1744)\n        {\n            _1752 = abs(_1732) > 0.5;\n        }\n        else\n        {\n            _1752 = _1744;\n        }\n        bool _1760;\n        if (!_1752)\n        {\n            _1760 = abs(_1739) > 0.5;\n        }\n        else\n        {\n            _1760 = _1752;\n        }\n        if (_1760)\n        {\n            continue;\n        }\n        float _1775 = fast::clamp(dot(geo_normal, fast::normalize(_1734)) * _1692.z, 0.0, 1.0);\n        if (_1775 <= 0.0)\n        {\n            continue;\n        }\n        float _1795 = (fast::clamp((0.5 - abs(_1739)) * 10.0, 0.0, 1.0) * _1775) * _1692.x;\n        float2 _1803 = float2(_1725 + 0.5, 0.5 - _1732);\n        float2 _1813 = float2(dot(_1720, _1609), dot(_1727, _1609));\n        float2 _1823 = float2(dot(_1720, _1612), dot(_1727, _1612));\n        int param_8 = _1687 + 5;\n        float4 _1828 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n        int param_9 = _1687 + 3;\n        float4 _1833 = fa_light_texel(param_9, fa_light_tex, fa_shadow_smp);\n        int param_10 = _1687 + 4;\n        float4 _1838 = fa_light_texel(param_10, fa_light_tex, fa_shadow_smp);\n        float tex_a = 1.0;\n        float3 col = _1828.xyz;\n        bool _1848 = _1833.z > _1833.x;\n        if (_1848)\n        {\n            float4 param_11 = _1833;\n            float2 param_12 = _1803;\n            float2 param_13 = _1637;\n            float2 param_14 = _1813;\n            float2 param_15 = _1823;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15, fa_env_smp, fa_decal_tex);\n            if ((_1647 > 0.5) && (_1647 < 1.5))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1874 = fa_dc_to_linear(param_16);\n                float4 _4798 = tx;\n                _4798.x = _1874.x;\n                _4798.y = _1874.y;\n                _4798.z = _1874.z;\n                tx = _4798;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, float3(fast::clamp((_1795 * tex_a) * _1828.w, 0.0, 1.0)));\n        if (_1838.z > _1838.x)\n        {\n            float4 param_17 = _1838;\n            float2 param_18 = _1803;\n            float2 param_19 = _1637;\n            float2 param_20 = _1813;\n            float2 param_21 = _1823;\n            float4 _1918 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21, fa_env_smp, fa_decal_tex);\n            if (_1647 > 1.5)\n            {\n                float3 param_22 = _1918.xyz;\n                float3 _1928 = fa_dc_to_srgb(param_22);\n                _1922 = _1928;\n            }\n            else\n            {\n                _1922 = _1918.xyz;\n            }\n            float3 _1937 = (_1922 * 2.0) - float3(1.0);\n            float2 _1942 = _1937.xy * _1692.y;\n            float3 _1964 = (fast::normalize(_1720) * _1942.x) + (fast::normalize(_1727) * _1942.y);\n            float3 _1967 = fast::normalize(normal);\n            normal = fast::normalize(mix(_1967, fast::normalize((_1967 * fast::max(_1937.z, 0.0500000007450580596923828125)) + (_1964 - (_1967 * dot(_1967, _1964)))), float3(fast::clamp(_1795 * (_1848 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_sh_coef(thread const int& k, constant fa_mesh_fs_params& _392, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float3 v = fa_env_tex.sample(fa_env_smp, float3(1.0, 1.0 - (float((2 * (k >> 2)) + 1) * 0.25), 1.0 - (float((2 * (k & 3)) + 1) * 0.25)), level(5.0)).xyz;\n    if (_392.fa_env_sky.w > 1.5)\n    {\n        v = (v - float3(0.5)) * 8.0;\n    }\n    return v;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sh_eval(thread const spvUnsafeArray<float3, 9>& c, thread const float3& n)\n{\n    float3 _3162 = fast::max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), float3(0.0));\n    return _3162;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _392, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    if (_392.fa_env_sky.w > 0.5)\n    {\n        spvUnsafeArray<float3, 9> c;\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param, _392, fa_env_smp, fa_env_tex);\n        }\n        spvUnsafeArray<float3, 9> param_1 = c;\n        float3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return _392.fa_ambient.xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_indirect_diffuse(thread const float3& n, constant fa_mesh_fs_params& _392, sampler fa_env_smp, texturecube<float> fa_env_tex, thread float3& fa_lm, texture2d<float> fa_lightmap)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return fa_lightmap.sample(fa_env_smp, fa_lm.xy, level(0.0)).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param, _392, fa_env_smp, fa_env_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 ambient(thread const SurfaceInput& i, thread const Surface& s, thread const float3& ambientColor)\n{\n    return ambientColor;\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, constant fa_mesh_fs_params& _392, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (int(_392.fa_cl_info.x) + int(_392.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, constant fa_mesh_fs_params& _392, texture2d<float> fa_light_tex, sampler fa_shadow_smp, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, _392, fa_light_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_light_base(thread const int& li, constant fa_mesh_fs_params& _392)\n{\n    return li * ((_392.fa_ambient.w > 4.5) ? 8 : 4);\n}\n\nstatic inline __attribute__((always_inline))\nbool fa_light_baked(thread const int& li, constant fa_mesh_fs_params& _392, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li;\n    int param_1 = fa_light_base(param, _392) + 3;\n    return fa_light_texel(param_1, fa_light_tex, fa_shadow_smp).w > 0.5;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_light_type(thread const int& li, constant fa_mesh_fs_params& _392, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li;\n    int param_1 = fa_light_base(param, _392) + 1;\n    return fa_light_texel(param_1, fa_light_tex, fa_shadow_smp).w;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_area_point(thread const float3& c, thread const float3& axis, thread const float3& ru, thread const float3& uu, thread const float& hx, thread const float& hy, thread const float& shape, thread const float3& p, thread const float3& r)\n{\n    bool _570 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        float3 _583 = (c - (ru * hx)) - p;\n        float3 _589 = ru * (2.0 * hx);\n        float _595 = fast::max(dot(_589, _589), 9.9999999392252902907785028219223e-09);\n        float _599 = dot(_583, _589);\n        float t = fast::clamp((-_599) / _595, 0.0, 1.0);\n        if (_570)\n        {\n            float _614 = dot(r, _589);\n            float _620 = _595 - (_614 * _614);\n            if (abs(_620) > (9.9999997473787516355514526367188e-06 * _595))\n            {\n                t = fast::clamp(((dot(r, _583) * _614) - _599) / _620, 0.0, 1.0);\n            }\n        }\n        return (p + _583) + (_589 * t);\n    }\n    float3 q = p;\n    float _652 = dot(r, axis);\n    bool _660;\n    if (_570)\n    {\n        _660 = abs(_652) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _660 = _570;\n    }\n    if (_660)\n    {\n        float _670 = dot(c - p, axis) / _652;\n        if (_670 > 0.0)\n        {\n            q = p + (r * _670);\n        }\n    }\n    float3 _683 = q - c;\n    float2 xy = float2(dot(_683, ru), dot(_683, uu));\n    if (shape > 0.5)\n    {\n        float _698 = length(xy);\n        if (_698 > hx)\n        {\n            xy *= (hx / _698);\n        }\n    }\n    else\n    {\n        xy = fast::clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_atlas_fetch(thread const float2& texel, texture2d<float> fa_light_atlas, sampler fa_env_smp)\n{\n    return fa_light_atlas.sample(fa_env_smp, (texel / float2(int2(fa_light_atlas.get_width(), fa_light_atlas.get_height()))), level(0.0));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_cookie_sample(thread const float2& tile_origin, thread const float2& uv, texture2d<float> fa_light_atlas, sampler fa_env_smp)\n{\n    float2 param = (tile_origin + float2(1.0)) + (fast::clamp(uv, float2(0.0), float2(1.0)) * 254.0);\n    return fa_atlas_fetch(param, fa_light_atlas, fa_env_smp).xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_ies_sample(thread const float2& tile_origin, thread const float3& d, thread const float3& axis, thread const float3& right, thread const float3& up, texture2d<float> fa_light_atlas, sampler fa_env_smp)\n{\n    float _490 = dot(d, right);\n    float _494 = dot(d, up);\n    float _505;\n    if (((_490 * _490) + (_494 * _494)) > 1.0000000133514319600180897396058e-10)\n    {\n        _505 = precise::atan2(_494, _490) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _505 = 0.0;\n    }\n    float2 param = tile_origin + float2(1.0 + ((_505 - floor(_505)) * 64.0), 1.0 + (acos(fast::clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param, fa_light_atlas, fa_env_smp).x;\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cube_face(thread const float3& d)\n{\n    float3 _341 = abs(d);\n    float _343 = _341.x;\n    float _345 = _341.y;\n    bool _346 = _343 >= _345;\n    bool _354;\n    if (_346)\n    {\n        _354 = _343 >= _341.z;\n    }\n    else\n    {\n        _354 = _346;\n    }\n    int _355;\n    if (_354)\n    {\n        _355 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _370;\n        if (_345 >= _341.z)\n        {\n            _370 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _370 = (d.z > 0.0) ? 4 : 5;\n        }\n        _355 = _370;\n    }\n    return _355;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cube_face_basis(thread const int& f, thread float3& fwd, thread float3& up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0, 0.0, 0.0);\n        up = float3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0, 0.0, 0.0);\n            up = float3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0, 1.0, 0.0);\n                up = float3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0, -1.0, 0.0);\n                    up = float3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0, 0.0, 1.0);\n                        up = float3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0, 0.0, -1.0);\n                        up = float3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample_n(thread const int& li, thread const float3& world_pos, thread const float3& n, constant fa_mesh_fs_params& _392, texture2d<float> fa_light_tex, sampler fa_shadow_smp, texture2d<float> fa_light_atlas, sampler fa_env_smp, thread float3& fa_light_tint, thread bool& fa_light_is_area)\n{\n    int param = li;\n    int _736 = fa_light_base(param, _392);\n    bool _740 = _392.fa_ambient.w > 4.5;\n    int param_1 = _736;\n    float4 _744 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    int param_2 = _736 + 1;\n    float4 _749 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float _752 = _749.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = float3(1.0);\n    bool _764 = _740 && (_752 > 2.5);\n    fa_light_is_area = _764;\n    bool _766 = _752 < 0.5;\n    float3 l;\n    if (_766)\n    {\n        l = fast::normalize(_744.xyz);\n        if (_740)\n        {\n            int param_3 = _736 + 6;\n            float4 _780 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            if (_780.z > 0.5)\n            {\n                int param_4 = _736 + 4;\n                float4 _790 = fa_light_texel(param_4, fa_light_tex, fa_shadow_smp);\n                int param_5 = _736 + 5;\n                float4 _795 = fa_light_texel(param_5, fa_light_tex, fa_shadow_smp);\n                float2 param_6 = _780.xy;\n                float2 param_7 = fract(float2(dot(world_pos, _790.xyz) * _790.w, (-dot(world_pos, _795.xyz)) * _795.w) + float2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7, fa_light_atlas, fa_env_smp);\n            }\n        }\n    }\n    else\n    {\n        float3 _825 = _744.xyz;\n        float3 _827 = _825 - world_pos;\n        float3 to_light = _827;\n        float _830 = length(_827);\n        float reach = _830;\n        bool front = true;\n        if (_764)\n        {\n            int param_8 = _736 + 7;\n            reach = fast::max(_830 - fa_light_texel(param_8, fa_light_tex, fa_shadow_smp).w, 0.0);\n            int param_9 = _736 + 4;\n            float4 _854 = fa_light_texel(param_9, fa_light_tex, fa_shadow_smp);\n            int param_10 = _736 + 5;\n            float4 _859 = fa_light_texel(param_10, fa_light_tex, fa_shadow_smp);\n            int param_11 = _736 + 6;\n            float4 _864 = fa_light_texel(param_11, fa_light_tex, fa_shadow_smp);\n            float _865 = _864.w;\n            int param_12 = _736 + 2;\n            float3 _872 = fast::normalize(fa_light_texel(param_12, fa_light_tex, fa_shadow_smp).xyz);\n            bool _874 = _865 > 1.5;\n            bool _882;\n            if (!_874)\n            {\n                _882 = dot(_872, to_light) < 0.0;\n            }\n            else\n            {\n                _882 = _874;\n            }\n            front = _882;\n            float3 r = float3(0.0);\n            float3 _891 = _392.fa_camera_pos.xyz - world_pos;\n            bool _895 = dot(n, n) > 0.5;\n            bool _903;\n            if (_895)\n            {\n                _903 = dot(_891, _891) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _903 = _895;\n            }\n            if (_903)\n            {\n                r = reflect(-fast::normalize(_891), fast::normalize(n));\n            }\n            float3 param_13 = _825;\n            float3 param_14 = _872;\n            float3 param_15 = _854.xyz;\n            float3 param_16 = _859.xyz;\n            float param_17 = _854.w;\n            float param_18 = _859.w;\n            float param_19 = _865;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _939 = length(to_light);\n        dist = _939;\n        l = to_light / float3(fast::max(_939, 9.9999997473787516355514526367188e-05));\n        float _953 = reach / fast::max(_744.w, 0.001000000047497451305389404296875);\n        float _959 = fast::clamp(1.0 - (_953 * _953), 0.0, 1.0);\n        float _961;\n        if (front)\n        {\n            _961 = _959 * _959;\n        }\n        else\n        {\n            _961 = 0.0;\n        }\n        atten = _961;\n        bool _972 = _752 < 2.5;\n        if ((_752 > 1.5) && _972)\n        {\n            int param_22 = _736 + 2;\n            float4 _980 = fa_light_texel(param_22, fa_light_tex, fa_shadow_smp);\n            float _990 = _980.w;\n            int param_23 = _736 + 3;\n            float4 _995 = fa_light_texel(param_23, fa_light_tex, fa_shadow_smp);\n            float _996 = _995.x;\n            float cos_inner = _996;\n            if (_996 > 1.5)\n            {\n                cos_inner = mix(_990, 1.0, 0.25);\n            }\n            atten *= smoothstep(_990, cos_inner, dot(-l, fast::normalize(_980.xyz)));\n        }\n        if (_740 && (_752 < 1.5))\n        {\n            int param_24 = _736 + 6;\n            float4 _1020 = fa_light_texel(param_24, fa_light_tex, fa_shadow_smp);\n            if (_1020.z > 0.5)\n            {\n                float3 _1028 = -to_light;\n                int param_25 = _736 + 4;\n                int param_26 = _736 + 5;\n                float3 _1042 = fa_light_texel(param_25, fa_light_tex, fa_shadow_smp).xyz;\n                float3 _1046 = fa_light_texel(param_26, fa_light_tex, fa_shadow_smp).xyz;\n                float3 _1055 = float3(dot(_1028, _1042), dot(_1028, _1046), dot(_1028, cross(_1042, _1046)));\n                float3 param_27 = _1055;\n                int _1059 = fa_cube_face(param_27);\n                int param_28 = _1059;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1086 = float2(dot(_1055, cross(param_29, param_30)), dot(_1055, param_30)) / float2(fast::max(dot(_1055, param_29), 9.9999997473787516355514526367188e-05));\n                int _1090 = _1059 / 3;\n                float2 param_31 = _1020.xy + (float2(float(_1059 - (_1090 * 3)), float(_1090)) * 256.0);\n                float2 param_32 = float2(0.5 + (0.5 * _1086.x), 0.5 - (0.5 * _1086.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32, fa_light_atlas, fa_env_smp);\n            }\n            int param_33 = _736 + 7;\n            float4 _1120 = fa_light_texel(param_33, fa_light_tex, fa_shadow_smp);\n            if (_1120.z > 0.5)\n            {\n                int param_34 = _736 + 2;\n                int param_35 = _736 + 4;\n                int param_36 = _736 + 5;\n                float2 param_37 = _1120.xy;\n                float3 param_38 = -l;\n                float3 param_39 = fast::normalize(fa_light_texel(param_34, fa_light_tex, fa_shadow_smp).xyz);\n                float3 param_40 = fa_light_texel(param_35, fa_light_tex, fa_shadow_smp).xyz;\n                float3 param_41 = fa_light_texel(param_36, fa_light_tex, fa_shadow_smp).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41, fa_light_atlas, fa_env_smp);\n            }\n        }\n        else\n        {\n            if (_740 && _972)\n            {\n                int param_42 = _736 + 6;\n                float4 _1167 = fa_light_texel(param_42, fa_light_tex, fa_shadow_smp);\n                int param_43 = _736 + 7;\n                float4 _1172 = fa_light_texel(param_43, fa_light_tex, fa_shadow_smp);\n                bool _1175 = _1167.z > 0.5;\n                bool _1182;\n                if (!_1175)\n                {\n                    _1182 = _1172.z > 0.5;\n                }\n                else\n                {\n                    _1182 = _1175;\n                }\n                if (_1182)\n                {\n                    int param_44 = _736 + 2;\n                    float4 _1189 = fa_light_texel(param_44, fa_light_tex, fa_shadow_smp);\n                    float3 _1193 = fast::normalize(_1189.xyz);\n                    int param_45 = _736 + 4;\n                    float4 _1198 = fa_light_texel(param_45, fa_light_tex, fa_shadow_smp);\n                    int param_46 = _736 + 5;\n                    float4 _1203 = fa_light_texel(param_46, fa_light_tex, fa_shadow_smp);\n                    if (_1175)\n                    {\n                        float3 _1211 = -to_light;\n                        float _1218 = _1189.w;\n                        float _1234 = 0.5 / fast::max(dot(_1211, _1193) * (sqrt(fast::max(1.0 - (_1218 * _1218), 0.0)) / fast::max(_1218, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        float2 param_47 = _1167.xy;\n                        float2 param_48 = float2(0.5 + (dot(_1211, _1198.xyz) * _1234), 0.5 - (dot(_1211, _1203.xyz) * _1234));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48, fa_light_atlas, fa_env_smp);\n                    }\n                    if (_1172.z > 0.5)\n                    {\n                        float2 param_49 = _1172.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1193;\n                        float3 param_52 = _1198.xyz;\n                        float3 param_53 = _1203.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53, fa_light_atlas, fa_env_smp);\n                    }\n                }\n            }\n        }\n    }\n    float3 _4664 = _749.xyz * atten;\n    if (_740)\n    {\n        _4664 *= fa_light_tint;\n    }\n    int _1302;\n    if (_766)\n    {\n        _1302 = 0;\n    }\n    else\n    {\n        _1302 = ((_752 > 1.5) && (_752 < 2.5)) ? 2 : 1;\n    }\n    return LightSample{ l, _4664, atten, 1.0, dist, _1302 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_fetch(thread const float2& uv, thread const float4& rect, thread const float3& conv, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2096 = fa_shadow_depth(param, param_1, fa_shadow_smp, fa_shadow_tex);\n    float _2100;\n    if (conv.x < 0.5)\n    {\n        _2100 = _2096;\n    }\n    else\n    {\n        _2100 = (conv.y * conv.z) / (conv.z - (_2096 * (conv.z - conv.y)));\n    }\n    return _2100;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _2027 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_2027), sin(_2027)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_filter(thread const float2& uv, thread const float4& rect, thread const float& zr, thread const float& texel_m, thread const float& unit, thread const float& reach, thread const float& plane, thread const float3& conv, thread const int& mode, thread const float& k, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2049, texture2d<float> fa_shadow_tex)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2, fa_shadow_smp, fa_shadow_tex));\n    }\n    float _2146 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2155;\n        if (k < 0.0)\n        {\n            _2155 = (-k) / fast::max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2155 = k;\n        }\n        float _2175 = fast::clamp((_2155 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2146;\n            float2 _2194 = fa_shadow_vogel(param_3, param_4, param_5) * _2175;\n            float2 param_6 = uv + (_2194 * _2049.fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _2206 = fa_shadow_fetch(param_6, param_7, param_8, fa_shadow_smp, fa_shadow_tex);\n            if (_2206 < (zr - (length(_2194) * plane)))\n            {\n                sum += _2206;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2232 = sum / cnt;\n        float _2242;\n        if (k < 0.0)\n        {\n            _2242 = (-k) / fast::max(_2232, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2242 = k;\n        }\n        radius = fast::clamp(((fast::max(zr - _2232, 0.0) * unit) * _2242) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _2264 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2264; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2264;\n        float param_11 = _2146;\n        float2 _2283 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_2283 * _2049.fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_2283) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14, fa_shadow_smp, fa_shadow_tex));\n    }\n    return lit / float(_2264);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_local(thread const int& li, thread const float3& lpos, thread const float3& world, thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _392, texture2d<float> fa_light_tex, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2049, texture2d<float> fa_shadow_tex)\n{\n    bool _2483 = _392.fa_pbr.z < 0.5;\n    bool _2490;\n    if (!_2483)\n    {\n        _2490 = _2049.fa_shadow_lcfg.x < 0.5;\n    }\n    else\n    {\n        _2490 = _2483;\n    }\n    if (_2490)\n    {\n        return 1.0;\n    }\n    int param = (int(_2049.fa_shadow_lcfg.x + 0.5) - 1) + li;\n    float4 _2503 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    float _2504 = _2503.x;\n    if (_2504 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2513 = int(_2504 + 0.5);\n    int param_1 = _2513;\n    float4 _2517 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    int param_2 = _2513 + 1;\n    float4 _2522 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float fade = 1.0;\n    float _2525 = _2517.y;\n    if (_2525 > 0.0)\n    {\n        float _2542 = 1.0 - smoothstep(0.75 * _2525, _2525, length(world - _2049.fa_shadow_eye.xyz));\n        fade = _2542;\n        if (_2542 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2517.x > 1.5)\n    {\n        float3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2566 = (_2513 + 2) + (face * 6);\n    int param_4 = _2566;\n    int param_5 = _2566 + 1;\n    int param_6 = _2566 + 3;\n    float4 _2580 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n    int param_7 = _2566 + 4;\n    float4 _2585 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n    int param_8 = _2566 + 5;\n    float4 _2590 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n    float _2602 = _2590.x * fast::max(dot(_2580, float4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2607 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _2630 = fast::clamp(dot(n, _2580.xyz), -1.0, 1.0);\n    float _2649 = fast::min(sqrt(1.0 - (_2630 * _2630)) / fast::max(abs(dot(n, world - lpos)) / fast::max(dot(_2580, float4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2652 = _2522.y;\n    float _2654;\n    if (_2652 > 0.0)\n    {\n        _2654 = _2652;\n    }\n    else\n    {\n        _2654 = 1.5 * _2602;\n    }\n    float4 _2674 = float4(world + (n * (_2654 * sqrt(1.0 - (_2607 * _2607)))), 1.0);\n    float _2678 = dot(_2580, _2674);\n    float _2681 = _2590.y;\n    if (_2678 < _2681)\n    {\n        return 1.0;\n    }\n    float2 _2696 = float2(dot(fa_light_texel(param_4, fa_light_tex, fa_shadow_smp), _2674), dot(fa_light_texel(param_5, fa_light_tex, fa_shadow_smp), _2674)) / float2(_2678);\n    float _2698 = _2696.x;\n    bool _2701 = _2698 < _2585.x;\n    bool _2710;\n    if (!_2701)\n    {\n        _2710 = _2698 > _2585.z;\n    }\n    else\n    {\n        _2710 = _2701;\n    }\n    bool _2719;\n    if (!_2710)\n    {\n        _2719 = _2696.y < _2585.y;\n    }\n    else\n    {\n        _2719 = _2710;\n    }\n    bool _2728;\n    if (!_2719)\n    {\n        _2728 = _2696.y > _2585.w;\n    }\n    else\n    {\n        _2728 = _2719;\n    }\n    if (_2728)\n    {\n        return 1.0;\n    }\n    float _2734 = _2522.x;\n    float _2736;\n    if (_2734 > 0.0)\n    {\n        _2736 = _2734;\n    }\n    else\n    {\n        _2736 = 1.5 * _2602;\n    }\n    float2 param_9 = _2696;\n    float4 param_10 = _2585;\n    float param_11 = _2678 - (_2736 * (1.0 + (0.5 * _2649)));\n    float param_12 = _2602;\n    float param_13 = 1.0;\n    float param_14 = _2590.z * 0.25;\n    float param_15 = (_2602 * fast::min(_2649, 3.0)) * 0.5;\n    float3 param_16 = float3(1.0, _2681, _2590.z);\n    int param_17 = int(_2517.z + 0.5);\n    float param_18 = _2517.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, fa_shadow_smp, gl_FragCoord, _2049, fa_shadow_tex), fade);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _2049)\n{\n    float _2039;\n    if (i == 0)\n    {\n        _2039 = _2049.fa_shadow_split.x;\n    }\n    else\n    {\n        float _2055;\n        if (i == 1)\n        {\n            _2055 = _2049.fa_shadow_split.y;\n        }\n        else\n        {\n            float _2063;\n            if (i == 2)\n            {\n                _2063 = _2049.fa_shadow_split.z;\n            }\n            else\n            {\n                _2063 = _2049.fa_shadow_split.w;\n            }\n            _2055 = _2063;\n        }\n        _2039 = _2055;\n    }\n    return _2039;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2049, texture2d<float> fa_shadow_tex)\n{\n    float _2325 = fast::max(_2049.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _2330 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _2336 = sqrt(1.0 - (_2330 * _2330));\n    float _2343 = fast::min(_2336 / fast::max(_2330, 0.20000000298023223876953125), 4.0);\n    float _2348;\n    if (_2049.fa_shadow_bias.y > 0.0)\n    {\n        _2348 = _2049.fa_shadow_bias.y;\n    }\n    else\n    {\n        _2348 = 1.5 * _2049.fa_shadow_info[ci].x;\n    }\n    float4 _2373 = _2049.fa_shadow_mat[ci] * float4(world + (n * (_2348 * _2336)), 1.0);\n    float _2380 = _2373.x;\n    bool _2383 = _2380 < _2049.fa_shadow_rect[ci].x;\n    bool _2392;\n    if (!_2383)\n    {\n        _2392 = _2380 > _2049.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2392 = _2383;\n    }\n    bool _2401;\n    if (!_2392)\n    {\n        _2401 = _2373.y < _2049.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2401 = _2392;\n    }\n    bool _2410;\n    if (!_2401)\n    {\n        _2410 = _2373.y > _2049.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2410 = _2401;\n    }\n    bool _2417;\n    if (!_2410)\n    {\n        _2417 = _2373.z > 1.0;\n    }\n    else\n    {\n        _2417 = _2410;\n    }\n    if (_2417)\n    {\n        return -1.0;\n    }\n    float _2425;\n    if (_2049.fa_shadow_bias.x > 0.0)\n    {\n        _2425 = _2049.fa_shadow_bias.x;\n    }\n    else\n    {\n        _2425 = 1.5 * _2049.fa_shadow_info[ci].x;\n    }\n    float2 param = _2373.xy;\n    float4 param_1 = _2049.fa_shadow_rect[ci];\n    float param_2 = _2373.z - ((_2425 * (1.0 + (0.5 * _2343))) / _2325);\n    float param_3 = _2049.fa_shadow_info[ci].x;\n    float param_4 = _2325;\n    float param_5 = _2325 * 0.25;\n    float param_6 = ((_2049.fa_shadow_info[ci].x * fast::min(_2343, 3.0)) * 0.5) / _2325;\n    float3 param_7 = float3(0.0);\n    int param_8 = int(_2049.fa_shadow_cfg.z + 0.5);\n    float param_9 = _2049.fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9, fa_shadow_smp, gl_FragCoord, _2049, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _392, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2049, texture2d<float> fa_shadow_tex)\n{\n    if (_392.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2803 = int(_2049.fa_shadow_cfg.x + 0.5);\n    if (_2803 < 1)\n    {\n        return 1.0;\n    }\n    float _2818 = dot(world - _2049.fa_shadow_eye.xyz, _2049.fa_shadow_fwd.xyz);\n    int param = _2803 - 1;\n    if (_2818 > fa_shadow_split_at(param, _2049))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2830 = _2803 > 1;\n    bool _2837;\n    if (_2830)\n    {\n        _2837 = _2818 > _2049.fa_shadow_split.x;\n    }\n    else\n    {\n        _2837 = _2830;\n    }\n    if (_2837)\n    {\n        ci = 1;\n    }\n    bool _2841 = _2803 > 2;\n    bool _2848;\n    if (_2841)\n    {\n        _2848 = _2818 > _2049.fa_shadow_split.y;\n    }\n    else\n    {\n        _2848 = _2841;\n    }\n    if (_2848)\n    {\n        ci = 2;\n    }\n    bool _2852 = _2803 > 3;\n    bool _2859;\n    if (_2852)\n    {\n        _2859 = _2818 > _2049.fa_shadow_split.z;\n    }\n    else\n    {\n        _2859 = _2852;\n    }\n    if (_2859)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2803)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2885 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_shadow_smp, gl_FragCoord, _2049, fa_shadow_tex);\n        s = _2885;\n        if (_2885 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_2049.fa_shadow_cfg.y > 0.0)\n    {\n        float _2910;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2910 = fa_shadow_split_at(param_5, _2049);\n        }\n        else\n        {\n            _2910 = _2049.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _2929 = _2049.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _2049) - _2910, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2940 = fast::clamp((_2818 - (fa_shadow_split_at(param_7, _2049) - _2929)) / _2929, 0.0, 1.0);\n        if (_2940 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2803)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _2961 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_shadow_smp, gl_FragCoord, _2049, fa_shadow_tex);\n                s2 = _2961;\n                if (_2961 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2940);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _392, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2049, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, _392, fa_shadow_smp, gl_FragCoord, _2049, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_contact_shadow(thread const int& li, thread const float3& world, thread const float3& gn, thread const float3& l, thread const float& dist, constant fa_mesh_fs_params& _392, texture2d<float> fa_light_tex, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2049, texture2d<float> fa_screen_tex)\n{\n    bool _3242 = _392.fa_ct_a.x < 0.5;\n    bool _3249;\n    if (!_3242)\n    {\n        _3249 = _2049.fa_shadow_lcfg.x < 0.5;\n    }\n    else\n    {\n        _3249 = _3242;\n    }\n    if (_3249)\n    {\n        return 1.0;\n    }\n    int param = (int(_2049.fa_shadow_lcfg.x + 0.5) - 1) + li;\n    float4 _3262 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    float _3263 = _3262.y;\n    float len = _3263;\n    if (_3263 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3275 = length(world - _392.fa_camera_pos.xyz);\n    float _3285 = 1.0 - smoothstep(0.5 * _392.fa_ct_b.x, _392.fa_ct_b.x, _3275);\n    if (_3285 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3291 = len;\n    float _3294 = fast::min(_3291, 0.89999997615814208984375 * dist);\n    len = _3294;\n    float _3300 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _3275);\n    float _3305 = _3300 + (0.5 * _3294);\n    float3 _3311 = world + (gn * _3300);\n    float _3313 = fa_shadow_noise(gl_FragCoord);\n    float occ = 0.0;\n    float _3378;\n    for (int k = 0; k < 12; k++)\n    {\n        float _3329 = (float(k) + _3313) * 0.083333335816860198974609375;\n        float3 _3337 = _3311 + (l * (_3329 * len));\n        float4 _3343 = float4(_3337, 1.0);\n        float _3349 = dot(_392.fa_ct_vpw, _3343);\n        if (_3349 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        float2 _3369 = float2(dot(_392.fa_ct_vpx, _3343), dot(_392.fa_ct_vpy, _3343)) / float2(_3349);\n        float _3373 = _3369.x * 0.5;\n        float _3374 = _3373 + 0.5;\n        if (_392.fa_ct_a.y > 0.5)\n        {\n            _3378 = (_3369.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _3378 = 0.5 - (_3369.y * 0.5);\n        }\n        bool _3394 = _3374 < 0.0;\n        bool _3401;\n        if (!_3394)\n        {\n            _3401 = _3374 >= 1.0;\n        }\n        else\n        {\n            _3401 = _3394;\n        }\n        bool _3408;\n        if (!_3401)\n        {\n            _3408 = _3378 < 0.0;\n        }\n        else\n        {\n            _3408 = _3401;\n        }\n        bool _3415;\n        if (!_3408)\n        {\n            _3415 = _3378 >= 1.0;\n        }\n        else\n        {\n            _3415 = _3408;\n        }\n        if (_3415)\n        {\n            break;\n        }\n        float4 _3434 = fa_screen_tex.read(uint2(int2(float2(_3374, _3378) * _392.fa_ct_a.zw)), 0);\n        if (_3434.w < 0.5)\n        {\n            continue;\n        }\n        float _3453 = (dot(_392.fa_ct_fwd.xyz, _3337) + _392.fa_ct_fwd.w) - _3434.x;\n        if ((_3453 > _3300) && (_3453 < _3305))\n        {\n            occ = fast::max(occ, (1.0 - (_3329 * _3329)) * smoothstep(0.0, 0.0500000007450580596923828125, fast::min(fast::min(_3374, 0.5 - _3373), fast::min(_3378, 1.0 - _3378))));\n        }\n    }\n    return 1.0 - (occ * _3285);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, constant fa_mesh_fs_params& _392, texture2d<float> fa_light_tex, sampler fa_shadow_smp, texture2d<float> fa_light_atlas, sampler fa_env_smp, thread float3& fa_light_tint, thread bool& fa_light_is_area, thread float4& gl_FragCoord, constant fa_shadows& _2049, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos, texture2d<float> fa_screen_tex, thread float3& fa_lm)\n{\n    bool _3529 = fa_lm.z > 0.5;\n    bool _3535;\n    if (_3529)\n    {\n        int param = li;\n        _3535 = fa_light_baked(param, _392, fa_light_tex, fa_shadow_smp);\n    }\n    else\n    {\n        _3535 = _3529;\n    }\n    if (_3535)\n    {\n        int param_1 = li;\n        return LightSample{ float3(0.0, 1.0, 0.0), float3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1, _392, fa_light_tex, fa_shadow_smp) + 0.5) };\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _3559 = fa_light_sample_n(param_2, param_3, param_4, _392, fa_light_tex, fa_shadow_smp, fa_light_atlas, fa_env_smp, fa_light_tint, fa_light_is_area);\n    float3 _4690 = _3559.color;\n    float _4692 = _3559.shadow;\n    bool _3562 = _3559.type == 0;\n    if (_3562 && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _3559.direction;\n        float _3573 = fa_shadow_factor(param_5, param_6, _392, fa_shadow_smp, gl_FragCoord, _2049, fa_shadow_tex, fa_world_pos);\n        _4692 = _3573;\n        _4690 *= _3573;\n    }\n    else\n    {\n        bool _3584 = _3559.type != 0;\n        bool _3590;\n        if (_3584)\n        {\n            _3590 = _3559.attenuation > 0.0;\n        }\n        else\n        {\n            _3590 = _3584;\n        }\n        if (_3590)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7, _392);\n            int param_9 = li;\n            float3 param_10 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp).xyz;\n            float3 param_11 = world_pos;\n            float3 param_12 = gn;\n            float3 param_13 = _3559.direction;\n            float _3609 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13, _392, fa_light_tex, fa_shadow_smp, gl_FragCoord, _2049, fa_shadow_tex);\n            _4692 = _3609;\n            _4690 *= _3609;\n        }\n    }\n    bool _3619 = _392.fa_ct_a.x > 0.5;\n    bool _3625;\n    if (_3619)\n    {\n        _3625 = _3559.attenuation > 0.0;\n    }\n    else\n    {\n        _3625 = _3619;\n    }\n    if (_3625)\n    {\n        float _3632;\n        if (_3562)\n        {\n            _3632 = 1000000000.0;\n        }\n        else\n        {\n            _3632 = _3559._distance;\n        }\n        int param_14 = li;\n        float3 param_15 = world_pos;\n        float3 param_16 = gn;\n        float3 param_17 = _3559.direction;\n        float param_18 = _3632;\n        float _3650 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18, _392, fa_light_tex, fa_shadow_smp, gl_FragCoord, _2049, fa_screen_tex);\n        _4692 *= _3650;\n        _4690 *= _3650;\n    }\n    return LightSample{ _3559.direction, _4690, _3559.attenuation, _4692, _3559._distance, _3559.type };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 light(thread const SurfaceInput& i, thread const Surface& s, thread const LightSample& l)\n{\n    return float3(0.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _2049)\n{\n    if (_2049.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _2985 = int(_2049.fa_shadow_cfg.x + 0.5);\n    float _2995 = dot(world - _2049.fa_shadow_eye.xyz, _2049.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _3000 = _2985 > 0;\n    bool _3009;\n    if (_3000)\n    {\n        int param = _2985 - 1;\n        _3009 = _2995 <= fa_shadow_split_at(param, _2049);\n    }\n    else\n    {\n        _3009 = _3000;\n    }\n    if (_3009)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3015 = _2985 > 1;\n        bool _3022;\n        if (_3015)\n        {\n            _3022 = _2995 > _2049.fa_shadow_split.x;\n        }\n        else\n        {\n            _3022 = _3015;\n        }\n        if (_3022)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3028 = _2985 > 2;\n        bool _3035;\n        if (_3028)\n        {\n            _3035 = _2995 > _2049.fa_shadow_split.y;\n        }\n        else\n        {\n            _3035 = _3028;\n        }\n        if (_3035)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3041 = _2985 > 3;\n        bool _3048;\n        if (_3041)\n        {\n            _3048 = _2995 > _2049.fa_shadow_split.z;\n        }\n        else\n        {\n            _3048 = _3041;\n        }\n        if (_3048)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _392 [[buffer(1)]], constant fa_shadows& _2049 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_env_tex [[texture(6)]], texture2d<float> fa_light_tex [[texture(7)]], texture2d<float> fa_light_atlas [[texture(8)]], texture2d<float> fa_lightmap [[texture(9)]], texture2d<float> fa_decal_tex [[texture(10)]], texture2d<float> fa_screen_tex [[texture(11)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _4482 = fast::normalize(in.fa_world_normal);\n    float3 fa_light_tint;\n    bool fa_light_is_area;\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _4482 = -_4482;\n    }\n    float3 _4052 = fast::normalize(_392.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, _392, fa_light_tex, fa_shadow_smp, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _4482, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _4052, short(gl_FrontFacing) };\n    Surface _4060 = fa_standard_surface(param_1, _392, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _4521 = _4060.albedo;\n    float _4522 = _4060.alpha;\n    float3 _4523 = _4060.normal;\n    float _4524 = _4060.metallic;\n    float _4525 = _4060.roughness;\n    float _4526 = _4060.occlusion;\n    float3 _4527 = _4060.emission;\n    float _4528 = _4060.clearcoat;\n    float _4529 = _4060.clearcoat_roughness;\n    float3 _4530 = _4060.sheen_color;\n    float _4531 = _4060.sheen_roughness;\n    float _4532 = _4060.anisotropy;\n    float _4533 = _4060.anisotropy_rotation;\n    float _4534 = _4060.specular;\n    float _4535 = _4060.ior;\n    float3 _4536 = _4060.specular_color;\n    float _4537 = _4060.transmission;\n    float _4538 = _4060.thickness;\n    float3 _4539 = _4060.attenuation_color;\n    float _4540 = _4060.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _4482, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _4052, short(gl_FrontFacing) };\n    Surface param_3 = _4060;\n    surface(param_2, param_3);\n    _4521 = param_3.albedo;\n    _4522 = param_3.alpha;\n    _4523 = param_3.normal;\n    _4524 = param_3.metallic;\n    _4525 = param_3.roughness;\n    _4526 = param_3.occlusion;\n    _4527 = param_3.emission;\n    _4528 = param_3.clearcoat;\n    _4529 = param_3.clearcoat_roughness;\n    _4530 = param_3.sheen_color;\n    _4531 = param_3.sheen_roughness;\n    _4532 = param_3.anisotropy;\n    _4533 = param_3.anisotropy_rotation;\n    _4534 = param_3.specular;\n    _4535 = param_3.ior;\n    _4536 = param_3.specular_color;\n    _4537 = param_3.transmission;\n    _4538 = param_3.thickness;\n    _4539 = param_3.attenuation_color;\n    _4540 = param_3.attenuation_distance;\n    float3 param_4 = in.fa_world_pos;\n    float3 param_5 = _4482;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7, _392, fa_light_tex, fa_shadow_smp, fa_env_smp, fa_decal_tex);\n    _4521 = param_6;\n    _4523 = param_7;\n    float3 result;\n    if (_392.fa_emissive.w > 0.5)\n    {\n        result = _4521;\n    }\n    else\n    {\n        float3 _4099 = _4523;\n        float3 _4100 = fast::normalize(_4099);\n        _4523 = _4100;\n        float3 param_8 = _4100;\n        SurfaceInput param_9 = SurfaceInput{ in.fa_world_pos, _4482, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _4052, short(gl_FrontFacing) };\n        Surface param_10 = Surface{ _4521, _4522, _4523, _4524, _4525, _4526, _4527, _4528, _4529, _4530, _4531, _4532, _4533, _4534, _4535, _4536, _4537, _4538, _4539, _4540 };\n        float3 param_11 = fa_indirect_diffuse(param_8, _392, fa_env_smp, fa_env_tex, in.fa_lm, fa_lightmap);\n        float3 lit = ambient(param_9, param_10, param_11);\n        int _4119 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _4119; ln++)\n        {\n            int param_12 = ln;\n            int _4132 = fa_cl_light(param_12, _392, fa_light_tex, fa_shadow_smp, fa_cl_ndir, fa_cl_slot);\n            bool _4135 = in.fa_lm.z > 0.5;\n            bool _4141;\n            if (_4135)\n            {\n                int param_13 = _4132;\n                _4141 = fa_light_baked(param_13, _392, fa_light_tex, fa_shadow_smp);\n            }\n            else\n            {\n                _4141 = _4135;\n            }\n            if (_4141)\n            {\n                continue;\n            }\n            int param_14 = _4132;\n            float3 param_15 = in.fa_world_pos;\n            float3 param_16 = _4482;\n            LightSample _4153 = fa_light_shadowed(param_14, param_15, param_16, _392, fa_light_tex, fa_shadow_smp, fa_light_atlas, fa_env_smp, fa_light_tint, fa_light_is_area, gl_FragCoord, _2049, fa_shadow_tex, in.fa_world_pos, fa_screen_tex, in.fa_lm);\n            SurfaceInput param_17 = SurfaceInput{ in.fa_world_pos, _4482, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _4052, short(gl_FrontFacing) };\n            Surface param_18 = Surface{ _4521, _4522, _4523, _4524, _4525, _4526, _4527, _4528, _4529, _4530, _4531, _4532, _4533, _4534, _4535, _4536, _4537, _4538, _4539, _4540 };\n            LightSample param_19 = _4153;\n            lit += light(param_17, param_18, param_19);\n        }\n        result = lit;\n    }\n    float3 _4168 = result;\n    float3 _4169 = _4168 + _4527;\n    result = _4169;\n    float3 param_20 = _4169;\n    float3 param_21 = in.fa_world_pos;\n    result = fa_shadow_debug(param_20, param_21, _2049);\n    bool _4178 = _392.fa_fog.w > 0.0;\n    bool _4185;\n    if (!_4178)\n    {\n        _4185 = _392.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _4185 = _4178;\n    }\n    if (_4185)\n    {\n        float3 _4194 = in.fa_world_pos - _392.fa_camera_pos.xyz;\n        float _4200 = dot(_4194, _392.fa_fog_c.xyz);\n        bool _4204 = _392.fa_fog_c.w > 0.5;\n        float _4205;\n        if (_4204)\n        {\n            _4205 = _4200;\n        }\n        else\n        {\n            _4205 = length(_4194);\n        }\n        float _4217 = _4205 - _392.fa_fog_b.x;\n        if (_4217 > 0.0)\n        {\n            float _4226 = _392.fa_fog.w * _4217;\n            float tau = _4226 * _4226;\n            if (_392.fa_fog_b.y > 0.0)\n            {\n                float _4242;\n                if (_4204)\n                {\n                    _4242 = in.fa_world_pos.y - (_392.fa_fog_c.y * _4200);\n                }\n                else\n                {\n                    _4242 = _392.fa_camera_pos.y;\n                }\n                float _4263 = mix(_4242, in.fa_world_pos.y, fast::clamp(_392.fa_fog_b.x / _4205, 0.0, 1.0));\n                float _4267 = in.fa_world_pos.y - _4263;\n                float _4272 = _4263 - _392.fa_fog_b.z;\n                float _4277 = in.fa_world_pos.y - _392.fa_fog_b.z;\n                bool _4280 = _4272 <= 0.0;\n                bool _4281 = !_4280;\n                bool _4287;\n                if (_4281)\n                {\n                    _4287 = _392.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4287 = _4280;\n                }\n                float _4288;\n                if (_4287)\n                {\n                    _4288 = _392.fa_fog_b.y;\n                }\n                else\n                {\n                    _4288 = _392.fa_fog_b.y * exp(-fast::min(_392.fa_fog_b.w * _4272, 80.0));\n                }\n                bool _4315;\n                if (_4281)\n                {\n                    _4315 = _392.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4315 = _4280;\n                }\n                float _4316;\n                if (_4315)\n                {\n                    _4316 = _392.fa_fog_b.y * _4272;\n                }\n                else\n                {\n                    _4316 = (_392.fa_fog_b.y * (1.0 - exp(-fast::min(_392.fa_fog_b.w * _4272, 80.0)))) / _392.fa_fog_b.w;\n                }\n                bool _4341 = _4277 <= 0.0;\n                bool _4348;\n                if (!_4341)\n                {\n                    _4348 = _392.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4348 = _4341;\n                }\n                float _4349;\n                if (_4348)\n                {\n                    _4349 = _392.fa_fog_b.y * _4277;\n                }\n                else\n                {\n                    _4349 = (_392.fa_fog_b.y * (1.0 - exp(-fast::min(_392.fa_fog_b.w * _4277, 80.0)))) / _392.fa_fog_b.w;\n                }\n                float _4376;\n                if (abs(_4267) < 0.001000000047497451305389404296875)\n                {\n                    _4376 = _4288;\n                }\n                else\n                {\n                    _4376 = (_4349 - _4316) / _4267;\n                }\n                tau += (_4217 * fast::max(_4376, 0.0));\n            }\n            result = mix(result, _392.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _4522);\n    return out;\n}\n\n",
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
            "inst_name": "_392",
            "msl_buffer_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2049",
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
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n    float4 fa_ct_a;\n    float4 fa_ct_b;\n    float4 fa_ct_vpx;\n    float4 fa_ct_vpy;\n    float4 fa_ct_vpw;\n    float4 fa_ct_fwd;\n    float4 fa_tr_a;\n    float4 fa_tr_b;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _56;\n    if (bool(i.front_facing))\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = fast::normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = fast::normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (bool(i.front_facing))\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _213, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _213.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _828 = base_t;\n    _828.x = _225.x;\n    _828.y = _225.y;\n    _828.z = _225.z;\n    base_t = _828;\n    float4 _241 = (_828 * _213.fa_base_color) * i.vertex_color;\n    float3 _783 = i.world_normal;\n    if (_213.fa_maps.z > 0.5)\n    {\n        float param_4 = _213.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0) - float3(1.0);\n        float2 _284 = _279.xy * _213.fa_maps.x;\n        float3 _836 = _279;\n        _836.x = _284.x;\n        _836.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _836;\n        _783 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _213.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _839 = mrt;\n    _839.x = _313.x;\n    _839.y = _313.y;\n    _839.z = _313.z;\n    mrt = _839;\n    float4 _343 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _213.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _385 = fa_tex_fix(param_20, param_21);\n    float _788 = _213.fa_layers_a.x;\n    float _789 = _213.fa_layers_a.y;\n    float _792 = _213.fa_layers_a.z;\n    float _791 = _213.fa_layers_b.w;\n    float _794 = _213.fa_layers_c.x;\n    if (_213.fa_layers_c.z > 0.5)\n    {\n        if (mod(_213.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _788 *= _355.y;\n            _789 *= _355.z;\n            _791 *= _343.w;\n        }\n        if (_213.fa_layers_c.z > 1.5)\n        {\n            _792 *= mrt.x;\n            _794 *= mrt.w;\n        }\n    }\n    return Surface{ _241.xyz, _241.w, _783, fast::clamp(_213.fa_pbr.x * _313.z, 0.0, 1.0), fast::clamp(_213.fa_pbr.y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_213.fa_maps.y * (_355.x - 1.0)), _213.fa_emissive.xyz + (_213.fa_model_emissive.xyz * _385), _788, _789, _213.fa_layers_b.xyz, _791, _792, _213.fa_layers_a.w, _794, _213.fa_layers_c.y, _213.fa_layers_d.xyz, _213.fa_tr_a.x, _213.fa_tr_a.y, _213.fa_tr_b.xyz, _213.fa_tr_a.z };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _213 [[buffer(1)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], sampler fa_smp [[sampler(0)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _678 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _678 = -_678;\n    }\n    float3 _538 = fast::normalize(_213.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _678, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _538, short(gl_FrontFacing) };\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _678, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _538, short(gl_FrontFacing) };\n    Surface param_2 = fa_standard_surface(param, fa_tex, fa_smp, _213, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    surface(param_1, param_2);\n    float3 _553 = fast::normalize(param_2.normal);\n    float3 _568 = fast::normalize(float3(dot(in.fa_pre_r0, _553), dot(in.fa_pre_r1, _553), dot(in.fa_pre_r2, _553)));\n    float _580 = _568.z;\n    float2 e = _568.xy / float2((abs(_568.x) + abs(_568.y)) + abs(_580));\n    if (_580 < 0.0)\n    {\n        e = (float2(1.0) - abs(e.yx)) * float2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    out.fa_frag_color = float4(fast::min(in.fa_pre_depth, 60000.0), e, 1.0);\n    return out;\n}\n\n",
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n    float4 fa_joints [[attribute(9)]];\n    float4 fa_weights [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _183)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_183.fa_joint_rows[_174] * weights[i]);\n        r1 += (_183.fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183.fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_prepass_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float& fa_pre_depth, thread float3& fa_pre_r0, thread float3& fa_pre_r1, thread float3& fa_pre_r2, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _136);\n    float3 _420 = _273.world_pos;\n    float4 _284 = float4(_420, 1.0);\n    fa_world_pos = _420;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    fa_pre_depth = -(_136.fa_light_vp * _284).z;\n    fa_pre_r0 = float3(_136.fa_light_vp[0].x, _136.fa_light_vp[1].x, _136.fa_light_vp[2].x);\n    fa_pre_r1 = float3(_136.fa_light_vp[0].y, _136.fa_light_vp[1].y, _136.fa_light_vp[2].y);\n    fa_pre_r2 = float3(_136.fa_light_vp[0].z, _136.fa_light_vp[1].z, _136.fa_light_vp[2].z);\n    gl_Position = _136.fa_view_proj * _284;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _136 [[buffer(0)]], constant fa_skin& _183 [[buffer(3)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float4x4 param_2 = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _183);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7, _136, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_pre_depth, out.fa_pre_r0, out.fa_pre_r1, out.fa_pre_r2, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n    float4 fa_ct_a;\n    float4 fa_ct_b;\n    float4 fa_ct_vpx;\n    float4 fa_ct_vpy;\n    float4 fa_ct_vpw;\n    float4 fa_ct_fwd;\n    float4 fa_tr_a;\n    float4 fa_tr_b;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _56;\n    if (bool(i.front_facing))\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = fast::normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = fast::normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (bool(i.front_facing))\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _213, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _213.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _828 = base_t;\n    _828.x = _225.x;\n    _828.y = _225.y;\n    _828.z = _225.z;\n    base_t = _828;\n    float4 _241 = (_828 * _213.fa_base_color) * i.vertex_color;\n    float3 _783 = i.world_normal;\n    if (_213.fa_maps.z > 0.5)\n    {\n        float param_4 = _213.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0) - float3(1.0);\n        float2 _284 = _279.xy * _213.fa_maps.x;\n        float3 _836 = _279;\n        _836.x = _284.x;\n        _836.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _836;\n        _783 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _213.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _839 = mrt;\n    _839.x = _313.x;\n    _839.y = _313.y;\n    _839.z = _313.z;\n    mrt = _839;\n    float4 _343 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _213.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _385 = fa_tex_fix(param_20, param_21);\n    float _788 = _213.fa_layers_a.x;\n    float _789 = _213.fa_layers_a.y;\n    float _792 = _213.fa_layers_a.z;\n    float _791 = _213.fa_layers_b.w;\n    float _794 = _213.fa_layers_c.x;\n    if (_213.fa_layers_c.z > 0.5)\n    {\n        if (mod(_213.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _788 *= _355.y;\n            _789 *= _355.z;\n            _791 *= _343.w;\n        }\n        if (_213.fa_layers_c.z > 1.5)\n        {\n            _792 *= mrt.x;\n            _794 *= mrt.w;\n        }\n    }\n    return Surface{ _241.xyz, _241.w, _783, fast::clamp(_213.fa_pbr.x * _313.z, 0.0, 1.0), fast::clamp(_213.fa_pbr.y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_213.fa_maps.y * (_355.x - 1.0)), _213.fa_emissive.xyz + (_213.fa_model_emissive.xyz * _385), _788, _789, _213.fa_layers_b.xyz, _791, _792, _213.fa_layers_a.w, _794, _213.fa_layers_c.y, _213.fa_layers_d.xyz, _213.fa_tr_a.x, _213.fa_tr_a.y, _213.fa_tr_b.xyz, _213.fa_tr_a.z };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _213 [[buffer(1)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], sampler fa_smp [[sampler(0)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _678 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _678 = -_678;\n    }\n    float3 _538 = fast::normalize(_213.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _678, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _538, short(gl_FrontFacing) };\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _678, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _538, short(gl_FrontFacing) };\n    Surface param_2 = fa_standard_surface(param, fa_tex, fa_smp, _213, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    surface(param_1, param_2);\n    float3 _553 = fast::normalize(param_2.normal);\n    float3 _568 = fast::normalize(float3(dot(in.fa_pre_r0, _553), dot(in.fa_pre_r1, _553), dot(in.fa_pre_r2, _553)));\n    float _580 = _568.z;\n    float2 e = _568.xy / float2((abs(_568.x) + abs(_568.y)) + abs(_580));\n    if (_580 < 0.0)\n    {\n        e = (float2(1.0) - abs(e.yx)) * float2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    out.fa_frag_color = float4(fast::min(in.fa_pre_depth, 60000.0), e, 1.0);\n    return out;\n}\n\n",
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
