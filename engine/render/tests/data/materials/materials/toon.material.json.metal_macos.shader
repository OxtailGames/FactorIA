{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "4155841b00106f1351e36fe7e96d502ece90660dd797ea3c7df876d511a0f129",
  "slang": "metal_macos",
  "params": [
    "dark"
  ],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float3 fa_lm [[user(locn5)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_shade_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _131, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _131);\n    float3 _270 = _160.world_pos;\n    fa_world_pos = _270;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = _131.fa_view_proj * float4(_270, 1.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _131 [[buffer(0)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4x4 param = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3);\n    float3 param_1 = in.fa_position;\n    float3 param_2 = in.fa_normal;\n    float4 param_3 = in.fa_tangent;\n    float2 param_4 = in.fa_texcoord0;\n    float4 param_5 = in.fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5, _131, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.gl_Position);\n    out.fa_lm = float3(0.0);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n#pragma clang diagnostic ignored \"-Wmissing-braces\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\ntemplate<typename T, size_t Num>\nstruct spvUnsafeArray\n{\n    T elements[Num ? Num : 1];\n    \n    thread T& operator [] (size_t pos) thread\n    {\n        return elements[pos];\n    }\n    constexpr const thread T& operator [] (size_t pos) const thread\n    {\n        return elements[pos];\n    }\n    \n    device T& operator [] (size_t pos) device\n    {\n        return elements[pos];\n    }\n    constexpr const device T& operator [] (size_t pos) const device\n    {\n        return elements[pos];\n    }\n    \n    constexpr const constant T& operator [] (size_t pos) const constant\n    {\n        return elements[pos];\n    }\n    \n    threadgroup T& operator [] (size_t pos) threadgroup\n    {\n        return elements[pos];\n    }\n    constexpr const threadgroup T& operator [] (size_t pos) const threadgroup\n    {\n        return elements[pos];\n    }\n};\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n    float4 fa_ct_a;\n    float4 fa_ct_b;\n    float4 fa_ct_vpx;\n    float4 fa_ct_vpy;\n    float4 fa_ct_vpw;\n    float4 fa_ct_fwd;\n    float4 fa_tr_a;\n    float4 fa_tr_b;\n    float4 fa_probe_sh[9];\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n    float4 fa_shadow_lcfg;\n};\n\nstruct fa_material\n{\n    float dark;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float3 fa_lm [[user(locn5)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_cluster_texel(thread const float3& world_pos, constant fa_mesh_fs_params& _390, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    bool _1318 = _390.fa_cl_info.x < 0.0;\n    bool _1325;\n    if (!_1318)\n    {\n        _1325 = _390.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _1325 = _1318;\n    }\n    bool _1333;\n    if (!_1325)\n    {\n        _1333 = _390.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _1333 = _1325;\n    }\n    bool _1340;\n    if (!_1333)\n    {\n        _1340 = _390.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _1340 = _1333;\n    }\n    bool _1347;\n    if (!_1340)\n    {\n        _1347 = _390.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _1347 = _1340;\n    }\n    if (_1347)\n    {\n        return float4(0.0);\n    }\n    float4 _1357 = float4(world_pos, 1.0);\n    float _1363 = dot(_390.fa_cl_vpw, _1357);\n    if (!(_1363 > 9.9999999747524270787835121154785e-07))\n    {\n        return float4(0.0);\n    }\n    float2 _1385 = float2(dot(_390.fa_cl_vpx, _1357), dot(_390.fa_cl_vpy, _1357)) / float2(_1363);\n    int _1389 = int(_390.fa_cl_grid.x);\n    int _1393 = int(_390.fa_cl_grid.y);\n    int param = (int(_390.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_390.fa_cl_fwd.xyz, world_pos) + _390.fa_cl_fwd.w, _390.fa_cl_grid.w) / _390.fa_cl_grid.w) * _390.fa_cl_grid.z)), 0, int(_390.fa_cl_info.y) - 1) * _1393) + clamp(int(floor(((_1385.y * 0.5) + 0.5) * _390.fa_cl_grid.y)), 0, _1393 - 1)) * _1389)) + clamp(int(floor(((_1385.x * 0.5) + 0.5) * _390.fa_cl_grid.x)), 0, _1389 - 1);\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, constant fa_mesh_fs_params& _390, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    float3 param = world_pos;\n    float4 _1469 = fa_cluster_texel(param, _390, fa_light_tex, fa_shadow_smp);\n    return int2(int(_1469.x), int(_1469.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, constant fa_mesh_fs_params& _390, texture2d<float> fa_light_tex, sampler fa_shadow_smp, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_390.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _3528 = fa_cluster_lookup(param, _390, fa_light_tex, fa_shadow_smp);\n    fa_cl_slot = _3528.x;\n    fa_cl_local = _3528.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _3759 = fa_linear_to_srgb(param);\n        c = _3759;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _3767 = fa_srgb_to_linear(param_1);\n            c = _3767;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _272;\n    if (bool(i.front_facing))\n    {\n        _272 = i.world_normal;\n    }\n    else\n    {\n        _272 = -i.world_normal;\n    }\n    float3 _296 = fast::normalize(i.world_tangent.xyz - (_272 * dot(_272, i.world_tangent.xyz)));\n    float3 _323 = fast::normalize(((_296 * m.x) + ((cross(_272, _296) * i.world_tangent.w) * m.y)) + (_272 * m.z));\n    float3 _326;\n    if (bool(i.front_facing))\n    {\n        _326 = _323;\n    }\n    else\n    {\n        _326 = -_323;\n    }\n    return _326;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _390, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _390.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _3798 = fa_tex_fix(param_2, param_3);\n    float4 _4923 = base_t;\n    _4923.x = _3798.x;\n    _4923.y = _3798.y;\n    _4923.z = _3798.z;\n    base_t = _4923;\n    float4 _3812 = (_4923 * _390.fa_base_color) * i.vertex_color;\n    float3 _4767 = i.world_normal;\n    if (_390.fa_maps.z > 0.5)\n    {\n        float param_4 = _390.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _3844 = fa_tex_fix(param_6, param_7);\n        float3 _3847 = (_3844 * 2.0) - float3(1.0);\n        float2 _3852 = _3847.xy * _390.fa_maps.x;\n        float3 _4931 = _3847;\n        _4931.x = _3852.x;\n        _4931.y = _3852.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _4931;\n        _4767 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _390.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _3880 = fa_tex_fix(param_12, param_13);\n    float4 _4934 = mrt;\n    _4934.x = _3880.x;\n    _4934.y = _3880.y;\n    _4934.z = _3880.z;\n    mrt = _4934;\n    float4 _3908 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _390.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _3908.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _3919 = fa_tex_fix(param_16, param_17);\n    float param_18 = _390.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _3949 = fa_tex_fix(param_20, param_21);\n    float _4772 = _390.fa_layers_a.x;\n    float _4773 = _390.fa_layers_a.y;\n    float _4776 = _390.fa_layers_a.z;\n    float _4775 = _390.fa_layers_b.w;\n    float _4778 = _390.fa_layers_c.x;\n    if (_390.fa_layers_c.z > 0.5)\n    {\n        if (mod(_390.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _4772 *= _3919.y;\n            _4773 *= _3919.z;\n            _4775 *= _3908.w;\n        }\n        if (_390.fa_layers_c.z > 1.5)\n        {\n            _4776 *= mrt.x;\n            _4778 *= mrt.w;\n        }\n    }\n    return Surface{ _3812.xyz, _3812.w, _4767, fast::clamp(_390.fa_pbr.x * _3880.z, 0.0, 1.0), fast::clamp(_390.fa_pbr.y * _3880.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_390.fa_maps.y * (_3919.x - 1.0)), _390.fa_emissive.xyz + (_390.fa_model_emissive.xyz * _3949), _4772, _4773, _390.fa_layers_b.xyz, _4775, _4776, _390.fa_layers_a.w, _4778, _390.fa_layers_c.y, _390.fa_layers_d.xyz, _390.fa_tr_a.x, _390.fa_tr_a.y, _390.fa_tr_b.xyz, _390.fa_tr_a.z };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_decal_tile(thread const float4& rect, thread const float2& uv, thread const float2& atlas, thread const float2& ddx, thread const float2& ddy, sampler fa_env_smp, texture2d<float> fa_decal_tex)\n{\n    float2 _1549 = rect.zw - rect.xy;\n    float2 _1553 = _1549 * atlas;\n    float2 _1557 = ddx * _1553;\n    float2 _1561 = ddy * _1553;\n    return fa_decal_tex.sample(fa_env_smp, (rect.xy + (fast::clamp(uv, float2(0.0), float2(1.0)) * _1549)), level(fast::clamp(0.5 * log2(fast::max(fast::max(dot(_1557, _1557), dot(_1561, _1561)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_apply_decals(thread const float3& world_pos, thread const float3& geo_normal, thread float3& albedo, thread float3& normal, constant fa_mesh_fs_params& _390, texture2d<float> fa_light_tex, sampler fa_shadow_smp, sampler fa_env_smp, texture2d<float> fa_decal_tex)\n{\n    bool _1594 = _390.fa_counts.y < 0.5;\n    bool _1601;\n    if (!_1594)\n    {\n        _1601 = _390.fa_counts.w < 0.5;\n    }\n    else\n    {\n        _1601 = _1594;\n    }\n    if (_1601)\n    {\n        return;\n    }\n    float3 _1607 = dfdx(world_pos);\n    float3 _1610 = dfdy(world_pos);\n    float3 param = world_pos;\n    float4 _1614 = fa_cluster_texel(param, _390, fa_light_tex, fa_shadow_smp);\n    int _1618 = int(_1614.w);\n    if (_1618 < 1)\n    {\n        return;\n    }\n    int _1628 = int(_390.fa_counts.y + 0.5);\n    int param_1 = _1628;\n    float4 _1632 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float2 _1635 = _1632.yz;\n    int _1639 = int(_1632.w);\n    int param_2 = _1628 + 1;\n    float4 _1644 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float _1645 = _1644.x;\n    int _1651 = int(_390.fa_counts.w + 0.5) - 1;\n    int _1655 = int(_1614.z);\n    float3 _1920;\n    for (int k = 0; k < _1618; k++)\n    {\n        int _1668 = _1655 + k;\n        int param_3 = _1639 + (_1668 >> 2);\n        int _1685 = (_1628 + 2) + (int(fa_light_texel(param_3, fa_light_tex, fa_shadow_smp)[_1668 & 3]) * 7);\n        int param_4 = _1685 + 6;\n        float4 _1690 = fa_light_texel(param_4, fa_light_tex, fa_shadow_smp);\n        if (((int(_1690.w + 0.5) >> _1651) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1685;\n        float4 _1705 = fa_light_texel(param_5, fa_light_tex, fa_shadow_smp);\n        int param_6 = _1685 + 1;\n        float4 _1710 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n        int param_7 = _1685 + 2;\n        float4 _1715 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n        float3 _1718 = _1705.xyz;\n        float _1723 = dot(_1718, world_pos) + _1705.w;\n        float3 _1725 = _1710.xyz;\n        float _1730 = dot(_1725, world_pos) + _1710.w;\n        float3 _1732 = _1715.xyz;\n        float _1737 = dot(_1732, world_pos) + _1715.w;\n        bool _1742 = abs(_1723) > 0.5;\n        bool _1750;\n        if (!_1742)\n        {\n            _1750 = abs(_1730) > 0.5;\n        }\n        else\n        {\n            _1750 = _1742;\n        }\n        bool _1758;\n        if (!_1750)\n        {\n            _1758 = abs(_1737) > 0.5;\n        }\n        else\n        {\n            _1758 = _1750;\n        }\n        if (_1758)\n        {\n            continue;\n        }\n        float _1773 = fast::clamp(dot(geo_normal, fast::normalize(_1732)) * _1690.z, 0.0, 1.0);\n        if (_1773 <= 0.0)\n        {\n            continue;\n        }\n        float _1793 = (fast::clamp((0.5 - abs(_1737)) * 10.0, 0.0, 1.0) * _1773) * _1690.x;\n        float2 _1801 = float2(_1723 + 0.5, 0.5 - _1730);\n        float2 _1811 = float2(dot(_1718, _1607), dot(_1725, _1607));\n        float2 _1821 = float2(dot(_1718, _1610), dot(_1725, _1610));\n        int param_8 = _1685 + 5;\n        float4 _1826 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n        int param_9 = _1685 + 3;\n        float4 _1831 = fa_light_texel(param_9, fa_light_tex, fa_shadow_smp);\n        int param_10 = _1685 + 4;\n        float4 _1836 = fa_light_texel(param_10, fa_light_tex, fa_shadow_smp);\n        float tex_a = 1.0;\n        float3 col = _1826.xyz;\n        bool _1846 = _1831.z > _1831.x;\n        if (_1846)\n        {\n            float4 param_11 = _1831;\n            float2 param_12 = _1801;\n            float2 param_13 = _1635;\n            float2 param_14 = _1811;\n            float2 param_15 = _1821;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15, fa_env_smp, fa_decal_tex);\n            if ((_1645 > 0.5) && (_1645 < 1.5))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1872 = fa_dc_to_linear(param_16);\n                float4 _4855 = tx;\n                _4855.x = _1872.x;\n                _4855.y = _1872.y;\n                _4855.z = _1872.z;\n                tx = _4855;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, float3(fast::clamp((_1793 * tex_a) * _1826.w, 0.0, 1.0)));\n        if (_1836.z > _1836.x)\n        {\n            float4 param_17 = _1836;\n            float2 param_18 = _1801;\n            float2 param_19 = _1635;\n            float2 param_20 = _1811;\n            float2 param_21 = _1821;\n            float4 _1916 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21, fa_env_smp, fa_decal_tex);\n            if (_1645 > 1.5)\n            {\n                float3 param_22 = _1916.xyz;\n                float3 _1926 = fa_dc_to_srgb(param_22);\n                _1920 = _1926;\n            }\n            else\n            {\n                _1920 = _1916.xyz;\n            }\n            float3 _1935 = (_1920 * 2.0) - float3(1.0);\n            float2 _1940 = _1935.xy * _1690.y;\n            float3 _1962 = (fast::normalize(_1718) * _1940.x) + (fast::normalize(_1725) * _1940.y);\n            float3 _1965 = fast::normalize(normal);\n            normal = fast::normalize(mix(_1965, fast::normalize((_1965 * fast::max(_1935.z, 0.0500000007450580596923828125)) + (_1962 - (_1965 * dot(_1965, _1962)))), float3(fast::clamp(_1793 * (_1846 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_sh_coef(thread const int& k, constant fa_mesh_fs_params& _390, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float3 v = fa_env_tex.sample(fa_env_smp, float3(1.0, 1.0 - (float((2 * (k >> 2)) + 1) * 0.25), 1.0 - (float((2 * (k & 3)) + 1) * 0.25)), level(5.0)).xyz;\n    if (_390.fa_env_sky.w > 1.5)\n    {\n        v = (v - float3(0.5)) * 8.0;\n    }\n    return v;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sh_eval(thread const spvUnsafeArray<float3, 9>& c, thread const float3& n)\n{\n    float3 _3160 = fast::max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), float3(0.0));\n    return _3160;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _390, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    if (_390.fa_env_sky.w > 0.5)\n    {\n        spvUnsafeArray<float3, 9> c;\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param, _390, fa_env_smp, fa_env_tex);\n        }\n        spvUnsafeArray<float3, 9> param_1 = c;\n        float3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return _390.fa_ambient.xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_indirect_diffuse(thread const float3& n, constant fa_mesh_fs_params& _390, sampler fa_env_smp, texturecube<float> fa_env_tex, thread float3& fa_lm, texture2d<float> fa_lightmap)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return fa_lightmap.sample(fa_env_smp, fa_lm.xy, level(0.0)).xyz;\n    }\n    if (_390.fa_probe_sh[0].w > 0.0)\n    {\n        spvUnsafeArray<float3, 9> c;\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = _390.fa_probe_sh[k].xyz;\n        }\n        float3 param = n;\n        spvUnsafeArray<float3, 9> param_1 = c;\n        float3 param_2 = n;\n        return mix(fa_ambient_light(param, _390, fa_env_smp, fa_env_tex), fa_sh_eval(param_1, param_2), float3(fast::clamp(_390.fa_probe_sh[0].w, 0.0, 1.0)));\n    }\n    float3 param_3 = n;\n    return fa_ambient_light(param_3, _390, fa_env_smp, fa_env_tex);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, constant fa_mesh_fs_params& _390, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (int(_390.fa_cl_info.x) + int(_390.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, constant fa_mesh_fs_params& _390, texture2d<float> fa_light_tex, sampler fa_shadow_smp, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, _390, fa_light_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_light_base(thread const int& li, constant fa_mesh_fs_params& _390)\n{\n    return li * ((_390.fa_ambient.w > 4.5) ? 8 : 4);\n}\n\nstatic inline __attribute__((always_inline))\nbool fa_light_baked(thread const int& li, constant fa_mesh_fs_params& _390, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li;\n    int param_1 = fa_light_base(param, _390) + 3;\n    return fa_light_texel(param_1, fa_light_tex, fa_shadow_smp).w > 0.5;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_baked_keep(thread const int& li, constant fa_mesh_fs_params& _390, texture2d<float> fa_light_tex, sampler fa_shadow_smp, thread float3& fa_lm)\n{\n    float _3498;\n    if (fa_lm.z > 0.5)\n    {\n        _3498 = 0.0;\n    }\n    else\n    {\n        _3498 = 1.0 - fast::clamp(_390.fa_probe_sh[0].w, 0.0, 1.0);\n    }\n    bool _3509 = _3498 < 1.0;\n    bool _3515;\n    if (_3509)\n    {\n        int param = li;\n        _3515 = fa_light_baked(param, _390, fa_light_tex, fa_shadow_smp);\n    }\n    else\n    {\n        _3515 = _3509;\n    }\n    return _3515 ? _3498 : 1.0;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_light_type(thread const int& li, constant fa_mesh_fs_params& _390, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li;\n    int param_1 = fa_light_base(param, _390) + 1;\n    return fa_light_texel(param_1, fa_light_tex, fa_shadow_smp).w;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_area_point(thread const float3& c, thread const float3& axis, thread const float3& ru, thread const float3& uu, thread const float& hx, thread const float& hy, thread const float& shape, thread const float3& p, thread const float3& r)\n{\n    bool _568 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        float3 _581 = (c - (ru * hx)) - p;\n        float3 _587 = ru * (2.0 * hx);\n        float _593 = fast::max(dot(_587, _587), 9.9999999392252902907785028219223e-09);\n        float _597 = dot(_581, _587);\n        float t = fast::clamp((-_597) / _593, 0.0, 1.0);\n        if (_568)\n        {\n            float _612 = dot(r, _587);\n            float _618 = _593 - (_612 * _612);\n            if (abs(_618) > (9.9999997473787516355514526367188e-06 * _593))\n            {\n                t = fast::clamp(((dot(r, _581) * _612) - _597) / _618, 0.0, 1.0);\n            }\n        }\n        return (p + _581) + (_587 * t);\n    }\n    float3 q = p;\n    float _650 = dot(r, axis);\n    bool _658;\n    if (_568)\n    {\n        _658 = abs(_650) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _658 = _568;\n    }\n    if (_658)\n    {\n        float _668 = dot(c - p, axis) / _650;\n        if (_668 > 0.0)\n        {\n            q = p + (r * _668);\n        }\n    }\n    float3 _681 = q - c;\n    float2 xy = float2(dot(_681, ru), dot(_681, uu));\n    if (shape > 0.5)\n    {\n        float _696 = length(xy);\n        if (_696 > hx)\n        {\n            xy *= (hx / _696);\n        }\n    }\n    else\n    {\n        xy = fast::clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_atlas_fetch(thread const float2& texel, texture2d<float> fa_light_atlas, sampler fa_env_smp)\n{\n    return fa_light_atlas.sample(fa_env_smp, (texel / float2(int2(fa_light_atlas.get_width(), fa_light_atlas.get_height()))), level(0.0));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_cookie_sample(thread const float2& tile_origin, thread const float2& uv, texture2d<float> fa_light_atlas, sampler fa_env_smp)\n{\n    float2 param = (tile_origin + float2(1.0)) + (fast::clamp(uv, float2(0.0), float2(1.0)) * 254.0);\n    return fa_atlas_fetch(param, fa_light_atlas, fa_env_smp).xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_ies_sample(thread const float2& tile_origin, thread const float3& d, thread const float3& axis, thread const float3& right, thread const float3& up, texture2d<float> fa_light_atlas, sampler fa_env_smp)\n{\n    float _488 = dot(d, right);\n    float _492 = dot(d, up);\n    float _503;\n    if (((_488 * _488) + (_492 * _492)) > 1.0000000133514319600180897396058e-10)\n    {\n        _503 = precise::atan2(_492, _488) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _503 = 0.0;\n    }\n    float2 param = tile_origin + float2(1.0 + ((_503 - floor(_503)) * 64.0), 1.0 + (acos(fast::clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param, fa_light_atlas, fa_env_smp).x;\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cube_face(thread const float3& d)\n{\n    float3 _338 = abs(d);\n    float _340 = _338.x;\n    float _342 = _338.y;\n    bool _343 = _340 >= _342;\n    bool _351;\n    if (_343)\n    {\n        _351 = _340 >= _338.z;\n    }\n    else\n    {\n        _351 = _343;\n    }\n    int _352;\n    if (_351)\n    {\n        _352 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _367;\n        if (_342 >= _338.z)\n        {\n            _367 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _367 = (d.z > 0.0) ? 4 : 5;\n        }\n        _352 = _367;\n    }\n    return _352;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cube_face_basis(thread const int& f, thread float3& fwd, thread float3& up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0, 0.0, 0.0);\n        up = float3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0, 0.0, 0.0);\n            up = float3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0, 1.0, 0.0);\n                up = float3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0, -1.0, 0.0);\n                    up = float3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0, 0.0, 1.0);\n                        up = float3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0, 0.0, -1.0);\n                        up = float3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample_n(thread const int& li, thread const float3& world_pos, thread const float3& n, constant fa_mesh_fs_params& _390, texture2d<float> fa_light_tex, sampler fa_shadow_smp, texture2d<float> fa_light_atlas, sampler fa_env_smp, thread float3& fa_light_tint, thread bool& fa_light_is_area)\n{\n    int param = li;\n    int _734 = fa_light_base(param, _390);\n    bool _738 = _390.fa_ambient.w > 4.5;\n    int param_1 = _734;\n    float4 _742 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    int param_2 = _734 + 1;\n    float4 _747 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float _750 = _747.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = float3(1.0);\n    bool _762 = _738 && (_750 > 2.5);\n    fa_light_is_area = _762;\n    bool _764 = _750 < 0.5;\n    float3 l;\n    if (_764)\n    {\n        l = fast::normalize(_742.xyz);\n        if (_738)\n        {\n            int param_3 = _734 + 6;\n            float4 _778 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            if (_778.z > 0.5)\n            {\n                int param_4 = _734 + 4;\n                float4 _788 = fa_light_texel(param_4, fa_light_tex, fa_shadow_smp);\n                int param_5 = _734 + 5;\n                float4 _793 = fa_light_texel(param_5, fa_light_tex, fa_shadow_smp);\n                float2 param_6 = _778.xy;\n                float2 param_7 = fract(float2(dot(world_pos, _788.xyz) * _788.w, (-dot(world_pos, _793.xyz)) * _793.w) + float2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7, fa_light_atlas, fa_env_smp);\n            }\n        }\n    }\n    else\n    {\n        float3 _823 = _742.xyz;\n        float3 _825 = _823 - world_pos;\n        float3 to_light = _825;\n        float _828 = length(_825);\n        float reach = _828;\n        bool front = true;\n        if (_762)\n        {\n            int param_8 = _734 + 7;\n            reach = fast::max(_828 - fa_light_texel(param_8, fa_light_tex, fa_shadow_smp).w, 0.0);\n            int param_9 = _734 + 4;\n            float4 _852 = fa_light_texel(param_9, fa_light_tex, fa_shadow_smp);\n            int param_10 = _734 + 5;\n            float4 _857 = fa_light_texel(param_10, fa_light_tex, fa_shadow_smp);\n            int param_11 = _734 + 6;\n            float4 _862 = fa_light_texel(param_11, fa_light_tex, fa_shadow_smp);\n            float _863 = _862.w;\n            int param_12 = _734 + 2;\n            float3 _870 = fast::normalize(fa_light_texel(param_12, fa_light_tex, fa_shadow_smp).xyz);\n            bool _872 = _863 > 1.5;\n            bool _880;\n            if (!_872)\n            {\n                _880 = dot(_870, to_light) < 0.0;\n            }\n            else\n            {\n                _880 = _872;\n            }\n            front = _880;\n            float3 r = float3(0.0);\n            float3 _889 = _390.fa_camera_pos.xyz - world_pos;\n            bool _893 = dot(n, n) > 0.5;\n            bool _901;\n            if (_893)\n            {\n                _901 = dot(_889, _889) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _901 = _893;\n            }\n            if (_901)\n            {\n                r = reflect(-fast::normalize(_889), fast::normalize(n));\n            }\n            float3 param_13 = _823;\n            float3 param_14 = _870;\n            float3 param_15 = _852.xyz;\n            float3 param_16 = _857.xyz;\n            float param_17 = _852.w;\n            float param_18 = _857.w;\n            float param_19 = _863;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _937 = length(to_light);\n        dist = _937;\n        l = to_light / float3(fast::max(_937, 9.9999997473787516355514526367188e-05));\n        float _951 = reach / fast::max(_742.w, 0.001000000047497451305389404296875);\n        float _957 = fast::clamp(1.0 - (_951 * _951), 0.0, 1.0);\n        float _959;\n        if (front)\n        {\n            _959 = _957 * _957;\n        }\n        else\n        {\n            _959 = 0.0;\n        }\n        atten = _959;\n        bool _970 = _750 < 2.5;\n        if ((_750 > 1.5) && _970)\n        {\n            int param_22 = _734 + 2;\n            float4 _978 = fa_light_texel(param_22, fa_light_tex, fa_shadow_smp);\n            float _988 = _978.w;\n            int param_23 = _734 + 3;\n            float4 _993 = fa_light_texel(param_23, fa_light_tex, fa_shadow_smp);\n            float _994 = _993.x;\n            float cos_inner = _994;\n            if (_994 > 1.5)\n            {\n                cos_inner = mix(_988, 1.0, 0.25);\n            }\n            atten *= smoothstep(_988, cos_inner, dot(-l, fast::normalize(_978.xyz)));\n        }\n        if (_738 && (_750 < 1.5))\n        {\n            int param_24 = _734 + 6;\n            float4 _1018 = fa_light_texel(param_24, fa_light_tex, fa_shadow_smp);\n            if (_1018.z > 0.5)\n            {\n                float3 _1026 = -to_light;\n                int param_25 = _734 + 4;\n                int param_26 = _734 + 5;\n                float3 _1040 = fa_light_texel(param_25, fa_light_tex, fa_shadow_smp).xyz;\n                float3 _1044 = fa_light_texel(param_26, fa_light_tex, fa_shadow_smp).xyz;\n                float3 _1053 = float3(dot(_1026, _1040), dot(_1026, _1044), dot(_1026, cross(_1040, _1044)));\n                float3 param_27 = _1053;\n                int _1057 = fa_cube_face(param_27);\n                int param_28 = _1057;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1084 = float2(dot(_1053, cross(param_29, param_30)), dot(_1053, param_30)) / float2(fast::max(dot(_1053, param_29), 9.9999997473787516355514526367188e-05));\n                int _1088 = _1057 / 3;\n                float2 param_31 = _1018.xy + (float2(float(_1057 - (_1088 * 3)), float(_1088)) * 256.0);\n                float2 param_32 = float2(0.5 + (0.5 * _1084.x), 0.5 - (0.5 * _1084.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32, fa_light_atlas, fa_env_smp);\n            }\n            int param_33 = _734 + 7;\n            float4 _1118 = fa_light_texel(param_33, fa_light_tex, fa_shadow_smp);\n            if (_1118.z > 0.5)\n            {\n                int param_34 = _734 + 2;\n                int param_35 = _734 + 4;\n                int param_36 = _734 + 5;\n                float2 param_37 = _1118.xy;\n                float3 param_38 = -l;\n                float3 param_39 = fast::normalize(fa_light_texel(param_34, fa_light_tex, fa_shadow_smp).xyz);\n                float3 param_40 = fa_light_texel(param_35, fa_light_tex, fa_shadow_smp).xyz;\n                float3 param_41 = fa_light_texel(param_36, fa_light_tex, fa_shadow_smp).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41, fa_light_atlas, fa_env_smp);\n            }\n        }\n        else\n        {\n            if (_738 && _970)\n            {\n                int param_42 = _734 + 6;\n                float4 _1165 = fa_light_texel(param_42, fa_light_tex, fa_shadow_smp);\n                int param_43 = _734 + 7;\n                float4 _1170 = fa_light_texel(param_43, fa_light_tex, fa_shadow_smp);\n                bool _1173 = _1165.z > 0.5;\n                bool _1180;\n                if (!_1173)\n                {\n                    _1180 = _1170.z > 0.5;\n                }\n                else\n                {\n                    _1180 = _1173;\n                }\n                if (_1180)\n                {\n                    int param_44 = _734 + 2;\n                    float4 _1187 = fa_light_texel(param_44, fa_light_tex, fa_shadow_smp);\n                    float3 _1191 = fast::normalize(_1187.xyz);\n                    int param_45 = _734 + 4;\n                    float4 _1196 = fa_light_texel(param_45, fa_light_tex, fa_shadow_smp);\n                    int param_46 = _734 + 5;\n                    float4 _1201 = fa_light_texel(param_46, fa_light_tex, fa_shadow_smp);\n                    if (_1173)\n                    {\n                        float3 _1209 = -to_light;\n                        float _1216 = _1187.w;\n                        float _1232 = 0.5 / fast::max(dot(_1209, _1191) * (sqrt(fast::max(1.0 - (_1216 * _1216), 0.0)) / fast::max(_1216, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        float2 param_47 = _1165.xy;\n                        float2 param_48 = float2(0.5 + (dot(_1209, _1196.xyz) * _1232), 0.5 - (dot(_1209, _1201.xyz) * _1232));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48, fa_light_atlas, fa_env_smp);\n                    }\n                    if (_1170.z > 0.5)\n                    {\n                        float2 param_49 = _1170.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1191;\n                        float3 param_52 = _1196.xyz;\n                        float3 param_53 = _1201.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53, fa_light_atlas, fa_env_smp);\n                    }\n                }\n            }\n        }\n    }\n    float3 _4721 = _747.xyz * atten;\n    if (_738)\n    {\n        _4721 *= fa_light_tint;\n    }\n    int _1300;\n    if (_764)\n    {\n        _1300 = 0;\n    }\n    else\n    {\n        _1300 = ((_750 > 1.5) && (_750 < 2.5)) ? 2 : 1;\n    }\n    return LightSample{ l, _4721, atten, 1.0, dist, _1300 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_fetch(thread const float2& uv, thread const float4& rect, thread const float3& conv, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2094 = fa_shadow_depth(param, param_1, fa_shadow_smp, fa_shadow_tex);\n    float _2098;\n    if (conv.x < 0.5)\n    {\n        _2098 = _2094;\n    }\n    else\n    {\n        _2098 = (conv.y * conv.z) / (conv.z - (_2094 * (conv.z - conv.y)));\n    }\n    return _2098;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _2025 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_2025), sin(_2025)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_filter(thread const float2& uv, thread const float4& rect, thread const float& zr, thread const float& texel_m, thread const float& unit, thread const float& reach, thread const float& plane, thread const float3& conv, thread const int& mode, thread const float& k, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2047, texture2d<float> fa_shadow_tex)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2, fa_shadow_smp, fa_shadow_tex));\n    }\n    float _2144 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2153;\n        if (k < 0.0)\n        {\n            _2153 = (-k) / fast::max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2153 = k;\n        }\n        float _2173 = fast::clamp((_2153 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2144;\n            float2 _2192 = fa_shadow_vogel(param_3, param_4, param_5) * _2173;\n            float2 param_6 = uv + (_2192 * _2047.fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _2204 = fa_shadow_fetch(param_6, param_7, param_8, fa_shadow_smp, fa_shadow_tex);\n            if (_2204 < (zr - (length(_2192) * plane)))\n            {\n                sum += _2204;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2230 = sum / cnt;\n        float _2240;\n        if (k < 0.0)\n        {\n            _2240 = (-k) / fast::max(_2230, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2240 = k;\n        }\n        radius = fast::clamp(((fast::max(zr - _2230, 0.0) * unit) * _2240) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _2262 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2262; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2262;\n        float param_11 = _2144;\n        float2 _2281 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_2281 * _2047.fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_2281) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14, fa_shadow_smp, fa_shadow_tex));\n    }\n    return lit / float(_2262);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_local(thread const int& li, thread const float3& lpos, thread const float3& world, thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _390, texture2d<float> fa_light_tex, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2047, texture2d<float> fa_shadow_tex)\n{\n    bool _2481 = _390.fa_pbr.z < 0.5;\n    bool _2488;\n    if (!_2481)\n    {\n        _2488 = _2047.fa_shadow_lcfg.x < 0.5;\n    }\n    else\n    {\n        _2488 = _2481;\n    }\n    if (_2488)\n    {\n        return 1.0;\n    }\n    int param = (int(_2047.fa_shadow_lcfg.x + 0.5) - 1) + li;\n    float4 _2501 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    float _2502 = _2501.x;\n    if (_2502 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2511 = int(_2502 + 0.5);\n    int param_1 = _2511;\n    float4 _2515 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    int param_2 = _2511 + 1;\n    float4 _2520 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float fade = 1.0;\n    float _2523 = _2515.y;\n    if (_2523 > 0.0)\n    {\n        float _2540 = 1.0 - smoothstep(0.75 * _2523, _2523, length(world - _2047.fa_shadow_eye.xyz));\n        fade = _2540;\n        if (_2540 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2515.x > 1.5)\n    {\n        float3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2564 = (_2511 + 2) + (face * 6);\n    int param_4 = _2564;\n    int param_5 = _2564 + 1;\n    int param_6 = _2564 + 3;\n    float4 _2578 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n    int param_7 = _2564 + 4;\n    float4 _2583 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n    int param_8 = _2564 + 5;\n    float4 _2588 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n    float _2600 = _2588.x * fast::max(dot(_2578, float4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2605 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _2628 = fast::clamp(dot(n, _2578.xyz), -1.0, 1.0);\n    float _2647 = fast::min(sqrt(1.0 - (_2628 * _2628)) / fast::max(abs(dot(n, world - lpos)) / fast::max(dot(_2578, float4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2650 = _2520.y;\n    float _2652;\n    if (_2650 > 0.0)\n    {\n        _2652 = _2650;\n    }\n    else\n    {\n        _2652 = 1.5 * _2600;\n    }\n    float4 _2672 = float4(world + (n * (_2652 * sqrt(1.0 - (_2605 * _2605)))), 1.0);\n    float _2676 = dot(_2578, _2672);\n    float _2679 = _2588.y;\n    if (_2676 < _2679)\n    {\n        return 1.0;\n    }\n    float2 _2694 = float2(dot(fa_light_texel(param_4, fa_light_tex, fa_shadow_smp), _2672), dot(fa_light_texel(param_5, fa_light_tex, fa_shadow_smp), _2672)) / float2(_2676);\n    float _2696 = _2694.x;\n    bool _2699 = _2696 < _2583.x;\n    bool _2708;\n    if (!_2699)\n    {\n        _2708 = _2696 > _2583.z;\n    }\n    else\n    {\n        _2708 = _2699;\n    }\n    bool _2717;\n    if (!_2708)\n    {\n        _2717 = _2694.y < _2583.y;\n    }\n    else\n    {\n        _2717 = _2708;\n    }\n    bool _2726;\n    if (!_2717)\n    {\n        _2726 = _2694.y > _2583.w;\n    }\n    else\n    {\n        _2726 = _2717;\n    }\n    if (_2726)\n    {\n        return 1.0;\n    }\n    float _2732 = _2520.x;\n    float _2734;\n    if (_2732 > 0.0)\n    {\n        _2734 = _2732;\n    }\n    else\n    {\n        _2734 = 1.5 * _2600;\n    }\n    float2 param_9 = _2694;\n    float4 param_10 = _2583;\n    float param_11 = _2676 - (_2734 * (1.0 + (0.5 * _2647)));\n    float param_12 = _2600;\n    float param_13 = 1.0;\n    float param_14 = _2588.z * 0.25;\n    float param_15 = (_2600 * fast::min(_2647, 3.0)) * 0.5;\n    float3 param_16 = float3(1.0, _2679, _2588.z);\n    int param_17 = int(_2515.z + 0.5);\n    float param_18 = _2515.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, fa_shadow_smp, gl_FragCoord, _2047, fa_shadow_tex), fade);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _2047)\n{\n    float _2037;\n    if (i == 0)\n    {\n        _2037 = _2047.fa_shadow_split.x;\n    }\n    else\n    {\n        float _2053;\n        if (i == 1)\n        {\n            _2053 = _2047.fa_shadow_split.y;\n        }\n        else\n        {\n            float _2061;\n            if (i == 2)\n            {\n                _2061 = _2047.fa_shadow_split.z;\n            }\n            else\n            {\n                _2061 = _2047.fa_shadow_split.w;\n            }\n            _2053 = _2061;\n        }\n        _2037 = _2053;\n    }\n    return _2037;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2047, texture2d<float> fa_shadow_tex)\n{\n    float _2323 = fast::max(_2047.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _2328 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _2334 = sqrt(1.0 - (_2328 * _2328));\n    float _2341 = fast::min(_2334 / fast::max(_2328, 0.20000000298023223876953125), 4.0);\n    float _2346;\n    if (_2047.fa_shadow_bias.y > 0.0)\n    {\n        _2346 = _2047.fa_shadow_bias.y;\n    }\n    else\n    {\n        _2346 = 1.5 * _2047.fa_shadow_info[ci].x;\n    }\n    float4 _2371 = _2047.fa_shadow_mat[ci] * float4(world + (n * (_2346 * _2334)), 1.0);\n    float _2378 = _2371.x;\n    bool _2381 = _2378 < _2047.fa_shadow_rect[ci].x;\n    bool _2390;\n    if (!_2381)\n    {\n        _2390 = _2378 > _2047.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2390 = _2381;\n    }\n    bool _2399;\n    if (!_2390)\n    {\n        _2399 = _2371.y < _2047.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2399 = _2390;\n    }\n    bool _2408;\n    if (!_2399)\n    {\n        _2408 = _2371.y > _2047.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2408 = _2399;\n    }\n    bool _2415;\n    if (!_2408)\n    {\n        _2415 = _2371.z > 1.0;\n    }\n    else\n    {\n        _2415 = _2408;\n    }\n    if (_2415)\n    {\n        return -1.0;\n    }\n    float _2423;\n    if (_2047.fa_shadow_bias.x > 0.0)\n    {\n        _2423 = _2047.fa_shadow_bias.x;\n    }\n    else\n    {\n        _2423 = 1.5 * _2047.fa_shadow_info[ci].x;\n    }\n    float2 param = _2371.xy;\n    float4 param_1 = _2047.fa_shadow_rect[ci];\n    float param_2 = _2371.z - ((_2423 * (1.0 + (0.5 * _2341))) / _2323);\n    float param_3 = _2047.fa_shadow_info[ci].x;\n    float param_4 = _2323;\n    float param_5 = _2323 * 0.25;\n    float param_6 = ((_2047.fa_shadow_info[ci].x * fast::min(_2341, 3.0)) * 0.5) / _2323;\n    float3 param_7 = float3(0.0);\n    int param_8 = int(_2047.fa_shadow_cfg.z + 0.5);\n    float param_9 = _2047.fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9, fa_shadow_smp, gl_FragCoord, _2047, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _390, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2047, texture2d<float> fa_shadow_tex)\n{\n    if (_390.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2801 = int(_2047.fa_shadow_cfg.x + 0.5);\n    if (_2801 < 1)\n    {\n        return 1.0;\n    }\n    float _2816 = dot(world - _2047.fa_shadow_eye.xyz, _2047.fa_shadow_fwd.xyz);\n    int param = _2801 - 1;\n    if (_2816 > fa_shadow_split_at(param, _2047))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2828 = _2801 > 1;\n    bool _2835;\n    if (_2828)\n    {\n        _2835 = _2816 > _2047.fa_shadow_split.x;\n    }\n    else\n    {\n        _2835 = _2828;\n    }\n    if (_2835)\n    {\n        ci = 1;\n    }\n    bool _2839 = _2801 > 2;\n    bool _2846;\n    if (_2839)\n    {\n        _2846 = _2816 > _2047.fa_shadow_split.y;\n    }\n    else\n    {\n        _2846 = _2839;\n    }\n    if (_2846)\n    {\n        ci = 2;\n    }\n    bool _2850 = _2801 > 3;\n    bool _2857;\n    if (_2850)\n    {\n        _2857 = _2816 > _2047.fa_shadow_split.z;\n    }\n    else\n    {\n        _2857 = _2850;\n    }\n    if (_2857)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2801)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2883 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_shadow_smp, gl_FragCoord, _2047, fa_shadow_tex);\n        s = _2883;\n        if (_2883 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_2047.fa_shadow_cfg.y > 0.0)\n    {\n        float _2908;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2908 = fa_shadow_split_at(param_5, _2047);\n        }\n        else\n        {\n            _2908 = _2047.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _2927 = _2047.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _2047) - _2908, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2938 = fast::clamp((_2816 - (fa_shadow_split_at(param_7, _2047) - _2927)) / _2927, 0.0, 1.0);\n        if (_2938 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2801)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _2959 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_shadow_smp, gl_FragCoord, _2047, fa_shadow_tex);\n                s2 = _2959;\n                if (_2959 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2938);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _390, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2047, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, _390, fa_shadow_smp, gl_FragCoord, _2047, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_contact_shadow(thread const int& li, thread const float3& world, thread const float3& gn, thread const float3& l, thread const float& dist, constant fa_mesh_fs_params& _390, texture2d<float> fa_light_tex, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2047, texture2d<float> fa_screen_tex)\n{\n    bool _3240 = _390.fa_ct_a.x < 0.5;\n    bool _3247;\n    if (!_3240)\n    {\n        _3247 = _2047.fa_shadow_lcfg.x < 0.5;\n    }\n    else\n    {\n        _3247 = _3240;\n    }\n    if (_3247)\n    {\n        return 1.0;\n    }\n    int param = (int(_2047.fa_shadow_lcfg.x + 0.5) - 1) + li;\n    float4 _3260 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    float _3261 = _3260.y;\n    float len = _3261;\n    if (_3261 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3273 = length(world - _390.fa_camera_pos.xyz);\n    float _3283 = 1.0 - smoothstep(0.5 * _390.fa_ct_b.x, _390.fa_ct_b.x, _3273);\n    if (_3283 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3289 = len;\n    float _3292 = fast::min(_3289, 0.89999997615814208984375 * dist);\n    len = _3292;\n    float _3298 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _3273);\n    float _3303 = _3298 + (0.5 * _3292);\n    float3 _3309 = world + (gn * _3298);\n    float _3311 = fa_shadow_noise(gl_FragCoord);\n    float occ = 0.0;\n    float _3376;\n    for (int k = 0; k < 12; k++)\n    {\n        float _3327 = (float(k) + _3311) * 0.083333335816860198974609375;\n        float3 _3335 = _3309 + (l * (_3327 * len));\n        float4 _3341 = float4(_3335, 1.0);\n        float _3347 = dot(_390.fa_ct_vpw, _3341);\n        if (_3347 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        float2 _3367 = float2(dot(_390.fa_ct_vpx, _3341), dot(_390.fa_ct_vpy, _3341)) / float2(_3347);\n        float _3371 = _3367.x * 0.5;\n        float _3372 = _3371 + 0.5;\n        if (_390.fa_ct_a.y > 0.5)\n        {\n            _3376 = (_3367.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _3376 = 0.5 - (_3367.y * 0.5);\n        }\n        bool _3392 = _3372 < 0.0;\n        bool _3399;\n        if (!_3392)\n        {\n            _3399 = _3372 >= 1.0;\n        }\n        else\n        {\n            _3399 = _3392;\n        }\n        bool _3406;\n        if (!_3399)\n        {\n            _3406 = _3376 < 0.0;\n        }\n        else\n        {\n            _3406 = _3399;\n        }\n        bool _3413;\n        if (!_3406)\n        {\n            _3413 = _3376 >= 1.0;\n        }\n        else\n        {\n            _3413 = _3406;\n        }\n        if (_3413)\n        {\n            break;\n        }\n        float4 _3432 = fa_screen_tex.read(uint2(int2(float2(_3372, _3376) * _390.fa_ct_a.zw)), 0);\n        if (_3432.w < 0.5)\n        {\n            continue;\n        }\n        float _3451 = (dot(_390.fa_ct_fwd.xyz, _3335) + _390.fa_ct_fwd.w) - _3432.x;\n        if ((_3451 > _3298) && (_3451 < _3303))\n        {\n            occ = fast::max(occ, (1.0 - (_3327 * _3327)) * smoothstep(0.0, 0.0500000007450580596923828125, fast::min(fast::min(_3372, 0.5 - _3371), fast::min(_3376, 1.0 - _3376))));\n        }\n    }\n    return 1.0 - (occ * _3283);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, constant fa_mesh_fs_params& _390, texture2d<float> fa_light_tex, sampler fa_shadow_smp, texture2d<float> fa_light_atlas, sampler fa_env_smp, thread float3& fa_light_tint, thread bool& fa_light_is_area, thread float4& gl_FragCoord, constant fa_shadows& _2047, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos, texture2d<float> fa_screen_tex, thread float3& fa_lm)\n{\n    int param = li;\n    float _3554 = fa_baked_keep(param, _390, fa_light_tex, fa_shadow_smp, fa_lm);\n    if (_3554 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample{ float3(0.0, 1.0, 0.0), float3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1, _390, fa_light_tex, fa_shadow_smp) + 0.5) };\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _3580 = fa_light_sample_n(param_2, param_3, param_4, _390, fa_light_tex, fa_shadow_smp, fa_light_atlas, fa_env_smp, fa_light_tint, fa_light_is_area);\n    float3 _4747 = _3580.color;\n    float _4748 = _3580.attenuation;\n    float _4749 = _3580.shadow;\n    bool _3583 = _3580.type == 0;\n    if (_3583 && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _3580.direction;\n        float _3594 = fa_shadow_factor(param_5, param_6, _390, fa_shadow_smp, gl_FragCoord, _2047, fa_shadow_tex, fa_world_pos);\n        _4749 = _3594;\n        _4747 *= _3594;\n    }\n    else\n    {\n        bool _3605 = _3580.type != 0;\n        bool _3611;\n        if (_3605)\n        {\n            _3611 = _4748 > 0.0;\n        }\n        else\n        {\n            _3611 = _3605;\n        }\n        if (_3611)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7, _390);\n            int param_9 = li;\n            float3 param_10 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp).xyz;\n            float3 param_11 = world_pos;\n            float3 param_12 = gn;\n            float3 param_13 = _3580.direction;\n            float _3630 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13, _390, fa_light_tex, fa_shadow_smp, gl_FragCoord, _2047, fa_shadow_tex);\n            _4749 = _3630;\n            _4747 *= _3630;\n        }\n    }\n    bool _3640 = _390.fa_ct_a.x > 0.5;\n    bool _3646;\n    if (_3640)\n    {\n        _3646 = _4748 > 0.0;\n    }\n    else\n    {\n        _3646 = _3640;\n    }\n    if (_3646)\n    {\n        float _3653;\n        if (_3583)\n        {\n            _3653 = 1000000000.0;\n        }\n        else\n        {\n            _3653 = _3580._distance;\n        }\n        int param_14 = li;\n        float3 param_15 = world_pos;\n        float3 param_16 = gn;\n        float3 param_17 = _3580.direction;\n        float param_18 = _3653;\n        float _3671 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18, _390, fa_light_tex, fa_shadow_smp, gl_FragCoord, _2047, fa_screen_tex);\n        _4749 *= _3671;\n        _4747 *= _3671;\n    }\n    float _3684 = _4748;\n    float _3685 = _3684 * _3554;\n    _4748 = _3685;\n    float3 _3689 = _4747;\n    float3 _3690 = _3689 * _3554;\n    _4747 = _3690;\n    return LightSample{ _3580.direction, _3690, _3685, _4749, _3580._distance, _3580.type };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 light(thread const SurfaceInput& i, thread const Surface& s, thread const LightSample& l, constant fa_material& _3710)\n{\n    float _3704;\n    if (dot(s.normal, l.direction) > 0.5)\n    {\n        _3704 = 1.0;\n    }\n    else\n    {\n        _3704 = _3710.dark;\n    }\n    return (s.albedo * l.color) * _3704;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _2047)\n{\n    if (_2047.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _2983 = int(_2047.fa_shadow_cfg.x + 0.5);\n    float _2993 = dot(world - _2047.fa_shadow_eye.xyz, _2047.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _2998 = _2983 > 0;\n    bool _3007;\n    if (_2998)\n    {\n        int param = _2983 - 1;\n        _3007 = _2993 <= fa_shadow_split_at(param, _2047);\n    }\n    else\n    {\n        _3007 = _2998;\n    }\n    if (_3007)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3013 = _2983 > 1;\n        bool _3020;\n        if (_3013)\n        {\n            _3020 = _2993 > _2047.fa_shadow_split.x;\n        }\n        else\n        {\n            _3020 = _3013;\n        }\n        if (_3020)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3026 = _2983 > 2;\n        bool _3033;\n        if (_3026)\n        {\n            _3033 = _2993 > _2047.fa_shadow_split.y;\n        }\n        else\n        {\n            _3033 = _3026;\n        }\n        if (_3033)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3039 = _2983 > 3;\n        bool _3046;\n        if (_3039)\n        {\n            _3046 = _2993 > _2047.fa_shadow_split.z;\n        }\n        else\n        {\n            _3046 = _3039;\n        }\n        if (_3046)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _390 [[buffer(1)]], constant fa_material& _3710 [[buffer(5)]], constant fa_shadows& _2047 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_env_tex [[texture(6)]], texture2d<float> fa_light_tex [[texture(7)]], texture2d<float> fa_light_atlas [[texture(8)]], texture2d<float> fa_lightmap [[texture(9)]], texture2d<float> fa_decal_tex [[texture(10)]], texture2d<float> fa_screen_tex [[texture(11)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _4568 = fast::normalize(in.fa_world_normal);\n    float3 fa_light_tint;\n    bool fa_light_is_area;\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _4568 = -_4568;\n    }\n    float3 _4143 = fast::normalize(_390.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, _390, fa_light_tex, fa_shadow_smp, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _4568, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _4143, short(gl_FrontFacing) };\n    Surface _4151 = fa_standard_surface(param_1, _390, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _4599 = _4151.albedo;\n    float _4600 = _4151.alpha;\n    float3 _4601 = _4151.normal;\n    float _4602 = _4151.metallic;\n    float _4603 = _4151.roughness;\n    float _4604 = _4151.occlusion;\n    float3 _4605 = _4151.emission;\n    float _4606 = _4151.clearcoat;\n    float _4607 = _4151.clearcoat_roughness;\n    float3 _4608 = _4151.sheen_color;\n    float _4609 = _4151.sheen_roughness;\n    float _4610 = _4151.anisotropy;\n    float _4611 = _4151.anisotropy_rotation;\n    float _4612 = _4151.specular;\n    float _4613 = _4151.ior;\n    float3 _4614 = _4151.specular_color;\n    float _4615 = _4151.transmission;\n    float _4616 = _4151.thickness;\n    float3 _4617 = _4151.attenuation_color;\n    float _4618 = _4151.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _4568, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _4143, short(gl_FrontFacing) };\n    Surface param_3 = _4151;\n    surface(param_2, param_3);\n    _4599 = param_3.albedo;\n    _4600 = param_3.alpha;\n    _4601 = param_3.normal;\n    _4602 = param_3.metallic;\n    _4603 = param_3.roughness;\n    _4604 = param_3.occlusion;\n    _4605 = param_3.emission;\n    _4606 = param_3.clearcoat;\n    _4607 = param_3.clearcoat_roughness;\n    _4608 = param_3.sheen_color;\n    _4609 = param_3.sheen_roughness;\n    _4610 = param_3.anisotropy;\n    _4611 = param_3.anisotropy_rotation;\n    _4612 = param_3.specular;\n    _4613 = param_3.ior;\n    _4614 = param_3.specular_color;\n    _4615 = param_3.transmission;\n    _4616 = param_3.thickness;\n    _4617 = param_3.attenuation_color;\n    _4618 = param_3.attenuation_distance;\n    float3 param_4 = in.fa_world_pos;\n    float3 param_5 = _4568;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7, _390, fa_light_tex, fa_shadow_smp, fa_env_smp, fa_decal_tex);\n    _4599 = param_6;\n    _4601 = param_7;\n    float3 result;\n    if (_390.fa_emissive.w > 0.5)\n    {\n        result = _4599;\n    }\n    else\n    {\n        float3 _4190 = _4601;\n        float3 _4191 = fast::normalize(_4190);\n        _4601 = _4191;\n        float3 param_8 = _4191;\n        float3 lit = (fa_indirect_diffuse(param_8, _390, fa_env_smp, fa_env_tex, in.fa_lm, fa_lightmap) * _4599) * _4604;\n        int _4210 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _4210; ln++)\n        {\n            int param_9 = ln;\n            int _4223 = fa_cl_light(param_9, _390, fa_light_tex, fa_shadow_smp, fa_cl_ndir, fa_cl_slot);\n            int param_10 = _4223;\n            if (fa_baked_keep(param_10, _390, fa_light_tex, fa_shadow_smp, in.fa_lm) <= 0.0)\n            {\n                continue;\n            }\n            int param_11 = _4223;\n            float3 param_12 = in.fa_world_pos;\n            float3 param_13 = _4568;\n            LightSample _4239 = fa_light_shadowed(param_11, param_12, param_13, _390, fa_light_tex, fa_shadow_smp, fa_light_atlas, fa_env_smp, fa_light_tint, fa_light_is_area, gl_FragCoord, _2047, fa_shadow_tex, in.fa_world_pos, fa_screen_tex, in.fa_lm);\n            SurfaceInput param_14 = SurfaceInput{ in.fa_world_pos, _4568, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _4143, short(gl_FrontFacing) };\n            Surface param_15 = Surface{ _4599, _4600, _4601, _4602, _4603, _4604, _4605, _4606, _4607, _4608, _4609, _4610, _4611, _4612, _4613, _4614, _4615, _4616, _4617, _4618 };\n            LightSample param_16 = _4239;\n            lit += light(param_14, param_15, param_16, _3710);\n        }\n        result = lit;\n    }\n    float3 _4254 = result;\n    float3 _4255 = _4254 + _4605;\n    result = _4255;\n    float3 param_17 = _4255;\n    float3 param_18 = in.fa_world_pos;\n    result = fa_shadow_debug(param_17, param_18, _2047);\n    bool _4264 = _390.fa_fog.w > 0.0;\n    bool _4271;\n    if (!_4264)\n    {\n        _4271 = _390.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _4271 = _4264;\n    }\n    if (_4271)\n    {\n        float3 _4280 = in.fa_world_pos - _390.fa_camera_pos.xyz;\n        float _4286 = dot(_4280, _390.fa_fog_c.xyz);\n        bool _4290 = _390.fa_fog_c.w > 0.5;\n        float _4291;\n        if (_4290)\n        {\n            _4291 = _4286;\n        }\n        else\n        {\n            _4291 = length(_4280);\n        }\n        float _4303 = _4291 - _390.fa_fog_b.x;\n        if (_4303 > 0.0)\n        {\n            float _4312 = _390.fa_fog.w * _4303;\n            float tau = _4312 * _4312;\n            if (_390.fa_fog_b.y > 0.0)\n            {\n                float _4328;\n                if (_4290)\n                {\n                    _4328 = in.fa_world_pos.y - (_390.fa_fog_c.y * _4286);\n                }\n                else\n                {\n                    _4328 = _390.fa_camera_pos.y;\n                }\n                float _4349 = mix(_4328, in.fa_world_pos.y, fast::clamp(_390.fa_fog_b.x / _4291, 0.0, 1.0));\n                float _4353 = in.fa_world_pos.y - _4349;\n                float _4358 = _4349 - _390.fa_fog_b.z;\n                float _4363 = in.fa_world_pos.y - _390.fa_fog_b.z;\n                bool _4366 = _4358 <= 0.0;\n                bool _4367 = !_4366;\n                bool _4373;\n                if (_4367)\n                {\n                    _4373 = _390.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4373 = _4366;\n                }\n                float _4374;\n                if (_4373)\n                {\n                    _4374 = _390.fa_fog_b.y;\n                }\n                else\n                {\n                    _4374 = _390.fa_fog_b.y * exp(-fast::min(_390.fa_fog_b.w * _4358, 80.0));\n                }\n                bool _4401;\n                if (_4367)\n                {\n                    _4401 = _390.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4401 = _4366;\n                }\n                float _4402;\n                if (_4401)\n                {\n                    _4402 = _390.fa_fog_b.y * _4358;\n                }\n                else\n                {\n                    _4402 = (_390.fa_fog_b.y * (1.0 - exp(-fast::min(_390.fa_fog_b.w * _4358, 80.0)))) / _390.fa_fog_b.w;\n                }\n                bool _4427 = _4363 <= 0.0;\n                bool _4434;\n                if (!_4427)\n                {\n                    _4434 = _390.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4434 = _4427;\n                }\n                float _4435;\n                if (_4434)\n                {\n                    _4435 = _390.fa_fog_b.y * _4363;\n                }\n                else\n                {\n                    _4435 = (_390.fa_fog_b.y * (1.0 - exp(-fast::min(_390.fa_fog_b.w * _4363, 80.0)))) / _390.fa_fog_b.w;\n                }\n                float _4462;\n                if (abs(_4353) < 0.001000000047497451305389404296875)\n                {\n                    _4462 = _4374;\n                }\n                else\n                {\n                    _4462 = (_4435 - _4402) / _4353;\n                }\n                tau += (_4303 * fast::max(_4462, 0.0));\n            }\n            result = mix(result, _390.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _4600);\n    return out;\n}\n\n",
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
            "size": 656,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_390",
            "msl_buffer_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2047",
            "msl_buffer_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_3710",
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
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n#pragma clang diagnostic ignored \"-Wmissing-braces\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\ntemplate<typename T, size_t Num>\nstruct spvUnsafeArray\n{\n    T elements[Num ? Num : 1];\n    \n    thread T& operator [] (size_t pos) thread\n    {\n        return elements[pos];\n    }\n    constexpr const thread T& operator [] (size_t pos) const thread\n    {\n        return elements[pos];\n    }\n    \n    device T& operator [] (size_t pos) device\n    {\n        return elements[pos];\n    }\n    constexpr const device T& operator [] (size_t pos) const device\n    {\n        return elements[pos];\n    }\n    \n    constexpr const constant T& operator [] (size_t pos) const constant\n    {\n        return elements[pos];\n    }\n    \n    threadgroup T& operator [] (size_t pos) threadgroup\n    {\n        return elements[pos];\n    }\n    constexpr const threadgroup T& operator [] (size_t pos) const threadgroup\n    {\n        return elements[pos];\n    }\n};\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n    float4 fa_ct_a;\n    float4 fa_ct_b;\n    float4 fa_ct_vpx;\n    float4 fa_ct_vpy;\n    float4 fa_ct_vpw;\n    float4 fa_ct_fwd;\n    float4 fa_tr_a;\n    float4 fa_tr_b;\n    float4 fa_probe_sh[9];\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n    float4 fa_shadow_lcfg;\n};\n\nstruct fa_material\n{\n    float dark;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float3 fa_lm [[user(locn5)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_cluster_texel(thread const float3& world_pos, constant fa_mesh_fs_params& _390, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    bool _1318 = _390.fa_cl_info.x < 0.0;\n    bool _1325;\n    if (!_1318)\n    {\n        _1325 = _390.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _1325 = _1318;\n    }\n    bool _1333;\n    if (!_1325)\n    {\n        _1333 = _390.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _1333 = _1325;\n    }\n    bool _1340;\n    if (!_1333)\n    {\n        _1340 = _390.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _1340 = _1333;\n    }\n    bool _1347;\n    if (!_1340)\n    {\n        _1347 = _390.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _1347 = _1340;\n    }\n    if (_1347)\n    {\n        return float4(0.0);\n    }\n    float4 _1357 = float4(world_pos, 1.0);\n    float _1363 = dot(_390.fa_cl_vpw, _1357);\n    if (!(_1363 > 9.9999999747524270787835121154785e-07))\n    {\n        return float4(0.0);\n    }\n    float2 _1385 = float2(dot(_390.fa_cl_vpx, _1357), dot(_390.fa_cl_vpy, _1357)) / float2(_1363);\n    int _1389 = int(_390.fa_cl_grid.x);\n    int _1393 = int(_390.fa_cl_grid.y);\n    int param = (int(_390.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_390.fa_cl_fwd.xyz, world_pos) + _390.fa_cl_fwd.w, _390.fa_cl_grid.w) / _390.fa_cl_grid.w) * _390.fa_cl_grid.z)), 0, int(_390.fa_cl_info.y) - 1) * _1393) + clamp(int(floor(((_1385.y * 0.5) + 0.5) * _390.fa_cl_grid.y)), 0, _1393 - 1)) * _1389)) + clamp(int(floor(((_1385.x * 0.5) + 0.5) * _390.fa_cl_grid.x)), 0, _1389 - 1);\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, constant fa_mesh_fs_params& _390, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    float3 param = world_pos;\n    float4 _1469 = fa_cluster_texel(param, _390, fa_light_tex, fa_shadow_smp);\n    return int2(int(_1469.x), int(_1469.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, constant fa_mesh_fs_params& _390, texture2d<float> fa_light_tex, sampler fa_shadow_smp, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_390.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _3528 = fa_cluster_lookup(param, _390, fa_light_tex, fa_shadow_smp);\n    fa_cl_slot = _3528.x;\n    fa_cl_local = _3528.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _3759 = fa_linear_to_srgb(param);\n        c = _3759;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _3767 = fa_srgb_to_linear(param_1);\n            c = _3767;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _272;\n    if (bool(i.front_facing))\n    {\n        _272 = i.world_normal;\n    }\n    else\n    {\n        _272 = -i.world_normal;\n    }\n    float3 _296 = fast::normalize(i.world_tangent.xyz - (_272 * dot(_272, i.world_tangent.xyz)));\n    float3 _323 = fast::normalize(((_296 * m.x) + ((cross(_272, _296) * i.world_tangent.w) * m.y)) + (_272 * m.z));\n    float3 _326;\n    if (bool(i.front_facing))\n    {\n        _326 = _323;\n    }\n    else\n    {\n        _326 = -_323;\n    }\n    return _326;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _390, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _390.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _3798 = fa_tex_fix(param_2, param_3);\n    float4 _4923 = base_t;\n    _4923.x = _3798.x;\n    _4923.y = _3798.y;\n    _4923.z = _3798.z;\n    base_t = _4923;\n    float4 _3812 = (_4923 * _390.fa_base_color) * i.vertex_color;\n    float3 _4767 = i.world_normal;\n    if (_390.fa_maps.z > 0.5)\n    {\n        float param_4 = _390.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _3844 = fa_tex_fix(param_6, param_7);\n        float3 _3847 = (_3844 * 2.0) - float3(1.0);\n        float2 _3852 = _3847.xy * _390.fa_maps.x;\n        float3 _4931 = _3847;\n        _4931.x = _3852.x;\n        _4931.y = _3852.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _4931;\n        _4767 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _390.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _3880 = fa_tex_fix(param_12, param_13);\n    float4 _4934 = mrt;\n    _4934.x = _3880.x;\n    _4934.y = _3880.y;\n    _4934.z = _3880.z;\n    mrt = _4934;\n    float4 _3908 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _390.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _3908.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _3919 = fa_tex_fix(param_16, param_17);\n    float param_18 = _390.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _3949 = fa_tex_fix(param_20, param_21);\n    float _4772 = _390.fa_layers_a.x;\n    float _4773 = _390.fa_layers_a.y;\n    float _4776 = _390.fa_layers_a.z;\n    float _4775 = _390.fa_layers_b.w;\n    float _4778 = _390.fa_layers_c.x;\n    if (_390.fa_layers_c.z > 0.5)\n    {\n        if (mod(_390.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _4772 *= _3919.y;\n            _4773 *= _3919.z;\n            _4775 *= _3908.w;\n        }\n        if (_390.fa_layers_c.z > 1.5)\n        {\n            _4776 *= mrt.x;\n            _4778 *= mrt.w;\n        }\n    }\n    return Surface{ _3812.xyz, _3812.w, _4767, fast::clamp(_390.fa_pbr.x * _3880.z, 0.0, 1.0), fast::clamp(_390.fa_pbr.y * _3880.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_390.fa_maps.y * (_3919.x - 1.0)), _390.fa_emissive.xyz + (_390.fa_model_emissive.xyz * _3949), _4772, _4773, _390.fa_layers_b.xyz, _4775, _4776, _390.fa_layers_a.w, _4778, _390.fa_layers_c.y, _390.fa_layers_d.xyz, _390.fa_tr_a.x, _390.fa_tr_a.y, _390.fa_tr_b.xyz, _390.fa_tr_a.z };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_decal_tile(thread const float4& rect, thread const float2& uv, thread const float2& atlas, thread const float2& ddx, thread const float2& ddy, sampler fa_env_smp, texture2d<float> fa_decal_tex)\n{\n    float2 _1549 = rect.zw - rect.xy;\n    float2 _1553 = _1549 * atlas;\n    float2 _1557 = ddx * _1553;\n    float2 _1561 = ddy * _1553;\n    return fa_decal_tex.sample(fa_env_smp, (rect.xy + (fast::clamp(uv, float2(0.0), float2(1.0)) * _1549)), level(fast::clamp(0.5 * log2(fast::max(fast::max(dot(_1557, _1557), dot(_1561, _1561)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_apply_decals(thread const float3& world_pos, thread const float3& geo_normal, thread float3& albedo, thread float3& normal, constant fa_mesh_fs_params& _390, texture2d<float> fa_light_tex, sampler fa_shadow_smp, sampler fa_env_smp, texture2d<float> fa_decal_tex)\n{\n    bool _1594 = _390.fa_counts.y < 0.5;\n    bool _1601;\n    if (!_1594)\n    {\n        _1601 = _390.fa_counts.w < 0.5;\n    }\n    else\n    {\n        _1601 = _1594;\n    }\n    if (_1601)\n    {\n        return;\n    }\n    float3 _1607 = dfdx(world_pos);\n    float3 _1610 = dfdy(world_pos);\n    float3 param = world_pos;\n    float4 _1614 = fa_cluster_texel(param, _390, fa_light_tex, fa_shadow_smp);\n    int _1618 = int(_1614.w);\n    if (_1618 < 1)\n    {\n        return;\n    }\n    int _1628 = int(_390.fa_counts.y + 0.5);\n    int param_1 = _1628;\n    float4 _1632 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float2 _1635 = _1632.yz;\n    int _1639 = int(_1632.w);\n    int param_2 = _1628 + 1;\n    float4 _1644 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float _1645 = _1644.x;\n    int _1651 = int(_390.fa_counts.w + 0.5) - 1;\n    int _1655 = int(_1614.z);\n    float3 _1920;\n    for (int k = 0; k < _1618; k++)\n    {\n        int _1668 = _1655 + k;\n        int param_3 = _1639 + (_1668 >> 2);\n        int _1685 = (_1628 + 2) + (int(fa_light_texel(param_3, fa_light_tex, fa_shadow_smp)[_1668 & 3]) * 7);\n        int param_4 = _1685 + 6;\n        float4 _1690 = fa_light_texel(param_4, fa_light_tex, fa_shadow_smp);\n        if (((int(_1690.w + 0.5) >> _1651) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1685;\n        float4 _1705 = fa_light_texel(param_5, fa_light_tex, fa_shadow_smp);\n        int param_6 = _1685 + 1;\n        float4 _1710 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n        int param_7 = _1685 + 2;\n        float4 _1715 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n        float3 _1718 = _1705.xyz;\n        float _1723 = dot(_1718, world_pos) + _1705.w;\n        float3 _1725 = _1710.xyz;\n        float _1730 = dot(_1725, world_pos) + _1710.w;\n        float3 _1732 = _1715.xyz;\n        float _1737 = dot(_1732, world_pos) + _1715.w;\n        bool _1742 = abs(_1723) > 0.5;\n        bool _1750;\n        if (!_1742)\n        {\n            _1750 = abs(_1730) > 0.5;\n        }\n        else\n        {\n            _1750 = _1742;\n        }\n        bool _1758;\n        if (!_1750)\n        {\n            _1758 = abs(_1737) > 0.5;\n        }\n        else\n        {\n            _1758 = _1750;\n        }\n        if (_1758)\n        {\n            continue;\n        }\n        float _1773 = fast::clamp(dot(geo_normal, fast::normalize(_1732)) * _1690.z, 0.0, 1.0);\n        if (_1773 <= 0.0)\n        {\n            continue;\n        }\n        float _1793 = (fast::clamp((0.5 - abs(_1737)) * 10.0, 0.0, 1.0) * _1773) * _1690.x;\n        float2 _1801 = float2(_1723 + 0.5, 0.5 - _1730);\n        float2 _1811 = float2(dot(_1718, _1607), dot(_1725, _1607));\n        float2 _1821 = float2(dot(_1718, _1610), dot(_1725, _1610));\n        int param_8 = _1685 + 5;\n        float4 _1826 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n        int param_9 = _1685 + 3;\n        float4 _1831 = fa_light_texel(param_9, fa_light_tex, fa_shadow_smp);\n        int param_10 = _1685 + 4;\n        float4 _1836 = fa_light_texel(param_10, fa_light_tex, fa_shadow_smp);\n        float tex_a = 1.0;\n        float3 col = _1826.xyz;\n        bool _1846 = _1831.z > _1831.x;\n        if (_1846)\n        {\n            float4 param_11 = _1831;\n            float2 param_12 = _1801;\n            float2 param_13 = _1635;\n            float2 param_14 = _1811;\n            float2 param_15 = _1821;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15, fa_env_smp, fa_decal_tex);\n            if ((_1645 > 0.5) && (_1645 < 1.5))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1872 = fa_dc_to_linear(param_16);\n                float4 _4855 = tx;\n                _4855.x = _1872.x;\n                _4855.y = _1872.y;\n                _4855.z = _1872.z;\n                tx = _4855;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, float3(fast::clamp((_1793 * tex_a) * _1826.w, 0.0, 1.0)));\n        if (_1836.z > _1836.x)\n        {\n            float4 param_17 = _1836;\n            float2 param_18 = _1801;\n            float2 param_19 = _1635;\n            float2 param_20 = _1811;\n            float2 param_21 = _1821;\n            float4 _1916 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21, fa_env_smp, fa_decal_tex);\n            if (_1645 > 1.5)\n            {\n                float3 param_22 = _1916.xyz;\n                float3 _1926 = fa_dc_to_srgb(param_22);\n                _1920 = _1926;\n            }\n            else\n            {\n                _1920 = _1916.xyz;\n            }\n            float3 _1935 = (_1920 * 2.0) - float3(1.0);\n            float2 _1940 = _1935.xy * _1690.y;\n            float3 _1962 = (fast::normalize(_1718) * _1940.x) + (fast::normalize(_1725) * _1940.y);\n            float3 _1965 = fast::normalize(normal);\n            normal = fast::normalize(mix(_1965, fast::normalize((_1965 * fast::max(_1935.z, 0.0500000007450580596923828125)) + (_1962 - (_1965 * dot(_1965, _1962)))), float3(fast::clamp(_1793 * (_1846 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_sh_coef(thread const int& k, constant fa_mesh_fs_params& _390, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float3 v = fa_env_tex.sample(fa_env_smp, float3(1.0, 1.0 - (float((2 * (k >> 2)) + 1) * 0.25), 1.0 - (float((2 * (k & 3)) + 1) * 0.25)), level(5.0)).xyz;\n    if (_390.fa_env_sky.w > 1.5)\n    {\n        v = (v - float3(0.5)) * 8.0;\n    }\n    return v;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sh_eval(thread const spvUnsafeArray<float3, 9>& c, thread const float3& n)\n{\n    float3 _3160 = fast::max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), float3(0.0));\n    return _3160;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _390, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    if (_390.fa_env_sky.w > 0.5)\n    {\n        spvUnsafeArray<float3, 9> c;\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param, _390, fa_env_smp, fa_env_tex);\n        }\n        spvUnsafeArray<float3, 9> param_1 = c;\n        float3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return _390.fa_ambient.xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_indirect_diffuse(thread const float3& n, constant fa_mesh_fs_params& _390, sampler fa_env_smp, texturecube<float> fa_env_tex, thread float3& fa_lm, texture2d<float> fa_lightmap)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return fa_lightmap.sample(fa_env_smp, fa_lm.xy, level(0.0)).xyz;\n    }\n    if (_390.fa_probe_sh[0].w > 0.0)\n    {\n        spvUnsafeArray<float3, 9> c;\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = _390.fa_probe_sh[k].xyz;\n        }\n        float3 param = n;\n        spvUnsafeArray<float3, 9> param_1 = c;\n        float3 param_2 = n;\n        return mix(fa_ambient_light(param, _390, fa_env_smp, fa_env_tex), fa_sh_eval(param_1, param_2), float3(fast::clamp(_390.fa_probe_sh[0].w, 0.0, 1.0)));\n    }\n    float3 param_3 = n;\n    return fa_ambient_light(param_3, _390, fa_env_smp, fa_env_tex);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, constant fa_mesh_fs_params& _390, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (int(_390.fa_cl_info.x) + int(_390.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, constant fa_mesh_fs_params& _390, texture2d<float> fa_light_tex, sampler fa_shadow_smp, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, _390, fa_light_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_light_base(thread const int& li, constant fa_mesh_fs_params& _390)\n{\n    return li * ((_390.fa_ambient.w > 4.5) ? 8 : 4);\n}\n\nstatic inline __attribute__((always_inline))\nbool fa_light_baked(thread const int& li, constant fa_mesh_fs_params& _390, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li;\n    int param_1 = fa_light_base(param, _390) + 3;\n    return fa_light_texel(param_1, fa_light_tex, fa_shadow_smp).w > 0.5;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_baked_keep(thread const int& li, constant fa_mesh_fs_params& _390, texture2d<float> fa_light_tex, sampler fa_shadow_smp, thread float3& fa_lm)\n{\n    float _3498;\n    if (fa_lm.z > 0.5)\n    {\n        _3498 = 0.0;\n    }\n    else\n    {\n        _3498 = 1.0 - fast::clamp(_390.fa_probe_sh[0].w, 0.0, 1.0);\n    }\n    bool _3509 = _3498 < 1.0;\n    bool _3515;\n    if (_3509)\n    {\n        int param = li;\n        _3515 = fa_light_baked(param, _390, fa_light_tex, fa_shadow_smp);\n    }\n    else\n    {\n        _3515 = _3509;\n    }\n    return _3515 ? _3498 : 1.0;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_light_type(thread const int& li, constant fa_mesh_fs_params& _390, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li;\n    int param_1 = fa_light_base(param, _390) + 1;\n    return fa_light_texel(param_1, fa_light_tex, fa_shadow_smp).w;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_area_point(thread const float3& c, thread const float3& axis, thread const float3& ru, thread const float3& uu, thread const float& hx, thread const float& hy, thread const float& shape, thread const float3& p, thread const float3& r)\n{\n    bool _568 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        float3 _581 = (c - (ru * hx)) - p;\n        float3 _587 = ru * (2.0 * hx);\n        float _593 = fast::max(dot(_587, _587), 9.9999999392252902907785028219223e-09);\n        float _597 = dot(_581, _587);\n        float t = fast::clamp((-_597) / _593, 0.0, 1.0);\n        if (_568)\n        {\n            float _612 = dot(r, _587);\n            float _618 = _593 - (_612 * _612);\n            if (abs(_618) > (9.9999997473787516355514526367188e-06 * _593))\n            {\n                t = fast::clamp(((dot(r, _581) * _612) - _597) / _618, 0.0, 1.0);\n            }\n        }\n        return (p + _581) + (_587 * t);\n    }\n    float3 q = p;\n    float _650 = dot(r, axis);\n    bool _658;\n    if (_568)\n    {\n        _658 = abs(_650) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _658 = _568;\n    }\n    if (_658)\n    {\n        float _668 = dot(c - p, axis) / _650;\n        if (_668 > 0.0)\n        {\n            q = p + (r * _668);\n        }\n    }\n    float3 _681 = q - c;\n    float2 xy = float2(dot(_681, ru), dot(_681, uu));\n    if (shape > 0.5)\n    {\n        float _696 = length(xy);\n        if (_696 > hx)\n        {\n            xy *= (hx / _696);\n        }\n    }\n    else\n    {\n        xy = fast::clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_atlas_fetch(thread const float2& texel, texture2d<float> fa_light_atlas, sampler fa_env_smp)\n{\n    return fa_light_atlas.sample(fa_env_smp, (texel / float2(int2(fa_light_atlas.get_width(), fa_light_atlas.get_height()))), level(0.0));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_cookie_sample(thread const float2& tile_origin, thread const float2& uv, texture2d<float> fa_light_atlas, sampler fa_env_smp)\n{\n    float2 param = (tile_origin + float2(1.0)) + (fast::clamp(uv, float2(0.0), float2(1.0)) * 254.0);\n    return fa_atlas_fetch(param, fa_light_atlas, fa_env_smp).xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_ies_sample(thread const float2& tile_origin, thread const float3& d, thread const float3& axis, thread const float3& right, thread const float3& up, texture2d<float> fa_light_atlas, sampler fa_env_smp)\n{\n    float _488 = dot(d, right);\n    float _492 = dot(d, up);\n    float _503;\n    if (((_488 * _488) + (_492 * _492)) > 1.0000000133514319600180897396058e-10)\n    {\n        _503 = precise::atan2(_492, _488) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _503 = 0.0;\n    }\n    float2 param = tile_origin + float2(1.0 + ((_503 - floor(_503)) * 64.0), 1.0 + (acos(fast::clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param, fa_light_atlas, fa_env_smp).x;\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cube_face(thread const float3& d)\n{\n    float3 _338 = abs(d);\n    float _340 = _338.x;\n    float _342 = _338.y;\n    bool _343 = _340 >= _342;\n    bool _351;\n    if (_343)\n    {\n        _351 = _340 >= _338.z;\n    }\n    else\n    {\n        _351 = _343;\n    }\n    int _352;\n    if (_351)\n    {\n        _352 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _367;\n        if (_342 >= _338.z)\n        {\n            _367 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _367 = (d.z > 0.0) ? 4 : 5;\n        }\n        _352 = _367;\n    }\n    return _352;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cube_face_basis(thread const int& f, thread float3& fwd, thread float3& up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0, 0.0, 0.0);\n        up = float3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0, 0.0, 0.0);\n            up = float3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0, 1.0, 0.0);\n                up = float3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0, -1.0, 0.0);\n                    up = float3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0, 0.0, 1.0);\n                        up = float3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0, 0.0, -1.0);\n                        up = float3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample_n(thread const int& li, thread const float3& world_pos, thread const float3& n, constant fa_mesh_fs_params& _390, texture2d<float> fa_light_tex, sampler fa_shadow_smp, texture2d<float> fa_light_atlas, sampler fa_env_smp, thread float3& fa_light_tint, thread bool& fa_light_is_area)\n{\n    int param = li;\n    int _734 = fa_light_base(param, _390);\n    bool _738 = _390.fa_ambient.w > 4.5;\n    int param_1 = _734;\n    float4 _742 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    int param_2 = _734 + 1;\n    float4 _747 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float _750 = _747.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = float3(1.0);\n    bool _762 = _738 && (_750 > 2.5);\n    fa_light_is_area = _762;\n    bool _764 = _750 < 0.5;\n    float3 l;\n    if (_764)\n    {\n        l = fast::normalize(_742.xyz);\n        if (_738)\n        {\n            int param_3 = _734 + 6;\n            float4 _778 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            if (_778.z > 0.5)\n            {\n                int param_4 = _734 + 4;\n                float4 _788 = fa_light_texel(param_4, fa_light_tex, fa_shadow_smp);\n                int param_5 = _734 + 5;\n                float4 _793 = fa_light_texel(param_5, fa_light_tex, fa_shadow_smp);\n                float2 param_6 = _778.xy;\n                float2 param_7 = fract(float2(dot(world_pos, _788.xyz) * _788.w, (-dot(world_pos, _793.xyz)) * _793.w) + float2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7, fa_light_atlas, fa_env_smp);\n            }\n        }\n    }\n    else\n    {\n        float3 _823 = _742.xyz;\n        float3 _825 = _823 - world_pos;\n        float3 to_light = _825;\n        float _828 = length(_825);\n        float reach = _828;\n        bool front = true;\n        if (_762)\n        {\n            int param_8 = _734 + 7;\n            reach = fast::max(_828 - fa_light_texel(param_8, fa_light_tex, fa_shadow_smp).w, 0.0);\n            int param_9 = _734 + 4;\n            float4 _852 = fa_light_texel(param_9, fa_light_tex, fa_shadow_smp);\n            int param_10 = _734 + 5;\n            float4 _857 = fa_light_texel(param_10, fa_light_tex, fa_shadow_smp);\n            int param_11 = _734 + 6;\n            float4 _862 = fa_light_texel(param_11, fa_light_tex, fa_shadow_smp);\n            float _863 = _862.w;\n            int param_12 = _734 + 2;\n            float3 _870 = fast::normalize(fa_light_texel(param_12, fa_light_tex, fa_shadow_smp).xyz);\n            bool _872 = _863 > 1.5;\n            bool _880;\n            if (!_872)\n            {\n                _880 = dot(_870, to_light) < 0.0;\n            }\n            else\n            {\n                _880 = _872;\n            }\n            front = _880;\n            float3 r = float3(0.0);\n            float3 _889 = _390.fa_camera_pos.xyz - world_pos;\n            bool _893 = dot(n, n) > 0.5;\n            bool _901;\n            if (_893)\n            {\n                _901 = dot(_889, _889) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _901 = _893;\n            }\n            if (_901)\n            {\n                r = reflect(-fast::normalize(_889), fast::normalize(n));\n            }\n            float3 param_13 = _823;\n            float3 param_14 = _870;\n            float3 param_15 = _852.xyz;\n            float3 param_16 = _857.xyz;\n            float param_17 = _852.w;\n            float param_18 = _857.w;\n            float param_19 = _863;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _937 = length(to_light);\n        dist = _937;\n        l = to_light / float3(fast::max(_937, 9.9999997473787516355514526367188e-05));\n        float _951 = reach / fast::max(_742.w, 0.001000000047497451305389404296875);\n        float _957 = fast::clamp(1.0 - (_951 * _951), 0.0, 1.0);\n        float _959;\n        if (front)\n        {\n            _959 = _957 * _957;\n        }\n        else\n        {\n            _959 = 0.0;\n        }\n        atten = _959;\n        bool _970 = _750 < 2.5;\n        if ((_750 > 1.5) && _970)\n        {\n            int param_22 = _734 + 2;\n            float4 _978 = fa_light_texel(param_22, fa_light_tex, fa_shadow_smp);\n            float _988 = _978.w;\n            int param_23 = _734 + 3;\n            float4 _993 = fa_light_texel(param_23, fa_light_tex, fa_shadow_smp);\n            float _994 = _993.x;\n            float cos_inner = _994;\n            if (_994 > 1.5)\n            {\n                cos_inner = mix(_988, 1.0, 0.25);\n            }\n            atten *= smoothstep(_988, cos_inner, dot(-l, fast::normalize(_978.xyz)));\n        }\n        if (_738 && (_750 < 1.5))\n        {\n            int param_24 = _734 + 6;\n            float4 _1018 = fa_light_texel(param_24, fa_light_tex, fa_shadow_smp);\n            if (_1018.z > 0.5)\n            {\n                float3 _1026 = -to_light;\n                int param_25 = _734 + 4;\n                int param_26 = _734 + 5;\n                float3 _1040 = fa_light_texel(param_25, fa_light_tex, fa_shadow_smp).xyz;\n                float3 _1044 = fa_light_texel(param_26, fa_light_tex, fa_shadow_smp).xyz;\n                float3 _1053 = float3(dot(_1026, _1040), dot(_1026, _1044), dot(_1026, cross(_1040, _1044)));\n                float3 param_27 = _1053;\n                int _1057 = fa_cube_face(param_27);\n                int param_28 = _1057;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1084 = float2(dot(_1053, cross(param_29, param_30)), dot(_1053, param_30)) / float2(fast::max(dot(_1053, param_29), 9.9999997473787516355514526367188e-05));\n                int _1088 = _1057 / 3;\n                float2 param_31 = _1018.xy + (float2(float(_1057 - (_1088 * 3)), float(_1088)) * 256.0);\n                float2 param_32 = float2(0.5 + (0.5 * _1084.x), 0.5 - (0.5 * _1084.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32, fa_light_atlas, fa_env_smp);\n            }\n            int param_33 = _734 + 7;\n            float4 _1118 = fa_light_texel(param_33, fa_light_tex, fa_shadow_smp);\n            if (_1118.z > 0.5)\n            {\n                int param_34 = _734 + 2;\n                int param_35 = _734 + 4;\n                int param_36 = _734 + 5;\n                float2 param_37 = _1118.xy;\n                float3 param_38 = -l;\n                float3 param_39 = fast::normalize(fa_light_texel(param_34, fa_light_tex, fa_shadow_smp).xyz);\n                float3 param_40 = fa_light_texel(param_35, fa_light_tex, fa_shadow_smp).xyz;\n                float3 param_41 = fa_light_texel(param_36, fa_light_tex, fa_shadow_smp).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41, fa_light_atlas, fa_env_smp);\n            }\n        }\n        else\n        {\n            if (_738 && _970)\n            {\n                int param_42 = _734 + 6;\n                float4 _1165 = fa_light_texel(param_42, fa_light_tex, fa_shadow_smp);\n                int param_43 = _734 + 7;\n                float4 _1170 = fa_light_texel(param_43, fa_light_tex, fa_shadow_smp);\n                bool _1173 = _1165.z > 0.5;\n                bool _1180;\n                if (!_1173)\n                {\n                    _1180 = _1170.z > 0.5;\n                }\n                else\n                {\n                    _1180 = _1173;\n                }\n                if (_1180)\n                {\n                    int param_44 = _734 + 2;\n                    float4 _1187 = fa_light_texel(param_44, fa_light_tex, fa_shadow_smp);\n                    float3 _1191 = fast::normalize(_1187.xyz);\n                    int param_45 = _734 + 4;\n                    float4 _1196 = fa_light_texel(param_45, fa_light_tex, fa_shadow_smp);\n                    int param_46 = _734 + 5;\n                    float4 _1201 = fa_light_texel(param_46, fa_light_tex, fa_shadow_smp);\n                    if (_1173)\n                    {\n                        float3 _1209 = -to_light;\n                        float _1216 = _1187.w;\n                        float _1232 = 0.5 / fast::max(dot(_1209, _1191) * (sqrt(fast::max(1.0 - (_1216 * _1216), 0.0)) / fast::max(_1216, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        float2 param_47 = _1165.xy;\n                        float2 param_48 = float2(0.5 + (dot(_1209, _1196.xyz) * _1232), 0.5 - (dot(_1209, _1201.xyz) * _1232));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48, fa_light_atlas, fa_env_smp);\n                    }\n                    if (_1170.z > 0.5)\n                    {\n                        float2 param_49 = _1170.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1191;\n                        float3 param_52 = _1196.xyz;\n                        float3 param_53 = _1201.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53, fa_light_atlas, fa_env_smp);\n                    }\n                }\n            }\n        }\n    }\n    float3 _4721 = _747.xyz * atten;\n    if (_738)\n    {\n        _4721 *= fa_light_tint;\n    }\n    int _1300;\n    if (_764)\n    {\n        _1300 = 0;\n    }\n    else\n    {\n        _1300 = ((_750 > 1.5) && (_750 < 2.5)) ? 2 : 1;\n    }\n    return LightSample{ l, _4721, atten, 1.0, dist, _1300 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_fetch(thread const float2& uv, thread const float4& rect, thread const float3& conv, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2094 = fa_shadow_depth(param, param_1, fa_shadow_smp, fa_shadow_tex);\n    float _2098;\n    if (conv.x < 0.5)\n    {\n        _2098 = _2094;\n    }\n    else\n    {\n        _2098 = (conv.y * conv.z) / (conv.z - (_2094 * (conv.z - conv.y)));\n    }\n    return _2098;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _2025 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_2025), sin(_2025)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_filter(thread const float2& uv, thread const float4& rect, thread const float& zr, thread const float& texel_m, thread const float& unit, thread const float& reach, thread const float& plane, thread const float3& conv, thread const int& mode, thread const float& k, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2047, texture2d<float> fa_shadow_tex)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2, fa_shadow_smp, fa_shadow_tex));\n    }\n    float _2144 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2153;\n        if (k < 0.0)\n        {\n            _2153 = (-k) / fast::max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2153 = k;\n        }\n        float _2173 = fast::clamp((_2153 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2144;\n            float2 _2192 = fa_shadow_vogel(param_3, param_4, param_5) * _2173;\n            float2 param_6 = uv + (_2192 * _2047.fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _2204 = fa_shadow_fetch(param_6, param_7, param_8, fa_shadow_smp, fa_shadow_tex);\n            if (_2204 < (zr - (length(_2192) * plane)))\n            {\n                sum += _2204;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2230 = sum / cnt;\n        float _2240;\n        if (k < 0.0)\n        {\n            _2240 = (-k) / fast::max(_2230, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2240 = k;\n        }\n        radius = fast::clamp(((fast::max(zr - _2230, 0.0) * unit) * _2240) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _2262 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2262; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2262;\n        float param_11 = _2144;\n        float2 _2281 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_2281 * _2047.fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_2281) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14, fa_shadow_smp, fa_shadow_tex));\n    }\n    return lit / float(_2262);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_local(thread const int& li, thread const float3& lpos, thread const float3& world, thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _390, texture2d<float> fa_light_tex, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2047, texture2d<float> fa_shadow_tex)\n{\n    bool _2481 = _390.fa_pbr.z < 0.5;\n    bool _2488;\n    if (!_2481)\n    {\n        _2488 = _2047.fa_shadow_lcfg.x < 0.5;\n    }\n    else\n    {\n        _2488 = _2481;\n    }\n    if (_2488)\n    {\n        return 1.0;\n    }\n    int param = (int(_2047.fa_shadow_lcfg.x + 0.5) - 1) + li;\n    float4 _2501 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    float _2502 = _2501.x;\n    if (_2502 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2511 = int(_2502 + 0.5);\n    int param_1 = _2511;\n    float4 _2515 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    int param_2 = _2511 + 1;\n    float4 _2520 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float fade = 1.0;\n    float _2523 = _2515.y;\n    if (_2523 > 0.0)\n    {\n        float _2540 = 1.0 - smoothstep(0.75 * _2523, _2523, length(world - _2047.fa_shadow_eye.xyz));\n        fade = _2540;\n        if (_2540 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2515.x > 1.5)\n    {\n        float3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2564 = (_2511 + 2) + (face * 6);\n    int param_4 = _2564;\n    int param_5 = _2564 + 1;\n    int param_6 = _2564 + 3;\n    float4 _2578 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n    int param_7 = _2564 + 4;\n    float4 _2583 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n    int param_8 = _2564 + 5;\n    float4 _2588 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n    float _2600 = _2588.x * fast::max(dot(_2578, float4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2605 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _2628 = fast::clamp(dot(n, _2578.xyz), -1.0, 1.0);\n    float _2647 = fast::min(sqrt(1.0 - (_2628 * _2628)) / fast::max(abs(dot(n, world - lpos)) / fast::max(dot(_2578, float4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2650 = _2520.y;\n    float _2652;\n    if (_2650 > 0.0)\n    {\n        _2652 = _2650;\n    }\n    else\n    {\n        _2652 = 1.5 * _2600;\n    }\n    float4 _2672 = float4(world + (n * (_2652 * sqrt(1.0 - (_2605 * _2605)))), 1.0);\n    float _2676 = dot(_2578, _2672);\n    float _2679 = _2588.y;\n    if (_2676 < _2679)\n    {\n        return 1.0;\n    }\n    float2 _2694 = float2(dot(fa_light_texel(param_4, fa_light_tex, fa_shadow_smp), _2672), dot(fa_light_texel(param_5, fa_light_tex, fa_shadow_smp), _2672)) / float2(_2676);\n    float _2696 = _2694.x;\n    bool _2699 = _2696 < _2583.x;\n    bool _2708;\n    if (!_2699)\n    {\n        _2708 = _2696 > _2583.z;\n    }\n    else\n    {\n        _2708 = _2699;\n    }\n    bool _2717;\n    if (!_2708)\n    {\n        _2717 = _2694.y < _2583.y;\n    }\n    else\n    {\n        _2717 = _2708;\n    }\n    bool _2726;\n    if (!_2717)\n    {\n        _2726 = _2694.y > _2583.w;\n    }\n    else\n    {\n        _2726 = _2717;\n    }\n    if (_2726)\n    {\n        return 1.0;\n    }\n    float _2732 = _2520.x;\n    float _2734;\n    if (_2732 > 0.0)\n    {\n        _2734 = _2732;\n    }\n    else\n    {\n        _2734 = 1.5 * _2600;\n    }\n    float2 param_9 = _2694;\n    float4 param_10 = _2583;\n    float param_11 = _2676 - (_2734 * (1.0 + (0.5 * _2647)));\n    float param_12 = _2600;\n    float param_13 = 1.0;\n    float param_14 = _2588.z * 0.25;\n    float param_15 = (_2600 * fast::min(_2647, 3.0)) * 0.5;\n    float3 param_16 = float3(1.0, _2679, _2588.z);\n    int param_17 = int(_2515.z + 0.5);\n    float param_18 = _2515.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, fa_shadow_smp, gl_FragCoord, _2047, fa_shadow_tex), fade);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _2047)\n{\n    float _2037;\n    if (i == 0)\n    {\n        _2037 = _2047.fa_shadow_split.x;\n    }\n    else\n    {\n        float _2053;\n        if (i == 1)\n        {\n            _2053 = _2047.fa_shadow_split.y;\n        }\n        else\n        {\n            float _2061;\n            if (i == 2)\n            {\n                _2061 = _2047.fa_shadow_split.z;\n            }\n            else\n            {\n                _2061 = _2047.fa_shadow_split.w;\n            }\n            _2053 = _2061;\n        }\n        _2037 = _2053;\n    }\n    return _2037;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2047, texture2d<float> fa_shadow_tex)\n{\n    float _2323 = fast::max(_2047.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _2328 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _2334 = sqrt(1.0 - (_2328 * _2328));\n    float _2341 = fast::min(_2334 / fast::max(_2328, 0.20000000298023223876953125), 4.0);\n    float _2346;\n    if (_2047.fa_shadow_bias.y > 0.0)\n    {\n        _2346 = _2047.fa_shadow_bias.y;\n    }\n    else\n    {\n        _2346 = 1.5 * _2047.fa_shadow_info[ci].x;\n    }\n    float4 _2371 = _2047.fa_shadow_mat[ci] * float4(world + (n * (_2346 * _2334)), 1.0);\n    float _2378 = _2371.x;\n    bool _2381 = _2378 < _2047.fa_shadow_rect[ci].x;\n    bool _2390;\n    if (!_2381)\n    {\n        _2390 = _2378 > _2047.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2390 = _2381;\n    }\n    bool _2399;\n    if (!_2390)\n    {\n        _2399 = _2371.y < _2047.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2399 = _2390;\n    }\n    bool _2408;\n    if (!_2399)\n    {\n        _2408 = _2371.y > _2047.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2408 = _2399;\n    }\n    bool _2415;\n    if (!_2408)\n    {\n        _2415 = _2371.z > 1.0;\n    }\n    else\n    {\n        _2415 = _2408;\n    }\n    if (_2415)\n    {\n        return -1.0;\n    }\n    float _2423;\n    if (_2047.fa_shadow_bias.x > 0.0)\n    {\n        _2423 = _2047.fa_shadow_bias.x;\n    }\n    else\n    {\n        _2423 = 1.5 * _2047.fa_shadow_info[ci].x;\n    }\n    float2 param = _2371.xy;\n    float4 param_1 = _2047.fa_shadow_rect[ci];\n    float param_2 = _2371.z - ((_2423 * (1.0 + (0.5 * _2341))) / _2323);\n    float param_3 = _2047.fa_shadow_info[ci].x;\n    float param_4 = _2323;\n    float param_5 = _2323 * 0.25;\n    float param_6 = ((_2047.fa_shadow_info[ci].x * fast::min(_2341, 3.0)) * 0.5) / _2323;\n    float3 param_7 = float3(0.0);\n    int param_8 = int(_2047.fa_shadow_cfg.z + 0.5);\n    float param_9 = _2047.fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9, fa_shadow_smp, gl_FragCoord, _2047, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _390, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2047, texture2d<float> fa_shadow_tex)\n{\n    if (_390.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2801 = int(_2047.fa_shadow_cfg.x + 0.5);\n    if (_2801 < 1)\n    {\n        return 1.0;\n    }\n    float _2816 = dot(world - _2047.fa_shadow_eye.xyz, _2047.fa_shadow_fwd.xyz);\n    int param = _2801 - 1;\n    if (_2816 > fa_shadow_split_at(param, _2047))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2828 = _2801 > 1;\n    bool _2835;\n    if (_2828)\n    {\n        _2835 = _2816 > _2047.fa_shadow_split.x;\n    }\n    else\n    {\n        _2835 = _2828;\n    }\n    if (_2835)\n    {\n        ci = 1;\n    }\n    bool _2839 = _2801 > 2;\n    bool _2846;\n    if (_2839)\n    {\n        _2846 = _2816 > _2047.fa_shadow_split.y;\n    }\n    else\n    {\n        _2846 = _2839;\n    }\n    if (_2846)\n    {\n        ci = 2;\n    }\n    bool _2850 = _2801 > 3;\n    bool _2857;\n    if (_2850)\n    {\n        _2857 = _2816 > _2047.fa_shadow_split.z;\n    }\n    else\n    {\n        _2857 = _2850;\n    }\n    if (_2857)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2801)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2883 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_shadow_smp, gl_FragCoord, _2047, fa_shadow_tex);\n        s = _2883;\n        if (_2883 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_2047.fa_shadow_cfg.y > 0.0)\n    {\n        float _2908;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2908 = fa_shadow_split_at(param_5, _2047);\n        }\n        else\n        {\n            _2908 = _2047.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _2927 = _2047.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _2047) - _2908, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2938 = fast::clamp((_2816 - (fa_shadow_split_at(param_7, _2047) - _2927)) / _2927, 0.0, 1.0);\n        if (_2938 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2801)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _2959 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_shadow_smp, gl_FragCoord, _2047, fa_shadow_tex);\n                s2 = _2959;\n                if (_2959 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2938);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _390, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2047, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, _390, fa_shadow_smp, gl_FragCoord, _2047, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_contact_shadow(thread const int& li, thread const float3& world, thread const float3& gn, thread const float3& l, thread const float& dist, constant fa_mesh_fs_params& _390, texture2d<float> fa_light_tex, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2047, texture2d<float> fa_screen_tex)\n{\n    bool _3240 = _390.fa_ct_a.x < 0.5;\n    bool _3247;\n    if (!_3240)\n    {\n        _3247 = _2047.fa_shadow_lcfg.x < 0.5;\n    }\n    else\n    {\n        _3247 = _3240;\n    }\n    if (_3247)\n    {\n        return 1.0;\n    }\n    int param = (int(_2047.fa_shadow_lcfg.x + 0.5) - 1) + li;\n    float4 _3260 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    float _3261 = _3260.y;\n    float len = _3261;\n    if (_3261 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3273 = length(world - _390.fa_camera_pos.xyz);\n    float _3283 = 1.0 - smoothstep(0.5 * _390.fa_ct_b.x, _390.fa_ct_b.x, _3273);\n    if (_3283 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3289 = len;\n    float _3292 = fast::min(_3289, 0.89999997615814208984375 * dist);\n    len = _3292;\n    float _3298 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _3273);\n    float _3303 = _3298 + (0.5 * _3292);\n    float3 _3309 = world + (gn * _3298);\n    float _3311 = fa_shadow_noise(gl_FragCoord);\n    float occ = 0.0;\n    float _3376;\n    for (int k = 0; k < 12; k++)\n    {\n        float _3327 = (float(k) + _3311) * 0.083333335816860198974609375;\n        float3 _3335 = _3309 + (l * (_3327 * len));\n        float4 _3341 = float4(_3335, 1.0);\n        float _3347 = dot(_390.fa_ct_vpw, _3341);\n        if (_3347 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        float2 _3367 = float2(dot(_390.fa_ct_vpx, _3341), dot(_390.fa_ct_vpy, _3341)) / float2(_3347);\n        float _3371 = _3367.x * 0.5;\n        float _3372 = _3371 + 0.5;\n        if (_390.fa_ct_a.y > 0.5)\n        {\n            _3376 = (_3367.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _3376 = 0.5 - (_3367.y * 0.5);\n        }\n        bool _3392 = _3372 < 0.0;\n        bool _3399;\n        if (!_3392)\n        {\n            _3399 = _3372 >= 1.0;\n        }\n        else\n        {\n            _3399 = _3392;\n        }\n        bool _3406;\n        if (!_3399)\n        {\n            _3406 = _3376 < 0.0;\n        }\n        else\n        {\n            _3406 = _3399;\n        }\n        bool _3413;\n        if (!_3406)\n        {\n            _3413 = _3376 >= 1.0;\n        }\n        else\n        {\n            _3413 = _3406;\n        }\n        if (_3413)\n        {\n            break;\n        }\n        float4 _3432 = fa_screen_tex.read(uint2(int2(float2(_3372, _3376) * _390.fa_ct_a.zw)), 0);\n        if (_3432.w < 0.5)\n        {\n            continue;\n        }\n        float _3451 = (dot(_390.fa_ct_fwd.xyz, _3335) + _390.fa_ct_fwd.w) - _3432.x;\n        if ((_3451 > _3298) && (_3451 < _3303))\n        {\n            occ = fast::max(occ, (1.0 - (_3327 * _3327)) * smoothstep(0.0, 0.0500000007450580596923828125, fast::min(fast::min(_3372, 0.5 - _3371), fast::min(_3376, 1.0 - _3376))));\n        }\n    }\n    return 1.0 - (occ * _3283);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, constant fa_mesh_fs_params& _390, texture2d<float> fa_light_tex, sampler fa_shadow_smp, texture2d<float> fa_light_atlas, sampler fa_env_smp, thread float3& fa_light_tint, thread bool& fa_light_is_area, thread float4& gl_FragCoord, constant fa_shadows& _2047, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos, texture2d<float> fa_screen_tex, thread float3& fa_lm)\n{\n    int param = li;\n    float _3554 = fa_baked_keep(param, _390, fa_light_tex, fa_shadow_smp, fa_lm);\n    if (_3554 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample{ float3(0.0, 1.0, 0.0), float3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1, _390, fa_light_tex, fa_shadow_smp) + 0.5) };\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _3580 = fa_light_sample_n(param_2, param_3, param_4, _390, fa_light_tex, fa_shadow_smp, fa_light_atlas, fa_env_smp, fa_light_tint, fa_light_is_area);\n    float3 _4747 = _3580.color;\n    float _4748 = _3580.attenuation;\n    float _4749 = _3580.shadow;\n    bool _3583 = _3580.type == 0;\n    if (_3583 && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _3580.direction;\n        float _3594 = fa_shadow_factor(param_5, param_6, _390, fa_shadow_smp, gl_FragCoord, _2047, fa_shadow_tex, fa_world_pos);\n        _4749 = _3594;\n        _4747 *= _3594;\n    }\n    else\n    {\n        bool _3605 = _3580.type != 0;\n        bool _3611;\n        if (_3605)\n        {\n            _3611 = _4748 > 0.0;\n        }\n        else\n        {\n            _3611 = _3605;\n        }\n        if (_3611)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7, _390);\n            int param_9 = li;\n            float3 param_10 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp).xyz;\n            float3 param_11 = world_pos;\n            float3 param_12 = gn;\n            float3 param_13 = _3580.direction;\n            float _3630 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13, _390, fa_light_tex, fa_shadow_smp, gl_FragCoord, _2047, fa_shadow_tex);\n            _4749 = _3630;\n            _4747 *= _3630;\n        }\n    }\n    bool _3640 = _390.fa_ct_a.x > 0.5;\n    bool _3646;\n    if (_3640)\n    {\n        _3646 = _4748 > 0.0;\n    }\n    else\n    {\n        _3646 = _3640;\n    }\n    if (_3646)\n    {\n        float _3653;\n        if (_3583)\n        {\n            _3653 = 1000000000.0;\n        }\n        else\n        {\n            _3653 = _3580._distance;\n        }\n        int param_14 = li;\n        float3 param_15 = world_pos;\n        float3 param_16 = gn;\n        float3 param_17 = _3580.direction;\n        float param_18 = _3653;\n        float _3671 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18, _390, fa_light_tex, fa_shadow_smp, gl_FragCoord, _2047, fa_screen_tex);\n        _4749 *= _3671;\n        _4747 *= _3671;\n    }\n    float _3684 = _4748;\n    float _3685 = _3684 * _3554;\n    _4748 = _3685;\n    float3 _3689 = _4747;\n    float3 _3690 = _3689 * _3554;\n    _4747 = _3690;\n    return LightSample{ _3580.direction, _3690, _3685, _4749, _3580._distance, _3580.type };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 light(thread const SurfaceInput& i, thread const Surface& s, thread const LightSample& l, constant fa_material& _3710)\n{\n    float _3704;\n    if (dot(s.normal, l.direction) > 0.5)\n    {\n        _3704 = 1.0;\n    }\n    else\n    {\n        _3704 = _3710.dark;\n    }\n    return (s.albedo * l.color) * _3704;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _2047)\n{\n    if (_2047.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _2983 = int(_2047.fa_shadow_cfg.x + 0.5);\n    float _2993 = dot(world - _2047.fa_shadow_eye.xyz, _2047.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _2998 = _2983 > 0;\n    bool _3007;\n    if (_2998)\n    {\n        int param = _2983 - 1;\n        _3007 = _2993 <= fa_shadow_split_at(param, _2047);\n    }\n    else\n    {\n        _3007 = _2998;\n    }\n    if (_3007)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3013 = _2983 > 1;\n        bool _3020;\n        if (_3013)\n        {\n            _3020 = _2993 > _2047.fa_shadow_split.x;\n        }\n        else\n        {\n            _3020 = _3013;\n        }\n        if (_3020)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3026 = _2983 > 2;\n        bool _3033;\n        if (_3026)\n        {\n            _3033 = _2993 > _2047.fa_shadow_split.y;\n        }\n        else\n        {\n            _3033 = _3026;\n        }\n        if (_3033)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3039 = _2983 > 3;\n        bool _3046;\n        if (_3039)\n        {\n            _3046 = _2993 > _2047.fa_shadow_split.z;\n        }\n        else\n        {\n            _3046 = _3039;\n        }\n        if (_3046)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _390 [[buffer(1)]], constant fa_material& _3710 [[buffer(5)]], constant fa_shadows& _2047 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_env_tex [[texture(6)]], texture2d<float> fa_light_tex [[texture(7)]], texture2d<float> fa_light_atlas [[texture(8)]], texture2d<float> fa_lightmap [[texture(9)]], texture2d<float> fa_decal_tex [[texture(10)]], texture2d<float> fa_screen_tex [[texture(11)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _4568 = fast::normalize(in.fa_world_normal);\n    float3 fa_light_tint;\n    bool fa_light_is_area;\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _4568 = -_4568;\n    }\n    float3 _4143 = fast::normalize(_390.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, _390, fa_light_tex, fa_shadow_smp, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _4568, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _4143, short(gl_FrontFacing) };\n    Surface _4151 = fa_standard_surface(param_1, _390, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _4599 = _4151.albedo;\n    float _4600 = _4151.alpha;\n    float3 _4601 = _4151.normal;\n    float _4602 = _4151.metallic;\n    float _4603 = _4151.roughness;\n    float _4604 = _4151.occlusion;\n    float3 _4605 = _4151.emission;\n    float _4606 = _4151.clearcoat;\n    float _4607 = _4151.clearcoat_roughness;\n    float3 _4608 = _4151.sheen_color;\n    float _4609 = _4151.sheen_roughness;\n    float _4610 = _4151.anisotropy;\n    float _4611 = _4151.anisotropy_rotation;\n    float _4612 = _4151.specular;\n    float _4613 = _4151.ior;\n    float3 _4614 = _4151.specular_color;\n    float _4615 = _4151.transmission;\n    float _4616 = _4151.thickness;\n    float3 _4617 = _4151.attenuation_color;\n    float _4618 = _4151.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _4568, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _4143, short(gl_FrontFacing) };\n    Surface param_3 = _4151;\n    surface(param_2, param_3);\n    _4599 = param_3.albedo;\n    _4600 = param_3.alpha;\n    _4601 = param_3.normal;\n    _4602 = param_3.metallic;\n    _4603 = param_3.roughness;\n    _4604 = param_3.occlusion;\n    _4605 = param_3.emission;\n    _4606 = param_3.clearcoat;\n    _4607 = param_3.clearcoat_roughness;\n    _4608 = param_3.sheen_color;\n    _4609 = param_3.sheen_roughness;\n    _4610 = param_3.anisotropy;\n    _4611 = param_3.anisotropy_rotation;\n    _4612 = param_3.specular;\n    _4613 = param_3.ior;\n    _4614 = param_3.specular_color;\n    _4615 = param_3.transmission;\n    _4616 = param_3.thickness;\n    _4617 = param_3.attenuation_color;\n    _4618 = param_3.attenuation_distance;\n    float3 param_4 = in.fa_world_pos;\n    float3 param_5 = _4568;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7, _390, fa_light_tex, fa_shadow_smp, fa_env_smp, fa_decal_tex);\n    _4599 = param_6;\n    _4601 = param_7;\n    float3 result;\n    if (_390.fa_emissive.w > 0.5)\n    {\n        result = _4599;\n    }\n    else\n    {\n        float3 _4190 = _4601;\n        float3 _4191 = fast::normalize(_4190);\n        _4601 = _4191;\n        float3 param_8 = _4191;\n        float3 lit = (fa_indirect_diffuse(param_8, _390, fa_env_smp, fa_env_tex, in.fa_lm, fa_lightmap) * _4599) * _4604;\n        int _4210 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _4210; ln++)\n        {\n            int param_9 = ln;\n            int _4223 = fa_cl_light(param_9, _390, fa_light_tex, fa_shadow_smp, fa_cl_ndir, fa_cl_slot);\n            int param_10 = _4223;\n            if (fa_baked_keep(param_10, _390, fa_light_tex, fa_shadow_smp, in.fa_lm) <= 0.0)\n            {\n                continue;\n            }\n            int param_11 = _4223;\n            float3 param_12 = in.fa_world_pos;\n            float3 param_13 = _4568;\n            LightSample _4239 = fa_light_shadowed(param_11, param_12, param_13, _390, fa_light_tex, fa_shadow_smp, fa_light_atlas, fa_env_smp, fa_light_tint, fa_light_is_area, gl_FragCoord, _2047, fa_shadow_tex, in.fa_world_pos, fa_screen_tex, in.fa_lm);\n            SurfaceInput param_14 = SurfaceInput{ in.fa_world_pos, _4568, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _4143, short(gl_FrontFacing) };\n            Surface param_15 = Surface{ _4599, _4600, _4601, _4602, _4603, _4604, _4605, _4606, _4607, _4608, _4609, _4610, _4611, _4612, _4613, _4614, _4615, _4616, _4617, _4618 };\n            LightSample param_16 = _4239;\n            lit += light(param_14, param_15, param_16, _3710);\n        }\n        result = lit;\n    }\n    float3 _4254 = result;\n    float3 _4255 = _4254 + _4605;\n    result = _4255;\n    float3 param_17 = _4255;\n    float3 param_18 = in.fa_world_pos;\n    result = fa_shadow_debug(param_17, param_18, _2047);\n    bool _4264 = _390.fa_fog.w > 0.0;\n    bool _4271;\n    if (!_4264)\n    {\n        _4271 = _390.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _4271 = _4264;\n    }\n    if (_4271)\n    {\n        float3 _4280 = in.fa_world_pos - _390.fa_camera_pos.xyz;\n        float _4286 = dot(_4280, _390.fa_fog_c.xyz);\n        bool _4290 = _390.fa_fog_c.w > 0.5;\n        float _4291;\n        if (_4290)\n        {\n            _4291 = _4286;\n        }\n        else\n        {\n            _4291 = length(_4280);\n        }\n        float _4303 = _4291 - _390.fa_fog_b.x;\n        if (_4303 > 0.0)\n        {\n            float _4312 = _390.fa_fog.w * _4303;\n            float tau = _4312 * _4312;\n            if (_390.fa_fog_b.y > 0.0)\n            {\n                float _4328;\n                if (_4290)\n                {\n                    _4328 = in.fa_world_pos.y - (_390.fa_fog_c.y * _4286);\n                }\n                else\n                {\n                    _4328 = _390.fa_camera_pos.y;\n                }\n                float _4349 = mix(_4328, in.fa_world_pos.y, fast::clamp(_390.fa_fog_b.x / _4291, 0.0, 1.0));\n                float _4353 = in.fa_world_pos.y - _4349;\n                float _4358 = _4349 - _390.fa_fog_b.z;\n                float _4363 = in.fa_world_pos.y - _390.fa_fog_b.z;\n                bool _4366 = _4358 <= 0.0;\n                bool _4367 = !_4366;\n                bool _4373;\n                if (_4367)\n                {\n                    _4373 = _390.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4373 = _4366;\n                }\n                float _4374;\n                if (_4373)\n                {\n                    _4374 = _390.fa_fog_b.y;\n                }\n                else\n                {\n                    _4374 = _390.fa_fog_b.y * exp(-fast::min(_390.fa_fog_b.w * _4358, 80.0));\n                }\n                bool _4401;\n                if (_4367)\n                {\n                    _4401 = _390.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4401 = _4366;\n                }\n                float _4402;\n                if (_4401)\n                {\n                    _4402 = _390.fa_fog_b.y * _4358;\n                }\n                else\n                {\n                    _4402 = (_390.fa_fog_b.y * (1.0 - exp(-fast::min(_390.fa_fog_b.w * _4358, 80.0)))) / _390.fa_fog_b.w;\n                }\n                bool _4427 = _4363 <= 0.0;\n                bool _4434;\n                if (!_4427)\n                {\n                    _4434 = _390.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4434 = _4427;\n                }\n                float _4435;\n                if (_4434)\n                {\n                    _4435 = _390.fa_fog_b.y * _4363;\n                }\n                else\n                {\n                    _4435 = (_390.fa_fog_b.y * (1.0 - exp(-fast::min(_390.fa_fog_b.w * _4363, 80.0)))) / _390.fa_fog_b.w;\n                }\n                float _4462;\n                if (abs(_4353) < 0.001000000047497451305389404296875)\n                {\n                    _4462 = _4374;\n                }\n                else\n                {\n                    _4462 = (_4435 - _4402) / _4353;\n                }\n                tau += (_4303 * fast::max(_4462, 0.0));\n            }\n            result = mix(result, _390.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _4600);\n    return out;\n}\n\n",
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
            "size": 656,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_390",
            "msl_buffer_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2047",
            "msl_buffer_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_3710",
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
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n    float4 fa_ct_a;\n    float4 fa_ct_b;\n    float4 fa_ct_vpx;\n    float4 fa_ct_vpy;\n    float4 fa_ct_vpw;\n    float4 fa_ct_fwd;\n    float4 fa_tr_a;\n    float4 fa_tr_b;\n    float4 fa_probe_sh[9];\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _56;\n    if (bool(i.front_facing))\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = fast::normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = fast::normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (bool(i.front_facing))\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _215, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _215.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _227 = fa_tex_fix(param_2, param_3);\n    float4 _833 = base_t;\n    _833.x = _227.x;\n    _833.y = _227.y;\n    _833.z = _227.z;\n    base_t = _833;\n    float4 _243 = (_833 * _215.fa_base_color) * i.vertex_color;\n    float3 _788 = i.world_normal;\n    if (_215.fa_maps.z > 0.5)\n    {\n        float param_4 = _215.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _277 = fa_tex_fix(param_6, param_7);\n        float3 _281 = (_277 * 2.0) - float3(1.0);\n        float2 _286 = _281.xy * _215.fa_maps.x;\n        float3 _841 = _281;\n        _841.x = _286.x;\n        _841.y = _286.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _841;\n        _788 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _215.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _315 = fa_tex_fix(param_12, param_13);\n    float4 _844 = mrt;\n    _844.x = _315.x;\n    _844.y = _315.y;\n    _844.z = _315.z;\n    mrt = _844;\n    float4 _345 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _215.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _345.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _357 = fa_tex_fix(param_16, param_17);\n    float param_18 = _215.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _387 = fa_tex_fix(param_20, param_21);\n    float _793 = _215.fa_layers_a.x;\n    float _794 = _215.fa_layers_a.y;\n    float _797 = _215.fa_layers_a.z;\n    float _796 = _215.fa_layers_b.w;\n    float _799 = _215.fa_layers_c.x;\n    if (_215.fa_layers_c.z > 0.5)\n    {\n        if (mod(_215.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _793 *= _357.y;\n            _794 *= _357.z;\n            _796 *= _345.w;\n        }\n        if (_215.fa_layers_c.z > 1.5)\n        {\n            _797 *= mrt.x;\n            _799 *= mrt.w;\n        }\n    }\n    return Surface{ _243.xyz, _243.w, _788, fast::clamp(_215.fa_pbr.x * _315.z, 0.0, 1.0), fast::clamp(_215.fa_pbr.y * _315.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_215.fa_maps.y * (_357.x - 1.0)), _215.fa_emissive.xyz + (_215.fa_model_emissive.xyz * _387), _793, _794, _215.fa_layers_b.xyz, _796, _797, _215.fa_layers_a.w, _799, _215.fa_layers_c.y, _215.fa_layers_d.xyz, _215.fa_tr_a.x, _215.fa_tr_a.y, _215.fa_tr_b.xyz, _215.fa_tr_a.z };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _215 [[buffer(1)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], sampler fa_smp [[sampler(0)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _683 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _683 = -_683;\n    }\n    float3 _540 = fast::normalize(_215.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _683, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _540, short(gl_FrontFacing) };\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _683, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _540, short(gl_FrontFacing) };\n    Surface param_2 = fa_standard_surface(param, fa_tex, fa_smp, _215, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    surface(param_1, param_2);\n    float3 _555 = fast::normalize(param_2.normal);\n    float3 _570 = fast::normalize(float3(dot(in.fa_pre_r0, _555), dot(in.fa_pre_r1, _555), dot(in.fa_pre_r2, _555)));\n    float _582 = _570.z;\n    float2 e = _570.xy / float2((abs(_570.x) + abs(_570.y)) + abs(_582));\n    if (_582 < 0.0)\n    {\n        e = (float2(1.0) - abs(e.yx)) * float2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    out.fa_frag_color = float4(fast::min(in.fa_pre_depth, 60000.0), e, 1.0);\n    return out;\n}\n\n",
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
            "size": 656,
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\nstruct fa_mesh_vs_params\n{\n    float4x4 fa_view_proj;\n    float4x4 fa_light_vp;\n    float4 fa_uv_scale;\n    float4 fa_time;\n    float4 fa_lm_so;\n};\n\nstruct fa_skin\n{\n    float4 fa_joint_rows[192];\n};\n\nstruct main0_out\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 fa_position [[attribute(0)]];\n    float3 fa_normal [[attribute(1)]];\n    float2 fa_texcoord0 [[attribute(2)]];\n    float4 fa_tangent [[attribute(3)]];\n    float4 fa_color [[attribute(4)]];\n    float4 fa_inst_m0 [[attribute(5)]];\n    float4 fa_inst_m1 [[attribute(6)]];\n    float4 fa_inst_m2 [[attribute(7)]];\n    float4 fa_inst_m3 [[attribute(8)]];\n    float4 fa_joints [[attribute(9)]];\n    float4 fa_weights [[attribute(10)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_begin()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4x4 fa_skin_matrix(thread const float4& joints, thread const float4& weights, constant fa_skin& _183)\n{\n    float4 r0 = float4(0.0);\n    float4 r1 = float4(0.0);\n    float4 r2 = float4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (_183.fa_joint_rows[_174] * weights[i]);\n        r1 += (_183.fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183.fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0), float4(r0.y, r1.y, r2.y, 0.0), float4(r0.z, r1.z, r2.z, 0.0), float4(r0.w, r1.w, r2.w, 1.0));\n}\n\nstatic inline __attribute__((always_inline))\nVertexData fa_vertex_data(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData{ (model * float4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136.fa_uv_scale.xy, color, position };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_prepass_vertex(thread const float4x4& model, thread const float3& position, thread const float3& normal, thread const float4& tangent, thread const float2& texcoord0, thread const float4& color, constant fa_mesh_vs_params& _136, thread float3& fa_world_pos, thread float3& fa_world_normal, thread float4& fa_world_tangent, thread float2& fa_uv, thread float4& fa_vertex_color, thread float& fa_pre_depth, thread float3& fa_pre_r0, thread float3& fa_pre_r1, thread float3& fa_pre_r2, thread float4& gl_Position)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5, _136);\n    float3 _423 = _273.world_pos;\n    float4 _284 = float4(_423, 1.0);\n    fa_world_pos = _423;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    fa_pre_depth = -(_136.fa_light_vp * _284).z;\n    fa_pre_r0 = float3(_136.fa_light_vp[0].x, _136.fa_light_vp[1].x, _136.fa_light_vp[2].x);\n    fa_pre_r1 = float3(_136.fa_light_vp[0].y, _136.fa_light_vp[1].y, _136.fa_light_vp[2].y);\n    fa_pre_r2 = float3(_136.fa_light_vp[0].z, _136.fa_light_vp[1].z, _136.fa_light_vp[2].z);\n    gl_Position = _136.fa_view_proj * _284;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant fa_mesh_vs_params& _136 [[buffer(0)]], constant fa_skin& _183 [[buffer(3)]])\n{\n    main0_out out = {};\n    fa_inst_begin();\n    float4 param = in.fa_joints;\n    float4 param_1 = in.fa_weights;\n    float4x4 param_2 = float4x4(in.fa_inst_m0, in.fa_inst_m1, in.fa_inst_m2, in.fa_inst_m3) * fa_skin_matrix(param, param_1, _183);\n    float3 param_3 = in.fa_position;\n    float3 param_4 = in.fa_normal;\n    float4 param_5 = in.fa_tangent;\n    float2 param_6 = in.fa_texcoord0;\n    float4 param_7 = in.fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7, _136, out.fa_world_pos, out.fa_world_normal, out.fa_world_tangent, out.fa_uv, out.fa_vertex_color, out.fa_pre_depth, out.fa_pre_r0, out.fa_pre_r1, out.fa_pre_r2, out.gl_Position);\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n    float4 fa_ct_a;\n    float4 fa_ct_b;\n    float4 fa_ct_vpx;\n    float4 fa_ct_vpy;\n    float4 fa_ct_vpw;\n    float4 fa_ct_fwd;\n    float4 fa_tr_a;\n    float4 fa_tr_b;\n    float4 fa_probe_sh[9];\n};\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float fa_pre_depth [[user(locn5)]];\n    float3 fa_pre_r0 [[user(locn6)]];\n    float3 fa_pre_r1 [[user(locn7)]];\n    float3 fa_pre_r2 [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _56;\n    if (bool(i.front_facing))\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = fast::normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = fast::normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (bool(i.front_facing))\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, texture2d<float> fa_tex, sampler fa_smp, constant fa_mesh_fs_params& _215, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _215.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _227 = fa_tex_fix(param_2, param_3);\n    float4 _833 = base_t;\n    _833.x = _227.x;\n    _833.y = _227.y;\n    _833.z = _227.z;\n    base_t = _833;\n    float4 _243 = (_833 * _215.fa_base_color) * i.vertex_color;\n    float3 _788 = i.world_normal;\n    if (_215.fa_maps.z > 0.5)\n    {\n        float param_4 = _215.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _277 = fa_tex_fix(param_6, param_7);\n        float3 _281 = (_277 * 2.0) - float3(1.0);\n        float2 _286 = _281.xy * _215.fa_maps.x;\n        float3 _841 = _281;\n        _841.x = _286.x;\n        _841.y = _286.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _841;\n        _788 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _215.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _315 = fa_tex_fix(param_12, param_13);\n    float4 _844 = mrt;\n    _844.x = _315.x;\n    _844.y = _315.y;\n    _844.z = _315.z;\n    mrt = _844;\n    float4 _345 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _215.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _345.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _357 = fa_tex_fix(param_16, param_17);\n    float param_18 = _215.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _387 = fa_tex_fix(param_20, param_21);\n    float _793 = _215.fa_layers_a.x;\n    float _794 = _215.fa_layers_a.y;\n    float _797 = _215.fa_layers_a.z;\n    float _796 = _215.fa_layers_b.w;\n    float _799 = _215.fa_layers_c.x;\n    if (_215.fa_layers_c.z > 0.5)\n    {\n        if (mod(_215.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _793 *= _357.y;\n            _794 *= _357.z;\n            _796 *= _345.w;\n        }\n        if (_215.fa_layers_c.z > 1.5)\n        {\n            _797 *= mrt.x;\n            _799 *= mrt.w;\n        }\n    }\n    return Surface{ _243.xyz, _243.w, _788, fast::clamp(_215.fa_pbr.x * _315.z, 0.0, 1.0), fast::clamp(_215.fa_pbr.y * _315.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_215.fa_maps.y * (_357.x - 1.0)), _215.fa_emissive.xyz + (_215.fa_model_emissive.xyz * _387), _793, _794, _215.fa_layers_b.xyz, _796, _797, _215.fa_layers_a.w, _799, _215.fa_layers_c.y, _215.fa_layers_d.xyz, _215.fa_tr_a.x, _215.fa_tr_a.y, _215.fa_tr_b.xyz, _215.fa_tr_a.z };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _215 [[buffer(1)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_normal_tex [[texture(1)]], texture2d<float> fa_mr_tex [[texture(2)]], texture2d<float> fa_occlusion_tex [[texture(3)]], texture2d<float> fa_emissive_tex [[texture(4)]], sampler fa_smp [[sampler(0)]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _683 = fast::normalize(in.fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _683 = -_683;\n    }\n    float3 _540 = fast::normalize(_215.fa_camera_pos.xyz - in.fa_world_pos);\n    SurfaceInput param = SurfaceInput{ in.fa_world_pos, _683, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _540, short(gl_FrontFacing) };\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _683, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _540, short(gl_FrontFacing) };\n    Surface param_2 = fa_standard_surface(param, fa_tex, fa_smp, _215, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    surface(param_1, param_2);\n    float3 _555 = fast::normalize(param_2.normal);\n    float3 _570 = fast::normalize(float3(dot(in.fa_pre_r0, _555), dot(in.fa_pre_r1, _555), dot(in.fa_pre_r2, _555)));\n    float _582 = _570.z;\n    float2 e = _570.xy / float2((abs(_570.x) + abs(_570.y)) + abs(_582));\n    if (_582 < 0.0)\n    {\n        e = (float2(1.0) - abs(e.yx)) * float2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    out.fa_frag_color = float4(fast::min(in.fa_pre_depth, 60000.0), e, 1.0);\n    return out;\n}\n\n",
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
            "size": 656,
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
