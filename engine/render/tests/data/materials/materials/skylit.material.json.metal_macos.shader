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
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n#pragma clang diagnostic ignored \"-Wmissing-braces\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\ntemplate<typename T, size_t Num>\nstruct spvUnsafeArray\n{\n    T elements[Num ? Num : 1];\n    \n    thread T& operator [] (size_t pos) thread\n    {\n        return elements[pos];\n    }\n    constexpr const thread T& operator [] (size_t pos) const thread\n    {\n        return elements[pos];\n    }\n    \n    device T& operator [] (size_t pos) device\n    {\n        return elements[pos];\n    }\n    constexpr const device T& operator [] (size_t pos) const device\n    {\n        return elements[pos];\n    }\n    \n    constexpr const constant T& operator [] (size_t pos) const constant\n    {\n        return elements[pos];\n    }\n    \n    threadgroup T& operator [] (size_t pos) threadgroup\n    {\n        return elements[pos];\n    }\n    constexpr const threadgroup T& operator [] (size_t pos) const threadgroup\n    {\n        return elements[pos];\n    }\n};\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    short on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    short sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n    float4 fa_shadow_lcfg;\n};\n\nconstant spvUnsafeArray<float, 63> _3356 = spvUnsafeArray<float, 63>({ 1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875 });\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float3 fa_lm [[user(locn5)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_cluster_texel(thread const float3& world_pos, constant fa_mesh_fs_params& _365, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    bool _1333 = _365.fa_cl_info.x < 0.0;\n    bool _1340;\n    if (!_1333)\n    {\n        _1340 = _365.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _1340 = _1333;\n    }\n    bool _1348;\n    if (!_1340)\n    {\n        _1348 = _365.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _1348 = _1340;\n    }\n    bool _1355;\n    if (!_1348)\n    {\n        _1355 = _365.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _1355 = _1348;\n    }\n    bool _1362;\n    if (!_1355)\n    {\n        _1362 = _365.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _1362 = _1355;\n    }\n    if (_1362)\n    {\n        return float4(0.0);\n    }\n    float4 _1372 = float4(world_pos, 1.0);\n    float _1378 = dot(_365.fa_cl_vpw, _1372);\n    if (!(_1378 > 9.9999999747524270787835121154785e-07))\n    {\n        return float4(0.0);\n    }\n    float2 _1400 = float2(dot(_365.fa_cl_vpx, _1372), dot(_365.fa_cl_vpy, _1372)) / float2(_1378);\n    int _1404 = int(_365.fa_cl_grid.x);\n    int _1408 = int(_365.fa_cl_grid.y);\n    int param = (int(_365.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_365.fa_cl_fwd.xyz, world_pos) + _365.fa_cl_fwd.w, _365.fa_cl_grid.w) / _365.fa_cl_grid.w) * _365.fa_cl_grid.z)), 0, int(_365.fa_cl_info.y) - 1) * _1408) + clamp(int(floor(((_1400.y * 0.5) + 0.5) * _365.fa_cl_grid.y)), 0, _1408 - 1)) * _1404)) + clamp(int(floor(((_1400.x * 0.5) + 0.5) * _365.fa_cl_grid.x)), 0, _1404 - 1);\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, constant fa_mesh_fs_params& _365, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    float3 param = world_pos;\n    float4 _1484 = fa_cluster_texel(param, _365, fa_light_tex, fa_shadow_smp);\n    return int2(int(_1484.x), int(_1484.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, constant fa_mesh_fs_params& _365, texture2d<float> fa_light_tex, sampler fa_shadow_smp, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_365.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _3888 = fa_cluster_lookup(param, _365, fa_light_tex, fa_shadow_smp);\n    fa_cl_slot = _3888.x;\n    fa_cl_local = _3888.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _4044 = fa_linear_to_srgb(param);\n        c = _4044;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _4052 = fa_srgb_to_linear(param_1);\n            c = _4052;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _297;\n    if (bool(i.front_facing))\n    {\n        _297 = i.world_normal;\n    }\n    else\n    {\n        _297 = -i.world_normal;\n    }\n    float3 _321 = fast::normalize(i.world_tangent.xyz - (_297 * dot(_297, i.world_tangent.xyz)));\n    float3 _349 = fast::normalize(((_321 * m.x) + ((cross(_297, _321) * i.world_tangent.w) * m.y)) + (_297 * m.z));\n    float3 _352;\n    if (bool(i.front_facing))\n    {\n        _352 = _349;\n    }\n    else\n    {\n        _352 = -_349;\n    }\n    return _352;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _365, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _365.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _4083 = fa_tex_fix(param_2, param_3);\n    float4 _5198 = base_t;\n    _5198.x = _4083.x;\n    _5198.y = _4083.y;\n    _5198.z = _4083.z;\n    base_t = _5198;\n    float4 _4097 = (_5198 * _365.fa_base_color) * i.vertex_color;\n    float3 _5050 = i.world_normal;\n    if (_365.fa_maps.z > 0.5)\n    {\n        float param_4 = _365.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _4129 = fa_tex_fix(param_6, param_7);\n        float3 _4132 = (_4129 * 2.0) - float3(1.0);\n        float2 _4137 = _4132.xy * _365.fa_maps.x;\n        float3 _5206 = _4132;\n        _5206.x = _4137.x;\n        _5206.y = _4137.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _5206;\n        _5050 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _365.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _4165 = fa_tex_fix(param_12, param_13);\n    float4 _5209 = mrt;\n    _5209.x = _4165.x;\n    _5209.y = _4165.y;\n    _5209.z = _4165.z;\n    mrt = _5209;\n    float4 _4193 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _365.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _4193.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _4204 = fa_tex_fix(param_16, param_17);\n    float param_18 = _365.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _4234 = fa_tex_fix(param_20, param_21);\n    float _5055 = _365.fa_layers_a.x;\n    float _5056 = _365.fa_layers_a.y;\n    float _5059 = _365.fa_layers_a.z;\n    float _5058 = _365.fa_layers_b.w;\n    float _5061 = _365.fa_layers_c.x;\n    if (_365.fa_layers_c.z > 0.5)\n    {\n        if (mod(_365.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _5055 *= _4204.y;\n            _5056 *= _4204.z;\n            _5058 *= _4193.w;\n        }\n        if (_365.fa_layers_c.z > 1.5)\n        {\n            _5059 *= mrt.x;\n            _5061 *= mrt.w;\n        }\n    }\n    return Surface{ _4097.xyz, _4097.w, _5050, fast::clamp(_365.fa_pbr.x * _4165.z, 0.0, 1.0), fast::clamp(_365.fa_pbr.y * _4165.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_365.fa_maps.y * (_4204.x - 1.0)), _365.fa_emissive.xyz + (_365.fa_model_emissive.xyz * _4234), _5055, _5056, _365.fa_layers_b.xyz, _5058, _5059, _365.fa_layers_a.w, _5061, _365.fa_layers_c.y, _365.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_decal_tile(thread const float4& rect, thread const float2& uv, thread const float2& atlas, thread const float2& ddx, thread const float2& ddy, sampler fa_env_smp, texture2d<float> fa_decal_tex)\n{\n    float2 _1564 = rect.zw - rect.xy;\n    float2 _1568 = _1564 * atlas;\n    float2 _1572 = ddx * _1568;\n    float2 _1576 = ddy * _1568;\n    return fa_decal_tex.sample(fa_env_smp, (rect.xy + (fast::clamp(uv, float2(0.0), float2(1.0)) * _1564)), level(fast::clamp(0.5 * log2(fast::max(fast::max(dot(_1572, _1572), dot(_1576, _1576)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_apply_decals(thread const float3& world_pos, thread const float3& geo_normal, thread float3& albedo, thread float3& normal, constant fa_mesh_fs_params& _365, texture2d<float> fa_light_tex, sampler fa_shadow_smp, sampler fa_env_smp, texture2d<float> fa_decal_tex)\n{\n    bool _1609 = _365.fa_counts.y < 0.5;\n    bool _1616;\n    if (!_1609)\n    {\n        _1616 = _365.fa_counts.w < 0.5;\n    }\n    else\n    {\n        _1616 = _1609;\n    }\n    if (_1616)\n    {\n        return;\n    }\n    float3 _1622 = dfdx(world_pos);\n    float3 _1625 = dfdy(world_pos);\n    float3 param = world_pos;\n    float4 _1629 = fa_cluster_texel(param, _365, fa_light_tex, fa_shadow_smp);\n    int _1633 = int(_1629.w);\n    if (_1633 < 1)\n    {\n        return;\n    }\n    int _1643 = int(_365.fa_counts.y + 0.5);\n    int param_1 = _1643;\n    float4 _1647 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float2 _1650 = _1647.yz;\n    int _1654 = int(_1647.w);\n    int param_2 = _1643 + 1;\n    float4 _1659 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float _1660 = _1659.x;\n    int _1666 = int(_365.fa_counts.w + 0.5) - 1;\n    int _1670 = int(_1629.z);\n    float3 _1935;\n    for (int k = 0; k < _1633; k++)\n    {\n        int _1683 = _1670 + k;\n        int param_3 = _1654 + (_1683 >> 2);\n        int _1700 = (_1643 + 2) + (int(fa_light_texel(param_3, fa_light_tex, fa_shadow_smp)[_1683 & 3]) * 7);\n        int param_4 = _1700 + 6;\n        float4 _1705 = fa_light_texel(param_4, fa_light_tex, fa_shadow_smp);\n        if (((int(_1705.w + 0.5) >> _1666) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1700;\n        float4 _1720 = fa_light_texel(param_5, fa_light_tex, fa_shadow_smp);\n        int param_6 = _1700 + 1;\n        float4 _1725 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n        int param_7 = _1700 + 2;\n        float4 _1730 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n        float3 _1733 = _1720.xyz;\n        float _1738 = dot(_1733, world_pos) + _1720.w;\n        float3 _1740 = _1725.xyz;\n        float _1745 = dot(_1740, world_pos) + _1725.w;\n        float3 _1747 = _1730.xyz;\n        float _1752 = dot(_1747, world_pos) + _1730.w;\n        bool _1757 = abs(_1738) > 0.5;\n        bool _1765;\n        if (!_1757)\n        {\n            _1765 = abs(_1745) > 0.5;\n        }\n        else\n        {\n            _1765 = _1757;\n        }\n        bool _1773;\n        if (!_1765)\n        {\n            _1773 = abs(_1752) > 0.5;\n        }\n        else\n        {\n            _1773 = _1765;\n        }\n        if (_1773)\n        {\n            continue;\n        }\n        float _1788 = fast::clamp(dot(geo_normal, fast::normalize(_1747)) * _1705.z, 0.0, 1.0);\n        if (_1788 <= 0.0)\n        {\n            continue;\n        }\n        float _1808 = (fast::clamp((0.5 - abs(_1752)) * 10.0, 0.0, 1.0) * _1788) * _1705.x;\n        float2 _1816 = float2(_1738 + 0.5, 0.5 - _1745);\n        float2 _1826 = float2(dot(_1733, _1622), dot(_1740, _1622));\n        float2 _1836 = float2(dot(_1733, _1625), dot(_1740, _1625));\n        int param_8 = _1700 + 5;\n        float4 _1841 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n        int param_9 = _1700 + 3;\n        float4 _1846 = fa_light_texel(param_9, fa_light_tex, fa_shadow_smp);\n        int param_10 = _1700 + 4;\n        float4 _1851 = fa_light_texel(param_10, fa_light_tex, fa_shadow_smp);\n        float tex_a = 1.0;\n        float3 col = _1841.xyz;\n        bool _1861 = _1846.z > _1846.x;\n        if (_1861)\n        {\n            float4 param_11 = _1846;\n            float2 param_12 = _1816;\n            float2 param_13 = _1650;\n            float2 param_14 = _1826;\n            float2 param_15 = _1836;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15, fa_env_smp, fa_decal_tex);\n            if ((_1660 > 0.5) && (_1660 < 1.5))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1887 = fa_dc_to_linear(param_16);\n                float4 _5130 = tx;\n                _5130.x = _1887.x;\n                _5130.y = _1887.y;\n                _5130.z = _1887.z;\n                tx = _5130;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, float3(fast::clamp((_1808 * tex_a) * _1841.w, 0.0, 1.0)));\n        if (_1851.z > _1851.x)\n        {\n            float4 param_17 = _1851;\n            float2 param_18 = _1816;\n            float2 param_19 = _1650;\n            float2 param_20 = _1826;\n            float2 param_21 = _1836;\n            float4 _1931 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21, fa_env_smp, fa_decal_tex);\n            if (_1660 > 1.5)\n            {\n                float3 param_22 = _1931.xyz;\n                float3 _1941 = fa_dc_to_srgb(param_22);\n                _1935 = _1941;\n            }\n            else\n            {\n                _1935 = _1931.xyz;\n            }\n            float3 _1950 = (_1935 * 2.0) - float3(1.0);\n            float2 _1955 = _1950.xy * _1705.y;\n            float3 _1977 = (fast::normalize(_1733) * _1955.x) + (fast::normalize(_1740) * _1955.y);\n            float3 _1980 = fast::normalize(normal);\n            normal = fast::normalize(mix(_1980, fast::normalize((_1980 * fast::max(_1950.z, 0.0500000007450580596923828125)) + (_1977 - (_1980 * dot(_1980, _1977)))), float3(fast::clamp(_1808 * (_1861 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _365, sampler fa_env_smp, texturecube<float> fa_irr_tex)\n{\n    if (_365.fa_env_sky.w > 0.5)\n    {\n        return fa_irr_tex.sample(fa_env_smp, n, level(0.0)).xyz;\n    }\n    return _365.fa_ambient.xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_indirect_diffuse(thread const float3& n, constant fa_mesh_fs_params& _365, sampler fa_env_smp, texturecube<float> fa_irr_tex, thread float3& fa_lm, texture2d<float> fa_lightmap)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return fa_lightmap.sample(fa_env_smp, fa_lm.xy, level(0.0)).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param, _365, fa_env_smp, fa_irr_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_sheen_albedo(thread const float& ndv, thread const float& rough)\n{\n    float _3281 = fast::min(sqrt(fast::max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _3289 = fast::min(sqrt(fast::clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _3292 = int(_3281);\n    int _3295 = int(_3289);\n    float _3305 = _3289 - float(_3295);\n    int _3361 = (_3292 * 9) + _3295;\n    int _3381 = ((_3292 + 1) * 9) + _3295;\n    return mix(mix(_3356[_3361], _3356[_3361 + 1], _3305), mix(_3356[_3381], _3356[_3381 + 1], _3305), _3281 - float(_3292));\n}\n\nstatic inline __attribute__((always_inline))\nFaLayers fa_layers_setup(thread const SurfaceInput& i, thread const Surface& s, thread const float3& n, thread const float3& v, thread const float& metallic, thread const float& roughness, thread float3& f0)\n{\n    bool _4909 = false;\n    float _4910 = 1.0;\n    float _4911 = 1.0;\n    float _4912 = 1.0;\n    float _4913 = 0.0;\n    float _4914 = 0.0;\n    float _4915 = 0.0;\n    float _4916 = 0.0;\n    float _4918 = 1.0;\n    bool _4919 = false;\n    float3 _4920 = float3(0.0);\n    float _4921 = 1.0;\n    float _4922 = 1.0;\n    float _4923 = 1.0;\n    float _4924 = 0.0;\n    float _4925 = 0.0;\n    float3 _4926 = float3(1.0, 0.0, 0.0);\n    float3 _4927 = float3(0.0, 0.0, 1.0);\n    float _4928 = 1.0;\n    float _4929 = 1.0;\n    float _3432 = fast::clamp(s.specular, 0.0, 1.0);\n    float _3436 = fast::clamp(s.ior, 1.0, 3.0);\n    bool _3441 = (_3432 != 1.0) || (_3436 != 1.5);\n    bool _3450;\n    if (!_3441)\n    {\n        _3450 = any(s.specular_color != float3(1.0));\n    }\n    else\n    {\n        _3450 = _3441;\n    }\n    if (_3450)\n    {\n        float _3458 = (_3436 - 1.0) / (_3436 + 1.0);\n        f0 = mix(fast::min(float3(_3458 * _3458) * fast::max(s.specular_color, float3(0.0)), float3(1.0)) * _3432, s.albedo, float3(metallic));\n        _4910 = mix(_3432, 1.0, metallic);\n        _4909 = true;\n    }\n    float _3485 = fast::clamp(s.clearcoat, 0.0, 1.0);\n    if (_3485 > 0.0)\n    {\n        float _3493 = fast::clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _4913 = _3485;\n        _4914 = _3493;\n        float _3500 = _3493 * _3493;\n        _4915 = _3500;\n        _4916 = _3500 * _3500;\n        float _3512 = fast::max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _4918 = _3512;\n        _4911 = 1.0 - (_3485 * (0.039999999105930328369140625 + (0.959999978542327880859375 * powr(fast::clamp(1.0 - _3512, 0.0, 1.0), 5.0))));\n        _4909 = true;\n    }\n    float3 _3532 = fast::max(s.sheen_color, float3(0.0));\n    float _3541 = fast::max(_3532.x, fast::max(_3532.y, _3532.z));\n    if (_3541 > 0.0)\n    {\n        float _3549 = fast::clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _4919 = true;\n        _4920 = _3532;\n        _4921 = _3549;\n        _4922 = _3549 * _3549;\n        float param = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _3549;\n        float _3566 = fa_sheen_albedo(param, param_1);\n        _4924 = _3566;\n        _4923 = 1.0 - fast::min(_3541 * _3566, 1.0);\n        _4909 = true;\n    }\n    _4912 = _4911 * _4923;\n    float _3585 = fast::clamp(s.anisotropy, -1.0, 1.0);\n    if (_3585 != 0.0)\n    {\n        float3 _3600 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _3600;\n        if (dot(_3600, _3600) < 9.9999999392252902907785028219223e-09)\n        {\n            t = cross(select(float3(1.0, 0.0, 0.0), float3(0.0, 1.0, 0.0), bool3(abs(n.y) < 0.9900000095367431640625)), n);\n        }\n        float3 _3616 = t;\n        float3 _3617 = fast::normalize(_3616);\n        t = _3617;\n        float3 _3642 = fast::normalize((_3617 * cos(s.anisotropy_rotation)) + ((cross(n, _3617) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _4926 = _3642;\n        _4927 = cross(n, _3642);\n        float _3652 = roughness * roughness;\n        float _3658 = mix(_3652, 1.0, _3585 * _3585);\n        bool _3660 = _3585 > 0.0;\n        _4928 = _3660 ? _3658 : _3652;\n        _4929 = _3660 ? _3652 : _3658;\n        _4925 = _3585;\n        _4909 = true;\n    }\n    return FaLayers{ short(_4909), _4910, _4911, _4912, _4913, _4914, _4915, _4916, i.world_normal, _4918, short(_4919), _4920, _4921, _4922, _4923, _4924, _4925, _4926, _4927, _4928, _4929 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_env_brdf(thread const float& rough, thread const float& ndv)\n{\n    float4 _3213 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _3216 = _3213.x;\n    return (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_3216 * _3216, exp2((-9.27999973297119140625) * ndv)) * _3216) + _3213.y)) + _3213.zw;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_environment(thread const float3& d, thread const float& rough, constant fa_mesh_fs_params& _365, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    if (_365.fa_env_sky.w > 0.5)\n    {\n        return fa_env_tex.sample(fa_env_smp, d, level(fast::clamp(rough, 0.0, 1.0) * _365.fa_env_horizon.w)).xyz;\n    }\n    float _3119 = rough * rough;\n    float _3149 = 0.60000002384185791015625 * _3119;\n    return mix(mix(_365.fa_env_horizon.xyz * 0.550000011920928955078125, mix(_365.fa_env_horizon.xyz, _365.fa_env_sky.xyz, float3(powr(fast::clamp(d.y * (1.0 - (0.699999988079071044921875 * _3119)), 0.0, 1.0), 0.550000011920928955078125))), float3(smoothstep((-0.0500000007450580596923828125) - _3149, 0.0500000007450580596923828125 + _3149, d.y))), ((_365.fa_env_sky.xyz + _365.fa_env_horizon.xyz) * 0.5) * 0.800000011920928955078125, float3(_3119 * 0.60000002384185791015625));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_layers_ibl(thread const FaLayers& L, thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _365, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        float3 _3693;\n        if (L.aniso >= 0.0)\n        {\n            _3693 = L.b;\n        }\n        else\n        {\n            _3693 = L.t;\n        }\n        rn = fast::normalize(mix(n, cross(cross(_3693, v), _3693), float3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _3726 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3, _365, fa_env_smp, fa_env_tex) * ((f0 * _3726.x) + (float3(L.f90) * _3726.y))) * L.base_scale;\n    if (bool(L.sheen_on))\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5, _365, fa_env_smp, fa_env_tex));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _3781 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9, _365, fa_env_smp, fa_env_tex) * (L.coat * ((0.039999999105930328369140625 * _3781.x) + _3781.y)));\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_reflection(thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _365, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _3255 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3, _365, fa_env_smp, fa_env_tex) * ((f0 * _3255.x) + float3(_3255.y));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_light(thread const SurfaceInput& i, thread const Surface& s, constant fa_mesh_fs_params& _365, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float _3810 = fast::clamp(s.metallic, 0.0, 1.0);\n    float _3814 = fast::clamp(s.roughness, 0.0500000007450580596923828125, 1.0);\n    float3 _3821 = mix(float3(0.039999999105930328369140625), s.albedo, float3(_3810));\n    float3 f0 = _3821;\n    float3 _3825 = fast::normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    float3 param_2 = _3825;\n    float3 param_3 = i.view_dir;\n    float param_4 = _3810;\n    float param_5 = _3814;\n    float3 param_6 = _3821;\n    FaLayers _3842 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_3842.on)\n    {\n        FaLayers param_7 = _3842;\n        float3 param_8 = _3825;\n        float3 param_9 = i.view_dir;\n        float3 param_10 = f0;\n        float param_11 = _3814;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11, _365, fa_env_smp, fa_env_tex) * s.occlusion;\n    }\n    float3 param_12 = _3825;\n    float3 param_13 = i.view_dir;\n    float3 param_14 = f0;\n    float param_15 = _3814;\n    return fa_sky_reflection(param_12, param_13, param_14, param_15, _365, fa_env_smp, fa_env_tex) * s.occlusion;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 ambient(thread const SurfaceInput& i, thread const Surface& s, thread const float3& ambientColor, constant fa_mesh_fs_params& _365, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    return fa_sky_light(param, param_1, _365, fa_env_smp, fa_env_tex);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, constant fa_mesh_fs_params& _365, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (int(_365.fa_cl_info.x) + int(_365.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, constant fa_mesh_fs_params& _365, texture2d<float> fa_light_tex, sampler fa_shadow_smp, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, _365, fa_light_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_light_base(thread const int& li, constant fa_mesh_fs_params& _365)\n{\n    return li * ((_365.fa_ambient.w > 4.5) ? 8 : 4);\n}\n\nstatic inline __attribute__((always_inline))\nbool fa_light_baked(thread const int& li, constant fa_mesh_fs_params& _365, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li;\n    int param_1 = fa_light_base(param, _365) + 3;\n    return fa_light_texel(param_1, fa_light_tex, fa_shadow_smp).w > 0.5;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_light_type(thread const int& li, constant fa_mesh_fs_params& _365, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li;\n    int param_1 = fa_light_base(param, _365) + 1;\n    return fa_light_texel(param_1, fa_light_tex, fa_shadow_smp).w;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_atlas_fetch(thread const float2& texel, texture2d<float> fa_light_atlas, sampler fa_env_smp)\n{\n    return fa_light_atlas.sample(fa_env_smp, (texel / float2(int2(fa_light_atlas.get_width(), fa_light_atlas.get_height()))), level(0.0));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_cookie_sample(thread const float2& tile_origin, thread const float2& uv, texture2d<float> fa_light_atlas, sampler fa_env_smp)\n{\n    float2 param = (tile_origin + float2(1.0)) + (fast::clamp(uv, float2(0.0), float2(1.0)) * 254.0);\n    return fa_atlas_fetch(param, fa_light_atlas, fa_env_smp).xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_area_point(thread const float3& c, thread const float3& axis, thread const float3& ru, thread const float3& uu, thread const float& hx, thread const float& hy, thread const float& shape, thread const float3& p, thread const float3& r)\n{\n    bool _593 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        float3 _606 = (c - (ru * hx)) - p;\n        float3 _612 = ru * (2.0 * hx);\n        float _618 = fast::max(dot(_612, _612), 9.9999999392252902907785028219223e-09);\n        float _622 = dot(_606, _612);\n        float t = fast::clamp((-_622) / _618, 0.0, 1.0);\n        if (_593)\n        {\n            float _637 = dot(r, _612);\n            float _643 = _618 - (_637 * _637);\n            if (abs(_643) > (9.9999997473787516355514526367188e-06 * _618))\n            {\n                t = fast::clamp(((dot(r, _606) * _637) - _622) / _643, 0.0, 1.0);\n            }\n        }\n        return (p + _606) + (_612 * t);\n    }\n    float3 q = p;\n    float _675 = dot(r, axis);\n    bool _683;\n    if (_593)\n    {\n        _683 = abs(_675) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _683 = _593;\n    }\n    if (_683)\n    {\n        float _693 = dot(c - p, axis) / _675;\n        if (_693 > 0.0)\n        {\n            q = p + (r * _693);\n        }\n    }\n    float3 _706 = q - c;\n    float2 xy = float2(dot(_706, ru), dot(_706, uu));\n    if (shape > 0.5)\n    {\n        float _721 = length(xy);\n        if (_721 > hx)\n        {\n            xy *= (hx / _721);\n        }\n    }\n    else\n    {\n        xy = fast::clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cube_face(thread const float3& d)\n{\n    float3 _514 = abs(d);\n    float _516 = _514.x;\n    float _518 = _514.y;\n    bool _519 = _516 >= _518;\n    bool _527;\n    if (_519)\n    {\n        _527 = _516 >= _514.z;\n    }\n    else\n    {\n        _527 = _519;\n    }\n    int _528;\n    if (_527)\n    {\n        _528 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _541;\n        if (_518 >= _514.z)\n        {\n            _541 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _541 = (d.z > 0.0) ? 4 : 5;\n        }\n        _528 = _541;\n    }\n    return _528;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cube_face_basis(thread const int& f, thread float3& fwd, thread float3& up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0, 0.0, 0.0);\n        up = float3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0, 0.0, 0.0);\n            up = float3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0, 1.0, 0.0);\n                up = float3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0, -1.0, 0.0);\n                    up = float3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0, 0.0, 1.0);\n                        up = float3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0, 0.0, -1.0);\n                        up = float3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_ies_sample(thread const float2& tile_origin, thread const float3& d, thread const float3& axis, thread const float3& right, thread const float3& up, texture2d<float> fa_light_atlas, sampler fa_env_smp)\n{\n    float _467 = dot(d, right);\n    float _471 = dot(d, up);\n    float _482;\n    if (((_467 * _467) + (_471 * _471)) > 1.0000000133514319600180897396058e-10)\n    {\n        _482 = precise::atan2(_471, _467) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _482 = 0.0;\n    }\n    float2 param = tile_origin + float2(1.0 + ((_482 - floor(_482)) * 64.0), 1.0 + (acos(fast::clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param, fa_light_atlas, fa_env_smp).x;\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample_n(thread const int& li, thread const float3& world_pos, thread const float3& n, constant fa_mesh_fs_params& _365, texture2d<float> fa_light_tex, sampler fa_shadow_smp, texture2d<float> fa_light_atlas, sampler fa_env_smp, thread float3& fa_light_tint, thread bool& fa_light_is_area)\n{\n    int param = li;\n    int _759 = fa_light_base(param, _365);\n    bool _763 = _365.fa_ambient.w > 4.5;\n    int param_1 = _759;\n    float4 _767 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    int param_2 = _759 + 1;\n    float4 _772 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float _775 = _772.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = float3(1.0);\n    bool _787 = _763 && (_775 > 2.5);\n    fa_light_is_area = _787;\n    bool _789 = _775 < 0.5;\n    float3 l;\n    if (_789)\n    {\n        l = fast::normalize(_767.xyz);\n        if (_763)\n        {\n            int param_3 = _759 + 6;\n            float4 _803 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            if (_803.z > 0.5)\n            {\n                int param_4 = _759 + 4;\n                float4 _813 = fa_light_texel(param_4, fa_light_tex, fa_shadow_smp);\n                int param_5 = _759 + 5;\n                float4 _818 = fa_light_texel(param_5, fa_light_tex, fa_shadow_smp);\n                float2 param_6 = _803.xy;\n                float2 param_7 = fract(float2(dot(world_pos, _813.xyz) * _813.w, (-dot(world_pos, _818.xyz)) * _818.w) + float2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7, fa_light_atlas, fa_env_smp);\n            }\n        }\n    }\n    else\n    {\n        float3 _848 = _767.xyz;\n        float3 _850 = _848 - world_pos;\n        float3 to_light = _850;\n        float _853 = length(_850);\n        float reach = _853;\n        bool front = true;\n        if (_787)\n        {\n            int param_8 = _759 + 7;\n            reach = fast::max(_853 - fa_light_texel(param_8, fa_light_tex, fa_shadow_smp).w, 0.0);\n            int param_9 = _759 + 4;\n            float4 _877 = fa_light_texel(param_9, fa_light_tex, fa_shadow_smp);\n            int param_10 = _759 + 5;\n            float4 _882 = fa_light_texel(param_10, fa_light_tex, fa_shadow_smp);\n            int param_11 = _759 + 6;\n            float4 _887 = fa_light_texel(param_11, fa_light_tex, fa_shadow_smp);\n            float _888 = _887.w;\n            int param_12 = _759 + 2;\n            float3 _895 = fast::normalize(fa_light_texel(param_12, fa_light_tex, fa_shadow_smp).xyz);\n            bool _897 = _888 > 1.5;\n            bool _905;\n            if (!_897)\n            {\n                _905 = dot(_895, to_light) < 0.0;\n            }\n            else\n            {\n                _905 = _897;\n            }\n            front = _905;\n            float3 r = float3(0.0);\n            if (dot(n, n) > 0.5)\n            {\n                r = reflect(-fast::normalize(_365.fa_camera_pos.xyz - world_pos), fast::normalize(n));\n            }\n            float3 param_13 = _848;\n            float3 param_14 = _895;\n            float3 param_15 = _877.xyz;\n            float3 param_16 = _882.xyz;\n            float param_17 = _877.w;\n            float param_18 = _882.w;\n            float param_19 = _888;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _952 = length(to_light);\n        dist = _952;\n        l = to_light / float3(fast::max(_952, 9.9999997473787516355514526367188e-05));\n        float _966 = reach / fast::max(_767.w, 0.001000000047497451305389404296875);\n        float _972 = fast::clamp(1.0 - (_966 * _966), 0.0, 1.0);\n        float _974;\n        if (front)\n        {\n            _974 = _972 * _972;\n        }\n        else\n        {\n            _974 = 0.0;\n        }\n        atten = _974;\n        bool _985 = _775 < 2.5;\n        if ((_775 > 1.5) && _985)\n        {\n            int param_22 = _759 + 2;\n            float4 _993 = fa_light_texel(param_22, fa_light_tex, fa_shadow_smp);\n            float _1003 = _993.w;\n            int param_23 = _759 + 3;\n            float4 _1008 = fa_light_texel(param_23, fa_light_tex, fa_shadow_smp);\n            float _1009 = _1008.x;\n            float cos_inner = _1009;\n            if (_1009 > 1.5)\n            {\n                cos_inner = mix(_1003, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1003, cos_inner, dot(-l, fast::normalize(_993.xyz)));\n        }\n        if (_763 && (_775 < 1.5))\n        {\n            int param_24 = _759 + 6;\n            float4 _1033 = fa_light_texel(param_24, fa_light_tex, fa_shadow_smp);\n            if (_1033.z > 0.5)\n            {\n                float3 _1041 = -to_light;\n                int param_25 = _759 + 4;\n                int param_26 = _759 + 5;\n                float3 _1055 = fa_light_texel(param_25, fa_light_tex, fa_shadow_smp).xyz;\n                float3 _1059 = fa_light_texel(param_26, fa_light_tex, fa_shadow_smp).xyz;\n                float3 _1068 = float3(dot(_1041, _1055), dot(_1041, _1059), dot(_1041, cross(_1055, _1059)));\n                float3 param_27 = _1068;\n                int _1072 = fa_cube_face(param_27);\n                int param_28 = _1072;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1099 = float2(dot(_1068, cross(param_29, param_30)), dot(_1068, param_30)) / float2(fast::max(dot(_1068, param_29), 9.9999997473787516355514526367188e-05));\n                int _1103 = _1072 / 3;\n                float2 param_31 = _1033.xy + (float2(float(_1072 - (_1103 * 3)), float(_1103)) * 256.0);\n                float2 param_32 = float2(0.5 + (0.5 * _1099.x), 0.5 - (0.5 * _1099.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32, fa_light_atlas, fa_env_smp);\n            }\n            int param_33 = _759 + 7;\n            float4 _1133 = fa_light_texel(param_33, fa_light_tex, fa_shadow_smp);\n            if (_1133.z > 0.5)\n            {\n                int param_34 = _759 + 2;\n                int param_35 = _759 + 4;\n                int param_36 = _759 + 5;\n                float2 param_37 = _1133.xy;\n                float3 param_38 = -l;\n                float3 param_39 = fast::normalize(fa_light_texel(param_34, fa_light_tex, fa_shadow_smp).xyz);\n                float3 param_40 = fa_light_texel(param_35, fa_light_tex, fa_shadow_smp).xyz;\n                float3 param_41 = fa_light_texel(param_36, fa_light_tex, fa_shadow_smp).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41, fa_light_atlas, fa_env_smp);\n            }\n        }\n        else\n        {\n            if (_763 && _985)\n            {\n                int param_42 = _759 + 6;\n                float4 _1180 = fa_light_texel(param_42, fa_light_tex, fa_shadow_smp);\n                int param_43 = _759 + 7;\n                float4 _1185 = fa_light_texel(param_43, fa_light_tex, fa_shadow_smp);\n                bool _1188 = _1180.z > 0.5;\n                bool _1195;\n                if (!_1188)\n                {\n                    _1195 = _1185.z > 0.5;\n                }\n                else\n                {\n                    _1195 = _1188;\n                }\n                if (_1195)\n                {\n                    int param_44 = _759 + 2;\n                    float4 _1202 = fa_light_texel(param_44, fa_light_tex, fa_shadow_smp);\n                    float3 _1206 = fast::normalize(_1202.xyz);\n                    int param_45 = _759 + 4;\n                    float4 _1211 = fa_light_texel(param_45, fa_light_tex, fa_shadow_smp);\n                    int param_46 = _759 + 5;\n                    float4 _1216 = fa_light_texel(param_46, fa_light_tex, fa_shadow_smp);\n                    if (_1188)\n                    {\n                        float3 _1224 = -to_light;\n                        float _1231 = _1202.w;\n                        float _1247 = 0.5 / fast::max(dot(_1224, _1206) * (sqrt(fast::max(1.0 - (_1231 * _1231), 0.0)) / fast::max(_1231, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        float2 param_47 = _1180.xy;\n                        float2 param_48 = float2(0.5 + (dot(_1224, _1211.xyz) * _1247), 0.5 - (dot(_1224, _1216.xyz) * _1247));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48, fa_light_atlas, fa_env_smp);\n                    }\n                    if (_1185.z > 0.5)\n                    {\n                        float2 param_49 = _1185.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1206;\n                        float3 param_52 = _1211.xyz;\n                        float3 param_53 = _1216.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53, fa_light_atlas, fa_env_smp);\n                    }\n                }\n            }\n        }\n    }\n    float3 _4897 = _772.xyz * atten;\n    if (_763)\n    {\n        _4897 *= fa_light_tint;\n    }\n    int _1315;\n    if (_789)\n    {\n        _1315 = 0;\n    }\n    else\n    {\n        _1315 = ((_775 > 1.5) && (_775 < 2.5)) ? 2 : 1;\n    }\n    return LightSample{ l, _4897, atten, 1.0, dist, _1315 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _2062)\n{\n    float _2052;\n    if (i == 0)\n    {\n        _2052 = _2062.fa_shadow_split.x;\n    }\n    else\n    {\n        float _2068;\n        if (i == 1)\n        {\n            _2068 = _2062.fa_shadow_split.y;\n        }\n        else\n        {\n            float _2076;\n            if (i == 2)\n            {\n                _2076 = _2062.fa_shadow_split.z;\n            }\n            else\n            {\n                _2076 = _2062.fa_shadow_split.w;\n            }\n            _2068 = _2076;\n        }\n        _2052 = _2068;\n    }\n    return _2052;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_fetch(thread const float2& uv, thread const float4& rect, thread const float3& conv, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2109 = fa_shadow_depth(param, param_1, fa_shadow_smp, fa_shadow_tex);\n    float _2113;\n    if (conv.x < 0.5)\n    {\n        _2113 = _2109;\n    }\n    else\n    {\n        _2113 = (conv.y * conv.z) / (conv.z - (_2109 * (conv.z - conv.y)));\n    }\n    return _2113;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _2040 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_2040), sin(_2040)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_filter(thread const float2& uv, thread const float4& rect, thread const float& zr, thread const float& texel_m, thread const float& unit, thread const float& reach, thread const float& plane, thread const float3& conv, thread const int& mode, thread const float& k, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2062, texture2d<float> fa_shadow_tex)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2, fa_shadow_smp, fa_shadow_tex));\n    }\n    float _2159 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2168;\n        if (k < 0.0)\n        {\n            _2168 = (-k) / fast::max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2168 = k;\n        }\n        float _2188 = fast::clamp((_2168 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2159;\n            float2 _2207 = fa_shadow_vogel(param_3, param_4, param_5) * _2188;\n            float2 param_6 = uv + (_2207 * _2062.fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _2219 = fa_shadow_fetch(param_6, param_7, param_8, fa_shadow_smp, fa_shadow_tex);\n            if (_2219 < (zr - (length(_2207) * plane)))\n            {\n                sum += _2219;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2245 = sum / cnt;\n        float _2255;\n        if (k < 0.0)\n        {\n            _2255 = (-k) / fast::max(_2245, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2255 = k;\n        }\n        radius = fast::clamp(((fast::max(zr - _2245, 0.0) * unit) * _2255) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _2277 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2277; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2277;\n        float param_11 = _2159;\n        float2 _2296 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_2296 * _2062.fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_2296) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14, fa_shadow_smp, fa_shadow_tex));\n    }\n    return lit / float(_2277);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2062, texture2d<float> fa_shadow_tex)\n{\n    float _2338 = fast::max(_2062.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _2343 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _2349 = sqrt(1.0 - (_2343 * _2343));\n    float _2356 = fast::min(_2349 / fast::max(_2343, 0.20000000298023223876953125), 4.0);\n    float _2361;\n    if (_2062.fa_shadow_bias.y > 0.0)\n    {\n        _2361 = _2062.fa_shadow_bias.y;\n    }\n    else\n    {\n        _2361 = 1.5 * _2062.fa_shadow_info[ci].x;\n    }\n    float4 _2386 = _2062.fa_shadow_mat[ci] * float4(world + (n * (_2361 * _2349)), 1.0);\n    float _2393 = _2386.x;\n    bool _2396 = _2393 < _2062.fa_shadow_rect[ci].x;\n    bool _2405;\n    if (!_2396)\n    {\n        _2405 = _2393 > _2062.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2405 = _2396;\n    }\n    bool _2414;\n    if (!_2405)\n    {\n        _2414 = _2386.y < _2062.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2414 = _2405;\n    }\n    bool _2423;\n    if (!_2414)\n    {\n        _2423 = _2386.y > _2062.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2423 = _2414;\n    }\n    bool _2430;\n    if (!_2423)\n    {\n        _2430 = _2386.z > 1.0;\n    }\n    else\n    {\n        _2430 = _2423;\n    }\n    if (_2430)\n    {\n        return -1.0;\n    }\n    float _2438;\n    if (_2062.fa_shadow_bias.x > 0.0)\n    {\n        _2438 = _2062.fa_shadow_bias.x;\n    }\n    else\n    {\n        _2438 = 1.5 * _2062.fa_shadow_info[ci].x;\n    }\n    float2 param = _2386.xy;\n    float4 param_1 = _2062.fa_shadow_rect[ci];\n    float param_2 = _2386.z - ((_2438 * (1.0 + (0.5 * _2356))) / _2338);\n    float param_3 = _2062.fa_shadow_info[ci].x;\n    float param_4 = _2338;\n    float param_5 = _2338 * 0.25;\n    float param_6 = ((_2062.fa_shadow_info[ci].x * fast::min(_2356, 3.0)) * 0.5) / _2338;\n    float3 param_7 = float3(0.0);\n    int param_8 = int(_2062.fa_shadow_cfg.z + 0.5);\n    float param_9 = _2062.fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9, fa_shadow_smp, gl_FragCoord, _2062, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _365, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2062, texture2d<float> fa_shadow_tex)\n{\n    if (_365.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2826 = int(_2062.fa_shadow_cfg.x + 0.5);\n    if (_2826 < 1)\n    {\n        return 1.0;\n    }\n    float _2841 = dot(world - _2062.fa_shadow_eye.xyz, _2062.fa_shadow_fwd.xyz);\n    int param = _2826 - 1;\n    if (_2841 > fa_shadow_split_at(param, _2062))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2853 = _2826 > 1;\n    bool _2860;\n    if (_2853)\n    {\n        _2860 = _2841 > _2062.fa_shadow_split.x;\n    }\n    else\n    {\n        _2860 = _2853;\n    }\n    if (_2860)\n    {\n        ci = 1;\n    }\n    bool _2864 = _2826 > 2;\n    bool _2871;\n    if (_2864)\n    {\n        _2871 = _2841 > _2062.fa_shadow_split.y;\n    }\n    else\n    {\n        _2871 = _2864;\n    }\n    if (_2871)\n    {\n        ci = 2;\n    }\n    bool _2875 = _2826 > 3;\n    bool _2882;\n    if (_2875)\n    {\n        _2882 = _2841 > _2062.fa_shadow_split.z;\n    }\n    else\n    {\n        _2882 = _2875;\n    }\n    if (_2882)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2826)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2908 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_shadow_smp, gl_FragCoord, _2062, fa_shadow_tex);\n        s = _2908;\n        if (_2908 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_2062.fa_shadow_cfg.y > 0.0)\n    {\n        float _2933;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2933 = fa_shadow_split_at(param_5, _2062);\n        }\n        else\n        {\n            _2933 = _2062.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _2952 = _2062.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _2062) - _2933, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2963 = fast::clamp((_2841 - (fa_shadow_split_at(param_7, _2062) - _2952)) / _2952, 0.0, 1.0);\n        if (_2963 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2826)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _2984 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_shadow_smp, gl_FragCoord, _2062, fa_shadow_tex);\n                s2 = _2984;\n                if (_2984 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2963);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _365, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2062, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, _365, fa_shadow_smp, gl_FragCoord, _2062, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_local(thread const int& li, thread const float3& world, thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _365, texture2d<float> fa_light_tex, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2062, texture2d<float> fa_shadow_tex)\n{\n    bool _2496 = _365.fa_pbr.z < 0.5;\n    bool _2503;\n    if (!_2496)\n    {\n        _2503 = _2062.fa_shadow_lcfg.x < 0.5;\n    }\n    else\n    {\n        _2503 = _2496;\n    }\n    if (_2503)\n    {\n        return 1.0;\n    }\n    int param = (int(_2062.fa_shadow_lcfg.x + 0.5) - 1) + li;\n    float4 _2516 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    float _2517 = _2516.x;\n    if (_2517 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2526 = int(_2517 + 0.5);\n    int param_1 = _2526;\n    float4 _2530 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    int param_2 = _2526 + 1;\n    float4 _2535 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float fade = 1.0;\n    float _2538 = _2530.y;\n    if (_2538 > 0.0)\n    {\n        float _2555 = 1.0 - smoothstep(0.75 * _2538, _2538, length(world - _2062.fa_shadow_eye.xyz));\n        fade = _2555;\n        if (_2555 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2530.x > 1.5)\n    {\n        int param_3 = li;\n        int param_4 = fa_light_base(param_3, _365);\n        float3 param_5 = world - fa_light_texel(param_4, fa_light_tex, fa_shadow_smp).xyz;\n        face = fa_cube_face(param_5);\n    }\n    int _2584 = (_2526 + 2) + (face * 6);\n    int param_6 = _2584;\n    int param_7 = _2584 + 1;\n    int param_8 = _2584 + 3;\n    float4 _2598 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n    int param_9 = _2584 + 4;\n    float4 _2603 = fa_light_texel(param_9, fa_light_tex, fa_shadow_smp);\n    int param_10 = _2584 + 5;\n    float4 _2608 = fa_light_texel(param_10, fa_light_tex, fa_shadow_smp);\n    float _2620 = _2608.x * fast::max(dot(_2598, float4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2625 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _2648 = fast::clamp(dot(n, _2598.xyz), -1.0, 1.0);\n    int param_11 = li;\n    int param_12 = fa_light_base(param_11, _365);\n    float _2672 = fast::min(sqrt(1.0 - (_2648 * _2648)) / fast::max(abs(dot(n, world - fa_light_texel(param_12, fa_light_tex, fa_shadow_smp).xyz)) / fast::max(dot(_2598, float4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2675 = _2535.y;\n    float _2677;\n    if (_2675 > 0.0)\n    {\n        _2677 = _2675;\n    }\n    else\n    {\n        _2677 = 1.5 * _2620;\n    }\n    float4 _2697 = float4(world + (n * (_2677 * sqrt(1.0 - (_2625 * _2625)))), 1.0);\n    float _2701 = dot(_2598, _2697);\n    float _2704 = _2608.y;\n    if (_2701 < _2704)\n    {\n        return 1.0;\n    }\n    float2 _2719 = float2(dot(fa_light_texel(param_6, fa_light_tex, fa_shadow_smp), _2697), dot(fa_light_texel(param_7, fa_light_tex, fa_shadow_smp), _2697)) / float2(_2701);\n    float _2721 = _2719.x;\n    bool _2724 = _2721 < _2603.x;\n    bool _2733;\n    if (!_2724)\n    {\n        _2733 = _2721 > _2603.z;\n    }\n    else\n    {\n        _2733 = _2724;\n    }\n    bool _2742;\n    if (!_2733)\n    {\n        _2742 = _2719.y < _2603.y;\n    }\n    else\n    {\n        _2742 = _2733;\n    }\n    bool _2751;\n    if (!_2742)\n    {\n        _2751 = _2719.y > _2603.w;\n    }\n    else\n    {\n        _2751 = _2742;\n    }\n    if (_2751)\n    {\n        return 1.0;\n    }\n    float _2757 = _2535.x;\n    float _2759;\n    if (_2757 > 0.0)\n    {\n        _2759 = _2757;\n    }\n    else\n    {\n        _2759 = 1.5 * _2620;\n    }\n    float2 param_13 = _2719;\n    float4 param_14 = _2603;\n    float param_15 = _2701 - (_2759 * (1.0 + (0.5 * _2672)));\n    float param_16 = _2620;\n    float param_17 = 1.0;\n    float param_18 = _2608.z * 0.25;\n    float param_19 = (_2620 * fast::min(_2672, 3.0)) * 0.5;\n    float3 param_20 = float3(1.0, _2704, _2608.z);\n    int param_21 = int(_2530.z + 0.5);\n    float param_22 = _2530.w;\n    return mix(1.0, fa_shadow_filter(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21, param_22, fa_shadow_smp, gl_FragCoord, _2062, fa_shadow_tex), fade);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, constant fa_mesh_fs_params& _365, texture2d<float> fa_light_tex, sampler fa_shadow_smp, texture2d<float> fa_light_atlas, sampler fa_env_smp, thread float3& fa_light_tint, thread bool& fa_light_is_area, thread float4& gl_FragCoord, constant fa_shadows& _2062, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos, thread float3& fa_lm)\n{\n    bool _3915 = fa_lm.z > 0.5;\n    bool _3921;\n    if (_3915)\n    {\n        int param = li;\n        _3921 = fa_light_baked(param, _365, fa_light_tex, fa_shadow_smp);\n    }\n    else\n    {\n        _3921 = _3915;\n    }\n    if (_3921)\n    {\n        int param_1 = li;\n        return LightSample{ float3(0.0, 1.0, 0.0), float3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1, _365, fa_light_tex, fa_shadow_smp) + 0.5) };\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _3945 = fa_light_sample_n(param_2, param_3, param_4, _365, fa_light_tex, fa_shadow_smp, fa_light_atlas, fa_env_smp, fa_light_tint, fa_light_is_area);\n    float3 _5030 = _3945.color;\n    float _5032 = _3945.shadow;\n    if ((_3945.type == 0) && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _3945.direction;\n        float _3959 = fa_shadow_factor(param_5, param_6, _365, fa_shadow_smp, gl_FragCoord, _2062, fa_shadow_tex, fa_world_pos);\n        _5032 = _3959;\n        _5030 *= _3959;\n    }\n    else\n    {\n        bool _3970 = _3945.type != 0;\n        bool _3976;\n        if (_3970)\n        {\n            _3976 = _3945.attenuation > 0.0;\n        }\n        else\n        {\n            _3976 = _3970;\n        }\n        if (_3976)\n        {\n            int param_7 = li;\n            float3 param_8 = world_pos;\n            float3 param_9 = gn;\n            float3 param_10 = _3945.direction;\n            float _3988 = fa_shadow_local(param_7, param_8, param_9, param_10, _365, fa_light_tex, fa_shadow_smp, gl_FragCoord, _2062, fa_shadow_tex);\n            _5032 = _3988;\n            _5030 *= _3988;\n        }\n    }\n    return LightSample{ _3945.direction, _5030, _3945.attenuation, _5032, _3945._distance, _3945.type };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 light(thread const SurfaceInput& i, thread const Surface& s, thread const LightSample& l)\n{\n    return float3(0.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _2062)\n{\n    if (_2062.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _3008 = int(_2062.fa_shadow_cfg.x + 0.5);\n    float _3018 = dot(world - _2062.fa_shadow_eye.xyz, _2062.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _3023 = _3008 > 0;\n    bool _3032;\n    if (_3023)\n    {\n        int param = _3008 - 1;\n        _3032 = _3018 <= fa_shadow_split_at(param, _2062);\n    }\n    else\n    {\n        _3032 = _3023;\n    }\n    if (_3032)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3038 = _3008 > 1;\n        bool _3045;\n        if (_3038)\n        {\n            _3045 = _3018 > _2062.fa_shadow_split.x;\n        }\n        else\n        {\n            _3045 = _3038;\n        }\n        if (_3045)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3051 = _3008 > 2;\n        bool _3058;\n        if (_3051)\n        {\n            _3058 = _3018 > _2062.fa_shadow_split.y;\n        }\n        else\n        {\n            _3058 = _3051;\n        }\n        if (_3058)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3064 = _3008 > 3;\n        bool _3071;\n        if (_3064)\n        {\n            _3071 = _3018 > _2062.fa_shadow_split.z;\n        }\n        else\n        {\n            _3071 = _3064;\n        }\n        if (_3071)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _365 [[buffer(1)]], constant fa_shadows& _2062 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_env_tex [[texture(6)]], texturecube<float> fa_irr_tex [[texture(7)]], texture2d<float> fa_light_tex [[texture(8)]], texture2d<float> fa_light_atlas [[texture(9)]], texture2d<float> fa_lightmap [[texture(10)]], texture2d<float> fa_decal_tex [[texture(11)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _4739 = fast::normalize(in.fa_world_normal);\n    float3 fa_light_tint;\n    bool fa_light_is_area;\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _4739 = -_4739;\n    }\n    float3 _4374 = fast::normalize(_365.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, _365, fa_light_tex, fa_shadow_smp, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _4739, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _4374, short(gl_FrontFacing) };\n    Surface _4382 = fa_standard_surface(param_1, _365, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _4778 = _4382.albedo;\n    float _4779 = _4382.alpha;\n    float3 _4780 = _4382.normal;\n    float _4781 = _4382.metallic;\n    float _4782 = _4382.roughness;\n    float _4783 = _4382.occlusion;\n    float3 _4784 = _4382.emission;\n    float _4785 = _4382.clearcoat;\n    float _4786 = _4382.clearcoat_roughness;\n    float3 _4787 = _4382.sheen_color;\n    float _4788 = _4382.sheen_roughness;\n    float _4789 = _4382.anisotropy;\n    float _4790 = _4382.anisotropy_rotation;\n    float _4791 = _4382.specular;\n    float _4792 = _4382.ior;\n    float3 _4793 = _4382.specular_color;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _4739, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _4374, short(gl_FrontFacing) };\n    Surface param_3 = _4382;\n    surface(param_2, param_3);\n    _4778 = param_3.albedo;\n    _4779 = param_3.alpha;\n    _4780 = param_3.normal;\n    _4781 = param_3.metallic;\n    _4782 = param_3.roughness;\n    _4783 = param_3.occlusion;\n    _4784 = param_3.emission;\n    _4785 = param_3.clearcoat;\n    _4786 = param_3.clearcoat_roughness;\n    _4787 = param_3.sheen_color;\n    _4788 = param_3.sheen_roughness;\n    _4789 = param_3.anisotropy;\n    _4790 = param_3.anisotropy_rotation;\n    _4791 = param_3.specular;\n    _4792 = param_3.ior;\n    _4793 = param_3.specular_color;\n    float3 param_4 = in.fa_world_pos;\n    float3 param_5 = _4739;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7, _365, fa_light_tex, fa_shadow_smp, fa_env_smp, fa_decal_tex);\n    _4778 = param_6;\n    _4780 = param_7;\n    float3 result;\n    if (_365.fa_emissive.w > 0.5)\n    {\n        result = _4778;\n    }\n    else\n    {\n        float3 _4420 = _4780;\n        float3 _4421 = fast::normalize(_4420);\n        _4780 = _4421;\n        float3 param_8 = _4421;\n        SurfaceInput param_9 = SurfaceInput{ in.fa_world_pos, _4739, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _4374, short(gl_FrontFacing) };\n        Surface param_10 = Surface{ _4778, _4779, _4780, _4781, _4782, _4783, _4784, _4785, _4786, _4787, _4788, _4789, _4790, _4791, _4792, _4793 };\n        float3 param_11 = fa_indirect_diffuse(param_8, _365, fa_env_smp, fa_irr_tex, in.fa_lm, fa_lightmap);\n        float3 lit = ambient(param_9, param_10, param_11, _365, fa_env_smp, fa_env_tex);\n        int _4440 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _4440; ln++)\n        {\n            int param_12 = ln;\n            int _4453 = fa_cl_light(param_12, _365, fa_light_tex, fa_shadow_smp, fa_cl_ndir, fa_cl_slot);\n            bool _4456 = in.fa_lm.z > 0.5;\n            bool _4462;\n            if (_4456)\n            {\n                int param_13 = _4453;\n                _4462 = fa_light_baked(param_13, _365, fa_light_tex, fa_shadow_smp);\n            }\n            else\n            {\n                _4462 = _4456;\n            }\n            if (_4462)\n            {\n                continue;\n            }\n            int param_14 = _4453;\n            float3 param_15 = in.fa_world_pos;\n            float3 param_16 = _4739;\n            LightSample _4474 = fa_light_shadowed(param_14, param_15, param_16, _365, fa_light_tex, fa_shadow_smp, fa_light_atlas, fa_env_smp, fa_light_tint, fa_light_is_area, gl_FragCoord, _2062, fa_shadow_tex, in.fa_world_pos, in.fa_lm);\n            SurfaceInput param_17 = SurfaceInput{ in.fa_world_pos, _4739, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _4374, short(gl_FrontFacing) };\n            Surface param_18 = Surface{ _4778, _4779, _4780, _4781, _4782, _4783, _4784, _4785, _4786, _4787, _4788, _4789, _4790, _4791, _4792, _4793 };\n            LightSample param_19 = _4474;\n            lit += light(param_17, param_18, param_19);\n        }\n        result = lit;\n    }\n    float3 _4489 = result;\n    float3 _4490 = _4489 + _4784;\n    result = _4490;\n    float3 param_20 = _4490;\n    float3 param_21 = in.fa_world_pos;\n    result = fa_shadow_debug(param_20, param_21, _2062);\n    bool _4499 = _365.fa_fog.w > 0.0;\n    bool _4506;\n    if (!_4499)\n    {\n        _4506 = _365.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _4506 = _4499;\n    }\n    if (_4506)\n    {\n        float3 _4515 = in.fa_world_pos - _365.fa_camera_pos.xyz;\n        float _4521 = dot(_4515, _365.fa_fog_c.xyz);\n        bool _4525 = _365.fa_fog_c.w > 0.5;\n        float _4526;\n        if (_4525)\n        {\n            _4526 = _4521;\n        }\n        else\n        {\n            _4526 = length(_4515);\n        }\n        float _4538 = _4526 - _365.fa_fog_b.x;\n        if (_4538 > 0.0)\n        {\n            float _4547 = _365.fa_fog.w * _4538;\n            float tau = _4547 * _4547;\n            if (_365.fa_fog_b.y > 0.0)\n            {\n                float _4563;\n                if (_4525)\n                {\n                    _4563 = in.fa_world_pos.y - (_365.fa_fog_c.y * _4521);\n                }\n                else\n                {\n                    _4563 = _365.fa_camera_pos.y;\n                }\n                float _4584 = mix(_4563, in.fa_world_pos.y, fast::clamp(_365.fa_fog_b.x / _4526, 0.0, 1.0));\n                float _4588 = in.fa_world_pos.y - _4584;\n                float _4593 = _4584 - _365.fa_fog_b.z;\n                float _4598 = in.fa_world_pos.y - _365.fa_fog_b.z;\n                bool _4601 = _4593 <= 0.0;\n                bool _4602 = !_4601;\n                bool _4608;\n                if (_4602)\n                {\n                    _4608 = _365.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4608 = _4601;\n                }\n                float _4609;\n                if (_4608)\n                {\n                    _4609 = _365.fa_fog_b.y;\n                }\n                else\n                {\n                    _4609 = _365.fa_fog_b.y * exp(-fast::min(_365.fa_fog_b.w * _4593, 80.0));\n                }\n                bool _4636;\n                if (_4602)\n                {\n                    _4636 = _365.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4636 = _4601;\n                }\n                float _4637;\n                if (_4636)\n                {\n                    _4637 = _365.fa_fog_b.y * _4593;\n                }\n                else\n                {\n                    _4637 = (_365.fa_fog_b.y * (1.0 - exp(-fast::min(_365.fa_fog_b.w * _4593, 80.0)))) / _365.fa_fog_b.w;\n                }\n                bool _4662 = _4598 <= 0.0;\n                bool _4669;\n                if (!_4662)\n                {\n                    _4669 = _365.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4669 = _4662;\n                }\n                float _4670;\n                if (_4669)\n                {\n                    _4670 = _365.fa_fog_b.y * _4598;\n                }\n                else\n                {\n                    _4670 = (_365.fa_fog_b.y * (1.0 - exp(-fast::min(_365.fa_fog_b.w * _4598, 80.0)))) / _365.fa_fog_b.w;\n                }\n                float _4697;\n                if (abs(_4588) < 0.001000000047497451305389404296875)\n                {\n                    _4697 = _4609;\n                }\n                else\n                {\n                    _4697 = (_4670 - _4637) / _4588;\n                }\n                tau += (_4538 * fast::max(_4697, 0.0));\n            }\n            result = mix(result, _365.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _4779);\n    return out;\n}\n\n",
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
            "inst_name": "_365",
            "msl_buffer_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2062",
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
          },
          {
            "texture": {
              "slot": 25,
              "stage": "fragment",
              "name": "fa_light_atlas",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 9
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
              "msl_texture_n": 10
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
            "name": "fa_irr_tex_fa_env_smp",
            "view_name": "fa_irr_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 15,
            "sampler_slot": 10
          },
          {
            "slot": 9,
            "stage": "fragment",
            "name": "fa_env_tex_fa_env_smp",
            "view_name": "fa_env_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10
          },
          {
            "slot": 10,
            "stage": "fragment",
            "name": "fa_light_atlas_fa_env_smp",
            "view_name": "fa_light_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 25,
            "sampler_slot": 10
          },
          {
            "slot": 11,
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
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n#pragma clang diagnostic ignored \"-Wmissing-braces\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\ntemplate<typename T, size_t Num>\nstruct spvUnsafeArray\n{\n    T elements[Num ? Num : 1];\n    \n    thread T& operator [] (size_t pos) thread\n    {\n        return elements[pos];\n    }\n    constexpr const thread T& operator [] (size_t pos) const thread\n    {\n        return elements[pos];\n    }\n    \n    device T& operator [] (size_t pos) device\n    {\n        return elements[pos];\n    }\n    constexpr const device T& operator [] (size_t pos) const device\n    {\n        return elements[pos];\n    }\n    \n    constexpr const constant T& operator [] (size_t pos) const constant\n    {\n        return elements[pos];\n    }\n    \n    threadgroup T& operator [] (size_t pos) threadgroup\n    {\n        return elements[pos];\n    }\n    constexpr const threadgroup T& operator [] (size_t pos) const threadgroup\n    {\n        return elements[pos];\n    }\n};\n\n// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()\ntemplate<typename Tx, typename Ty>\ninline Tx mod(Tx x, Ty y)\n{\n    return x - y * floor(x / y);\n}\n\nstruct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    short front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\nstruct FaLayers\n{\n    short on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    short sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstruct fa_mesh_fs_params\n{\n    float4 fa_camera_pos;\n    float4 fa_ambient;\n    float4 fa_base_color;\n    float4 fa_emissive;\n    float4 fa_model_emissive;\n    float4 fa_pbr;\n    float4 fa_maps;\n    float4 fa_fog;\n    float4 fa_fog_b;\n    float4 fa_fog_c;\n    float4 fa_counts;\n    float4 fa_env_sky;\n    float4 fa_env_horizon;\n    float4 fa_time;\n    float4 fa_cl_vpx;\n    float4 fa_cl_vpy;\n    float4 fa_cl_vpw;\n    float4 fa_cl_fwd;\n    float4 fa_cl_grid;\n    float4 fa_cl_info;\n    float4 fa_layers_a;\n    float4 fa_layers_b;\n    float4 fa_layers_c;\n    float4 fa_layers_d;\n};\n\nstruct fa_shadows\n{\n    float4x4 fa_shadow_mat[4];\n    float4 fa_shadow_rect[4];\n    float4 fa_shadow_info[4];\n    float4 fa_shadow_split;\n    float4 fa_shadow_cfg;\n    float4 fa_shadow_bias;\n    float4 fa_shadow_eye;\n    float4 fa_shadow_fwd;\n    float4 fa_shadow_lcfg;\n};\n\nconstant spvUnsafeArray<float, 63> _3356 = spvUnsafeArray<float, 63>({ 1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875 });\n\nstruct main0_out\n{\n    float4 fa_frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float3 fa_world_pos [[user(locn0)]];\n    float3 fa_world_normal [[user(locn1)]];\n    float4 fa_world_tangent [[user(locn2)]];\n    float2 fa_uv [[user(locn3)]];\n    float4 fa_vertex_color [[user(locn4)]];\n    float3 fa_lm [[user(locn5)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_light_texel(thread const int& t, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    return fa_light_tex.read(uint2(int2(t & 1023, t >> 10)), 0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_cluster_texel(thread const float3& world_pos, constant fa_mesh_fs_params& _365, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    bool _1333 = _365.fa_cl_info.x < 0.0;\n    bool _1340;\n    if (!_1333)\n    {\n        _1340 = _365.fa_cl_info.w < 1.0;\n    }\n    else\n    {\n        _1340 = _1333;\n    }\n    bool _1348;\n    if (!_1340)\n    {\n        _1348 = _365.fa_cl_grid.x < 1.0;\n    }\n    else\n    {\n        _1348 = _1340;\n    }\n    bool _1355;\n    if (!_1348)\n    {\n        _1355 = _365.fa_cl_grid.y < 1.0;\n    }\n    else\n    {\n        _1355 = _1348;\n    }\n    bool _1362;\n    if (!_1355)\n    {\n        _1362 = _365.fa_cl_info.y < 1.0;\n    }\n    else\n    {\n        _1362 = _1355;\n    }\n    if (_1362)\n    {\n        return float4(0.0);\n    }\n    float4 _1372 = float4(world_pos, 1.0);\n    float _1378 = dot(_365.fa_cl_vpw, _1372);\n    if (!(_1378 > 9.9999999747524270787835121154785e-07))\n    {\n        return float4(0.0);\n    }\n    float2 _1400 = float2(dot(_365.fa_cl_vpx, _1372), dot(_365.fa_cl_vpy, _1372)) / float2(_1378);\n    int _1404 = int(_365.fa_cl_grid.x);\n    int _1408 = int(_365.fa_cl_grid.y);\n    int param = (int(_365.fa_cl_info.x) + (((clamp(int(floor(log2(fast::max(dot(_365.fa_cl_fwd.xyz, world_pos) + _365.fa_cl_fwd.w, _365.fa_cl_grid.w) / _365.fa_cl_grid.w) * _365.fa_cl_grid.z)), 0, int(_365.fa_cl_info.y) - 1) * _1408) + clamp(int(floor(((_1400.y * 0.5) + 0.5) * _365.fa_cl_grid.y)), 0, _1408 - 1)) * _1404)) + clamp(int(floor(((_1400.x * 0.5) + 0.5) * _365.fa_cl_grid.x)), 0, _1404 - 1);\n    return fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nint2 fa_cluster_lookup(thread const float3& world_pos, constant fa_mesh_fs_params& _365, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    float3 param = world_pos;\n    float4 _1484 = fa_cluster_texel(param, _365, fa_light_tex, fa_shadow_smp);\n    return int2(int(_1484.x), int(_1484.y));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cluster_begin(thread const float3& world_pos, constant fa_mesh_fs_params& _365, texture2d<float> fa_light_tex, sampler fa_shadow_smp, thread int& fa_cl_ndir, thread int& fa_cl_slot, thread int& fa_cl_local)\n{\n    fa_cl_ndir = int(_365.fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _3888 = fa_cluster_lookup(param, _365, fa_light_tex, fa_shadow_smp);\n    fa_cl_slot = _3888.x;\n    fa_cl_local = _3888.y;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_fix_of(thread const float& _packed, thread const float& scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _4044 = fa_linear_to_srgb(param);\n        c = _4044;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _4052 = fa_srgb_to_linear(param_1);\n            c = _4052;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tangent_normal(thread const SurfaceInput& i, thread const float3& m)\n{\n    float3 _297;\n    if (bool(i.front_facing))\n    {\n        _297 = i.world_normal;\n    }\n    else\n    {\n        _297 = -i.world_normal;\n    }\n    float3 _321 = fast::normalize(i.world_tangent.xyz - (_297 * dot(_297, i.world_tangent.xyz)));\n    float3 _349 = fast::normalize(((_321 * m.x) + ((cross(_297, _321) * i.world_tangent.w) * m.y)) + (_297 * m.z));\n    float3 _352;\n    if (bool(i.front_facing))\n    {\n        _352 = _349;\n    }\n    else\n    {\n        _352 = -_349;\n    }\n    return _352;\n}\n\nstatic inline __attribute__((always_inline))\nSurface fa_standard_surface(thread const SurfaceInput& i, constant fa_mesh_fs_params& _365, texture2d<float> fa_tex, sampler fa_smp, texture2d<float> fa_normal_tex, texture2d<float> fa_mr_tex, texture2d<float> fa_occlusion_tex, texture2d<float> fa_emissive_tex)\n{\n    float4 base_t = fa_tex.sample(fa_smp, i.uv);\n    float param = _365.fa_maps.w;\n    float param_1 = 1.0;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _4083 = fa_tex_fix(param_2, param_3);\n    float4 _5198 = base_t;\n    _5198.x = _4083.x;\n    _5198.y = _4083.y;\n    _5198.z = _4083.z;\n    base_t = _5198;\n    float4 _4097 = (_5198 * _365.fa_base_color) * i.vertex_color;\n    float3 _5050 = i.world_normal;\n    if (_365.fa_maps.z > 0.5)\n    {\n        float param_4 = _365.fa_maps.w;\n        float param_5 = 16.0;\n        float3 param_6 = fa_normal_tex.sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _4129 = fa_tex_fix(param_6, param_7);\n        float3 _4132 = (_4129 * 2.0) - float3(1.0);\n        float2 _4137 = _4132.xy * _365.fa_maps.x;\n        float3 _5206 = _4132;\n        _5206.x = _4137.x;\n        _5206.y = _4137.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _5206;\n        _5050 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.sample(fa_smp, i.uv);\n    float param_10 = _365.fa_maps.w;\n    float param_11 = 64.0;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _4165 = fa_tex_fix(param_12, param_13);\n    float4 _5209 = mrt;\n    _5209.x = _4165.x;\n    _5209.y = _4165.y;\n    _5209.z = _4165.z;\n    mrt = _5209;\n    float4 _4193 = fa_occlusion_tex.sample(fa_smp, i.uv);\n    float param_14 = _365.fa_maps.w;\n    float param_15 = 256.0;\n    float3 param_16 = _4193.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _4204 = fa_tex_fix(param_16, param_17);\n    float param_18 = _365.fa_maps.w;\n    float param_19 = 4.0;\n    float3 param_20 = fa_emissive_tex.sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _4234 = fa_tex_fix(param_20, param_21);\n    float _5055 = _365.fa_layers_a.x;\n    float _5056 = _365.fa_layers_a.y;\n    float _5059 = _365.fa_layers_a.z;\n    float _5058 = _365.fa_layers_b.w;\n    float _5061 = _365.fa_layers_c.x;\n    if (_365.fa_layers_c.z > 0.5)\n    {\n        if (mod(_365.fa_layers_c.z, 2.0) > 0.5)\n        {\n            _5055 *= _4204.y;\n            _5056 *= _4204.z;\n            _5058 *= _4193.w;\n        }\n        if (_365.fa_layers_c.z > 1.5)\n        {\n            _5059 *= mrt.x;\n            _5061 *= mrt.w;\n        }\n    }\n    return Surface{ _4097.xyz, _4097.w, _5050, fast::clamp(_365.fa_pbr.x * _4165.z, 0.0, 1.0), fast::clamp(_365.fa_pbr.y * _4165.y, 0.0500000007450580596923828125, 1.0), 1.0 + (_365.fa_maps.y * (_4204.x - 1.0)), _365.fa_emissive.xyz + (_365.fa_model_emissive.xyz * _4234), _5055, _5056, _365.fa_layers_b.xyz, _5058, _5059, _365.fa_layers_a.w, _5061, _365.fa_layers_c.y, _365.fa_layers_d.xyz };\n}\n\nstatic inline __attribute__((always_inline))\nvoid surface(thread const SurfaceInput& i, thread const Surface& s)\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_decal_tile(thread const float4& rect, thread const float2& uv, thread const float2& atlas, thread const float2& ddx, thread const float2& ddy, sampler fa_env_smp, texture2d<float> fa_decal_tex)\n{\n    float2 _1564 = rect.zw - rect.xy;\n    float2 _1568 = _1564 * atlas;\n    float2 _1572 = ddx * _1568;\n    float2 _1576 = ddy * _1568;\n    return fa_decal_tex.sample(fa_env_smp, (rect.xy + (fast::clamp(uv, float2(0.0), float2(1.0)) * _1564)), level(fast::clamp(0.5 * log2(fast::max(fast::max(dot(_1572, _1572), dot(_1576, _1576)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_dc_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_apply_decals(thread const float3& world_pos, thread const float3& geo_normal, thread float3& albedo, thread float3& normal, constant fa_mesh_fs_params& _365, texture2d<float> fa_light_tex, sampler fa_shadow_smp, sampler fa_env_smp, texture2d<float> fa_decal_tex)\n{\n    bool _1609 = _365.fa_counts.y < 0.5;\n    bool _1616;\n    if (!_1609)\n    {\n        _1616 = _365.fa_counts.w < 0.5;\n    }\n    else\n    {\n        _1616 = _1609;\n    }\n    if (_1616)\n    {\n        return;\n    }\n    float3 _1622 = dfdx(world_pos);\n    float3 _1625 = dfdy(world_pos);\n    float3 param = world_pos;\n    float4 _1629 = fa_cluster_texel(param, _365, fa_light_tex, fa_shadow_smp);\n    int _1633 = int(_1629.w);\n    if (_1633 < 1)\n    {\n        return;\n    }\n    int _1643 = int(_365.fa_counts.y + 0.5);\n    int param_1 = _1643;\n    float4 _1647 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    float2 _1650 = _1647.yz;\n    int _1654 = int(_1647.w);\n    int param_2 = _1643 + 1;\n    float4 _1659 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float _1660 = _1659.x;\n    int _1666 = int(_365.fa_counts.w + 0.5) - 1;\n    int _1670 = int(_1629.z);\n    float3 _1935;\n    for (int k = 0; k < _1633; k++)\n    {\n        int _1683 = _1670 + k;\n        int param_3 = _1654 + (_1683 >> 2);\n        int _1700 = (_1643 + 2) + (int(fa_light_texel(param_3, fa_light_tex, fa_shadow_smp)[_1683 & 3]) * 7);\n        int param_4 = _1700 + 6;\n        float4 _1705 = fa_light_texel(param_4, fa_light_tex, fa_shadow_smp);\n        if (((int(_1705.w + 0.5) >> _1666) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1700;\n        float4 _1720 = fa_light_texel(param_5, fa_light_tex, fa_shadow_smp);\n        int param_6 = _1700 + 1;\n        float4 _1725 = fa_light_texel(param_6, fa_light_tex, fa_shadow_smp);\n        int param_7 = _1700 + 2;\n        float4 _1730 = fa_light_texel(param_7, fa_light_tex, fa_shadow_smp);\n        float3 _1733 = _1720.xyz;\n        float _1738 = dot(_1733, world_pos) + _1720.w;\n        float3 _1740 = _1725.xyz;\n        float _1745 = dot(_1740, world_pos) + _1725.w;\n        float3 _1747 = _1730.xyz;\n        float _1752 = dot(_1747, world_pos) + _1730.w;\n        bool _1757 = abs(_1738) > 0.5;\n        bool _1765;\n        if (!_1757)\n        {\n            _1765 = abs(_1745) > 0.5;\n        }\n        else\n        {\n            _1765 = _1757;\n        }\n        bool _1773;\n        if (!_1765)\n        {\n            _1773 = abs(_1752) > 0.5;\n        }\n        else\n        {\n            _1773 = _1765;\n        }\n        if (_1773)\n        {\n            continue;\n        }\n        float _1788 = fast::clamp(dot(geo_normal, fast::normalize(_1747)) * _1705.z, 0.0, 1.0);\n        if (_1788 <= 0.0)\n        {\n            continue;\n        }\n        float _1808 = (fast::clamp((0.5 - abs(_1752)) * 10.0, 0.0, 1.0) * _1788) * _1705.x;\n        float2 _1816 = float2(_1738 + 0.5, 0.5 - _1745);\n        float2 _1826 = float2(dot(_1733, _1622), dot(_1740, _1622));\n        float2 _1836 = float2(dot(_1733, _1625), dot(_1740, _1625));\n        int param_8 = _1700 + 5;\n        float4 _1841 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n        int param_9 = _1700 + 3;\n        float4 _1846 = fa_light_texel(param_9, fa_light_tex, fa_shadow_smp);\n        int param_10 = _1700 + 4;\n        float4 _1851 = fa_light_texel(param_10, fa_light_tex, fa_shadow_smp);\n        float tex_a = 1.0;\n        float3 col = _1841.xyz;\n        bool _1861 = _1846.z > _1846.x;\n        if (_1861)\n        {\n            float4 param_11 = _1846;\n            float2 param_12 = _1816;\n            float2 param_13 = _1650;\n            float2 param_14 = _1826;\n            float2 param_15 = _1836;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15, fa_env_smp, fa_decal_tex);\n            if ((_1660 > 0.5) && (_1660 < 1.5))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1887 = fa_dc_to_linear(param_16);\n                float4 _5130 = tx;\n                _5130.x = _1887.x;\n                _5130.y = _1887.y;\n                _5130.z = _1887.z;\n                tx = _5130;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, float3(fast::clamp((_1808 * tex_a) * _1841.w, 0.0, 1.0)));\n        if (_1851.z > _1851.x)\n        {\n            float4 param_17 = _1851;\n            float2 param_18 = _1816;\n            float2 param_19 = _1650;\n            float2 param_20 = _1826;\n            float2 param_21 = _1836;\n            float4 _1931 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21, fa_env_smp, fa_decal_tex);\n            if (_1660 > 1.5)\n            {\n                float3 param_22 = _1931.xyz;\n                float3 _1941 = fa_dc_to_srgb(param_22);\n                _1935 = _1941;\n            }\n            else\n            {\n                _1935 = _1931.xyz;\n            }\n            float3 _1950 = (_1935 * 2.0) - float3(1.0);\n            float2 _1955 = _1950.xy * _1705.y;\n            float3 _1977 = (fast::normalize(_1733) * _1955.x) + (fast::normalize(_1740) * _1955.y);\n            float3 _1980 = fast::normalize(normal);\n            normal = fast::normalize(mix(_1980, fast::normalize((_1980 * fast::max(_1950.z, 0.0500000007450580596923828125)) + (_1977 - (_1980 * dot(_1980, _1977)))), float3(fast::clamp(_1808 * (_1861 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_ambient_light(thread const float3& n, constant fa_mesh_fs_params& _365, sampler fa_env_smp, texturecube<float> fa_irr_tex)\n{\n    if (_365.fa_env_sky.w > 0.5)\n    {\n        return fa_irr_tex.sample(fa_env_smp, n, level(0.0)).xyz;\n    }\n    return _365.fa_ambient.xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_indirect_diffuse(thread const float3& n, constant fa_mesh_fs_params& _365, sampler fa_env_smp, texturecube<float> fa_irr_tex, thread float3& fa_lm, texture2d<float> fa_lightmap)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return fa_lightmap.sample(fa_env_smp, fa_lm.xy, level(0.0)).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param, _365, fa_env_smp, fa_irr_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_sheen_albedo(thread const float& ndv, thread const float& rough)\n{\n    float _3281 = fast::min(sqrt(fast::max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _3289 = fast::min(sqrt(fast::clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _3292 = int(_3281);\n    int _3295 = int(_3289);\n    float _3305 = _3289 - float(_3295);\n    int _3361 = (_3292 * 9) + _3295;\n    int _3381 = ((_3292 + 1) * 9) + _3295;\n    return mix(mix(_3356[_3361], _3356[_3361 + 1], _3305), mix(_3356[_3381], _3356[_3381 + 1], _3305), _3281 - float(_3292));\n}\n\nstatic inline __attribute__((always_inline))\nFaLayers fa_layers_setup(thread const SurfaceInput& i, thread const Surface& s, thread const float3& n, thread const float3& v, thread const float& metallic, thread const float& roughness, thread float3& f0)\n{\n    bool _4909 = false;\n    float _4910 = 1.0;\n    float _4911 = 1.0;\n    float _4912 = 1.0;\n    float _4913 = 0.0;\n    float _4914 = 0.0;\n    float _4915 = 0.0;\n    float _4916 = 0.0;\n    float _4918 = 1.0;\n    bool _4919 = false;\n    float3 _4920 = float3(0.0);\n    float _4921 = 1.0;\n    float _4922 = 1.0;\n    float _4923 = 1.0;\n    float _4924 = 0.0;\n    float _4925 = 0.0;\n    float3 _4926 = float3(1.0, 0.0, 0.0);\n    float3 _4927 = float3(0.0, 0.0, 1.0);\n    float _4928 = 1.0;\n    float _4929 = 1.0;\n    float _3432 = fast::clamp(s.specular, 0.0, 1.0);\n    float _3436 = fast::clamp(s.ior, 1.0, 3.0);\n    bool _3441 = (_3432 != 1.0) || (_3436 != 1.5);\n    bool _3450;\n    if (!_3441)\n    {\n        _3450 = any(s.specular_color != float3(1.0));\n    }\n    else\n    {\n        _3450 = _3441;\n    }\n    if (_3450)\n    {\n        float _3458 = (_3436 - 1.0) / (_3436 + 1.0);\n        f0 = mix(fast::min(float3(_3458 * _3458) * fast::max(s.specular_color, float3(0.0)), float3(1.0)) * _3432, s.albedo, float3(metallic));\n        _4910 = mix(_3432, 1.0, metallic);\n        _4909 = true;\n    }\n    float _3485 = fast::clamp(s.clearcoat, 0.0, 1.0);\n    if (_3485 > 0.0)\n    {\n        float _3493 = fast::clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _4913 = _3485;\n        _4914 = _3493;\n        float _3500 = _3493 * _3493;\n        _4915 = _3500;\n        _4916 = _3500 * _3500;\n        float _3512 = fast::max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _4918 = _3512;\n        _4911 = 1.0 - (_3485 * (0.039999999105930328369140625 + (0.959999978542327880859375 * powr(fast::clamp(1.0 - _3512, 0.0, 1.0), 5.0))));\n        _4909 = true;\n    }\n    float3 _3532 = fast::max(s.sheen_color, float3(0.0));\n    float _3541 = fast::max(_3532.x, fast::max(_3532.y, _3532.z));\n    if (_3541 > 0.0)\n    {\n        float _3549 = fast::clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _4919 = true;\n        _4920 = _3532;\n        _4921 = _3549;\n        _4922 = _3549 * _3549;\n        float param = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _3549;\n        float _3566 = fa_sheen_albedo(param, param_1);\n        _4924 = _3566;\n        _4923 = 1.0 - fast::min(_3541 * _3566, 1.0);\n        _4909 = true;\n    }\n    _4912 = _4911 * _4923;\n    float _3585 = fast::clamp(s.anisotropy, -1.0, 1.0);\n    if (_3585 != 0.0)\n    {\n        float3 _3600 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _3600;\n        if (dot(_3600, _3600) < 9.9999999392252902907785028219223e-09)\n        {\n            t = cross(select(float3(1.0, 0.0, 0.0), float3(0.0, 1.0, 0.0), bool3(abs(n.y) < 0.9900000095367431640625)), n);\n        }\n        float3 _3616 = t;\n        float3 _3617 = fast::normalize(_3616);\n        t = _3617;\n        float3 _3642 = fast::normalize((_3617 * cos(s.anisotropy_rotation)) + ((cross(n, _3617) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _4926 = _3642;\n        _4927 = cross(n, _3642);\n        float _3652 = roughness * roughness;\n        float _3658 = mix(_3652, 1.0, _3585 * _3585);\n        bool _3660 = _3585 > 0.0;\n        _4928 = _3660 ? _3658 : _3652;\n        _4929 = _3660 ? _3652 : _3658;\n        _4925 = _3585;\n        _4909 = true;\n    }\n    return FaLayers{ short(_4909), _4910, _4911, _4912, _4913, _4914, _4915, _4916, i.world_normal, _4918, short(_4919), _4920, _4921, _4922, _4923, _4924, _4925, _4926, _4927, _4928, _4929 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_env_brdf(thread const float& rough, thread const float& ndv)\n{\n    float4 _3213 = (float4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + float4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _3216 = _3213.x;\n    return (float2(-1.03999996185302734375, 1.03999996185302734375) * ((fast::min(_3216 * _3216, exp2((-9.27999973297119140625) * ndv)) * _3216) + _3213.y)) + _3213.zw;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_environment(thread const float3& d, thread const float& rough, constant fa_mesh_fs_params& _365, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    if (_365.fa_env_sky.w > 0.5)\n    {\n        return fa_env_tex.sample(fa_env_smp, d, level(fast::clamp(rough, 0.0, 1.0) * _365.fa_env_horizon.w)).xyz;\n    }\n    float _3119 = rough * rough;\n    float _3149 = 0.60000002384185791015625 * _3119;\n    return mix(mix(_365.fa_env_horizon.xyz * 0.550000011920928955078125, mix(_365.fa_env_horizon.xyz, _365.fa_env_sky.xyz, float3(powr(fast::clamp(d.y * (1.0 - (0.699999988079071044921875 * _3119)), 0.0, 1.0), 0.550000011920928955078125))), float3(smoothstep((-0.0500000007450580596923828125) - _3149, 0.0500000007450580596923828125 + _3149, d.y))), ((_365.fa_env_sky.xyz + _365.fa_env_horizon.xyz) * 0.5) * 0.800000011920928955078125, float3(_3119 * 0.60000002384185791015625));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_layers_ibl(thread const FaLayers& L, thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _365, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        float3 _3693;\n        if (L.aniso >= 0.0)\n        {\n            _3693 = L.b;\n        }\n        else\n        {\n            _3693 = L.t;\n        }\n        rn = fast::normalize(mix(n, cross(cross(_3693, v), _3693), float3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _3726 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3, _365, fa_env_smp, fa_env_tex) * ((f0 * _3726.x) + (float3(L.f90) * _3726.y))) * L.base_scale;\n    if (bool(L.sheen_on))\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5, _365, fa_env_smp, fa_env_tex));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _3781 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9, _365, fa_env_smp, fa_env_tex) * (L.coat * ((0.039999999105930328369140625 * _3781.x) + _3781.y)));\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_reflection(thread const float3& n, thread const float3& v, thread const float3& f0, thread const float& roughness, constant fa_mesh_fs_params& _365, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float param = roughness;\n    float param_1 = fast::max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    float2 _3255 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3, _365, fa_env_smp, fa_env_tex) * ((f0 * _3255.x) + float3(_3255.y));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_sky_light(thread const SurfaceInput& i, thread const Surface& s, constant fa_mesh_fs_params& _365, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    float _3810 = fast::clamp(s.metallic, 0.0, 1.0);\n    float _3814 = fast::clamp(s.roughness, 0.0500000007450580596923828125, 1.0);\n    float3 _3821 = mix(float3(0.039999999105930328369140625), s.albedo, float3(_3810));\n    float3 f0 = _3821;\n    float3 _3825 = fast::normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    float3 param_2 = _3825;\n    float3 param_3 = i.view_dir;\n    float param_4 = _3810;\n    float param_5 = _3814;\n    float3 param_6 = _3821;\n    FaLayers _3842 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_3842.on)\n    {\n        FaLayers param_7 = _3842;\n        float3 param_8 = _3825;\n        float3 param_9 = i.view_dir;\n        float3 param_10 = f0;\n        float param_11 = _3814;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11, _365, fa_env_smp, fa_env_tex) * s.occlusion;\n    }\n    float3 param_12 = _3825;\n    float3 param_13 = i.view_dir;\n    float3 param_14 = f0;\n    float param_15 = _3814;\n    return fa_sky_reflection(param_12, param_13, param_14, param_15, _365, fa_env_smp, fa_env_tex) * s.occlusion;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 ambient(thread const SurfaceInput& i, thread const Surface& s, thread const float3& ambientColor, constant fa_mesh_fs_params& _365, sampler fa_env_smp, texturecube<float> fa_env_tex)\n{\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    return fa_sky_light(param, param_1, _365, fa_env_smp, fa_env_tex);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cluster_index(thread const int& slot, thread const int& n, constant fa_mesh_fs_params& _365, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = (int(_365.fa_cl_info.x) + int(_365.fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    return int(t[(slot + n) & 3]);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cl_light(thread const int& n, constant fa_mesh_fs_params& _365, texture2d<float> fa_light_tex, sampler fa_shadow_smp, thread int& fa_cl_ndir, thread int& fa_cl_slot)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1, _365, fa_light_tex, fa_shadow_smp);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_light_base(thread const int& li, constant fa_mesh_fs_params& _365)\n{\n    return li * ((_365.fa_ambient.w > 4.5) ? 8 : 4);\n}\n\nstatic inline __attribute__((always_inline))\nbool fa_light_baked(thread const int& li, constant fa_mesh_fs_params& _365, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li;\n    int param_1 = fa_light_base(param, _365) + 3;\n    return fa_light_texel(param_1, fa_light_tex, fa_shadow_smp).w > 0.5;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_light_type(thread const int& li, constant fa_mesh_fs_params& _365, texture2d<float> fa_light_tex, sampler fa_shadow_smp)\n{\n    int param = li;\n    int param_1 = fa_light_base(param, _365) + 1;\n    return fa_light_texel(param_1, fa_light_tex, fa_shadow_smp).w;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_atlas_fetch(thread const float2& texel, texture2d<float> fa_light_atlas, sampler fa_env_smp)\n{\n    return fa_light_atlas.sample(fa_env_smp, (texel / float2(int2(fa_light_atlas.get_width(), fa_light_atlas.get_height()))), level(0.0));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_cookie_sample(thread const float2& tile_origin, thread const float2& uv, texture2d<float> fa_light_atlas, sampler fa_env_smp)\n{\n    float2 param = (tile_origin + float2(1.0)) + (fast::clamp(uv, float2(0.0), float2(1.0)) * 254.0);\n    return fa_atlas_fetch(param, fa_light_atlas, fa_env_smp).xyz;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_area_point(thread const float3& c, thread const float3& axis, thread const float3& ru, thread const float3& uu, thread const float& hx, thread const float& hy, thread const float& shape, thread const float3& p, thread const float3& r)\n{\n    bool _593 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        float3 _606 = (c - (ru * hx)) - p;\n        float3 _612 = ru * (2.0 * hx);\n        float _618 = fast::max(dot(_612, _612), 9.9999999392252902907785028219223e-09);\n        float _622 = dot(_606, _612);\n        float t = fast::clamp((-_622) / _618, 0.0, 1.0);\n        if (_593)\n        {\n            float _637 = dot(r, _612);\n            float _643 = _618 - (_637 * _637);\n            if (abs(_643) > (9.9999997473787516355514526367188e-06 * _618))\n            {\n                t = fast::clamp(((dot(r, _606) * _637) - _622) / _643, 0.0, 1.0);\n            }\n        }\n        return (p + _606) + (_612 * t);\n    }\n    float3 q = p;\n    float _675 = dot(r, axis);\n    bool _683;\n    if (_593)\n    {\n        _683 = abs(_675) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _683 = _593;\n    }\n    if (_683)\n    {\n        float _693 = dot(c - p, axis) / _675;\n        if (_693 > 0.0)\n        {\n            q = p + (r * _693);\n        }\n    }\n    float3 _706 = q - c;\n    float2 xy = float2(dot(_706, ru), dot(_706, uu));\n    if (shape > 0.5)\n    {\n        float _721 = length(xy);\n        if (_721 > hx)\n        {\n            xy *= (hx / _721);\n        }\n    }\n    else\n    {\n        xy = fast::clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nstatic inline __attribute__((always_inline))\nint fa_cube_face(thread const float3& d)\n{\n    float3 _514 = abs(d);\n    float _516 = _514.x;\n    float _518 = _514.y;\n    bool _519 = _516 >= _518;\n    bool _527;\n    if (_519)\n    {\n        _527 = _516 >= _514.z;\n    }\n    else\n    {\n        _527 = _519;\n    }\n    int _528;\n    if (_527)\n    {\n        _528 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _541;\n        if (_518 >= _514.z)\n        {\n            _541 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _541 = (d.z > 0.0) ? 4 : 5;\n        }\n        _528 = _541;\n    }\n    return _528;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_cube_face_basis(thread const int& f, thread float3& fwd, thread float3& up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0, 0.0, 0.0);\n        up = float3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0, 0.0, 0.0);\n            up = float3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0, 1.0, 0.0);\n                up = float3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0, -1.0, 0.0);\n                    up = float3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0, 0.0, 1.0);\n                        up = float3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0, 0.0, -1.0);\n                        up = float3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_ies_sample(thread const float2& tile_origin, thread const float3& d, thread const float3& axis, thread const float3& right, thread const float3& up, texture2d<float> fa_light_atlas, sampler fa_env_smp)\n{\n    float _467 = dot(d, right);\n    float _471 = dot(d, up);\n    float _482;\n    if (((_467 * _467) + (_471 * _471)) > 1.0000000133514319600180897396058e-10)\n    {\n        _482 = precise::atan2(_471, _467) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _482 = 0.0;\n    }\n    float2 param = tile_origin + float2(1.0 + ((_482 - floor(_482)) * 64.0), 1.0 + (acos(fast::clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param, fa_light_atlas, fa_env_smp).x;\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_sample_n(thread const int& li, thread const float3& world_pos, thread const float3& n, constant fa_mesh_fs_params& _365, texture2d<float> fa_light_tex, sampler fa_shadow_smp, texture2d<float> fa_light_atlas, sampler fa_env_smp, thread float3& fa_light_tint, thread bool& fa_light_is_area)\n{\n    int param = li;\n    int _759 = fa_light_base(param, _365);\n    bool _763 = _365.fa_ambient.w > 4.5;\n    int param_1 = _759;\n    float4 _767 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    int param_2 = _759 + 1;\n    float4 _772 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float _775 = _772.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = float3(1.0);\n    bool _787 = _763 && (_775 > 2.5);\n    fa_light_is_area = _787;\n    bool _789 = _775 < 0.5;\n    float3 l;\n    if (_789)\n    {\n        l = fast::normalize(_767.xyz);\n        if (_763)\n        {\n            int param_3 = _759 + 6;\n            float4 _803 = fa_light_texel(param_3, fa_light_tex, fa_shadow_smp);\n            if (_803.z > 0.5)\n            {\n                int param_4 = _759 + 4;\n                float4 _813 = fa_light_texel(param_4, fa_light_tex, fa_shadow_smp);\n                int param_5 = _759 + 5;\n                float4 _818 = fa_light_texel(param_5, fa_light_tex, fa_shadow_smp);\n                float2 param_6 = _803.xy;\n                float2 param_7 = fract(float2(dot(world_pos, _813.xyz) * _813.w, (-dot(world_pos, _818.xyz)) * _818.w) + float2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7, fa_light_atlas, fa_env_smp);\n            }\n        }\n    }\n    else\n    {\n        float3 _848 = _767.xyz;\n        float3 _850 = _848 - world_pos;\n        float3 to_light = _850;\n        float _853 = length(_850);\n        float reach = _853;\n        bool front = true;\n        if (_787)\n        {\n            int param_8 = _759 + 7;\n            reach = fast::max(_853 - fa_light_texel(param_8, fa_light_tex, fa_shadow_smp).w, 0.0);\n            int param_9 = _759 + 4;\n            float4 _877 = fa_light_texel(param_9, fa_light_tex, fa_shadow_smp);\n            int param_10 = _759 + 5;\n            float4 _882 = fa_light_texel(param_10, fa_light_tex, fa_shadow_smp);\n            int param_11 = _759 + 6;\n            float4 _887 = fa_light_texel(param_11, fa_light_tex, fa_shadow_smp);\n            float _888 = _887.w;\n            int param_12 = _759 + 2;\n            float3 _895 = fast::normalize(fa_light_texel(param_12, fa_light_tex, fa_shadow_smp).xyz);\n            bool _897 = _888 > 1.5;\n            bool _905;\n            if (!_897)\n            {\n                _905 = dot(_895, to_light) < 0.0;\n            }\n            else\n            {\n                _905 = _897;\n            }\n            front = _905;\n            float3 r = float3(0.0);\n            if (dot(n, n) > 0.5)\n            {\n                r = reflect(-fast::normalize(_365.fa_camera_pos.xyz - world_pos), fast::normalize(n));\n            }\n            float3 param_13 = _848;\n            float3 param_14 = _895;\n            float3 param_15 = _877.xyz;\n            float3 param_16 = _882.xyz;\n            float param_17 = _877.w;\n            float param_18 = _882.w;\n            float param_19 = _888;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _952 = length(to_light);\n        dist = _952;\n        l = to_light / float3(fast::max(_952, 9.9999997473787516355514526367188e-05));\n        float _966 = reach / fast::max(_767.w, 0.001000000047497451305389404296875);\n        float _972 = fast::clamp(1.0 - (_966 * _966), 0.0, 1.0);\n        float _974;\n        if (front)\n        {\n            _974 = _972 * _972;\n        }\n        else\n        {\n            _974 = 0.0;\n        }\n        atten = _974;\n        bool _985 = _775 < 2.5;\n        if ((_775 > 1.5) && _985)\n        {\n            int param_22 = _759 + 2;\n            float4 _993 = fa_light_texel(param_22, fa_light_tex, fa_shadow_smp);\n            float _1003 = _993.w;\n            int param_23 = _759 + 3;\n            float4 _1008 = fa_light_texel(param_23, fa_light_tex, fa_shadow_smp);\n            float _1009 = _1008.x;\n            float cos_inner = _1009;\n            if (_1009 > 1.5)\n            {\n                cos_inner = mix(_1003, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1003, cos_inner, dot(-l, fast::normalize(_993.xyz)));\n        }\n        if (_763 && (_775 < 1.5))\n        {\n            int param_24 = _759 + 6;\n            float4 _1033 = fa_light_texel(param_24, fa_light_tex, fa_shadow_smp);\n            if (_1033.z > 0.5)\n            {\n                float3 _1041 = -to_light;\n                int param_25 = _759 + 4;\n                int param_26 = _759 + 5;\n                float3 _1055 = fa_light_texel(param_25, fa_light_tex, fa_shadow_smp).xyz;\n                float3 _1059 = fa_light_texel(param_26, fa_light_tex, fa_shadow_smp).xyz;\n                float3 _1068 = float3(dot(_1041, _1055), dot(_1041, _1059), dot(_1041, cross(_1055, _1059)));\n                float3 param_27 = _1068;\n                int _1072 = fa_cube_face(param_27);\n                int param_28 = _1072;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1099 = float2(dot(_1068, cross(param_29, param_30)), dot(_1068, param_30)) / float2(fast::max(dot(_1068, param_29), 9.9999997473787516355514526367188e-05));\n                int _1103 = _1072 / 3;\n                float2 param_31 = _1033.xy + (float2(float(_1072 - (_1103 * 3)), float(_1103)) * 256.0);\n                float2 param_32 = float2(0.5 + (0.5 * _1099.x), 0.5 - (0.5 * _1099.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32, fa_light_atlas, fa_env_smp);\n            }\n            int param_33 = _759 + 7;\n            float4 _1133 = fa_light_texel(param_33, fa_light_tex, fa_shadow_smp);\n            if (_1133.z > 0.5)\n            {\n                int param_34 = _759 + 2;\n                int param_35 = _759 + 4;\n                int param_36 = _759 + 5;\n                float2 param_37 = _1133.xy;\n                float3 param_38 = -l;\n                float3 param_39 = fast::normalize(fa_light_texel(param_34, fa_light_tex, fa_shadow_smp).xyz);\n                float3 param_40 = fa_light_texel(param_35, fa_light_tex, fa_shadow_smp).xyz;\n                float3 param_41 = fa_light_texel(param_36, fa_light_tex, fa_shadow_smp).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41, fa_light_atlas, fa_env_smp);\n            }\n        }\n        else\n        {\n            if (_763 && _985)\n            {\n                int param_42 = _759 + 6;\n                float4 _1180 = fa_light_texel(param_42, fa_light_tex, fa_shadow_smp);\n                int param_43 = _759 + 7;\n                float4 _1185 = fa_light_texel(param_43, fa_light_tex, fa_shadow_smp);\n                bool _1188 = _1180.z > 0.5;\n                bool _1195;\n                if (!_1188)\n                {\n                    _1195 = _1185.z > 0.5;\n                }\n                else\n                {\n                    _1195 = _1188;\n                }\n                if (_1195)\n                {\n                    int param_44 = _759 + 2;\n                    float4 _1202 = fa_light_texel(param_44, fa_light_tex, fa_shadow_smp);\n                    float3 _1206 = fast::normalize(_1202.xyz);\n                    int param_45 = _759 + 4;\n                    float4 _1211 = fa_light_texel(param_45, fa_light_tex, fa_shadow_smp);\n                    int param_46 = _759 + 5;\n                    float4 _1216 = fa_light_texel(param_46, fa_light_tex, fa_shadow_smp);\n                    if (_1188)\n                    {\n                        float3 _1224 = -to_light;\n                        float _1231 = _1202.w;\n                        float _1247 = 0.5 / fast::max(dot(_1224, _1206) * (sqrt(fast::max(1.0 - (_1231 * _1231), 0.0)) / fast::max(_1231, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        float2 param_47 = _1180.xy;\n                        float2 param_48 = float2(0.5 + (dot(_1224, _1211.xyz) * _1247), 0.5 - (dot(_1224, _1216.xyz) * _1247));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48, fa_light_atlas, fa_env_smp);\n                    }\n                    if (_1185.z > 0.5)\n                    {\n                        float2 param_49 = _1185.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1206;\n                        float3 param_52 = _1211.xyz;\n                        float3 param_53 = _1216.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53, fa_light_atlas, fa_env_smp);\n                    }\n                }\n            }\n        }\n    }\n    float3 _4897 = _772.xyz * atten;\n    if (_763)\n    {\n        _4897 *= fa_light_tint;\n    }\n    int _1315;\n    if (_789)\n    {\n        _1315 = 0;\n    }\n    else\n    {\n        _1315 = ((_775 > 1.5) && (_775 < 2.5)) ? 2 : 1;\n    }\n    return LightSample{ l, _4897, atten, 1.0, dist, _1315 };\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_split_at(thread const int& i, constant fa_shadows& _2062)\n{\n    float _2052;\n    if (i == 0)\n    {\n        _2052 = _2062.fa_shadow_split.x;\n    }\n    else\n    {\n        float _2068;\n        if (i == 1)\n        {\n            _2068 = _2062.fa_shadow_split.y;\n        }\n        else\n        {\n            float _2076;\n            if (i == 2)\n            {\n                _2076 = _2062.fa_shadow_split.z;\n            }\n            else\n            {\n                _2076 = _2062.fa_shadow_split.w;\n            }\n            _2068 = _2076;\n        }\n        _2052 = _2068;\n    }\n    return _2052;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_depth(thread float2& uv, thread const float4& rect, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    uv = fast::clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.sample(fa_shadow_smp, uv, level(0.0)).x;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_fetch(thread const float2& uv, thread const float4& rect, thread const float3& conv, sampler fa_shadow_smp, texture2d<float> fa_shadow_tex)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2109 = fa_shadow_depth(param, param_1, fa_shadow_smp, fa_shadow_tex);\n    float _2113;\n    if (conv.x < 0.5)\n    {\n        _2113 = _2109;\n    }\n    else\n    {\n        _2113 = (conv.y * conv.z) / (conv.z - (_2109 * (conv.z - conv.y)));\n    }\n    return _2113;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_noise(thread float4& gl_FragCoord)\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_shadow_vogel(thread const int& k, thread const int& n, thread const float& phi)\n{\n    float _2040 = (float(k) * 2.3999631404876708984375) + phi;\n    return float2(cos(_2040), sin(_2040)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_filter(thread const float2& uv, thread const float4& rect, thread const float& zr, thread const float& texel_m, thread const float& unit, thread const float& reach, thread const float& plane, thread const float3& conv, thread const int& mode, thread const float& k, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2062, texture2d<float> fa_shadow_tex)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2, fa_shadow_smp, fa_shadow_tex));\n    }\n    float _2159 = fa_shadow_noise(gl_FragCoord) * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2168;\n        if (k < 0.0)\n        {\n            _2168 = (-k) / fast::max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2168 = k;\n        }\n        float _2188 = fast::clamp((_2168 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2159;\n            float2 _2207 = fa_shadow_vogel(param_3, param_4, param_5) * _2188;\n            float2 param_6 = uv + (_2207 * _2062.fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _2219 = fa_shadow_fetch(param_6, param_7, param_8, fa_shadow_smp, fa_shadow_tex);\n            if (_2219 < (zr - (length(_2207) * plane)))\n            {\n                sum += _2219;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2245 = sum / cnt;\n        float _2255;\n        if (k < 0.0)\n        {\n            _2255 = (-k) / fast::max(_2245, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2255 = k;\n        }\n        radius = fast::clamp(((fast::max(zr - _2245, 0.0) * unit) * _2255) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _2277 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2277; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2277;\n        float param_11 = _2159;\n        float2 _2296 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_2296 * _2062.fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_2296) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14, fa_shadow_smp, fa_shadow_tex));\n    }\n    return lit / float(_2277);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_cascade(thread const int& ci, thread const float3& world, thread const float3& n, thread const float3& l, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2062, texture2d<float> fa_shadow_tex)\n{\n    float _2338 = fast::max(_2062.fa_shadow_info[ci].y, 0.001000000047497451305389404296875);\n    float _2343 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _2349 = sqrt(1.0 - (_2343 * _2343));\n    float _2356 = fast::min(_2349 / fast::max(_2343, 0.20000000298023223876953125), 4.0);\n    float _2361;\n    if (_2062.fa_shadow_bias.y > 0.0)\n    {\n        _2361 = _2062.fa_shadow_bias.y;\n    }\n    else\n    {\n        _2361 = 1.5 * _2062.fa_shadow_info[ci].x;\n    }\n    float4 _2386 = _2062.fa_shadow_mat[ci] * float4(world + (n * (_2361 * _2349)), 1.0);\n    float _2393 = _2386.x;\n    bool _2396 = _2393 < _2062.fa_shadow_rect[ci].x;\n    bool _2405;\n    if (!_2396)\n    {\n        _2405 = _2393 > _2062.fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2405 = _2396;\n    }\n    bool _2414;\n    if (!_2405)\n    {\n        _2414 = _2386.y < _2062.fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2414 = _2405;\n    }\n    bool _2423;\n    if (!_2414)\n    {\n        _2423 = _2386.y > _2062.fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2423 = _2414;\n    }\n    bool _2430;\n    if (!_2423)\n    {\n        _2430 = _2386.z > 1.0;\n    }\n    else\n    {\n        _2430 = _2423;\n    }\n    if (_2430)\n    {\n        return -1.0;\n    }\n    float _2438;\n    if (_2062.fa_shadow_bias.x > 0.0)\n    {\n        _2438 = _2062.fa_shadow_bias.x;\n    }\n    else\n    {\n        _2438 = 1.5 * _2062.fa_shadow_info[ci].x;\n    }\n    float2 param = _2386.xy;\n    float4 param_1 = _2062.fa_shadow_rect[ci];\n    float param_2 = _2386.z - ((_2438 * (1.0 + (0.5 * _2356))) / _2338);\n    float param_3 = _2062.fa_shadow_info[ci].x;\n    float param_4 = _2338;\n    float param_5 = _2338 * 0.25;\n    float param_6 = ((_2062.fa_shadow_info[ci].x * fast::min(_2356, 3.0)) * 0.5) / _2338;\n    float3 param_7 = float3(0.0);\n    int param_8 = int(_2062.fa_shadow_cfg.z + 0.5);\n    float param_9 = _2062.fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9, fa_shadow_smp, gl_FragCoord, _2062, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_sun(thread const float3& world, thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _365, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2062, texture2d<float> fa_shadow_tex)\n{\n    if (_365.fa_pbr.z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2826 = int(_2062.fa_shadow_cfg.x + 0.5);\n    if (_2826 < 1)\n    {\n        return 1.0;\n    }\n    float _2841 = dot(world - _2062.fa_shadow_eye.xyz, _2062.fa_shadow_fwd.xyz);\n    int param = _2826 - 1;\n    if (_2841 > fa_shadow_split_at(param, _2062))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2853 = _2826 > 1;\n    bool _2860;\n    if (_2853)\n    {\n        _2860 = _2841 > _2062.fa_shadow_split.x;\n    }\n    else\n    {\n        _2860 = _2853;\n    }\n    if (_2860)\n    {\n        ci = 1;\n    }\n    bool _2864 = _2826 > 2;\n    bool _2871;\n    if (_2864)\n    {\n        _2871 = _2841 > _2062.fa_shadow_split.y;\n    }\n    else\n    {\n        _2871 = _2864;\n    }\n    if (_2871)\n    {\n        ci = 2;\n    }\n    bool _2875 = _2826 > 3;\n    bool _2882;\n    if (_2875)\n    {\n        _2882 = _2841 > _2062.fa_shadow_split.z;\n    }\n    else\n    {\n        _2882 = _2875;\n    }\n    if (_2882)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2826)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2908 = fa_shadow_cascade(param_1, param_2, param_3, param_4, fa_shadow_smp, gl_FragCoord, _2062, fa_shadow_tex);\n        s = _2908;\n        if (_2908 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (_2062.fa_shadow_cfg.y > 0.0)\n    {\n        float _2933;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2933 = fa_shadow_split_at(param_5, _2062);\n        }\n        else\n        {\n            _2933 = _2062.fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _2952 = _2062.fa_shadow_cfg.y * fast::max(fa_shadow_split_at(param_6, _2062) - _2933, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2963 = fast::clamp((_2841 - (fa_shadow_split_at(param_7, _2062) - _2952)) / _2952, 0.0, 1.0);\n        if (_2963 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2826)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _2984 = fa_shadow_cascade(param_8, param_9, param_10, param_11, fa_shadow_smp, gl_FragCoord, _2062, fa_shadow_tex);\n                s2 = _2984;\n                if (_2984 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2963);\n        }\n    }\n    return s;\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_factor(thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _365, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2062, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2, _365, fa_shadow_smp, gl_FragCoord, _2062, fa_shadow_tex);\n}\n\nstatic inline __attribute__((always_inline))\nfloat fa_shadow_local(thread const int& li, thread const float3& world, thread const float3& n, thread const float3& l, constant fa_mesh_fs_params& _365, texture2d<float> fa_light_tex, sampler fa_shadow_smp, thread float4& gl_FragCoord, constant fa_shadows& _2062, texture2d<float> fa_shadow_tex)\n{\n    bool _2496 = _365.fa_pbr.z < 0.5;\n    bool _2503;\n    if (!_2496)\n    {\n        _2503 = _2062.fa_shadow_lcfg.x < 0.5;\n    }\n    else\n    {\n        _2503 = _2496;\n    }\n    if (_2503)\n    {\n        return 1.0;\n    }\n    int param = (int(_2062.fa_shadow_lcfg.x + 0.5) - 1) + li;\n    float4 _2516 = fa_light_texel(param, fa_light_tex, fa_shadow_smp);\n    float _2517 = _2516.x;\n    if (_2517 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2526 = int(_2517 + 0.5);\n    int param_1 = _2526;\n    float4 _2530 = fa_light_texel(param_1, fa_light_tex, fa_shadow_smp);\n    int param_2 = _2526 + 1;\n    float4 _2535 = fa_light_texel(param_2, fa_light_tex, fa_shadow_smp);\n    float fade = 1.0;\n    float _2538 = _2530.y;\n    if (_2538 > 0.0)\n    {\n        float _2555 = 1.0 - smoothstep(0.75 * _2538, _2538, length(world - _2062.fa_shadow_eye.xyz));\n        fade = _2555;\n        if (_2555 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2530.x > 1.5)\n    {\n        int param_3 = li;\n        int param_4 = fa_light_base(param_3, _365);\n        float3 param_5 = world - fa_light_texel(param_4, fa_light_tex, fa_shadow_smp).xyz;\n        face = fa_cube_face(param_5);\n    }\n    int _2584 = (_2526 + 2) + (face * 6);\n    int param_6 = _2584;\n    int param_7 = _2584 + 1;\n    int param_8 = _2584 + 3;\n    float4 _2598 = fa_light_texel(param_8, fa_light_tex, fa_shadow_smp);\n    int param_9 = _2584 + 4;\n    float4 _2603 = fa_light_texel(param_9, fa_light_tex, fa_shadow_smp);\n    int param_10 = _2584 + 5;\n    float4 _2608 = fa_light_texel(param_10, fa_light_tex, fa_shadow_smp);\n    float _2620 = _2608.x * fast::max(dot(_2598, float4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2625 = fast::clamp(dot(n, l), 0.0, 1.0);\n    float _2648 = fast::clamp(dot(n, _2598.xyz), -1.0, 1.0);\n    int param_11 = li;\n    int param_12 = fa_light_base(param_11, _365);\n    float _2672 = fast::min(sqrt(1.0 - (_2648 * _2648)) / fast::max(abs(dot(n, world - fa_light_texel(param_12, fa_light_tex, fa_shadow_smp).xyz)) / fast::max(dot(_2598, float4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2675 = _2535.y;\n    float _2677;\n    if (_2675 > 0.0)\n    {\n        _2677 = _2675;\n    }\n    else\n    {\n        _2677 = 1.5 * _2620;\n    }\n    float4 _2697 = float4(world + (n * (_2677 * sqrt(1.0 - (_2625 * _2625)))), 1.0);\n    float _2701 = dot(_2598, _2697);\n    float _2704 = _2608.y;\n    if (_2701 < _2704)\n    {\n        return 1.0;\n    }\n    float2 _2719 = float2(dot(fa_light_texel(param_6, fa_light_tex, fa_shadow_smp), _2697), dot(fa_light_texel(param_7, fa_light_tex, fa_shadow_smp), _2697)) / float2(_2701);\n    float _2721 = _2719.x;\n    bool _2724 = _2721 < _2603.x;\n    bool _2733;\n    if (!_2724)\n    {\n        _2733 = _2721 > _2603.z;\n    }\n    else\n    {\n        _2733 = _2724;\n    }\n    bool _2742;\n    if (!_2733)\n    {\n        _2742 = _2719.y < _2603.y;\n    }\n    else\n    {\n        _2742 = _2733;\n    }\n    bool _2751;\n    if (!_2742)\n    {\n        _2751 = _2719.y > _2603.w;\n    }\n    else\n    {\n        _2751 = _2742;\n    }\n    if (_2751)\n    {\n        return 1.0;\n    }\n    float _2757 = _2535.x;\n    float _2759;\n    if (_2757 > 0.0)\n    {\n        _2759 = _2757;\n    }\n    else\n    {\n        _2759 = 1.5 * _2620;\n    }\n    float2 param_13 = _2719;\n    float4 param_14 = _2603;\n    float param_15 = _2701 - (_2759 * (1.0 + (0.5 * _2672)));\n    float param_16 = _2620;\n    float param_17 = 1.0;\n    float param_18 = _2608.z * 0.25;\n    float param_19 = (_2620 * fast::min(_2672, 3.0)) * 0.5;\n    float3 param_20 = float3(1.0, _2704, _2608.z);\n    int param_21 = int(_2530.z + 0.5);\n    float param_22 = _2530.w;\n    return mix(1.0, fa_shadow_filter(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21, param_22, fa_shadow_smp, gl_FragCoord, _2062, fa_shadow_tex), fade);\n}\n\nstatic inline __attribute__((always_inline))\nLightSample fa_light_shadowed(thread const int& li, thread const float3& world_pos, thread const float3& gn, constant fa_mesh_fs_params& _365, texture2d<float> fa_light_tex, sampler fa_shadow_smp, texture2d<float> fa_light_atlas, sampler fa_env_smp, thread float3& fa_light_tint, thread bool& fa_light_is_area, thread float4& gl_FragCoord, constant fa_shadows& _2062, texture2d<float> fa_shadow_tex, thread float3& fa_world_pos, thread float3& fa_lm)\n{\n    bool _3915 = fa_lm.z > 0.5;\n    bool _3921;\n    if (_3915)\n    {\n        int param = li;\n        _3921 = fa_light_baked(param, _365, fa_light_tex, fa_shadow_smp);\n    }\n    else\n    {\n        _3921 = _3915;\n    }\n    if (_3921)\n    {\n        int param_1 = li;\n        return LightSample{ float3(0.0, 1.0, 0.0), float3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1, _365, fa_light_tex, fa_shadow_smp) + 0.5) };\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _3945 = fa_light_sample_n(param_2, param_3, param_4, _365, fa_light_tex, fa_shadow_smp, fa_light_atlas, fa_env_smp, fa_light_tint, fa_light_is_area);\n    float3 _5030 = _3945.color;\n    float _5032 = _3945.shadow;\n    if ((_3945.type == 0) && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _3945.direction;\n        float _3959 = fa_shadow_factor(param_5, param_6, _365, fa_shadow_smp, gl_FragCoord, _2062, fa_shadow_tex, fa_world_pos);\n        _5032 = _3959;\n        _5030 *= _3959;\n    }\n    else\n    {\n        bool _3970 = _3945.type != 0;\n        bool _3976;\n        if (_3970)\n        {\n            _3976 = _3945.attenuation > 0.0;\n        }\n        else\n        {\n            _3976 = _3970;\n        }\n        if (_3976)\n        {\n            int param_7 = li;\n            float3 param_8 = world_pos;\n            float3 param_9 = gn;\n            float3 param_10 = _3945.direction;\n            float _3988 = fa_shadow_local(param_7, param_8, param_9, param_10, _365, fa_light_tex, fa_shadow_smp, gl_FragCoord, _2062, fa_shadow_tex);\n            _5032 = _3988;\n            _5030 *= _3988;\n        }\n    }\n    return LightSample{ _3945.direction, _5030, _3945.attenuation, _5032, _3945._distance, _3945.type };\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 light(thread const SurfaceInput& i, thread const Surface& s, thread const LightSample& l)\n{\n    return float3(0.0);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_shadow_debug(thread const float3& color, thread const float3& world, constant fa_shadows& _2062)\n{\n    if (_2062.fa_shadow_eye.w < 0.5)\n    {\n        return color;\n    }\n    int _3008 = int(_2062.fa_shadow_cfg.x + 0.5);\n    float _3018 = dot(world - _2062.fa_shadow_eye.xyz, _2062.fa_shadow_fwd.xyz);\n    float3 tint = float3(0.3499999940395355224609375);\n    bool _3023 = _3008 > 0;\n    bool _3032;\n    if (_3023)\n    {\n        int param = _3008 - 1;\n        _3032 = _3018 <= fa_shadow_split_at(param, _2062);\n    }\n    else\n    {\n        _3032 = _3023;\n    }\n    if (_3032)\n    {\n        tint = float3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3038 = _3008 > 1;\n        bool _3045;\n        if (_3038)\n        {\n            _3045 = _3018 > _2062.fa_shadow_split.x;\n        }\n        else\n        {\n            _3045 = _3038;\n        }\n        if (_3045)\n        {\n            tint = float3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3051 = _3008 > 2;\n        bool _3058;\n        if (_3051)\n        {\n            _3058 = _3018 > _2062.fa_shadow_split.y;\n        }\n        else\n        {\n            _3058 = _3051;\n        }\n        if (_3058)\n        {\n            tint = float3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3064 = _3008 > 3;\n        bool _3071;\n        if (_3064)\n        {\n            _3071 = _3018 > _2062.fa_shadow_split.z;\n        }\n        else\n        {\n            _3071 = _3064;\n        }\n        if (_3071)\n        {\n            tint = float3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, float3(0.550000011920928955078125));\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant fa_mesh_fs_params& _365 [[buffer(1)]], constant fa_shadows& _2062 [[buffer(7)]], texture2d<float> fa_tex [[texture(0)]], texture2d<float> fa_shadow_tex [[texture(1)]], texture2d<float> fa_normal_tex [[texture(2)]], texture2d<float> fa_mr_tex [[texture(3)]], texture2d<float> fa_occlusion_tex [[texture(4)]], texture2d<float> fa_emissive_tex [[texture(5)]], texturecube<float> fa_env_tex [[texture(6)]], texturecube<float> fa_irr_tex [[texture(7)]], texture2d<float> fa_light_tex [[texture(8)]], texture2d<float> fa_light_atlas [[texture(9)]], texture2d<float> fa_lightmap [[texture(10)]], texture2d<float> fa_decal_tex [[texture(11)]], sampler fa_smp [[sampler(0)]], sampler fa_shadow_smp [[sampler(1)]], sampler fa_env_smp [[sampler(10)]], float4 gl_FragCoord [[position]], bool gl_FrontFacing [[front_facing]])\n{\n    main0_out out = {};\n    fa_inst_load();\n    float3 _4739 = fast::normalize(in.fa_world_normal);\n    float3 fa_light_tint;\n    bool fa_light_is_area;\n    int fa_cl_ndir;\n    int fa_cl_slot;\n    int fa_cl_local;\n    if (!gl_FrontFacing)\n    {\n        _4739 = -_4739;\n    }\n    float3 _4374 = fast::normalize(_365.fa_camera_pos.xyz - in.fa_world_pos);\n    float3 param = in.fa_world_pos;\n    fa_cluster_begin(param, _365, fa_light_tex, fa_shadow_smp, fa_cl_ndir, fa_cl_slot, fa_cl_local);\n    SurfaceInput param_1 = SurfaceInput{ in.fa_world_pos, _4739, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _4374, short(gl_FrontFacing) };\n    Surface _4382 = fa_standard_surface(param_1, _365, fa_tex, fa_smp, fa_normal_tex, fa_mr_tex, fa_occlusion_tex, fa_emissive_tex);\n    float3 _4778 = _4382.albedo;\n    float _4779 = _4382.alpha;\n    float3 _4780 = _4382.normal;\n    float _4781 = _4382.metallic;\n    float _4782 = _4382.roughness;\n    float _4783 = _4382.occlusion;\n    float3 _4784 = _4382.emission;\n    float _4785 = _4382.clearcoat;\n    float _4786 = _4382.clearcoat_roughness;\n    float3 _4787 = _4382.sheen_color;\n    float _4788 = _4382.sheen_roughness;\n    float _4789 = _4382.anisotropy;\n    float _4790 = _4382.anisotropy_rotation;\n    float _4791 = _4382.specular;\n    float _4792 = _4382.ior;\n    float3 _4793 = _4382.specular_color;\n    SurfaceInput param_2 = SurfaceInput{ in.fa_world_pos, _4739, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _4374, short(gl_FrontFacing) };\n    Surface param_3 = _4382;\n    surface(param_2, param_3);\n    _4778 = param_3.albedo;\n    _4779 = param_3.alpha;\n    _4780 = param_3.normal;\n    _4781 = param_3.metallic;\n    _4782 = param_3.roughness;\n    _4783 = param_3.occlusion;\n    _4784 = param_3.emission;\n    _4785 = param_3.clearcoat;\n    _4786 = param_3.clearcoat_roughness;\n    _4787 = param_3.sheen_color;\n    _4788 = param_3.sheen_roughness;\n    _4789 = param_3.anisotropy;\n    _4790 = param_3.anisotropy_rotation;\n    _4791 = param_3.specular;\n    _4792 = param_3.ior;\n    _4793 = param_3.specular_color;\n    float3 param_4 = in.fa_world_pos;\n    float3 param_5 = _4739;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7, _365, fa_light_tex, fa_shadow_smp, fa_env_smp, fa_decal_tex);\n    _4778 = param_6;\n    _4780 = param_7;\n    float3 result;\n    if (_365.fa_emissive.w > 0.5)\n    {\n        result = _4778;\n    }\n    else\n    {\n        float3 _4420 = _4780;\n        float3 _4421 = fast::normalize(_4420);\n        _4780 = _4421;\n        float3 param_8 = _4421;\n        SurfaceInput param_9 = SurfaceInput{ in.fa_world_pos, _4739, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _4374, short(gl_FrontFacing) };\n        Surface param_10 = Surface{ _4778, _4779, _4780, _4781, _4782, _4783, _4784, _4785, _4786, _4787, _4788, _4789, _4790, _4791, _4792, _4793 };\n        float3 param_11 = fa_indirect_diffuse(param_8, _365, fa_env_smp, fa_irr_tex, in.fa_lm, fa_lightmap);\n        float3 lit = ambient(param_9, param_10, param_11, _365, fa_env_smp, fa_env_tex);\n        int _4440 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _4440; ln++)\n        {\n            int param_12 = ln;\n            int _4453 = fa_cl_light(param_12, _365, fa_light_tex, fa_shadow_smp, fa_cl_ndir, fa_cl_slot);\n            bool _4456 = in.fa_lm.z > 0.5;\n            bool _4462;\n            if (_4456)\n            {\n                int param_13 = _4453;\n                _4462 = fa_light_baked(param_13, _365, fa_light_tex, fa_shadow_smp);\n            }\n            else\n            {\n                _4462 = _4456;\n            }\n            if (_4462)\n            {\n                continue;\n            }\n            int param_14 = _4453;\n            float3 param_15 = in.fa_world_pos;\n            float3 param_16 = _4739;\n            LightSample _4474 = fa_light_shadowed(param_14, param_15, param_16, _365, fa_light_tex, fa_shadow_smp, fa_light_atlas, fa_env_smp, fa_light_tint, fa_light_is_area, gl_FragCoord, _2062, fa_shadow_tex, in.fa_world_pos, in.fa_lm);\n            SurfaceInput param_17 = SurfaceInput{ in.fa_world_pos, _4739, in.fa_world_tangent, in.fa_uv, in.fa_vertex_color, _4374, short(gl_FrontFacing) };\n            Surface param_18 = Surface{ _4778, _4779, _4780, _4781, _4782, _4783, _4784, _4785, _4786, _4787, _4788, _4789, _4790, _4791, _4792, _4793 };\n            LightSample param_19 = _4474;\n            lit += light(param_17, param_18, param_19);\n        }\n        result = lit;\n    }\n    float3 _4489 = result;\n    float3 _4490 = _4489 + _4784;\n    result = _4490;\n    float3 param_20 = _4490;\n    float3 param_21 = in.fa_world_pos;\n    result = fa_shadow_debug(param_20, param_21, _2062);\n    bool _4499 = _365.fa_fog.w > 0.0;\n    bool _4506;\n    if (!_4499)\n    {\n        _4506 = _365.fa_fog_b.y > 0.0;\n    }\n    else\n    {\n        _4506 = _4499;\n    }\n    if (_4506)\n    {\n        float3 _4515 = in.fa_world_pos - _365.fa_camera_pos.xyz;\n        float _4521 = dot(_4515, _365.fa_fog_c.xyz);\n        bool _4525 = _365.fa_fog_c.w > 0.5;\n        float _4526;\n        if (_4525)\n        {\n            _4526 = _4521;\n        }\n        else\n        {\n            _4526 = length(_4515);\n        }\n        float _4538 = _4526 - _365.fa_fog_b.x;\n        if (_4538 > 0.0)\n        {\n            float _4547 = _365.fa_fog.w * _4538;\n            float tau = _4547 * _4547;\n            if (_365.fa_fog_b.y > 0.0)\n            {\n                float _4563;\n                if (_4525)\n                {\n                    _4563 = in.fa_world_pos.y - (_365.fa_fog_c.y * _4521);\n                }\n                else\n                {\n                    _4563 = _365.fa_camera_pos.y;\n                }\n                float _4584 = mix(_4563, in.fa_world_pos.y, fast::clamp(_365.fa_fog_b.x / _4526, 0.0, 1.0));\n                float _4588 = in.fa_world_pos.y - _4584;\n                float _4593 = _4584 - _365.fa_fog_b.z;\n                float _4598 = in.fa_world_pos.y - _365.fa_fog_b.z;\n                bool _4601 = _4593 <= 0.0;\n                bool _4602 = !_4601;\n                bool _4608;\n                if (_4602)\n                {\n                    _4608 = _365.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4608 = _4601;\n                }\n                float _4609;\n                if (_4608)\n                {\n                    _4609 = _365.fa_fog_b.y;\n                }\n                else\n                {\n                    _4609 = _365.fa_fog_b.y * exp(-fast::min(_365.fa_fog_b.w * _4593, 80.0));\n                }\n                bool _4636;\n                if (_4602)\n                {\n                    _4636 = _365.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4636 = _4601;\n                }\n                float _4637;\n                if (_4636)\n                {\n                    _4637 = _365.fa_fog_b.y * _4593;\n                }\n                else\n                {\n                    _4637 = (_365.fa_fog_b.y * (1.0 - exp(-fast::min(_365.fa_fog_b.w * _4593, 80.0)))) / _365.fa_fog_b.w;\n                }\n                bool _4662 = _4598 <= 0.0;\n                bool _4669;\n                if (!_4662)\n                {\n                    _4669 = _365.fa_fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4669 = _4662;\n                }\n                float _4670;\n                if (_4669)\n                {\n                    _4670 = _365.fa_fog_b.y * _4598;\n                }\n                else\n                {\n                    _4670 = (_365.fa_fog_b.y * (1.0 - exp(-fast::min(_365.fa_fog_b.w * _4598, 80.0)))) / _365.fa_fog_b.w;\n                }\n                float _4697;\n                if (abs(_4588) < 0.001000000047497451305389404296875)\n                {\n                    _4697 = _4609;\n                }\n                else\n                {\n                    _4697 = (_4670 - _4637) / _4588;\n                }\n                tau += (_4538 * fast::max(_4697, 0.0));\n            }\n            result = mix(result, _365.fa_fog.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    out.fa_frag_color = float4(result, _4779);\n    return out;\n}\n\n",
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
            "inst_name": "_365",
            "msl_buffer_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2062",
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
          },
          {
            "texture": {
              "slot": 25,
              "stage": "fragment",
              "name": "fa_light_atlas",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 9
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
              "msl_texture_n": 10
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
            "name": "fa_irr_tex_fa_env_smp",
            "view_name": "fa_irr_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 15,
            "sampler_slot": 10
          },
          {
            "slot": 9,
            "stage": "fragment",
            "name": "fa_env_tex_fa_env_smp",
            "view_name": "fa_env_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10
          },
          {
            "slot": 10,
            "stage": "fragment",
            "name": "fa_light_atlas_fa_env_smp",
            "view_name": "fa_light_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 25,
            "sampler_slot": 10
          },
          {
            "slot": 11,
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
