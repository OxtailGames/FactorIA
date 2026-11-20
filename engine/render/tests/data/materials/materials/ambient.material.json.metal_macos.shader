{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "63c8ed9ef72f0fba56beb38b3018a9ae9876604a67ae71ca005757f89f9b9e64",
  "slang": "metal_macos",
  "params": [],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float3 fa_lm [[user(locn5)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _131);\n    float3 _267 = _160.world_pos;\n    fa_world_pos = _267;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = _131.fa_view_proj * float4(_267, 1.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _131 [[buffer(0)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5, _131, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.gl_Position);\n    out.fa_lm = float3(0.0);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n    float4 fa_shadow_lcfg;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float3 fa_lm [[user(locn5)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_cluster_texel(thread const float3& world_pos, constant fa_mesh_fs_params& _320, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    bool _1288 = _320.fa_cl_info.x < 0.0;\n    bool _1295;\n    if (!_1288)\n    {\n        _1295 = _320.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _1295 = _1288;\n    }\n    bool _1303;\n    if (!_1295)\n    {\n        _1303 = _320.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _1303 = _1295;\n    }\n    bool _1310;\n    if (!_1303)\n    {\n        _1310 = _320.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _1310 = _1303;\n    }\n    bool _1317;\n    if (!_1310)\n    {\n        _1317 = _320.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _1317 = _1310;\n    }\n    if (_1317)\n    {\n        return float4(0.0);\n    }\n    float4 _1327 = float4(world_pos, 1.0);\n    float _1333 = dot(_320.fa_cl_vpw, _1327);\n    if (!(_1333 > 9.9999999747524270787835121154785e-07))\n    {\n        return float4(0.0);\n    }\n    float2 _1355 = float2(dot(_320.fa_cl_vpx, _1327), dot(_320.fa_cl_vpy, _1327)) / float2(_1333);\n    int _1359 = int(_320.fa_cl_grid.x);\n    int _1363 = int(_320.fa_cl_grid.y);\n    int param = (int(_320.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_320.fa_cl_fwd.xyz, world_pos) + _320.fa_cl_fwd.w, _320.fa_cl_grid.w) / _320.fa_cl_grid.w) * _320.fa_cl_grid.z)), 0, int(_320.fa_cl_info.y) - 1) * _1363) + clamp(int(floor(((_1355.y * 0.5) + 0.5) * _320.fa_cl_grid.y)), 0, _1363 - 1)) * _1359)) + clamp(int(floor(((_1355.x * 0.5) + 0.5) * _320.fa_cl_grid.x)), 0, _1359 - 1);\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, constant fa_mesh_fs_params& _320, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    float3 param = world_pos;\n    float4 _1439 = fa_cluster_texel(param, _320, fa_light_tex, fa_shadow_smp);\n    return int2(int(_1439.x), int(_1439.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, constant fa_mesh_fs_params& _320, texture2d<float> fa_light_tex, sampler fa_shadow_smp, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_320.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _3079 = fa_cluster_lookup(param, _320, fa_light_tex, fa_shadow_smp);\n    fa_cl_slot = _3079.x;\n    fa_cl_local = _3079.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _3233 = fa_linear_to_srgb(param);\n        c = _3233;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _3241 = fa_srgb_to_linear(param_1);\n            c = _3241;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _252;\n    if (bool(i.front_facing))\n    {\n        _252 = i.world_normal;\n    }\n    else\n    {\n        _252 = -i.world_normal;\n    }\n    float3 _276 = fast::normalize(i.world_tangent.xyz - (_252 * dot(_252, i.world_tangent.xyz)));\n    float3 _304 = fast::normalize(((_276 * m.x) + ((cross(_252, _276) * i.world_tangent.w) * m.y)) + (_252 * m.z));\n    float3 _307;\n    if (bool(i.front_facing))\n    {\n        _307 = _304;\n    }\n    else\n    {\n        _307 = -_304;\n    }\n    return _307;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _320, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _320.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _3272 = fa_tex_fix(param_2, param_3);\n    float4 _4322 = base_t;\n    _4322.x = _3272.x;\n    _4322.y = _3272.y;\n    _4322.z = _3272.z;\n    base_t = _4322;\n    float4 _3286 = (_4322 * _320.fa_base_color) * i.vertex_color;\n    float3 _4187 = i.world_normal;\n    if (_320.fa_maps.z > 0.5)\n    {\n        float param_4 = _320.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _3318 = fa_tex_fix(param_6, param_7);\n        float3 _3321 = (_3318 * 2.0) - float3(1.0);\n        float2 _3326 = _3321.xy * _320.fa_maps.x;\n        float3 _4330 = _3321;\n        _4330.x = _3326.x;\n        _4330.y = _3326.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _4330;\n        _4187 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _320.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _3354 = fa_tex_fix(param_12, param_13);\n    float4 _4333 = mrt;\n    _4333.x = _3354.x;\n    _4333.y = _3354.y;\n    _4333.z = _3354.z;\n    mrt = _4333;\n    float4 _3382 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _320.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _3382.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _3393 = fa_tex_fix(param_16, param_17);\n    float param_18 = _320.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _3423 = fa_tex_fix(param_20, param_21);\n    float _4192 = _320.fa_layers_a.x;\n    float _4193 = _320.fa_layers_a.y;\n    float _4196 = _320.fa_layers_a.z;\n    float _4195 = _320.fa_layers_b.w;\n    float _4198 = _320.fa_layers_c.x;\n    if (_320.fa_layers_c.z > 0.5)\n    {\n        if (mod(_320.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _4192 *= _3393.y;\n            _4193 *= _3393.z;\n            _4195 *= _3382.w;\n        }\n        if (_320.fa_layers_c.z > 1.5)\n        {\n            _4196 *= mrt.x;\n            _4198 *= mrt.w;\n        }\n    }\n    return Surface{ _3286.xyz, _3286.w, _4187, fast::clamp(_320.fa_pbr.x * _3354.z, 0.0, 1.0), fast::clamp(_320.fa_pbr.y * _3354.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_320.fa_maps.y * (_3393.x - 1.0)), _320.fa_emissive.xyz + (_320.fa_model_emissive.xyz * _3423), _4192, _4193, _320.fa_layers_b.xyz, _4195, _4196, _320.fa_layers_a.w, _4198, _320.fa_layers_c.y, _320.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_decal_tile(thread const float4& rect, thread const float2& uv, thread const float2& atlas, thread const float2& ddx, thread const float2& ddy, sampler fa_env_smp, texture2d<float> fa_decal_tex)\n{\n    float2 _1519 = rect.zw - rect.xy;\n    float2 _1523 = _1519 * atlas;\n    float2 _1527 = ddx * _1523;\n    float2 _1531 = ddy * _1523;\n    return fa_decal_tex.sample(fa_env_smp, (rect.xy + (fast::clamp(uv, float2(0.0), float2(1.0)) * _1519)), level(fast::clamp(0.5 * log2(fast::max(fast::max(dot(_1527, _1527), dot(_1531, _1531)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_apply_decals(thread const float3& world_pos, thread const float3& geo_normal, thread float3& albedo, thread float3& normal, constant fa_mesh_fs_params& _320, texture2d<float> fa_light_tex, sampler fa_shadow_smp, sampler fa_env_smp, texture2d<float> fa_decal_tex)\n{\n    bool _1564 = _320.fa_counts.y < 0.5;\n    bool _1571;\n    if (!_1564)\n    {\n        _1571 = _320.fa_counts.w < 0.5;\n    }\n    else\n    {\n        _1571 = _1564;\n    }\n    if (_1571)\n    {\n        return;\n    }\n    float3 _1577 = dfdx(world_pos);\n    float3 _1580 = dfdy(world_pos);\n    float3 param = world_pos;\n    float4 _1584 = fa_cluster_texel(param, _320, fa_light_tex, fa_shadow_smp);\n    int _1588 = int(_1584.w);\n    if (_1588 < 1)\n    {\n        return;\n    }\n    int _1598 = int(_320.fa_counts.y + 0.5);\n    int param_1 = _1598;\n    float4 _1602 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float2 _1605 = _1602.yz;\n    int _1609 = int(_1602.w);\n    int param_2 = _1598 + 1;\n    float4 _1614 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float _1615 = _1614.x;\n    int _1621 = int(_320.fa_counts.w + 0.5) - 1;\n    int _1625 = int(_1584.z);\n    float3 _1890;\n    for (int k = 0; k < _1588; k++)\n    {\n        int _1638 = _1625 + k;\n        int param_3 = _1609 + (_1638 >> 2);\n        int _1655 = (_1598 + 2) + (int(fa_light_texel(param_3, fa_light_tex, fa_shadow_smp)[_1638 & 3]) * 7);\n        int param_4 = _1655 + 6;\n        float4 _1660 = fa_light_texel(param_4, fa_light_tex, fa_shadow_smp);\n        if (((int(_1660.w + 0.5) >> _1621) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1655;\n        float4 _1675 = fa_light_texel(param_5, fa_light_tex, fa_shadow_smp);\n        int param_6 = _1655 + 1;\n        float4 _1680 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n        int param_7 = _1655 + 2;\n        float4 _1685 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n        float3 _1688 = _1675.xyz;\n        float _1693 = dot(_1688, world_pos) + _1675.w;\n        float3 _1695 = _1680.xyz;\n        float _1700 = dot(_1695, world_pos) + _1680.w;\n        float3 _1702 = _1685.xyz;\n        float _1707 = dot(_1702, world_pos) + _1685.w;\n        bool _1712 = abs(_1693) > 0.5;\n        bool _1720;\n        if (!_1712)\n        {\n            _1720 = abs(_1700) > 0.5;\n        }\n        else\n        {\n            _1720 = _1712;\n        }\n        bool _1728;\n        if (!_1720)\n        {\n            _1728 = abs(_1707) > 0.5;\n        }\n        else\n        {\n            _1728 = _1720;\n        }\n        if (_1728)\n        {\n            continue;\n        }\n        float _1743 = fast::clamp(dot(geo_normal, fast::normalize(_1702)) * _1660.z, 0.0, 1.0);\n        if (_1743 <= 0.0)\n        {\n            continue;\n        }\n        float _1763 = (fast::clamp((0.5 - abs(_1707)) * 10.0, 0.0, 1.0) * _1743) * _1660.x;\n        float2 _1771 = float2(_1693 + 0.5, 0.5 - _1700);\n        float2 _1781 = float2(dot(_1688, _1577), dot(_1695, _1577));\n        float2 _1791 = float2(dot(_1688, _1580), dot(_1695, _1580));\n        int param_8 = _1655 + 5;\n        float4 _1796 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n        int param_9 = _1655 + 3;\n        float4 _1801 = fa_light_texel(param_9, fa_light_tex, fa_shadow_smp);\n        int param_10 = _1655 + 4;\n        float4 _1806 = fa_light_texel(param_10, fa_light_tex, fa_shadow_smp);\n        float tex_a = 1.0;\n        float3 col = _1796.xyz;\n        bool _1816 = _1801.z > _1801.x;\n        if (_1816)\n        {\n            float4 param_11 = _1801;\n            float2 param_12 = _1771;\n            float2 param_13 = _1605;\n            float2 param_14 = _1781;\n            float2 param_15 = _1791;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15, fa_env_smp, fa_decal_tex);\n            if ((_1615 > 0.5) && (_1615 < 1.5))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1842 = fa_dc_to_linear(param_16);\n                float4 _4267 = tx;\n                _4267.x = _1842.x;\n                _4267.y = _1842.y;\n                _4267.z = _1842.z;\n                tx = _4267;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, float3(fast::clamp((_1763 * tex_a) * _1796.w, 0.0, 1.0)));\n        if (_1806.z > _1806.x)\n        {\n            float4 param_17 = _1806;\n            float2 param_18 = _1771;\n            float2 param_19 = _1605;\n            float2 param_20 = _1781;\n            float2 param_21 = _1791;\n            float4 _1886 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21, fa_env_smp, fa_decal_tex);\n            if (_1615 > 1.5)\n            {\n                float3 param_22 = _1886.xyz;\n                float3 _1896 = fa_dc_to_srgb(param_22);\n                _1890 = _1896;\n            }\n            else\n            {\n                _1890 = _1886.xyz;\n            }\n            float3 _1905 = (_1890 * 2.0) - float3(1.0);\n            float2 _1910 = _1905.xy * _1660.y;\n            float3 _1932 = (fast::normalize(_1688) * _1910.x) + (fast::normalize(_1695) * _1910.y);\n            float3 _1935 = fast::normalize(normal);\n            normal = fast::normalize(mix(_1935, fast::normalize((_1935 * fast::max(_1905.z, 0.0500000007450580596923828125)) + (_1932 - (_1935 * dot(_1935, _1932)))), float3(fast::clamp(_1763 * (_1816 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _320, sampler fa_env_smp, texturecube<float> fa_irr_tex)\n{\n    if (_320.fa_env_sky.w > 0.5)\n    {\n        return fa_irr_tex.sample(fa_env_smp, n, level(0.0)).xyz;\n    }\n    return _320.fa_ambient.xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_indirect_diffuse(thread const float3& n, constant fa_mesh_fs_params& _320, sampler fa_env_smp, texturecube<float> fa_irr_tex, thread float3& fa_lm, texture2d<float> fa_lightmap)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return fa_lightmap.sample(fa_env_smp, fa_lm.xy, level(0.0)).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param, _320, fa_env_smp, fa_irr_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 ambient(thread const SurfaceInput& i, thread const Surface& s, thread const float3& ambientColor)\n{\n    return float3(0.0, ambientColor.y, 0.0);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, constant fa_mesh_fs_params& _320, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (int(_320.fa_cl_info.x) + int(_320.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, constant fa_mesh_fs_params& _320, texture2d<float> fa_light_tex, sampler fa_shadow_smp, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, _320, fa_light_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_light_base(thread const int& li, constant fa_mesh_fs_params& _320)\n{\n    return li * ((_320.fa_ambient.w > 4.5) ? 8 : 4);\n}\n\nstatic inline __attribute__((always_inline))\nbool fa_light_baked(thread const int& li, constant fa_mesh_fs_params& _320, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li;\n    int param_1 = fa_light_base(param, _320) + 3;\n    return fa_light_texel(param_1, fa_light_tex, fa_shadow_smp).w > 0.5;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_light_type(thread const int& li, constant fa_mesh_fs_params& _320, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li;\n    int param_1 = fa_light_base(param, _320) + 1;\n    return fa_light_texel(param_1, fa_light_tex, fa_shadow_smp).w;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_atlas_fetch(thread const float2& texel, texture2d<float> fa_light_atlas, sampler fa_env_smp)\n{\n    return fa_light_atlas.sample(fa_env_smp, (texel / float2(int2(fa_light_atlas.get_width(), fa_light_atlas.get_height()))), level(0.0));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_cookie_sample(thread const float2& tile_origin, thread const float2& uv, texture2d<float> fa_light_atlas, sampler fa_env_smp)\n{\n    float2 param = (tile_origin + float2(1.0)) + (fast::clamp(uv, float2(0.0), float2(1.0)) * 254.0);\n    return fa_atlas_fetch(param, fa_light_atlas, fa_env_smp).xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_area_point(thread const float3& c, thread const float3& axis, thread const float3& ru, thread const float3& uu, thread const float& hx, thread const float& hy, thread const float& shape, thread const float3& p, thread const float3& r)\n{\n    bool _548 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        float3 _561 = (c - (ru * hx)) - p;\n        float3 _567 = ru * (2.0 * hx);\n        float _573 = fast::max(dot(_567, _567), 9.9999999392252902907785028219223e-09);\n        float _577 = dot(_561, _567);\n        float t = fast::clamp((-_577) / _573, 0.0, 1.0);\n        if (_548)\n        {\n            float _592 = dot(r, _567);\n            float _598 = _573 - (_592 * _592);\n            if (abs(_598) > (9.9999997473787516355514526367188e-06 * _573))\n            {\n                t = fast::clamp(((dot(r, _561) * _592) - _577) / _598, 0.0, 1.0);\n            }\n        }\n        return (p + _561) + (_567 * t);\n    }\n    float3 q = p;\n    float _630 = dot(r, axis);\n    bool _638;\n    if (_548)\n    {\n        _638 = abs(_630) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _638 = _548;\n    }\n    if (_638)\n    {\n        float _648 = dot(c - p, axis) / _630;\n        if (_648 > 0.0)\n        {\n            q = p + (r * _648);\n        }\n    }\n    float3 _661 = q - c;\n    float2 xy = float2(dot(_661, ru), dot(_661, uu));\n    if (shape > 0.5)\n    {\n        float _676 = length(xy);\n        if (_676 > hx)\n        {\n            xy *= (hx / _676);\n        }\n    }\n    else\n    {\n        xy = fast::clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cube_face(thread const float3& d)\n{\n    float3 _469 = abs(d);\n    float _471 = _469.x;\n    float _473 = _469.y;\n    bool _474 = _471 >= _473;\n    bool _482;\n    if (_474)\n    {\n        _482 = _471 >= _469.z;\n    }\n    else\n    {\n        _482 = _474;\n    }\n    int _483;\n    if (_482)\n    {\n        _483 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _496;\n        if (_473 >= _469.z)\n        {\n            _496 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _496 = (d.z > 0.0) ? 4 : 5;\n        }\n        _483 = _496;\n    }\n    return _483;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cube_face_basis(thread const int& f, thread float3& fwd, thread float3& up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0, 0.0, 0.0);\n        up = float3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0, 0.0, 0.0);\n            up = float3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0, 1.0, 0.0);\n                up = float3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0, -1.0, 0.0);\n                    up = float3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0, 0.0, 1.0);\n                        up = float3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0, 0.0, -1.0);\n                        up = float3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_ies_sample(thread const float2& tile_origin, thread const float3& d, thread const float3& axis, thread const float3& right, thread const float3& up, texture2d<float> fa_light_atlas, sampler fa_env_smp)\n{\n    float _422 = dot(d, right);\n    float _426 = dot(d, up);\n    float _437;\n    if (((_422 * _422) + (_426 * _426)) > 1.0000000133514319600180897396058e-10)\n    {\n        _437 = precise::atan2(_426, _422) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _437 = 0.0;\n    }\n    float2 param = tile_origin + float2(1.0 + ((_437 - floor(_437)) * 64.0), 1.0 + (acos(fast::clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param, fa_light_atlas, fa_env_smp).x;\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample_n(thread const int& li, thread const float3& world_pos, thread const float3& n, constant fa_mesh_fs_params& _320, texture2d<float> fa_light_tex, sampler fa_shadow_smp, texture2d<float> fa_light_atlas, sampler fa_env_smp, thread float3& fa_light_tint, thread bool& fa_light_is_area)\n{\n    int param = li;\n    int _714 = fa_light_base(param, _320);\n    bool _718 = _320.fa_ambient.w > 4.5;\n    int param_1 = _714;\n    float4 _722 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    int param_2 = _714 + 1;\n    float4 _727 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float _730 = _727.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = float3(1.0);\n    bool _742 = _718 && (_730 > 2.5);\n    fa_light_is_area = _742;\n    bool _744 = _730 < 0.5;\n    float3 l;\n    if (_744)\n    {\n        l = fast::normalize(_722.xyz);\n        if (_718)\n        {\n            int param_3 = _714 + 6;\n            float4 _758 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            if (_758.z > 0.5)\n            {\n                int param_4 = _714 + 4;\n                float4 _768 = fa_light_texel(param_4, fa_light_tex, fa_shadow_smp);\n                int param_5 = _714 + 5;\n                float4 _773 = fa_light_texel(param_5, fa_light_tex, fa_shadow_smp);\n                float2 param_6 = _758.xy;\n                float2 param_7 = fract(float2(dot(world_pos, _768.xyz) * _768.w, (-dot(world_pos, _773.xyz)) * _773.w) + float2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7, fa_light_atlas, fa_env_smp);\n            }\n        }\n    }\n    else\n    {\n        float3 _803 = _722.xyz;\n        float3 _805 = _803 - world_pos;\n        float3 to_light = _805;\n        float _808 = length(_805);\n        float reach = _808;\n        bool front = true;\n        if (_742)\n        {\n            int param_8 = _714 + 7;\n            reach = fast::max(_808 - fa_light_texel(param_8, fa_light_tex, fa_shadow_smp).w, 0.0);\n            int param_9 = _714 + 4;\n            float4 _832 = fa_light_texel(param_9, fa_light_tex, fa_shadow_smp);\n            int param_10 = _714 + 5;\n            float4 _837 = fa_light_texel(param_10, fa_light_tex, fa_shadow_smp);\n            int param_11 = _714 + 6;\n            float4 _842 = fa_light_texel(param_11, fa_light_tex, fa_shadow_smp);\n            float _843 = _842.w;\n            int param_12 = _714 + 2;\n            float3 _850 = fast::normalize(fa_light_texel(param_12, fa_light_tex, fa_shadow_smp).xyz);\n            bool _852 = _843 > 1.5;\n            bool _860;\n            if (!_852)\n            {\n                _860 = dot(_850, to_light) < 0.0;\n            }\n            else\n            {\n                _860 = _852;\n            }\n            front = _860;\n            float3 r = float3(0.0);\n            if (dot(n, n) > 0.5)\n            {\n                r = reflect(-fast::normalize(_320.fa_camera_pos.xyz - world_pos), fast::normalize(n));\n            }\n            float3 param_13 = _803;\n            float3 param_14 = _850;\n            float3 param_15 = _832.xyz;\n            float3 param_16 = _837.xyz;\n            float param_17 = _832.w;\n            float param_18 = _837.w;\n            float param_19 = _843;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _907 = length(to_light);\n        dist = _907;\n        l = to_light / float3(fast::max(_907, 9.9999997473787516355514526367188e-05));\n        float _921 = reach / fast::max(_722.w, 0.001000000047497451305389404296875);\n        float _927 = fast::clamp(1.0 - (_921 * _921), 0.0, 1.0);\n        float _929;\n        if (front)\n        {\n            _929 = _927 * _927;\n        }\n        else\n        {\n            _929 = 0.0;\n        }\n        atten = _929;\n        bool _940 = _730 < 2.5;\n        if ((_730 > 1.5) && _940)\n        {\n            int param_22 = _714 + 2;\n            float4 _948 = fa_light_texel(param_22, fa_light_tex, fa_shadow_smp);\n            float _958 = _948.w;\n            int param_23 = _714 + 3;\n            float4 _963 = fa_light_texel(param_23, fa_light_tex, fa_shadow_smp);\n            float _964 = _963.x;\n            float cos_inner = _964;\n            if (_964 > 1.5)\n            {\n                cos_inner = mix(_958, 1.0, 0.25);\n            }\n            atten *= smoothstep(_958, cos_inner, dot(-l, fast::normalize(_948.xyz)));\n        }\n        if (_718 && (_730 < 1.5))\n        {\n            int param_24 = _714 + 6;\n            float4 _988 = fa_light_texel(param_24, fa_light_tex, fa_shadow_smp);\n            if (_988.z > 0.5)\n            {\n                float3 _996 = -to_light;\n                int param_25 = _714 + 4;\n                int param_26 = _714 + 5;\n                float3 _1010 = fa_light_texel(param_25, fa_light_tex, fa_shadow_smp).xyz;\n                float3 _1014 = fa_light_texel(param_26, fa_light_tex, fa_shadow_smp).xyz;\n                float3 _1023 = float3(dot(_996, _1010), dot(_996, _1014), dot(_996, cross(_1010, _1014)));\n                float3 param_27 = _1023;\n                int _1027 = fa_cube_face(param_27);\n                int param_28 = _1027;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1054 = float2(dot(_1023, cross(param_29, param_30)), dot(_1023, param_30)) / float2(fast::max(dot(_1023, param_29), 9.9999997473787516355514526367188e-05));\n                int _1058 = _1027 / 3;\n                float2 param_31 = _988.xy + (float2(float(_1027 - (_1058 * 3)), float(_1058)) * 256.0);\n                float2 param_32 = float2(0.5 + (0.5 * _1054.x), 0.5 - (0.5 * _1054.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32, fa_light_atlas, fa_env_smp);\n            }\n            int param_33 = _714 + 7;\n            float4 _1088 = fa_light_texel(param_33, fa_light_tex, fa_shadow_smp);\n            if (_1088.z > 0.5)\n            {\n                int param_34 = _714 + 2;\n                int param_35 = _714 + 4;\n                int param_36 = _714 + 5;\n                float2 param_37 = _1088.xy;\n                float3 param_38 = -l;\n                float3 param_39 = fast::normalize(fa_light_texel(param_34, fa_light_tex, fa_shadow_smp).xyz);\n                float3 param_40 = fa_light_texel(param_35, fa_light_tex, fa_shadow_smp).xyz;\n                float3 param_41 = fa_light_texel(param_36, fa_light_tex, fa_shadow_smp).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41, fa_light_atlas, fa_env_smp);\n            }\n        }\n        else\n        {\n            if (_718 && _940)\n            {\n                int param_42 = _714 + 6;\n                float4 _1135 = fa_light_texel(param_42, fa_light_tex, fa_shadow_smp);\n                int param_43 = _714 + 7;\n                float4 _1140 = fa_light_texel(param_43, fa_light_tex, fa_shadow_smp);\n                bool _1143 = _1135.z > 0.5;\n                bool _1150;\n                if (!_1143)\n                {\n                    _1150 = _1140.z > 0.5;\n                }\n                else\n                {\n                    _1150 = _1143;\n                }\n                if (_1150)\n                {\n                    int param_44 = _714 + 2;\n                    float4 _1157 = fa_light_texel(param_44, fa_light_tex, fa_shadow_smp);\n                    float3 _1161 = fast::normalize(_1157.xyz);\n                    int param_45 = _714 + 4;\n                    float4 _1166 = fa_light_texel(param_45, fa_light_tex, fa_shadow_smp);\n                    int param_46 = _714 + 5;\n                    float4 _1171 = fa_light_texel(param_46, fa_light_tex, fa_shadow_smp);\n                    if (_1143)\n                    {\n                        float3 _1179 = -to_light;\n                        float _1186 = _1157.w;\n                        float _1202 = 0.5 / fast::max(dot(_1179, _1161) * (sqrt(fast::max(1.0 - (_1186 * _1186), 0.0)) / fast::max(_1186, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        float2 param_47 = _1135.xy;\n                        float2 param_48 = float2(0.5 + (dot(_1179, _1166.xyz) * _1202), 0.5 - (dot(_1179, _1171.xyz) * _1202));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48, fa_light_atlas, fa_env_smp);\n                    }\n                    if (_1140.z > 0.5)\n                    {\n                        float2 param_49 = _1140.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1161;\n                        float3 param_52 = _1166.xyz;\n                        float3 param_53 = _1171.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53, fa_light_atlas, fa_env_smp);\n                    }\n                }\n            }\n        }\n    }\n    float3 _4141 = _727.xyz * atten;\n    if (_718)\n    {\n        _4141 *= fa_light_tint;\n    }\n    int _1270;\n    if (_744)\n    {\n        _1270 = 0;\n    }\n    else\n    {\n        _1270 = ((_730 > 1.5) && (_730 < 2.5)) ? 2 : 1;\n    }\n    return LightSample{ l, _4141, atten, 1.0, dist, _1270 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _2017)\n{\n    float _2007;\n    if (i == 0)\n    {\n        _2007 = _2017.fa_shadow_split.x;\n    }\n    else\n    {\n        float _2023;\n        if (i == 1)\n        {\n            _2023 = _2017.fa_shadow_split.y;\n        }\n        else\n        {\n            float _2031;\n            if (i == 2)\n            {\n                _2031 = _2017.fa_shadow_split.z;\n            }\n            else\n            {\n                _2031 = _2017.fa_shadow_split.w;\n            }\n            _2023 = _2031;\n        }\n        _2007 = _2023;\n    }\n    return _2007;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_fetch(thread const float2& uv, thread const float4& rect, thread const float3& conv, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2064 = fa_shadow_depth(param, param_1, fa_shadow_smp, fa_shadow_tex);\n    float _2068;\n    if (conv.x < 0.5)\n    {\n        _2068 = _2064;\n    }\n    else\n    {\n        _2068 = (conv.y * conv.z) / (conv.z - (_2064 * (conv.z - conv.y)));\n    }\n    return _2068;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _1995 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_1995), sin(_1995)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_filter(thread const float2& uv, thread const float4& rect, thread const float& zr, thread const float& texel_m, thread const float& unit, thread const float& reach, thread const float& plane, thread const float3& conv, thread const int& mode, thread const float& k, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2017, texture2d<float> fa_shadow_tex)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2, fa_shadow_smp, fa_shadow_tex));\n    }\n    float _2114 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2123;\n        if (k < 0.0)\n        {\n            _2123 = (-k) / fast::max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2123 = k;\n        }\n        float _2143 = fast::clamp((_2123 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2114;\n            float2 _2162 = fa_shadow_vogel(param_3, param_4, param_5) * _2143;\n            float2 param_6 = uv + (_2162 * _2017.fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _2174 = fa_shadow_fetch(param_6, param_7, param_8, fa_shadow_smp, fa_shadow_tex);\n            if (_2174 < (zr - (length(_2162) * plane)))\n            {\n                sum += _2174;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2200 = sum / cnt;\n        float _2210;\n        if (k < 0.0)\n        {\n            _2210 = (-k) / fast::max(_2200, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2210 = k;\n        }\n        radius = fast::clamp(((fast::max(zr - _2200, 0.0) * unit) * _2210) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _2232 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2232; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2232;\n        float param_11 = _2114;\n        float2 _2251 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_2251 * _2017.fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_2251) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14, fa_shadow_smp, fa_shadow_tex));\n    }\n    return lit / float(_2232);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2017, texture2d<float> fa_shadow_tex)\n{\n    float _2293 = fast::max(_2017.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _2298 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _2304 = sqrt(1.0 - (_2298 * _2298));\n    float _2311 = fast::min(_2304 / fast::max(_2298, 0.20000000298023223876953125), 4.0);\n    float _2316;\n    if (_2017.fa_shadow_bias.y > 0.0)\n    {\n        _2316 = _2017.fa_shadow_bias.y;\n    }\n    else\n    {\n        _2316 = 1.5 * _2017.fa_shadow_info[ci].x;\n    }\n    float4 _2341 = _2017.fa_shadow_mat[ci] * float4(world + (n * (_2316 * _2304)), 1.0);\n    float _2348 = _2341.x;\n    bool _2351 = _2348 < _2017.fa_shadow_rect[ci].x;\n    bool _2360;\n    if (!_2351)\n    {\n        _2360 = _2348 > _2017.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2360 = _2351;\n    }\n    bool _2369;\n    if (!_2360)\n    {\n        _2369 = _2341.y < _2017.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2369 = _2360;\n    }\n    bool _2378;\n    if (!_2369)\n    {\n        _2378 = _2341.y > _2017.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2378 = _2369;\n    }\n    bool _2385;\n    if (!_2378)\n    {\n        _2385 = _2341.z > 1.0;\n    }\n    else\n    {\n        _2385 = _2378;\n    }\n    if (_2385)\n    {\n        return -1.0;\n    }\n    float _2393;\n    if (_2017.fa_shadow_bias.x > 0.0)\n    {\n        _2393 = _2017.fa_shadow_bias.x;\n    }\n    else\n    {\n        _2393 = 1.5 * _2017.fa_shadow_info[ci].x;\n    }\n    float2 param = _2341.xy;\n    float4 param_1 = _2017.fa_shadow_rect[ci];\n    float param_2 = _2341.z - ((_2393 * (1.0 + (0.5 * _2311))) / _2293);\n    float param_3 = _2017.fa_shadow_info[ci].x;\n    float param_4 = _2293;\n    float param_5 = _2293 * 0.25;\n    float param_6 = ((_2017.fa_shadow_info[ci].x * fast::min(_2311, 3.0)) * 0.5) / _2293;\n    float3 param_7 = float3(0.0);\n    int param_8 = int(_2017.fa_shadow_cfg.z + 0.5);\n    float param_9 = _2017.fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9, fa_shadow_smp, gl_FragCoord, _2017, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _320, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2017, texture2d<float> fa_shadow_tex)\n{\n    if (_320.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2781 = int(_2017.fa_shadow_cfg.x + 0.5);\n    if (_2781 < 1)\n    {\n        return 1.0;\n    }\n    float _2796 = dot(world - _2017.fa_shadow_eye.xyz, _2017.fa_shadow_fwd.xyz);\n    int param = _2781 - 1;\n    if (_2796 > fa_shadow_split_at(param, _2017))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2808 = _2781 > 1;\n    bool _2815;\n    if (_2808)\n    {\n        _2815 = _2796 > _2017.fa_shadow_split.x;\n    }\n    else\n    {\n        _2815 = _2808;\n    }\n    if (_2815)\n    {\n        ci = 1;\n    }\n    bool _2819 = _2781 > 2;\n    bool _2826;\n    if (_2819)\n    {\n        _2826 = _2796 > _2017.fa_shadow_split.y;\n    }\n    else\n    {\n        _2826 = _2819;\n    }\n    if (_2826)\n    {\n        ci = 2;\n    }\n    bool _2830 = _2781 > 3;\n    bool _2837;\n    if (_2830)\n    {\n        _2837 = _2796 > _2017.fa_shadow_split.z;\n    }\n    else\n    {\n        _2837 = _2830;\n    }\n    if (_2837)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2781)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2863 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_shadow_smp, gl_FragCoord, _2017, fa_shadow_tex);\n        s = _2863;\n        if (_2863 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_2017.fa_shadow_cfg.y > 0.0)\n    {\n        float _2888;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2888 = fa_shadow_split_at(param_5, _2017);\n        }\n        else\n        {\n            _2888 = _2017.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _2907 = _2017.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _2017) - _2888, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2918 = fast::clamp((_2796 - (fa_shadow_split_at(param_7, _2017) - _2907)) / _2907, 0.0, 1.0);\n        if (_2918 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2781)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _2939 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_shadow_smp, gl_FragCoord, _2017, fa_shadow_tex);\n                s2 = _2939;\n                if (_2939 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2918);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _320, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2017, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, _320, fa_shadow_smp, gl_FragCoord, _2017, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_local(thread const int& li, thread const float3& world, thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _320, texture2d<float> fa_light_tex, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2017, texture2d<float> fa_shadow_tex)\n{\n    bool _2451 = _320.fa_pbr.z < 0.5;\n    bool _2458;\n    if (!_2451)\n    {\n        _2458 = _2017.fa_shadow_lcfg.x < 0.5;\n    }\n    else\n    {\n        _2458 = _2451;\n    }\n    if (_2458)\n    {\n        return 1.0;\n    }\n    int param = (int(_2017.fa_shadow_lcfg.x + 0.5) - 1) + li;\n    float4 _2471 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    float _2472 = _2471.x;\n    if (_2472 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2481 = int(_2472 + 0.5);\n    int param_1 = _2481;\n    float4 _2485 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    int param_2 = _2481 + 1;\n    float4 _2490 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float fade = 1.0;\n    float _2493 = _2485.y;\n    if (_2493 > 0.0)\n    {\n        float _2510 = 1.0 - smoothstep(0.75 * _2493, _2493, length(world - _2017.fa_shadow_eye.xyz));\n        fade = _2510;\n        if (_2510 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2485.x > 1.5)\n    {\n        int param_3 = li;\n        int param_4 = fa_light_base(param_3, _320);\n        float3 param_5 = world - fa_light_texel(param_4, fa_light_tex, fa_shadow_smp).xyz;\n        face = fa_cube_face(param_5);\n    }\n    int _2539 = (_2481 + 2) + (face * 6);\n    int param_6 = _2539;\n    int param_7 = _2539 + 1;\n    int param_8 = _2539 + 3;\n    float4 _2553 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n    int param_9 = _2539 + 4;\n    float4 _2558 = fa_light_texel(param_9, fa_light_tex, fa_shadow_smp);\n    int param_10 = _2539 + 5;\n    float4 _2563 = fa_light_texel(param_10, fa_light_tex, fa_shadow_smp);\n    float _2575 = _2563.x * fast::max(dot(_2553, float4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2580 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _2603 = fast::clamp(dot(n, _2553.xyz), -1.0, 1.0);\n    int param_11 = li;\n    int param_12 = fa_light_base(param_11, _320);\n    float _2627 = fast::min(sqrt(1.0 - (_2603 * _2603)) / fast::max(abs(dot(n, world - fa_light_texel(param_12, fa_light_tex, fa_shadow_smp).xyz)) / fast::max(dot(_2553, float4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2630 = _2490.y;\n    float _2632;\n    if (_2630 > 0.0)\n    {\n        _2632 = _2630;\n    }\n    else\n    {\n        _2632 = 1.5 * _2575;\n    }\n    float4 _2652 = float4(world + (n * (_2632 * sqrt(1.0 - (_2580 * _2580)))), 1.0);\n    float _2656 = dot(_2553, _2652);\n    float _2659 = _2563.y;\n    if (_2656 < _2659)\n    {\n        return 1.0;\n    }\n    float2 _2674 = float2(dot(fa_light_texel(param_6, fa_light_tex, fa_shadow_smp), _2652), dot(fa_light_texel(param_7, fa_light_tex, fa_shadow_smp), _2652)) / float2(_2656);\n    float _2676 = _2674.x;\n    bool _2679 = _2676 < _2558.x;\n    bool _2688;\n    if (!_2679)\n    {\n        _2688 = _2676 > _2558.z;\n    }\n    else\n    {\n        _2688 = _2679;\n    }\n    bool _2697;\n    if (!_2688)\n    {\n        _2697 = _2674.y < _2558.y;\n    }\n    else\n    {\n        _2697 = _2688;\n    }\n    bool _2706;\n    if (!_2697)\n    {\n        _2706 = _2674.y > _2558.w;\n    }\n    else\n    {\n        _2706 = _2697;\n    }\n    if (_2706)\n    {\n        return 1.0;\n    }\n    float _2712 = _2490.x;\n    float _2714;\n    if (_2712 > 0.0)\n    {\n        _2714 = _2712;\n    }\n    else\n    {\n        _2714 = 1.5 * _2575;\n    }\n    float2 param_13 = _2674;\n    float4 param_14 = _2558;\n    float param_15 = _2656 - (_2714 * (1.0 + (0.5 * _2627)));\n    float param_16 = _2575;\n    float param_17 = 1.0;\n    float param_18 = _2563.z * 0.25;\n    float param_19 = (_2575 * fast::min(_2627, 3.0)) * 0.5;\n    float3 param_20 = float3(1.0, _2659, _2563.z);\n    int param_21 = int(_2485.z + 0.5);\n    float param_22 = _2485.w;\n    return mix(1.0, fa_shadow_filter(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21, param_22, fa_shadow_smp, gl_FragCoord, _2017, fa_shadow_tex), fade);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, constant fa_mesh_fs_params& _320, texture2d<float> fa_light_tex, sampler fa_shadow_smp, texture2d<float> fa_light_atlas, sampler fa_env_smp, thread float3& fa_light_tint, thread bool& fa_light_is_area, thread float4& gl_FragCoord, constant fa_shadows& _2017, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos, thread float3& fa_lm)\n{\n    bool _3106 = fa_lm.z > 0.5;\n    bool _3112;\n    if (_3106)\n    {\n        int param = li;\n        _3112 = fa_light_baked(param, _320, fa_light_tex, fa_shadow_smp);\n    }\n    else\n    {\n        _3112 = _3106;\n    }\n    if (_3112)\n    {\n        int param_1 = li;\n        return LightSample{ float3(0.0, 1.0, 0.0), float3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1, _320, fa_light_tex, fa_shadow_smp) + 0.5) };\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _3136 = fa_light_sample_n(param_2, param_3, param_4, _320, fa_light_tex, fa_shadow_smp, fa_light_atlas, fa_env_smp, fa_light_tint, fa_light_is_area);\n    float3 _4167 = _3136.color;\n    float _4169 = _3136.shadow;\n    if ((_3136.type == 0) && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _3136.direction;\n        float _3150 = fa_shadow_factor(param_5, param_6, _320, fa_shadow_smp, gl_FragCoord, _2017, fa_shadow_tex, fa_world_pos);\n        _4169 = _3150;\n        _4167 *= _3150;\n    }\n    else\n    {\n        bool _3161 = _3136.type != 0;\n        bool _3167;\n        if (_3161)\n        {\n            _3167 = _3136.attenuation > 0.0;\n        }\n        else\n        {\n            _3167 = _3161;\n        }\n        if (_3167)\n        {\n            int param_7 = li;\n            float3 param_8 = world_pos;\n            float3 param_9 = gn;\n            float3 param_10 = _3136.direction;\n            float _3179 = fa_shadow_local(param_7, param_8, param_9, param_10, _320, fa_light_tex, fa_shadow_smp, gl_FragCoord, _2017, fa_shadow_tex);\n            _4169 = _3179;\n            _4167 *= _3179;\n        }\n    }\n    return LightSample{ _3136.direction, _4167, _3136.attenuation, _4169, _3136._distance, _3136.type };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 light(thread const SurfaceInput& i, thread const Surface& s, thread const LightSample& l)\n{\n    return float3(0.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _2017)\n{\n    if (_2017.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _2963 = int(_2017.fa_shadow_cfg.x + 0.5);\n    float _2973 = dot(world - _2017.fa_shadow_eye.xyz, _2017.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _2978 = _2963 > 0;\n    bool _2987;\n    if (_2978)\n    {\n        int param = _2963 - 1;\n        _2987 = _2973 <= fa_shadow_split_at(param, _2017);\n    }\n    else\n    {\n        _2987 = _2978;\n    }\n    if (_2987)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _2993 = _2963 > 1;\n        bool _3000;\n        if (_2993)\n        {\n            _3000 = _2973 > _2017.fa_shadow_split.x;\n        }\n        else\n        {\n            _3000 = _2993;\n        }\n        if (_3000)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3006 = _2963 > 2;\n        bool _3013;\n        if (_3006)\n        {\n            _3013 = _2973 > _2017.fa_shadow_split.y;\n        }\n        else\n        {\n            _3013 = _3006;\n        }\n        if (_3013)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3019 = _2963 > 3;\n        bool _3026;\n        if (_3019)\n        {\n            _3026 = _2973 > _2017.fa_shadow_split.z;\n        }\n        else\n        {\n            _3026 = _3019;\n        }\n        if (_3026)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _320 [[buffer(1)]], constant fa_shadows& _2017 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_irr_tex [[texture(6)]], texture2d<float> fa_light_tex [[texture(7)]], texture2d<float> fa_light_atlas [[texture(8)]], texture2d<float> fa_lightmap [[texture(9)]], texture2d<float> fa_decal_tex [[texture(10)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _3983 = fast::normalize(in.fa_world_normal);\n    float3 fa_light_tint;\n    bool fa_light_is_area;\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _3983 = -_3983;\n    }\n    float3 _3567 = fast::normalize(_320.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, _320, fa_light_tex, fa_shadow_smp, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _3983, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _3567, short(gl_FrontFacing) };\n    Surface _3575 = fa_standard_surface(param_1, _320, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _4022 = _3575.albedo;\n    float _4023 = _3575.alpha;\n    float3 _4024 = _3575.normal;\n    float _4025 = _3575.metallic;\n    float _4026 = _3575.roughness;\n    float _4027 = _3575.occlusion;\n    float3 _4028 = _3575.emission;\n    float _4029 = _3575.clearcoat;\n    float _4030 = _3575.clearcoat_roughness;\n    float3 _4031 = _3575.sheen_color;\n    float _4032 = _3575.sheen_roughness;\n    float _4033 = _3575.anisotropy;\n    float _4034 = _3575.anisotropy_rotation;\n    float _4035 = _3575.specular;\n    float _4036 = _3575.ior;\n    float3 _4037 = _3575.specular_color;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _3983, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _3567, short(gl_FrontFacing) };\n    Surface param_3 = _3575;\n    surface(param_2, param_3);\n    _4022 = param_3.albedo;\n    _4023 = param_3.alpha;\n    _4024 = param_3.normal;\n    _4025 = param_3.metallic;\n    _4026 = param_3.roughness;\n    _4027 = param_3.occlusion;\n    _4028 = param_3.emission;\n    _4029 = param_3.clearcoat;\n    _4030 = param_3.clearcoat_roughness;\n    _4031 = param_3.sheen_color;\n    _4032 = param_3.sheen_roughness;\n    _4033 = param_3.anisotropy;\n    _4034 = param_3.anisotropy_rotation;\n    _4035 = param_3.specular;\n    _4036 = param_3.ior;\n    _4037 = param_3.specular_color;\n    float3 param_4 = in.fa_world_pos;\n    float3 param_5 = _3983;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7, _320, fa_light_tex, fa_shadow_smp, fa_env_smp, fa_decal_tex);\n    _4022 = param_6;\n    _4024 = param_7;\n    float3 result;\n    if (_320.fa_emissive.w > 0.5)\n    {\n        result = _4022;\n    }\n    else\n    {\n        float3 _3613 = _4024;\n        float3 _3614 = fast::normalize(_3613);\n        _4024 = _3614;\n        float3 param_8 = _3614;\n        SurfaceInput param_9 = SurfaceInput{ in.fa_world_pos, _3983, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _3567, short(gl_FrontFacing) };\n        Surface param_10 = Surface{ _4022, _4023, _4024, _4025, _4026, _4027, _4028, _4029, _4030, _4031, _4032, _4033, _4034, _4035, _4036, _4037 };\n        float3 param_11 = fa_indirect_diffuse(param_8, _320, fa_env_smp, fa_irr_tex, in.fa_lm, fa_lightmap);\n        float3 lit = ambient(param_9, param_10, param_11);\n        int _3633 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _3633; ln++)\n        {\n            int param_12 = ln;\n            int _3646 = fa_cl_light(param_12, _320, fa_light_tex, fa_shadow_smp, fa_cl_ndir, fa_cl_slot);\n            bool _3649 = in.fa_lm.z > 0.5;\n            bool _3655;\n            if (_3649)\n            {\n                int param_13 = _3646;\n                _3655 = fa_light_baked(param_13, _320, fa_light_tex, fa_shadow_smp);\n            }\n            else\n            {\n                _3655 = _3649;\n            }\n            if (_3655)\n            {\n                continue;\n            }\n            int param_14 = _3646;\n            float3 param_15 = in.fa_world_pos;\n            float3 param_16 = _3983;\n            LightSample _3667 = fa_light_shadowed(param_14, param_15, param_16, _320, fa_light_tex, fa_shadow_smp, fa_light_atlas, fa_env_smp, fa_light_tint, fa_light_is_area, gl_FragCoord, _2017, fa_shadow_tex, in.fa_world_pos, in.fa_lm);\n            SurfaceInput param_17 = SurfaceInput{ in.fa_world_pos, _3983, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _3567, short(gl_FrontFacing) };\n            Surface param_18 = Surface{ _4022, _4023, _4024, _4025, _4026, _4027, _4028, _4029, _4030, _4031, _4032, _4033, _4034, _4035, _4036, _4037 };\n            LightSample param_19 = _3667;\n            lit += light(param_17, param_18, param_19);\n        }\n        result = lit;\n    }\n    float3 _3682 = result;\n    float3 _3683 = _3682 + _4028;\n    result = _3683;\n    float3 param_20 = _3683;\n    float3 param_21 = in.fa_world_pos;\n    result = fa_shadow_debug(param_20, param_21, _2017);\n    bool _3692 = _320.fa_fog.w > 0.0;\n    bool _3699;\n    if (!_3692)\n    {\n        _3699 = _320.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _3699 = _3692;\n    }\n    if (_3699)\n    {\n        float3 _3708 = in.fa_world_pos - _320.fa_camera_pos.xyz;\n        float _3714 = dot(_3708, _320.fa_fog_c.xyz);\n        bool _3718 = _320.fa_fog_c.w > 0.5;\n        float _3719;\n        if (_3718)\n        {\n            _3719 = _3714;\n        }\n        else\n        {\n            _3719 = length(_3708);\n        }\n        float _3731 = _3719 - _320.fa_fog_b.x;\n        if (_3731 > 0.0)\n        {\n            float _3740 = _320.fa_fog.w * _3731;\n            float tau = _3740 * _3740;\n            if (_320.fa_fog_b.y > 0.0)\n            {\n                float _3756;\n                if (_3718)\n                {\n                    _3756 = in.fa_world_pos.y - (_320.fa_fog_c.y * _3714);\n                }\n                else\n                {\n                    _3756 = _320.fa_camera_pos.y;\n                }\n                float _3777 = mix(_3756, in.fa_world_pos.y, fast::clamp(_320.fa_fog_b.x / _3719, 0.0, 1.0));\n                float _3781 = in.fa_world_pos.y - _3777;\n                float _3786 = _3777 - _320.fa_fog_b.z;\n                float _3791 = in.fa_world_pos.y - _320.fa_fog_b.z;\n                bool _3794 = _3786 <= 0.0;\n                bool _3795 = !_3794;\n                bool _3801;\n                if (_3795)\n                {\n                    _3801 = _320.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3801 = _3794;\n                }\n                float _3802;\n                if (_3801)\n                {\n                    _3802 = _320.fa_fog_b.y;\n                }\n                else\n                {\n                    _3802 = _320.fa_fog_b.y * exp(-fast::min(_320.fa_fog_b.w * _3786, 80.0));\n                }\n                bool _3829;\n                if (_3795)\n                {\n                    _3829 = _320.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3829 = _3794;\n                }\n                float _3830;\n                if (_3829)\n                {\n                    _3830 = _320.fa_fog_b.y * _3786;\n                }\n                else\n                {\n                    _3830 = (_320.fa_fog_b.y * (1.0 - exp(-fast::min(_320.fa_fog_b.w * _3786, 80.0)))) / _320.fa_fog_b.w;\n                }\n                bool _3855 = _3791 <= 0.0;\n                bool _3862;\n                if (!_3855)\n                {\n                    _3862 = _320.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3862 = _3855;\n                }\n                float _3863;\n                if (_3862)\n                {\n                    _3863 = _320.fa_fog_b.y * _3791;\n                }\n                else\n                {\n                    _3863 = (_320.fa_fog_b.y * (1.0 - exp(-fast::min(_320.fa_fog_b.w * _3791, 80.0)))) / _320.fa_fog_b.w;\n                }\n                float _3890;\n                if (abs(_3781) < 0.001000000047497451305389404296875)\n                {\n                    _3890 = _3802;\n                }\n                else\n                {\n                    _3890 = (_3863 - _3830) / _3781;\n                }\n                tau += (_3731 * fast::max(_3890, 0.0));\n            }\n            result = mix(result, _320.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _4023);\n    return out;\n}\n\n",
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
            "inst_name": "_320",
            "msl_buffer_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2017",
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
              "slot": 15,
              "stage": "fragment",
              "name": "fa_irr_tex",
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
            "name": "fa_irr_tex_fa_env_smp",
            "view_name": "fa_irr_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 15,
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
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n    float4 fa_shadow_lcfg;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float3 fa_lm [[user(locn5)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_cluster_texel(thread const float3& world_pos, constant fa_mesh_fs_params& _320, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    bool _1288 = _320.fa_cl_info.x < 0.0;\n    bool _1295;\n    if (!_1288)\n    {\n        _1295 = _320.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _1295 = _1288;\n    }\n    bool _1303;\n    if (!_1295)\n    {\n        _1303 = _320.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _1303 = _1295;\n    }\n    bool _1310;\n    if (!_1303)\n    {\n        _1310 = _320.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _1310 = _1303;\n    }\n    bool _1317;\n    if (!_1310)\n    {\n        _1317 = _320.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _1317 = _1310;\n    }\n    if (_1317)\n    {\n        return float4(0.0);\n    }\n    float4 _1327 = float4(world_pos, 1.0);\n    float _1333 = dot(_320.fa_cl_vpw, _1327);\n    if (!(_1333 > 9.9999999747524270787835121154785e-07))\n    {\n        return float4(0.0);\n    }\n    float2 _1355 = float2(dot(_320.fa_cl_vpx, _1327), dot(_320.fa_cl_vpy, _1327)) / float2(_1333);\n    int _1359 = int(_320.fa_cl_grid.x);\n    int _1363 = int(_320.fa_cl_grid.y);\n    int param = (int(_320.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_320.fa_cl_fwd.xyz, world_pos) + _320.fa_cl_fwd.w, _320.fa_cl_grid.w) / _320.fa_cl_grid.w) * _320.fa_cl_grid.z)), 0, int(_320.fa_cl_info.y) - 1) * _1363) + clamp(int(floor(((_1355.y * 0.5) + 0.5) * _320.fa_cl_grid.y)), 0, _1363 - 1)) * _1359)) + clamp(int(floor(((_1355.x * 0.5) + 0.5) * _320.fa_cl_grid.x)), 0, _1359 - 1);\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, constant fa_mesh_fs_params& _320, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    float3 param = world_pos;\n    float4 _1439 = fa_cluster_texel(param, _320, fa_light_tex, fa_shadow_smp);\n    return int2(int(_1439.x), int(_1439.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, constant fa_mesh_fs_params& _320, texture2d<float> fa_light_tex, sampler fa_shadow_smp, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_320.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _3079 = fa_cluster_lookup(param, _320, fa_light_tex, fa_shadow_smp);\n    fa_cl_slot = _3079.x;\n    fa_cl_local = _3079.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _3233 = fa_linear_to_srgb(param);\n        c = _3233;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _3241 = fa_srgb_to_linear(param_1);\n            c = _3241;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _252;\n    if (bool(i.front_facing))\n    {\n        _252 = i.world_normal;\n    }\n    else\n    {\n        _252 = -i.world_normal;\n    }\n    float3 _276 = fast::normalize(i.world_tangent.xyz - (_252 * dot(_252, i.world_tangent.xyz)));\n    float3 _304 = fast::normalize(((_276 * m.x) + ((cross(_252, _276) * i.world_tangent.w) * m.y)) + (_252 * m.z));\n    float3 _307;\n    if (bool(i.front_facing))\n    {\n        _307 = _304;\n    }\n    else\n    {\n        _307 = -_304;\n    }\n    return _307;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _320, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _320.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _3272 = fa_tex_fix(param_2, param_3);\n    float4 _4322 = base_t;\n    _4322.x = _3272.x;\n    _4322.y = _3272.y;\n    _4322.z = _3272.z;\n    base_t = _4322;\n    float4 _3286 = (_4322 * _320.fa_base_color) * i.vertex_color;\n    float3 _4187 = i.world_normal;\n    if (_320.fa_maps.z > 0.5)\n    {\n        float param_4 = _320.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _3318 = fa_tex_fix(param_6, param_7);\n        float3 _3321 = (_3318 * 2.0) - float3(1.0);\n        float2 _3326 = _3321.xy * _320.fa_maps.x;\n        float3 _4330 = _3321;\n        _4330.x = _3326.x;\n        _4330.y = _3326.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _4330;\n        _4187 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _320.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _3354 = fa_tex_fix(param_12, param_13);\n    float4 _4333 = mrt;\n    _4333.x = _3354.x;\n    _4333.y = _3354.y;\n    _4333.z = _3354.z;\n    mrt = _4333;\n    float4 _3382 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _320.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _3382.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _3393 = fa_tex_fix(param_16, param_17);\n    float param_18 = _320.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _3423 = fa_tex_fix(param_20, param_21);\n    float _4192 = _320.fa_layers_a.x;\n    float _4193 = _320.fa_layers_a.y;\n    float _4196 = _320.fa_layers_a.z;\n    float _4195 = _320.fa_layers_b.w;\n    float _4198 = _320.fa_layers_c.x;\n    if (_320.fa_layers_c.z > 0.5)\n    {\n        if (mod(_320.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _4192 *= _3393.y;\n            _4193 *= _3393.z;\n            _4195 *= _3382.w;\n        }\n        if (_320.fa_layers_c.z > 1.5)\n        {\n            _4196 *= mrt.x;\n            _4198 *= mrt.w;\n        }\n    }\n    return Surface{ _3286.xyz, _3286.w, _4187, fast::clamp(_320.fa_pbr.x * _3354.z, 0.0, 1.0), fast::clamp(_320.fa_pbr.y * _3354.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_320.fa_maps.y * (_3393.x - 1.0)), _320.fa_emissive.xyz + (_320.fa_model_emissive.xyz * _3423), _4192, _4193, _320.fa_layers_b.xyz, _4195, _4196, _320.fa_layers_a.w, _4198, _320.fa_layers_c.y, _320.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_decal_tile(thread const float4& rect, thread const float2& uv, thread const float2& atlas, thread const float2& ddx, thread const float2& ddy, sampler fa_env_smp, texture2d<float> fa_decal_tex)\n{\n    float2 _1519 = rect.zw - rect.xy;\n    float2 _1523 = _1519 * atlas;\n    float2 _1527 = ddx * _1523;\n    float2 _1531 = ddy * _1523;\n    return fa_decal_tex.sample(fa_env_smp, (rect.xy + (fast::clamp(uv, float2(0.0), float2(1.0)) * _1519)), level(fast::clamp(0.5 * log2(fast::max(fast::max(dot(_1527, _1527), dot(_1531, _1531)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_apply_decals(thread const float3& world_pos, thread const float3& geo_normal, thread float3& albedo, thread float3& normal, constant fa_mesh_fs_params& _320, texture2d<float> fa_light_tex, sampler fa_shadow_smp, sampler fa_env_smp, texture2d<float> fa_decal_tex)\n{\n    bool _1564 = _320.fa_counts.y < 0.5;\n    bool _1571;\n    if (!_1564)\n    {\n        _1571 = _320.fa_counts.w < 0.5;\n    }\n    else\n    {\n        _1571 = _1564;\n    }\n    if (_1571)\n    {\n        return;\n    }\n    float3 _1577 = dfdx(world_pos);\n    float3 _1580 = dfdy(world_pos);\n    float3 param = world_pos;\n    float4 _1584 = fa_cluster_texel(param, _320, fa_light_tex, fa_shadow_smp);\n    int _1588 = int(_1584.w);\n    if (_1588 < 1)\n    {\n        return;\n    }\n    int _1598 = int(_320.fa_counts.y + 0.5);\n    int param_1 = _1598;\n    float4 _1602 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float2 _1605 = _1602.yz;\n    int _1609 = int(_1602.w);\n    int param_2 = _1598 + 1;\n    float4 _1614 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float _1615 = _1614.x;\n    int _1621 = int(_320.fa_counts.w + 0.5) - 1;\n    int _1625 = int(_1584.z);\n    float3 _1890;\n    for (int k = 0; k < _1588; k++)\n    {\n        int _1638 = _1625 + k;\n        int param_3 = _1609 + (_1638 >> 2);\n        int _1655 = (_1598 + 2) + (int(fa_light_texel(param_3, fa_light_tex, fa_shadow_smp)[_1638 & 3]) * 7);\n        int param_4 = _1655 + 6;\n        float4 _1660 = fa_light_texel(param_4, fa_light_tex, fa_shadow_smp);\n        if (((int(_1660.w + 0.5) >> _1621) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1655;\n        float4 _1675 = fa_light_texel(param_5, fa_light_tex, fa_shadow_smp);\n        int param_6 = _1655 + 1;\n        float4 _1680 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n        int param_7 = _1655 + 2;\n        float4 _1685 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n        float3 _1688 = _1675.xyz;\n        float _1693 = dot(_1688, world_pos) + _1675.w;\n        float3 _1695 = _1680.xyz;\n        float _1700 = dot(_1695, world_pos) + _1680.w;\n        float3 _1702 = _1685.xyz;\n        float _1707 = dot(_1702, world_pos) + _1685.w;\n        bool _1712 = abs(_1693) > 0.5;\n        bool _1720;\n        if (!_1712)\n        {\n            _1720 = abs(_1700) > 0.5;\n        }\n        else\n        {\n            _1720 = _1712;\n        }\n        bool _1728;\n        if (!_1720)\n        {\n            _1728 = abs(_1707) > 0.5;\n        }\n        else\n        {\n            _1728 = _1720;\n        }\n        if (_1728)\n        {\n            continue;\n        }\n        float _1743 = fast::clamp(dot(geo_normal, fast::normalize(_1702)) * _1660.z, 0.0, 1.0);\n        if (_1743 <= 0.0)\n        {\n            continue;\n        }\n        float _1763 = (fast::clamp((0.5 - abs(_1707)) * 10.0, 0.0, 1.0) * _1743) * _1660.x;\n        float2 _1771 = float2(_1693 + 0.5, 0.5 - _1700);\n        float2 _1781 = float2(dot(_1688, _1577), dot(_1695, _1577));\n        float2 _1791 = float2(dot(_1688, _1580), dot(_1695, _1580));\n        int param_8 = _1655 + 5;\n        float4 _1796 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n        int param_9 = _1655 + 3;\n        float4 _1801 = fa_light_texel(param_9, fa_light_tex, fa_shadow_smp);\n        int param_10 = _1655 + 4;\n        float4 _1806 = fa_light_texel(param_10, fa_light_tex, fa_shadow_smp);\n        float tex_a = 1.0;\n        float3 col = _1796.xyz;\n        bool _1816 = _1801.z > _1801.x;\n        if (_1816)\n        {\n            float4 param_11 = _1801;\n            float2 param_12 = _1771;\n            float2 param_13 = _1605;\n            float2 param_14 = _1781;\n            float2 param_15 = _1791;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15, fa_env_smp, fa_decal_tex);\n            if ((_1615 > 0.5) && (_1615 < 1.5))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1842 = fa_dc_to_linear(param_16);\n                float4 _4267 = tx;\n                _4267.x = _1842.x;\n                _4267.y = _1842.y;\n                _4267.z = _1842.z;\n                tx = _4267;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, float3(fast::clamp((_1763 * tex_a) * _1796.w, 0.0, 1.0)));\n        if (_1806.z > _1806.x)\n        {\n            float4 param_17 = _1806;\n            float2 param_18 = _1771;\n            float2 param_19 = _1605;\n            float2 param_20 = _1781;\n            float2 param_21 = _1791;\n            float4 _1886 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21, fa_env_smp, fa_decal_tex);\n            if (_1615 > 1.5)\n            {\n                float3 param_22 = _1886.xyz;\n                float3 _1896 = fa_dc_to_srgb(param_22);\n                _1890 = _1896;\n            }\n            else\n            {\n                _1890 = _1886.xyz;\n            }\n            float3 _1905 = (_1890 * 2.0) - float3(1.0);\n            float2 _1910 = _1905.xy * _1660.y;\n            float3 _1932 = (fast::normalize(_1688) * _1910.x) + (fast::normalize(_1695) * _1910.y);\n            float3 _1935 = fast::normalize(normal);\n            normal = fast::normalize(mix(_1935, fast::normalize((_1935 * fast::max(_1905.z, 0.0500000007450580596923828125)) + (_1932 - (_1935 * dot(_1935, _1932)))), float3(fast::clamp(_1763 * (_1816 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _320, sampler fa_env_smp, texturecube<float> fa_irr_tex)\n{\n    if (_320.fa_env_sky.w > 0.5)\n    {\n        return fa_irr_tex.sample(fa_env_smp, n, level(0.0)).xyz;\n    }\n    return _320.fa_ambient.xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_indirect_diffuse(thread const float3& n, constant fa_mesh_fs_params& _320, sampler fa_env_smp, texturecube<float> fa_irr_tex, thread float3& fa_lm, texture2d<float> fa_lightmap)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return fa_lightmap.sample(fa_env_smp, fa_lm.xy, level(0.0)).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param, _320, fa_env_smp, fa_irr_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 ambient(thread const SurfaceInput& i, thread const Surface& s, thread const float3& ambientColor)\n{\n    return float3(0.0, ambientColor.y, 0.0);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, constant fa_mesh_fs_params& _320, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (int(_320.fa_cl_info.x) + int(_320.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, constant fa_mesh_fs_params& _320, texture2d<float> fa_light_tex, sampler fa_shadow_smp, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, _320, fa_light_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_light_base(thread const int& li, constant fa_mesh_fs_params& _320)\n{\n    return li * ((_320.fa_ambient.w > 4.5) ? 8 : 4);\n}\n\nstatic inline __attribute__((always_inline))\nbool fa_light_baked(thread const int& li, constant fa_mesh_fs_params& _320, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li;\n    int param_1 = fa_light_base(param, _320) + 3;\n    return fa_light_texel(param_1, fa_light_tex, fa_shadow_smp).w > 0.5;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_light_type(thread const int& li, constant fa_mesh_fs_params& _320, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li;\n    int param_1 = fa_light_base(param, _320) + 1;\n    return fa_light_texel(param_1, fa_light_tex, fa_shadow_smp).w;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_atlas_fetch(thread const float2& texel, texture2d<float> fa_light_atlas, sampler fa_env_smp)\n{\n    return fa_light_atlas.sample(fa_env_smp, (texel / float2(int2(fa_light_atlas.get_width(), fa_light_atlas.get_height()))), level(0.0));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_cookie_sample(thread const float2& tile_origin, thread const float2& uv, texture2d<float> fa_light_atlas, sampler fa_env_smp)\n{\n    float2 param = (tile_origin + float2(1.0)) + (fast::clamp(uv, float2(0.0), float2(1.0)) * 254.0);\n    return fa_atlas_fetch(param, fa_light_atlas, fa_env_smp).xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_area_point(thread const float3& c, thread const float3& axis, thread const float3& ru, thread const float3& uu, thread const float& hx, thread const float& hy, thread const float& shape, thread const float3& p, thread const float3& r)\n{\n    bool _548 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        float3 _561 = (c - (ru * hx)) - p;\n        float3 _567 = ru * (2.0 * hx);\n        float _573 = fast::max(dot(_567, _567), 9.9999999392252902907785028219223e-09);\n        float _577 = dot(_561, _567);\n        float t = fast::clamp((-_577) / _573, 0.0, 1.0);\n        if (_548)\n        {\n            float _592 = dot(r, _567);\n            float _598 = _573 - (_592 * _592);\n            if (abs(_598) > (9.9999997473787516355514526367188e-06 * _573))\n            {\n                t = fast::clamp(((dot(r, _561) * _592) - _577) / _598, 0.0, 1.0);\n            }\n        }\n        return (p + _561) + (_567 * t);\n    }\n    float3 q = p;\n    float _630 = dot(r, axis);\n    bool _638;\n    if (_548)\n    {\n        _638 = abs(_630) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _638 = _548;\n    }\n    if (_638)\n    {\n        float _648 = dot(c - p, axis) / _630;\n        if (_648 > 0.0)\n        {\n            q = p + (r * _648);\n        }\n    }\n    float3 _661 = q - c;\n    float2 xy = float2(dot(_661, ru), dot(_661, uu));\n    if (shape > 0.5)\n    {\n        float _676 = length(xy);\n        if (_676 > hx)\n        {\n            xy *= (hx / _676);\n        }\n    }\n    else\n    {\n        xy = fast::clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cube_face(thread const float3& d)\n{\n    float3 _469 = abs(d);\n    float _471 = _469.x;\n    float _473 = _469.y;\n    bool _474 = _471 >= _473;\n    bool _482;\n    if (_474)\n    {\n        _482 = _471 >= _469.z;\n    }\n    else\n    {\n        _482 = _474;\n    }\n    int _483;\n    if (_482)\n    {\n        _483 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _496;\n        if (_473 >= _469.z)\n        {\n            _496 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _496 = (d.z > 0.0) ? 4 : 5;\n        }\n        _483 = _496;\n    }\n    return _483;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cube_face_basis(thread const int& f, thread float3& fwd, thread float3& up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0, 0.0, 0.0);\n        up = float3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0, 0.0, 0.0);\n            up = float3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0, 1.0, 0.0);\n                up = float3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0, -1.0, 0.0);\n                    up = float3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0, 0.0, 1.0);\n                        up = float3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0, 0.0, -1.0);\n                        up = float3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_ies_sample(thread const float2& tile_origin, thread const float3& d, thread const float3& axis, thread const float3& right, thread const float3& up, texture2d<float> fa_light_atlas, sampler fa_env_smp)\n{\n    float _422 = dot(d, right);\n    float _426 = dot(d, up);\n    float _437;\n    if (((_422 * _422) + (_426 * _426)) > 1.0000000133514319600180897396058e-10)\n    {\n        _437 = precise::atan2(_426, _422) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _437 = 0.0;\n    }\n    float2 param = tile_origin + float2(1.0 + ((_437 - floor(_437)) * 64.0), 1.0 + (acos(fast::clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param, fa_light_atlas, fa_env_smp).x;\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample_n(thread const int& li, thread const float3& world_pos, thread const float3& n, constant fa_mesh_fs_params& _320, texture2d<float> fa_light_tex, sampler fa_shadow_smp, texture2d<float> fa_light_atlas, sampler fa_env_smp, thread float3& fa_light_tint, thread bool& fa_light_is_area)\n{\n    int param = li;\n    int _714 = fa_light_base(param, _320);\n    bool _718 = _320.fa_ambient.w > 4.5;\n    int param_1 = _714;\n    float4 _722 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    int param_2 = _714 + 1;\n    float4 _727 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float _730 = _727.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = float3(1.0);\n    bool _742 = _718 && (_730 > 2.5);\n    fa_light_is_area = _742;\n    bool _744 = _730 < 0.5;\n    float3 l;\n    if (_744)\n    {\n        l = fast::normalize(_722.xyz);\n        if (_718)\n        {\n            int param_3 = _714 + 6;\n            float4 _758 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            if (_758.z > 0.5)\n            {\n                int param_4 = _714 + 4;\n                float4 _768 = fa_light_texel(param_4, fa_light_tex, fa_shadow_smp);\n                int param_5 = _714 + 5;\n                float4 _773 = fa_light_texel(param_5, fa_light_tex, fa_shadow_smp);\n                float2 param_6 = _758.xy;\n                float2 param_7 = fract(float2(dot(world_pos, _768.xyz) * _768.w, (-dot(world_pos, _773.xyz)) * _773.w) + float2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7, fa_light_atlas, fa_env_smp);\n            }\n        }\n    }\n    else\n    {\n        float3 _803 = _722.xyz;\n        float3 _805 = _803 - world_pos;\n        float3 to_light = _805;\n        float _808 = length(_805);\n        float reach = _808;\n        bool front = true;\n        if (_742)\n        {\n            int param_8 = _714 + 7;\n            reach = fast::max(_808 - fa_light_texel(param_8, fa_light_tex, fa_shadow_smp).w, 0.0);\n            int param_9 = _714 + 4;\n            float4 _832 = fa_light_texel(param_9, fa_light_tex, fa_shadow_smp);\n            int param_10 = _714 + 5;\n            float4 _837 = fa_light_texel(param_10, fa_light_tex, fa_shadow_smp);\n            int param_11 = _714 + 6;\n            float4 _842 = fa_light_texel(param_11, fa_light_tex, fa_shadow_smp);\n            float _843 = _842.w;\n            int param_12 = _714 + 2;\n            float3 _850 = fast::normalize(fa_light_texel(param_12, fa_light_tex, fa_shadow_smp).xyz);\n            bool _852 = _843 > 1.5;\n            bool _860;\n            if (!_852)\n            {\n                _860 = dot(_850, to_light) < 0.0;\n            }\n            else\n            {\n                _860 = _852;\n            }\n            front = _860;\n            float3 r = float3(0.0);\n            if (dot(n, n) > 0.5)\n            {\n                r = reflect(-fast::normalize(_320.fa_camera_pos.xyz - world_pos), fast::normalize(n));\n            }\n            float3 param_13 = _803;\n            float3 param_14 = _850;\n            float3 param_15 = _832.xyz;\n            float3 param_16 = _837.xyz;\n            float param_17 = _832.w;\n            float param_18 = _837.w;\n            float param_19 = _843;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _907 = length(to_light);\n        dist = _907;\n        l = to_light / float3(fast::max(_907, 9.9999997473787516355514526367188e-05));\n        float _921 = reach / fast::max(_722.w, 0.001000000047497451305389404296875);\n        float _927 = fast::clamp(1.0 - (_921 * _921), 0.0, 1.0);\n        float _929;\n        if (front)\n        {\n            _929 = _927 * _927;\n        }\n        else\n        {\n            _929 = 0.0;\n        }\n        atten = _929;\n        bool _940 = _730 < 2.5;\n        if ((_730 > 1.5) && _940)\n        {\n            int param_22 = _714 + 2;\n            float4 _948 = fa_light_texel(param_22, fa_light_tex, fa_shadow_smp);\n            float _958 = _948.w;\n            int param_23 = _714 + 3;\n            float4 _963 = fa_light_texel(param_23, fa_light_tex, fa_shadow_smp);\n            float _964 = _963.x;\n            float cos_inner = _964;\n            if (_964 > 1.5)\n            {\n                cos_inner = mix(_958, 1.0, 0.25);\n            }\n            atten *= smoothstep(_958, cos_inner, dot(-l, fast::normalize(_948.xyz)));\n        }\n        if (_718 && (_730 < 1.5))\n        {\n            int param_24 = _714 + 6;\n            float4 _988 = fa_light_texel(param_24, fa_light_tex, fa_shadow_smp);\n            if (_988.z > 0.5)\n            {\n                float3 _996 = -to_light;\n                int param_25 = _714 + 4;\n                int param_26 = _714 + 5;\n                float3 _1010 = fa_light_texel(param_25, fa_light_tex, fa_shadow_smp).xyz;\n                float3 _1014 = fa_light_texel(param_26, fa_light_tex, fa_shadow_smp).xyz;\n                float3 _1023 = float3(dot(_996, _1010), dot(_996, _1014), dot(_996, cross(_1010, _1014)));\n                float3 param_27 = _1023;\n                int _1027 = fa_cube_face(param_27);\n                int param_28 = _1027;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1054 = float2(dot(_1023, cross(param_29, param_30)), dot(_1023, param_30)) / float2(fast::max(dot(_1023, param_29), 9.9999997473787516355514526367188e-05));\n                int _1058 = _1027 / 3;\n                float2 param_31 = _988.xy + (float2(float(_1027 - (_1058 * 3)), float(_1058)) * 256.0);\n                float2 param_32 = float2(0.5 + (0.5 * _1054.x), 0.5 - (0.5 * _1054.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32, fa_light_atlas, fa_env_smp);\n            }\n            int param_33 = _714 + 7;\n            float4 _1088 = fa_light_texel(param_33, fa_light_tex, fa_shadow_smp);\n            if (_1088.z > 0.5)\n            {\n                int param_34 = _714 + 2;\n                int param_35 = _714 + 4;\n                int param_36 = _714 + 5;\n                float2 param_37 = _1088.xy;\n                float3 param_38 = -l;\n                float3 param_39 = fast::normalize(fa_light_texel(param_34, fa_light_tex, fa_shadow_smp).xyz);\n                float3 param_40 = fa_light_texel(param_35, fa_light_tex, fa_shadow_smp).xyz;\n                float3 param_41 = fa_light_texel(param_36, fa_light_tex, fa_shadow_smp).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41, fa_light_atlas, fa_env_smp);\n            }\n        }\n        else\n        {\n            if (_718 && _940)\n            {\n                int param_42 = _714 + 6;\n                float4 _1135 = fa_light_texel(param_42, fa_light_tex, fa_shadow_smp);\n                int param_43 = _714 + 7;\n                float4 _1140 = fa_light_texel(param_43, fa_light_tex, fa_shadow_smp);\n                bool _1143 = _1135.z > 0.5;\n                bool _1150;\n                if (!_1143)\n                {\n                    _1150 = _1140.z > 0.5;\n                }\n                else\n                {\n                    _1150 = _1143;\n                }\n                if (_1150)\n                {\n                    int param_44 = _714 + 2;\n                    float4 _1157 = fa_light_texel(param_44, fa_light_tex, fa_shadow_smp);\n                    float3 _1161 = fast::normalize(_1157.xyz);\n                    int param_45 = _714 + 4;\n                    float4 _1166 = fa_light_texel(param_45, fa_light_tex, fa_shadow_smp);\n                    int param_46 = _714 + 5;\n                    float4 _1171 = fa_light_texel(param_46, fa_light_tex, fa_shadow_smp);\n                    if (_1143)\n                    {\n                        float3 _1179 = -to_light;\n                        float _1186 = _1157.w;\n                        float _1202 = 0.5 / fast::max(dot(_1179, _1161) * (sqrt(fast::max(1.0 - (_1186 * _1186), 0.0)) / fast::max(_1186, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        float2 param_47 = _1135.xy;\n                        float2 param_48 = float2(0.5 + (dot(_1179, _1166.xyz) * _1202), 0.5 - (dot(_1179, _1171.xyz) * _1202));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48, fa_light_atlas, fa_env_smp);\n                    }\n                    if (_1140.z > 0.5)\n                    {\n                        float2 param_49 = _1140.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1161;\n                        float3 param_52 = _1166.xyz;\n                        float3 param_53 = _1171.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53, fa_light_atlas, fa_env_smp);\n                    }\n                }\n            }\n        }\n    }\n    float3 _4141 = _727.xyz * atten;\n    if (_718)\n    {\n        _4141 *= fa_light_tint;\n    }\n    int _1270;\n    if (_744)\n    {\n        _1270 = 0;\n    }\n    else\n    {\n        _1270 = ((_730 > 1.5) && (_730 < 2.5)) ? 2 : 1;\n    }\n    return LightSample{ l, _4141, atten, 1.0, dist, _1270 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _2017)\n{\n    float _2007;\n    if (i == 0)\n    {\n        _2007 = _2017.fa_shadow_split.x;\n    }\n    else\n    {\n        float _2023;\n        if (i == 1)\n        {\n            _2023 = _2017.fa_shadow_split.y;\n        }\n        else\n        {\n            float _2031;\n            if (i == 2)\n            {\n                _2031 = _2017.fa_shadow_split.z;\n            }\n            else\n            {\n                _2031 = _2017.fa_shadow_split.w;\n            }\n            _2023 = _2031;\n        }\n        _2007 = _2023;\n    }\n    return _2007;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_fetch(thread const float2& uv, thread const float4& rect, thread const float3& conv, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2064 = fa_shadow_depth(param, param_1, fa_shadow_smp, fa_shadow_tex);\n    float _2068;\n    if (conv.x < 0.5)\n    {\n        _2068 = _2064;\n    }\n    else\n    {\n        _2068 = (conv.y * conv.z) / (conv.z - (_2064 * (conv.z - conv.y)));\n    }\n    return _2068;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _1995 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_1995), sin(_1995)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_filter(thread const float2& uv, thread const float4& rect, thread const float& zr, thread const float& texel_m, thread const float& unit, thread const float& reach, thread const float& plane, thread const float3& conv, thread const int& mode, thread const float& k, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2017, texture2d<float> fa_shadow_tex)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2, fa_shadow_smp, fa_shadow_tex));\n    }\n    float _2114 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2123;\n        if (k < 0.0)\n        {\n            _2123 = (-k) / fast::max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2123 = k;\n        }\n        float _2143 = fast::clamp((_2123 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2114;\n            float2 _2162 = fa_shadow_vogel(param_3, param_4, param_5) * _2143;\n            float2 param_6 = uv + (_2162 * _2017.fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _2174 = fa_shadow_fetch(param_6, param_7, param_8, fa_shadow_smp, fa_shadow_tex);\n            if (_2174 < (zr - (length(_2162) * plane)))\n            {\n                sum += _2174;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2200 = sum / cnt;\n        float _2210;\n        if (k < 0.0)\n        {\n            _2210 = (-k) / fast::max(_2200, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2210 = k;\n        }\n        radius = fast::clamp(((fast::max(zr - _2200, 0.0) * unit) * _2210) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _2232 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2232; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2232;\n        float param_11 = _2114;\n        float2 _2251 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_2251 * _2017.fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_2251) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14, fa_shadow_smp, fa_shadow_tex));\n    }\n    return lit / float(_2232);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2017, texture2d<float> fa_shadow_tex)\n{\n    float _2293 = fast::max(_2017.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _2298 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _2304 = sqrt(1.0 - (_2298 * _2298));\n    float _2311 = fast::min(_2304 / fast::max(_2298, 0.20000000298023223876953125), 4.0);\n    float _2316;\n    if (_2017.fa_shadow_bias.y > 0.0)\n    {\n        _2316 = _2017.fa_shadow_bias.y;\n    }\n    else\n    {\n        _2316 = 1.5 * _2017.fa_shadow_info[ci].x;\n    }\n    float4 _2341 = _2017.fa_shadow_mat[ci] * float4(world + (n * (_2316 * _2304)), 1.0);\n    float _2348 = _2341.x;\n    bool _2351 = _2348 < _2017.fa_shadow_rect[ci].x;\n    bool _2360;\n    if (!_2351)\n    {\n        _2360 = _2348 > _2017.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2360 = _2351;\n    }\n    bool _2369;\n    if (!_2360)\n    {\n        _2369 = _2341.y < _2017.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2369 = _2360;\n    }\n    bool _2378;\n    if (!_2369)\n    {\n        _2378 = _2341.y > _2017.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2378 = _2369;\n    }\n    bool _2385;\n    if (!_2378)\n    {\n        _2385 = _2341.z > 1.0;\n    }\n    else\n    {\n        _2385 = _2378;\n    }\n    if (_2385)\n    {\n        return -1.0;\n    }\n    float _2393;\n    if (_2017.fa_shadow_bias.x > 0.0)\n    {\n        _2393 = _2017.fa_shadow_bias.x;\n    }\n    else\n    {\n        _2393 = 1.5 * _2017.fa_shadow_info[ci].x;\n    }\n    float2 param = _2341.xy;\n    float4 param_1 = _2017.fa_shadow_rect[ci];\n    float param_2 = _2341.z - ((_2393 * (1.0 + (0.5 * _2311))) / _2293);\n    float param_3 = _2017.fa_shadow_info[ci].x;\n    float param_4 = _2293;\n    float param_5 = _2293 * 0.25;\n    float param_6 = ((_2017.fa_shadow_info[ci].x * fast::min(_2311, 3.0)) * 0.5) / _2293;\n    float3 param_7 = float3(0.0);\n    int param_8 = int(_2017.fa_shadow_cfg.z + 0.5);\n    float param_9 = _2017.fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9, fa_shadow_smp, gl_FragCoord, _2017, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _320, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2017, texture2d<float> fa_shadow_tex)\n{\n    if (_320.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2781 = int(_2017.fa_shadow_cfg.x + 0.5);\n    if (_2781 < 1)\n    {\n        return 1.0;\n    }\n    float _2796 = dot(world - _2017.fa_shadow_eye.xyz, _2017.fa_shadow_fwd.xyz);\n    int param = _2781 - 1;\n    if (_2796 > fa_shadow_split_at(param, _2017))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2808 = _2781 > 1;\n    bool _2815;\n    if (_2808)\n    {\n        _2815 = _2796 > _2017.fa_shadow_split.x;\n    }\n    else\n    {\n        _2815 = _2808;\n    }\n    if (_2815)\n    {\n        ci = 1;\n    }\n    bool _2819 = _2781 > 2;\n    bool _2826;\n    if (_2819)\n    {\n        _2826 = _2796 > _2017.fa_shadow_split.y;\n    }\n    else\n    {\n        _2826 = _2819;\n    }\n    if (_2826)\n    {\n        ci = 2;\n    }\n    bool _2830 = _2781 > 3;\n    bool _2837;\n    if (_2830)\n    {\n        _2837 = _2796 > _2017.fa_shadow_split.z;\n    }\n    else\n    {\n        _2837 = _2830;\n    }\n    if (_2837)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2781)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2863 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_shadow_smp, gl_FragCoord, _2017, fa_shadow_tex);\n        s = _2863;\n        if (_2863 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_2017.fa_shadow_cfg.y > 0.0)\n    {\n        float _2888;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2888 = fa_shadow_split_at(param_5, _2017);\n        }\n        else\n        {\n            _2888 = _2017.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _2907 = _2017.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _2017) - _2888, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2918 = fast::clamp((_2796 - (fa_shadow_split_at(param_7, _2017) - _2907)) / _2907, 0.0, 1.0);\n        if (_2918 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2781)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _2939 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_shadow_smp, gl_FragCoord, _2017, fa_shadow_tex);\n                s2 = _2939;\n                if (_2939 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2918);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _320, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2017, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, _320, fa_shadow_smp, gl_FragCoord, _2017, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_local(thread const int& li, thread const float3& world, thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _320, texture2d<float> fa_light_tex, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2017, texture2d<float> fa_shadow_tex)\n{\n    bool _2451 = _320.fa_pbr.z < 0.5;\n    bool _2458;\n    if (!_2451)\n    {\n        _2458 = _2017.fa_shadow_lcfg.x < 0.5;\n    }\n    else\n    {\n        _2458 = _2451;\n    }\n    if (_2458)\n    {\n        return 1.0;\n    }\n    int param = (int(_2017.fa_shadow_lcfg.x + 0.5) - 1) + li;\n    float4 _2471 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    float _2472 = _2471.x;\n    if (_2472 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2481 = int(_2472 + 0.5);\n    int param_1 = _2481;\n    float4 _2485 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    int param_2 = _2481 + 1;\n    float4 _2490 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float fade = 1.0;\n    float _2493 = _2485.y;\n    if (_2493 > 0.0)\n    {\n        float _2510 = 1.0 - smoothstep(0.75 * _2493, _2493, length(world - _2017.fa_shadow_eye.xyz));\n        fade = _2510;\n        if (_2510 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2485.x > 1.5)\n    {\n        int param_3 = li;\n        int param_4 = fa_light_base(param_3, _320);\n        float3 param_5 = world - fa_light_texel(param_4, fa_light_tex, fa_shadow_smp).xyz;\n        face = fa_cube_face(param_5);\n    }\n    int _2539 = (_2481 + 2) + (face * 6);\n    int param_6 = _2539;\n    int param_7 = _2539 + 1;\n    int param_8 = _2539 + 3;\n    float4 _2553 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n    int param_9 = _2539 + 4;\n    float4 _2558 = fa_light_texel(param_9, fa_light_tex, fa_shadow_smp);\n    int param_10 = _2539 + 5;\n    float4 _2563 = fa_light_texel(param_10, fa_light_tex, fa_shadow_smp);\n    float _2575 = _2563.x * fast::max(dot(_2553, float4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2580 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _2603 = fast::clamp(dot(n, _2553.xyz), -1.0, 1.0);\n    int param_11 = li;\n    int param_12 = fa_light_base(param_11, _320);\n    float _2627 = fast::min(sqrt(1.0 - (_2603 * _2603)) / fast::max(abs(dot(n, world - fa_light_texel(param_12, fa_light_tex, fa_shadow_smp).xyz)) / fast::max(dot(_2553, float4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2630 = _2490.y;\n    float _2632;\n    if (_2630 > 0.0)\n    {\n        _2632 = _2630;\n    }\n    else\n    {\n        _2632 = 1.5 * _2575;\n    }\n    float4 _2652 = float4(world + (n * (_2632 * sqrt(1.0 - (_2580 * _2580)))), 1.0);\n    float _2656 = dot(_2553, _2652);\n    float _2659 = _2563.y;\n    if (_2656 < _2659)\n    {\n        return 1.0;\n    }\n    float2 _2674 = float2(dot(fa_light_texel(param_6, fa_light_tex, fa_shadow_smp), _2652), dot(fa_light_texel(param_7, fa_light_tex, fa_shadow_smp), _2652)) / float2(_2656);\n    float _2676 = _2674.x;\n    bool _2679 = _2676 < _2558.x;\n    bool _2688;\n    if (!_2679)\n    {\n        _2688 = _2676 > _2558.z;\n    }\n    else\n    {\n        _2688 = _2679;\n    }\n    bool _2697;\n    if (!_2688)\n    {\n        _2697 = _2674.y < _2558.y;\n    }\n    else\n    {\n        _2697 = _2688;\n    }\n    bool _2706;\n    if (!_2697)\n    {\n        _2706 = _2674.y > _2558.w;\n    }\n    else\n    {\n        _2706 = _2697;\n    }\n    if (_2706)\n    {\n        return 1.0;\n    }\n    float _2712 = _2490.x;\n    float _2714;\n    if (_2712 > 0.0)\n    {\n        _2714 = _2712;\n    }\n    else\n    {\n        _2714 = 1.5 * _2575;\n    }\n    float2 param_13 = _2674;\n    float4 param_14 = _2558;\n    float param_15 = _2656 - (_2714 * (1.0 + (0.5 * _2627)));\n    float param_16 = _2575;\n    float param_17 = 1.0;\n    float param_18 = _2563.z * 0.25;\n    float param_19 = (_2575 * fast::min(_2627, 3.0)) * 0.5;\n    float3 param_20 = float3(1.0, _2659, _2563.z);\n    int param_21 = int(_2485.z + 0.5);\n    float param_22 = _2485.w;\n    return mix(1.0, fa_shadow_filter(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21, param_22, fa_shadow_smp, gl_FragCoord, _2017, fa_shadow_tex), fade);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, constant fa_mesh_fs_params& _320, texture2d<float> fa_light_tex, sampler fa_shadow_smp, texture2d<float> fa_light_atlas, sampler fa_env_smp, thread float3& fa_light_tint, thread bool& fa_light_is_area, thread float4& gl_FragCoord, constant fa_shadows& _2017, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos, thread float3& fa_lm)\n{\n    bool _3106 = fa_lm.z > 0.5;\n    bool _3112;\n    if (_3106)\n    {\n        int param = li;\n        _3112 = fa_light_baked(param, _320, fa_light_tex, fa_shadow_smp);\n    }\n    else\n    {\n        _3112 = _3106;\n    }\n    if (_3112)\n    {\n        int param_1 = li;\n        return LightSample{ float3(0.0, 1.0, 0.0), float3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1, _320, fa_light_tex, fa_shadow_smp) + 0.5) };\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _3136 = fa_light_sample_n(param_2, param_3, param_4, _320, fa_light_tex, fa_shadow_smp, fa_light_atlas, fa_env_smp, fa_light_tint, fa_light_is_area);\n    float3 _4167 = _3136.color;\n    float _4169 = _3136.shadow;\n    if ((_3136.type == 0) && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _3136.direction;\n        float _3150 = fa_shadow_factor(param_5, param_6, _320, fa_shadow_smp, gl_FragCoord, _2017, fa_shadow_tex, fa_world_pos);\n        _4169 = _3150;\n        _4167 *= _3150;\n    }\n    else\n    {\n        bool _3161 = _3136.type != 0;\n        bool _3167;\n        if (_3161)\n        {\n            _3167 = _3136.attenuation > 0.0;\n        }\n        else\n        {\n            _3167 = _3161;\n        }\n        if (_3167)\n        {\n            int param_7 = li;\n            float3 param_8 = world_pos;\n            float3 param_9 = gn;\n            float3 param_10 = _3136.direction;\n            float _3179 = fa_shadow_local(param_7, param_8, param_9, param_10, _320, fa_light_tex, fa_shadow_smp, gl_FragCoord, _2017, fa_shadow_tex);\n            _4169 = _3179;\n            _4167 *= _3179;\n        }\n    }\n    return LightSample{ _3136.direction, _4167, _3136.attenuation, _4169, _3136._distance, _3136.type };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 light(thread const SurfaceInput& i, thread const Surface& s, thread const LightSample& l)\n{\n    return float3(0.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _2017)\n{\n    if (_2017.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _2963 = int(_2017.fa_shadow_cfg.x + 0.5);\n    float _2973 = dot(world - _2017.fa_shadow_eye.xyz, _2017.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _2978 = _2963 > 0;\n    bool _2987;\n    if (_2978)\n    {\n        int param = _2963 - 1;\n        _2987 = _2973 <= fa_shadow_split_at(param, _2017);\n    }\n    else\n    {\n        _2987 = _2978;\n    }\n    if (_2987)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _2993 = _2963 > 1;\n        bool _3000;\n        if (_2993)\n        {\n            _3000 = _2973 > _2017.fa_shadow_split.x;\n        }\n        else\n        {\n            _3000 = _2993;\n        }\n        if (_3000)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3006 = _2963 > 2;\n        bool _3013;\n        if (_3006)\n        {\n            _3013 = _2973 > _2017.fa_shadow_split.y;\n        }\n        else\n        {\n            _3013 = _3006;\n        }\n        if (_3013)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3019 = _2963 > 3;\n        bool _3026;\n        if (_3019)\n        {\n            _3026 = _2973 > _2017.fa_shadow_split.z;\n        }\n        else\n        {\n            _3026 = _3019;\n        }\n        if (_3026)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _320 [[buffer(1)]], constant fa_shadows& _2017 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_irr_tex [[texture(6)]], texture2d<float> fa_light_tex [[texture(7)]], texture2d<float> fa_light_atlas [[texture(8)]], texture2d<float> fa_lightmap [[texture(9)]], texture2d<float> fa_decal_tex [[texture(10)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _3983 = fast::normalize(in.fa_world_normal);\n    float3 fa_light_tint;\n    bool fa_light_is_area;\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _3983 = -_3983;\n    }\n    float3 _3567 = fast::normalize(_320.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, _320, fa_light_tex, fa_shadow_smp, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _3983, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _3567, short(gl_FrontFacing) };\n    Surface _3575 = fa_standard_surface(param_1, _320, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _4022 = _3575.albedo;\n    float _4023 = _3575.alpha;\n    float3 _4024 = _3575.normal;\n    float _4025 = _3575.metallic;\n    float _4026 = _3575.roughness;\n    float _4027 = _3575.occlusion;\n    float3 _4028 = _3575.emission;\n    float _4029 = _3575.clearcoat;\n    float _4030 = _3575.clearcoat_roughness;\n    float3 _4031 = _3575.sheen_color;\n    float _4032 = _3575.sheen_roughness;\n    float _4033 = _3575.anisotropy;\n    float _4034 = _3575.anisotropy_rotation;\n    float _4035 = _3575.specular;\n    float _4036 = _3575.ior;\n    float3 _4037 = _3575.specular_color;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _3983, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _3567, short(gl_FrontFacing) };\n    Surface param_3 = _3575;\n    surface(param_2, param_3);\n    _4022 = param_3.albedo;\n    _4023 = param_3.alpha;\n    _4024 = param_3.normal;\n    _4025 = param_3.metallic;\n    _4026 = param_3.roughness;\n    _4027 = param_3.occlusion;\n    _4028 = param_3.emission;\n    _4029 = param_3.clearcoat;\n    _4030 = param_3.clearcoat_roughness;\n    _4031 = param_3.sheen_color;\n    _4032 = param_3.sheen_roughness;\n    _4033 = param_3.anisotropy;\n    _4034 = param_3.anisotropy_rotation;\n    _4035 = param_3.specular;\n    _4036 = param_3.ior;\n    _4037 = param_3.specular_color;\n    float3 param_4 = in.fa_world_pos;\n    float3 param_5 = _3983;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7, _320, fa_light_tex, fa_shadow_smp, fa_env_smp, fa_decal_tex);\n    _4022 = param_6;\n    _4024 = param_7;\n    float3 result;\n    if (_320.fa_emissive.w > 0.5)\n    {\n        result = _4022;\n    }\n    else\n    {\n        float3 _3613 = _4024;\n        float3 _3614 = fast::normalize(_3613);\n        _4024 = _3614;\n        float3 param_8 = _3614;\n        SurfaceInput param_9 = SurfaceInput{ in.fa_world_pos, _3983, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _3567, short(gl_FrontFacing) };\n        Surface param_10 = Surface{ _4022, _4023, _4024, _4025, _4026, _4027, _4028, _4029, _4030, _4031, _4032, _4033, _4034, _4035, _4036, _4037 };\n        float3 param_11 = fa_indirect_diffuse(param_8, _320, fa_env_smp, fa_irr_tex, in.fa_lm, fa_lightmap);\n        float3 lit = ambient(param_9, param_10, param_11);\n        int _3633 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _3633; ln++)\n        {\n            int param_12 = ln;\n            int _3646 = fa_cl_light(param_12, _320, fa_light_tex, fa_shadow_smp, fa_cl_ndir, fa_cl_slot);\n            bool _3649 = in.fa_lm.z > 0.5;\n            bool _3655;\n            if (_3649)\n            {\n                int param_13 = _3646;\n                _3655 = fa_light_baked(param_13, _320, fa_light_tex, fa_shadow_smp);\n            }\n            else\n            {\n                _3655 = _3649;\n            }\n            if (_3655)\n            {\n                continue;\n            }\n            int param_14 = _3646;\n            float3 param_15 = in.fa_world_pos;\n            float3 param_16 = _3983;\n            LightSample _3667 = fa_light_shadowed(param_14, param_15, param_16, _320, fa_light_tex, fa_shadow_smp, fa_light_atlas, fa_env_smp, fa_light_tint, fa_light_is_area, gl_FragCoord, _2017, fa_shadow_tex, in.fa_world_pos, in.fa_lm);\n            SurfaceInput param_17 = SurfaceInput{ in.fa_world_pos, _3983, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _3567, short(gl_FrontFacing) };\n            Surface param_18 = Surface{ _4022, _4023, _4024, _4025, _4026, _4027, _4028, _4029, _4030, _4031, _4032, _4033, _4034, _4035, _4036, _4037 };\n            LightSample param_19 = _3667;\n            lit += light(param_17, param_18, param_19);\n        }\n        result = lit;\n    }\n    float3 _3682 = result;\n    float3 _3683 = _3682 + _4028;\n    result = _3683;\n    float3 param_20 = _3683;\n    float3 param_21 = in.fa_world_pos;\n    result = fa_shadow_debug(param_20, param_21, _2017);\n    bool _3692 = _320.fa_fog.w > 0.0;\n    bool _3699;\n    if (!_3692)\n    {\n        _3699 = _320.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _3699 = _3692;\n    }\n    if (_3699)\n    {\n        float3 _3708 = in.fa_world_pos - _320.fa_camera_pos.xyz;\n        float _3714 = dot(_3708, _320.fa_fog_c.xyz);\n        bool _3718 = _320.fa_fog_c.w > 0.5;\n        float _3719;\n        if (_3718)\n        {\n            _3719 = _3714;\n        }\n        else\n        {\n            _3719 = length(_3708);\n        }\n        float _3731 = _3719 - _320.fa_fog_b.x;\n        if (_3731 > 0.0)\n        {\n            float _3740 = _320.fa_fog.w * _3731;\n            float tau = _3740 * _3740;\n            if (_320.fa_fog_b.y > 0.0)\n            {\n                float _3756;\n                if (_3718)\n                {\n                    _3756 = in.fa_world_pos.y - (_320.fa_fog_c.y * _3714);\n                }\n                else\n                {\n                    _3756 = _320.fa_camera_pos.y;\n                }\n                float _3777 = mix(_3756, in.fa_world_pos.y, fast::clamp(_320.fa_fog_b.x / _3719, 0.0, 1.0));\n                float _3781 = in.fa_world_pos.y - _3777;\n                float _3786 = _3777 - _320.fa_fog_b.z;\n                float _3791 = in.fa_world_pos.y - _320.fa_fog_b.z;\n                bool _3794 = _3786 <= 0.0;\n                bool _3795 = !_3794;\n                bool _3801;\n                if (_3795)\n                {\n                    _3801 = _320.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3801 = _3794;\n                }\n                float _3802;\n                if (_3801)\n                {\n                    _3802 = _320.fa_fog_b.y;\n                }\n                else\n                {\n                    _3802 = _320.fa_fog_b.y * exp(-fast::min(_320.fa_fog_b.w * _3786, 80.0));\n                }\n                bool _3829;\n                if (_3795)\n                {\n                    _3829 = _320.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3829 = _3794;\n                }\n                float _3830;\n                if (_3829)\n                {\n                    _3830 = _320.fa_fog_b.y * _3786;\n                }\n                else\n                {\n                    _3830 = (_320.fa_fog_b.y * (1.0 - exp(-fast::min(_320.fa_fog_b.w * _3786, 80.0)))) / _320.fa_fog_b.w;\n                }\n                bool _3855 = _3791 <= 0.0;\n                bool _3862;\n                if (!_3855)\n                {\n                    _3862 = _320.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3862 = _3855;\n                }\n                float _3863;\n                if (_3862)\n                {\n                    _3863 = _320.fa_fog_b.y * _3791;\n                }\n                else\n                {\n                    _3863 = (_320.fa_fog_b.y * (1.0 - exp(-fast::min(_320.fa_fog_b.w * _3791, 80.0)))) / _320.fa_fog_b.w;\n                }\n                float _3890;\n                if (abs(_3781) < 0.001000000047497451305389404296875)\n                {\n                    _3890 = _3802;\n                }\n                else\n                {\n                    _3890 = (_3863 - _3830) / _3781;\n                }\n                tau += (_3731 * fast::max(_3890, 0.0));\n            }\n            result = mix(result, _320.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _4023);\n    return out;\n}\n\n",
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
            "inst_name": "_320",
            "msl_buffer_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2017",
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
              "slot": 15,
              "stage": "fragment",
              "name": "fa_irr_tex",
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
            "name": "fa_irr_tex_fa_env_smp",
            "view_name": "fa_irr_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 15,
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
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _56;\n    if (bool(i.front_facing))\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = fast::normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = fast::normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (bool(i.front_facing))\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _213, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _213.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _785 = base_t;\n    _785.x = _225.x;\n    _785.y = _225.y;\n    _785.z = _225.z;\n    base_t = _785;\n    float4 _241 = (_785 * _213.fa_base_color) * i.vertex_color;\n    float3 _748 = i.world_normal;\n    if (_213.fa_maps.z > 0.5)\n    {\n        float param_4 = _213.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0) - float3(1.0);\n        float2 _284 = _279.xy * _213.fa_maps.x;\n        float3 _793 = _279;\n        _793.x = _284.x;\n        _793.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _793;\n        _748 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _213.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _796 = mrt;\n    _796.x = _313.x;\n    _796.y = _313.y;\n    _796.z = _313.z;\n    mrt = _796;\n    float4 _343 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _213.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _385 = fa_tex_fix(param_20, param_21);\n    float _753 = _213.fa_layers_a.x;\n    float _754 = _213.fa_layers_a.y;\n    float _757 = _213.fa_layers_a.z;\n    float _756 = _213.fa_layers_b.w;\n    float _759 = _213.fa_layers_c.x;\n    if (_213.fa_layers_c.z > 0.5)\n    {\n        if (mod(_213.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _753 *= _355.y;\n            _754 *= _355.z;\n            _756 *= _343.w;\n        }\n        if (_213.fa_layers_c.z > 1.5)\n        {\n            _757 *= mrt.x;\n            _759 *= mrt.w;\n        }\n    }\n    return Surface{ _241.xyz, _241.w, _748, fast::clamp(_213.fa_pbr.x * _313.z, 0.0, 1.0), fast::clamp(_213.fa_pbr.y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_213.fa_maps.y * (_355.x - 1.0)), _213.fa_emissive.xyz + (_213.fa_model_emissive.xyz * _385), _753, _754, _213.fa_layers_b.xyz, _756, _757, _213.fa_layers_a.w, _759, _213.fa_layers_c.y, _213.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _213 [[buffer(1)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], sampler fa_smp [[sampler(0)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _659 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _659 = -_659;\n    }\n    float3 _519 = fast::normalize(_213.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _659, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _519, short(gl_FrontFacing) };\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _659, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _519, short(gl_FrontFacing) };\n    Surface param_2 = fa_standard_surface(param, fa_tex, fa_smp, _213, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    surface(param_1, param_2);\n    float3 _534 = fast::normalize(param_2.normal);\n    float3 _549 = fast::normalize(float3(dot(in.fa_pre_r0, _534), dot(in.fa_pre_r1, _534), dot(in.fa_pre_r2, _534)));\n    float _561 = _549.z;\n    float2 e = _549.xy / float2((abs(_549.x) + abs(_549.y)) + abs(_561));\n    if (_561 < 0.0)\n    {\n        e = (float2(1.0) - abs(e.yx)) * float2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    out.fa_frag_color = float4(fast::min(in.fa_pre_depth, 60000.0), e, 1.0);\n    return out;\n}\n\n",
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
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _56;\n    if (bool(i.front_facing))\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = fast::normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = fast::normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (bool(i.front_facing))\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _213, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _213.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _785 = base_t;\n    _785.x = _225.x;\n    _785.y = _225.y;\n    _785.z = _225.z;\n    base_t = _785;\n    float4 _241 = (_785 * _213.fa_base_color) * i.vertex_color;\n    float3 _748 = i.world_normal;\n    if (_213.fa_maps.z > 0.5)\n    {\n        float param_4 = _213.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0) - float3(1.0);\n        float2 _284 = _279.xy * _213.fa_maps.x;\n        float3 _793 = _279;\n        _793.x = _284.x;\n        _793.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _793;\n        _748 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _213.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _796 = mrt;\n    _796.x = _313.x;\n    _796.y = _313.y;\n    _796.z = _313.z;\n    mrt = _796;\n    float4 _343 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _213.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _385 = fa_tex_fix(param_20, param_21);\n    float _753 = _213.fa_layers_a.x;\n    float _754 = _213.fa_layers_a.y;\n    float _757 = _213.fa_layers_a.z;\n    float _756 = _213.fa_layers_b.w;\n    float _759 = _213.fa_layers_c.x;\n    if (_213.fa_layers_c.z > 0.5)\n    {\n        if (mod(_213.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _753 *= _355.y;\n            _754 *= _355.z;\n            _756 *= _343.w;\n        }\n        if (_213.fa_layers_c.z > 1.5)\n        {\n            _757 *= mrt.x;\n            _759 *= mrt.w;\n        }\n    }\n    return Surface{ _241.xyz, _241.w, _748, fast::clamp(_213.fa_pbr.x * _313.z, 0.0, 1.0), fast::clamp(_213.fa_pbr.y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_213.fa_maps.y * (_355.x - 1.0)), _213.fa_emissive.xyz + (_213.fa_model_emissive.xyz * _385), _753, _754, _213.fa_layers_b.xyz, _756, _757, _213.fa_layers_a.w, _759, _213.fa_layers_c.y, _213.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _213 [[buffer(1)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], sampler fa_smp [[sampler(0)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _659 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _659 = -_659;\n    }\n    float3 _519 = fast::normalize(_213.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _659, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _519, short(gl_FrontFacing) };\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _659, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _519, short(gl_FrontFacing) };\n    Surface param_2 = fa_standard_surface(param, fa_tex, fa_smp, _213, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    surface(param_1, param_2);\n    float3 _534 = fast::normalize(param_2.normal);\n    float3 _549 = fast::normalize(float3(dot(in.fa_pre_r0, _534), dot(in.fa_pre_r1, _534), dot(in.fa_pre_r2, _534)));\n    float _561 = _549.z;\n    float2 e = _549.xy / float2((abs(_549.x) + abs(_549.y)) + abs(_561));\n    if (_561 < 0.0)\n    {\n        e = (float2(1.0) - abs(e.yx)) * float2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    out.fa_frag_color = float4(fast::min(in.fa_pre_depth, 60000.0), e, 1.0);\n    return out;\n}\n\n",
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
