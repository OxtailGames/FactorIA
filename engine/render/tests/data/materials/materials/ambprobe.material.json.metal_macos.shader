{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "c074417cc32d65946d9fd800b8e1855ea5fc09e97e16038fe5558a6cb62d2704",
  "slang": "metal_macos",
  "params": [],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float3 fa_lm [[user(locn5)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _131);\n    float3 _267 = _160.world_pos;\n    fa_world_pos = _267;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = _131.fa_view_proj * float4(_267, 1.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _131 [[buffer(0)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5, _131, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.gl_Position);\n    out.fa_lm = float3(0.0);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n#pragma clang diagnostic ignored \"-Wmissing-braces\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\ntemplate<typename T, size_t Num>\nstruct spvUnsafeArray\n{\n    T elements[Num ? Num : 1];\n    \n    thread T& operator [] (size_t pos) thread\n    {\n        return elements[pos];\n    }\n    constexpr const thread T& operator [] (size_t pos) const thread\n    {\n        return elements[pos];\n    }\n    \n    device T& operator [] (size_t pos) device\n    {\n        return elements[pos];\n    }\n    constexpr const device T& operator [] (size_t pos) const device\n    {\n        return elements[pos];\n    }\n    \n    constexpr const constant T& operator [] (size_t pos) const constant\n    {\n        return elements[pos];\n    }\n    \n    threadgroup T& operator [] (size_t pos) threadgroup\n    {\n        return elements[pos];\n    }\n    constexpr const threadgroup T& operator [] (size_t pos) const threadgroup\n    {\n        return elements[pos];\n    }\n};\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n    float4 fa_ct_a;\n    float4 fa_ct_b;\n    float4 fa_ct_vpx;\n    float4 fa_ct_vpy;\n    float4 fa_ct_vpw;\n    float4 fa_ct_fwd;\n    float4 fa_tr_a;\n    float4 fa_tr_b;\n    float4 fa_probe_sh[9];\n    float4 fa_atlas;\n    float4 fa_rpa_tile;\n    float4 fa_rpa_pos;\n    float4 fa_rpa_bx;\n    float4 fa_rpa_by;\n    float4 fa_rpa_bz;\n    float4 fa_rpb_tile;\n    float4 fa_rpb_pos;\n    float4 fa_rpb_bx;\n    float4 fa_rpb_by;\n    float4 fa_rpb_bz;\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n    float4 fa_shadow_lcfg;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float3 fa_lm [[user(locn5)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_cluster_texel(thread const float3& world_pos, constant fa_mesh_fs_params& _401, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    bool _1329 = _401.fa_cl_info.x < 0.0;\n    bool _1336;\n    if (!_1329)\n    {\n        _1336 = _401.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _1336 = _1329;\n    }\n    bool _1344;\n    if (!_1336)\n    {\n        _1344 = _401.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _1344 = _1336;\n    }\n    bool _1351;\n    if (!_1344)\n    {\n        _1351 = _401.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _1351 = _1344;\n    }\n    bool _1358;\n    if (!_1351)\n    {\n        _1358 = _401.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _1358 = _1351;\n    }\n    if (_1358)\n    {\n        return float4(0.0);\n    }\n    float4 _1368 = float4(world_pos, 1.0);\n    float _1374 = dot(_401.fa_cl_vpw, _1368);\n    if (!(_1374 > 9.9999999747524270787835121154785e-07))\n    {\n        return float4(0.0);\n    }\n    float2 _1396 = float2(dot(_401.fa_cl_vpx, _1368), dot(_401.fa_cl_vpy, _1368)) / float2(_1374);\n    int _1400 = int(_401.fa_cl_grid.x);\n    int _1404 = int(_401.fa_cl_grid.y);\n    int param = (int(_401.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_401.fa_cl_fwd.xyz, world_pos) + _401.fa_cl_fwd.w, _401.fa_cl_grid.w) / _401.fa_cl_grid.w) * _401.fa_cl_grid.z)), 0, int(_401.fa_cl_info.y) - 1) * _1404) + clamp(int(floor(((_1396.y * 0.5) + 0.5) * _401.fa_cl_grid.y)), 0, _1404 - 1)) * _1400)) + clamp(int(floor(((_1396.x * 0.5) + 0.5) * _401.fa_cl_grid.x)), 0, _1400 - 1);\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, constant fa_mesh_fs_params& _401, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    float3 param = world_pos;\n    float4 _1480 = fa_cluster_texel(param, _401, fa_light_tex, fa_shadow_smp);\n    return int2(int(_1480.x), int(_1480.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, constant fa_mesh_fs_params& _401, texture2d<float> fa_light_tex, sampler fa_shadow_smp, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_401.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _3656 = fa_cluster_lookup(param, _401, fa_light_tex, fa_shadow_smp);\n    fa_cl_slot = _3656.x;\n    fa_cl_local = _3656.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _3864 = fa_linear_to_srgb(param);\n        c = _3864;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _3872 = fa_srgb_to_linear(param_1);\n            c = _3872;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _283;\n    if (bool(i.front_facing))\n    {\n        _283 = i.world_normal;\n    }\n    else\n    {\n        _283 = -i.world_normal;\n    }\n    float3 _307 = fast::normalize(i.world_tangent.xyz - (_283 * dot(_283, i.world_tangent.xyz)));\n    float3 _334 = fast::normalize(((_307 * m.x) + ((cross(_283, _307) * i.world_tangent.w) * m.y)) + (_283 * m.z));\n    float3 _337;\n    if (bool(i.front_facing))\n    {\n        _337 = _334;\n    }\n    else\n    {\n        _337 = -_334;\n    }\n    return _337;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _401, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _401.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _3903 = fa_tex_fix(param_2, param_3);\n    float4 _5057 = base_t;\n    _5057.x = _3903.x;\n    _5057.y = _3903.y;\n    _5057.z = _3903.z;\n    base_t = _5057;\n    float4 _3917 = (_5057 * _401.fa_base_color) * i.vertex_color;\n    float3 _4901 = i.world_normal;\n    if (_401.fa_maps.z > 0.5)\n    {\n        float param_4 = _401.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _3949 = fa_tex_fix(param_6, param_7);\n        float3 _3952 = (_3949 * 2.0) - float3(1.0);\n        float2 _3957 = _3952.xy * _401.fa_maps.x;\n        float3 _5065 = _3952;\n        _5065.x = _3957.x;\n        _5065.y = _3957.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _5065;\n        _4901 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _401.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _3985 = fa_tex_fix(param_12, param_13);\n    float4 _5068 = mrt;\n    _5068.x = _3985.x;\n    _5068.y = _3985.y;\n    _5068.z = _3985.z;\n    mrt = _5068;\n    float4 _4013 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _401.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _4013.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _4024 = fa_tex_fix(param_16, param_17);\n    float param_18 = _401.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _4054 = fa_tex_fix(param_20, param_21);\n    float _4906 = _401.fa_layers_a.x;\n    float _4907 = _401.fa_layers_a.y;\n    float _4910 = _401.fa_layers_a.z;\n    float _4909 = _401.fa_layers_b.w;\n    float _4912 = _401.fa_layers_c.x;\n    if (_401.fa_layers_c.z > 0.5)\n    {\n        if (mod(_401.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _4906 *= _4024.y;\n            _4907 *= _4024.z;\n            _4909 *= _4013.w;\n        }\n        if (_401.fa_layers_c.z > 1.5)\n        {\n            _4910 *= mrt.x;\n            _4912 *= mrt.w;\n        }\n    }\n    return Surface{ _3917.xyz, _3917.w, _4901, fast::clamp(_401.fa_pbr.x * _3985.z, 0.0, 1.0), fast::clamp(_401.fa_pbr.y * _3985.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_401.fa_maps.y * (_4024.x - 1.0)), _401.fa_emissive.xyz + (_401.fa_model_emissive.xyz * _4054), _4906, _4907, _401.fa_layers_b.xyz, _4909, _4910, _401.fa_layers_a.w, _4912, _401.fa_layers_c.y, _401.fa_layers_d.xyz, _401.fa_tr_a.x, _401.fa_tr_a.y, _401.fa_tr_b.xyz, _401.fa_tr_a.z };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_decal_tile(thread const float4& rect, thread const float2& uv, thread const float2& atlas, thread const float2& ddx, thread const float2& ddy, sampler fa_env_smp, texture2d<float> fa_decal_tex)\n{\n    float2 _1560 = rect.zw - rect.xy;\n    float2 _1564 = _1560 * atlas;\n    float2 _1568 = ddx * _1564;\n    float2 _1572 = ddy * _1564;\n    return fa_decal_tex.sample(fa_env_smp, (rect.xy + (fast::clamp(uv, float2(0.0), float2(1.0)) * _1560)), level(fast::clamp(0.5 * log2(fast::max(fast::max(dot(_1568, _1568), dot(_1572, _1572)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_apply_decals(thread const float3& world_pos, thread const float3& geo_normal, thread float3& albedo, thread float3& normal, constant fa_mesh_fs_params& _401, texture2d<float> fa_light_tex, sampler fa_shadow_smp, sampler fa_env_smp, texture2d<float> fa_decal_tex)\n{\n    bool _1605 = _401.fa_counts.y < 0.5;\n    bool _1612;\n    if (!_1605)\n    {\n        _1612 = _401.fa_counts.w < 0.5;\n    }\n    else\n    {\n        _1612 = _1605;\n    }\n    if (_1612)\n    {\n        return;\n    }\n    float3 _1618 = dfdx(world_pos);\n    float3 _1621 = dfdy(world_pos);\n    float3 param = world_pos;\n    float4 _1625 = fa_cluster_texel(param, _401, fa_light_tex, fa_shadow_smp);\n    int _1629 = int(_1625.w);\n    if (_1629 < 1)\n    {\n        return;\n    }\n    int _1639 = int(_401.fa_counts.y + 0.5);\n    int param_1 = _1639;\n    float4 _1643 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float2 _1646 = _1643.yz;\n    int _1650 = int(_1643.w);\n    int param_2 = _1639 + 1;\n    float4 _1655 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float _1656 = _1655.x;\n    int _1662 = int(_401.fa_counts.w + 0.5) - 1;\n    int _1666 = int(_1625.z);\n    float3 _1931;\n    for (int k = 0; k < _1629; k++)\n    {\n        int _1679 = _1666 + k;\n        int param_3 = _1650 + (_1679 >> 2);\n        int _1696 = (_1639 + 2) + (int(fa_light_texel(param_3, fa_light_tex, fa_shadow_smp)[_1679 & 3]) * 7);\n        int param_4 = _1696 + 6;\n        float4 _1701 = fa_light_texel(param_4, fa_light_tex, fa_shadow_smp);\n        if (((int(_1701.w + 0.5) >> _1662) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1696;\n        float4 _1716 = fa_light_texel(param_5, fa_light_tex, fa_shadow_smp);\n        int param_6 = _1696 + 1;\n        float4 _1721 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n        int param_7 = _1696 + 2;\n        float4 _1726 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n        float3 _1729 = _1716.xyz;\n        float _1734 = dot(_1729, world_pos) + _1716.w;\n        float3 _1736 = _1721.xyz;\n        float _1741 = dot(_1736, world_pos) + _1721.w;\n        float3 _1743 = _1726.xyz;\n        float _1748 = dot(_1743, world_pos) + _1726.w;\n        bool _1753 = abs(_1734) > 0.5;\n        bool _1761;\n        if (!_1753)\n        {\n            _1761 = abs(_1741) > 0.5;\n        }\n        else\n        {\n            _1761 = _1753;\n        }\n        bool _1769;\n        if (!_1761)\n        {\n            _1769 = abs(_1748) > 0.5;\n        }\n        else\n        {\n            _1769 = _1761;\n        }\n        if (_1769)\n        {\n            continue;\n        }\n        float _1784 = fast::clamp(dot(geo_normal, fast::normalize(_1743)) * _1701.z, 0.0, 1.0);\n        if (_1784 <= 0.0)\n        {\n            continue;\n        }\n        float _1804 = (fast::clamp((0.5 - abs(_1748)) * 10.0, 0.0, 1.0) * _1784) * _1701.x;\n        float2 _1812 = float2(_1734 + 0.5, 0.5 - _1741);\n        float2 _1822 = float2(dot(_1729, _1618), dot(_1736, _1618));\n        float2 _1832 = float2(dot(_1729, _1621), dot(_1736, _1621));\n        int param_8 = _1696 + 5;\n        float4 _1837 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n        int param_9 = _1696 + 3;\n        float4 _1842 = fa_light_texel(param_9, fa_light_tex, fa_shadow_smp);\n        int param_10 = _1696 + 4;\n        float4 _1847 = fa_light_texel(param_10, fa_light_tex, fa_shadow_smp);\n        float tex_a = 1.0;\n        float3 col = _1837.xyz;\n        bool _1857 = _1842.z > _1842.x;\n        if (_1857)\n        {\n            float4 param_11 = _1842;\n            float2 param_12 = _1812;\n            float2 param_13 = _1646;\n            float2 param_14 = _1822;\n            float2 param_15 = _1832;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15, fa_env_smp, fa_decal_tex);\n            if ((_1656 > 0.5) && (_1656 < 1.5))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1883 = fa_dc_to_linear(param_16);\n                float4 _4989 = tx;\n                _4989.x = _1883.x;\n                _4989.y = _1883.y;\n                _4989.z = _1883.z;\n                tx = _4989;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, float3(fast::clamp((_1804 * tex_a) * _1837.w, 0.0, 1.0)));\n        if (_1847.z > _1847.x)\n        {\n            float4 param_17 = _1847;\n            float2 param_18 = _1812;\n            float2 param_19 = _1646;\n            float2 param_20 = _1822;\n            float2 param_21 = _1832;\n            float4 _1927 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21, fa_env_smp, fa_decal_tex);\n            if (_1656 > 1.5)\n            {\n                float3 param_22 = _1927.xyz;\n                float3 _1937 = fa_dc_to_srgb(param_22);\n                _1931 = _1937;\n            }\n            else\n            {\n                _1931 = _1927.xyz;\n            }\n            float3 _1946 = (_1931 * 2.0) - float3(1.0);\n            float2 _1951 = _1946.xy * _1701.y;\n            float3 _1973 = (fast::normalize(_1729) * _1951.x) + (fast::normalize(_1736) * _1951.y);\n            float3 _1976 = fast::normalize(normal);\n            normal = fast::normalize(mix(_1976, fast::normalize((_1976 * fast::max(_1946.z, 0.0500000007450580596923828125)) + (_1973 - (_1976 * dot(_1976, _1973)))), float3(fast::clamp(_1804 * (_1857 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_atlas_size(sampler fa_env_smp, texture2d<float> fa_probe_atlas)\n{\n    return float2(int2(fa_probe_atlas.get_width(), fa_probe_atlas.get_height()));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_probe_sh_coef(thread const float2& origin, thread const float& res, thread const int& k, constant fa_mesh_fs_params& _401, sampler fa_env_smp, texture2d<float> fa_probe_atlas)\n{\n    float3 v = fa_probe_atlas.sample(fa_env_smp, ((origin + float2(float(k) + 0.5, res + 2.5)) / fa_atlas_size(fa_env_smp, fa_probe_atlas)), level(0.0)).xyz;\n    if (_401.fa_atlas.y > 0.5)\n    {\n        v = (v - float3(0.5)) * 8.0;\n    }\n    return v;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sh_eval(thread const spvUnsafeArray<float3, 9>& c, thread const float3& n)\n{\n    float3 _3171 = fast::max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), float3(0.0));\n    return _3171;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _401, sampler fa_env_smp, texture2d<float> fa_probe_atlas)\n{\n    float _3227 = (1.0 - _401.fa_rpa_tile.w) - _401.fa_rpb_tile.w;\n    float3 amb = float3(0.0);\n    bool _3233 = _401.fa_env_sky.w > 0.5;\n    spvUnsafeArray<float3, 9> c;\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = float3(0.0);\n    }\n    if (_3227 > 0.0005000000237487256526947021484375)\n    {\n        if (_3233)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                float2 param = _401.fa_atlas.zw;\n                float param_1 = 128.0;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2, _401, fa_env_smp, fa_probe_atlas) * _3227;\n            }\n        }\n        else\n        {\n            amb = _401.fa_ambient.xyz * _3227;\n        }\n    }\n    bool _3286 = _401.fa_rpa_tile.w > 0.0;\n    if (_3286)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            float2 param_3 = _401.fa_rpa_tile.xy;\n            float param_4 = _401.fa_rpa_tile.z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5, _401, fa_env_smp, fa_probe_atlas) * _401.fa_rpa_tile.w);\n        }\n    }\n    bool _3317 = _401.fa_rpb_tile.w > 0.0;\n    if (_3317)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            float2 param_6 = _401.fa_rpb_tile.xy;\n            float param_7 = _401.fa_rpb_tile.z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8, _401, fa_env_smp, fa_probe_atlas) * _401.fa_rpb_tile.w);\n        }\n    }\n    if ((_3233 || _3286) || _3317)\n    {\n        spvUnsafeArray<float3, 9> param_9 = c;\n        float3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_indirect_diffuse(thread const float3& n, constant fa_mesh_fs_params& _401, sampler fa_env_smp, texture2d<float> fa_probe_atlas, thread float3& fa_lm, texture2d<float> fa_lightmap)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return fa_lightmap.sample(fa_env_smp, fa_lm.xy, level(0.0)).xyz;\n    }\n    if (_401.fa_probe_sh[0].w > 0.0)\n    {\n        spvUnsafeArray<float3, 9> c;\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = _401.fa_probe_sh[k].xyz;\n        }\n        float3 param = n;\n        spvUnsafeArray<float3, 9> param_1 = c;\n        float3 param_2 = n;\n        return mix(fa_ambient_light(param, _401, fa_env_smp, fa_probe_atlas), fa_sh_eval(param_1, param_2), float3(fast::clamp(_401.fa_probe_sh[0].w, 0.0, 1.0)));\n    }\n    float3 param_3 = n;\n    return fa_ambient_light(param_3, _401, fa_env_smp, fa_probe_atlas);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 ambient(thread const SurfaceInput& i, thread const Surface& s, thread const float3& ambientColor)\n{\n    return ambientColor;\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, constant fa_mesh_fs_params& _401, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (int(_401.fa_cl_info.x) + int(_401.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, constant fa_mesh_fs_params& _401, texture2d<float> fa_light_tex, sampler fa_shadow_smp, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, _401, fa_light_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_light_base(thread const int& li, constant fa_mesh_fs_params& _401)\n{\n    return li * ((_401.fa_ambient.w > 4.5) ? 8 : 4);\n}\n\nstatic inline __attribute__((always_inline))\nbool fa_light_baked(thread const int& li, constant fa_mesh_fs_params& _401, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li;\n    int param_1 = fa_light_base(param, _401) + 3;\n    return fa_light_texel(param_1, fa_light_tex, fa_shadow_smp).w > 0.5;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_baked_keep(thread const int& li, constant fa_mesh_fs_params& _401, texture2d<float> fa_light_tex, sampler fa_shadow_smp, thread float3& fa_lm)\n{\n    float _3626;\n    if (fa_lm.z > 0.5)\n    {\n        _3626 = 0.0;\n    }\n    else\n    {\n        _3626 = 1.0 - fast::clamp(_401.fa_probe_sh[0].w, 0.0, 1.0);\n    }\n    bool _3637 = _3626 < 1.0;\n    bool _3643;\n    if (_3637)\n    {\n        int param = li;\n        _3643 = fa_light_baked(param, _401, fa_light_tex, fa_shadow_smp);\n    }\n    else\n    {\n        _3643 = _3637;\n    }\n    return _3643 ? _3626 : 1.0;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_light_type(thread const int& li, constant fa_mesh_fs_params& _401, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li;\n    int param_1 = fa_light_base(param, _401) + 1;\n    return fa_light_texel(param_1, fa_light_tex, fa_shadow_smp).w;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_area_point(thread const float3& c, thread const float3& axis, thread const float3& ru, thread const float3& uu, thread const float& hx, thread const float& hy, thread const float& shape, thread const float3& p, thread const float3& r)\n{\n    bool _579 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        float3 _592 = (c - (ru * hx)) - p;\n        float3 _598 = ru * (2.0 * hx);\n        float _604 = fast::max(dot(_598, _598), 9.9999999392252902907785028219223e-09);\n        float _608 = dot(_592, _598);\n        float t = fast::clamp((-_608) / _604, 0.0, 1.0);\n        if (_579)\n        {\n            float _623 = dot(r, _598);\n            float _629 = _604 - (_623 * _623);\n            if (abs(_629) > (9.9999997473787516355514526367188e-06 * _604))\n            {\n                t = fast::clamp(((dot(r, _592) * _623) - _608) / _629, 0.0, 1.0);\n            }\n        }\n        return (p + _592) + (_598 * t);\n    }\n    float3 q = p;\n    float _661 = dot(r, axis);\n    bool _669;\n    if (_579)\n    {\n        _669 = abs(_661) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _669 = _579;\n    }\n    if (_669)\n    {\n        float _679 = dot(c - p, axis) / _661;\n        if (_679 > 0.0)\n        {\n            q = p + (r * _679);\n        }\n    }\n    float3 _692 = q - c;\n    float2 xy = float2(dot(_692, ru), dot(_692, uu));\n    if (shape > 0.5)\n    {\n        float _707 = length(xy);\n        if (_707 > hx)\n        {\n            xy *= (hx / _707);\n        }\n    }\n    else\n    {\n        xy = fast::clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_atlas_fetch(thread const float2& texel, texture2d<float> fa_light_atlas, sampler fa_env_smp)\n{\n    return fa_light_atlas.sample(fa_env_smp, (texel / float2(int2(fa_light_atlas.get_width(), fa_light_atlas.get_height()))), level(0.0));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_cookie_sample(thread const float2& tile_origin, thread const float2& uv, texture2d<float> fa_light_atlas, sampler fa_env_smp)\n{\n    float2 param = (tile_origin + float2(1.0)) + (fast::clamp(uv, float2(0.0), float2(1.0)) * 254.0);\n    return fa_atlas_fetch(param, fa_light_atlas, fa_env_smp).xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_ies_sample(thread const float2& tile_origin, thread const float3& d, thread const float3& axis, thread const float3& right, thread const float3& up, texture2d<float> fa_light_atlas, sampler fa_env_smp)\n{\n    float _499 = dot(d, right);\n    float _503 = dot(d, up);\n    float _514;\n    if (((_499 * _499) + (_503 * _503)) > 1.0000000133514319600180897396058e-10)\n    {\n        _514 = precise::atan2(_503, _499) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _514 = 0.0;\n    }\n    float2 param = tile_origin + float2(1.0 + ((_514 - floor(_514)) * 64.0), 1.0 + (acos(fast::clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param, fa_light_atlas, fa_env_smp).x;\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cube_face(thread const float3& d)\n{\n    float3 _349 = abs(d);\n    float _351 = _349.x;\n    float _353 = _349.y;\n    bool _354 = _351 >= _353;\n    bool _362;\n    if (_354)\n    {\n        _362 = _351 >= _349.z;\n    }\n    else\n    {\n        _362 = _354;\n    }\n    int _363;\n    if (_362)\n    {\n        _363 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _378;\n        if (_353 >= _349.z)\n        {\n            _378 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _378 = (d.z > 0.0) ? 4 : 5;\n        }\n        _363 = _378;\n    }\n    return _363;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cube_face_basis(thread const int& f, thread float3& fwd, thread float3& up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0, 0.0, 0.0);\n        up = float3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0, 0.0, 0.0);\n            up = float3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0, 1.0, 0.0);\n                up = float3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0, -1.0, 0.0);\n                    up = float3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0, 0.0, 1.0);\n                        up = float3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0, 0.0, -1.0);\n                        up = float3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample_n(thread const int& li, thread const float3& world_pos, thread const float3& n, constant fa_mesh_fs_params& _401, texture2d<float> fa_light_tex, sampler fa_shadow_smp, texture2d<float> fa_light_atlas, sampler fa_env_smp, thread float3& fa_light_tint, thread bool& fa_light_is_area)\n{\n    int param = li;\n    int _745 = fa_light_base(param, _401);\n    bool _749 = _401.fa_ambient.w > 4.5;\n    int param_1 = _745;\n    float4 _753 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    int param_2 = _745 + 1;\n    float4 _758 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float _761 = _758.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = float3(1.0);\n    bool _773 = _749 && (_761 > 2.5);\n    fa_light_is_area = _773;\n    bool _775 = _761 < 0.5;\n    float3 l;\n    if (_775)\n    {\n        l = fast::normalize(_753.xyz);\n        if (_749)\n        {\n            int param_3 = _745 + 6;\n            float4 _789 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            if (_789.z > 0.5)\n            {\n                int param_4 = _745 + 4;\n                float4 _799 = fa_light_texel(param_4, fa_light_tex, fa_shadow_smp);\n                int param_5 = _745 + 5;\n                float4 _804 = fa_light_texel(param_5, fa_light_tex, fa_shadow_smp);\n                float2 param_6 = _789.xy;\n                float2 param_7 = fract(float2(dot(world_pos, _799.xyz) * _799.w, (-dot(world_pos, _804.xyz)) * _804.w) + float2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7, fa_light_atlas, fa_env_smp);\n            }\n        }\n    }\n    else\n    {\n        float3 _834 = _753.xyz;\n        float3 _836 = _834 - world_pos;\n        float3 to_light = _836;\n        float _839 = length(_836);\n        float reach = _839;\n        bool front = true;\n        if (_773)\n        {\n            int param_8 = _745 + 7;\n            reach = fast::max(_839 - fa_light_texel(param_8, fa_light_tex, fa_shadow_smp).w, 0.0);\n            int param_9 = _745 + 4;\n            float4 _863 = fa_light_texel(param_9, fa_light_tex, fa_shadow_smp);\n            int param_10 = _745 + 5;\n            float4 _868 = fa_light_texel(param_10, fa_light_tex, fa_shadow_smp);\n            int param_11 = _745 + 6;\n            float4 _873 = fa_light_texel(param_11, fa_light_tex, fa_shadow_smp);\n            float _874 = _873.w;\n            int param_12 = _745 + 2;\n            float3 _881 = fast::normalize(fa_light_texel(param_12, fa_light_tex, fa_shadow_smp).xyz);\n            bool _883 = _874 > 1.5;\n            bool _891;\n            if (!_883)\n            {\n                _891 = dot(_881, to_light) < 0.0;\n            }\n            else\n            {\n                _891 = _883;\n            }\n            front = _891;\n            float3 r = float3(0.0);\n            float3 _900 = _401.fa_camera_pos.xyz - world_pos;\n            bool _904 = dot(n, n) > 0.5;\n            bool _912;\n            if (_904)\n            {\n                _912 = dot(_900, _900) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _912 = _904;\n            }\n            if (_912)\n            {\n                r = reflect(-fast::normalize(_900), fast::normalize(n));\n            }\n            float3 param_13 = _834;\n            float3 param_14 = _881;\n            float3 param_15 = _863.xyz;\n            float3 param_16 = _868.xyz;\n            float param_17 = _863.w;\n            float param_18 = _868.w;\n            float param_19 = _874;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _948 = length(to_light);\n        dist = _948;\n        l = to_light / float3(fast::max(_948, 9.9999997473787516355514526367188e-05));\n        float _962 = reach / fast::max(_753.w, 0.001000000047497451305389404296875);\n        float _968 = fast::clamp(1.0 - (_962 * _962), 0.0, 1.0);\n        float _970;\n        if (front)\n        {\n            _970 = _968 * _968;\n        }\n        else\n        {\n            _970 = 0.0;\n        }\n        atten = _970;\n        bool _981 = _761 < 2.5;\n        if ((_761 > 1.5) && _981)\n        {\n            int param_22 = _745 + 2;\n            float4 _989 = fa_light_texel(param_22, fa_light_tex, fa_shadow_smp);\n            float _999 = _989.w;\n            int param_23 = _745 + 3;\n            float4 _1004 = fa_light_texel(param_23, fa_light_tex, fa_shadow_smp);\n            float _1005 = _1004.x;\n            float cos_inner = _1005;\n            if (_1005 > 1.5)\n            {\n                cos_inner = mix(_999, 1.0, 0.25);\n            }\n            atten *= smoothstep(_999, cos_inner, dot(-l, fast::normalize(_989.xyz)));\n        }\n        if (_749 && (_761 < 1.5))\n        {\n            int param_24 = _745 + 6;\n            float4 _1029 = fa_light_texel(param_24, fa_light_tex, fa_shadow_smp);\n            if (_1029.z > 0.5)\n            {\n                float3 _1037 = -to_light;\n                int param_25 = _745 + 4;\n                int param_26 = _745 + 5;\n                float3 _1051 = fa_light_texel(param_25, fa_light_tex, fa_shadow_smp).xyz;\n                float3 _1055 = fa_light_texel(param_26, fa_light_tex, fa_shadow_smp).xyz;\n                float3 _1064 = float3(dot(_1037, _1051), dot(_1037, _1055), dot(_1037, cross(_1051, _1055)));\n                float3 param_27 = _1064;\n                int _1068 = fa_cube_face(param_27);\n                int param_28 = _1068;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1095 = float2(dot(_1064, cross(param_29, param_30)), dot(_1064, param_30)) / float2(fast::max(dot(_1064, param_29), 9.9999997473787516355514526367188e-05));\n                int _1099 = _1068 / 3;\n                float2 param_31 = _1029.xy + (float2(float(_1068 - (_1099 * 3)), float(_1099)) * 256.0);\n                float2 param_32 = float2(0.5 + (0.5 * _1095.x), 0.5 - (0.5 * _1095.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32, fa_light_atlas, fa_env_smp);\n            }\n            int param_33 = _745 + 7;\n            float4 _1129 = fa_light_texel(param_33, fa_light_tex, fa_shadow_smp);\n            if (_1129.z > 0.5)\n            {\n                int param_34 = _745 + 2;\n                int param_35 = _745 + 4;\n                int param_36 = _745 + 5;\n                float2 param_37 = _1129.xy;\n                float3 param_38 = -l;\n                float3 param_39 = fast::normalize(fa_light_texel(param_34, fa_light_tex, fa_shadow_smp).xyz);\n                float3 param_40 = fa_light_texel(param_35, fa_light_tex, fa_shadow_smp).xyz;\n                float3 param_41 = fa_light_texel(param_36, fa_light_tex, fa_shadow_smp).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41, fa_light_atlas, fa_env_smp);\n            }\n        }\n        else\n        {\n            if (_749 && _981)\n            {\n                int param_42 = _745 + 6;\n                float4 _1176 = fa_light_texel(param_42, fa_light_tex, fa_shadow_smp);\n                int param_43 = _745 + 7;\n                float4 _1181 = fa_light_texel(param_43, fa_light_tex, fa_shadow_smp);\n                bool _1184 = _1176.z > 0.5;\n                bool _1191;\n                if (!_1184)\n                {\n                    _1191 = _1181.z > 0.5;\n                }\n                else\n                {\n                    _1191 = _1184;\n                }\n                if (_1191)\n                {\n                    int param_44 = _745 + 2;\n                    float4 _1198 = fa_light_texel(param_44, fa_light_tex, fa_shadow_smp);\n                    float3 _1202 = fast::normalize(_1198.xyz);\n                    int param_45 = _745 + 4;\n                    float4 _1207 = fa_light_texel(param_45, fa_light_tex, fa_shadow_smp);\n                    int param_46 = _745 + 5;\n                    float4 _1212 = fa_light_texel(param_46, fa_light_tex, fa_shadow_smp);\n                    if (_1184)\n                    {\n                        float3 _1220 = -to_light;\n                        float _1227 = _1198.w;\n                        float _1243 = 0.5 / fast::max(dot(_1220, _1202) * (sqrt(fast::max(1.0 - (_1227 * _1227), 0.0)) / fast::max(_1227, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        float2 param_47 = _1176.xy;\n                        float2 param_48 = float2(0.5 + (dot(_1220, _1207.xyz) * _1243), 0.5 - (dot(_1220, _1212.xyz) * _1243));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48, fa_light_atlas, fa_env_smp);\n                    }\n                    if (_1181.z > 0.5)\n                    {\n                        float2 param_49 = _1181.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1202;\n                        float3 param_52 = _1207.xyz;\n                        float3 param_53 = _1212.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53, fa_light_atlas, fa_env_smp);\n                    }\n                }\n            }\n        }\n    }\n    float3 _4855 = _758.xyz * atten;\n    if (_749)\n    {\n        _4855 *= fa_light_tint;\n    }\n    int _1311;\n    if (_775)\n    {\n        _1311 = 0;\n    }\n    else\n    {\n        _1311 = ((_761 > 1.5) && (_761 < 2.5)) ? 2 : 1;\n    }\n    return LightSample{ l, _4855, atten, 1.0, dist, _1311 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_fetch(thread const float2& uv, thread const float4& rect, thread const float3& conv, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2105 = fa_shadow_depth(param, param_1, fa_shadow_smp, fa_shadow_tex);\n    float _2109;\n    if (conv.x < 0.5)\n    {\n        _2109 = _2105;\n    }\n    else\n    {\n        _2109 = (conv.y * conv.z) / (conv.z - (_2105 * (conv.z - conv.y)));\n    }\n    return _2109;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _2036 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_2036), sin(_2036)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_filter(thread const float2& uv, thread const float4& rect, thread const float& zr, thread const float& texel_m, thread const float& unit, thread const float& reach, thread const float& plane, thread const float3& conv, thread const int& mode, thread const float& k, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2058, texture2d<float> fa_shadow_tex)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2, fa_shadow_smp, fa_shadow_tex));\n    }\n    float _2155 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2164;\n        if (k < 0.0)\n        {\n            _2164 = (-k) / fast::max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2164 = k;\n        }\n        float _2184 = fast::clamp((_2164 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2155;\n            float2 _2203 = fa_shadow_vogel(param_3, param_4, param_5) * _2184;\n            float2 param_6 = uv + (_2203 * _2058.fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _2215 = fa_shadow_fetch(param_6, param_7, param_8, fa_shadow_smp, fa_shadow_tex);\n            if (_2215 < (zr - (length(_2203) * plane)))\n            {\n                sum += _2215;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2241 = sum / cnt;\n        float _2251;\n        if (k < 0.0)\n        {\n            _2251 = (-k) / fast::max(_2241, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2251 = k;\n        }\n        radius = fast::clamp(((fast::max(zr - _2241, 0.0) * unit) * _2251) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _2273 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2273; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2273;\n        float param_11 = _2155;\n        float2 _2292 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_2292 * _2058.fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_2292) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14, fa_shadow_smp, fa_shadow_tex));\n    }\n    return lit / float(_2273);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_local(thread const int& li, thread const float3& lpos, thread const float3& world, thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _401, texture2d<float> fa_light_tex, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2058, texture2d<float> fa_shadow_tex)\n{\n    bool _2492 = _401.fa_pbr.z < 0.5;\n    bool _2499;\n    if (!_2492)\n    {\n        _2499 = _2058.fa_shadow_lcfg.x < 0.5;\n    }\n    else\n    {\n        _2499 = _2492;\n    }\n    if (_2499)\n    {\n        return 1.0;\n    }\n    int param = (int(_2058.fa_shadow_lcfg.x + 0.5) - 1) + li;\n    float4 _2512 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    float _2513 = _2512.x;\n    if (_2513 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2522 = int(_2513 + 0.5);\n    int param_1 = _2522;\n    float4 _2526 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    int param_2 = _2522 + 1;\n    float4 _2531 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float fade = 1.0;\n    float _2534 = _2526.y;\n    if (_2534 > 0.0)\n    {\n        float _2551 = 1.0 - smoothstep(0.75 * _2534, _2534, length(world - _2058.fa_shadow_eye.xyz));\n        fade = _2551;\n        if (_2551 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2526.x > 1.5)\n    {\n        float3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2575 = (_2522 + 2) + (face * 6);\n    int param_4 = _2575;\n    int param_5 = _2575 + 1;\n    int param_6 = _2575 + 3;\n    float4 _2589 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n    int param_7 = _2575 + 4;\n    float4 _2594 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n    int param_8 = _2575 + 5;\n    float4 _2599 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n    float _2611 = _2599.x * fast::max(dot(_2589, float4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2616 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _2639 = fast::clamp(dot(n, _2589.xyz), -1.0, 1.0);\n    float _2658 = fast::min(sqrt(1.0 - (_2639 * _2639)) / fast::max(abs(dot(n, world - lpos)) / fast::max(dot(_2589, float4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2661 = _2531.y;\n    float _2663;\n    if (_2661 > 0.0)\n    {\n        _2663 = _2661;\n    }\n    else\n    {\n        _2663 = 1.5 * _2611;\n    }\n    float4 _2683 = float4(world + (n * (_2663 * sqrt(1.0 - (_2616 * _2616)))), 1.0);\n    float _2687 = dot(_2589, _2683);\n    float _2690 = _2599.y;\n    if (_2687 < _2690)\n    {\n        return 1.0;\n    }\n    float2 _2705 = float2(dot(fa_light_texel(param_4, fa_light_tex, fa_shadow_smp), _2683), dot(fa_light_texel(param_5, fa_light_tex, fa_shadow_smp), _2683)) / float2(_2687);\n    float _2707 = _2705.x;\n    bool _2710 = _2707 < _2594.x;\n    bool _2719;\n    if (!_2710)\n    {\n        _2719 = _2707 > _2594.z;\n    }\n    else\n    {\n        _2719 = _2710;\n    }\n    bool _2728;\n    if (!_2719)\n    {\n        _2728 = _2705.y < _2594.y;\n    }\n    else\n    {\n        _2728 = _2719;\n    }\n    bool _2737;\n    if (!_2728)\n    {\n        _2737 = _2705.y > _2594.w;\n    }\n    else\n    {\n        _2737 = _2728;\n    }\n    if (_2737)\n    {\n        return 1.0;\n    }\n    float _2743 = _2531.x;\n    float _2745;\n    if (_2743 > 0.0)\n    {\n        _2745 = _2743;\n    }\n    else\n    {\n        _2745 = 1.5 * _2611;\n    }\n    float2 param_9 = _2705;\n    float4 param_10 = _2594;\n    float param_11 = _2687 - (_2745 * (1.0 + (0.5 * _2658)));\n    float param_12 = _2611;\n    float param_13 = 1.0;\n    float param_14 = _2599.z * 0.25;\n    float param_15 = (_2611 * fast::min(_2658, 3.0)) * 0.5;\n    float3 param_16 = float3(1.0, _2690, _2599.z);\n    int param_17 = int(_2526.z + 0.5);\n    float param_18 = _2526.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, fa_shadow_smp, gl_FragCoord, _2058, fa_shadow_tex), fade);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _2058)\n{\n    float _2048;\n    if (i == 0)\n    {\n        _2048 = _2058.fa_shadow_split.x;\n    }\n    else\n    {\n        float _2064;\n        if (i == 1)\n        {\n            _2064 = _2058.fa_shadow_split.y;\n        }\n        else\n        {\n            float _2072;\n            if (i == 2)\n            {\n                _2072 = _2058.fa_shadow_split.z;\n            }\n            else\n            {\n                _2072 = _2058.fa_shadow_split.w;\n            }\n            _2064 = _2072;\n        }\n        _2048 = _2064;\n    }\n    return _2048;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2058, texture2d<float> fa_shadow_tex)\n{\n    float _2334 = fast::max(_2058.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _2339 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _2345 = sqrt(1.0 - (_2339 * _2339));\n    float _2352 = fast::min(_2345 / fast::max(_2339, 0.20000000298023223876953125), 4.0);\n    float _2357;\n    if (_2058.fa_shadow_bias.y > 0.0)\n    {\n        _2357 = _2058.fa_shadow_bias.y;\n    }\n    else\n    {\n        _2357 = 1.5 * _2058.fa_shadow_info[ci].x;\n    }\n    float4 _2382 = _2058.fa_shadow_mat[ci] * float4(world + (n * (_2357 * _2345)), 1.0);\n    float _2389 = _2382.x;\n    bool _2392 = _2389 < _2058.fa_shadow_rect[ci].x;\n    bool _2401;\n    if (!_2392)\n    {\n        _2401 = _2389 > _2058.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2401 = _2392;\n    }\n    bool _2410;\n    if (!_2401)\n    {\n        _2410 = _2382.y < _2058.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2410 = _2401;\n    }\n    bool _2419;\n    if (!_2410)\n    {\n        _2419 = _2382.y > _2058.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2419 = _2410;\n    }\n    bool _2426;\n    if (!_2419)\n    {\n        _2426 = _2382.z > 1.0;\n    }\n    else\n    {\n        _2426 = _2419;\n    }\n    if (_2426)\n    {\n        return -1.0;\n    }\n    float _2434;\n    if (_2058.fa_shadow_bias.x > 0.0)\n    {\n        _2434 = _2058.fa_shadow_bias.x;\n    }\n    else\n    {\n        _2434 = 1.5 * _2058.fa_shadow_info[ci].x;\n    }\n    float2 param = _2382.xy;\n    float4 param_1 = _2058.fa_shadow_rect[ci];\n    float param_2 = _2382.z - ((_2434 * (1.0 + (0.5 * _2352))) / _2334);\n    float param_3 = _2058.fa_shadow_info[ci].x;\n    float param_4 = _2334;\n    float param_5 = _2334 * 0.25;\n    float param_6 = ((_2058.fa_shadow_info[ci].x * fast::min(_2352, 3.0)) * 0.5) / _2334;\n    float3 param_7 = float3(0.0);\n    int param_8 = int(_2058.fa_shadow_cfg.z + 0.5);\n    float param_9 = _2058.fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9, fa_shadow_smp, gl_FragCoord, _2058, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _401, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2058, texture2d<float> fa_shadow_tex)\n{\n    if (_401.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2812 = int(_2058.fa_shadow_cfg.x + 0.5);\n    if (_2812 < 1)\n    {\n        return 1.0;\n    }\n    float _2827 = dot(world - _2058.fa_shadow_eye.xyz, _2058.fa_shadow_fwd.xyz);\n    int param = _2812 - 1;\n    if (_2827 > fa_shadow_split_at(param, _2058))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2839 = _2812 > 1;\n    bool _2846;\n    if (_2839)\n    {\n        _2846 = _2827 > _2058.fa_shadow_split.x;\n    }\n    else\n    {\n        _2846 = _2839;\n    }\n    if (_2846)\n    {\n        ci = 1;\n    }\n    bool _2850 = _2812 > 2;\n    bool _2857;\n    if (_2850)\n    {\n        _2857 = _2827 > _2058.fa_shadow_split.y;\n    }\n    else\n    {\n        _2857 = _2850;\n    }\n    if (_2857)\n    {\n        ci = 2;\n    }\n    bool _2861 = _2812 > 3;\n    bool _2868;\n    if (_2861)\n    {\n        _2868 = _2827 > _2058.fa_shadow_split.z;\n    }\n    else\n    {\n        _2868 = _2861;\n    }\n    if (_2868)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2812)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2894 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_shadow_smp, gl_FragCoord, _2058, fa_shadow_tex);\n        s = _2894;\n        if (_2894 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_2058.fa_shadow_cfg.y > 0.0)\n    {\n        float _2919;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2919 = fa_shadow_split_at(param_5, _2058);\n        }\n        else\n        {\n            _2919 = _2058.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _2938 = _2058.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _2058) - _2919, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2949 = fast::clamp((_2827 - (fa_shadow_split_at(param_7, _2058) - _2938)) / _2938, 0.0, 1.0);\n        if (_2949 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2812)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _2970 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_shadow_smp, gl_FragCoord, _2058, fa_shadow_tex);\n                s2 = _2970;\n                if (_2970 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2949);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _401, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2058, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, _401, fa_shadow_smp, gl_FragCoord, _2058, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_contact_shadow(thread const int& li, thread const float3& world, thread const float3& gn, thread const float3& l, thread const float& dist, constant fa_mesh_fs_params& _401, texture2d<float> fa_light_tex, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2058, texture2d<float> fa_screen_tex)\n{\n    bool _3368 = _401.fa_ct_a.x < 0.5;\n    bool _3375;\n    if (!_3368)\n    {\n        _3375 = _2058.fa_shadow_lcfg.x < 0.5;\n    }\n    else\n    {\n        _3375 = _3368;\n    }\n    if (_3375)\n    {\n        return 1.0;\n    }\n    int param = (int(_2058.fa_shadow_lcfg.x + 0.5) - 1) + li;\n    float4 _3388 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    float _3389 = _3388.y;\n    float len = _3389;\n    if (_3389 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3401 = length(world - _401.fa_camera_pos.xyz);\n    float _3411 = 1.0 - smoothstep(0.5 * _401.fa_ct_b.x, _401.fa_ct_b.x, _3401);\n    if (_3411 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3417 = len;\n    float _3420 = fast::min(_3417, 0.89999997615814208984375 * dist);\n    len = _3420;\n    float _3426 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _3401);\n    float _3431 = _3426 + (0.5 * _3420);\n    float3 _3437 = world + (gn * _3426);\n    float _3439 = fa_shadow_noise(gl_FragCoord);\n    float occ = 0.0;\n    float _3504;\n    for (int k = 0; k < 12; k++)\n    {\n        float _3455 = (float(k) + _3439) * 0.083333335816860198974609375;\n        float3 _3463 = _3437 + (l * (_3455 * len));\n        float4 _3469 = float4(_3463, 1.0);\n        float _3475 = dot(_401.fa_ct_vpw, _3469);\n        if (_3475 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        float2 _3495 = float2(dot(_401.fa_ct_vpx, _3469), dot(_401.fa_ct_vpy, _3469)) / float2(_3475);\n        float _3499 = _3495.x * 0.5;\n        float _3500 = _3499 + 0.5;\n        if (_401.fa_ct_a.y > 0.5)\n        {\n            _3504 = (_3495.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _3504 = 0.5 - (_3495.y * 0.5);\n        }\n        bool _3520 = _3500 < 0.0;\n        bool _3527;\n        if (!_3520)\n        {\n            _3527 = _3500 >= 1.0;\n        }\n        else\n        {\n            _3527 = _3520;\n        }\n        bool _3534;\n        if (!_3527)\n        {\n            _3534 = _3504 < 0.0;\n        }\n        else\n        {\n            _3534 = _3527;\n        }\n        bool _3541;\n        if (!_3534)\n        {\n            _3541 = _3504 >= 1.0;\n        }\n        else\n        {\n            _3541 = _3534;\n        }\n        if (_3541)\n        {\n            break;\n        }\n        float4 _3560 = fa_screen_tex.read(uint2(int2(float2(_3500, _3504) * _401.fa_ct_a.zw)), 0);\n        if (_3560.w < 0.5)\n        {\n            continue;\n        }\n        float _3579 = (dot(_401.fa_ct_fwd.xyz, _3463) + _401.fa_ct_fwd.w) - _3560.x;\n        if ((_3579 > _3426) && (_3579 < _3431))\n        {\n            occ = fast::max(occ, (1.0 - (_3455 * _3455)) * smoothstep(0.0, 0.0500000007450580596923828125, fast::min(fast::min(_3500, 0.5 - _3499), fast::min(_3504, 1.0 - _3504))));\n        }\n    }\n    return 1.0 - (occ * _3411);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, constant fa_mesh_fs_params& _401, texture2d<float> fa_light_tex, sampler fa_shadow_smp, texture2d<float> fa_light_atlas, sampler fa_env_smp, thread float3& fa_light_tint, thread bool& fa_light_is_area, thread float4& gl_FragCoord, constant fa_shadows& _2058, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos, texture2d<float> fa_screen_tex, thread float3& fa_lm)\n{\n    int param = li;\n    float _3682 = fa_baked_keep(param, _401, fa_light_tex, fa_shadow_smp, fa_lm);\n    if (_3682 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample{ float3(0.0, 1.0, 0.0), float3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1, _401, fa_light_tex, fa_shadow_smp) + 0.5) };\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _3708 = fa_light_sample_n(param_2, param_3, param_4, _401, fa_light_tex, fa_shadow_smp, fa_light_atlas, fa_env_smp, fa_light_tint, fa_light_is_area);\n    float3 _4881 = _3708.color;\n    float _4882 = _3708.attenuation;\n    float _4883 = _3708.shadow;\n    bool _3711 = _3708.type == 0;\n    if (_3711 && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _3708.direction;\n        float _3722 = fa_shadow_factor(param_5, param_6, _401, fa_shadow_smp, gl_FragCoord, _2058, fa_shadow_tex, fa_world_pos);\n        _4883 = _3722;\n        _4881 *= _3722;\n    }\n    else\n    {\n        bool _3733 = _3708.type != 0;\n        bool _3739;\n        if (_3733)\n        {\n            _3739 = _4882 > 0.0;\n        }\n        else\n        {\n            _3739 = _3733;\n        }\n        if (_3739)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7, _401);\n            int param_9 = li;\n            float3 param_10 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp).xyz;\n            float3 param_11 = world_pos;\n            float3 param_12 = gn;\n            float3 param_13 = _3708.direction;\n            float _3758 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13, _401, fa_light_tex, fa_shadow_smp, gl_FragCoord, _2058, fa_shadow_tex);\n            _4883 = _3758;\n            _4881 *= _3758;\n        }\n    }\n    bool _3768 = _401.fa_ct_a.x > 0.5;\n    bool _3774;\n    if (_3768)\n    {\n        _3774 = _4882 > 0.0;\n    }\n    else\n    {\n        _3774 = _3768;\n    }\n    if (_3774)\n    {\n        float _3781;\n        if (_3711)\n        {\n            _3781 = 1000000000.0;\n        }\n        else\n        {\n            _3781 = _3708._distance;\n        }\n        int param_14 = li;\n        float3 param_15 = world_pos;\n        float3 param_16 = gn;\n        float3 param_17 = _3708.direction;\n        float param_18 = _3781;\n        float _3799 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18, _401, fa_light_tex, fa_shadow_smp, gl_FragCoord, _2058, fa_screen_tex);\n        _4883 *= _3799;\n        _4881 *= _3799;\n    }\n    float _3812 = _4882;\n    float _3813 = _3812 * _3682;\n    _4882 = _3813;\n    float3 _3817 = _4881;\n    float3 _3818 = _3817 * _3682;\n    _4881 = _3818;\n    return LightSample{ _3708.direction, _3818, _3813, _4883, _3708._distance, _3708.type };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 light(thread const SurfaceInput& i, thread const Surface& s, thread const LightSample& l)\n{\n    return float3(0.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _2058)\n{\n    if (_2058.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _2994 = int(_2058.fa_shadow_cfg.x + 0.5);\n    float _3004 = dot(world - _2058.fa_shadow_eye.xyz, _2058.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _3009 = _2994 > 0;\n    bool _3018;\n    if (_3009)\n    {\n        int param = _2994 - 1;\n        _3018 = _3004 <= fa_shadow_split_at(param, _2058);\n    }\n    else\n    {\n        _3018 = _3009;\n    }\n    if (_3018)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3024 = _2994 > 1;\n        bool _3031;\n        if (_3024)\n        {\n            _3031 = _3004 > _2058.fa_shadow_split.x;\n        }\n        else\n        {\n            _3031 = _3024;\n        }\n        if (_3031)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3037 = _2994 > 2;\n        bool _3044;\n        if (_3037)\n        {\n            _3044 = _3004 > _2058.fa_shadow_split.y;\n        }\n        else\n        {\n            _3044 = _3037;\n        }\n        if (_3044)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3050 = _2994 > 3;\n        bool _3057;\n        if (_3050)\n        {\n            _3057 = _3004 > _2058.fa_shadow_split.z;\n        }\n        else\n        {\n            _3057 = _3050;\n        }\n        if (_3057)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _401 [[buffer(1)]], constant fa_shadows& _2058 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texture2d<float> fa_probe_atlas [[texture(6)]], texture2d<float> fa_light_tex [[texture(7)]], texture2d<float> fa_light_atlas [[texture(8)]], texture2d<float> fa_lightmap [[texture(9)]], texture2d<float> fa_decal_tex [[texture(10)]], texture2d<float> fa_screen_tex [[texture(11)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _4673 = fast::normalize(in.fa_world_normal);\n    float3 fa_light_tint;\n    bool fa_light_is_area;\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _4673 = -_4673;\n    }\n    float3 _4248 = fast::normalize(_401.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, _401, fa_light_tex, fa_shadow_smp, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _4673, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _4248, short(gl_FrontFacing) };\n    Surface _4256 = fa_standard_surface(param_1, _401, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _4712 = _4256.albedo;\n    float _4713 = _4256.alpha;\n    float3 _4714 = _4256.normal;\n    float _4715 = _4256.metallic;\n    float _4716 = _4256.roughness;\n    float _4717 = _4256.occlusion;\n    float3 _4718 = _4256.emission;\n    float _4719 = _4256.clearcoat;\n    float _4720 = _4256.clearcoat_roughness;\n    float3 _4721 = _4256.sheen_color;\n    float _4722 = _4256.sheen_roughness;\n    float _4723 = _4256.anisotropy;\n    float _4724 = _4256.anisotropy_rotation;\n    float _4725 = _4256.specular;\n    float _4726 = _4256.ior;\n    float3 _4727 = _4256.specular_color;\n    float _4728 = _4256.transmission;\n    float _4729 = _4256.thickness;\n    float3 _4730 = _4256.attenuation_color;\n    float _4731 = _4256.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _4673, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _4248, short(gl_FrontFacing) };\n    Surface param_3 = _4256;\n    surface(param_2, param_3);\n    _4712 = param_3.albedo;\n    _4713 = param_3.alpha;\n    _4714 = param_3.normal;\n    _4715 = param_3.metallic;\n    _4716 = param_3.roughness;\n    _4717 = param_3.occlusion;\n    _4718 = param_3.emission;\n    _4719 = param_3.clearcoat;\n    _4720 = param_3.clearcoat_roughness;\n    _4721 = param_3.sheen_color;\n    _4722 = param_3.sheen_roughness;\n    _4723 = param_3.anisotropy;\n    _4724 = param_3.anisotropy_rotation;\n    _4725 = param_3.specular;\n    _4726 = param_3.ior;\n    _4727 = param_3.specular_color;\n    _4728 = param_3.transmission;\n    _4729 = param_3.thickness;\n    _4730 = param_3.attenuation_color;\n    _4731 = param_3.attenuation_distance;\n    float3 param_4 = in.fa_world_pos;\n    float3 param_5 = _4673;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7, _401, fa_light_tex, fa_shadow_smp, fa_env_smp, fa_decal_tex);\n    _4712 = param_6;\n    _4714 = param_7;\n    float3 result;\n    if (_401.fa_emissive.w > 0.5)\n    {\n        result = _4712;\n    }\n    else\n    {\n        float3 _4295 = _4714;\n        float3 _4296 = fast::normalize(_4295);\n        _4714 = _4296;\n        float3 param_8 = _4296;\n        SurfaceInput param_9 = SurfaceInput{ in.fa_world_pos, _4673, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _4248, short(gl_FrontFacing) };\n        Surface param_10 = Surface{ _4712, _4713, _4714, _4715, _4716, _4717, _4718, _4719, _4720, _4721, _4722, _4723, _4724, _4725, _4726, _4727, _4728, _4729, _4730, _4731 };\n        float3 param_11 = fa_indirect_diffuse(param_8, _401, fa_env_smp, fa_probe_atlas, in.fa_lm, fa_lightmap);\n        float3 lit = ambient(param_9, param_10, param_11);\n        int _4315 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _4315; ln++)\n        {\n            int param_12 = ln;\n            int _4328 = fa_cl_light(param_12, _401, fa_light_tex, fa_shadow_smp, fa_cl_ndir, fa_cl_slot);\n            int param_13 = _4328;\n            if (fa_baked_keep(param_13, _401, fa_light_tex, fa_shadow_smp, in.fa_lm) <= 0.0)\n            {\n                continue;\n            }\n            int param_14 = _4328;\n            float3 param_15 = in.fa_world_pos;\n            float3 param_16 = _4673;\n            LightSample _4344 = fa_light_shadowed(param_14, param_15, param_16, _401, fa_light_tex, fa_shadow_smp, fa_light_atlas, fa_env_smp, fa_light_tint, fa_light_is_area, gl_FragCoord, _2058, fa_shadow_tex, in.fa_world_pos, fa_screen_tex, in.fa_lm);\n            SurfaceInput param_17 = SurfaceInput{ in.fa_world_pos, _4673, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _4248, short(gl_FrontFacing) };\n            Surface param_18 = Surface{ _4712, _4713, _4714, _4715, _4716, _4717, _4718, _4719, _4720, _4721, _4722, _4723, _4724, _4725, _4726, _4727, _4728, _4729, _4730, _4731 };\n            LightSample param_19 = _4344;\n            lit += light(param_17, param_18, param_19);\n        }\n        result = lit;\n    }\n    float3 _4359 = result;\n    float3 _4360 = _4359 + _4718;\n    result = _4360;\n    float3 param_20 = _4360;\n    float3 param_21 = in.fa_world_pos;\n    result = fa_shadow_debug(param_20, param_21, _2058);\n    bool _4369 = _401.fa_fog.w > 0.0;\n    bool _4376;\n    if (!_4369)\n    {\n        _4376 = _401.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _4376 = _4369;\n    }\n    if (_4376)\n    {\n        float3 _4385 = in.fa_world_pos - _401.fa_camera_pos.xyz;\n        float _4391 = dot(_4385, _401.fa_fog_c.xyz);\n        bool _4395 = _401.fa_fog_c.w > 0.5;\n        float _4396;\n        if (_4395)\n        {\n            _4396 = _4391;\n        }\n        else\n        {\n            _4396 = length(_4385);\n        }\n        float _4408 = _4396 - _401.fa_fog_b.x;\n        if (_4408 > 0.0)\n        {\n            float _4417 = _401.fa_fog.w * _4408;\n            float tau = _4417 * _4417;\n            if (_401.fa_fog_b.y > 0.0)\n            {\n                float _4433;\n                if (_4395)\n                {\n                    _4433 = in.fa_world_pos.y - (_401.fa_fog_c.y * _4391);\n                }\n                else\n                {\n                    _4433 = _401.fa_camera_pos.y;\n                }\n                float _4454 = mix(_4433, in.fa_world_pos.y, fast::clamp(_401.fa_fog_b.x / _4396, 0.0, 1.0));\n                float _4458 = in.fa_world_pos.y - _4454;\n                float _4463 = _4454 - _401.fa_fog_b.z;\n                float _4468 = in.fa_world_pos.y - _401.fa_fog_b.z;\n                bool _4471 = _4463 <= 0.0;\n                bool _4472 = !_4471;\n                bool _4478;\n                if (_4472)\n                {\n                    _4478 = _401.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4478 = _4471;\n                }\n                float _4479;\n                if (_4478)\n                {\n                    _4479 = _401.fa_fog_b.y;\n                }\n                else\n                {\n                    _4479 = _401.fa_fog_b.y * exp(-fast::min(_401.fa_fog_b.w * _4463, 80.0));\n                }\n                bool _4506;\n                if (_4472)\n                {\n                    _4506 = _401.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4506 = _4471;\n                }\n                float _4507;\n                if (_4506)\n                {\n                    _4507 = _401.fa_fog_b.y * _4463;\n                }\n                else\n                {\n                    _4507 = (_401.fa_fog_b.y * (1.0 - exp(-fast::min(_401.fa_fog_b.w * _4463, 80.0)))) / _401.fa_fog_b.w;\n                }\n                bool _4532 = _4468 <= 0.0;\n                bool _4539;\n                if (!_4532)\n                {\n                    _4539 = _401.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4539 = _4532;\n                }\n                float _4540;\n                if (_4539)\n                {\n                    _4540 = _401.fa_fog_b.y * _4468;\n                }\n                else\n                {\n                    _4540 = (_401.fa_fog_b.y * (1.0 - exp(-fast::min(_401.fa_fog_b.w * _4468, 80.0)))) / _401.fa_fog_b.w;\n                }\n                float _4567;\n                if (abs(_4458) < 0.001000000047497451305389404296875)\n                {\n                    _4567 = _4479;\n                }\n                else\n                {\n                    _4567 = (_4540 - _4507) / _4458;\n                }\n                tau += (_4408 * fast::max(_4567, 0.0));\n            }\n            result = mix(result, _401.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _4713);\n    return out;\n}\n\n",
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
            "size": 832,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_401",
            "msl_buffer_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2058",
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
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n#pragma clang diagnostic ignored \"-Wmissing-braces\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\ntemplate<typename T, size_t Num>\nstruct spvUnsafeArray\n{\n    T elements[Num ? Num : 1];\n    \n    thread T& operator [] (size_t pos) thread\n    {\n        return elements[pos];\n    }\n    constexpr const thread T& operator [] (size_t pos) const thread\n    {\n        return elements[pos];\n    }\n    \n    device T& operator [] (size_t pos) device\n    {\n        return elements[pos];\n    }\n    constexpr const device T& operator [] (size_t pos) const device\n    {\n        return elements[pos];\n    }\n    \n    constexpr const constant T& operator [] (size_t pos) const constant\n    {\n        return elements[pos];\n    }\n    \n    threadgroup T& operator [] (size_t pos) threadgroup\n    {\n        return elements[pos];\n    }\n    constexpr const threadgroup T& operator [] (size_t pos) const threadgroup\n    {\n        return elements[pos];\n    }\n};\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n    float4 fa_ct_a;\n    float4 fa_ct_b;\n    float4 fa_ct_vpx;\n    float4 fa_ct_vpy;\n    float4 fa_ct_vpw;\n    float4 fa_ct_fwd;\n    float4 fa_tr_a;\n    float4 fa_tr_b;\n    float4 fa_probe_sh[9];\n    float4 fa_atlas;\n    float4 fa_rpa_tile;\n    float4 fa_rpa_pos;\n    float4 fa_rpa_bx;\n    float4 fa_rpa_by;\n    float4 fa_rpa_bz;\n    float4 fa_rpb_tile;\n    float4 fa_rpb_pos;\n    float4 fa_rpb_bx;\n    float4 fa_rpb_by;\n    float4 fa_rpb_bz;\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n    float4 fa_shadow_lcfg;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float3 fa_lm [[user(locn5)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_cluster_texel(thread const float3& world_pos, constant fa_mesh_fs_params& _401, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    bool _1329 = _401.fa_cl_info.x < 0.0;\n    bool _1336;\n    if (!_1329)\n    {\n        _1336 = _401.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _1336 = _1329;\n    }\n    bool _1344;\n    if (!_1336)\n    {\n        _1344 = _401.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _1344 = _1336;\n    }\n    bool _1351;\n    if (!_1344)\n    {\n        _1351 = _401.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _1351 = _1344;\n    }\n    bool _1358;\n    if (!_1351)\n    {\n        _1358 = _401.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _1358 = _1351;\n    }\n    if (_1358)\n    {\n        return float4(0.0);\n    }\n    float4 _1368 = float4(world_pos, 1.0);\n    float _1374 = dot(_401.fa_cl_vpw, _1368);\n    if (!(_1374 > 9.9999999747524270787835121154785e-07))\n    {\n        return float4(0.0);\n    }\n    float2 _1396 = float2(dot(_401.fa_cl_vpx, _1368), dot(_401.fa_cl_vpy, _1368)) / float2(_1374);\n    int _1400 = int(_401.fa_cl_grid.x);\n    int _1404 = int(_401.fa_cl_grid.y);\n    int param = (int(_401.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_401.fa_cl_fwd.xyz, world_pos) + _401.fa_cl_fwd.w, _401.fa_cl_grid.w) / _401.fa_cl_grid.w) * _401.fa_cl_grid.z)), 0, int(_401.fa_cl_info.y) - 1) * _1404) + clamp(int(floor(((_1396.y * 0.5) + 0.5) * _401.fa_cl_grid.y)), 0, _1404 - 1)) * _1400)) + clamp(int(floor(((_1396.x * 0.5) + 0.5) * _401.fa_cl_grid.x)), 0, _1400 - 1);\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, constant fa_mesh_fs_params& _401, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    float3 param = world_pos;\n    float4 _1480 = fa_cluster_texel(param, _401, fa_light_tex, fa_shadow_smp);\n    return int2(int(_1480.x), int(_1480.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, constant fa_mesh_fs_params& _401, texture2d<float> fa_light_tex, sampler fa_shadow_smp, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_401.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _3656 = fa_cluster_lookup(param, _401, fa_light_tex, fa_shadow_smp);\n    fa_cl_slot = _3656.x;\n    fa_cl_local = _3656.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _3864 = fa_linear_to_srgb(param);\n        c = _3864;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _3872 = fa_srgb_to_linear(param_1);\n            c = _3872;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _283;\n    if (bool(i.front_facing))\n    {\n        _283 = i.world_normal;\n    }\n    else\n    {\n        _283 = -i.world_normal;\n    }\n    float3 _307 = fast::normalize(i.world_tangent.xyz - (_283 * dot(_283, i.world_tangent.xyz)));\n    float3 _334 = fast::normalize(((_307 * m.x) + ((cross(_283, _307) * i.world_tangent.w) * m.y)) + (_283 * m.z));\n    float3 _337;\n    if (bool(i.front_facing))\n    {\n        _337 = _334;\n    }\n    else\n    {\n        _337 = -_334;\n    }\n    return _337;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _401, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _401.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _3903 = fa_tex_fix(param_2, param_3);\n    float4 _5057 = base_t;\n    _5057.x = _3903.x;\n    _5057.y = _3903.y;\n    _5057.z = _3903.z;\n    base_t = _5057;\n    float4 _3917 = (_5057 * _401.fa_base_color) * i.vertex_color;\n    float3 _4901 = i.world_normal;\n    if (_401.fa_maps.z > 0.5)\n    {\n        float param_4 = _401.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _3949 = fa_tex_fix(param_6, param_7);\n        float3 _3952 = (_3949 * 2.0) - float3(1.0);\n        float2 _3957 = _3952.xy * _401.fa_maps.x;\n        float3 _5065 = _3952;\n        _5065.x = _3957.x;\n        _5065.y = _3957.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _5065;\n        _4901 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _401.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _3985 = fa_tex_fix(param_12, param_13);\n    float4 _5068 = mrt;\n    _5068.x = _3985.x;\n    _5068.y = _3985.y;\n    _5068.z = _3985.z;\n    mrt = _5068;\n    float4 _4013 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _401.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _4013.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _4024 = fa_tex_fix(param_16, param_17);\n    float param_18 = _401.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _4054 = fa_tex_fix(param_20, param_21);\n    float _4906 = _401.fa_layers_a.x;\n    float _4907 = _401.fa_layers_a.y;\n    float _4910 = _401.fa_layers_a.z;\n    float _4909 = _401.fa_layers_b.w;\n    float _4912 = _401.fa_layers_c.x;\n    if (_401.fa_layers_c.z > 0.5)\n    {\n        if (mod(_401.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _4906 *= _4024.y;\n            _4907 *= _4024.z;\n            _4909 *= _4013.w;\n        }\n        if (_401.fa_layers_c.z > 1.5)\n        {\n            _4910 *= mrt.x;\n            _4912 *= mrt.w;\n        }\n    }\n    return Surface{ _3917.xyz, _3917.w, _4901, fast::clamp(_401.fa_pbr.x * _3985.z, 0.0, 1.0), fast::clamp(_401.fa_pbr.y * _3985.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_401.fa_maps.y * (_4024.x - 1.0)), _401.fa_emissive.xyz + (_401.fa_model_emissive.xyz * _4054), _4906, _4907, _401.fa_layers_b.xyz, _4909, _4910, _401.fa_layers_a.w, _4912, _401.fa_layers_c.y, _401.fa_layers_d.xyz, _401.fa_tr_a.x, _401.fa_tr_a.y, _401.fa_tr_b.xyz, _401.fa_tr_a.z };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_decal_tile(thread const float4& rect, thread const float2& uv, thread const float2& atlas, thread const float2& ddx, thread const float2& ddy, sampler fa_env_smp, texture2d<float> fa_decal_tex)\n{\n    float2 _1560 = rect.zw - rect.xy;\n    float2 _1564 = _1560 * atlas;\n    float2 _1568 = ddx * _1564;\n    float2 _1572 = ddy * _1564;\n    return fa_decal_tex.sample(fa_env_smp, (rect.xy + (fast::clamp(uv, float2(0.0), float2(1.0)) * _1560)), level(fast::clamp(0.5 * log2(fast::max(fast::max(dot(_1568, _1568), dot(_1572, _1572)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_apply_decals(thread const float3& world_pos, thread const float3& geo_normal, thread float3& albedo, thread float3& normal, constant fa_mesh_fs_params& _401, texture2d<float> fa_light_tex, sampler fa_shadow_smp, sampler fa_env_smp, texture2d<float> fa_decal_tex)\n{\n    bool _1605 = _401.fa_counts.y < 0.5;\n    bool _1612;\n    if (!_1605)\n    {\n        _1612 = _401.fa_counts.w < 0.5;\n    }\n    else\n    {\n        _1612 = _1605;\n    }\n    if (_1612)\n    {\n        return;\n    }\n    float3 _1618 = dfdx(world_pos);\n    float3 _1621 = dfdy(world_pos);\n    float3 param = world_pos;\n    float4 _1625 = fa_cluster_texel(param, _401, fa_light_tex, fa_shadow_smp);\n    int _1629 = int(_1625.w);\n    if (_1629 < 1)\n    {\n        return;\n    }\n    int _1639 = int(_401.fa_counts.y + 0.5);\n    int param_1 = _1639;\n    float4 _1643 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float2 _1646 = _1643.yz;\n    int _1650 = int(_1643.w);\n    int param_2 = _1639 + 1;\n    float4 _1655 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float _1656 = _1655.x;\n    int _1662 = int(_401.fa_counts.w + 0.5) - 1;\n    int _1666 = int(_1625.z);\n    float3 _1931;\n    for (int k = 0; k < _1629; k++)\n    {\n        int _1679 = _1666 + k;\n        int param_3 = _1650 + (_1679 >> 2);\n        int _1696 = (_1639 + 2) + (int(fa_light_texel(param_3, fa_light_tex, fa_shadow_smp)[_1679 & 3]) * 7);\n        int param_4 = _1696 + 6;\n        float4 _1701 = fa_light_texel(param_4, fa_light_tex, fa_shadow_smp);\n        if (((int(_1701.w + 0.5) >> _1662) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1696;\n        float4 _1716 = fa_light_texel(param_5, fa_light_tex, fa_shadow_smp);\n        int param_6 = _1696 + 1;\n        float4 _1721 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n        int param_7 = _1696 + 2;\n        float4 _1726 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n        float3 _1729 = _1716.xyz;\n        float _1734 = dot(_1729, world_pos) + _1716.w;\n        float3 _1736 = _1721.xyz;\n        float _1741 = dot(_1736, world_pos) + _1721.w;\n        float3 _1743 = _1726.xyz;\n        float _1748 = dot(_1743, world_pos) + _1726.w;\n        bool _1753 = abs(_1734) > 0.5;\n        bool _1761;\n        if (!_1753)\n        {\n            _1761 = abs(_1741) > 0.5;\n        }\n        else\n        {\n            _1761 = _1753;\n        }\n        bool _1769;\n        if (!_1761)\n        {\n            _1769 = abs(_1748) > 0.5;\n        }\n        else\n        {\n            _1769 = _1761;\n        }\n        if (_1769)\n        {\n            continue;\n        }\n        float _1784 = fast::clamp(dot(geo_normal, fast::normalize(_1743)) * _1701.z, 0.0, 1.0);\n        if (_1784 <= 0.0)\n        {\n            continue;\n        }\n        float _1804 = (fast::clamp((0.5 - abs(_1748)) * 10.0, 0.0, 1.0) * _1784) * _1701.x;\n        float2 _1812 = float2(_1734 + 0.5, 0.5 - _1741);\n        float2 _1822 = float2(dot(_1729, _1618), dot(_1736, _1618));\n        float2 _1832 = float2(dot(_1729, _1621), dot(_1736, _1621));\n        int param_8 = _1696 + 5;\n        float4 _1837 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n        int param_9 = _1696 + 3;\n        float4 _1842 = fa_light_texel(param_9, fa_light_tex, fa_shadow_smp);\n        int param_10 = _1696 + 4;\n        float4 _1847 = fa_light_texel(param_10, fa_light_tex, fa_shadow_smp);\n        float tex_a = 1.0;\n        float3 col = _1837.xyz;\n        bool _1857 = _1842.z > _1842.x;\n        if (_1857)\n        {\n            float4 param_11 = _1842;\n            float2 param_12 = _1812;\n            float2 param_13 = _1646;\n            float2 param_14 = _1822;\n            float2 param_15 = _1832;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15, fa_env_smp, fa_decal_tex);\n            if ((_1656 > 0.5) && (_1656 < 1.5))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1883 = fa_dc_to_linear(param_16);\n                float4 _4989 = tx;\n                _4989.x = _1883.x;\n                _4989.y = _1883.y;\n                _4989.z = _1883.z;\n                tx = _4989;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, float3(fast::clamp((_1804 * tex_a) * _1837.w, 0.0, 1.0)));\n        if (_1847.z > _1847.x)\n        {\n            float4 param_17 = _1847;\n            float2 param_18 = _1812;\n            float2 param_19 = _1646;\n            float2 param_20 = _1822;\n            float2 param_21 = _1832;\n            float4 _1927 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21, fa_env_smp, fa_decal_tex);\n            if (_1656 > 1.5)\n            {\n                float3 param_22 = _1927.xyz;\n                float3 _1937 = fa_dc_to_srgb(param_22);\n                _1931 = _1937;\n            }\n            else\n            {\n                _1931 = _1927.xyz;\n            }\n            float3 _1946 = (_1931 * 2.0) - float3(1.0);\n            float2 _1951 = _1946.xy * _1701.y;\n            float3 _1973 = (fast::normalize(_1729) * _1951.x) + (fast::normalize(_1736) * _1951.y);\n            float3 _1976 = fast::normalize(normal);\n            normal = fast::normalize(mix(_1976, fast::normalize((_1976 * fast::max(_1946.z, 0.0500000007450580596923828125)) + (_1973 - (_1976 * dot(_1976, _1973)))), float3(fast::clamp(_1804 * (_1857 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_atlas_size(sampler fa_env_smp, texture2d<float> fa_probe_atlas)\n{\n    return float2(int2(fa_probe_atlas.get_width(), fa_probe_atlas.get_height()));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_probe_sh_coef(thread const float2& origin, thread const float& res, thread const int& k, constant fa_mesh_fs_params& _401, sampler fa_env_smp, texture2d<float> fa_probe_atlas)\n{\n    float3 v = fa_probe_atlas.sample(fa_env_smp, ((origin + float2(float(k) + 0.5, res + 2.5)) / fa_atlas_size(fa_env_smp, fa_probe_atlas)), level(0.0)).xyz;\n    if (_401.fa_atlas.y > 0.5)\n    {\n        v = (v - float3(0.5)) * 8.0;\n    }\n    return v;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sh_eval(thread const spvUnsafeArray<float3, 9>& c, thread const float3& n)\n{\n    float3 _3171 = fast::max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), float3(0.0));\n    return _3171;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _401, sampler fa_env_smp, texture2d<float> fa_probe_atlas)\n{\n    float _3227 = (1.0 - _401.fa_rpa_tile.w) - _401.fa_rpb_tile.w;\n    float3 amb = float3(0.0);\n    bool _3233 = _401.fa_env_sky.w > 0.5;\n    spvUnsafeArray<float3, 9> c;\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = float3(0.0);\n    }\n    if (_3227 > 0.0005000000237487256526947021484375)\n    {\n        if (_3233)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                float2 param = _401.fa_atlas.zw;\n                float param_1 = 128.0;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2, _401, fa_env_smp, fa_probe_atlas) * _3227;\n            }\n        }\n        else\n        {\n            amb = _401.fa_ambient.xyz * _3227;\n        }\n    }\n    bool _3286 = _401.fa_rpa_tile.w > 0.0;\n    if (_3286)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            float2 param_3 = _401.fa_rpa_tile.xy;\n            float param_4 = _401.fa_rpa_tile.z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5, _401, fa_env_smp, fa_probe_atlas) * _401.fa_rpa_tile.w);\n        }\n    }\n    bool _3317 = _401.fa_rpb_tile.w > 0.0;\n    if (_3317)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            float2 param_6 = _401.fa_rpb_tile.xy;\n            float param_7 = _401.fa_rpb_tile.z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8, _401, fa_env_smp, fa_probe_atlas) * _401.fa_rpb_tile.w);\n        }\n    }\n    if ((_3233 || _3286) || _3317)\n    {\n        spvUnsafeArray<float3, 9> param_9 = c;\n        float3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_indirect_diffuse(thread const float3& n, constant fa_mesh_fs_params& _401, sampler fa_env_smp, texture2d<float> fa_probe_atlas, thread float3& fa_lm, texture2d<float> fa_lightmap)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return fa_lightmap.sample(fa_env_smp, fa_lm.xy, level(0.0)).xyz;\n    }\n    if (_401.fa_probe_sh[0].w > 0.0)\n    {\n        spvUnsafeArray<float3, 9> c;\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = _401.fa_probe_sh[k].xyz;\n        }\n        float3 param = n;\n        spvUnsafeArray<float3, 9> param_1 = c;\n        float3 param_2 = n;\n        return mix(fa_ambient_light(param, _401, fa_env_smp, fa_probe_atlas), fa_sh_eval(param_1, param_2), float3(fast::clamp(_401.fa_probe_sh[0].w, 0.0, 1.0)));\n    }\n    float3 param_3 = n;\n    return fa_ambient_light(param_3, _401, fa_env_smp, fa_probe_atlas);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 ambient(thread const SurfaceInput& i, thread const Surface& s, thread const float3& ambientColor)\n{\n    return ambientColor;\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, constant fa_mesh_fs_params& _401, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (int(_401.fa_cl_info.x) + int(_401.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, constant fa_mesh_fs_params& _401, texture2d<float> fa_light_tex, sampler fa_shadow_smp, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, _401, fa_light_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_light_base(thread const int& li, constant fa_mesh_fs_params& _401)\n{\n    return li * ((_401.fa_ambient.w > 4.5) ? 8 : 4);\n}\n\nstatic inline __attribute__((always_inline))\nbool fa_light_baked(thread const int& li, constant fa_mesh_fs_params& _401, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li;\n    int param_1 = fa_light_base(param, _401) + 3;\n    return fa_light_texel(param_1, fa_light_tex, fa_shadow_smp).w > 0.5;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_baked_keep(thread const int& li, constant fa_mesh_fs_params& _401, texture2d<float> fa_light_tex, sampler fa_shadow_smp, thread float3& fa_lm)\n{\n    float _3626;\n    if (fa_lm.z > 0.5)\n    {\n        _3626 = 0.0;\n    }\n    else\n    {\n        _3626 = 1.0 - fast::clamp(_401.fa_probe_sh[0].w, 0.0, 1.0);\n    }\n    bool _3637 = _3626 < 1.0;\n    bool _3643;\n    if (_3637)\n    {\n        int param = li;\n        _3643 = fa_light_baked(param, _401, fa_light_tex, fa_shadow_smp);\n    }\n    else\n    {\n        _3643 = _3637;\n    }\n    return _3643 ? _3626 : 1.0;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_light_type(thread const int& li, constant fa_mesh_fs_params& _401, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li;\n    int param_1 = fa_light_base(param, _401) + 1;\n    return fa_light_texel(param_1, fa_light_tex, fa_shadow_smp).w;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_area_point(thread const float3& c, thread const float3& axis, thread const float3& ru, thread const float3& uu, thread const float& hx, thread const float& hy, thread const float& shape, thread const float3& p, thread const float3& r)\n{\n    bool _579 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        float3 _592 = (c - (ru * hx)) - p;\n        float3 _598 = ru * (2.0 * hx);\n        float _604 = fast::max(dot(_598, _598), 9.9999999392252902907785028219223e-09);\n        float _608 = dot(_592, _598);\n        float t = fast::clamp((-_608) / _604, 0.0, 1.0);\n        if (_579)\n        {\n            float _623 = dot(r, _598);\n            float _629 = _604 - (_623 * _623);\n            if (abs(_629) > (9.9999997473787516355514526367188e-06 * _604))\n            {\n                t = fast::clamp(((dot(r, _592) * _623) - _608) / _629, 0.0, 1.0);\n            }\n        }\n        return (p + _592) + (_598 * t);\n    }\n    float3 q = p;\n    float _661 = dot(r, axis);\n    bool _669;\n    if (_579)\n    {\n        _669 = abs(_661) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _669 = _579;\n    }\n    if (_669)\n    {\n        float _679 = dot(c - p, axis) / _661;\n        if (_679 > 0.0)\n        {\n            q = p + (r * _679);\n        }\n    }\n    float3 _692 = q - c;\n    float2 xy = float2(dot(_692, ru), dot(_692, uu));\n    if (shape > 0.5)\n    {\n        float _707 = length(xy);\n        if (_707 > hx)\n        {\n            xy *= (hx / _707);\n        }\n    }\n    else\n    {\n        xy = fast::clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_atlas_fetch(thread const float2& texel, texture2d<float> fa_light_atlas, sampler fa_env_smp)\n{\n    return fa_light_atlas.sample(fa_env_smp, (texel / float2(int2(fa_light_atlas.get_width(), fa_light_atlas.get_height()))), level(0.0));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_cookie_sample(thread const float2& tile_origin, thread const float2& uv, texture2d<float> fa_light_atlas, sampler fa_env_smp)\n{\n    float2 param = (tile_origin + float2(1.0)) + (fast::clamp(uv, float2(0.0), float2(1.0)) * 254.0);\n    return fa_atlas_fetch(param, fa_light_atlas, fa_env_smp).xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_ies_sample(thread const float2& tile_origin, thread const float3& d, thread const float3& axis, thread const float3& right, thread const float3& up, texture2d<float> fa_light_atlas, sampler fa_env_smp)\n{\n    float _499 = dot(d, right);\n    float _503 = dot(d, up);\n    float _514;\n    if (((_499 * _499) + (_503 * _503)) > 1.0000000133514319600180897396058e-10)\n    {\n        _514 = precise::atan2(_503, _499) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _514 = 0.0;\n    }\n    float2 param = tile_origin + float2(1.0 + ((_514 - floor(_514)) * 64.0), 1.0 + (acos(fast::clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param, fa_light_atlas, fa_env_smp).x;\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cube_face(thread const float3& d)\n{\n    float3 _349 = abs(d);\n    float _351 = _349.x;\n    float _353 = _349.y;\n    bool _354 = _351 >= _353;\n    bool _362;\n    if (_354)\n    {\n        _362 = _351 >= _349.z;\n    }\n    else\n    {\n        _362 = _354;\n    }\n    int _363;\n    if (_362)\n    {\n        _363 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _378;\n        if (_353 >= _349.z)\n        {\n            _378 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _378 = (d.z > 0.0) ? 4 : 5;\n        }\n        _363 = _378;\n    }\n    return _363;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cube_face_basis(thread const int& f, thread float3& fwd, thread float3& up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0, 0.0, 0.0);\n        up = float3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0, 0.0, 0.0);\n            up = float3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0, 1.0, 0.0);\n                up = float3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0, -1.0, 0.0);\n                    up = float3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0, 0.0, 1.0);\n                        up = float3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0, 0.0, -1.0);\n                        up = float3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample_n(thread const int& li, thread const float3& world_pos, thread const float3& n, constant fa_mesh_fs_params& _401, texture2d<float> fa_light_tex, sampler fa_shadow_smp, texture2d<float> fa_light_atlas, sampler fa_env_smp, thread float3& fa_light_tint, thread bool& fa_light_is_area)\n{\n    int param = li;\n    int _745 = fa_light_base(param, _401);\n    bool _749 = _401.fa_ambient.w > 4.5;\n    int param_1 = _745;\n    float4 _753 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    int param_2 = _745 + 1;\n    float4 _758 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float _761 = _758.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = float3(1.0);\n    bool _773 = _749 && (_761 > 2.5);\n    fa_light_is_area = _773;\n    bool _775 = _761 < 0.5;\n    float3 l;\n    if (_775)\n    {\n        l = fast::normalize(_753.xyz);\n        if (_749)\n        {\n            int param_3 = _745 + 6;\n            float4 _789 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            if (_789.z > 0.5)\n            {\n                int param_4 = _745 + 4;\n                float4 _799 = fa_light_texel(param_4, fa_light_tex, fa_shadow_smp);\n                int param_5 = _745 + 5;\n                float4 _804 = fa_light_texel(param_5, fa_light_tex, fa_shadow_smp);\n                float2 param_6 = _789.xy;\n                float2 param_7 = fract(float2(dot(world_pos, _799.xyz) * _799.w, (-dot(world_pos, _804.xyz)) * _804.w) + float2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7, fa_light_atlas, fa_env_smp);\n            }\n        }\n    }\n    else\n    {\n        float3 _834 = _753.xyz;\n        float3 _836 = _834 - world_pos;\n        float3 to_light = _836;\n        float _839 = length(_836);\n        float reach = _839;\n        bool front = true;\n        if (_773)\n        {\n            int param_8 = _745 + 7;\n            reach = fast::max(_839 - fa_light_texel(param_8, fa_light_tex, fa_shadow_smp).w, 0.0);\n            int param_9 = _745 + 4;\n            float4 _863 = fa_light_texel(param_9, fa_light_tex, fa_shadow_smp);\n            int param_10 = _745 + 5;\n            float4 _868 = fa_light_texel(param_10, fa_light_tex, fa_shadow_smp);\n            int param_11 = _745 + 6;\n            float4 _873 = fa_light_texel(param_11, fa_light_tex, fa_shadow_smp);\n            float _874 = _873.w;\n            int param_12 = _745 + 2;\n            float3 _881 = fast::normalize(fa_light_texel(param_12, fa_light_tex, fa_shadow_smp).xyz);\n            bool _883 = _874 > 1.5;\n            bool _891;\n            if (!_883)\n            {\n                _891 = dot(_881, to_light) < 0.0;\n            }\n            else\n            {\n                _891 = _883;\n            }\n            front = _891;\n            float3 r = float3(0.0);\n            float3 _900 = _401.fa_camera_pos.xyz - world_pos;\n            bool _904 = dot(n, n) > 0.5;\n            bool _912;\n            if (_904)\n            {\n                _912 = dot(_900, _900) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _912 = _904;\n            }\n            if (_912)\n            {\n                r = reflect(-fast::normalize(_900), fast::normalize(n));\n            }\n            float3 param_13 = _834;\n            float3 param_14 = _881;\n            float3 param_15 = _863.xyz;\n            float3 param_16 = _868.xyz;\n            float param_17 = _863.w;\n            float param_18 = _868.w;\n            float param_19 = _874;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _948 = length(to_light);\n        dist = _948;\n        l = to_light / float3(fast::max(_948, 9.9999997473787516355514526367188e-05));\n        float _962 = reach / fast::max(_753.w, 0.001000000047497451305389404296875);\n        float _968 = fast::clamp(1.0 - (_962 * _962), 0.0, 1.0);\n        float _970;\n        if (front)\n        {\n            _970 = _968 * _968;\n        }\n        else\n        {\n            _970 = 0.0;\n        }\n        atten = _970;\n        bool _981 = _761 < 2.5;\n        if ((_761 > 1.5) && _981)\n        {\n            int param_22 = _745 + 2;\n            float4 _989 = fa_light_texel(param_22, fa_light_tex, fa_shadow_smp);\n            float _999 = _989.w;\n            int param_23 = _745 + 3;\n            float4 _1004 = fa_light_texel(param_23, fa_light_tex, fa_shadow_smp);\n            float _1005 = _1004.x;\n            float cos_inner = _1005;\n            if (_1005 > 1.5)\n            {\n                cos_inner = mix(_999, 1.0, 0.25);\n            }\n            atten *= smoothstep(_999, cos_inner, dot(-l, fast::normalize(_989.xyz)));\n        }\n        if (_749 && (_761 < 1.5))\n        {\n            int param_24 = _745 + 6;\n            float4 _1029 = fa_light_texel(param_24, fa_light_tex, fa_shadow_smp);\n            if (_1029.z > 0.5)\n            {\n                float3 _1037 = -to_light;\n                int param_25 = _745 + 4;\n                int param_26 = _745 + 5;\n                float3 _1051 = fa_light_texel(param_25, fa_light_tex, fa_shadow_smp).xyz;\n                float3 _1055 = fa_light_texel(param_26, fa_light_tex, fa_shadow_smp).xyz;\n                float3 _1064 = float3(dot(_1037, _1051), dot(_1037, _1055), dot(_1037, cross(_1051, _1055)));\n                float3 param_27 = _1064;\n                int _1068 = fa_cube_face(param_27);\n                int param_28 = _1068;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1095 = float2(dot(_1064, cross(param_29, param_30)), dot(_1064, param_30)) / float2(fast::max(dot(_1064, param_29), 9.9999997473787516355514526367188e-05));\n                int _1099 = _1068 / 3;\n                float2 param_31 = _1029.xy + (float2(float(_1068 - (_1099 * 3)), float(_1099)) * 256.0);\n                float2 param_32 = float2(0.5 + (0.5 * _1095.x), 0.5 - (0.5 * _1095.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32, fa_light_atlas, fa_env_smp);\n            }\n            int param_33 = _745 + 7;\n            float4 _1129 = fa_light_texel(param_33, fa_light_tex, fa_shadow_smp);\n            if (_1129.z > 0.5)\n            {\n                int param_34 = _745 + 2;\n                int param_35 = _745 + 4;\n                int param_36 = _745 + 5;\n                float2 param_37 = _1129.xy;\n                float3 param_38 = -l;\n                float3 param_39 = fast::normalize(fa_light_texel(param_34, fa_light_tex, fa_shadow_smp).xyz);\n                float3 param_40 = fa_light_texel(param_35, fa_light_tex, fa_shadow_smp).xyz;\n                float3 param_41 = fa_light_texel(param_36, fa_light_tex, fa_shadow_smp).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41, fa_light_atlas, fa_env_smp);\n            }\n        }\n        else\n        {\n            if (_749 && _981)\n            {\n                int param_42 = _745 + 6;\n                float4 _1176 = fa_light_texel(param_42, fa_light_tex, fa_shadow_smp);\n                int param_43 = _745 + 7;\n                float4 _1181 = fa_light_texel(param_43, fa_light_tex, fa_shadow_smp);\n                bool _1184 = _1176.z > 0.5;\n                bool _1191;\n                if (!_1184)\n                {\n                    _1191 = _1181.z > 0.5;\n                }\n                else\n                {\n                    _1191 = _1184;\n                }\n                if (_1191)\n                {\n                    int param_44 = _745 + 2;\n                    float4 _1198 = fa_light_texel(param_44, fa_light_tex, fa_shadow_smp);\n                    float3 _1202 = fast::normalize(_1198.xyz);\n                    int param_45 = _745 + 4;\n                    float4 _1207 = fa_light_texel(param_45, fa_light_tex, fa_shadow_smp);\n                    int param_46 = _745 + 5;\n                    float4 _1212 = fa_light_texel(param_46, fa_light_tex, fa_shadow_smp);\n                    if (_1184)\n                    {\n                        float3 _1220 = -to_light;\n                        float _1227 = _1198.w;\n                        float _1243 = 0.5 / fast::max(dot(_1220, _1202) * (sqrt(fast::max(1.0 - (_1227 * _1227), 0.0)) / fast::max(_1227, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        float2 param_47 = _1176.xy;\n                        float2 param_48 = float2(0.5 + (dot(_1220, _1207.xyz) * _1243), 0.5 - (dot(_1220, _1212.xyz) * _1243));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48, fa_light_atlas, fa_env_smp);\n                    }\n                    if (_1181.z > 0.5)\n                    {\n                        float2 param_49 = _1181.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1202;\n                        float3 param_52 = _1207.xyz;\n                        float3 param_53 = _1212.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53, fa_light_atlas, fa_env_smp);\n                    }\n                }\n            }\n        }\n    }\n    float3 _4855 = _758.xyz * atten;\n    if (_749)\n    {\n        _4855 *= fa_light_tint;\n    }\n    int _1311;\n    if (_775)\n    {\n        _1311 = 0;\n    }\n    else\n    {\n        _1311 = ((_761 > 1.5) && (_761 < 2.5)) ? 2 : 1;\n    }\n    return LightSample{ l, _4855, atten, 1.0, dist, _1311 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_fetch(thread const float2& uv, thread const float4& rect, thread const float3& conv, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2105 = fa_shadow_depth(param, param_1, fa_shadow_smp, fa_shadow_tex);\n    float _2109;\n    if (conv.x < 0.5)\n    {\n        _2109 = _2105;\n    }\n    else\n    {\n        _2109 = (conv.y * conv.z) / (conv.z - (_2105 * (conv.z - conv.y)));\n    }\n    return _2109;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _2036 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_2036), sin(_2036)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_filter(thread const float2& uv, thread const float4& rect, thread const float& zr, thread const float& texel_m, thread const float& unit, thread const float& reach, thread const float& plane, thread const float3& conv, thread const int& mode, thread const float& k, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2058, texture2d<float> fa_shadow_tex)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2, fa_shadow_smp, fa_shadow_tex));\n    }\n    float _2155 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2164;\n        if (k < 0.0)\n        {\n            _2164 = (-k) / fast::max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2164 = k;\n        }\n        float _2184 = fast::clamp((_2164 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2155;\n            float2 _2203 = fa_shadow_vogel(param_3, param_4, param_5) * _2184;\n            float2 param_6 = uv + (_2203 * _2058.fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _2215 = fa_shadow_fetch(param_6, param_7, param_8, fa_shadow_smp, fa_shadow_tex);\n            if (_2215 < (zr - (length(_2203) * plane)))\n            {\n                sum += _2215;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2241 = sum / cnt;\n        float _2251;\n        if (k < 0.0)\n        {\n            _2251 = (-k) / fast::max(_2241, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2251 = k;\n        }\n        radius = fast::clamp(((fast::max(zr - _2241, 0.0) * unit) * _2251) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _2273 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2273; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2273;\n        float param_11 = _2155;\n        float2 _2292 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_2292 * _2058.fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_2292) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14, fa_shadow_smp, fa_shadow_tex));\n    }\n    return lit / float(_2273);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_local(thread const int& li, thread const float3& lpos, thread const float3& world, thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _401, texture2d<float> fa_light_tex, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2058, texture2d<float> fa_shadow_tex)\n{\n    bool _2492 = _401.fa_pbr.z < 0.5;\n    bool _2499;\n    if (!_2492)\n    {\n        _2499 = _2058.fa_shadow_lcfg.x < 0.5;\n    }\n    else\n    {\n        _2499 = _2492;\n    }\n    if (_2499)\n    {\n        return 1.0;\n    }\n    int param = (int(_2058.fa_shadow_lcfg.x + 0.5) - 1) + li;\n    float4 _2512 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    float _2513 = _2512.x;\n    if (_2513 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2522 = int(_2513 + 0.5);\n    int param_1 = _2522;\n    float4 _2526 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    int param_2 = _2522 + 1;\n    float4 _2531 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float fade = 1.0;\n    float _2534 = _2526.y;\n    if (_2534 > 0.0)\n    {\n        float _2551 = 1.0 - smoothstep(0.75 * _2534, _2534, length(world - _2058.fa_shadow_eye.xyz));\n        fade = _2551;\n        if (_2551 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2526.x > 1.5)\n    {\n        float3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2575 = (_2522 + 2) + (face * 6);\n    int param_4 = _2575;\n    int param_5 = _2575 + 1;\n    int param_6 = _2575 + 3;\n    float4 _2589 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n    int param_7 = _2575 + 4;\n    float4 _2594 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n    int param_8 = _2575 + 5;\n    float4 _2599 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n    float _2611 = _2599.x * fast::max(dot(_2589, float4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2616 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _2639 = fast::clamp(dot(n, _2589.xyz), -1.0, 1.0);\n    float _2658 = fast::min(sqrt(1.0 - (_2639 * _2639)) / fast::max(abs(dot(n, world - lpos)) / fast::max(dot(_2589, float4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2661 = _2531.y;\n    float _2663;\n    if (_2661 > 0.0)\n    {\n        _2663 = _2661;\n    }\n    else\n    {\n        _2663 = 1.5 * _2611;\n    }\n    float4 _2683 = float4(world + (n * (_2663 * sqrt(1.0 - (_2616 * _2616)))), 1.0);\n    float _2687 = dot(_2589, _2683);\n    float _2690 = _2599.y;\n    if (_2687 < _2690)\n    {\n        return 1.0;\n    }\n    float2 _2705 = float2(dot(fa_light_texel(param_4, fa_light_tex, fa_shadow_smp), _2683), dot(fa_light_texel(param_5, fa_light_tex, fa_shadow_smp), _2683)) / float2(_2687);\n    float _2707 = _2705.x;\n    bool _2710 = _2707 < _2594.x;\n    bool _2719;\n    if (!_2710)\n    {\n        _2719 = _2707 > _2594.z;\n    }\n    else\n    {\n        _2719 = _2710;\n    }\n    bool _2728;\n    if (!_2719)\n    {\n        _2728 = _2705.y < _2594.y;\n    }\n    else\n    {\n        _2728 = _2719;\n    }\n    bool _2737;\n    if (!_2728)\n    {\n        _2737 = _2705.y > _2594.w;\n    }\n    else\n    {\n        _2737 = _2728;\n    }\n    if (_2737)\n    {\n        return 1.0;\n    }\n    float _2743 = _2531.x;\n    float _2745;\n    if (_2743 > 0.0)\n    {\n        _2745 = _2743;\n    }\n    else\n    {\n        _2745 = 1.5 * _2611;\n    }\n    float2 param_9 = _2705;\n    float4 param_10 = _2594;\n    float param_11 = _2687 - (_2745 * (1.0 + (0.5 * _2658)));\n    float param_12 = _2611;\n    float param_13 = 1.0;\n    float param_14 = _2599.z * 0.25;\n    float param_15 = (_2611 * fast::min(_2658, 3.0)) * 0.5;\n    float3 param_16 = float3(1.0, _2690, _2599.z);\n    int param_17 = int(_2526.z + 0.5);\n    float param_18 = _2526.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, fa_shadow_smp, gl_FragCoord, _2058, fa_shadow_tex), fade);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _2058)\n{\n    float _2048;\n    if (i == 0)\n    {\n        _2048 = _2058.fa_shadow_split.x;\n    }\n    else\n    {\n        float _2064;\n        if (i == 1)\n        {\n            _2064 = _2058.fa_shadow_split.y;\n        }\n        else\n        {\n            float _2072;\n            if (i == 2)\n            {\n                _2072 = _2058.fa_shadow_split.z;\n            }\n            else\n            {\n                _2072 = _2058.fa_shadow_split.w;\n            }\n            _2064 = _2072;\n        }\n        _2048 = _2064;\n    }\n    return _2048;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2058, texture2d<float> fa_shadow_tex)\n{\n    float _2334 = fast::max(_2058.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _2339 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _2345 = sqrt(1.0 - (_2339 * _2339));\n    float _2352 = fast::min(_2345 / fast::max(_2339, 0.20000000298023223876953125), 4.0);\n    float _2357;\n    if (_2058.fa_shadow_bias.y > 0.0)\n    {\n        _2357 = _2058.fa_shadow_bias.y;\n    }\n    else\n    {\n        _2357 = 1.5 * _2058.fa_shadow_info[ci].x;\n    }\n    float4 _2382 = _2058.fa_shadow_mat[ci] * float4(world + (n * (_2357 * _2345)), 1.0);\n    float _2389 = _2382.x;\n    bool _2392 = _2389 < _2058.fa_shadow_rect[ci].x;\n    bool _2401;\n    if (!_2392)\n    {\n        _2401 = _2389 > _2058.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2401 = _2392;\n    }\n    bool _2410;\n    if (!_2401)\n    {\n        _2410 = _2382.y < _2058.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2410 = _2401;\n    }\n    bool _2419;\n    if (!_2410)\n    {\n        _2419 = _2382.y > _2058.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2419 = _2410;\n    }\n    bool _2426;\n    if (!_2419)\n    {\n        _2426 = _2382.z > 1.0;\n    }\n    else\n    {\n        _2426 = _2419;\n    }\n    if (_2426)\n    {\n        return -1.0;\n    }\n    float _2434;\n    if (_2058.fa_shadow_bias.x > 0.0)\n    {\n        _2434 = _2058.fa_shadow_bias.x;\n    }\n    else\n    {\n        _2434 = 1.5 * _2058.fa_shadow_info[ci].x;\n    }\n    float2 param = _2382.xy;\n    float4 param_1 = _2058.fa_shadow_rect[ci];\n    float param_2 = _2382.z - ((_2434 * (1.0 + (0.5 * _2352))) / _2334);\n    float param_3 = _2058.fa_shadow_info[ci].x;\n    float param_4 = _2334;\n    float param_5 = _2334 * 0.25;\n    float param_6 = ((_2058.fa_shadow_info[ci].x * fast::min(_2352, 3.0)) * 0.5) / _2334;\n    float3 param_7 = float3(0.0);\n    int param_8 = int(_2058.fa_shadow_cfg.z + 0.5);\n    float param_9 = _2058.fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9, fa_shadow_smp, gl_FragCoord, _2058, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _401, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2058, texture2d<float> fa_shadow_tex)\n{\n    if (_401.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2812 = int(_2058.fa_shadow_cfg.x + 0.5);\n    if (_2812 < 1)\n    {\n        return 1.0;\n    }\n    float _2827 = dot(world - _2058.fa_shadow_eye.xyz, _2058.fa_shadow_fwd.xyz);\n    int param = _2812 - 1;\n    if (_2827 > fa_shadow_split_at(param, _2058))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2839 = _2812 > 1;\n    bool _2846;\n    if (_2839)\n    {\n        _2846 = _2827 > _2058.fa_shadow_split.x;\n    }\n    else\n    {\n        _2846 = _2839;\n    }\n    if (_2846)\n    {\n        ci = 1;\n    }\n    bool _2850 = _2812 > 2;\n    bool _2857;\n    if (_2850)\n    {\n        _2857 = _2827 > _2058.fa_shadow_split.y;\n    }\n    else\n    {\n        _2857 = _2850;\n    }\n    if (_2857)\n    {\n        ci = 2;\n    }\n    bool _2861 = _2812 > 3;\n    bool _2868;\n    if (_2861)\n    {\n        _2868 = _2827 > _2058.fa_shadow_split.z;\n    }\n    else\n    {\n        _2868 = _2861;\n    }\n    if (_2868)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2812)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2894 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_shadow_smp, gl_FragCoord, _2058, fa_shadow_tex);\n        s = _2894;\n        if (_2894 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_2058.fa_shadow_cfg.y > 0.0)\n    {\n        float _2919;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2919 = fa_shadow_split_at(param_5, _2058);\n        }\n        else\n        {\n            _2919 = _2058.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _2938 = _2058.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _2058) - _2919, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2949 = fast::clamp((_2827 - (fa_shadow_split_at(param_7, _2058) - _2938)) / _2938, 0.0, 1.0);\n        if (_2949 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2812)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _2970 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_shadow_smp, gl_FragCoord, _2058, fa_shadow_tex);\n                s2 = _2970;\n                if (_2970 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2949);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _401, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2058, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, _401, fa_shadow_smp, gl_FragCoord, _2058, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_contact_shadow(thread const int& li, thread const float3& world, thread const float3& gn, thread const float3& l, thread const float& dist, constant fa_mesh_fs_params& _401, texture2d<float> fa_light_tex, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2058, texture2d<float> fa_screen_tex)\n{\n    bool _3368 = _401.fa_ct_a.x < 0.5;\n    bool _3375;\n    if (!_3368)\n    {\n        _3375 = _2058.fa_shadow_lcfg.x < 0.5;\n    }\n    else\n    {\n        _3375 = _3368;\n    }\n    if (_3375)\n    {\n        return 1.0;\n    }\n    int param = (int(_2058.fa_shadow_lcfg.x + 0.5) - 1) + li;\n    float4 _3388 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    float _3389 = _3388.y;\n    float len = _3389;\n    if (_3389 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3401 = length(world - _401.fa_camera_pos.xyz);\n    float _3411 = 1.0 - smoothstep(0.5 * _401.fa_ct_b.x, _401.fa_ct_b.x, _3401);\n    if (_3411 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3417 = len;\n    float _3420 = fast::min(_3417, 0.89999997615814208984375 * dist);\n    len = _3420;\n    float _3426 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _3401);\n    float _3431 = _3426 + (0.5 * _3420);\n    float3 _3437 = world + (gn * _3426);\n    float _3439 = fa_shadow_noise(gl_FragCoord);\n    float occ = 0.0;\n    float _3504;\n    for (int k = 0; k < 12; k++)\n    {\n        float _3455 = (float(k) + _3439) * 0.083333335816860198974609375;\n        float3 _3463 = _3437 + (l * (_3455 * len));\n        float4 _3469 = float4(_3463, 1.0);\n        float _3475 = dot(_401.fa_ct_vpw, _3469);\n        if (_3475 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        float2 _3495 = float2(dot(_401.fa_ct_vpx, _3469), dot(_401.fa_ct_vpy, _3469)) / float2(_3475);\n        float _3499 = _3495.x * 0.5;\n        float _3500 = _3499 + 0.5;\n        if (_401.fa_ct_a.y > 0.5)\n        {\n            _3504 = (_3495.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _3504 = 0.5 - (_3495.y * 0.5);\n        }\n        bool _3520 = _3500 < 0.0;\n        bool _3527;\n        if (!_3520)\n        {\n            _3527 = _3500 >= 1.0;\n        }\n        else\n        {\n            _3527 = _3520;\n        }\n        bool _3534;\n        if (!_3527)\n        {\n            _3534 = _3504 < 0.0;\n        }\n        else\n        {\n            _3534 = _3527;\n        }\n        bool _3541;\n        if (!_3534)\n        {\n            _3541 = _3504 >= 1.0;\n        }\n        else\n        {\n            _3541 = _3534;\n        }\n        if (_3541)\n        {\n            break;\n        }\n        float4 _3560 = fa_screen_tex.read(uint2(int2(float2(_3500, _3504) * _401.fa_ct_a.zw)), 0);\n        if (_3560.w < 0.5)\n        {\n            continue;\n        }\n        float _3579 = (dot(_401.fa_ct_fwd.xyz, _3463) + _401.fa_ct_fwd.w) - _3560.x;\n        if ((_3579 > _3426) && (_3579 < _3431))\n        {\n            occ = fast::max(occ, (1.0 - (_3455 * _3455)) * smoothstep(0.0, 0.0500000007450580596923828125, fast::min(fast::min(_3500, 0.5 - _3499), fast::min(_3504, 1.0 - _3504))));\n        }\n    }\n    return 1.0 - (occ * _3411);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, constant fa_mesh_fs_params& _401, texture2d<float> fa_light_tex, sampler fa_shadow_smp, texture2d<float> fa_light_atlas, sampler fa_env_smp, thread float3& fa_light_tint, thread bool& fa_light_is_area, thread float4& gl_FragCoord, constant fa_shadows& _2058, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos, texture2d<float> fa_screen_tex, thread float3& fa_lm)\n{\n    int param = li;\n    float _3682 = fa_baked_keep(param, _401, fa_light_tex, fa_shadow_smp, fa_lm);\n    if (_3682 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample{ float3(0.0, 1.0, 0.0), float3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1, _401, fa_light_tex, fa_shadow_smp) + 0.5) };\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _3708 = fa_light_sample_n(param_2, param_3, param_4, _401, fa_light_tex, fa_shadow_smp, fa_light_atlas, fa_env_smp, fa_light_tint, fa_light_is_area);\n    float3 _4881 = _3708.color;\n    float _4882 = _3708.attenuation;\n    float _4883 = _3708.shadow;\n    bool _3711 = _3708.type == 0;\n    if (_3711 && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _3708.direction;\n        float _3722 = fa_shadow_factor(param_5, param_6, _401, fa_shadow_smp, gl_FragCoord, _2058, fa_shadow_tex, fa_world_pos);\n        _4883 = _3722;\n        _4881 *= _3722;\n    }\n    else\n    {\n        bool _3733 = _3708.type != 0;\n        bool _3739;\n        if (_3733)\n        {\n            _3739 = _4882 > 0.0;\n        }\n        else\n        {\n            _3739 = _3733;\n        }\n        if (_3739)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7, _401);\n            int param_9 = li;\n            float3 param_10 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp).xyz;\n            float3 param_11 = world_pos;\n            float3 param_12 = gn;\n            float3 param_13 = _3708.direction;\n            float _3758 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13, _401, fa_light_tex, fa_shadow_smp, gl_FragCoord, _2058, fa_shadow_tex);\n            _4883 = _3758;\n            _4881 *= _3758;\n        }\n    }\n    bool _3768 = _401.fa_ct_a.x > 0.5;\n    bool _3774;\n    if (_3768)\n    {\n        _3774 = _4882 > 0.0;\n    }\n    else\n    {\n        _3774 = _3768;\n    }\n    if (_3774)\n    {\n        float _3781;\n        if (_3711)\n        {\n            _3781 = 1000000000.0;\n        }\n        else\n        {\n            _3781 = _3708._distance;\n        }\n        int param_14 = li;\n        float3 param_15 = world_pos;\n        float3 param_16 = gn;\n        float3 param_17 = _3708.direction;\n        float param_18 = _3781;\n        float _3799 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18, _401, fa_light_tex, fa_shadow_smp, gl_FragCoord, _2058, fa_screen_tex);\n        _4883 *= _3799;\n        _4881 *= _3799;\n    }\n    float _3812 = _4882;\n    float _3813 = _3812 * _3682;\n    _4882 = _3813;\n    float3 _3817 = _4881;\n    float3 _3818 = _3817 * _3682;\n    _4881 = _3818;\n    return LightSample{ _3708.direction, _3818, _3813, _4883, _3708._distance, _3708.type };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 light(thread const SurfaceInput& i, thread const Surface& s, thread const LightSample& l)\n{\n    return float3(0.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _2058)\n{\n    if (_2058.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _2994 = int(_2058.fa_shadow_cfg.x + 0.5);\n    float _3004 = dot(world - _2058.fa_shadow_eye.xyz, _2058.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _3009 = _2994 > 0;\n    bool _3018;\n    if (_3009)\n    {\n        int param = _2994 - 1;\n        _3018 = _3004 <= fa_shadow_split_at(param, _2058);\n    }\n    else\n    {\n        _3018 = _3009;\n    }\n    if (_3018)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3024 = _2994 > 1;\n        bool _3031;\n        if (_3024)\n        {\n            _3031 = _3004 > _2058.fa_shadow_split.x;\n        }\n        else\n        {\n            _3031 = _3024;\n        }\n        if (_3031)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3037 = _2994 > 2;\n        bool _3044;\n        if (_3037)\n        {\n            _3044 = _3004 > _2058.fa_shadow_split.y;\n        }\n        else\n        {\n            _3044 = _3037;\n        }\n        if (_3044)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3050 = _2994 > 3;\n        bool _3057;\n        if (_3050)\n        {\n            _3057 = _3004 > _2058.fa_shadow_split.z;\n        }\n        else\n        {\n            _3057 = _3050;\n        }\n        if (_3057)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _401 [[buffer(1)]], constant fa_shadows& _2058 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texture2d<float> fa_probe_atlas [[texture(6)]], texture2d<float> fa_light_tex [[texture(7)]], texture2d<float> fa_light_atlas [[texture(8)]], texture2d<float> fa_lightmap [[texture(9)]], texture2d<float> fa_decal_tex [[texture(10)]], texture2d<float> fa_screen_tex [[texture(11)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _4673 = fast::normalize(in.fa_world_normal);\n    float3 fa_light_tint;\n    bool fa_light_is_area;\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _4673 = -_4673;\n    }\n    float3 _4248 = fast::normalize(_401.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, _401, fa_light_tex, fa_shadow_smp, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _4673, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _4248, short(gl_FrontFacing) };\n    Surface _4256 = fa_standard_surface(param_1, _401, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _4712 = _4256.albedo;\n    float _4713 = _4256.alpha;\n    float3 _4714 = _4256.normal;\n    float _4715 = _4256.metallic;\n    float _4716 = _4256.roughness;\n    float _4717 = _4256.occlusion;\n    float3 _4718 = _4256.emission;\n    float _4719 = _4256.clearcoat;\n    float _4720 = _4256.clearcoat_roughness;\n    float3 _4721 = _4256.sheen_color;\n    float _4722 = _4256.sheen_roughness;\n    float _4723 = _4256.anisotropy;\n    float _4724 = _4256.anisotropy_rotation;\n    float _4725 = _4256.specular;\n    float _4726 = _4256.ior;\n    float3 _4727 = _4256.specular_color;\n    float _4728 = _4256.transmission;\n    float _4729 = _4256.thickness;\n    float3 _4730 = _4256.attenuation_color;\n    float _4731 = _4256.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _4673, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _4248, short(gl_FrontFacing) };\n    Surface param_3 = _4256;\n    surface(param_2, param_3);\n    _4712 = param_3.albedo;\n    _4713 = param_3.alpha;\n    _4714 = param_3.normal;\n    _4715 = param_3.metallic;\n    _4716 = param_3.roughness;\n    _4717 = param_3.occlusion;\n    _4718 = param_3.emission;\n    _4719 = param_3.clearcoat;\n    _4720 = param_3.clearcoat_roughness;\n    _4721 = param_3.sheen_color;\n    _4722 = param_3.sheen_roughness;\n    _4723 = param_3.anisotropy;\n    _4724 = param_3.anisotropy_rotation;\n    _4725 = param_3.specular;\n    _4726 = param_3.ior;\n    _4727 = param_3.specular_color;\n    _4728 = param_3.transmission;\n    _4729 = param_3.thickness;\n    _4730 = param_3.attenuation_color;\n    _4731 = param_3.attenuation_distance;\n    float3 param_4 = in.fa_world_pos;\n    float3 param_5 = _4673;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7, _401, fa_light_tex, fa_shadow_smp, fa_env_smp, fa_decal_tex);\n    _4712 = param_6;\n    _4714 = param_7;\n    float3 result;\n    if (_401.fa_emissive.w > 0.5)\n    {\n        result = _4712;\n    }\n    else\n    {\n        float3 _4295 = _4714;\n        float3 _4296 = fast::normalize(_4295);\n        _4714 = _4296;\n        float3 param_8 = _4296;\n        SurfaceInput param_9 = SurfaceInput{ in.fa_world_pos, _4673, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _4248, short(gl_FrontFacing) };\n        Surface param_10 = Surface{ _4712, _4713, _4714, _4715, _4716, _4717, _4718, _4719, _4720, _4721, _4722, _4723, _4724, _4725, _4726, _4727, _4728, _4729, _4730, _4731 };\n        float3 param_11 = fa_indirect_diffuse(param_8, _401, fa_env_smp, fa_probe_atlas, in.fa_lm, fa_lightmap);\n        float3 lit = ambient(param_9, param_10, param_11);\n        int _4315 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _4315; ln++)\n        {\n            int param_12 = ln;\n            int _4328 = fa_cl_light(param_12, _401, fa_light_tex, fa_shadow_smp, fa_cl_ndir, fa_cl_slot);\n            int param_13 = _4328;\n            if (fa_baked_keep(param_13, _401, fa_light_tex, fa_shadow_smp, in.fa_lm) <= 0.0)\n            {\n                continue;\n            }\n            int param_14 = _4328;\n            float3 param_15 = in.fa_world_pos;\n            float3 param_16 = _4673;\n            LightSample _4344 = fa_light_shadowed(param_14, param_15, param_16, _401, fa_light_tex, fa_shadow_smp, fa_light_atlas, fa_env_smp, fa_light_tint, fa_light_is_area, gl_FragCoord, _2058, fa_shadow_tex, in.fa_world_pos, fa_screen_tex, in.fa_lm);\n            SurfaceInput param_17 = SurfaceInput{ in.fa_world_pos, _4673, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _4248, short(gl_FrontFacing) };\n            Surface param_18 = Surface{ _4712, _4713, _4714, _4715, _4716, _4717, _4718, _4719, _4720, _4721, _4722, _4723, _4724, _4725, _4726, _4727, _4728, _4729, _4730, _4731 };\n            LightSample param_19 = _4344;\n            lit += light(param_17, param_18, param_19);\n        }\n        result = lit;\n    }\n    float3 _4359 = result;\n    float3 _4360 = _4359 + _4718;\n    result = _4360;\n    float3 param_20 = _4360;\n    float3 param_21 = in.fa_world_pos;\n    result = fa_shadow_debug(param_20, param_21, _2058);\n    bool _4369 = _401.fa_fog.w > 0.0;\n    bool _4376;\n    if (!_4369)\n    {\n        _4376 = _401.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _4376 = _4369;\n    }\n    if (_4376)\n    {\n        float3 _4385 = in.fa_world_pos - _401.fa_camera_pos.xyz;\n        float _4391 = dot(_4385, _401.fa_fog_c.xyz);\n        bool _4395 = _401.fa_fog_c.w > 0.5;\n        float _4396;\n        if (_4395)\n        {\n            _4396 = _4391;\n        }\n        else\n        {\n            _4396 = length(_4385);\n        }\n        float _4408 = _4396 - _401.fa_fog_b.x;\n        if (_4408 > 0.0)\n        {\n            float _4417 = _401.fa_fog.w * _4408;\n            float tau = _4417 * _4417;\n            if (_401.fa_fog_b.y > 0.0)\n            {\n                float _4433;\n                if (_4395)\n                {\n                    _4433 = in.fa_world_pos.y - (_401.fa_fog_c.y * _4391);\n                }\n                else\n                {\n                    _4433 = _401.fa_camera_pos.y;\n                }\n                float _4454 = mix(_4433, in.fa_world_pos.y, fast::clamp(_401.fa_fog_b.x / _4396, 0.0, 1.0));\n                float _4458 = in.fa_world_pos.y - _4454;\n                float _4463 = _4454 - _401.fa_fog_b.z;\n                float _4468 = in.fa_world_pos.y - _401.fa_fog_b.z;\n                bool _4471 = _4463 <= 0.0;\n                bool _4472 = !_4471;\n                bool _4478;\n                if (_4472)\n                {\n                    _4478 = _401.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4478 = _4471;\n                }\n                float _4479;\n                if (_4478)\n                {\n                    _4479 = _401.fa_fog_b.y;\n                }\n                else\n                {\n                    _4479 = _401.fa_fog_b.y * exp(-fast::min(_401.fa_fog_b.w * _4463, 80.0));\n                }\n                bool _4506;\n                if (_4472)\n                {\n                    _4506 = _401.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4506 = _4471;\n                }\n                float _4507;\n                if (_4506)\n                {\n                    _4507 = _401.fa_fog_b.y * _4463;\n                }\n                else\n                {\n                    _4507 = (_401.fa_fog_b.y * (1.0 - exp(-fast::min(_401.fa_fog_b.w * _4463, 80.0)))) / _401.fa_fog_b.w;\n                }\n                bool _4532 = _4468 <= 0.0;\n                bool _4539;\n                if (!_4532)\n                {\n                    _4539 = _401.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4539 = _4532;\n                }\n                float _4540;\n                if (_4539)\n                {\n                    _4540 = _401.fa_fog_b.y * _4468;\n                }\n                else\n                {\n                    _4540 = (_401.fa_fog_b.y * (1.0 - exp(-fast::min(_401.fa_fog_b.w * _4468, 80.0)))) / _401.fa_fog_b.w;\n                }\n                float _4567;\n                if (abs(_4458) < 0.001000000047497451305389404296875)\n                {\n                    _4567 = _4479;\n                }\n                else\n                {\n                    _4567 = (_4540 - _4507) / _4458;\n                }\n                tau += (_4408 * fast::max(_4567, 0.0));\n            }\n            result = mix(result, _401.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _4713);\n    return out;\n}\n\n",
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
            "size": 832,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_401",
            "msl_buffer_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2058",
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
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n    float4 fa_ct_a;\n    float4 fa_ct_b;\n    float4 fa_ct_vpx;\n    float4 fa_ct_vpy;\n    float4 fa_ct_vpw;\n    float4 fa_ct_fwd;\n    float4 fa_tr_a;\n    float4 fa_tr_b;\n    float4 fa_probe_sh[9];\n    float4 fa_atlas;\n    float4 fa_rpa_tile;\n    float4 fa_rpa_pos;\n    float4 fa_rpa_bx;\n    float4 fa_rpa_by;\n    float4 fa_rpa_bz;\n    float4 fa_rpb_tile;\n    float4 fa_rpb_pos;\n    float4 fa_rpb_bx;\n    float4 fa_rpb_by;\n    float4 fa_rpb_bz;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _56;\n    if (bool(i.front_facing))\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = fast::normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = fast::normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (bool(i.front_facing))\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _215, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _215.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _227 = fa_tex_fix(param_2, param_3);\n    float4 _828 = base_t;\n    _828.x = _227.x;\n    _828.y = _227.y;\n    _828.z = _227.z;\n    base_t = _828;\n    float4 _243 = (_828 * _215.fa_base_color) * i.vertex_color;\n    float3 _783 = i.world_normal;\n    if (_215.fa_maps.z > 0.5)\n    {\n        float param_4 = _215.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _277 = fa_tex_fix(param_6, param_7);\n        float3 _281 = (_277 * 2.0) - float3(1.0);\n        float2 _286 = _281.xy * _215.fa_maps.x;\n        float3 _836 = _281;\n        _836.x = _286.x;\n        _836.y = _286.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _836;\n        _783 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _215.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _315 = fa_tex_fix(param_12, param_13);\n    float4 _839 = mrt;\n    _839.x = _315.x;\n    _839.y = _315.y;\n    _839.z = _315.z;\n    mrt = _839;\n    float4 _345 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _215.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _345.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _357 = fa_tex_fix(param_16, param_17);\n    float param_18 = _215.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _387 = fa_tex_fix(param_20, param_21);\n    float _788 = _215.fa_layers_a.x;\n    float _789 = _215.fa_layers_a.y;\n    float _792 = _215.fa_layers_a.z;\n    float _791 = _215.fa_layers_b.w;\n    float _794 = _215.fa_layers_c.x;\n    if (_215.fa_layers_c.z > 0.5)\n    {\n        if (mod(_215.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _788 *= _357.y;\n            _789 *= _357.z;\n            _791 *= _345.w;\n        }\n        if (_215.fa_layers_c.z > 1.5)\n        {\n            _792 *= mrt.x;\n            _794 *= mrt.w;\n        }\n    }\n    return Surface{ _243.xyz, _243.w, _783, fast::clamp(_215.fa_pbr.x * _315.z, 0.0, 1.0), fast::clamp(_215.fa_pbr.y * _315.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_215.fa_maps.y * (_357.x - 1.0)), _215.fa_emissive.xyz + (_215.fa_model_emissive.xyz * _387), _788, _789, _215.fa_layers_b.xyz, _791, _792, _215.fa_layers_a.w, _794, _215.fa_layers_c.y, _215.fa_layers_d.xyz, _215.fa_tr_a.x, _215.fa_tr_a.y, _215.fa_tr_b.xyz, _215.fa_tr_a.z };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _215 [[buffer(1)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], sampler fa_smp [[sampler(0)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _678 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _678 = -_678;\n    }\n    float3 _540 = fast::normalize(_215.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _678, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _540, short(gl_FrontFacing) };\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _678, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _540, short(gl_FrontFacing) };\n    Surface param_2 = fa_standard_surface(param, fa_tex, fa_smp, _215, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    surface(param_1, param_2);\n    float3 _555 = fast::normalize(param_2.normal);\n    float3 _570 = fast::normalize(float3(dot(in.fa_pre_r0, _555), dot(in.fa_pre_r1, _555), dot(in.fa_pre_r2, _555)));\n    float _582 = _570.z;\n    float2 e = _570.xy / float2((abs(_570.x) + abs(_570.y)) + abs(_582));\n    if (_582 < 0.0)\n    {\n        e = (float2(1.0) - abs(e.yx)) * float2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    out.fa_frag_color = float4(fast::min(in.fa_pre_depth, 60000.0), e, 1.0);\n    return out;\n}\n\n",
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
            "size": 832,
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
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n    float4 fa_ct_a;\n    float4 fa_ct_b;\n    float4 fa_ct_vpx;\n    float4 fa_ct_vpy;\n    float4 fa_ct_vpw;\n    float4 fa_ct_fwd;\n    float4 fa_tr_a;\n    float4 fa_tr_b;\n    float4 fa_probe_sh[9];\n    float4 fa_atlas;\n    float4 fa_rpa_tile;\n    float4 fa_rpa_pos;\n    float4 fa_rpa_bx;\n    float4 fa_rpa_by;\n    float4 fa_rpa_bz;\n    float4 fa_rpb_tile;\n    float4 fa_rpb_pos;\n    float4 fa_rpb_bx;\n    float4 fa_rpb_by;\n    float4 fa_rpb_bz;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _56;\n    if (bool(i.front_facing))\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = fast::normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = fast::normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (bool(i.front_facing))\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _215, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _215.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _227 = fa_tex_fix(param_2, param_3);\n    float4 _828 = base_t;\n    _828.x = _227.x;\n    _828.y = _227.y;\n    _828.z = _227.z;\n    base_t = _828;\n    float4 _243 = (_828 * _215.fa_base_color) * i.vertex_color;\n    float3 _783 = i.world_normal;\n    if (_215.fa_maps.z > 0.5)\n    {\n        float param_4 = _215.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _277 = fa_tex_fix(param_6, param_7);\n        float3 _281 = (_277 * 2.0) - float3(1.0);\n        float2 _286 = _281.xy * _215.fa_maps.x;\n        float3 _836 = _281;\n        _836.x = _286.x;\n        _836.y = _286.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _836;\n        _783 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _215.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _315 = fa_tex_fix(param_12, param_13);\n    float4 _839 = mrt;\n    _839.x = _315.x;\n    _839.y = _315.y;\n    _839.z = _315.z;\n    mrt = _839;\n    float4 _345 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _215.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _345.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _357 = fa_tex_fix(param_16, param_17);\n    float param_18 = _215.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _387 = fa_tex_fix(param_20, param_21);\n    float _788 = _215.fa_layers_a.x;\n    float _789 = _215.fa_layers_a.y;\n    float _792 = _215.fa_layers_a.z;\n    float _791 = _215.fa_layers_b.w;\n    float _794 = _215.fa_layers_c.x;\n    if (_215.fa_layers_c.z > 0.5)\n    {\n        if (mod(_215.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _788 *= _357.y;\n            _789 *= _357.z;\n            _791 *= _345.w;\n        }\n        if (_215.fa_layers_c.z > 1.5)\n        {\n            _792 *= mrt.x;\n            _794 *= mrt.w;\n        }\n    }\n    return Surface{ _243.xyz, _243.w, _783, fast::clamp(_215.fa_pbr.x * _315.z, 0.0, 1.0), fast::clamp(_215.fa_pbr.y * _315.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_215.fa_maps.y * (_357.x - 1.0)), _215.fa_emissive.xyz + (_215.fa_model_emissive.xyz * _387), _788, _789, _215.fa_layers_b.xyz, _791, _792, _215.fa_layers_a.w, _794, _215.fa_layers_c.y, _215.fa_layers_d.xyz, _215.fa_tr_a.x, _215.fa_tr_a.y, _215.fa_tr_b.xyz, _215.fa_tr_a.z };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _215 [[buffer(1)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], sampler fa_smp [[sampler(0)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _678 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _678 = -_678;\n    }\n    float3 _540 = fast::normalize(_215.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _678, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _540, short(gl_FrontFacing) };\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _678, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _540, short(gl_FrontFacing) };\n    Surface param_2 = fa_standard_surface(param, fa_tex, fa_smp, _215, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    surface(param_1, param_2);\n    float3 _555 = fast::normalize(param_2.normal);\n    float3 _570 = fast::normalize(float3(dot(in.fa_pre_r0, _555), dot(in.fa_pre_r1, _555), dot(in.fa_pre_r2, _555)));\n    float _582 = _570.z;\n    float2 e = _570.xy / float2((abs(_570.x) + abs(_570.y)) + abs(_582));\n    if (_582 < 0.0)\n    {\n        e = (float2(1.0) - abs(e.yx)) * float2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    out.fa_frag_color = float4(fast::min(in.fa_pre_depth, 60000.0), e, 1.0);\n    return out;\n}\n\n",
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
            "size": 832,
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
